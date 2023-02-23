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

module HistoricalDiary
  module JekyllLayer
    class PlaceDrop < Jekyll::Drops::Drop
      include Drop

      mutable false

      PLURAL_NOUN = "places"
      SINGULAR_NOUN = "place"
      DATA_KEY = "#{SINGULAR_NOUN}_key"

      def coordinates
        return [] if record.nil?
        return [] if latitude.nil?
        return [] if longitude.nil?

        coordinates = [
          latitude,
          longitude,
        ]
      end

      def point
        return if record.nil?

        {
          latitude: latitude,
          longitude: longitude,
          name: presentational_name,
          record_type: precision,
        }
      end

      def presentational_name
        record["presentational_name"]
      end

      def static_map_html
        return @static_map_html if defined? @static_map_html
        @static_map_html = MapTile.new(bounding_box: bounding_box,
                                       points: [point],
                                       site: site_object).static_map_html
      end

      private
        PRECISION_KEYS = %w[
          address
          locality
          region
          country
        ]

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
          return record["latitude"] if numeric? record["latitude"]
          return if bounding_box.nil?

          (bounding_box[1] + bounding_box[3]) / 2
        end

        def longitude
          return record["longitude"] if numeric? record["longitude"]
          return if bounding_box.nil?

          (bounding_box[0] + bounding_box[2]) / 2
        end

        def precision = PRECISION_KEYS.find { |key| !record[key].nil? } || "unknown"

        def numeric?(value) = value.is_a?(Numeric)
    end
  end
end
