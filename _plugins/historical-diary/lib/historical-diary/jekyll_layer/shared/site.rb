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
      module Site
        # @see https://github.com/jekyll/jekyll/blob/4.3-stable/test/test_filters.rb#L12
        def context_from_site(site) = Liquid::Context.new(site.site_payload, {}, site:)

        def site_from_context(context) = context&.registers&.dig(:site)

        # Indirect access to Jekyll's public <tt>Jekyll::Site</tt> instance.
        def site_object = @site || site_from_context(@context)
      end
    end
  end
end
