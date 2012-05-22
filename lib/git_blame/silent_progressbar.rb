class SilentProgressbar < ProgressBar
  def initialize(name, steps, active = false)
    if active
      out = $stdout
    else
      out = File.new("/dev/null", "w")
    end

    super(name, steps, out)
  end
end