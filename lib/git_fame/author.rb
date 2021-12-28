# frozen_string_literal: true

module GitFame
  class Author < Base
    attribute :name, Types::String
    attribute :email, Types::String
  end
end
