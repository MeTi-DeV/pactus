#!/bin/bash

# Set –e is used within the Bash to stop execution instantly as a query exits
# while having a non-zero status.
set -e

ROOT_DIR="$(pwd)"
VERSION="$(echo `git -C ${ROOT_DIR} describe --abbrev=0 --tags` | sed 's/^.//')" # "v1.2.3" -> "1.2.3"
BUILD_DIR="${ROOT_DIR}/build"
PACKAGE_NAME="pactus-gui_${VERSION}"
PACKAGE_DIR="${ROOT_DIR}/${PACKAGE_NAME}"

mkdir ${PACKAGE_DIR}

echo "Building the binaries"

# This fixes a bug in pkgconfig: invalid flag in pkg-config --libs: -Wl,-luuid
sed -i -e 's/-Wl,-luuid/-luuid/g' /mingw64/lib/pkgconfig/gdk-3.0.pc

go build -ldflags "-s -w" -o ${BUILD_DIR}/pactus-daemon.exe ./cmd/daemon
go build -ldflags "-s -w" -o ${BUILD_DIR}/pactus-wallet.exe ./cmd/wallet
go build -ldflags "-s -w -H windowsgui" -tags gtk -o ${BUILD_DIR}/pactus-gui.exe ./cmd/gtk

# Copying the neccesary libraries
echo "Creating GUI directory"
GUI_DIR="${PACKAGE_DIR}/pactus-gui/"
mkdir ${GUI_DIR}

echo "Changing working directory to MSYS2 MINGW64."
cd "${MINGW_PREFIX}" # https://github.com/msys2/setup-msys2/issues/150
echo "Copying dlls from ${MINGW_PREFIX}"

echo "Copying DLLs and EXEs."
cd ./bin
cp \
  "gdbus.exe" \
  "gspawn-win64-helper.exe" \
  "gspawn-win64-helper-console.exe" \
  "libatk-1.0-0.dll" \
  "libbrotlicommon.dll" \
  "libbrotlidec.dll" \
  "libbz2-1.dll" \
  "libcairo-2.dll" \
  "libcairo-gobject-2.dll" \
  "libdatrie-1.dll" \
  "libdeflate.dll" \
  "libepoxy-0.dll" \
  "libexpat-1.dll" \
  "libffi-8.dll" \
  "libfontconfig-1.dll" \
  "libfreetype-6.dll" \
  "libfribidi-0.dll" \
  "libgcc_s_seh-1.dll" \
  "libgdk_pixbuf-2.0-0.dll" \
  "libgdk-3-0.dll" \
  "libgio-2.0-0.dll" \
  "libglib-2.0-0.dll" \
  "libgmodule-2.0-0.dll" \
  "libgobject-2.0-0.dll" \
  "libgomp-1.dll" \
  "libgraphite2.dll" \
  "libgtk-3-0.dll" \
  "libharfbuzz-0.dll" \
  "libiconv-2.dll" \
  "libintl-8.dll" \
  "libjbig-0.dll" \
  "libjpeg-8.dll" \
  "libLerc.dll" \
  "liblzma-5.dll" \
  "libpango-1.0-0.dll" \
  "libpangocairo-1.0-0.dll" \
  "libpangoft2-1.0-0.dll" \
  "libpangowin32-1.0-0.dll" \
  "libpcre2-16-0.dll" \
  "libpcre2-32-0.dll" \
  "libpcre2-8-0.dll" \
  "libpcre2-posix-3.dll" \
  "libpixman-1-0.dll" \
  "libpng16-16.dll" \
  "librsvg-2-2.dll" \
  "libstdc++-6.dll" \
  "libsystre-0.dll" \
  "libthai-0.dll" \
  "libtiff-5.dll" \
  "libtre-5.dll" \
  "libwebp-7.dll" \
  "libwinpthread-1.dll" \
  "libxml2-2.dll" \
  "libzstd.dll" \
  "zlib1.dll" \
  "${GUI_DIR}"
cd -

echo "Copying Adwaita theme."
mkdir -p "${GUI_DIR}/share/icons/Adwaita"
cd 'share/icons/Adwaita/'
mkdir -p "${GUI_DIR}/share/icons/Adwaita/scalable"
cp -r \
  "scalable/actions" \
  "scalable/devices" \
  "scalable/mimetypes" \
  "scalable/places" \
  "scalable/status" \
  "scalable/ui" \
  "${GUI_DIR}/share/icons/Adwaita/scalable"
cp 'index.theme' "${GUI_DIR}/share/icons/Adwaita"
mkdir -p "${GUI_DIR}/share/icons/Adwaita/cursors"
cp -r \
  "cursors/plus.cur" \
  "cursors/sb_h_double_arrow.cur" \
  "cursors/sb_left_arrow.cur" \
  "cursors/sb_right_arrow.cur" \
  "cursors/sb_v_double_arrow.cur" \
  "${GUI_DIR}/share/icons/Adwaita/cursors"
cd -

echo "Copying GDK pixbuf."
mkdir -p "${GUI_DIR}/lib"
cp -r 'lib/gdk-pixbuf-2.0' "${GUI_DIR}/lib/gdk-pixbuf-2.0"

echo "Copying GLib schemas."
mkdir -p "${GUI_DIR}/share/glib-2.0/schemas"
cp 'share/glib-2.0/schemas/gschemas.compiled' "${GUI_DIR}/share/glib-2.0/schemas"

echo "Creating GTK settings.ini."
mkdir -p "${GUI_DIR}/share/gtk-3.0/"
echo '[Settings] gtk-button-images=1' > "${GUI_DIR}/share/gtk-3.0/settings.ini"

# Moving binaries to package directory
cd ${ROOT_DIR}
echo "Moving binaries"
mv ${BUILD_DIR}/pactus-gui.exe     ${PACKAGE_DIR}/pactus-gui/pactus-gui.exe
mv ${BUILD_DIR}/pactus-wallet.exe  ${PACKAGE_DIR}/pactus-wallet.exe
mv ${BUILD_DIR}/pactus-daemon.exe  ${PACKAGE_DIR}/pactus-daemon.exe


echo "Archiving the package"
7z a ${ROOT_DIR}/${PACKAGE_NAME}_windows_amd64.zip ${PACKAGE_DIR}

echo "Creating installer"
echo "
[Setup]
Appname=Pactus
AppVersion=${VERSION}
DefaultDirName={autopf64}/Pactus
DefaultGroupName=Pactus
[Files]
Source:${PACKAGE_NAME}/*; DestDir:{app}; Flags: recursesubdirs
[Icons]
Name:{group}\\Pactus GUI; Filename:{app}\\pactus-gui\\pactus-gui.exe;" >> ${ROOT_DIR}/inno.iss

cd ${ROOT_DIR}
INNO_DIR=$(cygpath -w -s "/c/Program Files (x86)/Inno Setup 6")
${INNO_DIR}/ISCC.exe ${ROOT_DIR}/inno.iss
mv Output/mysetup.exe ${ROOT_DIR}/${PACKAGE_NAME}_windows_amd64_installer.exe
