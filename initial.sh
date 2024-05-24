#!/bin/bash

# Function to check if the script is run as sudo
check_sudo() {
  if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (use sudo)"
    exit 1
  fi
}

# Function to check if the OS is Debian 11 or newer
check_os() {
  if ! grep -q 'Debian' /etc/os-release; then
    echo "This script is designed for Debian."
    exit 1
  fi
  
  # Get the version number
  VERSION=$(grep 'VERSION_ID' /etc/os-release | cut -d '"' -f 2)
  if [ "$MAJOR_VERSION" -lt 11 ]; then
    echo "Debian version 11 or higher is required."
    exit 1
  fi
}

# Function to update and upgrade the system
update_upgrade() {
  apt update && apt upgrade -y
}

# Function to install necessary packages
install_packages() {
  apt install -y htop tmux wget curl git ufw
}

# Function to install Docker
install_docker() {
  # Install required packages
  apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
  
  # Add Docker’s official GPG key
  curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  
  # Set up the stable repository
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
  
  # Update package index and install Docker
  apt update
  apt install -y docker-ce docker-ce-cli containerd.io
}

# Function to configure SSH
configure_ssh() {
  # Change SSH port to 2222
  sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config

  # Disable IPv6 in SSH
  echo "AddressFamily inet" >> /etc/ssh/sshd_config

  # Restart SSH service to apply changes
  systemctl restart sshd
}

# Function to disable IPv6 system-wide
disable_ipv6() {
  echo "Disabling IPv6..."

  # Disable IPv6 immediately
  sysctl -w net.ipv6.conf.all.disable_ipv6=1
  sysctl -w net.ipv6.conf.default.disable_ipv6=1
  sysctl -w net.ipv6.conf.lo.disable_ipv6=1

  # Make the changes persistent across reboots
  if ! grep -q "net.ipv6.conf.all.disable_ipv6" /etc/sysctl.conf; then
    echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
  fi

  if ! grep -q "net.ipv6.conf.default.disable_ipv6" /etc/sysctl.conf; then
    echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
  fi

  if ! grep -q "net.ipv6.conf.lo.disable_ipv6" /etc/sysctl.conf; then
    echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf
  fi
}

# Main script execution
check_sudo
check_os
update_upgrade
install_packages
install_docker
configure_ssh
disable_ipv6

echo "Setup completed successfully."
