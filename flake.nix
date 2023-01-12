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

          recordWeight = pkgs.writeShellScriptBin "opendb" ''
            ${prefix} "INSERT INTO weight (ts, weight_grams) VALUES ('$1', $2)"
          '';

          show = pkgs.writeShellScriptBin "show" ''
            ${prefix} << EOF
              SELECT ts AS "when", weight_grams::float / 1000 AS chonk FROM weight ORDER BY created_at, ts ASC LIMIT 20;

              WITH
                one_week_ago AS (SELECT * FROM weight ORDER BY date_diff('hour', weight.ts, now()::timestamp - INTERVAL 7 DAY) DESC LIMIT 1)
              SELECT 
                printf('%.1f', avg(one_week_ago.weight_grams) / 1000) AS one_week_ago
              FROM one_week_ago;
            EOF
          '';
          
          inherit duckdb;
        };


      devShells."${system}".default = pkgs.mkShell {
        packages = [ duckdb ];
      };
    };
}
