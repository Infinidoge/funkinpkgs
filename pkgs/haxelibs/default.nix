{ stdenv
, multiStdenv
, lib
, fetchzip
, fetchFromGitHub
, writeText
, haxe
, neko
}:

let
  withCommas = lib.replaceStrings [ "." ] [ "," ];

  # simulate "haxelib dev $libname ."
  simulateHaxelibDev = libname: ''
    devrepo=$(mktemp -d)
    mkdir -p "$devrepo/${withCommas libname}"
    echo $(pwd) > "$devrepo/${withCommas libname}/.dev"
    export HAXELIB_PATH="$HAXELIB_PATH:$devrepo"
  '';

  installLibHaxe = { libname, version, files ? "*" }: ''
    mkdir -p "$out/lib/haxe/${withCommas libname}/${withCommas version}"
    echo -n "${version}" > $out/lib/haxe/${withCommas libname}/.current
    cp -dpR ${files} "$out/lib/haxe/${withCommas libname}/${withCommas version}/"
  '';

  buildHaxeLib =
    { libname
    , version
    , sha256 ? null
    , src ? null
    , meta
    , ...
    } @ attrs:
    stdenv.mkDerivation (attrs // {
      name = "${libname}-${version}";

      buildInputs = (attrs.buildInputs or [ ]) ++ [ haxe neko ]; # for setup-hook.sh to work
      src = attrs.src or (fetchzip rec {
        name = "${libname}-${version}";
        url = "http://lib.haxe.org/files/3.0/${withCommas name}.zip";
        inherit sha256;
        stripRoot = false;
      });

      installPhase = attrs.installPhase or ''
        runHook preInstall
        (
          if [ $(ls $src | wc -l) == 1 ]; then
            cd $src/* || cd $src
          else
            cd $src
          fi
          ${installLibHaxe { inherit libname version; }}
        )
        runHook postInstall
      '';

      meta = {
        homepage = "http://lib.haxe.org/p/${libname}";
        license = lib.licenses.bsd2;
        platforms = lib.platforms.all;
        description = throw "please write meta.description";
      } // attrs.meta;
    });
in
rec {
  hxcpp = buildHaxeLib rec {
    libname = "hxcpp";
    version = "4.2.1";
    sha256 = "10ijb8wiflh46bg30gihg7fyxpcf26gibifmq5ylx0fam4r51lhp";
    postFixup = ''
      for f in $out/lib/haxe/${withCommas libname}/${withCommas version}/{,project/libs/nekoapi/}bin/Linux{,64}/*; do
        chmod +w "$f"
        patchelf --set-interpreter $(cat $NIX_CC/nix-support/dynamic-linker)   "$f" || true
        patchelf --set-rpath ${ lib.makeLibraryPath [ stdenv.cc.cc ] }  "$f" || true
      done
    '';
    setupHook = writeText "setup-hook.sh" ''
      if [ "$\{enableParallelBuilding-}" ]; then
        export HXCPP_COMPILE_THREADS=$NIX_BUILD_CORES
      else
        export HXCPP_COMPILE_THREADS=1
      fi
    '';
    meta.description = "Runtime support library for the Haxe C++ backend";
  };

  hscript = buildHaxeLib {
    libname = "hscript";
    version = "2.4.0";
    sha256 = "0qdxgqb75j1v125l9xavs1d32wwzi60rhfymngdhjqhdvq72bhxx";
    meta = with lib; {
      license = licenses.mit;
      description = "Scripting engine for a subset of the Haxe language";
    };
  };

  lime = buildHaxeLib {
    libname = "lime";
    version = "7.9.0";
    sha256 = "sha256-7UBSgzQEQjmMYk2MGfMZPYSj3quWbiP8LWM+vtyeWFg=";
    meta = with lib; {
      license = licenses.mit;
      description = "Flexible, lightweight layer for Haxe cross-platform developers";
    };
  };

  openfl = buildHaxeLib {
    libname = "openfl";
    version = "9.1.0";
    sha256 = "0ri9s8d7973d2jz6alhl5i4fx4ijh0kb27mvapq28kf02sp8kgim";
    meta = with lib; {
      license = licenses.mit;
      description = "Open Flash Library for fast 2D development";
    };
  };

  actuate = buildHaxeLib {
    libname = "actuate";
    version = "1.9.0";
    sha256 = "sha256-9Z4PYjQKTmwT25xlP+5FDcCgOS2hPD45D4L0I2tIpvY=";
    meta = with lib; {
      license = licenses.mit;
      description = "A fast and flexible tween library that uses a jQuery-style 'chaining' syntax.";
    };
  };

  flixel = buildHaxeLib {
    libname = "flixel";
    version = "4.11.0";
    sha256 = "sha256-xgiBzXu+ieXbT8nxRuEqft3p4sYTOF+weQqzcYsf+o0=";
    meta = with lib; {
      license = licenses.mit;
      description = "2D game engine based on OpenFL that delivers cross-platform games";
    };
  };

  flixel-addons = buildHaxeLib {
    libname = "flixel-addons";
    version = "2.11.0";
    sha256 = "sha256-mRKpLzhlh1UXxIdg1/a0NTVzriNEW1wsSirL1UOkvAI=";
    meta = with lib; {
      license = licenses.mit;
      description = "Set of useful, but optional classes for HaxeFlixel created by the community";
    };
  };

  flixel-ui = buildHaxeLib {
    libname = "flixel-ui";
    version = "2.4.0";
    sha256 = "sha256-5oNeDQWkA8Sfrl+kEi7H2DLOc5N2DfbbcwiRw5DBSGw=";
    meta = with lib; {
      license = licenses.mit;
      description = "UI library for Flixel";
    };
  };

  flixel-tools = buildHaxeLib {
    libname = "flixel-tools";
    version = "1.5.1";
    sha256 = "sha256-0PvkU/r5pOQslo9b2SqRcDcBiKsb0Ete8QfrwSEPEaw=";
    meta = with lib; {
      license = licenses.mit;
      description = "Command-Line tools for the HaxeFlixel game engine";
    };
  };

  newgrounds = buildHaxeLib {
    libname = "newgrounds";
    version = "1.1.5";
    sha256 = "sha256-Aqc6HYPva3YyerMLgC9tsAVO8DJrko/sWZbVFCfeAsE=";
    meta = with lib; {
      license = licenses.mit;
      description = "Newgrounds API for haxe";
    };
  };

  polymod = buildHaxeLib {
    libname = "polymod";
    version = "1.5.2";
    sha256 = "sha256-iKikj+KDg8qanuA+50cleKwXXsitNUY2sqhRCVMslAo=";
    meta = with lib; {
      license = licenses.mit;
      description = "Atomic modding framework for Haxe games/apps";
    };
  };

  discord_rpc = buildHaxeLib {
    libname = "discord_rpc";
    version = "unstable-2021-03-26";
    src = fetchFromGitHub {
      owner = "Aidan63";
      repo = "linc_discord-rpc";
      rev = "2d83fa863ef0c1eace5f1cf67c3ac315d1a3a8a5";
      fetchSubmodules = true;
      sha256 = "0w3f9772ypqil348dq8xvhh5g1z5dii5rrwlmmvcdr2gs2c28c7k";
    };
    meta = with lib; {
      license = licenses.mit;
      description = "Native bindings for discord-rpc";
    };
  };

  linc_luajit = buildHaxeLib {
    libname = "linc_luajit";
    version = "unstable-2022-09-30";
    src = fetchFromGitHub {
      owner = "nebulazorua";
      repo = "linc_luajit";
      rev = "bcb4254e057f8a20710e2cd0985086370d57ecd1";
      sha256 = "sha256-LuBBbHntgc3OnQiK+4eaGW849p2GWOUfMppUQIQaor0=";
    };
    meta = with lib; {
      license = licenses.mit;
      description = "Haxe/hxcpp native bindings for LuaJIT";
    };
  };

  hxvm-luajit = buildHaxeLib {
    libname = "hxvm-luajit";
    version = "unstable-2021-10-18";
    src = fetchFromGitHub {
      owner = "nebulazorua";
      repo = "hxvm-luajit";
      rev = "5d59ea1172be619bcda2668e27b828fdb10d78d7";
      sha256 = "sha256-/Non4Y0vUz5+b7WpuhcehXVoa1e7qdZlh28v2sZDYGk=";
    };
    meta = with lib; {
      license = licenses.mit;
      description = "Haxe Lua Bindings (Embed Lua runtime in your Haxe app)";
    };
  };

  faxe = buildHaxeLib {
    libname = "faxe";
    version = "unstable-2019-07-26";
    src = fetchFromGitHub {
      owner = "ashea-code";
      repo = "faxe";
      rev = "89be1d2f82f65a94ee3e0e8a01681fe1f0332228";
      sha256 = "sha256-U6I4xocQObK+F7rKOrCVcEZA6abVo3kLuzoedb0lGv8=";
    };
    meta = with lib; {
      license = licenses.mit;
      description = "FMOD Audio Engine for Haxe";
    };
  };

  extension-webm = multiStdenv.mkDerivation rec {
    pname = "extension-webm";
    version = "unstable-2021-06-01";


    src = fetchFromGitHub {
      owner = "KadeDev";
      repo = "extension-webm";
      rev = "809fda4776b11dd4ba15002c68249600b8bc1db0";
      sha256 = "sha256-dhJVlAVUev9ZqDQyGbicbSVxP90L7liLBnMgwP/lzbk=";
    };

    buildInputs = [ haxe neko lime hxcpp ];

    buildPhase = ''
      runHook preBuild

      export HOME=$PWD
      devrepo=$(mktemp -d)
      mkdir -p "$devrepo/${withCommas pname}"
      echo $(pwd) > "$devrepo/${withCommas pname}/.dev"
      export HAXELIB_PATH="$HAXELIB_PATH:$devrepo"
      haxelib run lime rebuild extension-webm linux

      runHook postBuild
    '';

    installPhase = ''
      mkdir -p "$out/lib/haxe/${withCommas pname}/${withCommas version}"
      echo -n "${version}" > $out/lib/haxe/${withCommas pname}/.current
      cp -dpR * "$out/lib/haxe/${withCommas pname}/${withCommas version}/"
    '';

    meta = with lib; {
      license = licenses.bsd2;
      description = "webm extension for haxe";
      platforms = lib.platforms.linux;
    };
  };
}
