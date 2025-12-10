#!/bin/bash
#
# Script Name : centos7-update-repos.sh
# Description : Switch CentOS 7 repos to archive.kernel.org vault mirror
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

info "Detected CentOS 7 — switching to archive.kernel.org Vault mirror."

# Backup existing repos
info "Backing up existing repo files..."
mkdir -p /etc/yum.repos.d/backup
mv -f /etc/yum.repos.d/CentOS-*.repo /etc/yum.repos.d/backup/ 2>/dev/null || true

# Remove any old vault repo file
rm -f /etc/yum.repos.d/CentOS-Vault.repo || true

# Create new working repo file using archive.kernel.org
info "Creating updated Vault repo configuration..."

cat <<EOF >/etc/yum.repos.d/CentOS-Vault.repo
[base]
name=CentOS-7 - Base (Vault)
baseurl=http://archive.kernel.org/centos-vault/7.9.2009/os/x86_64/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

[updates]
name=CentOS-7 - Updates (Vault)
baseurl=http://archive.kernel.org/centos-vault/7.9.2009/updates/x86_64/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

[extras]
name=CentOS-7 - Extras (Vault)
baseurl=http://archive.kernel.org/centos-vault/7.9.2009/extras/x86_64/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
EOF

# Clean yum cache
info "Cleaning and rebuilding yum cache..."
yum clean all -q
yum makecache -q

info "CentOS 7 repo successfully switched to archive.kernel.org vault mirror."

