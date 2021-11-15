#######################################################
# - Author : WeiyiGeek
# - Description: Windows Server��ȫ���ò��Ի��߼��ű�
# - Version: v1.1
# - Time: 2021��5��20�� 10��53��
# - Mail: Master@weiyigeek.top
# - wechat: WeiyiGeeker
#######################################################
<#
	.SYNOPSIS
	�����������Ƿ����Ԥ������
	.DESCRIPTION
	Ԥ�����ԣ�
		������ʷ��5
		�����ʹ�����ޣ�90
		�������ʹ�����ޣ�1
		���븴�Ӷ��Ƿ�����1����
		�Ƿ��Կɻ�ԭ�ķ�ʽ���ܴ洢���룺0��
		������С���ȣ�8λ
	.EXAMPLE
	Check-PasswordPolicy secInfoArray
	.NOTES
	General notes
#>
# * PowerShell �ű�ִ�в���
[Cmdletbinding()]
param(
  [Parameter(Mandatory=$true)][String]$Executor,
  [Boolean]$Update
)

# * �ļ����Ĭ��ΪUTF-8��ʽ
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

# * �ؼ���:ϵͳ���������ļ���ȡ *
secedit /export /cfg config.cfg /quiet
start-sleep 3
$Config = Get-Content -path config.cfg
$ScanTime = Get-date -Format 'yyyy-M-d H:m:s'



################################################################################################################################
# **********************#
# * ȫ�ֹ��ù�����������  *  
# **********************#
function F_Tools {
  param (
    [Parameter(Mandatory=$true)][String]$Key,
    [Parameter(Mandatory=$true)]$Value,
    [Parameter(Mandatory=$true)]$DefaultValue,
    [String]$Msg,
    [String]$Operator
  )
  
  if ( $Operator -eq  "eq" ) {
    if ( $Value -eq $DefaultValue ) {
      $Result = @{"$($Key)"="[�ϸ���]|$($Value)|$($DefaultValue)|$($Msg)-�����ϡ��ȼ�������׼."}
      Write-Host "$($Key)"=" [�ϸ���]|$($Value)|$($DefaultValue)|$($Msg)-�����ϡ��ȼ�������׼." -ForegroundColor White
      return $Result
    } else {
      $Result = @{"$($Key)"="[�쳣��]|$($Value)|$($DefaultValue)|$($Msg)-�������ϡ��ȼ�������׼."}
      Write-Host "$($Key)"=" [�쳣��]|$($Value)|$($DefaultValue)|$($Msg)-�������ϡ��ȼ�������׼." -ForegroundColor red
      return $Result
    }

  } elseif ($Operator -eq  "ne" ) {

    if ( $Value -ne $DefaultValue ) {
      $Result = @{"$($Key)"="[�ϸ���]|$($Value)|$($DefaultValue)|$($Msg)-�����ϡ��ȼ�������׼."}
      Write-Host "$($Key)"=" [�ϸ���]|$($Value)|$($DefaultValue)|$($Msg)-�����ϡ��ȼ�������׼." -ForegroundColor White
      return $Result
    } else {
      $Result = @{"$($Key)"="[�쳣��]|$($Value)|$($DefaultValue)|$($Msg)-�������ϡ��ȼ�������׼."}
      Write-Host "$($Key)"=" [�쳣��]|$($Value)|$($DefaultValue)|$($Msg)-�������ϡ��ȼ�������׼." -ForegroundColor red
      return $Result
    }

  } elseif ($Operator -eq  "le") {

    if ( $Value -le $DefaultValue ) {
      $Result = @{"$($Key)"="[�ϸ���]|$($Value)|$($DefaultValue)|$($Msg)-�����ϡ��ȼ�������׼."}
      Write-Host "$($Key)"=" [�ϸ���]|$($Value)|$($DefaultValue)|$($Msg)-�����ϡ��ȼ�������׼." -ForegroundColor White
      return $Result
    } else {
      $Result = @{"$($Key)"="[�쳣��]|$($Value)|$($DefaultValue)|$($Msg)-�������ϡ��ȼ�������׼."}
      Write-Host "$($Key)"=" [�쳣��]|$($Value)|$($DefaultValue)|$($Msg)-�������ϡ��ȼ�������׼." -ForegroundColor red
      return $Result
    }

  } elseif ($Operator -eq "ge") {

    if ( $Value -ge $DefaultValue ) {
      $Result =  @{"$($Key)"="[�ϸ���]|$($Value)|$($DefaultValue)|$($Msg)-�����ϡ��ȼ�������׼."}
      Write-Host "$($Key)"=" [�ϸ���]|$($Value)|$($DefaultValue)|$($Msg)-�����ϡ��ȼ�������׼." -ForegroundColor White
      return $Result
    } else {
      $Result = @{"$($Key)"="[�쳣��]|$($Value)|$($DefaultValue)|$($Msg)-�������ϡ��ȼ�������׼."}
      Write-Host "$($Key)"=" [�쳣��]|$($Value)|$($DefaultValue)|$($Msg)-�������ϡ��ȼ�������׼." -ForegroundColor red
      return $Result
    }
  }
}

function F_GetRegPropertyValue {
  param (
    [Parameter(Mandatory=$true)][String]$Key,
    [Parameter(Mandatory=$true)][String]$Name,
    [Parameter(Mandatory=$true)][String]$Operator,
    [Parameter(Mandatory=$true)]$DefaultValue,
    [Parameter(Mandatory=$true)][String]$Msg
  )

  try {
    $Value = Get-ItemPropertyValue -Path "Registry::$Key" -ErrorAction Ignore -WarningAction Ignore -Name $Name
    $Result = F_Tools -Key "Registry::$($Name)" -Value $Value -Operator $Operator -DefaultValue $DefaultValue  -Msg $Msg
    return $Result
  } catch {
   $Result = @{"Registry::$($Name)"="[�쳣��]|$($Key)��$($Name)�����ڸ���|$($DefaultValue)|$($Msg)"}
   Write-Host $Result.Values -ForegroundColor Red
   return $Result
  }
}

