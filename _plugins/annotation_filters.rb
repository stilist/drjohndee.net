# frozen_string_literal: true

require_relative '../_lib/collections'
require_relative '../_lib/timestamp'
require 'jekyll'

module HistoricalDiary
  module AnnotationFilters
    include ::DataCollection

    # @todo Use `Timestamp#intersect?`
    def entries_for_date(raw_date)
      @context.registers[:site].
        pages.
        select { |doc| doc.data['raw_timestamp'] == raw_date }
    end

    # @todo Use `Timestamp#intersect?`
    def relevant_footnotes(raw_timestamp)
      return [] if raw_timestamp.nil?

      raw_date = raw_timestamp.split('/').first
      footnotes_by_timestamp[raw_date]
    end
  end
end
Liquid::Template.register_filter(HistoricalDiary::AnnotationFilters)
