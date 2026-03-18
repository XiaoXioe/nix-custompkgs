{
  lib,
  fetchurl,
  appimageTools,
}:

let
  pname = "disbox";
  version = "3.7.5";

  # Pastikan URL sesuai dengan nama file aset rilis di GitHub Disbox
  src = fetchurl {
    url = "https://github.com/naufal-backup/disbox/releases/download/v${version}/Disbox-Linux-x64.AppImage";

    # Dapatkan hash yang valid dengan menjalankan:
    # nix-prefetch-url https://github.com/naufal-backup/disbox/releases/download/v3.7.5/Disbox-3.7.5.AppImage
    sha256 = "sha256:9d37b3df768e97c214f128f33b3ac58d7cb34fb701a92a747779d8a44b6ff973";
  };

  appimageContents = appimageTools.extractType2 { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  # Mengekstrak ikon dan file .desktop agar Disbox muncul di menu aplikasi KDE Plasma / Cinnamon
  extraInstallCommands = ''
    install -m 444 -D ${appimageContents}/disbox.desktop -t $out/share/applications
    cp -r ${appimageContents}/usr/share/icons $out/share
    substituteInPlace $out/share/applications/disbox.desktop \
      --replace 'Exec=AppRun' 'Exec=${pname}'
  '';

  meta = with lib; {
    description = "Aplikasi desktop penyimpanan awan modern yang memanfaatkan Discord";
    homepage = "https://github.com/naufal-backup/disbox";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
  };
}
