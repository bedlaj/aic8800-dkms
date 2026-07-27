# aic8800-dkms — AIC8800 USB Wi-Fi driver for current kernels

DKMS packaging of the AICSemi AIC8800 vendor driver (RivieraWaves `rwnx`
stack, v1.0.9) as shipped with BrosTrend USB Wi-Fi adapters, **ported to
build on current kernels** (tested through kernel 7.1 / Fedora 44).

The vendor/BrosTrend driver only builds against older kernels; this tree
adds version-guarded compatibility fixes so one source builds across old
and new kernels.

## Supported hardware

AIC8800-based USB adapters, e.g.:

- BrosTrend AIC8800DC — USB ID `2c4e:0126` (tested)
- Other AIC8800D80/DC-family dongles may work (firmware for both included)

## Install (Fedora)

```bash
git clone https://github.com/bedlaj/aic8800-dkms
cd aic8800-dkms
sudo ./install.sh
```

The script installs `dkms` + `kernel-devel` if missing, copies firmware to
`/lib/firmware/`, registers the source at `/usr/src/aic8800-1.0.9`, and
builds/installs the modules (`aic8800_fdrv`, `aic_load_fw`) for the running
kernel. DKMS rebuilds them automatically on future kernel updates.

Other distros: install `dkms` and your kernel headers manually, then run
`sudo ./install.sh`.

### Secure Boot

DKMS signs modules with a locally generated MOK key. If Secure Boot is
enabled, enroll it once before the module will load:

```bash
sudo mokutil --import /var/lib/dkms/mok.pub   # then reboot, enroll in MOK manager
```

## Uninstall

```bash
sudo dkms remove aic8800/1.0.9 --all
sudo rm -rf /usr/src/aic8800-1.0.9 /lib/firmware/aic8800DC /lib/firmware/aic8800D80
```

## Kernel compatibility / porting

Kernel API changes are handled with `HIGH_KERNEL_VERSION*` guards (see
`aic8800_fdrv/rwnx_defs.h`). Most recently, `HIGH_KERNEL_VERSION_WDEV`
(`KERNEL_VERSION(7,1,0)`) covers the kernel 7.1 cfg80211 changes:
key/station `cfg80211_ops` callbacks take `struct wireless_dev *` instead
of `struct net_device *`, and the action union in `struct ieee80211_mgmt`
became anonymous with a shared `action_code` field.

`dkms.service` rebuilds the modules automatically when a new kernel is
installed, as long as matching headers (`kernel-devel`) are present. To
rebuild manually:

```bash
sudo dkms install aic8800/1.0.9 -k $(uname -r)
```

If a future kernel breaks the build:

1. Check `journalctl -u dkms.service` and
   `/var/lib/dkms/aic8800/1.0.9/build/make.log` for the compile error.
2. Compare against the new kernel's headers, e.g.
   `/usr/src/kernels/$(uname -r)/include/net/cfg80211.h` and
   `include/linux/ieee80211.h`.
3. Add a new branch guarded by a `HIGH_KERNEL_VERSION*` macro, keeping the
   older branches so one source still builds for every installed kernel —
   see git history for worked examples.

## Upstream tracking

This tree is a fork of upstream 1.0.9 (see below), so upstream changes —
including possible security fixes — must be ported by hand. A weekly
GitHub Actions job (`.github/workflows/upstream-check.yml`) watches
BrosTrend's driver repo
([brostrend/linux.brostrend.com](https://github.com/brostrend/linux.brostrend.com),
which serves linux.brostrend.com): it pins the current release (versioned
pool deb named by their `aic8800-dkms.deb` pointer file), their release
commit, and per-file payload checksums in `upstream/SHA256SUMS`; if any of
that changed, it opens an issue with the diff. Run `./check-upstream.sh`
locally for the same check, and `./check-upstream.sh --update` to refresh
the baseline after porting the changes.

## Licensing / attribution

- Driver source: GPL-2.0 (see `LICENSE`; `MODULE_LICENSE("GPL")` = GPLv2 or
  later in kernel terms), Copyright RivieraWaves / AICSemi; redistributed
  unmodified apart from kernel-compatibility fixes.
- `firmware/`: AICSemi firmware blobs (no explicit license), redistributed
  as-is for convenience.

Both driver source and firmware were obtained from BrosTrend's official
Linux driver package `aic8800-dkms` 1.0.9
([linux.brostrend.com/aic8800-dkms.deb](https://linux.brostrend.com/aic8800-dkms.deb)),
maintained by BrosTrend at
[github.com/brostrend/linux.brostrend.com](https://github.com/brostrend/linux.brostrend.com).
The chipset, firmware, and vendor driver are developed by
[AICSemi](https://www.aicsemi.com/) (AIC Semiconductor).
