#!/bin/bash

# This script cleans the submodule after building the app

# navigating to submodule
cd submodules/WeGA-WebApp

# discarding changes
git restore .

#deleting untracked files
git clean -df