# frozen_string_literal: true

require_relative '../_lib/collections'
require 'jekyll'

module Jekyll
  module SourceFilters
    include ::DataCollection

    def source_name(key)
      data_collection_entry('sources', key)&.dig('title') || key
    end

    def source_tag(key, source_location = nil)
      record = data_collection_entry('sources', key)
      return "<cite class='data-source is-unknown-reference'>#{key}</cite>" if record.nil?

      person = person_tag(record['author']) || '(unknown author)'
      title = "<span class='data-source'>#{record['title']}</span>"
      parts = [
        person,
        title,
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
