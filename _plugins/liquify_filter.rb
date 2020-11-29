# @see https://github.com/gemfarmer/jekyll-liquify/blob/master/lib/jekyll-liquify.rb
# @see https://stackoverflow.com/a/17046748/672403
module LiquidFilter
  def liquify(input)
    Liquid::Template.parse(input).render(@context)
  end
end

Liquid::Template.register_filter(LiquidFilter)