Function F_UrlRequest {
  param (
    [Parameter(Mandatory=$true)][String]$Msrc_api
  )
  Write-Host "[-] $($Msrc_api)" -ForegroundColor Gray
  $Response=Invoke-WebRequest -Uri "$($Msrc_api)"
  Return ConvertFrom-Json -InputObject $Response
}

################################################################################################################################


#
# * ����ϵͳ������Ϣ��¼���� * #
#
# - ϵͳ��Ϣ��¼���� - #
$SysInfo = @{}
# - Get-Computer ����ʹ�� 
# Tips ���� Server 2019 �Լ� Windows 10 ����ϵͳ�޸�����
# $Item = 'WindowsProductName','WindowsEditionId','WindowsInstallationType','WindowsCurrentVersion','WindowsVersion','WindowsProductId','BiosManufacturer','BiosFirmwareType','BiosName','BiosVersion','BiosBIOSVersion','BiosSeralNumber','CsBootupState','OsBootDevice','BiosReleaseDate','CsName','CsAdminPasswordStatus','CsManufacturer','CsModel','OsName','OsType','OsProductType','OsServerLevel','OsArchitecture','CsSystemType','OsOperatingSystemSKU','OsVersion','OsBuildNumber','OsSerialNumber','OsInstallDate','OsSystemDevice','OsSystemDirectory','OsCountryCode','OsCodeSet','OsLocaleID','OsCurrentTimeZone','TimeZone','OsLanguage','OsLocalDateTime','OsLastBootUpTime','CsProcessors','OsBuildType','CsNumberOfProcessors','CsNumberOfLogicalProcessors','OsMaxNumberOfProcesses','OsTotalVisibleMemorySize','OsFreePhysicalMemory','OsTotalVirtualMemorySize','OsFreeVirtualMemory','OsInUseVirtualMemory','OsMaxProcessMemorySize','CsNetworkAdapters','OsHotFixes'
# - Systeminfo ����ʹ��(ͨ��-�Ƽ�)
$Item = 'Hostname','OSName','OSVersion','OSManufacturer','OSConfiguration','OS Build Type','RegisteredOwner','RegisteredOrganization','Product ID','Original Install Date','System Boot Time','System Manufacturer','System Model','System Type','Processor(s)','BIOS Version','Windows Directory','System Directory','Boot Device','System Locale','Input Locale','Time Zone','Total Physical Memory','Available Physical Memory','Virtual Memory: Max Size','Virtual Memory: Available','Virtual Memory: In Use','Page File Location(s)','Domain','Logon Server','Hotfix(s)','Network Card(s)'
Function F_SysInfo {
  # - ��ǰϵͳ������������Ϣ (Primary)
  # Server 2019 �Լ� Windows 10 ����
  # $Computer = Get-ComputerInfo
  $Computer = systeminfo.exe /FO CSV /S $env:COMPUTERNAME |Select-Object -Skip 1 | ConvertFrom-CSV -Header $Item
  foreach( $key in $Item) {
    $SysInfo += @{"$($key)"=$Computer.$key}
  }
  # - ͨ��������Բ���`systeminfo.exe`���ʽ
  $SysInfo += @{"WindowsProductName"="$($SysInfo.OSName)"}
  $SysInfo.OsVersion=($Sysinfo.OSVersion -split " ")[0]
  $SysInfo += @{"CsSystemType"=($Sysinfo."System Type" -split " ")[0]}

  # - ��ǰϵͳ PowerShell �汾��Ϣ�Լ��Ƿ�Ϊ�����
  $SysInfo += @{"PSVersion"=$PSVersionTable.PSEdition+"-"+$PSVersionTable.PSVersion}

  # - ��֤��ǰ�������Ʒ����汾 (Primary)
  $Flag = $SysInfo.WindowsProductName -match  "Windows 8.1|Windows 10|Server 2008|Server 2012|Server 2016|Server 2019"
  $ProductName = "$($Matches.Values)"
  if ( $ProductName.Contains("Windows")) {
    $SysInfo += @{"ProductType"="Client"}
    $SysInfo += @{"ProductName"=$ProductName}
    $SysInfo += @{"WindowsVersion"=Get-ItemPropertyValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name ReleaseId}
  } else {
    $SysInfo += @{"ProductType"="Server"}
    $SysInfo += @{"ProductName"=$ProductName}
  }

  # - ��֤��ǰ�������Ʒ������������������ (Primary)
  $ComputerType = get-wmiobject win32_computersystem
  if ($ComputerType.Manufacturer -match "VMware"){
    $SysInfo += @{"ComputerType"="����� - $($ComputerType.Model)"}
  } else {
    $SysInfo += @{"ComputerType"="����� - $($ComputerType.Model)"}
  }
  
  # # - ��ǰ������¶�ֵ��Ϣ��¼
  # Get-CimInstance -Namespace ROOT/WMI -Class MSAcpi_ThermalZoneTemperature | % { 
  #   $currentTempKelvin = $_.CurrentTemperature / 10 
  #   $currentTempCelsius = $currentTempKelvin - 273.15 
  #   $currentTempFahrenheit = (9/5) * $currentTempCelsius + 32 
  #   $Temperature += "InstanceName: " + $_.InstanceName+ " ==>> " +  $currentTempCelsius.ToString() + " ���϶�(C);  " + $currentTempFahrenheit.ToString() + " ���϶�(F) ; " + $currentTempKelvin + "���϶�(K) `n" 
  # }
  # $SysInfo += @{"Temperature"=$Temperature}

  return $SysInfo
}


