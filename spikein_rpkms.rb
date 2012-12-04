#!/usr/bin/env ruby

# runs simple_rpkms on a set of sam files

SAMTOOLS_BIN = 'samtools'
RPKM_BIN = File.join(File.dirname(__FILE__), "simple_rpkms.rb")

sam_input_dir = ARGV[0]

sam_filenames = Dir.glob(File.join(sam_input_dir, "*.sam"))

puts "found #{sam_filenames.size} sam files"

# first lets run samtools pileup

output_dir = File.join(File.dirname(__FILE__), "spikein_rpkms")

system("mkdir -p #{output_dir}")

sam_filenames.each do |sam_filename|
  # output_filename = File.join(output_dir, File.basename(sam_filename, File.extname(sam_filename)) + ".rpkm.txt")
  command = "#{RPKM_BIN} #{sam_filename} #{output_dir}"

  puts command
  system(command)
end
