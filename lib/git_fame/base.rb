require "csv"
require_relative "./errors"
require "open3"
if RUBY_VERSION.to_f < 2.1
  require "scrub_rb"
end

module GitFame
  class Base
    include GitFame::Helper

    #
    # @args[:repository] String Absolute path to git repository
    # @args[:sort] String What should #authors be sorted by?
    # @args[:bytype] Boolean Should counts be grouped by file extension?
    # @args[:exclude] String Comma-separated list of paths in the repo
    #   which should be excluded
    # @args[:branch] String Branch to run from
    #
    def initialize(args)
      @sort         = "loc"
      @progressbar  = false
      @whitespace   = false
      @bytype       = false
      @extensions   = ""
      @exclude      = ""
      @include      = ""
      @authors      = {}
      @file_authors = Hash.new { |h,k| h[k] = {} }
      args.keys.each do |name|
        instance_variable_set "@" + name.to_s, args[name]
      end

      @exclude = convert_exclude_paths_to_array
      @extensions = convert_extensions_to_array

      # User defined branch must exist
      if not @branch.nil? and not default_branch_exists?
        raise GitFame::BranchNotFound, "Branch '#{@branch}' does not exist"
      end

      @branch ||= default_branch

      # Fields that should be visible in the final table
      # Used by #csv_puts, #to_csv and #pretty_puts
      # Format: [ [ :method_on_author, "custom column name" ] ]
      @visible_fields = [
        :name,
        :loc,
        :commits,
        :files,
        [:distribution, "distribution (%)"]
      ]
    end

    #
    # Generates pretty output
    #
    def pretty_puts
      extend Hirb::Console
      Hirb.enable({ pager: false })
      puts "\nTotal number of files: #{number_with_delimiter(files)}"
      puts "Total number of lines: #{number_with_delimiter(loc)}"
      puts "Total number of commits: #{number_with_delimiter(commits)}\n"

      table(authors, fields: printable_fields)
    end

    #
    # Prints CSV
    #
    def csv_puts
      puts to_csv
    end

    #
    # Generate csv output
    #
    def to_csv
      CSV.generate do |csv|
        csv << fields
        authors.each do |author|
          csv << fields.map do |f|
            author.send(f)
          end
        end
      end
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
    # @return Array<Author> A list of authors
    #
    def authors
      @_authors ||= begin
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
    end

    private

    def printable_fields
      @_printable_fields ||= raw_fields.map do |field|
        field.is_a?(Array) ? field.last : field
      end
    end

    def raw_fields
      return @visible_fields unless @bytype
      @_raw_fields ||= (
        @visible_fields + populate.instance_variable_get("@file_extensions")
      ).uniq
    end

    def fields
      @_fields ||= raw_fields.map do |field|
        field.is_a?(Array) ? field.first : field
      end
    end

    #
    # @command String Command to be executed inside the @repository path
    #
    def execute(command, silent = false)
      result = Open3.popen2e(command, chdir: @repository) do |_, out, thread|
        Result.new(out.read, thread.value.success?)
      end

      return result if result.success? or silent
      raise cmd_error_message(command, result.data)
    rescue Errno::ENOENT
      raise cmd_error_message(command, $!.message)
    end

    def cmd_error_message(command, message)
      "Could not run '#{command}' => #{message}"
    end

    class Result < Struct.new(:data, :success?)
      def to_s
        data
      end
    end

    # Boolean Does the branch exist?
    def default_branch_exists?
      branch_exists?(@branch)
    end

    def branch_exists?(branch)
      execute("git show-ref '#{branch}'", true).success?
    end

    def default_branch
      return "master" if branch_exists?("master")
      if (result = execute("git rev-parse HEAD")).success?
        return result.data
      end

      raise BranchNotFound.new("No branch found")
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
        command = "git ls-tree -r #{@branch} --name-only #{@include}"
        command += " | grep \"\\.\\(#{@extensions.join("\\|")}\\)$\"" unless @extensions.empty?
        @files = execute(command).to_s.split("\n")
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

          output = execute(
            "git blame #{blame_opts} --line-porcelain #{@branch} -- '#{file}'"
          ).to_s
          output.scan(/^author (.+)$/).each do |author|
            fetch(author.first).raw_loc += 1
            @file_authors[author.first][file] ||= 1
            if @bytype
              fetch(author.first).
                file_type_counts[file_extension] += 1
            end
          end
        end

        execute("git shortlog #{@branch} -se").to_s.split("\n").map do |l|
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

    #
    # Converts @extensions argument to an array
    #
    def convert_extensions_to_array
      @extensions.split(",")
    end

    #
    # Removes files matching paths in @exclude from @files instance variable
    #
    def remove_excluded_files
      return if @exclude.empty?
      @files = @files.map do |path|
        next if path =~ /\A(#{@exclude.join("|")})/
        path
      end.compact
    end
  end
end
