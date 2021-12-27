# frozen_string_literal: true

using Module.new {
  refine Hash do
    def serialize
      transform_values(&:serialize).transform_keys(&:serialize)
    end
  end

  refine Array do
    def serialize
      map(&:serialize)
    end
  end

  refine Set do
    def serialize
      to_a.serialize
    end
  end

  refine Pathname do
    def serialize
      to_s
    end
  end

  refine Object do
    alias_method :serialize, :itself
  end
}

module Dumpable
  def serialize
    to_h.serialize
  end

  def inspect
    JSON.neat_generate(serialize, sort: true, wrap: 40, aligned: true, around_colon: 1)
  end

  def dump
    id = object_id
    name = self.class.name.split("::").last.downcase
    Pathname(__dir__).join("../fixtures/#{name}.#{id}.json").write(inspect)
  end
end
