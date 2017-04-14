# iosOTAGenerator
Native tool for generating html and manifest.plist for ios OTA distribution  
Moves ipa to ipa named directory and creates there manifest.plist and index.html due to [stackoverflow guide](http://stackoverflow.com/questions/23561370/download-and-install-an-ipa-from-url-on-ios)

Configurating with property list must contains:
1. bundleId  
2. version  
3. webUrl  
4. appName  
  
Demo config file in repo named: build-config.plist  
  
#### Usage:  
iosOTAGenerator -config absolutePathToConfigPlist -ipaPath absolutePathToIpaPath
