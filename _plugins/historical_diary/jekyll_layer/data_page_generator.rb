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

require_relative "utilities"

module HistoricalDiary
  module JekyllLayer
    module DataPageGenerator
      include Utilities

      def generate site
        @site = site

        site.data[drop_class::PLURAL_NOUN].each do |key, data|
          site.pages << page_class.new(site, data[drop_class::DATA_KEY] || key)
        end
      end

      protected
        def method_missing name
          if REQUIRED_METHODS.include?(name)
            raise NotImplementedError,
              "#{self.class.name} must define a ##{name} method"
          end
        end

      private
        REQUIRED_METHODS = %i[
          drop_class
          page_class
        ]
    end

    module DataPage
      include Utilities

      def initialize site, key
        @key = key

        @site = site
        @base = site.source
        @dir  = drop.dirname

        @basename = drop.basename
        @ext      = ".html"
        @name     = "#{@basename}#{@ext}"

        Jekyll.logger.debug "DataPage:", "Generating " \
          "#{drop_class::SINGULAR_NOUN} page at '#{@dir}/#{@name}'"

        layout_directory = File.join @base, "_layouts"
        read_yaml layout_directory, "#{drop.layout}.html"

        @data = drop.page_data["custom_metadata"].merge({
          "is_generated" => true,
          drop_class::DATA_KEY => drop.preferred_key,
          "title" => drop.presentational_name,
        })

        data.default_proc = proc do |_, key|
          site.frontmatter_defaults.find relative_path, :people, key
        end
      end

      def url_placeholders
        {
          :path       => @dir,
          :basename   => basename,
          :output_ext => output_ext,
        }
      end

      def inspect = super.sub(/(>)/, " @key=#{key.inspect}\\1")

      protected
        attr_reader :key

        def method_missing name
          if REQUIRED_METHODS.include?(name)
            raise NotImplementedError,
              "#{self.class.name} must define a ##{name} method"
          end
        end

      private
        REQUIRED_METHODS = %i[
          drop_class
          page_class
        ]

        def drop
          return @drop if defined?(@drop)
          @drop = nil

          context = context_from_site @site
          @drop = drop_class.new key, context: context
        end
    end
  end
end
