# frozen_string_literal: true

require 'jekyll'
require 'ox'
require_relative '../_lib/collections'

# Configure Ox to parse HTML.
Ox.default_options = {
  mode: :generic,
  effort: :tolerant,
  smart: true,
}

module Jekyll
  class ExtractReferencesGenerator < Generator
    priority :higher

    COLLECTION_PATTERN = /(?<collection>#{COLLECTION_MAP_SINGULAR.keys.join('|')})/
    REFERENCE_PATTERN = /
      \{\{\s
      "(?<reference>.+?)"
      \s\|\s
      #{COLLECTION_PATTERN.source}_(name|tag)
    /x

    def generate(site)
      @site = site

      site.posts.docs.each do |page|
        process_page(page)
      end
    end

    private

    def process_page(page)
      return if page.content.match(REFERENCE_PATTERN).nil?

      document = Ox.parse(page.content)
      return if document.nil?

      references = document.nodes.map do |node|
        extract_references(node)
      end
      sanitized = references.flatten.compact.uniq

      sanitized.each do |data|
        collection = COLLECTION_MAP_SINGULAR[data['collection']]
        Jekyll.logger.debug('Jekyll::ExtractReferencesGenerator:',
                            "Adding '#{data["reference"]}' to #{collection}.")
        page.data[collection] ||= []
        page.data[collection] << data['reference']
      end
    rescue Ox::ParseError
      Jekyll.logger.error('Jekyll::ExtractReferencesGenerator:',
                          "Bad/missing markup in #{page.url}.")
      abort
    end

    def extract_references(node)
      return nil if node.is_a?(Ox::Comment)

      if node.is_a?(String)
        # +#scan+ returns +Array<Array<String>>+; this changes it to
        # +Array<Hash>+.
        return node.scan(REFERENCE_PATTERN).map do |match|
          REFERENCE_PATTERN.names.zip(match).to_h
        end
      end

      if node.value == 'a'
        match = REFERENCE_PATTERN.match(node.href)
        return match&.named_captures
      end

      node.nodes.map do |child|
        extract_references(child)
      end
    end
  end
end
