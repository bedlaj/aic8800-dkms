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
covers the kernel 7.1 cfg80211 changes (wireless_dev-based key/station ops,
anonymous action union in `struct ieee80211_mgmt`). If a future kernel
breaks the build, check `/var/lib/dkms/aic8800/1.0.9/build/make.log`,
compare against the new kernel headers, and add another guarded branch —
see git history for worked examples.

## Licensing

- Driver source: GPL-2.0 (see `LICENSE`; `MODULE_LICENSE("GPL")` = GPLv2 or
  later in kernel terms), Copyright RivieraWaves /
  AICSemi; redistributed unmodified apart from kernel-compatibility fixes.
- `firmware/`: proprietary AICSemi firmware blobs, redistributed as-is from
  BrosTrend's official Linux driver package for convenience.
