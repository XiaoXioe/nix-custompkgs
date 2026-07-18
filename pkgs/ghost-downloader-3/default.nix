{
  lib,
  python3,
  fetchFromGitHub,
  fetchurl,
  autoPatchelfHook,
  stdenv,
  makeWrapper,
  qt6,
}:

let
  # Local wreq python package using precompiled ABI3 wheels
  wreq = python3.pkgs.buildPythonPackage rec {
    pname = "wreq";
    version = "0.12.0";
    format = "wheel";

    src =
      let
        system = stdenv.hostPlatform.system;
      in
      if system == "x86_64-linux" then
        fetchurl {
          url = "https://files.pythonhosted.org/packages/c2/b1/aacc3eb58e8ceee9f86cc097a6a077909b5989ccb95aa3ac877cbdbf7a43/wreq-0.12.0-cp311-abi3-manylinux_2_17_x86_64.manylinux2014_x86_64.whl";
          sha256 = "67fc6b7fd146e1c3b8e1b9c571fd03535509ec3bf9d1f983abd064a53250c7b9";
        }
      else if system == "aarch64-linux" then
        fetchurl {
          url = "https://files.pythonhosted.org/packages/18/88/901c400f55ab269861430667b47d77a8096f03d88ae248d54e25060805c1/wreq-0.12.0-cp311-abi3-manylinux_2_34_aarch64.whl";
          sha256 = "35bc7899a3f574d4c6c1474eb14cb08b267ba14e7bc3dab69283ca54f6818b61";
        }
      else
        throw "Unsupported system for wreq: ${system}";

    nativeBuildInputs = [ autoPatchelfHook ];

    buildInputs = [ stdenv.cc.cc.lib ];

    meta = {
      description = "Ergonomic Python HTTP client with TLS fingerprint emulation";
      homepage = "https://github.com/0x676e67/wreq-python";
      license = lib.licenses.mit;
    };
  };

  # Local pysidesix-frameless-window package
  pysidesix-frameless-window = python3.pkgs.buildPythonPackage rec {
    pname = "pysidesix-frameless-window";
    version = "0.8.1";
    format = "setuptools";

    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/e7/44/ee4b9ead46ec5fcc4d9a303f6ac82cb17b0e188bfe629ef962c4046cded5/pysidesix_frameless_window-0.8.1.tar.gz";
      sha256 = "95eefa64abdaca9d730bc097fd39e2cd07d3443a47a1645cc936a0076996d7cd";
    };

    propagatedBuildInputs = with python3.pkgs; [
      pyside6
    ];

    doCheck = false;

    meta = {
      description = "A cross-platform frameless window based on PySide6";
      homepage = "https://github.com/zhiyiYo/PyQt-Frameless-Window/tree/PySide6";
      license = lib.licenses.lgpl3Only;
    };
  };

  # Local pyside6-fluent-widgets package
  pyside6-fluent-widgets = python3.pkgs.buildPythonPackage rec {
    pname = "pyside6-fluent-widgets";
    version = "1.11.2";
    format = "setuptools";

    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/f1/22/01a72ab00873fac2575e8045cd4dfcb003afc0f0764982c706817be5629a/pyside6_fluent_widgets-1.11.2.tar.gz";
      sha256 = "cf49ff76b9b2ad1dc24f071a1b2a3f5f0a67d7adf655915071ddfb7342caf175";
    };

    propagatedBuildInputs = with python3.pkgs; [
      pyside6
      pysidesix-frameless-window
      darkdetect
    ];

    doCheck = false;

    meta = {
      description = "Fluent design widgets library for PySide6";
      homepage = "https://github.com/zhiyiYo/PyQt-Fluent-Widgets";
      license = lib.licenses.gpl3Only;
    };
  };
in
python3.pkgs.buildPythonApplication rec {
  pname = "ghost-downloader-3";
  version = "4.1.1";
  format = "other";

  src = fetchFromGitHub {
    owner = "XiaoYouChR";
    repo = "Ghost-Downloader-3";
    rev = "v${version}";
    hash = "sha256-rg5ObBvhcDFguIqZZwUurKSr2/4AFzGRL7Xe98vE5Ys=";
  };

  nativeBuildInputs = [ qt6.wrapQtAppsHook ];

  postPatch = ''
    substituteInPlace app/config/paths.py \
      --replace-fail 'Path(".")' 'Path(__file__).resolve().parent.parent.parent'
  '';

  buildInputs = [ qt6.qtbase ];

  propagatedBuildInputs =
    (with python3.pkgs; [
      aioftp
      desktop-notifier
      libtorrent-rasterbar
      loguru
      m3u8
      mpegdash
      pyside6
      qrcode
      uvloop
    ])
    ++ [
      wreq
      pyside6-fluent-widgets
    ];

  dontBuild = true;

  installPhase = ''
        runHook preInstall

        # Create directories
        mkdir -p $out/libexec/ghost-downloader-3
        mkdir -p $out/bin
        mkdir -p $out/share/applications
        mkdir -p $out/share/icons/hicolor/512x512/apps

        # Copy files
        cp -r * $out/libexec/ghost-downloader-3/

        # Install application icon
        cp app/assets/logo.png $out/share/icons/hicolor/512x512/apps/ghost-downloader-3.png

        # Generate desktop launcher file
        cat > $out/share/applications/ghost-downloader-3.desktop <<EOF
    [Desktop Entry]
    Name=Ghost Downloader 3
    Comment=AI-boost multi-protocol concurrent downloader
    Exec=ghost-downloader-3
    Icon=ghost-downloader-3
    Terminal=false
    Type=Application
    Categories=Network;FileTransfer;
    EOF

        # Create launcher script
        cat > $out/bin/ghost-downloader-3 <<EOF
    #!${python3.interpreter}
    import sys
    sys.path.insert(0, "$out/libexec/ghost-downloader-3")
    import runpy
    runpy.run_path("$out/libexec/ghost-downloader-3/Ghost-Downloader-3.py", run_name="__main__")
    EOF
        chmod +x $out/bin/ghost-downloader-3

        runHook postInstall
  '';

  meta = {
    description = "AI-boost cross-platform multi-protocol fluent-design concurrent downloader built with Python & Qt";
    homepage = "https://github.com/XiaoYouChR/Ghost-Downloader-3";
    license = lib.licenses.gpl3Only;
    mainProgram = "ghost-downloader-3";
  };
}
