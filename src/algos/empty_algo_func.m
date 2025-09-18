function output_struct=empty_algo_func(trans_obj,varargin)

p = inputParser;
addRequired(p,'trans_obj',@(x) isa(x,'transceiver_cl'));

%%%%Add whatever parameter your algo requires%%%%%%
addParameter(p,'XXX',Nan,@isnumeric);
%%%%Done%%%%

addParameter(p,'load_bar_comp',[]);
addParameter(p,'block_len',[],@(x) x>0 || isempty(x));
addParameter(p,'reg_obj',region_cl.empty(),@(x) isa(x,'region_cl'));
parse(p,trans_obj,varargin{:});

output_struct.done =  false;

%block_len = get_block_len(50,'cpu',p.Results.block_len);