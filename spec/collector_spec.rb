# frozen_string_literal: true

describe GitFame::Collector do
  let(:name) { "John Doe" }
  let(:email) { "john@example.com" }

  let(:change) do
    {
      file_path: Pathname("."),
      final_signature: {
        time: Time.now,
        email: email,
        name: name
      },
      final_commit_id: "abc",
      lines_in_hunk: 1
    }
  end

  describe "#call" do
    let(:hash) { fixture("collector.large.json") }
    let(:collector) { described_class.new(**hash, diff: diff) }

    let(:repo) { Rugged::Repository.discover(".") }
    let(:commit) { repo.rev_parse("HEAD") }

    let(:diff) { GitFame::Diff.new(commit: commit) }

    context "when not subbed" do
      subject(:result) { collector.call }

      it { is_expected.to be_a(GitFame::Result) }
      its(:lines) { is_expected.to be > 1_000 }
      its("authors.count") { is_expected.to be > 5 }
    end

    context "when block yields once" do
      subject { collector.call }

      before do
        allow(diff).to receive(:each).and_yield(change)
      end

      it { is_expected.to be_a(GitFame::Result) }
      its(:lines) { is_expected.to eq(1) }
      its("contributions.count") { is_expected.to eq(1) }
    end

    context "when block yields twice" do
      subject { collector.call }

      let(:change1) do
        change.deep_merge({
          lines_in_hunk: 10,
          final_signature: {
            email: "john1@example.com"
          }
        })
      end

      let(:change2) do
        change.deep_merge({
          lines_in_hunk: 20,
          final_signature: {
            email: "john2@example.com"
          }
        })
      end

      before do
        allow(diff).to receive(:each).and_yield(change1).and_yield(change2)
      end

      it { is_expected.to be_a(GitFame::Result) }
      its(:lines) { is_expected.to eq(30) }
      its("contributions.count") { is_expected.to eq(2) }
    end
  end
end
