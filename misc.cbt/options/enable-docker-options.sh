#!/bin/bash

cd /compile/source/linux-stable-tg

for i in `cat /compile/doc/stable-tg/misc.cbt/options/docker-options-mod.txt`; do
  echo $i
  ./scripts/config -m $i
done

for i in `cat /compile/doc/stable-tg/misc.cbt/options/docker-options-yes.txt`; do
  echo $i
  ./scripts/config -e $i
done
