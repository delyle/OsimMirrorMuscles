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
mainDir = 'C:\Users\dpolet\Dropbox\Osim Models Private\';
modelPath = [mainDir,'Marasuchus\Marasuchus_Model8muscles.osim'];% Many models in 'C:\Users\dpolet\Dropbox\Osim Models Private\'
modelNewPath = [mainDir,'Marasuchus\Marasuchus_Model8muscles_Mirror_noWrapDisp.osim'];% leave blank to make new file in same directory as modelPath with "_Mirror" appended.
modelNewName = 'Marasuchus_LRmuscles'; % leave blank to preserve name from old model
parameterFile = '';
saveParameters = false;
loadParameters = true;
setWrapDisplay = []; % set display_preference for all wrap objects to the given number (0-4). If number is empty ([]), the display preference will not be changed.

defaultSymAxis = [-1 -1 -1];
bodySymAxis.Body = [1 -1 1];
bodySymAxis.Proximal_tail = [1 1 -1];
bodySymAxis.Distal_tail = [1 1 -1];
midlineBodyList = {'Body','Proximal_tail','Distal_tail'};


%%
if isempty(modelNewPath)
    modelNewPath = [strrep(modelPath,'.osim',''),'_Mirror.osim'];
end

if loadParameters
    if isempty(parameterFile)
       load([strrep(modelPath,'.osim',''),'_MirrorParameters.mat']); 
    end
    % will have an option to overwrite input parameters above with values
    % from file.
end
if saveParameters
    savename = [strrep(modelPath,'.osim',''),'_MirrorParameters.mat'];
    save(savename,'modelPath','bodySymAxis','midlineBodyList','defaultSymAxis')
end

model = Model(modelPath);

if ~isempty(modelNewName)
    model.setName(modelNewName);
end
% Get the state
state = model.initSystem();
bodySet = model.getBodySet();

%% Duplicate and mirror wrapping objects
import org.opensim.modeling.*

newWrapObjects = struct();
nBodies = bodySet.getSize;
for ii = 1:nBodies-1
    % Note: in Opensim 3.x, ground is the first body (0), so we skip it.
    disp(' ')
    body = Body().safeDownCast(bodySet.getPropertyByIndex(0).updValueAsObject(ii));
    bodyName = cell2mat(body.getName.string);
    
    isMidlineBody = false;
    if any(strcmp(bodyName,midlineBodyList))
       isMidlineBody = true; 
       disp([bodyName,' identified as Midline Body'])
    elseif strcmpi(bodyName(1),'R')
        isMidlineBody = false;
        disp([bodyName,' identified as Rightside Body'])
    elseif strcmpi(bodyName(1),'L')
         disp([bodyName,' identified as Leftside Body'])
         continue % skip to the next iteration
    else
        warning([bodyName,' could not be identified as Midline, Right or Left',...
            newline,'Interpreting as midline body'])
        isMidlineBody = true;
    end
    wrapSet = body.updPropertyByName('WrapObjectSet');
    wrapSetObj = wrapSet.getValueAsObject(0);
    wrapSetArray = wrapSetObj.updPropertyByIndex(0);
    disp(['-- Finding wrap objects for ',bodyName])
    
    % Cannot get Array size apriori. Loop trough until it breaks to find
    % array size
    working = true;
    i = 0;
    while working
        try
            wrapSetArray.getValueAsObject(i);
            i = i+1;
        catch
            working = false;
            break
        end  
    end
    nWrapObjects = i;
    disp([num2str(nWrapObjects),' wrap objects found'])
    
    if isMidlineBody
        bodyAttachName = bodyName;
        bodyAttach = body;
    else
        bodyAttachName = ['L',bodyName(2:end)];
        bodyAttach = Body().safeDownCast(bodySet.get(bodyAttachName));
    end
    
    for i = 0:nWrapObjects-1
        wrapObj = wrapSetArray.getValueAsObject(i);
        wrapType = cell2mat(wrapObj.getConcreteClassName.string);
        wrapObj = org.opensim.modeling.(wrapType)().safeDownCast(wrapObj); % gets wrap object as derived class
        
        if ~isempty(setWrapDisplay)
           % change wrap display_preference to given number
           dispPref = wrapObj.getPropertyByName('display_preference');
           PropertyHelper.setValueInt(setWrapDisplay,dispPref)
        end
        
        wrapObj2 = wrapObj.clone();% duplicate wrap object
        nameOld = wrapObj.getName.string;
        nameNew = ['l',nameOld{1}(2:end)]; % set as "left"
        wrapObj2.setName(nameNew);
        
        
        % Update translation
        transProp = wrapObj2.getPropertyByName('translation');
        transOldMat = osimDoubleArrayToMat(transProp);
        mirror = defaultSymAxis;
        if isfield(bodySymAxis,bodyName)
            mirror = bodySymAxis.(bodyName); % use given value if provided
        end
        transNewMat = transOldMat.*mirror;
        transProp = setOsimTripleDouble(transProp,transNewMat);

        rotProp = wrapObj2.getPropertyByName('xyz_body_rotation');
        rotOldMat = osimDoubleArrayToMat(rotProp);
        rotNewMat = rotOldMat.*-mirror;
        rotProp = setOsimTripleDouble(rotProp,rotNewMat);
        
        quadOld = cell2mat(wrapObj.getQuadrantName.string);
        switch quadOld(1)
            case 'a'
                quadNew = 'all';
            case '-'
                quadNew = quadOld(2);
            case '+'
                quadNew = ['-',quadOld(2)];
            otherwise
                quadNew = ['-',quadOld];
        end
        wrapObj2.setQuadrantName(quadNew);
        
        bodyAttach.addWrapObject(wrapObj2);
        newWrapObjects.(nameNew) = wrapObj2; % save structure of new wrap objects to use later
    end
    model.initSystem(); 
