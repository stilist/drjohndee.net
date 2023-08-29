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
      # This module works together with <tt>DataPageGenerator</tt> to create a
      # Jekyll Page for a given Data File. It requires the same `#drop_class`
      # definition as <tt>DataPageGenerator</tt>.
      #
      # @example
      #   class SourcePage
      #     include DataPage
      #
      #     def drop_class = SourceDrop
      #   end
      module DataPage
        include Site

        def initialize(site, key)
          @key = key
          @site = site

          set_instance_variables
          set_up_data

          Jekyll.logger.debug self.class.name do
            "Generating #{drop_class::SINGULAR_NOUN} page at '#{@dir}/#{@name}'"
          end
        end

        def url_placeholders
          {
            path: @dir,
            basename:,
            output_ext:,
          }
        end

        def inspect = super.sub(/(>)/, " @key=#{key.inspect}\\1")

        protected

        attr_reader :key

        def method_missing(name)
          return unless REQUIRED_METHODS.include? name

          raise NotImplementedError,
                "#{self.class.name} must define a ##{name} method"
        end

        def respond_to_missing?(name, *) = REQUIRED_METHODS.include?(name)

        private

        REQUIRED_METHODS = %i[
          drop_class
        ].freeze

        def drop
          return @drop if defined?(@drop)

          context = context_from_site @site
          @drop = drop_class.new(key, context:)
        end

        def set_instance_variables
          @base = site.source
          @dir  = drop.dirname

          @basename = drop.basename
          @ext      = '.html'
          @name     = "#{@basename}#{@ext}"
        end

        def set_up_data
          @data = drop.page_data['custom_metadata']
                      .merge standard_metadata

          data.default_proc = proc do |_, key|
            site.frontmatter_defaults.find relative_path,
                                           drop_class::PLURAL_NOUN,
                                           key
          end
        end

        def standard_metadata
          {
            'is_generated' => true,
            'title' => drop['presentational_name'],
            drop_class::DATA_KEY => drop.preferred_key,
          }.freeze
        end
      end
    end
  end
end
