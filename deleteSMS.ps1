[CmdletBinding(DefaultParameterSetName="ByID")]
Param
(
    [parameter(Mandatory=$true, ParameterSetName="ByID")]
    [ValidateScript({$_ -gt 0})]
    [int32]$StartID,
    [parameter(ParameterSetName="ByID")]
    [int32]$EndID,
    [parameter(Mandatory=$true, ParameterSetName="ByPhone")]
    [string]$Phone,
    [parameter(Mandatory=$true, ParameterSetName="Clear")]
    [switch]$Clear
)

function Delete-SMS(){
param(
    [Parameter(ValueFromPipeline=$true, Position=0)]
    [string]$ListSMS,
    [string]$HostSMS    ="192.168.0.1",
    [string]$urlSMS    ="http://$hostSMS/goform/goform_set_cmd_process/",
    [string]$urlReferer ="http://$hostSMS/index.html",
    [string]$urlMain    ="http://$hostSMS/"
)
    #$hostSMS="192.168.0.1"
    #$urlSMS = "http://$hostSMS/"
    #$urlSMS = "http://$hostSMS/goform/goform_set_cmd_process/"
    #$urlReferer = "http://$hostSMS/index.html"
    #$urlMain="http://$hostSMS/"
    #$ct  = "application/x-www-form-urlencoded"
    if ( !$ListSMS) {
        return
    }
    $hd=@{
        'Origin'=$urlMain
        "Accept-Encoding"="gzip, deflate"
        "Accept-Language"="ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7"
        #"User-Agent"="Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/65.0.3325.181 Safari/537.36"
        "Accept"="application/json, text/javascript, */*; q=0.01"
        'Referer'="$urlReferer"
        "X-Requested-With"="XMLHttpRequest"
        'Content-Type'='application/x-www-form-urlencoded'
    }
    $b=@{
        'isTest'=$false
        'goformId'="DELETE_SMS"
        'msg_id'=$ListSMS
        'notCallback'=$true
    }
    Invoke-WebRequest $urlSMS -Method "POST" -Headers $hd -Body $b
}

function Get-ListSMS () {
    $r=Invoke-WebRequest -Uri "http://192.168.0.1/goform/goform_get_cmd_process?isTest=false&cmd=sms_data_total&page=0&data_per_page=500&mem_store=1&tags=10&order_by=order+by+id+desc&_=1521797514547" -Headers @{"Accept-Encoding"="gzip, deflate"; "Accept-Language"="ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7"; "User-Agent"="Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/65.0.3325.181 Safari/537.36"; "Accept"="application/json, text/javascript, */*; q=0.01"; "Referer"="http://192.168.0.1/index.html"; "X-Requested-With"="XMLHttpRequest"}
    $s=$r.Content.Replace("{""messages"":[{","")
    $s=($s.SubString(0, $s.Length-3)) -split "},{"
    $arrRet=@()
    $s.ForEach({
        $e=$_ -split ',', 3
        $hs=( (($e[0] -replace """", '') -replace ':', '=')|ConvertFrom-StringData )+( (($e[1] -replace """", '') -replace ':', '=')|ConvertFrom-StringData )
        $arrRet+=$hs
    })
    $arrRet
}

function Get-ListSMS-Id () {
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0)]
    #[ValidateNotNull]
    #[Alias("SMS")]
    [object[]]$arraySMS,
    [string]$Field='id'
)
    BEGIN {
        $AA=@()
        If ($PSBoundParameters.ContainsKey('arraySMS')) {
            $AA=$arraySMS[0..($arraySMS.Count-1)]
        } Else {
            $IsPipeline = $True
        }
    }
    PROCESS {
        If ($IsPipeline) {
            $AA+=$arraySMS
        }
    }
    END {
        $Result = ""
        $aa.ForEach({
            $Result+=([string]$_.$Field+';')
        })
        $Result
    }
}

$SMS=Get-ListSMS
switch ($PSCmdlet.ParameterSetName) {
    'ByID' {
        if ( !$EndID) {
            $EndID=$StartID
        }
        $arI=($StartID..$EndID)
        $str=''
        $SMS.ForEach({
            if ($arI.contains([int]$_.ID)) {
                $str+=([string]$_.ID)+';'
            }
        })
        Delete-SMS -listSMS ($str)
    }
    'ByPhone' {
        $str=''
        $SMS.ForEach({
            if ( $_.number.Contains($Phone)  ) {
                $str+=([string]$_.ID)+';'
            }
        })
        Delete-SMS -listSMS ($str)
    }
    'Clear' {
        (Get-ListSMS-Id -arraySMS $sms)|Delete-SMS
    }
    Default {
        return "Не задано параметров. Выполнение невозможно."
    }
}

return 

$sms
Get-ListSMS-Id -arraySMS $sms -Field 'number'
$sms|Get-ListSMS-Id
$sms|Get-ListSMS-Id -Field 'number'
Get-ListSMS-Id $sms
Get-ListSMS-Id $sms -Field 'number'
