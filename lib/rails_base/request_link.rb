# frozen_string_literal: true

module RailsBase
  class RequestLink
    attr_accessor :link, :text

    def self.add(link:, text:)
      return false if items.any? { _1.text == text }

      items << new(link:, text:)
      true
    end

    def self.items
      @array ||= []
    end

    def self.any?
      items.length > 0
    end

    def initialize(link:, text:)
      @link = link
      @text = text
    end
  end
end
