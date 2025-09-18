function rem_reg_tag_lim(gax,uid)
    delete(findobj(gax,'Tag',sprintf('%s_tag',uid)));
    delete(findobj(gax,'Tag',sprintf('%s_lim',uid)));
end