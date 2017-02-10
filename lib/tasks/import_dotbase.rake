# encoding: utf-8
######################################################################################
# Zwinalabs : https://github.com/zwinalabs
# authors :  kaiis.alcherif@gmail.com
# task for dumping from redmine using id_project
# First of all you should create the three tables  issues_dotbase, journals_dotbase and attachments_dotbase
# After that you should import all data from dumped files
# rake redmine:import_dotbase[old_dotbase_project_id, new_helpdesk_project_id]
# for exemple import all dotbase (project_id GeneralMedia = 133)issues, their journals and their attachements from redmine dotbase tmp tables rows to helpdesk tables using new project_id=621:
# rake redmine:import_dotbase[133,621]
#      - Dotbase project_id GeneralMedia = 133
#      - Helpdesk project_id GeneralMedia = 621
# id : project name
# 196 : ACM
# 133 : GeneralMedia
# 181 : Stucortec
# 313 : M&H
######################################################################################
require File.expand_path('../../../config/environment', __FILE__)
require 'active_record'
require 'date'
require 'csv'

$DBG = true
$DEVEL= true

# redmine dotbase database params
$dotbase_db_name = "redmine2"
$dotbase_db_user = "root"
$dotbase_db_pwd = "admin"
$dotbase_db_host = "localhost"
$dotbase_db_adapter = "mysql2"

# tmp tables used to import dotbase data
$tmp_table_issues = "issues_dotbase"
$tmp_table_journals = "journals_dotbase"
$tmp_table_attachments = "attachments_dotbase"

# current date
$current_date_tmp = DateTime.now.strftime("%d-%m-%Y")

$path_to_log_files = "/home/qays/projects/redmine2/redmine_issues/import_redmine/logs"
$files_opening_modes = "a+"

# Default data
$dotbase_user_mail = "kal+dotbase@zwinalabs.com"
$dotbase_tracker =  "Migration"
$dotbase_issue_status = "Fermé"


$stdout.sync = true
ActiveRecord::Base.record_timestamps = false
ENV['RAILS_ENV'] ||= 'production'


