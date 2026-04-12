{ 
  lib, 
  stdenv, 
  fetchurl, 
  dpkg, 
  makeWrapper, 
  steam-run 
}:

stdenv.mkDerivation rec {
  pname = "binance";
  version = "latest";

  src = fetchurl {
    url = "https://download.binance.com/electron-desktop/linux/production/binance-amd64-linux.deb";
    # Pastikan hash ini diupdate
    sha256 = "024snny1i34zg1r0qgyakkm8s1vlwr22igvrjj3vyv55fs5lrkr5"; 
  };

  nativeBuildInputs = [ dpkg makeWrapper ];

  unpackPhase = ''
    dpkg -x $src .
  '';

  installPhase = ''
    mkdir -p $out/bin $out/opt $out/share
    
    # Pindahkan direktori hasil ekstrak ke Nix Store
    cp -r opt/Binance $out/opt/
    cp -r usr/share/* $out/share/
    
    # Bungkus binari dengan steam-run agar berjalan di environment FHS
    makeWrapper ${steam-run}/bin/steam-run $out/bin/binance \
      --add-flags "$out/opt/Binance/binance"
      
    # Perbaiki path eksekusi pada file desktop agar berjalan dari app launcher
    substituteInPlace $out/share/applications/binance.desktop \
      --replace "/opt/Binance/binance" "$out/bin/binance"
  '';

  meta = with lib; {
    description = "Binance Desktop App";
    platforms = platforms.linux;
  };
}
