# frozen_string_literal: true

# The life and times of Dr John Dee
# Copyright (C) 2021  Jordan Cole <feedback@drjohndee.net>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

require 'jekyll'
require_relative '../_lib/collections'
require_relative '../_lib/timestamp_range'

module HistoricalDiary
  # Render a subset of Yaml annotation data as Ruby `Hash`es.
  class AnnotationGenerator < ::Jekyll::Generator
    include DataCollection
    safe true

    def generate(site)
      by_date = {}

      site.data['annotations'].each do |source_key, records|
        records.each do |timestamp, record|
          next if !record

          dates = TimestampRange.new(timestamp).dates

          dates.each do |date|
            date_string = date.strftime('%F')

            by_date[date_string] ||= []
            by_date[date_string] << record['annotations'].map do |annotation|
              {
                'replacement' => annotation['body']['value'],
                'selectors' => annotation['selectors'],
              }
            end

            by_date[date_string].flatten!
          end
        end
      end

      site.data['annotations_by_date'] = by_date
    end
  end
end
