# frozen_string_literal: true

#--
# The life and times of Dr John Dee
# Copyright (C) 2024  Jordan Cole <feedback@drjohndee.net>
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

require_relative '../annotation'

module HistoricalDiary
  module SourceDocuments
    # ‘Reflow’ text to tidy words that have been broken across lines and pages.
    #
    # `raw_pages` is the simple hash of page numbers and text produced by
    # `Paginator`.
    class Reflows
      def initialize(raw_pages, redactions:)
        @raw_pages = raw_pages
        @redactions = redactions
      end

      # Apply reflows to `raw_pages` and return the result.
      def pages
        by_page.each do |page_number, reflows|
          first_key, last_key = page_number.split '-'
          next if raw_pages[first_key].nil?

          reflow_across_pages(first_key, last_key, reflows) unless last_key.nil?

          raw_pages[first_key] = Annotation.new(raw_pages[first_key], annotations: reflows).text
        end

        raw_pages
      end

      private

      attr_reader :raw_pages,
                  :redactions

      # Convert `reflows` to a hash that’s keyed by page number. This makes it
      # easy to find the redactions that are relevant for a given page number.
      #
      # Given
      #     [{"value"=>"Test", "selectors"=>[{"page"=>"1", "exact"=>"Te- st"}]}]
      #
      # returns
      #     {"1"=>[{"value"=>"Gelderland", "selectors"=>[{"exact"=>"Gel- derland"}]}]}
      def by_page
        return {} if raw_pages.nil? || redactions['reflows'].nil?

        redactions['reflows'].each_with_object({}) do |reflow, memo|
          reflow['selectors'].each do |selector|
            page_number = selector['page']
            next if page_number.nil?

            (memo[page_number] ||= []) << reflow
          end
        end
      end

      # Handle selectors that split across pages by ‘moving’ the whole word to
      # `first_key`’s page.
      def reflow_across_pages(first_key, last_key, reflows)
        reflows.each do |reflow|
          # There can reasonably be multiple reflows across pages, if both the
          # body text and a note each break a word across pages. But for a given
          # reflow there's at most one pair of pages, and one relevant string
          # that runs across them, so there's at most one valid selector for the
          # reflow.
          selector = reflow['selectors'].first['exact']
          head_pattern, tail_pattern = head_and_tail_patterns selector
          next if head_pattern.nil?

          apply_cross_page_reflow(first_key, last_key, head_pattern, tail_pattern, reflow)
        end
      end

      def head_and_tail_patterns(selector)
        head, tail = selector.split(/-\s/)
        return nil if tail.nil?

        [
          /(#{head}-)(\n|\s?$)/,
          /^#{tail}\n?/,
        ]
      end

      def apply_cross_page_reflow(first_key, last_key, head_pattern, tail_pattern, reflow)
        first_page = raw_pages[first_key]
        return unless head_pattern.match? first_page

        last_page = raw_pages[last_key]
        return unless tail_pattern.match? last_page

        raw_pages[first_key] = first_page.sub head_pattern, reflow['value']
        raw_pages[last_key] = last_page.sub tail_pattern, ''
      end
    end
  end
end
