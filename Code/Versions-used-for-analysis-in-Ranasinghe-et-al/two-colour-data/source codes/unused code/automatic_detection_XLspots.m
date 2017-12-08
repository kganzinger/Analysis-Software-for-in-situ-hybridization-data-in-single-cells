%this function filters the image and applys SNR threshold to decide which
%spots represent real particles

function [c_peaks,filtered_image,spot_boundaries,Area,MeanInt4area,Perimeter4area,Perimeter4circle]=automatic_detection(image,parameters,save_dir,type,t,bg4ori)

global n n3
%5 parameters that determine detection
p_mean_in_spot=parameters.mean_in_spot;
p_convergence=parameters.convergence;
p_skewness=parameters.skewness;
p_size=parameters.size;
p_SNR=parameters.SNR;
inithreshold=parameters.initialthreshold;
if strcmp(type,'b') == 1;
    inithreshold = parameters.initialthresholdblue;
end
pkfnd_sz = parameters.pkfnd_sz;
cntrd_sz = parameters.cntrd_sz;


%apply bpass
filtered_image = bpass(image,parameters.lnoise,parameters.lobject);
% filtered_image = normalise_image(filtered_image);

% get background value to define threshold
region4background = 20;
temp4Background = [filtered_image(1:region4background, :); filtered_image(size(filtered_image, 1)-region4background:size(filtered_image, 1), :)];
Background = temp4Background(find(temp4Background>0));
std4BN = std(reshape(Background, prod(size(Background)), 1));
median4BN = median(reshape(Background, prod(size(Background)), 1));
%mean4BN = mean(reshape(Background, prod(size(Background)), 1))
iqr4BN = iqr(reshape(Background, prod(size(Background)), 1));

%if median4BN <= mean4BN   
Background2 = Background(find(Background<(median4BN+(2*iqr4BN))));
%else
%Background2 = Background(find(Background<(mean4BN+3*std4BN)));
%end

std4BN2 = std(reshape(Background2, prod(size(Background2)), 1));
mean4BN2 = mean(reshape(Background2, prod(size(Background2)), 1));
threshold = mean4BN2 + inithreshold*std4BN2;

%find centroid
d_peaks=pkfnd(filtered_image, threshold, pkfnd_sz);
if size(d_peaks,1)>0
    %here the first argument defines the image to which cntrd is applied and should always be the filtered image
    %the second argument of cntrd_laura defines the image for which the SNR
    %is calculated, if its the raw data, the SNR of the raw data is
    %calculated
    
    [c_peaks,spot_boundaries,msk_total,Area,MeanInt4area,Perimeter4area,Perimeter4circle]=cntrd_kristina_XLspots(filtered_image,image,d_peaks, cntrd_sz, 0,bg4ori,t);
    %apply SNR threshold before Gauss Fitting
%     SNR_threshold=zeros(length(SNR),5);
%     c_peaks_threshold=zeros(length(SNR),4);
%     if size(c_peaks,1)>0
%         
%         
%         jj=1;
%         for j=1:size(SNR,1)
%             p1=SNR(j,5);
%             p2=SNR(j,1);
%             if p1 > p_SNR && p2 > 0
%                 SNR_threshold(jj,:)=SNR(j,:);
%                 c_peaks_threshold(jj,:)=c_peaks(j,:);
%                 jj=jj+1;
%             end
%         end
%         SNR_threshold = SNR_threshold(1:jj-1,:);
%         c_peaks_threshold = c_peaks_threshold(1:jj-1,:);
%         
%         
%      
%      else
%          c_peaks = [];
%          SNR_threshold = [];
%          c_peaks_threshold = [];
%         
%         Gauss_param  = [];
%         SNR_Gauss = [];
%         Gaussian_param_threshold = [];
%         SNR_Gauss_threshold = [];
       
end
end
