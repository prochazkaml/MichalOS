#!/bin/bash

cc zx7.c optimize.c compress.c -o segmented_zx7
cc appzx7.c optimize.c compress.c -o app_zx7
