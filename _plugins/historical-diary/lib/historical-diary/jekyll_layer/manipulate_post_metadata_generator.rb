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
    # Overrides Jekyll’s default title for posts (taken from the post’s
    # filename), replacing it with the post’s publish date.
    class ManipulatePostMetadataGenerator < Jekyll::Generator
      safe true
      priority :highest

      def generate(site)
        posts = site.posts.docs
        posts.each do |post|
          date = post.data['date']
          post.data['title'] = date.strftime '%B %-d, %Y'
        end
      end
    end
  end
end
