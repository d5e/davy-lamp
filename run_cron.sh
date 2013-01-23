#!/bin/bash
#
for i in {1..29}
do
  curl http://heartbeat.sternzeit.de/heartbeat/run
  sleep 2
done
