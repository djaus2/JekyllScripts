# Purpose: Delete the contents of a web container in Azure Blob Storage
$env:AZCOPY_CONCURRENCY_VALUE = "AUTO";
$env:AZCOPY_CRED_TYPE = "AZCLI";
./azcopy.exe remove "https://djzblogaccname137.blob.core.windows.net/$web/?sv=2023-01-03&se=2024-07-07T11%3A53%3A00Z&sr=c&sp=rdl&sig=ONm4yNSlHmP3mi3r7L3l5F5QeUOcH%2B0brSjBHMztzoI%3D" --from-to=BlobTrash --list-of-files "C:\Users\david\AppData\Local\Temp\stg-exp-azcopy-5fcd22af-29db-4535-8479-66ee35d1c21f.txt" --recursive --log-level=INFO;
$env:AZCOPY_CONCURRENCY_VALUE = "";
$env:AZCOPY_CRED_TYPE = "";