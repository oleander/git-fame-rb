describe "bin/git-fame" do
  it "should include the authors name" do
    run("--help").should include_output("Linus Oleander")
  end

  it "should include the the current version" do
    run("--version").should include_output(GitFame::VERSION)
  end

  it "should fail on invalid option" do
    run("--nope").should_not be_a_succees
  end

  it "should not accept a non-existent repository" do
    run("--repository=??").should_not be_a_succees
  end

  [
    "--sort=name",
    "--sort=commits",
    "--sort=loc",
    "--hide-progressbar",
    "--whitespace",
    "--bytype",
    "--include=hello",
    "--exclude=hello",
    "--extension=rb,ln",
    "--branch=master",
    "--format=csv",
    "--format=pretty",
    "--before=2010-01-01",
    "--after=1980-01-01",
    "--version",
    "--help",
    "--verbose"
  ].each do |option|
    it "should support #{option}" do
      run(option).should be_a_succees
    end
  end

  it "should sort by loc by default" do
    run("--sort=loc", "--progressbar=0").first.should eq(run("--progressbar=0").first)
  end

  context "dates" do
    it "should fail on invalid before date" do
      res = run("--before='---'")
      res.should_not be_a_succees
      res.first.should eq("Error: '---' is not a valid date\n")
    end

    it "should fail on invalid after date" do
      res = run("--after='---'")
      res.should_not be_a_succees
      res.should include_output("Error: '---' is not a valid date\n")
    end

    it "should not print stack trace on invalid dates (--after)" do
      res = run("--after='---'")
      res.should_not be_a_succees
      res.should_not include_output("GitFame::Error")
    end

    it "should not print stack trace on invalid dates (--before)" do
      res = run("--before='---'")
      res.should_not be_a_succees
      res.should_not include_output("GitFame::Error")
    end

    it "should not print stack trace on out of span (--before)" do
      res = run("--before='1910-01-01'")
      res.should_not be_a_succees
      res.should_not include_output("GitFame::Error")
    end

    it "should not print stack trace on out of span (--after)" do
      res = run("--after='2100-01-01'")
      res.should_not be_a_succees
      res.should_not include_output("GitFame::Error")
    end
  end
end
