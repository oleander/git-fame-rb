# frozen_string_literal: true

# See: https://github.com/oleander/git-fame-rb/issues/126
require "active_support"

require "active_support/core_ext/module/delegation"
require "active_support/isolated_execution_state"
require "active_support/core_ext/numeric/time"
require "active_support/core_ext/object/blank"
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
