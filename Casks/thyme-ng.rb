cask "thyme-ng" do
  version "1.0.5"
  sha256 "a1b332d2e80072726cc5f51eed9a03add76904dfb972472e1c8a7651b1bc70f0"

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
