# frozen_string_literal: true

module GitFame
  module Extension
    refine Hash do
      # Exclude keys from a Hash
      #
      # @param [Array<Symbol>] keys
      #
      # @return [Hash]
      def only(...)
        dup.extract!(...)
      end
    end
  end
end
