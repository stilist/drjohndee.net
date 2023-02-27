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

require 'jekyll'

# Classes that interact with Jekyll's generation pipeline must be eagerly
# loaded.
require_relative 'jekyll_layer/hash_filters'
require_relative 'jekyll_layer/liquify_filters'
require_relative 'jekyll_layer/place_filters'
require_relative 'jekyll_layer/place_page_generator'
require_relative 'jekyll_layer/person_filters'
require_relative 'jekyll_layer/person_page_generator'
require_relative 'jekyll_layer/source_filters'
require_relative 'jekyll_layer/source_page_generator'
require_relative 'jekyll_layer/static_map_tile_block'
require_relative 'jekyll_layer/transclusion_block'
require_relative 'jekyll_layer/transclusion_tag'

module HistoricalDiary
  # Code in the <tt>HistoricalDiary::JekyllLayer</tt> module assumes access to
  # Jekyll's public APIs, going through
  # <tt>HistoricalDiary::JekyllLayer::Utilities</tt>.
  module JekyllLayer
    autoload :DataPage, 'jekyll_layer/data_page_generator'
    autoload :DataPageGenerator, 'jekyll_layer/data_page_generator'
    autoload :Drop, 'jekyll_layer/drop'
    autoload :PersonDrop, 'jekyll_layer/person_drop'
    autoload :PlaceDrop, 'jekyll_layer/place_drop'
    autoload :SourceDrop, 'jekyll_layer/source_drop'
    autoload :TransclusionLiquidHelpers, 'jekyll_layer/transclusion_liquid_helpers'
    autoload :Utilities, 'jekyll_layer/utilities'
  end
end
