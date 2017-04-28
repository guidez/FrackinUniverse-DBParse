#Change this to your FU mod directory
$fuPath = "F:\Steam\steamapps\common\Starbound\mods\FrackinUniverse"

#Change this to the path value you want to filter on
$filterValue = "/builderConfig/0/elementalType/-"

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
#endregion

$getFiles = Read-Host "Get patch files? Type Yes or No"

while("yes","no" -notcontains $getFiles)
{
	$getFiles = Read-Host "Get patch files? Type Yes or No"
}

if ($getFiles -like "yes"){
    Write-Host "Getting Patch files..."
    $allPatchFiles = Get-ChildItem -Path $fuPath\* -recurse -Include *.activeitem.patch | Where-Object { $_.Attributes -ne "Directory"}
}

#Da Magic
$count = 0
Write-Host "Parsing Patch files"
foreach ($file in $allPatchFiles){

    $cleanedFile = CleanOutComments $file

    $fileJSON = $cleanedFile | ConvertFrom-Json

    foreach ($changeThingy in $fileJSON[0]){

        if($changeThingy.path -like $filterValue){
            Write-Host "$($file.name) doesn't have $filterValue"
            break
        }

    }

}
