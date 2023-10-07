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
    # Adds a `{% commentary %}` Liquid block.
    #
    # @example
    #   {% commentary author_key="Cole, Jordan" %}
    #     Commentary HTML...
    #   {% endcommentary %}
    class CommentaryBlock < Liquid::Block
      include Shared::Attributes
      include Shared::Config
      include Shared::Site

      def initialize(_, block_arguments, _)
        super

        @raw_attributes = block_arguments
      end

      # rubocop:disable Metric/MethodLength
      def render(context)
        @context = context
        @commentary = super.dup.strip

        attributes = attributes_to_hash @raw_attributes

        lang = attributes['language'] || config(:lang)

        author_key = attributes['author_key']
        citation_input = "{{ \"#{author_key}\" | person_link }}"
        citation = liquify_string citation_input, context

        <<~HTML
          <figure
            itemscope
            itemtype="https://schema.org/Comment"
          >
            <div
              itemprop="text"
              lang="#{lang}">
              #{commentary}
            </div>
            <figcaption>
              — <span
                itemscope
                itemprop="author"
                itemtype="https://schema.org/Person"
                >#{citation}</span>
            </figcaption>
          </figure>
        HTML
      end
      # rubocop:enable Metric/MethodLength

      attr_reader :commentary
    end
  end
end
Liquid::Template.register_tag 'commentary',
                              HistoricalDiary::JekyllLayer::CommentaryBlock
