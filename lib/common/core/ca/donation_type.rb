module Common::Core::Ca::DonationType
  def self.included(base)
    base.class_eval do
      has_many :manual_donations
    end
  end
end
