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

require 'forwardable'
require_relative '../source_document'
require_relative '../transclusion'

module HistoricalDiary
  module SourceDocuments
    # Extract notes from `document`’s text, rewriting pages to remove the note
    # text.
    #
    # @note This class should be run after `Reflows`, because notes may have
    # reflows.
    class NoteExtractor
      extend Forwardable
      def_delegators :document,
                     :pages,
                     :redactions

      def initialize(document)
        @document = document
        @notes = {}
      end

      def notes
        return @notes if @notes.any?

        extract_and_rewrite!
      end

      private

      attr_reader :document

      def extract_and_rewrite!
        return if redactions['notes'].nil?

        redactions['notes'].each do |key, selectors|
          parsed = selectors.each_with_object({}) do |selector, memo|
            page_number = selector['page']&.to_s
            next memo if page_number.nil?

            page_text = pages[page_number]
            next memo if page_text.nil?

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

            pages[page_number] = pages[page_number].sub(/^\s*#{Regexp.escape(text)}\n?/, '')
          end

          next if parsed.empty?

          notes[key] = {
            pages: parsed[:pages].uniq,
            symbol: parsed[:symbol]&.strip,
            text: parsed[:text].join(' ').delete_prefix(parsed[:symbol]),
          }
        end
      end
    end
  end
end
