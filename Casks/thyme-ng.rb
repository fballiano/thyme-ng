cask "thyme-ng" do
  version "1.0.7"
  sha256 "cefb8a8e3276c0fc41f9d4552bf2e1c3cfd713c92c3e6c053003c73646482c42"

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
