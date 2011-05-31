module Common
  module Core
    module UserCode
      def self.included(base)
        base.class_eval do
          belongs_to :user
        end

        base.extend UserCodeClassMethods
      end

      def callback_url(base_url, controller, action)
        "#{base_url}/user_codes/#{code}/#{controller}/#{action}"
      end

      def pass_hash
        pass.present? ? Marshal.load(pass) : {}
      end

      module UserCodeClassMethods
        def new_code
          MD5.hexdigest((object_id + Time.now.to_i).to_s)
        end
      end
    end
  end
end
