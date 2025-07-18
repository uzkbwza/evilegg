@echo off
echo Deleting all Syncthing conflict files...

:: Looks for files with "sync-conflict" in the name
for /R %%f in (*sync-conflict*.*) do (
    echo Deleting: "%%f"
    del "%%f"
)

echo Done.
pause
