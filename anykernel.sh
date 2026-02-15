### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers

### AnyKernel setup
# global properties
properties() { '
kernel.string=FSociety kernel by Richard
do.devicecheck=1
do.modules=0
do.systemless=0
do.cleanup=1
do.cleanuponabort=1
device.name1=surya
device.name2=karna
supported.versions=11-17
'; } # end properties

### AnyKernel install
## boot files attributes
boot_attributes() {
set_perm_recursive 0 0 755 644 $RAMDISK/*;
set_perm_recursive 0 0 750 750 $RAMDISK/init* $RAMDISK/sbin;
} # end attributes

# begin build.prop loader
load_build_props() {
if [ ! -f "/system/build.prop" ] && [ ! -f "/system_root/system/build.prop" ]; then
	mount /system 2>/dev/null || mount /system_root 2>/dev/null
fi

if [ -f "/system/build.prop" ]; then
	SYSTEM_BUILD_PROP="/system/build.prop"
elif [ -f "/system_root/system/build.prop" ]; then
	SYSTEM_BUILD_PROP="/system_root/system/build.prop"
fi

if [ -n "$SYSTEM_BUILD_PROP" ]; then
	PROP_MIUI=$(file_getprop "$SYSTEM_BUILD_PROP" ro.miui.ui.version.code)
fi

if [ -f "$AKHOME/android_ver" ]; then
	ANDROID_VERSION=$(cat "$AKHOME/android_ver")
fi
} # end build.prop loader

# begin legacy bootargs patch
patch_legacy_bootargs() {

ui_print " "

if [ -n "$PROP_MIUI" ]; then
	ui_print "MIUI $PROP_MIUI detected, defaulting to legacy bootargs"
	patch_cmdline init.is_legacy_ebpf init.is_legacy_ebpf=1
	patch_cmdline init.is_legacy_timestamp init.is_legacy_timestamp=1
	return
fi

if [ "$ANDROID_VERSION" -lt 15 ]; then
	ui_print "Enabling legacy eBPF bootarg..."
	patch_cmdline init.is_legacy_ebpf init.is_legacy_ebpf=1
else
	ui_print "Disabling legacy eBPF bootarg..."
	patch_cmdline init.is_legacy_ebpf init.is_legacy_ebpf=0
fi

if [ "$ANDROID_VERSION" -lt 13 ]; then
	ui_print "Enabling legacy timestamp bootarg..."
	patch_cmdline init.is_legacy_timestamp init.is_legacy_timestamp=1
else
	ui_print "Disabling legacy timestamp bootarg..."
	patch_cmdline init.is_legacy_timestamp init.is_legacy_timestamp=0
fi
} # end legacy bootargs patch

# boot shell variables
BLOCK=/dev/block/bootdevice/by-name/boot;
IS_SLOT_DEVICE=0;
RAMDISK_COMPRESSION=auto;
PATCH_VBMETA_FLAG=auto;

# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh;

# load build.prop properties
load_build_props;

# replace dtbo if MIUI is detected
if [ -n "$PROP_MIUI" ] && [ -f "$AKHOME/dtbo-miui.img" ]; then
	ui_print " "
	ui_print "Replacing dtbo with MIUI-specific image..."
	mv "$AKHOME/dtbo-miui.img" "$AKHOME/dtbo.img"
fi

# boot install
dump_boot; # use split_boot to skip ramdisk unpack, e.g. for devices with init_boot ramdisk
patch_legacy_bootargs; # patch legacy bootargs based on Android version
write_boot; # use flash_boot to skip ramdisk repack, e.g. for devices with init_boot ramdisk
## end boot install
