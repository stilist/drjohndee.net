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

# This is a naïve, simplistic implementation of the ISO 8601 date format and
# interval syntax. It's only capable of handling very basic inputs, but
# currently that's all I need. (Notably, it can't handle the shorthand interval
# syntax -- for example, `1500-01-01/02`.)
#
# The `ISO8601` Ruby gem is much more robust, but has a few issues of its own.
class TimestampRange
  attr_reader :end_date,
              :start_date

  def initialize(raw_timestamp)
    @raw_timestamp = raw_timestamp
    parse_raw_timestamp
  end

  def dates
    return @dates if defined?(@dates)

    current_date = start_date[:object].clone
    @dates = []

    while current_date <= end_date[:object]
      @dates << current_date
      current_date = current_date + 1
    end

    @dates
  end

  def intersect?(timestamp_range)
    !intersection(timestamp_range).empty?
  end

  def intersection(timestamp_range)
    dates & timestamp_range.dates
  end

  private

  def parse_raw_timestamp
    # ISO 8601 specifies `/` as the interval separator, but allows `--` as an
    # alternative in cases where `/` isn't available. This is useful because it
    # allows filenames in `_source_material` to specify intervals without using
    # a file system path separator as the interval separator.
    @raw_start, _, @raw_end = @raw_timestamp.split(/(\/|--)/)

    @start_date = parse_raw_date(@raw_start)

    @end_date = parse_raw_date(@raw_end)
    ensure_end_date

    @start_date.freeze
    @end_date.freeze
  end

  def parse_raw_date(raw_date)
    return if raw_date.nil?

    year, month, day = raw_date.split('-').map(&:to_i)

    iso8601 = [
      year,
      month || 1,
      day || 1,
    ].map { |part| part.to_s.rjust(2, '0') }.
      join('-')

    {
      object: ::DateTime.iso8601(iso8601, ::Date::ENGLAND),
      year: year,
      month: month,
      day: day,
    }
  rescue
    raise "Unable to parse '#{raw_date}'"
  end

  def ensure_end_date
    return if @end_date.is_a?(Hash)

    @end_date = @start_date.clone

    # `@start_date` is just a year (no month or day)
    if @start_date[:month].nil?
      @end_date[:object] = @end_date[:object] >> 12
      @end_date[:object] -= 1
      @end_date[:month] = @end_date[:object].month
      @end_date[:day] = @end_date[:object].day
      return
    end

    # `@start_date` is a year and month (no day)
    if @start_date[:day].nil?
      @end_date[:object] = @end_date[:object] >> 1
      @end_date[:object] -= 1
      @end_date[:day] = @end_date[:object].day
      return
    end
  end
end
