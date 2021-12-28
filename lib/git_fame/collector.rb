# frozen_string_literal: true

module GitFame
  class Collector
    extend Dry::Initializer

    option :filter, type: Filter
    option :diff, type: Types::Any

    # @return [Collector]
    def call
      Result.new(contributions: contributions)
    end

    private

    def contributions
      commits = Hash.new { |h, k| h[k] = Set.new }
      files = Hash.new { |h, k| h[k] = Set.new }
      lines = Hash.new(0)
      names = {}

      diff.each do |change|
        filter.call(change) do |loc, file, oid, name, email|
          if commits[email].add?(oid)
            files[email].add(file)
            names[email] = name
            lines[email] += loc
          end
        end
      end

      lines.each_key.map do |email|
        Contribution.new({
          lines: lines[email],
          commits: commits[email],
          files: files[email],
          author: {
            name: names[email],
            email: email
          }
        })
      end
    end
  end
end
