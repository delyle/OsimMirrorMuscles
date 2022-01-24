function propMat = osimDoubleArrayToMat(osimProp)
% get osim property (array of three doubles) as matlab array
import org.opensim.modeling.*

propStr = cell2mat(osimProp.string);
propMat = str2num(propStr(2:end-1));