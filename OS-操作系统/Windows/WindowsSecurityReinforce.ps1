## ----------------------------------------- ##
# @Author: WeiyiGeek
# @Description:  WindowsServer Security Initiate
# @Create Time:  2019��5��6�� 11:04:42
# @Last Modified time: 2021-11-15 11:06:31
# @E-mail: master@weiyigeek.top
# @Blog: https://www.weiyigeek.top
# @wechat: WeiyiGeeker
# @Github: https://github.com/WeiyiGeek/SecOpsDev/tree/master/OS-����ϵͳ/Windows/
# @Version: 3.2
# @Runtime: Server 2019 / Windows 10
## ----------------------------------------- ##
# �ű���Ҫ����˵��:
# (1) CentOS7ϵͳ��ʼ����������IP��ַ���á���������������Լ���װ�ӹ̡�
# (2) CentOS7ϵͳ�����Լ�JDK��ػ�����װ��
# (3) CentOS7ϵͳ���쳣������־�����
# (4) CentOS7ϵͳ�г������װ���ã��������ݱ���Ŀ¼��
## ----------------------------------------- ##


# ϵͳ���������ļ���ȡ(ע�����ϵͳ����ԱȨ������) *
secedit /export /cfg config.cfg /quiet
if ( -not(Test-Path -Path config.cfg)) { Write-Host "[-] ��ʹ�ù���ԱȨ�����иýű���" -ForegroundColor Red; exit; } else { Copy-Item -Path config.cfg -Destination config.cfg.bak -Force }
$Config = Get-Content -path config.cfg
$SecConfig = $Config.Clone()
$StartTime = Get-date -Format 'yyyy-M-d H:m:s'

<#
.SYNOPSIS
F_Detection ����: ȫ�ֹ��ù���������
.DESCRIPTION
�������ڼ�� config.cfg �ؼ����Ƿ�ƥ�䲢������Ӧ�Ľ����
.EXAMPLE
An example
#>
function F_Detection {
  param (
    [Parameter(Mandatory=$true)]$Value,
    [Parameter(Mandatory=$true)]$Operator,
    [Parameter(Mandatory=$true)]$DefaultValue  
  )
  if ( $Operator -eq "eq" ) {
    if ( $Value -eq "$DefaultValue" ) {return 1;} else { return 0;}
  } elseif ($Operator -eq  "ne" ) {
    if ( $Value -ne $DefaultValue ) {return 1;} else { return 0;}
  } elseif ($Operator -eq  "le") {
    if ( $Value -le $DefaultValue ) {return 1;} else { return 0;}
  } elseif ($Operator -eq "ge") {
    if ( $Value -ge $DefaultValue ) {return 1;} else { return 0;}
  }
}


<#
.SYNOPSIS
F_GetRegPropertyValue ����: ȫ�ֹ��ù�������������
.DESCRIPTION
�������ڻ�ȡָ������ֵ�����жԱȲ���������������򷵻�NotExist
.EXAMPLE
An example
#>

function F_GetRegPropertyValue {
  param (
    [Parameter(Mandatory=$true)][String]$Key,
    [Parameter(Mandatory=$true)][String]$Name,
    [Parameter(Mandatory=$true)][String]$Operator,
    [Parameter(Mandatory=$true)]$DefaultValue
  )

  try {
    $Value = Get-ItemPropertyValue -Path "Registry::$Key" -Name $Name -ErrorAction Ignore -WarningAction Ignore 
    $Result = F_Detection -Value $Value -Operator $Operator -DefaultValue $DefaultValue
    return $Result
  } catch {
    Write-Host "[-] $Key - $Name - NotExist" -ForegroundColor Red
    return 'NotExist'
  }
}



<#
.SYNOPSIS
F_SeceditReinforce ��������ڲ���������޸�

.DESCRIPTION
��� config.cfg ��ȫ��������м�Ⲣ�޸�

.EXAMPLE
An example
#>

