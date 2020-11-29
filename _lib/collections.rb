# frozen_string_literal: true

COLLECTION_MAP_SINGULAR = {
  'person' => 'people',
  'place' => 'places',
  'source' => 'sources',
}.freeze
COLLECTION_MAP_PLURAL = COLLECTION_MAP_SINGULAR.map { |key, value| [value, key] }.
  to_h.
  freeze

module DataCollection
  UNKNOWN_REFERENCE_CLASS = 'is-unknown-reference'

  def data_collection_entry(collection, input)
    @context.registers[:site].
      data.dig(collection, input)
  end
end
