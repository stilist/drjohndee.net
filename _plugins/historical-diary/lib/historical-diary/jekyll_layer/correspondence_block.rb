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
    # Adds a `{% correspondence %}` Liquid block.
    #
    # @example
    #   {% correspondence
    #      author_key="Dee, John"
    #      recipient_key="Queen Elizabeth I"
    #   %}
    #     {% transclusion
    #       ...
    #     %}
    #   {% endcorrespondence %}
    class CorrespondenceBlock < Liquid::Block
      include Shared::Attributes
      include Shared::Config
      include Shared::Site

      def initialize(_, block_arguments, _)
        super

        @raw_attributes = block_arguments
      end

      def render(context)
        @context = context
        @correspondence_content = super.dup.strip

        page_html
      end

      attr_reader :context,
                  :correspondence_content

      private

      def attributes
        return @attributes if defined? @attributes

        @attributes = attributes_to_hash @raw_attributes
      end

      def page_html
        <<~HTML
          <div
            itemscope
            itemtype="https://schema.org/Message"
          >
            <dl>
              <dt>From</dt>
              <dd>
                #{person_link 'author_key', 'author'}
              </dd>
              <dt>To</dt>
              <dd>
                #{person_link 'recipient_key', 'recipient'}
              </dd>
            </dl>

            <div itemprop="text">
              #{correspondence_content}
            </div>
          </div>
        HTML
      end

      def person_link(attribute_name, itemprop)
        input = "{{ \"#{attributes[attribute_name]}\" | person_link: nil, \"#{itemprop}\" }}"
        # require 'byebug'
        # byebug
        liquify_string input, context
      end
    end
  end
end
Liquid::Template.register_tag 'correspondence',
                              HistoricalDiary::JekyllLayer::CorrespondenceBlock
