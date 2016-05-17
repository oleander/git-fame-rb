module GitFame
  class Result < Struct.new(:data, :success)
    def to_s; data; end
    def success?; success; end
  end
end