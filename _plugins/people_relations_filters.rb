# frozen_string_literal: true

require 'jekyll'

module Jekyll
  class PeopleReverseRelations < Generator
    priority :highest
    safe true

    FLAT_RELATIONSHIPS = %w[
      knows
      relatedTo
      siblings
      spouses
    ].freeze
    RELATIONSHIP_PAIRS = {
      'children' => 'parents',
      'parents' => 'children',
    }.freeze
    def generate(site)
      @collection = site.data['people']
      @collection.each do |id, person|
        ::Jekyll.logger.debug('Jekyll::PeopleReverseRelations:',
                              "Defining flat relationships for #{id}...")
        FLAT_RELATIONSHIPS.each do |type|
          next if !person.key?(type)

          person[type].each do |related_id|
            apply_relationship(id, related_id, type)
            ::Jekyll.logger.debug('Jekyll::PeopleReverseRelations:',
                                  "* #{id} has '#{type}' relationship with #{related_id}.")
          end

          ::Jekyll.logger.debug('Jekyll::PeopleReverseRelations:',
                                "* #{id} has '#{type}' relationships with: #{person[type].join(", ")}")
        end

        ::Jekyll.logger.debug('Jekyll::PeopleReverseRelations:',
                              "Defining pair relationships for #{id}...")
        RELATIONSHIP_PAIRS.each do |source_type, target_type|
          next if !person.key?(source_type)

          person[source_type].each do |related_id|
            apply_relationship(id, related_id, target_type)
            ::Jekyll.logger.debug('Jekyll::PeopleReverseRelations:',
                                  "* #{id} has '#{source_type}' relationship with #{related_id}.")
          end

          ::Jekyll.logger.debug('Jekyll::PeopleReverseRelations:',
                                "* #{id} has '#{source_type}<->#{target_type}' relationships with: #{person[source_type].join("; ")}")
        end
      end

      site.data['people'] = @collection
    end

    private

    def apply_relationship(source_id, target_id, target_type)
      if !@collection.key?(target_id)
        ::Jekyll.logger.warn('Jekyll::PeopleReverseRelations:',
                             "* #{source_id} has '#{target_type}' relationship with unknown person (#{target_id}).")
        return
      end

      @collection[target_id][target_type] ||= []
      if @collection[target_id][target_type].include?(source_id)
        ::Jekyll.logger.debug('Jekyll::PeopleReverseRelations:',
                              "  * #{target_id} already has '#{target_type}' relationship with #{source_id}.")
        return
      end

      ::Jekyll.logger.debug('Jekyll::PeopleReverseRelations:',
                            "* #{target_id} now has '#{target_type}' relationship with #{source_id}.")

      @collection[target_id][target_type] << source_id
    end
  end
end
