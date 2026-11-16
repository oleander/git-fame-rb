# frozen_string_literal: true

describe GitFame::Command do
  let(:args) { ["--after", "2010-01-01", "--before", "2020-01-01", "--branch", "HEAD"] }

  it "outputs to stdout" do
    expect { described_class.call(args) }.to output(/email|name/).to_stdout
  end

  describe "#terminal_width" do
    subject(:width) { described_class.new.send(:terminal_width) }

    before { allow(TTY::Screen).to receive(:width).and_return(72) }

    it "is the screen width when stdout is a terminal" do
      allow($stdout).to receive(:tty?).and_return(true)

      expect(width).to eq(72)
    end

    it "is nil, so the table keeps its natural width, when stdout is not a terminal" do
      allow($stdout).to receive(:tty?).and_return(false)

      expect(width).to be_nil
    end
  end
end
