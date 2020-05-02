%%
%  File: mpc_CubeSat_3_300K_res20.m
%  Directory: workspace
%  Author: Peter Polcz (ppolcz@gmail.com) 
% 
%  Created on 2019. December 21. (2019b)
%  Modified on 2020. January 24. (2019b)
%  Major review on 2020. May 01. (2019b)
%
% Executions:
% - 2019.12.21. (december 21, szombat), 06:20 [  OK  ]
% - 2020.01.24. (január 24, péntek), 04:16 [  OK  ]
% - 2020.01.29. (január 29, szerda), 04:45 [  OK  ] 
%    --> lambda ~= 0.7, Tt: 300K, 20 samples per orbital period (short) 
% - 2020.05.01. (május  1, péntek), 15:32 [  OK  ]

%%

G_reset

setenv('RUN_ID', num2str(pcz_runID(mfilename)))
logger = Logger(['results/' mfilename '-output.txt']);
TMP_vcUXzzrUtfOumvfgWXDd = pcz_dispFunctionName;
pcz_dispFunction2('Run ID = %s', getenv('RUN_ID'));

%%

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

%%

lambdaStar = 0.707;
lambda_lims = [ 0.65 0.75 ];
Tt_Min = 297;
Tt_Max = 303;
Time_for_convergence = 1000; % seconds
dQc_Max = 1.75;

% Order of inputs:
% dQc = u(1);     (manipulated variable)
% lambda = u(2);  (manipulated CONSTANT variable)
% rho1 = u(3);    (measured disturbance)
% rho2 = u(4);    (measured disturbance)
% rho4 = u(5);    (measured disturbance)

nlobj = nlmpc(7,7,'MV',[1 2],'MD',[3 4 5]);

params = { lambdaStar };
nlobj.Model.NumberOfParameters = 1;
nlobj.Model.StateFcn = @CubeSat_StateFcn;
nlobj.Jacobian.StateFcn = @CubeSat_StateJacobianFcn;

% Objective function: 1 - lambda(1)
nlobj.Optimization.CustomCostFcn = @(x,u,e,data,params) 1-u(1,2);
nlobj.Jacobian.CustomCostFcn = @CubeSat_CostJacobianFcn;

% Prediction horizon
T = 2*P;

% Samples per period
resolution = 20;

% Samples per prediction horizon
N = round(resolution * T/P);

% Sampling interval
Ts = T / N;

nlobj.Ts = Ts;
nlobj.PredictionHorizon = N;
nlobj.ControlHorizon = N;
nlobj.Model.IsContinuousTime = true;

p = nlobj.PredictionHorizon;

% Constraints for lambda (constant), between [0,1]
nlobj.Optimization.CustomEqConFcn = @(x,u,data,params) u(1:p+1,2) - u(1,2);
nlobj.ManipulatedVariables(2).Min = lambda_lims(1);
nlobj.ManipulatedVariables(2).Max = lambda_lims(2);

% Interval constraint for dQc
nlobj.ManipulatedVariables(1).Min = 0;
nlobj.ManipulatedVariables(1).Max = dQc_Max;

% Interval constraints for the tank temperature [version 2 - less strict]
% The interval constraints for the tank temperature is prescribed only
% after these transient steps.
p1 = ceil(Time_for_convergence / Ts);
nlobj.Optimization.CustomIneqConFcn = ...
    @(x,u,e,data,params) [ -x(p1:p+1,7)+Tt_Min ; x(p1:p+1,7)-Tt_Max ];

% Interval constraints for the tank temperature [version 1 - too strict]
% nlobj.Optimization.CustomIneqConFcn = ...
%     @(X,U,e,data,params) [ -U(1:p+1,1) ; -1 + U(1:p+1,1) ];


% Interval constraints for the tank temperature
% nlobj.States(7).Min = Tt_Min;
% nlobj.States(7).Max = Tt_Max;

% Check model
validateFcns(nlobj,x0,[1,1],[0,0,0],params)

t = 0:Ts:T;
ts = t(p1:p+1);
opt = nlmpcmoveopt;
opt.Parameters = params;
[mv,opt,info] = nlmpcmove(nlobj,x0,[0;0],[],CubeSat_rho(t),opt);

u = info.MVopt';
x = info.Xopt;

minu = min(nlobj.ManipulatedVariables(1).Min,round(min(u(1,:)),3));
maxu = max(nlobj.ManipulatedVariables(1).Max,round(max(u(1,:)),3));
if -1e-10 < minu
    minu = abs(minu);
end

lambda = min(u(2,:));
if lambda - max(u(2,:)) > 1e-10
    info.ExitFlag = -3;
end

modelname = sprintf('-Tt%d_%d_dQc%g_lambda%g',[Tt_Min Tt_Max],maxu,round(lambda,3));
CubeSat_plot_v3

pcz_dispFunctionEnd(TMP_vcUXzzrUtfOumvfgWXDd);
logger.stoplog

