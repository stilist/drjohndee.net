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

require "forwardable"
require "jekyll"
require_relative "utilities"

module HistoricalDiary
  module JekyllLayer
    class SourceDrop < Jekyll::Drops::Drop
      include Jekyll::Filters::URLFilters
      include Utilities

      mutable false

      def initialize(identifier, context:)
        @identifier = identifier

        @context = context
        @site = context.registers[:site]

        super record
      end

      # Provides all available metadata for a specific source, resolving data
      # from most-specific (a volume) to least-specific (the work in general).
      def record
        # The output shouldn't have any nested properties, so delete the
        # edition's `volumes` property if present.
        #
        # @note This is destructive, so `edition` has to be `#dup`ed to avoid
        #   changing the actual `source_data`.
        _edition = edition&.dup || {}
        _edition.delete("volumes")

        _work = work || {}
        _volume = volume || {}
        # Each `#merge`d `Hash` overwrites existing values, so go from least-
        # to most-specific.
        _work.merge(_edition).merge(_volume)
      end
      alias_method :fallback_data, :record
      private :record

      def edition
        source_data.dig("editions", edition_key)
      end

      def permalink
        relative_url("sources/#{source_key.downcase}.html")
      end

      def volume
        return if edition.nil?

        edition.dig("volumes", volume_key)
      end

      def work
        source_data["work"]
      end

      private
        attr_reader :identifier

        def edition_key
          identifier.split(", ")[1]
        end

        def source_key
          identifier.split(", ")[0]
        end

        def volume_key
          identifier.split(", ")[2]
        end

        def source_data
          site_object.data["sources"].fetch(source_key)
        rescue KeyError
          Jekyll.logger.error "SourceDrop:", "'#{source_key}' doesn't match any records"
          {
            "editions" => {}
          }
        end
    end
  end
end
