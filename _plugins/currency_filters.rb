# frozen_string_literal: true

module CurrencyFilter
  include ::DataCollection

  def currency_tag(input, display_text, date = nil)
    if date.is_a?(Integer)
      date = Date.new(date)
    elsif date.is_a?(String)
      date = Date.new(*date.split('-'))
    end
    date ||= @context.registers[:page]['date']

    currency, raw_value = input.match(/\A([A-Z]{3})\s(.+)\z/).captures
    method = "currency_#{currency.downcase}"

    classes = %w(
      data-money
      data-money--#{currency || 'unknown'}
    ).join(' ')

    if respond_to?(method, :include_private)
      value = send(method, raw_value)

      if !date.nil?
        url = "https://www.wolframalpha.com/input/?i=#{currency}+#{value}+inflation+since+#{date.to_date}"
      end

      microdata = <<~EOM
        <meta itemprop=currency content='#{currency}'>
        <span itemprop=value content='#{value}'>#{display_text}</span>
      EOM
      shared_metadata = "class='#{classes}' itemscope itemtype=http://schema.org/MonetaryAmount"

      if url
        <<~EOM
        <a href=#{url} #{shared_metadata}>#{microdata}</a>
        EOM
      else
        <<~EOM
        <span #{shared_metadata}>
          #{microdata}
        </span>
        EOM
      end
    else
      <<~EOM
      <span class='#{classes} #{UNKNOWN_REFERENCE_CLASS}'>#{display_text}</span>
      EOM
    end
  end

  private

  # @see https://en.wikipedia.org/w/index.php?title=Coins_of_the_pound_sterling&oldid=885599694#Pre-decimal_coinage
  GBP_SHILLING = 1.0
  GBP_SOVEREIGN = GBP_SHILLING * 20
  GBP_PENNY = GBP_SHILLING / 12
  GBP_DENOMINATIONS = {
    'guinea' => GBP_SHILLING * 21,
    'pound' => GBP_SOVEREIGN,
    'sovereign' => GBP_SOVEREIGN,
    'noble' => GBP_SHILLING * 6 + GBP_PENNY * 8,
    'crown' => GBP_SHILLING * 5,
    'half crown' => GBP_SHILLING * 2 + GBP_PENNY * 6,
    'florin' => GBP_SHILLING * 2,
    'shilling' => GBP_SHILLING,
    'pence' => GBP_PENNY,
    'farthing' => GBP_PENNY / 4,
  }.freeze
  # @note Spaces must be replaced with '\s' because the `/x` flag makes the
  #   regular expression ignore space and tab characters in the pattern--if the
  #   pattern is meant to match spaces, they must be encoded as `\s`.
  CURRENCY_KEYS = GBP_DENOMINATIONS.keys
   .map { |k| k.gsub(/\s+/, '\s') }
  # "2 guineas 1 half crown 3 shillings"
  # #=> [["2", "guinea"], ["1", "half crown"], ["3", "shilling"]]
  CURRENCY_PATTERN = /
    (\d+)
    \s+
    (#{CURRENCY_KEYS.join('|')})
  /x
  def currency_gbp(text)
    parts = text.scan(CURRENCY_PATTERN)
    parts.reduce(0) do |memo, part|
      string, denomination = part
      sanitized = denomination.strip.sub(/s\z/, '')
      value = string.to_i * GBP_DENOMINATIONS[sanitized] / GBP_SOVEREIGN

      memo + value
    end
  end
end
Liquid::Template.register_filter(CurrencyFilter)
