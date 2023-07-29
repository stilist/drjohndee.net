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

# :nodoc:
def resolve_path(path) = File.expand_path(path, __dir__)

module HistoricalDiary
  module JekyllLayer
    module Shared
      autoload :Attributes,                resolve_path('shared/attributes')
      autoload :DataPage,                  resolve_path('shared/data_page')
      autoload :DataPageGenerator,         resolve_path('shared/data_page_generator')
      autoload :Drop,                      resolve_path('shared/drop')
      autoload :Filters,                   resolve_path('shared/filters')
      autoload :Site,                      resolve_path('shared/site')
      autoload :TransclusionLiquidHelpers, resolve_path('shared/transclusion_liquid_helpers')
      autoload :UncategorizedHelpers,      resolve_path('shared/uncategorized_helpers')
    end
  end
end
