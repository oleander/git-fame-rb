require "csv"
require "time"
require "open3"
require "hirb"
require "memoist"
require "timeout"

# String#scrib is build in to Ruby 2.1+
if RUBY_VERSION.to_f < 2.1
  require "scrub_rb"
end

require "git_fame/helper"
require "git_fame/author"
require "git_fame/silent_progressbar"
require "git_fame/blame_parser"
require "git_fame/result"
require "git_fame/file"
require "git_fame/errors"
require "git_fame/commit_range"

module GitFame
  SORT = ["name", "commits", "loc", "files"]
  CMD_TIMEOUT = 10

  class Base
    include GitFame::Helper
    extend Memoist

    #
    # @args[:repository] String Absolute path to git repository
    # @args[:sort] String What should #authors be sorted by?
    # @args[:by_type] Boolean Should counts be grouped by file extension?
    # @args[:exclude] String Comma-separated list of paths in the repo
    #   which should be excluded
    # @args[:branch] String Branch to run from
    # @args[:after] date after
    # @args[:before] date before
    #
    def initialize(args)
      @default_settings = {
        branch: "master",
        sorting: "loc",
        ignore_types: ["image", "binary"]
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
      @repository = File.expand_path(args.fetch(:repository))
      @by_type = args.fetch(:by_type, false)
      @branch = args.fetch(:branch, nil)
      @everything = args.fetch(:everything, false)
      @timeout = args.fetch(:timeout, CMD_TIMEOUT)
      @git_dir = File.join(@repository, ".git")

      # Figure out what branch the caller is using
      if present?(@branch = args[:branch])
        unless branch_exists?(@branch)
          raise Error, "Branch '#{@branch}' does not exist"
        end
      else
        @branch = default_branch
      end

      @after = args.fetch(:after, nil)
      @before = args.fetch(:before, nil)
      [@after, @before].each do |date|
        if date and not valid_date?(date)
          raise Error, "#{date} is not a valid date"
        end
      end

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
      @wopt = args.fetch(:whitespace, false) ? "-w" : ""
      @authors = {}
      @verbose = args.fetch(:verbose, false)
      populate
    end

    #
    # Generates pretty output
    #
    def pretty_puts
      extend Hirb::Console
      Hirb.enable({ pager: false })
      puts "\nStatistics based on #{commit_range.to_s(true)}"
      puts "Active files: #{number_with_delimiter(files)}"
      puts "Active lines: #{number_with_delimiter(loc)}"
      puts "Total commits: #{number_with_delimiter(commits)}\n"
      unless @everything
        puts "\nNote: Files matching MIME type #{ignore_types.join(", ")} has been ignored\n\n"
      end
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
      used_files.count
    end

    #
    # @return Array list of repo files processed
    #
    # TODO: Rename
    def file_list; used_files; end

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
      unique_authors.sort_by do |author|
        @sort == "name" ? author.send(@sort) : -1 * author.raw(@sort)
      end
    end

    protected

    # Populates @authors and with data
    # Block is called on every call to populate, but
    # the data is only calculated once
    def populate
      # Display progressbar with the number of files as countdown
      progressbar = init_progressbar(current_files.count)

      # Extract the blame history from all checked in files
      current_files.each do |file|
        progressbar.increment

        # Skip this file if non wanted type
        next unless check_file?(file)

        # -w ignore whitespaces (defined in @wopt)
        # -M detect moved or copied lines.
        # -p procelain mode (parsed by BlameParser)
        execute("git #{git_directory_params} blame #{encoding_opt} -p -M #{default_params} #{commit_range.to_s} #{@wopt} -- '#{file}'") do |result|
          BlameParser.new(result.to_s).parse.each do |row|
            next if row[:boundary]

            email = get(row, :author, :mail)
            name = get(row, :author, :name)

            # Create or find user
            author = author_by_email(email, name)

            # Get author by name and increase the number of loc by 1
            author.inc(:loc, get(row, :num_lines))

            # Store the files and authors together
            associate_file_with_author(author, file)
          end
        end
      end

      # Get repository summery and update each author accordingly
      execute("git #{git_directory_params} shortlog #{encoding_opt} #{default_params} -se #{commit_range.to_s}") do |result|
        result.to_s.split("\n").map do |line|
          _, commits, name, email = line.match(/(\d+)\s+(.+)\s+<(.+?)>/).to_a
          author = author_by_email(email)

          author.name = name

          author.update({
            raw_commits: commits.to_i,
            raw_files: files_from_author(author).count,
            files_list: files_from_author(author)
          })
        end
      end

      progressbar.finish
    end

    # Ignore mime types found in {ignore_types}
    def check_file?(file)
      return true if @everything
      type = mime_type_for_file(file)
      ! ignore_types.any? { |ignored| type.include?(ignored) }
    end

    # Return mime type for file (form: x/y)
    def mime_type_for_file(file)
      execute("git #{git_directory_params} show #{commit_range.range.last}:'#{file}' | LC_ALL=C file --mime-type -").to_s.
        match(/.+: (.+?)$/).to_a[1]
    end

    def get(hash, *keys)
      keys.inject(hash) { |h, key| h.fetch(key) }
    end

    def ignore_types
      @default_settings.fetch(:ignore_types)
    end

    def unique_authors
      # Merges duplicate users (users with the same name)
      # Object#dup prevents the original to be changed
      @authors.values.dup.each_with_object({}) do |author, result|
        if ex_author = result[author.name]
          result[author.name] = ex_author.dup.merge(author)
        else
          result[author.name] = author
        end
      end.values
    end

    # Uses the more printable names in @visible_fields
    def printable_fields
      raw_fields.map do |field|
        field.is_a?(Array) ? field.last : field
      end
    end

    def associate_file_with_author(author, file)
      if @by_type
        author.file_type_counts[file.extname] += 1
      end
      @file_authors[author][file] ||= 1
    end

    def used_files
      @file_authors.values.map(&:keys).flatten.uniq
    end

    def file_extensions
      used_files.map(&:extname)
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

    def valid_date?(date)
      !! date.match(/\d{4}-\d{2}-\d{2}/)
    end

    # Includes fields from file extensions
    def raw_fields
      return @visible_fields unless @by_type
      (@visible_fields + file_extensions).uniq
    end

    # Method fields used by #to_csv and #pretty_puts
    def fields
      raw_fields.map do |field|
        field.is_a?(Array) ? field.first : field
      end
    end

    # Command to be executed at @repository
    # @silent = true wont raise an error on exit code =! 0
    def execute(command, silent = false, &block)
      result = run_with_timeout(command)
      if result.success? or silent
        warn command if @verbose
        return result unless block
        return block.call(result)
      end
      raise Error, cmd_error_message(command, result.data)
    rescue Errno::ENOENT
      raise Error, cmd_error_message(command, $!.message)
    end

    def run_with_timeout(command)
      if @timeout != -1
        Timeout.timeout(CMD_TIMEOUT) { run_no_timeout(command) }
      else
        run_no_timeout(command)
      end
    end

    def run_no_timeout(command)
      out, err, status = Open3.capture3(command)
      ok = status.success?
      output = ok ? out : err
      Result.new(output.scrub.strip, ok)
    end

    def cmd_error_message(command, message)
      "Could not run '#{command}' => #{message}"
    end

    # Does @branch exist in the current git repo?
    def branch_exists?(branch)
      return true if branch == "HEAD"
      execute("git #{git_directory_params} show-ref '#{branch}'", true) do |result|
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

      execute("git #{git_directory_params} rev-parse HEAD | head -1") do |result|
        return result.data.split(" ")[0] if result.success?
      end
      raise Error, "No branch found. Define one using --branch=<branch>"
    end

    def author_by_email(email, name = nil)
      @authors[(email || "").strip] ||= Author.new({ parent: self, name: name })
    end

    # Lists the paths to contained git submodules
    def current_submodules
      execute("git config --file .gitmodules --get-regexp path | awk '{ print $2 }'") do |result|
        result.to_s.split(/\n/)
      end
    end

    # List all files in current git directory, excluding
    # extensions in @extensions defined by the user
    def current_files
      if commit_range.is_range?
        execute("git #{git_directory_params} -c diff.renames=0 -c diff.renameLimit=1000 diff -M -C -c --name-only --ignore-submodules=all --diff-filter=AM #{encoding_opt} #{default_params} #{commit_range.to_s}") do |result|
          filter_files(result.to_s.split(/\n/))
        end
      else
        submodules = current_submodules
        execute("git #{git_directory_params} ls-tree -r #{commit_range.to_s} --name-only") do |result|
          filter_files(result.to_s.split(/\n/).select { |f| !submodules.index(f) })
        end
      end
    end

    def default_params
      "--date=local"
    end

    def git_directory_params
      "--git-dir='#{@git_dir}' --work-tree='#{@repository}'"
    end

    def encoding_opt
      "--encoding=UTF-8"
    end

    def filter_files(raw_files)
      files = remove_excluded_files(raw_files)
      files = keep_included_files(files)
      files = files.map { |file| GitFame::FileUnit.new(file) }
      return files if @extensions.empty?
      files.select { |file| @extensions.include?(file.extname) }
    end

    def commit_range
      CommitRange.new(current_range, @branch)
    end

    def current_range
      return @branch if blank?(@after) and blank?(@before)

      if present?(@after) and present?(@before)
        if end_date < start_date
          raise Error, "after=#{@after} can't be greater then before=#{@before}"
        end

        if end_date > end_commit_date and start_date > end_commit_date
          raise Error, "after=#{@after} and before=#{@before} is set too high, higest is #{end_commit_date}"
        end

        if end_date < start_commit_date and start_date < start_commit_date
          raise Error, "after=#{@after} and before=#{@before} is set too low, lowest is #{start_commit_date}"
        end
      elsif present?(@after)
        if start_date > end_commit_date
          raise Error, "after=#{@after} is set too high, highest is #{end_commit_date}"
        end
      elsif present?(@before)
        if end_date < start_commit_date
          raise Error, "before=#{@before} is set too low, lowest is #{start_commit_date}"
        end
      end

      if present?(@before)
        if end_date > end_commit_date
          commit2 = @branch
        else
          # Try finding a commit that day
          commit2 = execute("git #{git_directory_params} rev-list --before='#{@before} 23:59:59' --after='#{@before} 00:00:01' #{default_params} '#{@branch}' | head -1").to_s

          # Otherwise, look for the closest commit
          if blank?(commit2)
            commit2 = execute("git #{git_directory_params} rev-list --before='#{@before}' #{default_params} '#{@branch}' | head -1").to_s
          end
        end
      end

      if present?(@after)
        if start_date < start_commit_date
          return present?(commit2) ? commit2 : @branch
        end

        commit1 = execute("git #{git_directory_params} rev-list --before='#{end_of_yesterday(@after)}' #{default_params} '#{@branch}' | head -1").to_s

        # No commit found this early
        # If NO end date is choosen, just use current branch
        # Otherwise use specified (@before) as end date
        if blank?(commit1)
          return @branch unless @before
          return commit2
        end
      end

      if @after and @before
        # Nothing found in date span
        if commit1 == commit2
          raise Error, "There are no commits between #{@before} and #{@after}"
        end
        return [commit1, commit2]
      end

      return commit2 if @before
      [commit1, @branch]
    end

    def end_of_yesterday(time)
      (Time.parse(time) - 86400).strftime("%F 23:59:59")
    end

    def start_commit_date
      Time.parse(execute("git #{git_directory_params} log #{encoding_opt} --pretty=format:'%cd' #{default_params} #{@branch} | tail -1").to_s)
    end

    def end_commit_date
      Time.parse(execute("git #{git_directory_params} log #{encoding_opt} --pretty=format:'%cd' #{default_params} #{@branch} | head -1").to_s)
    end

    def end_date
      Time.parse("#{@before} 23:59:59")
    end

    def start_date
      Time.parse("#{@after} 00:00:01")
    end

    # Removes files excluded by the user
    # Defined using --exclude
    def remove_excluded_files(files)
      return files if @exclude.empty?
      files.reject do |file|
        @exclude.any? { |exclude| File.fnmatch(exclude, file) }
      end
    end

    def keep_included_files(files)
      return files if @include.empty?
      files.select do |file|
        @include.any? { |include| File.fnmatch(include, file) }
      end
    end

    def init_progressbar(files_count)
      SilentProgressbar.new("Git Fame", files_count, (@progressbar and not @verbose))
    end

    # TODO: Are all these needed?
    memoize :populate, :run_with_timeout
    memoize :current_range, :current_files
    memoize :printable_fields, :files_from_author
    memoize :raw_fields, :fields, :file_list
    memoize :end_commit_date, :loc, :commits
    memoize :start_commit_date, :files, :authors
    memoize :file_extensions, :used_files
  end
end
