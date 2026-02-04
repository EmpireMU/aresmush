# Organisations Plugin

A comprehensive plugin for managing character memberships in multiple organisations (noble houses, guilds, institutions, etc.).

## Features

- **Multiple Memberships**: Characters can belong to any number of organisations simultaneously
- **Staff-Controlled**: Only staff can add/remove characters from organisations (requires `manage_organisations` permission)
- **Profile Integration**: Organisation memberships display on character profiles
- **Web Portal Support**: Full web portal integration with API endpoints
- **Roster Filtering**: View roster characters grouped by organisation (critical for large rosters)
- **In-Game Commands**: Complete set of commands for viewing and managing organisations

## Installation

1. The plugin is already installed in your `plugins/organisations` directory
2. Copy the config file from `install/game.distr/config/organisations.yml` to your `game/config/` directory
3. Edit `game/config/organisations.yml` to add your 20 organisations
4. Restart the game

## Configuration

Edit `game/config/organisations.yml`:

```yaml
organisations:
  organisations:
    House Salfeld:
      description: Noble house description here.
      wiki: house-salfeld
    University of Sanctuary:
      description: Premier educational institution.
      wiki: university
    # Add your other 18 organisations...
```

Each organisation needs:
- **Name** (the key)
- **description**: A brief description
- **wiki**: Wiki page reference (can be blank)

## Commands

### For Staff (requires `manage_organisations` permission)

- `org/add <character>=<organisation>` - Add a character to an organisation
- `org/remove <character>=<organisation>` - Remove a character from an organisation

### For Everyone

- `orgs` - List all available organisations
- `org <name>` - Show information about a specific organisation
- `org/members <name>` - List all members of an organisation
- `orgs <character>` - Show which organisations a character belongs to

## Web Portal Integration

The plugin provides several API endpoints:

- `organisations` - Returns list of all organisations with member counts
- `organisationInfo` - Returns detailed info about a specific organisation
- `organisationMembers` - Returns member list for an organisation
- `rosterByOrganisation` - Returns roster grouped by organisation (for filtering)

## Roster Integration

The roster can now be filtered by organisation. Characters appear under each organisation they belong to. The web portal can call the `rosterByOrganisation` endpoint with an optional `organisation` parameter to filter the roster.

## Profile Integration

Organisation memberships automatically appear on character profiles (both in-game and web portal) in an "Organisations" section.

## Permissions

The plugin adds one permission:
- `manage_organisations` - Allows adding/removing characters from organisations

Assign this to your staff roles in `roles.yml`.

## Help Files

Two help files are included:
- `organisations` - Admin help for managing organisations
- `org_membership` - Player help for viewing organisations

## File Structure

```
plugins/organisations/
├── organisations.rb (main plugin file)
├── commands/ (all command handlers)
├── public/ (character model extensions and API)
├── templates/ (in-game display templates)
├── web/ (web portal request handlers)
├── locales/ (messages and translations)
├── help/ (help documentation)
└── README.md (this file)
```

## Notes

- Characters can belong to unlimited organisations
- Organisation names are case-insensitive for commands
- The system automatically handles duplicate prevention
- Empty organisations still appear in lists but show 0 members
