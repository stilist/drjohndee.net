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
      # Copied from <tt>Jekyll::DataReader#sanitize_filename</tt>, with an
      # added invariant that `key` must be a string.
      #
      # @see https://github.com/jekyll/jekyll/blob/4.3-stable/lib/jekyll/readers/data_reader.rb#L70-L73
      def sanitize_key(key)
        return key if !key.is_a?(String)

        key.gsub(%r![^\w\s-]+|(?<=^|\b\s)\s+(?=$|\s?\b)!, "")
          .gsub(%r!\s+!, "_")
      end

      # Indirect access to Jekyll's public <tt>Jekyll::Site</tt> instance.
      def site_object
        return @site if defined?(@site)
        @context.registers[:site] if defined?(@context)
      end
    end
  end
end
