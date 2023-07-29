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
      module TransclusionLiquidHelpers
        include Attributes

        protected

        def attributes
          @attributes ||= attributes_to_hash @raw_attributes
        end

        def page_html
          return @page_html if defined? @page_html

          if page_text.nil?
            @page_html = if respond_to? :fallback_html
                           "#{fallback_html}\n\n#{fallback_html_comment}"
                         else
                           fallback_html_comment
                         end
            return @page_html
          end

          # @todo Cache the rest of this based on `#cache_key_from_attributes`,
          #   `lang` and `page_text`.
          lang = attributes['language'] || source_drop.language
          with_paragraphs = page_text.gsub(/\n{2,}/, "</p>\n<p>")

          citation_input = "{{ \"#{transclusion_source_key}\" | source_citation: \"#{attributes['page']}\" }}"
          citation = liquify_string citation_input, @context

          <<~HTML
            <figure
              itemscope
              itemtype="https://schema.org/Quotation">
              <blockquote
                class="source-material e-content"
                itemprop="text"
                lang="#{lang}"
              >
                <p>#{with_paragraphs}</p>
              </blockquote>

              <figcaption itemprop="citation">#{citation}</figcaption>
            </figure>
          HTML
        end

        private

        def cache_key_from_attributes
          return @cache_key_from_attributes if defined? @cache_key_from_attributes

          cache_key_parts = %w[
            page
            prefix
            text_start
            text_end
            suffix
          ]
          @cache_key_from_attributes = attributes.slice(*cache_key_parts)
                                                 .values
                                                 .compact
                                                 .join('//')
        end

        # Get transcluded text for provided attributes.
        def page_text
          return '' if attributes['page'].nil?

          shared_cache.getset cache_key_from_attributes do
            candidate_text = source_drop.page(attributes['page'])
                                        .map(&:text)
                                        .join("\n")

            transclusion = Transclusion.new candidate_text,
                                            prefix: attributes['prefix'],
                                            text_start: attributes['text_start'],
                                            text_end: attributes['text_end'],
                                            suffix: attributes['suffix']
            as_html = apply_markup transclusion.text
            Liquid::Template.parse(as_html).render @context
          end
        rescue InvalidTransclusionError
          shared_cache.getset cache_key_from_attributes do
            Jekyll.logger.warn self.class.name do
              "Transclusion doesn't match anything: #{attributes.inspect}"
            end

            nil
          end
        end

        def apply_markup(text)
          range = SourceDocument.page_range attributes['page']

          cache_key = [
            range,
            text,
          ].join '//'

          shared_cache.getset cache_key do
            annotations = range.flat_map do |page_number|
              source_drop.markup_redactions_for_page page_number
            end

            Annotation.new(text, annotations: annotations.compact).text
          end
        end

        def fallback_html_comment
          tidied_attributes = @raw_attributes.strip.gsub(/\s{2,}/, "\n")
          <<~HTML
            <!--
            Provided transclude doesn't match anything:

            #{tidied_attributes}
            -->
          HTML
        end

        def transclusion_source_key
          SourceDocument.build_identifier attributes['source_key'],
                                          attributes['edition_key'],
                                          attributes['volume_key']
        end

        def source_drop
          shared_cache.getset transclusion_source_key do
            SourceDrop.new transclusion_source_key, context: @context
          end
        end
      end
    end
  end
end
