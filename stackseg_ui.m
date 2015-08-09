function [ output_args ] = stackseg_ui( filename )
%stackseg segments frames of a 4D (X,Y,Z,Color) stack and outputs the
%resulting stack with digital color notation. The segmentation is
%semi-automated.
%   Detailed explanation goes here

%% Initiation

% Use gui to find the filename if not provided
if nargin < 1
    [filename, filepath] = uigetfile('*.tif');
end

filename = fullfile(filepath,filename);

% Read the metadata of the stack
metadata = imfinfo(filename);

% Reduce metadata to a string
metadata = metadata(1).ImageDescription;

% Find the number of channels in the stack
channelinfo = strfind( metadata , 'channels=' );
n_channels = str2double( metadata( channelinfo + 9 ) );

% If no channel info, assume 1 channel.
if isnan(n_channels)
    n_channels = 1;
end

% Find the number of slics in the stack
sliceinfo = strfind( metadata , 'slices=');
n_slices = str2double( metadata( sliceinfo + 7 : sliceinfo + 8 ));

% Start from the first slice
currentslice = 1;

% Prime a vector of threshold modifiers
thresh_mod = ones(n_slices , 1);

% Read the left image and convert it to double
left_image = mat2gray( imread( filename , currentslice ));

% Find the unmodified threshold
def_thresh = graythresh (left_image);

% Apply the threshold in to initial segmentation and display the result in
% the right panel.
right_image = im2bw(left_image, thresh_mod(currentslice) * def_thresh);

% Create the figure
hFig = figure('Toolbar','none',...
              'Menubar','none',...
              'Name','Stack Segmentation Tool',...
              'NumberTitle','off',...
              'IntegerHandle','off',...
              'Position',[ 250 , 50 , 1100 , 650 ]);
          
% Display left image              
subplot( 121 )  
hImL = imshow( left_image , [] , 'colormap' , jet);

% Display right image
subplot( 122 )
hImR = imshow( right_image , [] , 'colormap' , jet);

% Create a scroll panel for left image
hSpL = imscrollpanel( hFig , hImL );
set(hSpL,'Units','normalized',...
    'Position',[ 0 0.1 .5 0.9 ])

% Create scroll panel for right image
hSpR = imscrollpanel( hFig , hImR );
set(hSpR,'Units','normalized',...
    'Position',[ 0.5 0.1 .5 0.9 ])

%% Magnification
% Add a magnification box 
hMagBox = immagbox( hFig , hImL );
pos = get( hMagBox , 'Position' );
set( hMagBox , 'Position' , [ 51 0 pos(3) pos(4) ])

% Add a magnification slider
uicontrol('Style', 'slider',...
        'Min', 0.5, 'Max', 5, 'Value', 1,...
        'Position', [ 110 00 300 20 ],...
        'Callback', @magnify);
    
% Add a text for the magnification slider
uicontrol('Style', 'text', 'Position', [ 0 , 0 , 50 , 19 ], 'String','Zoom:')

%% Segmentation
% Add a threshold box 
hThreshBox = uicontrol('style','edit',...
    'Position', [ 51 21 pos(3) 20 ],...
    'String','100%');

% Add a threshold slider
hThreshSlider = uicontrol('Style', 'slider',...
        'Min', 0.05, 'Max', 15, 'Value', 1,...
        'Position', [ 110 21 300 20 ],...
        'Callback', @updatethresh);
    
% Add a text for the threshold slider
uicontrol('Style', 'text', 'Position', [ 0 21 50 19 ], 'String', 'Tresh:')

%% Navigation
% Add a navigation box
hNavBox = uicontrol('style','edit',...
    'Position',[ 51 42 pos(3) 20 ],...
    'String','1');

% Add a navigation slider
uicontrol('Style', 'slider',...
        'Min',1,'Max',n_slices,'Value',1,...
        'Position', [ 110 42 300 20 ],...
        'SliderStep',[1/(n_slices-1) ,1/(n_slices-1)],...
        'Callback', @updatenavigate);
    
% Add a text for the navigation slider
uicontrol('Style', 'text', 'Position', [ 0 42 50 19 ], 'String','Slice:')


%% Output
% Add an output button
uicontrol('Style', 'pushbutton',...
    'Position', [ 1000 0 100 60 ],...
    'String','Generate',...
    'Callback', @generateoutput);

%% Callbacks
    function magnify(source,~)
        % Use a slide bar to control the magnificaiotn of the image
        apiL.setMagnification( get( source, 'Value' ));
    end

    function updatethresh(source,~)
        % Use a slide bar to control the threshold of the right image
        setthresh = get(source,'Value');
        
        % Update the threshold in the thresh vector
        thresh_mod(currentslice) = setthresh;
        
        % Update the value in the box
        set(hThreshBox,'String', [ num2str( setthresh * 100 ), '%']);
        
        % Apply the threshold modifier
        right_image = im2bw(left_image, setthresh * def_thresh);
        
        % Update the image
        set(hImR, 'CData', right_image);
        
    end

    function updatenavigate(source,~)
        % Use a slide bar to control the slice navigation
        currentslice = round(get(source,'Value'));
        
        % Recify the slider value to a integer
        set(hThreshSlider, 'Value', currentslice);
        
        % Update the value in the box
        set(hNavBox,'String',num2str(currentslice));
        
        % Update threshold slider and box
        setthresh = thresh_mod( currentslice );
        set(hThreshSlider, 'Value', setthresh);
        set(hThreshBox, 'String', [ num2str( setthresh * 100 ), '%' ]);
        
        % Update the left image
        left_image = mat2gray( imread( filename,...
            ( currentslice - 1 ) * n_channels + 1));
        
        % Find the unmodified threshold
        def_thresh = graythresh (left_image);
        
        % Update the right image
        right_image = im2bw(left_image, thresh_mod(currentslice) * def_thresh);
        
        % Update the panels
        set(hImL,'CData',left_image);
        
        set(hImR,'CData',right_image);
              
    end

    function generateoutput(~,~)
        % Output the modifer vector
        assignin('base','threshold_modifers', thresh_mod);
    end
%% Add an Overview tool
imoverview(hImL) 

%% Get APIs from the scroll panels 
apiL = iptgetapi(hSpL);
apiR = iptgetapi(hSpR);

%% Synchronize left and right scroll panels
apiL.setMagnification(apiR.getMagnification())
apiL.setVisibleLocation(apiR.getVisibleLocation())

% When magnification changes on left scroll panel, 
% tell right scroll panel
apiL.addNewMagnificationCallback(apiR.setMagnification);

% When magnification changes on right scroll panel, 
% tell left scroll panel
apiR.addNewMagnificationCallback(apiL.setMagnification);

% When location changes on left scroll panel, 
% tell right scroll panel
apiL.addNewLocationCallback(apiR.setVisibleLocation);

% When location changes on right scroll panel, 
% tell left scroll panel
apiR.addNewLocationCallback(apiL.setVisibleLocation);
end

