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

  def data_collection_entry(collection, key)
    @context.registers[:site].
      data.dig(collection, key)
  end

  def sanitize_url_key(key)
    key.gsub(/[^\w-]/, '-').
      gsub(/-{2,}/, '-').
      downcase
  end
end
