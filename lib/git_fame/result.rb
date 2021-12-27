# frozen_string_literal: true

module GitFame
  class Result < Base
    attribute :contributions, Types.Array(Contribution)

    def authors
      contributions.map(&:author)
    end

    def commits
      contributions.flat_map do |c|
        c.commits.to_a
      end
    end

    def files
      contributions.flat_map do |c|
        c.files.to_a
      end
    end

    def lines
      contributions.sum(&:lines)
    end
  end
end
