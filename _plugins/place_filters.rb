# frozen_string_literal: true

require_relative '../_lib/collections'
require 'jekyll'

module Jekyll
  module PlaceFilters
    include ::DataCollection

    def place_name(key, default_text = nil)
      default_text || key
    end

    def place_tag(key, display_text = nil)
      return "<span class='data-place is-unknown-reference'>#{display_text}</span>" if !display_text.nil?

      record = data_collection_entry('places', key)
      return fallback if record.nil?

      hidden_keys = %w(
        latitude
        longitude
      ).freeze
      known_keys = [
        hidden_keys,
        'streetAddress',
      ].flatten
       .map { |key| [key, key] }
       .to_h
      known_keys.merge!({
        'locality' => 'addressLocality',
        'region' => 'addressRegion',
        'country' => 'addressCountry',
      }).freeze
      markup = known_keys.map do |internal, external|
        next if !record.key?(internal)

        if hidden_keys.include?(internal)
          "<meta itemprop=#{external} content='#{record[internal]}'>"
        else
          "<span itemprop=#{external}>#{record[internal]}</span>"
        end
      end
      markup.compact!
      return fallback if markup.empty?

      <<~EOM
      #{display_text}
      <ins>
      <span class="data-place" itemscope itemtype="http://schema.org/Place">
      <span itemprop="address" itemscope itemtype="http://schema.org/PostalAddress">
      #{markup.join(' ')}
      </span>
      </span>
      </ins>
      EOM
    end
  end
end
Liquid::Template.register_filter(Jekyll::PlaceFilters)
