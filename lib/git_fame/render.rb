# frozen_string_literal: true

require "tty-table"

module GitFame
  class Render < Base
    FIELDS = [:name, :email, :lines, :commits, :files, :dist].map(&:to_s).freeze

    # Indexes of the columns that are truncated when the table is wider than
    # the terminal: name and email. The number columns keep their width.
    SHRINKABLE_COLUMNS = [0, 1].freeze

    # Truncated columns keep at least this many characters.
    MIN_COLUMN_WIDTH = 8

    attribute :branch, Types::String
    attribute :result, Result

    # Width of the terminal the table is printed to. Without it, the table is
    # printed at its natural width.
    attribute? :width, Types::Integer.optional
    delegate_missing_to :result

    using Extension

    # Renders to stdout
    #
    # @return [void]
    def call
      table = TTY::Table.new(header: FIELDS)

      contributions.reverse_each do |c|
        table << [escape(c.name), escape(c.email), c.lines.f, c.commits.count.f, c.files.count.f, c.dist(self)]
      end

      print render(table)
    end

    private

    def render(table)
      widths = column_widths(table)
      table.render(:unicode, column_widths: widths, width: table_width(widths), resize: false, alignment: [:center])
    end

    # Writes tabs and line breaks as \t, \r and \n, like the escape step in
    # tty-table, but before the column widths are measured. Rugged labels
    # author names UTF-8 even when a commit stored them in another encoding;
    # invalid bytes become U+FFFD instead of raising ArgumentError.
    #
    # @return [String]
    def escape(text)
      text.scrub.gsub(/[\t\r\n]/) { |char| char.dump.delete('"') }
    end

    # Natural column widths, with name and email truncated as needed to fit
    # the table within {#width}. TTY::Table::Columns is private API, which is
    # why the gemspec allows tty-table 0.12.x only.
    #
    # @return [Array<Integer>]
    def column_widths(table)
      widths = TTY::Table::Columns.extract_widths(table.data)
      return widths unless width

      overflow = table_width(widths) - width

      while overflow.positive?
        index = SHRINKABLE_COLUMNS.max_by { |i| widths[i] }
        break if widths[index] <= MIN_COLUMN_WIDTH

        widths[index] -= 1
        overflow -= 1
      end

      widths
    end

    # Columns plus the vertical borders around and between them
    #
    # @return [Integer]
    def table_width(widths)
      widths.sum + widths.size + 1
    end

    def contributions
      result.contributions.sort_by(&:lines)
    end
  end
end