# - ϵͳ�˺Ų��� - #
$SysAccountPolicy = @{
  # + �������������
  "MinimumPasswordAge" = @{operator="eq";value=1;msg="�������������"}
  # + �����������
  "MaximumPasswordAge" = @{operator="eq";value=90;msg="�����������"}
  # + ���볤����Сֵ
  "MinimumPasswordLength" = @{operator="ge";value=14;msg="���볤����Сֵ"}
  # + ���������ϸ�����Ҫ��
  "PasswordComplexity" = @{operator="eq";value=1;msg="����������ϸ�����Ҫ�����"}
  # + ǿ��������ʷ N����ס������
  "PasswordHistorySize" = @{operator="ge";value=3;msg="ǿ��������ʷN����ס������"}
  # + �˻���¼ʧ��������ֵN����
  "LockoutBadCount" = @{operator="eq";value=6;msg="�˻���¼ʧ��������ֵ����"}
  # + �˻�����ʱ��(����)
  "ResetLockoutCount" = @{operator="ge";value=15;msg="�˻�����ʱ��(����)"}
  # + ��λ�˻�����������ʱ��(����)
  "LockoutDuration" = @{operator="ge";value=15;msg="��λ�˻�����������ʱ��(����)"}
  # + �´ε�¼�����������
  "RequireLogonToChangePassword" = @{operator="eq";value=0;msg="�´ε�¼�����������"}
  # + ǿ�ƹ���
  "ForceLogoffWhenHourExpire" = @{operator="eq";value=1;msg="ǿ�ƹ���"}
  # + ��ǰ�����˺ŵ�½����
  "NewAdministratorName" = @{operator="ne";value='"cqzk_Admin"';msg="��ǰϵͳ�����˺ŵ�½���Ʋ���"}
  # + ��ǰ�����û���½����
  "NewGuestName" = @{operator="ne";value='"cqzk_Guest"';msg="��ǰϵͳ�����û���½���Ʋ���"}
  # + ����Ա�Ƿ�����
  "EnableAdminAccount" = @{operator="eq";value=1;msg="����Ա�˻�ͣ�������ò���"}
  # + �����û��Ƿ�����
  "EnableGuestAccount" = @{operator="eq";value=0;msg="�����˻�ͣ�������ò���"}
  # + ָʾ�Ƿ�ʹ�ÿ���������洢����һ�����(����Ӧ�ó���Ҫ�󳬹�����������Ϣ����Ҫ)
  "ClearTextPassword" = @{operator="eq";value=0;msg="ָʾ�Ƿ�ʹ�ÿ���������洢���� (����Ӧ�ó���Ҫ�󳬹�����������Ϣ����Ҫ)"}
  # + ����ʱ���������������û���ѯ����LSA����(0�ر�)
  "LSAAnonymousNameLookup" = @{operator="eq";value=0;msg="����ʱ���������������û���ѯ����LSA���� (0�ر�)"}
}

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
}

