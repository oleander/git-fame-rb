# frozen_string_literal: true

require "set"

module GitFame
  module Types
    include Dry::Types()

    Set = Instance(Set).constructor(&:to_set)
  end
end
