# Assembly Game

## Gameplay

This is a 3D first-person survival game set in an underground dungeon, featuring custom-made pixel art. 

The player is hunted by three different monsters that are always aware of the player's location. The only goal is survival, as there is no final win condition. If the player is caught, the application must be restarted to try again.

### Map Generation
The world is generated procedurally as the player explores using the Wave Function Collapse (WFC) algorithm. To mitigate potential failures of the WFC algorithm that could trap the player, areas of the world that are far away from the player are unloaded and generated again when the player comes near. This also gives deja-vu moments, as the layout of a previously visited area may not be as you remember it.

### The Monsters
*   **"Spider":** A small monster that can fit in spaces the player cannot, but is relatively slow.
*   **"Monster":** A medium-sized monster, about the size of the player and slightly slower.
*   **"Ravager":** A large monster that is confined to the main hallways, but is very fast.

## Technical Implementation

This project was written almost entirely from scratch in x86-64 assembly language for the windows operating system. A significant part of the development was figuring out the Windows x64 calling convention.
This was a process of 'blood, sweat, tears, and overusing the debugging tool,' eventually understanding how stack alignment, shadow space, and parameter passing works.

### External Libraries & APIs
The project has minimal dependencies, only using:
*   **Windows API:** For creating and managing the window, and handling OS-level events.
*   **OpenGL:** For GPU-accelerated rendering.
*   **C standard library:** For allocating and freeing memory.
*   **stb_image.h:** A single-file C library used for loading PNG images.

### Assembly Code
All other game systems were implemented manually in assembly. This includes:
*   **Raycasting Render Engine:** The 3D world is rendered using a raycasting engine. The assembly code manages all OpenGL objects (Shaders, FBOs, SSBOs) and data transfers, while GLSL shaders perform the raycasting calculations.
*   **Wave Function Collapse (WFC):** The procedural world generation algorithm.
*   **Physics & Collision:** A system to handle movement and collision with the generated world.
*   **Entity System:** Manages the state and properties of the player and multiple monsters, Allowing for practically infinite monsters even though the game only has 3.
*   **Pathfinding:** Logic for the monsters to find the fastest path towards the player, implemented using the A* algorithm and using a custom-built *binary heap* for the priority queue.
*   **User Input Handling:** Capturing and processing raw keyboard and mouse input.

## Build Instructions
1.  **Install Dependencies:** Ensure you have a working [MinGW-w64](https://www.mingw-w64.org/) installation with GCC and `mingw32-make` available in your system's PATH.
2.  **Compile:** Open a terminal in the project root and run the make command:
    ```sh
    mingw32-make
    ```
3.  **Run:** An executable named `build.exe` will be created in the project root.
    ```
    .\build.exe
    ```

Or simply download the build.exe file in the root of this repository!
