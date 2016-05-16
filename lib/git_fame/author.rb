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
      "%.1f / %.1f / %.1f" % [:loc, :commits, :files].
        map{ |w| (send("raw_#{w}") / @parent.send(w).to_f) * 100 }
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
  end
end
