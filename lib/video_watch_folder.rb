require 'video_api'
require 'command_line_script'
require 'fileutils'

module VideoApi

# Will watch a folder (directory) on the local hard drive for new files,
# keep track of the files' sizes, and whenever a file is larger than a set
# minimum size and has stopped growing in size, upload it to the
# online video account.  Useful for a batch transcode process,
# a special video drop-box for editors, or exporting from a video suite
# like Final Cut Pro, where it will build up the exported file
# as it renders/transcodes it.  Only when this class sees that the
# file is larger than a set minimum size and has stopped growing since 
# the last check will it upload the file.
#
# When a file has been uploaded, to keep it from being uploaded again
# it is moved to a subfolder of the watch folder called 'finished'
# or 'failed', depending on whether the upload succeeded.
# If those subfolders don't exist, this class will create them
# in its constructor.
#
class VideoWatchFolder

  attr_reader :watch_dir, :contributor, :stopped, :pause_in_seconds, :minimum_file_size
  attr_writer :video_metadata
  attr_accessor :log_file_mode

  #
  # Lets you start watching a folder easily from a ruby script
  #
  # VideoWatchFolder.run({
  #   :base_url => "http://...",
  #   :account_id => "my-account-id",
  #   :library_name => "develpoment",
  #   :license_key => "12345",
  #   :watch_folder => "/home/video-editing-team/video-watch-folder",
  #   :contributor => "video-editing-team",
  #   :pause_in_seconds => 300,
  #   :minimum_file_size => 1000000,
  #   :hours_to_run => nil,
  #   :log_file_mode => false,
  #   :metadata => {'video[stillframe]' => 5.0, 'video[keywords]' => 'batch'}
  # })
  #
  # a non-nil (numeric) hours_to_run means run indefinitely
  # if log_file_mode is true, will only output upload progress
  # when the upload total has increased by 1%, making for a total
  # of 100 upload progress updates in the log.  
  #
  # metadata lets you specify the metadata to apply to each video uploaded,
  # including any of the fields you can include in a call to the 
  # Video Upload API (see online documentation for details)
  #
  def self.run(params)

    video_api = VideoApi.for_library(params[:base_url], 
                                     params[:account_id],
                                     params[:library_id],
                                     params[:license_key])

    watch_folder = VideoWatchFolder.new(params[:watch_folder],
                                        params[:contributor],
                                        video_api)

    watch_folder.log_file_mode = params[:log_file_mode]

    watch_folder.video_metadata = params[:video_metadata]

    puts("\n#{video_api.settings_trace_string}")

    params_doc = <<DOC

      contributor: #{watch_folder.contributor}
      watch_folder: #{watch_folder.watch_dir}
      pause_in_seconds: #{params[:pause_in_seconds]}
      minimum_file_size: #{params[:minimum_file_size]}
      hours_to_run: #{params[:hours_to_run]}
      log_file_mode: #{watch_folder.log_file_mode}

