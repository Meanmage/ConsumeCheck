# ConsumeCheck

A World of Warcraft Vanilla 1.12.1 addon that scans raid members' buffs and generates report in a text file.

## Features

- **Raid Buff Scanning**: On-demand scans all online raid members and their active buffs
- **Filtering**: Uses a blacklist to filter out common buffs while preserving consumables
- **Detailed Reports**: Generates timestamped reports with player information, maximum health, buff count, buff names, and spell IDs
- **File Export**: Saves reports to text files with timestamp and zone information

## Requirements

- **World of Warcraft Vanilla 1.12.1**
- **[SuperWoW](https://github.com/balakethelock/SuperWoW)** - Required for extended API functionality

## Installation

1. Download or clone this repository
2. Extract the `ConsumeCheck` folder to your WoW `Interface/AddOns/` directory
3. Ensure you have SuperWoW installed and running

## Usage

### Basic Command
```
/cc
```

Simply type `/cc` while in a raid to scan all online raid members and generate a comprehensive buff report.

### What Gets Reported

- **Player Information**: Name, class, and maximum health
- **Buff Counts**: Total buffs vs. significant buffs (after filtering)
- **Buff Details**: Each significant buff with its spell ID for identification
- **Zone and Timestamp**: When and where the scan was performed

### Blacklist System

The addon includes a blacklist that filters out common buffs while preserving important consumables. Blacklisted buffs include:

- Class buffs (Battle Shout, Arcane Intellect, etc.)
- Paladin blessings and auras
- Druid forms and auras
- Totem effects
- Common armor spells
- And many more...

**Note**: Blacklisted buffs are still counted in the total but hidden from the detailed display to focus on consumables and temporary effects.

## Sample Output

```
=== ConsumeCheck Report ===
Timestamp: 2025-06-29 15:30:45
Zone: Blackwing Lair
==========================

Online Players: 40

Raidleader (Warrior)
Max Health: 6500
Buffs: 12/32 (showing 3 significant)
  1. Flask of the Titans (ID: 17626)
  2. Elixir of Fortitude (ID: 3593)
  3. Juju Power (ID: 16323)

Healer (Priest)
Max Health: 4200
Buffs: 8/32 (showing 2 significant)
  1. Greater Arcane Elixir (ID: 17539)
  2. Cerebral Cortex Compound (ID: 25668)
```

## File Output

Reports are automatically saved to your WoW directory with filenames like:
- `ConsumeCheck_2025-06-29_15-30-45_Blackwing_Lair.txt`

## Customization

### Adding Buffs to Blacklist

The blacklist can be customized by editing the `BuffBlacklist` table in `ConsumeCheck.lua`. The blacklist uses lowercase, exact string matching for buff names.

### Modifying Scan Parameters

- `MAX_BUFFS`: Maximum number of buff slots to scan (default: 32)
- Buff detection logic can be adjusted in the `ScanRaidBuffs()` function

## Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.

### Adding New Blacklisted Buffs

If you find buffs that should be blacklisted, please:
1. Include the exact buff name as it appears in-game
2. Provide the spell ID if possible
3. Explain why it should be filtered (common raid buff, class ability, etc.)

## License

This project is open source. Feel free to modify and redistribute as needed.

## Changelog

### Version 1.0
- Initial release
- Raid buff scanning with SuperWoW integration
- Blacklist filtering system
- File export functionality
- Spell ID display for buff identification
- Support for offline player detection
- Comprehensive error handling