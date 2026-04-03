{
  lib,
  fetchurl,
  appimageTools,
}:

let
  pname = "disbox";
  version = "4.8.8";

  src = fetchurl {
    url = "https://github.com/naufal-backup/disbox/releases/download/v${version}/Disbox-Linux-x64.AppImage";

    sha256 = "sha256-2qxNNmY/785BAT7ZATBey5zu1ImOriNvIuf6gZRTr8I=";
  };

  appimageContents = appimageTools.extractType2 { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  # Mengekstrak ikon dan file .desktop agar Disbox muncul di menu aplikasi KDE Plasma / Cinnamon
  # extraInstallCommands = ''
  #   install -m 444 -D ${appimageContents}/disbox.desktop -t $out/share/applications
  #   cp -r ${appimageContents}/usr/share/icons/hicolor/0x0/apps $out/share
  #   substituteInPlace $out/share/applications/disbox.desktop \
  #     --replace 'Exec=AppRun' 'Exec=${pname}'
  # '';
  extraInstallCommands = ''
    # Kita ambil dari folder 0x0 yang aneh itu,
    # tapi kita simpan ke folder 512x512 agar sistem bisa membacanya.
    # Flag -D akan membuatkan folder share/icons/hicolor/512x512/apps/ secara otomatis.

    install -m 444 -D ${appimageContents}/usr/share/icons/hicolor/0x0/apps/disbox.png \
      $out/share/icons/hicolor/512x512/apps/disbox.png

    # Install file desktop
    install -m 444 -D ${appimageContents}/disbox.desktop $out/share/applications/disbox.desktop

    # Pastikan file desktop merujuk ke nama ikon yang benar
    substituteInPlace $out/share/applications/disbox.desktop \
      --replace 'Exec=AppRun' 'Exec=${pname}' \
      --replace 'Icon=disbox' 'Icon=disbox'
  '';

  meta = with lib; {
    description = "Aplikasi desktop penyimpanan awan modern yang memanfaatkan Discord";
    homepage = "https://github.com/naufal-backup/disbox";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
  };
}
