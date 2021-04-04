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
require_relative "../_lib/place"

module HistoricalDiary
  class StaticMapTileBlock < Liquid::Block
    def render(context)
      key = super
      Place.new(key, context.registers[:site]).static_map_html
    end
  end
end
Liquid::Template.register_tag("static_map_tile", HistoricalDiary::StaticMapTileBlock)
