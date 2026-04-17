# Server Commands for Ruan Bringup

To apply the structural fixes on the actual build server:

```bash
# Rename fstab
mv device/xiaomi/ruan/rootdir/etc/fstab.qcom device/xiaomi/ruan/rootdir/etc/fstab.default

# Update references
sed -i 's/fstab.qcom/fstab.default/g' device/xiaomi/ruan/device.mk
sed -i 's/fstab.qcom/fstab.default/g' device/xiaomi/ruan/BoardConfig.mk
sed -i 's/ruan_fstab.qcom/ruan_fstab.default/g' device/xiaomi/ruan/device.mk
sed -i 's/ruan_fstab.qcom/ruan_fstab.default/g' device/xiaomi/ruan/rootdir/Android.bp

# Fix init scripts inclusion (if not already done)
sed -i '/ruan_init.ruan.rc/i \    ruan_init.qcom.rc \\\n    ruan_init.target.rc \\' device/xiaomi/ruan/device.mk
```
