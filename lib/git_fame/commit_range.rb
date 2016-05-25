class CommitRange < Struct.new(:data)
  def to_s
    @_to_s ||= is_range? ? data.join("..") : data
  end

  def is_range?
    data.is_a?(Array)
  end
end