# - ϵͳ����԰�ȫѡ����� - #
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
  InactivityTimeoutSecs = @{operator="eq";value="MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System\InactivityTimeoutSecs=4,600";msg="����ʽ��¼-������������ֵΪ600������"}
  # - ����ʽ��¼: ������ʻ���ֵ�˲�������ȷ���ɵ��¼����������ʧ�ܵ�¼���Դ���
  MaxDevicePasswordFailedAttempts = @{operator="le";value="MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System\MaxDevicePasswordFailedAttempts=4,10";msg="����ʽ��¼: �˲�������ȷ���ɵ��¼����������ʧ�ܵ�¼���Դ���"}
  # - ����ʽ��¼: ��ͼ��¼���û�����Ϣ����
  LegalNoticeCaption = @{operator="eq";value='MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System\LegalNoticeCaption=1,"��ȫ��½"';msg="����ʽ��¼: ��ͼ��¼���û�����Ϣ����"}
  # - ����ʽ��¼: ��ͼ��¼���û�����Ϣ�ı�
  LegalNoticeText = @{operator="eq";value='MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System\LegalNoticeText=7,������Ĳ�������,���в����������';msg="����ʽ��¼: ��ͼ��¼���û�����Ϣ�ı�"}
  
  # - Microsoft����ͻ���: ��δ���ܵ����뷢�͵������� SMB ������(����)
  EnablePlainTextPassword = @{operator="eq";value="MACHINE\System\CurrentControlSet\Services\LanmanWorkstation\Parameters\EnablePlainTextPassword=4,0";msg="Microsoft����ͻ���-��δ���ܵ����뷢�͵������� SMB ������(����)"}
  # - Microsoft�������������ͣ�Ựǰ����Ŀ���ʱ������ֵΪ15���ӻ���ٵ���Ϊ0
  AutoDisconnect = @{operator="15";value="MACHINE\System\CurrentControlSet\Services\LanManServer\Parameters\AutoDisconnect=4,15";msg="Microsoft���������-��ͣ�Ựǰ����Ŀ���ʱ������ֵΪ15����"}
  
  # - ���簲ȫ: ����һ�θı�����ʱ���洢LAN��������ϣֵ(����)
  NoLMHash = @{operator="eq";value="MACHINE\System\CurrentControlSet\Control\Lsa\NoLMHash=4,1";msg="���簲ȫ-����һ�θı�����ʱ���洢LAN��������ϣֵ(����)"}
  
  # - �������: ������SAM�˻�������ö��ֵΪ(����)
  RestrictAnonymousSAM = @{operator="eq";value="MACHINE\System\CurrentControlSet\Control\Lsa\RestrictAnonymousSAM=4,1";msg="�������-������SAM�˻�������ö��ֵΪ(����)"}
  # - �������:������SAM�˻��͹��������ö��ֵΪ(����)
  RestrictAnonymous = @{operator="eq";value="MACHINE\System\CurrentControlSet\Control\Lsa\RestrictAnonymous=4,1";msg="�������-������SAM�˻��͹��������ö��ֵΪ(����)"}
  
  # - �ػ�:����ȷ���Ƿ�����������¼ Windows ������¹رռ����(����)
  ClearPageFileAtShutdown = @{operator="eq";value="MACHINE\System\CurrentControlSet\Control\Session Manager\Memory Management\ClearPageFileAtShutdown=4,0";msg="�ػ�-����ȷ���Ƿ�����������¼ Windows ������¹رռ����(����)"}
}

