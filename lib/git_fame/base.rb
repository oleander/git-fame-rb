# frozen_string_literal: true

module GitFame
  class Base < Dry::Struct
    schema schema.strict(true)

    attribute? :log_level, Types::Coercible::Symbol.default(:debug).enum(:debug, :info, :warn, :error, :fatal, :unknown)

    private

    def say(template, *args)
      logger.debug(template % args)
    end

    def logger
      @logger ||= Logger.new($stdout, level: log_level, progname: self.class.name)
    end
  end
end
