#!/bin/bash

pathToRepository='/home/tcallister/LWA-Imaging/'

# Generate flags for calibration integration
. $pathToRepository/Calibration/makeCalibrationFlags.sh ./config-calibration.cfg

# Make caltables
. $pathToRepository/Calibration/gen_caltables.sh ./config-calibration.cfg

# Image!
. $pathToRepository/Imaging/gen_images_new.sh ./config-imaging.cfg
