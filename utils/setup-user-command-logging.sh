#!/bin/bash

# 1. Create logging directory
mkdir -p /var/log/user-commands
chmod 750 /var/log/user-commands
chown root:root /var/log/user-commands

# 2. Install system-wide logging script
cat >/etc/profile.d/user_cmd_logging.sh <<'EOF'
#!/bin/bash

export HISTSIZE=10000
export HISTFILESIZE=10000
export HISTTIMEFORMAT="%F %T "
shopt -s histappend
PROMPT_COMMAND="history -a; $PROMPT_COMMAND"

LOG_DIR="/var/log/user-commands"
USER_LOG="$LOG_DIR/$(whoami).log"

trap 'printf "%s | %s | %s\n" "$(date +%F\ %T)" "$(whoami)" "$(history 1 | sed "s/^[ ]*[0-9]\+[ ]*//")" >> "$USER_LOG"' DEBUG
EOF

chmod 755 /etc/profile.d/user_cmd_logging.sh

# 3. Ensure root also loads the logging script
if ! grep -q "user_cmd_logging.sh" /root/.bashrc; then
    echo 'source /etc/profile.d/user_cmd_logging.sh' >> /root/.bashrc
fi

echo "Setup complete."

