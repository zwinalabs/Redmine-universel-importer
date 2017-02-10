# encoding: utf-8
######################################################################################
# Zwinalabs : https://github.com/zwinalabs
# authors :  kaiis.alcherif@gmail.com
# task to import user projects and their roles to another user
# Exemples:
# rake RAILS_ENV=production redmine:import_user_projects[574,"pzu"] --trace
#      - 574 : id of user source (to import from)
#      - pzu : login of user destination (to import to)
######################################################################################
require File.expand_path('../../../config/environment', __FILE__)
require 'active_record'
require 'date'
require 'csv'

$DBG = true
$DEVEL= true


# redmine database params
$red_db_name = "redmine"
$red_db_user = "root"
$red_db_pwd = "admin"
$red_db_host = "127.0.0.1"
$red_db_adapter = "mysql2"

# current date
$current_date_tmp = DateTime.now.strftime("%d-%m-%Y")

$stdout.sync = true
ActiveRecord::Base.record_timestamps = false
ENV['RAILS_ENV'] ||= 'production'


namespace :redmine do
  desc "***Import projects and their roles from user to another***"
  # arg1: user source (to import from)
  # arg2: user destination (to import to)
  task :import_user_projects, [:arg1, :arg2] do |t, args|

    @connection = ActiveRecord::Base.establish_connection(
        :adapter => $red_db_adapter,
        :host => $red_db_host,
        :database => $red_db_name,
        :username => $red_db_user,
        :password => $red_db_pwd
    )



    puts "WARNING: Your Redmine data will be updated during this process."
    puts "The cmd 'rake redmine:import_user_projects[#{args[:arg1]},#{args[:arg2]}]' import user_id : #{args[:arg1]} projects and their roles to user login is : #{args[:arg2]}"
    puts "-------------------->"
    print "Are you sure you want to continue ? [y/N] "
    STDOUT.flush
    break unless STDIN.gets.match(/^y$/i)

    user = User.find_by_login(args[:arg2]);
    members_lista = ""
    member_roles_lista = ""


    # list all member the indicated user
    sql1 = "SELECT * FROM  members WHERE user_id = #{args[:arg1]}"
    puts "full name is : #{user.id} #{user.firstname}	#{user.lastname}"
    @result1 = @connection.connection.execute(sql1)
    if @result1.count > 0
      @result1.each(:as => :hash) do |member_row|
        #insert a new member line
        sql2 = "INSERT INTO members (user_id, project_id, created_on, mail_notification) VALUES ( #{user.id}, #{member_row["project_id"]}, '#{member_row["created_on"]}', #{member_row["mail_notification"]} )"
        member_id = Member.connection.insert_sql(sql2)

        # check if member line is saved
        if member_id > 0
          puts "member saved with id: #{member_id}"
          members_lista = "#{members_lista},#{member_id}"

          # liste all roles of the selected member line
          sql3 = "SELECT * FROM  member_roles WHERE member_id = #{member_row["id"]}"
          puts "imported member_role from  member_id = #{member_row["id"]}"
          @result2 = @connection.connection.execute(sql3)
          if @result2.count > 0
            @result2.each(:as => :hash) do |member_role_row|
              sql4 = "INSERT INTO member_roles (member_id, role_id, inherited_from) VALUES (#{member_id}, #{member_role_row["role_id"]}, '#{member_role_row["inherited_from"]}')"
              #insert the new line of member_role
              member_role_id = MemberRole.connection.insert_sql(sql4)
              puts "member_role saved with id: #{member_role_id}"
              member_roles_lista = "#{member_roles_lista},#{member_role_id}"

            end
          end

        else
          puts "#{member_row["id"]} is not save"
        end

      end

    else
        abort("ABORTED! no members for this user_id : #{args[:arg1]}!!!")
    end
    puts "-----------------------"
    puts "new members ID's list for '#{args[:arg2]}' : #{members_lista}"
    puts "new member_roles ID's list for '#{args[:arg2]}': #{member_roles_lista}"
    puts "-----------------------"
  end

end