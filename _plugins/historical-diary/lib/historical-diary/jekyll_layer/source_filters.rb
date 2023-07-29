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

require_relative 'shared'

module HistoricalDiary
  module JekyllLayer
    # Liquid filters for working with data from `sources` Data Files.
    module SourceFilters
      include Shared::Filters

      def source_citation(key, pages = nil)
        cache_key = "#{source_drop_class.name}/#{key}/#{pages}"
        shared_cache.getset cache_key do
          data = filter_drop(key, drop_class: source_drop_class).citation_data

          parts = []
          parts << "{{ \"#{data['author']}\" | person_link: \"#{data['author']}\", \"author\" }}" if data['author']
          parts << source_link(key)
          if data['editor']
            parts << "Edited by {{ \"#{data['editor']}\" | person_link: \"#{data['editor']}\", \"editor\" }}"
          end
          if data['publisher']
            # avoid output like "Monkey Publishing Ltd.."
            tidied = data['publisher'].delete_suffix '.'
            parts << "<span itemprop='publisher'>#{tidied}</span>"
          end
          parts << "<time itemprop='datePublished' datetime='#{data['date']}'>#{data['year']}</time>" if data['year']

          input = parts.join '. '
          without_pages = Liquid::Template.parse(input).render @context
          return without_pages if pages.nil?

          if /\w-\w/.match?(pages)
            word = 'pages'
            abbreviation = 'pp'
          else
            word = 'page'
            abbreviation = 'p'
          end

          [
            "#{without_pages},",
            "<abbr title='#{word}'>#{abbreviation}.</abbr>",
            "<span itemprop='pagination'>#{pages}</span>",
          ].join ' '
        end
      end

      def source_data(key) = filter_drop(key, drop_class: source_drop_class)

      def source_presentational_name(source_key, edition_key = nil, volume_key = nil)
        key = SourceDocument.build_identifier source_key, edition_key, volume_key
        filter_drop(key, drop_class: source_drop_class)['presentational_name']
      end

      def source_link(key, display_content = nil, itemprop = nil)
        data_record_link(key,
                         display_content:,
                         drop_class: source_drop_class,
                         itemprop:)
      end

      def source_reference(key, display_content = nil, itemprop = nil)
        data_record_reference(key,
                              display_content:,
                              drop_class: source_drop_class,
                              itemprop:)
      end

      def source_url(key) = data_record_url(key, drop_class: source_drop_class)

      private

      def source_drop_class = SourceDrop
    end
  end
end
Liquid::Template.register_filter HistoricalDiary::JekyllLayer::SourceFilters
