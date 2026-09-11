#!/bin/bash

UDEV_DIR="/etc/udev/rules.d"
UDEV_NAME="80-lamzu_devices.rules"

REAL_USER=${SUDO_USER:-$USER}

echo "=================================================="
echo "  LAMZU udev permission setup"
echo "=================================================="

if [ "$EUID" -ne 0 ]; then
    echo "This operation requires administrator privileges."
    sudo -v || exit 1
fi

# --------------------------------------------------
# [1/5] Detect LAMZU USB devices
# --------------------------------------------------

echo -n "[1/5] Detecting LAMZU USB device... "

LAMZU_DEVICES=$(lsusb | grep -iE 'LAMZU')

if [ -z "$LAMZU_DEVICES" ]; then
    echo "[FAILED]"
    echo " No LAMZU USB device detected."
    echo " Please connect your mouse/dongle and run the script again."
    exit 1
fi

echo "[SUCCESS]"
echo "$LAMZU_DEVICES"

# --------------------------------------------------
# [2/5] Generate udev rules
# --------------------------------------------------

echo -n "[2/5] Writing udev rules... "

sudo tee "${UDEV_DIR}/${UDEV_NAME}" >/dev/null <<'EOF'
# LAMZU USB HID devices
EOF

while read -r line; do
    USB_ID=$(echo "$line" | grep -oE 'ID [0-9a-fA-F]{4}:[0-9a-fA-F]{4}' | awk '{print $2}')

    if [ -z "$USB_ID" ]; then
        continue
    fi

    VID="${USB_ID%%:*}"
    PID="${USB_ID##*:}"

    sudo tee -a "${UDEV_DIR}/${UDEV_NAME}" >/dev/null <<EOF

# LAMZU device: ${VID}:${PID}
SUBSYSTEM=="hidraw", ATTRS{idVendor}=="${VID}", ATTRS{idProduct}=="${PID}", MODE="0666", TAG+="uaccess"
EOF

done <<< "$LAMZU_DEVICES"

if [ $? -eq 0 ]; then
    echo "[SUCCESS]"
else
    echo "[FAILED]"
    exit 1
fi

# --------------------------------------------------
# [3/5] Reload udev rules
# --------------------------------------------------

echo -n "[3/5] Reloading udev rules... "

sudo udevadm control --reload-rules

if [ $? -eq 0 ]; then
    echo "[SUCCESS]"
else
    echo "[FAILED]"
    exit 1
fi

# --------------------------------------------------
# [4/5] Trigger devices
# --------------------------------------------------

echo -n "[4/5] Triggering HID devices... "

sudo udevadm trigger --action=add --subsystem-match=hidraw
sudo udevadm settle --timeout=10

echo "[SUCCESS]"

# --------------------------------------------------
# [5/5] Done
# --------------------------------------------------

echo "=================================================="
echo "  LAMZU udev configuration complete!"
echo ""
echo "  Installed rules:"
cat "${UDEV_DIR}/${UDEV_NAME}"
echo "=================================================="