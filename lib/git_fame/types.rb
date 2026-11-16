# frozen_string_literal: true

module GitFame
  module Types
    include Dry::Types()

    Set = Instance(Set).constructor(&:to_set)
  end
end
