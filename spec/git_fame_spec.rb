describe GitFame::Base do
  let(:subject) { GitFame::Base.new({ repository: repository }) }
  describe "#authors" do
    it "should have a list of authors" do
      subject.should have(3).authors
    end

    describe "author" do
      let(:author) { subject.authors.last }
      it "should have a bunch of commits" do
        author.raw_commits.should eq(17)
      end

      it "should respond to name" do
        author.name.should eq("Linus Oleander")
      end

      it "should have a number of locs" do
        author.raw_loc.should eq(136)
      end

      it "should have a number of files" do
        author.raw_files.should eq(7)
      end

      it "should have a distribution" do
        author.distribution.should eq("15.2 / 27.4 / 38.9")
      end
    end
    describe "format" do
      let(:author) do
        GitFame::Author.new({
          raw_commits: 12345,
          raw_files: 6789,
          raw_loc: 1234
        })
      end

      it "should format #commits" do
        author.commits.should eq("12,345")
      end

      it "should format #files" do
        author.files.should eq("6,789")
      end

      it "should format #loc" do
        author.loc.should eq("1,234")
      end
    end
  end

  describe "total" do
    it "should respond to #loc, #commits and #files" do
      subject.files.should eq(18)
      subject.commits.should eq(62)
      subject.loc.should eq(897)
    end
  end

  describe "sort" do
    it "should be able to sort #authors by name" do
      authors = GitFame::Base.new({
        repository: repository,
        sort: "name"
      }).authors
      authors.map(&:name).
        should eq(["7rans", "Linus Oleander", "Magnus Holm"])
    end

    it "should be able to sort #authors by commits" do
      authors = GitFame::Base.new({
        repository: repository,
        sort: "commits"
      }).authors
      authors.map(&:name).
        should eq(["Magnus Holm", "Linus Oleander", "7rans"])
    end

    it "should be able to sort #authors by files" do
      authors = GitFame::Base.new({
        repository: repository,
        sort: "files"
      }).authors
      authors.map(&:name).
        should eq(["7rans", "Linus Oleander", "Magnus Holm"])
    end
  end

  describe "#command_line_arguments" do
    let(:subject) do
      GitFame::Base.new({
        repository: repository,
        exclude: "lib",
        bytype: true,
        extensions: "rb,rdoc"
      })
    end

    it "should exclude the lib folder" do
      subject.file_list.include?("lib/gash.rb").should be_falsey
    end

    it "should exclude non rb or rdoc files" do
      subject.file_list.include?("HISTORY").should be_falsey
    end

    let(:author) { subject.authors.find { |author| author.name == "7rans" } }
    it "should break out counts by file type" do
      author.file_type_counts["rdoc"].should eq(23)
    end

    it "should output zero for file types the author hasn't touched" do
      author.file_type_counts["derp"].should eq(0)
    end
  end

  describe "#pretty_print" do
    it "should print" do
      lambda {
        2.times { subject.pretty_puts }
      }.should_not raise_error
    end
  end

  describe "#csv_print" do
    it "should print" do
      lambda {
        subject.csv_puts
      }.should_not raise_error
    end

    it "should be equal to" do
      subject.to_csv.should eq([
        "name,loc,commits,files,distribution\n",
        "Magnus Holm,401,40,4,44.7 / 64.5 / 22.2\n",
        "7rans,360,5,10,40.1 /  8.1 / 55.6\n",
        "Linus Oleander,136,17,7,15.2 / 27.4 / 38.9\n"
      ].join)
    end
  end

  describe "branches" do
    it "should handle existing branches" do
      authors = GitFame::Base.new({
        repository: repository,
        branch: "0.1.0"
      }).authors

      authors.count.should eq(1)
      authors.first.name.should eq("Magnus Holm")
    end

    it "should raise an error if branch doesn't exist" do
      expect {
        GitFame::Base.new({
          repository: repository,
          branch: "-----"
        }).authors
      }.to raise_error(GitFame::Error)
    end

    it "should not raise on empty branch (use fallback)" do
      GitFame::Base.new({
        repository: repository,
        branch: ""
      }).authors.should_not be_empty

      GitFame::Base.new({
        repository: repository,
        branch: nil
      }).authors.should_not be_empty
    end
  end

  describe "after" do
    it "shouldn't find anything if 'after' too far in future" do
      after = GitFame::Base.new({
        repository: repository,
        after: "2100-01-01"
      })

      after.files.should eq(0)
      after.commits.should eq(0)
      after.loc.should eq(0)
    end
  end

  describe "before" do
    it "shouldn't find anything if 'before' is to far back in history" do
      after = GitFame::Base.new({
        repository: repository,
        before: "1972-01-01"
      })

      after.files.should eq(0)
      after.commits.should eq(0)
      after.loc.should eq(0)
    end
  end

  describe "after with content" do
    let (:after) do
      GitFame::Base.new({
        repository: repository,
        after: "2008-09-01",
        before: "2008-09-03"
      })
    end

    describe "summary" do
      it "should ignore all files after before" do
        after.files.should eq(1)
        after.commits.should eq(2)
        after.loc.should eq(12)
      end
    end

    describe "author" do
      it "should have two authors" do
        after.should have(1).authors
      end

      let(:author) { after.authors.sort_by(&:name).first }

      it "should have a bunch of commits" do
        author.raw_commits.should eq(2)
      end

      it "should respond to name" do
        author.name.should eq("Magnus Holm")
      end

      it "should have a number of locs" do
        author.raw_loc.should eq(12)
      end

      it "should have a number of files" do
        author.raw_files.should eq(1)
      end
    end
  end
end