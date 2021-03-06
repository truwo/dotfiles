if command -v subl &> /dev/null; then
  q () {
    # easy access to SublimeText
    if [ $# -eq 0 ]; then
      subl .;
    else
      subl "$@";
    fi;
  }
fi

if [ ! "$SSH_TTY" ] && command -v micro &> /dev/null; then
  EDITOR='micro'; export EDITOR;
  LESSEDIT='micro %f'; export LESSEDIT;
  VISUAL="$EDITOR"; export VISUAL;
  m () { micro "$@" ;}
else
  EDITOR=$(type micro nano pico &> /dev/null | sed 's/ .*$//;q')
  export EDITOR;
  VISUAL="$EDITOR"; export VISUAL;
fi