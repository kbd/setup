#!/usr/bin/env python

"""Bootstrap the setup tool.

This assumes Python is installed on the target os, but not specifically Python3.

What this does (only intended for Mac atm):

* installs Homebrew
* Homebrew installs a core set of packages (git and python3)
* git check out the project into ~/setup
* run
  - setup (will restart os functions to reflect new settings)
  - setup brew
  - setup packages
* tell the user to restart terminal to get new everything

You should be able to run this with curl | python shenanigans.

"""
