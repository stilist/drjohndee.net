# frozen_string_literal: true

require 'test/unit'
require_relative '../../lib/historical-diary/transclusion'

class TestTransclusion < Test::Unit::TestCase
  INVALID_UTF8 = "\xC3\x28"
  NFC = "\u00e9" # 'é'
  NFD = "e\u0301" # 'é'
  STRING = 'The quick brown fox jumps over the lazy dog.'

  def test_error_if_text_is_not_string
    assert_raise(HistoricalDiary::InvalidTransclusionError) do
      HistoricalDiary::Transclusion.new(
        nil,
        text_start: 'quick',
        text_end: 'dog'
      )
    end
  end

  def test_error_if_no_match
    assert_raise(HistoricalDiary::InvalidTransclusionError) do
      HistoricalDiary::Transclusion.new(
        STRING,
        text_start: 'cat',
        text_end: 'dog'
      ).text
    end
  end

  def test_start_is_required
    assert_raise(HistoricalDiary::InvalidTransclusionError) do
      HistoricalDiary::Transclusion.new(
        STRING,
        text_start: nil,
        text_end: 'quick'
      )
    end
  end

  def test_start_only
    transclusion = HistoricalDiary::Transclusion.new(
      STRING,
      text_start: 'quick',
      text_end: nil
    )

    assert_equal 'quick', transclusion.text
  end

  def test_normalizing_invalid_utf8_text
    assert_raise(HistoricalDiary::InvalidTransclusionError.new('Invalid UTF-8')) do
      HistoricalDiary::Transclusion.new(
        INVALID_UTF8,
        text_start: 'quick',
        text_end: nil
      ).text
    end
  end

  def test_normalizing_invalid_utf8_selector
    assert_raise(HistoricalDiary::InvalidTransclusionError.new('Invalid UTF-8')) do
      HistoricalDiary::Transclusion.new(
        STRING,
        text_start: INVALID_UTF8,
        text_end: nil
      ).text
    end
  end

  def test_start_and_end
    transclusion = HistoricalDiary::Transclusion.new(
      STRING,
      text_start: 'quick',
      text_end: 'lazy'
    )

    assert_equal 'quick brown fox jumps over the lazy', transclusion.text
  end

  def test_uses_first_match
    transclusion = HistoricalDiary::Transclusion.new(
      "quick brown lazy #{STRING}",
      text_start: 'quick',
      text_end: 'lazy'
    )

    assert_equal 'quick brown lazy', transclusion.text
  end

  def test_identical_start_and_end_without_match
    assert_raise(HistoricalDiary::InvalidTransclusionError) do
      HistoricalDiary::Transclusion.new(
        STRING,
        text_start: 'quick',
        text_end: 'quick'
      ).text
    end
  end

  def test_identical_start_and_end_with_match
    transclusion = HistoricalDiary::Transclusion.new(
      "quick cat #{STRING}",
      text_start: 'quick',
      text_end: 'quick'
    )

    assert_equal 'quick cat The quick', transclusion.text
  end

  def test_prefix
    transclusion = HistoricalDiary::Transclusion.new(
      STRING,
      prefix: 'quick ',
      text_start: 'brown',
      text_end: 'lazy'
    )

    assert_equal 'brown fox jumps over the lazy', transclusion.text
  end

  def test_prefix_with_implicit_whitespace
    transclusion = HistoricalDiary::Transclusion.new(
      STRING,
      prefix: 'quick',
      text_start: 'brown',
      text_end: 'lazy'
    )

    assert_equal 'brown fox jumps over the lazy', transclusion.text
  end

  def test_suffix
    transclusion = HistoricalDiary::Transclusion.new(
      STRING,
      text_start: 'brown',
      text_end: 'lazy',
      suffix: ' dog'
    )

    assert_equal 'brown fox jumps over the lazy', transclusion.text
  end

  def test_suffix_with_implicit_whitespace
    transclusion = HistoricalDiary::Transclusion.new(
      STRING,
      text_start: 'brown',
      text_end: 'lazy',
      suffix: 'dog'
    )

    assert_equal 'brown fox jumps over the lazy', transclusion.text
  end

  def test_prefix_and_suffix
    transclusion = HistoricalDiary::Transclusion.new(
      STRING,
      prefix: 'quick',
      text_start: 'brown',
      text_end: 'over',
      suffix: 'the'
    )

    assert_equal 'brown fox jumps over', transclusion.text
  end

  def test_multiline
    transclusion = HistoricalDiary::Transclusion.new(
      STRING.tr(' ', "\n"),
      text_start: 'quick',
      text_end: 'lazy'
    )

    assert_equal "quick\nbrown\nfox\njumps\nover\nthe\nlazy", transclusion.text
  end

  def test_regex_metacharacters_in_text
    text = 'Text with * and + and ? and . and | and \\ and ^ and $ characters.'
    transclusion = HistoricalDiary::Transclusion.new(
      text,
      text_start: 'with',
      text_end: 'characters'
    )

    assert_equal 'with * and + and ? and . and | and \\ and ^ and $ characters', transclusion.text
  end

  def test_metacharacters_in_text
    text = 'Text A*B+C DEF GHI J.K|L'
    transclusion = HistoricalDiary::Transclusion.new(
      text,
      text_start: 'A*B+C',
      text_end: 'J.K|L'
    )

    assert_equal 'A*B+C DEF GHI J.K|L', transclusion.text
  end

  def test_metacharacters_in_text_with_prefix_and_suffix
    text = 'Start [a+b*c] Middle End (x.y|z)'
    transclusion = HistoricalDiary::Transclusion.new(
      text,
      prefix: '[a+b*c]',
      text_start: 'Middle',
      text_end: 'End',
      suffix: '(x.y|z)'
    )

    assert_equal 'Middle End', transclusion.text
  end

  def test_escaped_whitespace_handling
    text = "Text with    multiple   spaces \ttabs and\nnewlines."
    transclusion = HistoricalDiary::Transclusion.new(
      text,
      text_start: 'with',
      text_end: 'and',
      suffix: 'newlines'
    )

    assert_equal "with    multiple   spaces \ttabs and", transclusion.text
  end

  def test_mixed_latin_cjk
    text = '这是一个 mixed text 与汉字 example.'
    transclusion = HistoricalDiary::Transclusion.new(
      text,
      text_start: 'mixed',
      text_end: '汉字'
    )

    assert_equal 'mixed text 与汉字', transclusion.text
  end

  def test_multibyte_glyphs
    text = 'Text with emoji 🌟 and diacritics éèêë.'
    transclusion = HistoricalDiary::Transclusion.new(
      text,
      text_start: '🌟',
      text_end: 'êë'
    )

    assert_equal '🌟 and diacritics éèêë', transclusion.text
  end

  def test_nfc_only
    text = STRING.sub('quick', NFC)
    transclusion = HistoricalDiary::Transclusion.new(
      text,
      text_start: NFC,
      text_end: 'brown'
    )

    assert_equal "#{NFC} brown", transclusion.text
  end

  def test_nfd_only
    text = STRING.sub('quick', NFD)
    transclusion = HistoricalDiary::Transclusion.new(
      text,
      text_start: NFD,
      text_end: 'brown'
    )

    assert_equal "#{NFC} brown", transclusion.text
  end

  def test_nfd_text_with_nfc_pattern
    text = STRING.sub('quick', NFD)
    transclusion = HistoricalDiary::Transclusion.new(
      text,
      text_start: NFC,
      text_end: 'brown'
    )

    assert_equal "#{NFC} brown", transclusion.text
  end

  def test_nfc_text_with_nfd_pattern
    text = STRING.sub('quick', NFD)
    transclusion = HistoricalDiary::Transclusion.new(
      text,
      text_start: NFD,
      text_end: 'brown'
    )

    assert_equal "#{NFC} brown", transclusion.text
  end

  def test_mixed_nfc_and_nfd
    text = STRING.sub('quick', "#{NFD}#{NFC}")
    transclusion = HistoricalDiary::Transclusion.new(
      text,
      text_start: "#{NFC}#{NFD}",
      text_end: 'brown'
    )

    assert_equal "#{NFC}#{NFC} brown", transclusion.text
  end
end
