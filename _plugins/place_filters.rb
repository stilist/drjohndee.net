# frozen_string_literal: true

require_relative '../_lib/collections'
require 'jekyll'

module Jekyll
  module PlaceFilters
    include ::DataCollection

    HIDDEN_PARTS = %w(
      id
      latitude
      longitude
      url
    ).freeze
    UNSTRUCTURED_PARTS = %w(
      footnotes
    ).freeze

    def place_name(key)
      combined = combine_place_name_parts(key) do |part, value|
        next if HIDDEN_PARTS.include?(part)
        value
      end

      combined || key
    end

    def place_tag(key, display_text = nil)
      fallback = "<span class='data-place #{UNKNOWN_REFERENCE_CLASS}'>#{display_text || key}</span>"
      record = data_collection_entry('places', key)
      return fallback if record.nil?

      url = relative_url("/#{COLLECTION_MAP_PLURAL['places']}/#{sanitize_url_key(key)}.html")
      return "<a href=#{url} class='data-place'>#{display_text}</a>" if !display_text.nil?

      known_keys = HIDDEN_PARTS.map { |key| [key, key] }
       .to_h
      known_keys.merge!({
        'streetAddress' => 'address',
        'locality' => 'addressLocality',
        'region' => 'addressRegion',
        'country' => 'addressCountry',
      }).freeze

      combined = combine_place_name_parts(key) do |part, value|
        if HIDDEN_PARTS.include?(part)
          "<meta itemprop=#{part} content='#{value}'>"
        else
          "<span itemprop=#{part}>#{value}</span>"
        end
      end
      return fallback if combined.nil?

      <<~EOM
      <span class="data-place" itemscope itemtype=http://schema.org/Place>
        <span itemprop="address" itemscope itemtype=http://schema.org/PostalAddress>
          <a href='#{url}' itemprop=url>#{combined}</a>
        </span>
      </span>
      EOM
    end

    private

    def place_name_parts(key)
      data_collection_entry('places', key)
    end

    def combine_place_name_parts(key)
      parts = place_name_parts(key)
      if parts.nil?
        Jekyll.logger.info('Jekyll::PlaceFilters',
                           "Unable to find name data for '#{key}'")
        return
      end

      parts.reject! { |part, _| UNSTRUCTURED_PARTS.include?(part) }
      formatted = parts.map do |part, value|
        if block_given?
          yield(part, value)
        else
          value
        end
      end

      joined = formatted.compact.join(', ')
      joined if joined != ''
    end
  end
end
Liquid::Template.register_filter(Jekyll::PlaceFilters)
