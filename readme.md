#Movie Mash

* Combine Short clips (2-8 seconds ideal) w/ ffmpeg, with a time offset and interval to sync them up, remove audio

Usage:

```
set variables at top of mm.rb
have ffmpeg 3.3.2
ruby mm.rb

eventually:
mash [location of mp3] [directory path to video files] [interval in s/ms] [initial offset in s/ms]
```

* later:
  - recognize tempo and align
  - slow down to 93% of speed if 60fps
  - color grade s curve - use photoshop scheme

