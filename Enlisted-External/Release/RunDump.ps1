Set-Location "C:\Users\fff92\Desktop\GameCheats\Enlisted-External\Release"
dotnet "Enlisted External.dll" --dump 2>&1 | Out-File -FilePath "dump_output.txt" -Encoding utf8
Write-Host "Done! Check dump_output.txt"
