function update_echo_int_alphamap(main_figure)

curr_disp=get_esp3_prop('curr_disp');
echo_int_tab_comp=getappdata(main_figure,'EchoInt_tab');
alpha_data = [];
if ~isempty(echo_int_tab_comp.echo_obj.echo_surf.UserData)&&ischar(echo_int_tab_comp.echo_obj.echo_surf.UserData)
    switch echo_int_tab_comp.echo_obj.echo_surf.UserData
        case 'nb_samples'
            cd=echo_int_tab_comp.echo_obj.echo_surf.CData(echo_int_tab_comp.echo_obj.echo_surf.CData>0);
            if ~isempty(cd)
                cax=[prctile(cd(:),5) prctile(cd(:),95)];
            else
                cax=[0 1];
            end
        case 'prc'
            cax=[0 100];
        case {'nb_st_tracks'}
            cd=echo_int_tab_comp.echo_obj.echo_surf.CData;
            cax=[max(1,prctile(cd(:),5)) max(cd,[],'all','omitnan')];
        case{'tag'}
            cd=echo_int_tab_comp.echo_obj.echo_surf.CData;
            cax=[max(1,min(cd,[],'all','omitnan')) max(cd,[],'all','omitnan')];
        otherwise
            cax=curr_disp.getCaxField(echo_int_tab_comp.echo_obj.echo_surf.UserData);
    end

    if cax(2)<=cax(1)
        cax(2)=cax(1)+1;
    end

    alpha_data= echo_int_tab_comp.echo_obj.echo_surf.CData>=cax(1);

    set(echo_int_tab_comp.echo_obj.main_ax,'Clim',cax);
    set(echo_int_tab_comp.echo_obj.echo_surf,'alphadata',alpha_data);
    set(echo_int_tab_comp.echo_obj.main_ax,'layer','top');
end

end