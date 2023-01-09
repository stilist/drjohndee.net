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

# Classes that interact with Jekyll's generation pipeline must be eagerly
# loaded.
require_relative "jekyll_layer/liquify_filters"
require_relative "jekyll_layer/tag_filters"
require_relative "jekyll_layer/year_page_generator"

module HistoricalDiary
  # Code in the <tt>HistoricalDiary::JekyllLayer</tt> module assumes access to
  # Jekyll's public APIs, going through
  # <tt>HistoricalDiary::JekyllLayer::Utilities#site_object</tt>.
  module JekyllLayer
    autoload :PersonDrop, "jekyll_layer/person_drop"
    autoload :PlaceDrop, "jekyll_layer/place_drop"
    autoload :SourceDrop, "jekyll_layer/source_drop"
    autoload :Utilities, "jekyll_layer/utilities"
  end
end
