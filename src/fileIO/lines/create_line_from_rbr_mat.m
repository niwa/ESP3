function obj=create_line_from_rbr_mat(filename)

    rbr_mat = load(filename);
    timestamp=zeros(1,length(rbr_mat.RBR.sampletimes));
    for i=1:length(rbr_mat.RBR.sampletimes)
        timestamp(i) = datenum(rbr_mat.RBR.sampletimes{i});
    end
    
    fprintf('\nRBR file starts at %s and finishes at %s\n',datestr(timestamp(1)),datestr(timestamp(end)));
    depth = rbr_mat.RBR.data(:,4);
    obj=line_cl('Tag','Imported from RBR','Range',depth,'Time',timestamp,'File_origin',{filename},'UTC_diff',0);
end