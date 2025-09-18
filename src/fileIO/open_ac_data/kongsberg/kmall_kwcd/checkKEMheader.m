function out_bool = checkKEMheader(header_struct)

patt = "#" + characterListPattern("A","Z") ...
    + characterListPattern("A","Z") ...
    + characterListPattern("A","Z");

out_bool = header_struct.dgSize>0 && matches(header_struct.dgmType,patt);
end