#!/usr/bin/env python3

# Copyright (c) 2026 Egor Tensin <egor@tensin.name>
# This file is part of the "Tagger" project.
# For details, see https://github.com/egor-tensin/tagger
# Distributed under the MIT License.

R"""
This script automates the creation of git tags in accordance with the semantic
versioning policy. It follows the convention of tags being in the MAJOR.MINOR.PATCH
format (with an optional prefix - "v" by default). You can then use it to bump
either of the major/minor/patch version numbers, and it will take care of
creating the proper tag for you.
"""

import argparse
from contextlib import contextmanager
from dataclasses import dataclass
from enum import Enum
import logging
import os
import re
import subprocess
import sys


@contextmanager
def setup_logging():
    logging.basicConfig(
        level=logging.DEBUG,
        datefmt="%Y-%m-%d %H:%M:%S%z",
        format="%(filename)s | %(asctime)s | %(message)s",
        stream=sys.stdout,
    )
    try:
        yield
    except Exception as e:
        logging.exception(e)
        sys.exit(1)


def run(*args, **kwargs):
    stdout = subprocess.PIPE
    stderr = subprocess.STDOUT

    logging.info("Running: %s", subprocess.list2cmdline(args))

    try:
        result = subprocess.run(
            args, check=True, stdout=stdout, stderr=stderr, encoding="utf-8", **kwargs
        )
    except subprocess.CalledProcessError as e:
        logging.error("... Returned exit code %d", e.returncode)
        logging.error("Output (%d characters):", len(e.output))
        for line in e.output.splitlines():
            logging.error("    %s", line)
        raise

    if not result.stdout:
        logging.info("... No output")
        return ""

    logging.info("Output (%d characters):", len(result.stdout))
    for line in result.stdout.splitlines():
        logging.info("    %s", line)

    return result.stdout


class ReleaseScope(Enum):
    MAJOR = "major"
    MINOR = "minor"
    PATCH = "patch"

    def __str__(self):
        return self.value

    def next_version(self, version):
        version = version.extend(len(ReleaseScope))
        version = version.upgrade(self._index)
        return version

    @property
    def _index(self):
        if self is ReleaseScope.MAJOR:
            return 0
        if self is ReleaseScope.MINOR:
            return 1
        if self is ReleaseScope.PATCH:
            return 2
        raise NotImplemented(f"Unknown release scope: {self}")


class Version:
    def __init__(self, nums):
        nums = list(nums)
        while nums and nums[-1] is None:
            nums.pop()

        if not nums:
            raise ValueError("Must provide at least the major version number")
        if any((n is None for n in nums)):
            raise ValueError("Some version components are invalid")

        self._nums = tuple(nums)

    @staticmethod
    def parse(src, strict=False):
        invalid_msg = f"Invalid version: {src}"

        match = re.fullmatch(r"(\d+)(?:\.(\d+)(?:\.(\d+))?)?", src)
        if not match:
            if strict:
                raise ValueError(invalid_msg)
            else:
                logging.warning("%s", invalid_msg)
                return None
        assert len(match.groups()) == 3

        nums = [int(n) if n is not None else None for n in match.groups()]
        return Version(nums)

    def __str__(self):
        return ".".join(map(str, self._nums))

    def __eq__(self, other):
        return self._nums == other._nums

    def __lt__(self, other):
        for a, b in zip(self._nums, other._nums):
            if a > b:
                return False
            if a < b:
                return True
        return len(self._nums) < len(other._nums)

    def __hash__(self):
        return hash(self._nums)

    def extend(self, new_len):
        if new_len < 0:
            raise ValueError(f"Invalid version length {new_len}")
        if len(self._nums) >= new_len:
            return Version(self._nums)
        nums = list(self._nums)
        nums.extend([0 for i in range(new_len - len(self._nums))])
        return Version(nums)

    def upgrade(self, idx):
        if idx < 0 or len(self._nums) < idx + 1:
            raise ValueError(
                f"Can't increment version number at index {idx} for version {self}"
            )
        nums = list(self._nums[:idx])
        nums.append(self._nums[idx] + 1)
        nums.extend([0 for i in range(len(self._nums) - idx - 1)])
        return Version(nums)


