#!/usr/bin/env bash
set -e

: ${WIN2012_KEY:?"Must provide a product key for Windows 2012 Server R2"}

if [[ "$(which openssl)" = "" ]]
then
  echo "Must have openssl on PATH for sha1 checks."
  exit -1
fi

if [[ "$(which packer)" = "" ]]
then
  echo "Must have packer on PATH for building vagrant box."
  exit -1
fi

if [[ ! "$(packer version | sed -n '1p')" = "Packer v0.7.5" ]]
then
  echo "Only known to work with packer version 0.7.5"
  exit -1
fi


if [[ ! -f iso/windows/en_windows_server_2012_r2_with_update_x64_dvd_6052708.iso ]];
then
  echo "Windows 2012 ISO doesn't exist in iso/windows. Please copy it in there if you haven't done so. Thank you!"
  echo "Try https://msdn.microsoft.com/subscriptions/json/GetDownloadRequest?brand=MSDN&locale=en-us&fileId=62611&activexDisabled=true&akamaiDL=false"
  echo "Thanks, bye!"
  exit -1
fi


echo "Verifying Windows 2012 ISO..."
if [[ ! "$(openssl sha1 iso/windows/en_windows_server_2012_r2_with_update_x64_dvd_6052708.iso  | awk '{print $2}')" = "865494e969704be1c4496d8614314361d025775e" ]]
then
  echo "Unexpected sha1 for Windows 2012 ISO. Check that you put it in iso/windows and that it is the correct version."
  echo "Try https://msdn.microsoft.com/subscriptions/json/GetDownloadRequest?brand=MSDN&locale=en-us&fileId=62611&activexDisabled=true&akamaiDL=false"
  echo "Thanks!"
  exit -1
fi

if [[ ! -f iso/en_visual_studio_ultimate_2013_with_update_4_x86_dvd_5935075.iso ]];
then
  echo "Visual Studio ISO doesn't exist in iso. Please copy it in there if you haven't done so."
  echo "Try https://msdn.microsoft.com/subscriptions/json/GetDownloadRequest?brand=MSDN&locale=en-us&fileId=61638&activexDisabled=true&akamaiDL=false"
  echo "Cya!!"
  exit -1
fi


echo "Verifying Visual Studio ISO..."
if [[ ! "$(openssl sha1 iso/en_visual_studio_ultimate_2013_with_update_4_x86_dvd_5935075.iso  | awk '{print $2}')" = "62c2f1500924e7b1402b6fcb9350ae9e0af444f9" ]]
then
  echo "Unexpected sha1 for Visual Studio ISO. Check that you put it in iso and that it is the correct version. Thanks!"
  echo "Try https://msdn.microsoft.com/subscriptions/json/GetDownloadRequest?brand=MSDN&locale=en-us&fileId=61638&activexDisabled=true&akamaiDL=false"
  echo "Have a wonderful day!!!1!"
  exit -1
fi

git co answer_files/2012_r2/
echo "Cleaning up Resharper artifacts..."
rm -f iso/other/ReSharper.exe
mkdir -p iso/other
echo "Downloading Resharper..."
[ -f iso/other/ReSharper.exe ] || curl -L -o "iso/other/ReSharper.exe" -C - "https://download.jetbrains.com/resharper/JetBrains.ReSharperUltimate.2015.1.1.exe"

echo "Verifying Resharper..."
if [[ ! "$(openssl sha1 iso/other/ReSharper.exe | awk '{print $2}')" = "e67cad599af5479072d052b59086ded854eb404e" ]]
then
  echo "Unexpected sha1 for Resharper. Check that it correctly downloaded and the link in this script isn't stale."
  exit -1
fi

echo "Splicing in key..."
sed -i.bak -e 's/WIN2012_KEY/'$WIN2012_KEY'/' answer_files/2012_r2/Autounattend.xml
echo "Starting packer..."
packer build --only=virtualbox-iso windows_2012_r2.json
