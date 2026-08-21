cask "thyme-ng" do
  version "1.0.6"
  sha256 "054be9c797e35b433654368a45448674c511af66c25bb217296cc6bf9f1d1e1a"

  url "https://github.com/fballiano/thyme-ng/releases/download/v#{version}/thyme-ng-#{version}.dmg"
  name "thyme-ng"
  desc "Menu bar stopwatch"
  homepage "https://github.com/fballiano/thyme-ng"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: :sequoia

  app "thyme-ng.app"

  zap trash: [
    "~/Library/Application Support/thyme-ng",
    "~/Library/Caches/com.fabrizioballiano.thyme-ng",
    "~/Library/HTTPStorages/com.fabrizioballiano.thyme-ng",
    "~/Library/Preferences/com.fabrizioballiano.thyme-ng.plist",
  ]
end
