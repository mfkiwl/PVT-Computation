function acq_info = extract_info(GNSS_info, j)

% Checking all the struct and separing into constellations

%% Initial declarations

acq_info.SV_list.SVlist_GPS         =   [];
acq_info.SV_list.SVlist_SBAS        =   [];
acq_info.SV_list.SVlist_GLONASS     =   [];
acq_info.SV_list.SVlist_QZSS        =   [];
acq_info.SV_list.SVlist_BEIDOU      =   [];
acq_info.SV_list.SVlist_Galileo     =   [];
acq_info.SV_list.SVlist_UNK         =   [];
c                                   =   299792458;

%% Flags
acq_info.flags      =   GNSS_info.Params(j);

%% Location
acq_info.refLocation.LLH = [GNSS_info.Location.latitude GNSS_info.Location.longitude GNSS_info.Location.altitude];
%acq_info.refLocation.LLH = [41.4991 2.1155 179.058]; %geodesic reference
%acq_info.refLocation.LLH = [41.500019, 2.112665 240]; % Q5
acq_info.refLocation.XYZ = lla2ecef(acq_info.refLocation.LLH); 

%% Clock info
acq_info.nsrxTime = GNSS_info.Clock.timeNanos;
if GNSS_info.Clock.hasBiasNanos
    acq_info.nsGPSTime =  (acq_info.nsrxTime - (GNSS_info.Clock.biasNanos + GNSS_info.Clock.fullBiasNanos));
else
    acq_info.nsGPSTime =  (acq_info.nsrxTime - (GNSS_info.Clock.fullBiasNanos));
end
[tow, now]      = nsgpst2gpst(acq_info.nsGPSTime);
acq_info.TOW    = tow;
acq_info.NOW    = now;

%% Measurements

nGPS        =   1;
nSBAS       =   1;
nGLONASS    =   1;
nQZSS       =   1;
nBEIDOU     =   1;
nGalileo    =   1;
nUNK        =   1;