#
# * - �����Mac��IP��ַ��Ϣ���� * #
#
#  * ϵͳ���缰��������Ϣ���� * #
$SysNetAdapter = @{}
function F_SysNetAdapter {
  # - �����Mac��IP��ַ��Ϣ
  $Adapter = Get-NetAdapter | Sort-Object -Property LinkSpeed
  foreach ( $Item in $Adapter) {
    $IPAddress = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceIndex $Item.ifIndex).IPAddress
    $SysNetAdapter += @{"$($Item.MacAddress)"="$($Item.Status) | $($Item.Name) | $($IPAddress) | $($Item.LinkSpeed) | $($Item.InterfaceDescription)"}
  }
  return $SysNetAdapter
}


#
# * - �����ϵͳ������ռ�ʣ���ѯ���� * #
#
# - ϵͳ������ռ�ʣ����Ϣ - #
$SysDisk = @{}
function F_SysDisk {
  # - �����������Ϣ
  $Disk = Get-Disk
  foreach ( $Item in $Disk) {
    $SysDisk += @{"$($Item.SerialNumber)"="$($Item.Number) | $($Item.FriendlyName) | $($Item.HealthStatus)| $($Item.Size / [math]::Pow(1024,3)) GB | $($Item.PartitionStyle) |$($Item.OperationalStatus)"}
  }
  $Drive = Get-PSDrive -PSProvider FileSystem | Sort-Object -Property Name
  $Drive | % {
    $Free = [Math]::Round( $_.Free / [math]::pow(1024,3),2 )
    $Used = [Math]::Round( $_.Used / [math]::pow(1024,3),2 )
    $Total = [Math]::Ceiling($Free + $Used)
    $SysDisk += @{"FileSystem::$($_.Name)"="$($_.Name) | Free: $($Free) GB | Used: $($Used) GB | Total: $($Total) GB"}
  }

  return $SysDisk
}


#
# * ϵͳ�˺ż�麯��  * #
#
# - ϵͳ�˻���Ϣ���� - # 
$SysAccount = @{}
Function F_SysAccount {
  # - �˻����
  $Account = Get-WmiObject -Class Win32_UserAccount | Select-Object Name,AccountType,Caption,SID
  Write-Host "* ��ǰϵͳ���ڵ� $($Account.Length) ���˻� : $($Account.Name)" -ForegroundColor Green
  if($Acount.Length -ge 4 -and ($Account.sid  | Select-String -Pattern "^((?!(-500|-501|-503|-504)).)*$")) {
    $Result = @{"SysAccount"="[�쳣��]-ϵͳ�д��������˺�����: $($Account.Name)"}
    $SysAccount += $Result
  }else{
    $Result = @{"SysAccount"="[�ϸ���]-ϵͳ���޶��������˺�";}
    $SysAccount += $Result
  }
  return $SysAccount
}

#
# * ϵͳ�˺Ų������ú˲麯��  * #
#
# - ϵͳ�˺Ų��� - #
$SysAccountPolicy = @{
  # + �������������
  "MinimumPasswordAge" = @{operator="le";value=1;msg="�������������"}
  # + �����������
  "MaximumPasswordAge" = @{operator="le";value=90;msg="�����������"}
  # + ���볤����Сֵ
  "MinimumPasswordLength" = @{operator="ge";value=12;msg="���볤����Сֵ"}
  # + ���������ϸ�����Ҫ��
  "PasswordComplexity" = @{operator="eq";value=1;msg="���������ϸ�����Ҫ�����"}
  # + ǿ��������ʷ N����ס������
  "PasswordHistorySize" = @{operator="ge";value=3;msg="ǿ��������ʷ����ס������"}
  # + �˻���¼ʧ��������ֵN����
  "LockoutBadCount" = @{operator="le";value=6;msg="�˻���¼ʧ��������ֵ����"}
  # + �˻�����ʱ��(����)
  "ResetLockoutCount" = @{operator="ge";value=15;msg="�˻�����ʱ��(����)"}
  # + ��λ�˻�����������ʱ��(����)
  "LockoutDuration" = @{operator="ge";value=15;msg="��λ�˻�����������ʱ��(����)"}
  # + �´ε�¼�����������
  "RequireLogonToChangePassword" = @{operator="eq";value=0;msg="�´ε�¼�����������"}
  # + ǿ�ƹ���
  "ForceLogoffWhenHourExpire" = @{operator="eq";value=0;msg="ǿ�ƹ���"}
  # + ��ǰ�����˺ŵ�½����
  "NewAdministratorName" = @{operator="ne";value='"Administrator"';msg="��ǰϵͳ�����˺ŵ�½���Ʋ���"}
  # + ��ǰ�����û���½����
  "NewGuestName" = @{operator="ne";value='"Guest"';msg="��ǰϵͳ�����û���½���Ʋ���"}
  # + ����Ա�Ƿ�����
  "EnableAdminAccount" = @{operator="eq";value=1;msg="����Ա�˻�ͣ�������ò���"}
  # + �����û��Ƿ�����
  "EnableGuestAccount" = @{operator="eq";value=0;msg="�����˻�ͣ�������ò���"}
  # + ָʾ�Ƿ�ʹ�ÿ���������洢����һ�����(����Ӧ�ó���Ҫ�󳬹�����������Ϣ����Ҫ)
  "ClearTextPassword" = @{operator="eq";value=0;msg="ָʾ�Ƿ�ʹ�ÿ���������洢���� (����Ӧ�ó���Ҫ�󳬹�����������Ϣ����Ҫ)"}
  # + ����ʱ���������������û���ѯ����LSA����(0�ر�)
  "LSAAnonymousNameLookup" = @{operator="eq";value=0;msg="����ʱ���������������û���ѯ����LSA���� (0�ر�)"}
  # + �������ŵĿ�����
  "CheckResults" = @()
  }
