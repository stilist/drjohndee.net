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

require 'jekyll'
require_relative '../_lib/person'

module HistoricalDiary
  module PeopleFilters
    def person_initials(key, maximum_characters = 2)
      Person.new(key, @context.registers[:site]).name_initials(maximum_characters)
    end

    def person_name(key, name_key = 'presentational_name')
      Person.new(key, @context.registers[:site]).name_text(name_key)
    end

    def sorted_people_keys(keys)
      return keys if !keys.is_a?(Array)
      keys.sort_by { |key| person_name(key) }
    end
  end
end

Liquid::Template.register_filter(HistoricalDiary::PeopleFilters)
