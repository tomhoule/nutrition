{
  description = "Nutrition tracking for my personal needs.";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages."${system}";
      inherit (pkgs) duckdb;
    in
    {
      packages."${system}" =
        let
          withDb = "${duckdb}/bin/duckdb -init ${./import_database.sql}";
        in
        {
          opendb = pkgs.writeShellScriptBin "opendb" withDb;

          recordWeight = pkgs.writeShellScriptBin "recordWeight" ''
            echo \
              "INSERT INTO weight (date, weight_grams) VALUES ($1, $2);"\
              "EXPORT DATABASE 'db' (FORMAT PARQUET)"\
            | ${withDb}
          '';

          show = pkgs.writeShellScriptBin "show" ''
            cat \
              ${./measurements_count.sql}\
              ${./last_measurements.sql}\
              ${./dashboard.sql}\
            | ${withDb}
          '';

          inherit duckdb;
        };


      devShells."${system}".default = pkgs.mkShell {
        packages = [ duckdb ];
      };
    };
}
