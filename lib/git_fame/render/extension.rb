# frozen_string_literal: true

require "active_support/dependencies/autoload"
require "active_support/number_helper"

module GitFame
  class Render
    module Extension
      refine Integer do
        def f
          ActiveSupport::NumberHelper.number_to_delimited(self, delimiter: " ")
        end
      end

      refine Contribution do
        def dist(result)
          l = lines.to_f / result.lines
          c = commits.count.to_f / result.commits.count
          f = files.count.to_f / result.files.count

          "%0.1f%% / %0.1f%% / %0.1f%%" % [l * 100, c * 100, f * 100]
        end
      end
    end
  end
end
