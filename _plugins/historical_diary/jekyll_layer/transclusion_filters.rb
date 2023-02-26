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
    # Adds a `{% transclusion %}` Liquid block.
    #
    # @example
    #   {% transclusion
    #      source_key="John Dee (1527-1608)"
    #      edition_key="book"
    #      page="30-31"
    #   %}
    #   Optional commentary...
    #   {% endtransclusion %}
    class TransclusionBlock < Liquid::Block
      def initialize(tag_name, markup, options)
        super

        @raw_attributes = markup
      end

      def render(context)
        @context = context
        @block_text = super.dup.strip

        transcluded = <<~HTML
          <blockquote>#{page_text}</blockquote>
        HTML

        transcluded << "\n\n#{@block_text}" if @block_text

        transcluded
      end

      private

      attr_reader :context,
                  :block_text,
                  :raw_attributes

      KEY_PATTERN = /(\w+_key)="(.+?)"/
      def attributes
        return @attributes if defined?(@attributes)

        matches = raw_attributes.scan KEY_PATTERN
        @attributes = matches.each_with_object({}) do |match, memo|
          key, value = match
          memo[key] = value
        end
      end

      def page_text
        page = raw_attributes.match(/page="(.+?)"/)
        return '' if page.nil?

        text = source_drop.page(page[1])
                          .map(&:text)
                          .join "\n"
        Liquid::Template.parse(text).render(@context)
      end

      def source_drop
        return @source_drop if defined?(@source_drop)

        key = SourceDocument.build_identifier(attributes['source_key'],
                                              attributes['edition_key'],
                                              attributes['volume_key'])
        SourceDrop.new(key, context:)
      end
    end
  end
end
Liquid::Template.register_tag 'transclusion', HistoricalDiary::JekyllLayer::TransclusionBlock
