# frozen_string_literal: true

require 'date'
require 'jekyll'

module HistoricalDiary
  class DatePage < Jekyll::Page
    def initialize(site, date:)
      @site = site
      @base = site.source
      # "1500-01-02" => ["1500", "01", "02"]
      # "1500-01-02--03" => ["1500", "01", "02"]
      date_parts = date.
        split('--').
        first.
        split('-')
      @dir = date_parts.first(2).join('/')

      @basename = date_parts.last
      @ext = '.html'
      @name = "#{@basename}#{@ext}"
      # require 'byebug' ; byebug

      read_yaml(File.join(@base, '_layouts'), 'date.html')
      @data = {
        'date' => date,
        'date_object' => DateTime.iso8601(date, Date::ENGLAND),
      }
      data.default_proc = proc do |_, key|
        site.frontmatter_defaults.find(relative_path, :entries, key)
      end
    end

    def <=>(other)
      data['date_object'] <=> other.data['date_object']
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
      by_date = {}

      site.collections['entries'].docs.each do |document|
        iso8601_date = document.basename_without_ext.match(/\d{4}-\d{2}-\d{2}/)[0]
        source_name = document.relative_path.split(File::SEPARATOR)[1]
        by_date[iso8601_date] ||= {}
        by_date[iso8601_date][source_name] = document
      end

      by_date.each do |date, parts|
        parts.each do |source_name, document|
          document.data['date'] = date
          document.data['source'] ||= source_name
          site.pages << document
        end

        site.posts.docs << DatePage.new(site, date: date)
      end
    end
  end
end
