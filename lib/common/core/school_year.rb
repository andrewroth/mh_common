module Common
  module Core
    module SchoolYear
      def self.included(base)
        base.class_eval do
          acts_as_list
          default_scope :order => _(:position)
          validates_presence_of :name
        end
      end

      def description
        @description ||= "#{name}#{level.present? ? ' (' + level.to_s + ')' : ''}"
      end
    end
  end
end
