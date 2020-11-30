# frozen_string_literal: true

require 'date'
require 'jekyll'

module Jekyll
  module TimeFilters
    def time_text(input, country)
      begin
        date = input.is_a?(Time) ? input.to_date : DateTime.parse(input)
        date.strftime('%A, %-d %B %Y')
      rescue
        input
      end
    end

    def time_tag(input, country, itemprop = nil)
      attributes = []
      attributes << "itemprop='#{itemprop}'" if !itemprop.nil?

      begin
        date = input.is_a?(Time) ? input.to_date : DateTime.parse(input)
        formatted = date.strftime('%A, %-d %B %Y')
        attributes << "datetime=#{date.iso8601}"
      rescue
        formatted = input
      end

      "<time #{attributes.join(' ')}>#{formatted}</time>"
    end
  end
end
Liquid::Template.register_filter(Jekyll::TimeFilters)
