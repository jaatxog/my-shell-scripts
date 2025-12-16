============================================================
USER COMMAND LOGGING SETUP (BASH – ALL USERS, AUTO-HARDENED)
============================================================

PURPOSE
-------
Log every interactive Bash command for all users into:
  /var/log/user-commands/<user>.log

• One line per command
• No duplicates
• Works over SSH
• Automatic for new users
• Logs are append-only
• Readable by root

------------------------------------------------------------
REQUIREMENTS
------------------------------------------------------------
- Linux server
- Bash as login shell
- Root access
- ext4 / xfs filesystem (for chattr)

------------------------------------------------------------
STEP 1: CREATE GROUP AND LOG DIRECTORY
------------------------------------------------------------

Run as root:

  groupadd usercmdlog
  mkdir -p /var/log/user-commands

  chown root:usercmdlog /var/log/user-commands
  chmod 2770 /var/log/user-commands

------------------------------------------------------------
STEP 2: AUTO-ADD NEW USERS TO LOGGING GROUP
------------------------------------------------------------

Edit:

  /etc/login.defs

Add this line (if not present):

  EXTRA_GROUPS usercmdlog

------------------------------------------------------------
STEP 3: INSTALL GLOBAL LOGGING SCRIPT
------------------------------------------------------------

Create file:

  /etc/profile.d/user_cmd_logging.sh

Paste EXACTLY this:

------------------------------------------------------------
#!/bin/bash

# Prevent double loading
[[ -n "$USER_CMD_LOGGING_LOADED" ]] && return
export USER_CMD_LOGGING_LOADED=1

# Only interactive shells
[[ $- != *i* ]] && return

export HISTSIZE=10000
export HISTFILESIZE=10000
export HISTTIMEFORMAT=
shopt -s histappend

LOG_DIR="/var/log/user-commands"
USER_LOG="$LOG_DIR/$(whoami).log"

log_last_command() {
    local cmd
    cmd=$(history 1 | sed 's/^[ ]*[0-9]\+[ ]*//')
    printf "%s | %s | %s\n" "$(date '+%F %T')" "$(whoami)" "$cmd" >> "$USER_LOG"
}

PROMPT_COMMAND="history -a; log_last_command"
------------------------------------------------------------

Set permissions:

  chmod 755 /etc/profile.d/user_cmd_logging.sh

------------------------------------------------------------
STEP 4: REMOVE MANUAL SOURCING (CRITICAL)
------------------------------------------------------------

Ensure this script is NOT manually sourced.

Check:

  grep -R user_cmd_logging /root/.bashrc /root/.bash_profile

If found, remove the line.

------------------------------------------------------------
STEP 5: AUTO-HARDEN LOG FILES (SYSTEMD)
------------------------------------------------------------

Create path unit:

  /etc/systemd/system/usercmdlog.path

------------------------------------------------------------
[Unit]
Description=Watch user command logs

[Path]
PathChanged=/var/log/user-commands

[Install]
WantedBy=multi-user.target
------------------------------------------------------------

Create service unit:

  /etc/systemd/system/usercmdlog.service

------------------------------------------------------------
[Unit]
Description=Harden user command logs

[Service]
Type=oneshot
ExecStart=/usr/bin/chattr +a /var/log/user-commands/*.log
------------------------------------------------------------

Enable:

  systemctl daemon-reload
  systemctl enable --now usercmdlog.path

------------------------------------------------------------
STEP 6: RE-LOGIN
------------------------------------------------------------

All users must log out and log back in.

------------------------------------------------------------
STEP 7: VERIFY
------------------------------------------------------------

As any user:

  cd /tmp
  ls

As root:

  cat /var/log/user-commands/<user>.log

Expected format:

  YYYY-MM-DD HH:MM:SS | <user> | command

------------------------------------------------------------
WHAT THIS LOGS
------------------------------------------------------------

✔ Interactive Bash commands
✔ SSH sessions
✔ Root and all users
✔ New users automatically

------------------------------------------------------------
WHAT THIS DOES NOT LOG
------------------------------------------------------------

✘ Non-interactive scripts
✘ bash --noprofile --norc
✘ Other shells (zsh, sh)

------------------------------------------------------------
SECURITY NOTE
------------------------------------------------------------

This is best-effort Bash logging.
It can be bypassed by a determined user.

For non-bypassable auditing, use auditd.

============================================================
END OF DOCUMENT
============================================================



