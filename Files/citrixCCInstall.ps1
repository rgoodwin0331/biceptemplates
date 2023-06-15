Invoke-WebRequest -Uri "https://downloads.cloud.com/x1ojiluounsw/connector/cwcconnector.exe" -OutFile "c:\temp\cwcconnector.exe"

Invoke-WebRequest -Uri "https://raw.githubusercontent.com/rgoodwin0331/biceptemplates/main/Files/cloudConnect.json" -OutFile "c:\temp\cloudConnect.json"

c:\temp\cwcconnector.exe /q /ParametersFilePath:c:\temp\cloudConnect.json