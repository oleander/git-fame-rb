# frozen_string_literal: true

require "tty-table"
require "tty-box"
require "erb"

module GitFame
  class Render < Base
    FIELDS = [:name, :email, :lines, :commits, :files, :dist].map(&:to_s).freeze

    Table = Struct.new(:name, :email, :lines)
    attribute :branch, Types::String
    attribute :result, Result
    delegate_missing_to :result

    def call
      table = TTY::Table.new(header: FIELDS)

      contributions.map do |c|
        table << [c.name, c.email, c.lines, c.commits.count, c.files.count, dist(c)]
      end

      print table.render(:unicode, width: TTY::Screen.width, resize: true, alignment: [:center])
    end

    private

    def dist(contribution)
      l = contribution.lines.to_f / lines
      c = contribution.commits.count.to_f / commits.count
      f = contribution.files.count.to_f / files.count

      "%0.1f%% / %0.1f%% / %0.1f%%" % [l * 100, c * 100, f * 100]
    end

    def files_count
      number_with_delimiter(files.count)
    end

    def contributions_count
      contributions.count
    end

    def commits_count
      number_with_delimiter(commits.count)
    end

    def lines_count
      number_with_delimiter(lines)
    end

    def table_authors
      contributions.map do |c|
        Table.new(c.name, c.email, number_with_delimiter(c.lines))
      end
    end
  end
end
