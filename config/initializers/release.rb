PROIEL_RELEASE_FILE = Rails.root.join("RELEASE")

if File.exists?(PROIEL_RELEASE_FILE)
  PROIEL_RELEASE = File.read(PROIEL_RELEASE_FILE).strip
else
  PROIEL_RELEASE = nil
end
