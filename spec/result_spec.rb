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
  end
end
