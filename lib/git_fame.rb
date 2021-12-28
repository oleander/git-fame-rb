# frozen_string_literal: true

require "active_support/core_ext/module/delegation"
require "active_support/isolated_execution_state"
require "active_support/core_ext/numeric/time"
require "dry/core/memoizable"
require "dry/initializer"
require "dry/struct"
require "dry/types"
require "neatjson"
require "zeitwerk"
require "pathname"
require "rugged"

module GitFame
  Zeitwerk::Loader.for_gem.tap(&:setup)
end
