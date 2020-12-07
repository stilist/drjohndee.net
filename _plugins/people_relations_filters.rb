# frozen_string_literal: true

require 'jekyll'

module Jekyll
  class PeopleRelations < Generator
    safe true

    FLAT_TYPES = %w[
      knows
      relatedTo
      siblings
      spouses
    ].freeze
    RELATIONSHIPS = FLAT_TYPES
      .map { |type| [type, type] }
      .to_h
      .merge({
        'children' => 'parents',
        'parents' => 'children',
      }).freeze
    def generate(site)
      @collection = site.data['people']
      @collection.each do |key, data|
        RELATIONSHIPS.each do |from_type, to_type|
          next if !data.key?(from_type)

          data[from_type].each do |related_key|
            apply_relationship(key, related_key, to_type)
          end
        end
      end

      types = RELATIONSHIPS.keys.freeze
      @collection.each do |key, data|
        if (data.keys & types).empty?
          ::Jekyll.logger.info('Jekyll::PeopleRelations:',
                               "#{key} doesn't have any relationships defined.")
        end
      end

      site.data['people'] = @collection
    end

    private

    def apply_relationship(from_key, to_key, target_type)
      if !@collection.key?(to_key)
        ::Jekyll.logger.warn('Jekyll::PeopleRelations:',
                             "#{from_key} has #{target_type} relationship with unknown person '#{to_key}'.")
        return
      end

      @collection[to_key][target_type] ||= []
      if @collection[to_key][target_type].include?(from_key)
        ::Jekyll.logger.debug('Jekyll::PeopleRelations:',
                              "'#{to_key}' already has #{target_type} relationship with '#{from_key}'.")
        return
      end

      ::Jekyll.logger.debug('Jekyll::PeopleRelations:',
                            "'#{to_key}' now has #{target_type} relationship with '#{from_key}'.")

      @collection[to_key][target_type] << from_key
    end
  end
end
