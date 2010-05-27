require 'multisite_helper'

module Cdm
  class Database
    def self.database_yml
      common_config = Dir["#{RAILS_ROOT}/config/common_*"]
      if common_config.length == 0
        raise "Error: no config/common_* file found."
      elsif common_config.length > 1
        raise "Error: more than one config/common_* file found.  Should be exactly one."
      end

      config = Dir["#{RAILS_ROOT}/config/common_*"].first
      load config

      multisite_config_hash(false)
      yml = %|
#{ 
dbh = "#{RAILS_ROOT}/config/database/database_header.yml"; dbhd = dbh+".default";
file = File.exists?(dbh) ? dbh : dbhd
File.read(file).chomp
}

development:
  database: #{local_db_name(Cdm::SERVER, Cdm::APP, Cdm::STAGE)}
  <<: *defaults

production:
  database: #{local_db_name(Cdm::SERVER, Cdm::APP, Cdm::STAGE)}
  <<: *defaults

test:
  database: #{utopian_db_name(Cdm::SERVER, Cdm::APP, "test")}
  <<: *defaults

#{multisite_config_hash[:apps].keys.collect { |app| yml_section(Cdm::SERVER, app, Cdm::STAGE) }}
|

      puts yml if ENV["pdb"] == "t"
      return yml
    end

    private

    def self.yml_section(server, app, stage)
%|#{app}_development:
  database: #{local_db_name(server, app, stage)}
  <<: *defaults

#{app}_production:
  database: #{local_db_name(server, app, stage)}
  <<: *defaults

#{app}_test:
  database: #{local_db_name(server, app, stage)}
  <<: *defaults

|
    end
  end
end
