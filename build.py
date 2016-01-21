#!/usr/bin/env python
# coding: utf-8

import os
import shutil
import subprocess
import time

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
BUILD_DIR = os.path.join(BASE_DIR, "build")
BUILD_NUMBER = time.strftime("%Y%m%d%H%M", time.gmtime())
PACKAGE_NAME = "adblockplussafariios-%s.ipa" % BUILD_NUMBER

def build_dependencies():
  subprocess.check_call(["pod", "install"])
  subprocess.check_call(["xcodebuild",
                         "-workspace", "AdblockPlusSafari.xcworkspace",
                         "-scheme", "Pods-AdblockPlusSafariExtension",
                         "CONFIGURATION_BUILD_DIR=" + BUILD_DIR,
                         "build"])

def build_apps():
  subprocess.check_call(["xcodebuild",
                         "-configuration", "Devbuild Release",
                         "CONFIGURATION_BUILD_DIR=" + BUILD_DIR,
                         "BUILD_NUMBER=" + BUILD_NUMBER,
                         "APP_PROVISIONING_PROFILE=2591efa4-c166-4956-a62a-e3a0cd41f5a3",
                         "EXTENSION_PROVISIONING_PROFILE=c4495b74-44a8-499e-ad28-4190912bad0b",
                         "build"])

def package():
  subprocess.check_call(["xcrun", "-sdk", "iphoneos",
                         "PackageApplication", "-v",
                         os.path.join(BUILD_DIR, "AdblockPlusSafari.app"),
                         "-o", os.path.join(BUILD_DIR, PACKAGE_NAME),
                         "-s", "iPhone Distribution: Eyeo GmbH"])

if __name__ == "__main__":
  shutil.rmtree(BUILD_DIR, ignore_errors=True)
  build_dependencies()
  build_apps()
  package()
