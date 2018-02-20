#!/bin/bash

echo -n '#define GIT_VERSION "'
git describe --always | tr -d '\n'
echo '"'