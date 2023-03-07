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
    module Drop
      include Jekyll::Filters::URLFilters
      include Utilities

      def initialize(identifier, context:)
        @identifier = identifier

        @context = context
        @site = context.registers[:site]

        super record
      end

      def record
        @record ||= data_for_type self.class::PLURAL_NOUN
      end
      alias fallback_data record
      protected :record

      def dig(*args) = record.dig(*args)

      def permalink = relative_url("#{dirname}/#{basename}.html")

      def preferred_key = record[data_key] || key

      def basename = sanitize_key(preferred_key)
      alias page_data_key basename
      private :page_data_key

      def page_data
        page = site_object.pages.find do |p|
          next if p.data['is_generated']

          sanitize_key(p.data[data_key]) == page_data_key
        end
        return DEFAULT_PAGE_DATA if page.nil?

        {
          'custom_content' => page.content,
          'custom_metadata' => page.data,
        }
      end

      def layout = self.class::SINGULAR_NOUN

      def dirname = self.class::PLURAL_NOUN

      def data_key
        @data_key ||= "#{self.class::SINGULAR_NOUN}_key"
      end

      def language = nil

      protected

      def data_for_type(type)
        default_data = {}

        if INVALID_KEYS.include? key
          Jekyll.logger.debug self.class.name do
            "Short-circuiting #{type} lookup on invalid key ('#{key.inspect}')"
          end
          return default_data
        end

        unless site_object.data.key?(type)
          Jekyll.logger.debug self.class.name do
            "Short-circuiting #{type} lookup--no data exists"
          end
          return default_data
        end

        redactions = site_object.data[type]
        Jekyll.logger.debug self.class.name do
          "Searching #{type} data for '#{key}'"
        end

        redactions.fetch(key)
      rescue KeyError
        indirect_record = redactions.values.find do |value|
          sanitize_key(value[data_key]) == key
        end

        if indirect_record.nil?
          Jekyll.logger.debug self.class.name do
            "No #{type} data for '#{key}'"
          end
        end

        indirect_record || default_data
      end

      def key
        @key ||= sanitize_key(identifier)
      end

      private

      attr_reader :identifier

      DEFAULT_PAGE_DATA = {
        'custom_content' => nil,
        'custom_metadata' => {},
      }.freeze

      INVALID_KEYS = [
        nil,
        '',
      ].freeze
    end
  end
end
