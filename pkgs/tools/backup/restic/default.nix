{ stdenv, lib, buildGoPackage, fetchFromGitHub, nixosTests}:

buildGoPackage rec {
  pname = "restic";
  version = "0.9.6";

  goPackagePath = "github.com/restic/restic";

  src = fetchFromGitHub {
    owner = "restic";
    repo = "restic";
    rev = "v${version}";
    sha256 = "0lydll93n1lcn1fl669b9cikmzz9d6vfpc8ky3ng5fi8kj3v1dz7";
  };

  passthru.tests.restic = nixosTests.restic;

  # Use a custom install phase here as by default the
  # build-release-binaries and prepare-releases binaries are
  # installed.
  installPhase = ''
    mkdir -p "$bin/bin"
    cp go/bin/restic "$bin/bin"
  '' + lib.optionalString (stdenv.hostPlatform == stdenv.buildPlatform) ''
    mkdir -p \
      $bin/etc/bash_completion.d \
      $bin/share/zsh/vendor-completions \
      $bin/share/man/man1
    $bin/bin/restic generate \
      --bash-completion $bin/etc/bash_completion.d/restic.sh \
      --zsh-completion $bin/share/zsh/vendor-completions/_restic \
      --man $bin/share/man/man1
  '';

  meta = with lib; {
    homepage = "https://restic.net";
    description = "A backup program that is fast, efficient and secure";
    platforms = platforms.linux ++ platforms.darwin;
    license = licenses.bsd2;
    maintainers = [ maintainers.mbrgm ];
  };
}
