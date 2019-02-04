ARG FROM_ARG
FROM ${FROM_ARG}

ENV USERNAME autoware
USER autoware

# Install Autoware
RUN cd && mkdir /home/$USERNAME/Autoware
COPY --chown=autoware ./ /home/$USERNAME/Autoware/
RUN /bin/bash -c 'source /opt/ros/kinetic/setup.bash; \
                  cd /home/$USERNAME/Autoware/ros/src; \
                  catkin_init_workspace; \
                  cd ../; \
                  ./catkin_make_release'
RUN echo "source /home/$USERNAME/Autoware/ros/devel/setup.bash" >> /home/$USERNAME/.bashrc

# Set working directory to /home
WORKDIR /home/$USERNAME

# Default CMD
CMD ["/bin/bash"]
