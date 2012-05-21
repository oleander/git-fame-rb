# GitBlame

Who did what in your project?
GitBlame generates som much needed statistics from your current git repository. 

## Output

Example out from the [water project](https://github.com/water/mainline).

```
Total number of files: 2,053
Total number of lines: 63,132
Total number of commits: 4,330
+------------------------+--------+---------+-------+--------------------+
| name                   | loc    | commits | files | percent            |
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

## Usage

### Console

Start by navigating to a git repository.

#### Plain

`git accuse`

#### Order by a specific field

Order by the amounts of current lines of code `loc`, the amounts of `commits` or author

- `git accuse --order=loc`
- `git accuse --order=commits`
- `git accuse --order=author`

Default is `loc`.

### Class

Want to work with the data before printing it?

`repository = GitBlame.new`

#### Order by

The constructor takes a hash with arguments, one being the `order` key.

`GitBlame.new({order: "loc"})`

#### Print table to console

`repository.pretty_print`

### Statistics

#### GitBlame

- Total number of lines
  - `repository.loc`
- Total number of commits
  - `repository.commits`
- Total number of files
  - `repository.files`
- All authors
  - `repository.authors`

#### Author

`author = repository.authors`

- Number of lines
  - `author.loc`
- Number of commits
  - `author.commits`
- Number of files changed
  - `author.files`
- Percent of total (loc/commits/files)
  - `author.percent`

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
