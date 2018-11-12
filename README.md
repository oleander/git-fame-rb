# git-fame
[![Gem](https://img.shields.io/gem/dt/git_fame.svg)](https://rubygems.org/gems/git_fame)
[![Gitter](https://img.shields.io/gitter/room/oleander/git-fame-rb.svg)](https://gitter.im/oleander/git-fame-rb)
[![Travis](https://img.shields.io/travis/oleander/git-fame-rb.svg)](https://travis-ci.org/oleander/git-fame-rb)
[![Coveralls](https://img.shields.io/coveralls/oleander/git-fame-rb.svg)](https://coveralls.io/github/oleander/git-fame-rb)
[![My personal webpage](https://img.shields.io/badge/me-oleander.io-blue.svg)](http://oleander.io)

`git-fame` is a command-line tool that helps you summarize and pretty-print collaborators in a git repository based on contributions.

## Example output

Statistics generated from this git repository using `git fame .`

```
Statistics based on master
Active files: 21
Active lines: 967
Total commits: 109

Note: Files matching MIME type image, binary has been ignored

+----------------+-----+---------+-------+---------------------+
| name           | loc | commits | files | distribution (%)    |
+----------------+-----+---------+-------+---------------------+
| Linus Oleander | 914 | 106     | 21    | 94.5 / 97.2 / 100.0 |
| f1yegor        | 47  | 2       | 7     |  4.9 /  1.8 / 33.3  |
| David Selassie | 6   | 1       | 2     |  0.6 /  0.9 /  9.5  |
+----------------+-----+---------+-------+---------------------+
```

## Installation

`[sudo] gem install git_fame`

## Usage

### Command-line

From a git repository run `git fame .`

#### Options

- `git fame --by-type` Group line counts by file extension (i.e. .rb, .erb, .yml). See the *by type* section below.
- `git fame --exclude=path1/*,path2/*` Comma separated, [glob](https://en.wikipedia.org/wiki/Glob_(programming)) file path to exclude.
- `git fame --include=path1/*,path2/*` Comma separated, [glob](https://en.wikipedia.org/wiki/Glob_(programming)) file path to include.
- `git fame --sort=loc` Order table by `loc`. Available options are: `loc`, `files` and `commits`. Default is `loc`.
- `git fame --hide-progressbar` Hide progressbar.
- `git fame --whitespace` Ignore whitespace changes when blaming files. [More about git blame and whitespace](https://coderwall.com/p/x8xbnq/git-don-t-blame-people-for-changing-whitespaces-or-moving-code).
- `git fame --repository=/path/to/repo` Git repository to be used. Default is the current folder.
- `git fame --branch=HEAD` Branch to run on. Default is what `HEAD` points to.
- `git fame --format=output` Output format. Default is `pretty`. Additional: `csv`.
- `git fame --after=2010-01-01` Only use commits after this date. Format: yyyy-mm-dd. Note that the given date is included.
- `git fame --before=2016-02-01` Only use commits before this date. Format: yyyy-mm-dd. Note that the given date is included.
- `git fame --verbose` Print shell commands used by `git-fame`.
- `git fame --everything` Images and binaries are ignored by default. Include them as well.
- `git fame --timeout` Set timeout in seconds for each git command.

#### By type

`--by-type` adds extra columns file types.

```
+----------------+-----+---------+-------+---------------------+---------+-----+----+---------+-----+
| name           | loc | commits | files | distribution (%)    | unknown | yml | md | gemspec | rb  |
+----------------+-----+---------+-------+---------------------+---------+-----+----+---------+-----+
| Linus Oleander | 914 | 106     | 21    | 94.5 / 97.2 / 100.0 | 32      | 5   | 61 | 23      | 257 |
| f1yegor        | 47  | 2       | 7     |  4.9 /  1.8 / 33.3  | 3       | 5   | 6  | 1       | 10  |
| David Selassie | 6   | 1       | 2     |  0.6 /  0.9 /  9.5  | 2       | 0   | 3  | 0       | 0   |
+----------------+-----+---------+-------+---------------------+---------+-----+----+---------+-----+
```

### Programmatically

Want to work with the data before using it? Here's how.

#### Constructor arguments

`options` is a hash with most of the arguments passed to the binary defined above.
Take a look at the [bin/git-fame](bin/git-fame) file for more information.

``` ruby
repository = GitFame::Base.new(options)
```

#### Print table

`repository.pretty_puts` outputs the statistics as an ascii table.


#### Print csv table to console

`repository.csv_puts` outputs the statistics as csv.

#### Statistics

##### GitFame

- `repository.loc` (Fixnum) Total number of lines.
- `repository.commits` (Fixnum) Total number of commits.
- `repository.files` (Fixnum) Total number of files.
- `repository.authors` (Array< Author >) All authors.

##### Author

`author = repository.authors.first`

- Formated
  - `author.loc` (String) Number of lines.
  - `author.commits` (String) Number of commits.
  - `author.files` (String) Number of files changed.
- Non formated
  - `author.distribution` (String) Distribution (in %) between users (loc/commits/files)
  - `author.raw_loc` (Fixnum) Number of lines.
  - `author.raw_commits` (Fixnum) Number of commits.
  - `author.raw_files` (Fixnum) Number of files changed.
  - `author.file_type_counts` (Array) File types (k) and loc (v)

## Testing

1. Download fixtures (`spec/fixtures`) using `git submodule update --init`.
2. Run rspec using `bundle exec rspec`.

Note that `puts` has been disabled to avoid unnecessary output during testing.
Visit `spec/spec_helper.rb` to enable it again.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Requirements

*GitFame* should work on all Unix based operating system with Git installed.

## License

*GitFame* is released under the *MIT license*.
