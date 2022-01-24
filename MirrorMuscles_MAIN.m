% Main Script for mirroring muscles

clear; clc
import org.opensim.modeling.*

% BEFORE RUNNING: 
% *Prep the OSIM model*. Models from Maya2OpenSim lack blank wrap object
% sets, which are necessary for adding wrap objects to a body.
% Open the model in a text editor (Notepad ++ recommended). For each left-
% side body, ensure that the following code appears:
% 					<WrapObjectSet>
% 						<objects /> 
%                       <groups />
% 					</WrapObjectSet>
% If it doesn't, add it to the body (below the "VisualObject" set and above
% the </Body> tag)

modelPath = 'C:\Users\dpolet\Dropbox\Osim Models Private\Marasuchus\Marasuchus_Model8muscles.osim';% Many models in 'C:\Users\dpolet\Dropbox\Osim Models Private\'
modelNewPath = '';% leave blank to make new file in same directory as modelPath with "_Mirror" appended.
modelNewName = 'Marasuchus_LRmuscles'; % leave blank to preserve name from old model
parameterFile = '';
saveParameters = true;
loadParameters = false;
setWrapDisplay = []; % set display_preference for all wrap objects to the given number (0-4). If number is empty ([]), the display preference will not be changed.

defaultSymAxis = [-1 -1 -1];
bodySymAxis.Body = [1 -1 1];
bodySymAxis.Proximal_tail = [1 1 -1];
bodySymAxis.Distal_tail = [1 1 -1];
midlineBodyList = {'Body','Proximal_tail','Distal_tail'};
