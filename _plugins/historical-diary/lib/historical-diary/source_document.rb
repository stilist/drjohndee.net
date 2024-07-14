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

require_relative 'source_documents/identifier'
require_relative 'source_documents/page_range'
require_relative 'source_documents/paginator'

module HistoricalDiary
  # A collection of `SourceDocuments::Page`s, representing a source such
  # as a book or manuscript.
  #
  # This class is completely independent of Jekyll, and doesn't internally use
  # the identifier to retrieve data, but other classes may use the parsed
  # identifier for that purpose.
  class SourceDocument
    class InvalidPageError < StandardError; end

    class InvalidRedactionError < StandardError; end

    class << self
      def build_identifier(source, edition = nil, volume = nil)
        SourceDocuments::Identifier.new(source:, edition:, volume:)
      end

      def parse_identifier(identifier)
        return identifier if identifier.is_a? SourceDocuments::Identifier

        build_identifier(*identifier.split(','))
      end
    end

    extend Forwardable
    def_delegator :identifier,
                  :source,
                  :edition,
                  :volume

    def_delegator :paginator,
                  :pages,
                  :[]

    def initialize(identifier, raw_text:, redactions: nil)
      @identifier = identifier

      @raw_text = raw_text.dup
      @redactions = redactions

      # state
      @completed_initial_parsing = false
      @notes = {}
      @parsed_pages = {}
      @raw_text_by_page = {}
    end

    alias [] page

    def markup_redactions_for_page(page_number)
      return @markup_redactions[page_number] if defined? @markup_redactions

      @markup_redactions = redactions_by_page('markup')

      @markup_redactions[page_number]
    end

    def notes_for_page(page_number) = notes[page_number]

    attr_reader :identifier,
                :raw_text,
                :redactions

    private

    def paginator
      @paginator ||= SourceDocuments::Paginator.new(raw_text)
    end

    attr_accessor :completed_initial_parsing
    attr_reader :notes,
                :pages,
                :parsed_pages,
                :raw_text_by_page,
                :raw_text,
                :redactions

    def page(page_number)
      return parsed_pages[page_number] if parsed_pages.key?(page_number)

      raw_text = raw_text_by_page.delete page_number
      page = SourceDocumentPage.new(document: self,
                                    page_number:,
                                    raw_text:)
      parsed_pages[page_number] = page
    end

    def completed_initial_parsing? = completed_initial_parsing

    def process!
      return if completed_initial_parsing?

      parse_pages!

      apply_reflows!
      extract_notes!

      @completed_initial_parsing = true
    end

    def apply_reflows!
      redactions_by_page('reflows').each do |page_number, reflows|
        start_page, end_page = page_number.split '-'

        if end_page.nil?
          annotation = Annotation.new(raw_text_by_page[page_number],
                                      annotations: reflows)
          raw_text_by_page[page_number] = annotation.text
        else
          # Handle cross-page reflows by 'moving' the whole word to
          # `start_page`.
          reflows.each do |reflow|
            # @note Possible but unlikely that there will be more than one
            #   selector; deal with it if needed.
            head, tail = reflow['selectors'].first['exact'].split '- '
            raw_text_by_page[start_page].sub!(/#{head}\z/, reflow['value'])
            raw_text_by_page[end_page].sub!(/\A#{tail}/, '')
          end
        end
      end
    end

    def extract_notes!
      return if redactions['notes'].nil?

      redactions['notes'].each do |key, note_data|
        parsed = note_data.each_with_object({}) do |selector, memo|
          page_number = selector['page']&.to_s
          next if page_number.nil?

          page_text = raw_text_by_page[page_number]
          next if page_text.nil?

          transclusion = Transclusion.new(page_text,
                                          prefix: selector['prefix'],
                                          text_start: selector['textStart'],
                                          text_end: selector['textEnd'],
                                          suffix: selector['suffix'])
          begin
            text = transclusion.text
          rescue InvalidTransclusionError
            raise InvalidRedactionError, selector.inspect
          end

          memo[:symbol] ||= selector['prefix']
          (memo[:pages] ||= []) << page_number
          (memo[:text] ||= []) << text

          raw_text_by_page[page_number].sub!(text, '')
        end
        notes[key] = {
          pages: parsed[:pages].uniq,
          symbol: parsed[:symbol]&.strip,
          text: parsed[:text].join(' ').delete_prefix(parsed[:symbol]),
        }.freeze
      end
    end

    # @note If the `PAGE_NUMBER` capture group is merged into
    #   `PAGE_HEADER_PATTERN` the added capture group changes the output of
    #   `#split` by creating an extra array member for each page number. (For
    #   example, `[page 1]\n\ntest` would parse as `["[page 1]", "1", "test"]`
    #   instead of `["[page 1]", "test"]`.)
    PAGE_NUMBER = /\s(\w+)\]/
    PAGE_HEADER_PATTERN = /
      (\[
        (?:page|folio)
        \s\w+
      \])
    /x
    def parse_pages!
      # If `raw_text` is
      #
      #     [page 1]\n\nexample\n\n  another line\n\n[…]\n\n[page 2]\n\n  other text\n
      #
      # `raw_pages` will be
      #
      #     [
      #       "[page 1]",
      #       "example\n\n  another line",
      #       "[page 2]",
      #       "other text"
      #     ]
      raw_pages = raw_text.split(PAGE_HEADER_PATTERN)
                          .grep_v(/\A(\s+|\[…\])\z/)
                          .map(&:strip)

      raw_pages.each_with_index do |slice, index|
        page_header = slice.match(PAGE_HEADER_PATTERN)
        next if page_header.nil?

        page_number = slice.match(PAGE_NUMBER)[1]

        # `+ 1` uses the consistent structure to 'peek' at the page text. If
        # the current `slice` *isn't* followed by page text, the
        # `SourceDocumentPage` will have an empty string as its `raw_text`.
        #
        # This happens if:
        # * `slice` is the last element of `raw_pages`--that is, `raw_pages`
        #   ends with a page number (example: `"...\n\n[page 5]\n"`)
        # * the page text is blank (example: `"[page 1]\n\n[page 2] ..."`)
        text = raw_pages[index + 1]
        text = nil if PAGE_HEADER_PATTERN.match?(text)
        next if text.nil?

        sanitized = text.tr("\n", ' ')
                        .gsub(/\s{2,}/, ' ')
        raw_text_by_page[page_number] = sanitized
      end
    end

    # Rewrite `key` redactions from an array to a hash that's keyed by page
    # number. This makes it easy to find the redactions that are relevant for
    # a given page number.
    def redactions_by_page(key)
      return {} if redactions[key].nil?

      redactions[key].each_with_object({}) do |reflow, memo|
        reflow['selectors'].each do |selector|
          page_number = selector['page']
          next if page_number.nil?

          (memo[page_number] ||= []) << {
            'value' => reflow['value'],
            'selectors' => [{
              'prefix' => selector['prefix'],
              'exact' => selector['exact'],
              'suffix' => selector['suffix'],
            }],
          }.compact.freeze
        end
      end
    end
  end
end