class VersionList:
    def __init__(self, versions):
        self._lst = sorted(versions)
        self._set = set(versions)
        if len(self._set) != len(self._lst):
            raise ValueError("Duplicate tags found")

    def __len__(self):
        return len(self._lst)

    @property
    def latest(self):
        if not self:
            raise RuntimeError("No versions, can't get the latest")
        return self._lst[-1]

    def release_next(self, scope):
        version = scope.next_version(self.latest)
        assert version not in self._set
        self._lst.append(version)
        self._set.add(version)
        return version


@dataclass
class TagParams:
    lightweight: bool = False
    message: str = "{}"


class TagList:
    DEFAULT_PREFIX = "v"
    DEFAULT_VERSION = Version((0, 0, 0))

    def __init__(self, repo_dir, prefix, versions):
        self._repo_dir = repo_dir
        self._prefix = prefix
        self._versions = versions

    @staticmethod
    def parse(repo_dir=None, prefix=None, strict=False):
        if repo_dir is None:
            repo_dir = os.getcwd()
        if prefix is None:
            prefix = TagList.DEFAULT_PREFIX

        cmd = [
            "git",
            "-C",
            repo_dir,
            "for-each-ref",
            "--format=%(refname)",
            "refs/tags/",
        ]
        output = run(*cmd)
        versions = output.splitlines()

        strip = f"refs/tags/{prefix}"
        for version in versions:
            if not version.startswith(strip):
                msg = f"Unexpected git for-each-ref output: {version}"
                if strict:
                    raise RuntimeError(msg)
                else:
                    logging.warning("%s", msg)
        versions = [version.removeprefix(strip) for version in versions]

        versions = [Version.parse(version, strict=strict) for version in versions]
        versions = [version for version in versions if version is not None]
        if not versions:
            versions = [TagList.DEFAULT_VERSION]

        return TagList(repo_dir, prefix, VersionList(versions))

    def release_next(self, scope, tag_params):
        version = self._versions.release_next(scope)
        tag_name = f"{self._prefix}{version}"

        cmd = ["git", "-C", self._repo_dir]
        if tag_params.lightweight:
            cmd += ["tag", tag_name]
        else:
            cmd += ["tag", "-a", "-m", tag_params.message.format(tag_name), tag_name]

        run(*cmd)


def parse_args(argv=None):
    if argv is None:
        argv = sys.argv[1:]

    epilog = R"""
The tag message (--message) can include Python's str.format() placeholders.
It will be format()ted with a single argument: the full tag name (for example,
v1.2.3).
"""

    parser = argparse.ArgumentParser(description=__doc__, epilog=epilog)

    parser.add_argument(
        "-p",
        "--prefix",
        default=TagList.DEFAULT_PREFIX,
        metavar="STR",
        help=f"""tag prefix ("{TagList.DEFAULT_PREFIX}" by default)""",
    )
    parser.add_argument(
        "-s",
        "--strict",
        action="store_true",
        help="error out on discovering malformed tags",
    )
    parser.add_argument(
        "-l",
        "--lightweight",
        action="store_true",
        help="create lightweight tags (annotated by default)",
    )
    parser.add_argument(
        "-m",
        "--message",
        metavar="FMT",
        default="{}",
        help="tag message format string",
    )
    parser.add_argument(
        "release_scope", choices=ReleaseScope, type=ReleaseScope, help="release scope"
    )
    parser.add_argument(
        "repo_dir",
        metavar="DIR",
        nargs="?",
        help="path to repository (working directory by default)",
    )

    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(argv)
    with setup_logging():
        tags = TagList.parse(args.repo_dir, args.prefix, strict=args.strict)
        tag_params = TagParams(args.lightweight, args.message)
        tags.release_next(args.release_scope, tag_params)
    return 0


if __name__ == "__main__":
    sys.exit(main())
