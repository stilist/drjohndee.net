# frozen_string_literal: true

#--
# The life and times of Dr John Dee
# Copyright (C) 2023  Jordan Cole <feedback@drjohndee.net>
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
  # Build the URL for a specific rendering of a map tile.
  class MapTile
    COLORS = {
      # --accent-70
      dark_accent: 'c18e48',
      light_accent: '923b00',
      # --neutral-100
      dark_contrast: '000',
      light_contrast: 'fffefc',
    }.freeze
    TILESETS = {
      dark: 'mapbox/dark-v11',
      default: 'mapbox/light-v11',
      light: 'mapbox/light-v11',
    }.freeze
    URL_BASE = 'https://api.mapbox.com/styles/v1'
    # These values should give reasonable output in most cases. If you need
    # something more specific, set up a `bounding_box` array on the record
    # instead.
    ZOOM_LEVELS = {
      address: 14,
      locality: 9,
      region: 7,
      unknown: 5,
      country: 3,
    }.freeze

    def initialize(access_token:, bounding_box: [], centerpoint: nil, markers: [])
      @access_token = access_token
      @bounding_box = bounding_box
      @centerpoint = centerpoint
      @markers = markers
    end

    def renderable?
      valid_bounding_box? || valid_centerpoint? || valid_markers?
    end

    # Build the URL for a specific tile appearance.
    #
    # @see https://docs.mapbox.com/api/maps/static-images/
    def url(more_contrast:, size:, dpi: 1, theme: :default)
      parts = [
        URL_BASE,
        TILESETS[theme],
        'static',
        serialized_markers(more_contrast:, theme:),
        serialized_location,
        size_fragment(size, dpi:),
      ].compact
      parts.join('/') + "?access_token=#{access_token}&logo=false"
    end

    private

    attr_reader :access_token,
                :bounding_box,
                :centerpoint,
                :markers

    def serialized_location
      return @serialized_location if defined? @serialized_location

      return @serialized_location = "[#{bounding_box.join(',')}]" if valid_bounding_box?
      return @serialized_location = 'auto' if valid_markers?

      @serialized_location = [
        centerpoint[:longitude],
        centerpoint[:latitude],
        ZOOM_LEVELS[centerpoint[:record_type]],
      ].flatten.join ','
    end

    def serialized_markers(more_contrast:, theme:)
      markers.map { serialized_marker(_1, more_contrast:, theme:) }
             .join(',')
    end

    def serialized_marker(marker, more_contrast:, theme:)
      color_key = [
        theme,
        more_contrast ? 'contrast' : 'accent',
      ].join('_').to_sym

      "pin-s+#{COLORS[color_key]}(#{marker[:longitude]},#{marker[:latitude]})"
    end

    def size_fragment(size, dpi:)
      [
        size,
        'x',
        size,
        dpi == 1 ? '' : '@2x',
      ].join
    end

    def valid_bounding_box?
      bounding_box.is_a?(Array) && bounding_box.length == 4
    end

    def valid_centerpoint?
      centerpoint.is_a?(Hash)
    end

    def valid_markers?
      markers.is_a?(Array) && !markers.empty?
    end
  end
end
