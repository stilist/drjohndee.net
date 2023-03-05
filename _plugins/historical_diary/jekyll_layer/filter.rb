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

      def data_record_link(key, display_text: nil)
        attributes = data_record_tag_attributes(key, data_type: drop_class::PLURAL_NOUN)

        <<~HTML
          <a
            href="#{data_record_url(key)}"
            class="#{attributes['class']}"
            data-key="#{attributes['dataKey']}">#{display_text || key}</a>
        HTML
      end

      def data_record_reference(key, display_text: nil)
        attributes = data_record_tag_attributes(key, data_type: drop_class::PLURAL_NOUN)

        <<~HTML
          <span
            class="#{attributes['class']}"
            data-key="#{attributes['dataKey']}">#{display_text || key}</span>
        HTML
      end

      def data_record_tag_attributes(key, data_type:)
        {
          "class" => "data-entity data-#{data_type}",
          "dataKey" => "#{data_type}/#{sanitize_key(key)}",
        }.freeze
      end

      def data_record_url(key) = drop(key).permalink

      def drop(key)
        DROPS[key] ||= drop_class.new(key, context: @context)
      end
    end
  end
end
