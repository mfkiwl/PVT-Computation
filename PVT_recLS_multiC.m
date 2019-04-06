function    [PVT, DOP, Corr, NS, error]  =   PVT_recLS_multiC(acq_info, eph)
% PVT_recLS:    Computation of the receiver position at time TOW from  
%               pseudoranges (pr) and ephemerides information (eph). 
%               Implementation using the iterative Least-Squares principle 
%               after linearization of the navigation equations. We use the
%               svn Id (svn) to get the satellite coordinates corresponding 
%               to the pseudoranges given by the input (pr).
%               
% Input:            
%               acq_info:   Struct with all the acquisition information
%                           extracted from the phone.
%               eph:        Struct with all the matrix ephemeris 
%                           information for different constellations
%
% Output:       PVT:        Nsolx1 vector with the estimated PVT solution                  
%
        
    %% General initializations
    c                   =   299792458; 
    Nit                 =   5; 
    emptysat            =   [];
    GPS_tropoCorr       =   0;
    GPS_ionoCorr        =   0;
    Galileo_tropoCorr   =   0;
    Galileo_ionoCorr    =   0;
    error.flag          =   0;
    error.text          =   '';
    e_t                 =   0;
    
    %% LS loop
    for iter = 1:Nit
%         iter
        % Declarations
        if (iter == 1)
            PVT     =   [acq_info.refLocation.XYZ zeros(1, (acq_info.flags.constellations.GPS +acq_info.flags.constellations.Galileo))];
            iono    =   acq_info.ionoProto;
        end
        
        %% GPS loop
        if acq_info.flags.constellations.GPS
            
            if (iter == 1)
                
                if acq_info.flags.constellations.GPSL1
                    nGPS            =   length(acq_info.SV.GPS.GPSL1);
                    GPS_A           =   zeros(nGPS, 4);
                    GPS_p           =   zeros(nGPS, 1);
                    %GPS_tcorr       =   zeros(nGPS, 1);
                    %GPS_Pcorr       =   zeros(nGPS, 1);
                    GPS_X           =   zeros(3, nGPS);
                    GPS_pr1          =   [];
                    GPS_svn1         =   [];
                    GPS_CN01         =   [];
                    for i=1:nGPS
                        GPS_pr1      =   [GPS_pr1 acq_info.SV.GPS.GPSL1(i).p];
                        GPS_svn1     =   [GPS_svn1 acq_info.SV.GPS.GPSL1(i).svid];
                        GPS_CN01     =   [GPS_CN01 acq_info.SV.GPS.GPSL1(i).CN0];
                    end    
                    GPS_eph1            =   eph.GPSL1;
                    GPS_pr              =   GPS_pr1;
                    GPS_svn             =   GPS_svn1;
                    GPS_eph             =   GPS_eph1;
                    GPS_CN0             =   GPS_CN01;
                end
                if acq_info.flags.constellations.GPSL5
                    nGPS            =   length(acq_info.SV.GPS.GPSL5);
                    GPS_A           =   zeros(nGPS, 4);
                    GPS_p           =   zeros(nGPS, 1);
                    %GPS_tcorr       =   zeros(nGPS, 1);
                    %GPS_Pcorr       =   zeros(nGPS, 1);
                    GPS_X           =   zeros(3, nGPS);
                    GPS_pr2          =   [];
                    GPS_svn2         =   [];
                    GPS_CN02         =   [];
                    for i=1:nGPS
                        GPS_pr2      =   [GPS_pr2 acq_info.SV.GPS.GPSL5(i).p];
                        GPS_svn2     =   [GPS_svn2 acq_info.SV.GPS.GPSL5(i).svid];
                        GPS_CN02     =   [GPS_CN02 acq_info.SV.GPS.GPSL5(i).CN0];
                    end    
                    GPS_eph2            =   eph.GPSL5;
                    GPS_pr              =   GPS_pr2;
                    GPS_svn             =   GPS_svn2;
                    GPS_eph             =   GPS_eph2;
                    GPS_CN0             =   GPS_CN02;
                end
                if(acq_info.flags.constellations.GPSL1 && acq_info.flags.constellations.GPSL5)
                   [flg,i1,i5]            =   intersect(GPS_svn1,GPS_svn2); 
                   ttt              =   GPS_svn2(i5);
                   pr           =   GPS_pr2(i5);
                   CN0          =   GPS_CN02(i5);
                   N2           =   length(ttt);
                   if(N2 ~= length(GPS_svn2))
                       aa       =   setdiff(GPS_svn2,GPS_svn1);
                       for ii =1:length(aa) 
                           ttt      =   [ttt aa(ii)];
                           pr       =   [pr GPS_pr2(GPS_svn2==aa(ii))];
                           CN0      =   [CN0 GPS_CN02(GPS_svn2==aa(ii))];
                       end
                       N2       =   length(ttt);
                   end 
                   aa           =   setdiff(GPS_svn1,GPS_svn2);
                   if(~isempty(aa))
                       for ii = 1:length(aa)
                           ttt          =   [ttt aa(ii)];
                           pr           =   [pr GPS_pr1(GPS_svn1==aa(ii))];
                           CN0          =   [CN0 GPS_CN01(GPS_svn1==aa(ii))];
                       end
                       N1           =   length(aa);
                       eph_idx      =   [2*ones(N2,1);ones(N1,1)]; 
                   else
                       eph_idx      =   2*ones(N2,1); 
                   end
                       
                   nGPS     =   length(pr);
                   GPS_pr   =   pr;
                   GPS_svn  =   ttt;
                   GPS_CN0  =   CN0;
                   GPS_eph  =   [GPS_eph1 GPS_eph2];
                end
            end
        
            for sat = 1:nGPS                
                %% GPS corrections
                % GPS satellite coordinates and time correction (always applying)
                if (iter == 1)
                    [GPS_X(:, sat), GPS_tcorr(sat)]  =   getCtrl_corr(GPS_eph, GPS_svn(sat), acq_info.TOW, GPS_pr(sat), acq_info.flags, 1);
                end
                GPS_corr                =   c * GPS_tcorr(sat);
                
                % Another GPS corrections (depending on flags)
                
                % Ionosphere and troposphere corrections
                if acq_info.flags.corrections.ionosphere || acq_info.flags.corrections.troposphere
                    [GPS_tropoCorr, GPS_ionoCorr]           =   getProp_corr(GPS_X(:, sat), PVT, iono, acq_info.TOW);  % Iono + Tropo correction
                    if acq_info.flags.corrections.troposphere 
                        GPS_corr            =   GPS_corr - GPS_tropoCorr; % troposphere correction
                    end
                    if acq_info.flags.corrections.ionosphere
                        GPS_corr            =   GPS_corr - GPS_ionoCorr; % ionosphere correction
                    end
                else
                    
                end
                
                % Ionosphere correction based on dual frequency
                if acq_info.flags.corrections.f2corr
                    if sat == 1
                        if acq_info.flags.constellations.GPSL1
                            % For L1 from L5
                            [Pif,Ierr,Ierr2,ncomm]   =   getIonoCorrDualFreq_GPS(1575.42e6, 1176.45e6,...
                                [acq_info.SV.GPS.GPSL1.svid; acq_info.SV.GPS.GPSL1.p],...
                                [acq_info.SV.GPS.GPSL5.svid; acq_info.SV.GPS.GPSL5.p],...
                                [acq_info.SV.GPS.GPSL1.svid; acq_info.SV.GPS.GPSL1.tgdS]);
                        end                      
                        if acq_info.flags.constellations.GPSL5
                            % For L5 from L1
                            [Pif,Ierr,Ierr2,ncomm]   =   getIonoCorrDualFreq_GPS(1176.45e6, 1575.42e6,...
                                [acq_info.SV.GPS.GPSL5.svid; acq_info.SV.GPS.GPSL5.p],...
                                [acq_info.SV.GPS.GPSL1.svid; acq_info.SV.GPS.GPSL1.p],...
                                [acq_info.SV.GPS.GPSL5.svid; acq_info.SV.GPS.GPSL5.tgdS]);
                        end

                        % Pseudorange - ionofree error
                        temp     = ismember(GPS_svn,ncomm);
                        idx      = find(temp);
                        for oo = 1:length(Ierr)
                            % Only substract ionofree error if it is
                            % positive (else is because of noise)
                            if Ierr(oo) > 0
                                GPS_pr(idx(oo))   = GPS_pr(idx(oo)) - Ierr(oo); 
                            end
                        end
                    end
                end
                
                % Applies Klobuchar to the satellites without ionofree
                % correction
                if acq_info.flags.corrections.f2corr
                    if ~temp(sat)
                        [~, GPS_ionoCorr]           =   getProp_corr(GPS_X(:, sat), PVT, iono, acq_info.TOW);
                    end
                    GPS_corr            =   GPS_corr - GPS_ionoCorr;
                end
                
                
                GPS_pr_c                =   GPS_pr(sat) + GPS_corr - PVT(4)*c;
                
                %% GPS geometric matrix generation
                if (~isnan(GPS_pr_c))    % Fill as long as there is C1 measurement,
                                     % otherwise discard the measurement.
                    %--     Fill the measurement vector (rhoc_i - d0_i)
                    GPS_d0  = sqrt((GPS_X(1,sat) - PVT(1))^2 + (GPS_X(2,sat) - PVT(2))^2 + (GPS_X(3,sat) - PVT(3))^2); %TODO: shorten
                    GPS_p(sat)          =   GPS_pr_c - GPS_d0;
                    %
                    %--     Fill the geometry matrix (TBD)
                    GPS_ax              =   -(GPS_X(1, sat) - PVT(1)) / GPS_d0;   % dx/d0
                    GPS_ay              =   -(GPS_X(2, sat) - PVT(2)) / GPS_d0;   % dy/d0
                    GPS_az              =   -(GPS_X(3, sat) - PVT(3)) / GPS_d0;   % dz/d0
                    GPS_A(sat, :)     =   [GPS_ax GPS_ay GPS_az 1];
                    % 
                end       
            end
            % Delete rows of 0s
            if iter == 1
                for i=1:size(GPS_A, 1)
                    if GPS_A(i,:) == 0
                        emptysat = [emptysat i];
                    end
                end
                emptysat = emptysat(length(emptysat):-1:1);
                for i=1:length(emptysat)
                   GPS_A(emptysat(i),:) = [];
                   GPS_p(emptysat(i))   = [];
                end
            end
            emptysat         = []; 
        else
            GPS_A           =   [];
            GPS_X           =   [];
            GPS_p           =   [];
            GPS_CN0         =   [];
            GPS_tcorr       =   [];
            GPS_Pcorr       =   [];
        end

        %% Galileo loop
        if acq_info.flags.constellations.Galileo
            
            if (iter == 1)
                
                if acq_info.flags.constellations.GalileoE1
                    nGalileo            =   length(acq_info.SV.Galileo.GalileoE1);
                    Galileo_A           =   zeros(nGalileo, 4);
                    Galileo_X           =   zeros(nGalileo,3)';
                    Galileo_p           =   zeros(nGalileo, 1);
                    Galileo_pr1          =   [];
                    Galileo_svn1         =   [];
                    Galileo_CN01         =   [];
                    for i=1:nGalileo
                        Galileo_pr1      =   [Galileo_pr1 acq_info.SV.Galileo.GalileoE1(i).p];
                        Galileo_svn1     =   [Galileo_svn1 acq_info.SV.Galileo.GalileoE1(i).svid];
                        Galileo_CN01     =   [Galileo_CN01 acq_info.SV.Galileo.GalileoE1(i).CN0];
                    end
                    Galileo_eph1         =   eph.GalileoE1;
                    Galileo_pr          =   Galileo_pr1;
                    Galileo_svn         =   Galileo_svn1;
                    Galileo_eph     =   Galileo_eph1;
                    Galileo_CN0     =   Galileo_CN01;
                end
                if acq_info.flags.constellations.GalileoE5a
                    nGalileo            = length(acq_info.SV.Galileo.GalileoE5a);
                    Galileo_A           =   zeros(nGalileo, 4);
                    Galileo_X           =   zeros(nGalileo,3)';
                    Galileo_p           =   zeros(nGalileo, 1);
                    Galileo_pr2          =   [];
                    Galileo_svn2         =   [];
                    Galileo_CN02         =   [];
                    for i=1:nGalileo
                        Galileo_pr2      =   [Galileo_pr2 acq_info.SV.Galileo.GalileoE5a(i).p];
                        Galileo_svn2     =   [Galileo_svn2 acq_info.SV.Galileo.GalileoE5a(i).svid];
                        Galileo_CN02     =   [Galileo_CN02 acq_info.SV.Galileo.GalileoE5a(i).CN0];
                    end
                    Galileo_eph2         =   eph.GalileoE5a;
                    Galileo_pr          =   Galileo_pr2;
                    Galileo_svn         =   Galileo_svn2;
                    Galileo_eph     =   Galileo_eph2;
                    Galileo_CN0     =   Galileo_CN02;
                end
                if(acq_info.flags.constellations.GalileoE1 && acq_info.flags.constellations.GalileoE5a)
                   [flg,i1,i5]            =   intersect(Galileo_svn1,Galileo_svn2); 
                   ttt              =   Galileo_svn2(i5);
                   pr           =   Galileo_pr2(i5);
                   CN0          =   Galileo_CN02(i5);
                   N2           =   length(ttt);
                   if(N2 ~= length(Galileo_svn2))
                       aa       =   setdiff(Galileo_svn2,Galileo_svn1);
                       for ii =1:length(aa) 
                           ttt      =   [ttt aa(ii)];
                           pr       =   [pr Galileo_pr2(Galileo_svn2==aa(ii))];
                           CN0      =   [CN0 Galileo_CN02(Galileo_svn2==aa(ii))];
                       end
                       N2       =   length(ttt);
                   end 
                   aa           =   setdiff(Galileo_svn1,Galileo_svn2);
                   if(~isempty(aa))
                       for ii = 1:length(aa)
                           ttt          =   [ttt aa(ii)];
                           pr           =   [pr Galileo_pr1(Galileo_svn1==aa(ii))];
                           CN0          =   [CN0 Galileo_CN01(Galileo_svn1==aa(ii))];
                       end
                       N1           =   length(aa);
                       eph_idx      =   [2*ones(N2,1);ones(N1,1)]; 
                   else
                       eph_idx      =   2*ones(N2,1); 
                   end
                       
                   nGalileo     =   length(pr);
                   Galileo_pr   =   pr;
                   Galileo_svn  =   ttt;
                   Galileo_CN0  =   CN0;
                   Galileo_eph  =   [Galileo_eph1 Galileo_eph2];
                end
                
            end
            flag2               =   acq_info.flags.constellations.GalileoE1 && acq_info.flags.constellations.GalileoE5a;
            
            for sat = 1:nGalileo
                %% Galileo corrections
                % Galileo satellite coordinates and time correction (always applying)
                if (iter == 1)  % Only 1st iteration
                    if flag2
                        if( sat<=N2 )
                            Galileo_eph         =   Galileo_eph2;
                        else
                            Galileo_eph         =   Galileo_eph1;
                        end
                    end
                    [Galileo_X(:, sat), Galileo_tcorr(sat)]  =   getCtrl_corr(Galileo_eph, Galileo_svn(sat), acq_info.TOW, Galileo_pr(sat), acq_info.flags, 0);
                end
                Galileo_corr                =   c * Galileo_tcorr(sat);
                
                % Another Galileo corrections (depending on flags)
                
                % Ionosphere and troposphere corrections
                if acq_info.flags.corrections.ionosphere || acq_info.flags.corrections.troposphere
                    [Galileo_tropoCorr, Galileo_ionoCorr]           =   getProp_corr(Galileo_X(:, sat), PVT, iono, acq_info.TOW);  % Iono + Tropo correction
                    if acq_info.flags.corrections.troposphere 
                        Galileo_corr            =   Galileo_corr - Galileo_tropoCorr; % troposphere correction
                    end
                    if acq_info.flags.corrections.ionosphere
                        Galileo_corr            =   Galileo_corr - Galileo_ionoCorr; % ionosphere correction
                    end
                end
                
                % Ionosphere correction based on dual frequency
                if acq_info.flags.corrections.f2corr
                    if sat == 1
                        if acq_info.flags.constellations.GalileoE1
                            % For E1 from E5a
                            [Pif,Ierr,Ierr2,ncomm]   =   getIonoCorrDualFreq_GAL(1575.42e6, 1176.45e6,...
                                [acq_info.SV.Galileo.GalileoE1.svid; acq_info.SV.Galileo.GalileoE1.p],...
                                [acq_info.SV.Galileo.GalileoE5a.svid; acq_info.SV.Galileo.GalileoE5a.p]);
                        end                      
                        if acq_info.flags.constellations.GalileoE5a
                            % For E5a from E1
                            [Pif,Ierr,Ierr2,ncomm]   =   getIonoCorrDualFreq_GAL(1176.45e6, 1575.42e6,...
                                [acq_info.SV.Galileo.GalileoE5a.svid; acq_info.SV.Galileo.GalileoE5a.p],...
                                [acq_info.SV.Galileo.GalileoE1.svid; acq_info.SV.Galileo.GalileoE1.p]);
                        end
                        
                        % Pseudorange - ionofree error
                        temp     = ismember(Galileo_svn,ncomm);
                        idx      = find(temp);
                        for oo = 1:length(Ierr)
                            % Only substract ionofree error if it is
                            % positive (else is because of noise)
                            if Ierr(oo) > 0
                                Galileo_pr(idx(oo))   = Galileo_pr(idx(oo)) - Ierr(oo); 
                            end
                        end
                    end
                end
                
                % Applies Klobuchar to the satellites without ionofree
                % correction
                if acq_info.flags.corrections.f2corr
                    if ~temp(sat)
                        [~, Galileo_ionoCorr]           =   getProp_corr(Galileo_X(:, sat), PVT, iono, acq_info.TOW);
                    end
                    Galileo_corr            =   Galileo_corr - Galileo_ionoCorr;
                end
                            
                
                % Corrections application
                if(acq_info.flags.constellations.GPS && acq_info.flags.constellations.Galileo) % if multiconstellation
                    Galileo_pr_c                =   Galileo_pr(sat) + Galileo_corr - (PVT(4)+PVT(5))*c;
                else
                    Galileo_pr_c                =   Galileo_pr(sat) + Galileo_corr - PVT(4)*c;   %   Corrected pseudorange
                end
                
                %% Galileo geometric matrix generation
                if (~isnan(Galileo_pr_c))    % Fill as long as there is C1 measurement,
                                     % otherwise discard the measurement.
                    %--     Fill the measurement vector (rhoc_i - d0_i)
                    Galileo_d0              =   sqrt((Galileo_X(1,sat) - PVT(1))^2 + (Galileo_X(2,sat) - PVT(2))^2 + (Galileo_X(3,sat) - PVT(3))^2); %TODO: shorten
                    Galileo_p(sat)          =   Galileo_pr_c - Galileo_d0;
                    %
                    %--     Fill the geometry matrix
                    Galileo_ax              =   -(Galileo_X(1, sat) - PVT(1)) / Galileo_d0;   % dx/d0
                    Galileo_ay              =   -(Galileo_X(2, sat) - PVT(2)) / Galileo_d0;   % dy/d0
                    Galileo_az              =   -(Galileo_X(3, sat) - PVT(3)) / Galileo_d0;   % dz/d0
                    Galileo_A(sat, :)     =   [Galileo_ax Galileo_ay Galileo_az 1];
                    % 
                end
            end
            % Delete rows of 0s
            if iter == 1
                for i=1:size(Galileo_A, 1)
                    if Galileo_A(i,:) == 0
                        emptysat = [emptysat i];
                    end
                end
                emptysat = emptysat(length(emptysat):-1:1);
                for i=1:length(emptysat)
                   Galileo_A(emptysat(i),:) = [];
                   Galileo_p(emptysat(i))   = [];
                end
            end
            emptysat         = [];
        else
            Galileo_A           =   [];
            Galileo_X           =   [];
            Galileo_p           =   [];
            Galileo_CN0         =   [];
            Galileo_tcorr       =   [];
            Galileo_Pcorr       =   [];
        end
        
        %% Multiconstellation settings (GPS + Galileo)
        % Add multiconstellation column
        if iter == 1
            if acq_info.flags.constellations.GPS && acq_info.flags.constellations.Galileo
                GPS_A       =   [GPS_A zeros(size(GPS_A, 1), 1)];
                Galileo_A   =   [Galileo_A ones(size(Galileo_A, 1), 1)];
                
            end
        end
        
        % Multiconstellation unions
        G           =   [GPS_A; Galileo_A];
        p           =   [GPS_p; Galileo_p];
        CN0         =   [GPS_CN0 Galileo_CN0];
        Sat_X       =   [GPS_X Galileo_X];
        
        %% Satellite azimuth and elevation computation
        for ii = 1:length(p)
            [~, eL(ii), ~]      =   topocent(PVT(1:3),Sat_X(:,ii));    % Satellite elevation
        end
        
        %% Elevation mask application
        if  acq_info.flags.algorithm.mask.flag
            if acq_info.flags.algorithm.mask.elev
                maskVal     =   acq_info.flags.algorithm.mask.elevvalue;
                idx         =   eL > maskVal;
                G           =   G(idx,:);
                p           =   p(idx);
                CN0         =   CN0(idx);
                eL          =   eL(idx);    
            end
        end        
        
        %% Get rid of the outliers
        tmp     =   p<1e5;
        G       =   G(tmp,:);
        p       =   p(tmp);
        CN0     =   CN0(tmp);
        eL      =   eL(tmp); 
        %
        
        %% If there is enough satellites
        if size(G, 1) >= (3 + acq_info.flags.constellations.GPS + acq_info.flags.constellations.Galileo)
            %% Weighting matrix
            if acq_info.flags.algorithm.WLS
                W   =   compute_Wmatrix(eL,CN0,acq_info.flags.algorithm.weight.type);
            else
                W   =   eye(length(G));
            end

            %% LS corrections
            H               =   inv(G'*W*G);
            d               =   H*G'*W*p;            % PVT update      
            
            %% Integrity check (RAIM)
%             if( iter == Nit )
                if( length(p) > 4 ) % Fault Exclusion
                    resi            =   p-G*d;
                    SSE             =   sqrt((resi'*resi)/length(p)-4);   % Sum of Square Errors (SSE) for RAIM
                    while( SSE > 1e3 && length(p) > 4)
                        [~,idx]     =   max(resi);
                        idt         =   ~(1:length(p) == idx);
                        p           =   p(idt);
                        G           =   G(idt,:);
                        W           =   W(idt,idt);
                        H           =   inv(G'*W*G);
                        d           =   H*G'*W*p;
                        %
                        resi        =   p - G*d;
                        SSE         =   sqrt((resi'*resi)/(length(p)-4));
                    end
                else        % Fault detection --> PVT exclusion (i.e. nan)
%                     resi            =   p-G*d;
%                     SSE             =   sqrt((resi'*resi));   % Sum of Square Errors (SSE) for RAIM
%                     if( SSE > 1e3 )
%                         d           =   nan(4,1); % Ojo luego al promediar, al promediar trata de utilizar nanmean()
%                     end
                end                       
%             end
            PVT(1:3)    =   PVT(1:3) + d(1:3)';  % Update the PVT coords.
            PVT(4)      =   PVT(4) + d(4)/c;     % Update receiver clock offset
            
            if acq_info.flags.constellations.GPS && acq_info.flags.constellations.Galileo
                PVT(5)      =   PVT(5) + d(5)/c;     % GGTO
            end
            
            GDOP            =   sqrt(H(1,1) + H(2,2) + H(3,3) + H(4,4));
            PDOP            =   sqrt(H(1,1) + H(2,2) + H(3,3));
            TDOP            =   sqrt(H(4,4));
            DOP             =   [GDOP, PDOP, TDOP];
            Corr.GPS        =   [GPS_ionoCorr GPS_tropoCorr];
            Corr.Galileo    =   [Galileo_ionoCorr Galileo_tropoCorr];
            NS              =   size(G, 1);
        else
            error.flag = 1;
            error.text = 'Not enough satellites';
            PVT     =   [0 0 0 0];
            DOP   	=   [];
            Corr    =   [];
            NS      =   0;
        end
        %
    end
     
    % Trick: don't accept executions with an error exceeding a fixed
    % threshold
%     e_t = sqrt((acq_info.refLocation.XYZ(1)-PVT(1))^2 + (acq_info.refLocation.XYZ(2)-PVT(2))^2 + (acq_info.refLocation.XYZ(3)-PVT(3))^2);
%     if e_t > 1000
%         error.flag = 1;
%         error.text = 'Bad data';
%         PVT     =   [0 0 0 0];
%         DOP   	=   [];
%         Corr    =   [];
%         NS      =   0;
%     end
    

end

    %fprintf('\nGDOP: %f', GDOP);
    %fprintf('\nPDOP: %f', PDOP);
    %fprintf('\nTDOP: %f\n\n:', TDOP);
    %tcorr   =   [GPS_tcorr' Galileo_tcorr];
    %Pcorr   =   [GPS_Pcorr Galileo_Pcorr];
    %tcorr = mean(tcorr);
    %Pcorr = mean(Pcorr);
    
%% Test code

    % Have to delete de duplicated satellites?
%     svn         =   (unique(svn', 'rows'))';
%     pr          =   pr(1:length(svn));

%             % Delete rows of 0s
%             for i=1:length(GPS_A)
%                 if GPS_A(i,:) == 0
%                     emptysat = [emptysat i];
%                 end
%             end
%             for i=1:length(emptysat)
%                GPS_A(emptysat(i),:) = [];
%                GPS_p(emptysat(i))   = [];
%                emptysat         = []; 
%             end
