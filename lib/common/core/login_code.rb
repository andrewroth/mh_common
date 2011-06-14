module Common
  module Core
    module LoginCode
      def self.included(base)
        base.class_eval do
          after_create :init
        end

        base.extend LoginCodeClassMethods
      end
      
      def acceptable?
        is_acceptable = true
        is_acceptable = self.acceptable == true ? true : false
        # self.expires_at overrides self.acceptable
        is_acceptable = Time.now < self.expires_at ? true : false if self.expires_at.present?
      end
      
      def unacceptable?
        !acceptable?
      end
      
      def invalidate
        self.acceptable = false
        save!
      end
      
      def increment_times_used
        self.times_used = self.times_used.present? ? self.times_used += 1 : 1
        save!
      end
      
      private
      
      def init
        self.code ||= ::LoginCode.new_code
        self.acceptable ||= true
        self.times_used ||= 0
        self.save!
      end

      module LoginCodeClassMethods
        def new_code
          `uuidgen`.chomp
        end
      end
    end
  end
end
