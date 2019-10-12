#!/bin/bash
docker ps -a | grep -Ei 'rpaas:v1' | awk '{print $1}' | xargs -I {} docker rm -f {}
