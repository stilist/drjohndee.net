# frozen_string_literal: true

require_relative '../_lib/collections'
require 'jekyll'

module Jekyll
  module PlaceFilters
    include ::DataCollection

    # only rendered as metadata
    HIDDEN_PARTS = %w(
      latitude
      longitude
      url
    ).freeze
    # rendered separately, if at all
    EXCLUDED_PARTS = %w(
      footnotes
      id
      language
    ).freeze

    def place_name(key)
      filtered = place_data(key) do |part, value|
        next if HIDDEN_PARTS.include?(part)
        value
      end
      return filtered.compact.join(', ') if !filtered.empty?

      key
    end

    def place_tag(key, display_text = nil)
      fallback = "<span class='data-place #{UNKNOWN_REFERENCE_CLASS}'>#{display_text || key}</span>"
      parts = place_data(key)
      return fallback if parts.empty?

      url = relative_url("/#{COLLECTION_MAP_PLURAL['places']}/#{sanitize_url_key(key)}.html")
      return "<a href=#{url} class='data-place'>#{display_text}</a>" if !display_text.nil?

      known_keys = HIDDEN_PARTS.map { |key| [key, key] }
        .to_h
      known_keys.merge!({
        'streetAddress' => 'streetAddress',
        'locality' => 'addressLocality',
        'region' => 'addressRegion',
        'country' => 'addressCountry',
        'postcode' => 'postalCode',
        'name' => 'name',
      }).freeze

      combined = place_data(key) do |part, value|
        if HIDDEN_PARTS.include?(part)
          "<meta itemprop=#{part} content='#{value}'>"
        else
          "<span itemprop=#{part}>#{value}</span>"
        end
      end

      language = data_collection_entry('places', key)&.dig('language')
      language_tag = "lang=#{language}" if !language.nil?

      <<~EOM
      <span class="data-place" itemscope itemtype=http://schema.org/Place #{language_tag}>
        <span itemprop=address itemscope itemtype=http://schema.org/PostalAddress>
          <a href='#{url}' itemprop=url>#{combined.join(' ')}</a>
        </span>
      </span>
      EOM
    end

    private

    def place_data(key)
      parts = data_collection_entry('places', key)&.clone
      if parts.nil?
        Jekyll.logger.warn('Jekyll::PlaceFilters:',
                           "Unable to find data for '#{key}'.")
        return []
      end

      parts.reject! { |part, _| EXCLUDED_PARTS.include?(part) }
      return parts.map { |part, value| yield(part, value) } if block_given?
      parts
    end
  end
end
Liquid::Template.register_filter(Jekyll::PlaceFilters)
