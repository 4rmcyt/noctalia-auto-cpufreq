# auto-cpufreq — Noctalia Shell Plugin

Monitor and control the [auto-cpufreq](https://github.com/AdnanHodzic/auto-cpufreq) daemon from your Noctalia bar.

## Features

- **Bar widget** — shows active CPU governor and turbo state at a glance
- **Panel** — CPU usage, frequency, temperature, governor, force override and turbo boost controls
- **Right-click menu** — quick force/turbo override without opening the panel
- Works with Intel (intel_pstate) and AMD (k10temp, amd_pstate) CPUs

## Requirements

- [auto-cpufreq](https://github.com/AdnanHodzic/auto-cpufreq) installed and daemon running
- polkit (for force override and turbo boost controls — see below)

## Installation

Add this repository as a custom source in Noctalia Shell:

**Settings → Plugins → Sources → Add source:**
```
https://github.com/4rmcyt/noctalia-auto-cpufreq
```

Then enable the **auto-cpufreq** plugin and add the bar widget.

## Polkit Setup (required for controls)

Force override and turbo boost buttons use `pkexec` to run `auto-cpufreq` with elevated privileges. Without a polkit rule the buttons will show an error banner.

### NixOS

Add to your NixOS configuration:

```nix
security.polkit.extraConfig = ''
  polkit.addRule(function(action, subject) {
    if (action.id === "org.auto-cpufreq.pkexec" &&
        subject.isInGroup("wheel")) {
      return polkit.Result.YES;
    }
  });
'';

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
        <allow_active>auth_admin</allow_active>
      </defaults>
      <annotate key="org.freedesktop.policykit.exec.path">${pkgs.auto-cpufreq}/bin/auto-cpufreq</annotate>
    </action>
  </policyconfig>
'';
```

### Other distributions (Arch, Ubuntu, Fedora, etc.)

**1. Create the polkit policy file:**

```bash
sudo tee /usr/share/polkit-1/actions/org.auto-cpufreq.pkexec.policy << 'EOF'
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
      <allow_active>auth_admin</allow_active>
    </defaults>
    <annotate key="org.freedesktop.policykit.exec.path">/usr/bin/auto-cpufreq</annotate>
  </action>
</policyconfig>
EOF
```

> Adjust the path in `exec.path` to match your installation: `which auto-cpufreq`

**2. Create the polkit rules file (passwordless for wheel group):**

```bash
sudo tee /etc/polkit-1/rules.d/49-auto-cpufreq.rules << 'EOF'
polkit.addRule(function(action, subject) {
  if (action.id === "org.auto-cpufreq.pkexec" &&
      subject.isInGroup("wheel")) {
    return polkit.Result.YES;
  }
});
EOF
```

> On some distros the group is `sudo` instead of `wheel`. Adjust accordingly.

**3. Reload polkit:**

```bash
sudo systemctl reload polkit
```

## License

MIT
