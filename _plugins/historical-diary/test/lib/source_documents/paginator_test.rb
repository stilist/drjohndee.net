# frozen_string_literal: true

require 'test/unit'
require_relative '../../../lib/historical-diary/source_documents/paginator'

class TestSourceDocumentsPaginator < Test::Unit::TestCase
  def instance(raw_text)
    HistoricalDiary::SourceDocuments::Paginator.new(raw_text)
  end

  def test_no_text
    parser = instance(nil)
    assert_equal({}, parser.pages)
  end

  def test_blank_text
    parser = instance('')
    assert_equal({}, parser.pages)
  end

  def test_no_header
    parser = instance('a')
    assert_equal({}, parser.pages)
  end

  def test_invalid_header_page_word
    parser = instance('[test 1]')
    assert_equal({}, parser.pages)
  end

  def test_invalid_header_no_page_word
    parser = instance('[1]')
    assert_equal({}, parser.pages)
  end

  def test_invalid_header_no_number
    parser = instance('[test]')
    assert_equal({}, parser.pages)
  end

  def test_invalid_header_page_number_whitespace
    parser = instance('[test  ]')
    assert_equal({}, parser.pages)
  end

  def test_invalid_header_page_number_punctuation
    parser = instance('[test .]')
    assert_equal({}, parser.pages)
  end

  def test_bare_header_page
    parser = instance('[page 1]')
    assert_equal({ '1' => nil }, parser.pages)
  end

  def test_bare_header_folio
    parser = instance('[folio 1]')
    assert_equal({ '1' => nil }, parser.pages)
  end

  def test_bare_header_letter
    parser = instance('[folio i]')
    assert_equal({ 'i' => nil }, parser.pages)
  end

  def test_bare_header_number_and_letter
    parser = instance('[folio 1r]')
    assert_equal({ '1r' => nil }, parser.pages)
  end

  def test_header_with_prefix_newline
    parser = instance("\n[page 1]")
    assert_equal({ '1' => nil }, parser.pages)
  end

  def test_header_with_suffix_newline
    parser = instance("[page 1]\n")
    assert_equal({ '1' => nil }, parser.pages)
  end

  def test_header_with_prefix_and_suffix_newlines
    parser = instance("\n[page 1]\n")
    assert_equal({ '1' => nil }, parser.pages)
  end

  def test_header_with_invalid_pre_page
    parser = instance("a\n\n[page 1]")
    assert_equal({ '1' => nil }, parser.pages)
  end

  def test_invalid_page
    parser = instance('[page 1]a')
    assert_equal({}, parser.pages)
  end

  def test_whitespace_page
    parser = instance("[page 1]\n           ")
    assert_equal({ '1' => nil }, parser.pages)
  end

  def test_page_with_text_after_single_newline
    parser = instance("[page 1]\na")
    assert_equal({ '1' => 'a' }, parser.pages)
  end

  def test_page_with_text_after_double_newline
    parser = instance("[page 1]\n\na")
    assert_equal({ '1' => 'a' }, parser.pages)
  end

  def test_page_with_text_with_newlines
    parser = instance("[page 1]\na\nb\n\nc\n\n\nd")
    assert_equal({ '1' => "a\nb\n\nc\n\n\nd" }, parser.pages)
  end

  def test_repeated_header
    parser = instance("[page 1]\n[page 1]")
    assert_equal({ '1' => nil }, parser.pages)
  end

  def test_repeated_page_with_text
    parser = instance("[page 1]\n[page 1]\nb")
    assert_equal({ '1' => 'b' }, parser.pages)
  end

  def test_two_pages
    parser = instance("[page 1]\na\n[page 2]\nb")
    assert_equal({ '1' => 'a', '2' => 'b' }, parser.pages)
  end

  def test_skipped_page
    parser = instance("[page 1]\na\n[page 3]\nc")
    assert_equal({ '1' => 'a', '3' => 'c' }, parser.pages)
  end

  def test_disordered_page_numbers
    parser = instance("[page 2]\na\n[page 1]\nb")
    assert_equal({ '2' => 'a', '1' => 'b' }, parser.pages)
  end

  def test_bare_manual_ellipsis
    parser = instance("[page 1]\n[...]")
    assert_equal({ '1' => nil }, parser.pages)
  end

  def test_manual_ellipsis_with_whitespace
    parser = instance("[page 1]\n    [...]   ")
    assert_equal({ '1' => nil }, parser.pages)
  end

  def test_leading_manual_ellipsis
    parser = instance("[page 1]\n[...]a")
    assert_equal({ '1' => 'a' }, parser.pages)
  end

  def test_trailing_manual_ellipsis
    parser = instance("[page 1]\n[...]a")
    assert_equal({ '1' => 'a' }, parser.pages)
  end

  def test_internal_manual_ellipsis
    parser = instance("[page 1]\na[...]b")
    assert_equal({ '1' => 'a[...]b' }, parser.pages)
  end

  def test_two_pages_with_trailing_manual_ellipsis
    parser = instance("[page 1]\na[...]\n[page 2]\nb")
    assert_equal({ '1' => 'a', '2' => 'b' }, parser.pages)
  end

  def test_two_pages_with_manual_ellided_text
    parser = instance("[page 1]\na[...]x\n[page 2]\nb")
    assert_equal({ '1' => 'a[...]x', '2' => 'b' }, parser.pages)
  end

  def test_two_pages_with_manual_ellided_text_before_newlines
    parser = instance("[page 1]\na\n[...]x\n[page 2]\nb")
    assert_equal({ '1' => "a\n[...]x", '2' => 'b' }, parser.pages)
  end

  def test_two_pages_with_manual_ellided_text_after_newlines
    parser = instance("[page 1]\na[...]\nx\n[page 2]\nb")
    assert_equal({ '1' => "a[...]\nx", '2' => 'b' }, parser.pages)
  end

  def test_bare_unicode_ellipsis
    parser = instance("[page 1]\n[…]")
    assert_equal({ '1' => nil }, parser.pages)
  end

  def test_unicode_ellipsis_with_whitespace
    parser = instance("[page 1]\n    […]   ")
    assert_equal({ '1' => nil }, parser.pages)
  end

  def test_leading_unicode_ellipsis
    parser = instance("[page 1]\n[…]a")
    assert_equal({ '1' => 'a' }, parser.pages)
  end

  def test_trailing_unicode_ellipsis
    parser = instance("[page 1]\n[…]a")
    assert_equal({ '1' => 'a' }, parser.pages)
  end

  def test_internal_unicode_ellipsis
    parser = instance("[page 1]\na[…]b")
    assert_equal({ '1' => 'a[…]b' }, parser.pages)
  end

  def test_two_pages_with_trailing_unicode_ellipsis
    parser = instance("[page 1]\na[…]\n[page 2]\nb")
    assert_equal({ '1' => 'a', '2' => 'b' }, parser.pages)
  end

  def test_two_pages_with_unicode_ellided_text
    parser = instance("[page 1]\na[…]x\n[page 2]\nb")
    assert_equal({ '1' => 'a[…]x', '2' => 'b' }, parser.pages)
  end

  def test_two_pages_with_unicode_ellided_text_before_newlines
    parser = instance("[page 1]\na\n[…]x\n[page 2]\nb")
    assert_equal({ '1' => "a\n[…]x", '2' => 'b' }, parser.pages)
  end

  def test_two_pages_with_unicode_ellided_text_after_newlines
    parser = instance("[page 1]\na[…]\nx\n[page 2]\nb")
    assert_equal({ '1' => "a[…]\nx", '2' => 'b' }, parser.pages)
  end
end
