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
require_relative '../_lib/data_collection'

module HistoricalDiary
  class DataPage < ::Jekyll::Page
    include ::DataCollection

    def initialize(site, collection_name, key:)
      singular = ::DataCollection::PLURAL_TO_SINGULAR[collection_name]
      @site = site
      @base = site.source
      @dir = collection_name

      @basename = slugify_key(key)
      @ext = '.html'
      @name = "#{@basename}#{@ext}"

      read_yaml(File.join(@base, '_layouts'), "#{singular}.html")

      @data ||= {}
      data["#{singular}_key"] = key

      record = send(:"#{singular}_data", key)
      if record.nil?
        title = key
      else
        title = case collection_name
                when 'people'
                  record['presentational_name'].values.join(' ')
                when 'sources'
                  record.dig('work', 'name')
                end
      end
      data['title'] = title

      data.default_proc = proc do |_, key|
        site.frontmatter_defaults.find(relative_path, :source_material, key)
      end
    end
  end

  class DataGenerator < ::Jekyll::Generator
    safe true

    def generate(site)
      ::DataCollection::RENDERED_COLLECTIONS.each do |collection_name|
        site.data[collection_name].each do |key, _|
          site.pages << DataPage.new(site, collection_name,
                                     key: key)
        end
      end
    end
  end
end
