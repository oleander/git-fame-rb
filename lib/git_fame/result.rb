# frozen_string_literal: true

module GitFame
  class Result < Base
    attribute :contributions, Types.Array(Contribution)

    # @return [Array<Author>]
    def authors
      contributions.map(&:author)
    end

    # @return [Array<String>]
    def commits
      contributions.flat_map do |c|
        c.commits.to_a
      end
    end

    # @return [Array<String>]
    def files
      contributions.flat_map do |c|
        c.files.to_a
      end
    end

    # @return [Integer]
    def lines
      contributions.sum(&:lines)
    end
  end
end
