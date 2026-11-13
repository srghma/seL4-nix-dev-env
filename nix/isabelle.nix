{
  lib,
  stdenv,
  fetchurl,
  fetchFromGitHub,
  coreutils,
  net-tools,
  openjdk25,
  scala_3,
  polyml,
  verit,
  vampire,
  eprover-ho,
  cvc5,
  csdp,
  gmp,
  rlwrap,
  perl,
  procps,
  makeDesktopItem,
  copyDesktopItems,
  desktopToDarwinBundle,
  electron,
  writableTmpDirAsHomeHook,
  isabelleSrc,
}:

let
  java = openjdk25;

  platforms = {
    x86_64-linux = "x86_64-linux";
    aarch64-linux = "arm64-linux";
    aarch64-darwin = "arm64-darwin";
  };

  platform = platforms."${stdenv.hostPlatform.system}";

  contribTarball =
    if stdenv.hostPlatform.isDarwin then
      fetchurl {
        url = "https://isabelle.in.tum.de/website-Isabelle2026/dist/Isabelle2026_macos_arm.tar.gz";
        hash = "sha256-ckTlltRO6fu4uYjvKZBHSzOF+kp+wTQ4Z7IkoTtt3Cg=";
      }
    else if stdenv.hostPlatform.isx86 then
      fetchurl {
        url = "https://isabelle.in.tum.de/website-Isabelle2026/dist/Isabelle2026_linux.tar.gz";
        hash = "sha256-hYyZWzIhazh2vzlcO+hDFH0fHu5AS8bJWNdTTuM15I0=";
      }
    else
      fetchurl {
        url = "https://isabelle.in.tum.de/website-Isabelle2026/dist/Isabelle2026_linux_arm.tar.gz";
        hash = "sha256-7fsWcNi9+kJIiCnKA3nCGbh0oedUg0DJlR/9IlDaWn8=";
      };

  flatlafTarball = fetchurl {
    url = "https://isabelle.in.tum.de/components/flatlaf-3.8.tar.gz";
    hash = "sha256-a6oP1Bd7NSdtVBPWL5fwAPg4IRVImvXFVvKaP8hNYkM=";
  };

  polyml' = polyml.overrideAttrs {
    pname = "polyml-for-isabelle";
    version = "2026";

    src = fetchFromGitHub {
      owner = "polyml";
      repo = "polyml";
      rev = "ccd3e3717f7238b9b5d295fea4b5426182dfc0b6";
      hash = "sha256-wYW8aSvXzhW3hCDeorkD59j+1S6smzsFXHuPYeqo7z8=";
    };

    configureFlags = [
      "--enable-intinf-as-int"
      "--with-gmp"
      "--disable-shared"
    ];
    buildFlags = [ "compiler" ];

    postInstall = ''
      echo "ba433f9b-1286-450a-afb6-53f49be54d33" > $out/bin/poly.uuid
    '';
  };

  vampire' = vampire.override {
    enableZ3 = false;
  };

  cvc5' = cvc5.overrideAttrs {
    version = "1.3.4";
    src = fetchFromGitHub {
      owner = "cvc5";
      repo = "cvc5";
      tag = "cvc5-1.3.4";
      hash = "sha256-PZcOArSTyJzyd2DKT8K0aFC4RlVXgTCnkoU0f08KPfY=";
    };
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "isabelle";
  version = "2026-git";

  dirname = "Isabelle${finalAttrs.version}";

  src = isabelleSrc;

  unpackPhase = ''
    runHook preUnpack

    mkdir -p ${finalAttrs.dirname}
    cp -r --no-preserve=mode "$src"/. ${finalAttrs.dirname}/
    chmod -R u+w ${finalAttrs.dirname}

    mkdir -p _contrib_src
    tar -xzf ${contribTarball} -C _contrib_src --strip-components=1
    cp -r _contrib_src/contrib ${finalAttrs.dirname}/
    rm -rf ${finalAttrs.dirname}/contrib/flatlaf-*
    tar -xzf ${flatlafTarball} -C ${finalAttrs.dirname}/contrib/

    sed -n '/^#bundled components/,$p' _contrib_src/etc/components \
      | sed 's/flatlaf-3\.7\.2/flatlaf-3.8/' \
      >> ${finalAttrs.dirname}/etc/components

    rm -rf _contrib_src
    sourceRoot=${finalAttrs.dirname}

    runHook postUnpack
  '';

  nativeBuildInputs = [
    java
    copyDesktopItems
    writableTmpDirAsHomeHook
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    desktopToDarwinBundle
  ];

  buildInputs = [
    polyml'
    verit
    vampire'
    eprover-ho
    net-tools
    cvc5'
    csdp
  ];

  propagatedBuildInputs = lib.optionals stdenv.hostPlatform.isDarwin [ procps ];

  doCheck = stdenv.hostPlatform.isx86_64;
  checkPhase = "bin/isabelle build -v HOL-SMT_Examples";

  postPatch = ''
    patchShebangs lib/Tools/ bin/

    # Make copied files writable in Nix builds
    substituteInPlace src/Pure/System/isabelle_system.scala \
      --replace-fail 'StandardCopyOption.REPLACE_EXISTING)' $'StandardCopyOption.REPLACE_EXISTING)\n        target.setWritable(true)'

    substituteInPlace src/Pure/ML/ml_settings.scala \
      --replace-fail 'polyml_home + Path.basic(ml_platform)' 'Path.explode("${polyml'}/bin")'

    cat >contrib/verit-*/etc/settings <<EOF
      ISABELLE_VERIT=${verit}/bin/veriT
    EOF

    cat >contrib/e-*/etc/settings <<EOF
      E_HOME=${eprover-ho}/bin
      E_VERSION=${eprover-ho.version}
    EOF

    cat >contrib/vampire-*/etc/settings <<EOF
      VAMPIRE_HOME=${vampire'}/bin
      VAMPIRE_VERSION=${vampire'.version}
      VAMPIRE_EXTRA_OPTIONS="--mode casc"
    EOF

    cat >contrib/cvc5-*/etc/settings <<EOF
      CVC5_HOME=${cvc5'}
      CVC5_VERSION=${cvc5'.version}
      CVC5_SOLVER=${cvc5'}/bin/cvc5
      CVC5_INSTALLED=yes
    EOF

    cat >contrib/csdp-*/etc/settings <<EOF
      ISABELLE_CSDP=${csdp}/bin/csdp
    EOF

    cat >contrib/polyml-*/etc/settings <<EOF
      ML_SYSTEM_64=true
      ML_SYSTEM=${polyml'.name}
      ML_PLATFORM=${stdenv.system}
      ML_OPTIONS="--minheap 1000"
      POLYML_HOME="\$COMPONENT"
      ML_SOURCES="\$POLYML_HOME/src"
    EOF

    cat >contrib/jdk*/etc/settings <<EOF
      ISABELLE_JAVA_PLATFORM=${stdenv.system}
      ISABELLE_JDK_HOME=${java}
    EOF

    echo ISABELLE_LINE_EDITOR=${rlwrap}/bin/rlwrap >>etc/settings

    for comp in contrib/jdk* contrib/polyml-* contrib/verit-* contrib/vampire-* \
                contrib/e-* contrib/cvc5-* contrib/csdp-*; do
      rm -rf $comp/${if stdenv.hostPlatform.isx86 then "x86" else "arm"}*
    done
    rm -rf contrib/*/src

    substituteInPlace lib/Tools/env \
      --replace-fail /usr/bin/env ${coreutils}/bin/env

    substituteInPlace src/Tools/Setup/src/Environment.java \
      --replace-fail 'cmd.add("/usr/bin/env");' "" \
      --replace-fail 'cmd.add("bash");' "cmd.add(\"$SHELL\");"

    rm -rf heaps
  ''
  + lib.optionalString stdenv.hostPlatform.isLinux ''
    for f in contrib/*/${platform}/{z3,nunchaku,SPASS,zipperposition,opam,rsync,smbc}; do
      if [ -f "$f" ]; then
        patchelf --set-interpreter $(cat ${stdenv.cc}/nix-support/dynamic-linker) "$f"
      fi
    done
    patchelf --set-interpreter $(cat ${stdenv.cc}/nix-support/dynamic-linker) contrib/bash_process-*/${platform}/bash_process

    for f in contrib/naproche-*/${platform}/Naproche; do
      if [ -f "$f" ]; then
        patchelf \
          --set-interpreter $(cat ${stdenv.cc}/nix-support/dynamic-linker) \
          --set-rpath "${lib.getLib gmp}/lib" \
          "$f"
      fi
    done

    ln -sf ${electron}/bin/electron contrib/vscodium-*/*/electron
    rm contrib/vscodium-*/*/*.so{,.*}
    rm contrib/vscodium-*/*/chrome*

    for d in contrib/kodkodi-*/jni/${platform}; do
      patchelf --set-rpath "${
        lib.concatStringsSep ":" [
          "${java}/lib/openjdk/lib/server"
          "${lib.getLib stdenv.cc.cc}/lib"
        ]
      }" $d/*.so
      if [ -f "$d/plingeling" ]; then
        patchelf \
          --set-interpreter $(cat ${stdenv.cc}/nix-support/dynamic-linker) \
          --set-rpath "${lib.getLib stdenv.cc.cc}/lib" \
          "$d/plingeling"
      fi
    done
  ''
  + lib.optionalString (stdenv.hostPlatform.system == "x86_64-linux") ''
    patchelf --set-rpath "${lib.getLib stdenv.cc.cc}/lib" contrib/z3-*/${platform}/z3
  '';

  buildPhase = ''
    runHook preBuild

    setup_name=$(basename contrib/isabelle_setup*)

    user_home="$(bin/isabelle getenv -b ISABELLE_HOME_USER)"
    mkdir -p "$user_home/etc"
    echo 'ISABELLE_TMP_PREFIX="$TMPDIR/isabelle"' > "$user_home/etc/settings"

    TARGET_DIR="contrib/$setup_name/lib"
    rm -rf "$TARGET_DIR"
    mkdir -p "$TARGET_DIR/isabelle/setup"
    declare -a ARGS=("-Xlint:unchecked")

    SOURCES="$(${perl}/bin/perl -e 'while (<>) { if (m/(\S+\.java)/)  { print "$1 "; } }' "src/Tools/Setup/etc/build.props")"
    for SRC in $SOURCES
    do
      ARGS["''${#ARGS[@]}"]="src/Tools/Setup/$SRC"
    done
    echo "Building isabelle setup"
    javac -d "$TARGET_DIR" -classpath "${scala_3.bare}/maven2/org/scala-lang/scala3-interfaces/${scala_3.version}/scala3-interfaces-${scala_3.version}.jar:${scala_3.bare}/maven2/org/scala-lang/scala3-compiler_3/${scala_3.version}/scala3-compiler_3-${scala_3.version}.jar:./contrib/flatlaf-3.8/lib/flatlaf-3.8-no-natives.jar" "''${ARGS[@]}"
    jar -c -f "$TARGET_DIR/isabelle_setup.jar" -e "isabelle.setup.Setup" -C "$TARGET_DIR" isabelle
    rm -rf "$TARGET_DIR/isabelle"

    bin/isabelle scala_build

    echo "Building HOL heap"
    ln -s ${polyml'}/bin ./contrib/polyml-*/
    bin/isabelle build -v -o system_heaps -b HOL

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share
    mv $TMP/$dirname $out/share
    cd $out/share/$dirname
    bin/isabelle install $out/bin

    mkdir -p "$out/share/icons/hicolor/isabelle/apps"
    cp "$out/share/$dirname/lib/icons/isabelle.xpm" "$out/share/icons/hicolor/isabelle/apps/"

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "isabelle";
      exec = "isabelle jedit";
      icon = "isabelle";
      desktopName = "Isabelle";
      comment = finalAttrs.meta.description;
      categories = [
        "Education"
        "Science"
        "Math"
      ];
    })
  ];

  passthru = {
    inherit platform;
    vampire = vampire';
    polyml = polyml';
    cvc5 = cvc5';
  };

  meta = {
    description = "Generic proof assistant (built from local git checkout)";
    homepage = "https://isabelle.in.tum.de/";
    license = lib.licenses.bsd3;
    broken = !(stdenv.buildPlatform.canExecute stdenv.hostPlatform);
    platforms = lib.attrNames platforms;
  };
})
