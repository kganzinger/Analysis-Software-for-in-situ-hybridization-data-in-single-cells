function [Gauss_param,SNR_Gauss,mask_count,output,failedfits]=post_cntrd_Gauss_rcp(im,im_original,dye,c_peaks,parameters)

% Gauss_param:  a N x 9 array containing the result of the Gaussian Fit
%           Gauss_param(:,1) is the x-coordinates
%           Gauss_param(:,2) is the y-coordinates
%           Gauss_param(:,3) is the amplitude
%           Gauss_param(:,4) is FHWM_x
%           Gauss_param(:,5) is FHWM_y
%           Gauss_param(:,6) sigma_x/sigma_y, ratio of ellipse axes;
%           Gauss_param(:,7) fval of fit
%           Gauss_param(:,8) exitflag of fit
%           Gauss_param(:,9) area_ellipse
%           Gauss_param(:,10) window x
%           Gauss_param(:,11) window y
%           Gauss_param(:,12) background(fit)
%           Gauss_param(:,13) amplitude/background(fit)

% SNR_Gauss:  a N x 6 array containing, mean intensity of spot, std of intensity
% of spot, mean intensity of local background, std of intensity
% of local background,SNR=(spot-back)/(sqrt(std_spot^2+std_back^2));
%          SNR_Gauss(:,1) is the mean intensity of spot
%          SNR_Gauss(:,2) is the std of intensity of spot
%          SNR_Gauss(:,3) is the mean intensity of local background
%          SNR_Gauss(:,4) std of intensity of local background
%          SNR_Gauss(:,5) SNR=(spot-back)/(sqrt(std_spot^2,std_back^2));
%          SNR_Gauss(:,6) is the mean intensity of spot - local background
%          SNR_Gauss(:,7) is the dye background



Gauss_param= [];
SNR_Gauss=[];
nmx = size(c_peaks,1);
mask_count = ones(size(im));
failedfits = 0;
exitflag =1;
fval = 1;

for i=1:nmx
    clear tmp*
    % 9x9 pixel window for rcps for 107nm = 428x428 nm, sigma of 1.5 pixel = 160.5nm
    window4gaussfit = round(428/parameters.pixel_size);
    %window4gaussfit = 2;
    sigma0 = round(160.5/parameters.pixel_size);
    
    [x_cor]=round(c_peaks(i,2))-window4gaussfit;
    [y_cor]=round(c_peaks(i,1))-window4gaussfit;
   
    
    %%%%%%%%Gaussian FITTING%%%%%%%%%%%%%%%%%%%
    %Use Gauss-Fitting Function on unfiltered (!) image
   
    tmp4GaussFit=double(im_original((x_cor:x_cor+window4gaussfit*2),(y_cor:y_cor+window4gaussfit*2)));
    %param0 = [window4gaussfit+1,window4gaussfit+1,tmp4GaussFit(window4gaussfit+1,window4gaussfit+1)-2700,sigma0,sigma0,2700];
    %param0 = [window4gaussfit+1,window4gaussfit+1,tmp4GaussFit(window4gaussfit+1,window4gaussfit+1),sigma0,sigma0];
    param_new = [2700,tmp4GaussFit(window4gaussfit+1,window4gaussfit+1)-2700,window4gaussfit+1,sigma0,window4gaussfit+1,sigma0];
    [bestparameters, gof{i},output{i}] = Gaussianfit_kristina(tmp4GaussFit,param_new);
%     [bestparameters, fval,exitflag,output{i}] = Gaussianfit(tmp4GaussFit,param0);
    % bestparameters(6) = 1;
    %Chi^2 test characteristics only 1d, along both directions
    %     [h1,p1,st1] = chi2gof(tmp4GaussFit(:,3));
    %     [h2,p2,st2] = chi2gof(tmp4GaussFit(3,:));
