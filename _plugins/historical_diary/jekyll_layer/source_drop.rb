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

require 'forwardable'

module HistoricalDiary
  module JekyllLayer
    # Combined <tt>SourceDocument</tt> and `source` Data File, for use in
    # Jekyll-specific code.
    class SourceDrop < Jekyll::Drops::Drop
      include Drop

      extend Forwardable
      def_delegators :source_document,
                     :markup_redactions_for_page,
                     :notes_for_page,
                     :page,
                     :page_numbers

      mutable false

      PLURAL_NOUN = 'sources'
      SINGULAR_NOUN = 'source'
      DATA_KEY = "#{SINGULAR_NOUN}_key".freeze

      # Provides all available metadata for a specific source, resolving data
      # from most-specific (a volume) to least-specific (the work in general).
      def record
        return @record if defined?(@record)

        # Each `#merge`d `Hash` overwrites existing values, so go from least-
        # to most-specific.
        @record = work.merge(edition).merge volume
      end

      def edition
        data = source_data.dig('editions', edition_key)&.dup || {}
        # The output shouldn't have any nested properties, so delete the
        # edition's `volumes` property if present.
        data.delete 'volumes'
        data
      end

      def volume = edition.dig('volumes', volume_key)&.dup || {}

      def work = source_data['work']&.dup || {}

      def page(requested) = source_document[requested]

      def language = record['language']

      def presentational_name_language = record['name_language'] || language

      def presentational_name
        return @presentational_name if defined? @presentational_name

        annotations = redactions(SINGULAR_NOUN)['reflows']
        annotation = Annotation.new(record['name'],
                                    annotations: annotations)
        @presentational_name = annotation.text
      end

      private

      attr_reader :identifier

      def parsed_identifier = SourceDocument.parse_identifier(identifier)
      def edition_key = source_document&.edition_key || parsed_identifier[1]
      def source_key = source_document&.source_key || parsed_identifier[0]
      def volume_key = source_document&.volume_key || parsed_identifier[2]

      def redactions(collection) = data_for_type("#{collection}_redactions")

      def source_data
        return @source_data if defined?(@source_data)

        @source_data = site_object.data[PLURAL_NOUN].fetch sanitize_key(source_key)
      rescue KeyError
        Jekyll.logger.error self.class.name do
          "'#{source_key}' doesn't match any records"
        end

        @source_data = {
          'editions' => {},
        }
      end

      def source_document_collection_entry
        documents = site_object.collections['source_documents'].docs
        documents.find do |doc|
          [
            doc.basename_without_ext,
            sanitize_key(doc.basename_without_ext),
          ].include? key
        end
      end

      # Wrapper around an underlying <tt>SourceDocument</tt>.
      def source_document
        return @source_document if defined? @source_document

        @source_document = nil
        return if source_document_collection_entry.nil?

        @source_document = SourceDocument.new identifier,
                                              raw_text: source_document_collection_entry.content,
                                              redactions: redactions('source_document')
      end
    end
  end
end
