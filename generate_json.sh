echo "Installing version-locked swift-json-gen"
npm install --prefix . --only=dev swift-json-gen@1.0

echo "Generating JSON..."

node node_modules/swift-json-gen/bin/swift-json-gen HoelangTotTrein2/json/
echo "Done!"
