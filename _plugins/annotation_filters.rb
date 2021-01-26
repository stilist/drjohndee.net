# frozen_string_literal: true

require_relative '../_lib/collections'
require_relative '../_lib/timestamp'
require 'jekyll'

module HistoricalDiary
  module AnnotationFilters
    include ::DataCollection

    def entries_for_date(raw_date)
      @context.registers[:site].
        pages.
        select { |doc| doc.data['raw_timestamp'] == raw_date }
    end
  end
end
Liquid::Template.register_filter(HistoricalDiary::AnnotationFilters)
