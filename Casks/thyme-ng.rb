cask "thyme-ng" do
  version "1.0.9"
  sha256 "0cbb533c3a1f72e145a162b0292a42f42532a6a76ea7cd45620aea56257c1e75"

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
