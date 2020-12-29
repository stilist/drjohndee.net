# frozen_string_literal: true

require_relative '../_lib/collections'
require 'jekyll'

module Jekyll
  module SourceFilters
    include ::DataCollection

    # only rendered as metadata
    HIDDEN_PARTS = %w(
      oclc_number
      url
    ).freeze
    # rendered separately, if at all
    EXCLUDED_PARTS = %w(
      author
      date
      editor
      footnotes
      id
      language
      license
      subtitle
    ).freeze

    def source_name(key)
      filtered = source_data(key) do |part, value|
        next if HIDDEN_PARTS.include?(part)
        value
      end
      return filtered.compact.join(', ') if !filtered.empty?

      key
    end

    def source_tag(key, display_text = nil, source_location = nil)
      fallback = "<span class='data-source' #{UNKNOWN_REFERENCE_CLASS}'>#{display_text || key}</span>"
      parts = source_data(key)
      return fallback if parts.empty?

      url = relative_url("/#{COLLECTION_MAP_PLURAL['sources']}/#{sanitize_key(key)}.html")
      return "<a href=#{url} class='data-source'>#{display_text}</a>" if !display_text.nil?

      known_keys = HIDDEN_PARTS.map { |key| [key, key] }
        .to_h
      known_keys.merge!({
        'name' => 'name',
        'volume_number' => 'volumeNumber',
        'oclc_number' => 'OCLC_NUMBER',
      }).freeze

      combined = source_data(key) do |part, value|
        if HIDDEN_PARTS.include?(part)
          "<meta itemprop=#{known_keys[part] || part} content='#{value}'>"
        elsif part == 'volume_number'
          "<span itemprop=#{known_keys[part] || part}>volume #{value}</span>"
        else
          "<span itemprop=#{known_keys[part] || part}>#{value}</span>"
        end
      end

      language = data_collection_record('places', key)&.dig('language')
      language_tag = "lang=#{language} translate" if !language.nil?

      <<~EOM
      <cite class="data-source" #{language_tag}>
        <a href='#{url}' itemprop=url>#{combined.join(' ')}</a>
      </cite>
      EOM
    end

    private

    def source_data(key)
      parts = data_collection_record('sources', key)&.clone
      if parts.nil?
        Jekyll.logger.warn('Jekyll::SourceFilters:',
                           "Unable to find data for '#{key}'.")
        return []
      end

      parts.reject! { |part, _| EXCLUDED_PARTS.include?(part) }
      return parts.map { |part, value| yield(part, value) } if block_given?
      parts
    end
  end
end
Liquid::Template.register_filter(Jekyll::SourceFilters)
