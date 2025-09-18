function format_geoaxes(gax)

for iax=1:numel(gax)
    if will_it_work([],'9.8',true)
        enableDefaultInteractivity(gax(iax));
        gax(iax).Interactions=[panInteraction zoomInteraction];
        gax(iax).Scalebar.Visible = 'on';
        gax(iax).TickLabelFormat = 'dm';
    end

    if will_it_work([],'9.7',true)
        gax(iax).LongitudeLabel=matlab.graphics.primitive.Text;
        gax(iax).LatitudeLabel=matlab.graphics.primitive.Text;
        gax(iax).LatitudeAxis.TickLabelRotation = 90;
    end
    
    gax(iax).NextPlot='add';
    gax(iax).Box='on';
    gax(iax).MapCenterMode='manual';
    gax(iax).Toolbar=[];
    gax(iax).FontSize=8;

    %     if will_it_work([],'9.13',true)
    %         tb = axtoolbar(gax(iax),"default");
    %         addToolbarMapButton(tb,"basemap")
    %     end

end