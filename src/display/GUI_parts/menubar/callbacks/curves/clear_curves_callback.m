function clear_curves_callback(~,~,~)
layer=get_current_layer();

if isempty(layer)
return;
end
    

layer.clear_curves();

end