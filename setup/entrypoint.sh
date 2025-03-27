#!/bin/bash

# exit on error
set -e

# if not root, just source and execute the command
if [ ! $UID -eq 0 ]; then
    # Execute given command
    exec "$@"
    # never returns
fi

CONT_HOME_DIR=/home/${CONT_USER}

# create user and give it sudo rights
mkdir -p /home/${CONT_USER} && 
    echo "${CONT_USER}:x:${CONT_UID}:${CONT_GID}:${CONT_USER},,,:${CONT_HOME_DIR}:/bin/bash" >> /etc/passwd && 
    echo "${CONT_USER}:x:${CONT_GID}:" >> /etc/group &&
    pwconv && 
    cp -r /etc/skel/. /home/${CONT_USER}/ &&
    echo "${CONT_USER} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/99_${CONT_USER} && 
    chmod 0440 /etc/sudoers.d/99_${CONT_USER} &&
    chown ${CONT_UID}:${CONT_GID} -R ${CONT_HOME_DIR}


# enable bash completion for apt
sed -i -e 's/^/#/' /etc/apt/apt.conf.d/docker-clean

# uncomment line with force_color_prompt=yes
sed -i '/force_color_prompt=yes/s/^#//g' ${CONT_HOME_DIR}/.bashrc

# comment line with force_color_prompt=yes
#sed -i '/force_color_prompt=yes/s/^/#/g' ${CONT_HOME_DIR}/.bashrc 

# check CONT_DIR
if [ ! -d "$CONT_PWD" ] ; then
    echo "ERROR: ENV CONT_PWD=$CONT_PWD not valid." 1>&2
    echo "  Dir '$CONT_PWD' does not exist." 1>&2
    exit 1
fi

#exec cp /etc/skel/.bashrc /home/devel/.bashrc

# transform args to string for bash -c ""
cmd=''
for i in "$@"; do 
    cmd="$cmd ${i@Q}"
done

# run command
exec runuser \
    -u $CONT_USER \
    -- \
    bash -c "cd $CONT_PWD && $cmd"


