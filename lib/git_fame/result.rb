module GitFame
  class Result < Struct.new(:data, :success?)
    def to_s
      data
    end
  end
end