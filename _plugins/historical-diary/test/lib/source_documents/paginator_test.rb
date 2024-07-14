# frozen_string_literal: true

require 'test/unit'
require_relative '../../../lib/historical-diary/source_documents/paginator'

class TestSourceDocumentsPaginator < Test::Unit::TestCase
  def instance(raw_text)
    HistoricalDiary::SourceDocuments::Paginator.new(raw_text)
  end

  def test_no_text
    paginator = instance(nil)
    assert_equal({}, paginator.pages)
  end

  def test_blank_text
    paginator = instance('')
    assert_equal({}, paginator.pages)
  end

  def test_no_header
    paginator = instance('a')
    assert_equal({}, paginator.pages)
  end

  def test_invalid_header_page_word
    paginator = instance('[test 1]')
    assert_equal({}, paginator.pages)
  end

  def test_invalid_header_no_page_word
    paginator = instance('[1]')
    assert_equal({}, paginator.pages)
  end

  def test_invalid_header_no_number
    paginator = instance('[test]')
    assert_equal({}, paginator.pages)
  end

  def test_invalid_header_page_number_whitespace
    paginator = instance('[test  ]')
    assert_equal({}, paginator.pages)
  end

  def test_invalid_header_page_number_punctuation
    paginator = instance('[test .]')
    assert_equal({}, paginator.pages)
  end

  def test_bare_header_page
    paginator = instance('[page 1]')
    assert_equal({ '1' => nil }, paginator.pages)
  end

  def test_bare_header_folio
    paginator = instance('[folio 1]')
    assert_equal({ '1' => nil }, paginator.pages)
  end

  def test_bare_header_letter
    paginator = instance('[folio i]')
    assert_equal({ 'i' => nil }, paginator.pages)
  end

  def test_bare_header_number_and_letter
    paginator = instance('[folio 1r]')
    assert_equal({ '1r' => nil }, paginator.pages)
  end

  def test_header_with_prefix_newline
    paginator = instance("\n[page 1]")
    assert_equal({ '1' => nil }, paginator.pages)
  end

  def test_header_with_suffix_newline
    paginator = instance("[page 1]\n")
    assert_equal({ '1' => nil }, paginator.pages)
  end

  def test_header_with_prefix_and_suffix_newlines
    paginator = instance("\n[page 1]\n")
    assert_equal({ '1' => nil }, paginator.pages)
  end

  def test_header_with_invalid_pre_page
    paginator = instance("a\n\n[page 1]")
    assert_equal({ '1' => nil }, paginator.pages)
  end

  def test_invalid_page
    paginator = instance('[page 1]a')
    assert_equal({}, paginator.pages)
  end

  def test_doubled_header
    paginator = instance('[page 1][page 2]')
    assert_equal({}, paginator.pages)
  end

  def test_whitespace_page
    paginator = instance("[page 1]\n           ")
    assert_equal({ '1' => nil }, paginator.pages)
  end

  def test_page_with_text_after_single_newline
    paginator = instance("[page 1]\na")
    assert_equal({ '1' => 'a' }, paginator.pages)
  end

  def test_page_with_text_after_double_newline
    paginator = instance("[page 1]\n\na")
    assert_equal({ '1' => 'a' }, paginator.pages)
  end

  def test_page_with_text_with_newlines
    paginator = instance("[page 1]\na\nb\n\nc\n\n\nd")
    assert_equal({ '1' => "a\nb\n\nc\n\n\nd" }, paginator.pages)
  end

  def test_repeated_header
    paginator = instance("[page 1]\n[page 1]")
    assert_equal({ '1' => nil }, paginator.pages)
  end

  def test_repeated_page_with_text
    paginator = instance("[page 1]\n[page 1]\nb")
    assert_equal({ '1' => 'b' }, paginator.pages)
  end

  def test_two_pages
    paginator = instance("[page 1]\na\n[page 2]\nb")
    assert_equal({ '1' => 'a', '2' => 'b' }, paginator.pages)
  end

  def test_two_pages_with_no_text
    paginator = instance("[page 1]\n[page 2]")
    assert_equal({ '1' => nil, '2' => nil }, paginator.pages)
  end

  def test_skipped_page
    paginator = instance("[page 1]\na\n[page 3]\nc")
    assert_equal({ '1' => 'a', '3' => 'c' }, paginator.pages)
  end

  def test_disordered_page_numbers
    paginator = instance("[page 2]\na\n[page 1]\nb")
    assert_equal({ '2' => 'a', '1' => 'b' }, paginator.pages)
  end

  def test_bare_manual_ellipsis
    paginator = instance("[page 1]\n[...]")
    assert_equal({ '1' => nil }, paginator.pages)
  end

  def test_manual_ellipsis_with_whitespace
    paginator = instance("[page 1]\n    [...]   ")
    assert_equal({ '1' => nil }, paginator.pages)
  end

  def test_leading_manual_ellipsis
    paginator = instance("[page 1]\n[...]a")
    assert_equal({ '1' => 'a' }, paginator.pages)
  end

  def test_trailing_manual_ellipsis
    paginator = instance("[page 1]\n[...]a")
    assert_equal({ '1' => 'a' }, paginator.pages)
  end

  def test_internal_manual_ellipsis
    paginator = instance("[page 1]\na[...]b")
    assert_equal({ '1' => 'a[...]b' }, paginator.pages)
  end

  def test_two_pages_with_trailing_manual_ellipsis
    paginator = instance("[page 1]\na[...]\n[page 2]\nb")
    assert_equal({ '1' => 'a', '2' => 'b' }, paginator.pages)
  end

  def test_two_pages_with_manual_ellided_text
    paginator = instance("[page 1]\na[...]x\n[page 2]\nb")
    assert_equal({ '1' => 'a[...]x', '2' => 'b' }, paginator.pages)
  end

  def test_two_pages_with_manual_ellided_text_before_newlines
    paginator = instance("[page 1]\na\n[...]x\n[page 2]\nb")
    assert_equal({ '1' => "a\n[...]x", '2' => 'b' }, paginator.pages)
  end

  def test_two_pages_with_manual_ellided_text_after_newlines
    paginator = instance("[page 1]\na[...]\nx\n[page 2]\nb")
    assert_equal({ '1' => "a[...]\nx", '2' => 'b' }, paginator.pages)
  end

  def test_bare_unicode_ellipsis
    paginator = instance("[page 1]\n[…]")
    assert_equal({ '1' => nil }, paginator.pages)
  end

  def test_unicode_ellipsis_with_whitespace
    paginator = instance("[page 1]\n    […]   ")
    assert_equal({ '1' => nil }, paginator.pages)
  end

  def test_leading_unicode_ellipsis
    paginator = instance("[page 1]\n[…]a")
    assert_equal({ '1' => 'a' }, paginator.pages)
  end

  def test_trailing_unicode_ellipsis
    paginator = instance("[page 1]\n[…]a")
    assert_equal({ '1' => 'a' }, paginator.pages)
  end

  def test_internal_unicode_ellipsis
    paginator = instance("[page 1]\na[…]b")
    assert_equal({ '1' => 'a[…]b' }, paginator.pages)
  end

  def test_two_pages_with_trailing_unicode_ellipsis
    paginator = instance("[page 1]\na[…]\n[page 2]\nb")
    assert_equal({ '1' => 'a', '2' => 'b' }, paginator.pages)
  end

  def test_two_pages_with_unicode_ellided_text
    paginator = instance("[page 1]\na[…]x\n[page 2]\nb")
    assert_equal({ '1' => 'a[…]x', '2' => 'b' }, paginator.pages)
  end

  def test_two_pages_with_unicode_ellided_text_before_newlines
    paginator = instance("[page 1]\na\n[…]x\n[page 2]\nb")
    assert_equal({ '1' => "a\n[…]x", '2' => 'b' }, paginator.pages)
  end

  def test_two_pages_with_unicode_ellided_text_after_newlines
    paginator = instance("[page 1]\na[…]\nx\n[page 2]\nb")
    assert_equal({ '1' => "a[…]\nx", '2' => 'b' }, paginator.pages)
  end

  def test_single_invalid_page
    assert_raise HistoricalDiary::SourceDocuments::InvalidPageRangeError do
      instance('')['1']
    end
  end

  def test_single_valid_roman_numeral
    assert_equal %w[ⅰ], instance('[page ⅰ]')['ⅰ']
  end

  def test_single_valid_western_arabic_numeral
    assert_equal %w[1], instance('[page 1]')['1']
  end

  def test_single_valid_eastern_arabic_numeral
    assert_equal %w[١], instance('[page ١]')['١']
  end

  def test_invalid_range_end
    assert_raise HistoricalDiary::SourceDocuments::InvalidPageRangeError do
      instance('[page 1]')['1', '2']
    end
  end

  def test_reversed_range
    assert_raise HistoricalDiary::SourceDocuments::InvalidPageRangeError do
      instance("[page 1]\n[page 2]")['2', '1']
    end
  end

  def test_simple_range
    assert_equal %w[1 2], instance("[page 1]\n[page 2]")['1', '2']
  end

  def test_skipped_range
    assert_equal %w[1 2 3], instance("[page 1]\n[page 2]\n[page 3]")['1', '3']
  end

  def test_middle_of_range
    assert_equal %w[1 ١], instance("[page ⅰ]\n[page 1]\n[page ١]\n[page 3]")['1', '١']
  end

  def test_cross_digit_set
    assert_equal %w[ⅰ 1 ١], instance("[page ⅰ]\n[page 1]\n[page ١]")['ⅰ', '١']
  end

  def test_gap_in_range
    assert_equal %w[1 5], instance("[page 1]\n[page 5]")['1', '5']
  end
end
