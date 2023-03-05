# frozen_string_literal: true

#--
# The life and times of Dr John Dee
# Copyright (C) 2020-2023  Jordan Cole <feedback@drjohndee.net>
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
#++

module HistoricalDiary
  module JekyllLayer
    module SourceFilters
      include Filter

      alias source_data drop

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
      def mla_citation(source_key, location, edition_key = nil, volume_key = nil, author_key = nil)
        key = SourceDocument.build_identifier source_key, edition_key, volume_key
        data = drop key

        publication_date = data['date']
        unless publication_date.nil?
          year = publication_date.match(/\A\d{4}/)
          # Tagging this as an actual date improves the screenreader experience.
          publication_date = "<time datetime='#{publication_date}'>#{year}</time>" unless year.nil?
        end

        publishing_info = [
          data['city'],
          data['publisher'],
          publication_date,
          location&.sub('-', '–'),
        ].compact.join(', ')
        publishing_info[0] = publishing_info[0].capitalize unless publishing_info.empty?

        source_name = data['name']
        output = [
          data_record_link('sources', source_key, source_name),
          publishing_info,
        ]

        volume_number = data['volumeNumber']
        output.insert(1, "Volume #{volume_number}") unless volume_number.nil?

        author_key ||= data['author_key']
        author = person_data author_key
        if author.nil?
          output.unshift author_key
        else
          author_name = [
            author.dig('presentational_name', 'familyName'),
            author.dig('presentational_name', 'givenName'),
          ].compact.join ', '
          output.unshift person_link(author_key, author_name)
        end

        editor_key = data['editor_key']
        editor = person_data editor_key
        if editor.nil?
          output.insert 2, editor_key
        else
          editor_name = [
            editor.dig('presentational_name', 'givenName'),
            editor.dig('presentational_name', 'familyName'),
          ].compact.join ' '
          out = "Edited by #{person_link(editor_key, editor_name)}"
          output.insert 2, out
        end

        output.flatten
              .compact
              .reject { |part| part.strip == '' }
              .join('. ')
              .sub(/\.{2,}/, '.') + '.'
      end

      def source_language(source_key, edition_key = nil, volume_key = nil)
        key = SourceDocument.build_identifier source_key, edition_key, volume_key
        drop(key).language
      end

      def source_presentational_name(source_key, edition_key = nil, volume_key = nil)
        key = SourceDocument.build_identifier source_key, edition_key, volume_key
        drop(key).presentational_name
      end

      def source_link(key, display_text)
        data_record_link(key, display_text: display_text)
      end

      def source_reference(key, display_text)
        data_record_reference(key, display_text: display_text)
      end

      def source_url(key) = data_record_url(key)

      private

      def drop_class = PersonDrop
    end
  end
end
Liquid::Template.register_filter HistoricalDiary::JekyllLayer::SourceFilters
