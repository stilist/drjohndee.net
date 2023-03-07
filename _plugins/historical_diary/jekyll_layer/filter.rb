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

require_relative 'utilities'

module HistoricalDiary
  module JekyllLayer
    module Filter
      include Utilities

      DROPS = {}

      protected

      def data_record_link(key, drop_class:, display_content: nil)
        attributes = data_record_tag_attributes(key,
                                                data_type: drop_class::PLURAL_NOUN,
                                                drop_class: drop_class)
        default_text = attributes.delete 'default_text'
        content = display_content || default_text

        html = attributes.map { |key, value| "#{key}=\"#{value}\"" }
                         .join ' '

        <<~HTML
          <a #{html}
            href="#{data_record_url(key, drop_class: drop_class)}">#{content}</a>
        HTML
      end

      def data_record_reference(key, drop_class:, display_content: nil)
        attributes = data_record_tag_attributes(key,
                                                data_type: drop_class::PLURAL_NOUN,
                                                drop_class: drop_class)
        default_text = attributes.delete 'default_text'
        content = display_content || default_text

        html = attributes.map { |key, value| "#{key}=\"#{value}\"" }
                         .join ' '

        <<~HTML
          <span #{html}>#{content}</span>
        HTML
      end

      def data_record_tag_attributes(key, data_type:, drop_class:)
        {
          "class" => "data-entity data-#{data_type}",
          "data-key" => "#{data_type}/#{sanitize_key(key)}",
          "default_text" => drop(key, drop_class: drop_class).presentational_name,
          "lang" => drop(key, drop_class: drop_class).language,
        }.compact
      end

      def data_record_url(key, drop_class:)
        drop(key, drop_class: drop_class).permalink
      end

      def drop(key, drop_class:)
        cache_key = "#{drop_class.name}/#{key}"
        DROPS[cache_key] ||= drop_class.new(key, context: @context)
      end
    end
  end
end
