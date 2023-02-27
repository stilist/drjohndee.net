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

      # Get transcluded text for provided attributes.
      def page_text
        return @page_text if defined? @page_text

        return '' if attributes['page'].nil?

        candidate_text = source_drop.page(attributes['page'])
                                    .map(&:text)
                                    .join("\n")
        transclusion = Transclusion.new(candidate_text,
                                        prefix: attributes['prefix'],
                                        textStart: attributes['textStart'],
                                        textEnd: attributes['textEnd'],
                                        suffix: attributes['suffix'])
        text = transclusion.text.gsub /\n{2,}/, "</p>\n<p>"
        Liquid::Template.parse(text)
                        .render(@context)
      rescue InvalidTransclusionError
        nil
      end

      private

      def source_drop
        return @source_drop if defined? @source_drop

        key = SourceDocument.build_identifier(attributes['source_key'],
                                              attributes['edition_key'],
                                              attributes['volume_key'])
        SourceDrop.new(key, context: @context)
      end
    end
  end
end
