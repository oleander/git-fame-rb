module GitFame
  class FileUnit < Struct.new(:path)
    def extname
      return @_extname if @_extname
      @_extname = ::File.extname(path).sub(/^\./, "")
      @_extname = @_extname.empty? ? "unknown" : @_extname
    end

    def to_s
      path
    end
  end
end