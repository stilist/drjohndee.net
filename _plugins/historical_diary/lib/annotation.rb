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
  class Annotation
    def initialize(text, annotations: {})
      raise ArgumentError unless text.is_a?(String)

      @annotations = annotations
      @text = text.dup
    end

    def text
      parsed_annotations.each do |pattern, replacement|
        @text.gsub! pattern, replacement
      end
    end

    private

    attr_reader :annotations

    def parsed_annotations
      annotations.flat_map do |annotation|
        exact_replacement = annotation['value']
        next if exact_replacement.nil?
        next if annotation['selectors'].nil?

        annotation['selectors'].map do |selector|
          next if selector['exact'].nil? || selector['exact'] == ''

          prefix = Regexp.escape(selector['prefix']) if selector['prefix']
          exact = "(#{Regexp.escape(selector['exact'])})"
          suffix = Regexp.escape(selector['suffix']) if selector['suffix']
          pattern = [
            prefix,
            exact,
            suffix,
          ].compact.join
          replacement = [
            selector['prefix'],
            exact_replacement,
            selector['suffix'],
          ].compact.join

          [
            /#{pattern}/,
            replacement,
          ]
        end
      end
    end
  end
end
