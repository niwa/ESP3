
function create_region(~,~,main_figure,shape,mode)

if check_axes_tab(main_figure)==0
    return;
end

main_figure.Pointer = 'cross';
global_region_create(main_figure,shape,mode);

end
