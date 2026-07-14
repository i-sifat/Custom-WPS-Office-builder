# Step 1: Download + extract (default)

chmod +x download.sh repack.sh clean.sh cleaner.sh
./download.sh              # Downloads .deb + extracts to build/

# Step 2: (You manually edit clean.sh, then run it)
# Edit clean.sh to add your rm/find commands
./clean.sh                 # Runs your custom cleaning on build/

# Step 3: Repack
./repack.sh                # Creates output/wps-office-custom_*.deb

# Step 4: Clean up project when done
./cleaner.sh               # Removes build/, output/, logs (keeps .deb)



download.sh Modes
bash
./download.sh              # Download + extract (default)
./download.sh --download   # Download .deb only, no extract
./download.sh --extract    # Extract existing wps-office.deb only
./download.sh --help       # Show help
