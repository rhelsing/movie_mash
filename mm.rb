require "date"
@folder = "/Users/ryanhelsing/Movies/Mexico"
@files = Dir["#{@folder}/*"]

# puts @files

#gather info for each file, load into hash and sort
@hash = {}

@files.each do |f|
  length = %x(ffprobe -i #{f} -show_entries format=duration -v quiet -of csv="p=0")
  created = %x(ffprobe -v quiet #{f} -print_format json -show_entries format_tags=creation_time -of csv="p=0")
  @hash[f] = {length: length.gsub("\n", "").strip, date: DateTime.parse("#{created.gsub(" ", "T")}+0:00")}
end

puts @hash
