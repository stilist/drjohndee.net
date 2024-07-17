# frozen_string_literal: true

require 'test/unit'
require_relative '../../../lib/historical-diary/source_documents/reflows'

class TestSourceDocumentsReflows < Test::Unit::TestCase
  REFLOWS = [{
    'value' => 'Gelderland',
    'selectors' => [
      {
        'page' => '1',
        'exact' => 'Gel- derland',
      },
    ],
  }, {
    'value' => 'gratiously',
    'selectors' => [
      {
        'page' => '18-19',
        'exact' => 'gra- tiously',
      },
    ],
  }, {
    'value' => 'Gelderland',
    'selectors' => [
      {
        'page' => '18-19',
        'exact' => 'Gel- derland',
      },
    ],
  },].freeze

  def instance(pages)
    HistoricalDiary::SourceDocuments::Reflows.new(pages, redactions: { 'reflows' => REFLOWS })
  end

  def test_no_pages
    redactor = instance(nil)
    assert_equal(nil, redactor.pages)
  end

  def test_no_redactions
    redactor = HistoricalDiary::SourceDocuments::Reflows.new({ '1' => 'a' }, redactions: {})
    assert_equal({ '1' => 'a' }, redactor.pages)
  end

  def test_no_matching_redactions
    redactor = instance({ '1' => 'a' })
    assert_equal({ '1' => 'a' }, redactor.pages)
  end

  def test_matching_reflow
    redactor = instance({ '1' => 'Gel- derland' })
    assert_equal({ '1' => 'Gelderland' }, redactor.pages)
  end

  def test_non_matching_prefix_reflow_across_pages
    redactor = instance({ '18' => 'gra- ', '19' => 'xtiously' })
    assert_equal({ '18' => 'gra- ', '19' => 'xtiously' }, redactor.pages)
  end

  def test_non_matching_whitespace_prefix_reflow_across_pages
    redactor = instance({ '18' => 'gra- ', '19' => ' tiously' })
    assert_equal({ '18' => 'gra- ', '19' => ' tiously' }, redactor.pages)
  end

  def test_reflow_across_pages
    redactor = instance({ '18' => 'gra-', '19' => 'tiously' })
    assert_equal({ '18' => 'gratiously', '19' => '' }, redactor.pages)
  end

  def test_reflow_with_whitespace_across_pages
    redactor = instance({ '18' => 'gra- ', '19' => 'tiously' })
    assert_equal({ '18' => 'gratiously', '19' => '' }, redactor.pages)
  end

  def test_reflow_with_newline_across_pages
    redactor = instance({ '18' => "gra-\n", '19' => 'tiously' })
    assert_equal({ '18' => 'gratiously', '19' => '' }, redactor.pages)
  end

  def test_multiple_reflows_across_pages
    redactor = instance({ '18' => "gra- \nGel-\n", '19' => "tiously\nderland" })
    assert_equal({ '18' => "gratiously\nGelderland", '19' => '' }, redactor.pages)
  end
end