for i=1:length(GNSS_info.Meas)

    switch GNSS_info.Meas(i).constellationType
        case 1
            if check_GPSstate(GNSS_info.Meas(i).state)
                acq_info.SV_list.SVlist_GPS                     =   [acq_info.SV_list.SVlist_GPS GNSS_info.Meas(i).svid];
                acq_info.SV.GPS(nGPS).svid                      =   GNSS_info.Meas(i).svid;
                acq_info.SV.GPS(nGPS).carrierFreq               =   GNSS_info.Meas(i).carrierFrequencyHz;
                acq_info.SV.GPS(nGPS).t_tx                      =   GNSS_info.Meas(i).receivedSvTimeNanos;
                acq_info.SV.GPS(nGPS).t_rx                      =   acq_info.nsGPSTime - floor(-GNSS_info.Clock.fullBiasNanos/604800e9)*604800e9;
                acq_info.SV.GPS(nGPS).pseudorangeRate           =   GNSS_info.Meas(i).pseudorangeRateMetersPerSecond;
                acq_info.SV.GPS(nGPS).CN0                       =   GNSS_info.Meas(i).cn0DbHz;
                acq_info.SV.GPS(nGPS).phase                     =   GNSS_info.Meas(i).accumulatedDeltaRangeMeters;
                acq_info.SV.GPS(nGPS).phaseState                =   GNSS_info.Meas(i).accumulatedDeltaRangeState;
                acq_info.SV.GPS(nGPS).p                         =   pseudo_gen(acq_info.SV.GPS(nGPS).t_tx, acq_info.SV.GPS(nGPS).t_rx, c);
                nGPS                                            =   nGPS + 1;
            end
        case 2
            acq_info.SV_list.SVlist_SBAS                    =   [acq_info.SV_list.SVlist_SBAS GNSS_info.Meas(i).svid];
            acq_info.SV.SBAS(nSBAS).svid                    =   GNSS_info.Meas(i).svid;
            acq_info.SV.SBAS(nSBAS).carrierFreq             =   GNSS_info.Meas(i).carrierFrequencyHz;
            acq_info.SV.SBAS(nSBAS).t_tx                    =   GNSS_info.Meas(i).receivedSvTimeNanos;
            acq_info.SV.SBAS(nSBAS).pseudorangeRate         =   GNSS_info.Meas(i).pseudorangeRateMetersPerSecond;
            acq_info.SV.SBAS(nSBAS).CN0                     =   GNSS_info.Meas(i).cn0DbHz;
            nSBAS                                           =   nSBAS + 1;
        case 3
            acq_info.SV_list.SVlist_GLONASS             	=   [acq_info.SV_list.SVlist_GLONASS GNSS_info.Meas(i).svid];
            acq_info.SV.GLONASS(nGLONASS).svid           	=   GNSS_info.Meas(i).svid;
            acq_info.SV.GLONASS(nGLONASS).carrierFreq     	=   GNSS_info.Meas(i).carrierFrequencyHz;
            acq_info.SV.GLONASS(nGLONASS).t_tx              =   GNSS_info.Meas(i).receivedSvTimeNanos;
            acq_info.SV.GLONASS(nGLONASS).pseudorangeRate   =   GNSS_info.Meas(i).pseudorangeRateMetersPerSecond;
            acq_info.SV.GLONASS(nGLONASS).CN0               =   GNSS_info.Meas(i).cn0DbHz;
            nGLONASS                                        =   nGLONASS + 1;
        case 4
            acq_info.SV_list.SVlist_QZSS                    =   [acq_info.SV_list.SVlist_QZSS GNSS_info.Meas(i).svid];
            acq_info.SV.QZSS(nQZSS).svid                    =   GNSS_info.Meas(i).svid;
            acq_info.SV.QZSS(nQZSS).carrierFreq             =   GNSS_info.Meas(i).carrierFrequencyHz;
            acq_info.SV.QZSS(nQZSS).t_tx                    =   GNSS_info.Meas(i).receivedSvTimeNanos;
            acq_info.SV.QZSS(nQZSS).pseudorangeRate         =   GNSS_info.Meas(i).pseudorangeRateMetersPerSecond;
            acq_info.SV.QZSS(nQZSS).CN0                     =   GNSS_info.Meas(i).cn0DbHz;
            nQZSS                                           =   nQZSS + 1;

        case 5
            acq_info.SV_list.SVlist_BEIDOU                  =   [acq_info.SV_list.SVlist_BEIDOU GNSS_info.Meas(i).svid];
            acq_info.SV.BEIDOU(nBEIDOU).svid                =   GNSS_info.Meas(i).svid;
            acq_info.SV.BEIDOU(nBEIDOU).carrierFreq      	=   GNSS_info.Meas(i).carrierFrequencyHz;
            acq_info.SV.BEIDOU(nBEIDOU).t_tx                =   GNSS_info.Meas(i).receivedSvTimeNanos;
            acq_info.SV.BEIDOU(nBEIDOU).pseudorangeRate     =   GNSS_info.Meas(i).pseudorangeRateMetersPerSecond;
            acq_info.SV.BEIDOU(nBEIDOU).CN0                 =   GNSS_info.Meas(i).cn0DbHz;
            nBEIDOU                                         =   nBEIDOU + 1;
        case 6
            if check_Galstate(GNSS_info.Meas(i).state)
                acq_info.SV_list.SVlist_Galileo          	    =   [acq_info.SV_list.SVlist_Galileo GNSS_info.Meas(i).svid];
                acq_info.SV.Galileo(nGalileo).svid           	=   GNSS_info.Meas(i).svid;
                acq_info.SV.Galileo(nGalileo).carrierFreq    	=   GNSS_info.Meas(i).carrierFrequencyHz;
                acq_info.SV.Galileo(nGalileo).t_tx              =   GNSS_info.Meas(i).receivedSvTimeNanos;
                acq_info.SV.Galileo(nGalileo).t_rx              =   acq_info.nsGPSTime - floor(-GNSS_info.Clock.fullBiasNanos/100e6)*100e6;
                acq_info.SV.Galileo(nGalileo).pseudorangeRate   =   GNSS_info.Meas(i).pseudorangeRateMetersPerSecond;
                acq_info.SV.Galileo(nGalileo).CN0               =   GNSS_info.Meas(i).cn0DbHz;
                acq_info.SV.Galileo(nGalileo).phase             =   GNSS_info.Meas(i).accumulatedDeltaRangeMeters;
                acq_info.SV.Galileo(nGalileo).phaseState        =   GNSS_info.Meas(i).accumulatedDeltaRangeState;
                acq_info.SV.Galileo(nGalileo).p                 =   pseudo_gen(mod(acq_info.SV.Galileo(nGalileo).t_tx, 100e6), mod(acq_info.SV.Galileo(nGalileo).t_rx, 100e6), c);
                nGalileo                                        =   nGalileo + 1;
            end
        otherwise
            acq_info.SV_list.SVlist_UNK                     =   [acq_info.SV_list.SVlist_UNK GNSS_info.Meas(i).svid];
            acq_info.SV.UNK(nUNK).svid                      =   GNSS_info.Meas(i).svid;
            acq_info.SV.UNK(nUNK).carrierFreq               =   GNSS_info.Meas(i).carrierFrequencyHz;
            acq_info.SV.UNK(nUNK).t_tx                      =   GNSS_info.Meas(i).receivedSvTimeNanos;
            acq_info.SV.UNK(nUNK).pseudorangeRate           =   GNSS_info.Meas(i).pseudorangeRateMetersPerSecond;
            acq_info.SV.UNK(nUNK).CN0                       =   GNSS_info.Meas(i).cn0DbHz;
            nUNK                                            =   nUNK + 1;
    end
