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
    # Combined <tt>SourceDocument</tt> and `source` Data File, for use in
    # Jekyll-specific code.
    class SourceDrop < Jekyll::Drops::Drop
      include Drop

      mutable false

      PLURAL_NOUN = "sources"
      SINGULAR_NOUN = "source"
      DATA_KEY = "#{SINGULAR_NOUN}_key"

      # Provides all available metadata for a specific source, resolving data
      # from most-specific (a volume) to least-specific (the work in general).
      def record
        return @record if defined?(@record)

        # The output shouldn't have any nested properties, so delete the
        # edition's `volumes` property if present.
        #
        # @note This is destructive, so `edition` has to be `#dup`ed to avoid
        #   changing the actual `source_data`.
        _edition = edition&.dup || {}
        _edition.delete "volumes"

        _work = work || {}
        _volume = volume || {}
        # Each `#merge`d `Hash` overwrites existing values, so go from least-
        # to most-specific.
        @record = _work.merge(_edition).merge _volume
      end

      def edition = source_data.dig("editions", edition_key)

      def page_numbers = source_document&.page_numbers

      def presentational_name
        Redactions.new(record["name"],
                       redactions: redactions(SINGULAR_NOUN)).text
      end

      def volume
        return if edition.nil?

        edition.dig "volumes", volume_key
      end

      def work = source_data["work"]

      private
        attr_reader :identifier

        def parsed_identifier = SourceDocument.parse_identifier(identifier)
        def edition_key = source_document&.edition_key || parsed_identifier[1]
        def source_key = source_document&.source_key || parsed_identifier[0]
        def volume_key = source_document&.volume_key || parsed_identifier[2]

        def redactions(collection) = data_for_type("#{collection}_redactions")

        def source_data
          site_object.data[PLURAL_NOUN].fetch source_key
        rescue KeyError
          Jekyll.logger.error "#{self.class.name}:",
                              "'#{source_key}' doesn't match any records"

          {
            "editions" => {},
          }
        end

        def source_document_collection_entry
          documents = site_object.collections["source_documents"].docs
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

          _redactions = redactions "source_documents", identifier
          @source_document = SourceDocument.new identifier,
                                                raw_text: source_document_collection_entry.content,
                                                redactions: _redactions
        end
    end
  end
end
