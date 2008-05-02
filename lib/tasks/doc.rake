desc "Update all documentation"
task(:doc => ["doc:diagrams", "doc:app"])
