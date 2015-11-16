require 'exiftool'
require 'fileutils'
require 'rainbow/ext/string'
require 'ruby-progressbar'
require 'digest/md5'

def stash(p, dst_dir, file)
  begin
    outdir = File.join dst_dir, 'unsorted'
    FileUtils::mkdir_p outdir
    dst_path = File.join(outdir, File.basename(file))
    FileUtils::mv file, outdir
  rescue
    p.log "ERROR: Unable to stash #{file} in #{dst_dir}".color(:red)
  end
end

VALID_EXTENSIONS = %w{.jpg .tiff .tif .nef .raf .dng .mov .mp4 .rw2}
MEGABYTE = 1024 * 1024

src_dir = File.expand_path ARGV[0]
dst_dir = File.expand_path ARGV[1]

Dir.chdir src_dir

puts "Finding files in #{src_dir}..."

files = Dir.glob("**/*")

p = ProgressBar.create(title: 'Organizing', total: files.count, format: '%t %c/%C %B %e')

files.each do |file|
  unless File.file?(file) && VALID_EXTENSIONS.include?(File.extname(file).downcase)
    p.increment
    next
  end

  filename = File.basename(file)

  p.log file.color(:blue)

  begin
    e = Exiftool.new(file)
    r = e.to_hash
  rescue ArgumentError
    p.log "ERROR: Exception thrown opening #{filename}, stashing!".color(:red)
    stash(p, dst_dir, file)
    p.increment
    next
  end

  unless r[:date_time_original_civil]
    p.log 'ERROR: date_time_original_civil not found in EXIF data, stashing!'.color(:red)
    stash(p, dst_dir, file)
    p.increment
    next
  end

  dt = r[:date_time_original_civil]

  outdir = File.join dst_dir, dt.year.to_s, dt.month.to_s, dt.day.to_s
  FileUtils::mkdir_p outdir

  dst_path = File.join(outdir, File.basename(file))

  if File.file?(dst_path)
    p.log 'File exists. Hashing...'

    src_hash = Digest::MD5.hexdigest(File.read(file, MEGABYTE))
    dst_hash = Digest::MD5.hexdigest(File.read(dst_path, MEGABYTE))

    if src_hash == dst_hash
      p.log 'Files are identical, skipping!'
      p.increment
      next
    else
      puts "Hashes are different: #{src_hash} vs #{dst_hash}"
    end

    src_w = r[:image_width]
    src_h = r[:image_height]

    dst_e = Exiftool.new(dst_path)
    dst_r = dst_e.to_hash

    dst_w = dst_r[:image_width]
    dst_h = dst_r[:image_height]

    src_fsize = File.size(file).to_f / 2**20
    dst_fsize = File.size(dst_path).to_f / 2**20

    if src_fsize > dst_fsize || (src_w * src_h) > (dst_w * dst_h)
      p.log "File #{File.basename(dst_path)} exists but is smaller (#{src_fsize} > #{dst_fsize} || #{(src_w * src_h) / 1000000.0} MP > #{(dst_w * dst_h) / 1000000.0} MP), overwriting"
      FileUtils.rm dst_path
    else
      p.log "File #{File.basename(dst_path)} exists and is larger or equal in size (#{dst_fsize} >= #{src_fsize} || #{(dst_w * dst_h) / 1000000.0} MP >= #{(src_w * src_h) / 1000000.0} MP), skipping."
      p.increment
      next
    end
  end

  begin
    FileUtils::mv file, outdir
    p.log "Moved #{file} to #{dst_path}".color(:green)
  rescue
    p.log "ERROR: Unable to move #{file} to #{dst_path}".color(:red)
  end

  p.increment
end
