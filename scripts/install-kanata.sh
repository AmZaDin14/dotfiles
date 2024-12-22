#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Function to check if a command exists
command_exists() {
  command -v "$1" &>/dev/null
}

# Step 1: Create the uinput group if it doesn't exist
if ! getent group uinput >/dev/null 2>&1; then
  echo "Creating uinput group..."
  sudo groupadd uinput
else
  echo "uinput group already exists."
fi

# Step 2: Add the user to the input and uinput groups
echo "Adding user to input and uinput groups..."
sudo usermod -aG input "$USER"
sudo usermod -aG uinput "$USER"

# Ensure the group changes take effect
echo "Make sure to log out and log back in for the changes to take effect."
groups

# Step 3: Create the udev rule for uinput permissions
echo "Creating udev rule for uinput permissions..."
if ! command_exists tee; then
  echo "Error: 'tee' command is missing. Please install it."
  exit 1
fi

sudo tee /etc/udev/rules.d/99-input.rules <<EOF
KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
EOF

# Reload udev rules
echo "Reloading udev rules..."
sudo udevadm control --reload-rules && sudo udevadm trigger

# Verify uinput permissions
echo "Verifying uinput permissions..."
ls -l /dev/uinput

# Step 4: Ensure the uinput driver is loaded
echo "Loading uinput driver..."
if ! command_exists modprobe; then
  echo "Error: 'modprobe' command is missing. Please install it."
  exit 1
fi

sudo modprobe uinput

# Step 5: Create and enable the systemd daemon service
echo "Setting up systemd service for kanata..."

mkdir -p ~/.config/systemd/user

KANATA_SERVICE_PATH="$HOME/.config/systemd/user/kanata.service"

# Check if the service file already exists
if [ -f "$KANATA_SERVICE_PATH" ]; then
  echo "Systemd service file already exists at $KANATA_SERVICE_PATH. Skipping creation."
else
  cat <<'EOF' >"$KANATA_SERVICE_PATH"
[Unit]
Description=Kanata keyboard remapper
Documentation=https://github.com/jtroo/kanata

[Service]
Environment=PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/bin
Environment=DISPLAY=:0
Type=simple
ExecStart=/usr/bin/sh -c 'exec $$(which kanata) --cfg $${HOME}/.config/kanata/kanata.kbd'
Restart=no

[Install]
WantedBy=default.target
EOF
  echo "Systemd service file created at $KANATA_SERVICE_PATH."
fi

# Make sure the sh path is correct
SH_PATH=$(which sh)
KANATA_PATH=$(which kanata)

# Update systemd service file if necessary
if [ "$SH_PATH" != "/usr/bin/sh" ]; then
  echo "Updating systemd service with correct sh path..."
  sed -i "s|/usr/bin/sh|$SH_PATH|" "$KANATA_SERVICE_PATH"
fi

# Ensure kanata path is correctly included in the PATH
if ! grep -q "$KANATA_PATH" "$KANATA_SERVICE_PATH"; then
  echo "Updating systemd service with kanata path..."
  sed -i "s|Environment=PATH=.*|Environment=PATH=$KANATA_PATH:\$PATH|" "$KANATA_SERVICE_PATH"
fi

# Reload systemd daemon and enable the service
echo "Reloading systemd daemon..."
systemctl --user daemon-reload

echo "Enabling and starting kanata service..."
systemctl --user enable kanata.service
systemctl --user start kanata.service

# Check the status of the service
systemctl --user status kanata.service
