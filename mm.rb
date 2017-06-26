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
@output = "/Users/ryanhelsing/Movies/mm"

#get length of song

# puts @files

#convert length to seconds

#gather info for each file, load into hash and sort
@hash = {}

puts "analyzing"

@files.each do |f|
  length = %x(ffprobe -i #{f} -show_entries format=duration -v quiet -of csv="p=0")
  created = %x(ffprobe -v quiet #{f} -print_format json -show_entries format_tags=creation_time -of csv="p=0")
  @hash[f] = {length: length.gsub("\n", "").strip.to_f, date: DateTime.parse("#{created.gsub(" ", "T")}+0:00")}
  print "."
end
puts ""

#go through hash and determine optimal length of each video based on interval - round down to nearest 1/(2^n) of @interval
first = true

puts "measuring"

@hash.each do |k, v|
  temp_strip_length = @interval
  power = 0
  while temp_strip_length > v[:length]
    power += 1
    temp_strip_length = @interval*(1/(2**power.to_f))
  end

  if first
    v[:split_length] = temp_strip_length+@offset
  else
    v[:split_length] = temp_strip_length
  end
  first = false
  print "."
end

puts ""

@hash.each{|v| p "Found: #{v[0]}: #{v[1][:split_length]}" }


#1. sort by date
@hash.sort_by { |k, v| v[:date] }

#2. output all clips to new folder sliced
# ffmpeg -i #{in_clip} -ss 0.00 -t #{slice_interval} #{incrementing string} #aa, ab, ac
puts "slicing"
i = 0
@hash.each do |k, v|
  %x(ffmpeg -i #{k} -c copy -ss 0.00 -t #{v[:split_length]} #{@output}/temp_#{i}.mp4)
  print "."
  i += 1
end

#3. merge all clips to new file from folder
@output_files = Dir["#{@output}/*"] #write to file inputs.txt - file 'part1.mp4'

@hash_output = {}

puts "indexing"
@output_files.each do |f|
  t_index = f.split("temp_")[1].split(".")[0].to_i
  @hash_output[f] = {index: t_index}
  print "."
end
puts ""

@hash_output.sort_by { |k, v| v[:index] }

puts "merging"
File.open("#{@output}/input.txt", "w+") do |f|
  @hash_output.each { |k, v| f.puts("file '#{k}'") }
end

%x(ffmpeg -f concat -i #{@output}/input.txt -c copy #{@output}/output.mp4)

#compare length of song vs vid to output which is longer and by how much
puts "adding audio"
%x(ffmpeg -i #{@output}/output.mp4 -i #{@song} -c:v copy -map 0:v:0 -map 1:a:0 -shortest #{@output}/output_final.mp4)

puts "cleanup"
%x(rm #{@output}/output.mp4)
%x(rm #{@output}/temp_*)
%x(rm #{@output}/*.txt)

puts "done"
#cleanup
