# frozen_string_literal: true

module GitFame
  module Extension
    refine Hash do
      def only(...)
        dup.extract!(...)
      end
    end
  end
end
