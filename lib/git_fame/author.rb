module GitFame
  class Author
    include GitFame::Helper
    attr_accessor :name, :raw_files, :raw_commits,
      :raw_loc, :files_list, :file_type_counts

    #
    # @args Hash
    #
    def initialize(args = {})
      @raw_loc          = 0
      @raw_commits      = 0
      @raw_files        = 0
      @file_type_counts = Hash.new(0)
      args.keys.each do |name|
        instance_variable_set "@" + name.to_s, args[name]
      end
    end

    #
    # @format loc / commits / files
    # @return String Distribution (in %) between users
    #
    def distribution
      "%s / %s / %s" % [:loc, :commits, :files].map do |field|
        ("%.1f" % (percent_for_field(field) * 100)).rjust(4, " ")
      end
    end
    alias_method :"distribution (%)", :distribution

    [:commits, :files, :loc].each do |method|
      define_method(method) do
        number_with_delimiter(send("raw_#{method}"))
      end
    end

    #
    # Intended to catch file type counts
    #
    def method_missing(m, *args, &block)
      file_type_counts[m.to_s]
    end

    private

    def percent_for_field(field)
      send("raw_#{field}") / @parent.send(field).to_f
    end
  end
end
