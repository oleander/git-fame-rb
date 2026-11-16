# Changelog

All notable changes to this project are documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Releases before 3.3.0 are listed on [RubyGems](https://rubygems.org/gems/git_fame/versions).

## [Unreleased]

### Added

- Support for Ruby 3.4 and 4.0.

### Changed

- Ruby 3.3 or later is required. Ruby 3.1 and 3.2 reached their end of life in March 2025 and March 2026. On Ruby 3.1 and 3.2, `gem install git_fame` keeps installing 3.2.19.
- Dependencies: activesupport 7.1 to 8.x, tty-table 0.12, tty-screen 0.8 and tty-option 0.3. The unused neatjson and tty-box gems are no longer installed, and logger is declared because Ruby 4.0 no longer ships it as a default gem.
- The table keeps its natural width. It no longer stretches to fill a wide terminal, and output that is piped or redirected is no longer fitted into 80 columns.
- The gem declares its MIT license and links to its source code, changelog and issue tracker, and ships with LICENSE, README.md and CHANGELOG.md.
- Binary files are skipped. They used to add their newline bytes to the line counts, which git-fame 2.x did not do either.
- The file share in the `dist` column is relative to the number of distinct files, as in git-fame 2.x. It used to be relative to the sum of every author's file count, which counted a file once per author.
- Files left out by `--include`, `--exclude` or `--extensions` are no longer blamed at all, which makes filtered runs faster.
- The README explains what each column counts and that `git fame -h` shows the help, since git turns `git fame --help` into a man page lookup.
- Releases are published when the version in `lib/git_fame/version.rb` changes on `main`, instead of on every push to `main`. The release job tags the merged commit, creates a GitHub release from this changelog and pushes the gem to RubyGems.

### Fixed

<<<<<<< HEAD
- Outside a git repository, in a repository or on a branch without commits, with an unknown `--branch`, with an unreadable repository file and with an invalid option value such as `--log-level loud`, git-fame printed a stack trace. It now prints an error message and exits with status 1.
- `--branch` with an annotated tag raised `NameError`. Annotated tags now resolve to the commit they point to.
- `--include`, `--exclude` and `--extensions` matched renamed files by their path before the rename, so `--extensions .ts` missed a file renamed from `.js` to `.ts`.
- `--include` or `--exclude` with a non-ASCII pattern crashed with `Encoding::CompatibilityError` on files with non-ASCII names.
- A blame hunk without an author or path raised `NoMatchingPatternError`; such hunks are now skipped.
- The help text described `--before` as "after this date" and `--after` as "before this date", and showed `[BLOB]` instead of `[GLOB]` for `-E` and `-I`.
- When no lines match the filters, git-fame explains that on stderr instead of printing nothing.
- The table ends with a newline, so the shell prompt no longer starts on its last line.
- Ctrl-C exits with status 130 instead of 0.
- `exe/git-fame` run from a source checkout added `exe/lib` instead of `lib` to the load path.
||||||| a20ee3d
=======
- An author name or email that is not valid UTF-8 crashed the table with `ArgumentError: invalid byte sequence in UTF-8`; invalid bytes are now shown as U+FFFD.
>>>>>>> chore/ruby-4-and-deps
- In an 80-column terminal, the `lines`, `commits` and `files` columns collapsed to zero width and the borders broke. Names and email addresses are now shortened to fit the terminal, and the number columns keep their width.
- CI no longer depends on the retired Code Climate coverage service, whose upload step was the only step running RSpec on Linux.
- Release tags point to commits on `main`. The old release job amended the version commit after tagging it, so the tags `v3.2.15` to `v3.2.19` point to commits that never reached `main`.
