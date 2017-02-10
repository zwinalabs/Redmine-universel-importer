# encoding: utf-8
######################################################################################
# Zwinalabs : https://github.com/zwinalabs
# authors :  kaiis.alcherif@gmail.com
# task for importing attachment files
# cmd : rake redmine:import_attachment_files
#
######################################################################################
require File.expand_path('../../../config/environment', __FILE__)
require 'active_record'
require 'date'
require 'csv'
require 'time'

$DBG = true
$DEVEL= true

# redmine dotbase database params
$dotbase_db_name = "redmine2_prod"
$dotbase_db_user = "root"
$dotbase_db_pwd = "admin"
$dotbase_db_host = "localhost"
$dotbase_db_adapter = "mysql2"

# current date
$current_date_tmp = DateTime.now.strftime("%d-%m-%Y")

$path_to_log_files = "/home/qays/projects/redmine2/redmine_issues/import_redmine/logs"
$files_opening_modes = "a+"
$path_to_tmp_attachment_files = "/home/qays/projects/redmine2/redmine_issues/attachements_redmine"
$path_to_attachment_files = "/home/qays/projects/Projects/redmine2.3.4/files"

# log_fils
$csv_log_files = ["attachement_ok_133_to_621_26-01-2016.csv", "attachement_ok_181_to_623_26-01-2016.csv", "attachement_ok_196_to_622_26-01-2016.csv", "attachement_ok_313_to_620_26-01-2016.csv"]
$table_of_attachments = Array.new

$stdout.sync = true
ActiveRecord::Base.record_timestamps = false
ENV['RAILS_ENV'] ||= 'production'



namespace :redmine do
  desc "***Dotbase import script***"
  # arg1: id project source (to import from)
  task :importing_attachment_files do

      @connection = ActiveRecord::Base.establish_connection(
          :adapter => $dotbase_db_adapter,
          :host => $dotbase_db_host,
          :database => $dotbase_db_name,
          :username => $dotbase_db_user,
          :password => $dotbase_db_pwd
      )


      for fiche in $csv_log_files
        if File.file?("#{$path_to_log_files}/#{fiche}")
          CSV.foreach("#{$path_to_log_files}/#{fiche}") do |row|
            obj = row[1]
            if !obj.nil?
              $table_of_attachments<<obj
            end
          end
        else
          abort("ABORTED! No such file at #{$path_to_log_files}/#{fiche} !!!!")
        end
      end

      #
      $table_of_attachments.delete("saved_attachement")
      #binding.pry
      Attachment.find($table_of_attachments).each do |attache|
        if File.file?("#{$path_to_tmp_attachment_files}/#{attache.disk_filename}")
          time = attache.created_on
          attache.disk_directory = time.strftime("%y/%m")
          if attache.save
            FileUtils.mkdir_p("#{$path_to_attachment_files}/#{time.strftime("%y/%m")}")
            FileUtils.cp("#{$path_to_tmp_attachment_files}/#{attache.disk_filename}", "#{$path_to_attachment_files}/#{time.strftime("%y/%m")}")
            CSV.open("#{$path_to_log_files}/files_attachement_ok_#{$current_date_tmp}.csv", $files_opening_modes) do |csv|
                csv << [attache.id]
            end
          end
        else
          CSV.open("#{$path_to_log_files}/files_attachement_ko_#{$current_date_tmp}.csv", $files_opening_modes) do |csv|
            csv << [attache.id]
          end
        end
      end
    end
end