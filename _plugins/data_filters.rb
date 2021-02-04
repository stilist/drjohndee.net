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

require_relative '../_lib/collections'
require 'jekyll'

module HistoricalDiary
  module DataFilters
    include ::DataCollection

    def collection_entry(key, collection_name)
      data_collection_record(collection_name, key)
    end

    def collection_entry_url(key, collection_name)
      data_collection_record_url(collection_name, key)
    end

    def commentary_for_date(timestamp)
      return [] if timestamp.nil?

      date = timestamp.split(/(--|\/)/).first
      commentary_by_timestamp[date]
    end

    # > Author. Title. Title of container (do not list container for standalone
    # > books, e.g. novels), Other contributors (translators or editors),
    # > Version (edition), Number (vol. and/or no.), Publisher, Publication
    # > Date, Location (pages, paragraphs URL or DOI). 2nd container’s title,
    # > Other contributors, Version, Number, Publisher, Publication date,
    # > Location, Date of Access (if applicable).
    # >
    # > Last Name, First Name. Title of Book. City of Publication, Publisher,
    # > Publication Date.
    # >
    # > *Note: the City of Publication should only be used if the book was
    # > published before 1900, if the publisher has offices in more than one
    # > country, or if the publisher is unknown in North America.
    def mla_citation(source_key, location, edition_key = nil, author_key = nil)
      source = source_data(source_key)
      return source_key if source.nil?

      edition = source.dig('editions', edition_key)
      if edition.nil? && source['editions'].length == 1
        edition = source['editions'].values.first
      end
      edition ||= {}
      publishing_info = [
        edition['city'],
        edition['publisher'],
        edition['date'],
        location.sub('-', '–'),
      ].compact.join(', ')
      publishing_info[0] = publishing_info[0].capitalize

      source_name = edition['name'] || source.dig('work', 'name')
      output = [
        data_collection_record_link('sources', source_key, source_name),
        publishing_info,
      ]

      author_key ||= source.dig('work', 'author_key')
      author = person_data(author_key)
      if author.nil?
        output.unshift(author_key)
      else
        author_name = [
          author.dig('presentational_name', 'familyName'),
          author.dig('presentational_name', 'givenName'),
        ].compact.join(', ')
        output.unshift(data_collection_record_link('people', author_key, author_name))
      end

      editor_key ||= source.dig('work', 'editor_key')
      editor = person_data(editor_key)
      if editor.nil?
        output.insert(2, editor_key)
      else
        editor_name = [
          editor.dig('presentational_name', 'givenName'),
          editor.dig('presentational_name', 'familyName'),
        ].compact.join(' ')
        out = "Edited by " + data_collection_record_link('people', editor_key, editor_name)
        output.insert(2, out)
      end

      output.flatten.
        compact.
        reject { |part| part.strip == '' }.
        join('. ').
        sub('..', '.') + '.'
    end

    def relevant_footnotes(timestamp)
      return [] if timestamp.nil?

      date = timestamp.split(/(--|\/)/).first
      footnotes_by_timestamp[date]
    end

    def source_material_for_date(timestamp)
      @context.registers[:site].
        pages.
        select { |doc| doc.data['timestamp'] == timestamp }
    end
  end
end
Liquid::Template.register_filter(HistoricalDiary::DataFilters)
