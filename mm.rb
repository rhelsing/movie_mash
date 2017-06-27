require "date"
require "pry"
@interval = 10.0 #no clip will be longer than this.. double if needed
@bpm = 96.0 #same as interval
@offset = 1.250
@frame_shift = 0.93#not yet
@length = "3:51" #in minutes.seconds
@folder = "/Users/ryanhelsing/Movies/Mexico"
@song = "/Users/ryanhelsing/Music/cool_blue.mp3"
@files = Dir["#{@folder}/*"]
@output = "/Users/ryanhelsing/Movies/mm"

#get length of song

# puts @files

#fix all rotation at beginning.. once, in place?

#convert length to seconds

#gather info for each file, load into hash and sort
@hash = {}

puts "analyzing"

@files.each do |f|
  length = %x(ffprobe -i #{f} -show_entries format=duration -v quiet -of csv="p=0")
  created = %x(ffprobe -v quiet #{f} -print_format json -show_entries format_tags=creation_time -of csv="p=0")
  rotation = %x(ffprobe #{f} 2>&1 | grep rotate)
  if rotation.strip != ""
    #there is rotation
    rotate = rotation.split(":")[1].strip
  else
    rotate = false
  end
  @hash[f] = {length: length.gsub("\n", "").strip.to_f, date: DateTime.parse("#{created.gsub(" ", "T")}+0:00"), rotate: rotate}
  print "."
end
puts ""

#1. sort by date
@hash = @hash.sort_by { |k, v| v[:date] }

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

#2. output all clips to new folder sliced
# ffmpeg -i #{in_clip} -ss 0.00 -t #{slice_interval} #{incrementing string} #aa, ab, ac
puts "slicing"
i = 0
@hash.each do |k, v|
  if v[:rotate]
    # Note: All inputs must have the same stream types (same formats, same time base, etc.).
    # ffmpeg -i <input_filename> -vf "transpose=<dir>" -metadata:s:v "rotate=0" -r 60 -vcodec libx264 -crf 18 -acodec copy <output_filename>
    # Stream #0:0(und): Video: h264 (High) (avc1 / 0x31637661), yuv420p(tv, bt709), 1920x1080, 23735 kb/s, 60 fps, 60 tbr, 600 tbn, 1200 tbc (default)
    # %x(ffmpeg -i #{k} -ss 0.00 -t #{v[:split_length]} -r 60 -vcodec libx264 -crf 18 -acodec copy #{@output}/temp_#{i}.mp4) #need a faster way :( - autorotate w/ metadata loses on concat
    %x(ffmpeg -i #{k} -c copy -ss 0.00 -t #{v[:split_length]} #{@output}/temp_#{i}.mp4)
  else
    %x(ffmpeg -i #{k} -c copy -ss 0.00 -t #{v[:split_length]} #{@output}/temp_#{i}.mp4)
  end
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

@hash_output = @hash_output.sort_by { |k, v| v[:index] }

puts "merging"
File.open("#{@output}/input.txt", "w+") do |f|
  @hash_output.each { |k, v| f.puts("file '#{k.gsub("#{@output}/", "")}'") }
end

%x(ffmpeg -f concat -i #{@output}/input.txt -c copy #{@output}/output.mp4)
# binding.pry
# %x(ffmpeg -i "concat:#{@hash_output.map{|x| x[0]}.join("|")}" -c copy #{@output}/output.mp4)

#compare length of song vs vid to output which is longer and by how much
vid_length = @hash.map{|x| x[1][:split_length] }.reduce(:+)
song_length = @length.split(":")[0].to_i*60+@length.split(":")[1].to_i

if vid_length > song_length
  puts "WARNING: ------> video is longer than song by #{vid_length-song_length} seconds"
else
  puts "WARNING: ------> song is longer than video by #{song_length-vid_length} seconds"
end

puts "adding audio"
%x(ffmpeg -i #{@output}/output.mp4 -i #{@song} -c:v copy -map 0:v:0 -map 1:a:0 -shortest #{@output}/output_final.mp4)

puts "cleanup"
# %x(rm #{@output}/output.mp4)
# %x(rm #{@output}/temp_*)
# %x(rm #{@output}/*.txt)

puts "done"
#cleanup
