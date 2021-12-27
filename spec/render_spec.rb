# frozen_string_literal: true

describe GitFame::Render do
  let(:input) { fixture("result.large.json") }
  let(:result) { GitFame::Result.new(input) }
  let(:render) { described_class.new(result: result, branch: "master") }

  it "renders to stdout" do
    expect { render.call }.to output(/Statistics based on .*\n/).to_stdout
  end
end
