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

      <<~EOM
      <cite>
        #{parts.join(', ')}
      </cite>
      EOM
    end
  end
end
Liquid::Template.register_filter(Jekyll::SourceFilters)
