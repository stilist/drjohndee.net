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

require_relative "data_collection"
require_relative "map_tile"

module HistoricalDiary
  class Place
    include DataCollection

    attr_reader :key,
                :site

    def initialize(key, site)
      @key = key
      # needs to be defined for `DataCollection` (used by `#record`)
      @site = site
    end

    def coordinates
      return [] if record.nil?
      return [] if latitude.nil?
      return [] if longitude.nil?

      coordinates = [
        latitude,
        longitude,
      ].freeze
    end

    def point
      return if record.nil?
      return if coordinates.empty?

      {
        latitude: latitude,
        longitude: longitude,
        name: record["presentational_name"],
        record_type: record_type,
      }.freeze
    end

    def static_map_html
      MapTile.new(bounding_box: bounding_box,
                  points: [point],
                  site: site).static_map_html
    end

    private

    def bounding_box
      return if record.nil?
      return if !record["bounding_box"].is_a?(Array)

      record["bounding_box"].each_with_object([]) do |coordinate, bounding_box|
        latitude = coordinate["latitude"]
        longitude = coordinate["longitude"]

        bounding_box[0] = [bounding_box[0], longitude].compact.min
        bounding_box[1] = [bounding_box[1], latitude].compact.min
        bounding_box[2] = [bounding_box[2], longitude].compact.max
        bounding_box[3] = [bounding_box[3], latitude].compact.max
      end
    end

    def latitude
      return record["latitude"] if record["latitude"].is_a?(Float) || record["latitude"].is_a?(Integer)
      return if bounding_box.nil?

      (bounding_box[1] + bounding_box[3]) / 2
    end

    def longitude
      return record["longitude"] if record["longitude"].is_a?(Float) || record["longitude"].is_a?(Integer)
      return if bounding_box.nil?

      (bounding_box[0] + bounding_box[2]) / 2
    end

    def record_type
      return :unknown if record.nil?

      if record["address"] then :address
      elsif record["locality"] then :locality
      elsif record["region"] then :region
      elsif record["country"] then :country
      else :unknown
      end
    end

    def record
      place_data(key)
    end
  end
end
