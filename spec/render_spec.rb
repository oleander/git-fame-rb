# frozen_string_literal: true

describe GitFame::Render do
  let(:render) { build(:render) }

  it "renders to stdout" do
    expect { render.call }.to output(/name|email|lines|commits|files/).to_stdout
  end
end
