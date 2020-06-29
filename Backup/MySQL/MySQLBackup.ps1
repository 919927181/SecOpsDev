# ------------------------------- #
# Author:WeiyiGeek                #
# Ps ���ݿⱸ�� & Ӧ�ñ���           #
# Create: 2020��6��11�� 21:34:40  #
# ------------------------------- #    

$TIME=Get-Date
$TIME=$TIME.ToString('yyyy-MM-dd_HHmmss')
$BACKUP_DIR="F:\backup"
$MYSQL_DUMP="F:\backup\mysql-5.7.30-winx64\bin\mysqldump.exe"
$SECURE= "WeiyiGeek_test" | ConvertTo-SecureString -AsPlainText -Force
$CRED = New-Object System.Management.Automation.PSCredential("root",$SECURE) 
$BACKUP_FILENAME="bookstack_${TIME}.tar.gz"

$FLAG=Test-Path -Path "$BACKUP_DIR/SQL"
# ��֤�����ļ����Ƿ񴴽�
if (!$FLAG ){
  #New-Item -ItemType Directory -Path $BACKUP_DIR/ -Force
  mkdir "$BACKUP_DIR/SQL"
} 

$FLAG=Test-Path -Path "$BACKUP_DIR/APP"
if ( !$FLAG ){
  mkdir "$BACKUP_DIR/APP"
}

# MySQL���ݿⱸ������
function dumpMysql {
  param (
    [string] $APP_HOST="",
    [string] $APP_DBNAME="",
    [string] $APP_DBU="",
    [string] $APP_DBP="",
    [int] $APP_PORT=3306
  )

 if([String]::IsNullOrEmpty($APP_HOST) -or [String]::IsNullOrEmpty($APP_DBNAME) -or [String]::IsNullOrEmpty($APP_DBU) -or [String]::IsNullOrEmpty($APP_DBP)){
  Write-Host "# ���� $APP_DBNAME ���ݿ���� "  -ForegroundColor red
  [Environment]::Exit(127)
  } else {
  Write-Host "# ���ڱ��� $APP_DBNAME ���ݿ� "  -ForegroundColor Green
  Invoke-Expression "${MYSQL_DUMP} -h 10.20.172.1 -P $APP_PORT --default-character-set=UTF8 -u$APP_DBU -p$APP_DBP -B --databases $APP_DBNAME --hex-blob --result-file=$BACKUP_DIR/SQL/${APP_DBNAME}_${TIME}.sql"
 }
}

# ����MysqlDump����ִ������
dumpMysql -APP_HOST 10.20.12.1 -APP_PORT 3306 -APP_DBNAME "snipeit" -APP_DBU "snipeit" -APP_DBP "WeiyiGeek"
dumpMysql -APP_HOST 10.20.12.1 -APP_PORT 3366 -APP_DBNAME "bookstackapp" -APP_DBU "bookstack" -APP_DBP "WeiyiGeek"


# ��֤ ssh ģ���Ƿ����
if(Get-Module -ListAvailable -Name Posh-SSH){
  Write-Host "# Posh-SSH ģ���Ѱ�װ"  -ForegroundColor Green
}else{
  Write-Host "# Posh-SSH ģ��δ��װ,���ڰ�װ��ģ�飬ע����Ҫ����ԱȨ��!"  -ForegroundColor red
  Install-Module -Force Posh-SSH
}

# ִ�б���
New-SSHSession -ComputerName 10.20.72.1 -Credential $CRED -AcceptKey
Invoke-SSHCommand -SessionId 0 -Command "tar -zcf $BACKUP_FILENAME /app/bookstack/web/*"

# ִ�����ر���
New-SFTPSession -ComputerName 10.20.72.1 -Credential $CRED -AcceptKey
Get-SFTPFile -SessionId 0 -RemoteFile "$BACKUP_FILENAME" -LocalPath "$BACKUP_DIR/APP/"

if((Remove-SSHSession -SessionId 0) -and (Remove-SFTPSession -SessionId 0)){
  Write-Host "# �ѹر�SSH��SFTP����"  -ForegroundColor Green
}else{
  Write-Host "# �ر�����ʧ��"  -ForegroundColor red
}

# Write-Host "# ��������������ݿ�·��: $BACKUP_DIR\SQL"  -ForegroundColor Green
# Get-ChildItem F:\backup\SQL\*.sql 
# Write-Host "# �����������Ӧ�ñ���·��: $BACKUP_DIR\APP"  -ForegroundColor Green
# Get-ChildItem F:\backup\APP\*.tar.gz
exit
