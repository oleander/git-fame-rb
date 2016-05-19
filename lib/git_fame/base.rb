require "csv"
require "date"
require_relative "./errors"
require "pp" # TODO: Remove
require_relative "./result"
require_relative "./file"
require "open3"

if RUBY_VERSION.to_f < 2.1
  require "scrub_rb"
end

# TODO: Move this
module GitFame
  class Error < StandardError
  end

  class NothingFound < StandardError
  end
end

module GitFame
  class Base
    include GitFame::Helper
    attr_accessor :file_extensions

    #
    # @args[:repository] String Absolute path to git repository
    # @args[:sort] String What should #authors be sorted by?
    # @args[:bytype] Boolean Should counts be grouped by file extension?
    # @args[:exclude] String Comma-separated list of paths in the repo
    #   which should be excluded
    # @args[:branch] String Branch to run from
    # @args[:after] date after
    # @args[:before] date before
    #
    def initialize(args)
      @default_settings = {
        branch: "master",
        sorting: "loc"
      }
      @progressbar  = args.fetch(:progressbar, false)
      @file_authors = Hash.new { |h,k| h[k] = {} }
      # Create array out of comma separated list
      @exclude = args.fetch(:exclude, "").split(",").
        map{ |path| path.strip.sub(/\A\//, "") }
      @extensions = args.fetch(:extensions, "").split(",")
      # Default sorting option is by loc
      @include = args.fetch(:include, "").split(",")
      @sort = args.fetch(:sort, @default_settings.fetch(:sorting))
      @repository = args.fetch(:repository)
      @bytype = args.fetch(:bytype, false)
      @branch = args.fetch(:branch, default_branch)
      @since = args.fetch(:since, "1970-02-01")
      @until = args.fetch(:until,"now")

      # Figure out what branch the caller is using
      if present?(@branch = args[:branch])
        unless branch_exists?(@branch)
          raise Error, "Branch '#{@branch}' does not exist"
        end
      else
        @branch = default_branch
      end

      # TODO: Validate
      @after = args.fetch(:after, nil)
      @before = args.fetch(:before, nil)

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
      @cache = {}
      @file_extensions = []
      @wopt = args.fetch(:whitespace, false) ? "-w" : ""
      @authors = {}
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
    # TODO: Rename this
    #
    def files
      file_list.count
    end

    #
    # @return Array list of repo files processed
    #
    def file_list
      populate { current_files }
    end

    #
    # @return Fixnum Total number of commits
    #
    def commits
      authors.inject(0) { |result, author| author.raw(:commits) + result }
    end

    #
    # @return Fixnum Total number of lines
    #
    def loc
      authors.inject(0) { |result, author| author.raw(:loc) + result }
    end

    #
    # @return Array<Author> A list of authors
    #
    def authors
      cache(:authors) do
        populate do
          @authors.values.sort_by do |author|
            @sort == "name" ? author.send(@sort) : -1 * author.raw(@sort)
          end
        end
      end
    end

    private

    # Populates @authors and with data
    # Block is called on every call to populate, but
    # the data is only calculated once
    def populate(&block)
      cache(:populate) do
        # Display progressbar with the number of files as countdown
        progressbar = init_progressbar(current_files.count)

        # Extract the blame history from all checked in files
        current_files.each do |file|
          progressbar.inc

          # Skip if mimetype can't be decided
          next unless type = Mimer.identify(File.join(@repository, file.path))
          # Binary types isn't very usefull to run git-blame on
          next if type.binary?

          store_file_extension(file)

          execute("git blame -l #{commit_range} #{@wopt} --no-merges --first-parent -- '#{file}'") do |result|
            result.to_s.scan(/(.+)\s+\((.+)\s+\d{4}-\d{2}-\d{2}/).each do |commit, raw_author|
              # This line is not inside the defined commit boundary
              # Indicated by ^<hash>
              next if commit[0] == "^"
              # Create or find already existing user
              author = fetch(raw_author)

              # Get author by name and increase the number of loc by 1
              author.inc(:loc, 1)

              # Store the files and authors together
              associate_file_with_author(author, file)
            end
          end
        end

        # puts "git shortlog #{commit_range} -se"
        # Get repository summery and update each author accordingly
        execute("git shortlog #{commit_range} --no-merges --first-parent -se") do |result|
          result.to_s.split("\n").map do |line|
            _, commits, raw_author = line.match(%r{^\s*(\d+)\s+(.+?)\s+<.+?>}).to_a
            author = fetch(raw_author)
            # There might be duplicate authors using git shortlog
            # (same name, different emails). Update already existing authors
            if author.raw(:commits).zero?
              update(raw_author, {
                raw_commits: commits.to_i,
                raw_files: files_from_author(author).count,
                files_list: files_from_author(author)
              })
            else
              # Calculate the number of files edited by users
              files = (author.files_list + files_from_author(author)).uniq
              update(raw_author, {
                raw_commits: commits.to_i + author.raw(:commits),
                raw_files: files.count,
                files_list: files
              })
            end
          end
        end

        progressbar.finish
      end

      block.call
    rescue NothingFound
      block.call
    end

    # Uses the more printable names in @visible_fields
    def printable_fields
      cache(:printable_fields) do
        raw_fields.map do |field|
          field.is_a?(Array) ? field.last : field
        end
      end
    end

    def associate_file_with_author(author, file)
      @file_authors[author][file] ||= 1
      if @bytype
        author.file_type_counts[file.extname] += 1
      end
    end

    # TODO: Shouldn't this be unique?
    def store_file_extension(file)
      @file_extensions << file.extname
    end

    # Check to see if a string is empty (nil or "")
    def blank?(value)
      value.nil? or value.empty?
    end

    def files_from_author(author)
      @file_authors[author].keys
    end

    def present?(value)
      not blank?(value)
    end

    # Includes fields from file extensions
    def raw_fields
      return @visible_fields unless @bytype
      cache(:raw_fields) do
        populate do
          (@visible_fields + file_extensions).uniq
        end
      end
    end

    # Method fields used by #to_csv and #pretty_puts
    def fields
      cache(:fields) do
        raw_fields.map do |field|
          field.is_a?(Array) ? field.first : field
        end
      end
    end

    # Command to be executed at @repository
    # @silent = true wont raise an error on exit code =! 0
    def execute(command, silent = false, &block)
      result = Open3.popen2e(command, chdir: @repository) do |_, out, thread|
        Result.new(out.read.scrub.strip, thread.value.success?)
      end

      if result.success? or silent
        return result unless block
        return block.call(result)
      end
      raise Error, cmd_error_message(command, result.data)
    rescue Errno::ENOENT
      raise Error, cmd_error_message(command, $!.message)
    end

    def cmd_error_message(command, message)
      "Could not run '#{command}' => #{message}"
    end

    # Does @branch exist in the current git repo?
    def branch_exists?(branch)
      execute("git show-ref '#{branch}'", true) do |result|
        result.success?
      end
    end

    # In those cases the users havent defined a branch
    # We try to define it for him/her by
    # 1. check if { @default_settings.fetch(:branch) } exists
    # 1. look at .git/HEAD (basically)
    def default_branch
      if branch_exists?(@default_settings.fetch(:branch))
        return @default_settings.fetch(:branch)
      end

      execute("git rev-parse HEAD | head -1") do |result|
        return result.data.split(" ")[0] if result.success?
      end

      raise Error, "No branch found. Define one using --branch=<branch>"
    end

    # Tries to create an author, unless it already exists in cache
    # User is always updated with the passed @args
    def update(author, args)
      fetch(author).tap do |found|
        args.keys.each do |key|
          found.send("#{key}=", args[key])
        end
      end
    end

    # Fetches user from cache
    def fetch(author)
      name = author.strip
      @authors[name] ||= Author.new({ name: name, parent: self })
    end

    # List all files in current git directory, excluding
    # extensions in @extensions defined by the user
    def current_files
      cache(:current_files) do
        execute("git log #{commit_range} --pretty=format: --no-merges --first-parent --name-status | cut -f2- | sort -u") do |result|
          filter_files(result, true)
        end
      end
    rescue NothingFound
      []
    end

    def filter_files(result, filter = false)
      raw_files = result.to_s.split("\n")
      files = remove_excluded_files(raw_files)
      files = keep_included_files(files)
      files = files.map { |file| GitFame::FileUnit.new(file) }
      return files if @extensions.empty?
      files.select { |file| @extensions.include?(file.extname) }
    end

    def commit_range
      cache(:commit_range) do
        return @branch if blank?(@after) and blank?(@before)

        unless blank?(@after)
          commit1 = execute("git rev-list --after='#{@after}' --first-parent '#{@branch}' --reverse --no-merges | head -1").to_s
          if blank?(commit1)
            raise NothingFound, "Could not find commit close to after=#{@after}"
          end
        end

        unless blank?(@before)
          commit2 = execute("git rev-list --before='#{@before}' --first-parent --no-merges '#{@branch}' | head -1").to_s
          if blank?(commit2)
            raise NothingFound, "Could not find commit close to before=#{@before}"
          end
        end

        if @after and @before
          return [commit1, commit2].join("..")
        end

        if @before
          return commit2
        end

        return [commit1, @branch].join("..")
      end
    end

    # The block is only called once for every unique key
    # Used to ensure methods are only called once
    def cache(key, &block)
      @cache[key] ||= block.call
    end

    # Removes files excluded by the user
    # Defined using --exclude
    def remove_excluded_files(files)
      return files if @exclude.empty?
      files.reject do |file|
        @exclude.any? { |exclude| file.match(exclude) }
      end
    end

    def keep_included_files(files)
      return files if @include.empty?
      files.select do |file|
        @include.any? { |exclude| file.match(exclude) }
      end
    end

    def init_progressbar(files_count)
      SilentProgressbar.new("GitBlame", files_count, @progressbar)
    end
  end
end