%       figure(10),h = plot(tmp4GaussFit(window4gaussfit,:),'bx');
%       tmp4GaussFit(window4gaussfit,:)
%       set(h,'LineStyle','none');
%       [ny,nx] = size(tmp4GaussFit);
%       [X,Y] = meshgrid(1:nx,1:ny);
%       y_fit = bestparameters(1) + (bestparameters(2)*exp(-(X(1,:)-bestparameters(3)).^2/(2*bestparameters(4)^2)));
%       hold on;
%       
%       plot(X(1,:),y_fit,'or-')
%       hold off;   
%      pause
    %attention, x and y directions in Gaussianfit are changed compared to
    %the centroid fitting
    x_pos=bestparameters(2);
    y_pos=bestparameters(1);
    bestparameters(1)=x_cor+x_pos-1;
    bestparameters(2)=y_cor+y_pos-1;
    
    x_pos_round = round(bestparameters(1));
    y_pos_round = round(bestparameters(2));
    
    if exitflag == 1 && x_pos_round>0 && x_pos_round<=size(mask_count,1) && y_pos_round>0 && y_pos_round<=size(mask_count,2) && mask_count(x_pos_round,y_pos_round)==1;
        window_x = ceil(bestparameters(4)*3);
        window_y = ceil(bestparameters(5)*3);
        
        %Calculate FWHM of Gaussian, FWHM=2*sqrt(2*ln2)*w, (w=sigma)
        bestparameters(4)=2*sqrt(2*log(2))*bestparameters(4);
        bestparameters(5)=2*sqrt(2*log(2))*bestparameters(5);
        %calculating the ratio of both eliptical axes
        if bestparameters(4)>bestparameters(5)
            ratio = bestparameters(4)/bestparameters(5);
        else
            ratio = bestparameters(5)/bestparameters(4);
        end
        area_ellipse = bestparameters(4)*bestparameters(5)*pi;
       
        bestparameters = [bestparameters(2),bestparameters(1),bestparameters(3),bestparameters(4),bestparameters(5),ratio,fval,exitflag,area_ellipse,window_x,window_y,bestparameters(1),bestparameters(2)/bestparameters(1)];
        Gauss_param=[Gauss_param ,[bestparameters]'];
        mask_count(x_pos_round,y_pos_round)=0;
      
    elseif exitflag ~= 1
        failedfits = failedfits +1;
    end
end

Gauss_param=Gauss_param';
    
    
    %create mask_total with new coordinates which defines the areas in which objects have been found
    [M,N]=size(im);
    msk_total=ones(M,N);
    
    for i=1:size(Gauss_param,1)
        
        [x_cor]=round(Gauss_param(i,2))-Gauss_param(i,10);
        [y_cor]=round(Gauss_param(i,1))-Gauss_param(i,11);
        
        if 0<x_cor && x_cor+Gauss_param(i,10)*2<=size(im_original,1) && 0<y_cor && y_cor+Gauss_param(i,11)*2<=size(im_original,2)
            
            clear tmp*
            tmp4mask=double(im_original((x_cor:x_cor+Gauss_param(i,10)*2),(y_cor:y_cor+Gauss_param(i,11)*2)));
            %select circular region around center of tmp4mask
            x = -Gauss_param(i,10):Gauss_param(i,10);
            y = -Gauss_param(i,11):Gauss_param(i,11);
            [X Y] = meshgrid(x,y);
            radius1=(Gauss_param(i,10));
            radius2=(Gauss_param(i,11));
            tmp4mask(X.^2./radius1^2+Y.^2./radius2^2<1)=10;
            [x1,y1]=find(tmp4mask==10);
            x1=x1+x_cor-1;
            y1=y1+y_cor-1;
            msk_total(x1,y1)=-1;
        end
    end

 figure 
 imagesc(msk_total);
 pause
if isempty(Gauss_param) 

 SNR_Gauss=[0,0,0,0,0,0,0]';

else



%calculate SNR_Gauss for new positions

    for i=1:size(Gauss_param,1)
    clear tmp*
    window_x = Gauss_param(i,10);
    window_y = Gauss_param(i,11);
    
    [x_cor_back]=round(Gauss_param(i,2))-window_x-2;
    [y_cor_back]=round(Gauss_param(i,1))-window_y-2;
    [x_cor]=round(Gauss_param(i,2))-window_x;
    [y_cor]=round(Gauss_param(i,1))-window_y;
    
    
    
    im_original_zero=double(im_original).*msk_total;
    %calculate mean spot intensity and standard deviation
    figure, imagesc(im_original_zero);
    pause
    
    if  x_cor_back+(window_x+2)*2<=size(im_original_zero,1) && y_cor_back+(window_y+2)*2<=size(im_original_zero,2)  && x_cor_back>0 && y_cor_back>0
        
        tmp=double(im_original((x_cor:x_cor+window_x*2),(y_cor:y_cor+window_y*2)));
        tmp_dye=double(dye((x_cor:x_cor+window_x*2),(y_cor:y_cor+window_y*2)));
        %select circular region around center of tmp
        x = -window_x:window_x;
        y = -window_y:window_y;
        [X Y] = meshgrid(x,y);
        
        radius1=(Gauss_param(i,4))/2;
        radius2=(Gauss_param(i,5))/2;
        tmp=tmp(X.^2./radius1^2+Y.^2./radius2^2<1);
        tmp_dye=tmp_dye(X.^2./radius1^2+Y.^2./radius2^2<1);
        
        tmp=tmp(tmp>0);
        tmp_dye=tmp_dye(tmp_dye>0);
        size(tmp);
        spot_mean=mean(tmp(:));
        dye_mean=mean(tmp_dye(:));
        %spot=Gauss_param(i,3);
        spot=spot_mean;
        std_spot=std(tmp(:));
        %same for the background
        tmp_background=im_original_zero((x_cor_back:x_cor_back+((window_x+2)*2)),(y_cor_back:y_cor_back+((window_y+2)*2)));
        tmp_back=tmp_background(tmp_background>0);
        if isempty(tmp_back)==1
            back=0;
            SNR=(spot-back)/0.1;
            std_back=0;
            spot_back=0;
            spot_dye_int = 0;
        else
            back=mean(tmp_back);
            std_back=std(tmp_back);
            spot_back=spot-back;
            spot_dye_int = dye_mean;
            %SNR (Cheezum 2001)
            %     SNR=(spot-back)/(sqrt(std_spot^2+std_back^2));
            %SNR Changed, Problem: STD of a Gaussian-shaped spot is higher than the
            %Noise, because obviously, the variation of the Gaussian Shape from the
            %mean is high, the factor 3 is arbitrary, since it is just a threshold
            %method, it is not so important
            SNR=(spot-back)/(sqrt(std_spot^2+std_back^2));
        end
        %concatenate it up
        SNR_Gauss=[SNR_Gauss ,[spot,std_spot,back,std_back,SNR,spot_back,spot_dye_int]'];
    else
        SNR_Gauss=[SNR_Gauss ,[0,0,0,0,0,0,0]'];
    end
    end
end
SNR_Gauss=SNR_Gauss';
%mean_background = mean(SNR_Gauss(:,3));
%mean_window = mean(Gauss_param(i,10));
end












