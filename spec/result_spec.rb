# frozen_string_literal: true

describe GitFame::Result do
  subject { build(:result) }

  its(:contributions) { is_expected.to be_present }

  describe "#authors" do
    its(:authors) { is_expected.to be_present }
  end

  describe "#commits" do
    its(:commits) { is_expected.to be_present }
  end

  describe "#lines" do
    its(:lines) { is_expected.to be > 0 }
  end

  describe "#files" do
    its(:files) { is_expected.to be_present }

    context "when several authors contributed to the same file" do
      subject(:result) do
        build(:result, contributions: [
          build(:contribution, files: ["README.md", "lib/a.rb"]),
          build(:contribution, files: ["README.md"])
        ])
      end

      it "lists each file once" do
        expect(result.files).to contain_exactly("README.md", "lib/a.rb")
      end
    end
  end
end
