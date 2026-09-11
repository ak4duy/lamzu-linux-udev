# lamzu-linux-udev

## Quick Install

Connect your LAMZU mouse or receiver, then run:

```bash
curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/ak4duy/lamzu-linux-udev/refs/heads/master/setup-lamzu.sh | bash
```

## What It Does

The script detects LAMZU devices automatically:

```text
Bus 001 Device 011: ID 37b0:002e LAMZU LAMZU 8K Dongle V2 Dongle
```

It extracts the vendor ID:

```text
37b0
```

and creates:

```udev
SUBSYSTEM=="hidraw", ATTRS{idVendor}=="37b0", MODE="0666", TAG+="uaccess"
```

The rule is located at:

```text
/etc/udev/rules.d/80-lamzu_devices.rules
```

## Uninstall

Remove the generated rule:

```bash
sudo rm /etc/udev/rules.d/80-lamzu_devices.rules
sudo udevadm control --reload-rules
sudo udevadm trigger
```

Then reconnect your mouse or receiver.

## License

[MIT](https://choosealicense.com/licenses/mit/)