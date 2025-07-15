{
  config,
  lib,
  ...
}: let
  homeDir = config.home.homeDirectory;
in {
  home.activation.ensureSecretsDir = lib.hm.dag.entryBefore ["writeBoundary"] ''
    echo "[+] Ensuring base .secrets directory exists"
    mkdir -p "${homeDir}/.secrets"
    chmod 700 "${homeDir}/.secrets"
  '';
}
