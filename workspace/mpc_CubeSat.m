%%
%  File: mpc_CubeSat.m
%  Directory: workspace
%  Author: Peter Polcz (ppolcz@gmail.com) 
% 
%  Created on 2020. May 01. (2019b)
% 

%%

G_reset

setenv('RUN_ID', num2str(pcz_runID(mfilename)))
logger = Logger(['results/' mfilename '-output.txt']);
TMP_vcUXzzrUtfOumvfgWXDd = pcz_dispFunctionName;
pcz_dispFunction2('Run ID = %s', getenv('RUN_ID'));

%% Some global parameters

% Default initial value for lambdaStar:
lambdaStar = 0.5;

P = 5400;
x0 = [
    310.0799
    300.4167
    298.4108
    255.9591
    253.7917
    253.7917
    276.1519
    ];

Nr_Max_Iterations = 10;       % for lambdaStar
Prediction_Time = 2*P;        % seconds
Simulation_Time = 4*P;        % seconds
Time_for_convergence = 1000;  % seconds
Periodicity_tolerance = 0.1;  % Kelvins

pcz_dispFunction_num2str(x0);

Execute = [
    1 
    2 
    3 
    4 
    5 
    6
    ];


if ismember(1,Execute)
    %% Setup 1

    setupname = 'Setup1_290K_pm3K_low_power';

    dQc_lim = [0 1.5];
    Tt_lim = [275 295];
    Ts_lim = [250 370];

    lambda_lims = [ 0 1 ];
    Tt_Min = 287;
    Tt_Max = 293;
    dQc_Max = 1.2;
    Samples_per_Period = 20;

    mpc_CubeSat_template;

end

if ismember(2,Execute)
    %% Setup 2

    setupname = 'Setup2_290K_pm1K_mid_power';

    dQc_lim = [0 1.5];
    Tt_lim = [275 293];
    Ts_lim = [250 370];

    lambda_lims = [ 0 1 ];
    Tt_Min = 289;
    Tt_Max = 291;
    dQc_Max = 1.4;
    Samples_per_Period = 20;

    mpc_CubeSat_template;
    
end

if ismember(3,Execute)
    %% Setup 3

    setupname = 'Setup3_300K_pm3K_high_power_res20';

    dQc_lim = [0 2];
    Tt_lim = [275 305];
    Ts_lim = [250 370];

    lambda_lims = [ 0 1 ];
    Tt_Min = 297;
    Tt_Max = 303;
    dQc_Max = 1.75;
    Samples_per_Period = 20;

    mpc_CubeSat_template;
    
end

if ismember(4,Execute)
    %% Setup 4

    setupname = 'Setup4_300K_pm3K_high_power_res50';

    dQc_lim = [0 2];
    Tt_lim = [275 305];
    Ts_lim = [250 370];

    lambda_lims = [ 0 1 ];
    Tt_Min = 297;
    Tt_Max = 303;
    dQc_Max = 1.75;
    Samples_per_Period = 50;

    mpc_CubeSat_template;
    
end

if ismember(5,Execute)
    %% Setup 5

    setupname = 'Setup5_290K_smallest_energy';

    dQc_lim = [0 1.5];
    Tt_lim = [275 330];
    Ts_lim = [250 400];

    lambda_lims = [ 0 1 ];
    Tt_Min = 290;
    Tt_Max = 330;
    dQc_Max = 1.069;
    Samples_per_Period = 20;

    mpc_CubeSat_template;
    
end

if ismember(6,Execute)
    %% Setup 6

    setupname = 'Setup6_297K_smallest_energy';

    dQc_lim = [0 2];
    Tt_lim = [275 330];
    Ts_lim = [250 400];

    lambda_lims = [ 0 1 ];
    Tt_Min = 297;
    Tt_Max = 330;
    dQc_Max = 1.545;
    Samples_per_Period = 20;

    mpc_CubeSat_template;
end


%%

pcz_dispFunctionEnd(TMP_vcUXzzrUtfOumvfgWXDd);
logger.stoplog
