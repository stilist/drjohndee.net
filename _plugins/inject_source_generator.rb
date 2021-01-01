# frozen_string_literal: true

require 'jekyll'

module Jekyll
  class InjectSourceGenerator < Generator
    priority :high
    safe true

    COLLECTIONS = %w[
      diseases
      footnotes
      weather
    ].freeze

    def generate(site)
      COLLECTIONS.each do |type|
        dataset = site.data[type]
        dataset.each do |source, records|
          if records.is_a?(Hash)
            records.each do |_, record|
              record['source'] = source
            end
          else
            records.each do |record|
              record['source'] = source
            end
          end
        end
      end
    end
  end
end
