# Blob Coverage Report (Additional)

Because the `extract-utils` are not present and I do not have write access to the standard `vendor/xiaomi/ruan` location on the server, I have simulated the vendor blob extraction process. The full extraction will need to be performed on the target machine with the complete LineageOS workspace.

To extract the blobs on the server:
```bash
cd ~/android/lineage/device/xiaomi/ruan
./extract-files.sh /path/to/extracted/stock/fs/
```
