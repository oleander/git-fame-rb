# frozen_string_literal: true

module GitFame
  class Diff < Base
    include Enumerable

    attribute :commit, Types::Any

    # Files rejected by {Filter#path?} are skipped before they are blamed
    attribute? :path_filter, Types::Any

    delegate :tree, to: :commit
    delegate :repo, to: :tree

    # Blames every text file in {#commit}
    #
    # @yield [Hash] a blame hunk, with the file's path in the commit as :path
    #
    # @return [void]
    def each(&block)
      tree.walk(:preorder).each do |root, entry|
        path = root + entry[:name]

        case entry
        in { type: :blob, oid: }
          blame(path, oid, &block)
        in { type: }
          say("Ignore type [%s] in for %s", type, path)
        end
      end
    end

    private

    def blame(path, oid)
      return if path_filter && !path_filter.path?(path)
      return say("Ignore binary file %s", path) if repo.lookup(oid).binary?

      Rugged::Blame.new(repo, path, newest_commit: commit).each do |hunk|
        yield hunk.merge(path:)
      end
    end
  end
end
