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

require 'jekyll'

module HistoricalDiary
  module LiquidFilters
    def hash_keys(object)
      return object if !object.is_a?(Hash)
      object.keys
    end

    def sort_hash(object, sort_key = nil)
      return object if !object.is_a?(Hash)
      return object.sort_by { |key, _| key }.to_h if sort_key.nil?
      object.sort_by { |_, value| value[sort_key] }.to_h
    end
  end
end
Liquid::Template.register_filter(HistoricalDiary::LiquidFilters)
