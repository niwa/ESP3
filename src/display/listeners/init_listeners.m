    function init_listeners(esp3_obj)

if isempty(esp3_obj)
    return;
end

curr_disp_obj=esp3_obj.curr_disp;
main_figure=esp3_obj.main_figure;

if isappdata(main_figure,'ListenersH')
    ls=getappdata(main_figure,'ListenersH');
else
    ls=[];
end

%ls=[ls addlistener(curr_disp_obj,'EchoType','PostSet',@(src,envdata)listenEchoType(src,envdata,main_figure))];
ls=[ls addlistener(curr_disp_obj,'EchoQuality','PostSet',@(src,envdata)listenEchoQuality(src,envdata,main_figure))];

[AlphaMapDispStr,~] = curr_disp_obj.getAlphamapDispProp();
for ui = 1:numel(AlphaMapDispStr)
     ls=[ls addlistener(curr_disp_obj,AlphaMapDispStr{ui},'PostSet',@(src,envdata)listenAlphamapChange(src,envdata,main_figure,AlphaMapDispStr{ui}))];
end
ls=[ls addlistener(curr_disp_obj,'UnderBotTransparency','PostSet',@(src,envdata)listenAlphamapChange(src,envdata,main_figure,'DispUnderBottom'))];

ls=[ls addlistener(curr_disp_obj,'DispBottom','PostSet',@(src,envdata)listenDispBot(src,envdata,main_figure))];
ls=[ls addlistener(curr_disp_obj,'DispColorbar','PostSet',@(src,envdata)listenDispColorbar(src,envdata,main_figure))];
ls=[ls addlistener(curr_disp_obj,'DispReg','PostSet',@(src,envdata)listenDispReg(src,envdata,main_figure))];
ls=[ls addlistener(curr_disp_obj,'DispTracks','PostSet',@(src,envdata)listenDispTracks(src,envdata,main_figure))];
ls=[ls addlistener(curr_disp_obj,'DispLines','PostSet',@(src,envdata)listenDispLines(src,envdata,main_figure))];
ls=[ls addlistener(curr_disp_obj,'DispSurveyLines','PostSet',@(src,envdata)listenDispSurveyLines(src,envdata,main_figure))];
ls=[ls addlistener(curr_disp_obj,'CursorMode','PostSet',@(src,envdata)listenCursorMode(src,envdata,main_figure))];
ls=[ls addlistener(curr_disp_obj,'Active_reg_ID','PostSet',@(src,envdata)listenActive_reg_ID(src,envdata,main_figure))];
ls=[ls addlistener(curr_disp_obj,'ChannelID','PostSet',@(src,envdata)listenChannelID(src,envdata,main_figure))];
ls=[ls addlistener(curr_disp_obj,'Fieldname','PostSet',@(src,envdata)listenField(src,envdata,main_figure))];
ls=[ls addlistener(curr_disp_obj,'Cmap','PostSet',@(src,envdata)listenCmap(src,envdata,main_figure))];
ls=[ls addlistener(curr_disp_obj,'ReverseCmap','PostSet',@(src,envdata)listenCmap(src,envdata,main_figure))];
ls=[ls addlistener(curr_disp_obj,'Cax','PostSet',@(src,envdata)listenCax(src,envdata,main_figure))];
ls=[ls addlistener(curr_disp_obj,'Font','PostSet',@(src,envdata)listenFont(src,envdata,main_figure))];
ls=[ls addlistener(curr_disp_obj,'DispSecFreqs','PostSet',@(src,envdata)listenDispSecFreqs(src,envdata,main_figure))];
ls=[ls addlistener(curr_disp_obj,'DispSecFreqsOr','PostSet',@(src,envdata)listenDispSecFreqs(src,envdata,main_figure))];
ls=[ls addlistener(curr_disp_obj,'H_axes_ratio','PostSet',@(src,envdata)listenAxesRatio(src,envdata,main_figure))];
ls=[ls addlistener(curr_disp_obj,'V_axes_ratio','PostSet',@(src,envdata)listenAxesRatio(src,envdata,main_figure))];
ls=[ls addlistener(curr_disp_obj,'DispSecFreqsWithOffset','PostSet',@(src,envdata)listenDispSecFreqsWithOffset(src,envdata,main_figure))];
ls=[ls addlistener(curr_disp_obj,'YDir','PostSet',@(src,envdata)listenYDir(src,envdata,main_figure))];
ls=[ls addlistener(curr_disp_obj,'BeamAngularLimit','PostSet',@(src,envdata)listenBeamLimit(src,envdata,main_figure))];
ls=[ls addlistener(curr_disp_obj,'Al_opt_tab_size_ratio','PostSet',@(src,envdata)listenAl_opt_tab_size_ratio(src,envdata,main_figure))];

setappdata(main_figure,'ListenersH',ls);

end