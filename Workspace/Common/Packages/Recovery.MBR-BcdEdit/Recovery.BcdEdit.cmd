@echo off

REM Run this on every boot
bcdedit /set bootstatuspolicy IgnoreShutdownFailures
bcdedit /set recoveryenabled yes
bcdedit /set recoverysequence {a5935ff2-32ba-4617-bf36-5ac314b3f9bf}
bcdedit /set {a5935ff2-32ba-4617-bf36-5ac314b3f9bf} device ramdisk=[C:\mmos]\winpe.wim,{ramdiskoptions}
bcdedit /set {a5935ff2-32ba-4617-bf36-5ac314b3f9bf} osdevice ramdisk=[C:\mmos]\winpe.wim,{ramdiskoptions}
