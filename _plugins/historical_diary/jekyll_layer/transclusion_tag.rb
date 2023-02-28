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
    # Adds a `{% transclusion %}` Liquid block.
    #
    # @example
    #   {% transclusion
    #      source_key="John Dee (1527-1608)"
    #      edition_key="book"
    #      page="30-31"
    #   %}
    class TransclusionTag < Liquid::Tag
      include TransclusionLiquidHelpers

      def initialize(_, block_arguments, _)
        super

        @raw_attributes = block_arguments
      end

      def render(context)
        @context = context

        page_html
      end
    end
  end
end
Liquid::Template.register_tag 'transclusion',
                              HistoricalDiary::JekyllLayer::TransclusionTag
