#!/usr/bin/env python
# -*- coding: utf-8 -*-
""" Additional filters for the j2cli

:see: https://github.com/kolypto/j2cli#filters
"""


def translate(s: str) -> str:
    if s == "foo":
        return "bar"
    elif s == "bar":
        return "foo"
    else:
        return s
