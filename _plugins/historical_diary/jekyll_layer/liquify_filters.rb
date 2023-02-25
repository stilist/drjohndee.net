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
    module LiquidFilters
      # License information copied from
      # https://github.com/gemfarmer/jekyll-liquify/blob/92b6b5b114fb13a5ef1e6fea8d71aaa7731ee551/LICENSE
      #
      # > As a work of the United States government, this project is in the public
      # > domain within the United States.
      # >
      # > Additionally, we waive copyright and related rights in the work worldwide
      # > through the [CC0 1.0 Universal public domain dedication](https://creativecommons.org/publicdomain/zero/1.0/).
      #
      # @see https://github.com/gemfarmer/jekyll-liquify/blob/master/lib/jekyll-liquify.rb
      #
      # @note If using the `liquify` filter causes a `SystemStackError` your
      #   input to the filter is already being passed through Liquid.
      def liquify(input)
        Liquid::Template.parse(input).render(@context)
      end
    end
  end
end
Liquid::Template.register_filter HistoricalDiary::JekyllLayer::LiquidFilters