# - ����ϵͳ������û�Ȩ�޹������ - #
$SysUserPrivilegePolicy = @{
  # + ����ϵͳ���عػ����԰�ȫ
  SeShutdownPrivilege = @{operator="eq";value='*S-1-5-32-544';msg="����ϵͳ���عػ�����"}
  # + ����ϵͳԶ�̹ػ����԰�ȫ
  SeRemoteShutdownPrivilege = @{operator="eq";value='*S-1-5-32-544';msg="����ϵͳԶ�̹ػ�����"}
  # + ȡ���ļ����������������Ȩ�޲���
  SeProfileSingleProcessPrivilege = @{operator="eq";value='*S-1-5-32-544';msg="ȡ���ļ����������������Ȩ�޲���"}
  # + ��������ʴ˼��������
  SeNetworkLogonRight = @{operator="eq";value='*S-1-5-32-544,*S-1-5-32-545,*S-1-5-32-551';msg="��������ʴ˼��������"}
}
function F_SeceditReinforce() {
  # - ϵͳ�˺Ų�������
  $Hash = $SysAccountPolicy.Clone()
  foreach ( $Name in $Hash.keys ) {
    $Flag = $Config | Select-String $Name.toString()
    if ($Flag) {
      Write-Host "[-] Update - $Name"
      $Line = $Flag -split " = "
      $Result = F_Detection -Value $Line[1] -Operator $SysAccountPolicy["$($Line[0])"].operator -DefaultValue $SysAccountPolicy["$($Line[0])"].value
      $NewLine = $Line[0] + " = " + $SysAccountPolicy["$($Line[0])"].value
      # - �ڲ�ƥ��ʱ���йؼ����滻����
      if ( -not($Result) -or $Line[0] -eq "NewGuestName" -or $Line[0] -eq "NewAdministratorName" ) {
	    write-host "### $Flag - $NewLine##"
        $SecConfig = $SecConfig -replace "$Flag", "$NewLine" 
      }
    } else {
      Write-Host "[+] Insert - $Name"
      $NewLine = $Name + " = " + $SysAccountPolicy["$Name"].value
      Write-Host $NewLine 
      # - �ڲ����ڸ�������ʱ���в���
      $SecConfig = $SecConfig -replace "\[System Access\]", "[System Access]`n$NewLine"
    }
  }

  # - ϵͳ�¼���˲�������
  $Hash = $SysEventAuditPolicy.Clone()
  foreach ( $Name in $Hash.keys ) {
    $Flag = $Config | Select-String $Name.toString()
    if ($Flag) {
      Write-Host "[-] Update - $Name"
      $Line = $Flag -split " = "
      $Result = F_Detection -Value $Line[1] -Operator $SysEventAuditPolicy["$($Line[0])"].operator -DefaultValue $SysEventAuditPolicy["$($Line[0])"].value
      $NewLine = $Line[0] + " = " + $SysEventAuditPolicy["$($Line[0])"].value
      # - �ڲ�ƥ��ʱ���йؼ����滻����
      if (-not($Result)) {
        $SecConfig = $SecConfig -replace "$Flag", "$NewLine" 
      }
    } else {
      Write-Host "[+] Insert - $Name"
      $NewLine = $Name + " = " + $SysEventAuditPolicy["$Name"].value
      Write-Host $NewLine 
      # - �ڲ����ڸ�������ʱ���в���
      $SecConfig = $SecConfig -replace "\[Event Audit\]", "[Event Audit] `n$NewLine"
    }
  }

  # - ϵͳ����԰�ȫѡ������ - #
  $Hash = $SysSecurityOptionPolicy.Clone()
  foreach ( $Name in $Hash.keys ) {
    $Flag = $Config | Select-String $Name.toString()
    if ($Flag) {
      Write-Host "[-] Update - $Name"
      # Դ�ַ���
      $Line = $Flag -split "="
      # Ŀ���ַ���
      $Value = $SysSecurityOptionPolicy["$($Name)"].value -split "="
      $Result = F_Detection -Value $Line[1] -Operator $SysSecurityOptionPolicy["$($Name)"].operator -DefaultValue $Value[1] 
      $NewLine = $Line[0] + "=" + $Value[1]
      if (-not($Result)) {
        $SecConfig = $SecConfig -Replace ([Regex]::Escape("$Flag")),"$NewLine" 
      }
    } else {
      Write-Host "[+] Insert - $Name"
      $NewLine = $SysSecurityOptionPolicy["$Name"].value
      Write-Host $NewLine
      # ����������ƥ��ԭ�ַ���(ֵ��ѧϰ)
      $SecConfig = $SecConfig -Replace ([Regex]::Escape("[Registry Values]")),"[Registry Values]`n$NewLine"
    }
  }

  # - ����ϵͳ���û�Ȩ�޹����������
  $Hash = $SysUserPrivilegePolicy.Clone()
  foreach ( $Name in $Hash.keys ) {
    $Flag = $Config | Select-String $Name.toString()
    if ($Flag) {
      Write-Host "[-] Update - $Name"
      $Line = $Flag -split " = "
      $Result = F_Detection -Value $Line[1] -Operator $SysUserPrivilegePolicy["$($Line[0])"].operator -DefaultValue $SysUserPrivilegePolicy["$($Line[0])"].value
      $NewLine = $Line[0] + " = " + $SysUserPrivilegePolicy["$($Line[0])"].value
      if (-not($Result)) {
        $SecConfig = $SecConfig -Replace ([Regex]::Escape("$Flag")), "$NewLine" 
      }
    } else {
      Write-Host "[+] Insert - $Name"
      $NewLine = $Name + " = " + $SysUserPrivilegePolicy["$Name"].value
      Write-Host $NewLine 
      $SecConfig = $SecConfig -Replace ([Regex]::Escape("[Privilege Rights]")),"[Privilege Rights]`n$NewLine"
    }
  }
  # ������Ա��ذ�ȫ�������secconfig.cfgע�ⲻ����ӱ����ʽ������ʱ�ᱨ��ʽ����
  $SecConfig | Out-File secconfig.cfg
}

<#
.SYNOPSIS
F_SysRegistryReinforce ���������ע�����ϵͳ������á�

.DESCRIPTION
��� config.cfg ��ȫ��������м�Ⲣ�޸�

.EXAMPLE
An example
#>

