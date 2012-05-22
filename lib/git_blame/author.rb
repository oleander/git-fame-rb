module GitBlame
  class Author
    attr_accessor :name, :files
    attr_accessor :commits, :loc
    #
    # @args Hash
    #
    def initialize(args = {})
      @loc = 0
      @commits = 0
      @files = 0
      args.keys.each { |name| instance_variable_set "@" + name.to_s, args[name] }
    end

    #
    # @return String Percent of total
    # @format loc / commits / files
    #
    def percent
      "%.1f / %.1f / %.1f" % [:loc, :commits, :files].
        map{ |w| (send(w) / @parent.send(w).to_f) * 100 }
    end
  end
end