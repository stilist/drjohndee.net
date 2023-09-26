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
    # Adds a `{% transclusion_with_commentary %}` Liquid block. The block takes
    # the same attributes as the `{% transclusion %}` Liquid tag; the
    # difference is the ability to provide commentary on the transclusion.
    #
    # @example
    #   {% transclusion_with_commentary
    #     source_key="The Private Diary of Dr John Dee"
    #     edition_key="book"
    #     footnotes="1-*"
    #     language="en-emodeng"
    #     page="1"
    #     text_start="Oct. 12th, the"
    #     text_end="derland."
    #   %}
    #     Commentary...
    #   {% endtransclusion_with_commentary %}
    class TransclusionBlock < Liquid::Block
      include Shared::TransclusionLiquidHelpers

      attr_reader :commentary
      alias fallback_html commentary

      def initialize(_, block_arguments, _)
        super

        @raw_attributes = block_arguments
      end

      def render(context)
        @context = context
        @commentary = super.dup.strip

        [
          page_html,
          commentary,
        ].compact.join "\n\n"
      end
    end
  end
end
Liquid::Template.register_tag 'transclusion_with_commentary',
                              HistoricalDiary::JekyllLayer::TransclusionBlock
