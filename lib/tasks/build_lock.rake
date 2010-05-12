class CustomLogger < Logger
  def format_message(severity, timestamp, progname, msg)
    "#{msg}\n"
  end
end

namespace :test do
  namespace :mh_common do
    task :lock do
      $logfile = File.open(Rails.root.join("log/mh_common_lock.log"), "a")
      $logfile.sync = true
      $logger = CustomLogger.new($logfile)
      $logger.info "Starting #{Time.now}"
      $lock_path = File.expand_path("~/.mh_common_lock")
      while File.exists?($lock_path)
        $logger.info "Detected another test going on.  Waiting 30 seconds."
        sleep 30
      end
      $lock = File.open($lock_path, "w")
      $logger.info "Established mh_common lock"
    end

    namespace :lock do
      task :release do
        $logger.info "Finished tests, closing lock"
        $lock.close
        File.delete($lock_path)
        $logger.info "Done #{Time.now}"
      end
    end
  end
end
