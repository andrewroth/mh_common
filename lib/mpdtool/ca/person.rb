module Common::Mpdtool::Ca::Person
  def current_application
    @current_application ||= user.profiles.find(:first, :conditions => "type = 'Acceptance' OR type = 'StaffProfile'", :order => 'project_id desc') 
  end
end
