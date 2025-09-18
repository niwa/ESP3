function cal_merged=merge_calibration(cal_init,cal_master)

if isrow(cal_init.G0)
    cal_init = structfun(@transpose,cal_init,'Un',0);
end

cal_merged=cal_init;
fields=fieldnames(cal_init);

if ~isempty(cal_master)
    if isrow(cal_master.G0)
        cal_master = structfun(@transpose,cal_master,'Un',0);
    end
    for ical=1:numel(cal_init.G0)
        
        found_cid = true;
        if isfield(cal_init,'CID')
            idx_cal = find(strcmp(cal_init.CID{ical},cal_master.CID),1);
        end

        if isempty(idx_cal)
            found_cid = false;
            idx_cal = find(cellfun(@(x) contains(cal_init.CID{ical},x),cal_master.CID),1);
        end

        if isempty(idx_cal)
            found_cid = false;
            idx_cal=find(cal_init.FREQ(ical)==cal_master.FREQ,1);
        end

        if ~isempty(idx_cal)
            for ifi=1:numel(fields)
                if isnumeric(cal_master.(fields{ifi}))
                    if ~isnan(cal_master.(fields{ifi})(idx_cal))
                        cal_merged.(fields{ifi})(ical)= cal_master.(fields{ifi})(idx_cal);
                    end
                else
                    if ~isempty(cal_master.(fields{ifi}){idx_cal})
                        cal_merged.(fields{ifi}){ical}= cal_master.(fields{ifi}){idx_cal};
                    end
                end
            end

            if ~found_cid
                cal_merged.CID{ical} = cal_init.CID{ical};
            end
        end
    end
end