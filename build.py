#!/usr/bin/env python
# coding: utf-8

# This file is part of Adblock Plus <https://adblockplus.org/>,
# Copyright (C) 2006-present eyeo GmbH
#
# Adblock Plus is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 3 as
# published by the Free Software Foundation.
#
# Adblock Plus is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Adblock Plus.  If not, see <http://www.gnu.org/licenses/>.

"""

Builds AdblockPlusSafari Xcode project for iOS.

Supported build configurations:

    * Release
    * Devbuild Release (Enterprise account)

Usage:

    $ python build.py <release|devbuild> [bootstrap]

where adding the optional bootstrap argument will rebuild everything in
Cartfile.resolved.

Tested with Python 2.7.14 and 3.6.5.

"""

import os
import shutil
import subprocess
import sys
import time
import re

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
BUILD_DIR = os.path.join(BASE_DIR, "build")
BUILD_NUMBER = time.strftime("%Y%m%d%H%M", time.gmtime())
VALID_SLICES = ["arm64"]
FRAMEWORK_DIR = os.path.join(BASE_DIR, "Carthage", "Build", "iOS")


def print_usage():
    print("Usage: {} release|devbuild [bootstrap]"
          .format(os.path.basename(sys.argv[0]),
                  file = sys.stderr))


def build_args(update_type):
    return ["carthage", "{}".format(update_type), "--platform", "ios"]


def build_dependencies(bootstrap):
    """
    :param bootstrap: Builds the dependencies in Cartfile.resolved while
                      ignoring binaries, if True.
    """

    update = "update"
    if bootstrap:
        update = "bootstrap"
    subprocess.check_call(build_args(update))


def get_frameworks():
    """
    :return: List of frameworks in the Cartfile
    """

    frameworks = []
    regex = '^(?:(?!#).+).*/(.*)\"' # Ignore commented lines
    with open("Cartfile", "r") as file:
        for cnt, line in enumerate(file):
            fw_name = re.search(regex, line)
            if fw_name:
                base = fw_name.group(1).replace('-', '_')
                frameworks.append(os.path.join(base + ".framework",
                                               base))
    return frameworks


def strip_slices():
    """
    Strip unused/invalid slices from built frameworks as required for the
    Apple App Store.
    """

    for framework in get_frameworks():
        fw = os.path.join(FRAMEWORK_DIR, framework)

        for slice in get_slices(fw):
            if slice not in VALID_SLICES:
                subprocess.check_call(["lipo",
                                       "-remove", slice,
                                       "-output", fw,
                                       fw])


def get_slices(framework):
    """
    Get existing slices for a framework as parsed from lipo info.
    """

    result = subprocess.check_output(["lipo", "-info", framework])
    text = result.decode(sys.stdout.encoding)
    archs = re.search('are:(.*?)$', text)

    if archs:
        return archs.group(1).strip().split(' ')
    else:
        return []


def build_app(build_type, build_name):
    build_configuration = "Release" if build_type == "release" else "Devbuild Release"
    archive_path = os.path.join(BUILD_DIR, build_name + ".xcarchive")

    subprocess.check_call([
        "xcodebuild",
        "-project", "AdblockPlusSafari.xcodeproj",
        "-configuration", build_configuration,
        "-scheme", "AdblockPlusSafari",
        "CONFIGURATION_BUILD_DIR=" + BUILD_DIR,
        "BUILD_NUMBER=" + BUILD_NUMBER,
        "ENABLE_BITCODE=YES",
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
    bootstrap = False

    if build_type not in ["devbuild", "release"]:
        print_usage()
        sys.exit(2)

    if len(sys.argv) == 3:
        if sys.argv[2] not in ["bootstrap"]:
            print_usage()
            sys.exit(3)
        else:
            bootstrap = True

    shutil.rmtree(BUILD_DIR, ignore_errors=True)
    build_dependencies(bootstrap)
    strip_slices()
    build_name = "adblockplussafariios-%s-%s" % (build_type, BUILD_NUMBER)
    archive_path = build_app(build_type, build_name)
    package_app(archive_path, build_type, build_name)
