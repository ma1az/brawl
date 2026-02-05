import re
import os
import sys

def parse_binds(bind_file):
    bound_commands = set()
    # Matches: bindKey(..., "commandName", ...)
    # The command name is usually the 3rd argument for server or client, but key and state come before.
    # bindKey ( player thePlayer, string key, string keyState, string commandName
    # bindKey ( string key, string keyState, string commandName
    # We'll just look for quoted strings after at least 2 commas as a heuristic, or any quoted string that matches a known command later.
    # Actually, simplistic regex might be: bindKey\s*\(.*,.*,["']([^"']+)["']
    
    # Let's try to be a bit more robust:
    # bindKey(player, "k", "down", "lock") -> matches "lock"
    # bindKey("m", "down", "showcursor") -> matches "showcursor"
    pattern = re.compile(r'bindKey\s*\([^,]+,[^,]+,\s*(?:[^,]+,\s*)?[\'"](?P<cmd>[^\'"]+)[\'"]')
    
    try:
        with open(bind_file, 'r', encoding='utf-16', errors='ignore') as f:
            for line in f:
                line = line.strip()
                if not line: continue
                # Simple extraction of all quoted strings in bindKey calls might be safer if the arg position varies
                # But let's try the pattern first.
                match = pattern.search(line)
                if match:
                    bound_commands.add(match.group('cmd'))
    except FileNotFoundError:
        print(f"Warning: {bind_file} not found. No binds filtered.")
    
    return bound_commands

def generate_commands_md(input_file, bind_file, output_file):
    commands_by_resource = {}
    commands_map = {} # (resource, function) -> list of aliases
    
    # Regex to capture resource, command, and function
    # Line: full/path/s_c.lua:addCommandHandler("cmd", func, ...)
    pattern = re.compile(r'^(?:.*\\)?(?:resources\\)?(?P<resource>[^\\]+)\\.*:.*addCommandHandler\s*\(\s*[\'"](?P<command>[^\'"]+)[\'"]\s*,\s*(?P<function>[^,\)\s]+)')
    
    bound_commands = parse_binds(bind_file)
    print(f"Found {len(bound_commands)} bound commands to exclude.")

    try:
        with open(input_file, 'r', encoding='utf-16', errors='ignore') as f:
            for line in f:
                line = line.strip()
                if not line: continue
                match = pattern.search(line)
                if match:
                    resource = match.group('resource')
                    command = match.group('command')
                    func = match.group('function')
                    
                    if command in bound_commands:
                        continue

                    # Filter out commented commands
                    # Check if '--' appears before 'addCommandHandler' in the line
                    # Heuristic: find indices of both.
                    ach_index = line.find("addCommandHandler")
                    comment_index = line.find("--")
                    
                    if comment_index != -1 and comment_index < ach_index:
                        # Ensure the -- isn't part of the filename (unlikely but possible)
                        # The regex matched 'resource', so we are likely past the filename part in the match?
                        # No, 'line' is the full line.
                        # Let's trust that resources don't have -- in their paths usually.
                        # Matches: path/file.lua:--addCommandHandler -> comment < ach : True -> Skip
                        # Matches: path/file.lua:addCommandHandler... -- comment -> comment > ach : False -> Keep
                        continue

                    key = (resource, func)
                    if key not in commands_map:
                        commands_map[key] = []
                    commands_map[key].append(command)

    except FileNotFoundError:
        print(f"Error: {input_file} not found.")
        return

    # Process deduplication
    final_commands = {} # resource -> list of display strings
    

    # Define Categories
    categories = {
        "Admin & Management": ["admin", "report", "duty", "logs", "monitor", "serial", "bans", "anticheat", "integration"],
        "Vehicles": ["vehicle", "carshop", "tow-system", "fuel", "garage", "handling"],
        "Factions & Jobs": ["faction", "pd-system", "mdc", "job-system", "prison", "sapt", "sfia", "police"],
        "Property & Interiors": ["interior", "elevator", "gate", "object"],
        "General & Roleplay": ["global", "chat", "account", "social", "phone", "hud", "item"],
        "Other": []
    }

    def get_category(res_name):
        res_lower = res_name.lower()
        if res_lower.startswith("[") and res_lower.endswith("]"):
            res_lower = res_lower[1:-1]
        
        for cat, keywords in categories.items():
            for kw in keywords:
                if kw in res_lower:
                    return cat
        return "Other"

    # Filter rules
    ignored_prefixes = ["test", "debug", "temp", "tmp"]
    ignored_commands = ["x", "y", "z", "xyz", "rot"] # explicitly useless single letter parsing helper cmds found earlier

    final_commands_by_cat = {cat: {} for cat in categories.keys()} 
    
    for (resource, func), aliases in commands_map.items():
        # Heuristic: Pick the longest alias that looks "clean" (no random numbers if possible), 
        # or maybe the one that is NOT an abbreviation.
        unique_aliases = sorted(list(set(aliases)), key=len, reverse=True)
        primary = unique_aliases[0]
        
        # Filter junk
        if len(primary) < 2 and primary not in ["me", "do"]: # Allow very common short RP commands
            continue
        if any(primary.lower().startswith(p) for p in ignored_prefixes):
            continue
        if primary.lower() in ignored_commands:
            continue

        if len(unique_aliases) > 1:
            display = f"/{primary} *(Aliases: {', '.join(['/'+a for a in unique_aliases[1:]])})*"
        else:
            display = f"/{primary}"
            
        cat = get_category(resource)
        if resource not in final_commands_by_cat[cat]:
            final_commands_by_cat[cat][resource] = []
        final_commands_by_cat[cat][resource].append(display)

    with open(output_file, 'w', encoding='utf-8') as f:
        f.write("# Server Command List\n\n")
        f.write("> [!NOTE]\n")
        f.write(f"> This curated list contains commands categorized by system. Debug and internal commands have been hidden.\n\n")
        
        for cat in categories.keys(): # Iterate in defined order
            resources = final_commands_by_cat[cat]
            if not resources: continue
            
            f.write(f"## {cat}\n\n")
            
            for resource in sorted(resources.keys()):
                cmds = resources[resource]
                f.write(f"### {resource}\n")
                # f.write("| Command |\n")
                # f.write("| :--- |\n")
                # Grid view might be better for many commands? prefer list for readibility
                for cmd in sorted(cmds):
                    f.write(f"- {cmd}\n")
                f.write("\n")

    print(f"Successfully generated {output_file}.")

if __name__ == "__main__":
    generate_commands_md("all_commands.txt", "all_binds.txt", "commands.md")
