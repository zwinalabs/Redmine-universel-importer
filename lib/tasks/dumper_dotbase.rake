# encoding: utf-8
######################################################################################
# Zwinalabs : https://github.com/zwinalabs
# authors :  kaiis.alcherif@gmail.com
# task for dumping from redmine using id_project
# rake redmine:dumper_dotbase[project_id]
# for exemple dump all M&H(id=313)issues, their journals and their attachements redmine database rows:
# rake redmine:dumper_dotbase[313]
#
######################################################################################
require 'active_record'
require 'date'
$DBG = true
$DEVEL= true

# redmine dotbase database params
$dotbase_db_name = "redmine2"
$dotbase_db_user = "root"
$dotbase_db_pwd = "admin"
$dotbase_db_host = "localhost"
$dotbase_db_adapter = "mysql2"

$dumping_date = DateTime.now.strftime("%d-%m-%Y")

# dumping files and paths
$dotbase_path_to_dump_files = "/home/qays/projects/redmine2/db"



# arg1: id project to dump
# arg2: closed status id (5)

$stdout.sync = true
ActiveRecord::Base.record_timestamps = false
ENV['RAILS_ENV'] ||= 'production'


namespace :redmine do
  desc "***Dotbase dumping script***"
  task :dumper_dotbase, [:arg1] do |t, args|

    @connection = ActiveRecord::Base.establish_connection(
        :adapter => $dotbase_db_adapter,
        :host => $dotbase_db_host,
        :database => $dotbase_db_name,
        :username => $dotbase_db_user,
        :password => $dotbase_db_pwd
    )

    #check if id project exist
    sql = "SELECT id FROM projects WHERE id = #{args[:arg1]}"
    @result = @connection.connection.execute(sql);
    if @result.count > 0

      puts "Dumping of closed issues, journals and attachments for projet id: #{args[:arg1]} only"

      puts "################"
      puts "#issues dumping#"
      puts "################"
      $issues_file = "project_#{args[:arg1]}_issues_dotbase_#{$dumping_date}.sql"
      $cmd_issues_dump = "mysqldump --skip-triggers -h#{$dotbase_db_host} -u#{$dotbase_db_user} -p#{$dotbase_db_pwd} --databases #{$dotbase_db_name} --tables issues --where='project_id = #{args[:arg1]}' > #{$dotbase_path_to_dump_files}/#{$issues_file}"
      puts "---------------------------"
      puts "Exec : #{$cmd_issues_dump}"
      #exec issues dump
      system $cmd_issues_dump
      puts "---------------------------"
      puts "- issues dump [OK], dump files saved @ : #{$dotbase_path_to_dump_files}/#{$issues_file}"

      puts "################"
      puts "#journals dumping#"
      puts "################"
      $journals_file = "project_#{args[:arg1]}_journals_dotbase_#{$dumping_date}.sql"
      $cmd_journals_dump = "mysqldump --lock-all-tables  --skip-triggers -h#{$dotbase_db_host} -u#{$dotbase_db_user} -p#{$dotbase_db_pwd} --databases #{$dotbase_db_name} --tables journals --where='journalized_id IN (SELECT id FROM issues WHERE project_id = #{args[:arg1]})' > #{$dotbase_path_to_dump_files}/#{$journals_file}"
      puts "---------------------------"
      puts "Exec : #{$cmd_journals_dump}"
      #exec issues dump
      system $cmd_journals_dump
      puts "---------------------------"
      puts "- journals dump [OK], dump files saved @ : #{$dotbase_path_to_dump_files}/#{$journals_file}"

      puts "################"
      puts "#attachments dumping#"
      puts "################"
      $attachments_file = "project_#{args[:arg1]}_attachments_dotbase_#{$dumping_date}.sql"
      $cmd_attachments_dump = "mysqldump --lock-all-tables  --skip-triggers -h#{$dotbase_db_host} -u#{$dotbase_db_user} -p#{$dotbase_db_pwd} --databases #{$dotbase_db_name} --tables  attachments --where='container_id IN (SELECT id FROM issues WHERE project_id = #{args[:arg1]})' > #{$dotbase_path_to_dump_files}/#{$attachments_file}"
      puts "---------------------------"
      puts "Exec : #{$cmd_attachments_dump}"
      #exec issues dump
      system $cmd_attachments_dump
      puts "---------------------------"
      puts "- attachments dump [OK], dump files saved @ : #{$dotbase_path_to_dump_files}/#{$attachments_file}"


    else
      puts "The projet with id: #{args[:arg1]} doesn't exist please try on other id !!!"
    end


  end
end
