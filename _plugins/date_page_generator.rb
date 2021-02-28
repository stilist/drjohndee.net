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
require_relative '../_lib/collections'
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
      data['legal_year_dates'] = months.to_h
      data['title'] = year
      data['year'] = year

      # Generate 13 full months, though ultimately a month of it will be
      # considered 'filler'.
      legal_year_timestamp = "#{year}-03-01/#{year + 1}-03-31"
      next_calendar_year = DateTime.iso8601("#{year + 1}-01-01", ::Date::ENGLAND)
      TimestampRange.new(legal_year_timestamp).dates.each do |date|
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
        data['legal_year_dates'][month_number]['days'] << {
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

  class DayPage < ::HistoricalDiaryPage
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
    include ::DataCollection
    include LegalYear

    safe true

    def generate(site)
      @site = site
      generate_day_pages
      generate_year_pages
    end

    def generate_day_pages
      pages_by_timestamp = {}
      generated_dates = {}
      @pages_by_year = {}

      @site.collections['source_material'].docs.each do |document|
        timestamp = document.basename_without_ext
        pages_by_timestamp[timestamp] ||= {}
        source_key = document.relative_path.split(::File::SEPARATOR)[-2]
        pages_by_timestamp[timestamp][source_key] = document
      end

      # Some days may have commentary but nosource material: for example, the
      # dates covered in Dee's Compendious Rehearsall.
      @site.data['commentary'].values.map(&:keys).flatten.each do |timestamp|
        pages_by_timestamp[timestamp] ||= {}
      end

      dates_for_people = {}
      pages_by_timestamp.each do |timestamp, documents|
        timestamp_range = TimestampRange.new(timestamp)

        documents.each do |source_key, document|
          # @see https://github.com/jekyll/jekyll-sitemap/blob/aecc559ff6d15e3bea92cdc898b4edeb6fdf774d/README.md#exclusions
          document.data['sitemap'] = false

          people_for_document = document.data['people'] || []
          # @note This doesn't include the `author_key` associated with the
          #   `document`'s `source_key`, only explicit `author_key`s.
          %w[
            author_key
            recipient_key
          ].each do |key|
            value = document.data[author_key]
            people_for_document << value if value
          end
          people_for_document.map! { |key| escape_key(key) }
          people_for_document.uniq!
          dates = timestamp_range.dates
          people_for_document.each do |key|
            dates_for_people[key] ||= []
            dates_for_people[key].concat(dates)
          end

          document.data['source_key'] = source_key
          document.data['timestamp'] = timestamp
          document.data['timestamp_dates'] = []
          timestamp_range.dates.each do |date|
            date_string = date.strftime('%F')
            document.data['timestamp_dates'] << date_string
          end
          document.data['timestamp_range'] = timestamp_range

          @site.pages << document
        end

        timestamp_range.dates.each do |date|
          next if generated_dates.key?(date)

          # Use legal year, rather than calendar year, to simplify later logic.
          # This means that for 1600-03-24 the timestamp will be pushed into
          # `@pages_by_year[1599]`, and 1600-03-25 will be pushed into
          # `@pages_by_year[1600]`.
          year = date.year
          year -= 1 if date < legal_year_start(year)
          @pages_by_year[year] ||= []
          @pages_by_year[year] << date.strftime('%F')

          document = DayPage.new(@site, date: date)
          @site.posts.docs << document
          generated_dates[date] = document
        end
      end

      @site.data['dates_for_people'] = dates_for_people
      @site.data['dates_for_people'].freeze

      sorted_date_hash = generated_dates.sort.to_h.freeze
      sorted_documents = sorted_date_hash.values
      sorted_date_hash.each_with_index do |(date, document), index|
        if index > 0
          document.data['previous'] = sorted_documents[index - 1]
        end
        if index < sorted_documents.length
          document.data['next'] = sorted_documents[index + 1]
        end
      end

      @site.data['generated_dates'] = generated_dates.keys
    end

    def generate_year_pages
      person_key = @site.config['subject_person_key']
      record = person_data(person_key)
      return if record.nil?
      return if !record.key?('birth_date')
      return if !record.key?('death_date')

      birthYear = record['birth_date'].split('-').first.to_i
      deathYear = record['death_date'].split('-').first.to_i

      year_documents = {}

      (birthYear..deathYear).each do |year|
        dates_with_content = (@pages_by_year[year] || []).uniq.freeze
        document = YearPage.new(@site,
                                dates_with_content: dates_with_content,
                                year: year)
        year_documents[year] = document

        if year_documents[year - 1]
          year_documents[year].data['previous'] = year_documents[year - 1]
          year_documents[year - 1].data['next'] = document
        end
        @site.pages << document
      end
    end
  end
end
