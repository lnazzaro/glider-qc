function [minfail,maxfail,minsuspect,maxsuspect,accuracy,resolution]=...
    getManufacturerQCLimits(dgroup,field,file)

% Get manufacturer-defined thresholds for glider data.
% 
% Outputs:
%     minfail: minimum threshold to flag as fail for gross range test
%       (sensor detection limit)
%     maxfail: maximum threshold to flag as fail for gross range test
%       (sensor detection limit)
%     minsuspect: minimum suspect threshold for gross range test
%       (calibration limit)
%     maxsuspect: maximum suspect threshold for gross range test
%       (calibration limit)
%     accuracy: accuracy of sensor (for flat line test)
%     resolution: resolution of sensor (for flat line test)
%     
% Inputs:
%     dgroup: entire dbd group
%     field: sensor to get thresholds for
%     file: excel file containing manufacturer defined thresholds.
%


caller = [mfilename '.m'];

if nargin <2
    fprintf(2,...
        '%s E: not enough arguments.\n',...
        caller);
    return;
elseif ~ischar(field)
    fprintf(2,'%s E: ''field'' input must be a string.\n',caller);
    return;
end

try
    if(~ismember(field,dgroup.sensors))
        fprintf(2,'%s E: field %s not a valid sensor in dgroup.\n',caller,field);
        return;
    end
catch err
    fprintf(2,[caller ' E: ' err.message]);
    return;
end

varunit=dgroup.sensorUnits.(field);
n1=nan;


[~,~,limits]=xlsread(file);
indunits=find(strcmp('units',limits(1,:)));
found=false;
for n=2:size(limits,1)
    indfield=strfind(field,limits{n,1});
    if(~isempty(indfield))
        if(strcmp(lower(limits{n,indunits}),lower(varunit)))
            found=true;
            break;
        elseif(strcmp(lower(limits{n,indunits}),'nodim')|isempty(limits{n,indunits}))
            n1=n;
        end
    end
end
if(~found&~isnan(n1))
    n=n1;
    found=true;
end
if(~found)
    fprintf(2,'%s E: Limits for %s not found in %s\n',caller,field,file);
    return;
end
ind=find(strcmp('min_fail',limits(1,:)));
minfail=limits{n,ind};
ind=find(strcmp('max_fail',limits(1,:)));
maxfail=limits{n,ind};
ind=find(strcmp('min_suspect',limits(1,:)));
minsuspect=limits{n,ind};
ind=find(strcmp('max_suspect',limits(1,:)));
maxsuspect=limits{n,ind};
ind=find(strcmp('accuracy',limits(1,:)));
accuracy=limits{n,ind};
ind=find(strcmp('resolution',limits(1,:)));
resolution=limits{n,ind};
