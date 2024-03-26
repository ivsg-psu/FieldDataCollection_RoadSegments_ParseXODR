function laneSectionStations = fcn_ParseXODR_extractFromLanes_LaneSectionStations(lanesStructure, roadEndStation, varargin)
%% fcn_ParseXODR_extractFromLanes_LaneSectionStations
% Given a lanes structure, extracts the lane sections start/end stations as a [N x 2]
% vector where row 1 corresponds to the first lane section, row 2 is
% the second section, etc. Each row lists the stations for the geometric
% description as [laneSectionStart laneSectionEnd].
%
% NOTE: The ends of each station are calculated by the "s" parameter
% in the Attributes for each lane offset. By default, the end "s" value in
% an lane section is the starting s-value of the next section. For the
% last section, the offset is the road's end station.
% the end of one segment may not actually be the station for the start of
% the next segment.
%
% FORMAT:
%
%       laneSectionStations = fcn_ParseXODR_extractFromLanes_LaneSectionStations(lanesStructure, roadEndStation, (fig_num))
%
% INPUTS:
%
%      lanes: the lanes subfield for an XODRRoad
%
%      roadEndStation: the station coordinate that ends the road
%      containining this lanes structure
%
% (OPTIONAL INPUTS)
%
%      fig_num: a figure number to plot results. If set to -1, skips any
%      input checking or debugging, no figures will be generated, and sets
%      up code to maximize speed.
%
% OUTPUTS:
%
%       laneSectionStations: a [N x 2] vector where N is the number of
%       laneOffset segments in the lanes, each row is ordered in the sequence
%       of segment 1, segment 2, etc, and each row corresponds to
%       [laneSectionStart laneSectionEnd] for that laneOffset segment
%
%
% DEPENDENCIES:
%
%      (none)
%
% EXAMPLES:
%
%       See the script: script_test_fcn_ParseXODR_extractFromLanes_LaneSectionStations
%       for a full test suite.
%
% This function was by S. Brennan
% Questions or comments? sbrennan@psu.edu

% Revision history:
% 2024_03_24 - S. Brennan
% -- original write of function


%% Debugging and Input checks

% Check if flag_max_speed set. This occurs if the fig_num variable input
% argument (varargin) is given a number of -1, which is not a valid figure
% number.
flag_max_speed = 0;
if (nargin==3 && isequal(varargin{end},-1))
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   _____                   _
%  |_   _|                 | |
%    | |  _ __  _ __  _   _| |_ ___
%    | | | '_ \| '_ \| | | | __/ __|
%   _| |_| | | | |_) | |_| | |_\__ \
%  |_____|_| |_| .__/ \__,_|\__|___/
%              | |
%              |_|
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=Inputs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if 0==flag_max_speed
    if flag_check_inputs == 1
        % Are there the right number of inputs?
        narginchk(2,3);

        % % Check the left_or_right_or_center input to be a string
        % if ~isstring(left_or_right_or_center) &&  ~ischar(left_or_right_or_center)
        %     error('The left_or_right_or_center input must be a string or character type');
        % end

    end
end


% Does user want to specify fig_num?
fig_num = []; % Default is to have no figure
flag_do_plots = 0;
if (0==flag_max_speed) && (3<= nargin)
    temp = varargin{end};
    if ~isempty(temp)
        fig_num = temp;
        flag_do_plots = 1;
    end
end


%% Solve for the circle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   __  __       _
%  |  \/  |     (_)
%  | \  / | __ _ _ _ __
%  | |\/| |/ _` | | '_ \
%  | |  | | (_| | | | | |
%  |_|  |_|\__,_|_|_| |_|
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



% Determine whether there are any offsets to the center lane in the
% current road
if isfield(lanesStructure,'laneSection')
    % Determine the number of lane offset descriptors in the road
    NlaneSection = length(lanesStructure.laneSection);

    % Preallocate a vector for the stations of the geometry element bounds
    laneSectionStations = zeros(NlaneSection,2);

    % Iterate through all of the offset descriptors
    for laneSectionIndex = 1:NlaneSection

        % Determine the start point of the current offset descriptor
        laneSectionStations(laneSectionIndex,1) = str2double(lanesStructure.laneSection{laneSectionIndex}.Attributes.s);

        if laneSectionIndex>1
            % Set the end point of the previous offset descriptor
            laneSectionStations(laneSectionIndex-1,2) = laneSectionStations(laneSectionIndex,1);
        end
    end

    % Set the end station
    laneSectionStations(end,2) = roadEndStation;

else
    laneSectionStations = [0 roadEndStation];
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
    N_colors = length(color_ordering(:,1)); %#ok<NASGU>

    % Set up labels and title
    xlabel('East (m)')
    ylabel('North (m)')
    title('XY view')

    % % Plot road reference line in solid blue
    % roadStationPoints = (min(stationPoints):0.1:max(stationPoints))';
    % [xPts_roadReferenceLine,yPts_roadReferenceLine] = fcn_ParseXODR_extractFromLanes_LaneSectionStations(planView_geometry, roadStationPoints);
    % plot(xPts_roadReferenceLine,yPts_roadReferenceLine,'b-','LineWidth',3);
    %
    % % Plot the results
    % for ith_column = 1:length(xPts(1,:))
    %     % Get current color
    %     current_color = color_ordering(mod(ith_column,N_colors)+1,:);
    %
    %     % Plot results as dots
    %     plot(xPts(:,ith_column),yPts(:,ith_column),'.','MarkerSize',30,'Color',current_color);
    % end

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

