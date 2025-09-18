function ref_cell = list_echo_int_ref(varargin)
    ref_cell = {'Transducer' 'Surface' 'Bottom'};%TODO add line...
    if nargin>=1
        ref_cell = ref_cell{varargin{1}};
    end