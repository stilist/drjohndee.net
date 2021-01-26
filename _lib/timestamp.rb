# frozen_string_literal: true

require 'iso8601'

class Timestamp
  attr_reader :interval,
              :parsed,
              :raw_end,
              :raw_start,
              :raw_timestamp_string,
              :type

  def initialize(raw_timestamp)
    @raw_timestamp = raw_timestamp
    parse
  end

  def intersect?(other_timestamp)
    return false if interval.nil?

    interval.intersection(other_timestamp.interval)
    true
  rescue ISO8601::Errors::IntervalError
    false
  end

  def startsAt
    case type
    when :interval, :timestamp then interval.first
    else nil
    end
  end

  def endsAt
    case type
    when :interval, :timestamp then interval.last
    else nil
    end
  end

  private

  def parse
    as_string = if @raw_timestamp.is_a?(String)
                  @raw_timestamp
                elsif @raw_timestamp.is_a?(Integer)
                  @raw_timestamp.to_s
                else
                  @raw_timestamp.utc.strftime('%FT%TZ')
                end
    @raw_timestamp_string = as_string

    if as_string =~ /\//
      @parsed = ISO8601::TimeInterval.parse(as_string)
      @raw_start, @raw_end = as_string.split('/')
      @interval = @parsed
      @type = :interval
    elsif as_string =~ /\AP/
      @parsed = ISO8601::Duration.new(as_string)
      @interval = nil
      @type = :duration
    else
      # @note `ISO8601::DateTime`'s constructor uses the default `DateTime`
      #   constructor, which defaults to `Date::ITALY` (1582-10-15) for the
      #   date the Gregorian calendar reform takes effect. This is fine for
      #   most people, but this project is in the context of England/United
      #   Kingdom and uses Julian dates throughout, so the correct transition
      #   date is `Date::ENGLAND` (1752-09-14). This indirection allows for
      #   dates that are valid in England, but not Italy. (For example,
      #   1582-10-12.)
      julian_parse = DateTime.iso8601(as_string, Date::ENGLAND)
      @parsed = ISO8601::DateTime.new(julian_parse.strftime('%Y-%j'))

      @interval = ISO8601::TimeInterval.from_datetimes(@parsed, @parsed)
      @raw_end = as_string
      @raw_start = as_string
      @type = :timestamp
    end
  end
end
