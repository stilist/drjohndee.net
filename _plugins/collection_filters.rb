# frozen_string_literal: true

require_relative '../_lib/collections'
require 'jekyll'

module Jekyll
  module CollectionFilters
    include ::DataCollection

    def collection_entry(key, collection)
      data_collection_record(collection, key)
    end
  end
end
Liquid::Template.register_filter(Jekyll::CollectionFilters)
