#!/usr/bin/env sh
set -eu

OUT_DIR="${1:-$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/generated}"
DAYS="${DAYS:-825}"
mkdir -p "$OUT_DIR"
umask 077

command -v openssl >/dev/null 2>&1 || { echo "openssl is required" >&2; exit 1; }

openssl genrsa -out "$OUT_DIR/ca.key" 4096
openssl req -x509 -new -nodes -key "$OUT_DIR/ca.key" -sha256 -days "$DAYS" \
  -out "$OUT_DIR/ca.crt" -subj "/CN=alevi-mesh-ca"

create_node() {
  node_name="$1"
  san="$2"
  openssl genrsa -out "$OUT_DIR/${node_name}.key" 3072
  openssl req -new -key "$OUT_DIR/${node_name}.key" \
    -out "$OUT_DIR/${node_name}.csr" -subj "/CN=${node_name}"
  cat > "$OUT_DIR/${node_name}.ext" <<EOF
basicConstraints=critical,CA:FALSE
keyUsage=critical,digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth,clientAuth
subjectAltName=${san}
EOF
  openssl x509 -req -in "$OUT_DIR/${node_name}.csr" -CA "$OUT_DIR/ca.crt" -CAkey "$OUT_DIR/ca.key" \
    -CAcreateserial -out "$OUT_DIR/${node_name}.crt" -days "$DAYS" -sha256 -extfile "$OUT_DIR/${node_name}.ext"
  rm -f "$OUT_DIR/${node_name}.csr" "$OUT_DIR/${node_name}.ext"
}

create_node node "DNS:node,DNS:localhost,IP:127.0.0.1"
create_node node-2 "DNS:node-2,DNS:localhost,IP:127.0.0.1"
rm -f "$OUT_DIR/ca.srl"
chmod 600 "$OUT_DIR"/*.key
chmod 644 "$OUT_DIR"/*.crt
printf 'Generated mTLS certificates in %s\n' "$OUT_DIR"
