# DP Setup
#6-10-22

#CSV of devices format has this as the first line then device names on supsequent lines, Quotes and commas are optional after the initial "header" line
#"Device",
#
#
Function Setup-DistributionPoints{
    param(
    [String][Parameter(Mandatory=$true, Position=1)] $csvPath
    )

    #These variables need to be set once for your environment
    $certPath = "\\Server\drive$\path\to\cert.pfx"
    $domain = "site.example"
    $siteCode = "SCM1"
    $password = "certPass01"
    $logPath = "C:\temp\Setup-DistributionPoints.log"
    $dpGroupName = "Pull Distribution Points"
    #alternatively $dpGroupID = "{########-####-####-####-###########}"

    Import-Csv -Path $csvPath | ForEach-Object{
    
        try{$Device = Get-CMDevice -Name $_.Device -fast } 
        catch {
            $path = $logPath
            Write-Host "$_Device not in SCCM"
            New-PSDrive -Name Z -PSProvider filesystem -Root $path
            $Device.Name | out-file -FilePath "Z:\DistributionPoints.log" -Append  -Force
            Remove-PSDrive -Name Z -PSProvider filesystem
            return
         }
         
        #Give device site system role.
        $FQDN = $Device.name + $domain
        try{New-CMSiteSystemServer -SiteSystemServerName $FQDN -SiteCode $siteCode -AccountName $null}
        catch{
            write-host "system is already a site server"
        }

        #Ensure NO_SMS_ON_DRIVE.SMS exists on E or C drives
        #Set to drives of your preference
        $Drives = @("\C$","\E$")
        Foreach($Drive in $Drives){
            $path ="\\"+ $Device.Name + $Drive
            try{New-PSDrive -Name Z -PSProvider filesystem -Root $path -ErrorAction Stop}
            catch{
                $path = $logPath
                Write-Host "Could not connect to $path"
                New-PSDrive -Name Z -PSProvider filesystem -Root $path
                $Device.Name | out-file -FilePath "Z:\DistributionPoints.log" -Append  -Force
                Remove-PSDrive -Name Z -PSProvider filesystem
                return
            }
            if(-not (test-path Z:\NO_SMS_ON_DRIVE.SMS)){
                new-item -ItemType file -Path Z:\ -Name NO_SMS_ON_DRIVE.SMS -Force
            }
            Remove-PSDrive -Name Z -PSProvider filesystem
        } 

        #Give Device DP role with settings
        $Schedule = New-CMSchedule  -DayOfWeek Sunday -Start "1/1/2023 12:00 AM" -RecurCount 1 
        $SiteSystemServer = Get-CMSiteSystemServer -SiteSystemServerName $FQDN
        $Password = ConvertTo-SecureString $password -AsPlainText -Force
        try{$AddDP = Add-CMDistributionPoint -InputObject $SiteSystemServer -Description $_.Description -InstallInternetServer -EnableBranchCache`
        -EnablePxe -EnableUnknownComputerSupport -PxePassword $Password -EnableContentValidation -ContentValidationSchedule  $Schedule `
        -ClientConnectionType Intranet -CertificatePath $certPath -CertificatePassword $Password -Force -ErrorAction stop
        | Set-CMDistributionPoint -ClientCommunicationType Https -AddBoundaryGroupName $_.Description -ErrorAction Stop} 
        catch{
            write-host "system already has DP role"
        }
    
        #Continue to adding pull role
        #enter FQDNs of your "source" distribution points the pull DP will get content from 
        $SourceDPs = @("SCCMDP01@domain.com","SCCMDP02@domain.com","SCCMDP03@domain.com")
        #randomize priority of source DPs for balancing...
        $Priority = @(1,2,3) 
        $Priority = $Priority | Sort-Object {Get-Random}

        #Not adding to DP groups until conversion
        #Add Pull DP group by name
        Add-CMDistributionPointToGroup -DistributionPointGroupName $dpGroupName -DistributionPointName $FQDN
        #Add group by group ID (you can add new DP to multiple groups in one pass.
        #Add-CMDistributionPointToGroup -DistributionPointGroupID $dpGroupID -DistributionPointName $FQDN

        $DP = Get-CMDistributionPoint -SiteSystemServerName $FQDN
        Set-CMDistributionPoint -inputObject $DP -EnablePullDP $true -SourceDistributionPoint $SourceDPs -SourceDPRank $Priority 
    }
}

Setup-DistributionPoints -csvPath "C:\temp\DpList.csv"

