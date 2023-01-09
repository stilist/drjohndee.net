#--
# The life and times of Dr John Dee
# Copyright (C) 2020-2023  Jordan Cole <feedback@drjohndee.net>
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
#++

require "jekyll"
require_relative "data_collection"
require_relative "historical_diary_page"
require_relative "../lib/timestamp_range"

module HistoricalDiary
  module JekyllLayer
    class YearPage < HistoricalDiaryPage
      def initialize(site, dates_with_content:, year:)
        @site = site
        @base = site.source
        @dir = ""

        @basename = year.to_s
        @ext = ".html"
        @name = "#{@basename}#{@ext}"

        read_yaml(::File.join(@base, "_layouts"), "year.html")

        @year = year

        @data ||= {}
        months = (1..12).map do |n|
          [
            n,
            {
              "name" => DateTime.new(2000, n).strftime("%B"),
              "days" => [],
            },
          ]
        end
        data["date"] = timestamp_range.start_date
        data["last_modified_at"] = DateTime.now.to_date
        data["months"] = months.to_h
        data["title"] = year
        data["year"] = year

        timestamp_range.dates.each do |date|
          calendar_timestamp = date.strftime("%F")

          type = "no-content"
          type = "content" if dates_with_content.include?(calendar_timestamp)

          data["months"][date.month]["days"] << {
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

      def timestamp_range
        return @timestamp_range if defined?(@timestamp_range)
        @timestamp_range = TimestampRange.new(@year.to_s, "Gregorian")
      end
    end

    # Generates a `Jekyll::Page` for each calendar year in the life of
    # `subject_person_key`.
    class YearPageGenerator < Jekyll::Generator
      # for `#person_data`
      include DataCollection

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
          year = date.year
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
end
