# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- Person pages now display context from the person’s lifetime, if any is available
- Date pages now indicate if source material spans multiple days
- Context data from Thomas Short’s ‘A General Chronological History of the Air, Weather, Seasons, Meteors…’, covering 1527–1559 --- more is available

### Fixed
- `transclusions_for_timestamp` can now return transclusions for multiple dates, improving the `commentary_for_date`, `context_for_date`, and `relevant_footnotes` Liquid filters

## [1.0.2] - 2021-02-06
### Added
- Set `license` property where possible
- `person_name` Liquid filter simplifies displaying names from `people` data
- Page title and `headline` property now have more than just the date
- `people` data for Thomas Short (author of ‘New Observations, Natural, Moral, Civil, Political and Medical…’)
- Link to DOI if available

### Changed
- Manually render page metadata instead of using `jekyll-seo-tag` plugin -- the plugin doesn't have a way to disable JSON-LD output, but, that output is a secondary, lower-quality version of the structured data applied throughout the site
- Directly host EB Garamond font files -- CSS and files were assembled using the [`google-webfonts-helper` tool](https://google-webfonts-helper.herokuapp.com/fonts/eb-garamond?subsets=greek,latin,latin-ext)

### Fixed
- Don’t try to render `person_data` include for source author/editor unless the key is available
- Remove unnecessary `person` property from `person_data` include’s `itemscope`

## [1.0.1] - 2021-02-05
### Added
- Add two weather entries to ‘New Observations, Natural, Moral, Civil, Political and Medical…’ context data

### Changed
- Adjust keys in ‘New Observations, Natural, Moral, Civil, Political and Medical…’ context data to end with inclusive date, rather than exclusive

### Fixed
- Transcluded data (commentary, context, footnotes) would not be rendered into pages if the data key contained a `/` (for example, the key `"1603/1604"` in `_data/context/new observations natural moral civil political and medical.yaml`)

## [1.0.0] - 2021-02-05
### Added
- All of John Dee’s diary entries recorded in ‘The Private Diary of Dr. John Dee’, with footnotes
- All of John Dee’s diary entries recorded in ‘Local Gleanings: an Archælogical & Historical Magazine, Chiefly Relating to Lancashire & Cheshire’, with commentary and footnotes
- A few entries from Sloane MS 3188, manually trascribed
- Some weather information from ‘New Observations, Natural, Moral, Civil, Political and Medical…’ to provide context
- Site provides day-by-day access to entries, with additional pages for people and sources
- Site uses structured data for entries, people, and sources

[Unreleased]: https://github.com/stilist/drjohndee.net/compare/v1.0.2...HEAD
[1.0.2]: https://github.com/stilist/drjohndee.net/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/stilist/drjohndee.net/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/stilist/drjohndee.net/releases/tag/v1.0.0