# - ע�����ذ�ȫ����  -
$SysRegistryPolicy = @{
  # + ��Ļ�Զ���������
  ScreenSaveActive = @{reg="HKEY_CURRENT_USER\Control Panel\Desktop";name="ScreenSaveActive";regtype="String";value=1;operator="eq";msg="������Ļ�Զ������������"}
  # + ��Ļ�ָ�ʱʹ�����뱣��
  ScreenSaverIsSecure = @{reg="HKEY_CURRENT_USER\Control Panel\Desktop";name="ScreenSaverIsSecure";regtype="String";value=1;operator="eq";msg="������Ļ�ָ�ʱʹ�����뱣������"}
  # + ��Ļ������������ʱ��
  ScreenSaveTimeOut = @{reg="HKEY_CURRENT_USER\Control Panel\Desktop";name="ScreenSaveTimeOut";regtype="String";value=600;operator="le";msg="������Ļ������������ʱ�����"}
  
  # + ��ֹȫ���������Զ�����
  NoDriveTypeAutoRun = @{reg="HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer";name="NoDriveTypeAutoRun";regtype="String";operator="eq";value=233;msg="��ֹȫ���������Զ�����"}
  
  # + ���ر�Ĭ�Ϲ�����
  restrictanonymous = @{reg="HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa";name="restrictanonymous";regtype="String";operator="eq";value=1;msg="�ر�Ĭ�Ϲ����̲���"}

  # + Զ�����濪����ر�
  fDenyTSConnections = @{reg='HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Terminal Server';Name='fDenyTSConnections';regtype="DWord";operator="eq";value=0;msg="�Ƿ����Զ���������"}
  RDPTcpPortNumber = @{reg='HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\';Name='PortNumber';regtype="DWord";operator="eq";value=39393;msg="Զ���������˿�RDP-Tcp��3389"}
  TDSTcpPortNumber = @{reg='HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\Wds\rdpwd\Tds\tcp\';Name='PortNumber';regtype="DWord";operator="eq";value=39393;msg="Զ���������˿�TDS-Tcp��3389"}


  #tes = @{reg='';Name='';regtype="";operator="eq";value=39393;msg="Զ���������˿ڷ�3389"}
}

function F_SysRegistryReinforce()  {
  # - ����ȼ�������ػ�������
  $Hash = $SysRegistryPolicy.Clone()
  foreach ( $Name in $Hash.keys ) {
    $Result = F_GetRegPropertyValue -Key $SysRegistryPolicy.$Name.reg -Name $SysRegistryPolicy.$Name.name -Operator $SysRegistryPolicy.$Name.operator -DefaultValue $SysRegistryPolicy.$Name.value
    if ( $Result -eq 'NotExist' ){
    
      # �ж�ע������Ƿ���ڲ������򴴽�
      if (-not(Test-Path -Path "Registry::$($SysRegistryPolicy.$Name.reg)")){
         New-Item -Path "registry::$($SysRegistryPolicy.$Name.reg)" -Force
      }
      # ���ܵ�ö��ֵ����"String��ExpandString��Binary��DWord��MultiString��QWord��Unknown"
      New-ItemProperty -Path "Registry::$($SysRegistryPolicy.$Name.reg)" -Name $SysRegistryPolicy.$Name.name -PropertyType $SysRegistryPolicy.$Name.regtype -Value $SysRegistryPolicy.$Name.value
    } elseif ( $Result -eq 0 ) {
      Set-ItemProperty -Path "Registry::$($SysRegistryPolicy.$Name.reg)" -Name $SysRegistryPolicy.$Name.name -Value $SysRegistryPolicy.$Name.value
    }
  }
}

$SensitiveFile = @("%systemroot%\system32\inetsrv\iisadmpwd")

Function F_SensitiveFile() {
  if (Test-Path -Path $SensitiveFile[$i]) {
    # 1.ɾ�������κ��ļ���չ�����ļ�
    Remove-Item C:\Test\*.* # == Del C:\Test\*.*
    Remove-Item -Path C:\Test\file.txt -Force 

    # 2.ɾ�������������ļ�����Ŀ¼
    Remove-Item -Path C:\temp\DeleteMe -Recurse # �ݹ�ɾ�����ļ����е��ļ�
    }
}



Write-Host "[-] ��ȫ�ӹ�������......" -ForegroundColor Green
F_SeceditReinforce
secedit /configure /db secconfig.sdb /cfg secconfig.cfg
F_SysRegistryReinforce
Write-Host "[-] ��ȫ�ӹ������......" -ForegroundColor Green