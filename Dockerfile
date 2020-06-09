#------- Builder stage
FROM athackst/ros:kinetic-dev as builder

WORKDIR /workspaces/deepracer_ws/src
# Get the aws messages
RUN git clone https://github.com/athackst/aws_deepracer_msgs.git
# Copy this package
COPY . deepracer_joy
WORKDIR /workspaces/deepracer_ws
RUN rosdep update \
  # Get all dependencies
  && apt-get update \
  && rosdep install --from-paths src --ignore-src -y \
  && rm -rf /var/lib/apt/lists/* \
  # Make and install the packages
  && catkin_make -DCMAKE_INSTALL_PREFIX=/opt/deepracer_ws install

#------- Deployment stage
FROM athackst/ros:kinetic-base

RUN apt-get update && apt-get install -y \
  jstest-gtk \
  && rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/deepracer_ws/ /opt/deepracer_ws/
# Get all dependencies
RUN rosdep init \
  && rosdep update \
  && apt-get update \
  && rosdep install --from-paths /opt/deepracer_ws --ignore-src -y \
  && rm -rf /var/lib/apt/lists/*

# Set up environment
ENV ROS_PACKAGE_PATH=/opt/deepracer_ws/share:$ROS_PACKAGE_PATH
ENV LD_LIBRARY_PATH=/opt/deepracer_ws/lib:$LD_LIBRARY_PATH
ENV ROSLISP_PACKAGE_DIRECTORIES=
ENV PYTHONPATH=/opt/deepracer_ws/lib/python2.7/dist-packages:$PYTHONPATH
ENV PKG_CONFIG_PATH=/opt/deepracer_ws/lib/pkgconfig:$PKG_CONFIG_PATH

CMD ["bash", "-c", "roslaunch deepracer_joy deepracer_joy.launch"]