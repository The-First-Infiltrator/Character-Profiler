# App icon tooling

`generate_app_icon.py` deterministically creates the canonical 1024×1024 RGB application icon using only the Python standard library.

`validate_compiled_icon.py` decodes both ordinary PNG and Apple's compiled CgBI PNG format and compares the iPhoneOS `AppIcon60x60@2x.png` output against the source icon. The dedicated App Icon Integrity workflow uses this check to prevent a successful Xcode build from shipping a visually corrupted icon.
