describe GitBlame::Base do
  let(:subject) { GitBlame::Base.new({repository: @repository}) }
  describe "#authors" do
    it "should have a list of authors" do
      should have(3).authors
    end

    describe "author" do
      let(:author) { subject.authors[1] }
      it "should have a bunch of commits" do
        author.commits.should eq(21)
      end

      it "should respond to name" do
        author.name.should eq("Linus Oleander")
      end

      it "should have a number of locs" do
        author.loc.should eq(136)
      end

      it "should have a number of files" do
        author.files.should eq(6)
      end

      it "should have some percentage" do
        author.percent.should eq("12.6 / 30.9 / 40.0")
      end
    end
  end

  describe "total" do
    it "should respond to #loc, #commits and #files" do
      subject.files.should eq(15)
      subject.commits.should eq(68)
      subject.loc.should eq(1082)
    end
  end

  describe "sort" do
    it "should be able to sort #authors by name" do
      authors = GitBlame::Base.new({repository: @repository, sort: "name"}).authors
      authors.map(&:name).should eq(["7rans", "Linus Oleander", "Magnus Holm"])
    end

    it "should be able to sort #authors by commits" do
      authors = GitBlame::Base.new({repository: @repository, sort: "commits"}).authors
      authors.map(&:name).should eq(["Magnus Holm", "Linus Oleander", "7rans"])
    end

    it "should be able to sort #authors by files" do
      authors = GitBlame::Base.new({repository: @repository, sort: "files"}).authors
      authors.map(&:name).should eq(["7rans", "Linus Oleander", "Magnus Holm"])
    end
  end
end