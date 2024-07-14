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

module HistoricalDiary
  module SourceDocuments
    class InvalidPageRangeError < RangeError; end

    # Contains the logic for fetching individual pages and ranges of pages.
    # Works even if the style of numbering changes (for example, Roman numerals
    # to Western Arabic numerals).
    class PageRange
      def initialize(keys)
        @keys = keys
      end

      # Select a single page, or a range of pages. Always returns an array to
      # keep things simple for the caller.
      #
      # @example
      #
      #     page_range = PageRange.new(['i', 'ii', 'iii', '1', '5'])
      #     page_range['i'] #=> ['i']
      #     page_range['i', 'iii'] #=> ['i', 'ii', 'iii']
      #     page_range['ii', '1'] #=> ['ii', 'iii', '1']
      #     page_range['1', '5'] #=> ['1', '5']
      def [](first_key, last_key = nil)
        first_index = keys.index first_key
        raise InvalidPageRangeError, first_key if first_index.nil?

        return [first_key] if last_key.nil?

        last_index = keys.index last_key
        raise InvalidPageRangeError, last_key if last_index.nil?
        raise InvalidPageRangeError, "#{first_key}..#{last_key}" if last_index <= first_index

        keys[first_index..last_index]
      end

      private

      attr_reader :keys
    end
  end
end
