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

require "jekyll"
require_relative "utilities"

module HistoricalDiary
  module JekyllLayer
    class PersonDrop < Jekyll::Drops::Drop
      include Jekyll::Filters::URLFilters
      include Utilities

      mutable false

      def initialize(identifier, context:)
        @identifier = identifier

        @context = context
        @site = context.registers[:site]

        super record
      end

      def record
        site_object.data["people"].fetch(key)
      rescue KeyError
        Jekyll.logger.error "PersonDrop:", "'#{key}' doesn't match any records"
        {}
      end
      alias_method :fallback_data, :record
      private :record

      def dig(*args)
        record.dig(*args)
      end

      def living_years
        anchors = %w[
          birth_date
          death_date
        ].map do |key|
          record[key]&.split("-")&.first&.to_i
        end
        return [] if anchors.compact.length != 2

        (anchors.first..anchors.last).to_a
      end

      # This extracts word-initial characters in an internationalized, RTL-safe
      # way, using `#unicode_normalize` and `#each_grapheme_cluster`.
      #
      # Examples:
      #   "test" => "t"
      #   "Test Abc" => "TA"
      #   "חַנִּיאֵל" => "חַ"
      def name_initials(maximum_characters = 2)
        record["presentational_name"]
          values.
          map { |word| word.unicode_normalize(:nfc).grapheme_clusters.first }.
          first(maximum_characters).
          join("")
      end

      def permalink
        key = record["person_key"] || identifier
        relative_url("people/#{sanitize_key(key.downcase)}.html")
      end

      # @note This returns the name in the order the parts are written in the
      #   data file--if data is ordered with `familyName` before `givenName`,
      #   the output will also have `familyName` first. This helps a bit with
      #   internationalization, as some cultures (like Chinese and Hungarian)
      #   prefer the family name first, and others (like Australian and Spanish)
      #   prefer the given name first. It's not a substitute for proper
      #   internationalization support, though.
      def presentational_name
        record["presentational_name"]&.
          values&.
          join(" ")
      end

      private
        attr_reader :identifier

        def key
          sanitize_key(identifier)
        end
    end
  end
end
