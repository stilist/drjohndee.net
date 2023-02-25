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

require_relative 'historical_diary/jekyll_layer'

module HistoricalDiary
  autoload :Annotation, 'historical_diary/lib/annotation'
  autoload :MapTile, 'historical_diary/lib/map_tile'
  autoload :Redactions, 'historical_diary/lib/redactions'
  autoload :SourceDocument, 'historical_diary/lib/source_document'
  # autoload :SourceDocumentPage, "historical_diary/lib/source_document_page"
  autoload :TimestampRange, 'historical_diary/lib/timestamp_range'
  autoload :VERSION, 'historical_diary/version'
end