end

% Sat number correction
nGPS        =   nGPS - 1;
nSBAS       =   nSBAS - 1;
nGLONASS    =   nGLONASS - 1;
nQZSS       =   nQZSS - 1;
nBEIDOU     =   nBEIDOU - 1;
nGalileo    =   nGalileo - 1;
nUNK        =   nUNK - 1;

%% Status

for i=1:length(GNSS_info.Status)

    switch GNSS_info.Status(i).constellationType
        case 1
            for j=1:length(acq_info.SV_list.SVlist_GPS)
                if acq_info.SV.GPS(j).svid == GNSS_info.Meas(i).svid
                    acq_info.SV.GPS(j).Azimuth              = GNSS_info.Status(i).azimuthDegrees;
                    acq_info.SV.GPS(j).Elevation            = GNSS_info.Status(i).elevationDegrees;
                    acq_info.SV.GPS(j).OK                   = GNSS_info.Status(i).hasEphemerisData;
                end
            end
        case 2
            for j=1:length(acq_info.SV_list.SVlist_SBAS)
                if acq_info.SV.SBAS(j).svid == GNSS_info.Meas(i).svid
                    acq_info.SV.SBAS(j).Azimuth             = GNSS_info.Status(i).azimuthDegrees;
                    acq_info.SV.SBAS(j).Elevation       	= GNSS_info.Status(i).elevationDegrees;
                    acq_info.SV.SBAS(j).OK                	= GNSS_info.Status(i).hasEphemerisData;
                end
            end
        case 3
            for j=1:length(acq_info.SV_list.SVlist_GLONASS)
                if acq_info.SV.GLONASS(j).svid == GNSS_info.Meas(i).svid
                    acq_info.SV.GLONASS(j).Azimuth          = GNSS_info.Status(i).azimuthDegrees;
                    acq_info.SV.GLONASS(j).Elevation        = GNSS_info.Status(i).elevationDegrees;
                    acq_info.SV.GLONASS(j).OK               = GNSS_info.Status(i).hasEphemerisData;
                end
            end
        case 4
            for j=1:length(acq_info.SV_list.SVlist_QZSS)
                if acq_info.SV.QZSS(j).svid == GNSS_info.Meas(i).svid
                    acq_info.SV.QZSS(j).Azimuth         	= GNSS_info.Status(i).azimuthDegrees;
                    acq_info.SV.QZSS(j).Elevation        	= GNSS_info.Status(i).elevationDegrees;
                    acq_info.SV.QZSS(j).OK               	= GNSS_info.Status(i).hasEphemerisData;
                end
            end
        case 5
            for j=1:length(acq_info.SV_list.SVlist_BEIDOU)
                if acq_info.SV.BEIDOU(j).svid == GNSS_info.Meas(i).svid
                    acq_info.SV.BEIDOU(j).Azimuth           = GNSS_info.Status(i).azimuthDegrees;
                    acq_info.SV.BEIDOU(j).Elevation         = GNSS_info.Status(i).elevationDegrees;
                    acq_info.SV.BEIDOU(j).OK                = GNSS_info.Status(i).hasEphemerisData;
                end
            end
        case 6
            for j=1:length(acq_info.SV_list.SVlist_Galileo)
                if acq_info.SV.Galileo(j).svid == GNSS_info.Meas(i).svid
                    acq_info.SV.Galileo(j).Azimuth          = GNSS_info.Status(i).azimuthDegrees;
                    acq_info.SV.Galileo(j).Elevation        = GNSS_info.Status(i).elevationDegrees;
                    acq_info.SV.Galileo(j).OK               = GNSS_info.Status(i).hasEphemerisData;
                end
            end
        otherwise
            for j=1:length(acq_info.SV_list.SVlist_UNK)
                if acq_info.SV.UNK(j).svid == GNSS_info.Meas(i).svid
                    acq_info.SV.UNK(j).Azimuth          	= GNSS_info.Status(i).azimuthDegrees;
                    acq_info.SV.UNK(j).Elevation         	= GNSS_info.Status(i).elevationDegrees;
                    acq_info.SV.UNK(j).OK                 	= GNSS_info.Status(i).hasEphemerisData;
                end
            end
    end

  end

