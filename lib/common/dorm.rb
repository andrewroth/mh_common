module Common
  module Dorm
    def self.included(base)
      base.class_eval do
        belongs_to :campus
        has_many :groups
        load_mappings
        validates_presence_of :name
      end
    end
  end
end
