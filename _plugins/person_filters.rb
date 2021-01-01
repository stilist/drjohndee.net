# frozen_string_literal: true

require 'jekyll'
require_relative '../_lib/collections'

module Jekyll
  module PersonFilters
    include ::DataCollection

    # only rendered as metadata
    HIDDEN_PARTS = %w(
      url
    ).freeze
    # rendered separately, if at all
    EXCLUDED_PARTS = %w(
      footnotes
      id
      language
    ).freeze

    def person_name(key, type = 'name')
      parts = person_name_data(key, type: type)
      return key if parts.empty?

      parts.reject { |part| HIDDEN_PARTS.include?(part['type']) }
        .map { |part| part['text'] }
        .join(' ') || key
    end

    def person_tag(key, display_text = nil)
      fallback = "<span class='data-person #{UNKNOWN_REFERENCE_CLASS}'>#{display_text || key}</span>"
      parts = person_name_data(key)
      return fallback if parts.empty?

      url = person_permalink(key)
      return "<a href=#{url} class='data-person'>#{display_text}</a>" if !display_text.nil?

      combined = person_name_data(key) do |part|
        attributes = {
          itemprop: part['type'],
          itemid: part['id'],
        }.reject { |_, value| value.nil? }
         .map { |key, value| "#{key}=#{value}" }
         .join(' ')

        "<span #{attributes}>#{part['text']}</span>"
      end

      language = data_collection_record('places', key)&.dig('language')
      language_tag = "lang=#{language} translate" if !language.nil?

      <<~EOM
      <span class="data-person" itemscope itemtype=http://schema.org/Person #{language_tag}>
        <a href=#{url} itemprop=url>#{combined.join(' ')}</a>
      </span>
      EOM
    end

    def person_permalink(key)
      return if key.nil?
      relative_url("/#{COLLECTION_MAP_PLURAL['people']}/#{sanitize_key(key)}.html")
    end

    def person_name(key, type = 'name')
      parts = data_collection_record('people', key)&.dig(type)&.clone
      if parts.nil?
        Jekyll.logger.debug('Jekyll::PersonFilters:',
                           "Unable to find #{type} data for '#{key}'.")
        return
      end

      parts.each_with_object({}) do |part, memo|
        type = part['type']
        memo[type] ||= []
        memo[type] << part['text']
      end
    end

    def person_name_data(key, type: 'name')
      # XXX
      parts = data_collection_record('people', key)&.dig(type)&.clone
      return [] if parts.nil?

      parts.reject! { |part, _| EXCLUDED_PARTS.include?(part) }
      return parts.map { |part, value| yield(part, value) } if block_given?
      parts
    end
  end
end
Liquid::Template.register_filter(Jekyll::PersonFilters)
