# frozen_string_literal: true

module GitFame
  class Diff < Base
    include Enumerable

    attribute :commit, Types::Any
    delegate :tree, to: :commit
    delegate :repo, to: :tree

    # @yield [Hash]
    #
    # @return [void]
    def each(&block)
      tree.walk(:preorder).each do |_root, entry|
        case entry
        in { type: :blob, name: file }
          Rugged::Blame.new(repo, file, newest_commit: commit).each do |change|
            block[change.merge(file_path: Pathname(file))]
          end
        in { type: type, name: file }
          say("Ignore type %s in for %s", type, file)
        end
      rescue Rugged::TreeError => e
        next warn(e.message)
      end
    end
  end
end
