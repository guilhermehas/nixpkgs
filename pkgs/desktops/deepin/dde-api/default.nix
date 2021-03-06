{ stdenv, buildGoPackage, fetchFromGitHub, pkgconfig,
  alsaLib,
  bc,
  blur-effect,
  coreutils,
  dbus-factory,
  deepin,
  deepin-gettext-tools,
  fontconfig,
  go,
  go-dbus-factory,
  go-gir-generator,
  go-lib,
  grub2,
  gtk3,
  libcanberra,
  libgudev,
  librsvg,
  poppler,
  pulseaudio,
  rfkill,
  xcur2png
}:

buildGoPackage rec {
  pname = "dde-api";
  version = "5.0.0";

  goPackagePath = "pkg.deepin.io/dde/api";

  src = fetchFromGitHub {
    owner = "linuxdeepin";
    repo = pname;
    rev = version;
    sha256 = "0iv4krj6dqdknwvmax7aj40k1h96259kqcfnljadrwpl7cvsvp5p";
  };

  goDeps = ./deps.nix;

  outputs = [ "out" ];

  nativeBuildInputs = [
    pkgconfig
    deepin-gettext-tools # build
    dbus-factory         # build
    deepin.setupHook

    # TODO: using $PATH to find run time executable does not work with cross compiling
    bc          # run (to adjust grub theme?)
    blur-effect # run (is it really needed?)
    coreutils   # run (is it really needed?)
    fontconfig  # run (is it really needed?)
    rfkill      # run
    xcur2png    # run
    grub2       # run (is it really needed?)
  ];

  buildInputs = [
    go-dbus-factory      # needed
    go-gir-generator     # needed
    go-lib               # build

    alsaLib     # needed
    #glib        # ? arch
    gtk3        # build run
    libcanberra # build run
    libgudev    # needed
    librsvg     # build run
    poppler     # build run
    pulseaudio  # needed
    #locales     # run (locale-helper needs locale-gen, which is unavailable on NixOS?)
  ];

  postPatch = ''
    searchHardCodedPaths  # debugging

    fixPath $out /usr/lib/deepin-api \
      lunar-calendar/main.go \
      misc/services/com.deepin.api.CursorHelper.service \
      misc/services/com.deepin.api.Graphic.service \
      misc/services/com.deepin.api.LunarCalendar.service \
      misc/services/com.deepin.api.Pinyin.service \
      misc/system-services/com.deepin.api.Device.service \
      misc/system-services/com.deepin.api.LocaleHelper.service \
      misc/system-services/com.deepin.api.SoundThemePlayer.service \
      misc/systemd/system/deepin-shutdown-sound.service \
      theme_thumb/gtk/gtk.go \
      thumbnails/gtk/gtk.go
    fixPath $out /boot/grub Makefile     # TODO: confirm where to install grub themes
    fixPath $out /var Makefile

    # This package wants to install polkit local authority files into
    # /var/lib. Nix does not allow a package to install files into /var/lib
    # because it is outside of the Nix store and should contain applications
    # state information (persistent data modified by programs as they
    # run). Polkit looks for them in both /etc/polkit-1 and
    # /var/lib/polkit-1 (with /etc having priority over /var/lib). An
    # work around is to install them to $out/etc and simlnk them to
    # /etc in the deepin module.

    sed -i -e "s,/var/lib/polkit-1,/etc/polkit-1," Makefile
  '';

  buildPhase = ''
    export GOCACHE="$TMPDIR/go-cache";
    make -C go/src/${goPackagePath}
  '';

  installPhase = ''
    make install PREFIX="$out" SYSTEMD_LIB_DIR="$out/lib" -C go/src/${goPackagePath}
    mv $out/share/gocode $out/share/go
    remove-references-to -t ${go} $out/bin/* $out/lib/deepin-api/*
  '';

  postFixup = ''
    searchHardCodedPaths $out  # debugging
  '';

  passthru.updateScript = deepin.updateScript { name = "${pname}-${version}"; };

  meta = with stdenv.lib; {
    description = "Go-lang bindings for dde-daemon";
    homepage = "https://github.com/linuxdeepin/dde-api";
    license = licenses.gpl3;
    platforms = platforms.linux;
    maintainers = with maintainers; [ romildo ];
  };
}
