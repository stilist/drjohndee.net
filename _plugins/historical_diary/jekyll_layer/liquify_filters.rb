# License information copied from
# https://github.com/gemfarmer/jekyll-liquify/blob/92b6b5b114fb13a5ef1e6fea8d71aaa7731ee551/LICENSE
#
# > As a work of the United States government, this project is in the public
# > domain within the United States.
# >
# > Additionally, we waive copyright and related rights in the work worldwide
# > through the [CC0 1.0 Universal public domain dedication](https://creativecommons.org/publicdomain/zero/1.0/).
#
# @see https://github.com/gemfarmer/jekyll-liquify/blob/master/lib/jekyll-liquify.rb
module HistoricalDiary
  module JekyllLayer
    module LiquidFilters
      def liquify(input)
        Liquid::Template.parse(input).render(@context)
      end
    end
  end
end
Liquid::Template.register_filter(HistoricalDiary::JekyllLayer::LiquidFilters)
