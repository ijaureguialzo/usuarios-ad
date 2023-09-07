<#
Para atrapar posibles errores se pueden utilizar dos parámetros: ErrorAction y ErrorVariable.
ErrorAction determina que debe ocurrir cuando el error ocurre. Aberviatura ea. Posibles valores:
	SilentlyContinue
	Stop
	Continue
	Inquire
 ErrorVariable es un variable de tipo ARRAYLIST que mantiene toda la información sobre el error.
#>
$errorActionPreference="SilentlyContinue"
clear-host
#Comprobar si tengo el modulo de activeDirectory
#y si no esta importarlo
$modulo=Get-Module
if ($modulo.name -notcontains "ActiveDirectory")
	{
	Write-Host -ForegroundColor Yellow "Importando el modulo"
	Import-Module ActiveDirectory
	}
#Obtener el nombre del dominio
$d=Get-ADDomain
if($d.DistinguishedName -eq $Null)
{
"No existe Directorio donde crear el usuario"
}
else
{$raiz=$d.DnsRoot
 Write-Host -ForegroundColor Magenta "Bienvenido el dominio $raiz `n"

[string]$codGrp = read-host "Introduzca el codgrupo"
[string]$codMod = read-host "Introduzca letras modulo"
[string]$cantUsu = read-host "Introduzca cantidad de usuarios" 
if(($codGrp.length -eq 0) -or  ($codMod.length -eq 0))
{Write-Host -ForegroundColor Red "`n Debes introducir valores. Vuelve a ejecutar"
start-Sleep -second 3
}
else
{
$nomOU=$codGrp+$codMod
$nomGrp=$codGrp+$codMod
$nomAD=$d.DistinguishedName
$pathRaiz="OU=Usuarios," + $nomAD
$pathRaizExa="OU=UsuariosExamen," + $nomAD
"Creando OU $nomOU en  $nomAD ..."
New-ADOrganizationalUnit -Name $nomOU -Path $pathRaiz  -Server $d.DnsRoot -ErrorAction SilentlyContinue -ErrorVariable crearErr
New-ADOrganizationalUnit -Name $nomOU -Path $pathRaizExa  -Server $d.DnsRoot -ErrorAction SilentlyContinue -ErrorVariable crearErr
if ($crearErr[0].message -ne $null)
	{
    Write-Host -ForegroundColor Red " `n ... Error al crear OU $nomOU. Mira si ya existe."
}
else{
$pathOU="OU=" + $nomOU + "," + $pathRaiz
$pathOUExa="OU=" + $nomOU + "," + $pathRaizExa
if ((Get-ADGroup -Filter 'anr -like "$nomGrp*"' -Server $d.DnsRoot|measure-object).count -ne 0)
{
 Write-Host -ForegroundColor Red "el grupo $nomGrp existe"
  }
else
{
$nomUsu=$codGrp+$codMod
#Miro si hay usuarios creados con ese patron
if ((Get-ADUser -Filter 'anr -like "$nomUsu*"' -Server $d.DnsRoot|measure-object).count -ne 0)
{ 
Write-Host -ForegroundColor Red "`n el usuario $nomUsu existe" 
}
else
{
"Creando grupo $nomGrp..."
New-ADGroup -Name $nomGrp -GroupScope Global -Path $pathOU
$i=1
do
{
#Crear el usuario
$nomAD=$d.DistinguishedName
$nomUsu=$codGrp+$codMod+$i.ToString("00")
$nomUsuExa1=$codGrp+$codMod+"exa"+$i.ToString("00")
$nomUsuExa2=$codGrp+$codMod+"exa"+($i+12).ToString("00")
New-ADUser -name $nomUsu `
-AccountPassword (ConvertTo-SecureString "12345Abcde" -AsPlainText -Force) `
-ChangePasswordAtLogon $false `
-Enabled $true `
-SamAccountName $nomUsu `
-Path $pathOU `
-ErrorAction SilentlyContinue -ErrorVariable crearErr
if ($crearErr[0].message -eq $null)
{
        Add-ADGroupMember $nomGrp $nomUsu ;
        New-ADUser -name $nomUsuExa1 `
            -AccountPassword (ConvertTo-SecureString "12345Abcde" -AsPlainText -Force) `
            -ChangePasswordAtLogon $false `
            -Enabled $true `
            -SamAccountName $nomUsuExa1 `
            -Path $pathOUExa `
            -ErrorAction SilentlyContinue -ErrorVariable crearErr

New-ADUser -name $nomUsuExa2 `
-AccountPassword (ConvertTo-SecureString "12345Abcde" -AsPlainText -Force) `
-ChangePasswordAtLogon $false `
-Enabled $true `
-SamAccountName $nomUsuExa2 `
-Path $pathOUExa `
-ErrorAction SilentlyContinue -ErrorVariable crearErr

        } #fin tipo usuario
else
{
Write-Host -ForegroundColor Red "Error al crear el usuario $nomUsu"
}

$i=$i+1
} until ( $i -gt $cantUsu)
Write-Host -ForegroundColor Green "`n `n Proceso finalizado"
}#fin error usuarios
}#fin error grupo
} #fin error OU
} #fin de la comprobacion de existencia de valor envariables
} #fin comprobaci�n existencia DA
