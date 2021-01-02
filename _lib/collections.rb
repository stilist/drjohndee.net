# frozen_string_literal: true

require 'jekyll'

COLLECTION_MAP_SINGULAR = {
  'event' => 'events',
  'person' => 'people',
  'place' => 'places',
  'source' => 'sources',
}.freeze
COLLECTION_MAP_PLURAL = COLLECTION_MAP_SINGULAR.map { |key, value| [value, key] }.
  to_h.
  freeze

module DataCollection
  # for 'slugify'
  include ::Jekyll::Utils

  UNKNOWN_REFERENCE_CLASS = 'is-unknown-reference'

  def data_collection_records(collection)
    @context.registers[:site].data[collection]
  end

  def data_collection_record(collection_name, key)
    if key.nil?
      Jekyll.logger.debug('DataCollection:',
                          "Requested nil key from #{collection_name} data set.")
      return
    end

    records = data_collection_records(collection_name)

    prefix, suffix = key.split('/')
    sanitized_prefix = escape_key(prefix, collection_name)

    record = records[sanitized_prefix] || records[key]
    return record if suffix.nil?
    record[suffix]
  end

  def slugify_key(key)
    slugify(key, mode: :pretty).gsub(/[,\.]/, '')
  end

  private

  # @see https://github.com/jekyll/jekyll/blob/7d8a839a2132cadd940a3b4f8d7c5f9f6b0f9f62/lib/jekyll/readers/data_reader.rb#L71-L74
  def escape_key(key, collection_name = nil)
    # These data collections haven't been migrated to multiple files yet.
    return key if %w(people places).include?(collection_name)
    key.gsub(%r![^\w\s-]+|(?<=^|\b\s)\s+(?=$|\s?\b)!, "")
      .gsub(%r!\s+!, "_")
      .downcase
  end
end
