"""Cliente mínimo del protocolo PostgreSQL v3 (TLS + token de Entra ID).

Uso: python3 pgcheck.py <host> <usuario> <token> <sql>
Solo depende de la biblioteca estándar: la VM no tiene salida a Internet para
instalar psql. Los mensajes impresos se mantienen en ASCII porque run-command no
conserva la codificación UTF-8 de la salida.
"""
import socket
import ssl
import struct
import sys

host, user, token, sql = sys.argv[1:5]


def recv_exact(sock, n):
    data = b""
    while len(data) < n:
        chunk = sock.recv(n - len(data))
        if not chunk:
            raise ConnectionError("conexion cerrada por el servidor")
        data += chunk
    return data


def read_message(sock):
    kind = recv_exact(sock, 1)
    length = struct.unpack("!I", recv_exact(sock, 4))[0]
    return kind, recv_exact(sock, length - 4)


def error_text(payload):
    fields = dict((f[:1], f[1:].decode()) for f in payload.split(b"\x00") if f)
    return f"{fields.get(b'S', '')} {fields.get(b'C', '')}: {fields.get(b'M', '')}"


raw = socket.create_connection((host, 5432), timeout=15)
print(f"TCP conectado a {raw.getpeername()[0]}:5432")

# SSLRequest: el servidor responde 'S' si acepta TLS.
raw.sendall(struct.pack("!II", 8, 80877103))
if raw.recv(1) != b"S":
    sys.exit("El servidor rechazo TLS")
sock = ssl.create_default_context().wrap_socket(raw, server_hostname=host)
print(f"TLS establecido: {sock.version()}, certificado emitido para {dict(x[0] for x in sock.getpeercert()['subject'])['commonName']}")

params = b"user\x00" + user.encode() + b"\x00database\x00postgres\x00\x00"
sock.sendall(struct.pack("!II", 8 + len(params), 196608) + params)

while True:
    kind, payload = read_message(sock)
    if kind == b"R":
        code = struct.unpack("!I", payload[:4])[0]
        if code == 3:  # AuthenticationCleartextPassword: Entra ID usa el token como contraseña sobre TLS
            pwd = token.encode() + b"\x00"
            sock.sendall(b"p" + struct.pack("!I", 4 + len(pwd)) + pwd)
        elif code == 0:
            print(f"Autenticacion correcta como '{user}' con token de Entra ID")
        else:
            sys.exit(f"Metodo de autenticacion no soportado: {code}")
    elif kind == b"E":
        sys.exit("ERROR " + error_text(payload))
    elif kind == b"Z":
        break

query = sql.encode() + b"\x00"
sock.sendall(b"Q" + struct.pack("!I", 4 + len(query)) + query)
columns = []
while True:
    kind, payload = read_message(sock)
    if kind == b"T":
        count = struct.unpack("!H", payload[:2])[0]
        rest = payload[2:]
        for _ in range(count):
            name, rest = rest.split(b"\x00", 1)
            columns.append(name.decode())
            rest = rest[18:]
    elif kind == b"D":
        count = struct.unpack("!H", payload[:2])[0]
        rest, values = payload[2:], []
        for _ in range(count):
            size = struct.unpack("!i", rest[:4])[0]
            values.append(None if size < 0 else rest[4:4 + size].decode())
            rest = rest[4 + max(size, 0):]
        print(" | ".join(f"{c}={v}" for c, v in zip(columns, values)))
    elif kind == b"E":
        sys.exit("ERROR " + error_text(payload))
    elif kind == b"Z":
        break
sock.close()
