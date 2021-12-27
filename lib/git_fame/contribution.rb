# frozen_string_literal: true

module GitFame
  class Contribution < Base
    attribute :lines, Types::Integer
    attribute :commits, Types::Set
    attribute :files, Types::Set
    attribute :author, Author

    delegate :name, :email, to: :author
  end
end
