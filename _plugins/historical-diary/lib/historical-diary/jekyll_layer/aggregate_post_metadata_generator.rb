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

require_relative 'person_drop'
require_relative 'place_drop'
require_relative 'tag_drop'

module HistoricalDiary
  module JekyllLayer
    # Iterate through posts to set create `places_for_X` data, so that
    # per-drop pages can render a map.
    class AggregatePostMetadataGenerator < Jekyll::Generator
      priority :lowest
      safe true

      def generate(site)
        @site = site

        site.posts.docs.each do |post|
          values = post.data['places']
          next if values.nil? || values.empty?

          DROP_CLASSES.each do |drop_class|
            drop_keys = post.data[drop_class::PLURAL_NOUN]
            next if drop_keys.nil? || drop_keys.empty?

            drop_keys.each { add_data(drop_class:, drop_key: _1, values:) }
          end
        end
      end

      private

      attr_reader :site

      DROP_CLASSES = [
        PersonDrop,
        PlaceDrop,
        TagDrop,
      ].freeze
      private_constant :DROP_CLASSES

      def add_data(drop_class:, drop_key:, values:)
        data_key = "places_for_#{drop_class::SINGULAR_NOUN}"

        site.data[data_key] ||= {}
        site.data[data_key][drop_key] ||= Set.new
        site.data[data_key][drop_key].merge(values)
      end
    end
  end
end
