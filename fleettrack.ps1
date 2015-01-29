    
    $dte = $dte.AddDays(-14)  #this is the number of days a player would have to be inactive (set neg value)
    $serverlogs = 'yoursaverootpath\MyMap'
    $ownedlogs = "yourlogspath\Admin Logs\Audits\Owned\"
    $nofleetlogs = "yourlogspath\Admin Logs\Audits\Owned\"

    $filePath = 'yoursavepath\SANDBOX_0_0_0_.sbs'
    $filePath2 = 'yoursavepath\SANDBOX.sbc'


    # edit the above values for to match your server!

    $regex = "\d{4}-\d{2}-\d{2}"
    $dte = Get-Date
    $dte = $dte.DayofYear
    $CurrentDateTime = Get-Date -Format "MM-dd-yyyy_HH-mm"
    $ownedfilename = "Owned_Audit_" +$CurrentDateTime+ ".log"
    $ownedpath = $ownedLogs + $ownedfilename
    $nofleetfilename = "Freelancer_ShipsAudit_" +$CurrentDateTime+ ".log"
    $nofleetpath = $nofleetLogs + $nofleetfilename
    
    Write-Host -ForegroundColor Green "Fleetcheck loading please wait ... "

    [xml]$myXML = Get-Content $filePath -Encoding UTF8
    $ns = New-Object System.Xml.XmlNamespaceManager($myXML.NameTable)
    $ns.AddNamespace("xsi", "http://www.w3.org/2001/XMLSchema-instance")

    [xml]$myXML2 = Get-Content $filePath2 -Encoding UTF8
    $ns2 = New-Object System.Xml.XmlNamespaceManager($myXML2.NameTable)
    $ns2.AddNamespace("xsi", "http://www.w3.org/2001/XMLSchema-instance")

    $nodePIDs = $myXML2.SelectNodes("//Identities"  , $ns2)
    $nodeFactions = $myXML2.SelectNodes("//Factions/Factions/MyObjectBuilder_Faction" , $ns2)
    $nodeClientID=$myXML2.SelectNodes("//AllPlayersData/dictionary" , $ns2)


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
            $nodeclient = $nodeClientID.SelectSingleNode("item/Value[IdentityId='$($node.IdentityId)']" , $ns2)
            $nodeplayer = $nodePIDs.SelectSingleNode("MyObjectBuilder_Identity[IdentityId='$($member.PlayerId)']" , $ns2)
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

            #list ships and stations owned non faction
    New-Item -path $nofleetpath -type file
    Add-Content -path $nofleetpath -Value "[$([DateTime]::Now)] FoH Space Engineers Owned Ships by Freelancer  ==================="
    $nodes = $myXML.SelectNodes("//SectorObjects/MyObjectBuilder_EntityBase[IsStatic='false' and (@xsi:type='MyObjectBuilder_CubeGrid')]"  , $ns)
    $flstations = $myXML.SelectNodes("//SectorObjects/MyObjectBuilder_EntityBase[IsStatic='true' and (@xsi:type='MyObjectBuilder_CubeGrid')]"  , $ns)
    ForEach($freelancePID in $nodefreelancePIDS){
        $ownercheck = $myXML.SelectNodes("//SectorObjects/MyObjectBuilder_EntityBase[IsStatic='false' and (@xsi:type='MyObjectBuilder_CubeGrid')]/CubeBlocks/MyObjectBuilder_CubeBlock[Owner='$($freelancePID.IdentityId)' and (@xsi:type='MyObjectBuilder_Beacon')]"  , $ns).count
        $Freelancers = $nodeFactions.SelectNodes("Members/MyObjectBuilder_FactionMember[PlayerId='$($freelancePID.IdentityId)']" , $ns2)
            If($Freelancers.count -eq 0 -and $ownercheck -ne 0){
                $factshipcount = 0
                $factcapcount = 0
                $nodeclient = $nodeClientID.SelectSingleNode("item/Value[IdentityId='$($freelancePID.IdentityId)']" , $ns2)
                $nodeplayer = $nodePIDs.SelectSingleNode("MyObjectBuilder_Identity[IdentityId='$($freelancePID.IdentityId)']" , $ns2)
                $membershipcount = 0
                Add-Content -path $nofleetpath -Value "[  ]"
                Add-Content -path $nofleetpath -Value "[$($nodeplayer.DisplayName)] owns the following ships:"
                ForEach($node in $nodes){
                    $ownerbeacons = $node.SelectNodes("CubeBlocks/MyObjectBuilder_CubeBlock[(@xsi:type='MyObjectBuilder_Beacon')]", $ns)
                    IF($ownerbeacons.count -gt 0){
                        $ownerbeacon=$ownerbeacons | Get-Random
                        IF ($freelancePID.IdentityId -eq $ownerbeacon.Owner -and $ownerbeacon.CustomName -ne "Capital Core"){
                            Add-Content -path $nofleetpath -Value "="
                            Add-Content -path $nofleetpath -Value "$($node.DisplayName) Coords: $($node.PositionAndOrientation.position | Select X) , $($node.PositionAndOrientation.position | Select Y) , $($node.PositionAndOrientation.position | Select Z)"
                            $factshipcount = $factshipcount + 1
                            $membershipcount = $membershipcount + 1
                        }

                        IF ($freelancePID.IdentityId -eq $ownerbeacon.Owner -and $ownerbeacon.CustomName -eq "Capital Core"){
                            Add-Content -path $nofleetpath -Value "="
                            Add-Content -path $nofleetpath -Value "$($node.DisplayName) |CAPSHIP| Coords: $($node.PositionAndOrientation.position | Select X) , $($node.PositionAndOrientation.position | Select Y) , $($node.PositionAndOrientation.position | Select Z)"
                            $factcapcount = $factcapcount + 1
                            $membershipcount = $membershipcount + 1
                        }
                    }
                }
                $factstationcount = 0
                Add-Content -path $nofleetpath -Value "[  ]"
                Add-Content -path $nofleetpath -Value "[$($nodeplayer.DisplayName)] owns the following stations:"
                ForEach($station in $flstations){
                    $ownerbeacons = $station.SelectNodes("CubeBlocks/MyObjectBuilder_CubeBlock[(@xsi:type='MyObjectBuilder_Beacon')]", $ns)
                    IF($ownerbeacons.count -gt 0){
                        $ownerbeacon=$ownerbeacons | Get-Random
                        IF ($freelancePID.IdentityId -eq $ownerbeacon.Owner){
                            Add-Content -path $nofleetpath -Value "="
                            Add-Content -path $nofleetpath -Value "$($node.DisplayName) Coords: $($node.PositionAndOrientation.position | Select X) , $($node.PositionAndOrientation.position | Select Y) , $($node.PositionAndOrientation.position | Select Z)"
                            $factstationcount = $factstationcount + 1
                            $membershipcount = $membershipcount + 1
                        }

                        
                    }
                }
                Add-Content -path $nofleetpath -Value "[$membershipcount] Total owned grids."
                Add-Content -path $nofleetpath -Value "====="
                Add-Content -path $nofleetpath -Value "[$($freelancePID.DisplayName)] Freelancer Summary"
                Add-Content -path $nofleetpath -Value "Ships Detected for [$($freelancePID.DisplayName)] : $factshipcount"
                Add-Content -path $nofleetpath -Value "Capital Ships Detected for [$($freelancePID.DisplayName)] : $factcapcount"
                Add-Content -path $nofleetpath -Value "Stations Detected for [$($freelancePID.DisplayName)] : $factionstationcount"

                Add-Content -path $nofleetpath -Value " "
                Add-Content -path $nofleetpath -Value " "
            }
    }


    $myXML2.Save($filePath2)