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
      # This module provides a brief way to generate Jekyll Pages for a given
      # collection of Data Files. It requires a <tt>Jekyll::Drop</tt>
      # subclassed from <tt>HistoricalDiary::JekyllLayer::Drop</tt>, declared
      # as a `#drop_class` method, and a <tt>Jekyll::Page</tt> subclass,
      # declared as a `#page_class` method.
      #
      # @example
      #   class SourceGenerator
      #     include DataPageGenerator
      #
      #     def drop_class = SourceDrop
      #     def page_class = SourcePage
      #   end
      module DataPageGenerator
        def generate(site)
          @site = site

          site.data[drop_class::PLURAL_NOUN].each do |key, data|
            site.pages << page_class.new(site, data[drop_class::DATA_KEY] || key)
          end
        end

        protected

        def method_missing(name)
          return unless REQUIRED_METHODS.include?(name)

          raise NotImplementedError,
                "#{self.class.name} must define a ##{name} method"
        end

        def respond_to_missing?(name, *) = REQUIRED_METHODS.include?(name)

        REQUIRED_METHODS = %i[
          drop_class
          page_class
        ].freeze
      end
    end
  end
end
