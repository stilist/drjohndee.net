# frozen_string_literal: true

#--
# The life and times of Dr John Dee
# Copyright (C) 2023  Jordan Cole <feedback@drjohndee.net>
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
    # Generates a `Jekyll::Page` for each calendar year in the life of
    # `subject_person_key`.
    class YearPageGenerator < Jekyll::Generator
      include Shared::Config
      include Shared::Site

      safe true

      def generate(site)
        @year_documents = {}
        @site = site

        living_years.each_with_object({}) do |year, _memo|
          posts = posts_by_year[year.to_s] || []

          document = YearPage.new(year, posts:, site:)
          site.pages << document

          set_metadata_for_year year, document
        end
      end

      private

      def drop
        return @drop if defined? @drop

        return @drop = nil if key.nil?

        context = context_from_site @site
        # @note Without the parentheses this parses incorrectly and `@drop` is
        #   `nil`.
        @drop = PersonDrop.new(key, context:)
        unless @drop.exist?
          Jekyll.logger.warn self.class.name do
            'Configured subject_person_key does not exist in people Data Files'
          end
        end

        @drop
      end

      def key
        return @key if defined? @key

        @key = config! :subject_person_key
      rescue Shared::Config::ConfigIsMissingRequiredKeyError
        Jekyll.logger.warn self.class.name do
          'Plugin config needs a subject_person_key to generate year pages'
        end

        @key = nil
      end

      def living_years
        drop.living_years
      rescue NoMethodError
        Jekyll.logger.warn self.class.name do
          'Unable to retrieve lifespan for configured subject_person_key'
        end

        []
      end

      def posts_by_year
        return @posts_by_year if defined? @posts_by_year

        @posts_by_year = @site.posts.docs.each_with_object({}) do |post, memo|
          year = post.date.strftime '%Y'
          memo[year] ||= []
          memo[year] << post
        end
      end

      def set_metadata_for_year(year, document)
        @year_documents[year] = document

        previous_year = year - 1
        return unless @year_documents.key? previous_year

        @year_documents[year].data['previous'] = @year_documents[previous_year]
        @year_documents[previous_year].data['next'] = document
      end
    end
  end
end
