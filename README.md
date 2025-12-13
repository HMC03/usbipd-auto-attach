# USBIPD Auto Attach

This provides instruction on how to write a windows service that will automatically attach usb devices to your wsl. Good for serial communication and testing.

## Setup
1) Install script from this repo to `C:\Users\"your_username"\Services\usbipd-auto-attach.ps1`

2) Edit line 78 in the script
    * From: usbipd attach  --wsl "Ubuntu-24.04" --busid $dev.BusId 2>$null
    * To: usbipd attach  --wsl "`your_wsl_name`" --busid $dev.BusId 2>$null

3) Install nssm 

    Download from: https://nssm.cc/download

4) Open Powershell as administrator

5) Launch Nssm Gui
    ```ps
    C:path\to\nssm install usbipd-auto-attach
    ```

6) Set configuration in Nssm Gui
    * Application
        * Path: `C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe`

        * Startup: `C:\Users\"your_username"\Services\`

        * Arguments:  `-ExecutionPolicy Bypass -NoLogo -NoProfile -WindowStyle Hidden -File "C:\Users\"your_username"\Services\usbipd-auto-attach.ps1"`
    * Details
        * Display name: `usbipd-auto-attach`
        * Startup Type: `Automatic`

    * Log On
        * This account: `"your_username"`
        * Password: `"your_password"`
        * Confirm: `"your_password"`

7) Click Install Service

8) Start Service from powershell
    ```ps
    Start-Service usbipd-auto-attach
    ```

9) Log file should appear in `C:\Users\"your_username"\Services\usbipd-auto-attach.log`

10) Stop Service any time with
    ```ps
    Stop-Service usbipd-auto-attach
    ```