echo "Installing version-locked swift-json-gen"
npm install --dev swift-json-gen@0.3

echo "Generating JSON..."

node node_modules/swift-json-gen/bin/swift-json-gen HoelangTotTrein2/json/
echo "Done!"
