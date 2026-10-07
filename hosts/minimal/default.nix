{ pkgs, ... }:
{
  # Import hardware-specific configuration for Nothing Phone (1).
  imports = [
    ../../modules/hardware
  ];

  networking.hostName = "nothing";
  # WiFi + SSH (cable-independent login).
  networking.wireless.enable = true;
  networking.wireless.networks."ForVRChat".psk = "628812.iori";
  networking.interfaces.wlan0.ipv4.addresses = [{
    address = "192.168.1.128";
    prefixLength = 24;
  }];
  networking.defaultGateway = "192.168.1.1";
  networking.nameservers = [ "192.168.1.1" "8.8.8.8" ];
  services.openssh.enable = true;
  # USB serial console (ttyGS0) for host-side login via USB cable.
  nixos-nothing-spacewar.hardware.serial.enable = true;

  # Enable experimental Nix features (flakes).
  nix.settings.experimental-features = ["nix-command" "flakes"];

  # Create admin user (password set via `mkpasswd`, change with `passwd`).
  users = {
    mutableUsers = true;

    users.admin = {
      isNormalUser = true;
      hashedPassword = "$6$/q9DFs1FWNfkPVQS$/TfiEwaAWStUhdKQOam8bT31zx5behxknqHgm9C994fqjD8tXNsaj5f/LXomAz7wPvXOOvlCmOwMKe5XRzOAU0";
      # Add to wheel group for sudo access.
      extraGroups = ["wheel"];
    };
  };
  # On-boot audio probe: prints sound diagnostics to the screen console
  # (no login/input needed, for broken-USB debugging).
  environment.systemPackages = [ pkgs.alsa-utils ];
  systemd.services.audio-probe = {
    description = "Dump audio probe to console";
    wantedBy = [ "multi-user.target" ];
    after = [ "sound.target" ];
    serviceConfig.Type = "oneshot";
    serviceConfig.StandardOutput = "journal+console";
    script = ''
      sleep 15
      echo "===== AUDIO PROBE ====="
      dmesg | grep -iE 'wcd|soundwire|tx_macro|va_macro|asoc|sm8250|PPM|ppm' | head -40
      echo "===== ARECORD ====="
      arecord -l
      echo "===== CONTROLS ====="
      amixer scontrols | head -40
      echo "===== PROBE DONE ====="
    '';
  };

  system.stateVersion = "25.05";
}
