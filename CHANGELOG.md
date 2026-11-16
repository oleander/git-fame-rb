# Changelog

All notable changes to this project are documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Releases before 3.3.0 are listed on [RubyGems](https://rubygems.org/gems/git_fame/versions).

## [Unreleased]

### Added

- Support for Ruby 3.4 and 4.0.

### Changed

- Ruby 3.3 or later is required. Ruby 3.1 and 3.2 reached their end of life in March 2025 and March 2026. On older Rubies, `gem install git_fame` keeps installing 3.2.19.
- Dependencies: activesupport 7.1 to 8.x, tty-table 0.12, tty-screen 0.8 and tty-option 0.3. The unused neatjson and tty-box gems are no longer installed, and logger is declared because Ruby 4.0 no longer ships it as a default gem.
- The table keeps its natural width. It no longer stretches to fill a wide terminal, and output that is piped or redirected is no longer fitted into 80 columns.
- The gem declares its MIT license and links to its source code, changelog and issue tracker, and ships with LICENSE, README.md and CHANGELOG.md.
- Releases are published when the version in `lib/git_fame/version.rb` changes on `main`, instead of on every push to `main`. The release job tags the merged commit, creates a GitHub release from this changelog and pushes the gem to RubyGems.

### Fixed

- In an 80-column terminal, the `lines`, `commits` and `files` columns collapsed to zero width and the borders broke. Names and email addresses are now shortened to fit the terminal, and the number columns keep their width.
- CI no longer depends on the retired Code Climate coverage service, whose upload step was the only step running RSpec on Linux.
- Release tags point to commits on `main`. The old release job amended the version commit after tagging it, so the tags `v3.2.15` to `v3.2.19` point to commits that never reached `main`.
