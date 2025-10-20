@echo off
REM Script to set different GPS locations for testing Common Grounds global matching

echo Setting up test locations for Common Grounds Global Matching...

REM Check if emulators are running
echo Checking for running emulators...
adb devices

echo.
echo Setting locations for testing (within 50m proximity)...

REM Set location for first emulator (anywhere in the world)
echo Setting Emulator 1 to location (40.7128, -74.0060) - New York City...
adb -s emulator-5554 emu geo fix -74.0060 40.7128

REM Set nearby location for second emulator (within 50m)
echo Setting Emulator 2 to nearby location (40.7132, -74.0056) - 50m away...
adb -s emulator-5556 emu geo fix -74.0056 40.7132

echo.
echo Global matching locations set! Now run the app on both emulators:
echo Terminal 1: flutter run -d emulator-5554
echo Terminal 2: flutter run -d emulator-5556
echo.
echo Make sure both users have shared interests for matching to work!
echo The app now works anywhere in the world - no campus restrictions!
pause
