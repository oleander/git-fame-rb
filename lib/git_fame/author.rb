module GitFame
  class Author
    include GitFame::Helper
    attr_accessor :name, :raw_files, :raw_commits,
      :raw_loc, :files_list, :file_type_counts

    FIELDS = [:loc, :commits, :files]

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
      "%s / %s / %s" % FIELDS.map do |field|
        ("%.1f" % (percent_for_field(field) * 100)).rjust(4, " ")
      end
    end
    alias_method :"distribution (%)", :distribution

    FIELDS.each do |method|
      define_method(method) do
        number_with_delimiter(raw(method))
      end
    end

    def update(params)
      params.keys.each do |key|
        send("#{key}=", params[key])
      end
    end

    #
    # Intended to catch file type counts
    #
    def method_missing(m, *args, &block)
      file_type_counts[m.to_s]
    end

    def raw(method)
      unless FIELDS.include?(method.to_sym)
        raise "can't access raw '#{method}' on author"
      end

      send("raw_#{method}")
    end

    def inc(method, amount)
      send("raw_#{method}=", raw(method) + amount)
    end

    private

    def percent_for_field(field)
      raw(field) / @parent.send(field).to_f
    end
  end
end
