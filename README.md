# Realtime Tactics 2000

**Realtime Tactics 2000** is a real-time tactical strategy game where you command autonomous units to capture objectives and outmaneuver the opposing team.

Instead of directly controlling individual characters, you issue movement orders and let your units handle movement and combat autonomously. Your role is to observe the battlefield, make tactical decisions, and adapt to the situation as it unfolds.

## Vision

Realtime Tactics 2000 aims to capture the feeling of being a battlefield commander rather than a directly controlled combatant.

The game is built around a simple loop:

**Observe → Plan → Command → Adapt**

We want tactical decisions, positioning, timing, and unit composition to matter more than mechanical execution.

The visual design is intentionally simple and readable, using geometric shapes and strong colors to make units and battlefield events immediately understandable.

## Project Structure

```text
.
├── addons/
│   └── at-icons/                 # Icon browser and icon assets
├── src/
│   ├── gameplay/
│   │   ├── unit components/      # Movement, perception, health, rendering, and behavior
│   │   ├── unit.gd
│   │   ├── unit.tscn
│   │   └── unit_command_controller.gd
│   └── resources/
│       ├── classes/              # Strong, Quick, and Smart unit definitions
│       └── class_definition.gd
├── tools/                        # Level builder, geometry, polygons, and visuals
├── game.tscn                     # Main game scene
└── project.godot                 # Godot project configuration
```

## References

The main gameplay inspiration is **Team Fortress 2's Control Points** mode, particularly its focus on:

* Controlling territory
* Contesting objectives
* Coordinating different roles
* Creating opportunities through positioning and timing

The game's autonomous-unit approach also draws inspiration from strategy and tactics games where the player's primary role is giving orders rather than directly controlling individual characters.

## Team

* [**Willian (visconde)**](https://www.linkedin.com/in/visconde/) — Designer / Developer
* [**Eric (Centropic)**](https://www.linkedin.com/in/ericsingletonjr/) — Composer
* [**Germán (Weirhelmer)**](https://www.linkedin.com/in/griztall/) — SFX Designer

## Jam

Realtime Tactics 2000 is an entry for the **Dreamlayer Jam #1**.

[Dreamlayer Jam #1](https://itch.io/jam/dreamlayer-jam-1)
