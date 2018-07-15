require "date"
require "pry"
@interval = 9 #no clip will be longer than this.. double if needed
# @bpm = 94.0 #same as interval
@offset = 0
# @frame_shift = 0.93#not yet
@length = "7:20" #in minutes.seconds
@folder = "/Users/ryanhelsing/Movies/Chicago2018/raw" #E: point to all the movie files
@song = "/Users/ryanhelsing/Movies/Chicago2018/output.mp3"
@files = Dir["#{@folder}/*"]
@output = "/Users/ryanhelsing/Movies/Chicago2018/out" #E: CREATE THIS OUTPUT FOLDER COULD BE MEXIXO_OUTPUT
@render_final = true #WHEN TRUE, it will be slower but correct rotations

@overrides = "/Users/ryanhelsing/Movies/Chicago2018/override.txt" #set to nil if no overrides
# @overrides = nil

@constant_length = false #all videos will be the length of the interval

#NEED TO EDIT VIDS BEFORE EXPORTING FROM PHONE>> CROP OUT SUCKY PARTS

#get length of song

# puts @files

#fix all rotation at beginning.. once, in place?

#convert length to seconds

#gather info for each file, load into hash and sort
@hash = {}

puts "analyzing"

@files.each do |f|
  length = %x(ffprobe -i #{f} -show_entries format=duration -v quiet -of csv="p=0")
  # created = %x(ffprobe -v quiet #{f} -print_format json -show_entries format_tags=creation_time -of csv="p=0")
  created = %x(ffprobe -v quiet #{f} -print_format json -show_entries format_tags=com.apple.quicktime.creationdate -of csv="p=0")
  if !@constant_length || length.gsub("\n", "").strip.to_f >= @interval
    @hash[f] = {length: length.gsub("\n", "").strip.to_f, date: DateTime.parse("#{created.gsub(" ", "T")}+0:00")}
    print "."
  end
end

#1. sort by date
@hash = @hash.sort_by { |k, v| v[:date] }


@o_hash = {}

if @overrides != nil
  puts ""
  puts "overrides"
  #read each line into hash by name
  File.readlines(@overrides).each do |line|
    @o_hash[line.split(":")[0].strip] = {start_time: line.split(":")[1].strip.split("-")[0].strip.to_f, end_time: line.split(":")[1].strip.split("-")[1].strip.to_f}
  end
#   IMG_453: 2-6
# IMG_473: 10-14
end

#go through hash and determine optimal length of each video based on interval - round down to nearest 1/(2^n) of @interval
first = true
puts ""

puts "measuring"

@hash.each do |k, v|

  if @overrides != nil && @o_hash.count > 0 && @o_hash[k.gsub("#{@folder}/","")] != nil
    v[:start_time] = @o_hash[k.gsub("#{@folder}/","")][:start_time]
    v[:split_length] = @o_hash[k.gsub("#{@folder}/","")][:end_time]-@o_hash[k.gsub("#{@folder}/","")][:start_time]
  else
    temp_strip_length = @interval
    power = 0
    while temp_strip_length > v[:length]
      power += 1
      temp_strip_length = @interval*(1/(2**power.to_f))
    end
    v[:start_time] = 0.0
    v[:split_length] = temp_strip_length
  end

  if first
    v[:split_length] = v[:split_length]+@offset
  end
  first = false
  print "."
end

puts ""

# @hash.each{|v| p "Found: #{v[0]}: #{v[1][:split_length]}" }

#2. output all clips to new folder sliced
# ffmpeg -i #{in_clip} -ss 0.00 -t #{slice_interval} #{incrementing string} #aa, ab, ac
puts "slicing"
i = 0
@hash.each do |k, v|
  if @render_final
    # ffmpeg -i b.mp4 -ss 0.00 -t 2.5 -r 60 -vcodec libx264 -crf 20 -acodec copy test2.mp4
    #render all using same settings to concat
    %x(ffmpeg -i #{k} -v quiet -ss #{v[:start_time]} -t #{v[:split_length]} -r 60 -vcodec libx264 -crf 20 -acodec copy #{@output}/temp_#{i}.mp4)
  else
    #copy method.. some will be upside down, but fast for testing
    %x(ffmpeg -i #{k} -v quiet -c copy -ss #{v[:start_time]} -t #{v[:split_length]} #{@output}/temp_#{i}.mp4)
  end
  print "."
  i += 1
end

#3. merge all clips to new file from folder
@output_files = Dir["#{@output}/*"] #write to file inputs.txt - file 'part1.mp4'

@hash_output = {}

puts ""
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

%x(ffmpeg -f concat -i #{@output}/input.txt  -v quiet -c copy #{@output}/output.mp4)
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
%x(ffmpeg -i #{@output}/output.mp4 -i #{@song}  -v quiet -c:v copy -map 0:v:0 -map 1:a:0 -shortest #{@output}/output_final.mp4)

puts "cleanup"
# %x(rm #{@output}/output.mp4)
%x(rm #{@output}/temp_*)
%x(rm #{@output}/*.txt)

puts "done"
#cleanup
