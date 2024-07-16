# frozen_string_literal: true

require 'test/unit'
require_relative '../../lib/historical-diary/annotation'

class TestAnnotation < Test::Unit::TestCase
  def instance(text, annotations: [])
    HistoricalDiary::Annotation.new(text, annotations:)
  end

  def test_nil_text
    assert_raise_kind_of(ArgumentError) { instance(nil) }
  end

  def test_blank_text
    annotation = instance('')
    assert_equal '', annotation.text
  end

  def test_no_annotations
    annotation = instance('a')
    assert_equal 'a', annotation.text
  end

  def test_empty_annotations
    annotations = []
    annotation = instance('a', annotations:)
    assert_equal 'a', annotation.text
  end

  def test_no_value
    annotations = [{}]
    annotation = instance('a', annotations:)
    assert_equal 'a', annotation.text
  end

  def test_no_selectors
    annotations = [{ 'value' => 'b' }]
    annotation = instance('a', annotations:)
    assert_equal 'a', annotation.text
  end

  def test_empty_selectors
    annotations = [{ 'value' => 'b', 'selectors' => [] }]
    annotation = instance('a', annotations:)
    assert_equal 'a', annotation.text
  end

  def test_no_exact
    annotations = [{ 'value' => 'b', 'selectors' => [{}] }]
    annotation = instance('a', annotations:)
    assert_equal 'a', annotation.text
  end

  def test_nil_exact
    annotations = [{ 'value' => 'b', 'selectors' => [{ 'exact' => nil }] }]
    annotation = instance('a', annotations:)
    assert_equal 'a', annotation.text
  end

  def test_blank_exact
    annotations = [{ 'value' => 'b', 'selectors' => [{ 'exact' => '' }] }]
    annotation = instance('a', annotations:)
    assert_equal 'a', annotation.text
  end

  def test_exact
    annotations = [{ 'value' => 'b', 'selectors' => [{ 'exact' => 'a' }] }]
    annotation = instance('a', annotations:)
    assert_equal 'b', annotation.text
  end

  def test_prefix
    annotations = [{ 'value' => 'b', 'selectors' => [{ 'prefix' => 'c', 'exact' => 'a' }] }]
    annotation = instance('a ca', annotations:)
    assert_equal 'a cb', annotation.text
  end

  def test_suffix
    annotations = [{ 'value' => 'b', 'selectors' => [{ 'exact' => 'a', 'suffix' => 'c' }] }]
    annotation = instance('a ac', annotations:)
    assert_equal 'a bc', annotation.text
  end

  def test_prefix_and_suffix
    annotations = [{ 'value' => 'b', 'selectors' => [{ 'prefix' => 'c', 'exact' => 'a', 'suffix' => 'c' }] }]
    annotation = instance('a ac ca cac', annotations:)
    assert_equal 'a ac ca cbc', annotation.text
  end

  def test_multiple_matches
    annotations = [{ 'value' => 'b', 'selectors' => [{ 'exact' => 'a' }] }]
    annotation = instance('a a', annotations:)
    assert_equal 'b b', annotation.text
  end

  def test_start_of_word
    annotations = [{ 'value' => 'b', 'selectors' => [{ 'exact' => 'a' }] }]
    annotation = instance('apple', annotations:)
    assert_equal 'bpple', annotation.text
  end

  def test_end_of_word
    annotations = [{ 'value' => 'b', 'selectors' => [{ 'exact' => 'a' }] }]
    annotation = instance('novella', annotations:)
    assert_equal 'novellb', annotation.text
  end

  def test_middle_of_word
    annotations = [{ 'value' => 'b', 'selectors' => [{ 'exact' => 'a' }] }]
    annotation = instance('frank', annotations:)
    assert_equal 'frbnk', annotation.text
  end

  def test_escape_special_character
    annotations = [{ 'value' => 'b', 'selectors' => [{ 'exact' => '/' }] }]
    annotation = instance('one/two', annotations:)
    assert_equal 'onebtwo', annotation.text
  end

  def test_multiple_annotations
    annotations = [{ 'value' => 'b', 'selectors' => [{ 'exact' => 'a' }] },
                   { 'value' => 'c', 'selectors' => [{ 'exact' => 'b' }] },]
    annotation = instance('a', annotations:)
    assert_equal 'c', annotation.text
  end

  def test_applied_in_order
    annotations = [{ 'value' => 'c', 'selectors' => [{ 'exact' => 'b' }] },
                   { 'value' => 'b', 'selectors' => [{ 'exact' => 'a' }] },]
    annotation = instance('a', annotations:)
    assert_equal 'b', annotation.text
  end

  def test_use_backreference
    annotations = [{ 'value' => 'b\1b', 'selectors' => [{ 'exact' => 'a' }] }]
    annotation = instance('a', annotations:)
    assert_equal 'bab', annotation.text
  end
end
