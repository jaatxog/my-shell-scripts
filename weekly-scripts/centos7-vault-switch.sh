#!/bin/bash
#
# Script Name : centos7-vault-switch.sh
# Description : Switch CentOS 7 repos to vault.centos.org after EOL
# Author      : OG
# Run As      : root
#

set -euo pipefail

info() { echo -e "[INFO] $*"; }
error() { echo -e "[ERROR] $*" >&2; }

# Verify CentOS 7
version=$(rpm -q --qf "%{VERSION}" centos-release 2>/dev/null || true)

if [[ "$version" != "7" ]]; then
    error "This script is only for CentOS 7 systems."
    exit 1
fi

info "Detected CentOS 7 — proceeding to switch to Vault repositories."

# Backup existing repos
info "Backing up existing repo files..."
mkdir -p /etc/yum.repos.d/backup
mv /etc/yum.repos.d/CentOS-*.repo /etc/yum.repos.d/backup/ 2>/dev/null || true

# Remove old vault repo if exists
rm -f /etc/yum.repos.d/CentOS-Vault.repo || true

# Create fresh vault repo file
info "Creating new CentOS Vault repo file..."

cat <<EOF >/etc/yum.repos.d/CentOS-Vault.repo
[base]
name=CentOS-7 - Base (Vault)
baseurl=http://vault.centos.org/7.9.2009/os/x86_64/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

[updates]
name=CentOS-7 - Updates (Vault)
baseurl=http://vault.centos.org/7.9.2009/updates/x86_64/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

[extras]
name=CentOS-7 - Extras (Vault)
baseurl=http://vault.centos.org/7.9.2009/extras/x86_64/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
EOF

# Refresh yum cache
info "Cleaning and rebuilding yum cache..."
yum clean all -q
yum makecache -q
yum repolist

info "CentOS 7 successfully configured to use Vault repositories."

