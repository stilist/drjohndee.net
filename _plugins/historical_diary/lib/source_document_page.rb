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

require 'forwardable'

module HistoricalDiary
  # An individual 'page' of a <tt>SourceDocument</tt>, representing a physical
  # page of the source document.
  #
  # This class is completely independent of Jekyll.
  class SourceDocumentPage
    extend Forwardable
    def_delegators :document,
                   :identifier

    attr_reader :page_number

    def initialize(document:, page_number:, raw_text:)
      @document = document
      @page_number = page_number
      @raw_text = raw_text
    end

    def notes = document.notes_for_page(page_number)

    def text = raw_text

    private

    attr_reader :document,
                :raw_text
  end
end
