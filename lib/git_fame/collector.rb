# frozen_string_literal: true

module GitFame
  class Collector
    extend Dry::Initializer

    option :filter, type: Filter
    option :diff, type: Diff

    param :commits, type: Types::Hash, default: -> { Hash.new { |h, k| h[k] = Set.new } }
    param :files, type: Types::Hash, default: -> { Hash.new { |h, k| h[k] = Set.new } }
    param :lines, type: Types::Hash, default: -> { Hash.new(0) }
    param :names, type: Types::Hash, default: -> { {} }

    # @return [Collector]
    def call
      Result.new(contributions: contributions)
    end

    private

    def contributions
      diff.each do |change|
        filter.call(change) do |loc, file, oid, name, email|
          commits[email].add(oid)
          files[email].add(file)
          names[email] = name
          lines[email] += loc
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
