#Movie Mash

* Combine Short clips (2-8 seconds ideal) w/ ffmpeg, with a time offset and interval to sync them up, remove audio

Usage:

```
mash [location of mp3] [directory path to video files] [interval in s/ms] [initial offset in s/ms]
```

* sub tasks:

  - get the length of a video in seconds/ms
    - ffprobe -i IMG_0509.MOV -show_entries format=duration -v quiet -of csv="p=0"
    - 15.2222
  - get the creation date of a video
    - ffprobe -v quiet IMG_0509.MOV -print_format json -show_entries format_tags=creation_time -of csv="p=0"

  - determine length ranges of videos from interval

  - for each video, determine optimal length

  - stitch subvideos together in order, place song and render, first vid should have offset added to it
    - slice a video

ffmpeg -i input.mp4 -ss 00:02:00 -t 00:07:28 part1.mp4
ffmpeg -i input.mp4 -ss 00:10:50 -t 00:51:30 part2.mp4
ffmpeg -i input.mp4 -ss 01:19:00 -t 00:08:05 part3.mp4

    - stitch two videos

inputs.txt
file 'part1.mp4'
file 'part2.mp4'
file 'part3.mp4'

ffmpeg -f concat -i inputs.txt -c copy output.mp4

    - combine video with song


* later:
  - recognize tempo and align
  - slow down to 93% of speed if 60fps
  - color grade s curve

