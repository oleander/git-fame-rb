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

    using Module.new {
      refine Contribution do
        def dist(result)
          l = lines.to_f / result.lines
          c = commits.count.to_f / result.commits.count
          f = files.count.to_f / result.files.count

          "%0.1f%% / %0.1f%% / %0.1f%%" % [l * 100, c * 100, f * 100]
        end
      end
    }

    def call
      table = TTY::Table.new(header: FIELDS)

      contributions.map do |c|
        table << [c.name, c.email, c.lines, c.commits.count, c.files.count, c.dist(self)]
      end

      print table.render(:unicode, width: TTY::Screen.width, resize: true, alignment: [:center])
    end
  end
end
