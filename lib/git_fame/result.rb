# frozen_string_literal: true

module GitFame
  class Result < Base
    attribute :contributions, Types.Array(Contribution)

    # @return [Array<Author>]
    def authors
      contributions.map(&:author)
    end

    # Commits that last touched at least one line, each listed once
    #
    # @return [Array<String>]
    def commits
      contributions.flat_map do |c|
        c.commits.to_a
      end.uniq
    end

    # Files with at least one line, each listed once even when several
    # authors contributed to it
    #
    # @return [Array<String>]
    def files
      contributions.flat_map do |c|
        c.files.to_a
      end.uniq
    end

    # @return [Integer]
    def lines
      contributions.sum(&:lines)
    end
  end
end
