namespace :db do
  task :migrate do
    Rake::Task["db:structure:dump"].invoke
  end
end
