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
    "--by-type",
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
    "--verbose",
    "--everything",
    "--timeout=10"
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
      res.should include_output("'---' is not a valid date")
    end

    it "should fail on invalid after date" do
      res = run("--after='---'")
      res.should_not be_a_succees
      res.should include_output("'---' is not a valid date")
    end

    it "should not print stack trace on invalid dates (--after)" do
      res = run("--after='---'")
      res.should_not be_a_succees
      res.should_not include_output("GitFame::Error")
    end

    it "should fail on invalid timeout" do
      run("--timeout=hello").should_not be_a_succees
      run("--timeout=").should_not be_a_succees
      run("--timeout=-1").should_not be_a_succees
      run("--timeout=0").should_not be_a_succees
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

  context "sort" do
    it "should fail on non existing option" do
      run("--sort=-----").should_not be_a_succees
    end

    results = []
    GitFame::SORT.each do |option|
      it "should be able to sort by #{option}" do
        out = run("--sort=#{option}")
        out.should be_a_succees
        # TODO: Not a impl. problem
        # Just not enough data
        unless option == "name"
          results.push(out.first)
        end
      end
    end

    it "#{GitFame::SORT.join(", ")} should not output the same thing" do
      results.uniq.sort.should eq(results.sort)
    end
  end
end
