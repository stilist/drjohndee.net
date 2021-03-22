# frozen_string_literal: true

# The life and times of Dr John Dee
# Copyright (C) 2021  Jordan Cole <feedback@drjohndee.net>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

require 'jekyll'
require_relative '../_lib/data_collection'
require_relative '../_lib/historical_diary_page'
require_relative '../_lib/legal_year'
require_relative '../_lib/timestamp_range'

# This monkeypatches an `#html?` method into `Jekyll::Document`.
# `jekyll-sitemap` calls Jekyll's `site.html_pages`. `site.html_pages`
# (`Jekyll::Drops::SiteDrop#html_pages`) calls `#html?` to filter the items in
# `site.pages`. `HistoricalDiary::SourceMaterialGenerator#generate_day_pages`
# adds the `Jekyll::Document`s from the `source_material` collection to
# `site.pages`; thus `site.html_pages` will see `Jekyll::Document`s, but it
# only expects to see `Jekyll::Page`s -- `Jekyll::Page` defines `#html?`, but
# `Jekyll::Document` doesn't.
#
# This monkeypatch simply copies `Jekyll::Page#html?` to `Jekyll::Document`,
# fixing the crash.
class Jekyll::Document
  # @see https://github.com/jekyll/jekyll/blob/v4.2.0/lib/jekyll/page.rb#L171
  def html?
    ::Jekyll::Page::HTML_EXTENSIONS.include?(output_ext)
  end
end

