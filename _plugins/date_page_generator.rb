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
require_relative '../_lib/timestamp_range'

module HistoricalDiary
  class DatePage < ::Jekyll::Page
    def initialize(site, date:)
      @site = site
      @base = site.source
      # "1500-01-02" => [1500, 1, 2]
      @dir = [
        date.strftime('%Y'),
        date.strftime('%m'),
      ].join(::File::SEPARATOR)

      @basename = date.strftime('%d')
      @ext = '.html'
      @name = "#{@basename}#{@ext}"

      read_yaml(::File.join(@base, '_layouts'), 'date.html')

      @data ||= {}
      data['date'] = date
      timestamp = date.strftime('%F')
      data['timestamp'] = timestamp
      data['title'] = "Events and writings for #{timestamp}"

      data.default_proc = proc do |_, key|
        site.frontmatter_defaults.find(relative_path, :source_material, key)
      end
    end

    def <=>(other)
      data['date'] <=> other.data['date']
    end

    def url_placeholders
      {
        :path => @dir,
        :basename => basename,
        :output_ext => output_ext,
      }
    end
  end

  # This iterates over the `Jekyll::Document`s for all published source
  # material, generates a `Jekyll::Post` for each date that has material, and
  # manipulates the front matter of the `Jekyll::Document`s.
  class SourceMaterialGenerator < ::Jekyll::Generator
    safe true

    def generate(site)
      pages_by_timestamp = {}
      known_dates = []

      site.collections['source_material'].docs.each do |document|
        timestamp = document.basename_without_ext
        pages_by_timestamp[timestamp] ||= {}
        source_key = document.relative_path.split(::File::SEPARATOR)[-2]
        pages_by_timestamp[timestamp][source_key] = document
      end

      pages_by_timestamp.each do |timestamp, documents|
        timestamp_range = TimestampRange.new(timestamp)

        documents.each do |source_key, document|
          document.data['source_key'] = source_key
          document.data['timestamp'] = timestamp
          document.data['timestamp_range'] = timestamp_range

          site.pages << document
        end

        timestamp_range.dates.each do |date|
          next if known_dates.include?(date)

          site.posts.docs << DatePage.new(site, date: date)
          known_dates << date
        end
      end
    end
  end
end
