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
                weeks AS (SELECT unnest(range(now()::timestamp - INTERVAL 1 MONTH, now()::timestamp, INTERVAL 5 DAY)) AS anchor)
              SELECT
                weeks.anchor::date AS date,
                (
                  SELECT printf('%.1f', avg(weight_grams) / 1000)
                  FROM (
                    SELECT weight.weight_grams FROM weight
                    -- Take only a 5 day window around the date into account.
                    WHERE @date_diff('day', weight.ts, weeks.anchor) < 5
                    -- Take the 6 measurements closest to the anchor timestamp.
                    ORDER BY @date_diff('hour', weight.ts, weeks.anchor) ASC
                    LIMIT 6
                  )
                ) AS avg_weight
              FROM weeks;
            EOF
          '';
          
          inherit duckdb;
        };


      devShells."${system}".default = pkgs.mkShell {
        packages = [ duckdb ];
      };
    };
}
