#!/usr/bin/env ruby

$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'sample_report'

BOWTIE_EBT = File.expand_path(File.join(File.dirname(__FILE__), "data", "ERCC92"))
BOWTIE = "bowtie"
SAMTOOLS = "samtools"
RPKM_BIN = File.join(File.dirname(__FILE__), "simple_rpkms.rb")
RANGE_PLOT_BIN = File.join(File.dirname(__FILE__), "spikein_dynamic_range.R")

starting_dir_name = ARGV[0]
output_dir_name = File.join(starting_dir_name, "ercc_spikeins")

fastq_filenames = Dir.glob(File.expand_path(File.join(starting_dir_name, "*.fastq.gz")))
sample_report_file = File.expand_path(File.join(starting_dir_name, "Sample_Report.csv"))
fc_id = File.basename(starting_dir_name)

sample_report = SampleReport.new(sample_report_file)

# reject undetermined
fastq_filenames.reject! {|ff| ff =~ /Undetermined/}

fastq_filenames.each do |fastq_filename|
  puts fastq_filename
  fastq_data = sample_report.data_for(fastq_filename)
  #puts fastq_data.inspect

  sample_name = fastq_data["sample name"]

  sam_filename = File.expand_path(File.join(output_dir_name, "spikein_align", sample_name + ".sam"))
  puts sam_filename
  system("mkdir -p #{File.dirname(sam_filename)}")

  # unaligned_filename = File.expand_path(File.join(output_dir_name, "spikein_align", "unaligned.sam"))
  # system("rm -f #{unaligned_filename}")

  command = "zcat #{fastq_filename} | #{BOWTIE} -S -p 8 #{BOWTIE_EBT} - | #{SAMTOOLS} view -S -h -F 0x4 - > #{sam_filename}"
  puts command
  system(command)

  rpkm_filename = File.expand_path(File.join(output_dir_name, "spikein_rpkm", sample_name + ".rpkm.txt"))

  system("mkdir -p #{File.dirname(rpkm_filename)}")
  command = "#{RPKM_BIN} #{sam_filename} #{rpkm_filename}"
  puts command
  system(command)

  expected_filename = File.join(File.dirname(__FILE__), "data", "expected.txt")
  command = "R --slave --args #{sample_name} #{rpkm_filename} #{output_dir_name} #{expected_filename} < #{RANGE_PLOT_BIN}"
  puts command
  system(command)
end