Function F_SysAccountPolicy {
  $Count = $Config.Count
  for ($i=0;$i -lt $Count; $i++){
    $Line = $Config[$i] -split " = "
    if ($SysAccountPolicy.ContainsKey("$($Line[0])")) {
      $Result = F_Tools -Key "SysAccountPolicy::$($Line[0])" -Value $Line[1] -Operator $SysAccountPolicy["$($Line[0])"].Operator -DefaultValue $SysAccountPolicy["$($Line[0])"].Value  -Msg "ϵͳ�˺Ų�������-$($SysAccountPolicy["$($Line[0])"].Msg)"
      $SysAccountPolicy['CheckResults'] += $Result
    }
    if ( $Line[0] -eq "[Event Audit]" ) { break;}
  }
  return $SysAccountPolicy['CheckResults']
}



#
# * ϵͳ�¼���˲������ú˲麯��  * #
#
# - ϵͳ�¼���˲��� - #
$SysEventAuditPolicy  = @{
  # + ���ϵͳ�¼�(0) [�ɹ�(1)��ʧ��(2)] (3)
  AuditSystemEvents = @{operator="eq";value=3;msg="���ϵͳ�¼�"}
  # + ��˵�¼�¼� �ɹ���ʧ��
  AuditLogonEvents = @{operator="eq";value=3;msg="��˵�¼�¼�"}
  # + ��˶������ �ɹ���ʧ��
  AuditObjectAccess = @{operator="eq";value=3;msg="��˶������"}
  # + �����Ȩʹ�� ʧ��
  AuditPrivilegeUse = @{operator="ge";value=2;msg="�����Ȩʹ��"}
  # + ��˲��Ը��� �ɹ���ʧ��
  AuditPolicyChange = @{operator="eq";value=3;msg="��˲��Ը���"}
  # + ����˻����� �ɹ���ʧ��
  AuditAccountManage = @{operator="eq";value=3;msg="����˻�����"}
  # + ��˹���׷�� ʧ��
  AuditProcessTracking = @{operator="ge";value=2;msg="��˹���׷��"}
  # + ���Ŀ¼������� ʧ��
  AuditDSAccess = @{operator="ge";value=2;msg="���Ŀ¼�������"}
  # + ����˻���¼�¼� �ɹ���ʧ��
  AuditAccountLogon = @{operator="eq";value=3;msg="����˻���¼�¼�"}
  # + �������ŵĿ�����
  CheckResults = @()
}
function F_SysEventAuditPolicy {
  $Count = $Config.Count
  for ($i=0;$i -lt $Count; $i++){
    $Line = $Config[$i] -split " = "
    if ( $Line[0] -eq "[Registry Values]" ) { break;}
    if ($SysEventAuditPolicy.ContainsKey("$($Line[0])")) {
      $Result = F_Tools -Key "SysEventAuditPolicy::$($Line[0])" -Value $Line[1] -Operator $SysEventAuditPolicy["$($Line[0])"].Operator -DefaultValue $SysEventAuditPolicy["$($Line[0])"].Value  -Msg "ϵͳ�˺Ų�������-$($SysEventAuditPolicy["$($Line[0])"].Msg)"
      $SysEventAuditPolicy['CheckResults'] += $Result
    }
  }

  return $SysEventAuditPolicy['CheckResults']
}


#
# * ����ϵͳ�û�Ȩ�޹�����Լ��  * #
#
# - ������û�Ȩ�޹������ - #
$SysUserPrivilegePolicy = @{
# + ����ϵͳ���عػ����԰�ȫ
SeShutdownPrivilege = @{operator="eq";value='*S-1-5-32-544';msg="����ϵͳ���عػ�����"}
# + ����ϵͳԶ�̹ػ����԰�ȫ
SeRemoteShutdownPrivilege = @{operator="eq";value='*S-1-5-32-544';msg="����ϵͳԶ�̹ػ�����"}
# + ȡ���ļ����������������Ȩ�޲���
SeProfileSingleProcessPrivilege = @{operator="eq";value='*S-1-5-32-544';msg="ȡ���ļ����������������Ȩ�޲���"}
# + ��������ʴ˼��������
SeNetworkLogonRight = @{operator="eq";value='*S-1-5-32-544,*S-1-5-32-545,*S-1-5-32-551';msg="��������ʴ˼��������"}
CheckResults = @()
}

Function F_SysUserPrivilegePolicy {
  # - �������û�Ȩ������
  $Hash = $SysUserPrivilegePolicy.Clone()  # �޿�֮��
  foreach ( $Name in $Hash.keys) {
    if ( $Name.Equals("CheckResults")){ continue; }
    $Line = ($Config | Select-String $Name.toString()) -split " = "
    $Result = F_Tools -Key "SysUserPrivilegePolicy::$($Line[0])" -Value $Line[1] -Operator $SysUserPrivilegePolicy["$($Line[0])"].Operator -DefaultValue $SysUserPrivilegePolicy["$($Line[0])"].Value  -Msg "�������û�Ȩ������-$($SysUserPrivilegePolicy["$($Line[0])"].Msg)"
    $SysUserPrivilegePolicy['CheckResults'] += $Result
  }
  return $SysUserPrivilegePolicy['CheckResults']
}


