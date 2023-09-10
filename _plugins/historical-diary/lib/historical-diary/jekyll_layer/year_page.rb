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
    # `Jekyll::Page` for a given New Style year in the Gregorian calendar.
    class YearPage < Jekyll::Page
      # @note `Jekyll::Page` subclasses don't need to call `super`
      # rubocop:disable Lint/MissingSuper
      def initialize(year, posts:, site:)
        @posts = posts
        @site = site
        @year = year
        set_instance_variables

        set_up_data

        Jekyll.logger.debug self.class.name do
          "Generating year page at '#{@dir}/#{@name}'"
        end

        # @note Copied from `Jekyll::Page#initialize`.
        Jekyll::Hooks.trigger :pages, :post_init, self
      end
      # rubocop:enable Lint/MissingSuper

      def url_placeholders
        {
          path: @dir,
          basename:,
          output_ext:,
        }
      end

      def inspect = super.sub(/(>)/, " @year=#{@year}\\1")

      private

      attr_reader :posts, :type, :year

      def set_instance_variables
        @base = site.source
        @dir  = ''

        @basename = @year.to_s
        @ext      = '.html'
        @name     = "#{@basename}#{@ext}"

        @type = :years
      end

      def set_up_data
        @data = base_metadata.merge metadata_for_template
        @data.default_proc = proc do |_, key|
          site.frontmatter_defaults.find relative_path, type, key
        end
      end

      def base_metadata
        {
          'is_generated' => true,
          'last_modified_at' => Time.now.to_date,
          'layout' => 'year',
          'title' => year,
          'year' => year,
        }
      end

      def metadata_for_template
        (1..12).each_with_object({}) do |month_number, memo|
          memo['months'] ||= []
          memo['months'] << {
            'days' => days_in_month(month_number),
            'name' => Time.new(2000, month_number).strftime('%B'),
          }
        end
      end

      DAY_IN_SECONDS = 60 * 60 * 24
      private_constant :DAY_IN_SECONDS

      def days_in_month(month_number)
        next_month = if month_number == 12
                       Time.new(year + 1, 1)
                     else
                       Time.new(year, month_number + 1)
                     end
        last_day = (next_month - DAY_IN_SECONDS).mday

        (1..last_day).map do |day|
          date = Time.new(year, month_number, day)
          metadata_for_date(date)
        end
      end

      def metadata_for_date(date)
        timestamp = date.strftime('%F')

        type = 'no-content'
        type = 'filler' if skipped_gregorian_date?(date)
        type = 'content' if dates_with_content.include?(timestamp)

        {
          'date' => date,
          # used to inject `<tr>` / `</tr>` for week rows
          'day_of_week' => date.wday,
          'url' => date.strftime('%Y/%m/%d.html'),
          'type' => type,
        }
      end

      def dates_with_content
        return @dates_with_content if defined? @dates_with_content

        @dates_with_content = posts.each_with_object(Set.new) do |post, memo|
          memo.add(post.date.strftime('%F'))
        end
      end

      JULIAN_END = Time.new(1582, 10, 4)
      GREGORIAN_START = Time.new(1582, 10, 15)

      def skipped_gregorian_date?(date)
        date > JULIAN_END && date < GREGORIAN_START
      end
    end
  end
end
