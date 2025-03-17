# frozen_string_literal: true

require 'test/unit'
require_relative '../../../lib/historical-diary/source_document'
require_relative '../../../lib/historical-diary/source_documents/notes'

class TestSourceDocumentsNoteExtractor < Test::Unit::TestCase
  NOTES = {
    '1-*' => [{
      'page' => '1',
      'prefix' => '* ',
      'textStart' => 'It is almost',
      'textEnd' => 'as an astrologer.',
    }],
    '9-*' => [{
      'page' => '9',
      'prefix' => '* ',
      'textStart' => 'His first wife',
      'textEnd' => 'fetch my glass',
    }, {
      'page' => '10',
      'textStart' => 'so famous,',
      'textEnd' => 'spoken of again.',
    },],
    '22-*': [{
      'page' => '22',
      'prefix' => '* ',
      'textStart' => 'He frequently speaks',
      'textEnd' => 'title of Illustrissimus.',
    }],
    "22-\u2020": [{
      'page' => '22',
      'prefix' => '† ',
      'textStart' => 'It is almost',
      'textEnd' => 'to Edward Kelly.',
    }],
  }.freeze

  def instance(pages, redactions: {})
    raw_text = pages&.map { |key, text| "[page #{key}]\n#{text}" }&.join("\n")
    identifier = HistoricalDiary::SourceDocument.build_identifier('a')
    document = HistoricalDiary::SourceDocument.new(identifier, raw_text:, redactions:)
    HistoricalDiary::SourceDocuments::NoteExtractor.new(document)
  end

  def test_matching_note
    note_text = <<~NOTE
      It is almost unnecessary to observe that this and the following are notes of
      nativities. They are not for the most part contemporary notices, but apparently
      inserted at various times by Dee when professionally consulted as an astrologer.
    NOTE
    text = "before\n\t* #{note_text.strip}\nafter"
    redactor = instance({ '1' => text }, redactions: { 'notes' => NOTES })

    assert_equal({ '1-*' => { pages: ['1'], symbol: '*', text: note_text.chomp } }, redactor.notes)

    assert_equal({ '1' => "before\nafter" }, redactor.pages)
  end

  # rubocop:disable Metrics/MethodLength
  def test_multiple_matching_notes
    page_text = <<~TEXT
      before
      	* He frequently speaks of Prince Albert Leski under the title of Illustrissimus.
      	† It is almost unnecessary to observe that these initials refer to Edward Kelly.
      after
    TEXT
    redactor = instance({
                          '22' => page_text.strip,
                        }, redactions: { 'notes' => NOTES })

    assert_equal(
      {
        '22-*': { pages: %w[22], symbol: '*',
                  text: 'He frequently speaks of Prince Albert Leski under the title of Illustrissimus.', },
        "22-\u2020": { pages: %w[22], symbol: '†',
                       text: 'It is almost unnecessary to observe that these initials refer to Edward Kelly.', },
      },
      redactor.notes
    )

    assert_equal({ '22' => "before\nafter" }, redactor.pages)
  end
  # rubocop:enable Metrics/MethodLength

  def test_matching_note_across_pages
    redactor = instance({
                          '9' => "before\n	* His first wife died\n willed to fetch my glass\nafter",
                          '10' => "previous\nso famous, and to\nglass is spoken of again.\nsubsequent",
                        }, redactions: { 'notes' => NOTES })

    expected_note_text = "His first wife died\n willed to fetch my glass so famous, and to\nglass is spoken of again."
    assert_equal({ '9-*' => { pages: %w[9 10], symbol: '*', text: expected_note_text.strip } },
                 redactor.notes)

    assert_equal({ '9' => "before\nafter", '10' => "previous\nsubsequent" }, redactor.pages)
  end
end
