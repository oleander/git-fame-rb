class CommitRange < Struct.new(:data, :current_branch)
  SHORT_LENGTH = 7

  def to_s(short = false)
    @_to_s ||= range.map do |commit|
      short ? shorten(commit) : commit
    end.join("..")
  end

  def is_range?
    data.is_a?(Array)
  end

  def range
    is_range? ? data : [data]
  end
  
  private

  def branch?(commit)
    current_branch == commit
  end

  def shorten(commit)
    branch?(commit) ? commit : commit[0..SHORT_LENGTH]
  end
end