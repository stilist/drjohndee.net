# frozen_string_literal: true

require 'date'
require 'jekyll'
require_relative '../_lib/timestamp'

module HistoricalDiary
  class DatePage < Jekyll::Page
    def initialize(site, raw_timestamp:, timestamp:)
      @site = site
      @base = site.source
      # "1500-01-02" => ["1500", "01", "02"]
      # "1500-01-02--03" => ["1500", "01", "02"]
      date_parts = timestamp.startsAt.atoms
      @dir = date_parts.first(2).
        map { |atom| atom.to_s.rjust(2, '0') }.
        join(File::SEPARATOR)

      @basename = date_parts[2].to_s.rjust(2, '0')
      @ext = '.html'
      @name = "#{@basename}#{@ext}"

      read_yaml(File.join(@base, '_layouts'), 'date.html')
      @data = {
        'raw_timestamp' => raw_timestamp,
        # XXX
        'date_atoms' => date_parts.first(3),
        # 'timestamp' => timestamp,
        'footnotes' => [],
      }
      data.default_proc = proc do |_, key|
        site.frontmatter_defaults.find(relative_path, :entries, key)
      end
    end

    def <=>(other)
      data['date_atoms'] <=> other.data['date_atoms']
      # data['timestamp'].first <=> other.data['timestamp'].first &&
      # data['timestamp'].last <=> other.data['timestamp'].last
    end

    def url_placeholders
      {
        :path => @dir,
        :basename => basename,
        :output_ext => output_ext,
      }
    end
  end

  class EntryGenerator < Jekyll::Generator
    priority :highest
    safe true

    def generate(site)
      pages_by_timestamp = {}
      processed_timestamps = []

      site.collections['entries'].docs.each do |document|
        raw_timestamp = document.basename_without_ext.sub('--', '/')
        source_name = document.relative_path.split(File::SEPARATOR)[1]
        pages_by_timestamp[raw_timestamp] ||= {}
        pages_by_timestamp[raw_timestamp][source_name] = document
      end

      pages_by_timestamp.each do |raw_timestamp, documents|
        timestamp = Timestamp.new(raw_timestamp)

        if !processed_timestamps.include?(timestamp.startsAt)
          date_page = DatePage.new(site,
                                   raw_timestamp: raw_timestamp,
                                   timestamp: timestamp)
        end

        documents.each do |source_name, document|
          document.data['raw_timestamp'] = raw_timestamp
          document.data['timestamp'] = timestamp
          document.data['source'] ||= source_name

          if !date_page.nil? && document.data.key?('footnotes')
            date_page.data['footnotes'].concat(document.data['footnotes'])
          end

          site.pages << document
        end

        processed_timestamps << timestamp.startsAt
        site.posts.docs << date_page if !date_page.nil?
      end
    end
  end
end