%% SUPL information

% GPS

for i=1:length(GNSS_info.ephData.GPS)
    for j=1:nGPS
        if acq_info.SV.GPS(j).svid == GNSS_info.ephData.GPS(i).svid
            
            acq_info.SV.GPS(j).TOW                          =   GNSS_info.ephData.GPS(i).tocS;
            acq_info.SV.GPS(j).NOW                          =   GNSS_info.ephData.GPS(i).week;
            acq_info.SV.GPS(j).af0                          =   GNSS_info.ephData.GPS(i).af0S;
            acq_info.SV.GPS(j).af1                          =   GNSS_info.ephData.GPS(i).af1SecPerSec;
            acq_info.SV.GPS(j).af2                          =   GNSS_info.ephData.GPS(i).af2SecPerSec2;
            acq_info.SV.GPS(j).tgdS                         =   GNSS_info.ephData.GPS(i).tgdS;
            
            % Kepler Model
            acq_info.SV.GPS(j).keplerModel.cic              =   GNSS_info.ephData.GPS(i).keplerModel.cic;
            acq_info.SV.GPS(j).keplerModel.cis              =   GNSS_info.ephData.GPS(i).keplerModel.cis;
            acq_info.SV.GPS(j).keplerModel.crc              =   GNSS_info.ephData.GPS(i).keplerModel.crc;
            acq_info.SV.GPS(j).keplerModel.crs              =   GNSS_info.ephData.GPS(i).keplerModel.crs;
            acq_info.SV.GPS(j).keplerModel.cuc              =   GNSS_info.ephData.GPS(i).keplerModel.cuc;
            acq_info.SV.GPS(j).keplerModel.cus              =   GNSS_info.ephData.GPS(i).keplerModel.cus;
            acq_info.SV.GPS(j).keplerModel.deltaN           =   GNSS_info.ephData.GPS(i).keplerModel.deltaN;
            acq_info.SV.GPS(j).keplerModel.eccentricity     =   GNSS_info.ephData.GPS(i).keplerModel.eccentricity;
            acq_info.SV.GPS(j).keplerModel.i0               =   GNSS_info.ephData.GPS(i).keplerModel.i0;
            acq_info.SV.GPS(j).keplerModel.iDot             =   GNSS_info.ephData.GPS(i).keplerModel.iDot;
            acq_info.SV.GPS(j).keplerModel.m0               =   GNSS_info.ephData.GPS(i).keplerModel.m0;
            acq_info.SV.GPS(j).keplerModel.omega            =   GNSS_info.ephData.GPS(i).keplerModel.omega;
            acq_info.SV.GPS(j).keplerModel.omega0           =   GNSS_info.ephData.GPS(i).keplerModel.omega0;
            acq_info.SV.GPS(j).keplerModel.omegaDot         =   GNSS_info.ephData.GPS(i).keplerModel.omegaDot;
            acq_info.SV.GPS(j).keplerModel.sqrtA            =   GNSS_info.ephData.GPS(i).keplerModel.sqrtA;
            acq_info.SV.GPS(j).keplerModel.toeS             =   GNSS_info.ephData.GPS(i).keplerModel.toeS;
            
        end
    end
end

