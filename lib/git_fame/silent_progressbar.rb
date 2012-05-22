class SilentProgressbar < ProgressBar
  #
  # @name String Name for progressbar
  # @steps Fixnum Total number of steps
  # @active Should progressbar be visible?
  #
  def initialize(name, steps, active = false)
    out =  active ? $stdout : File.new("/dev/null", "w")
    super(name, steps, out)
  end
end