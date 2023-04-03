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
  exec = "Vs.\ Tricky";

  desktopItem = makeDesktopItem {
    name = "trickster";
    inherit exec;
    desktopName = "Friday Night Funkin: Vs. Tricky";
    categories = [ "Game" "ArcadeGame" ];
    icon = "trickster";
  };
in
stdenv.mkDerivation rec {
  pname = "trickster";
  version = "unstable-2021-06-15";

  src = fetchFromGitHub {
    owner = "KadeDev";
    repo = "trickster";
    rev = "85419e36f78a28e76583c2508af54707265edef0";
    sha256 = "sha256-YIjSZZ33qH+Gnz+PXondnpR+E9RWPGI6bB4cYTsexO8=";
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
    mkdir -p $out/{bin,lib/${pname}}
    cp -R export/release/linux/bin/* $out/lib/${pname}/
    for so in $out/lib/${pname}/{"${exec}",lime.ndll}; do
      $STRIP -s "$so"
    done
    wrapProgram "$out/lib/${pname}/${exec}" \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath buildInputs} \
      --chdir "$out/lib/${pname}"
    ln -s $out/{lib/${pname},bin}/"${exec}"
    # desktop file
    mkdir -p $out/share/applications
    ln -s ${desktopItem}/share/applications/* $out/share/applications
    # icons
    for i in 16 32 64; do
      install -D art/icon$i.png $out/share/icons/hicolor/''${i}x$i/${pname}.png
    done
    runHook postInstall
  '';

  meta = with lib; {
    description = "Friday Night Funkin': Vs. Tricky";
    license = licenses.asl20;
    platforms = platforms.linux;
    maintainers = with maintainers; [ infinidoge ];
    mainProgram = exec;
  };
}
