        function mask = get_feature_mask(obj,varargin)
            p = inputParser;

            addRequired(p,'obj',@(x) isa(x,'transceiver_cl'));
            addParameter(p,'idx_r',[],@isnumeric);
            addParameter(p,'idx_beam',[],@isnumeric);
            addParameter(p,'idx_ping',[],@isnumeric);

            parse(p,obj,varargin{:});

            idx_r = p.Results.idx_r;
            idx_beam = p.Results.idx_beam;
            idx_ping = p.Results.idx_ping;
            mask = [];

            if isempty(obj.Features)
                return;
            end

            if isempty(idx_r)
                idx_r=obj.Data.get_samples();
            end

            if isempty(idx_ping)
                idx_ping=1:obj.Data.Nb_pings;
            end

            if isempty(idx_beam)
                idx_beam=1:max(obj.Data.Nb_beams,[],'all','omitnan');
            end
            %features_lim = get_lim(obj.Features);
           mask = false(numel(idx_r),numel(idx_ping),numel(idx_beam));
           for uif = 1:numel(obj.Features)
                idx_keep = ismember(obj.Features(uif).Idx_r,idx_r) &...
                    ismember(obj.Features(uif).Idx_ping,idx_ping) &...
                    ismember(obj.Features(uif).Idx_beam,idx_beam);

                if ~any(idx_keep)
                    continue;
                end

                [~,ir]=ismember(obj.Features(uif).Idx_r(idx_keep),idx_r(:)');
                [~,ip]=ismember(obj.Features(uif).Idx_ping(idx_keep),idx_ping(:)');
                [~,ib]=ismember(obj.Features(uif).Idx_beam(idx_keep),idx_beam(:)');
                
                for uiff = 1:numel(ir)
                    mask(ir(uiff),ip(uiff),ib(uiff)) = true;
                end
            end

        end