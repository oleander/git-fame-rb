# frozen_string_literal: true

describe GitFame::Command do
  subject(:run) { described_class.call(args) }

  let(:git) { GitRepo.create }
  let(:grace) { { name: "Grace Hopper", email: "grace@example.com" } }

  before do
    git.commit({ "README.md" => "one\ntwo\n", "lib/a.rb" => "x\n" }, time: Time.utc(2015, 1, 1))
    git.commit({ "README.md" => "one\ntwo\nthree\n" }, author: grace, time: Time.utc(2021, 1, 1))
  end

  after { git.remove }

  context "with --after and --before" do
    let(:args) { [git.workdir, "--after", "2010-01-01", "--before", "2020-01-01"] }

    it "prints authors of lines changed in that period" do
      expect { run }.to output(/Ada Lovelace/).to_stdout
    end

    it "leaves out authors of later changes" do
      expect { run }.not_to output(/Grace Hopper/).to_stdout
    end
  end

  context "with -e" do
    let(:args) { [git.workdir, "-e", ".md"] }

    it "counts only files with that extension" do
      expect { run }.to output(/Ada Lovelace *│ *ada@example.com *│ *2 *│/).to_stdout
    end
  end

  context "with an annotated tag as --branch" do
    let(:args) { [git.workdir, "--branch", "v1.0.0"] }

    before do
      git.tag("v1.0.0")
      git.commit({ "CHANGELOG.md" => "later\n" }, author: { name: "Katherine Johnson", email: "kj@example.com" })
    end

    it "uses the commit the tag points to" do
      expect { run }.to output(/Grace Hopper/).to_stdout
    end

    it "leaves out commits made after the tag" do
      expect { run }.not_to output(/Katherine Johnson/).to_stdout
    end
  end

  context "with an unknown --branch" do
    let(:args) { [git.workdir, "--branch", "nope"] }

    it "exits with an error message" do
      expect { run }.to raise_error(SystemExit) { expect(_1.status).to eq(1) }
        .and output(/\AError: unknown revision 'nope'/).to_stderr
    end
  end

  context "when the repository has no commits" do
    let(:empty) { GitRepo.create }
    let(:args) { [empty.workdir] }

    after { empty.remove }

    it "exits with an error message" do
      expect { run }.to raise_error(SystemExit).and output(/\AError: repository at .+ has no commits/).to_stderr
    end
  end

  context "when the path is not in a git repository" do
    let(:args) { [directory] }
    let(:directory) { Dir.mktmpdir("git-fame-spec") }

    after { FileUtils.remove_entry(directory) }

    it "exits with an error message" do
      expect { run }.to raise_error(SystemExit).and output(/\AError: could not find repository/).to_stderr
    end
  end

  describe "--help" do
    let(:args) { ["--help"] }

    it "describes --after and --before" do
      expect { run }.to raise_error(SystemExit).and output(
        /--after \[DATE\] +Only changes made after this date\n.*--before \[DATE\] +Only changes made before this date/
      ).to_stdout
    end
  end
end
