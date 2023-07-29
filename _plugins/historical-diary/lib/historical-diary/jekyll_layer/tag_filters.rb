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

require_relative 'shared'

module HistoricalDiary
  module JekyllLayer
    # Liquid filters for working with data from `tags` Data Files.
    module TagFilters
      include Shared::Filters

      def tag_data(key) = drop(key, drop_class: tag_drop_class)

      def tag_link(key, display_content = nil)
        data_record_link(key,
                         display_content:,
                         drop_class: tag_drop_class)
      end

      def tag_reference(key, display_content = nil)
        data_record_reference(key,
                              display_content:,
                              drop_class: tag_drop_class)
      end

      def tag_url(key) = data_record_url(key, drop_class: tag_drop_class)

      private

      def tag_drop_class = TagDrop
    end
  end
end
Liquid::Template.register_filter HistoricalDiary::JekyllLayer::TagFilters
