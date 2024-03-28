function [xPts,yPts,hPts] = fcn_ParseXODR_extractXYfromSTandGeometries(geomElement,stationPoints, varargin)
% fcn_ParseXODR_extractXYfromSTandGeometries 
% Wrapper function to call the findXYfromST function with the appropriate
% arguments based on the XODR road geometry element being referenced
%
% FORMAT:
%
%       [xPts,yPts,hPts] = fcn_ParseXODR_extractXYfromSTandGeometries(geomElement,sPts,tPts)
%
% INPUTS:
%
%       geomElement: a portion of an XODR map containing a single road
%         geometry element and all of its child elements 
% 
%       stationPoints: a vector of s coordinates for points at which to
%       determine the X,Y coordinates
% 
% (OPTIONAL INPUTS)
%
%       tPts: a vector of t coordinates for points at which to determine
%         the X,Y coordinates. If not entered, defaults to zero to give the
%         road centerline
%
%      fig_num: a figure number to plot results. If set to -1, skips any
%      input checking or debugging, no figures will be generated, and sets
%      up code to maximize speed.
%
% OUTPUTS:
%
%       xPts: a vector of x coordinates for points at which the s and t
%         coordinates are provided as input
%       
%       yPts: a vector of y coordinates for points at which the s and t
%         coordinates are provided as input
%       
%       hPts: a vector of headings for points at which the s and t
%         coordinates are provided as input
%
%
% DEPENDENCIES:
%
%      fcn_ParseXODR_extractXYfromSTCurves
%
% EXAMPLES:
%
%       See the script: script_test_fcn_ParseXODR_extractXYfromSTandGeometries.m for
%       a full test suite.
%
% This function was originally written by C. Beal (cbeal@bucknell.edu) as
% fcn_RoadSeg_findXYfromSTandSegment, rewritten by S. Brennan
% Questions or comments? sbrennan@psu.edu

% Revision history:
% 2022_03_20 - C. Beal
% -- wrote the code as fcn_RoadSeg_findXYfromSTandSegment
% 2024_03_21 - S. Brennan
% -- renamed function
% -- added debug header
% -- added fig_num input and fast input check
% -- added plotting, debug, and function areas


%% Debugging and Input checks

% Check if flag_max_speed set. This occurs if the fig_num variable input
% argument (varargin) is given a number of -1, which is not a valid figure
% number.
flag_max_speed = 0;
if (nargin==4 && isequal(varargin{end},-1))
    flag_do_debug = 0; % Flag to plot the results for debugging
    flag_check_inputs = 0; % Flag to perform input checking
    flag_max_speed = 1;
else
    % Check to see if we are externally setting debug mode to be "on"
    flag_do_debug = 0; % Flag to plot the results for debugging
    flag_check_inputs = 1; % Flag to perform input checking
    MATLABFLAG_PARSEXODR_FLAG_CHECK_INPUTS = getenv("MATLABFLAG_PARSEXODR_FLAG_CHECK_INPUTS");
    MATLABFLAG_PARSEXODR_FLAG_DO_DEBUG = getenv("MATLABFLAG_PARSEXODR_FLAG_DO_DEBUG");
    if ~isempty(MATLABFLAG_PARSEXODR_FLAG_CHECK_INPUTS) && ~isempty(MATLABFLAG_PARSEXODR_FLAG_DO_DEBUG)
        flag_do_debug = str2double(MATLABFLAG_PARSEXODR_FLAG_DO_DEBUG);
        flag_check_inputs  = str2double(MATLABFLAG_PARSEXODR_FLAG_CHECK_INPUTS);
    end
end

if flag_do_debug
    st = dbstack; %#ok<*UNRCH>
    fprintf(1,'STARTING function: %s, in file: %s\n',st(1).name,st(1).file);
    debug_fig_num = 34838; %#ok<NASGU>
else
    debug_fig_num = []; %#ok<NASGU>
end


%% check input arguments
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   _____                   _
%  |_   _|                 | |
%    | |  _ __  _ __  _   _| |_ ___
%    | | | '_ \| '_ \| | | | __/ __|
%   _| |_| | | | |_) | |_| | |_\__ \
%  |_____|_| |_| .__/ \__,_|\__|___/
%              | |
%              |_|
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=Inputs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if 0==flag_max_speed
    if flag_check_inputs == 1
        % Are there the right number of inputs?
        narginchk(2,4);

        % % Check the left_or_right_or_center input to be a string
        % if ~isstring(left_or_right_or_center) &&  ~ischar(left_or_right_or_center)
        %     error('The left_or_right_or_center input must be a string or character type');
        % end

    end
end

% Does user want to specify tPts?
tPts = []; 
if (3<= nargin)
    temp = varargin{1};
    if ~isempty(temp)
        tPts = temp;
    end
end
% If user did not enter the points, then use 0
if isempty(tPts)
    tPts = 0*stationPoints;
end
% Make sure tPts is correct length
if 0==flag_max_speed
    if flag_check_inputs == 1
        if length(tPts(:,1))~=length(stationPoints(:,1))
            error('Transverse points must be same length as the station points.');
        end
    end
end


