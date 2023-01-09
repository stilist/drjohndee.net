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
require "date"
require_relative "jekyll_layer/historical_diary_page"

module HistoricalDiary
  class DayPage < HistoricalDiaryPage
    def initialize(site, date:, documents:, people_keys:, places_keys:, sources_keys:, tags:)
      @site = site
      @base = site.source
      @dir = [
        date.strftime("%Y"),
        date.strftime("%m"),
      ].join(File::SEPARATOR)

      @basename = date.strftime("%d")
      @ext = ".html"
      @name = "#{@basename}#{@ext}"

      read_yaml(File.join(@base, "_layouts"), "date.html")

      @data ||= {}
      data["has_source_material"] = true
      data["date"] = date
      data["last_modified_at"] = DateTime.now.to_date
      timestamp = date.strftime("%F")
      data["timestamp"] = timestamp
      data["title"] = timestamp

      data["documents"] = documents

      data["people_keys"] = people_keys
      data["places_keys"] = places_keys
      data["sources_keys"] = sources_keys
      data["tags"] = tags

      data.default_proc = proc do |_, key|
        site.frontmatter_defaults.find(relative_path, :day, key)
      end
    end
  end

  class DayPageGenerator < Jekyll::Generator
    safe true

    def generate(site)
      posts_by_date = {}

      keys_by_date = site.data["keys_by_date"]

      site.data["documents_by_date"].each do |date, documents|
        post_document = DayPage.new(site,
                                    date: date,
                                    documents: documents,
                                    people_keys: keys_by_date[:people_keys][date],
                                    places_keys: keys_by_date[:places_keys][date],
                                    sources_keys: keys_by_date[:referenced_sources_keys][date],
                                    tags: keys_by_date[:tags][date])
        site.posts.docs << post_document
        posts_by_date[date] = post_document
      end

      # Put `DayPage`s in chronological order, and set `next` / `previous` in
      # `DayPage` metadata for links on page.
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

      site.data["dates_with_content"] = sorted_dates
    end
  end
end
