describe GitFame::Base do
  let(:subject) { GitFame::Base.new({ repository: repository }) }

  describe "#authors" do
    it "should have a list of authors" do
      subject.should have(4).authors
    end

    describe "author" do
      let(:author) do
        subject.authors.find do |author|
          author.name.include?("Magnus Holm")
        end
      end

      it "should have a bunch of commits" do
        author.raw(:commits).should eq(40)
      end

      it "should respond to name" do
        author.name.should eq("Magnus Holm")
      end

      it "should have a number of locs" do
        author.raw(:loc).should eq(581)
      end

      it "should have a number of files" do
        author.raw(:files).should eq(4)
      end

      it "should have a distribution" do
        author.distribution.should eq("54.0 / 64.5 / 25.0")
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
      subject.files.should eq(16)
      subject.commits.should eq(62)
      subject.loc.should eq(1075)
    end
  end

  describe "sort" do
    it "should be able to sort #authors by name" do
      authors = GitFame::Base.new({
        repository: repository,
        sort: "name"
      }).authors
      authors.map(&:name).sort.
        should eq(["7rans", "Linus Oleander", "Linus Oleander", "Magnus Holm"].sort)
    end

    it "should be able to sort #authors by commits" do
      authors = GitFame::Base.new({
        repository: repository,
        sort: "commits"
      }).authors
      authors.map(&:name).sort.
        should eq(["Magnus Holm", "Linus Oleander", "Linus Oleander", "7rans"].sort)
    end

    it "should be able to sort #authors by files" do
      authors = GitFame::Base.new({
        repository: repository,
        sort: "files"
      }).authors
      authors.map(&:name).sort.
        should eq(["7rans", "Linus Oleander", "Linus Oleander", "Magnus Holm"].sort)
    end
  end

  describe "types" do
    let(:subject) do
      GitFame::Base.new({
        repository: repository,
        exclude: "lib",
        by_type: true,
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
      author.file_type_counts["rdoc"].should eq(1)
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
        "Magnus Holm,581,40,4,54.0 / 64.5 / 25.0\n",
        "7rans,358,5,10,33.3 /  8.1 / 62.5\n",
        "Linus Oleander,135,16,6,12.6 / 25.8 / 37.5\n",
        "Linus Oleander,1,1,1, 0.1 /  1.6 /  6.2\n"
      ].join)
    end
  end

  describe "branches", :this do
    it "should handle existing branches" do
      GitFame::Base.new({
        repository: repository,
        branch: "master"
      }).authors
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

  describe "after", :this do
    it "should raise error if 'after' is to far in the future" do
      lambda do
        GitFame::Base.new({
          repository: repository,
          after: "2020-01-01"
        }).commits
      end.should raise_error(GitFame::Error)
    end

    it "should handle same day as HEAD" do
      GitFame::Base.new({
        repository: repository,
        after: "2012-05-23"
      }).commits.should eq(1)
    end

    it "should handle an out of scope 'after' date" do
      GitFame::Base.new({
        repository: repository,
        after: "2000-01-01"
      }).commits.should eq(62)
    end
  end

  describe "before", :this do
    it "should raise error if 'before' is to far back in history" do
      lambda do
        GitFame::Base.new({
          repository: repository,
          before: "1972-01-01"
        }).commits
      end.should raise_error(GitFame::Error)
    end

    it "should handle same day as last commit" do
      GitFame::Base.new({
        repository: repository,
        before: "2008-08-31"
      }).commits.should eq(1)
    end

    it "should handle an out of scope 'before' date" do
      GitFame::Base.new({
        repository: repository,
        before: "2050-01-01"
      }).commits.should eq(62)
    end

    it "should handle same day as last commit" do
      GitFame::Base.new({
        repository: repository,
        before: "2008-08-31"
      }).commits.should eq(1)
    end

    it "should validate before date" do
      lambda do
        GitFame::Base.new({
          repository: repository,
          before: "----"
        })
      end.should raise_error(GitFame::Error)
    end

    it "should validate before date" do
      lambda do
        GitFame::Base.new({
          repository: repository,
          after: "----"
        })
      end.should raise_error(GitFame::Error)
    end
  end

  describe "span", :this do
    it "should handle spans as inclusive" do
      GitFame::Base.new({
        repository: repository,
        after: "2008-09-01",
        before: "2008-09-03"
      }).commits.should eq(4)
    end

    it "should should possible a wide date span (include all)" do
      GitFame::Base.new({
        repository: repository,
        after: "2000-01-01",
        before: "2020-01-01"
      }).commits.should eq(62)
    end

    it "should handle a too early 'after'" do
      GitFame::Base.new({
        repository: repository,
        after: "2000-01-01",
        before: "2008-08-31"
      }).commits.should eq(1)
    end

    it "should catch empty commit span" do
      lambda do
        GitFame::Base.new({
          repository: repository,
          after: "2010-04-10",
          before: "2010-04-11"
        }).commits
      end.should raise_error(GitFame::Error)
    end

    it "should handle a too late 'before'" do
      GitFame::Base.new({
        repository: repository,
        after: "2012-02-29",
        before: "2030-01-01"
      }).commits.should eq(4)
    end

    it "should handle the after date same date as init commit" do
      GitFame::Base.new({
        repository: repository,
        after: "2008-08-31",
        before: "2008-09-03"
      }).commits.should eq(5)
    end

    it "should handle an existing before with an old after" do
      GitFame::Base.new({
        repository: repository,
        after: "2000-08-31",
        before: "2008-09-03"
      }).commits.should eq(5)
    end

    it "should handle an existing after with an old before" do
      GitFame::Base.new({
        repository: repository,
        after: "2012-05-23",
        before: "2020-01-01"
      }).commits.should eq(1)
    end

    it "should raise an error if after > before" do
      lambda do
        GitFame::Base.new({
          repository: repository,
          after: "2020-01-01",
          before: "2000-01-01"
        }).commits
      end.should raise_error(GitFame::Error)
    end

    it "should raise error if set too high" do
      lambda do
        GitFame::Base.new({
          repository: repository,
          after: "2030-01-01",
          before: "2050-01-01"
        }).commits
      end.should raise_error(GitFame::Error)
    end

    it "should raise error if set too low" do
      lambda do
        GitFame::Base.new({
          repository: repository,
          after: "1990-01-01",
          before: "2000-01-01"
        }).commits
      end.should raise_error(GitFame::Error)
    end

    it "should handle same day" do
      GitFame::Base.new({
        repository: repository,
        after: "2012-02-29",
        before: "2012-02-29"
      }).commits.should eq(3)
    end

    it "should handle same day (HEAD)" do
      GitFame::Base.new({
        repository: repository,
        after: "2012-05-23",
        before: "2012-05-23"
      }).commits.should eq(1)
    end

    it "should handle same day (last commit)" do
      GitFame::Base.new({
        repository: repository,
        after: "2008-08-31",
        before: "2008-08-31"
      }).commits.should eq(1)
    end

    it "should handle a non existent 'after' date" do
      GitFame::Base.new({
        repository: repository,
        after: "2008-09-02",
        before: "2008-09-04"
      }).commits.should eq(4)
    end

    it "should handle a non existent 'before' date" do
      GitFame::Base.new({
        repository: repository,
        after: "2008-09-04",
        before: "2008-09-05"
      }).commits.should eq(3)
    end

    it "should handle both non existent 'before' and 'after'" do
      GitFame::Base.new({
        repository: repository,
        after: "2008-09-02",
        before: "2008-09-05"
      }).commits.should eq(4)
    end
  end
end