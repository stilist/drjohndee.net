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

require 'forwardable'
require_relative 'static_map/map_tile'

module HistoricalDiary
  # Render a static map tile for a given bounding box or set or points. Handles
  # light and dark themes, multiple sizes, high-contrast, and low-data mode.
  class StaticMap
    BASE_TILE_SIZE = 400
    BREAKPOINTS = {
      small: 960,
      large: 2200,
    }.freeze
    MEDIA_QUERIES = {
      dark: 'prefers-color-scheme: dark',
      large: "min-inline-size: #{BREAKPOINTS[:large]}px",
      light: 'prefers-color-scheme: light',
      low_data: 'prefers-reduced-data: reduced',
      small: "max-inline-size: #{BREAKPOINTS[:small]}px",
    }.freeze
    SIZE_SCALE_FACTORS = {
      small: 1,
      medium: 2.205,
      large: 3,
    }.freeze

    extend Forwardable
    def_delegators :tile,
                   :renderable?

    def initialize(map_api_key:, bounding_box: nil, points: [])
      @access_token = map_api_key
      @bounding_box = bounding_box || []
      @points = points
    end

    def html
      return '' unless renderable?

      <<~HTML
        <picture class="static-map">
          <source srcset='#{tile_url(size: :small)}' media='(#{MEDIA_QUERIES[:low_data]})'>
          #{size_sources.flatten.join("\n")}
          <img src='#{tile_url(size: :medium)}' alt='#{alt_text}'>
        </picture>
      HTML
    end

    private

    attr_reader :access_token,
                :bounding_box,
                :points

    def alt_text
      names = points.map { _1[:name] }
      formatted = if names.length <= 2 then names.join(' and ')
                  else
                    names.first + "and #{names.length - 1} other places"
                  end
      "Map of #{formatted}"
    end

    def centerpoint
      @centerpoint ||= points.first
    end

    def markers
      points.compact
            .select { _1.key?(:latitude) && _1.key?(:longitude) }
    end

    def size_source(theme)
      media_query = MEDIA_QUERIES[theme]
      SIZE_SCALE_FACTORS.map do |size_name, scale_factor|
        size = BASE_TILE_SIZE * scale_factor

        <<~HTML
          <source
            media='(#{media_query}) and (#{MEDIA_QUERIES[size_name]})'
            srcset='#{tile_url(size:, theme:)}, #{tile_url(dpi: 2, size:, theme:)} 2x'
          >
        HTML
      end
    end

    def size_sources
      %i[
        dark
        light
      ].map do |theme|
        size_source(theme)
      end
    end

    # @see https://docs.mapbox.com/api/maps/static-images/
    def tile_url(dpi: 1, more_contrast: false, size: :medium, theme: :default)
      @tile.url(dpi:, more_contrast:, size:, theme:)
    end

    def tile
      @tile ||= MapTile.new(access_token:,
                            bounding_box:,
                            centerpoint:,
                            markers:)
    end
  end
end
