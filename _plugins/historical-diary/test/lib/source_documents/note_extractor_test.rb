# frozen_string_literal: true

require 'test/unit'
require_relative '../../../lib/historical-diary/source_documents/note_extractor'

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
    HistoricalDiary::SourceDocuments::NoteExtractor.new(pages, redactions:)
  end

  def test_selector_without_text_start
    pages = { '1' => 'Text with a note here' }
    selectors = { 'note-key' => [{ 'page' => '1', 'textEnd' => 'here' }] }

    assert_raise(HistoricalDiary::InvalidTransclusionError) do
      instance(pages, redactions: { 'notes' => selectors }).notes
    end
  end

  def test_no_pages
    empty_pages = {}
    redactor = instance(empty_pages, redactions: { 'notes' => NOTES })

    assert_equal({}, redactor.notes)
    assert_equal({}, redactor.pages)
  end

  def test_no_redactions
    pages = { '1' => 'some text' }
    redactor = instance(pages, redactions: {})

    assert_equal({}, redactor.notes)
    assert_equal(pages, redactor.pages)
  end

  def test_selector_without_page
    pages = { '1' => 'Text with a note here' }
    selectors = { 'note-key' => [{ 'textStart' => 'with', 'textEnd' => 'here' }] }
    redactor = instance(pages, redactions: { 'notes' => selectors })

    assert_equal({}, redactor.notes)
    assert_equal(pages, redactor.pages)
  end

  def test_nonexistent_page_selector
    pages = { '1' => 'Text with a note' }
    selectors = { 'note-key' => [{ 'page' => '2', 'textStart' => 'with', 'textEnd' => 'note' }] }
    redactor = instance(pages, redactions: { 'notes' => selectors })

    assert_equal({}, redactor.notes)
    assert_equal(pages, redactor.pages)
  end

  def test_no_match
    notes = {}
    pages = { '1' => 'before\nafter' }
    redactor = instance(pages, redactions: { 'notes' => notes })

    assert_equal(notes, redactor.notes)
    assert_equal(pages, redactor.pages)
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

  def test_note_is_entire_page_text
    note_text = <<~NOTE
      It is almost unnecessary to observe that this and the following are notes of
      nativities. They are not for the most part contemporary notices, but apparently
      inserted at various times by Dee when professionally consulted as an astrologer.
    NOTE
    text = "* #{note_text.strip}"
    redactor = instance({ '1' => text }, redactions: { 'notes' => NOTES })

    assert_equal({ '1-*' => { pages: ['1'], symbol: '*', text: note_text.chomp } }, redactor.notes)
    assert_equal({ '1' => '' }, redactor.pages)
  end

  def test_multiple_matching_notes # rubocop:disable Metrics/MethodLength
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

  def test_regex_metacharacters_in_notes # rubocop:disable Metrics/MethodLength
    pages = { '1' => '[special] *characters* (in) text.' }
    selectors = {
      'note-key' => [{
        'page' => '1',
        'prefix' => '[',
        'textStart' => 'special] *characters*',
        'textEnd' => '(in)',
        'suffix' => 'text',
      }],
    }
    redactor = instance(pages, redactions: { 'notes' => selectors })

    assert_equal({ 'note-key' => { pages: ['1'], symbol: '[', text: 'special] *characters* (in)' } }, redactor.notes)
    assert_equal({ '1' => ' text.' }, redactor.pages)
  end

  def test_note_at_beginning_of_page
    pages = { '1' => "* Beginning note text.\nRegular content here." }
    selectors = { 'begin-note' => [{ 'page' => '1', 'prefix' => '*', 'textStart' => 'Beginning',
                                     'textEnd' => 'text.', }] }
    redactor = instance(pages, redactions: { 'notes' => selectors })

    assert_equal({ 'begin-note' => { pages: ['1'], symbol: '*', text: 'Beginning note text.' } }, redactor.notes)
    assert_equal({ '1' => 'Regular content here.' }, redactor.pages)
  end

  def test_note_at_end_of_page
    pages = { '2' => "Regular content here.\n* Ending note text." }
    selectors = { 'end-note' => [{ 'page' => '2', 'prefix' => '*', 'textStart' => 'Ending', 'textEnd' => 'text.' }] }
    redactor = instance(pages, redactions: { 'notes' => selectors })

    assert_equal({ 'end-note' => { pages: ['2'], symbol: '*', text: 'Ending note text.' } }, redactor.notes)
    assert_equal({ '2' => "Regular content here.\n" }, redactor.pages)
  end

  def test_complex_whitespace_handling # rubocop:disable Metrics/MethodLength
    pages = {
      '1' => "Content before.\n\t* \tNote with   multiple\n\tspaces and\ttabs.\nContent after.",
    }
    selectors = {
      'whitespace-note' => [{ 'page' => '1', 'prefix' => '*', 'textStart' => 'Note', 'textEnd' => 'tabs.' }],
    }
    redactor = instance(pages, redactions: { 'notes' => selectors })

    assert_equal({ 'whitespace-note' => {
                   pages: ['1'],
                   symbol: '*',
                   text: "Note with   multiple\n\tspaces and\ttabs.",
                 } }, redactor.notes)
    assert_equal({ '1' => "Content before.\nContent after." }, redactor.pages)
  end

  def test_unicode_characters_in_notes # rubocop:disable Metrics/MethodLength
    pages = { '1' => "Content before.\n* 你好 Unicode 😀.\nContent after." }
    selectors = {
      'unicode-note' => [{ 'page' => '1', 'prefix' => '*', 'textStart' => '你好', 'textEnd' => '😀.' }],
    }
    redactor = instance(pages, redactions: { 'notes' => selectors })

    assert_equal({ 'unicode-note' => {
                   pages: ['1'],
                   symbol: '*',
                   text: '你好 Unicode 😀.',
                 } }, redactor.notes)
    assert_equal({ '1' => "Content before.\nContent after." }, redactor.pages)
  end
end
