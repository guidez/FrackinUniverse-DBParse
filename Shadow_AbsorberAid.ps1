#Change this to your FU mod directory
$fuPath = "F:\Steam\steamapps\common\Starbound\mods\FrackinUniverse"

#region Functions have to go first... Sigh Powershell
function CleanOutComments ($tmpFile){

    $starterJSON = "[`n";
    $reader = [System.IO.File]::OpenText($tmpFile.FullName)
    try {
        for() {
            $line = $reader.ReadLine()
            if ($line -eq $null) { break }
            $starterJSON += "  " + $line + "`n"
        }
    }
    finally {
        $reader.Close()
    }

    $starterJSON += "`n]"

    $blockRegex = "/\*[^*]*\*+(?:[^*/][^*]*\*+)*/";
    $lineRegex = "(/\*([^*]|[\r\n]|(\*+([^*/]|[\r\n])))*\*+/)|(//.*)"

    $starterJSON = $starterJSON -replace $blockRegex;
    $starterJSON = $starterJSON -replace $lineRegex;

    $starterJSON

}

function ArrayOutString($tmpArray){

    $returnString = "null"

    foreach($thing in $tmpArray){
        if ($returnString -eq "null"){
            $returnString = "$thing"
        }
        else{
            $returnString = $returnString + " | $thing"
        }
        
    }

    $returnString
}

#endregion

$getFiles = Read-Host "Get patch files? Type Yes or No"

while("yes","no" -notcontains $getFiles)
{
	$getFiles = Read-Host "Get patch files? Type Yes or No"
}

$fuObjectProperties = [ordered]@{
                        'fileName'=""
                        'data'=@()
                        }

$parsedData = @()

if ($getFiles -like "yes"){
    Write-Host "Getting Patch files..."
    $allPatchFiles = Get-ChildItem -Path $fuPath\* -recurse -Include *.activeitem.patch | Where-Object { $_.Attributes -ne "Directory"}
}

#Da Magic
$count = 0
Write-Host "Parsing Patch files"
foreach ($file in $allPatchFiles){

    $fuDataItem = New-Object -TypeName PSObject –Prop $fuObjectProperties

    $cleanedFile = CleanOutComments $file

    $fileJSON = $cleanedFile | ConvertFrom-Json

    $fuDataItem.fileName = $file.Name
    $fuDataItem.data = @($fileJSON)

    $parsedData += $fuDataItem

}

$consolidatedInfo = foreach ($item in $parsedData){


    foreach ($changeThingy in $item.data[0]){
        if($changeThingy.path -like "/builderConfig/0/elementalType/-"){
            Write-Host "Oh no! $($item.fileName) doesn't have any elemental type!"
            break
        }
    }


}