    
    $dte = $dte.AddDays(-14)  #this is the number of days a player would have to be inactive (set neg value)
    $serverlogs = 'yoursaverootpath\MyMap'
    $ownedlogs = "yourlogspath\Admin Logs\Audits\Owned\"

    $filePath = 'yoursavepath\SANDBOX_0_0_0_.sbs'
    $filePath2 = 'yoursavepath\SANDBOX.sbc'

    # edit the above values for to match your server!

    $regex = "\d{4}-\d{2}-\d{2}"
    $dte = Get-Date
    $dte = $dte.DayofYear
    $CurrentDateTime = Get-Date -Format "MM-dd-yyyy_HH-mm"
    $ownedfilename = "Owned_Audit_" +$CurrentDateTime+ ".log"
    $ownedpath = $ownedLogs + $ownedfilename
    
    Write-Host -ForegroundColor Green "Fleetcheck loading please wait ... "

    [xml]$myXML = Get-Content $filePath
    $ns = New-Object System.Xml.XmlNamespaceManager($myXML.NameTable)
    $ns.AddNamespace("xsi", "http://www.w3.org/2001/XMLSchema-instance")

    [xml]$myXML2 = Get-Content $filePath2
    $ns2 = New-Object System.Xml.XmlNamespaceManager($myXML2.NameTable)
    $ns2.AddNamespace("xsi", "http://www.w3.org/2001/XMLSchema-instance")

    $nodePIDs = $myXML2.SelectNodes("//Identities"  , $ns2)
    $nodeFactions = $myXML2.SelectNodes("//Factions/Factions/MyObjectBuilder_Faction" , $ns2)
    $nodeClientID=$myXML2.SelectNodes("//ConnectedPlayers/dictionary/item | //DisconnectedPlayers/dictionary" , $ns2)


        #list ships owned
    New-Item -path $ownedpath -type file
    Add-Content -path $ownedpath -Value "[$([DateTime]::Now)] Space Engineers Owned Ships by Faction  ==================="
    $nodes = $myXML.SelectNodes("//SectorObjects/MyObjectBuilder_EntityBase[IsStatic='false' and (@xsi:type='MyObjectBuilder_CubeGrid')]"  , $ns)
    ForEach($faction in $nodeFactions){
        $inactivemembers = 0
        $factshipcount = 0
        $factionmembers = $faction.SelectNodes("Members/MyObjectBuilder_FactionMember")
        Add-Content -path $ownedpath -Value "=="
        Add-Content -path $ownedpath -Value "[$($faction.Name)] [$($faction.Tag)] Members and ships owned:"
        ForEach($member in $factionmembers){
            $nodeclient = $nodeClientID.SelectSingleNode("item[Value='$($member.PlayerId)']" , $ns2)
            $nodeplayer = $nodePIDs.SelectSingleNode("MyObjectBuilder_Identity[PlayerId='$($member.PlayerId)']" , $ns2)
            $findlogin = dir $serverlogs -Include *.log -Recurse | Select-String -Pattern "Peer2Peer_SessionRequest $($nodeclient.ClientId)"
            #check if member is active 
                    $matchInfos = @(Select-String -Pattern $regex -AllMatches -InputObject [$($findlogin[-1])])
                        foreach ($minfo in $matchInfos){
                            foreach ($match in @($minfo.Matches | Foreach {$_.Groups[0].value})){
                                if ([datetime]::parseexact($match, "yyyy-MM-dd", $null).DayOfYear -lt $dte){
                                   $inactivemembers = $inactivemembers + 1
                                }
                            }
                        }
            #end member active check
            Add-Content -path $ownedpath -Value "[  ]"
            Add-Content -path $ownedpath -Value "[$($nodeplayer.DisplayName)] owns the following ships:"
            ForEach($node in $nodes){
                $ownerbeacons = $node.SelectNodes("CubeBlocks/MyObjectBuilder_CubeBlock[(@xsi:type='MyObjectBuilder_Beacon')]", $ns)
                IF($ownerbeacons.count -gt 0){
                    $ownerbeacon=$ownerbeacons | Get-Random
                    IF ($member.PlayerId -eq $ownerbeacon.Owner -and $ownerbeacon.CustomName){
                        Add-Content -path $ownedpath -Value "="
                        Add-Content -path $ownedpath -Value "$($node.DisplayName) Coords: $($node.PositionAndOrientation.position | Select X) , $($node.PositionAndOrientation.position | Select Y) , $($node.PositionAndOrientation.position | Select Z)"
                        $factshipcount = $factshipcount + 1
                    }
                }
            }
        }
        $active = $factionmembers.count - $inactivemembers
        Add-Content -path $ownedpath -Value "====="
        Add-Content -path $ownedpath -Value "[$($faction.Tag)] Faction Summary"
        Add-Content -path $ownedpath -Value "Ships Detected for [$($faction.Tag)] : $factshipcount"
        Add-Content -path $ownedpath -Value "Active Members : $active"
        IF($active -le 2){$fleetlicense = 'Fleet License: Association'}
        IF($active -ge 3){$fleetlicense = 'Fleet License: Corporation'}
        IF($active -ge 5){$fleetlicense = 'Fleet License: Trade Federation'}
        IF($active -ge 8){$fleetlicense = 'Fleet License: Militant Coalition'}
        Add-Content -path $ownedpath -Value "$fleetlicense"
        #$faction.description = $fleetlicense   #uncomment this if you would like an in game visual for your factions so they know where they stand. (changes public info field in factions)
        Add-Content -path $ownedpath -Value " "
        Add-Content -path $ownedpath -Value " "

    }

    $myXML2.Save($filePath2)