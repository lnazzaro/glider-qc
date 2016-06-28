%% Gross Range Test

function [flag,thresholds]=gross_range_test(var,varargin)

% Checks whether data is within sensor limits defined by manufacturer
% (unless other limits are defined).
% 
% Outputs:
%     flag: vector the same size as var, with corresponding QARTOD flags
%         (1: pass, 2: not evaluated, 3: suspect, 4: fail, 9: no data)
%     thresholds: structured array describing thresholds used for test
%     
% Inputs:
%     var: 1-D vector with time-series glider data
%     varargin:
%         'minsuspect': single-element minimum threshold, below is flagged suspect
%         'maxsuspect': single-element max threshold, above is flagged suspect
%         'minfail': single-element min threshold, below is flagged fail
%         'maxfail': single-element max threshold, above is flagged fail 
%         'originalflag': vector the same size as var including flags already
%             in place; new flags will only be added where this is 2 or 9
%         'originalflag_replace': vector including flags in originalflag to
%             replace (default is 2 and 9; 1, 3, and 4 will not be changed)
%         'file': name of excel file containing gross range thresholds
%             - if using this option, varname and varunits must also be provided
%             - if minsuspect, maxsuspect, minfail, and/or maxfail are also
%                 input, they will override thresholds read in from the file
%         'varname': string with name of variable as shown in either the
%             dbd group or the excel thresholds file
%         'varunits': string indicating the sensor units used in var
        

caller = [mfilename '.m - Test 4: Gross Range Test'];

if nargin <2
    fprintf(2,...
        '%s E: not enough arguments.\n',...
        caller);
    return;
elseif ~isnumeric(var)
    fprintf(2,'%s E: First input must be numeric.\n',caller);
    return;
end


minfail=nan;
maxfail=nan;
minsuspect=nan;
maxsuspect=nan;
flag=2*ones(size(var));
originalflag=flag;
originalflagempty=[2,9];
fileinfo=[false false];

if(iscell(varargin)&length(varargin)==1)
    varargin=varargin{1};
end

for x=1:2:length(varargin)
    name=varargin{x};
    value=varargin{x+1};
    switch lower(name)
        case 'varname'
            if(~ischar(value))
                fprintf(2,'%s E: Value for %s must be a string indicating the variable name\n',caller,name);
                return;
            end
            varstring=value;
            fileinfo(1)=true;
        case 'varunits'
            if(~ischar(value))
                fprintf(2,'%s E: Value for %s must be a string indicating the variable units\n',caller,name);
                return;
            end
            varunit=value;
            fileinfo(2)=true;
        case 'minfail'
            if(~isnumeric(value)|length(value)>1)
                fprintf(2,'%s E: Value for %s must be a numeric scalar\n',caller,name);
                return;
            end
            minfail=value;
        case 'maxfail'
            if(~isnumeric(value)|length(value)>1)
                fprintf(2,'%s E: Value for %s must be a numeric scalar\n',caller,name);
                return;
            end
            maxfail=value;
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
        case 'file'
        otherwise
            fprintf(2,...
                '%s E: Unknown option specified: %s\n',...
                caller,...
                name);
            return;
    end
end

for x=1:2:length(varargin)
    name=varargin{x};
    value=varargin{x+1};
    switch lower(name)
        case 'file'
            if(~all(fileinfo))
                fprintf(2,'%s E: Must provide variable name and units in order to read limits from file\n',caller,name);
                return;
            end
            if(~ischar(value)|~exist(value,'file'))
                fprintf(2,'%s E: Value for %s must be a valid file name\n',caller,name);
                return;
            end
            indext=find(value=='.');
            if(isempty(indext))
                fprintf(2,'%s E: Value for %s must be a valid file name\n',caller,name);
                return;
            end
            if(~strcmp(value(indext(end)+1:indext(end)+3),'xls'))
                fprintf(2,'%s E: %s must be an Excel spreadsheet\n',caller,name);
                return;
            end
            [~,~,limits]=xlsread(value);
            indunits=find(strcmp('units',limits(1,:)));
            found=false;
            for n=2:size(limits,1)
                indfield=strfind(varstring,limits{n,1});
                if(~isempty(indfield))
                    if(strcmp(lower(limits{n,indunits}),lower(varunit)))
                        found=true;
                        break;
                    end
                end
            end
            if(~found)
                fprintf(2,'%s E: Limits for %s not found in %s\n',caller,varstring,value);
                return;
            end
            if(isnan(minfail))
                ind=find(strcmp('min_fail',limits(1,:)));
                minfail=limits{n,ind};
            end
            if(isnan(maxfail))
                ind=find(strcmp('max_fail',limits(1,:)));
                maxfail=limits{n,ind};
            end
            if(isnan(minsuspect))
                ind=find(strcmp('min_suspect',limits(1,:)));
                minsuspect=limits{n,ind};
            end
            if(isnan(maxsuspect))
                ind=find(strcmp('max_suspect',limits(1,:)));
                maxsuspect=limits{n,ind};
            end
    end
end

if(maxsuspect>maxfail)
    fprintf(2,'%s E: Value for suspect max is higher than value for fail max\n',caller);
    return;
end
if(minsuspect<minfail)
    fprintf(2,'%s E: Value for suspect min is lower than value for fail min\n',caller);
    return;
end
if(maxsuspect<minsuspect)
    fprintf(2,'%s E: Value for suspect max is lower than value for suspect min\n',caller);
    return;
end
if(maxfail<minfail)
    fprintf(2,'%s E: Value for fail max is lower than value for fail min\n',caller);
    return;
end


flag(isnan(var))=9;
flag(var>maxsuspect)=3;
flag(var<minsuspect)=3;
flag(var>maxfail)=4;
flag(var<minfail)=4;
flag(flag==2)=1;

ind=find(~ismember(originalflag,originalflagempty)&~isnan(originalflag));
flag(ind)=originalflag(ind);

thresholds.suspect=[minsuspect maxsuspect];
thresholds.fail=[minfail maxfail];


