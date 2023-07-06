#!/usr/bin/env bash

echo ${MACHINE_ID} | sudo tee /etc/machine-id
/usr/bin/sudo /usr/sbin/sshd -D -o ListenAddress=0.0.0.0
