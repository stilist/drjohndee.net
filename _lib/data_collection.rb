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

require 'jekyll'
require_relative '../_plugins/historical_diary/timestamp_range'

module DataCollection
  # for 'slugify'
  include ::Jekyll::Utils

  # static collections that get a page for each item
  RENDERED_COLLECTIONS = %w[
    people
    places
    sources
    tags
  ].freeze
  # dynamically-generated collections that get a page for each item
  GENERATED_COLLECTIONS = %w[
    tags
  ].freeze
  # static collections that are only presented as part of another page
  TRANSCLUDED_COLLECTIONS = %w[
    biography
    commentary
    context
    footnotes
  ].freeze
  SINGULAR_TO_PLURAL = {
    'person' => 'people',
    'place' => 'places',
    'source' => 'sources',
    'tag' => 'tags',
  }.freeze
  PLURAL_TO_SINGULAR = SINGULAR_TO_PLURAL.map { |key, value| [value, key] }.
    to_h.
    freeze
  TRANSCLUSIONS = {}

  def data_collection_records(collection_name)
    data_collection__site_object.data[collection_name]
  end

  def data_collection_record(collection_name, key)
    return if !key.is_a?(String) || key.strip == ''

    if GENERATED_COLLECTIONS.include?(collection_name)
      return data_collection_records(collection_name)[key]
    end

    prefix, suffix = key.split('/', 2)
    sanitized_prefix = escape_key(prefix) if prefix != ''

    records = data_collection_records(collection_name)
    record = records[sanitized_prefix] || nil
    return if record.nil?
    return record if suffix.nil?
    record[suffix]
  end

  def data_collection_record_url(collection_name, key)
    return nil if !key.is_a?(String)

    sanitized_key = escape_key(key)
    "/#{collection_name}/#{slugify_key(sanitized_key)}.html"
  end

  def slugify_key(key)
    slugify(key, mode: :pretty).gsub(/[,\.]/, '')
  end

  def method_missing(name, *args)
    if name =~ /[a-z]+_data/
      collection_name = name.match(/([a-z]+)_data/)[1]
      data_collection_record(SINGULAR_TO_PLURAL[collection_name],
                             args.first)
    end
  end

  def transclusions_for_timestamp(collection_name, timestamp)
    return [] if collection_name.nil?
    return [] if timestamp.nil? || timestamp.strip == ''

    ensure_transclusions_by_date(collection_name)

    timestamp_range = HistoricalDiary::TimestampRange.new(timestamp, data_collection__default_calendar_system)
    out = []
    timestamp_range.dates.each do |date|
      out << TRANSCLUSIONS[collection_name][date.strftime('%F')]
    end

    out.flatten.compact.uniq
  end

  private

  def data_collection__site_object
    @site || @context.registers[:site]
  end

  def data_collection__default_calendar_system
    data_collection__site_object.config["default_calendar_system"]
  end

  # @see https://github.com/jekyll/jekyll/blob/7d8a839a2132cadd940a3b4f8d7c5f9f6b0f9f62/lib/jekyll/readers/data_reader.rb#L71-L74
  def escape_key(key)
    return key if !key.is_a?(String)

    key.gsub(%r![^\w\s-]+|(?<=^|\b\s)\s+(?=$|\s?\b)!, "")
      .gsub(%r!\s+!, "_")
      .downcase
  end

  def ensure_transclusions_by_date(collection_name)
    return TRANSCLUSIONS[collection_name] if TRANSCLUSIONS.key?(collection_name)

    TRANSCLUSIONS[collection_name] = {}

    by_source = data_collection_records(collection_name)
    by_source.each do |source, records|
      next if records.nil?

      records.keys.each do |key|
        raw_timestamps = key.split(',')
        raw_timestamps.each do |raw_timestamp|
          timestamp_range = TimestampRange.new(raw_timestamp, data_collection__default_calendar_system)
          timestamp_range.dates.each do |date|
            as_string = date.strftime('%F')
            TRANSCLUSIONS[collection_name][as_string] ||= []
            TRANSCLUSIONS[collection_name][as_string] << "#{source}/#{key}"
          end
        end
      end
    end
  end
end
