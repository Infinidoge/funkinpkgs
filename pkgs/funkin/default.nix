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
    name = "funkin";
    exec = "Funkin";
    desktopName = "Friday Night Funkin";
    categories = [ "Game" "ArcadeGame" ];
    icon = "funkin";
  };
in
stdenv.mkDerivation rec {
  pname = "funkin";
  version = "unstable-2023-01-31";

  src = fetchFromGitHub {
    owner = "ninjamuffin99";
    repo = "Funkin";
    rev = "b644b6f8fe21699a486b3a6ce9fad7e4abfdc1b9";
    sha256 = "sha256-UlPWVx0zBzCVIZ5nGmLVRgOfWz/9thnCwJsjlQAvQuI=";
  };

  postPatch = ''
    # Real API keys are stripped from repo
    cat >source/APIStuff.hx <<EOF
    package;

    class APIStuff
    {
      inline public static var API:String = "51348:TtzK0rZ8";
      inline public static var EncKey:String = "5NqKsSVSNKHbF9fPgZPqPg==";
      inline public static var SESSION:String = null;
    }
    EOF
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
  ]);

  buildInputs = [ alsa-lib libpulseaudio libGL libX11 libXdmcp libXext libXi libXinerama libXrandr ];

  enableParallelBuilding = true;

  buildPhase = ''
    runHook preBuild
    export HOME=$PWD
    haxelib run lime build linux -final
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/{bin,lib/funkin}
    cp -R export/release/linux/bin/* $out/lib/funkin/
    for so in $out/lib/funkin/{Funkin,lime.ndll}; do
      $STRIP -s $so
    done
    wrapProgram $out/lib/funkin/Funkin \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath buildInputs} \
      --run "cd $out/lib/funkin"
    ln -s $out/{lib/funkin,bin}/Funkin
    # desktop file
    mkdir -p $out/share/applications
    ln -s ${desktopItem}/share/applications/* $out/share/applications
    # icons
    for i in 16 32 64; do
      install -D art/icon$i.png $out/share/icons/hicolor/''${i}x$i/funkin.png
    done
    runHook postInstall
  '';

  meta = with lib; {
    description = "Friday Night Funkin'";
    longDescription = ''
      Uh oh! Your tryin to kiss ur hot girlfriend, but her MEAN and EVIL dad is
      trying to KILL you! He's an ex-rockstar, the only way to get to his
      heart? The power of music...
      WASD/ARROW KEYS IS CONTROLS
      - and + are volume control
      0 to Mute
      It's basically like DDR, press arrow when arrow over other arrow.
      And uhhh don't die.
    '';
    homepage = "https://ninja-muffin24.itch.io/funkin";
    license = licenses.asl20;
    platforms = platforms.linux;
    maintainers = with maintainers; [ infinidoge ];
    mainProgram = "Funkin";
  };
}
