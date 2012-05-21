require "git_blame/version"
require "progressbar"
require "mimer_plus"
require "hirb"
require "action_view"

output = $-v
$-v = false

module GitBlame
  extend Hirb::Console
  include ActionView::Helpers::NumberHelper

  class Base
    #
    # @args[:repository] String Absolute path to git repository
    # @args[:order] String What should #authors be sorted by?
    #
    def initialize(args)
      args.keys.each { |name| instance_variable_set "@" + name.to_s, args[name] }
      @authors = {}
      @file_authors = Hash.new { |h,k| h[k] = {} }
    end

    #
    # @return Fixnum Total number of files
    #
    def files
      populate.instance_variable_get("@files").count
    end

    #
    # @return Fixnum Total number of commits
    #
    def commits
      authors.inject(0){ |result, author| author.commits + result }
    end

    #
    # @return Fixnum Total number of lines
    #
    def loc
      populate.authors.inject(0){|result, author| author.loc + result }
    end

    #
    # @return Array<Author> A list of authors
    #
    def authors
      populate.instance_variable_get("@authors").values
    end

    private
    #
    # @command String Command to be executed inside the @repository path
    #
    def execute(command)
      Dir.chdir(@repository) do
        return `#{command}`
      end
    end

    #
    # @author String Author
    # @args Hash Argument that should be set in @return
    # @return Author
    #
    def update(author, args)
      found = fetch(author)
      args.keys.each do |key|
        found.send("#{key}=", args[key])
      end

      return found
    end

    #
    # @return Author
    # @author String
    #
    def fetch(author)
      @authors[author] ||= Author.new({name: author, parent: self})
    end

    #
    # @return GitBlame
    #
    def populate
      @_pop ||= lambda {
        @files = execute("git ls-files").split("\n")
        @files.each do |file|
          if type = Mimer.identify(File.join(@repository, file)) and not type.mime_type.match(/binary/)
            begin
              execute("git blame '#{file}'").scan(/\((.+?)\s+\d{4}-\d{2}-\d{2}/).each do |author|
                fetch(author.first).loc += 1
                @file_authors[author.first][file] ||= 1
              end
            rescue ArgumentError; end # Encoding error
          end
        end

        execute("git shortlog -se").split("\n").map do |l| 
          _, commits, u = l.match(%r{^\s*(\d+)\s+(.+?)\s+<.+?>}).to_a
          update(u, {commits: commits.to_i, files: @file_authors[u].keys.count})
        end

      }.call
      return self
    end
  end

  class Author
    attr_accessor :name, :files
    attr_writer :commits, :loc

    #
    # @args Hash
    #
    def initialize(args = {})
      args.keys.each { |name| instance_variable_set "@" + name.to_s, args[name] }
    end

    #
    # @return Fixnum Number of lines
    #
    def loc
      @loc ||= 0
    end

    #
    # @return Fixnum Number of commits
    #
    def commits
      @commits || 0
    end

    #
    # @return String Percent of total
    # @format loc / commits / files
    #
    def percent
      "%.1f / %.1f / %.1f" % [:loc, :commits, :files].
        map{ |w| (send(w) / @parent.send(w).to_f) * 100 }
    end
  end
end