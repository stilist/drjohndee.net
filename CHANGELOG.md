# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- Manage DNS using Namecheap Terraform module
- Use CloudFront's managed cache and origin-request policies
- Split Terraform code into multiple files
- Add Lambda@Edge function to apply security headers -- note this code almost works, but fails with `Update the IAM policy to add permission: lambda:EnableReplication* for resource: arn:aws:lambda:us-east-1:<account id>:function:inject-headers:7 and try again.` and I give up on chasing obscure errors
- Add debug CSS/JS
- Add tag pages
- Add and update metadata on some entries
- Add and enhance content for 1583 from 'A True and Faithful Relation' (scrying sessions are still absent)

### Changed
- Upgrade Terraform `aws` provider
- Move Terraform code from `terraform/aws` to `terraform`

## [1.0.10] - 2021-03-21
### Added
- Add `dates_for_source`, `hash_keys`, `sort_hash`, and `sorted_people_keys` Liquid filters
- Add `Person` class to centralize functionality
- Link all people and sources from home page
- Note how many times each person appears in entries (based on `people` key)
- Link relevant dates on source pages
- Begin adding biography for John Dee from Charlotte Fell Smith’s book ‘John Dee’
- Add some `people` data
- Continue adding entries and letters
- Tag people, places, and source material in lots of entries
- Adjust `people_avatar` include and `Person#name_initials` to handle `people` keys that don't have a corresponding data file
- Display places, sources, and tags on date pages
- Add information for several sources

### Changed
- Refactor `people` include into `people_avatars` and `person_avatar` includes
- Redefine `person_initials` and `person_name` Liquid filters to use `Person` class
- Rename `attribute_from_record` Liquid filter to `attribute_from_object_or_source_record`
- Refactor `mla_citation` Liquid filter to use `attribute_from_object_or_source_record`
- Wrap source material in `<blockquote>` tag, to consistently indicate quoted text
- Convert additional properties from physical to logical: `margin`, `padding`, `height`, `width`, `bottom`, `top`
- Update styling to follow vertical rhythm
- Change `transcludes.html` to not use Markdown
- Change `transcludes.html` structured-data structure to match `entry.html`
- Rename `_lib/collections.rb` to `_lib/data_collection.rb` to match its module name
- Move ‘Autobiographical Tracts’ information from ‘commentary’ data to ‘context’, which is more appropriate
- Change Jekyll cache directory to `_cache.nosync`
- Rewrite `HistoricalDiary::SourceMaterialGenerator` to use Jekyll’s cache system -- `jekyll build` now takes me between 16 seconds and 18 seconds instead of between 23 seconds and 25 seconds if the cache is primed (22%-31% faster), and the code is clearer
- `HistoricalDiary::SourceMaterialGenerator` now understands filenames with comma-separated dates (for example, `_source_material/the private diary of dr john dee/1564-03-01,1593-03-01.md` will appear on both 1564-03-01 and 1593-03-01)
- `HistoricalDiary::SourceMaterialGenerator` now extracts `places` and `sources` from source material, in addition to `people` and `tags`
- Update `theme_color` setting
- `Person` class strips `unknown -- ` from person keys

### Fixed
- Improve structure of person and source pages
- Fix CSS selector for highlighted person avatar
- Adjust `DataCollection#data_collection_record` to handle the case that the `collection_name` collection doesn't have a match for `key`
- Adjust `HistoricalDiary::ManipulateDataGenerator` to handle case that source doesn't have an `editions` hash

### Removed
- Remove `get_author_key` Liquid filter -- its function is better done with the `attribute_from_object_or_source_record` filter

## [1.0.9] - 2021-03-13
### Added
- Add text for some shorter entries and a few letters
- Add `attribute_from_record` Liquid filter to automatically resolve volumes, editions, etc.
- Add ‘biography’ mechanism to show relevant information on person pages
- Set `logo` property in page header
- Tag some additional people and add data
- Display person's full name and title on person page
- Copy tags from source material to `DayPage`

