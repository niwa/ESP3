
function resize_echo(main_figure,~)

pix_pos=getpixelposition(main_figure);
pan_height=get_top_panel_height(9.25);

echo_tab_panel=getappdata(main_figure,'echo_tab_panel');
opt_panel=getappdata(main_figure,'option_tab_panel');
algo_panel=getappdata(main_figure,'algo_tab_panel');
load_bar_comp=getappdata(main_figure,'Loading_bar');

if isempty(load_bar_comp)
    return;
end

inf_h=load_bar_comp.panel.Position(4);

curr_disp=get_esp3_prop('curr_disp');

al_disp_ratio = curr_disp.Al_opt_tab_size_ratio;

try
    set(load_bar_comp.panel,'Position',[0 0 pix_pos(3) inf_h]);

    set(opt_panel,'Position',[0 pix_pos(4)-pan_height (1-al_disp_ratio)*pix_pos(3) pan_height]);
    set(algo_panel,'Position',[(1-al_disp_ratio)*pix_pos(3) pix_pos(4)-pan_height al_disp_ratio*pix_pos(3) pan_height]);
    set(echo_tab_panel,'Position',[0 inf_h pix_pos(3) pix_pos(4)-pan_height-inf_h]);
catch err
   print_errors_and_warnings(1,'warning',err) ;
end

end