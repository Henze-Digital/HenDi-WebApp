#!/bin/bash

# This script deploys hwh-data, WeGA-WebApp-lib and WeGA-WebApp to localhost:8080

cd ../henze-digital
echo "Starting deploy of hwh-data"
ant deploy

cd ../WeGA-WebApp-lib
echo "Starting deploy of WeGA-WebApp-lib"
ant deploy

cd ../WeGA-WebApp
echo "Starting deploy of WeGA-WebApp"
ant deploy

echo "Your App and data is set up."