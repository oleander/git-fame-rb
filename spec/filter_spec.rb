# frozen_string_literal: true

describe GitFame::Filter do
  describe "#call" do
    let(:changes) do
      {
        file_path: Pathname("."),
        final_signature: {
          time: Time.now,
          email: "hello@example.com",
          name: "John Doe"
        },
        final_commit_id: "abc",
        lines_in_hunk: 1
      }
    end

    context "when the filter contains all rules" do
      subject(:filter) do
        described_class.new({
          include: Set["test*{.rb, .js, .ts}"],
          extensions: Set[".rb", ".js"],
          exclude: Set["*_spec.rb"],
          before: before,
          after: after
        })
      end

      let(:now) { DateTime.now }
      let(:changes) { super().deep_merge(file_path: file_path, final_signature: { time: time }) }
      let(:file_path) { Pathname("test.rb") }
      let(:time) { Time.now }
      let(:before) { now + 1_000 }
      let(:after) { now - 1_000 }

      context "when change is valid" do
        it "invokes the block" do
          expect { |b| filter.call(changes, &b) }.to yield_control
        end
      end

      context "when the [exclude] filter fails" do
        let(:file_path) { Pathname("test_spec.rb") }
        let(:changes) { super().deep_merge(file_path: file_path) }

        it "does not invoke the block" do
          expect { |b| filter.call(changes, &b) }.not_to yield_control
        end
      end
    end

    context "when the before filter is set to today" do
      subject(:filter) { described_class.new(before: before) }

      let(:changes) { super().deep_merge(final_signature: { time: time }) }
      let(:before) { DateTime.now }

      context "when the change is set BEFORE the [before] filter" do
        let(:time) { before - 1.day }

        it "invokes the block" do
          expect { |b| filter.call(changes, &b) }.to yield_control
        end
      end

      context "when the change is set AFTER the [before] filter" do
        let(:time) { before + 1.day }

        it "does not invoke the block" do
          expect { |b| filter.call(changes, &b) }.not_to yield_control
        end
      end
    end

    context "when the [exclude] filter is set to ignore [LI*ENCE]" do
      subject(:filter) { described_class.new(exclude: exclude) }

      let(:changes) { super().deep_merge(file_path: file_path) }
      let(:exclude) { Set["LI*ENCE"] }

      context "when the change does NOT match the glob pattern" do
        let(:file_path) { Pathname("README") }

        it "does invoke the block" do
          expect { |b| filter.call(changes, &b) }.to yield_control
        end
      end

      context "when the change does match the glob pattern" do
        let(:file_path) { Pathname("LICENCE") }

        it "does not invoke the block" do
          expect { |b| filter.call(changes, &b) }.not_to yield_control
        end
      end
    end

    context "when the [include] filter is set to include [*_spec.rb]" do
      subject(:filter) { described_class.new(include: include) }

      let(:changes) { super().deep_merge(file_path: file_path) }
      let(:include) { Set["*_spec.rb"] }

      context "when the change does NOT match the glob pattern" do
        let(:file_path) { Pathname("main.rb") }

        it "does not invoke the block" do
          expect { |b| filter.call(changes, &b) }.not_to yield_control
        end
      end

      context "when the change does match the glob pattern" do
        let(:file_path) { Pathname("main_spec.rb") }

        it "does invoke the block" do
          expect { |b| filter.call(changes, &b) }.to yield_control
        end
      end
    end

    context "when the [extensions] filter is set to ignore [.rb]" do
      subject(:filter) { described_class.new(extensions: extensions) }

      let(:changes) { super().deep_merge(file_path: file_path) }
      let(:extensions) { Set[".rb"] }

      context "when the change does NOT have an .rb extension" do
        let(:file_path) { Pathname("foo.js") }

        it "does not invoke the block" do
          expect { |b| filter.call(changes, &b) }.not_to yield_control
        end
      end

      context "when the change does have an .rb extension" do
        let(:file_path) { Pathname("foo.rb") }

        it "invokes the block" do
          expect { |b| filter.call(changes, &b) }.to yield_control
        end
      end
    end

    context "when the after filter is set to today" do
      subject(:filter) { described_class.new(after: after) }

      let(:changes) { super().deep_merge(final_signature: { time: time }) }
      let(:after) { DateTime.now }

      context "when the change is set BEFORE the after filter" do
        let(:time) { after - 1.day }

        it "does not invoke the block" do
          expect { |b| filter.call(changes, &b) }.not_to yield_control
        end
      end

      context "when the change is set AFTER the after filter" do
        let(:time) { after + 1.day }

        it "invokes the block" do
          expect { |b| filter.call(changes, &b) }.to yield_control
        end
      end
    end
  end
end
