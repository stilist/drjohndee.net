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
    module Utilities
      # Convenience method for checking if an object is `Numeric` (`Bignum`,
      # `Float`, `Integer`).
      #
      # @see https://docs.ruby-lang.org/en/3.2/Numeric.html
      def numeric?(value) = value.is_a?(Numeric)

      # Copied from <tt>Jekyll::DataReader#sanitize_filename</tt>, with an
      # added invariant that `key` must be a string.
      #
      # @see https://github.com/jekyll/jekyll/blob/4.3-stable/lib/jekyll/readers/data_reader.rb#L70-L73
      def sanitize_key(key)
        return key unless key.is_a?(String)

        key.gsub(/[^\w\s-]+|(?<=^|\b\s)\s+(?=$|\s?\b)/, '')
           .gsub(/\s+/, '_')
      end

      def context_from_site(site)
        # @see https://github.com/jekyll/jekyll/blob/4.3-stable/test/test_filters.rb#L12
        Liquid::Context.new site.site_payload, {}, site:
      end

      def site_from_context(context)
        return if context.nil?

        context.registers[:site]
      end

      # Indirect access to Jekyll's public <tt>Jekyll::Site</tt> instance.
      def site_object
        return @site if defined? @site

        site_from_context @context
      end
    end
  end
end
