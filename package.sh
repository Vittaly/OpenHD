#!/bin/bash

set -euo pipefail

CUSTOM="${1}"
PACKAGE_ARCH="${2}"
OS="${3}"

PKGDIR="/tmp/openhd-installdir"
VERSION="2.5.2-beta-$(date '+%Y%m%d%H%M')-$(git rev-parse --short HEAD)"

create_package_directory() {
  rm -rf "${PKGDIR}"
  mkdir -p "${PKGDIR}"/{usr/local/bin,tmp,settings,etc/systemd/system}
  # rpi only - copy the camera config files
  if [[ "${OS}" == "raspbian" ]] && [[ "${PACKAGE_ARCH}" == "armhf" ]]; then
    echo "________"
    echo "building for raspberry"
    echo "________"
    mkdir -p "${PKGDIR}/boot/openhd/rpi_camera_configs"
    cp -r rpi_camera_configs/* "${PKGDIR}/boot/openhd/rpi_camera_configs/" || exit 1
  elif [[ "${OS}" == "debian" ]] && [[ "${PACKAGE_ARCH}" == "arm64" ]]; then
    mkdir -p "${PKGDIR}/boot/openhd/rock5_camera_configs"
    cp -r rock5_camera_configs/* "${PKGDIR}/boot/openhd/rock5_camera_configs/" || exit 1
  fi
  # We do not copy the openhd service for x86, since there we have launcher on the desktop
  # (Otherwise, we always copy it)
  if [[ "${PACKAGE_ARCH}" != "x86_64" ]]; then
    cp systemd/openhd.service "${PKGDIR}/etc/systemd/system/openhd.service" || exit 1
  fi
  # always - copy the hardware.config file, the custom unmanaged camera service and the .sh file for it
  mkdir -p "${PKGDIR}/boot/openhd/"
  cp OpenHD/ohd_common/config/hardware.config "${PKGDIR}/boot/openhd/hardware.config" || exit 1
  mkdir -p "${PKGDIR}/boot/openhd/scripts/"
  cp scripts/custom_unmanaged_camera.sh ${PKGDIR}/boot/openhd/scripts/ || exit 1
  cp systemd/custom_unmanaged_camera.service "${PKGDIR}/etc/systemd/system/custom_unmanaged_camera.service" || exit 1
}

build_package() {
  
  if [[ "${PACKAGE_ARCH}" == "armhf" ]]; then
      if [[ "${CUSTOM}" == "standard" ]]; then
      echo "this is cake"
      PACKAGE_NAME="openhd"
      PACKAGES="-d libcamera-openhd -d gst-openhd-plugins -d iw -d nmap -d aircrack-ng -d i2c-tools -d libv4l-dev -d libusb-1.0-0 -d libpcap-dev -d libnl-3-dev -d libnl-genl-3-dev -d libsdl2-2.0-0 -d libsodium-dev -d gstreamer1.0-plugins-base -d gstreamer1.0-plugins-good -d gstreamer1.0-plugins-bad -d gstreamer1.0-plugins-ugly -d gstreamer1.0-libav -d gstreamer1.0-tools -d gstreamer1.0-alsa -d gstreamer1.0-pulseaudio"
      PLATFORM_CONFIGS=""
      else
      echo "this isn't cake"
      PACKAGE_NAME="openhd-x20"
      PACKAGES="-d iw -d i2c-tools -d libv4l-dev -d libusb-1.0-0 -d libpcap-dev -d libnl-3-dev -d libnl-genl-3-dev -d libsdl2-2.0-0 -d libsodium-dev -d gstreamer1.0-plugins-base -d gstreamer1.0-plugins-good -d gstreamer1.0-plugins-bad -d gstreamer1.0-tools"
      PLATFORM_CONFIGS=""
      fi
  else
    echo "this isn't cake and also not pi"
    PACKAGE_NAME="openhd"
    PACKAGES="-d iw -d nmap -d aircrack-ng -d i2c-tools -d libv4l-dev -d libusb-1.0-0 -d libpcap-dev -d libnl-3-dev -d libnl-genl-3-dev -d libsdl2-2.0-0 -d libsodium-dev -d gstreamer1.0-plugins-base -d gstreamer1.0-plugins-good -d gstreamer1.0-plugins-bad -d gstreamer1.0-plugins-ugly -d gstreamer1.0-libav -d gstreamer1.0-tools -d gstreamer1.0-alsa -d gstreamer1.0-pulseaudio"
    PLATFORM_CONFIGS=""
  fi
  
  rm "${PACKAGE_NAME}_${VERSION}_${PACKAGE_ARCH}.deb" > /dev/null 2>&1 || true
  
  cmake OpenHD/
  make -j4
  cp openhd ${PKGDIR}/usr/local/bin/openhd

  fpm -a "${PACKAGE_ARCH}" -s dir -t deb -n "${PACKAGE_NAME}" -v "${VERSION}" -C "${PKGDIR}" \
    ${PLATFORM_CONFIGS} \
    -p "${PACKAGE_NAME}_${VERSION}_${PACKAGE_ARCH}.deb" \
    --after-install after-install.sh \
    --before-install before-install.sh \
    ${PACKAGES} 
}

  #Main Build
  create_package_directory
  build_package
