# frozen_string_literal: true

require 'jekyll'
require_relative '../_lib/collections'

module Jekyll
  class DataPage < Page
    include ::DataCollection

    def initialize(site, base, dir, category:, key:)
      singular = COLLECTION_MAP_PLURAL[category]
      @site = site
      @base = base
      @dir = singular
      @name = "#{slugify_key(key)}.html"

      Jekyll.logger.debug('Compiling data page:',
                          "#{singular}/#{slugify_key(key)}")

      process(@name)
      read_yaml(File.join(base, '_layouts'), "#{singular}.html")

      # used in the layout's Liquid filters
      self.data['key'] = key

      title = site.data.dig(type, key, 'name')
      title = title.map { |part| part['text'] }.join(' ') if title.is_a?(Array)
      self.data['title'] = title || key.capitalize
    end
  end

  class DataPageGenerator < Generator
    priority :lower
    safe true

    def generate(site)
      @site = site
      page_categories = COLLECTION_MAP_PLURAL.keys - ['footnotes']
      page_categories.freeze

      page_categories.each do |category|
        site.data[category].each do |key, value|
          site.pages << DataPage.new(site, site.source, category,
                                     category: category, key: key)
        end
      end
    end
  end
end
