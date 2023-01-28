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
                windowed_weights AS (
                  SELECT
                    *,
                    first_value(ts) OVER bucket AS first_ts,
                    last_value(ts) OVER bucket AS last_ts,
                    (epoch(first_ts) + epoch(last_ts)) / 2 AS mid_bucket,
                    regr_slope(weight_grams, epoch(ts) / (3600 * 24 * 7)) OVER (
                      ORDER BY ts
                      RANGE BETWEEN INTERVAL 8 DAYS PRECEDING
                                AND INTERVAL 2 DAYS FOLLOWING
                    ) AS rate,
                  FROM weight
                  WINDOW bucket AS (PARTITION BY date_diff('weeks', now()::timestamp, ts))
                  ORDER BY ts ASC
                )
              SELECT
                to_timestamp(mid_bucket)::date AS date,
                printf('%.2f', avg(weight_grams) / 1000) AS naive_avg_chonk,
                printf(
                  '%.2f',
                  regr_intercept(weight_grams, epoch(ts) - mid_bucket) / 1000
                ) AS avg_chonk,
                printf('%+.2f', last(rate) / 1000) AS rate,
              FROM windowed_weights
              GROUP BY mid_bucket
              HAVING avg_chonk IS NOT NULL;
            EOF
          '';

          inherit duckdb;
        };


      devShells."${system}".default = pkgs.mkShell {
        packages = [ duckdb ];
      };
    };
}
