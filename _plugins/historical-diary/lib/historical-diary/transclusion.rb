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

require 'cgi'

module HistoricalDiary
  class InvalidTransclusionError < ArgumentError; end

  # Select a substring from `full_text`, using selectors to locate the
  # substring.

  # Based on the  W3C's draft specification for Text Fragments. If the string
  # doesn't contain the given Text Fragment methods will raise
  # `InvalidTransclusionError`.
  class Transclusion
    def initialize(full_text, text_start:, text_end:, prefix: nil, suffix: nil)
      raise ArgumentError unless full_text.is_a?(String)

      @prefix = prefix
      @text_start = text_start
      @text_end = text_end
      @suffix = suffix
      @text = full_text.dup.strip
    end

    def text
      validate!

      extract
    end

    # Build a transclusion URL fragment.
    #
    # Syntax: `:~:text=[prefix-,]text_start[,text_end][,-suffix]`
    #
    # @see https://wicg.github.io/scroll-to-text-fragment/#syntax
    def fragment
      validate!

      parts = [
        text_start.first(EXACT_CUTOFF),
        text_end,
      ]
      parts.unshift("#{prefix}-") unless prefix.nil?
      parts.shift("-#{suffix}") unless suffix.nil?

      encoded = parts.compact.map { CGI.escape _1 }
                     .join ','
      ":~:text=#{encoded}"
    end

    # > Text snippets shorter than 300 characters are encouraged to be encoded
    # > using an exact match.
    #
    # @see https://wicg.github.io/scroll-to-text-fragment/#prefer-exact-matching-to-range-based
    EXACT_CUTOFF = 300

    private

    attr_reader :text_start,
                :text_end,
                :location,
                :prefix,
                :suffix

    def validate!
      @valid = !extract.nil? if @valid.nil?

      raise InvalidTransclusionError unless @valid
    end

    def extract
      return @extract if defined?(@extract)

      @extract = nil
      return if @text.nil?
      return if @text.strip == ''

      @extract = @text.match(pattern)&.to_s
    end

    def pattern
      pattern_parts = [
        Regexp.escape(text_start),
      ]
      unless text_end.nil?
        pattern_parts << '.*?'
        pattern_parts << Regexp.escape(text_end)
      end
      pattern_parts.unshift(Regexp.escape(prefix)) unless prefix.nil?
      pattern_parts << Regexp.escape(suffix) unless suffix.nil?

      /#{pattern_parts.compact.join}/m
    end
  end
end
