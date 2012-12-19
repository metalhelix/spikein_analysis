
class SampleReport
  attr_accessor :samples

  def initialize sample_report_filename
    if File.exists?(sample_report_filename)
      @samples = parse(sample_report_filename)
    else
      puts "ERROR: no SampleReport.csv found"
      puts "filename: #{sample_report_filename}"
    end
  end

  def parse(filename)
    lines = File.readlines(filename)
    header = lines.shift.chomp.split(",")
    samples = []
    lines.each do |line|
      data = line.chomp.split(",")
      samples << Hash[header.zip(data)]
    end
    samples
  end

  # def data_for(sequence_filename)
  #   File.basename(sequence_filename) =~ /s_(\\d+)_(\\d+)_([ATCG]*)\\.fastq.gz/
  #   @samples.select {|s| s["lane"] == $1 and s["illumina index"] == $3}[0]
  # end
  def data_for(sequence_filename)
    basename = File.basename(sequence_filename)
    @samples.select {|s| s["output"] == basename}[0]
  end
end
