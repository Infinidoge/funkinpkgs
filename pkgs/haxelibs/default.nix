{ stdenv
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
{
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
}
