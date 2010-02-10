module Common
  module Country
    def self.included(base)
      base.class_eval do
        named_scope :open, :conditions => {:closed => 0}
      end
    end
  end
end
