import os
import sys
print(os.path.dirname(sys.executable))

import pyvisa

rm = pyvisa.ResourceManager()
dev = 'TCPIP0::10.0.0.1::23::SOCKET'
session = rm.open_resource(dev)
session.read_termination = 'CCMT->'
session.write_termination = '\r\n'

while True:
    print(session.read_bytes(1))