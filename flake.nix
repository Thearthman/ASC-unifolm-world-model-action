{
  description = "UnifoLM-WMA runtime for Linux x86_64 (CUDA 12.8)";

  # Pin the Nix tools separately from the Python/CUDA wheels in uv.lock.
  inputs.nixpkgs.url = "https://releases.nixos.org/nixpkgs/nixpkgs-26.11pre1126808.619c39f6eac5/nixexprs.tar.zst";

  outputs = { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      wmaRuntime = pkgs.writeShellScriptBin "wma-runtime-sync" ''
        set -euo pipefail
        if [[ ! -f uv.lock || ! -d src/unifolm_wma ]]; then
          printf 'Run wma-runtime-sync from the UnifoLM-WMA repository root.\n' >&2
          exit 1
        fi
        # A uv-managed interpreter also works outside the nix-portable mount
        # namespace, which is where the Fish direnv hook runs on itx.
        exec ${pkgs.uv}/bin/uv sync --locked --managed-python --python 3.10.20
      '';
    in {
      devShells.${system}.default = pkgs.mkShellNoCC {
        packages = [ pkgs.uv pkgs.ffmpeg-headless wmaRuntime ];
        shellHook = ''
          if wma-runtime-sync; then
            source .venv/bin/activate
          else
            exit 1
          fi
        '';
      };
    };
}
