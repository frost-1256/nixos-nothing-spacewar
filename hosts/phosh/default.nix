{pkgs, lib, ...}: {
  # Minimal Phosh (no browser): auto-login shell + on-screen keyboard + terminal.
  imports = [
    ../../modules/bootmac
    ../../modules/hardware
    ../../modules/modem
  ];

  networking.hostName = "nothing";

  # Enable Qualcomm modem support.
  nixos-nothing-spacewar.modem.enable = true;

  # USB serial console (ttyGS0) fallback.
  nixos-nothing-spacewar.hardware.serial.enable = true;

  # Enable experimental Nix features (flakes).
  nix.settings.experimental-features = ["nix-command" "flakes"];

  # Disable documentation to save space.
  documentation.nixos.enable = false;

  networking.networkmanager.enable = true;
  # WiFi (static) via NetworkManager declarative profile + SSH.
  networking.networkmanager.ensureProfiles.profiles."ForVRChat" = {
    connection = {
      id = "ForVRChat";
      type = "wifi";
    };
    wifi = {
      mode = "infrastructure";
      ssid = "ForVRChat";
    };
    wifi-security = {
      key-mgmt = "wpa-psk";
      psk = "628812.iori";
    };
    ipv4 = {
      method = "manual";
      addresses = "192.168.1.128/24";
      gateway = "192.168.1.1";
      dns = "192.168.1.1,8.8.8.8";
    };
  };

  # Phosh on tty1 (auto-starts as admin, no display manager needed).
  services.xserver.desktopManager.phosh = {
    enable = true;
    user = "admin";
    group = "users";
  };

  # squeekboard autostart is unreliable under phosh-session; force it via
  # systemd user service bound to the graphical session.
  systemd.user.services.squeekboard = {
    description = "On-screen keyboard";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.squeekboard}/bin/squeekboard";
      Restart = "on-failure";
    };
  };
  # SSH fallback (no keyboard on device yet).
  services.openssh.enable = true;

  # Phosh starts locked; without a working OSK the lockscreen is a dead end.
  # Disable screen lock so the session is usable without typing a password.
  programs.dconf.enable = true;
  programs.dconf.profiles.user.databases = [
    {
      settings = {
        "org/gnome/desktop/screensaver" = {
          lock-enabled = false;
          idle-activation-enabled = false;
        };
        "org/gnome/desktop/session" = {
          idle-delay = lib.gvariant.mkUint32 0;
        };
      };
    }
  ];

  # Practical mobile packages (all stock nixpkgs, binary cache hits).
  programs.calls.enable = true;
  environment.systemPackages = with pkgs; [
    gnome-console # Terminal.
    firefox-bin # Browser (prebuilt, no source build).
    chatty # SMS/MMS.
    gnome-contacts
    gnome-clocks
    gnome-calculator
    papers # Document viewer.
    loupe # Image viewer.
    wl-clipboard
  ];

  # Create admin user (password set via `mkpasswd`, change with `passwd`).
  users = {
    mutableUsers = true;

    users.admin = {
      isNormalUser = true;
      hashedPassword = "$6$/q9DFs1FWNfkPVQS$/TfiEwaAWStUhdKQOam8bT31zx5behxknqHgm9C994fqjD8tXNsaj5f/LXomAz7wPvXOOvlCmOwMKe5XRzOAU0";
      extraGroups = [
        "networkmanager"
        "video"
        "wheel"
      ];
    };
  };

  system.stateVersion = "25.05";
}
