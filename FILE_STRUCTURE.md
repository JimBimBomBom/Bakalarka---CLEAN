# 📁 Project File Structure
## 🗂️ Root Structure
/ProjectRoot
├── Simulation/          # Base Godot project folder
├── rust/                # Rust GDExtension source code
├── EXPORT               # Contains executable build
├── Visualization        # Contains Python script used for visualizing CSV data.
└── Thesis               # Contains both Thesis PDF and SOURCE files

## 📁 Simulation/

Contains all assets and scripts related to the Godot application.

```
/Simulation
├── PARAMS/              # CSV files used to initialize the application (only when using Godot editor)
│
├── SCENES/              # Godot scenes (.tscn, .scn)
│
├── SCRIPTS/             # GDScript source files
│   ├── Camera/          # Camera movement scripts for GUI navigation
│   │
│   ├── Global/          # General-purpose and application-wide scripts
│   │   ├── DataLogger.gd               # Logs data in CSV format into file, for later visualization
│   │   ├── World_Variables.gd          # Godot global script holding shared variables
│   │   ├── SimulationGUI.gd            # GUI setup for simulation runs
│   │   ├── Simulation_Parameters.gd    # Contains all Godot and Rust side sim. params, and logic to load them from CSV file
│   │   └── Animal_Statistics.gd        # Struct holding displayable statistics (showcased only during DEBUG)
│   │
│   └── World_Generation/   # World generation and Rust interfacing
│       ├── TileMap.gd                  # Logic for creating and initializing map + handling visualization of map    
│       ├── TileProperties.gd           # Struct containing all variables neccessary for Tile
│       ├── world.gd                    # For simulation acts like "main" script
│       └── UI_statistics.gd            # Responsible for displaying current simulation statistics (only during DEBUG)
│
├── Sprites/             # In-app visualization sprite assets
│   └── Contains 1 sprite atlas where each biome corresponds to a hexagon
│
└── Visualization/       # External data visualization script
    └── visualize.py

## 📁 rust/
Contains all Rust source files used via GDExtension.

/rust
└── simulation/
    ├── animal.rs        # Implements the Animal class and behavior
    ├── genes.rs         # Implements Genes class for genetics handling
    ├── lib.rs           # Entrypoint; exposes functions to Godot, acts as main() logic
    ├── map.rs           # Logic for updating and managing the map state
    ├── structs.rs       # Shared structs used across Rust modules
    └── utils.rs         # Helper functions (e.g., coordinate math, tile queries)

## 📌 Notes

- The `lib.rs` file in Rust is the integration point with Godot via GDExtension.
- Godot's `World_Generation` scripts call Rust for computation-heavy operations.
- The `Visualization` folder contains a Python script for analyzing and plotting simulation results from logged data.
- Exported binaries and builds are located in `Simulation/EXPORT/`.
