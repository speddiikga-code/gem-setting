[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
$env:PYTHONIOENCODING = "utf-8"

# user@host in the prompt shows which account and machine a shell is on; `#` follows it in an elevated
# shell. Worked out once when the shell starts, so the prompt itself costs a string join.
$script:shellTag = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) ? ' #' : ''
function prompt { "[$env:USERNAME@$env:COMPUTERNAME$script:shellTag] PS $($PWD.Path)> " }
