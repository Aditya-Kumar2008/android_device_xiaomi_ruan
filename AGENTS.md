

5. Setup wizard stuck on first boot (GApps).
   ROOT CAUSE: vendor/pixel-style/config/common.mk gates
   ro.setupwizard.rotation_locked on PRODUCT_CHARACTERISTICS, but that block is
   evaluated when common_full_tablet.mk is inherited, which happens *before*
   device.mk sets the variable to tablet. The else branch therefore always won
   and the wizard shipped rotation-locked. On a landscape panel that strands the
   GLIF layout: oversized page, no scroll, no Continue button.
   FIX: set PRODUCT_CHARACTERISTICS in lineage_ruan.mk before inheriting the
   common config. Do NOT patch vendor/pixel-style - that is ROM source and
   repo sync would revert it.
6. Control centre tile sizing on the tablet.
   SystemUIOverlayDizi (static RRO, priority 1000, targetPackage com.android.systemui)
   now pins quick_settings_num_columns=4 and qs_tile_height/text/margins. The stock
   landscape bucket (values-sw600dp-land) is 2 columns, which renders oversized
   tiles at 320dpi. SystemUI declares no <overlayable>, so the RRO is unrestricted.

7. Device identity / Settings "About" on a dual-brand device.
   ruan ships as Redmi Pad Pro 5G AND POCO Pad 5G, and the tree had hardcoded the
   Redmi identity: props/system.prop pinned ro.product.marketname=Redmi Pad Pro 5G
   and ro.product.mod_device=ruan_global, and props/odm.prop imported
   /odm/etc/${ro.boot.hwc}_${ro.boot.hardware.sku}_build.prop. That key does not
   exist on ruan (stock imports ${ro.boot.product.hardware.sku}), so the import
   silently no-op'd and no per-SKU props were ever installed.
   FIX: ship the six stock per-SKU identity props (props/odm/n83*_build.prop,
   copied to /odm/etc by device.mk) and import them from odm.prop with the stock
   key. Drop marketname/mod_device from system.prop: system/build.prop loads
   first and ro.* is write-once, so a value there shadows the SKU one.
   ro.product.property_source_order=odm,... puts odm first, so the SKU value wins
   for the plain ro.product.* props too. Verified in the built image:
   odm/etc/n83upin_build.prop -> brand=POCO, model=24074PCD2I, marketname=POCO Pad 5G.
8. Always-on Display (AOD).
   framework-res defaults config_dozeAlwaysOnDisplayAvailable to false, so the
   toggle never appeared. overlay/FrameworkOverlayDizi now pins
   config_dozeAlwaysOnDisplayAvailable=true and config_dozeAfterScreenOffByDefault=true.
   The maintainer credit lives in overlay/SettingsOverlayDizi (build_maintainer_summary).
