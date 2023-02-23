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
    module HashFilters
      # Simple helper to return a <tt>Hash</tt>'s keys for iteration: instead
      # of using the `first` filter to select the key (because the
      # <tt>Hash</tt> will be iterated as an array of `[key, value]`)
      #
      #   {% for person of site.data.people %}
      #     {{person | first}}
      #   {% endfor %}
      #
      # do
      #
      #   {% assign people_keys = site.data.people | hash_keys %}
      #   {% for person_key of people_keys %}
      #     {{person_key}}
      #   {% endfor %}
      def hash_keys object
        return object if !object.is_a? Hash

        object.keys
      end

      # Ruby `Hash`es iterate in the order that keys were inserted. The
      # <tt>sort_hash</tt> filter instead orders the hash by `sort_key` (if
      # provided) or by key (if `sort_key` isn't provided). The functionality
      # is similar to the `sort` filter.
      #
      # @see https://ruby-doc.org/3.2.0/Hash.html#class-Hash-label-Entry+Order
      def sort_hash object, sort_key = nil
        return object if !object.is_a? Hash
        return object.sort_by { |key, _| key }.to_h if sort_key.nil?
        object.sort_by { |_, value| value[sort_key] }.to_h
      end
    end
  end
end
Liquid::Template.register_filter HistoricalDiary::JekyllLayer::HashFilters
