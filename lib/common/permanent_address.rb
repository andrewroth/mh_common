module Common
  module PermanentAddress
    def self.included(base)
      base.class_eval do
        before_create :set_address_type
      end
    end

    def set_address_type
      self.address_type = "permanent"
    end
  end
end