module HistoricalDiary
  class YearPage < ::HistoricalDiaryPage
    include LegalYear

    def initialize(site, dates_with_content:, year:)
      @site = site
      @base = site.source
      @dir = ''

      @basename = year.to_s
      @ext = '.html'
      @name = "#{@basename}#{@ext}"

      read_yaml(::File.join(@base, '_layouts'), 'year.html')

      @data ||= {}
      months = (1..13).map do |n|
        adjusted_n = n + 2
        actual_month_number = adjusted_n
        actual_month_number -= 12 if adjusted_n > 12

        [
          adjusted_n,
          {
            'name' => DateTime.new(2000, actual_month_number).strftime('%B'),
            'days' => [],
          },
        ]
      end
      calendar_year_start = DateTime.iso8601("#{year}-01-01", ::Date::ENGLAND).to_date
      data['date'] = calendar_year_start
      data['last_modified_at'] = DateTime.now.to_date
      data['expanded_legal_year_dates'] = months.to_h
      data['title'] = year
      data['year'] = year

      # Generate 13 full months, though ultimately a month of it will be
      # considered 'filler'.
      expanded_legal_year_timestamp = "#{year}-03-01/#{year + 1}-03-31"
      next_calendar_year = DateTime.iso8601("#{year + 1}-01-01", ::Date::ENGLAND)
      TimestampRange.new(expanded_legal_year_timestamp).dates.each do |date|
        calendar_timestamp = date.strftime('%F')

        month = date.strftime('%m')
        day = date.strftime('%d')
        type = if dates_with_content.include?(calendar_timestamp) then 'content'
               elsif date < legal_year_start(year) then 'filler'
               elsif date > legal_year_end(year) then 'filler'
               else 'no-content'
               end

        month_number = if date < next_calendar_year then date.month
                       else date.month + 12
                       end
        data['expanded_legal_year_dates'][month_number]['days'] << {
          'day_number' => date.day,
          # used to inject `<tr>` / `</tr>` for week rows
          'day_of_week' => date.strftime('%w').to_i,
          'url' => date.strftime('%Y/%m/%d.html'),
          'string' => calendar_timestamp,
          'type' => type,
        }.freeze
      end

      data.default_proc = proc do |_, key|
        site.frontmatter_defaults.find(relative_path, :year, key)
      end
    end
  end

  class DayPage < HistoricalDiaryPage
    def initialize(site, date:)
      @site = site
      @base = site.source
      # "1500-01-02" => [1500, 1, 2]
      @dir = [
        date.strftime('%Y'),
        date.strftime('%m'),
      ].join(::File::SEPARATOR)

      @basename = date.strftime('%d')
      @ext = '.html'
      @name = "#{@basename}#{@ext}"

      read_yaml(::File.join(@base, '_layouts'), 'date.html')

      @data ||= {}
      data['has_source_material'] = true
      data['date'] = date
      data['last_modified_at'] = DateTime.now.to_date
      timestamp = date.strftime('%F')
      data['timestamp'] = timestamp
      data['title'] = timestamp

      data.default_proc = proc do |_, key|
        site.frontmatter_defaults.find(relative_path, :day, key)
      end
    end
  end

  # This iterates over the `Jekyll::Document`s for all published source
  # material, generates a `Jekyll::Post` for each date that has material, and
  # manipulates the front matter of the `Jekyll::Document`s.
  class SourceMaterialGenerator < ::Jekyll::Generator
    include DataCollection
    include LegalYear

    safe true

    def generate(site)
      @site = site
      @data_keys = %i[
        people_keys
        places_keys
        sources_keys
        tags
      ]

      @source_material = source_material
      @documents_by_date, @dates_by_key = index_data_from_source_material

      @data_keys.each do |data_key|
        global_data_key = data_key == "tags" ? "tags" : "dates_for_#{data_key}"
        @site.data[global_data_key] = @dates_by_key[data_key]
      end

      generate_day_pages
      generate_year_pages
    end

    def cache
      @@cache ||= Jekyll::Cache.new("HistoricalDiary::SourceMaterialGenerator")
    end

    def source_material
      @site.collections["source_material"].docs.map do |document|
        timestamp_string = document.basename_without_ext
        source_key = escape_key(document.relative_path.split(::File::SEPARATOR)[-2])

        cache_key = [
          timestamp_string,
          source_key,
          document.data,
          document.content,
        ].map(&:to_s).join("")

        cache.getset(cache_key) do
          # Splitting on `,` allows for non-consecutive dates without making
          # `TimestampRange` more complex.
          dates = cache.getset(timestamp_string) do
            timestamp_string.split(",")
              .map { |timestamp| TimestampRange.new(timestamp).dates }
              .flatten
          end

          # SIDE EFFECTS
          # @see https://github.com/jekyll/jekyll-sitemap/blob/aecc559ff6d15e3bea92cdc898b4edeb6fdf774d/README.md#exclusions
          document.data["dates"] = dates
          document.data["sitemap"] = false
          document.data["source_key"] = source_key
          @site.pages << document
          # END SIDE EFFECTS

          # @note This doesn"t include the `author_key` associated with the
          #   `document`"s `source_key`, only explicit `author_key`s.
          people_keys = [
            document.data["people"],
            document.data["author_key"],
            document.data["recipient_key"],
          ].flatten.compact.map { |key| escape_key(key) }

          places_keys = [
            document.data["places"],
          ].flatten.compact.map { |key| escape_key(key) }

          sources_keys = [
            source_key,
            document.data["sources"],
          ].flatten.compact.map { |key| escape_key(key) }

          {
            document: document,
            dates: dates,
            people_keys: people_keys,
            places_keys: places_keys,
            sources_keys: sources_keys,
            source_key: source_key,
            tags: document.data["tags"] || [],
            timestamp_string: timestamp_string,
          }
        end
      end
    end

    def index_data_from_source_material
      documents_by_date = {}

      dates_by_key = {}
      @data_keys.each do |data_key|
        dates_by_key[data_key] = {}
      end

      @source_material.each do |item|
        item[:dates].each do |date|
          documents_by_date[date] ||= []
          documents_by_date[date] << item[:document]

          @data_keys.each do |data_key|
            item[data_key].each do |item_key|
              dates_by_key[data_key][item_key] ||= []
              dates_by_key[data_key][item_key] << date
            end
          end
        end
      end

      [
        documents_by_date,
        dates_by_key,
      ]
    end

    def generate_day_pages
      posts_by_date = {}
      @documents_by_date.each do |date, documents|
        post_document = DayPage.new(@site, date: date)
        @site.posts.docs << post_document
        posts_by_date[date] = post_document
      end
      @site.data["dates_with_content"] = posts_by_date

      sorted_posts_by_date = posts_by_date.sort.to_h.freeze
      sorted_documents = sorted_posts_by_date.values
      sorted_dates = sorted_posts_by_date.keys
      sorted_dates.each_with_index do |date, index|
        if index > 0
          previous_date = sorted_dates[index - 1]
          posts_by_date[date].data["previous"] = posts_by_date[previous_date]
        end

        if index < sorted_dates.length
          next_date = sorted_dates[index + 1]
          posts_by_date[date].data["next"] = posts_by_date[next_date]
        end
      end

      @site.data['dates_with_content'] = sorted_dates
    end

    def generate_year_pages
      person_key = @site.config["subject_person_key"]
      record = person_data(person_key)
      return if record.nil?
      return if !record.key?("birth_date")
      return if !record.key?("death_date")

      birth_year = record["birth_date"].split("-").first.to_i
      death_year = record["death_date"].split("-").first.to_i

      content_by_year = {}
      @documents_by_date.keys.each do |date|
        # Use legal year, rather than calendar year, to simplify later logic.
        # This means that for 1600-03-24 the timestamp will be pushed into
        # `@pages_by_year[1599]`, and 1600-03-25 will be pushed into
        # `@pages_by_year[1600]`.
        year = date.year
        year -= 1 if date < legal_year_start(year)
        content_by_year[year] ||= []
        content_by_year[year] << date.strftime("%F")
      end

      year_documents = {}
      (birth_year..death_year).each do |year|
        dates_with_content = (content_by_year[year] || []).uniq.freeze
        document = YearPage.new(@site,
                                dates_with_content: dates_with_content,
                                year: year)
        @site.pages << document

        year_documents[year] = document
        if year_documents[year - 1]
          year_documents[year].data['previous'] = year_documents[year - 1]
          year_documents[year - 1].data['next'] = document
        end
      end
    end
  end
end