% Galileo
for i=1:length(GNSS_info.ephData.Galileo)
    for j=1:nGalileo
        if acq_info.SV.Galileo(j).svid == GNSS_info.ephData.Galileo(i).svid
            acq_info.SV.Galileo(j).TOW                          =   GNSS_info.ephData.Galileo(i).tocS;
            acq_info.SV.Galileo(j).NOW                          =   GNSS_info.ephData.Galileo(i).week;
            acq_info.SV.Galileo(j).af0                          =   GNSS_info.ephData.Galileo(i).af0S;
            acq_info.SV.Galileo(j).af1                          =   GNSS_info.ephData.Galileo(i).af1SecPerSec;
            acq_info.SV.Galileo(j).af2                          =   GNSS_info.ephData.Galileo(i).af2SecPerSec2;
            acq_info.SV.Galileo(j).tgdS                         =   GNSS_info.ephData.Galileo(i).tgdS;
            
            % Kepler Model
            acq_info.SV.Galileo(j).keplerModel.cic              =   GNSS_info.ephData.Galileo(i).keplerModel.cic;
            acq_info.SV.Galileo(j).keplerModel.cis              =   GNSS_info.ephData.Galileo(i).keplerModel.cis;
            acq_info.SV.Galileo(j).keplerModel.crc              =   GNSS_info.ephData.Galileo(i).keplerModel.crc;
            acq_info.SV.Galileo(j).keplerModel.crs              =   GNSS_info.ephData.Galileo(i).keplerModel.crs;
            acq_info.SV.Galileo(j).keplerModel.cuc              =   GNSS_info.ephData.Galileo(i).keplerModel.cuc;
            acq_info.SV.Galileo(j).keplerModel.cus              =   GNSS_info.ephData.Galileo(i).keplerModel.cus;
            acq_info.SV.Galileo(j).keplerModel.deltaN           =   GNSS_info.ephData.Galileo(i).keplerModel.deltaN;
            acq_info.SV.Galileo(j).keplerModel.eccentricity     =   GNSS_info.ephData.Galileo(i).keplerModel.eccentricity;
            acq_info.SV.Galileo(j).keplerModel.i0               =   GNSS_info.ephData.Galileo(i).keplerModel.i0;
            acq_info.SV.Galileo(j).keplerModel.iDot             =   GNSS_info.ephData.Galileo(i).keplerModel.iDot;
            acq_info.SV.Galileo(j).keplerModel.m0               =   GNSS_info.ephData.Galileo(i).keplerModel.m0;
            acq_info.SV.Galileo(j).keplerModel.omega            =   GNSS_info.ephData.Galileo(i).keplerModel.omega;
            acq_info.SV.Galileo(j).keplerModel.omega0           =   GNSS_info.ephData.Galileo(i).keplerModel.omega0;
            acq_info.SV.Galileo(j).keplerModel.omegaDot         =   GNSS_info.ephData.Galileo(i).keplerModel.omegaDot;
            acq_info.SV.Galileo(j).keplerModel.sqrtA            =   GNSS_info.ephData.Galileo(i).keplerModel.sqrtA;
            acq_info.SV.Galileo(j).keplerModel.toeS             =   GNSS_info.ephData.Galileo(i).keplerModel.toeS;
        end
    end
end


if nGPS ~= 0
        count = 1;
        noEph = [];
        for i=1:length(acq_info.SV.GPS)
           if isempty(acq_info.SV.GPS(i).TOW)
               noEph(count) = i;
               count = count + 1;
           end
        end

    noEph = fliplr(noEph);
    for i=1:length(noEph)
        acq_info.SV.GPS(noEph(i)) = [];
    end
end

if nGalileo ~= 0
    count = 1;
    noEph = [];
    for i=1:length(acq_info.SV.Galileo)
       if isempty(acq_info.SV.Galileo(i).TOW)
           noEph(count) = i;
           count = count + 1;
       end
    end

    noEph = fliplr(noEph);
    for i=1:length(noEph)
        acq_info.SV.Galileo(noEph(i)) = [];
    end
end

% ionoProto
acq_info.ionoProto                        =   [GNSS_info.ephData.Klobuchar.alpha_; GNSS_info.ephData.Klobuchar.beta_];
%acq_info.ionoProto                        =   [GNSS_info.ephData.ionoProto.alpha_; GNSS_info.ephData.ionoProto.beta_];

%% Number of total SV
acq_info.SVs = nGPS + nSBAS + nGLONASS + nQZSS + nBEIDOU + nGalileo + nUNK;
end