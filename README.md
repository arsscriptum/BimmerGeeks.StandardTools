## Recombination

```
  .\makedoc.ps1 -Combine
```

## INSTALL INSTRUCTIONS IN BIMMERGEEKS STANDARD TOOLS

1. Run St212.exe using all default settings except the 4 checkbox options in the "select additional task" window regarding "backup and restore" and "create desktop/quick launch icons" . 
(If using Windows 10, run in st212.exe in "Compatibility Mode" for Windows 7)

2. After install completes, select "No" to restarting PC.

3. Navigate to your C:\ drive and delete the folders labeled "EC-APPS, EDIABAS & NCSEXPER"

4. Replace those folders with the "EC-APPS, EDIABAS & NCSEXPER" from this download by copying them to the C:\ drive.

5. Copy the 3 files inside the OCX folder and paste them in the C:\Windows\Syswow64 folder. If you do not have this folder you are a 32-bit system meaning you need to paste them in C:\Windows\system32 instead.

6. Open Command Prompt as administrator & enter the following commands. Please note if your 32bit system, start on the 2nd line: If you have issues getting the commands to succeed, make sure your running command prompt as administrator.

cd c:\windows\syswow64
(Press Enter)
regsvr32 mscomctl.ocx
(Press Enter & wait for "Registration Succeeded" message)
regsvr32 msflxgrd.ocx
(Press Enter & wait for "Registration Succeeded" message)
regsvr32 comdlg32.ocx
(Press Enter & wait for "Registration Succeeded" message)

7. Place the "BMW Tools" folder(BMW icon) on your desktop. Shortcuts to all the software are inside.

8. Make sure your cable is set to COM-1 with a Latency Timer as 1 in device manager.

9. Reboot Computer.

10. Installation is complete.

## SOURCE

https://www.bimmergeeks.net/downloads