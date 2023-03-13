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
        microdata = drop(key, drop_class: drop_class).microdata
                                                     .except('meta')
        with_microdata = attributes.merge(microdata)
        html = serialize_attributes(with_microdata)

        default_text = attributes.delete 'default_text'
        content = display_content || default_text

        <<~HTML
          <a #{html}
            href="#{data_record_url(key, drop_class: drop_class)}">#{content}</a>
        HTML
      end

      def data_record_microdata(key, drop_class:, itemprop:)
        microdata = drop(key, drop_class: drop_class).microdata
        outer = microdata.except('meta')

        <<~HTML
          <span
            itemprop="#{itemprop}"
            #{serialize_attributes(outer)}>
            #{serialize_microdata(microdata['meta'])}
          </span>
        HTML
      end

      def data_record_reference(key, drop_class:, display_content: nil)
        attributes = data_record_tag_attributes(key,
                                                data_type: drop_class::PLURAL_NOUN,
                                                drop_class: drop_class)
        microdata = drop(key, drop_class: drop_class).microdata
                                                     .except('meta')
        with_microdata = attributes.merge(microdata)
        html = serialize_attributes(with_microdata)

        default_text = attributes.delete 'default_text'
        content = display_content || default_text

        metadata = drop(key, drop_class: drop_class).microdata
                                                    .fetch('meta', [])
        meta_tags = serialize_microdata(metadata)
        "<span itemscope #{html}>#{meta_tags} #{content}</span>"
      end

      def data_record_tag_attributes(key, data_type:, drop_class:)
        {
          'class' => "data-entity data-#{data_type}",
          'data-key' => "#{data_type}/#{sanitize_key(key)}",
          'default_text' => drop(key, drop_class: drop_class).presentational_name,
          'lang' => drop(key, drop_class: drop_class).language,
        }.compact
      end

      def data_record_url(key, drop_class:)
        drop(key, drop_class: drop_class).permalink
      end

      def drop(key, drop_class:)
        cache_key = "#{drop_class.name}/#{key}"
        DROPS[cache_key] ||= drop_class.new(key, context: @context)
      end

      def serialize_attributes(attributes)
        mapped = attributes.map do |key, value|
          next key if value.nil?

          "#{key}=\"#{value}\""
        end

        mapped.join ' '
      end

      def serialize_microdata(microdata)
        microdata.compact
                 .map { |key, value| "<meta itemprop='#{key}' content='#{value}'>" }
                 .join
      end
    end
  end
end
