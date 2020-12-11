%% Optimal solar panel area computation with MPC (template script)
% 
%  File: mpc_CubeSat_template.m
%  Directory: workspace
%  Author: Peter Polcz (ppolcz@gmail.com) 
% 
%  Created on 2020. May 01. (2019b)
%  Minor review on 2020. December 11. (2020b)
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

% 2020.12.11. (december 11, péntek), 08:26
NLMPC_Vars.prediction_model_error = Inf;

%%

STANDALONE_SCRIPT = 0;

% Default parameter setup if `mpc_CubeSat' is not executed
if ~exist('dQc_Max','var')
    
    STANDALONE_SCRIPT = 1;
    
    % 2020.12.11. (december 11, péntek), 08:31
    setenv('RUN_ID', num2str(pcz_runID(mfilename)))
    logger = Logger(['results/' mfilename '-output.txt']);

    % 2020.12.10. (december 10, csütörtök), 16:01
    % This is the best combination: In the MPC the input is considered a
    % staircase function (0) the measured disturbance is assumed to be
    % piecewise affine (1). In the simulations we consider a first-order
    % hold on the computed discrete input values (1), namely, we assume
    % that the input is piecewise affine.
    mconfig = {0 1 1};
    u_MPC = mconfig{1};
    rho_MPC = mconfig{2};

    % Default initial value for lambdaStar:
    lambdaInit = 0.5;
    lambdaOpt = 0.5;
    Select_Lambda_Opt = 1;

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
    % Periodicity_tolerance = 0.1;  % Kelvins

    % Parameters for visualization
    dQc_lim = [0 1.5];
    Tt_lim = [275 295];
    Ts_lim = [250 370];
    
    SetupName = 'Setup1_290K_pm3K_low_power';

    lambda_lims = [ 0 1 ];
    Tt_Min = 287;
    Tt_Max = 293;
    dQc_Max = 1.2;
    Samples_per_Period = 20;

end    

if Select_Lambda_Opt
    % Select the already computed optimal lambda, and not perform the
    % iterations. The value of the optimal lambda is different if the
    % disturbance signal is assumed to be piecewise affine.
    lambdaStar = lambdaOpt;
else
    lambdaStar = lambdaInit;
end

TMP_KbocfQKqXbwtNPjzxHKN = pcz_dispFunctionName(SetupName);

Tt_bounds = [Tt_Min , Tt_Max];

pcz_dispFunction2 ' '
pcz_dispFunction2 'Iteration for lambdaStar:'
pcz_dispFunction_scalar(lambdaStar, Nr_Max_Iterations)

pcz_dispFunction2 ' '
pcz_dispFunction2 'Parameters for the optimization:'
pcz_dispFunction_scalar(dQc_Max, Tt_bounds, Time_for_convergence, ...
    lambda_lims, Prediction_Time, Samples_per_Period)
% pcz_dispFunction2(Periodicity_tolerance)

pcz_dispFunction2 ' '
pcz_dispFunction2 'Parameters for the visualization:'
pcz_dispFunction_scalar(dQc_lim, Tt_lim, Ts_lim)

NrIt = 0;
Lambdas = {};
while 1, NrIt = NrIt + 1; if NrIt > Nr_Max_Iterations, break; end
    
    mpctimer = pcz_dispFunctionName(sprintf('Iteration nr. %d, lambdaStar = %g', NrIt, round(lambdaStar,3)));
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
    nlobj.Optimization.CustomIneqConFcn = @(x,u,e,data,params) [ 
        -x(p1:p+1,7)+Tt_Min 
        x(p1:p+1,7)-Tt_Max
        % x(1:(p+1)*6)-370 % hard-coded
        % x(p-resolution+1,:)' - x(p+1,:)' - Periodicity_tolerance
        % x(p+1,:)' - x(p-resolution+1,:)' - Periodicity_tolerance
        ];

    % Check model
    validateFcns(nlobj,x0,[1,1],[0,0,0],params)

    t = 0:Ts:Prediction_Time;
    opt = nlmpcmoveopt;
    opt.Parameters = params;
    
    % Calling the MPC optimization ----------------------------------------
    [mv,opt,info] = nlmpcmove(nlobj,x0,[0;0],[],CubeSat_rho(t),opt);
    % ---------------------------------------------------------------------

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

    Lambdas = [ Lambdas sprintf('(%g->%g)',round(lambdaStar,4),round(lambda,4)) ];
    pcz_dispFunction_scalar(lambdaStar, lambda);

    SolverTime = round(toc(mpctimer),2);
    pcz_dispFunctionEnd(mpctimer);
    
    if abs(lambdaStar - lambda) > 0.0005
        lambdaStar = lambda;
    else
        break;
    end

end

for u_SIM = mconfig{3}

    modelname = sprintf('Hold%d%d%d-%s',u_MPC,rho_MPC,u_SIM,SetupName);

    % Simulate the system with the computed input

    u_fh = Staircase_Input_Generator(t,u(:,1),P,'hold',u_SIM);
    f_ode = @(t,x) CubeSat_StateFcn(x,[u_fh(t) lambda CubeSat_rho(t)]',lambdaStar);

    odeopts = odeset;
    odeopts.MaxStep = 1;
    [tt,xx] = ode45(f_ode,[0 Simulation_Time],x0,odeopts);
    uu = u_fh(tt);
    Sim = 'ode45';

    
    % Error evaluation

    x_sim = interp1(tt,xx,t);

    AbsEr = dround(max(max(abs(x(:,end) - x_sim(:,end)))),4);
    L2Er = dround(trapz(t,(x(:,end) - x_sim(:,end)).^2)^0.5,4);
    MSE = dround(sum((x(:,end) - x_sim(:,end)).^2)/N,4);

    
    % Save results (.xls)
    
    Lambdas = strjoin(Lambdas,',');
    Lambda = round(lambda,4);
    ExitFlag = info.ExitFlag;
    NrSolverIt = NLMPC_Vars.fmincon_itnr-1;
    SolverEr = dround(NLMPC_Vars.prediction_model_error,4);
    logger.store_results(1,SetupName,Tt_Min,Tt_Max,dQc_Max,N,u_MPC,rho_MPC,NrIt,Lambdas,'Last',Lambda,NrSolverIt,SolverTime,ExitFlag,SolverEr,u_SIM,Sim,MSE,AbsEr,L2Er)

    
    % Save results (.mat)

    MPC_desing = struct('t',t(:),'u',u(:,1),'x',x,'lambda',lambda);
    Simulation = struct('t',tt,'u',uu,'x',xx,'lambda',lambda);
    mat_fname = logger.mat_fname(modelname);
    pcz_save(mat_fname, N, P, Simulation_Time, Time_for_convergence, p1, Ts, ...
        Samples_per_Period, Tt_Min, Tt_Max, dQc_Max, info, lambda, ...
        lambdaStar, maxu, minu, opt, p, p1, params,...
        dQc_lim, Tt_lim, Ts_lim,...
        MPC_desing, Simulation,...
        SetupName,u_MPC,rho_MPC,NrIt,NrSolverIt,SolverTime,ExitFlag,SolverEr,u_SIM,Sim,MSE,AbsEr,L2Er);

    
    % Visualize
    if STANDALONE_SCRIPT
        CubeSat_plot_v3
        % CubeSat_plot_v4
        % CubeSat_plot_v5
    end

end
%%

pcz_dispFunctionEnd(TMP_KbocfQKqXbwtNPjzxHKN);
