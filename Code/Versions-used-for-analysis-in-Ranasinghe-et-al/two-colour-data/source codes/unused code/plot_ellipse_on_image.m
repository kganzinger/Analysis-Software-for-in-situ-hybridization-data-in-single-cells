function [im]=plot_ellipse_on_image(image,spots,SNR)
        [H,W] = size(image);
        %Change figure size and define its position on the screen
        screen_size = get(0,'screensize'); %get screen value
        %position = [0.1516    0.01    2*(W/(H+W))*0.7023    2*(H/(H+W))*0.7910].*[screen_size(3:4) screen_size(3:4)];
        figure,imagesc(image); %set(gcf,'Position',position), 
        colormap('jet');
        axis image
        hold on; %grid off;  %set gcf current figure handle
        %%plot local maxima found by d_peaks on filtered image
        plot(spots(:,1),spots(:,2),'gx'); 
        hold on
        plot_ellipse(spots(:,1),spots(:,2),spots(:,4),spots(:,5),SNR(:,5),SNR(:,1),spots(:,8),spots(:,9)); 
        %make_tiff(num2str(n),video,nImage)
%         F = getframe(gcf);
%         colormap(F.colormap);
%         im=F.cdata;
        im=1; 
        % Convert it to grey image
        %im = 0.2989 * im_rgb(:,:,1) + 0.5870 * im_rgb(:,:,2) + 0.1140 * im_rgb(:,:,3); 
        
        %print(figure(n), '-r80', '-dtiff', num2str(n));