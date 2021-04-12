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

require "jekyll"
require_relative "../_lib/data_collection"
require_relative "../_lib/historical_diary_page"
require_relative "../_lib/legal_year"
require_relative "../_lib/timestamp_range"

module HistoricalDiary
  class YearPage < HistoricalDiaryPage
    include LegalYear

    def initialize(site, dates_with_content:, year:)
      @site = site
      @base = site.source
      @dir = ""

      @basename = year.to_s
      @ext = ".html"
      @name = "#{@basename}#{@ext}"

      read_yaml(::File.join(@base, "_layouts"), "year.html")

      @data ||= {}
      months = (1..13).map do |n|
        adjusted_n = n + 2
        actual_month_number = adjusted_n
        actual_month_number -= 12 if adjusted_n > 12

        [
          adjusted_n,
          {
            "name" => DateTime.new(2000, actual_month_number).strftime("%B"),
            "days" => [],
          },
        ]
      end
      calendar_year_start = DateTime.iso8601("#{year}-01-01")
      data["date"] = calendar_year_start
      data["last_modified_at"] = DateTime.now.to_date
      data["expanded_legal_year_dates"] = months.to_h
      data["title"] = year
      data["year"] = year

      next_calendar_year = DateTime.iso8601("#{year + 1}-01-01")
      # Generate 13 full months, though ultimately a month of it will be
      # considered 'filler'.
      expanded_legal_year_timestamp = "#{year}-03-01/#{year + 1}-03-31"
      legal_year_start_date = legal_year_start(year)
      legal_year_end_date = legal_year_end(year)
      TimestampRange.new(expanded_legal_year_timestamp, "Gregorian").dates.each do |date|
        calendar_timestamp = date.strftime("%F")

        month = date.strftime("%m")
        day = date.strftime("%d")
        type = if dates_with_content.include?(calendar_timestamp) then "content"
               elsif date < legal_year_start_date then "filler"
               elsif date > legal_year_end_date then "filler"
               else "no-content"
               end

        month_number = if date < next_calendar_year then date.month
                       else date.month + 12
                       end
        data["expanded_legal_year_dates"][month_number]["days"] << {
          "day_number" => date.day,
          # used to inject `<tr>` / `</tr>` for week rows
          "day_of_week" => date.strftime("%w").to_i,
          "url" => date.strftime("%Y/%m/%d.html"),
          "string" => calendar_timestamp,
          "type" => type,
        }.freeze
      end

      data.default_proc = proc do |_, key|
        site.frontmatter_defaults.find(relative_path, :year, key)
      end
    end
  end

  # This iterates over the `Jekyll::Document`s for all published source
  # material, generates a `Jekyll::Post` for each date that has material, and
  # manipulates the front matter of the `Jekyll::Document`s.
  class YearPageGenerator < Jekyll::Generator
    # for `person_data`
    include DataCollection
    # for `legal_year_start`
    include LegalYear

    safe true

    def generate(site)
      @site = site

      person_key = site.config["subject_person_key"]
      record = person_data(person_key)
      if record.nil? || !record.key?("birth_date") || !record.key?("birth_date")
        Jekyll.logger.warn(self.class.name,
                           "Didn't find usable birth and death dates for '#{person_key}'")
        return
      end

      birth_year = record["birth_date"].split("-").first.to_i
      death_year = record["death_date"].split("-").first.to_i

      content_by_year = {}
      site.data["documents_by_date"].keys.each do |date|
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
        Jekyll.logger.debug(self.class.name,
                            "Generating page for #{year}...")

        dates_with_content = (content_by_year[year] || []).uniq.freeze
        document = YearPage.new(site,
                                dates_with_content: dates_with_content,
                                year: year)
        site.pages << document

        year_documents[year] = document
        if year_documents[year - 1]
          year_documents[year].data["previous"] = year_documents[year - 1]
          year_documents[year - 1].data["next"] = document
        end
      end
    end
  end
end
