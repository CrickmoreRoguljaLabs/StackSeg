[filename, filepath] = uigetfile('*.tif');

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

newdata = boolean(zeros(1024,1024,20));

for i = 1:n_slices
    im = mat2gray(imread(filename,(i-1)*n_channels+1));
    
    thisthresh = threshold_modifers(i) * graythresh(im);
    
    newdata(:,:,i)=im2bw(im,thisthresh);
    
    imwrite(newdata(:, :, i), 'test.tif', 'WriteMode', 'append','Compression','none');
    
    
end