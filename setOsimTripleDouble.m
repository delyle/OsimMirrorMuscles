function osimProp = setOsimTripleDouble(osimProp,newValues)

import org.opensim.modeling.*

% iterate over indices of the osim triple double
for i = 1:3
PropertyHelper.setValueDouble(newValues(i),osimProp,i-1)
end