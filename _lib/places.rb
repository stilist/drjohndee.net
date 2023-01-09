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

require_relative "../_plugins/historical_diary/lib/map_tile"
require_relative "place"

module HistoricalDiary
  class Places
    attr_reader :keys,
                :site

    def initialize(keys, site)
      @keys = keys
      # passed to `Place`
      @site = site
    end

    def static_map_html
      MapTile.new(points: points,
                  site: site).static_map_html
    end

    private

    def points
      keys.map { |key| Place.new(key, site).point }.compact
    end
  end
end
