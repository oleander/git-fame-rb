require "progressbar"

class SilentProgressbar
  #
  # @name String Name for progressbar
  # @steps Fixnum Total number of steps
  # @active Should progressbar be visible?
  #
  def initialize(name, steps, active = false)
    @bp = ProgressBar.new(name, steps) if active
  end
  
  def finish
    @bp && @bp.finish
  end
  
  def increment
    @bp && @bp.inc
  end
end