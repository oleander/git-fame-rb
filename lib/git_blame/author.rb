module GitBlame
  class Author
    attr_accessor :name, :files
    attr_writer :commits, :loc
    #
    # @args Hash
    #
    def initialize(args = {})
      args.keys.each { |name| instance_variable_set "@" + name.to_s, args[name] }
    end

    #
    # @return Fixnum Number of lines
    #
    def loc
      @loc ||= 0
    end

    #
    # @return Fixnum Number of commits
    #
    def commits
      @commits || 0
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