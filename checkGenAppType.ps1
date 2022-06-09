
try
{
    # Création du point d'entrée au registre HKU (s'il n'existe pas)
    if($false -eq (Test-Path HKU:\ ))
    {
        New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS | Out-Null
    }

    $results = ""

    # Récupération des répertoires enfants dans la ruche HKEY_USERS (Les users justement)       
    $hkuEntries = Get-ChildItem -Path HKU:\ |  Select-Object
   

    # on itère sur chaque user afin de recherche une entrée d'enregistrement d'URI Scheme pour iNot
    foreach($userEntry in $hkuEntries)
    {
        # $userEntry = $hkuEntries[3]
        $fullGenapiKeyPath = $userEntry.Name + "\Software\GenApi"
        $fullGenapiKeyPath = $fullGenapiKeyPath.Replace("HKEY_USERS", "HKU:")

        $fulliNotKeyPath = $fullGenapiKeyPath + "\iNot.client"

        if($true -eq (Test-Path $fulliNotKeyPath ))
        {
            try{
                $userName = ((New-Object System.Security.Principal.SecurityIdentifier ($userEntry.PSChildName)).Translate( [System.Security.Principal.NTAccount])).Value        
            }
            catch{
                $userName = "unknown_$userEntry"
            }

            $valueUrlPro    =  Get-ItemProperty -Path $fulliNotKeyPath -Name UrlProtocol -ErrorAction SilentlyContinue
            $valueUrlActe   =  $(Get-ItemProperty -Path $fulliNotKeyPath -Name BaseUrl -ErrorAction SilentlyContinue)
                if( ($valueUrlActe -ne $null) -or ($valueUrlActe.Length -gt 0) ) { $valueUrlActe = $valueUrlActe.BaseUrlInotActe}

            $valueUrlCompta =  $(Get-ItemProperty -Path $fullGenapiKeyPath -Name BaseUrlInotComptabilite -ErrorAction SilentlyContinue)
            if( ($valueUrlCompta -ne $null) -or ($valueUrlCompta.Length -gt 0) ) { $valueUrlCompta = $valueUrlCompta.BaseUrlInotComptabilite}

            if( ($valueUrlActe -eq $null) -or ($valueUrlActe.Length -eq 0) )
            {
               $valueUrlActe = ""
            } else { $valueUrlActe = ",Inot:$valueUrlActe" }

            if( ($valueUrlCompta -eq $null) -or ($valueUrlCompta.Length -eq 0) )
            {
               $valueUrlCompta = ""
            } else { $valueUrlCompta = ",Books:$valueUrlCompta" }


           if( ($valueUrlPro -ne $null) -or ($valueUrlPro.Length -gt 0) )
            {
                $urlProtocolValue = $valueUrlPro.UrlProtocol

                # si l'uri Scheme point vers un répertoire de l'app data, l'installation est en mode ClickOnce
                if($urlProtocolValue.Contains("AppData"))
                {
                    $results+= "$($userName):ClickOnce" + $valueUrlActe + $valueUrlCompta + ";"
                }
                else
                {
                    $results+= "$($userName):SAN" + $valueUrlActe + $valueUrlCompta + ";"
                }
            }# Fin If
       
        }# Fin If
    } # Fin ForEach

    if (![string]::IsNullOrEmpty($results)) {
        Write-Host  $results.TrimEnd(";")
        exit 1
    }
    else {
        Write-Host  "Aucune application SAN ou ClickOnce detecte dans les profils"
        exit 1
    }
   
}
catch
{
    Write-Host $_
    exit 0
}
