# GitFame
[![Join the chat at https://gitter.im/oleander/git-fame-rb](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/oleander/git-fame-rb)
[![Build Status](https://travis-ci.org/oleander/git-fame-rb.svg?branch=master)](https://travis-ci.org/oleander/git-fame-rb)
[![Coverage Status](https://coveralls.io/repos/oleander/git-fame-rb/badge.svg?branch=master&service=github)](https://coveralls.io/github/oleander/git-fame-rb?branch=master)

Pretty-print collaborators sorted by contributions.

## Output

```
Total number of files: 2,053
Total number of lines: 63,132
Total number of commits: 4,330

+------------------------+--------+---------+-------+--------------------+
| name                   | loc    | commits | files | distribution       |
+------------------------+--------+---------+-------+--------------------+
| Johan Sørensen         | 22,272 | 1,814   | 414   | 35.3 / 41.9 / 20.2 |
| Marius Mathiesen       | 10,387 | 502     | 229   | 16.5 / 11.6 / 11.2 |
| Jesper Josefsson       | 9,689  | 519     | 191   | 15.3 / 12.0 / 9.3  |
| Ole Martin Kristiansen | 6,632  | 24      | 60    | 10.5 / 0.6 / 2.9   |
| Linus Oleander         | 5,769  | 705     | 277   | 9.1 / 16.3 / 13.5  |
| Fabio Akita            | 2,122  | 24      | 60    | 3.4 / 0.6 / 2.9    |
| August Lilleaas        | 1,572  | 123     | 63    | 2.5 / 2.8 / 3.1    |
| David A. Cuadrado      | 731    | 111     | 35    | 1.2 / 2.6 / 1.7    |
| Jonas Ängeslevä        | 705    | 148     | 51    | 1.1 / 3.4 / 2.5    |
| Diego Algorta          | 650    | 6       | 5     | 1.0 / 0.1 / 0.2    |
| Arash Rouhani          | 629    | 95      | 31    | 1.0 / 2.2 / 1.5    |
| Sofia Larsson          | 595    | 70      | 77    | 0.9 / 1.6 / 3.8    |
| Tor Arne Vestbø        | 527    | 51      | 97    | 0.8 / 1.2 / 4.7    |
| spontus                | 339    | 18      | 42    | 0.5 / 0.4 / 2.0    |
| Pontus                 | 225    | 49      | 34    | 0.4 / 1.1 / 1.7    |
+------------------------+--------+---------+-------+--------------------+
```

## Installation

`[sudo] gem install git_fame`

## Usage

### Console

Start by navigating to a git repository.

Run `git fame` to generate output as above.

#### Options

- `git fame --bytype` Should a breakout of line counts by file type be output? Default is `false`.
- `git fame --exclude=paths/to/files,paths/to/other/files` Comma separated, realtive paths to exclude from the counts. Note that you should not start the paths with a dot. Default is none.
- `git fame --sort=loc` Order table by `loc`. Available options are: `loc`, `commits` and `files`. Default is `loc`.
- `git fame --progressbar=1` Should a progressbar be visible during the calculation? Default is `1`.
- `git fame --whitespace` Ignore whitespace changes when blaming files. Default is `false`.
- `git fame --repository=/path/to/repo` Git repository to be used. Default is the current folder.
- `git fame --branch=master` Branch to run on. Default is `master`.
- `git fame --format=output` Output format. Default is `pretty`. Additional: csv.

### Class

Want to work with the data before printing it?

#### Constructor arguments

- **repository** (String) Path to repository.
- **sort** (String) What should #authors be sorted by? Available options are: `loc`, `commits` and `files`. Default is `loc`.
- **progressbar** (Boolean) Should a progressbar be shown during the calculation? Default is `false`.
- **whitespace** (Boolean) Ignore whitespace changes when blaming files. Default is `false`.
- **bytype** (Boolean) Should a breakout of line counts by file type be output? Default is 'false'
- **exclude** (String) Comma separated paths to exclude from the counts. Default is none.
- **branch** (String) Branch to run on. Default is `master`.
- **format** (String) Output format. Default is `pretty`.

``` ruby
repository = GitFame::Base.new({
  sort: "loc",
  repository: "/tmp/repo",
  progressbar: false,
  whitespace: false
  bytype: false,
  exclude: "vendor, public/assets",
  branch: "master",
  format: "pretty"
})
```

#### Print table to console

`repository.pretty_puts`

#### Print csv table to console

`repository.csv_puts`

### Statistics

#### GitFame

- `repository.loc` (Fixnum) Total number of lines.
- `repository.commits` (Fixnum) Total number of commits.
- `repository.files` (Fixnum) Total number of files.
- `repository.authors` (Array< Author >) All authors.

#### Author

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

#### A note about authors found

The list of authors may include duplicate people. If a git user's configured name or email address change over time, the person will appear multiple times in this list (and your repo's git history). Git allows you to configure this using the .mailmap feature. See ````git shortlog --help```` for more information.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Testing

1. Download fixtures (`spec/fixtures`) using `git submodule update --init`.
2. Run rspec using `rspec spec/git_fame_spec.rb`.

## Requirements

*GitFame* should work on all Unix based operating system with Git installed.

## License

*GitFame* is released under the *MIT license*.
