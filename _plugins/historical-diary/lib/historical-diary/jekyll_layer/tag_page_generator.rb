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
    # Generate a Jekyll Page for each tag in `site.tags`.
    class TagPageGenerator < Jekyll::Generator
      include Shared::DataPageGenerator

      safe true

      def generate(site)
        site.tags.each do |key, posts|
          site.pages << page_class.new(site, key, posts)
        end
      end

      def drop_class = TagDrop
      def page_class = TagPage
    end

    # Generate a Jekyll Page for a given tag.
    class TagPage < Jekyll::Page
      include Shared::DataPage

      def initialize(site, key, posts)
        super(site, key)

        @data['linked_docs'] = posts
      end

      def drop_class = TagDrop
    end
  end
end
