clear;clc
import org.opensim.modeling.*

modelPath = 'C:\Users\dpolet\Dropbox\Osim Models Private\Mussaurus\Mussaurus_Base_Model4-4.2.osim';
modelNewPath = '';% leave blank to make new file in same directory as modelPath with "_Mirror" appended.
modelNewName = 'Mussaurus_LRmuscles'; % leave blank to preserve name from old model
parameterFile = '';
saveParameters = true;
loadParameters = false;

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
for ii = 0:nBodies-1
    disp(' ')
    body = Body().safeDownCast(bodySet.getPropertyByIndex(1).updValueAsObject(ii));
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
    wrapSetArray = wrapSetObj.updPropertyByIndex(1);
    disp(['-- Finding wrap objects for ',bodyName])
    
    % Cannot get Array size apriori. Loop trough until it issues an error
    % to find array size
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
        bodyAttach = bodySet.get(bodyAttachName);
    end
    
    for i = 0:nWrapObjects-1
        wrapObj = wrapSetArray.getValueAsObject(i);
        wrapType = cell2mat(wrapObj.getConcreteClassName.string);
        wrapObj = org.opensim.modeling.(wrapType)().safeDownCast(wrapObj); % gets wrap object as derived class
        
        wrapObj2 = wrapObj.clone();% duplicate wrap object
        nameOld = wrapObj.getName.string;
        nameNew = ['l',nameOld{1}(2:end)]; % set as "left"
        wrapObj2.setName(nameNew);
        
        transOld = wrapObj.get_translation().string;
        transOldMat = str2num(transOld{1}(3:end-1));
        mirror = defaultSymAxis;
        if isfield(bodySymAxis,bodyName)
            mirror = bodySymAxis.(bodyName); % use given value if provided
        end
        transNewMat = transOldMat.*mirror;
        wrapObj2.set_translation(mat2Vec3(transNewMat));
        
        rotOld = wrapObj.get_xyz_body_rotation().string;
        rotOldMat = str2num(rotOld{1}(3:end-1));
        rotNewMat = rotOldMat.*-mirror;
        wrapObj2.set_xyz_body_rotation(mat2Vec3(rotNewMat));
        
        quadOld = cell2mat(wrapObj.get_quadrant.string);
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
        wrapObj2.set_quadrant(quadNew);
        
        bodyAttach.addWrapObject(wrapObj2)
        newWrapObjects.(nameNew) = wrapObj2; % save structure of new wrap objects to use later
    end
    model.initSystem(); 
end

%% iterate through muscles

nMuscles = model.getForceSet.getSize;
for ii = 0:nMuscles-1
    forces = model.getForceSet();
    muscleRight = forces.get(ii);
    forces.cloneAndAppend(muscleRight); % duplicate muscle and add to the force set.
    muscleLeft = ... % retrieve new muscle in matlab-safe version.
        Millard2012EquilibriumMuscle.safeDownCast(forces.get(model.getForceSet.getSize-1));
    muscleRight = ... % also retrieve right muscle in derived class
        Millard2012EquilibriumMuscle.safeDownCast(muscleRight);
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
        ppBody = ... % gets the parent body and removes the affix '/bodyset/'
            strrep(cell2mat(pathPoint.getPropertyByName('socket_parent_frame').string),'/bodyset/','');
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
    wrapSet = geomPath.updWrapSet;
    for i = 0:nWraps-1
        pathWrap = PathWrap().safeDownCast(wrapSet.getPropertyByName('objects').getValueAsObject(i));
        pathWrapName = cell2mat(pathWrap.get_wrap_object.string);
        pathWrapNewName = ['l',pathWrapName(2:end)];
        
        % duplicate wrap object
        wrapSet.cloneAndAppend(pathWrap);
        pathWrapNew = pathWrap().safeDownCast(wrapSet.getPropertyByName('objects').updValueAsObject(i+nWraps));
        pathWrapNew.set_wrap_object(pathWrapNewName);
        
        % get corresponding range from Right muscle (will not transfer over
        % to left muscle)
        pathWrapRight = PathWrap.safeDownCast(muscleRight.getGeometryPath().getWrapSet.getPropertyByName('objects').getValueAsObject(i));
        wrapRange(1) = pathWrapRight.get_range(0);
        wrapRange(2) = pathWrapRight.get_range(1);
        
        % set apropriate range for new wrap object on left muscle 
        pathWrapNew.set_range(0,wrapRange(1));
        pathWrapNew.set_range(1,wrapRange(2));
    end
    %%% Delete original Path Wraps
    state = model.initSystem();
    for i = 0:nWraps-1
        geomPath.deletePathWrap(state,0);
    end
end
%% Save the model to a file
model.initSystem(); % check model consistency
model.print(modelNewPath);
disp([modelNewPath,' printed'])
