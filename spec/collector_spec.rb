# frozen_string_literal: true

describe GitFame::Collector do
  describe "#call" do
    subject(:result) { collector.call }

    let(:collector) { build(:collector) }

    its("lines") { is_expected.to eq(result.contributions.sum(&:lines)) }
    its("authors") { is_expected.to be_present }
    its("commits") { is_expected.to be_present }
    its("files") { is_expected.to be_present }
  end
end
