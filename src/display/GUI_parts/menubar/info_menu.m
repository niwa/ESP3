function info_menu(~,~,main_figure)

curr_disp=get_esp3_prop('curr_disp');
dialog_fig=new_echo_figure(main_figure,...
    'Units','pixels','Position',[200 100 500 200],...
    'Name','Infos',...
    'Resize','off',...
    'Tag','infos',...
    'visible','off');

version=get_ver();
bgcolor = num2cell(get(main_figure, 'Color'));

labelStr1 = ['<html>' '<body><h3>' sprintf('ESP3 version %s',version) '</h3></body></html>'];
jLabel1 = javaObjectEDT('javax.swing.JLabel', labelStr1);
[hjLabel1,~] = javacomponent(jLabel1, [10,170,480,40], dialog_fig);
hjLabel1.setBackground(java.awt.Color(bgcolor{:}));


labelStr = '<html>Releases: <a href="https://sourceforge.net/projects/esp3/">ESP3 on SourceForge</a></html>';
jLabel = javaObjectEDT('javax.swing.JLabel', labelStr);
[hjLabel,~] = javacomponent(jLabel, [10,130,480,20], dialog_fig);
hjLabel.setBackground(java.awt.Color(bgcolor{:}));
set(hjLabel, 'MouseClickedCallback', @(h,e)web('https://sourceforge.net/projects/esp3/','-browser'))
hjLabel.setCursor(java.awt.Cursor.getPredefinedCursor(java.awt.Cursor.HAND_CURSOR));
hjLabel.setToolTipText('https://sourceforge.net/projects/esp3/');

labelStr = '<html>Source and help: <a href="https://bitbucket.org/yladroit/esp3/src">ESP3 on Bitbucket</u></html>';
jLabel = javaObjectEDT('javax.swing.JLabel', labelStr);
[hjLabel,~] = javacomponent(jLabel, [10,110,480,20], dialog_fig);
hjLabel.setBackground(java.awt.Color(bgcolor{:}));
 set(hjLabel, 'MouseClickedCallback', @(h,e)web('https://bitbucket.org/yladroit/esp3/wiki/Home','-browser'))
 hjLabel.setCursor(java.awt.Cursor.getPredefinedCursor(java.awt.Cursor.HAND_CURSOR));
 hjLabel.setToolTipText('https://bitbucket.org/yladroit/esp3/wiki/Home');

labelStr = ['<html><u>'...
'Contacts:</u></html>'];
jLabel = javaObjectEDT('javax.swing.JLabel', labelStr);
[hjLabel,~] = javacomponent(jLabel, [10,80,480,20], dialog_fig);
hjLabel.setBackground(java.awt.Color(bgcolor{:}));

labelStryl ='<html><body>Yoann Ladroit : <a href="mailto:yoann.ladroit@gmail.com">yoann.ladroit@gmail.com</a></body></html>';
labelStrpe ='<html><body>Pablo Escobar-Flores: <a href="mailto:pablo.escobar@niwa.co.nz">pablo.escobar@niwa.co.nz</a></body></html>';
labelStram ='<html><body>Alicia Maurice: <a href="mailto:alicia.maurice@niwa.co.nz">alicia.maurice@niwa.co.nz</a></body></html>';
labelStraw ='<html><body>Alina Wieczorek: <a href="mailto:alina.wieczorek@niwa.co.nz">alina.wieczorek@niwa.co.nz</a></body></html>';

jLabelyl = javaObjectEDT('javax.swing.JLabel', labelStryl);
[hjLabelyl,~] = javacomponent(jLabelyl, [10,60,480,20], dialog_fig);
hjLabelyl.setBackground(java.awt.Color(bgcolor{:}));
set(hjLabelyl, 'MouseClickedCallback', @(h,e)web('mailto:yoann.ladroit@niwa.co.nz'))
hjLabelyl.setCursor(java.awt.Cursor.getPredefinedCursor(java.awt.Cursor.HAND_CURSOR));
hjLabelyl.setToolTipText('mailto:yoann.ladroit@niwa.co.nz');
  
jLabelpe = javaObjectEDT('javax.swing.JLabel', labelStrpe);
[hjLabelpe,~] = javacomponent(jLabelpe, [10,40,480,20], dialog_fig);
hjLabelpe.setBackground(java.awt.Color(bgcolor{:}));
set(hjLabelpe, 'MouseClickedCallback', @(h,e)web('mailto:pablo.escobar@niwa.co.nz'))
hjLabelpe.setCursor(java.awt.Cursor.getPredefinedCursor(java.awt.Cursor.HAND_CURSOR));
hjLabelpe.setToolTipText('mailto:pablo.escobar@niwa.co.nz');
  
jLabelam = javaObjectEDT('javax.swing.JLabel', labelStram);
[hjLabelam,~] = javacomponent(jLabelam, [10,20,480,20], dialog_fig);
hjLabelam.setBackground(java.awt.Color(bgcolor{:}));
set(hjLabelam, 'MouseClickedCallback', @(h,e)web('mailto:alicia.maurice@niwa.co.nz'))
hjLabelam.setCursor(java.awt.Cursor.getPredefinedCursor(java.awt.Cursor.HAND_CURSOR));
hjLabelam.setToolTipText('mailto:alicia.maurice@niwa.co.nz');

jLabelaw = javaObjectEDT('javax.swing.JLabel', labelStraw);
[hjLabelaw,~] = javacomponent(jLabelaw, [10,0,480,20], dialog_fig);
hjLabelaw.setBackground(java.awt.Color(bgcolor{:}));
set(hjLabelaw, 'MouseClickedCallback', @(h,e)web('mailto:alina.wieczorek@niwa.co.nz'))
hjLabelaw.setCursor(java.awt.Cursor.getPredefinedCursor(java.awt.Cursor.HAND_CURSOR));
hjLabelaw.setToolTipText('mailto:alina.wieczorek@niwa.co.nz');


% Set the label's tooltip
%hjLabel.setToolTipText(['Visit the ' real_struct.url ' website']);
format_color_gui(dialog_fig,curr_disp.Font,curr_disp.Cmap);

set(dialog_fig,'Visible','on');


end