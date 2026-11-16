# frozen_string_literal: true

require "unicode/display_width"

describe GitFame::Render do
  let(:render) { build(:render) }

  it "renders to stdout" do
    expect { render.call }.to output(/name|email|lines|commits|files/).to_stdout
  end

  describe "#call" do
    subject(:lines) { stdout.lines.map(&:chomp) }

    let(:stdout) do
      capture = StringIO.new
      original = $stdout
      $stdout = capture
      render.call
      capture.string
    ensure
      $stdout = original
    end

    let(:result) { build(:result, contributions:) }
    let(:contributions) do
      [
        build(:contribution, lines: 1_234, author: { name: "Margaret Hamilton", email: "margaret.hamilton@apollo.example.com" }),
        build(:contribution, lines: 56, author: { name: "조성빈", email: "seongbin@example.com" }),
        build(:contribution, lines: 7, author: { name: "René Descartes", email: "rene@example.com" })
      ]
    end

    context "without a terminal width" do
      let(:render) { build(:render, result:) }

      it "prints every name and email in full" do
        expect(stdout).to include("Margaret Hamilton", "margaret.hamilton@apollo.example.com", "조성빈", "René Descartes")
      end

      it "prints all six column headers" do
        expect(lines[1].split("│").map(&:strip).reject(&:empty?)).to eq(described_class::FIELDS)
      end

      it "aligns every line, including names with wide characters" do
        expect(lines.map { Unicode::DisplayWidth.of(_1) }.uniq.size).to eq(1)
      end
    end

    context "with a terminal narrower than the table" do
      let(:render) { build(:render, result:, width: 70) }

      it "fits every line within the terminal width" do
        expect(lines.map { Unicode::DisplayWidth.of(_1) }).to all(be <= 70)
      end

      it "keeps the number columns intact" do
        expect(stdout).to include("1 234", "lines", "commits", "files")
      end

      it "truncates the email column" do
        expect(stdout).not_to include("margaret.hamilton@apollo.example.com")
      end
    end

    context "with a terminal too narrow for the number columns" do
      let(:render) { build(:render, result:, width: 20) }

      it "keeps the number columns intact" do
        expect(stdout).to include("1 234", "lines", "commits", "files")
      end

      it "shortens names and emails to the minimum width" do
        name, email = lines[3].split("│")[1, 2]

        expect([name, email]).to all(include("…"))
        expect([name, email].map { Unicode::DisplayWidth.of(_1) }).to eq([8, 8])
      end
    end

    context "when a name contains a tab" do
      let(:render) { build(:render, result: build(:result, contributions: [build(:contribution, author: { name: "Ada\tLovelace", email: "ada@example.com" })])) }

      it "prints the escaped name in full" do
        expect(stdout).to include("Ada\\tLovelace")
      end
    end

    context "when a name is not valid UTF-8" do
      let(:name) { (+"Ren\xE9 Descartes").force_encoding(Encoding::UTF_8) }
      let(:render) { build(:render, result: build(:result, contributions: [build(:contribution, author: { name:, email: "rene@example.com" })])) }

      it "prints the name with a replacement character" do
        expect(stdout).to include("Ren\uFFFD Descartes")
      end
    end

    context "with a terminal wider than the table" do
      let(:render) { build(:render, result:, width: 500) }

      it "prints the table at its natural width" do
        expect(lines.map { Unicode::DisplayWidth.of(_1) }).to all(be < 500)
      end
    end
  end
end
