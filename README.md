# scankeys - demo Commodore 64 and 128 keyboard matrix #

Actively scan Commodore 64/128 keyboard matrix and display pressed keys on screen

C64 Usage (supports 64 keys):

````
LOAD "SCANKEY64 49152",8,1
SYS 49152
````

C128 Usage (supports 90 keys):

````
LOAD "SCANKEY128 1700",8,1
SYS DEC("1700")
````

64 mode support of 128 keys (supports 89 keys, all but 40/80 DISPLAY because MMU disabled) Usage:

````
GO 64
LOAD "SCANKEY64MODE",8,1
SYS 49152
````

STOP+RESTORE may get you to a BASIC prompt if you are lucky, keep trying (hold STOP, tap RESTORE repeatedly).  Otherwise reset system.

![scankey64.png](scankey64.png)

![scankey128.png](scankey128.png)
