# Bloxy Lune
Lune scripts to simulate Roblox luau scripts

# Purpose
The goal is to run a few simple scripts that does not depend too much on Roblox APIs without Roblox client nor Roblox Studio

# Implemented
## Every Roblox methods which is implemented in Lune (@lune/roblox)
## RunService
## require
## Instance
- Instance.new(className: string, parent: Instance?)
- Instance.fromExisting
- instance.WaitForChild

# TODO
- TweenService
- HttpService
- Debris
- RemoteEvents that uses @lune/net's `ws`
- UserInputService (idk)
- DataStoreService
- Raycast (idk)
- Add `run` option `--rojo-project`
- Add `run` option `--plugin <script path>` to customize luau environments
- Add `run` option `--player <player name>` for running client and server script
- Script timeout feature (also with `--timeout` option)

# In the future
This project is going to be used for my **discord bot** which can run the roblox'ish luau scripts on discord platform. and thinking of using it my coming project called **RbxGui2Web**

# Credits
- [Lune](https://github.com/lune-org/lune)
- Thanks to [BusyCityGuy](https://github.com/BusyCityGuy) for Jest lune scripts from [finite-state-machine-luau](https://github.com/BusyCityGuy/finite-state-machine-luau)
