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
  class InvalidTransclusionError < ArgumentError; end

  # Select a substring from `full_text`, using selectors to locate the
  # substring.
  #
  # Based on the  W3C’s draft specification for Text Fragments. If the string
  # doesn’t contain the given Text Fragment methods will raise
  # `InvalidTransclusionError`.
  #
  # @note This normalizes `full_text` and all selectors to Unicode NFC.
  class Transclusion
    def initialize(full_text, text_start:, text_end:, prefix: nil, suffix: nil)
      raise InvalidTransclusionError, 'full_text must be a string' unless full_text.is_a?(String)
      raise InvalidTransclusionError, 'text_start must be a string' unless text_start.is_a?(String)

      @prefix = sanitize_for_regexp(prefix)
      @text_start = sanitize_for_regexp(text_start)
      @text_end = sanitize_for_regexp(text_end)
      @suffix = sanitize_for_regexp(suffix)
      @text = normalize(full_text)
    end

    def text
      validate!

      extract
    end

    private

    attr_reader :text_start,
                :text_end,
                :location,
                :prefix,
                :suffix

    def normalize(text)
      text.dup.strip.unicode_normalize(:nfc)
    rescue ArgumentError
      raise InvalidTransclusionError, 'Invalid UTF-8'
    end

    def validate!
      @valid = !extract.nil? if @valid.nil?

      raise InvalidTransclusionError, 'pattern did not match text' unless @valid
    end

    def extract
      return @extract if defined?(@extract)

      @extract = nil
      return if @text.nil?

      match = @text.match(pattern)
      return if match.nil?

      @extract = match[:text]
    end

    def sanitize_for_regexp(text)
      return if text.nil?

      Regexp.escape(normalize(text))
    end

    def pattern
      text_pattern = text_start
      text_pattern << ".*?#{text_end}" unless text_end.nil?

      pattern_parts = "(?<text>#{text_pattern})"

      pattern_parts.prepend("#{prefix}\\p{Space}*") unless prefix.nil?
      pattern_parts << "\\p{Space}*#{suffix}" unless suffix.nil?

      /#{pattern_parts}/m
    end
  end
end
