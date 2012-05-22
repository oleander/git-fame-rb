module GitFame
  class Author
    include GitFame::Helper
    attr_accessor :name, :raw_files, :raw_commits, :raw_loc
    #
    # @args Hash
    #
    def initialize(args = {})
      @raw_loc = 0
      @raw_commits = 0
      @raw_files = 0
      args.keys.each { |name| instance_variable_set "@" + name.to_s, args[name] }
    end

    #
    # @return String Percent of total
    # @format loc / commits / files
    #
    def percent
      "%.1f / %.1f / %.1f" % [:loc, :commits, :files].
        map{ |w| (send("raw_#{w}") / @parent.send(w).to_f) * 100 }
    end

    [:commits, :files, :loc].each do |method|
      define_method(method) do
        number_with_delimiter(send("raw_#{method}"))
      end
    end
  end
end