cask "thyme-ng" do
  version "1.0.4"
  sha256 "d50ebfc1da1a74d1f7a9daa70bb0e847b5515d8db23e0ca4e08f93af4b62d7f2"

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
