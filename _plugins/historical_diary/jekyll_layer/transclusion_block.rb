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

require_relative 'transclusion_liquid_helpers'

module HistoricalDiary
  module JekyllLayer
    # Adds a `{% transclusion_with_commentary %}` Liquid block.
    #
    # @example
    #   {% transclusion_with_commentary
    #      source_key="John Dee (1527-1608)"
    #      edition_key="book"
    #      page="30-31"
    #   %}
    #   Commentary...
    #   {% endtransclusion_with_commentary %}
    class TransclusionBlock < Liquid::Block
      include TransclusionLiquidHelpers

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

      attr_reader :commentary
      alias fallback_html commentary
    end
  end
end
Liquid::Template.register_tag 'transclusion_with_commentary',
                              HistoricalDiary::JekyllLayer::TransclusionBlock
