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
    module TransclusionLiquidHelpers
      SOURCE_DROPS = {}

      # Parse basic key-value pairs in the form of `key="value"`. Useful for
      # custom Liquid blocks and tags.
      ATTRIBUTE_PATTERN = /(\w+)="(.+?)"/
      def attributes
        return @attributes if defined? @attributes

        matches = @raw_attributes.scan ATTRIBUTE_PATTERN
        @attributes = matches.each_with_object({}) do |match, memo|
          key, value = match
          memo[key] = value
        end
      end

      def page_html
        return @page_html if defined? @page_html

        if page_text.nil?
          return "#{fallback_html}\n\n#{fallback_html_comment}" if respond_to? :fallback_html

          return fallback_html_comment
        end

        lang = attributes['language'] || source_drop.language
        with_paragraphs = page_text.gsub(/\n{2,}/, "</p>\n<p>")
        <<~HTML
          <blockquote
            class="source-material e-content"
            lang="#{lang}"
          >
            <p>#{with_paragraphs}</p>
          </blockquote>
        HTML
      end

      # Get transcluded text for provided attributes.
      def page_text
        return @page_text if defined? @page_text

        return '' if attributes['page'].nil?

        candidate_text = source_drop.page(attributes['page'])
                                    .map(&:text)
                                    .join("\n")
        transclusion = Transclusion.new(candidate_text,
                                        prefix: attributes['prefix'],
                                        text_start: attributes['text_start'],
                                        text_end: attributes['text_end'],
                                        suffix: attributes['suffix'])
        Liquid::Template.parse(transclusion.text)
                        .render(@context)
      rescue InvalidTransclusionError
        nil
      end

      private

      def fallback_html_comment
        tidied_attributes = @raw_attributes.strip.gsub(/\s{2,}/, "\n")
        <<~HTML
          <!--
          Provided transclude doesn't match anything:

          #{tidied_attributes}
          -->
        HTML
      end

      def source_drop
        return @source_drop if defined? @source_drop

        key = SourceDocument.build_identifier(attributes['source_key'],
                                              attributes['edition_key'],
                                              attributes['volume_key'])
        SOURCE_DROPS[key] ||= SourceDrop.new(key, context: @context)
      end
    end
  end
end
