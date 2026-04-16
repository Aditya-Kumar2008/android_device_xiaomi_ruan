# Remaining Risks

1. **Kernel Module Loading**: The `BOARD_VENDOR_KERNEL_MODULES` paths assume all DLKM modules are in `modules/dlkm`. Since the stock ROM uses EROFS and GKI, we must ensure these modules load in the correct order (`modules.load`) and don't conflict.
2. **5G Modem**: Telephony and 5G heavily rely on `/md1img` mounting. Make sure `/md1img` is correctly formatted and flashable.
3. **Audio Configuration**: The quad-speaker configuration might need XML edits in `vendor/etc/audio` once audio starts playing to ensure all four speakers route correctly.
