module GitFame
  class FileUnit < Struct.new(:path, :repository)
  
    def extname
      return @_extname if @_extname
      @_extname = ::File.extname(path).sub(/^\./, "")
      @_extname = @_extname.empty? ? "unknown" : @_extname
    end

    def to_s
      path
    end

    def rep
      repository
    end
  end
end
