require "string-scrub"

module GitFame
  class Base
    include GitFame::Helper

    #
    # @args[:repository] String Absolute path to git repository
    # @args[:sort] String What should #authors be sorted by?
    # @args[:bytype] Boolean Should counts be grouped by file extension?
    # @args[:exclude] String Comma-separated list of paths in the repo
    #   which should be excluded
    #
    def initialize(args)
      @sort         = "loc"
      @progressbar  = false
      @whitespace   = false
      @bytype       = false
      @exclude      = ""
      @include      = ""
      @since        = "1970-01-01"
      @until        = "now"
      @authors      = {}
      @file_authors = Hash.new { |h,k| h[k] = {} }
      args.keys.each do |name|
        instance_variable_set "@" + name.to_s, args[name]
      end
      @include = convert_include_paths_to_array
      @exclude = convert_exclude_paths_to_array
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

      fields = [:name, :loc, :commits, :files, :distribution]
      if @since or @until
        fields << :added << :deleted << :total
      end
      if @bytype
        fields << populate.instance_variable_get("@file_extensions").
          uniq.sort
      end
      table(authors, fields: fields.flatten)
    end

    #
    # @return Fixnum Total number of files
    #
    def files
      populate.instance_variable_get("@files").count
    end

    #
    # @return Array list of repo files processed
    #
    def file_list
      populate.instance_variable_get("@files")
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
      populate.authors.
        inject(0){ |result, author| author.raw_loc + result }
    end

    #
    # @return Fixnum Total number of lines added
    #
    def added
      populate.authors.inject(0){ |result, author| author.raw_added + result }
    end

    #
    # @return Fixnum Total number of lines deleted
    #
    def deleted
      populate.authors.inject(0){ |result, author| author.raw_deleted + result }
    end

    #
    # @return Array<Author> A list of authors
    #
    def authors
      authors = populate.instance_variable_get("@authors").values
      if @sort
        authors.sort_by do |author|
          if @sort == "name"
            author.send(@sort)
          else
            -1 * author.send("raw_#{@sort}")
          end
        end
      else
        authors
      end
    end

    #
    # @return Boolean Is the given @dir a git repository?
    # @dir Path (relative or absolute) to git repository
    #
    def self.git_repository?(dir)
      return false unless File.directory?(dir)
      Dir.chdir(dir) { system "git rev-parse --git-dir > /dev/null 2>&1" }
    end

    private
    #
    # @command String Command to be executed inside the @repository path
    #
    def execute(command)
      Dir.chdir(@repository) do
        return `#{command}`.scrub
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
      @_populate ||= begin
        @files = execute("git ls-files #{@include}").split("\n")
        @file_extensions = []
        remove_excluded_files
        progressbar = SilentProgressbar.new(
          "Blame",
          @files.count,
          @progressbar
        )
        blame_opts = @whitespace ? "-w" : ""
        @files.each do |file|
          progressbar.inc
          if @bytype
            file_extension = File.extname(file).gsub(/^\./, "")
            file_extension = "unknown" if file_extension.empty?
          end

          unless type = Mimer.identify(File.join(@repository, file))
            next
          end

          if type.binary?
            next
          end

          # only count extensions that aren't binary
          @file_extensions << file_extension
          if @until
            blame_opts += " --since=#{@until}"  # blame since-flag has meaning `until`
          end
          output = execute(
            "git blame '#{file}' #{blame_opts} --line-porcelain"
          )
          output.scan(/^author (.+)$/).each do |author|
            fetch(author.first).raw_loc += 1
            @file_authors[author.first][file] ||= 1
            if @bytype
              fetch(author.first).
                file_type_counts[file_extension] += 1
            end
          end
        end

        if @since or @until
          progressbar_authors = SilentProgressbar.new("Authors", @authors.count, active = @progressbar)
          @authors.each do |name, author|
            progressbar_authors.inc
            lines_stat_cmd = "git log --author='#{name}' --after=#{@since} --before=#{@until}" +
                "--pretty=tformat: --numstat #{@include.join(' ')}"
            execute(lines_stat_cmd).scan(/(\d+)\t(\d+)\t\w+/).each do |added, deleted|
              author.raw_added += added.to_i || 0
              author.raw_deleted += deleted.to_i || 0
            end
            author.raw_total = author.raw_added - author.raw_deleted
          end
          progressbar_authors.finish
        end

        shortlog_cmd = "git shortlog -se "
        if @since
          shortlog_cmd += ' --since=' + @since
        end
        if @until
          shortlog_cmd += ' --until=' + @until
        end
        execute(shortlog_cmd).split("\n").map do |l|
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

      end
      return self
    end

    #
    # Converts @exclude argument to an array and removes leading slash
    #
    def convert_exclude_paths_to_array
      @exclude.split(",").map{|path| path.strip.sub(/\A\//, "") }
    end

    def convert_include_paths_to_array
      @include.split(",").map{|path| path.strip.sub(/\A\//, "") }
    end

    #
    # Removes files matching paths in @exclude from @files instance variable
    #
    def remove_excluded_files
      return if @exclude.empty?
      @files = @files.map do |path|
        next if  path =~ /\A(#{@exclude.join("|")})/
        path
      end.compact
    end
  end
end
