# frozen_string_literal: true

require "rugged"
require "tmpdir"

# Builds throwaway git repositories for specs, without a git binary
class GitRepo
  DEFAULT_AUTHOR = { name: "Ada Lovelace", email: "ada@example.com" }.freeze

  attr_reader :repo

  delegate :workdir, to: :repo

  def self.create
    new(Rugged::Repository.init_at(Dir.mktmpdir("git-fame-spec")))
  end

  def initialize(repo)
    @repo = repo
  end

  # Commits on top of HEAD. A nil content deletes the file.
  #
  # @param files [Hash{String => String, nil}] path => content
  #
  # @return [String] the commit id
  def commit(files, author: DEFAULT_AUTHOR, time: Time.utc(2020, 1, 1), message: "Update files")
    index = Rugged::Index.new
    index.read_tree(repo.head.target.tree) unless repo.empty?

    files.each do |path, content|
      if content.nil?
        index.remove(path)
      else
        index.add(path:, oid: repo.write(content, :blob), mode: 0o100644)
      end
    end

    signature = author.merge(time:)
    parents = repo.empty? ? [] : [repo.head.target]

    Rugged::Commit.create(repo, tree: index.write_tree(repo), author: signature, committer: signature, message:,
                                parents:, update_ref: "HEAD")
  end

  # Tags HEAD with an annotated tag
  def tag(name)
    repo.tags.create(name, "HEAD", message: "Release #{name}", tagger: DEFAULT_AUTHOR.merge(time: Time.now))
  end

  def remove
    FileUtils.remove_entry(workdir)
  end
end
