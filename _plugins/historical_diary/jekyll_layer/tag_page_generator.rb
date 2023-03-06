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

require_relative 'utilities'

module HistoricalDiary
  module JekyllLayer
    class TagPageGenerator < Jekyll::Generator
      safe true

      def generate(site)
        site.tags.each do |key, posts|
          site.pages << TagPage.new(site, key, posts)
        end
      end
    end

    class TagPage < Jekyll::Page
      include Utilities

      def initialize(site, key, posts)
        @key = key

        @site = site
        @base = site.source
        @dir  = 'tags'

        @dir  = drop.dirname

        @basename = drop.basename
        @ext      = '.html'
        @name     = "#{@basename}#{@ext}"

        Jekyll.logger.debug self.class.name do
          "Generating #{drop_class::SINGULAR_NOUN} page at '#{@dir}/#{@name}'"
        end

        @data = {
          'is_generated' => true,
          'linked_docs' => posts,
          'tag_key' => key,
          'title' => drop.presentational_name,
          drop_class::DATA_KEY => drop.preferred_key,
        }.merge(drop.page_data['custom_metadata'])

        data.default_proc = proc do |_, key|
          site.frontmatter_defaults.find(relative_path, :tags, key)
        end
      end

      def url_placeholders
        {
          path: @dir,
          basename: basename,
          output_ext: output_ext,
        }
      end

      def inspect = super.sub(/(>)/, " @key=#{key.inspect}\\1")

      protected

      attr_reader :key

      private

      def drop_class = TagDrop

      def drop
        return @drop if defined?(@drop)

        context = context_from_site @site
        @drop = drop_class.new key, context: context
      end
    end
  end
end
