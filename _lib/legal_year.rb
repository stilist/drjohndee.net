# frozen_string_literal: true

# The life and times of Dr John Dee
# Copyright (C) 2021  Jordan Cole <feedback@drjohndee.net>
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

require 'date'
require_relative 'timestamp_range'

# > In England, Lady Day was New Year's Day (i.e. the new year began on 25
# > March) from 1155 until 1752, when the Gregorian calendar was adopted in
# > Great Britain and its Empire and with it the first of January as the
# > official start of the year in England, Wales and Ireland. […]
# > Until this change Lady Day had been used as the start of the legal year
# > but also the end of the fiscal and tax year. […] It appears that in
# > England and Wales, from at least the late 14th century, New Year's Day
# > was celebrated on 1 January as part of Yule.
#
# @see https://en.wikipedia.org/wiki/Lady_Day
#
# @note This is hard-coded for Great Britain, and doesn't apply for other
#   countries.
module LegalYear
  def legal_year(year)
    legal_year__timestamp_range(year).dates
  end

  def legal_year_start(year)
    legal_year__timestamp_range(year).start_date[:object]
  end

  def legal_year_end(year)
    legal_year__timestamp_range(year).end_date[:object]
  end

  private

  def legal_year__timestamp_range(year)
    timestamp = "#{year}-03-25/#{year + 1}-03-24"
    TimestampRange.new(timestamp, legal_year__default_calendar_system)
  end

  def legal_year__default_calendar_system
    site = @site || @context.registers[:site]
    site.config["default_calendar_system"]
  end
end
