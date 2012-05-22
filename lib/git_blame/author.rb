module GitBlame
  class Author
    include ActionView::Helpers::NumberHelper
    attr_accessor :name, :f_files, :f_commits, :f_loc
    #
    # @args Hash
    #
    def initialize(args = {})
      @f_loc = 0
      @f_commits = 0
      @f_files = 0
      args.keys.each { |name| instance_variable_set "@" + name.to_s, args[name] }
    end

    #
    # @return String Percent of total
    # @format loc / commits / files
    #
    def percent
      "%.1f / %.1f / %.1f" % [:loc, :commits, :files].
        map{ |w| (send("f_#{w}") / @parent.send(w).to_f) * 100 }
    end

    [:commits, :files, :loc].each do |method|
      define_method(method) do
        number_with_delimiter(send("f_#{method}"))
      end
    end
  end
end