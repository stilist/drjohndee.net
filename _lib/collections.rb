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

module DataCollection
  # for 'slugify'
  include ::Jekyll::Utils

  RENDERED_COLLECTIONS = %w[
    people
    sources
  ].freeze
  TRANSCLUDED_COLLECTIONS = %w[
    commentary
    footnotes
  ].freeze
  SINGULAR_TO_PLURAL = {
    'person' => 'people',
    'source' => 'sources',
  }.freeze
  PLURAL_TO_SINGULAR = SINGULAR_TO_PLURAL.map { |key, value| [value, key] }.
    to_h.
    freeze

  def data_collection_records(collection_name)
    site = @site
    site ||= @context.registers[:site]
    site.data[collection_name]
  end

  def data_collection_record(collection_name, key)
    return if key.nil? || key.strip == ''

    prefix, suffix = key.split('/')
    sanitized_prefix = escape_key(prefix)

    records = data_collection_records(collection_name)
    record = records[sanitized_prefix] || nil
    return record if suffix.nil?
    record[suffix]
  end

  def data_collection_record_url(collection_name, key)
    sanitized_key = escape_key(key)
    "/#{collection_name}/#{slugify_key(sanitized_key)}.html"
  end

  def data_collection_record_link(collection_name, key, display_text = nil)
    display_text ||= key
    url = data_collection_record_url(collection_name, key)
    "<a href='#{url}'>#{display_text}</a>"
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

  SIMPLE_DATE_PATTERN = /\A\d{4}-\d{2}-\d{2}/
  def commentary_by_timestamp
    return @commentary_by_timestamp if defined?(@commentary_by_timestamp)
    @commentary_by_timestamp = {}

    by_source = data_collection_records('commentary')
    by_source.each do |source, records|
      next if records.nil?

      records.keys.each do |key|
        timestamp = key.match(SIMPLE_DATE_PATTERN)&.to_s
        next if timestamp.nil?

        @commentary_by_timestamp[timestamp] ||= []
        @commentary_by_timestamp[timestamp] << "#{source}/#{key}"
      end
    end
    @commentary_by_timestamp
  end

  def footnotes_by_timestamp
    return @footnotes_by_timestamp if defined?(@footnotes_by_timestamp)
    @footnotes_by_timestamp = {}

    by_source = data_collection_records('footnotes')
    by_source.each do |source, records|
      next if records.nil?

      records.keys.each do |key|
        timestamp = key.match(SIMPLE_DATE_PATTERN)&.to_s
        next if timestamp.nil?

        @footnotes_by_timestamp[timestamp] ||= []
        @footnotes_by_timestamp[timestamp] << "#{source}/#{key}"
      end
    end

    @footnotes_by_timestamp
  end

  private

  # @see https://github.com/jekyll/jekyll/blob/7d8a839a2132cadd940a3b4f8d7c5f9f6b0f9f62/lib/jekyll/readers/data_reader.rb#L71-L74
  def escape_key(key)
    key.gsub(%r![^\w\s-]+|(?<=^|\b\s)\s+(?=$|\s?\b)!, "")
      .gsub(%r!\s+!, "_")
      .downcase
  end
end