DOC

    puts(params_doc)

    watch_folder.start(params[:pause_in_seconds], 
                       params[:minimum_file_size], 
                       params[:hours_to_run])

  end

  # Initializes this watch folder object and the underlying watch folder.
  # Creates two subdirectories under the given watch_dir: 'finished'
  # and 'failed'.  Uploaded files will be moved into finished, and
  # files that fail to upload will be moved into failed.
  #
  # watch_dir:: the absolute or relative path of the folder/directory to watch for files to upload.
  # contributor:: the text to use as the videos' contributor.
  # video_api:: a VideoApi object that will be used to upload the files.
  #
  def initialize(watch_dir, contributor, video_api)

    @watch_dir = watch_dir
    @contributor = contributor
    @api = video_api
    @log_file_mode = false
    @video_metadata = {}

  end

  # Starts the watch folder process.  It will run until stop is called
  # or hours_to_run have passed.  If either of those events occurs
  # while this method is pausing between file checks or
  # while it's uploading a file, the pause or upload in progress
  # will finish before this method returns.
  # 
  # pause_in_seconds:: the number of seconds to pause between watch folder checks.  On each watch folder check, it looks for new files and compares current files sizes to their sizes on the last check.  And files that haven't changed in this number of seconds since the last check will be uploaded, unless they are smaller than minimum_file_size.
  # minimum_file_size:: the minimum size for a file to be eligible for upload.  A file that is not at least this many bytes will not be uploaded.
  # hours_to_run:: optional number of hours to watch the folder, after which this method calls stop, which ends the watch folder process.
  def start(pause_in_seconds, minimum_file_size, hours_to_run=nil)

    # make sure the subdirectories are in place
    [pass_dir, fail_dir].each do |path|
      unless File.exists?(path)
        trace "Creating directory #{path}"
        File.makedirs(path) 
      end
    end

    begin
      test_authentication
    rescue
      trace "Not starting."
      return
    end

    start_time = Time.new
    if hours_to_run.nil?
      end_time = nil
    else
      end_time = start_time + (60 * 60 * hours_to_run)
    end

    if (! end_time.nil?)
      trace("Will stop watching folder at #{end_time}")
    end

    @stopped = false
    sizes = Hash.new

    while not stopped
      
      puts("\n")
      trace("Checking for new/changed files...")

      # files in watch folder sorted with oldest on top
      files = watch_folder_files.sort {|x,y| File.ctime(x) - File.ctime(y)}
      trace("Files in watch folder: #{files.length}")

      # hash of file path -> size      
      new_sizes = array_to_hash(files) {|path| File.size(path)}   
      new_sizes.each do |path, size| 
        trace("#{path} = #{size} bytes")
      end
     
      unchanged_files = files.select {|path| sizes[path].eql? new_sizes[path]}
      unchanged_files.each do |path| 
        trace("Unchanged file #{path} found, size is #{File.size(path)}")
      end
      
      sizes = new_sizes

      if unchanged_files.length > 0
        upload(unchanged_files[0])
      else
        trace("Sleeping #{pause_in_seconds} seconds...")
        sleep(pause_in_seconds)
      end

      # if end_time specified and current time is >= current time, stop.
      if past_end_time?(end_time)
        trace("#{hours_to_run} hours have elapsed.")
        stop
      end
    end

    trace "Done watching folder #{watch_dir}"
  end

  # Stops the watch folder process.
  def stop
    trace("Stopping...")
    @stopped = true
  end

  def video_metadata
    @video_metadata.nil? ? {} : @video_metadata
  end

  protected

  attr_reader :api

  def test_authentication
    begin 
      trace("Testing ingest authentication...")
      api.authenticate_for_ingest('VideoWatchFolder test sig')
      trace("Authentication successful.")
    rescue VideoApiException => e
      trace("Unable to obtain ingest authentication signature: #{e}")
      raise
    end
  end

  def upload(path)
    total_size = File.size path
    trace("Uploading #{path} (#{total_size} bytes)...")
    begin

      total_bytes_written = 0
      old_percent = 0

      api.upload_video(path, contributor, video_metadata) do |bytes_written|
        
        total_bytes_written += bytes_written
        
        old_percent = trace_upload_status(total_bytes_written, total_size, old_percent)
        
      end

      move_finished_file(path, "PASS", pass_dir)

    rescue Exception => e
      trace e
      move_finished_file(path, "FAIL", fail_dir)
    end
  end

  def trace_upload_status(part, total, old_percent)

    percent = (part.fdiv(total) * 100).floor

    # for log file, only output each new percent written and the last update
    if (! log_file_mode) || (! percent.eql?(old_percent)) || (part.eql?(total))
      trace("#{percent}% [#{part} out of #{total} bytes written]", (! log_file_mode))
    end

    if part.eql? total
      print("\n")
      trace("Validating upload on server...")
    end

    percent

  end

  def move_finished_file(path, status, finished_folder)
    trace "#{status}: #{path}."
    trace "Moving to #{finished_folder}."
    begin
      File.move(path, finished_folder)
    rescue => e
      "Failed to move file out of watch folder to subfolder - aborting watch folder process."
      trace(e)
      exit
    end
  end  

  def trace(s, sameline=false)

    if sameline
      print("\r")
    end

    print "[#{Time.new}] #{s}"
    
    unless sameline
      print("\n")
    end

    STDOUT.flush
  end

  def past_end_time?(end_time)
    end_time && (Time.new.to_i >= end_time.to_i)
  end

  def array_to_hash(array)
    hash = Hash.new
    array.each do |x|
      hash[x] = yield x
    end
    hash
  end

  # returns a list of file paths, with the watch folder path prepended to them,
  # of all files in the watch folder (watch_dir).
  # The returned file paths are only for files (not directories)
  # and do not include any file beginning with a dot, like a hidden file.
  def watch_folder_files
    Dir.entries(watch_dir).map {|x| "#{watch_dir}/#{x}"}.select {|x| 
      File.file?(x) && x.match('^\.').nil?
    }
  end

  def fail_dir
    "#{watch_dir}/failed"
  end

  def pass_dir
    "#{watch_dir}/finished"
  end

  def dry_run?
    dry_run_pause > 0
  end  

end

end # VideoApi module
