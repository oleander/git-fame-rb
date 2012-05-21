describe GitBlame::Base do
  let(:subject) { GitBlame::Base.new({repository: @repository}) }
  describe "#authors" do
    it "should have a list of authors" do
      should have(3).authors
    end

    it "should respond to commits" do
      subject.authors.first.commits.should > 0
    end

    it "should respond to name" do
      subject.authors.first.name.length.should > 0
    end
  end

  describe "total" do
    it "should respond to #loc, #commits and #files" do
      subject.files.should eq(15)
      subject.commits.should eq(69)
      subject.loc.should eq(1081)
    end
  end
end