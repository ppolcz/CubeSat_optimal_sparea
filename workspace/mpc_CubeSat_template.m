%% Optimal solar panel area computation with MPC (template script)
% 
%  File: mpc_CubeSat_template.m
%  Directory: workspace
%  Author: Peter Polcz (ppolcz@gmail.com) 
% 
%  Created on 2020. May 01. (2019b)
% 
% This template script is NOT a function, therefore, it uses and writes the
% global workspace. Some variables are assumed to be initialized outside of
% this script. Nevertheless, a default parameter setup is hardcoded in this
% script, for the case when the main script `mpc_CubSet` is not executed.
% This template script is a generalized version of:
% 
%  File: mpc_CubeSat_1_290K_low_power.m
%  Directory: workspace
%  Author: Peter Polcz (ppolcz@gmail.com) 
% 
%  Created on 2019. December 21. (2019b)
%  Modified on 2020. January 24. (2019b)
%  Major review on 2020. May 01. (2019b)
%

global NLMPC_Vars

%%

% Default parameter setup if `mpc_CubeSat' is not executed
if ~exist('dQc_Max','var')
    
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

    % Parameters for visualization
    dQc_lim = [0 1.5];
    Tt_lim = [275 295];
    Ts_lim = [250 370];
    
    setupname = 'Setup1_290K_pm3K_low_power';

    dQc_lim = [0 1.5];
    Tt_lim = [275 295];
    Ts_lim = [250 370];

    lambda_lims = [ 0 1 ];
    Tt_Min = 287;
    Tt_Max = 293;
    dQc_Max = 1.2;
    Samples_per_Period = 20;

end    

TMP_KbocfQKqXbwtNPjzxHKN = pcz_dispFunctionName(setupname);

Tt_bounds = [Tt_Min , Tt_Max];

pcz_dispFunction2 ' '
pcz_dispFunction2 'Iteration for lambdaStar:'
pcz_dispFunction_scalar(lambdaStar, Nr_Max_Iterations)

pcz_dispFunction2 ' '
pcz_dispFunction2 'Parameters for the optimization:'
pcz_dispFunction_scalar(dQc_Max, Tt_bounds, Time_for_convergence, ...
    lambda_lims, Periodicity_tolerance, Prediction_Time, Samples_per_Period)

pcz_dispFunction2 ' '
pcz_dispFunction2 'Parameters for the visualization:'
pcz_dispFunction_scalar(dQc_lim, Tt_lim, Ts_lim)

for iteration = 1:Nr_Max_Iterations

    TMP_iYXzPhvVPXIbSWJNMuIi = pcz_dispFunctionName(...
        sprintf('Iteration nr. %d, lambdaStar = %g', iteration, round(lambdaStar,3)));
    NLMPC_Vars.fmincon_itnr = 0;
    
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

    % Samples per prediction horizon
    N = round(Samples_per_Period * Prediction_Time/P);

    % Sampling interval
    Ts = Prediction_Time / N;

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

    % Check model
    validateFcns(nlobj,x0,[1,1],[0,0,0],params)

    t = 0:Ts:Prediction_Time;
    opt = nlmpcmoveopt;
    opt.Parameters = params;
    [mv,opt,info] = nlmpcmove(nlobj,x0,[0;0],[],CubeSat_rho(t),opt);

    pcz_dispFunction('Nr. of fmincon evaluations: %d', NLMPC_Vars.fmincon_itnr-1)
    pcz_dispFunction('Prediction model error: %d', NLMPC_Vars.prediction_model_error)
    pcz_info(info.ExitFlag > 0, 'The constraints are feasible.')

    u = info.MVopt;
    x = info.Xopt;

    minu = min(nlobj.ManipulatedVariables(1).Min,round(min(u(:,1)),3));
    maxu = max(nlobj.ManipulatedVariables(1).Max,round(max(u(:,1)),3));
    if -1e-10 < minu
        minu = abs(minu);
    end

    lambda = min(u(:,2));
    if lambda - max(u(:,2)) > 1e-10
        info.ExitFlag = -3;
    end

    pcz_dispFunction_scalar(lambdaStar, lambda);

    modelname = sprintf('-%s-Tt%d_%d_dQc%g_lambdaStar%g_lambda%g',setupname,[Tt_Min Tt_Max],maxu,round(lambdaStar,3),round(lambda,3));

    pcz_dispFunctionEnd(TMP_iYXzPhvVPXIbSWJNMuIi);
    
    if abs(lambdaStar - lambda) > 0.0005
        lambdaStar = lambda;
    else
        break;
    end

end

%% Simulate the system with the computed input

u_fh = Staircase_Input_Generator(t,u(:,1),P,'hold',1);
f_ode = @(t,x) CubeSat_StateFcn(x,[u_fh(t) lambda CubeSat_rho(t)]',lambdaStar);

t_ode = 0:Ts:Simulation_Time;
[tt,xx] = ode45(f_ode,t_ode([1,end]),x0);

%% Error evaluation

x_sim = interp1(tt,xx,t);

ABS_ERROR = max(max(abs(x(:,end) - x_sim(:,end))));
L2_ERROR = trapz(t,(x(:,end) - x_sim(:,end)).^2)^0.5;
MS_ERROR = sum((x(:,end) - x_sim(:,end)).^2)/N;

%% Save results

mat_fname = logger.mat_fname;
pcz_save(mat_fname, N, P, Prediction_Time, Simulation_Time, Time_for_convergence, Ts, Tt_Max, Tt_Min, ...
    dQc_Max, info, lambda, lambdaStar, lambda_lims, maxu, minu, opt, p, p1, ...
    params, Samples_per_Period, t, u, x, t_ode, tt, xx);

%% Visualize

CubeSat_plot_v3
CubeSat_plot_v4

%%

pcz_dispFunctionEnd(TMP_KbocfQKqXbwtNPjzxHKN);
