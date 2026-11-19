#!/usr/bin/env bash
# Rebuild the AirportDB demo from scratch inside the SQL Server container.
# Usage: ./run_all.sh            (container already running)
#        CONTAINER=my-sql ./run_all.sh
set -euo pipefail

CONTAINER="${CONTAINER:-airport-sql}"
SA_PASSWORD="${SA_PASSWORD:-Airport#2026!Demo}"
SQLCMD="/opt/mssql-tools18/bin/sqlcmd"
HERE="$(cd "$(dirname "$0")" && pwd)"

if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER"; then
  echo "Container $CONTAINER is not running. Start it with:"
  echo "  docker run -d --name $CONTAINER -p 14333:1433 -e ACCEPT_EULA=Y \\"
  echo "    -e MSSQL_SA_PASSWORD='$SA_PASSWORD' -e MSSQL_PID=Developer \\"
  echo "    mcr.microsoft.com/mssql/server:2019-latest"
  exit 1
fi

for f in "$HERE"/sql/0[0-6]*.sql; do
  echo
  echo "==> $(basename "$f")"
  docker exec -i "$CONTAINER" "$SQLCMD" -S localhost -U sa -P "$SA_PASSWORD" \
    -C -b -I -f 65001 < "$f"
done

echo
echo "Done. Connect with:"
echo "  docker exec -it $CONTAINER $SQLCMD -S localhost -U sa -P '$SA_PASSWORD' -C"
