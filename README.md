# OsimMirrorMuscles

These scripts and functions duplicate muscles and wrap objects from the right side of an OpenSim model to the left.

Both OpenSim v3 and v4 models are supported, though the appropriate API must be installed and working on your matlab instance

## Dependencies

This software requires the OpenSim API for Matlab.

* OpenSim 3.x: installation instructions [here](https://simtk-confluence.stanford.edu:8443/display/OpenSim33/Scripting+with+Matlab#:~:text=Setting%20up%20your%20Matlab%20Scripting%20Environment)
* Opensim 4.x: installation instructions [here](https://simtk-confluence.stanford.edu:8443/display/OpenSim/Scripting+with+Matlab#ScriptingwithMatlab-MatlabSetupSettingupyourMatlabScriptingEnvironment)

### Notes on switching OpenSim API versions

I have installed the OpenSim 3.x API on one version of MATLAB, and the OpenSim 4.x API on another. This avoids having to run the `configureOpenSim` command every time I want to switch.

However, the both versions require the system paths to be set up appropriately, and will conflict depending on which version has priority in the path.

If your paths are not set up correctly, the script will error and you will receive a notice to check and update your system path, as directed [here](https://simtk-confluence.stanford.edu:8443/display/OpenSim/Scripting+with+Matlab#ScriptingwithMatlab-MatlabSetupSettingupyourMatlabScriptingEnvironment). Specific instructions for finding and editing path variables (in general) are [here](https://www.java.com/en/download/help/path.html). You'll need to restart your instance of Matlab for the changes to take effect.

## Basic Useage

Specify the path to your model, and (optionally) a path and name for your new model.

Then, specify parameters

`defaultSymAxis` says whether to flip x, y, and z by default. `[-1 -1 -1]` means all axes are flipped, while `[1 -1 1]` means only the y axis is flipped.

`defaultSymAxis` is applied to all bodies by default. Exceptions can be specified in the structure `bodySymAxis`. Here, the field names are the names of the OpenSim body (CASE SENSITIVE!), and the value is the symmetry axis (defined in the same way as `defaultSymAxis`)

For example, if the body "Distal_tail" had a different Sym axis from default, I could write `bodySymAxis.Distal_tail = [1 1 -1];`

Midline bodies are treated differently. Here, muscles and wrap objects need to be transferred to the *same* object, but on a different side. Specify these special bodies with a cell array called `midlineBodyList`. For example, I could write `midlineBodyList = {'Body','Proximal_tail','Distal_tail'};`

To save these parameters, set `saveParameters` to true. To load them, set `loadParameters` to true. By default, the script saves the parameters to `<model path>_MirrorParameters.mat`

Email questions to dpolet@rvc.ac.uk
