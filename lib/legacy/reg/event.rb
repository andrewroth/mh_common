module Legacy
  module Reg
    module Event

      def self.included(base)
        base.class_eval do
          require 'ordered_hash_sort.rb'
          
          has_many :registrations, :foreign_key => _(:event_id, :registration)
          has_many :price_rules, :foreign_key => _(:event_id, :price_rule)
          has_many :fields, :foreign_key => _(:event_id, :field)
          has_many :people, :through => :registrations
          belongs_to :country, :foreign_key => _(:country_id)

        end

        base.extend EventClassMethods
      end


      # get registration totals for gender and registration status for this event
      # returns a hash of hashes
      def info_totals()

        registrations = Assignment.all( :joins => [ :person => [ { :registrations => :registration_status_assoc }, :gender ] ],
                                        :select => "DISTINCT #{__(:id, :person)} AS person_id, #{__(:description, :gender)} AS gender, #{__(:description, :registration_status)} AS status",
                                        :conditions => [ "#{__(:event_id, :registration)} = ?", self.id ] )

        info_totals = { :gender => { :male => 0, :female => 0, :unknown => 0 },
                        :status => { :cancelled => 0, :registered => 0, :incomplete => 0 } }

        info_totals[:gender][:male]       = registrations.find_all{ |registration| registration.gender == Gender::MALE }.size
        info_totals[:gender][:female]     = registrations.find_all{ |registration| registration.gender == Gender::FEMALE }.size
        info_totals[:gender][:unknown]    = registrations.find_all{ |registration| registration.gender == Gender::UNKNOWN }.size
        info_totals[:status][:cancelled]  = registrations.find_all{ |registration| registration.status == RegistrationStatus::CANCELLED }.size
        info_totals[:status][:registered] = registrations.find_all{ |registration| registration.status == RegistrationStatus::REGISTERED }.size
        info_totals[:status][:incomplete] = registrations.find_all{ |registration| registration.status == RegistrationStatus::INCOMPLETE }.size

        info_totals
      end


      # get per-campus gender and registration status counts for this event
      # returns a hash of hashes accessed by campus id
      def per_campus_event_info()

        campus_info = ActiveSupport::OrderedHash.new # will contain gender and registration status info for each campus

        campuses = Assignment.all( :joins => [ :campus, { :person => [ { :registrations => :registration_status_assoc }, :gender ] } ],

                                   :select => "#{__(:id, :campus)} AS campusID, " +
                                              "#{__(:description, :campus)} AS name, " +
                                              "SUM(#{__(:description, :gender)} = '#{Gender::MALE}') AS males, " +
                                              "SUM(#{__(:description, :gender)} = '#{Gender::FEMALE}') AS females, " +
                                              "SUM(#{__(:description, :gender)} = '#{Gender::UNKNOWN}') AS unknowns, " +
                                              "SUM(#{__(:description, :registration_status)} = '#{RegistrationStatus::CANCELLED}') AS cancelled, " +
                                              "SUM(#{__(:description, :registration_status)} = '#{RegistrationStatus::REGISTERED}') AS registered, " +
                                              "SUM(#{__(:description, :registration_status)} = '#{RegistrationStatus::INCOMPLETE}') AS incomplete",

                                   :group => "#{__(:id, :campus)}",

                                   :conditions => [ "#{__(:event_id, :registration)} = ?", self.id ] )

        campuses.each do |campus|
          campus_info.merge!( campus.campusID => { :name => "", :gender => { :male => 0, :female => 0, :unknown => 0 },
                                                                :status => { :cancelled => 0, :registered => 0, :incomplete => 0 } } )

          campus_info[campus.campusID][:name] = campus.name
          campus_info[campus.campusID][:gender][:male] = campus.males.to_i
          campus_info[campus.campusID][:gender][:female] = campus.females.to_i
          campus_info[campus.campusID][:gender][:unknown] = campus.unknowns.to_i
          campus_info[campus.campusID][:status][:cancelled] = campus.cancelled.to_i
          campus_info[campus.campusID][:status][:registered] = campus.registered.to_i
          campus_info[campus.campusID][:status][:incomplete] = campus.incomplete.to_i
        end

        # sort the hash by campus name
        campus_info = campus_info.sorted_hash{ |a, b| a[1][:name] <=> b[1][:name]}

        campus_info
      end


      def registrations_from_campus(campus)

        self.registrations.all( :include => [ { :person => { :assignments => :campus } }, :registration_status_assoc, :cash_transactions ],

                                :select => "#{__(:id, :campus)}, #{__(:first_name, :person)}, #{__(:last_name, :person)}, #{__(:email, :person)}, " +
                                           "#{__(:received, :cash_transaction)}, #{__(:staff_name, :cash_transaction)}, " +
                                           "#{__(:description, :registration_status)}, #{__(:date, :registration)}, #{__(:balance, :registration)}, #{__(:id, :registration)}",

                                :conditions => [ "#{__(:id, :campus)} = ?", campus.id ] )
      end


      module EventClassMethods
        def get_all_events(order_field = :id, order = "DESC")
          order = order.upcase
          order = "DESC" if (order != "ASC" && order != "DESC")

          Event.all(:order => _(order_field) + " " + order + ", " + _(:id) + " " + order)
        end
      end

    end
  end
end
