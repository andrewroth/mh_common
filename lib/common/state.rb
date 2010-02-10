module Common
  module State
    def self.included(base)
      base.class_eval do
        belongs_to :country
        has_many :campuses, :foreign_key => _(:state_id, :campus)
      end
    end
  end
end
