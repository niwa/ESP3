function bool = does_it_work_on_mbes(obj)

bool=false;

switch obj.Name
    case 'school_detect_3D'
        bool = true;
    case 'CFARdetection'
        bool = true;
    case 'CanopyHeight'
        
    case 'BottomDetection'
        
    case 'BottomDetectionV2'
        bool = true;
    case 'BadPingsV2'
       
    case 'DropOuts'
       
    case 'Denoise'
       bool = true;
    case 'SchoolDetection'
       
    case 'SingleTarget'
       
    case 'TrackTarget'
       
    case 'SpikesRemoval'
       
    case 'BottomFeatures'
       
    case 'Classification'
       
    otherwise
       
end

end