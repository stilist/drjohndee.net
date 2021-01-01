# frozen_string_literal: true

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
    sanitized_prefix = sanitize_key(prefix)

    record = records[sanitized_prefix] || records[key]
    return record if suffix.nil?
    record[suffix]
  end

  def sanitize_key(key)
    key.gsub(/[^\w-]/, '_').downcase
  end
end
