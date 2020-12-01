# frozen_string_literal: true

require_relative '../_lib/collections'
require 'jekyll'

module Jekyll
  module PersonFilters
    include ::DataCollection

    def person_name(key, type = 'name')
      combine_person_name_parts(key, type: type) || key
    end

    def person_tag(key, display_text = nil)
      return if key.nil?

      fallback = "<span class='data-person #{UNKNOWN_REFERENCE_CLASS}'>#{key}</span>"
      parts = data_collection_entry('people', key)
      url = relative_url("/#{COLLECTION_MAP_PLURAL['people']}/#{sanitize_url_key(key)}.html")

      if !display_text.nil?
        return fallback if parts.nil?
        return "<a href=#{url} class='data-person'>#{display_text}</a>"
      end

      combined = combine_person_name_parts(key) do |part|
        attributes = {
          itemprop: part['type'],
          itemid: part['id'],
        }.reject { |_, value| value.nil? }
         .map { |key, value| "#{key}=#{value}" }
         .join(' ')

        "<span #{attributes}>#{part['text']}</span>"
      end
      return fallback if combined.nil?


      <<~EOM
      <span class="data-person" itemscope itemtype=http://schema.org/Person>
        <a href=#{url} itemprop=url>#{combined}</a>
      </span>
      EOM
    end

    private

    def person_name_parts(key, type: 'name')
      data_collection_entry('people', key)&.dig(type)
    end

    def combine_person_name_parts(key, type: 'name')
      parts = person_name_parts(key, type: type)
      if parts.nil?
        Jekyll.logger.info('Jekyll::PersonFilters',
                           "Unable to find #{type} data for '#{key}'")
        return
      end

      formatted = parts.map do |part|
        if block_given?
          yield(part)
        else
          part['text']
        end
      end

      joined = formatted.compact.join(' ')
      joined if joined != ''
    end
  end
end
Liquid::Template.register_filter(Jekyll::PersonFilters)
