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

def print_usage():
    print >>sys.stderr, "Usage: %s release|devbuild" % \
        os.path.basename(sys.argv[0])


def build_dependencies():
    subprocess.check_call(["pod", "install"])

def build_app(build_type, build_name):
    if build_type == "release":
        build_configuration = "Release"
    else:
        build_configuration = "Devbuild Release"
    archive_path = os.path.join(BUILD_DIR, build_name + ".xcarchive")
    subprocess.check_call([
        "xcodebuild",
        "-workspace", "AdblockPlusSafari.xcworkspace",
        "-configuration", build_configuration,
        "-scheme", "AdblockPlusSafari",
        "CONFIGURATION_BUILD_DIR=" + BUILD_DIR,
        "BUILD_NUMBER=" + BUILD_NUMBER,
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
