# frozen_string_literal: true

require_relative '../_lib/collections'
require 'jekyll'

module Jekyll
  module SourceFilters
    include ::DataCollection

    def source_name(key)
      data_collection_entry('sources', key)&.dig('title') || key
    end

    def source_tag(key, display_text = nil, source_location = nil)
      record = data_collection_entry('sources', key)
      return "<cite class='data-source #{UNKNOWN_REFERENCE_CLASS}'>#{display_text || key}</cite>" if record.nil?

      title = "<span class='data-source' lang=#{record['language']}>#{display_text || record['title']}</span>"
      volume = "volume #{record['volume_number']}" if record.key?('volume_number')
      parts = [
        title,
        volume,
        source_location,
      ].compact

      url = relative_url("/#{COLLECTION_MAP_PLURAL['sources']}/#{sanitize_url_key(key)}.html")
      <<~EOM
      <cite>
        <a href='#{url}' itemprop=url>#{parts.join(', ')}</a>
      </cite>
      EOM
    end
  end
end
Liquid::Template.register_filter(Jekyll::SourceFilters)