#
# * ����ϵͳ�����鰲ȫѡ��Ȩ�����ü�� * #
# 
# - ����԰�ȫѡ����� - #
$SysSecurityOptionPolicy = @{
  # - �ʻ�:ʹ�ÿ�����ı����ʻ�ֻ������п���̨��¼(����),ע������ò�Ӱ��ʹ�����ʻ��ĵ�¼��(0����|1����)
  LimitBlankPasswordUse = @{operator="eq";value="MACHINE\System\CurrentControlSet\Control\Lsa\LimitBlankPasswordUse=4,1";msg="�ʻ�-ʹ�ÿ�����ı����ʻ�ֻ������п���̨��¼(����)"}
  
  # - ����ʽ��¼: ����ʾ�ϴε�¼�û���ֵ(����)
  DontDisplayLastUserName = @{operator="eq";value="MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System\DontDisplayLastUserName=4,1";msg="����ʽ��¼-����ʾ�ϴε�¼�û���ֵ(����)"}
  # - ����ʽ��¼: ��¼ʱ����ʾ�û���
  DontDisplayUserName = @{operator="eq";value="MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System\DontDisplayUserName=4,1";msg="����ʽ��¼: ��¼ʱ����ʾ�û���"}
  # - ����ʽ��¼: �����Ựʱ��ʾ�û���Ϣ(����ʾ�κ���Ϣ)
  DontDisplayLockedUserId = @{operator="eq";value="MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System\DontDisplayLockedUserId=4,3";msg="����ʽ��¼: �����Ựʱ��ʾ�û���Ϣ(����ʾ�κ���Ϣ)"}
  # - ����ʽ��¼: ���谴 CTRL+ALT+DEL(����)
  DisableCAD = @{operator="eq";value="MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System\DisableCAD=4,0";msg="����ʽ��¼-���谴CTRL+ALT+DELֵ(����)"}
  # - ����ʽ��¼��������������ֵΪ600������
  InactivityTimeoutSecs = @{operator="le";value="MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System\InactivityTimeoutSecs=4,600";msg="����ʽ��¼-������������ֵΪ600������"}
  # - ����ʽ��¼: ������ʻ���ֵ�˲�������ȷ���ɵ��¼����������ʧ�ܵ�¼���Դ���
  MaxDevicePasswordFailedAttempts = @{operator="le";value="MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System\MaxDevicePasswordFailedAttempts=4,10";msg="����ʽ��¼: �˲�������ȷ���ɵ��¼����������ʧ�ܵ�¼���Դ���"}
  # - ����ʽ��¼: ��ͼ��¼���û�����Ϣ����
  LegalNoticeCaption = @{operator="eq";value='MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System\LegalNoticeCaption=1,"��ȫ��½"';msg="����ʽ��¼: ��ͼ��¼���û�����Ϣ����"}
  # - ����ʽ��¼: ��ͼ��¼���û�����Ϣ�ı�
  LegalNoticeText = @{operator="eq";value='MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System\LegalNoticeText=7,������Ĳ�������';msg="����ʽ��¼: ��ͼ��¼���û�����Ϣ�ı�"}
  
  # - Microsoft����ͻ���: ��δ���ܵ����뷢�͵������� SMB ������(����)
  EnablePlainTextPassword = @{operator="eq";value="MACHINE\System\CurrentControlSet\Services\LanmanWorkstation\Parameters\EnablePlainTextPassword=4,0";msg="Microsoft����ͻ���-��δ���ܵ����뷢�͵������� SMB ������(����)"}
  # - Microsoft�������������ͣ�Ựǰ����Ŀ���ʱ������ֵΪ15���ӻ���ٵ���Ϊ0
  AutoDisconnect = @{operator="eq";value="MACHINE\System\CurrentControlSet\Services\LanManServer\Parameters\AutoDisconnect=4,15";msg="Microsoft���������-��ͣ�Ựǰ����Ŀ���ʱ������ֵΪ15����"}
  
  # - ���簲ȫ: ����һ�θı�����ʱ���洢LAN��������ϣֵ(����)
  NoLMHash = @{operator="eq";value="MACHINE\System\CurrentControlSet\Control\Lsa\NoLMHash=4,1";msg="���簲ȫ-����һ�θı�����ʱ���洢LAN��������ϣֵ(����)"}
  
  # - �������: ������SAM�˻�������ö��ֵΪ(����)
  RestrictAnonymousSAM = @{operator="eq";value="MACHINE\System\CurrentControlSet\Control\Lsa\RestrictAnonymousSAM=4,1";msg="�������-������SAM�˻�������ö��ֵΪ(����)"}
  # - �������:������SAM�˻��͹��������ö��ֵΪ(����)
  RestrictAnonymous = @{operator="eq";value="MACHINE\System\CurrentControlSet\Control\Lsa\RestrictAnonymous=4,1";msg="�������-������SAM�˻��͹��������ö��ֵΪ(����)"}
  
  # - �ػ�:����ȷ���Ƿ�����������¼ Windows ������¹رռ����(����)
  ClearPageFileAtShutdown = @{operator="eq";value="MACHINE\System\CurrentControlSet\Control\Session Manager\Memory Management\ClearPageFileAtShutdown=4,0";msg="�ػ�-����ȷ���Ƿ�����������¼ Windows ������¹رռ����(����)"}
  
  "CheckResults" = @()
}
Function F_SysSecurityOptionPolicy {
  $Hash = $SysSecurityOptionPolicy.Clone()  # �޿�֮��
  foreach ( $Name in $Hash.keys) {
    if ( $Name.Equals("CheckResults")){ continue; }
    $Flag = $Config | Select-String $Name.toString() 
    $Value = $SysSecurityOptionPolicy["$($Name)"].Value -split ","
    if ( $Flag ) {
      $Line = $Flag -split ","
      $Result = F_Tools -Key "SysSecurityOptionPolicy::$($Name)" -Value $Line[1] -Operator $SysSecurityOptionPolicy["$($Name)"].Operator -DefaultValue $Value[1] -Msg "�����鰲ȫѡ������-$($SysSecurityOptionPolicy["$($Name)"].Msg)"
      $SysSecurityOptionPolicy['CheckResults'] += $Result
    } else {
      $Result = @{"SysSecurityOptionPolicy::$($Name)"="[�쳣��]|δ����|$($Value[1])|�����鰲ȫѡ������-$($SysSecurityOptionPolicy["$($Name)"].Msg)-�������ϡ��ȼ�������׼."}
      $SysSecurityOptionPolicy['CheckResults'] += $Result
    }
  }
  return $SysSecurityOptionPolicy['CheckResults']
}


