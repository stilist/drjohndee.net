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
require_relative "../_lib/timestamp_range"

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
    Jekyll::Page::HTML_EXTENSIONS.include?(output_ext)
  end
end

module HistoricalDiary
  # This iterates over the `Jekyll::Document`s for all published source
  # material, generates a `Jekyll::Post` for each date that has material, and
  # manipulates the front matter of the `Jekyll::Document`s.
  class SourceMaterialGenerator < Jekyll::Generator
    # for `escape_key`
    include DataCollection

    # This produces data used by `DayPageGenerator` and `YearPageGenerator`.
    priority :highest
    safe true

    def generate(site)
      @site = site

      @data_keys = %i[
        people_keys
        places_keys
        referenced_sources_keys
        sources_keys
        tags
      ].freeze
      @dates_by_key = {}
      @keys_by_date = {}
      @data_keys.each do |data_key|
        @dates_by_key[data_key] = {}
        @keys_by_date[data_key] = {}
      end

      @documents_by_date = {}

      Jekyll.logger.debug(self.class.name,
                          "#{@site.pages.length} page(s) before processing source material")

      @source_material = @site.collections["source_material"].docs
      @source_material_data = source_material

      manipulate_source_material_metadata
      build_data_indexes_from_source_material

      @data_keys.each do |data_key|
        global_data_key = data_key == :tags ? "tags" : "dates_for_#{data_key}"
        @site.data[global_data_key] = @dates_by_key[data_key]
      end

      @site.data["documents_by_date"] = @documents_by_date
      @site.data["keys_by_date"] = @keys_by_date
    end

    def cache
      @@cache ||= Jekyll::Cache.new("HistoricalDiary::SourceMaterialGenerator")
    end

    def source_material
      @source_material.map do |document|
        Jekyll.logger.debug(self.class.name,
                            "Processing metadata for #{document.relative_path}...")

        timestamp_string = document.basename_without_ext
        source_key = escape_key(document.relative_path.split(File::SEPARATOR)[-2])

        cache_key = [
          timestamp_string,
          source_key,
          document.data,
          document.content,
        ].map(&:to_s).join("")

        cache.getset(cache_key) do
          Jekyll.logger.debug(self.class.name,
                              "Not yet cached: #{cache_key}")

          # Splitting on `,` allows for non-consecutive dates without making
          # `TimestampRange` more complex.
          dates = cache.getset(timestamp_string) do
            timestamp_string.split(",")
              .map { |timestamp| TimestampRange.new(timestamp).dates }
              .flatten
          end

          # @note This doesn't include the `author_key` associated with the
          #   `document`'s `source_key`, only explicit `author_key`s.
          people_keys = [
            document.data["people"],
            document.data["author_key"],
            document.data["recipient_key"],
          ].flatten.compact.map { |key| escape_key(key) }

          places_keys = [
            document.data["places"],
          ].flatten.compact

          referenced_sources_keys = document.data["sources"] || []
          sources_keys = [
            source_key,
            referenced_sources,
          ].flatten.compact.map { |key| escape_key(key) }

          {
            document: document,
            dates: dates,
            people_keys: people_keys,
            places_keys: places_keys,
            referenced_sources_keys: referenced_sources_keys,
            sources_keys: sources_keys,
            source_key: source_key,
            tags: document.data["tags"] || [],
            timestamp_string: timestamp_string,
          }
        end
      end
    end

    # Side effects go here.
    def manipulate_source_material_metadata
      @source_material_data.each do |item|
        document = item[:document]

        document.data["all_people_keys"] = item[:people_keys]
        document.data["dates"] = item[:dates]
        document.data["source_key"] = item[:source_key]

        # @see https://github.com/jekyll/jekyll-sitemap/blob/aecc559ff6d15e3bea92cdc898b4edeb6fdf774d/README.md#exclusions
        document.data["sitemap"] = false
      end
    end

    def build_data_indexes_from_source_material
      @source_material_data.each do |item|
        item[:dates].each do |date|
          @documents_by_date[date] ||= []
          @documents_by_date[date] << item[:document]

          @data_keys.each do |data_key|
            item[data_key].each do |item_key|
              @dates_by_key[data_key][item_key] ||= []
              @dates_by_key[data_key][item_key] << date

              @keys_by_date[data_key][date] ||= []
              @keys_by_date[data_key][date] << item_key
            end
          end
        end
      end
    end
  end
end
