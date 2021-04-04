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
require_relative "../_lib/places"

module HistoricalDiary
  module TagFilters
    include DataCollection

    def places_keys_for_tag(key)
      dates = data_collection_record("tags", key)
      dates_for_places_keys = @context.registers[:site].data["dates_for_places_keys"]

      cache_key = [
        key,
        dates_for_places_keys,
      ].map(&:to_s).join("")

      tag_filters_cache.getset(cache_key) do
        Jekyll.logger.debug(self.class.name,
                            "Not yet cached: #{cache_key}")
        dates_for_places_keys.select { |place_key, place_dates| !(dates & place_dates).empty? }.keys
      end
    end

    def static_map_html_for_tag(key)
      place_keys = places_keys_for_tag(key)
      tag_filters_cache.getset(place_keys.to_s) do
        Places.new(place_keys, @context.registers[:site]).static_map_html
      end
    end

    private

    def tag_filters_cache
      @@tag_filters_cache ||= Jekyll::Cache.new("HistoricalDiary::TagFilters")
    end
  end
end

Liquid::Template.register_filter(HistoricalDiary::TagFilters)
