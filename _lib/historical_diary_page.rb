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

class HistoricalDiaryPage < ::Jekyll::Page
  # Copied from `Jekyll::Document`, under the MIT license.
  #
  # @see https://github.com/jekyll/jekyll/blob/a988f9da145262efeb79e285c0bbce62b82ea002/lib/jekyll/document.rb#L342-L348
  # @see https://github.com/jekyll/jekyll/blob/a988f9da145262efeb79e285c0bbce62b82ea002/LICENSE
  def <=>(other)
    return nil unless other.respond_to?(:data)

    cmp = data["date"] <=> other.data["date"]
    cmp = path <=> other.path if cmp.nil? || cmp.zero?
    cmp
  end

  def url_placeholders
    {
      :path => @dir,
      :basename => basename,
      :output_ext => output_ext,
    }
  end
end
