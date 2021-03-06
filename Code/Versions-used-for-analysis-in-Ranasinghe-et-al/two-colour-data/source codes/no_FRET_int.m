function [redint, blueint, FRET] = no_FRET_int(pos,sp,parameters)
%pos = coloc_pos{n,n4}{3,1};
%sp = spots{n,n4};

allindex = [];

if parameters.fret == 1
    
    if ~isempty(pos) == 1
        
        for i = 1:size(pos,1)
            index1 = find(pos(i,1)== sp(:,1));
            index2 = find(pos(i,2)== sp(:,2));
            for ii = 1:length(index1)
                for iii = 1:length(index2)
                    if index1(ii)==index2(iii)
                        allindex = [allindex index1(ii)];
                    end
                end
            end
        end
        posFRET = sp(allindex,:);
        FRET = posFRET(:,3);
        sp(allindex,:) = [];
        blueint = sp(:,3);
        redint = [];
    else
        FRET = [];
        redint = [];
        blueint = sp(:,3);
    end
else
    if ~isempty(pos) == 1
        
        for i = 1:size(pos,1)
            index1 = find(pos(i,3)== sp(:,1));
            index2 = find(pos(i,4)== sp(:,2));
            for ii = 1:length(index1)
                for iii = 1:length(index2)
                    if index1(ii)==index2(iii)
                        allindex = [allindex index1(ii)];
                    end
                end
            end
        end
        posFRET = sp(allindex,:);
        FRET = posFRET(:,3);
        sp(allindex,:) = [];
        redint = sp(:,5);
        blueint = [];
    else
        FRET = [];
        redint = sp(:,5);
        blueint = [];
    end

end
