# frozen_string_literal: true

require 'test/unit'
require_relative '../../../lib/historical-diary/source_documents/page_range'

class TestSourceDocumentsPageRange < Test::Unit::TestCase
  def instance(keys)
    HistoricalDiary::SourceDocuments::PageRange.new(keys)
  end

  def test_single_invalid_page
    assert_raise HistoricalDiary::SourceDocuments::InvalidPageRangeError do
      instance([])['1']
    end
  end

  def test_single_valid_roman_numeral
    instance = HistoricalDiary::SourceDocuments::PageRange.new(['ⅰ'])
    assert_equal %w[ⅰ], instance['ⅰ']
  end

  def test_single_valid_western_arabic_numeral
    instance = HistoricalDiary::SourceDocuments::PageRange.new(['1'])
    assert_equal %w[1], instance['1']
  end

  def test_single_valid_eastern_arabic_numeral
    instance = HistoricalDiary::SourceDocuments::PageRange.new(['١'])
    assert_equal %w[١], instance['١']
  end

  def test_invalid_range_end
    assert_raise HistoricalDiary::SourceDocuments::InvalidPageRangeError do
      instance(['1'])['1', '2']
    end
  end

  def test_reversed_range
    assert_raise HistoricalDiary::SourceDocuments::InvalidPageRangeError do
      instance(%w[1 2])['2', '1']
    end
  end

  def test_simple_range
    instance = HistoricalDiary::SourceDocuments::PageRange.new(%w[1 2])
    assert_equal %w[1 2], instance['1', '2']
  end

  def test_skipped_range
    instance = HistoricalDiary::SourceDocuments::PageRange.new(%w[1 2 3])
    assert_equal %w[1 2 3], instance['1', '3']
  end

  def test_cross_digit_set
    instance = HistoricalDiary::SourceDocuments::PageRange.new(%w[ⅰ 1 ١])
    assert_equal %w[ⅰ 1 ١], instance['ⅰ', '١']
  end

  def test_gap_in_range
    instance = HistoricalDiary::SourceDocuments::PageRange.new(%w[1 5])
    assert_equal %w[1 5], instance['1', '5']
  end
end
