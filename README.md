# LWA-Imaging

To use:

1. Copy **genCommands.sh**, **config-calibration.cfg**, and **config-imaging.cfg** to working directory outside the repository.
2. Edit the filepaths in **config-calibration.cfg** and **config-imaging.cfg** as needed (see header information in the .cfg files)
3. Run **genCommands.sh**. This will generate antenna flags and create the following files:
   * ...working-directory/scripts/calibrationCommands.txt
   * ...working-directory/scripts/do_makeMS.txt
   * ...working-directory/scripts/do_cleanCommands.txt
   These files contain lists of bash commands that can be passed to ibps_taskfarm.py
4. Run **
