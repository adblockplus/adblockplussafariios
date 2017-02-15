#!/usr/bin/env python
# coding: utf-8

import os
import shutil
import subprocess
import sys
import time

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
BUILD_DIR = os.path.join(BASE_DIR, "build")
BUILD_NUMBER = time.strftime("%Y%m%d%H%M", time.gmtime())
RELEASE_APP_PROVISIONING_PROFILE = "00d92821-2b0f-4036-9b2d-541ce10d0429"
RELEASE_EXTENSION_PROVISIONING_PROFILE = "a30dba35-c866-4331-8967-28b9cab60ca2"
DEVBUILD_APP_PROVISIONING_PROFILE = "e5707b43-6416-4244-b7c2-eeafe3c73e68"
DEVBUILD_EXTENSION_PROVISIONING_PROFILE = "ff4c872e-ccf0-4d00-802f-f35e142cc977"


def print_usage():
    print >>sys.stderr, "Usage: %s release|devbuild" % \
        os.path.basename(sys.argv[0])


def build_dependencies():
    subprocess.check_call(["pod", "install"])


def build_app(build_type, build_name):
    if build_type == "release":
        build_configuration = "Release"
        app_provisioning_profile = RELEASE_APP_PROVISIONING_PROFILE
        extension_provisioning_profile = RELEASE_EXTENSION_PROVISIONING_PROFILE
    else:
        build_configuration = "Devbuild Release"
        app_provisioning_profile = DEVBUILD_APP_PROVISIONING_PROFILE
        extension_provisioning_profile = DEVBUILD_EXTENSION_PROVISIONING_PROFILE
    archive_path = os.path.join(BUILD_DIR, build_name + ".xcarchive")
    subprocess.check_call([
        "xcodebuild",
        "-workspace", "AdblockPlusSafari.xcworkspace",
        "-configuration", build_configuration,
        "-scheme", "AdblockPlusSafari",
        "CONFIGURATION_BUILD_DIR=" + BUILD_DIR,
        "BUILD_NUMBER=" + BUILD_NUMBER,
        "APP_PROVISIONING_PROFILE=" + app_provisioning_profile,
        "EXTENSION_PROVISIONING_PROFILE=" + extension_provisioning_profile,
        "ENABLE_BITCODE=NO",
        "archive",
        "-archivePath", archive_path
    ])
    return archive_path


def package_app(archive_path, build_type, build_name):
    subprocess.check_call([
        "xcodebuild",
        "-exportArchive",
        "-archivePath", archive_path,
        "-exportPath", BUILD_DIR,
        "-exportOptionsPlist", build_type + "ExportOptions.plist"
    ])
    os.rename(os.path.join(BUILD_DIR, "AdblockPlusSafari.ipa"),
              os.path.join(BUILD_DIR, build_name + ".ipa"))

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print_usage()
        sys.exit(1)

    build_type = sys.argv[1]
    if build_type not in ["devbuild", "release"]:
        print_usage()
        sys.exit(2)

    shutil.rmtree(BUILD_DIR, ignore_errors=True)
    build_dependencies()
    build_name = "adblockplussafariios-%s-%s" % (build_type, BUILD_NUMBER)
    archive_path = build_app(build_type, build_name)
    package_app(archive_path, build_type, build_name)
