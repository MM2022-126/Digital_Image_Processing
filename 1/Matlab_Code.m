                    % 1

                    % Capturing frames from video


vid_path = input("Enter video path: ");
vid_src = VideoReader(vid_path);
f_count = 1;

tot_width = 0;
tot_height = 0;

while hasFrame(vid_src)
    frame = readFrame(vid_src);
    gray_frame = rgb2gray(frame);

    tot_width = tot_width + width(gray_frame);
    tot_height = tot_height + height(gray_frame);

    imwrite(gray_frame, sprintf("D://Assignments//DIP//Frames//frame_%04d.jpg", f_count));
    f_count = f_count + 1;
end

avg_width = tot_width / f_count;
avg_height = tot_height / f_count;

fprintf('Each Frame Width: %d\n', tot_width);
fprintf('Each Frame Height: %d\n', tot_height);

fprintf('Frame extraction and grayscale conversion completed. Total frames: %d\n', f_count);


                    % 2

                    % Applying Averaging filter 


out_vid = VideoWriter("D://Assignments//DIP//Averaging_Output.mp4", 'MPEG-4');
open(out_vid);

while hasFrame(vid_src)
    frame = readFrame(vid_src);
    gray_frame = double(rgb2gray(frame));
    [rows, cols] = size(gray_frame);

    for i = 3:rows-2
        for j = 3:cols-2  % 5x5 Average Mask
            patch = gray_frame(i-2: i+2, j-2: j+2);
            pixel_val = round(sum(sum(patch)) / 25);
            gray_frame(i, j) = pixel_val;
        end
    end
    proc_frame = uint8(gray_frame);
    writeVideo(out_vid, proc_frame);
end

close(out_vid);
implay("D://Assignments//DIP/Averaging_Output.mp4", vid_src.FrameRate);


                    % 5

                    % Removing noise from video through median filter

f_size = input('Enter filter size for median filter (3, 5, 7, 9, or 11): ');
applyMedFilter(f_size);

function applyMedFilter(f_size)
    % Read input video
    noisy_vid_path = input("Enter the noisy video: ");
    noisy_vid_src = VideoReader(noisy_vid_path);
    
    % Creating output video writer
    filt_vid = VideoWriter("D://Assignments//DIP/MedianFilteredVideo.mp4", 'MPEG-4');
    open(filt_vid);
    
    % Defining the time range for filtering (2 to 4 seconds)
    noise_start = 2;
    noise_end = 4;
    
    % Process each frame
    while hasFrame(noisy_vid_src)
        frame = readFrame(noisy_vid_src);
        curr_time = noisy_vid_src.CurrentTime;
        
        gray_frame = double(rgb2gray(frame));
        [rows, cols] = size(gray_frame);
        filt_frame = zeros(rows, cols);
        
        % Applying median filter only if within the noise duration
        if curr_time >= noise_start && curr_time <= noise_end
            f_half = (f_size - 1) / 2;
            for i = (1 + f_half):(rows - f_half)
                for j = (1 + f_half):(cols - f_half)
                    patch = gray_frame(i - f_half:i + f_half, j - f_half:j + f_half);
                    sorted_patch = sort(patch(:));
                    median_idx = round(numel(sorted_patch) / 2);
                    filt_frame(i, j) = sorted_patch(median_idx);
                end
            end
        else
            filt_frame = gray_frame;
        end
        
        % Converting to uint8 to save the video
        filt_frame = uint8(filt_frame);
        writeVideo(filt_vid, filt_frame);
    end
    
    % Close the output video
    close(filt_vid);
    
    % Play the output video
    implay("D://Assignments//DIP/MedianFilteredVideo.mp4", noisy_vid_src.FrameRate);
end

