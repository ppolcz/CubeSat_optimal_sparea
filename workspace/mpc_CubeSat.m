%%
%  File: mpc_CubeSat.m
%  Directory: workspace
%  Author: Peter Polcz (ppolcz@gmail.com) 
% 
%  Created on 2020. May 01. (2019b)
% 

%%

global u_MPC rho_MPC

G_reset

setenv('RUN_ID', num2str(pcz_runID(mfilename)))
logger = Logger(['results/' mfilename '-output.txt']);
TMP_vcUXzzrUtfOumvfgWXDd = pcz_dispFunctionName;
pcz_dispFunction2('Run ID = %s', getenv('RUN_ID'));

logger.store_results_init(1,'SetupName','Tt_Min','Tt_Max','dQc_Max','N','NrIt','Lambdas','Last','Lambda','NrSolverIt','SolverTime','ExitFlag','SolverEr',u_MPC,rho_MPC,'u_SIM','Sim','MSE','AbsEr','L2Er')

%% Some global parameters

Model_Configurations = {
    
    % This is the best combination: In the MPC the input is considered a
    % staircase function (0) the measured disturbance is assumed to be
    % piecewise affine (1). In the simulations we consider a first-order
    % hold on the computed discrete input values (1), namely, we assume
    % that the input is piecewise affine.
    0 1 1        
    
  % 0 0 [0,1] 
  % 0 1 [0,1]
  % 1 1 1
    };

ModelID = [
    1 
    2 
    3 
    4 
    5 
    6
    ];

% Default initial value for lambdaStar:
lambdaInit = 0.5;
lambdaOpt = 0.5;
Select_Lambda_Opt = 0;

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

Nr_Max_Iterations = 10;       % for lambdaStaruk
Prediction_Time = 2*P;        % seconds
Simulation_Time = 4*P;        % seconds
Time_for_convergence = 1000;  % seconds
% Periodicity_tolerance = 0.1;  % Kelvins

pcz_dispFunction_num2str(x0);

for mconfig = Model_Configurations'

% Initialize results' table
u_MPC = mconfig{1};
rho_MPC = mconfig{2};

if ismember(1,ModelID)
    %% Setup 1

    SetupName = 'Setup1_290K_pm3K_low_power';
    lambdaOpt = 0.5103; % 1st order hold on rho

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

if ismember(2,ModelID)
    %% Setup 2

    SetupName = 'Setup2_290K_pm1K_mid_power';
    lambdaOpt = 0.4476; % 1st order hold on rho

    dQc_lim = [0 1.5];
    Tt_lim = [275 293];
    Ts_lim = [250 370];

    lambda_lims = [ 0 1 ];
    Tt_Min = 289;
    Tt_Max = 291;
    dQc_Max = 1.4;
    Samples_per_Period = 30;

    mpc_CubeSat_template;
    
end

if ismember(3,ModelID)
    %% Setup 3

    SetupName = 'Setup3_300K_pm3K_high_power_res20';
    lambdaOpt = 0.7123; % 1st order hold on rho

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

if ismember(4,ModelID)
    %% Setup 4

    SetupName = 'Setup4_300K_pm3K_high_power_res50';
    lambdaOpt = 0.7026; % 1st order hold on rho

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

if ismember(5,ModelID)
    %% Setup 5

    SetupName = 'Setup5_290K_smallest_energy';
    lambdaOpt = 1; % 1st order hold on rho

    dQc_lim = [0 1.5];
    Tt_lim = [260 330];
    Ts_lim = [250 400];

    lambda_lims = [ 0 1 ];
    Tt_Min = 290;
    Tt_Max = 330;
    dQc_Max = 1.069;
    Samples_per_Period = 20;

    mpc_CubeSat_template;
    
end

if ismember(6,ModelID)
    %% Setup 6

    SetupName = 'Setup6_297K_smallest_energy';
    lambdaOpt = 1; % 1st order hold on rho

    dQc_lim = [0 2];
    Tt_lim = [270 330];
    Ts_lim = [250 400];

    lambda_lims = [ 0 1 ];
    Tt_Min = 297;
    Tt_Max = 330;
    dQc_Max = 1.545;
    Samples_per_Period = 20;

    mpc_CubeSat_template;
end

end

%%

pcz_dispFunctionEnd(TMP_vcUXzzrUtfOumvfgWXDd);
logger.stoplog
