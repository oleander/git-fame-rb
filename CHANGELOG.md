# Changelog

All notable changes to this project are documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Releases before 3.3.0 are listed on [RubyGems](https://rubygems.org/gems/git_fame/versions).

## [Unreleased]

### Changed

- Releases are published when the version in `lib/git_fame/version.rb` changes on `main`, instead of on every push to `main`. The release job tags the merged commit, creates a GitHub release from this changelog and pushes the gem to RubyGems.

### Fixed

- CI no longer depends on the retired Code Climate coverage service, whose upload step was the only step running RSpec on Linux.
- Release tags point to commits on `main`. The old release job amended the version commit after tagging it, so the tags `v3.2.15` to `v3.2.19` point to commits that never reached `main`.
