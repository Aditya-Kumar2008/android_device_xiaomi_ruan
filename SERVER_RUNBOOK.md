# Server Runbook for Ruan Validation

Run these commands to validate the applied static fixes:

```bash
source build/envsetup.sh
lunch lineage_ruan-trunk_staging-eng
mka bacon
```
If errors occur, parse the first error block:
```bash
awk '/^FAILED:/{f=1} f{print} /ninja failed with:/{exit}' out/error.log
```
