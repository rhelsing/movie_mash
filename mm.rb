require "date"
require "pry"
@interval = 10.0 #no clip will be longer than this.. double if needed
@bpm = 96.0 #same as interval
@offset = 0.732
@frame_shift = 0.93#not yet
@length = 3.51 #in minutes.seconds
@folder = "/Users/ryanhelsing/Movies/Mexico"
@song = "/Users/ryanhelsing/Music/cool_blue.mp3"
@files = Dir["#{@folder}/*"]

#get length of song

# puts @files

#convert length to seconds

#gather info for each file, load into hash and sort
@hash = {}

@files.each do |f|
  length = %x(ffprobe -i #{f} -show_entries format=duration -v quiet -of csv="p=0")
  created = %x(ffprobe -v quiet #{f} -print_format json -show_entries format_tags=creation_time -of csv="p=0")
  @hash[f] = {length: length.gsub("\n", "").strip.to_f, date: DateTime.parse("#{created.gsub(" ", "T")}+0:00")}
end

#go through hash and determine optimal length of each video based on interval - round down to nearest 1/(2^n) of @interval
@hash.each do |k, v|
  temp_strip_length = @interval
  power = 0
  while temp_strip_length > v[:length]
    power += 1
    temp_strip_length = @interval*(1/(2**power.to_f))
  end
  v[:split_length] = temp_strip_length
end

@hash.each{|r| p r }

#1. sort by date

#2. output all clips to new folder sliced
# ffmpeg -i #{in_clip} -ss 0.00 -t #{slice_interval} #{incrementing string} #aa, ab, ac
@hash.each do |k, v|
  puts %x(ffmpeg -i #{k} -ss 0.00 -t #{v[:split_length]} /Users/ryanhelsing/Movies/mm/temp_#{rand(20000)}.mp4)
end

#3. merge all clips to new file from folder
