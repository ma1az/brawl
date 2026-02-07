-- ============================================================
-- Garbage Collector Job – Shared Configuration
-- ============================================================

GARBAGE_JOB_ID = 8

-- Object models for each trash type (used with /createtrash [1-7])
GARBAGE_TRASH_MODELS = {
	[1] = 1337,   -- wheelie bin
	[2] = 1359,   -- bin bag pile
	[3] = 1439,   -- rubbish pile
	[4] = 1339,   -- bin bag (small green)
    [5] = 1340,   -- bin bag (small black)
	[6] = 1409,   -- bin bags
	[7] = 1430,   -- rubbish
}

-- Carry prop model (attached to player hand while carrying)
GARBAGE_CARRY_MODEL = 1265   -- BinBag (small black trash bag)

-- Pay range per bag (random between min-max)
GARBAGE_PAY_MIN = 30
GARBAGE_PAY_MAX = 80

-- Cooldown before the same trash object can be collected again (seconds)
GARBAGE_COOLDOWN_SECONDS = 5 * 60

-- Vehicle load capacity (bags)
GARBAGE_BASE_CAPACITY    = 10
GARBAGE_CAPACITY_PER_LEVEL = 4

-- Maximum distance to pick up trash (world units)
GARBAGE_PICKUP_DISTANCE = 3.0

-- Dump location (drive here to unload)
GARBAGE_DUMP_POSITION = { x = -1894.2470703125, y = -1671.7001953125, z = 23.015625 }
GARBAGE_DUMP_RADIUS   = 4
GARBAGE_DUMP_WAIT_MS  = 3000

-- Load zone (back of the Trashmaster – offset from vehicle origin)
GARBAGE_LOAD_OFFSET = { x = 0, y = -4.2, z = 0.2 }
GARBAGE_LOAD_RADIUS = 2.0

-- XP needed per level
GARBAGE_LEVEL_REQUIREMENTS = {
	[1] = 50,
	[2] = 200,
	[3] = 1000,
	[4] = 3200,
}
