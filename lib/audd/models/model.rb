# frozen_string_literal: true

module Audd
  # Base for the response objects. Subclasses declare the fields their OpenAPI
  # schema documents; every instance also keeps the untouched `raw` hash,
  # because those schemas are all `additionalProperties: true` — Apple, Spotify
  # and friends ship new keys without warning and AudD passes them through
  # verbatim. Reach unmapped keys with `result["some_new_key"]`.
  class Model
    class << self
      # Declares a reader backed by `key` in the raw payload. An optional block
      # casts the raw value (used to nest sub-models).
      def field(name, key = name.to_s, &cast)
        fields[name] = [key, cast]
        attr_reader(name)
      end

      def fields
        @fields ||= superclass.respond_to?(:fields) ? superclass.fields.dup : {}
      end

      # Anything that isn't an object (`null`, mostly) is absence, not an error.
      def from_json(raw)
        new(raw) if raw.is_a?(Hash)
      end
    end

    attr_reader :raw

    def initialize(raw)
      @raw = raw
      self.class.fields.each do |name, (key, cast)|
        value = raw[key]
        value = cast.call(value) if cast && !value.nil?
        instance_variable_set(:"@#{name}", value)
      end
    end

    def [](key)
      raw[key.to_s]
    end

    def to_h
      raw
    end

    def ==(other)
      other.instance_of?(self.class) && other.raw == raw
    end
    alias_method :eql?, :==

    def hash
      [self.class, raw].hash
    end

    # Only the fields that are actually present — these payloads are wide and
    # mostly empty, and a full dump buries the useful bits.
    def inspect
      populated = self.class.fields.keys.filter_map do |name|
        value = public_send(name)
        "#{name}=#{value.inspect}" unless value.nil?
      end
      "#<#{self.class.name} #{populated.join(" ")}>"
    end
  end
end
