#!/bin/bash

ross()
{
    . /opt/ros/$ROS_DISTRO/setup.bash
}


rospals()
{
    . /opt/pal/setup.bash
}


if [[ "$CONT_PWD_AUTO_SOURCE_SETUP" == true ]] ; then
    if [ -f "$CONT_PWD/setup_devcont.sh" ] ; then
        . "$CONT_PWD/setup_devcont.sh"
    fi
fi

