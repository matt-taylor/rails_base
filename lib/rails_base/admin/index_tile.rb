require RailsBase::Engine.root.join('app', 'helpers', 'rails_base', 'admin_helper.rb')

module RailsBase::Admin
  class IndexTile
    include RailsBase::AdminHelper
    attr_accessor :type, :name, :value, :col_name, :insert, :on, :off, :disabled, :disabled_msg, :selector, :partial , :link , :min_width , :url, :method , :color
    MODIFY_TYPES = [
      RISKY = { type: :risky },
      TOGGLE = { type: :toggle, expects: { on: 'String', off: 'String' } },
      SELECTOR = { type: :selector, expects: { selector: 'Proc' } },
      TEXT = { type: :text, expects: { partial: 'String' } },
      BUTTON = { type: :button, expects: { url: 'Proc', method: 'Symbol', color: 'String' } },
      PLAIN = { type: :plain },
    ]

    VALID_METHODS = [:get, :post, :delete, :patch, :put]
    # Input params
      # type: Symbol
      # => values: MODIFY_TYPES.map{|s| s[:type]}
      # => what: This is the type of index self will be
      #
      # name: Symbol
      # => values: <Anything>
      # => what:  Used as the `id` for html. when risky, expected it is a key in RailsBase::AdminController::SECOND_MODAL_MAPPING
      #
      # value: Proc
      # => values: Proc that takes a user as an argument ex: ->(current_user) { user.full_name }
      # => what: Value returned from proc will be value displayed table grid
      #
      # display: Proc
      # => values: Proc that takes a user as an argument ex: ->(current_user) { user.full_name }
      # => what: Boolean returned from proc will allow the element to be changeable
      #
      # col_name: String
      # => values: Short String
      # => what: Value for the Column header
      #
      # insert: Integer
      # => values: Expected to be an integer
      # => what: Column number in the admin view index table
      #
      # on: String
      # => values: 1 word for a toggle switch
      # => what: When toggle is on, this is displayed
      #
      # off: String
      # => values: 1 word for a toggle switch
      # => what: When toggle is off, this is displayed
      #
      # partial: String
      # => values: Path to partial
      # => what: Partial that will get loaded. At present, only for TEXT type
      #
      # url: Proc
      # => values: Given a user, Proc that dynamically assigns url based on the user
      # => what: ->(user) { Rails.application.url_routes.root_path }
      #
      # min_width: Integer
      # => values: nil || > 0
      # => what: Min width for the given table column. When nil passed, none will be set
      #
      # method: Symbol
      # => values: [:get, :post, :delete, :patch, :put]
      # => what: Min width for the given table column. When nil passed, none will be set. Used for Button
      #
      # method: String
      # => values: [:get, :post, :delete, :patch, :put]
      # => what: Min width for the given table column. When nil passed, none will be set. Used for Button
      #
      # selector: Array
      # => values: [:get, :post, :delete, :patch, :put]
      # => what: Min width for the given table column. When nil passed, none will be set. Used for Button
      #
      # selected: String
      # => values: [:get, :post, :delete, :patch, :put]
      # => what: Min width for the given table column. When nil passed, none will be set. Used for Button

    def self.add(instance)
      @default ||= []
      @default.insert(instance.insert, instance)
    end

    def self.defaults
      @default
    end

    def initialize(type:, name:, value:, col_name:, disabled: nil, disabled_msg: nil, insert: nil, on: nil, off: nil, selector: [], partial: nil, url: nil, min_width: nil, method: nil, color: 'warning')
      @type = type
      @name = name
      @value = value
      @col_name = col_name
      @insert = insert.is_a?(Integer) ? insert : -1
      @on = on
      @off = off
      @partial = partial
      @min_width = min_width.to_i rescue nil
      @disabled = disabled
      @disabled_msg = disabled_msg
      @selector = selector
      @method = method
      @url = url
      @color = color

      validate!
      validate_expects!
      validate_risky!
      validate_method!
      validate_disabled!
      validate_disabled_msg!
    end

    def is_toggle?
      type == TOGGLE[:type]
    end

    def is_selector?
      type == SELECTOR[:type]
    end

    def is_risky?
      type == RISKY[:type]
    end

    def is_text?
      type == TEXT[:type]
    end

    def is_button?
      type == BUTTON[:type]
    end

    private

    def validate!
      types = MODIFY_TYPES.map{|s| s[:type]}
      raise ArgumentError, "Expected type to be in [#{types}]" unless types.include? type
      raise ArgumentError, "Expected value to be a proc" unless value.is_a? Proc
    end

    def validate_disabled!
      return if disabled.nil?
      return if disabled.is_a?(Proc)

      raise ArgumentError, 'Expected disabled to be a Proc'
    end

    def validate_disabled_msg!
      return if disabled.nil?
      return unless disabled_msg.nil?

      raise ArgumentError, 'Expected `disabled_msg` to be present'
    end

    def validate_expects!
      type_object = MODIFY_TYPES.find { |s| s[:type] == type }

      return if type_object[:expects].nil?

      type_object[:expects].each do |k, v|
        val = public_send(k)
        raise ArgumentError, "Expected [#{val}] to be a #{v.constantize}" unless val.is_a? v.constantize
      end
    end

    def validate_risky!
      return unless is_risky?
      return if SECOND_MODAL_MAPPING.keys.include?(name)

      keys = SECOND_MODAL_MAPPING.keys
      msg = "Unable to use name #{name}. Expected to be defined in #{keys}" \
        "RailsBase::AdminController::SECOND_MODAL_MAPPING"
      raise ArgumentError, msg
    end


    def validate_method!
      return if method.nil?

      raise ArgumentError, "Unexpected method. Received: #{method}. Expected [#{VALID_METHODS}]" unless VALID_METHODS.include? method
    end
  end
end
