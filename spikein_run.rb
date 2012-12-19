#!/usr/bin/env ruby

require 'optparse'
require 'yaml'

$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'sample_report'

RPKM_BIN = File.join(File.dirname(__FILE__), "simple_rpkms.rb")
RANGE_PLOT_BIN = File.join(File.dirname(__FILE__), "spikein_dynamic_range.R")


options = {}
options[:data] = File.expand_path(File.join(File.dirname(__FILE__), "data"))
options[:bowtie] = "bowtie"
options[:samtools] = "samtools"
options[:zcat] = "zcat"
options[:extension] = ".fastq.gz"

opts = OptionParser.new do |o|
  o.banner = "Usage: spikein_run.rb [fastq dir] [options]"
  o.on('-u', '--undetermined', 'process the undetermined fastq files as well') {|b| options[:undetermined] = true}
  o.on('-d', '--data /data/dir/path', String, "Specify data location. Default: #{options[:data]}") {|b| options[:data] = b}
  o.on( '--bowtie /path/to/bowtie', String, "Specify bowtie path. Default: #{options[:bowtie]}") {|b| options[:bowtie] = b}
  o.on( '--samtools /path/to/samtools', String, "Specify samtools path. Default: #{options[:samtools]}") {|b| options[:samtools] = b}
  o.on( '--extension EXTENSION', String, "Specify fastq extension. Default: #{options[:extension]}") {|b| options[:extension] = b}
  o.on( '--zcat /path/to/zcat', String, "Specify zcat path. Default: #{options[:zcat]}") {|b| options[:zcat] = b}
  o.on('-y', '--yaml YAML_FILE', String, "Yaml configuration file that can be used to load options.","Command line options will trump yaml options") {|b| options.merge!(Hash[YAML::load(open(b)).map {|k,v| [k.to_sym, v]}]) }
  o.on('-h', '--help', 'Displays help screen, then exits') {puts o; exit}
end

opts.parse!

starting_dir_name = ARGV[0]

def test_options options
  valid = true
  puts options.inspect
  if !File.exists?(options[:data])
    puts "ERROR: cannot find data directory."
    puts "#{options[:data]} does not exist"
    valid = false
  end
  valid
end

valid = test_options(options)
if !valid
  puts " exiting"
  exit(1)
end

output_dir_name = File.join(starting_dir_name, "ercc_spikeins")
fastq_filenames = Dir.glob(File.expand_path(File.join(starting_dir_name, "*#{options[:extension]}")))
sample_report_file = File.expand_path(File.join(starting_dir_name, "Sample_Report.csv"))
fc_id = File.basename(starting_dir_name)

sample_report = SampleReport.new(sample_report_file)

# reject undetermined
fastq_filenames.reject! {|ff| ff =~ /Undetermined/} unless options[:undetermined]

bowtie_index = File.join(options[:data], "ERCC92")

puts "analyzing #{fastq_filenames.size} fastq files"
fastq_filenames.each do |fastq_filename|
  puts fastq_filename
  fastq_data = sample_report.data_for(fastq_filename)
  if !fastq_data
    puts "ERROR: no SampleReport data found"
    puts "fastq file: #{fastq_filename}"
    next
  end
  #puts fastq_data.inspect

  sample_name = fastq_data["sample name"]

  output_bam_filename = File.expand_path(File.join(output_dir_name, "spikein_align", sample_name + ".bam"))
  puts output_bam_filename
  system("mkdir -p #{File.dirname(output_bam_filename)}")

  # this will open a fastq file, align with bowtie,
  # use samtools view to keep only aligned reads, and redirect to bam file
  command = "#{options[:zcat]} -f #{fastq_filename} | #{options[:bowtie]} -S -p 8 #{bowtie_index} - | #{options[:samtools]} view -S -h -b -F 0x4 - > #{output_bam_filename}"
  puts command
  system(command)

  rpkm_filename = File.expand_path(File.join(output_dir_name, "spikein_rpkm", sample_name + ".rpkm.txt"))

  system("mkdir -p #{File.dirname(rpkm_filename)}")
  command = "#{RPKM_BIN} #{output_bam_filename} #{rpkm_filename}"
  puts command
  system(command)

  expected_filename = File.join(File.dirname(__FILE__), "data", "expected.txt")
  command = "R --slave --args #{sample_name} #{rpkm_filename} #{output_dir_name} #{expected_filename} < #{RANGE_PLOT_BIN}"
  puts command
  system(command)
end
