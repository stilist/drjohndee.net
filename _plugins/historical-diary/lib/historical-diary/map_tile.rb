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
  class MapTile
    attr_reader :bounding_box,
                :points

    BREAKPOINTS = {
      small: 960,
      large: 2200,
    }.freeze
    COLORS = {
      # --accent-70
      dark_accent: 'c18e48',
      light_accent: '923b00',
      # --neutral-100
      dark_contrast: '000',
      light_contrast: 'fffefc',
    }.freeze
    SIZES = {
      small: 400,
      medium: 882,
      large: 1200,
    }.freeze
    QUERIES = {
      dark: 'prefers-color-scheme: dark',
      logical_large: "min-inline-size: #{BREAKPOINTS[:large]}px",
      large: "min-width: #{BREAKPOINTS[:large]}px",
      light: 'prefers-color-scheme: light',
      low_data: 'prefers-reduced-data: reduced',
      logical_small: "max-inline-size: #{BREAKPOINTS[:small]}px",
      small: "max-width: #{BREAKPOINTS[:small]}px",
    }.freeze
    # keys: query, size, theme
    SOURCES = [
      { query: %i[dark], theme: :dark },
      { query: %i[light], theme: :light },
    ].freeze
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

    def initialize(site:, bounding_box: nil, points: [])
      @bounding_box = bounding_box || []
      @points = points.compact
                      .select { |point| point.key?(:latitude) && point.key?(:longitude) }
      @site = site
    end

    def static_map_html
      return '' unless renderable?

      sources = SOURCES.map do |source|
        media_query = source[:query].map { QUERIES[_1] }.join(' and ')
        [
          "<source srcset='#{tile_url(size: :large,
                                      theme: source[:theme])}, #{tile_url(dpi: 2,
                                                                          size: :large, theme: source[:theme])} 2x' " \
          "media='(#{media_query}) and (#{QUERIES[:logical_large]}), (#{media_query}) and (#{QUERIES[:large]})'>",
          "<source srcset='#{tile_url(size: :small,
                                      theme: source[:theme])}, #{tile_url(dpi: 2,
                                                                          size: :small, theme: source[:theme])} 2x' " \
          "media='(#{media_query}) and (#{QUERIES[:logical_small]}), (#{media_query}) and (#{QUERIES[:small]})'>",
          "<source srcset='#{tile_url(size: :medium,
                                      theme: source[:theme])}, #{tile_url(dpi: 2,
                                                                          size: :medium, theme: source[:theme])} 2x' " \
          "media='(#{media_query})'>",
        ]
      end

      low_data = "<source srcset='#{tile_url(size: :small)}' media='(#{QUERIES[:low_data]})'>"
      names = if points.length <= 2 then points.first(2).map { |point| point[:name] }.join(' and ')
              else
                points.first[:name] + "and #{points.length - 1} other places"
              end
      default = "<img src='#{tile_url(size: :medium)}' alt='Map of #{names}'>"

      <<~HTML
        <picture class="static-map">
        #{low_data}
        #{sources.flatten.join("\n")}
        #{default}
        </picture>
      HTML
    end

    private

    attr_reader :site

    def api_token = site.config['mapbox_access_token']

    def renderable?
      return true if points.is_a?(Array) && !points.empty?

      bounding_box.is_a?(Array) && bounding_box.length == 4
    end

    # @see https://docs.mapbox.com/api/maps/static-images/
    def tile_url(contrast: false, dpi: 1, include_markers: true, size: :medium, theme: :default)
      if include_markers
        marker_color = [
          theme,
          contrast ? 'contrast' : 'accent',
        ].join('_').to_sym

        markers_array = points.map do |point|
          "pin-s+#{COLORS[marker_color] || COLORS[:dark_accent]}(#{point[:longitude]},#{point[:latitude]})"
        end
        markers = markers_array.join ','
      end

      if bounding_box.is_a?(Array) && !bounding_box.empty?
        location = "[#{bounding_box.join(',')}]"
      elsif points.length > 1
        location = 'auto'
      else
        point = points.first
        location = [
          point[:longitude],
          point[:latitude],
          ZOOM_LEVELS[point[:record_type]],
          0,
        ].flatten.join ','
      end

      size_in_px = SIZES[size]
      parts = [
        URL_BASE,
        TILESETS[theme],
        'static',
        markers,
        location,
        [
          size_in_px,
          'x',
          size_in_px,
          dpi == 1 ? '' : '@2x',
        ].join,
      ].compact
      parts.join('/') + "?access_token=#{api_token}&logo=false"
    end
  end
end
