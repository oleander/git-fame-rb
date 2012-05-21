describe GitBlame::Base do
  describe "#authors" do
    let(:subject) { GitBlame::Base.new({repository: @repository}) }

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
end