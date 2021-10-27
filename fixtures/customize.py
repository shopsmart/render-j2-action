#!/usr/bin/env python
# -*- coding: utf-8 -*-
""" Setup configurations for the j2cli

:see: https://github.com/kolypto/j2cli#customization
"""


def alter_context(context):
    """ Modify the context and return it """

    context['foo'] = 'bar'
    return context
