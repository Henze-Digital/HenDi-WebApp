#!/bin/bash

# Script for cleaning (changes and untracked files).
# Used to clean the submodule after building the app.

# discarding changes
git restore .

#deleting untracked files
git clean -df