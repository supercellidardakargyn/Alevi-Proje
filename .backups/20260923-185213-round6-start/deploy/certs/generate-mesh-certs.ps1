[CmdletBinding()]
param([string]$OutDir = (Join-Path $PSScriptRoot 'generated'))
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$openssl = Get-Command openssl -ErrorAction Stop

& $openssl genrsa -out (Join-Path $OutDir 'ca.key') 4096
& $openssl req -x509 -new -nodes -key (Join-Path $OutDir 'ca.key') -sha256 -days 825 -out (Join-Path $OutDir 'ca.crt') -subj '/CN=alevi-mesh-ca'

function New-NodeCert([string]$Name, [string]$San) {
  $key = Join-Path $OutDir "$Name.key"
  $csr = Join-Path $OutDir "$Name.csr"
  $crt = Join-Path $OutDir "$Name.crt"
  $ext = Join-Path $OutDir "$Name.ext"
  & $openssl genrsa -out $key 3072
  & $openssl req -new -key $key -out $csr -subj "/CN=$Name"
  @("basicConstraints=critical,CA:FALSE", "keyUsage=critical,digitalSignature,keyEncipherment", "extendedKeyUsage=serverAuth,clientAuth", "subjectAltName=$San") | Set-Content -Encoding ascii $ext
  & $openssl x509 -req -in $csr -CA (Join-Path $OutDir 'ca.crt') -CAkey (Join-Path $OutDir 'ca.key') -CAcreateserial -out $crt -days 825 -sha256 -extfile $ext
  Remove-Item $csr, $ext, (Join-Path $OutDir 'ca.srl') -ErrorAction SilentlyContinue
}

New-NodeCert 'node' 'DNS:node,DNS:localhost,IP:127.0.0.1'
New-NodeCert 'node-2' 'DNS:node-2,DNS:localhost,IP:127.0.0.1'
Write-Host "Generated mTLS certificates in $OutDir"