namespace :redmine do
  desc "***Dotbase import script***"
  # arg1: id project source (to import from)
  # arg2: id project destination (to import to)
  task :import_dotbase, [:arg1, :arg2] do |t, args|

    @connection = ActiveRecord::Base.establish_connection(
        :adapter => $dotbase_db_adapter,
        :host => $dotbase_db_host,
        :database => $dotbase_db_name,
        :username => $dotbase_db_user,
        :password => $dotbase_db_pwd
    )


    # Logs files init
    CSV.open("#{$path_to_log_files}/issues_ko_#{args[:arg1]}_to_#{args[:arg2]}_#{$current_date_tmp}.csv", $files_opening_modes) do |csv|
      csv << ["-unsaved_dotbase_issue-"]
    end
    CSV.open("#{$path_to_log_files}/issues_ok_#{args[:arg1]}_to_#{args[:arg2]}_#{$current_date_tmp}.csv", $files_opening_modes) do |csv|
      csv << ["dotbase_issue","saved_issues"]
    end
    CSV.open("#{$path_to_log_files}/journal_ko_#{args[:arg1]}_to_#{args[:arg2]}_#{$current_date_tmp}.csv", $files_opening_modes) do |csv|
      csv << ["-unsaved_dotbase_journal-"]
    end
    CSV.open("#{$path_to_log_files}/journal_ok_#{args[:arg1]}_to_#{args[:arg2]}_#{$current_date_tmp}.csv", $files_opening_modes) do |csv|
      csv << ["dotbase_journal","saved__journal"]
    end
    CSV.open("#{$path_to_log_files}/attachement_ko_#{args[:arg1]}_to_#{args[:arg2]}_#{$current_date_tmp}.csv", $files_opening_modes) do |csv|
      csv << ["-unsaved_dotbase_attachement-"]
    end
    CSV.open("#{$path_to_log_files}/attachement_ok_#{args[:arg1]}_to_#{args[:arg2]}_#{$current_date_tmp}.csv", $files_opening_modes) do |csv|
      csv << ["dotbase_attachement","saved_attachement"]
    end

    puts "WARNING: Your Redmine data (issues, journals and attachements) will be updated during this process."
    puts "The cmd 'rake redmine:import_dotbase[#{args[:arg1]},#{args[:arg2]}]' import issues their journals and their attachements from the project #{args[:arg1]} to #{args[:arg2]}"
    puts "-------------------->"
    print "Are you sure you want to continue ? [y/N] "
    STDOUT.flush
    break unless STDIN.gets.match(/^y$/i)


    #check if  $tmp_table_issues exist
    sql3 = "SELECT 1 FROM #{$tmp_table_issues} LIMIT 1;"
    @result3 = @connection.connection.execute(sql3);
    if @result3.count <= 0
      abort("ABORTED! the table #{$tmp_table_issues} is not created!!!")
    end

    #check if  $tmp_table_journals exist
    sql4 = "SELECT 1 FROM #{$tmp_table_journals} LIMIT 1;"
    @result4 = @connection.connection.execute(sql4);
    if @result4.count <= 0
      abort("ABORTED! the table #{$tmp_table_journals} is not created!!!")
    end

    #check if  $tmp_table_attachments exist
    sql5 = "SELECT 1 FROM #{$tmp_table_attachments} LIMIT 1;"
    @result5 = @connection.connection.execute(sql5);
    if @result5.count <= 0
      abort("ABORTED! the table #{$tmp_table_attachments} is not created!!!")
    end


    #check if id project(arg1) source exist in tmp_issues table
    sql1 = "SELECT * FROM #{$tmp_table_issues} WHERE project_id = #{args[:arg1]}"
    @result1 = @connection.connection.execute(sql1);

    #check if id project(arg2) destination exist in project table
    sql2 = "SELECT id FROM projects WHERE id = #{args[:arg2]}"
    @result2 = @connection.connection.execute(sql2);


    if @result1.count <= 0
      abort("ABORTED! You forgot to put the first arg : source project_id or this source project_id: #{args[:arg1]} does not exist")
    end

    if @result2.count <= 0
      abort("ABORTED! You forgot to put the second arg : destination project_id or this destination project_id: #{args[:arg2]} does not exist")
    end

    if @result1.count > 0 && @result2.count > 0
      puts "#{args[:arg1]} and #{args[:arg2]} exit ;)"
      puts "Importing of issues, journals and attachments from #{args[:arg1]} to #{args[:arg2]}"

      puts "......................................."
      puts "...........issues importing............"
      puts "......................................."

      # Browse all issues from dotbase
      @result1.each(:as => :hash) do |row|
          dotbase_issue_id = row["id"]
          user = User.find_by_mail($dotbase_user_mail)
          tracker = Tracker.find_by_name($dotbase_tracker)
          status = IssueStatus.find_by_name($dotbase_issue_status)
          issue = Issue.new(
              :author => user,
              :project_id => args[:arg2].to_i,
              :tracker => tracker,
              :assigned_to => user,
              :status => status,
              :subject => row["subject"],
              :description => row["description"],
              :done_ratio => 100,
              :category_id => nil,
              :priority_id => row["priority_id"],
              :estimated_hours => row["estimated_hours"],
              :created_on => row["created_on"],
              :updated_on => row["updated_on"],
              :start_date => row["start_date"],
              :closed_on => row["closed_on"],
              :parent_id => nil

          )

          # save new issue in helpdesk with dotbase data
          if issue.save
            # les dates sont forcées dans la création par date system donc il faut les updater
            issue.created_on = row["created_on"]
            issue.updated_on = row["updated_on"]
            issue.closed_on = row["closed_on"]
            issue.save
            # log moved issue
            CSV.open("#{$path_to_log_files}/issues_ok_#{args[:arg1]}_to_#{args[:arg2]}_#{$current_date_tmp}.csv", $files_opening_modes) do |csv|
              csv << [row["id"],issue.id]
            end


            # "...........import journals............"
            sql3 = "SELECT * FROM  #{$tmp_table_journals} WHERE journalized_id 	= #{dotbase_issue_id}"
            @result3 = @connection.connection.execute(sql3);
            if @result3.count > 0
              @result3.each(:as => :hash) do |jrow|
                journal = Journal.new(
                    :journalized =>issue,
                    :journalized_type => jrow["journalized_type"],
                    :user => user,
                    :notes => jrow["notes"],
                    :private_notes => false,
                    :created_on => jrow["created_on"]
                )

                if journal.save
                  # moved journals
                  CSV.open("#{$path_to_log_files}/journal_ok_#{args[:arg1]}_to_#{args[:arg2]}_#{$current_date_tmp}.csv", $files_opening_modes) do |csv|
                    csv << [jrow["id"], journal.id]
                  end
                else
                  # unmoved journals
                  CSV.open("#{$path_to_log_files}/journal_ko_#{args[:arg1]}_to_#{args[:arg2]}_#{$current_date_tmp}.csv", $files_opening_modes) do |csv|
                    csv << [jrow["id"]]
                  end
                end

              end

            end
            # "...........import attachments............"
            sql3 = "SELECT * FROM  #{$tmp_table_attachments} WHERE container_id 	= #{dotbase_issue_id}"
            @result3 = @connection.connection.execute(sql3);
            if @result3.count > 0
              @result3.each(:as => :hash) do |att_row|
                attachement =  Attachment.new(
                    :container => issue,
                    :container_type => att_row["container_type"],
                    :filename => att_row["filename"],
                    :disk_filename => att_row["disk_filename"],
                    :filesize => att_row["filesize"],
                    :content_type => att_row["content_type"],
                    :digest => att_row["digest"],
                    :downloads => att_row["downloads"],
                    :author => user,
                    :created_on => att_row["created_on"],
                    :description => att_row["description"],
                )
                if attachement.save
                  # moved attachements
                  CSV.open("#{$path_to_log_files}/attachement_ok_#{args[:arg1]}_to_#{args[:arg2]}_#{$current_date_tmp}.csv", $files_opening_modes) do |csv|
                    csv << [att_row["id"],attachement.id]
                  end
                else
                  # unmoved attachements
                  CSV.open("#{$path_to_log_files}/attachement_ko_#{args[:arg1]}_to_#{args[:arg2]}_#{$current_date_tmp}.csv", $files_opening_modes) do |csv|
                    csv << [att_row["id"]]
                  end
                end
              end

            end
          else
            # Keep unsaved issues ids to display them in flash error
            CSV.open("#{$path_to_log_files}/issues_ko_#{args[:arg1]}_to_#{args[:arg2]}_#{$current_date_tmp}.csv", $files_opening_modes) do |csv|
              csv << [row["id"]]
            end
          end
      end
    end
  end
end

