# frozen_string_literal: true

if ENV.key?("CI")
  require "simplecov"
  require "simplecov-cobertura"

  SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter

  SimpleCov.start do
    add_filter "app/secrets"
  end
end
