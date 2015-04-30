NS=$1
BASE=$2

if [ -z "$NS" ] || [ -z "$BASE" ]; then
    echo "Missing parameter"
    exit 1;
fi

DIRS=(proc var etc lib lib64 usr sbin bin var/cache sys var/lib/samba dev)

for dir in "${DIRS[@]}"; do
  [ -d $BASE/$NS/$dir ]                || mkdir -p $BASE/$NS/$dir
done

cp -fr /var/cache/samba$NS $BASE/$NS/var/cache/

DIRS=(proc etc lib lib64 bin usr sbin sys var/lib/samba dev)

for dir in "${DIRS[@]}"; do
  mount -o bind /$dir           $BASE/$NS/$dir
done


