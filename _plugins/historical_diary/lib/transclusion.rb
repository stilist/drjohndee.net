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

require 'cgi'

module HistoricalDiary
  class InvalidTransclusionError < ArgumentError; end

  # Use the W3C's draft specification for Text Fragments as a syntax to select
  # part of a string. If the string doesn't contain the given Text Fragment
  # methods will raise `InvalidTransclusionError`.
  #
  # @see https://wicg.github.io/scroll-to-text-fragment/
  class Transclusion
    def initialize(full_text, prefix: nil, textStart:, textEnd:, suffix: nil)
      raise ArgumentError unless full_text.is_a?(String)

      @prefix = prefix
      @textStart = textStart
      @textEnd = textEnd
      @suffix = suffix
      @text = full_text.dup.strip
    end

    def text
      validate!

      extract
    end

    # Syntax: `:~:text=[prefix-,]textStart[,textEnd][,-suffix]`
    #
    # @see https://wicg.github.io/scroll-to-text-fragment/#syntax
    def fragment
      validate!

      parts = [
        textStart.first(EXACT_CUTOFF),
        textEnd,
      ]
      parts.unshift("#{prefix}-") unless prefix.nil?
      parts.shift("-#{suffix}") unless suffix.nil?

      encoded = parts.compact
                     .map { |part| CGI.escape(part) }
                     .join ','
      ":~:text=#{encoded}"
    end

    # > Text snippets shorter than 300 characters are encouraged to be encoded
    # > using an exact match.
    #
    # @see https://wicg.github.io/scroll-to-text-fragment/#prefer-exact-matching-to-range-based
    EXACT_CUTOFF = 300

    private

    attr_reader :textStart,
                :textEnd,
                :location,
                :prefix,
                :suffix

    def validate!
      @valid = !extract.nil? if @valid.nil?

      raise InvalidTransclusionError unless @valid
    end

    def extract
      return @extract if defined?(@extract)

      pattern_parts = [
        textStart,
      ]
      unless textEnd.nil?
        pattern_parts << '.*?'
        pattern_parts << Regexp.escape(textEnd)
      end
      pattern_parts.unshift(Regexp.escape(prefix)) unless prefix.nil?
      pattern_parts << Regexp.escape(suffix) unless suffix.nil?

      pattern = /#{pattern_parts.compact.join}/m
      @extract = @text.match(pattern)&.to_s
    end
  end
end
