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
  module JekyllLayer
    module PersonFilters
      include Filter

      alias person_data drop

      def person_content(key) = drop(key).page_data['custom_content']

      def person_initials(key, maximum_characters = 2)
        drop(key).name_initials maximum_characters
      end

      def person_living_years(key) = drop(key).living_years

      def person_presentational_name(key) = drop(key).presentational_name

      def person_full_name(key)
        drop(key)
          .fallback_data['full_name']
          &.map { |x| x['text'] }
          &.join(' ')
      end

      def person_full_name_differs_from_presentational_name(key)
        person_presentational_name(key) != person_full_name(key)
      end

      def person_link(key, display_text)
        data_record_link(key, display_text: display_text)
      end

      def person_reference(key, display_text)
        data_record_reference(key, display_text: display_text)
      end

      def person_url(key) = data_record_url(key)

      def sort_people_keys(keys)
        return keys unless keys.is_a? Array

        keys.sort_by { |key| person_presentational_name(key) }
      end

      private

      def drop_class = PersonDrop
    end
  end
end
Liquid::Template.register_filter HistoricalDiary::JekyllLayer::PersonFilters
