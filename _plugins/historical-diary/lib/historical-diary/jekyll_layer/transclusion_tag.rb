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
    # Adds a `{% transclusion %}` Liquid block that transcludes text (with
    # redactions) from a source document.
    #
    # Example with only required arguments
    # ```
    # {% transclusion
    #    source_key="The Private Diary of Dr John Dee"
    #    edition_key="book"
    #    page="1"
    #    text_start="Aug. 25th,"
    #    text_end="circumstances."
    # %}
    # ```
    #
    # Example with optional arguments
    # ```
    # {% transclusion
    #   source_key="The Private Diary of Dr John Dee"
    #   edition_key="book"
    #   volume_key="I"
    #   footnotes="1-*"
    #   language="en-emodeng"
    #   page="1"
    #   prefix="1554. "
    #   suffix=" Oct. 25th"
    #   text_start="Aug. 25th,"
    #   text_end="circumstances."
    # %}
    # ```
    class TransclusionTag < Liquid::Tag
      include Shared::TransclusionLiquidHelpers

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
