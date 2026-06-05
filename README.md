# auto-cpufreq — Noctalia Shell Plugin

Monitor and control the [auto-cpufreq](https://github.com/AdnanHodzic/auto-cpufreq) daemon from your Noctalia bar.

## Features

- **Bar widget** — active CPU governor and turbo state at a glance, color-coded by profile
- **Panel** — CPU usage, frequency, temperature, governor info, force override and turbo boost controls
- **Right-click menu** — quick force/turbo override without opening the panel
- Works with Intel (`intel_pstate`) and AMD (`k10temp`, `amd_pstate`) CPUs

## System Requirements

- [auto-cpufreq](https://github.com/AdnanHodzic/auto-cpufreq) installed with daemon running
- polkit (for force override and turbo boost controls — see setup below)

Verify daemon status:
```bash
systemctl status auto-cpufreq
```

## Installation

1. Open Noctalia **Settings → Plugins → Sources → Add source**:
   ```
   https://github.com/4rmcyt/noctalia-auto-cpufreq
   ```
2. Enable the **auto-cpufreq** plugin
3. Add the bar widget via **Settings → Bar**
4. Set up polkit (see below) to enable controls

## Polkit Setup (required for controls)

Force override and turbo boost buttons use `pkexec` to run `auto-cpufreq` with root privileges. Without a polkit rule the panel will show an error banner when you try to use the controls.

### Linux (Arch, Ubuntu, Fedora, openSUSE, etc.)

Run the provided setup script once:

```bash
cd ~/.config/noctalia/plugins/auto-cpufreq/
chmod +x setup_polkit.sh
sudo ./setup_polkit.sh
```

The script:
- Detects the real path of `auto-cpufreq` (handles symlinks)
- Detects your privilege group (`wheel` or `sudo`)
- Writes the polkit policy and rules files
- Reloads polkit

### NixOS

Add to your NixOS configuration:

```nix
environment.etc."polkit-1/actions/org.auto-cpufreq.pkexec.policy".text = ''
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE policyconfig PUBLIC
   "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN"
   "http://www.freedesktop.org/standards/PolicyKit/1/policyconfig.dtd">
  <policyconfig>
    <action id="org.auto-cpufreq.pkexec">
      <description>Run auto-cpufreq</description>
      <message>Authentication is required to run auto-cpufreq</message>
      <defaults>
        <allow_any>auth_admin</allow_any>
        <allow_inactive>auth_admin</allow_inactive>
        <allow_active>auth_admin_keep</allow_active>
      </defaults>
      <annotate key="org.freedesktop.policykit.exec.path">${pkgs.auto-cpufreq}/bin/auto-cpufreq</annotate>
    </action>
  </policyconfig>
'';
```

`auth_admin_keep` — запрашивает пароль один раз, кеширует на ~5 минут.

Then rebuild: `sudo nixos-rebuild switch`

## License

MIT
