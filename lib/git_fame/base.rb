module GitFame
  class Base
    include GitFame::Helper

    #
    # @args[:repository] String Absolute path to git repository
    # @args[:sort] String What should #authors be sorted by?
    #
    def initialize(args)
      @sort = "loc"
      @progressbar = false
      @whitespace = false
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
      puts "\nTotal number of files: #{number_with_delimiter(files)}"
      puts "Total number of lines: #{number_with_delimiter(loc)}"
      puts "Total number of commits: #{number_with_delimiter(commits)}\n"
      table(authors, fields: [:name, :loc, :commits, :files, :percent])
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
      authors.inject(0){ |result, author| author.raw_commits + result }
    end

    #
    # @return Fixnum Total number of lines
    #
    def loc
      populate.authors.inject(0){ |result, author| author.raw_loc + result }
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
          -1 * author.send("raw_#{@sort}")
        end
      end : authors
    end

    #
    # @return Boolean Is the given @dir a git repository?
    # @dir Path (relative or absolute) to git repository
    #
    def self.git_repository?(dir)
      Dir.exists?(File.join(dir, ".git"))
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
      fetch(author).tap do |found|
        args.keys.each do |key|
          found.send("#{key}=", args[key])
        end
      end
    end

    #
    # @return Author
    # @author String
    #
    def fetch(author)
      @authors[author] ||= Author.new({name: author, parent: self})
    end

    #
    # @return GitFame
    #
    def populate
      @_pop ||= lambda {
        @files = execute("git ls-files").split("\n")
        progressbar = SilentProgressbar.new("Blame", @files.count, @progressbar)
        blame_opts = @whitespace ? "-w" : ""
        @files.each do |file|
          progressbar.inc
          if type = Mimer.identify(File.join(@repository, file)) and not type.mime_type.match(/binary/)
            begin
              execute("git blame '#{file}' #{blame_opts} --line-porcelain").scan(/^author (.+)$/).each do |author|
                fetch(author.first).raw_loc += 1
                @file_authors[author.first][file] ||= 1
              end
            rescue ArgumentError; end # Encoding error
          end
        end

        execute("git shortlog -se").split("\n").map do |l| 
          _, commits, u = l.match(%r{^\s*(\d+)\s+(.+?)\s+<.+?>}).to_a
          user = fetch(u)
          # Has this user been updated before?
          if user.raw_commits.zero?
            update(u, {
              raw_commits: commits.to_i, 
              raw_files: @file_authors[u].keys.count, 
              files_list: @file_authors[u].keys
            })
          else
            # Calculate the number of files edited by users
            files = (user.files_list + @file_authors[u].keys).uniq
            update(u, {
              raw_commits: commits.to_i + user.raw_commits, 
              raw_files: files.count, 
              files_list: files
            })
          end
        end

        progressbar.finish

      }.call
      return self
    end
  end
end
