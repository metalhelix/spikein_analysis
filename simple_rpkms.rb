#!/usr/bin/env ruby

require 'open3'

# i want to be able to read bam files
# so this tool currently requires samtools
# to run. In the future - we could remove this
# dependency by allowing the data to be pipped in
# so it could come from a simple text file if needed.
SAMTOOLS = "samtools"

input_filename = ARGV[0]

output_filename = ARGV[1]

if !output_filename
  puts "ERROR: provide sam file and output filename"
  exit(1)
end

system("mkdir -p #{File.dirname(output_filename)}")

total = 0
read_length = 0

counts = Hash.new {|h,k| h[k] = 0}
sq_lengths = {}

# command will open bam or sam file
command = "#{SAMTOOLS} view -h"
filetype = File.extname(input_filename)
if filetype == ".sam"
  command += " -S"
end
command += " #{input_filename}"

# Open3.popen3 opens a stream and allows
# us to read each line of the stream
Open3.popen3(command) do |i,o,e,t|
  while line = o.gets
    if line =~ /^@SQ/
      fields = line.split("\t")
      name = fields[1].gsub("SN:","")
      length = fields[2].gsub("LN:", "").to_i
      sq_lengths[name] = length
    end
    next if line =~ /^@/
    fields = line.split("\t")
    # unaligned reads are ignored
    next if fields[2] == "*"

    counts[fields[2]] += 1
    total += 1

    if total < 10000
      length = fields[9].size
      if read_length < length
        read_length = length
      end
    end
  end
end

sorted = counts.to_a.sort {|a,b| b[1] <=> a[1]}

output = []
sorted.each do |s|
  # s << s[1].to_f / total.to_f
  rpkm = (1E9 * s[1].to_f) / total.to_f / sq_lengths[s[0]].to_f
  # rpkm = s[1].to_f / (total.to_f * 1000000.0) / (sq_lengths[s[0]].to_f * 1000.0)
  output << [s[0], sq_lengths[s[0]], s[1], total, rpkm]
end

File.open(output_filename, 'w') do |file|

  header = ["name", "length", "reads", "all_reads", "rpkm"]
  file.puts header.join("\t")

  output.each do |s|
    file.puts s.join("\t")
  end
end


