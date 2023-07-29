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
  module JekyllLayer
    module Shared
      module Attributes
        include UncategorizedHelpers

        # Parse basic key-value pairs in the form of `key="value"`. Useful for
        # custom Liquid blocks and tags.
        ATTRIBUTE_PATTERN = /(\w+)="(.+?)"/
        private_constant :ATTRIBUTE_PATTERN
        def attributes_to_hash(attributes)
          shared_cache.getset attributes do
            matches = @raw_attributes.scan ATTRIBUTE_PATTERN
            @parsed_attributes = matches.each_with_object({}) do |match, memo|
              key, value = match
              memo[key] = value
            end
          end
        end

        def hash_to_attributes(hash)
          mapped = hash.map do |key, value|
            next key if value.nil?
            next unless numeric?(value) || value.is_a?(String)

            "#{key}=\"#{value}\""
          end

          mapped.join ' '
        end
      end
    end
  end
end
