require 'fileutils'

namespace :db do
  namespace :migrate do
    namespace :copy do
      Dir["#{File.dirname(__FILE__)}/../../db/migrate/*"].each do |dir|
        next unless File.directory?(dir)
        dirname = File.basename(dir)
        desc "Copy common plugin's db/migrate/#{dirname}/* to db/migrate"
        task dirname do
          Dir["#{dir}/*"].each do |file|
            puts "Copy #{dirname}/#{File.basename(file)} to db/migrate"
            FileUtils.cp file, Rails.root.join("db/migrate/")
          end
        end
      end
    end
  end
end
