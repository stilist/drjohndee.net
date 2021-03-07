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
require_relative '../_lib/collections'
require_relative '../_lib/legal_year'
require_relative '../_lib/timestamp_range'

module HistoricalDiary
  module DataFilters
    include ::DataCollection
    include LegalYear

    def annotate_content(object)
      path_segments = object['relative_path'].split(File::SEPARATOR)
      timestamp = File.basename(path_segments.last, '.md')
      annotations = @context.registers[:site]
        .data['annotations']
        .dig(escape_key(object['source_key']),
             escape_key(timestamp),
             'annotations')
      return object.content if annotations.nil?

      content = object.content.clone

      # @note This approach is only usable for exact text matches; it would
      #   need to be much more complicated to work with the full Web Annotation
      #   set of selectors.
      annotations.each do |annotation|
        exact_replacement = annotation.dig('body', 'value')
        next if exact_replacement.nil?
        next if annotation['selectors'].nil?

        annotation['selectors'].each do |selector|
          if selector['exact'].nil? || selector['exact'] == ''
            Jekyll.logger.warn("Bad annotation data for #{object.relative_path}")
            Jekyll.logger.info(selector.inspect)
            next
          end

          prefix = Regexp.escape(selector['prefix']) if selector['prefix']
          exact = "(#{Regexp.escape(selector['exact'])})"
          suffix = Regexp.escape(selector['suffix']) if selector['suffix']
          pattern = [
            prefix,
            exact,
            suffix,
          ].compact.join('')
          replacement = [
            selector['prefix'],
            exact_replacement,
            selector['suffix'],
          ].compact.join('')

          content.gsub!(/#{pattern}/, replacement)
        end
      end

      content
    end

    def attribute_from_record(record, attribute)
      return record[attribute] if record.key?(attribute)

      source = source_data(record['source_key'])
      return nil if source.nil?

      work = source['work']
      edition = source.dig('editions', record['edition_key']) || {}
      volume = edition.dig('volumes', record['volume_key']) || {}

      volume[attribute] || edition[attribute] || work[attribute]
    end

    def biography_for_person(key)
      matches = []

      records_by_source = data_collection_records('biography')
      records_by_source.each do |source_key, records|
        next if records.nil?

        records.each do |record|
          next if !record.key?('people')
          escaped_people_keys = record['people'].map { |person_key| escape_key(person_key) }
          matches << record if escaped_people_keys.include?(key)
        end
      end

      matches
    end

    def collection_entry(key, collection_name)
      data_collection_record(collection_name, key)
    end

    def collection_entry_url(key, collection_name)
      data_collection_record_url(collection_name, key)
    end

    def commentary_for_date(timestamp)
      transclusions_for_timestamp('commentary', timestamp)
    end

    def commentary_keys_for_year(year)
      legal_year_timestamp = [
        legal_year_start(year),
        legal_year_end(year),
      ].map { |timestamp| timestamp.strftime('%F') }
        .join('/')

      commentary_for_date(legal_year_timestamp)
    end

    def context_for_date(timestamp)
      transclusions_for_timestamp('context', timestamp)
    end

    def context_keys_for_year(year)
      legal_year_timestamp = [
        legal_year_start(year),
        legal_year_end(year),
      ].map { |timestamp| timestamp.strftime('%F') }
        .join('/')

      context_for_date(legal_year_timestamp)
    end

    def dates_for_person(key)
      dates = @context.registers[:site]
        .data['dates_for_people'][key]
      return [] if dates.nil?
      dates.uniq.sort
    end

    def date_to_url(date)
      # @see `HistoricalDiary::DayPage`
      date.strftime('/%Y/%m/%d.html')
    end

    def escape_data_key(key)
      escape_key(key)
    end

    def get_author_key(object, edition_key=nil, volume_key=nil)
      return object['author_key'] if object.key?('author_key')

      source = source_data(object['source_key'])
      return nil if source.nil?

      work = source['work']
      edition = source.dig('editions', edition_key) || {}
      volume = edition.dig('volumes', volume_key) || {}

      volume['author_key'] || edition['author_key'] || work['author_key']
    end

    def legal_year_has_content(year)
      known_dates = @context.registers[:site]
        .data['generated_dates'] || []
      candidates = legal_year(year)
      !(candidates & known_dates).empty?
    end

    def license_url(license_key)
      return if !license_key.is_a?(String)

      version = license_key.match(/\s(\d+(?:\.\d+)?\+?)/)
      version = version[1].strip if !version.nil?
      license_shorthand = license_key.sub(/\s*#{version}/, '')

      case license_shorthand
      when 'CC0' then "https://creativecommons.org/publicdomain/zero/#{version}"
      when 'CC BY-SA' then "https://creativecommons.org/licenses/by-sa/#{version}"
      else license_key
      end
    end

    def lifespan_years(person_key)
      record = person_data(person_key)
      return [] if record.nil?
      return [] if !record.key?('birth_date')
      return [] if !record.key?('death_date')

      birthYear = record['birth_date'].split('-').first.to_i
      deathYear = record['death_date'].split('-').first.to_i

      (birthYear..deathYear).to_a
    end

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
      source = source_data(source_key)
      return source_key if source.nil?

      work = source['work']

      edition = source.dig('editions', edition_key)
      if edition.nil? && source['editions'].length == 1
        edition = source['editions'].values.first
      end
      edition ||= {}

      volume = edition.dig('volumes', volume_key) if !volume_key.nil?
      volume ||= {}

      # Tagging this as an actual date improves the screenreader experience.
      publication_date = volume['date'] || edition['date']
      if publication_date
        year = publication_date.match(/\d{4}/)
        publication_date = "<time datetime='#{publication_date}'>#{year}</time>"
      end

      publishing_info = [
        volume['city'] || edition['city'],
        volume['publisher'] || edition['publisher'],
        publication_date,
        location&.sub('-', '–'),
      ].compact.join(', ')
      publishing_info[0] = publishing_info[0].capitalize if publishing_info.length > 0

      source_name = volume['name'] || edition['name'] || work['name']
      output = [
        data_record_link('sources', source_key, source_name),
        publishing_info,
      ]
      output.insert(1, "Volume #{volume['volume_number']}") if volume.key?('volume_number')

      author_key ||= get_author_key({}, editor_key, volume_key)
      author = person_data(author_key)
      if author.nil?
        output.unshift(author_key)
      else
        author_name = [
          author.dig('presentational_name', 'familyName'),
          author.dig('presentational_name', 'givenName'),
        ].compact.join(', ')
        output.unshift(person_link(author_key, author_name))
      end

      editor_key = volume['editor_key'] || edition['editor_key'] || work['editor_key']
      editor = person_data(editor_key)
      if editor.nil?
        output.insert(2, editor_key)
      else
        editor_name = [
          editor.dig('presentational_name', 'givenName'),
          editor.dig('presentational_name', 'familyName'),
        ].compact.join(' ')
        out = "Edited by " + data_record_link('people', editor_key, editor_name)
        output.insert(2, out)
      end

      output.flatten.
        compact.
        reject { |part| part.strip == '' }.
        join('. ').
        sub('..', '.') + '.'
    end

    # This extracts word-initial characters in an internationalized, RTL-safe
    # way, using `#unicode_normalize` and `#each_grapheme_cluster`.
    #
    # Examples:
    #   "test" => "t"
    #   "Test Abc" => "TA"
    #   "חַנִּיאֵל" => "חַ"
    def person_initials(key, maximum_characters = 2)
      person_name(key)
        .split(' ')
        .map { |word| word.unicode_normalize(:nfc).each_grapheme_cluster.first }
        .first(maximum_characters)
        .join('')
    end

    def person_link(key, display_text)
      data_record_link('people', key, display_text)
    end

    # @note This returns the name in the order the parts are written in the
    #   data file--if data is ordered with `familyName` before `givenName`,
    #   the output will also have `familyName` first. This helps a bit with
    #   internationalization, as some cultures (like Chinese and Hungarian)
    #   prefer the family name first, and others (like Australian and Spanish).
    #   It's not a substitute for proper internationalization support, though.
    def person_name(key, name_key = 'presentational_name')
      return '' if key.nil?

      record = person_data(key)
      return '' if record.nil?

      parts = record[name_key]&.values
      return '' if parts.nil?

      parts.join(' ')
    end

    def person_reference(key, display_text)
      data_record_reference('people', key, display_text)
    end

    def relevant_footnotes(timestamp)
      transclusions_for_timestamp('footnotes', timestamp)
    end

    def source_material_for_date(timestamp)
      timestamp_range = TimestampRange.new(timestamp)

      candidates = @context.registers[:site].pages.
        select { |document| document.data.key?('timestamp_range') }
      candidates.select do |document|
        document.data['timestamp_range'].intersect?(timestamp_range)
      end
    end

    def data_record_tag_attributes(key, collection_name)
      {
        "class" => "data-entity data-#{collection_name}",
        "dataKey" => "#{collection_name}/#{slugify_key(key)}",
      }.freeze
    end

    private

    def data_record_link(collection_name, key, display_text = nil)
      url = data_collection_record_url(collection_name, key)

      attributes = data_record_tag_attributes(key, collection_name)
      "<a " \
        "href='#{url}' " \
        "class='#{attributes['class']}' " \
        "data-key='#{attributes['dataKey']}'>#{display_text || key}</a>"
    end

    def data_record_reference(collection_name, key, display_text = nil)
      attributes = data_record_tag_attributes(key, collection_name)
      "<span " \
        "class='#{attributes['class']}' " \
        "data-key='#{attributes['dataKey']}'>#{display_text || key}</span>"
    end

  end
end
Liquid::Template.register_filter(HistoricalDiary::DataFilters)
