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
  # Rewrite `text` using one or more annotation hashes.
  #
  # An annotation takes the form
  #
  # ```ruby
  # {
  #   value: "Gelderland"
  #   selectors: [{
  #     prefix: "Wessell in "
  #     exact: "Gel- derland"
  #     suffix: "."
  #   }]
  # }
  # ```
  #
  # This example would find the string `"Wessell in Gel- derland."` (where the
  # `" "` after `"-"` is a literal space or a newline) and replace
  # `"Gel- derland"` with `"Gelderland"`.
  #
  # Notes:
  # * The annotation is applied as many times as it matches.
  # * Annotations are applied in the order they’re declared.
  # * `prefix` and `suffix` are optional, and are useful to disambiguate
  #   multiple matches.
  # * `exact` can be an arbitrary value, including HTML.
  # * `value` can use the `\1` regular expression backreference to use `exact`’s
  #   text.
  class Annotation
    def initialize(text, annotations: [])
      raise ArgumentError unless text.is_a? String

      @annotations = annotations
      @text = text.dup
      @processed = false
    end

    def text
      return @text if processed?

      parsed_annotations.each do |pattern, replacement|
        next if pattern.nil? || replacement.nil?

        @text.gsub! pattern, replacement
      end
      @processed = true

      @text
    end

    private

    attr_reader :annotations

    def processed? = @processed

    def pattern(selector)
      prefix = Regexp.escape(selector['prefix']) if selector['prefix']
      suffix = Regexp.escape(selector['suffix']) if selector['suffix']
      [
        prefix,
        "(#{Regexp.escape(selector['exact'])})",
        suffix,
      ].compact.join
    end

    def replacement(selector, exact_replacement)
      [
        selector['prefix'],
        exact_replacement,
        selector['suffix'],
      ].compact.join.strip
    end

    def parsed_annotations
      return [] if annotations.nil?

      annotations.flat_map do |annotation|
        exact_replacement = annotation['value']
        next if exact_replacement.nil?
        next if annotation['selectors'].nil?

        annotation['selectors'].map do |selector|
          next if selector['exact'].nil? || selector['exact'] == ''

          [
            /#{pattern(selector)}/,
            replacement(selector, exact_replacement),
          ].freeze
        end
      end
    end
  end
end