### Changed
- Replace `alternateType` in people data with `addtionalType` -- [`additionalType` is a `schema.org` property](https://schema.org/additionalType)
- Rebuild color palette for better contrast and easier maintenance
- Display day name on date page

### Fixed
- Correctly tag `lang` attribute on source material
- Handle case that ‘source’ data file is empty
- Increase color contrast for dark-mode year page to meet WCAG AA requirement
- Fix issues with page structure, identified by `axe-core`
- Redo `prefers-contrast: more` overrides, after enabling `layout.css.prefers-contrast.enabled` in Firefox’s `about:config`

## [1.0.8] - 2021-03-05
### Added
- Letter from John Dee to William Langley on 1597-05-02
- Display commentary on year pages
- Add three days from Casaubon’s ‘True and Faithful Relation’ -- raw transcription without annotations.
- Add metadata for all entries from ‘True and Faithful Relation’
- Tag entries for Olbracht Łaski

### Changed
- Year page generator’s `legal_year_dates` property is now `expanded_legal_year_dates`, to convey it includes the full month of March on both ends
- Adjust ‘missing content’ text to encourage contributions with a link to edit the file, and a link to the source
- Display ‘Context’ section on year page rather than date page -- in the future it would be ideal to have a concept of ‘relevance’, so a given item of commentary or context is considered relevant to a specific date (or set of dates), or to a year, and only shown in that context
- Use more robust lookup for `author_key` on date page
- Use short day number on date page, rather than 0-padded
- Sort keys in `transclude` `include`, to get more 'ibid's

### Fixed
- Filter out duplicate related dates
- Handle case that no publication information is available in the `mla_citation` Liquid filter
- Fix bugs that prevented `author_key` and `recipient_key` from being passed to the `people` `include`

### Removed
- Remove code that generated date pages if only commentary was available -- this is now handled in a better way by rendering the commentary on the year page

## [1.0.7] - 2021-02-28
### Added
- Set `class` and `data-key` attributes on ‘Ibid.’ citations
- Annotations for 1582-03-11 entry
- Add placeholder files for all other dates in Sloane MS 3188
- Provide a message for placeholder entries
- A few entries are copied in another hand -- add those page numbers to the relevant source files
- Initial transcript of 1582-03-21 entries
- Tag all source material related to Bartholomew Hickman, Jane Dee, Edward Kelley, Jane Kelley, and Thomas Kelley
- Add `dates_for_person` Liquid filter and display related dates on person page
- Add `date_to_url` Liquid filter for converting Ruby `Date` and `DateTime` objects to URLs to dates
- Adjust person pages to display aliases and birth names
- Adjust markup/CSS to handle long lists of related dates
- Add `<meta>` tag for Google site verification
- Add website icon
- Set `theme-color` for whatever happens to support it 🤷
- Add `escape_data_key` Liquid filter that wraps `DataCollection#escape_key`
- Add letter from John Dee to King James on 1604-06-05

### Changed
- Generation `destination` is now `_site.nosync` -- `.nosync` prevents iCloud from syncing files
- Render commentary markup before related dates & footnotes
- Use shorter titles for year & date pages
- Use `-` instead of `·` in page title, to improve screenreader experience
- Adjust date display in date page header

### Fixed
- Safari 14 doesn’t support the [`inset-inline-start` CSS property](https://developer.mozilla.org/en-US/docs/Web/CSS/inset-inline-start) -- use `left` by default, and switch to `inset-inline-start` when available. Note that this means the layout is *not* fully RTL-compatible in Safari unless `right` rules are added to compensate for reversed layout.
- Person page and source page now use `<h2>` and `<h3>` for proper hierarchy (reported by Bing)
- Fix bug with logic for removing entry author from list of related people
- Dates with content on year page were being marked as `aria-hidden`
- Reduce intensity of 'content'-indicating background-color on calendar to fix constrast issue
- Year-page link on date page was incorrect
- Handle case that `exact` selector is missing or empty
- Handle case that `mla_citation` is given an empty `location`
- Handle case that publication date is a full date, not just a year

## [1.0.6] - 2021-02-26
### Added
- Handle source material that has a `footnotes:` array in the front matter
- Add `.terraform/` to Jekyll ignore list
- `mla_citation` Liquid filter now prefers information from a specified volume, falling back to the edition, and finally to the work
- Link to (calendar) year on date page
- Add references to Dee from ‘Calendar of State Papers, Domestic Series, of the reign of Elizabeth…’
- Add two letters from John Chamberlain to Dudley Carlton that reference John Dee, from ‘Letters written by John Chamberlain during the Reign of Queen Elizabeth’
- Annotate mentions of Adrian and Humphrey Gilbert
- Display ‘related dates’ on date pages
- Add letter from John Dee to William Cecil
- Fully annotate 1581-12-22 and 1582-03-10 entries, including illustrations
- Add stylized SVG rendering of illustrations from 1582-03-10 entries
- Add widget to display the list of people related to an entry
- Add `get_author_key` Liquid filter to automatically identify an `author_key` based on the provided object, falling back to the volume, edition, and ‘work’ author of the object’s associated source record
- Add `person_initials` Liquid filter that generates a string of graphemes representing the initials of a name
- Add `person_reference` Liquid filter
- Add `data_record_tag_attributes` Liquid filter that provides a consistent class name and `data-key` attribute so everything using the `person_reference` and `person_link` filters be connected
- Add styling for `<em>` and `<strong>`
- Add JavaScript to display all `person_link` and `person_reference`s that point to the same record

### Changed
- Remove `markdownify` filter from `entry` `include` -- source material is raw text without Markdown formatting
- Split 1582-03-10’s two sessions into separate files
- Refactor `person_link` Liquid filter to use `data_record_tag_attributes`
- `annotate_content` Liquid filter now uses a Yaml file that matches the source material’s filename -- annotation files apply to at most one entry for a date, rather than all
- Use `data_record_tag_attributes` Liquid filter in `people` include
- Improve CSS for `person-avatar`s

### Fixed
- Code that called the `mla_citation` Liquid filter on date pages was using the incorrect variables for edition and volume
- `annotate_content` Liquid filter now calls `#clone` on content to avoid mutating content that will render on multiple days
- In `HistoricalDiary::DataPage`, handle case that fetched record is `nil`
- Fix layout of `<sup>` footnote references
- Fix ordering of color declarations in CSS
- Fix crashes in `DataCollection` methods when given an object that’s not a string
- Layout is now entirely RTL-compatible
- Fix spelling of ‘Lundrumguffa’
- Extend `header` grid area by one column to fix collapsed column between primary and secondary content

### Removed
- Remove `data_collection_record_link` method -- replaced by private `data_record_link` method

## [1.0.5] - 2021-02-21
### Added
- Generate a sitemap with `jekyll-sitemap`
- Set `url` in `_config.yml` to get valid `<loc>`s in sitemap
- Add three entries from Sloane MS 3188
- Add next/previous links on day pages
- Render day pages that have commentary but no source material
- Begin adding material from the ‘Autobiographical Tracts of Dr John Dee’
- Attempt transcription of Mercator’s letter to Dee regarding Rupes Nigra
- Add `LegalYear` module to simplify dealing with calendar-vs-legal year
- Add letter from John Dee to Queen Elizabeth Ⅰ
- Add annotation mechanism to insert links and other markup in rendered source material
- Add annotations to entries regarding initial ‘Actions’ with Edward Kelley
- Use annotations to style signature on letters

### Changed
- Update `README` to be more accurate and useful
- Begin using a custom mix of [diplomatic and semi-diplomatic transcription](https://www.english.cam.ac.uk/ceres/ehoc/conventions.html#advice): see `README`’s ‘Conventions for transcribing manuscripts’ section for details
- Make an `entry.html` include file with the contents of the date page’s `<li>` loop

### Fixed
- Change footer links to `LICENSE` and `CONTRIBUTING` pages to use uppercase filenames
- Set `last_modified_at` in metadata for year and day pages so Google will accept the sitemap
- Adjust year pages to end on March 24th, not March 25th
- Put source publication date in `<time>` tag for screenreader
- Add missing copyright header to data file
- Improve usability on mobile devices and small screens
- Index page now links years that have content for the *legal* year, rather than the *calendar* year
- Handle case that the key passed to `lifespan_years` doesn’t correspond to a record

## [1.0.4] - 2021-02-13
### Added
- Generate a calendar page for each year, with a design based on the design of Apple’s Calendar app in macOS Big Sur
- Add `lifespan_years` Liquid filter that returns an array of the years a given `person` was alive, if both the birth and death year are known
- Index page now shows list of years, rather than a list of all the dates that have content
- Index page’s list of years is the `lifespan_years` of `subject_person_key` in `_config.yml`
- Add `HistoricalDiaryPage` subclass of `Jekyll::Page`
- Set `has_source_material` property for `HistoricalDiary::DayPage`
- Add CSS for the `prefers-contrast: more` media query

### Changed
- Rework CSS so all variables are grouped, and rules use aliases for colors instead of referencing them directly, making it easier to maintain the dark-mode variant

### Fixed
- Only preload the Garamond font file for pages that need it, determined by a `has_source_material` property in a page’s `data`
- Add `crossorigin` attribute to font preload -- otherwise the browser won’t use it
- Site is now usable on mobile screens
- Improve accessibility and HTML standards compliance

## [1.0.3] - 2021-02-09
### Added
- Person pages now display context from the person’s lifetime, if any is available
- Date pages now indicate if source material spans multiple days
- Context data from Thomas Short’s ‘A General Chronological History of the Air, Weather, Seasons, Meteors…’, covering 1527–1608
- Display information about volumes on source page
- Manage AWS infrastructure for `drjohndee.net` with Terraform

### Changed
- Use `volume_key` instead of `volume`, and adjust source data to list volume
details for each edition -- this makes it easy to specify the `numberOfPages` property
- Create and consistently use permalinks as person and source `itemid`s
- Improve font loading

### Fixed
- `transclusions_for_timestamp` can now return transclusions for multiple dates, improving the `commentary_for_date`, `context_for_date`, and `relevant_footnotes` Liquid filters
- Put page title back in `<title>` --- was broken as part of removing the `jekyll-seo-tag` plugin

## [1.0.2] - 2021-02-06
### Added
- Set `license` property where possible
- `person_name` Liquid filter simplifies displaying names from `people` data
- Page title and `headline` property now have more than just the date
- `people` data for Thomas Short (author of ‘New Observations, Natural, Moral, Civil, Political and Medical…’)
- Link to DOI if available

### Changed
- Manually render page metadata instead of using `jekyll-seo-tag` plugin -- the plugin doesn’t have a way to disable JSON-LD output, but, that output is a secondary, lower-quality version of the structured data applied throughout the site
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

[Unreleased]: https://github.com/stilist/drjohndee.net/compare/v1.0.10...HEAD
[1.0.10]: https://github.com/stilist/drjohndee.net/compare/v1.0.9...v1.0.10
[1.0.9]: https://github.com/stilist/drjohndee.net/compare/v1.0.8...v1.0.9
[1.0.8]: https://github.com/stilist/drjohndee.net/compare/v1.0.7...v1.0.8
[1.0.7]: https://github.com/stilist/drjohndee.net/compare/v1.0.6...v1.0.7
[1.0.6]: https://github.com/stilist/drjohndee.net/compare/v1.0.5...v1.0.6
[1.0.5]: https://github.com/stilist/drjohndee.net/compare/v1.0.4...v1.0.5
[1.0.4]: https://github.com/stilist/drjohndee.net/compare/v1.0.3...v1.0.4
[1.0.3]: https://github.com/stilist/drjohndee.net/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/stilist/drjohndee.net/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/stilist/drjohndee.net/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/stilist/drjohndee.net/releases/tag/v1.0.0
