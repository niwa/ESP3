function PNN = get_oculus_model(PN)
switch PN
    case {0,255}
        PNN = 'Undefined';
    case 1041
        PNN = 'M370s';
    case 1229
        PNN = 'M370s_Artemis';
    case 1217
        PNN = 'M370s_Deep';
    case 1209
        PNN = 'M373s';
    case 1218
        PNN = 'M373s_Deep';
    case 1032
        PNN = 'M750d';
    case 1134
        PNN = 'M750d_Fusion';
    case 1135
        PNN = 'M750d_Artemis';
    case 1042
        PNN = 'M1200d';
    case 1219
        PNN = 'M1200d_Deep';
    case 1228
        PNN = 'M1200d_Artemis';
    case 1220
        PNN = 'N1200s';
    case 1221
        PNN = 'N1200s_Deep';
end
