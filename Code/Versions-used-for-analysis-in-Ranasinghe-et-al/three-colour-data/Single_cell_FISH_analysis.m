% PURPOSE: Calculates intensities for two- or three-colour FISH experiments with
% using wide-field images of single labelled bacteria
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% published in:
% Ranasinghe et al., Nat Commun, 2017 "Detecting RNA base methylations in single 
% cells by in situ hybridization"
%
% This code can analyse single data sets or a series of datasets organised in folders.
% For more information on the code and how to run it, please refer to the
% README file.
%
% Please cite our publication if you use or re-purpose our code!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all;
close all;
addpath('./source codes');

global n n2;

%% open dialogue for manual input of parameters and add general parameters
[parameters] = parameter_setup;
[parameters] = parameter_setup_auto(parameters);

%% ask whether multiple dataset are to be analysed

[isbatch,path] = run_batch;

%% extract number of folders to be analysed and their individual paths
% (or set number to 1 if single dataset is analysed and prompt for path)
if isbatch == 1
    [folders2analyse,root_directory] = getfolderstoanalyse(path);
    number_of_samples = length(folders2analyse);   
else
    folders2analyse = 1;
    number_of_samples = 1; %both variables are the same because no
    % normalisation is required for single sample
    %stacks_directory = uigetdir('');
    stacks_directory = 'C:\';
    %this variable can also be set to a fixed path so it does not require
    %GUI input; e.g. stacks_directory = 'C:\Users\DataToAnalyse';
end

% inialise variables before iterating over the datasets

glassorcell = 1;
all_bluevector = [];
total_mean=[];
total_stdev = [];
batchsave = [];

%pre-allocation of variables for batch mode:
if isbatch == 1
collect_n = zeros(1,number_of_samples);
collect_frames = zeros(1,number_of_samples);
collect_n_red = zeros(1,number_of_samples);
collect_n_blue = zeros(1,number_of_samples);
label = cell(1,number_of_samples);
ampli_gof = cell(1,number_of_samples);
ampli_fitres = cell(1,number_of_samples);
lnZ_AND_ampli = cell(1,number_of_samples);
all_red_ampli_collected = cell(1,number_of_samples);
all_blue_ampli_collected = cell(1,number_of_samples);
all_yellow_ampli_collected = cell(1,number_of_samples);
lnZ_hist_counts = cell(1,number_of_samples);
lnZ_hist_freq = cell(1,number_of_samples);
end

