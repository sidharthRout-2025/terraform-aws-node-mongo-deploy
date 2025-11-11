#!/bin/bash
set -ex
# install ecs agent and docker - Amazon Linux 2 recommended but here we use Amazon Linux 2 AMI implicitly via ami lookup
echo "ECS_CLUSTER=${cluster_name}" > /etc/ecs/ecs.config
# install log driver & start agent if not already present (Amazon Linux 2 images already include)
