{
  description = "A very basic flake";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages."${system}";
      inherit (pkgs) duckdb;
    in
    {
      packages."${system}" =
        let
          prefix = "${duckdb}/bin/duckdb nutrition.db";
        in
        {
          opendb = pkgs.writeShellScriptBin "opendb" prefix;

          recordWaist = pkgs.writeShellScriptBin "recordWaist" ''
            ${prefix} "INSERT INTO waist (ts, waist_mm) VALUES ('$1', $2)"
          '';

          recordWeight = pkgs.writeShellScriptBin "recordWeight" ''
            ${prefix} "INSERT INTO weight (ts, weight_grams) VALUES ('$1', $2)"
          '';

          show = pkgs.writeShellScriptBin "show" "cat ${./last_measurements.sql} ${./dashboard.sql} | ${prefix}";

          inherit duckdb;
        };


      devShells."${system}".default = pkgs.mkShell {
        packages = [ duckdb ];
      };
    };
}