#
# * ����ϵͳע���������ü�麯��  * #
#
# - ע�����ذ�ȫ����  -
$SysRegistryPolicy = @{
# + ��ֹȫ���������Զ�����
NoDriveTypeAutoRun = @{name="NoDriveTypeAutoRun";operator="eq";value=233;regname="HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer";msg="ϵͳ����˲�-��ֹȫ���������Զ�����"}
# + ��Ļ�Զ���������
ScreenSaveActive = @{name="ScreenSaveActive";operator="eq";value=1;regname="HKEY_CURRENT_USER\Control Panel\Desktop";msg="ϵͳ����˲�-��Ļ�Զ������������"}
# + ��Ļ�ָ�ʱʹ�����뱣��
ScreenSaverIsSecure = @{name="ScreenSaverIsSecure";operator="eq";value=1;regname="HKEY_CURRENT_USER\Control Panel\Desktop";msg="ϵͳ����˲�-��Ļ�ָ�ʱʹ�����뱣������"}
# + ��Ļ������������ʱ��
ScreenSaveTimeOut = @{name="ScreenSaveTimeOut";operator="le";value=600;regname="HKEY_CURRENT_USER\Control Panel\Desktop";msg="ϵͳ����˲�-��Ļ������������ʱ�����"}

# - ���ر�Ĭ�Ϲ�����
restrictanonymous = @{name="restrictanonymous";operator="eq";value=1;regname="HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa";msg="ϵͳ�������˲�-�ر�Ĭ�Ϲ����̲���"}

# - ϵͳ��Ӧ�á���ȫ��PS��־�鿴����С����
EventlogSystemMaxSize = @{name="MaxSize";operator="ge";value=20971520;regname="HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Eventlog\System";msg="ϵͳ����־��˲�-ϵͳ��־�鿴����С���ò���"}
EventlogApplicationMaxSize = @{name="MaxSize";operator="ge";value=20971520;regname="HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Eventlog\Application";msg="ϵͳ��־����˲�-Ӧ����־�鿴����С���ò���"}
EventlogSecurityMaxSize = @{name="MaxSize";operator="ge";value=20971520;regname="HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Eventlog\Security";msg="ϵͳ��־����˲�-��ȫ��־�鿴����С���ò���"}
EventlogPSMaxSize = @{name="MaxSize";operator="ge";value=15728640;regname="HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Eventlog\Windows PowerShell";msg="ϵͳ��־����˲�-PS��־�鿴����С���ò���"}

# - ����洢
CheckResults=@()
}
Function F_SysRegistryPolicy { 
  $Registry=  $SysRegistryPolicy.Clone()
  foreach ( $item in $Registry.keys) {
    if ( $item -eq "CheckResults" ){ continue;}
    $Result = F_GetRegPropertyValue -Key $SysRegistryPolicy.$item.regname -Name $SysRegistryPolicy.$item.name -Operator $SysRegistryPolicy.$item.operator -DefaultValue $SysRegistryPolicy.$item.value -Msg $SysRegistryPolicy.$item.msg
    $SysRegistryPolicy['CheckResults'] += $Result
  }
  return $SysRegistryPolicy['CheckResults']
}

#
# * ����ϵͳ�������г����麯��  * #
#
$SysProcessServicePolicy = @{"CheckResults"=@()}
function F_SysProcessServicePolicy {
  # + ���ϵͳ���û�����������
  $SysAutoStart = Get-Item -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
  $SysAutoStart.GetValueNames() | % { 
    $res += "$($_)#$($SysAutoStart.GetValue($_)) "
  }
  $Result = @{"SysProcessServicePolicy::SysAutoStart"=$res}
  $SysProcessServicePolicy['CheckResults'] += $Result

  $UserAutoStart = Get-Item -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
  $UserAutoStart.GetValueNames() | % { 
    $res += "$($_)#$($SysAutoStart.GetValue($_)) "
  }
  $Result = @{"SysProcessServicePolicy::UserAutoStart"=$res}
  $SysProcessServicePolicy['CheckResults'] += $Result

  # + ������Զ���������
  $RDPStatus = (Get-Service -Name "TermService").Status
  # if ($RDP -eq "0" -and $RDPStatus -eq "Running" ) {
  #   $Result = @{"SysProcessServicePolicy::RDPStatus"="��ǰϵͳ�������á�Զ���������."}
  # } else {
  #   $Result = @{"SysProcessServicePolicy::RDPStatus"="��ǰϵͳ��δ���á�Զ���������."}
  # }
  if ($RDPStatus -eq "Running" ) {
    $Result = F_GetRegPropertyValue -Key 'HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Terminal Server' -Name 'fDenyTSConnections' -Operator "eq" -DefaultValue 0 -Msg "�Ƿ�Զ������������"
  } else {
    $Result = @{"SysProcessServicePolicy::RDPStatus"="��ǰϵͳ��δ���á�Զ���������."}
  }
  $SysProcessServicePolicy['CheckResults'] += $Result
  # - ������NTP������ͬ��ʱ��
  # $NTP = F_GetReg -Key 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\NtpServer' -Name 'Enabled'
  # if ( $NTP -eq "1") {
  #   $Result = @{"SysProcessServicePolicy::NtpServerEnabled"="[�ϸ���]|$NTP|1|ϵͳ�������ú˲�-����NTP����ͬ��ʱ�Ӳ���-�����ϡ��ȼ�������׼."}
  # } else {
  #   $Result = @{"SysProcessServicePolicy::NtpServerEnabled"="[�쳣��]|$NTP|1|ϵͳ�������ú˲�-����NTP����ͬ��ʱ�Ӳ���-�������ϡ��ȼ�������׼."}
  # }
  $Result = F_GetRegPropertyValue -Key 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\NtpServer' -Name 'Enabled' -Operator "eq" -DefaultValue 1 -Msg "�Ƿ�����NTP����ͬ��ʱ�Ӳ���"
  $SysProcessServicePolicy['CheckResults'] += $Result
  

  # - �Ƿ��޸�Ĭ�ϵ�Զ������˿�
  $RDP1 = Get-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\' | % {$_.GetValue("PortNumber")}
  $RDP2 = Get-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\Wds\rdpwd\Tds\tcp\' | % {$_.GetValue("PortNumber")} 
  if ( $RDP1 -eq $RDP2 -and $RDP2 -ne "3389") {
    $Result = @{"SysProcessServicePolicy::RDPPort"="[�ϸ���]|$RDP1|��3389����Ķ˿�|ϵͳ�������ú˲�-Ĭ�ϵ�Զ������˿����޸�-�����ϡ��ȼ�������׼."}
  } else {
    $Result = @{"SysProcessServicePolicy::RDPPort"="[�쳣��]|$RDP1|��3389����Ķ˿�|ϵͳ�������ú˲�-Ĭ�ϵ�Զ������˿�δ�޸�-�������ϡ��ȼ�������׼."}
  }
  $SysProcessServicePolicy['CheckResults'] += $Result
}


