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
              WITH rows AS (SELECT ts AS "when", weight_grams::float / 1000 AS chonk, created_at FROM weight ORDER BY created_at DESC, ts ASC LIMIT 18)
              SELECT "when", chonk FROM rows ORDER BY created_at ASC;

              WITH
                weeks AS (SELECT unnest(range(now()::timestamp - INTERVAL 33 DAY, now()::timestamp, INTERVAL 5 DAY)) AS anchor)
              SELECT
                weeks.anchor::date AS date,
                (
                  SELECT
                     printf('%.2f', regr_intercept(weight_grams, date_diff('minutes', ts, weeks.anchor)) / 1000),
                  FROM (
                    SELECT weight.weight_grams, weight.ts FROM weight
                    -- Take only a 5 day window around the date into account.
                    WHERE @date_diff('day', weight.ts, weeks.anchor) < 5
                  )
                ) AS avg_weight,
              FROM weeks;

              SELECT
                printf(
                  '%.2f',
                  regr_slope(weight_grams, epoch(ts) / (3600 * 24 * 7)) / 1000
                ) AS weight_change_per_week_last_12_days
              FROM weight
              WHERE date_diff('day', ts, now()::TIMESTAMP) <= 12
            EOF
          '';

          inherit duckdb;
        };


      devShells."${system}".default = pkgs.mkShell {
        packages = [ duckdb ];
      };
    };
}
