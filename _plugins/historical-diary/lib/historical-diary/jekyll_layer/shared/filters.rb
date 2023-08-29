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
      # Convenience wrapper for building HTML microdata based on a
      # <tt>Drop</tt>.
      #
      # @example
      #   module PlaceFilters
      #     include Shared::Filters
      #
      #     # ...
      #   end
      module Filters
        include Attributes
        include UncategorizedHelpers

        protected

        # Wrapper around a `drop_class` Drop for a single record.
        def filter_drop(key, drop_class:)
          shared_cache.getset "#{drop_class.name}/#{key}" do
            drop_class.new key, context: @context
          end
        end

        def data_record_link(key, drop_class:, display_content: nil, itemprop: nil)
          attributes = data_record_tag_attributes(key,
                                                  data_type: drop_class::PLURAL_NOUN,
                                                  drop_class:)
          extra_attributes = attributes.except 'default_text'
          content = display_content || attributes['default_text']

          link = <<~HTML
            <a #{hash_to_attributes extra_attributes}
              href="#{data_record_url(key, drop_class:)}"
              itemprop="url">#{content}</a>
          HTML

          data_record_microdata key,
                                display_content: link.strip,
                                drop_class:,
                                itemprop:
        end

        # Build a chunk of HTML microdata for a record. Use `display_content`
        # and `extra_attributes` for more control over the output.
        def data_record_microdata(key, drop_class:, itemprop:, display_content: nil, extra_attributes: {})
          microdata = filter_drop(key, drop_class:).microdata
          outer = microdata.except('meta').merge extra_attributes

          [
            "<span itemprop='#{itemprop}' #{hash_to_attributes outer}>",
            serialize_metadata(microdata['meta']),
            display_content,
            '</span>',
          ].join
        end

        # Wrapper around <tt>#data_record_microdata</tt> that automatically
        # merges in <tt>#data_record_tag_attributes</tt>.
        def data_record_reference(key, drop_class:, display_content: nil, itemprop: nil)
          attributes = data_record_tag_attributes(key,
                                                  data_type: drop_class::PLURAL_NOUN,
                                                  drop_class:)
          extra_attributes = attributes.except 'default_text'
          content = display_content || attributes['default_text']

          data_record_microdata key,
                                display_content: content,
                                drop_class:,
                                extra_attributes:,
                                itemprop:
        end

        private

        # Build a <tt>Hash</tt> of HTML attributes for a given record.
        def data_record_tag_attributes(key, data_type:, drop_class:)
          drop = filter_drop(key, drop_class:)

          {
            'class' => "data-entity data-#{data_type}",
            'data-key' => "#{data_type}/#{sanitize_key key}",
            'default_text' => drop['presentational_name'],
            'lang' => drop.language,
          }.compact
        end

        def data_record_url(key, drop_class:)
          filter_drop(key, drop_class:).permalink
        end

        # Convert a <tt>Hash</tt> into HTML microdata in a `<meta>` tag.
        def serialize_metadata(metadata)
          return '' if metadata.nil?

          metadata.compact
                  .map { |key, value| "<meta itemprop='#{key}' content='#{value}'>" }
                  .join
        end
      end
    end
  end
end