#
# * ����ϵͳ��ȫ��⺯�� * 
#
# * ΢��Windows��������ȫ�����б���Ϣ * #
$Msrc_api = "https://api.msrc.microsoft.com/sug/v2.0/zh-CN/affectedProduct?%24orderBy=releaseDate+desc&%24filter=productFamilyId+in+%28%27100000010%27%29+and+severityId+in+%28%27100000000%27%2C%27100000001%27%29+and+%28releaseDate+gt+2020-01-14T00%3A00%3A00%2B08%3A00%29+and+%28releaseDate+lt+2021-05-22T23%3A59%3A59%2B08%3A00%29"
$SysWSUSList = @{}
$SysWSUSListId = @()
$AvailableWSUSList = @{}
function F_SysSecurityPolicy {
  # - ϵͳ������֤
  if ( $Update -or ! (Test-Path -Path .\WSUSList.json) ) {
    $MSRC_JSON = F_UrlRequest -Msrc_api $Msrc_api
    $MSRC_JSON.value | % { 
      $id = $_.id;
      $product = $_.product;
      $articleName = $_.kbArticles.articleName | Get-Unique;
      $fixedBuildNumber = $_.kbArticles.fixedBuildNumber | Get-Unique;
      $severity = $_.severity;
      $impact = $_.impact;
      $baseScore = $_.baseScore;
      $cveNumber = $_.cveNumber | Get-Unique;
      $releaseDate = $_.releaseDate
      $SysWSUSList += @{"$($id)"=@{"product"=$product;"articleName"=$articleName;"fixedBuildNumber"=$fixedBuildNumber;"severity"=$severity;"impact"=$impact;"baseScore"=$baseScore;"cveNumber"=$cveNumber;"releaseDate"=$releaseDate}}
    }
    while ($MSRC_JSON.'@odata.nextLink'.length) {
      $MSRC_JSON = F_UrlRequest -Msrc_api $MSRC_JSON.'@odata.nextLink'
      $MSRC_JSON.value | % { 
        $id = $_.id;
        $product = $_.product;
        $articleName = $_.kbArticles.articleName | Get-Unique;
        $fixedBuildNumber = $_.kbArticles.fixedBuildNumber | Get-Unique;
        $severity = $_.severity;
        $impact = $_.impact;
        $baseScore = $_.baseScore;
        $cveNumber = $_.cveNumber | Get-Unique;
        $releaseDate = $_.releaseDate
        $SysWSUSList += @{"$($id)"=@{"product"=$product;"articleName"=$articleName;"fixedBuildNumber"=$fixedBuildNumber;"severity"=$severity;"impact"=$impact;"baseScore"=$baseScore;"cveNumber"=$cveNumber;"releaseDate"=$releaseDate }}
      }
    }
    Write-Host "[-] �Ѵ� Microsoft ��ȫ��Ӧ���Ļ�ȡ���� $($MSRC_JSON.'@odata.count') ��������Ϣ!" -ForegroundColor Green
    Write-Host "[-] ���ڽ���ȡ�ĸ��� $($MSRC_JSON.'@odata.count') ��������Ϣд�뵽���� WSUSList.json �ļ�֮��!" -ForegroundColor Green
    $SysWSUSList | ConvertTo-Json | Out-File WSUSList.json -Encoding utf8
    $SysWSUSListId = $SysWSUSList.keys
    $SysWSUSList.keys | ConvertTo-Json | Out-File WSUSListId.json -Encoding utf8
  } else {
    # �ӱ��ض�ȡJSON�ļ��洢�Ĳ�����Ϣ��
    if (Test-Path -Path .\WSUSList.json) {
      $SysWSUSList = Get-Content -Raw -Encoding UTF8 .\WSUSList.json | ConvertFrom-Json
      $SysWSUSListId  = Get-Content -Raw -Encoding UTF8 .\WSUSListId.json | ConvertFrom-Json
      Write-Host "[-] �Ѵӱ��� WSUSList.json �ļ���� $($SysWSUSListId.count) ��������Ϣ!" -ForegroundColor Green
    } else {
      Write-Host "[-] ����δ���ҵ���Ų�����Ϣ�� WSUSList.json �ļ�! ����� -Update True ��Ǵ�Microsoft ��ȫ��Ӧ���Ļ�ȡ����" -ForegroundColor Red
      break
      exit
    }
  }
 
  # ��ȡ��ǰϵͳ�汾���õĲ����б�
  $AvailableWSUSListId = @() 
  if ($SysInfo.ProductType -eq "Client") {
    Write-Host "[-] Desktop Client" -ForegroundColor Gray
    foreach ($KeyName in $SysWSUSListId) {
      if(($SysWSUSList."$KeyName".product -match $SysInfo.ProductName) -and ($SysWSUSList."$KeyName".product -match $SysInfo.WindowsVersion) -and ($SysWSUSList."$KeyName".product -match ($SysInfo.CsSystemType -split " ")[0])) {
        if (($SysWSUSList."$KeyName".fixedBuildNumber -match $SysInfo.OsVersion) -or ($SysWSUSList."$KeyName".fixedBuildNumber.length -eq 0 )) {
          $AvailableWSUSList."$KeyName" = $SysWSUSList."$KeyName"
          $AvailableWSUSListId += "$KeyName"
        }
      }
    }
  } else {
    Write-Host "[-] Windows Server" -ForegroundColor Gray
    foreach ($KeyName in $SysWSUSListId) {
      if(($SysWSUSList."$KeyName".product -match $SysInfo.ProductName) -and ($SysWSUSList."$KeyName".product -match $SysInfo.ProductName)) {
        $AvailableWSUSList."$KeyName" = $SysWSUSList."$KeyName"
        $AvailableWSUSListId += "$KeyName"
      }
    }
  }
  Write-Host $SysInfo.ProductName $SysInfo.WindowsVersion ($SysInfo.CsSystemType -split " ")[0] $SysInfo.OsVersion
  Write-Host "[-] �Ѵ�����������ڵ�ǰ $($SysInfo.ProductType) ϵͳ�汾�� $($AvailableWSUSList.count) ��������Ϣ!`n" -ForegroundColor Green

  # �Ѱ�װ�Ĳ���
  $InstallWSUSList = @{}
  $msg = @()
  foreach ($id in $AvailableWSUSListId) {
    if( $SysInfo.'Hotfix(s)' -match $AvailableWSUSList."$id".articleName ) {
      $InstallWSUSList."$id" = $SysWSUSList."$id"
      $msg += "[+]" + $SysWSUSList."$id".product + $SysWSUSList."$id".fixedBuildNumber + " " +  $SysWSUSList."$id".articleName + "(" + $SysWSUSList."$id".cveNumber   + ")" + $SysWSUSList."$id".severity  + $SysWSUSList."$id".baseScore + "`n"
    } 
  }
  Write-Host "[-] $($SysInfo.'Hotfix(s)') ���� $($AvailableWSUSList.count) ��©��������Ϣ!`n$($msg)" -ForegroundColor Green

  # δ��װ�Ĳ���
  $NotInstallWSUSList = @{}
  $msg = @()
  foreach ($id in $AvailableWSUSListId) {
    if(-not($InstallWSUSList."$id")) {
     $NotInstallWSUSList."$id" = $SysWSUSList."$id"
     $msg += "[+]" + $SysWSUSList."$id".product + $SysWSUSList."$id".fixedBuildNumber + " " + $SysWSUSList."$id".articleName + "(" + $SysWSUSList."$id".cveNumber + ")" + $SysWSUSList."$id".severity + $SysWSUSList."$id".baseScore + "`n"
    }
  }
  Write-Host "[-] δ��װ $($NotInstallWSUSList.count) ��©��������Ϣ���� $($AvailableWSUSList.count) ��©��������Ϣ!`n$($msg)" -ForegroundColor red
}

