function [length_tracks,result_tracks_SNR,Results_final] = trackingXL(xyaSNRma,save_name,param)
global n n3
%Now we gonna create a matrix in a form which is suited for the function track
    %based on crockers code
    mkdir(save_name,strcat('tracks_for_',num2str(n),'_',num2str(n3)));
    Results_final=[];
    for t=1:10
        clear Temp;
        Temp = xyaSNRma{t}(:,1:3);
        if ~isempty(Temp)
            if Temp(1) ~=0
               Temp(:,3)=t;
               Temp=Temp';
               Results_final=[Results_final Temp];
            end
        end
    end
    Results_final=Results_final';
        
        %applying of track funtion
        if size(Results_final,1)>1
            result_tracks=track(Results_final,param.max_step,param);
            length_tracks = [];
            if ~isempty(result_tracks)
                
                %adding total brightness, SNR and mean intensity to result_tracks
                i_result_tracks = length(find(result_tracks(result_tracks(:,1)~=0)));
                result_tracks = result_tracks(1:i_result_tracks,:);
                for i=1:i_result_tracks
                    a=result_tracks(i,:);
                    tt=xyaSNRma{a(3)};
                    ll=find(tt==a(1));
                    temp=tt(ll,:);
                    result_tracks_SNR_temp=[a,temp(3:4)];
                    result_tracks_SNR(i,:)=result_tracks_SNR_temp;
                end
                
                %figure(10),imagesc(filtered_image_cell_(:,:,1))
                hold on
                ntrack = 1;
                for nt=1:result_tracks((size(result_tracks,1)-1),4)
                    clear temp a
                    a=find((result_tracks(:,4)==nt));
                    if length(a) > param.good
                        temp=result_tracks(a,3);
                        %save frame number, x,y position,
                        temp(:,2:5)=result_tracks_SNR(a,[1,2,4,5]);
                        order4track = num2str(ntrack, '%3d');
                        filename = strcat(save_name,'tracks_for_',num2str(n),'_',num2str(n3),'/track_', order4track, '.dat');
                        dlmwrite(filename,temp,'newline','pc');
                        length_tracks(ntrack)=length(a);
                        %drawTest(temp, nt, nt);
                        %drawTest_all(temp, nt)
                        %hold on
                        ntrack = ntrack +1;
                    end
                end
                
                
                
                
            else
                length_tracks = 0;
                result_tracks_SNR = [];
            end
            if isempty(length_tracks)
                length_tracks = 0;
            end
        else
            length_tracks = 0;
            result_tracks_SNR = [];
        end