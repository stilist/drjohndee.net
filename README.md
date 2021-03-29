# The life and times of Dr John Dee

This is the data and source code for [`drjohndee.net`](https://www.drjohndee.net/), which I’ve described as ‘Dr Dee’s life, presented with context, from source materials’. You can explore Dee’s writings and experiences, shown in the context of world events.

The project is inspired by [Phil Gyford](https://www.gyford.com)’s [The Diary of Samuel Pepys](https://www.pepysdiary.com). [The source code](https://github.com/philgyford/pepysdiary) for that project is available, though I don’t see an open-source license; the data doesn’t appear to be available outside of the site itself.

This project is built to ensure the material is accessible to as many people as possible, and can continue to be used in the future: the data and source code in this repository are provided under strong open licenses (see [`LICENSE.md`](LICENSE.md)); source material is stored as plain Unicode text; the website makes heavy use of [structured data](https://developers.google.com/search/docs/guides/intro-structured-data), which is built on [schema.org](https://schema.org) definitions; and I’ve used accessibility-testing tools to ensure the website is usable for a wide range of people.

## How this system works

The project is built on [Jekyll](https://jekyllrb.com), though it could use any [static site generator](https://www.netlify.com/blog/2020/04/14/what-is-a-static-site-generator-and-3-ways-to-find-the-best-one/). This repository has a few parts: data, code to process the data, and code to present the data.

The data is currently split between the `_data` directory (Jekyll’s [built-in system for managing data-sets](https://jekyllrb.com/docs/datafiles/)) and the `_source_material` directory. `_source_material` has the ‘raw’ data, with a handful of annotations using [Jekyll’s ‘front matter’ metadata system](https://jekyllrb.com/docs/front-matter/). The content is transcribed from source books and manuscripts, using the same line structure as the source material. (This makes it easier to locate a line from the source material in the transcription, and vice versa.) The `_data` directory has [Yaml files](https://yaml.org) that contain annotations and metadata for the source material. (For example, information about people.)

The `_plugins` directory has [generators](https://jekyllrb.com/docs/plugins/generators/) that create [pages](https://jekyllrb.com/docs/pages/) from data — a page for each year and date that have relevant source material, and for each file in `_data/people` and `_data/sources`.

The [`_includes`](https://jekyllrb.com/docs/includes/) and [`_layouts`](https://jekyllrb.com/docs/layouts/) directories have the HTML files used to generate pages for the site. The `_plugins` directory has [Liquid filters](https://jekyllrb.com/docs/plugins/filters/) that are used by the files in `_includes` and `_layouts`.

Last, the `assets` directory has the CSS and font files that determine the site’s appearance.

## How to run this project on your own machine

You’ll need to have [a supported version of Ruby](https://www.ruby-lang.org/en/downloads/) installed.

```shell
# install Jekyll and dependencies
bundle install

# run Jekyll server
bundle exec jekyll serve
```

[The Jekyll documentation](https://jekyllrb.com/docs/) has more information.

## How to contribute

Improvements and contributions of any kind and any size are welcome: it could be writing new code, improving the website’s design or source code, correcting transcriptions, or something else! The [`CONTRIBUTING.md` file](CONTRIBUTING.md) has more information about how to contribute.

## Conventions for transcribing manuscripts

This project uses a mix of [the diplomatic and semi-diplomatic transcription](https://www.english.cam.ac.uk/ceres/ehoc/conventions.html#advice) systems.

Specifically:

* follow original formatting as closely as Unicode will allow
  * for example, ‘your’ written as ‘y.ͬ’, or [scribal suspensions](https://en.wikipedia.org/wiki/Scribal_abbreviation#Suspension) like ‘cũ’ for ‘cum’
  * retain capitalization, spelling, line breaks, punctuation, hyphenation: for example, preserve inconsistent use of ‘u’ and ‘v’, ‘i’, ‘y’, and ‘j’
  * retain spacing; make a best guess at whether to use a narrow space (Unicode `U+202F`) no-break space (Unicode `U+00A0`)
* use `{x}` to transcribe uncertain letters (‘x’ in this example), and `{.}` to transcribe lost letters or letters too obscure to be inferred (for example, if the word ‘agayne’ were written too sloppy to read it might be transcribed as something like ‘a{ga..}e’)
* use `[x]` to note letters that are obviously missing (for example, ‘[L]undrumguffa’, when all other mentions of the name include an ‘L’)
* use `┌x┐` to note text that was clearly added at a later time
* retain deleted text, bracketed with `‹` and `›` (for example, ‘‹has› had’ means ‘has’ was written first, then crossed out)
