module SafetyNet
  def dump_table(table_name)
    table_name = table_name.to_s
    db_name, db_user, db_pass = get_db_config

    mysqldump = get_command_path('mysqldump')
    if mysqldump == 'SKIP!'
      puts "WARNING: Skipping dump of #{table_name}"
    else
      date = Time.now.to_s(:number)
      backup_file = File.join(RAILS_ROOT, 'tmp', "#{table_name}_#{date}.sql")

      host = `hostname`.chomp
      puts "** Backing up #{table_name} to #{backup_file} on #{host} **"
      system "#{mysqldump} -u#{db_user} -p#{db_pass} #{db_name}" \
             " #{table_name} > #{backup_file}"
      if $?.exitstatus != 0
        raise "UNABLE TO BACKUP #{table_name}.  Bugging out."
      end

      puts '** Backup success **'
    end
  end

  def restore_table(table_name)
    table_name = table_name.to_s
    db_name, db_user, db_pass = get_db_config

    mysql= get_command_path('mysql')
    if mysql== 'SKIP!'
      puts "WARNING: Skipping restore of #{table_name}"
    else
      tmp_dir = File.join(RAILS_ROOT, 'tmp')
      file_name = Dir.entries(tmp_dir).select do |name|
        name.match(/^#{table_name}_\d+\.sql$/)
      end.sort.last

      if !file_name
        raise "UNABLE TO RESTORE #{table_name}.  Bugging out."
      end

      restore_file = File.join(tmp_dir, file_name)
      puts "** Restoring #{table_name} from #{restore_file} **"
      system "#{mysql} -u#{db_user} -p#{db_pass} #{db_name} < #{restore_file}"
      if $?.exitstatus != 0
        raise "UNABLE TO RESTORE #{table_name}.  Bugging out."
      end
      puts '** Restore success **'
    end
  end

  def get_db_config
    db_config = ActiveRecord::Base.connection.instance_values["config"]
    return [db_config[:database], db_config[:user], db_config[:password]]
  end

  def get_command_path(command)
    path = `which #{command}`.chomp
    if path.blank?
      print "What is the full path to #{command} (or type 'SKIP!')? "
      gets.chomp
    else
      path
    end
  end
end
