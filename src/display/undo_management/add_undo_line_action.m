function add_undo_line_action(main_figure,layer,old_l,new_l)

cmd.Name = sprintf('Lines');
cmd.Function        = @line_undo_fcn;       % Redo action
cmd.Varargin        = {main_figure,layer,new_l};
cmd.InverseFunction = @line_undo_fcn;       % Undo action
cmd.InverseVarargin = {main_figure,layer,old_l};
uiundo(main_figure,'function',cmd);

end