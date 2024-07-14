# frozen_string_literal: true

require 'test/unit'
require_relative '../../../lib/historical-diary/source_documents/identifier'

class TestSourceDocumentsIdentifier < Test::Unit::TestCase
  def test_members_are_required
    assert_raises(ArgumentError) do
      HistoricalDiary::SourceDocuments::Identifier.new
    end
  end

  def test_source_must_be_non_nil
    assert_raises(ArgumentError) do
      HistoricalDiary::SourceDocuments::Identifier.new(source: nil, edition: 'b', volume: 'c')
    end
  end

  def test_edition_must_be_non_nil
    assert_raises(ArgumentError) do
      HistoricalDiary::SourceDocuments::Identifier.new(source: 'a', edition: nil, volume: 'c')
    end
  end

  def test_to_s_source_and_edition
    instance = HistoricalDiary::SourceDocuments::Identifier.new(source: 'a', edition: 'b', volume: nil)
    assert_equal 'a, b', instance.to_s
  end

  def test_to_s_source_edition_and_volume
    instance = HistoricalDiary::SourceDocuments::Identifier.new(source: 'a', edition: 'b', volume: 'c')
    assert_equal 'a, b, c', instance.to_s
  end
end
