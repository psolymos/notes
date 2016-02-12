#!/bin/bash
echo '>>> Loading git module'
module load application/git/1.7.10.1
echo '>>> Pulling updates: bragging'
cd ~/repos/bragging
git pull
echo '>>> Pulling updates: abmianalytics'
cd ~/repos/abmianalytics
git pull
echo '>>> Pulling updates: bamanalytics'
cd ~/repos/bamanalytics
git pull
echo '>>> Pulling updates: detect'
cd ~/repos/detect
git pull
cd ~

