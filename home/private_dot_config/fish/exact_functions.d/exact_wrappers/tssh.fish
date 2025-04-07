function tssh --description 'alias tssh=TERM=xterm tsh ssh'
  TERM=xterm /usr/local/bin/tsh ssh $argv;
end
