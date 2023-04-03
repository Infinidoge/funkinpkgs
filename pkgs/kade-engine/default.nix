{ stdenv
, lib
, fetchFromGitHub
, fetchpatch
, haxe
, haxePackages
, neko
, makeWrapper
, imagemagick
, alsa-lib
, libpulseaudio
, libGL
, libX11
, libXdmcp
, libXext
, libXi
, libXinerama
, libXrandr
, makeDesktopItem
}:

let
  desktopItem = makeDesktopItem {
    name = "kade-engine";
    exec = "Kade Engine";
    desktopName = "Friday Night Funkin: Kade Engine";
    categories = [ "Game" "ArcadeGame" ];
    icon = "kade-engine";
  };
in
stdenv.mkDerivation rec {
  pname = "kade-engine";
  version = "unstable-2021-10-30";

  src = fetchFromGitHub {
    owner = "KadeDev";
    repo = "Kade-Engine";
    rev = "b1fe905d9cfdcd10705f48ff47d62d1165d6c63a";
    sha256 = "sha256-8OMUV438jbNyr8hL1sKGVm4wVmjU5T0BC69ZDs+fZq8=";
  };

  patches = [
    ./dont-use-cwd-for-state.patch
  ];

  postPatch = ''
    mv Project.xml project.xml
  '';

  nativeBuildInputs = [ haxe neko makeWrapper imagemagick ]
    ++ (with haxePackages; [
    hxcpp
    hscript
    openfl
    lime
    flixel
    flixel-addons
    flixel-ui
    newgrounds
    polymod
    discord_rpc
    actuate
    flixel-tools
    faxe
    linc_luajit
    hxvm-luajit
    extension-webm
  ]);

  buildInputs = [ alsa-lib libpulseaudio libGL libX11 libXdmcp libXext libXi libXinerama libXrandr ];

  enableParallelBuilding = true;

  buildPhase = ''
    runHook preBuild
    export HOME=$PWD
    haxelib run lime build linux -final --debug
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/{bin,lib/kade-engine}
    cp -R export/release/linux/bin/* $out/lib/kade-engine/
    for so in $out/lib/kade-engine/{Kade\ Engine,lime.ndll}; do
      $STRIP -s "$so"
    done
    wrapProgram $out/lib/kade-engine/Kade\ Engine \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath buildInputs} \
      --chdir "$out/lib/kade-engine"
    ln -s $out/{lib/kade-engine,bin}/Kade\ Engine
    # desktop file
    mkdir -p $out/share/applications
    ln -s ${desktopItem}/share/applications/* $out/share/applications
    # icons
    for i in 16 32 64 128 256 512; do
      install -D art/icon$i.png $out/share/icons/hicolor/''${i}x$i/kade-engine.png
    done
    runHook postInstall
  '';

  meta = with lib; {
    description = "A Competitive Rhythm Game engine rewrite for FNF with Quality of Life features included.";
    license = licenses.asl20;
    platforms = platforms.all;
    maintainers = with maintainers; [ infinidoge ];
    broken = stdenv.system != "x86_64-linux";
    mainProgram = "Kade\ Engine";
  };
}
