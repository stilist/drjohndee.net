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
    # Generate Jekyll Pages for entries in the `people` Data Files collection.
    class PersonPageGenerator < Jekyll::Generator
      include DataPageGenerator

      safe true

      def drop_class = PersonDrop
      def page_class = PersonPage
    end

    # Generate a Jekyll Page for an entry in the `people` Data Files
    # collection.
    class PersonPage < Jekyll::Page
      include DataPage

      def drop_class = PersonDrop
    end
  end
end
