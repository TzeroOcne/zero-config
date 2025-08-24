BANNER_ACTIVE=0

activateBanner() {
  BANNER_ACTIVE=1
}

deactivateBanner() {
  BANNER_ACTIVE=0
}

toggleBanner() {
  ((BANNER_ACTIVE = 1 - BANNER_ACTIVE))
}

# https://patorjk.com/software/taag/#p=display&f=ANSI%20Shadow&t=done
DONE_BANNER="\x1b[1;32m
██████╗  ██████╗ ███╗   ██╗███████╗
██╔══██╗██╔═══██╗████╗  ██║██╔════╝
██║  ██║██║   ██║██╔██╗ ██║█████╗  
██║  ██║██║   ██║██║╚██╗██║██╔══╝  
██████╔╝╚██████╔╝██║ ╚████║███████╗
╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚══════╝
                                   "
# https://patorjk.com/software/taag/#p=display&f=ANSI%20Shadow&t=error
ERROR_BANNER="\033[1;31m
███████╗██████╗ ██████╗  ██████╗ ██████╗ 
██╔════╝██╔══██╗██╔══██╗██╔═══██╗██╔══██╗
█████╗  ██████╔╝██████╔╝██║   ██║██████╔╝
██╔══╝  ██╔══██╗██╔══██╗██║   ██║██╔══██╗
███████╗██║  ██║██║  ██║╚██████╔╝██║  ██║
╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝
                                         "

bannerDone() {
  if [[ $BANNER_ACTIVE == 1 ]]; then
    echo $DONE_BANNER
  fi
}

bannerError() {
  if [[ $BANNER_ACTIVE == 1 ]]; then
    echo $ERROR_BANNER
  fi
}
