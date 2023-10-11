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
      include Shared::Config
      include Shared::Filters
      include Shared::Site
      include Shared::UncategorizedHelpers

      def tag_name(key) = tag_data(key).presentational_name

      def tag_data(key) = filter_drop(key, drop_class: tag_drop_class)

      def tag_link(key, display_content = nil)
        data_record_link key,
                         display_content:,
                         drop_class: tag_drop_class
      end

      def tag_static_map_html(key)
        place_keys = site_object.data.dig 'places_for_tag', key
        return '' if place_keys.nil?

        points = place_keys.map { PlaceDrop.new _1, context: @context }
                           .select(&:exist?)
                           .map(&:point)
        return "<pre>#{place_keys.join('\n')}</pre>" if points.empty? && (Jekyll.env == 'development')

        map_api_key = config! 'mapbox_access_token', scoped: true
        StaticMap.new(map_api_key:, points:).html
      end

      def tag_reference(key, display_content = nil)
        data_record_reference key,
                              display_content:,
                              drop_class: tag_drop_class
      end

      def tag_url(key) = data_record_url(key, drop_class: tag_drop_class)

      private

      def tag_drop_class = TagDrop
    end
  end
end
Liquid::Template.register_filter HistoricalDiary::JekyllLayer::TagFilters
