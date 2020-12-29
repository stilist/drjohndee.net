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
      Jekyll.logger.warn('DataCollection:',
                         "Requested nil key from #{collection_name} data set.")
      return
    end

    internal_key = key.gsub(/[^\w\s-]/, '').downcase
    records = data_collection_records(collection_name)
    records[internal_key] || records[key]
  end

  def sanitize_url_key(key)
    key.gsub(/[^\w-]/, '-').
      gsub(/-{2,}/, '-').
      downcase
  end
end
