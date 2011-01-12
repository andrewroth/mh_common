module Common::Pat::Profile
  def self.included(base)
    base.class_eval do
      belongs_to :project
      belongs_to :user, :foreign_key => "viewer_id"

      has_many :auto_donations, :class_name => "AutoDonation", :finder_sql =>
        "SELECT #{AutoDonation.columns.collect{ |ad| "d."+ad.name }.join(', ')} " +
        "FROM #{Profile.table_name} p, #{AutoDonation.table_name} d " +
        'WHERE p.id = #{id} and d.participant_motv_code = \'#{motivation_code}\' ' +
        'ORDER BY d.donation_date'

      has_many :manual_donations, :class_name => "ManualDonation", :finder_sql =>
        "SELECT #{ManualDonation.columns.collect{ |ad| "d."+ad.name }.join(', ')} " +
        "FROM #{Profile.table_name} p, #{ManualDonation.table_name} d " +
        'WHERE p.id = #{id} and d.motivation_code = \'#{motivation_code}\' ' +
        'ORDER BY d.created_at'

      # --- following methods are to help with cache invalidation 
      def orig_atts
        @orig_atts ||= { }
        @orig_atts['type'] ||= self[:type]
        attributes.merge(@orig_atts)
      end

      def write_attribute(att, val)
        @orig_atts ||= { }
        @orig_atts[att.to_s] ||= self[att]

        # special case for remembering when the costing total needs to be recalculated
        if !@in_save && %w(type project_id).include?(att.to_s)
          @update_costing_total_cache = true
        end

        super
      end

      def save!
        @in_save = true # fix infinite loop (see 1661)
        success = super
        @orig_atts = nil if success
        success
        @in_save = false
      end

      def att_changed(att) orig_atts[att.to_s] != self[att] end

      # -- end cache methods

      def Profile.types
        [ 'StaffProfile', 'Acceptance', 'Withdrawn', 'Applying' ]
      end

      def donations(params = {})
        if params[:cache]
          params[:cache][id.to_s]
        else
          all_donations = manual_donations + auto_donations

          all_donations.sort! { |a,b|
            if a.donation_date.nil? && b.donation_date.nil?
              0
            elsif a.donation_date.nil? && b.donation_date
              1
            elsif b.donation_date.nil? && a.donation_date
              -1
            else
              a.donation_date <=> b.donation_date
            end
          }

        end || []
      end

      def donations_total(params = {})
        amount_method = (params.delete(:orig) ? :original_amount : :amount)

        donations(params).inject(0.0) { |received, donation|
          if donation.class == ManualDonation && donation.status == 'invalid'
            received
          else
            received + donation.send(amount_method).to_f
          end
        }
      end

      # nicer names and display
      def support_goal() cached_costing_total ? cached_costing_total : BigDecimal(0) end
      def support_received() BigDecimal("%.2f" % donations_total) end
      def support_outstanding_use_claimed() support_goal - BigDecimal(support_claimed.to_s) end
      def support_outstanding_use_received() support_goal - support_received end

    end
  end
end
