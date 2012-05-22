module GitBlame

  class Base
    include ActionView::Helpers::NumberHelper

    #
    # @args[:repository] String Absolute path to git repository
    # @args[:order] String What should #authors be sorted by?
    #
    def initialize(args)
      @sort = "loc"
      @progressbar = false
      args.keys.each { |name| instance_variable_set "@" + name.to_s, args[name] }
      @authors = {}
      @file_authors = Hash.new { |h,k| h[k] = {} }
    end

    #
    # Generates pretty output
    #
    def pretty_puts
      extend Hirb::Console
      Hirb.enable({pager: false})
      puts "Total number of files: #{number_with_delimiter(files)}"
      puts "Total number of lines: #{number_with_delimiter(loc)}"
      puts "Total number of commits: #{number_with_delimiter(commits)}"
      table(authors, fields: [:name, :f_loc, :f_commits, :f_files, :percent])
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
      authors = populate.instance_variable_get("@authors").values
      @sort ? authors.sort_by do |author| 
        if @sort == "name"
          author.send(@sort) 
        else
          -1 * author.send(@sort)
        end
      end : authors
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
        progressbar = SilentProgressbar.new("Blame", @files.count, @progressbar)
        @files.each do |file|
          progressbar.inc
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

        progressbar.finish

      }.call
      return self
    end
  end
end