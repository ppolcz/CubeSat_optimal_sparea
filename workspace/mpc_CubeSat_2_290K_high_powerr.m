%%
%  File: mpc_CubeSat_1.m
%  Directory: 1_PhD_projects/98_CubeSat/CubeSat_MPC
%  Author: Peter Polcz (ppolcz@gmail.com)
%
%  Created on 2019. December 21. (2019b)
%  Modified on 2020. January 24. (2019b)
%  Major review on 2020. May 01. (2019b)
%
% Futtatasok:
% - 2019.12.21. (december 21, szombat), 06:20 [  OK  ]
% - 2020.01.24. (január 24, péntek), 04:16 [  OK  ]
% - 2020.01.29. (január 29, szerda), 04:45 [  OK  ]   --- lambda 0.7, 300 K

%%

G_reset

setenv('RUN_ID', num2str(pcz_runID(mfilename)))
logger = Logger(['results/' mfilename '-output.txt']);
TMP_vcUXzzrUtfOumvfgWXDd = pcz_dispFunctionName;
pcz_dispFunction2('Run ID = %s', getenv('RUN_ID'));

%%

u_lim = [0 1.5];
Tt_lim = [275 293];
Ts_lim = [250 370];

lambdaStar = 0.5;
lambda_lims = [ 0 1 ];
Tt_Min = 289;
Tt_Max = 291;
Time_for_convergence = 1000; % seconds
dQc_Max = 1.4;
Nr_Max_Iterations = 10;
Periodicity_tolerance = 0.1; % Kelvins

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

for iteration = 1:Nr_Max_Iterations

    TMP_iYXzPhvVPXIbSWJNMuIi = pcz_dispFunctionName(...
        sprintf('Iteration nr. %d, lambdaStar = %g', iteration, round(lambdaStar,3)));
    
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

    % Prediction time
    T = 2*P;

    % Samples per period
    resolution = 20;

    % Prediction horizon
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
    nlobj.Optimization.CustomIneqConFcn = @(x,u,e,data,params) [ 
        -x(p1:p+1,7)+Tt_Min 
        x(p1:p+1,7)-Tt_Max 
        x(p-resolution+1,:)' - x(p+1,:)' - Periodicity_tolerance
        x(p+1,:)' - x(p-resolution+1,:)' - Periodicity_tolerance
        ];

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

    pcz_info(info.ExitFlag > 0, 'The constraints are feasible.')

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

    pcz_dispFunction_scalar(lambdaStar, lambda);

    modelname = sprintf('-Tt%d_%d_dQc%g_lambdaStar%g_lambda%g',[Tt_Min Tt_Max],maxu,round(lambdaStar,3),round(lambda,3));
    CubeSat_plot_v3, drawnow

    pcz_dispFunctionEnd(TMP_iYXzPhvVPXIbSWJNMuIi);
    
    if abs(lambdaStar - lambda) > 0.0005
        lambdaStar = lambda;
    else
        break;
    end

end

%%

pcz_dispFunctionEnd(TMP_vcUXzzrUtfOumvfgWXDd);
logger.stoplog
