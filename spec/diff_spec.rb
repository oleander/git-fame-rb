# frozen_string_literal: true

describe GitFame::Diff do
  subject(:paths) { diff.map { _1[:path] } }

  let(:git) { GitRepo.create }
  let(:diff) { described_class.new(commit: git.repo.head.target) }

  after { git.remove }

  context "when a file was renamed" do
    before do
      git.commit({ "src/old.js" => "a\nb\n" })
      git.commit({ "src/old.js" => nil, "src/new.ts" => "a\nb\n" }, message: "Rename")
    end

    it "yields the current path, not the path before the rename" do
      expect(paths).to all(eq("src/new.ts"))
    end
  end

  context "when the commit contains a binary file" do
    before { git.commit({ "image.png" => "\x89PNG\r\n\x1A\n\x00\x00\n", "README.md" => "hello\n" }) }

    it "skips the binary file" do
      expect(paths).to eq(["README.md"])
    end
  end

  context "when the path contains non-ASCII characters" do
    before { git.commit({ "项目记录.txt" => "中文\n" }) }

    it "yields a UTF-8 path" do
      expect(paths.map(&:encoding)).to eq([Encoding::UTF_8])
    end
  end

  context "without a block" do
    before { git.commit({ "README.md" => "hello\n" }) }

    it "returns an enumerator" do
      expect(diff.each).to be_an(Enumerator)
    end
  end

  context "with a filter" do
    let(:diff) { described_class.new(commit: git.repo.head.target, path_filter: build(:filter, extensions: Set[".rb"])) }

    before { git.commit({ "a.rb" => "x\n", "b.md" => "y\n" }) }

    it "blames only the files the filter accepts" do
      allow(Rugged::Blame).to receive(:new).and_call_original

      expect(paths).to eq(["a.rb"])
      expect(Rugged::Blame).to have_received(:new).once
    end
  end
end
