%% Monotonic Pressure Test

function [flag,thresholds]=monotonic_pressure_test(dbd,varargin)

% Tests whether each profile either continuously increases or continuously
% decreases in pressure with time.
% 
% Outputs:
%     flag: vector the same size as var, with corresponding QARTOD flags
%         (1: pass, 2: not evaluated, 3: suspect, 4: fail, 9: no data)
%     thresholds: structured array describing thresholds used for test
%     
% Inputs:
%     dbd: entire single dbd segment
%     varargin:
%         'threshold': single-element data range indicating how much of a
%             change in pressure in the opposite direction of the profile
%             is needed to count as a change in direction (default:
%             anything >0)
%         'exclude_nans': logical indicating whether to exclude nan data
%             points from QC process (default: true)
%         'originalflag': vector the same size as var including flags already
%             in place; new flags will only be added where this is 2 or 9
%         'originalflag_replace': vector including flags in originalflag to
%             replace (default is 2 and 9; 1, 3, and 4 will not be changed)


caller = [mfilename '.m - Monotonic Pressure Test'];

if nargin <1
    fprintf(2,...
        '%s E: not enough arguments.\n',...
        caller);
    return;
end


var=dbd.toArray('sensors','');
var=var(:,2);

threshold_suspect=0;
flag=2*ones(size(var));
originalflag=flag;
originalflagempty=[2,9];
nonan=true;

if(iscell(varargin)&length(varargin)==1)
    varargin=varargin{1};
end

for x=1:2:length(varargin)
    name=varargin{x};
    value=varargin{x+1};
    switch lower(name)
        case 'exclude_nans'
            if(~islogical(value)|length(value)>1)
                fprintf(2,'%s E: Value for %s must be logical\n',caller,name);
                return;
            end
            nonan=value;
        case 'threshold'
            if(~isnumeric(value)|length(value)>1)
                fprintf(2,'%s E: Value for %s must be numeric\n',caller,name);
                return;
            end
            threshold_suspect=-abs(value);
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

if(nonan)
    inddata=find(~isnan(var));
else
    inddata=1:length(var);
end

vardata=var(inddata);
flagdata=flag(inddata);

delta=diff(vardata);

proInds=dbd.profileInds;

if(~isempty(proInds))
    
    for k=1:size(proInds,1)
        indpro=find(inddata>=proInds(k,1)&inddata<=proInds(k,2));
        indpro(indpro==1)=[];
        deltapro=[nan;delta(indpro(1:end-1))];
        
        numinc=sum(deltapro>0);
        numdec=sum(deltapro<0);
        
        if(max(numinc,numdec)<length(deltapro)*.8)
            flagdata(indpro)=3;
            continue;
        end
        
        if(numdec>numinc)
            deltapro=-deltapro;
        end
        
        flagdata(indpro(deltapro<threshold_suspect))=3;
        flagdata(indpro(deltapro>=threshold_suspect))=1;
        
    end
end


flag(inddata)=flagdata;
flag(isnan(var))=9;

ind=find(~ismember(originalflag,originalflagempty)&~isnan(originalflag));
flag(ind)=originalflag(ind);

thresholds.suspect=threshold_suspect;

