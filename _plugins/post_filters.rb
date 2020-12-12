# frozen_string_literal: true

require 'jekyll'

module PostFilters
  include ::DataCollection

  def post_tag(key, display_text = nil)
    post = @context.
      registers[:site].
      collections['posts'].
      docs.
      find { |record| record.basename == "#{key}.html" }
    return key if post.nil?

    url = "{% post_url #{key} %}"
    return "<a href=#{url}>#{display_text}</a>" if !display_text.nil?

    date = post.date.strftime('%F')
    country = find_post_country(post)
    liquify(%{<a href=#{url}>{{ "#{date}" | time_tag: "#{country}", "datePublished" }}</a>})
  end

  private

  def find_post_country(post)
    location = post.data['location']
    if !location.nil?
      country = data_collection_entry('places', location)&.dig('country')
    end

    if country.nil?
      author = post.data['author']
      country = data_collection_entry('people', author)&.dig('country')
    end

    country
  end
end

Liquid::Template.register_filter(PostFilters)
