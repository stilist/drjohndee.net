# frozen_string_literal: true

# The life and times of Dr John Dee
# Copyright (C) 2021  Jordan Cole <feedback@drjohndee.net>
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

require_relative 'data_collection'

module HistoricalDiary
  class Person
    include DataCollection

    attr_reader :key

    def initialize(key, site)
      @key = key
      # needs to be defined for `DataCollection`
      @site = site
    end

    # This extracts word-initial characters in an internationalized, RTL-safe
    # way, using `#unicode_normalize` and `#each_grapheme_cluster`.
    #
    # Examples:
    #   "test" => "t"
    #   "Test Abc" => "TA"
    #   "חַנִּיאֵל" => "חַ"
    def name_initials(maximum_characters = 2)
      parts = if record.nil? then key.split(/[^[:alpha:]]+/)
              else record['presentational_name']&.values
              end
      return if parts.nil?

      parts.map { |word| word.unicode_normalize(:nfc).each_grapheme_cluster.first }
        .first(maximum_characters)
        .join('')
    end

    # @note This returns the name in the order the parts are written in the
    #   data file--if data is ordered with `familyName` before `givenName`,
    #   the output will also have `familyName` first. This helps a bit with
    #   internationalization, as some cultures (like Chinese and Hungarian)
    #   prefer the family name first, and others (like Australian and Spanish)
    #   prefer the given name first. It's not a substitute for proper
    #   internationalization support, though.
    def name_text(name_key = 'presentational_name')
      return '' if record.nil?

      parts = record[name_key]&.values
      return '' if parts.nil?

      parts.join(' ')
    end

    private

    def record
      person_data(key)
    end
  end
end
