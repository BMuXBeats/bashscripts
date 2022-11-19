# bashscripts
You can find my bash scripts here. Feel free to explore, use ore modificate them.

------------

## Automated backup with backup_daily.sh

### Motivation
I bought a second-hand *WD My Cloud Mirror Gen2* NAS .
The NAS has a webinterface with rudimentary functions and it has the ability to access via ssh.

The second point is what I wanted to get my data from my LINUX desktop backuped to a network share.

### SSH vs. Webinterface

The ssh access is better than the web interface for automating the daily backups.
However, I had to find out that the login via ssh-key is unfortunately not possible with the NAS mentioned above!
You can create a key, but it is not persistent. After each boot process of the NAS, this is unfortunately deleted from the NAS system.

A login with a password - which you can set up yourself via the web interface of the NAS - is possible at any time.
The energy-saving mode of the NAS can also be controlled via ssh.

In addition, the NAS can be woken up via **WOL** (wake on lan).

### Usage
The script needs to be executed with sudo rights.
It has furthermore mandatory to be marked as executable.

### Code modification issues
The code has been tested under Manjaro Linux and it worked reliable.
The script generates a logfile. The size of the logfile may increase infinitely at the moment.
A clean up routine for the logfile is not implemented, yet.
