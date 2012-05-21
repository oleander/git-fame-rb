describe GitBlame::Base do
  let(:subject) { GitBlame::Base.new({repository: @repository}) }
  describe "#authors" do
    it "should have a list of authors" do
      should have(3).authors
    end

    describe "author" do
      let(:author) { subject.authors.first }
      it "should respond to commits" do
        author.commits.should > 0
      end

      it "should respond to name" do
        author.name.length.should > 0
      end

      it "should have a number of locs" do
        author.loc.should > 0
      end
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