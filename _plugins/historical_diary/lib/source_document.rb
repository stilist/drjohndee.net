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
      def parse_identifier(identifier) = identifier.split(", ")

      def build_identifier source_key, edition_key, volume_key
        [
          source_key,
          edition_key,
          volume_key,
        ].compact.join ", "
      end
    end

    def initialize identifier, raw_text:, redactions: nil
      @identifier = identifier
      @source_key, @edition_key, @volume_key = parse_identifier identifier

      @raw_text = raw_text
      @redactions = redactions

      # state
      @pages = {}
      @processed = false
    end

    def redactions = @redactions || DEFAULT_REDACTIONS

    def page_numbers
      process!

      pages.keys
    end

    def [](requested)
      process!

      # @todo handle preface page numbers like `vii`
      # @todo `requested` may be a quoted number (`"200"`)
      case requested
      when Integer then pages.fetch requested
      when Range then requested.map { |page_number| pages.fetch(page_number) }
      else raise ArgumentError, "Must specify at least one page number"
      end
    rescue KeyError => e
      missing_page = e.message.match /:\s(\d+)/
      raise ArgumentError, "The raw source for '#{identifier}' doesn't include page #{missing_page[1]}"
    end

    private
      attr_reader :raw_text

      DEFAULT_REDACTIONS = {
        "chunks" => nil,
        "notes" => nil,
        "reflows" => nil,
      }
      PAGE_PATTERN = /(\[page\s\d+\])/

      def processed? = @processed

      def process!
        return if processed?

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
        raw_pages = raw_text.split(PAGE_PATTERN).
          reject { |part| part =~ /\A(\s+|\[…\])\z/ }.
          map { |part| part.strip }
        raw_pages.each_with_index do |slice, index|
          if slice =~ PAGE_PATTERN
            page_number = slice.match(/\d+/).to_s.to_i

            # `+ 1` uses the consistent structure to 'peek' at the page text. If
            # the current `slice` *isn't* followed by page text, the
            # `SourceDocumentPage` will have an empty string as its `raw_text`.
            # This happens if:
            #
            # * `slice` is the last element of `raw_pages`--that is, `raw_pages`
            #   ends with a page number (example: `"...\n\n[page 5]\n"`)
            # * the page text is blank (example: `"[page 1]\n\n[page 2] ..."`)
            raw_page_text = raw_pages[index + 1]
            raw_page_text = nil if raw_page_text =~ PAGE_PATTERN

            page = SourceDocumentPage.new document: self,
                                          page_number: page_number,
                                          raw_text: raw_page_text || ""
            @pages[page_number] = page
          end
        end

        @pages

        @processed = true
      end
  end
end