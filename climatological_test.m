%% Climatological Test

function [flag,thresholds]=climatological_test(var,varargin)

% Checks whether data is within a reasonable range based on time and
% location.
%
% Checks whether data is within sensor limits defined by manufacturer
% (unless other limits are defined).
% 
% Outputs:
%     flag: vector the same size as var, with corresponding QARTOD flags
%         (1: pass, 2: not evaluated, 3: suspect, 4: fail, 9: no data)
%         note: no fail flag defined for this test
%     thresholds: structured array describing thresholds used for test
%     
% Inputs:
%     var: 1-D vector with time-series glider data
%     varargin:
%         'minsuspect': single-element minimum threshold, below is flagged suspect
%         'maxsuspect': single-element max threshold, above is flagged suspect
%         'originalflag': vector the same size as var including flags already
%             in place; new flags will only be added where this is 2 or 9
%         'originalflag_replace': vector including flags in originalflag to
%             replace (default is 2 and 9; 1, 3, and 4 will not be changed)


caller = [mfilename '.m - Test 5: Climatological Test'];

if nargin <2
    fprintf(2,...
        '%s E: not enough arguments.\n',...
        caller);
    return;
elseif ~isnumeric(var)
    fprintf(2,'%s E: First input must be numeric.\n',caller);
    return;
end


minsuspect=nan;
maxsuspect=nan;
flag=2*ones(size(var));
originalflag=flag;
originalflagempty=[2,9];
depthvarying=false;
depthcats=nan;

if(iscell(varargin)&length(varargin)==1)
    varargin=varargin{1};
end

for x=1:2:length(varargin)
    name=varargin{x};
    value=varargin{x+1};
    switch lower(name)
        case 'minsuspect'
            if(~isnumeric(value)|length(value)>1)
                fprintf(2,'%s E: Value for %s must be a numeric scalar\n',caller,name);
                return;
            end
            minsuspect=value;
        case 'maxsuspect'
            if(~isnumeric(value)|length(value)>1)
                fprintf(2,'%s E: Value for %s must be a numeric scalar\n',caller,name);
                return;
            end
            maxsuspect=value;
        case 'originalflag'
            if(~isnumeric(value))
                fprintf(2,'%s E: Value for %s must be numeric\n',caller,name);
                return;
            elseif(size(value)~=size(var))
                fprintf(2,'%s E: Value for %s must be the same size as test variable\n',caller,name);
                return;
            end
            originalflag=value;
        case 'originalflag_replace'
            if(~isnumeric(value))
                fprintf(2,'%s E: Value for %s must be numeric\n',caller,name);
                return;
            end
            originalflagempty=value;
        otherwise
            fprintf(2,...
                '%s E: Unknown option specified: %s\n',...
                caller,...
                name);
            return;
    end
end

if(maxsuspect<minsuspect)
    fprintf(2,'%s E: Value for suspect max is lower than value for suspect min\n',caller);
    return;
end


flag(isnan(var))=9;
flag(var>maxsuspect)=3;
flag(var<minsuspect)=3;
flag(flag==2)=1;

ind=find(~ismember(originalflag,originalflagempty)&~isnan(originalflag));
flag(ind)=originalflag(ind);

if(depthvarying)
    thresholds.depth_ranges=depthcats;
end
thresholds.suspect=[minsuspect maxsuspect];
