# frozen_string_literal: true

# Loaded by `require "simplecov"` in spec/spec_helper.rb.
# Run `COVERAGE=1 bundle exec rspec` to write an HTML report to coverage/.
if ENV.key?("COVERAGE")
  SimpleCov.start do
    add_filter "/spec/"
    enable_coverage :branch
  end
end
