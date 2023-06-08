# This is the Containerfile for your custom image. 

# It takes in the recipe, version, and base image as arguments,
# all of which are provided by build.yml when doing builds
# in the cloud. The ARGs have default values, but changing those
# does nothing if the image is built in the cloud.

ARG FEDORA_MAJOR_VERSION=38
# Warning: changing this might not do anything for you. Read comment above.
ARG BASE_IMAGE_URL=ghcr.io/ublue-os/silverblue-main

FROM ${BASE_IMAGE_URL}:${FEDORA_MAJOR_VERSION}

# The default recipe set to the recipe's default filename
# so that `podman build` should just work for many people.
ARG RECIPE=./recipe.yml

# Copy static configurations and component files.
# Warning: If you want to place anything in "/etc" of the final image, you MUST
# place them in "./usr/etc" in your repo, so that they're written to "/usr/etc"
# on the final system. That is the proper directory for "system" configuration
# templates on immutable Fedora distros, whereas the normal "/etc" is ONLY meant
# for manual overrides and editing by the machine's admin AFTER installation!
# See issue #28 (https://github.com/ublue-os/startingpoint/issues/28).
COPY usr /usr

# Copy the recipe that we're building.
COPY ${RECIPE} /usr/share/ublue-os/recipe.yml

# "yq" used in build.sh and the "setup-flatpaks" just-action to read recipe.yml.
# Copied from the official container image since it's not available as an RPM.
COPY --from=docker.io/mikefarah/yq /usr/bin/yq /usr/bin/yq

# Copy the build script and all custom scripts.
COPY scripts /tmp/scripts

# Add additional repos
RUN wget https://copr.fedorainfracloud.org/coprs/ganto/lxc4/repo/fedora-"${FEDORA_MAJOR_VERSION}"/ganto-lxc4-fedora-"${FEDORA_MAJOR_VERSION}".repo -O /etc/yum.repos.d/ganto-lxc4-fedora-"${FEDORA_MAJOR_VERSION}".repo
RUN wget https://terra.fyralabs.com/terra.repo -O /etc/yum.repos.d/terra.repo


# Additional packages
RUN rpm-ostree install fail2ban && systemctl enable fail2ban
RUN rpm-ostree install code
RUN rpm-ostree install lxd lxc
RUN rpm-ostree install iotop dbus-x11 podman-compose podman-docker podman-plugins podman-tui
RUN rpm-ostree install adobe-source-code-pro-fonts cascadiacode-nerd-fonts google-droid-sans-mono-fonts google-go-mono-fonts ibm-plex-mono-fonts jetbrains-mono-fonts-all mozilla-fira-mono-fonts powerline-fonts ubuntumono-nerd-fonts
RUN rpm-ostree install qemu qemu-user-static qemu-user-binfmt virt-manager libvirt qemu qemu-user-static qemu-user-binfmt edk2-ovmf
RUN rpm-ostree install cockpit-bridge cockpit-system cockpit-networkmanager cockpit-selinux cockpit-storaged cockpit-podman cockpit-machines cockpit-pcp
RUN rpm-ostree install cargo nodejs-npm p7zip p7zip-plugins powertop rust go
# Run the build script, then clean up temp files and finalize container build.
RUN chmod +x /tmp/scripts/build.sh && \
        /tmp/scripts/build.sh && \
        rm -rf /tmp/* /var/* && \
        ostree container commit
