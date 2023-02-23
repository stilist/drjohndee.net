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

require "forwardable"

module HistoricalDiary
  class Redactions
    attr_reader :notes

    def initialize text, redactions: {}
      raise ArgumentError if !text.is_a?(String)

      @redactions = redactions
      @text = text.dup

      @notes = {}
    end

    def text
      reflow!
      extract_notes!

      @text
    end

    private
      attr_reader :redactions

      REQUIRED_REFLOW_KEYS = %w[start end value]

      # @TODO
      def extract_notes!
        return if redactions["notes"].nil?
      end

      def reflow!
        @text.strip!
        @text.gsub! /\n/, " "
        @text.gsub! /\s{2,}/, " "

        return if redactions["reflows"].nil?

        if redactions["reflows"].is_a?(Array)
          return Annotation.new(@text, annotations: redactions["reflows"]).text
        end

        redactions["reflows"].each do |reflow|
          REQUIRED_REFLOW_KEYS.each do |key|
            raise ArgumentError, "Reflows must have a '#{key}'" if reflow[key].nil?
          end

          pattern_string = [
            Regexp.escape(reflow["start"]),
            ".*?",
            Regexp.escape(reflow["end"]),
          ].join ""
          pattern = /#{pattern_string}/m

          if pattern.match(text).nil?
            raise ArgumentError, "No match for #{pattern_string}"
          end

          text.sub! pattern, reflow["value"]
        end
      end
  end
end
