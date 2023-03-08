# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
# WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

<#
    .DESCRIPTION
    Prepares a Windows guest operating system with final configuration.
#>

# Set SSH options.
Write-Output "Setting SSH options..."
Set-Service -Name sshd -StartupType 'Automatic'
Start-Service sshd

New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force

# Set PowerShell as default shell.
Write-Output "Setting PowerShell as default shell..."
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name Shell -Value 'PowerShell.exe -NoExit'

# Install Cloudbase Init
Write-Output "Installing cloudbase-init..."
choco install cloudbaseinit

Set-Content -Path "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\cloudbase-init.conf" -value @"
[DEFAULT]
username=rancher
groups=Administrators
netbios_host_name_compatibility=false
inject_user_password=true
retry_count=6
retry_count_interval=10
first_logon_behaviour=no
bsdtar_path=C:\Program Files\Cloudbase Solutions\Cloudbase-Init\bin\bsdtar.exe
mtools_path=C:\Program Files\Cloudbase Solutions\Cloudbase-Init\bin\
verbose=true
debug=true
log-dir=C:\Program Files\Cloudbase Solutions\Cloudbase-Init\log\
log-file=cloudbase-init.log
default_log_levels=comtypes=INFO,suds=INFO,iso8601=WARN,requests=WARN
logging_serial_port_settings=
mtu_use_dhcp_config=true
ntp_use_dhcp_config=true
local_scripts_path=C:\Program Files\Cloudbase Solutions\Cloudbase-Init\LocalScripts\
metadata_services=cloudbaseinit.metadata.services.nocloudservice.NoCloudConfigDriveService
plugins=cloudbaseinit.plugins.common.mtu.MTUPlugin,
        cloudbaseinit.plugins.common.userdata.UserDataPlugin,
        cloudbaseinit.plugins.common.sethostname.SetHostNamePlugin,
        cloudbaseinit.plugins.common.setuserpassword.SetUserPasswordPlugin,
        cloudbaseinit.plugins.common.sshpublickeys.SetUserSSHPublicKeysPlugin,
        cloudbaseinit.plugins.windows.certificates.ServerCertificatesPlugin,
        cloudbaseinit.plugins.common.networkconfig.NetworkConfigPlugin,
        cloudbaseinit.plugins.common.localscripts.LocalScriptsPlugin,
        cloudbaseinit.plugins.windows.extendvolumes.ExtendVolumesPlugin
check_latest_version=true
allow_reboot=false
stop_service_on_exit=false
[config_drive]
types=iso,vfat
locations=cdrom
"@

# Final cleanup
Write-Output "Cleaning event log..."
Get-EventLog -LogName * | ForEach { Clear-EventLog -LogName $_.Log }
