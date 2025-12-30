function tssh --description 'alias tssh=TERM=xterm tsh ssh'
  TERM=xterm /opt/homebrew/bin/tsh ssh $argv;
end
