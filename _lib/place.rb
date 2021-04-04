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

module HistoricalDiary
  class Place
    include DataCollection

    attr_reader :key

    BREAKPOINTS = {
      small: 960,
      large: 2200,
    }.freeze
    COLORS = {
      # --accent-70
      dark_accent: "c18e48",
      light_accent: "923b00",
      # --neutral-100
      dark_contrast: "000",
      light_contrast: "fffefc",
    }.freeze
    SIZES = {
      small: 400,
      medium: 882,
      large: 1200,
    }.freeze
    MEDIA_QUERIES = {
      dark: "prefers-color-scheme: dark",
      logical_large: "min-inline-size: #{BREAKPOINTS[:large]}px",
      large: "min-width: #{BREAKPOINTS[:large]}px",
      light: "prefers-color-scheme: light",
      low_data: "prefers-reduced-data: reduced",
      logical_small: "max-inline-size: #{BREAKPOINTS[:small]}px",
      small: "max-width: #{BREAKPOINTS[:small]}px",
    }.freeze
    # keys: query, size, theme
    SOURCES = [
      { query: %i[dark], theme: :dark },
      { query: %i[light], theme: :light },
    ].freeze
    TILESETS = {
      dark: "mapbox/dark-v10",
      default: "mapbox/light-v10",
      light: "mapbox/light-v10",
    }.freeze
    URL_BASE = "https://api.mapbox.com/styles/v1"
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

    def initialize(key, site)
      @key = key
      # needs to be defined for `DataCollection` (used by `#record`)
      @site = site
    end

    def static_map_tile
      return "" if coordinates.empty?

      sources = SOURCES.map do |source|
        media_query = source[:query].map { |key| MEDIA_QUERIES[key] }.join(" and ")
        [
          "<source srcset='#{tile_url(size: :large, theme: source[:theme])}, #{tile_url(dpi: 2, size: :large, theme: source[:theme])} 2x' " \
                   "media='(#{media_query}) and (#{MEDIA_QUERIES[:logical_large]}), (#{media_query}) and (#{MEDIA_QUERIES[:large]})'>",
          "<source srcset='#{tile_url(size: :small, theme: source[:theme])}, #{tile_url(dpi: 2, size: :small, theme: source[:theme])} 2x' " \
                  "media='(#{media_query}) and (#{MEDIA_QUERIES[:logical_small]}), (#{media_query}) and (#{MEDIA_QUERIES[:small]})'>",
          "<source srcset='#{tile_url(size: :medium, theme: source[:theme])}, #{tile_url(dpi: 2, size: :medium, theme: source[:theme])} 2x' " \
                   "media='(#{media_query})'>",
        ].freeze
      end

      low_data = "<source srcset='#{tile_url(size: :small)}' media='(#{MEDIA_QUERIES[:low_data]})'>"
      default = "<img src='#{tile_url(size: :medium)}' alt='Map of #{record['presentational_name']}'>"

      <<-EOM
      <picture class="static-map">
      #{low_data}
      #{sources.flatten.join("\n")}
      #{default}
      </picture>
      EOM
    end

    private

    def api_token
      @site.config["mapbox_access_token"]
    end

    def bounding_box
      return if record.nil?
      return if !record["bounding_box"].is_a?(Array)

      bounding_box = [
        coordinates,
        coordinates
      ].flatten
      record["bounding_box"].each do |coordinate|
        latitude = coordinate["latitude"]
        longitude = coordinate["longitude"]

        bounding_box[0] = [bounding_box[0], longitude].min
        bounding_box[1] = [bounding_box[1], latitude].min
        bounding_box[2] = [bounding_box[2], longitude].max
        bounding_box[3] = [bounding_box[3], latitude].max
      end

      bounding_box
    end

    def coordinates
      return [] if record.nil?
      return [] if record["latitude"].nil?
      return [] if record["longitude"].nil?

      coordinates = [
        record["longitude"],
        record["latitude"],
      ].freeze
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

    # @see https://docs.mapbox.com/api/maps/static-images/
    def tile_url(contrast: false, dpi: 1, include_marker: true, size: :medium, theme: :default)
      if include_marker
        marker_color = [
          theme,
          contrast ? "contrast" : "accent",
        ].join("_").to_sym
        marker = "pin-s+#{COLORS[marker_color] || COLORS[:dark_accent]}(#{coordinates.join(",")})"
      end

      if bounding_box
        location = "[#{bounding_box.join(",")}]"
      else
        location = [
          coordinates,
          zoom_level,
          0
        ].flatten.join(",")
      end

      size_in_px = SIZES[size]
      parts = [
        URL_BASE,
        TILESETS[theme],
        "static",
        marker,
        location,
        [
          size_in_px,
          "x",
          size_in_px,
          dpi == 1 ? "" : "@2x",
        ].join(""),
      ].compact
      parts.join("/") + "?access_token=#{api_token}&logo=false"
    end

    def zoom_level
      return ZOOM_LEVELS[record_type] || ZOOM_LEVELS[:locality]
    end
  end
end
