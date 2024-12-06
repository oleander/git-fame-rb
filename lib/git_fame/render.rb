# frozen_string_literal: true

require "tty-screen"
require "tty-table"
require "tty-box"
require "erb"

module GitFame
  class Render < Base
    FIELDS = [:name, :email, :lines, :commits, :files, :dist].map(&:to_s).freeze

    attribute :branch, Types::String
    attribute :result, Result
    delegate_missing_to :result

    using Extension

    # Renders to stdout
    #
    # @return [void]
    def call
      table = TTY::Table.new(header: FIELDS)
      width = TTY::Screen.width

      contributions.reverse_each do |c|
        table << [c.name, c.email, c.lines.f, c.commits.count.f, c.files.count.f, c.dist(self)]
      end

      print table.render(:unicode, width:, resize: true, alignment: [:center])
    end

    private

    def contributions
      result.contributions.sort_by(&:lines)
    end
  end
end
