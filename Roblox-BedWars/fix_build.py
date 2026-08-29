import re

with open("build.py", "r") as f:
    content = f.read()

# Fix the broken line
old = '    script.append("    local Library = createUI(bw, flags, api)\n    local ui = Library:New({Title="BedWars", Sub="v5.1"})")'
new = '    script.append("    local Library = createUI(bw, flags, api)")\n    script.append("    local ui = Library:New({Title=\'BedWars\', Sub=\'v5.1\'})")'

content = content.replace(old, new)

with open("build.py", "w") as f:
    f.write(content)

print("Fixed!")
