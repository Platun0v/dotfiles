function posix-source -d 'Source env vars from file'
  for i in (cat $argv)
    if test (count (echo $i | tr -d '[:space:]')) -eq 0
      continue
    end

    set arr (echo $i | cut -d= -f1) (echo $i | cut -d= -f2-)
    
    # Check if arr[1] starts with hashtag
    if test (string match -r '^#' $arr[1])
      continue
    end

    set -gx $arr[1] $arr[2]
  end
end