% Does user want to specify fig_num?
fig_num = []; % Default is to have no figure
flag_do_plots = 0;
if (0==flag_max_speed) && (4<= nargin)
    temp = varargin{end};
    if ~isempty(temp)
        fig_num = temp;
        flag_do_plots = 1;
    end
end


%% Main code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   __  __       _
%  |  \/  |     (_)
%  | \  / | __ _ _ _ __
%  | |\/| |/ _` | | '_ \
%  | |  | | (_| | | | | |
%  |_|  |_|\__,_|_|_| |_|
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Enumerate some constants for later convenience and code readability
E = 1; 
N = 2;


% Initialize X and Y points
xPts = nan(size(tPts));
yPts = nan(size(tPts));
hPts = nan(size(tPts));

% Get the geometry information for the geometry segment within which the
% object is located
p0 = [str2double(geomElement.Attributes.x), str2double(geomElement.Attributes.y)];

% Fill in initial values
x0 = p0(E);
y0 = p0(N);
h0 = str2double(geomElement.Attributes.hdg);
s0 = str2double(geomElement.Attributes.s);
l0 = str2double(geomElement.Attributes.length);

initial_values = [x0 y0 h0 s0 l0];


% TO-DO: FIX THE LOOP ONCE THE FUNCTIONS ARE VECTORIZED
for ith_transverse = 1:length(tPts(1,:))
    St_coordinates = [stationPoints, tPts(:,ith_transverse)];

    % Determine the type of road geometry element is being referenced, and call
    % the function to determine the X,Y coordinates from the S,T coordinates
    % with the proper arguments
    if isfield(geomElement,'line')
        [xPts(:,ith_transverse),yPts(:,ith_transverse),hPts(:,ith_transverse)] = fcn_ParseXODR_extractXYfromSTCurves('line',initial_values,St_coordinates);
    elseif isfield(geomElement,'arc')
        K0 = str2double(geomElement.arc.Attributes.curvature);
        [xPts(:,ith_transverse),yPts(:,ith_transverse),hPts(:,ith_transverse)]  = fcn_ParseXODR_extractXYfromSTCurves('arc',initial_values,St_coordinates,[K0 0]);
    elseif isfield(geomElement,'spiral')
        K0 = str2double(geomElement.spiral.Attributes.curvStart);
        KF = str2double(geomElement.spiral.Attributes.curvEnd);
        [xPts(:,ith_transverse),yPts(:,ith_transverse),hPts(:,ith_transverse)]  = fcn_ParseXODR_extractXYfromSTCurves('spiral',initial_values,St_coordinates,[K0,KF]);
    else
        fprintf(1,'Road segment type not handled by fcn_ParseXODR_extractXYfromSTandGeometries()\n');
    end
end

%% Plot the results (for debugging)?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   _____       _
%  |  __ \     | |
%  | |  | | ___| |__  _   _  __ _
%  | |  | |/ _ \ '_ \| | | |/ _` |
%  | |__| |  __/ |_) | |_| | (_| |
%  |_____/ \___|_.__/ \__,_|\__, |
%                            __/ |
%                           |___/
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if flag_do_plots
    temp_h = figure(fig_num);
    flag_rescale_axis = 0;
    if isempty(get(temp_h,'Children'))
        flag_rescale_axis = 1;
    end

    hold on;
    grid on;
    axis equal

    % Grab colors to use
    try
        color_ordering = orderedcolors('gem12');
    catch
        color_ordering = colororder;
    end    
    N_colors = length(color_ordering(:,1)); 

    % Set up labels and title
    xlabel('East (m)')
    ylabel('North (m)')
    title('XY view')

    % Plot road reference line in solid blue
    roadStationPoints = (min(stationPoints):0.1:max(stationPoints))';    
    [xPts_roadReferenceLine,yPts_roadReferenceLine] = fcn_ParseXODR_extractXYfromSTandGeometries(geomElement, roadStationPoints);
    plot(xPts_roadReferenceLine,yPts_roadReferenceLine,'b-','LineWidth',3);

    % Plot the results as dots
    for ith_column = 1:length(xPts(1,:))
        % Get current color
        current_color = color_ordering(mod(ith_column,N_colors)+1,:); %#ok<NASGU>

        % Plot results as dots
        plot(xPts(:,ith_column),yPts(:,ith_column),'.','MarkerSize',30); % ,'Color',current_color);
    end

    
    % Make axis slightly larger?
    if flag_rescale_axis
        temp = axis;
        %     temp = [min(points(:,1)) max(points(:,1)) min(points(:,2)) max(points(:,2))];
        axis_range_x = temp(2)-temp(1);
        axis_range_y = temp(4)-temp(3);
        percent_larger = 0.3;
        axis([temp(1)-percent_larger*axis_range_x, temp(2)+percent_larger*axis_range_x,  temp(3)-percent_larger*axis_range_y, temp(4)+percent_larger*axis_range_y]);
    end    

end % Ends check if plotting

if flag_do_debug
    fprintf(1,'ENDING function: %s, in file: %s\n\n',st(1).name,st(1).file);
end

end % Ends main function

%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   ______                _   _
%  |  ____|              | | (_)
%  | |__ _   _ _ __   ___| |_ _  ___  _ __  ___
%  |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
%  | |  | |_| | | | | (__| |_| | (_) | | | \__ \
%  |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%§