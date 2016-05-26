require "ruby-progressbar"

class SilentProgressbar < ProgressBar::Base
  #
  # @name String Name for progressbar
  # @steps Fixnum Total number of steps
  # @active Should progressbar be visible?
  #
  def initialize(name, steps, active = false)
    output =  active ? $stdout : File.new("/dev/null", "w")
    super({
      title: name, 
      total: steps, 
      output: output,
      smoothing: 0.6
    })
  end
end