%% iterate over all datasets to be anlysed
for n2=1:number_of_samples
    
    
    %% create saving directory for the given dataset and path to current folder
    if iscell(folders2analyse) == 1
        
        stacks_directory = strcat(root_directory,'\',folders2analyse{n2});
        [save_name,fig_name,batchsave]= make_directory(parameters.exp_name,folders2analyse{n2},batchsave,parameters.loc4dir);
        
    else
        
        [save_name,fig_name]= make_directory(parameters.exp_name,cell(1,1),batchsave,parameters.loc4dir);
        
    end
    
    if parameters.nocolours == 2
        
        [red_files,blue_files] = get_tiffs(parameters,stacks_directory);
        Lstack = length(red_files);
        
        %% calculate offset if GUI was set accordingly; use the mean value derived from previous measurements if calculation fails
        % (separate step from the subsequent image manipulations (extra for loop over all images)
        
        if parameters.offsetcorr == 1
            [parameters,offset_temp,offset_turn_temp] = calculate_offsets(parameters,stacks_directory,red_files,blue_files,Lstack);
        end
        
        
        
    else
        
        [red_files,blue_files,yellow_files] = get_tiffs_threecolours(parameters,stacks_directory);
        Lstack = length(red_files);
        yellow = cell(Lstack,1);
       
        
    end
    
    
    
    
    %inialise variables before looping over the individual images of a
    %dataset
    blue = cell(Lstack,1);
    red = cell(Lstack,1);
    Results_blue = cell(Lstack,1);
    Results_red = cell(Lstack,1);
    xyAI_red = cell(Lstack,1);
    xyAI_blue = cell(Lstack,1);
    xyAI_yellow = cell(Lstack,1);
    start_point_cell = zeros(Lstack,1);
    red_spot_index = ones(Lstack,1)*-1;
    blue_spot_index = ones(Lstack,1)*-1;
    yellow_spot_index = ones(Lstack,1)*-1;
    coloc_spots = cell(Lstack,1);
    coloc_pos = cell(Lstack,1);
    coloc_spots_y = cell(Lstack,1);
    coloc_pos_y = cell(Lstack,1);
    all_blueintAND = [];
    all_redintAND = [];
    all_yellowintAND = [];
    results = cell(Lstack,1);
    number_of_spots = cell(Lstack,1);
    
%% iterate over the individual images of the dataset n2:
    
    for n = 1:Lstack,
        
        %% read in image data (automatic selection) and correct channel offset if required
        
        if  ~isempty(red_files{n})
            
            % display file index for analysed file in the command line
            disp(strcat('Analysing File ',num2str(n), ' of ',num2str(Lstack)))
            
            %read in image data from tiff files (single image data)
            [both_colours_red] = read_data(stacks_directory,red_files{n});
            [both_colours_blue] = read_data(stacks_directory,blue_files{n});
            
            if parameters.nocolours == 3
                [yellow{n}] = read_data_threecolours(stacks_directory,yellow_files{n});
                [red{n}] = read_data_threecolours(stacks_directory,red_files{n});
                [blue{n}] = read_data_threecolours(stacks_directory,blue_files{n});
                
            else
                
                nImage = 1;
                
                close all;
                
                % this step crops the image to the region to be analysed - this
                % will probably need to be customised!
                
                [red_temp,~] = select_region_fullchip(both_colours_red,parameters.image_width,nImage);
                [~,blue_temp] = select_region_fullchip(both_colours_blue,parameters.image_width,nImage);
                
                %if there is no offset correction between the two channels, x_start = 15; x_end = 250; y_start = 30; y_end = 480 for all images
                %otherwise, offset correction is applied in this step to obtain
                %the same coordinates in both channels
                
                [red{n},blue{n},results{n}.x_start3, results{n}.x_end3, results{n}.y_start3, results{n}.y_end3, start_point_cell(n)] = select_region_auto_shiftcorr_optionalBAC(red_temp,blue_temp,nImage,parameters,n);
                %variables "red" and "blue" are cell arrays, cell i contains
                %blue or red image i as a matrix, offset corrected and cropped
                
                % since the index goes by the index number of the image files, and files may be deleted to bad data
                % quality, entries can be empty, in this case an empty matrix is added
            end
            if isempty(red{n})
                
                red_files{n} = [];
                blue_files{n} = [];
            end
            
        end
        
        
        
        %% detect cells in both channels (blue, red) and collect information
        
        if  ~isempty(red_files{n})
            
            if parameters.or == 1
                %generate mask / identify cells from both channels and overlay them ("OR" criterion for cell selection)
                [mask] = createBinaryMask(red{n},blue{n},parameters);
                
                
            elseif parameters.or == 2
                %generate mask / identify cells from red channel only (signal from blue channel ignored for cell selection)
                [mask] = createBinaryMaskRedOnly(red{n},parameters);
            end
            
            % in both cases ("OR" and "REDONLY"), the following function
            % extracts information for each cell (mask element)
            % xyAI_(blue/red) is 1xLstack cell containing each a 5xi matrix
            % where i is the number of cells identified in the current
            % image n; in the matrix
            % (:,1-2) is the xy position, (:,3) is the area (pixel),(:,4) intensity and (:,5) intensity corrected
            % for local background
            % cells whose areas are below the size threshold are discarded
            % in this step
            
            if parameters.or == 1 || parameters.or == 2
                
                if parameters.sizethresboolean == 1
                    [xyAI_red{n}]  = extract_int_per_cell_SingleThres(red{n},parameters,fig_name,'r',mask);
                    [xyAI_blue{n}]  = extract_int_per_cell_SingleThres(blue{n},parameters,fig_name,'b',mask);
                    
                    if parameters.nocolours == 3
                        [xyAI_yellow{n}]  = extract_int_per_cell_SingleThres(yellow{n},parameters,fig_name,'b',mask);
                        
                    end
                    
                else
                    % cells whose areas are larger than a second size threshold are also discarded
                    [xyAI_red{n},bacs2keep]  = extract_int_per_cell(red{n},parameters,fig_name,'r',mask);
                    [xyAI_blue{n}]  = extract_int_per_cell(blue{n},parameters,fig_name,'b',mask,xyAI_red{n},bacs2keep);
                    
                    if parameters.nocolours == 3
                        
                        [xyAI_yellow{n}]  = extract_int_per_cell(yellow{n},parameters,fig_name,'b',mask,xyAI_red{n},bacs2keep);
                        
                    end
                end
                
            else
                % generate mask / identify cells from each channel individually and collect data -> at later stage, cells are only
                % kept if they appear in both channels ("AND" criterion for cell selection)
                % extract cell information as for OR criterion
                
                if parameters.sizethresboolean == 1
                    
                    [xyAI_red{n}]  = extract_int_per_cell_SingleThres(red{n},parameters,fig_name,'r');
                    [xyAI_blue{n}]  = extract_int_per_cell_SingleThres(blue{n},parameters,fig_name,'b');
                    
                    
                else
                    
                    [xyAI_red{n},bacs2keep]  = extract_int_per_cell(red{n},parameters,fig_name,'r');
                    [xyAI_blue{n}]  = extract_int_per_cell(blue{n},parameters,fig_name,'b',bacs2keep);
                    
                    
                    
                end
            end
            
            
            %% COLOCALISATION - find cells that are present in both channels:
            
            % get number of cells detected for each channel, waste is the
            % dimension in which the coordinates etc per spot are listed (always 5)
            
            resred = xyAI_red{n}(:,1:2);
            resblue = xyAI_blue{n}(:,1:2);
            if isempty(resred)
                number_of_spots{n}.red = 0;
            elseif resred(1,1) ~= 0
                number_of_spots_1 = size(resred);
                number_of_spots{n}.red = number_of_spots_1(1);
            else
                number_of_spots{n}.red = 0;
            end
            if  isempty(resblue)
                number_of_spots{n}.blue = 0;
            elseif resblue(1,1) ~= 0
                number_of_spots_1 = size(resblue);
                number_of_spots{n}.blue = number_of_spots_1(1);
            else
                number_of_spots{n}.blue = 0;
            end
            
            
            
            % calculate distances and find colocalised spots, output the
            % total count and the positions of the colocalised spots
            
            if number_of_spots{n}.red ~= 0 && number_of_spots{n}.blue ~= 0
                [coloc_spots{n},coloc_pos{n}] = get_spot_distances(resred,resblue,parameters,number_of_spots{n},'b');
            else
                coloc_spots{n} = ones(parameters.maxD,1)*-1;
                coloc_pos{n} = cell(parameters.maxD,1);
            end
            
            if parameters.nocolours == 3
                
                resyellow = xyAI_yellow{n}(:,1:2);
                
                if  isempty(resyellow)
                    number_of_spots{n}.yellow = 0;
                elseif resyellow(1,1) ~= 0
                    number_of_spots_1 = size(resyellow);
                    number_of_spots{n}.yellow = number_of_spots_1(1);
                else
                    number_of_spots{n}.yellow = 0;
                end
                
                
                if number_of_spots{n}.red ~= 0 && number_of_spots{n}.yellow ~= 0
                    [coloc_spots_y{n},coloc_pos_y{n}] = get_spot_distances(resred,resyellow,parameters,number_of_spots{n},'y');
                else
                    coloc_spots_y{n} = ones(parameters.maxD,1)*-1;
                    coloc_pos_y{n} = cell(parameters.maxD,1);
                end
                
                yellow_spot_index(n) = number_of_spots{n}.yellow;
                [~, yellowintAND] = int4colocBACS(coloc_pos_y{n}{parameters.coloc_bin},xyAI_red{n},xyAI_yellow{n});
                
                
                
            end
            
            
            
            
            
            % collect counted cells for current images in a matrix format
            red_spot_index(n) = number_of_spots{n}.red;
            blue_spot_index(n) = number_of_spots{n}.blue;
            
            % extract intensities for colocalised spots (separate vectors for red and blue) so that every row of
            % the vector corresponds to a specific cell; the background
            % corrected intensity is used as a default
            [redintAND, blueintAND] = int4colocBACS(coloc_pos{n}{parameters.coloc_bin},xyAI_red{n},xyAI_blue{n});
            
            
            % concatenate vectors to create one intensity vector for all
            % images analysed in a sample
            
            all_blueintAND = [all_blueintAND;blueintAND];
            all_redintAND = [all_redintAND;redintAND];
            if parameters.nocolours == 3
            all_yellowintAND = [all_yellowintAND;yellowintAND];
            end
        end
        close all;
    end
    
    if parameters.nocolours == 2
        %% create colocalisation statistics (only interesting for "AND" criterion
        
        [total_coloc_events,coloc_events,coloc_mean,coloc_std,coincidence_blue, coincidence_red] = form_histogram_coloc(coloc_spots,parameters,Lstack,red_spot_index,blue_spot_index);
        
        %save colocalisation statistics in text file if desired
        %csvwrite(strcat(save_name,'_colocalisation_events_total','.dat'),total_coloc_events);
        %csvwrite(strcat(save_name,'_colocalisation_events_individual','.dat'),coloc_events);
        
        plot_histogram(parameters.distance_bin,coloc_mean,coloc_std,'blue',parameters.exp_name,save_name,parameters.maxD);
        plot_histogram(parameters.distance_bin,coloc_mean,coloc_std,'red',parameters.exp_name,save_name,parameters.maxD);
        
        save_histogram(save_name,parameters.distance_bin,coloc_mean,coloc_std,'blue')
        save_histogram(save_name,parameters.distance_bin,coloc_mean,coloc_std,'red')
        
        
        
        
        
        %% create and plot histgrams of the ratios of the two channels (red/blue)
        % information is saved both in matrices / variables (fit results) and
        % plots (.fig files)
        
        if parameters.or == 0
            [ampli_gof{n2},ampli_fitres{n2},lnZ_AND_ampli{n2}, all_red_ampli_collected{n2},all_blue_ampli_collected{n2},lnZ_hist_counts{n2},lnZ_hist_freq{n2}] = plot_ratio_histgrams(all_blueintAND,all_redintAND,'lnZ',save_name,'AND');
        elseif parameters.or == 1    
            [ampli_gof{n2},ampli_fitres{n2},lnZ_AND_ampli{n2}, all_red_ampli_collected{n2},all_blue_ampli_collected{n2},lnZ_hist_counts{n2},lnZ_hist_freq{n2}] = plot_ratio_histgrams(all_blueintAND,all_redintAND,'lnZ',save_name,'OR');
        else
            [ampli_gof{n2},ampli_fitres{n2},lnZ_AND_ampli{n2}, all_red_ampli_collected{n2},all_blue_ampli_collected{n2},lnZ_hist_counts{n2},lnZ_hist_freq{n2}] = plot_ratio_histgrams(all_blueintAND,all_redintAND,'lnZ',save_name,'dect red channel only');
        
        end
        
        
        
        
        
        %% create histograms of all intensities for the individual channels
        
        
        plot_save_histogram_int(all_blueintAND,'blue',save_name,folders2analyse);
        plot_save_histogram_int(all_red_ampli_collected{n2},'red',save_name,folders2analyse);
        
        %% save some information extracted from the data in the form of text files:
        dlmwrite(strcat(save_name,'_intensities_for_blue.txt'),all_blue_ampli_collected{n2});
        dlmwrite(strcat(save_name,'_intensities_for_red.txt'),all_red_ampli_collected{n2});
        dlmwrite(strcat(save_name,'_numbers_of_bacs_detected_in_red.txt'),red_spot_index);
        dlmwrite(strcat(save_name,'_numbers_of_bacs_detected_in_blue.txt'),blue_spot_index);
        
        % collect information for sample if multiple samples are analysed to be able
        % to access the information easily for all samples in one variable/file
        
        if isbatch == 1
            collect_n(n2) = total_coloc_events(parameters.coloc_bin);
            collect_frames(n2) = Lstack;
            collect_n_red(n2) = sum(red_spot_index);
            collect_n_blue(n2) = sum(blue_spot_index);
            label{n2} = folders2analyse{n2};
            save(strcat(save_name,'workspace.mat'));
            
        end
        
        %% make scatterplot of red versus blue intensities -
        % intensities plotted here that are 0 will be discarded when the ratio is calculated later
        
        figure;scatterhist(all_red_ampli_collected{n2},all_blue_ampli_collected{n2});
        title('2D Scatterplot of fluoresence intensities')
        xlabel('red');
        ylabel('green');
        saveas(gcf,strcat(save_name,'_Scatterplot_intensities','.fig'), 'fig');
        
        
        
    else
        dlmwrite(strcat(save_name,'_intensities_for_blue.txt'),all_blueintAND);
        dlmwrite(strcat(save_name,'_intensities_for_red.txt'),all_redintAND);
        dlmwrite(strcat(save_name,'_intensities_for_yellow.txt'),all_yellowintAND);
        dlmwrite(strcat(save_name,'_numbers_of_bacs_detected_in_red.txt'),red_spot_index);
        dlmwrite(strcat(save_name,'_numbers_of_bacs_detected_in_blue.txt'),blue_spot_index);
        dlmwrite(strcat(save_name,'_numbers_of_bacs_detected_in_yellow.txt'),yellow_spot_index);
        save(strcat(save_name,'completeworkspace.mat'));
        
        [ampli_gof{n2},ampli_fitres{n2},lnZ_AND_ampli{n2}, all_red_ampli_collected{n2},all_blue_ampli_collected{n2},all_yellow_ampli_collected{n2},lnZ_hist_counts{n2},lnZ_hist_freq{n2}] = calc_ratio_histograms(all_blueintAND,all_redintAND,all_yellowintAND,'lnZ',' not norm',save_name,'OR');
        
    end
    
end

%% Scatter plot of means and std from Gaussian fits across samples in batch mode
% comparison of the distributions obtained in different experiments and
% statistical assessment whether they can be assumed to be different
%
% export of ratios (log(ratios)) and amplitudes collected in an excel
% sheet, grouped by sample
if parameters.nocolours == 2
    if isbatch == 1
        [all_means_ampli,all_std_ampli] = collect_fit_parameters('_fitparameters',ampli_gof,ampli_fitres,folders2analyse,'means and stds for all LnZ distributions',save_name);
        %[all_means_sum,all_std_sum] = collect_fit_parameters('_fitparameters_sum',gof_SUM,fitres_SUM,folders2analyse,'sum',save_name);
        
        save_more_parameters(folders2analyse,save_name,collect_n, collect_frames, collect_n_blue, collect_n_red);
        excel_export_bacs2(folders2analyse,lnZ_AND_ampli,all_red_ampli_collected,all_blue_ampli_collected,lnZ_hist_counts,lnZ_hist_freq,save_name);
    end
    
else
    excel_export_bacs3(folders2analyse,all_blue_ampli_collected,all_red_ampli_collected,all_yellow_ampli_collected,lnZ_hist_counts,lnZ_hist_freq,save_name);
end
%save the workspace again after all samples have been analysed and batch
%calculations are done
save(strcat(save_name,'workspace.mat'));

