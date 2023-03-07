# frozen_string_literal: true

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
    module PlaceFilters
      include Filter

      def place_data(key) = drop(key, drop_class: place_drop_class)

      def place_language(key) = drop(key, drop_class: place_drop_class)['name_language']

      def place_presentational_name(key)
        drop(key, drop_class: place_drop_class).presentational_name
      end

      def place_link(key, display_content = nil)
        data_record_link(key,
                         display_content: display_content,
                         drop_class: place_drop_class)
      end

      def place_reference(key, display_content = nil)
        data_record_reference(key,
                              display_content: display_content,
                              drop_class: place_drop_class)
      end

      def place_url(key) = data_record_url(key, drop_class: place_drop_class)

      private

      def place_drop_class = PlaceDrop
    end
  end
end
Liquid::Template.register_filter HistoricalDiary::JekyllLayer::PlaceFilters
