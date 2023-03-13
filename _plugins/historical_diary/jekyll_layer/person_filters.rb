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

      def tag_data(key) = drop(key, drop_class: person_drop_class)

      def person_content(key)
        drop(key, drop_class: person_drop_class).page_data['custom_content']
      end

      def person_initials(key, maximum_characters = 2)
        drop(key, drop_class: person_drop_class).name_initials maximum_characters
      end

      def person_living_years(key)
        drop(key, drop_class: person_drop_class).living_years
      end

      def person_presentational_name(key)
        drop(key, drop_class: person_drop_class).presentational_name
      end

      def person_full_name(key)
        drop(key, drop_class: person_drop_class)
          .fallback_data['full_name']
          &.map { |x| x['text'] }
          &.join(' ')
      end

      def person_full_name_differs_from_presentational_name(key)
        person_presentational_name(key) != person_full_name(key)
      end

      def person_avatar(key)
        data = person_drop_class.new(key, context: @context)

        content = <<~HTML
          <span class="person-avatarInitials"
                aria-hidden="true">#{person_initials(key)}</span>
          <span class="is-assistiveOnly">#{person_full_name(key)}</span>
        HTML

        if data.key?('full_name') then person_link(key, content)
        else person_reference(key, content)
        end
      end

      def person_link(key, display_content = nil)
        data_record_link(key,
                         display_content: display_content,
                         drop_class: person_drop_class)
      end

      def person_reference(key, display_content = nil)
        data_record_reference(key,
                              display_content: display_content,
                              drop_class: person_drop_class)
      end

      def person_microdata(key, itemprop)
        data_record_microdata(key,
                              drop_class: person_drop_class,
                              itemprop: itemprop)
      end

      def person_url(key) = data_record_url(key, drop_class: person_drop_class)

      def sort_people_keys(keys)
        return keys unless keys.is_a? Array

        keys.sort_by { |key| person_presentational_name(key) }
      end

      private

      def person_drop_class = PersonDrop
    end
  end
end
Liquid::Template.register_filter HistoricalDiary::JekyllLayer::PersonFilters
