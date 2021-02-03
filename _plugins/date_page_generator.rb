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

module HistoricalDiary
  class DatePage < ::Jekyll::Page
    def initialize(site, timestamp:)
      @site = site
      @base = site.source
      # "1500-01-02" => [1500, 1, 2]
      date_parts = timestamp.split('-').map(&:to_i)
      @dir = date_parts.first(2).
        map { |atom| atom.to_s.rjust(2, '0') }.
        join(::File::SEPARATOR)

      @basename = date_parts[2].to_s.rjust(2, '0')
      @ext = '.html'
      @name = "#{@basename}#{@ext}"

      read_yaml(::File.join(@base, '_layouts'), 'date.html')

      @data ||= {}
      data['date_atoms'] = date_parts.first(3)
      data['timestamp'] = timestamp
      data['title'] = timestamp
      data.default_proc = proc do |_, key|
        site.frontmatter_defaults.find(relative_path, :source_material, key)
      end
    end

    def <=>(other)
      data['date_atoms'] <=> other.data['date_atoms']
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

      site.collections['source_material'].docs.each do |document|
        timestamp = document.basename_without_ext
        pages_by_timestamp[timestamp] ||= {}
        source_key = document.relative_path.split(::File::SEPARATOR)[-2]
        pages_by_timestamp[timestamp][source_key] = document
      end

      pages_by_timestamp.each do |timestamp, documents|
        documents.each do |source_key, document|
          document.data['source_key'] = source_key
          document.data['timestamp'] = timestamp

          site.pages << document
        end

        date_page = DatePage.new(site,
                                 timestamp: timestamp)
        site.posts.docs << date_page
      end
    end
  end
end
