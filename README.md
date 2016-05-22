# GitFame
[![Join the chat at https://gitter.im/oleander/git-fame-rb](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/oleander/git-fame-rb)
[![Build Status](https://travis-ci.org/oleander/git-fame-rb.svg?branch=master)](https://travis-ci.org/oleander/git-fame-rb)
[![Coverage Status](https://coveralls.io/repos/oleander/git-fame-rb/badge.svg?branch=master&service=github)](https://coveralls.io/github/oleander/git-fame-rb?branch=master)

Pretty-print collaborators sorted by contributions.

## Output

```
Total number of files: 24
Total number of lines: 1,029
Total number of commits: 133
+----------------+-----+---------+-------+--------------------+
| name           | loc | commits | files | distribution (%)   |
+----------------+-----+---------+-------+--------------------+
| Linus Oleander | 904 | 116     | 23    | 87.9 / 87.2 / 95.8 |
| f1yegor        | 52  | 7       | 7     |  5.1 /  5.3 / 29.2 |
| Steve Hodges   | 46  | 2       | 5     |  4.5 /  1.5 / 20.8 |
| Paul Padier    | 16  | 2       | 3     |  1.6 /  1.5 / 12.5 |
| David Selassie | 6   | 1       | 2     |  0.6 /  0.8 /  8.3 |
| Niklas Keller  | 2   | 1       | 1     |  0.2 /  0.8 /  4.2 |
| Arash Rouhani  | 1   | 1       | 1     |  0.1 /  0.8 /  4.2 |
| Matt Nedrich   | 1   | 1       | 1     |  0.1 /  0.8 /  4.2 |
| Andrew Fecheyr | 1   | 2       | 1     |  0.1 /  1.5 /  4.2 |
+----------------+-----+---------+-------+--------------------+
```

## Installation

`[sudo] gem install git_fame`

## Usage

### Console

From a git repository run `git fame`.

#### Options

- `git fame --bytype` Includes file types. See the *bytype* section below for more info. Default is `false`.
- `git fame --exclude=path1,path2` Comma separated, relative paths to exclude.
- `git fame --include=path1,path2` Comma separated, relative paths to include.
- `git fame --sort=loc` Order table by `loc`. Available options are: `loc` and `commits`. Default is `loc`.
- `git fame --hide-progressbar` Hide progressbar.
- `git fame --whitespace` Ignore whitespace changes when blaming files. [More about git blame and whitespace](https://coderwall.com/p/x8xbnq/git-don-t-blame-people-for-changing-whitespaces-or-moving-code). Default is `false`.
- `git fame --repository=/path/to/repo` Git repository to be used. Default is the current folder.
- `git fame --branch=master` Branch to run on. Default is what `HEAD` points to.
- `git fame --format=output` Output format. Default is `pretty`. Additional: `csv`.
- `git fame --after=2010-01-01` Only use commmits after this date. Format: yyyy-mm-dd. Note that the given date is included.
- `git fame --before=2016-02-01` Only use commits before this date. Format: yyyy-mm-dd. Note that the given date is included.
- `git fame --verbose` Print shell commands used by `git-fame`.

#### By type

```
Total number of files: 24
Total number of lines: 1,029
Total number of commits: 133
+----------------+-----+---------+-------+--------------------+---------+-----+-----+---------+-----+
| name           | loc | commits | files | distribution (%)   | unknown | yml | md  | gemspec | rb  |
+----------------+-----+---------+-------+--------------------+---------+-----+-----+---------+-----+
| Linus Oleander | 904 | 116     | 23    | 87.9 / 87.2 / 95.8 | 79      | 5   | 119 | 38      | 663 |
| f1yegor        | 52  | 7       | 7     |  5.1 /  5.3 / 29.2 | 3       | 11  | 9   | 1       | 28  |
| Steve Hodges   | 46  | 2       | 5     |  4.5 /  1.5 / 20.8 | 3       | 0   | 9   | 0       | 34  |
| Paul Padier    | 16  | 2       | 3     |  1.6 /  1.5 / 12.5 | 2       | 0   | 0   | 0       | 14  |
| David Selassie | 6   | 1       | 2     |  0.6 /  0.8 /  8.3 | 2       | 0   | 4   | 0       | 0   |
| Niklas Keller  | 2   | 1       | 1     |  0.2 /  0.8 /  4.2 | 0       | 0   | 2   | 0       | 0   |
| Arash Rouhani  | 1   | 1       | 1     |  0.1 /  0.8 /  4.2 | 0       | 0   | 1   | 0       | 0   |
| Matt Nedrich   | 1   | 1       | 1     |  0.1 /  0.8 /  4.2 | 0       | 0   | 1   | 0       | 0   |
| Andrew Fecheyr | 1   | 2       | 1     |  0.1 /  1.5 /  4.2 | 0       | 0   | 0   | 0       | 1   |
+----------------+-----+---------+-------+--------------------+---------+-----+-----+---------+-----+
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

#### A note about authors found

TODO: Fix this

The list of authors may include duplicate people. If a git user's configured name or email address change over time, the person will appear multiple times in this list (and your repo's git history). Git allows you to configure this using the .mailmap feature. See ````git shortlog --help```` for more information.

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