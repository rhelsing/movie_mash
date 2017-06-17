require "date"
@interval = 4.0
@offset = 0.0
@folder = "/Users/ryanhelsing/Movies/Mexico"
@files = Dir["#{@folder}/*"]

#get length of song

# puts @files

#gather info for each file, load into hash and sort
@hash = {}

@files.each do |f|
  length = %x(ffprobe -i #{f} -show_entries format=duration -v quiet -of csv="p=0")
  created = %x(ffprobe -v quiet #{f} -print_format json -show_entries format_tags=creation_time -of csv="p=0")
  @hash[f] = {length: length.gsub("\n", "").strip, date: DateTime.parse("#{created.gsub(" ", "T")}+0:00")}
end

#go through hash and determine optimal length of each video based on interval
puts @hash
