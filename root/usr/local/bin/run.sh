#!/bin/bash

# SIGTERM-handler
term_handler() {
  if [ $pid -ne 0 ]; then
    kill -SIGTERM "$pid"
    wait "$pid"
  fi
  exit 143; # 128 + 15 -- SIGTERM
}

# fix permissions
chown -R sitebar:sitebar /config

# run application
echo "Starting supervisord..."
exec /usr/bin/supervisord -c /etc/supervisord.conf
