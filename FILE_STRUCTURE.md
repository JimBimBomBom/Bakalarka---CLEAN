Certainly! Here's the complete `FILE_STRUCTURE.md` in a single output box, ready to copy:

```markdown
# 📁 Project File Structure

This document outlines the folder and file organization of the Godot + Rust simulation project.

---

## 🗂️ Root Structure

```
/ProjectRoot
├── Simulation/          # Base Godot project folder
└── rust/                # Rust GDExtension source code
```

---

## 📁 Simulation/

Contains all assets and scripts related to the Godot application.

```
/Simulation
├── EXPORT/              # Holds exported builds (e.g., Windows/Linux executables)
│
├── PARAMS/              # CSV files used to initialize the application
│
├── SCENES/              # Godot scenes (.tscn, .scn)
│
├── SCRIPTS/             # GDScript source files
│   ├── Camera/          # Camera movement scripts for GUI navigation
│   │   └── CameraController.gd
│   │
│   ├── Global/          # General-purpose and application-wide scripts
│   │   ├── DataLogger.gd
│   │   ├── Main.gd              # Godot "main" entry script
│   │   ├── SimulationGUI.gd     # GUI setup for simulation runs
│   │   └── Structs.gd           # Visualization-related structures
│   │
│   └── World_Generation/   # World generation and Rust interfacing
│       ├── MapGenerator.gd
│       ├── VisualUpdater.gd
│       └── RustBridge.gd       # Calls Rust functions for stats and logic
│
├── Sprites/             # In-app visualization sprite assets
│   └── (various .png files)
│
└── Visualization/       # External data visualization scripts
    └── visualize.py
```

---

## 📁 rust/

Contains all Rust source files used via GDExtension.

```
/rust
└── simulation/
    ├── animal.rs        # Implements the Animal class and behavior
    ├── genes.rs         # Implements Genes class for genetics handling
    ├── lib.rs           # Entrypoint; exposes functions to Godot, acts as main() logic
    ├── map.rs           # Logic for updating and managing the map state
    ├── structs.rs       # Shared structs used across Rust modules
    └── utils.rs         # Helper functions (e.g., coordinate math, tile queries)
```

---

## 📌 Notes

- The `lib.rs` file in Rust is the integration point with Godot via GDExtension.
- Godot's `World_Generation` scripts call Rust for computation-heavy operations.
- The `Visualization` folder contains a Python script for analyzing and plotting simulation results from logged data.
- Exported binaries and builds are located in `Simulation/EXPORT/`.

```