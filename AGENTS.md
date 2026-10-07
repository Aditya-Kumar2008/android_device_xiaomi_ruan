

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
