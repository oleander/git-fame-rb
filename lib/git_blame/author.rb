module GitBlame
  class Author
    include ActionView::Helpers::NumberHelper
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

    [:f_commits, :f_files, :f_loc].each do |method|
      define_method(method) do
        number_with_delimiter(send(method.to_s.gsub(/^f_/, "")))
      end
    end
  end
end