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
    end

    #
    # @return Fixnum Total number of lines
    #
    def loc

    end

    #
    # @return Fixnum Total number of commits
    #
    def commits
      
    end

    #
    # @return Fixnum Total number of files
    #
    def files
      
    end

    #
    # @return Array<Author> A list of authors
    #
    def authors
      execute("git shortlog -se").split("\n").map do |l| 
        _, commits, u = l.match(%r{^\s*(\d+)\s+(.+?)\s+<.+?>}).to_a
        update(u, {commits: commits.to_i})
      end

      return @authors.values
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
      @authors[author] ||= Author.new(name: author)
      args.keys.each do |key|
         @authors[author].send("#{key}=", args[key])
      end

      return @authors[author]
    end
  end

  class Author
    attr_accessor :commits, :name
    #
    # @args Hash
    #
    def initialize(args = {})
      args.keys.each { |name| instance_variable_set "@" + name.to_s, args[name] }
    end
  end
end

# base = "/Users/linus/Documents/Projekt/water/mainline"
# authors = Hash.new { |h,k| h[k] = 0 }
# authors2 = Hash.new { |h,k| h[k] = 0 }
# authors3 = Hash.new { |h,k| h[k] = {} }
# Author = Struct.new(:name, :loc, :commits, :files, :percent)

# files = nil

# Dir.chdir(base) do
#   `git shortlog -se`.split("\n").map do |l| 
#     _, loc, u = l.match(%r{^\s*(\d+)\s+(.+?)\s+<.+?>}).to_a
#     authors2[u] += loc.to_i
#   end

#   files = `git ls-files`.split("\n")
#   bar = ProgressBar.new("Blame", files.length)
#   files.each do |file|
#     bar.inc
#     if type = Mimer.identify(File.join(base, file)) and not type.mime_type.match(/binary/)
#       begin
#         `git blame '#{file}'`.scan(/\((.+?)\s+\d{4}-\d{2}-\d{2}/).each do |author|
#           authors[author.first] += 1
#           authors3[author.first][file] ||= 1
#         end
#       rescue ArgumentError; end # Encoding error
#     end
#   end

#   bar.finish
# end

# total_loc = authors.values.inject(:+)
# total_commits = authors2.values.inject(:+)
# total_files = files.count
# puts "Total number of files: #{number_with_delimiter(total_files)}"
# puts "Total number of lines: #{number_with_delimiter(total_loc)}"
# puts "Total number of commits: #{number_with_delimiter(total_commits)}"
# format_authors = authors.sort_by{ |a| a.last }.reverse.map do |a| 
#   name = a.first
#   files = authors3[name].keys.count
#   commits = authors2[a.first]
#   loc_percent = ((a.last.to_f / total_loc) * 100).round(1)
#   commits_percent = ((commits.to_f / total_commits) * 100).round(1)
#   files_percent = ((files.to_f / total_files) * 100).round(1)

#   Author.new(
#     name, 
#     number_with_delimiter(a.last), 
#     number_with_delimiter(commits),
#     number_with_delimiter(files),
#     "#{loc_percent} / #{commits_percent} / #{files_percent}"
#   )
# end
# table(format_authors, fields: [:name, :loc, :commits, :files, :percent])
# $-v = output