end


%% iterate through muscles

nMuscles = model.getForceSet.getSize;
for ii = 0:nMuscles-1
    forces = model.getForceSet();
    muscleRight = Millard2012EquilibriumMuscle.safeDownCast(forces.get(ii));
    forces.cloneAndAppend(muscleRight); % duplicate muscle and add to the force set.
    muscleLeft = ... % retrieve new muscle in matlab-safe version.
        Millard2012EquilibriumMuscle.safeDownCast(forces.get(model.getForceSet.getSize-1));
    muscleoldname = muscleRight.getName().string;
    musclenewname = ['L',muscleoldname{1}(2:end)];
    muscleLeft.setName(musclenewname);
    disp(['---New muscle ',musclenewname,' cloned from ',muscleoldname{:},'---'])
    
    %%% Get the geometry path
    geomPath = muscleLeft.updGeometryPath();%muscle2.getPropertyByName('GeometryPath');
    pathPointSet = geomPath.getPathPointSet();
    nPP = pathPointSet.getSize;
    
    for i = 0:nPP-1
        pathPoint = geomPath.getPathPointSet().getPropertyByIndex(0).getValueAsObject(i);
        ppName = cell2mat(pathPoint.getName.string);
        ppBody = cell2mat(pathPoint.getPropertyByName('body').string);
        ppLoc = cell2mat(pathPoint.getPropertyByName('location').string);
        
        mirror = defaultSymAxis;
        if isfield(bodySymAxis,ppBody)
            mirror = bodySymAxis.(ppBody); % use given value if provided
        end
        if any(strcmp(ppBody,midlineBodyList))
            ppNewBody = ppBody;
        else
            ppNewBody = ['L',ppBody(2:end)];
        end
        ppLocMat = str2num(ppLoc(2:end-1));
        ppNewLocMat = ppLocMat.*mirror; % flips the sign of one of the values
        ppNewName = ppName;
        if strcmpi(ppName(1),'r')
            ppNewName = ['l',ppName(2:end)];
        end
        muscleLeft.addNewPathPoint(ppNewName,bodySet.get(ppNewBody),mat2Vec3(ppNewLocMat))
        disp(['New path point ',ppNewName,' added to ',musclenewname])
        disp(['  Path point attached to body ',ppNewBody])
        disp(['  Location moved from ',ppLoc,' to ',mat2str(ppNewLocMat)])
        disp(' ')
    end
    %%% Delete original Path Points
    state = model.initSystem(); % reinitialize the state
    for i = 0:nPP-1
        geomPath.deletePathPoint(state,0);
    end
    
        %%% Add Path Wraps
    nWraps = geomPath.getWrapSet.getSize;
    wrapSet = geomPath.getWrapSet; % may need upd object... will see 'PathWrapSet'
    for i = 0:nWraps-1
        pathWrap = PathWrap().safeDownCast(wrapSet.getPropertyByIndex(0).getValueAsObject(i));
        pathWrapName = cell2mat(pathWrap.getWrapObjectName.string);
        pathWrapNewName = ['l',pathWrapName(2:end)];
        
        % duplicate wrap object
        wrapSet.cloneAndAppend(pathWrap);
        pathWrapNew = pathWrap().safeDownCast(wrapSet.getPropertyByIndex(0).updValueAsObject(i+nWraps));
        pathWrapNew.setWrapObject(newWrapObjects.(pathWrapNewName));
        
        % get corresponding range from Right muscle (will not transfer over
        % to left muscle)
        pathWrapRight = PathWrap.safeDownCast(muscleRight.getGeometryPath.getWrapSet.getPropertyByIndex(0).getValueAsObject(i));
        wrapRange = osimDoubleArrayToMat(pathWrapRight.getPropertyByName('range'));
        
        % set apropriate range for new wrap object on left muscle 
        pathRange = pathWrapNew.getPropertyByName('range');
        PropertyHelper.setValueInt(wrapRange(1),pathRange,0);
        PropertyHelper.setValueInt(wrapRange(2),pathRange,1);
    end
    %%% Delete original Path Wraps
    state = model.initSystem();
    for i = 0:nWraps-1
        geomPath.deletePathWrap(state,0);
    end
end
%% Save the model to a file

model.print(modelNewPath);
disp([modelNewPath,' printed'])
