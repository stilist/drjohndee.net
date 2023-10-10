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

require 'jekyll'

# :nodoc:
def resolve_path(path) = File.expand_path(path, __dir__)

# <tt>HistoricalDiary</tt> is a Jekyll plugin for rendering a diary. It
# generates pages for relevant metadata, and offers Liquid tags for inserting
# links and building structured data.
#
# The plugin relies on a ‘source document’
# collection[https://jekyllrb.com/docs/step-by-step/09-collections/], with
# plain-text files broken into pages. The source documents can be
# transcluded[https://en.wikipedia.org/wiki/Transclusion] into
# posts[https://jekyllrb.com/docs/posts/] using the plugin’s
# +transclusion+ and +transclusion_with_commentary+
# {Liquid tags}[https://shopify.dev/docs/api/liquid/tags]. The transcluded text
# can be annotated using Jekyll
# {Data Files}[https://jekyllrb.com/docs/datafiles/]. The plugin also provides
# filters[https://jekyllrb.com/docs/step-by-step/02-liquid/#filters] for rich
# cross-links.
module HistoricalDiary
  autoload :Annotation,         resolve_path('historical-diary/annotation')
  autoload :SourceDocument,     resolve_path('historical-diary/source_document')
  autoload :SourceDocumentPage, resolve_path('historical-diary/source_document_page')
  autoload :StaticMap,          resolve_path('historical-diary/static_map')
  autoload :VERSION,            resolve_path('historical-diary/version')
  autoload :Transclusion,       resolve_path('historical-diary/transclusion')
end
