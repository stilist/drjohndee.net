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

require 'forwardable'

module HistoricalDiary
  module SourceDocuments
    class InvalidPageRangeError < RangeError; end

    # Produces an ordered hash of pages (page number => page text) from a
    # string of raw text.
    class Paginator
      PAGE_WORD_PATTERN = /(?:page|folio)\s/
      private_constant :PAGE_WORD_PATTERN
      PAGE_HEADER_PATTERN = /
        ^
        (\[
          #{PAGE_WORD_PATTERN}
          [\p{Letter}\p{Number}]+
        \])
        $
      /x
      private_constant :PAGE_HEADER_PATTERN
      ELLIPSIS_PATTERN = /\[(\.{3}|…)\]/
      private_constant :ELLIPSIS_PATTERN

      def initialize(raw_text)
        @raw_text = raw_text
      end

      # If `raw_text` is
      #
      #     [page 1r]\n\nexample\n\n  another line\n\n[…]\n\n[page 30v]\n\n  other text\n
      #
      # this will return
      #
      #     {
      #       "1r" => "example\n\n  another line",
      #       "30v" => "other text",
      #     }
      def pages
        return @pages if defined? @pages

        @pages = {}
        return @pages if raw_text.nil?

        segmented_pages.each_slice(2) do |page_header, text|
          page_number = page_header.gsub(/(\[|\]|#{PAGE_WORD_PATTERN})/o, '')
          @pages[page_number] = sanitize_text text
        end

        @pages
      end

      # Get the page number for a single page, or a range of pages. Always
      # returns an array to keep things simple for the caller.
      #
      # Given page numbers `['ⅰ', 'ⅰⅰ', '١', '1', '5']`,
      # * `['ⅰ']` returns [`ⅰ`]
      # * `['ⅰ', '١']` returns [`ⅰ`, `ⅰⅰ`, `١`]
      # * `['ⅰⅰ', '1']` returns [`ⅰⅰ`, `١`, `1`]
      # * `['1', '5']` returns [`1`, `5`]
      def [](first_key, last_key = nil)
        first_index = keys.index first_key
        raise InvalidPageRangeError, first_key if first_index.nil?

        return [first_key] if last_key.nil?

        last_index = keys.index last_key
        raise InvalidPageRangeError, last_key if last_index.nil?
        raise InvalidPageRangeError, "#{first_key}..#{last_key}" if last_index <= first_index

        # Ruby preserves the insertion order of hash keys, so to load a range of
        # pages calling code can scan forward from the first page’s number to
        # the last page’s number.
        keys[first_index..last_index]
      end

      private

      attr_reader :raw_text

      def keys = pages.keys

      def sanitize_text(text)
        return if text.nil?

        text.strip!
        text.gsub!(/(\A#{ELLIPSIS_PATTERN}|#{ELLIPSIS_PATTERN}\z)/o, '')
        text.strip!
        return nil if text.empty?

        text
      end

      def segmented_pages
        pages = raw_text.split PAGE_HEADER_PATTERN
        return [] if pages.empty?

        # Ignore any text before the first header.
        pages.shift unless pages.first.match? PAGE_HEADER_PATTERN

        pages
      end
    end
  end
end
