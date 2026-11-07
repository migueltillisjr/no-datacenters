## File Editing Rules

When using the edit tool:

1. Never retry the same failed edit repeatedly.
2. If `oldString` matches multiple locations, read the surrounding lines and include enough neighboring content to make the match unique.
3. Do not use `replaceAll=true` unless every occurrence should intentionally be changed.
4. If an exact edit fails twice, use a shell command or script for a targeted modification instead.
5. After editing, read or grep the relevant section to verify the change actually occurred.
6. Never claim a file was updated unless the tool confirms the edit succeeded.
