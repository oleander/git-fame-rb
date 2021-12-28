# frozen_string_literal: true

describe GitFame::Command do
  let(:args) { ["--after", "2010-01-01", "--before", "2020-01-01", "--branch", "master"] }

  it "ouputs to stdout" do
    expect { described_class.call(args) }.to output(/email|name/).to_stdout
  end
end
