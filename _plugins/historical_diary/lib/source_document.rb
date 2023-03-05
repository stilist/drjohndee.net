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
  # A collection of <tt>SourceDocumentPage</tt>s, representing a source such as
  # a book or manuscript.
  #
  # An identifier has a 'source key' and 'edition key', and optionally a 'volume
  # key'; the keys are combined into a string separated by `", "`. For example,
  # in the identifier `"Brief Lives, clarendon"`, the source key is `"Brief
  # Lives` and the edition key is `clarendon`. The source key should match a
  # Jekyll Data File that provides metadata about the source. (For example,
  # `_data/sources/Brief Lives.yaml`.)
  #
  # This class is completely independent of Jekyll, and doesn't internally use
  # the identifier to retrieve data, but other classes may use the parsed
  # identifier for that purpose.
  class SourceDocument
    attr_reader :edition_key,
                :identifier,
                :pages,
                :source_key,
                :volume_key

    class << self
      # Parse a comma-separated identifier into keys for source, edition, and
      # volume.
      #
      # @example
      #   parse_identifier("Local Gleanings")
      #   #=> ["Local Gleanings"]
      #   parse_identifier("Brief Lives, clarendon")
      #   #=> ["Brief Lives", "clarendon"]
      #   parse_identifier("Annals of the Reformation and Establishment of Religion, clarendon, II-I")
      #   #=> ["Annals of the Reformation and Establishment of Religion", "clarendon", "II-I"]
      def parse_identifier(identifier) = identifier.split(', ')

      def build_identifier(source_key, edition_key, volume_key)
        [
          source_key,
          edition_key,
          volume_key,
        ].compact.join ', '
      end

      # @todo handle iteration for folio, Roman numerals, etc
      def page_range(requested)
        case requested
        when Integer then [requested.to_s]
        when String
          parts = requested.split('-')
          (parts.first..parts.last)
        when Array, Range then requested
        else
          raise ArgumentError, 'Must specify at least one page number'
        end
      end
    end

    def initialize(identifier, raw_text:, redactions: nil)
      @identifier = identifier
      @source_key, @edition_key, @volume_key = self.class.parse_identifier identifier

      @raw_text = raw_text
      @redactions = redactions

      # state
      @notes = {}
      @pages = {}
      @processed = false
      @raw_page_text = {}
    end

    def redactions = @redactions || DEFAULT_REDACTIONS

    def page_numbers
      process!

      pages.keys
    end

    def [](requested)
      process!

      range = self.class.page_range(requested)
      range.map { |page_number| page(page_number) }
    rescue KeyError => e
      missing_page = e.message.match(/:\s"?(\d+)"?/)
      raise ArgumentError, "The raw source for '#{identifier}' doesn't include page #{missing_page[1]}"
    end

    def notes_for_page(page_number) = notes[page_number]

    private

    attr_reader :notes,
                :raw_page_text,
                :raw_text

    DEFAULT_REDACTIONS = {
      'chunks' => nil,
      'notes' => nil,
      'reflows' => nil,
    }.freeze

    def page(page_number)
      return pages[page_number] if pages.key?(page_number)

      raw_text = raw_page_text.fetch(page_number, '')
      page = SourceDocumentPage.new(document: self,
                                    page_number: page_number,
                                    raw_text: raw_text)
      raw_page_text.delete page_number

      pages[page_number] = page
    end

    def processed? = @processed

    PAGE_PATTERN = /\s(\w+)\]/
    PAGE_HEADER_PATTERN = /(\[page\s\w+\])/
    def process!
      return if processed?

      extract_pages!
      extract_notes!

      @processed = true
    end

    NOTE_KEY_PATTERN = /\A(\w+)-(.+)\z/
    def extract_notes!
      return if redactions['notes'].nil?

      redactions['notes'].each do |key, note_data|
        parsed = note_data.each_with_object({}) do |selector, memo|
          page_number = selector['page']&.to_s
          next if page_number.nil?

          page_text = raw_page_text[page_number]
          next if page_text.nil?

          transclusion = Transclusion.new(page_text,
                                          prefix: selector['prefix'],
                                          text_start: selector['textStart'],
                                          text_end: selector['textEnd'],
                                          suffix: selector['suffix'])
          text = transclusion.text

          memo[:symbol] ||= selector['prefix']
          (memo[:pages] ||= []) << page_number
          (memo[:text] ||= []) << text

          raw_page_text[page_number].sub!(text, '')
        end
        notes[key] = {
          pages: parsed[:pages].uniq,
          symbol: parsed[:symbol]&.strip,
          text: parsed[:text].join(' ').delete_prefix(parsed[:symbol]),
        }.freeze
      end
    end

    def extract_pages!
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

        page_number = slice.match(PAGE_PATTERN)[1]

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

        sanitized = text
          .tr("\n", ' ')
          .gsub(/\s{2,}/, ' ')
        raw_page_text[page_number] = sanitized
      end
    end
  end
end
