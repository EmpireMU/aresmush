---
toc: ~admin~ Managing the Game
summary: Managing character organisation memberships.
aliases:
- orgs
---
# Organisations

Organisations represent the various groups, houses, guilds, and institutions that characters can belong to. Characters can be members of multiple organisations simultaneously.

> **Permission Required:** These commands require the `manage_organisations` permission.

## Viewing Organisations

`orgs` - Lists all available organisations.
`org <name>` - Shows information about a specific organisation.
`org/members <name>` - Lists all members of an organisation.
`orgs <character>` - Shows which organisations a character belongs to.

## Managing Memberships

`org/add <character>=<organisation>` - Adds a character to an organisation.
`org/remove <character>=<organisation>` - Removes a character from an organisation.

## Configuration

Organisations are configured in `organisations.yml`. Each organisation has:
- **Name** - The organisation's name
- **Description** - A brief description
- **Wiki** - Wiki page reference (optional)

## Examples

`orgs` - View all organisations
`org House Salfeld` - View info about House Salfeld
`org/add Alice=House Salfeld` - Add Alice to House Salfeld
`org/remove Bob=Merchant's Guild` - Remove Bob from Merchant's Guild
`orgs Alice` - See which organisations Alice belongs to
