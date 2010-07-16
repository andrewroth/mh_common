module Test
  module TestHelper

    require 'factory_girl'
    include ActionController::TestProcess

    Dir[Rails.root.join("vendor/plugins/mh_common/test/factories/**/*.rb")].each do |file|
      require file
    end

    def self.included(base)
      base.class_eval do
        base.use_transactional_fixtures = false
        base.use_instantiated_fixtures  = false

        def teardown() teardown_everything end
        def setup
          #Attachment.saves = 0
          #attachment_model self.class.attachment_model
        end
      end
    end

    def logger
      RAILS_DEFAULT_LOGGER
    end

    # Add more helper methods to be used by all tests here...
    def login(username = 'josh.starcher@example.com')
      @user = User.find(:first, :conditions => { User._(:username) => username})
      @request.session[:user] = @user.id
      @request.session[:ministry_id] = 1
      @person = @user.person
    end

    def reset_all_sequences
      Factory.sequences.values.each { |s| s.reset }
    end

    def teardown_everything
      reset_all_sequences
      ActiveRecord::Base.send(:subclasses).each { |m| m.delete_all unless m.abstract_class }
    end

    def setup_users
      Factory(:user_1)
      Factory(:user_3)
    end

    def setup_addresses
      Factory(:address_1)
      Factory(:address_2)
      Factory(:address_3)
    end

    def setup_ministry_involvements
      Factory(:ministryinvolvement_1)
      Factory(:ministryinvolvement_2)
      Factory(:ministryinvolvement_3)
      Factory(:ministryinvolvement_4)
      Factory(:ministryinvolvement_5)
      Factory(:ministryinvolvement_6)
      Factory(:ministryinvolvement_7)
    end

    def setup_school_years
      Factory(:schoolyear_1)
      Factory(:schoolyear_2)
    end

    def setup_generic_person
      return Factory(:person)
    end

    def setup_assignments
      Factory(:person_1)
      Factory(:person_2)
      Factory(:person_3)
      Factory(:person)
      Factory(:assignment_1)
      Factory(:assignment_2)
      Factory(:assignment_3)
      Factory(:assignment_4)
      Factory(:assignment_5)
      Factory(:assignment_6)
    end

    def setup_people
      reset_people_sequences
      Factory(:person_1)
      Factory(:person_3)
      Factory(:person_5)
      Factory(:person_111)
    end

    def setup_campuses
      Factory(:campus_1)
      Factory(:campus_2)
      Factory(:campus_3)
    end

    def setup_ministries
      @ministry_yfc = Factory(:ministry_1)
      Factory(:ministry_2)
      Factory(:ministry_3)
      Factory(:ministry_4)
      Factory(:ministry_5)
      Factory(:ministry_6)
      Factory(:ministry_7)
    end

    def setup_default_user
      Factory(:user_1)
      Factory(:person_1)
      Factory(:campusinvolvement_3)
      Factory(:ministry_1)
      Factory(:ministry_2)
      Factory(:ministryinvolvement_1)
      Factory(:ministryinvolvement_2)
      Factory(:campus_1)
      Factory(:campus_2)
      Factory(:ministrycampus_1)
      Factory(:ministrycampus_2)
      Factory(:country_1)
    end

    def setup_n_people(n)
      reset_people_sequences
      1.upto(n + 1) do |i|
        Factory(:person)
      end
    end

    def setup_n_campus_involvements(n)
      reset_campus_involvements_sequences
      1.upto(n + 1) do |i|
        Factory(:campusinvolvement)
      end
    end

    def setup_campus_involvements
      setup_n_campus_involvements(1000)
    end

    def setup_ministry_roles
      @ministry_role_one = Factory(:ministryrole_1)
      Factory(:ministryrole_2)
      Factory(:ministryrole_3)
      Factory(:ministryrole_4)
      Factory(:ministryrole_5)
      Factory(:ministryrole_6)
      Factory(:ministryrole_7)
      Factory(:ministryrole_8)
      Factory(:ministryrole_9)
    end

    def reset_campus_involvements_sequences
      Factory.sequences[:campusinvolvement_person_id].reset
      Factory.sequences[:campusinvolvement_id].reset
    end

    def reset_people_sequences
      Factory.sequences[:person_person_id].reset
      Factory.sequences[:person_last_name].reset
    end

    def setup_groups
      Factory(:grouptype_1)
      Factory(:grouptype_2)
      Factory(:grouptype_3)

      Factory(:group_1)
      Factory(:group_2)
      Factory(:group_3)
      Factory(:group_4)

      Factory(:person_3)

      setup_people
      50.times{ Factory(:person) }

      Factory(:groupinvolvement_1)
      Factory(:groupinvolvement_2)
      Factory(:groupinvolvement_3)
      Factory(:groupinvolvement_4)
      Factory(:groupinvolvement_5)
      Factory(:groupinvolvement_6)
    end

    def setup_ministry_campuses
      Factory(:ministrycampus_1)
      Factory(:ministrycampus_2)
      Factory(:ministrycampus_3)
    end


    protected

      def upload_file(options = {})
        use_temp_file options[:filename] do |file|
          att = attachment_model.create :uploaded_data => fixture_file_upload(file, options[:content_type] || 'image/png')
          att.reload unless att.new_record?
          return att
        end
      end

      def use_temp_file(fixture_filename)
        temp_path = File.join('/tmp', File.basename(fixture_filename))
        FileUtils.mkdir_p File.join(fixture_path, 'tmp')
        FileUtils.cp File.join(fixture_path, fixture_filename), File.join(fixture_path, temp_path)
        yield temp_path
      ensure
        FileUtils.rm_rf File.join(fixture_path, 'tmp')
      end

  end
end