#
# * �����⺯�� * 
#
$OtherCheck = @{}
function F_OtherCheckPolicy {
  # - ��ǰϵͳ�Ѱ�װ�����
  $Product = Get-WmiObject -Class Win32_Product | Select-Object -Property Name,Version,IdentifyingNumber | Sort-Object Name | Out-String
  $OtherCheck += @{"Product"="$($Product)"}

  # - ��ǰϵͳ��������ļ�����Ŀ¼
  $Recent = (Get-ChildItem ~\AppData\Roaming\Microsoft\Windows\Recent).Name
  $OtherCheck += @{"Recent"="$($Recent)"}
  return $OtherCheck
}


Write-Host "Job ִ����: $($Executor)  `nɨ�迪ʼʱ��: $($ScanTime) `n[-] ��ǰϵͳ��Ϣһ��" -ForegroundColor Green
$SysInfo = F_SysInfo
$SysInfo

Write-Host "[-] ��ǰϵͳ������Ϣһ��" -ForegroundColor Green
$SysNetAdapter = F_SysNetAdapter
$SysNetAdapter

Write-Host "[-] ��ǰϵͳ������Ϣһ��" -ForegroundColor Green
$SysDisk = F_SysDisk
$SysDisk

Write-Host "[-] ��ǰϵͳ�˻���Ϣһ��" -ForegroundColor Green
$SysAccount = F_SysAccount
$SysAccount

Write-Host "[-] ��ǰϵͳ��ȫ������Ϣһ��" -ForegroundColor Green
$SysAccountPolicy.CheckResults = F_SysAccountPolicy
$SysEventAuditPolicy.CheckResults = F_SysEventAuditPolicy
$SysUserPrivilegePolicy.CheckResults = F_SysUserPrivilegePolicy
$SysSecurityOptionPolicy.CheckResults = F_SysSecurityOptionPolicy
$SysRegistryPolicy.CheckResults = F_SysRegistryPolicy
$SysProcessServicePolicy.CheckResults = F_SysProcessServicePolicy

Write-Host "[-] ��ǰϵͳ������Ϣһ��" -ForegroundColor Green
$OtherCheck = F_OtherCheckPolicy
$OtherCheck.Values

Write-Host "[-] ��ǰϵͳ��ȫ���������Ϣһ��" -ForegroundColor Green
F_SysSecurityPolicy

Write-Host "ɨ�����ʱ��: $(Get-Date)" -ForegroundColor Green
