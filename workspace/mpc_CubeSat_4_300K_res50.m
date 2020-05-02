%% 
%  File: mpc_CubeSat_2.m
%  Directory: 1_PhD_projects/98_CubeSat/CubeSat_MPC
%  Author: Peter Polcz (ppolcz@gmail.com) 
% 
%  Created on 2019. December 21. (2019b)
% 
% Futtatasok:
% - 2019.12.21. (december 21, szombat), 06:58
% ----------------------------
% [1]
% lambdaStar = 0.726;
% lambda_lims = [ 0.65 0.75 ];
% Tt_Min = 295;
% Tt_Max = 305;
% Time_for_convergence = 800; % seconds
% dQc_Max = 1.7;
% ----------------------------
% [2]
% lambdaStar = 0.702;
% lambda_lims = [ 0.65 0.75 ];
% Tt_Min = 297;
% Tt_Max = 303;
% Time_for_convergence = 800; % seconds
% dQc_Max = 1.75;

%%

G_reset
P_init(12)

setenv('RUN_ID', num2str(pcz_runID(mfilename)))
logger = Logger(['results/' mfilename '-output.txt']);
TMP_vcUXzzrUtfOumvfgWXDd = pcz_dispFunctionName;
pcz_dispFunction2('Run ID = %s', getenv('RUN_ID'));

%% Simulation

P = 5400;
t = linspace(0,4*P,4*P)';

lambdaStar = 0.702;
lambda = lambdaStar;

u = [ 0 + 0*t , lambda + 0*t , CubeSat_rho(t) ];

u_ode = @(time) interp1(t,u,time)';
f_ode = @(t,x) CubeSat_StateFcn(x,u_ode(t),lambdaStar);

x0 = [
    310.0799  
    300.4167  
    298.4108  
    255.9591  
    253.7917  
    253.7917  
    276.1519
    ];

[tt,xx] = ode45(f_ode,t([1,end]),x0);

figure(2), 
ax(1) = subplot(211); hold off
plot(tt / P,xx(:,1:6)), grid on, hold on
plot(tt / P,xx(:,7), 'LineWidth', 3)
legend T1 T2 T3 T4 T5 T6 Tt

ax(2) = subplot(212); hold off
plot(tt / P, CubeSat_rho(tt)), grid on

linkaxes(ax,'x')

%% 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Parameters to set

lambdaStar = 0.702;
lambda_lims = [ 0.65 0.75 ];
Tt_Min = 297;
Tt_Max = 303;
Time_for_convergence = 800; % seconds
dQc_Max = 1.75;

% Prediction horizon
T = 2*P;

% Samples per period
resolution = 50;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Computations

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

nlobj.Optimization.CustomCostFcn = @(x,u,e,data,params) 1-u(1,2);
nlobj.Jacobian.CustomCostFcn = @CubeSat_CostJacobianFcn;

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
p1 = ceil(Time_for_convergence / Ts)
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

TMP_QVgVGfoCXYiYXzPhvVPX = pcz_dispFunctionName('MPC');

t = 0:Ts:T;
ts = t(p1:p+1);
opt = nlmpcmoveopt;
opt.Parameters = params;
[mv,opt,info] = nlmpcmove(nlobj,x0,[0;0],[],CubeSat_rho(t),opt);

pcz_dispFunction2(evalc('disp(info)'))

pcz_dispFunctionEnd(TMP_QVgVGfoCXYiYXzPhvVPX);

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

figure(2), subplot(211), hold off
plot(t, x(:,end),'o-', 'LineWidth', 3, 'MarkerSize', 10), 
axis([0 T 275 310]), grid on, hold on
shade(ts, Tt_Min + 0*ts, ts, Tt_Max + 0*ts, 'FillType', [1 2;2 1]);
plot([1 1]*t(p1), [Tt_Min Tt_Max], 'r', 'LineWidth',3);
title(sprintf('$\\lambda^* = %g,~ \\lambda = %g,~ T_t \\in [%d,%d],~ \\dot Q_c \\in [%g,%g]$. Feasible: %g', ...
    lambdaStar, round(lambda,3), [Tt_Min Tt_Max], minu, maxu,...
    info.ExitFlag), 'Interpreter', 'LaTeX', 'FontSize', 18)

subplot(212), hold off
plot(t,u(1,:),'o-', 'LineWidth', 3, 'MarkerSize', 10), hold on
axis tight, grid on
title(sprintf('Control input $\\dot Q_c(t)$, %d samples per period', resolution), ...
    'Interpreter', 'LaTeX', 'FontSize', 20)


pcz_dispFunctionEnd(TMP_vcUXzzrUtfOumvfgWXDd);
logger.stoplog
return

%%
% Computed control input and the resulting state function
% lambdaStar = 0.702;
% lambda_lims = [ 0.65 0.75 ];
% Tt_Min = 297;
% Tt_Max = 303;
% Time_for_convergence = 800; % seconds
% dQc_Max = 1.75;
% T = 2*P;
% resolution = 50;

lambda = u(2,1);
t   = [    0.000 ,  108.000 ,  216.000 ,  324.000 ,  432.000 ,  540.000 ,  648.000 ,  756.000 ,  864.000 ,  972.000 , 1080.000 , 1188.000 , 1296.000 , 1404.000 , 1512.000 , 1620.000 , 1728.000 , 1836.000 , 1944.000 , 2052.000 , 2160.000 , 2268.000 , 2376.000 , 2484.000 , 2592.000 , 2700.000 , 2808.000 , 2916.000 , 3024.000 , 3132.000 , 3240.000 , 3348.000 , 3456.000 , 3564.000 , 3672.000 , 3780.000 , 3888.000 , 3996.000 , 4104.000 , 4212.000 , 4320.000 , 4428.000 , 4536.000 , 4644.000 , 4752.000 , 4860.000 , 4968.000 , 5076.000 , 5184.000 , 5292.000 , 5400.000 , 5508.000 , 5616.000 , 5724.000 , 5832.000 , 5940.000 , 6048.000 , 6156.000 , 6264.000 , 6372.000 , 6480.000 , 6588.000 , 6696.000 , 6804.000 , 6912.000 , 7020.000 , 7128.000 , 7236.000 , 7344.000 , 7452.000 , 7560.000 , 7668.000 , 7776.000 , 7884.000 , 7992.000 , 8100.000 , 8208.000 , 8316.000 , 8424.000 , 8532.000 , 8640.000 , 8748.000 , 8856.000 , 8964.000 , 9072.000 , 9180.000 , 9288.000 , 9396.000 , 9504.000 , 9612.000 , 9720.000 , 9828.000 , 9936.000 , 10044.000 , 10152.000 , 10260.000 , 10368.000 , 10476.000 , 10584.000 , 10692.000 , 10800.000 ];
qQc = [    0.772 ,    0.000 ,    0.492 ,    1.343 ,    1.464 ,    1.636 ,    1.747 ,    0.043 ,    0.046 ,    0.059 ,    0.074 ,    0.090 ,    0.105 ,    0.318 ,    0.846 ,    1.475 ,    1.748 ,    1.606 ,    1.643 ,    1.750 ,    1.750 ,    1.750 ,    1.750 ,    1.750 ,    1.750 ,    1.750 ,    1.750 ,    1.750 ,    1.750 ,    1.750 ,    1.750 ,    1.750 ,    1.750 ,    1.750 ,    1.750 ,    1.750 ,    1.750 ,    1.750 ,    1.742 ,    1.479 ,    1.192 ,    0.904 ,    0.631 ,    0.386 ,    0.175 ,    0.000 ,    0.000 ,    0.000 ,    0.000 ,    0.000 ,    0.000 ,    0.000 ,    0.000 ,    0.000 ,    0.000 ,    0.000 ,    0.000 ,    0.000 ,    0.000 ,    0.000 ,    0.000 ,    0.000 ,    0.000 ,    0.064 ,    0.013 ,    0.275 ,    0.620 ,    1.384 ,    1.749 ,    1.750 ,    1.750 ,    1.750 ,    1.750 ,    1.750 ,    1.750 ,    1.750 ,    1.750 ,    1.750 ,    1.750 ,    1.750 ,    1.750 ,    1.750 ,    1.750 ,    1.750 ,    1.750 ,    1.750 ,    1.750 ,    1.750 ,    1.750 ,    1.492 ,    1.197 ,    0.905 ,    0.631 ,    0.385 ,    0.171 ,    0.003 ,    0.004 ,    0.004 ,    0.003 ,    0.002 ,    0.002 ];
x   = [  310.080 ,  324.221 ,  335.534 ,  344.024 ,  349.889 ,  353.388 ,  354.783 ,  354.326 ,  352.183 ,  348.497 ,  343.440 ,  337.142 ,  329.700 ,  321.188 ,  312.984 ,  306.246 ,  300.655 ,  295.982 ,  292.036 ,  288.668 ,  285.775 ,  283.275 ,  281.101 ,  279.201 ,  277.532 ,  276.060 ,  274.756 ,  273.598 ,  272.566 ,  271.645 ,  270.819 ,  270.079 ,  269.413 ,  268.813 ,  268.272 ,  267.783 ,  267.341 ,  266.940 ,  266.576 ,  267.619 ,  271.255 ,  277.100 ,  284.732 ,  293.694 ,  303.502 ,  313.665 ,  323.717 ,  333.244 ,  341.910 ,  349.460 ,  355.728 ,  360.623 ,  364.118 ,  366.235 ,  367.020 ,  366.534 ,  364.841 ,  362.000 ,  358.063 ,  353.074 ,  347.071 ,  340.083 ,  332.134 ,  323.246 ,  314.755 ,  307.765 ,  301.918 ,  296.975 ,  292.783 ,  289.226 ,  286.193 ,  283.588 ,  281.335 ,  279.375 ,  277.660 ,  276.154 ,  274.824 ,  273.647 ,  272.601 ,  271.669 ,  270.836 ,  270.089 ,  269.419 ,  268.817 ,  268.274 ,  267.784 ,  267.341 ,  266.940 ,  266.576 ,  267.620 ,  271.257 ,  277.103 ,  284.736 ,  293.699 ,  303.507 ,  313.671 ,  323.722 ,  333.250 ,  341.915 ,  349.466 ,  355.733 ;  300.417 ,  295.042 ,  290.518 ,  286.685 ,  283.465 ,  280.786 ,  278.572 ,  276.760 ,  275.238 ,  273.914 ,  272.765 ,  271.772 ,  270.915 ,  270.178 ,  269.541 ,  268.992 ,  268.533 ,  268.161 ,  267.852 ,  267.582 ,  267.343 ,  267.128 ,  266.930 ,  266.743 ,  266.565 ,  266.393 ,  266.227 ,  266.064 ,  265.906 ,  265.752 ,  265.603 ,  265.457 ,  265.316 ,  265.180 ,  265.048 ,  264.921 ,  264.799 ,  264.682 ,  264.570 ,  286.108 ,  304.387 ,  319.067 ,  330.095 ,  337.655 ,  342.079 ,  343.758 ,  343.075 ,  340.373 ,  335.935 ,  329.983 ,  322.685 ,  314.168 ,  307.186 ,  301.387 ,  296.520 ,  292.404 ,  288.900 ,  285.903 ,  283.329 ,  281.113 ,  279.200 ,  277.544 ,  276.107 ,  274.856 ,  273.757 ,  272.765 ,  271.854 ,  271.021 ,  270.281 ,  269.648 ,  269.110 ,  268.644 ,  268.235 ,  267.870 ,  267.541 ,  267.241 ,  266.965 ,  266.709 ,  266.470 ,  266.247 ,  266.037 ,  265.839 ,  265.653 ,  265.477 ,  265.311 ,  265.154 ,  265.006 ,  264.866 ,  264.733 ,  286.252 ,  304.511 ,  319.170 ,  330.180 ,  337.724 ,  342.134 ,  343.802 ,  343.110 ,  340.401 ,  335.958 ,  330.003 ,  322.702 ;  298.411 ,  298.793 ,  299.148 ,  299.466 ,  299.783 ,  300.115 ,  300.453 ,  300.790 ,  301.055 ,  301.196 ,  301.232 ,  301.179 ,  301.051 ,  300.857 ,  300.659 ,  300.511 ,  300.417 ,  300.376 ,  300.365 ,  300.359 ,  300.355 ,  300.348 ,  300.334 ,  300.312 ,  300.280 ,  300.240 ,  300.191 ,  300.136 ,  300.077 ,  300.013 ,  299.947 ,  299.880 ,  299.812 ,  299.744 ,  299.678 ,  299.612 ,  299.549 ,  299.488 ,  299.429 ,  299.431 ,  299.541 ,  299.736 ,  299.998 ,  300.309 ,  300.653 ,  301.014 ,  301.381 ,  301.744 ,  302.101 ,  302.443 ,  302.760 ,  303.042 ,  303.278 ,  303.462 ,  303.590 ,  303.659 ,  303.670 ,  303.623 ,  303.518 ,  303.359 ,  303.148 ,  302.888 ,  302.581 ,  302.230 ,  301.886 ,  301.577 ,  301.283 ,  301.009 ,  300.779 ,  300.612 ,  300.496 ,  300.413 ,  300.347 ,  300.290 ,  300.238 ,  300.185 ,  300.131 ,  300.075 ,  300.017 ,  299.957 ,  299.896 ,  299.834 ,  299.771 ,  299.709 ,  299.647 ,  299.586 ,  299.527 ,  299.469 ,  299.414 ,  299.419 ,  299.532 ,  299.731 ,  299.995 ,  300.308 ,  300.654 ,  301.016 ,  301.384 ,  301.748 ,  302.105 ,  302.447 ,  302.765 ;  255.959 ,  256.181 ,  259.174 ,  264.596 ,  272.104 ,  281.288 ,  291.667 ,  302.730 ,  313.905 ,  324.665 ,  334.618 ,  343.455 ,  350.963 ,  357.022 ,  341.294 ,  329.127 ,  319.465 ,  311.647 ,  305.215 ,  299.849 ,  295.323 ,  291.476 ,  288.177 ,  285.331 ,  282.860 ,  280.705 ,  278.816 ,  277.154 ,  275.687 ,  274.387 ,  273.234 ,  272.207 ,  271.291 ,  270.473 ,  269.739 ,  269.082 ,  268.491 ,  267.959 ,  267.481 ,  267.053 ,  266.673 ,  266.336 ,  266.036 ,  265.770 ,  265.534 ,  265.324 ,  265.138 ,  264.976 ,  264.844 ,  264.741 ,  264.666 ,  264.614 ,  267.314 ,  272.401 ,  279.478 ,  288.105 ,  297.807 ,  308.092 ,  318.475 ,  328.507 ,  337.803 ,  346.062 ,  353.075 ,  358.718 ,  342.673 ,  330.264 ,  320.370 ,  312.315 ,  305.673 ,  300.151 ,  295.519 ,  291.594 ,  288.241 ,  285.356 ,  282.858 ,  280.685 ,  278.784 ,  277.115 ,  275.645 ,  274.344 ,  273.191 ,  272.166 ,  271.252 ,  270.436 ,  269.706 ,  269.051 ,  268.463 ,  267.935 ,  267.459 ,  267.033 ,  266.657 ,  266.323 ,  266.027 ,  265.764 ,  265.529 ,  265.321 ,  265.136 ,  264.976 ,  264.845 ,  264.743 ,  264.670 ;  253.792 ,  253.966 ,  254.171 ,  254.399 ,  254.693 ,  255.075 ,  255.543 ,  256.089 ,  256.644 ,  257.146 ,  257.606 ,  258.033 ,  258.430 ,  258.801 ,  259.145 ,  259.463 ,  259.773 ,  260.084 ,  260.380 ,  260.645 ,  260.878 ,  261.081 ,  261.250 ,  261.388 ,  261.495 ,  261.575 ,  261.629 ,  261.662 ,  261.675 ,  261.672 ,  261.655 ,  261.627 ,  261.589 ,  261.544 ,  261.493 ,  261.438 ,  261.379 ,  261.319 ,  261.257 ,  261.198 ,  261.146 ,  261.101 ,  261.061 ,  261.026 ,  260.995 ,  260.968 ,  260.944 ,  260.928 ,  260.926 ,  260.941 ,  260.971 ,  261.014 ,  261.065 ,  261.121 ,  261.181 ,  261.246 ,  261.315 ,  261.389 ,  261.468 ,  261.552 ,  261.640 ,  261.731 ,  261.823 ,  261.911 ,  261.987 ,  262.026 ,  262.018 ,  261.977 ,  261.937 ,  261.924 ,  261.935 ,  261.956 ,  261.978 ,  261.995 ,  262.003 ,  262.001 ,  261.989 ,  261.966 ,  261.933 ,  261.891 ,  261.843 ,  261.788 ,  261.728 ,  261.664 ,  261.597 ,  261.528 ,  261.458 ,  261.387 ,  261.317 ,  261.252 ,  261.195 ,  261.145 ,  261.102 ,  261.063 ,  261.029 ,  260.999 ,  260.973 ,  260.954 ,  260.951 ,  260.964 ,  260.993 ;  253.792 ,  253.966 ,  254.171 ,  254.399 ,  254.693 ,  255.075 ,  255.543 ,  256.089 ,  256.644 ,  257.146 ,  257.606 ,  258.033 ,  258.430 ,  258.801 ,  259.145 ,  259.463 ,  259.773 ,  260.084 ,  260.380 ,  260.645 ,  260.878 ,  261.081 ,  261.250 ,  261.388 ,  261.495 ,  261.575 ,  261.629 ,  261.662 ,  261.675 ,  261.672 ,  261.655 ,  261.627 ,  261.589 ,  261.544 ,  261.493 ,  261.438 ,  261.379 ,  261.319 ,  261.257 ,  261.198 ,  261.146 ,  261.101 ,  261.061 ,  261.026 ,  260.995 ,  260.968 ,  260.944 ,  260.928 ,  260.926 ,  260.941 ,  260.971 ,  261.014 ,  261.065 ,  261.121 ,  261.181 ,  261.246 ,  261.315 ,  261.389 ,  261.468 ,  261.552 ,  261.640 ,  261.731 ,  261.823 ,  261.911 ,  261.987 ,  262.026 ,  262.018 ,  261.977 ,  261.937 ,  261.924 ,  261.935 ,  261.956 ,  261.978 ,  261.995 ,  262.003 ,  262.001 ,  261.989 ,  261.966 ,  261.933 ,  261.891 ,  261.843 ,  261.788 ,  261.728 ,  261.664 ,  261.597 ,  261.528 ,  261.458 ,  261.387 ,  261.317 ,  261.252 ,  261.195 ,  261.145 ,  261.102 ,  261.063 ,  261.029 ,  260.999 ,  260.973 ,  260.954 ,  260.951 ,  260.964 ,  260.993 ;  276.152 ,  278.575 ,  279.536 ,  281.680 ,  285.521 ,  289.378 ,  293.299 ,  297.111 ,  297.320 ,  297.709 ,  298.223 ,  298.798 ,  299.372 ,  299.883 ,  300.237 ,  300.744 ,  301.796 ,  302.772 ,  302.995 ,  302.997 ,  302.997 ,  302.832 ,  302.556 ,  302.208 ,  301.817 ,  301.404 ,  300.984 ,  300.565 ,  300.155 ,  299.758 ,  299.377 ,  299.015 ,  298.671 ,  298.346 ,  298.041 ,  297.754 ,  297.486 ,  297.235 ,  297.000 ,  297.004 ,  297.003 ,  297.001 ,  297.001 ,  297.001 ,  297.001 ,  297.002 ,  297.004 ,  297.274 ,  297.704 ,  298.200 ,  298.682 ,  299.082 ,  299.405 ,  299.707 ,  300.016 ,  300.342 ,  300.691 ,  301.061 ,  301.448 ,  301.841 ,  302.223 ,  302.565 ,  302.836 ,  302.999 ,  302.716 ,  301.538 ,  300.432 ,  299.691 ,  300.157 ,  300.953 ,  301.390 ,  301.568 ,  301.564 ,  301.431 ,  301.210 ,  300.931 ,  300.616 ,  300.280 ,  299.936 ,  299.591 ,  299.251 ,  298.920 ,  298.601 ,  298.297 ,  298.007 ,  297.732 ,  297.473 ,  297.229 ,  297.000 ,  297.024 ,  297.049 ,  297.053 ,  297.051 ,  297.048 ,  297.042 ,  297.032 ,  297.037 ,  297.313 ,  297.746 ,  298.243 ,  298.724 ];



%% Cikkbe

labels = {
    '0'
    % '$\frac{\pi}{4}$'
    '$\frac{\pi}{2}$'
    % '$\frac{3\pi}{4}$'
    '$\pi$'
    % '$\frac{5\pi}{4}$'
    '$\frac{3\pi}{2}$'
    % '$\frac{7\pi}{4}$'
    '$2\pi$'
    % '$\frac{9\pi}{4}$'
    '$\frac{5\pi}{2}$'
    % '$\frac{11\pi}{4}$'
    '$3\pi$'
    % '$\frac{13\pi}{4}$'
    '$\frac{7\pi}{2}$'
    % '$\frac{7\pi}{4}$'
    '$~~~~4\pi \cdot \frac{P}{2 \pi}$'
    };

fig = figure(3);
ax1 = subplot(211); hold off
plot(2*pi*t/P, x(:,end),'.:', 'LineWidth', 1.5, 'MarkerSize', 16),
axis([0 2*pi*T/P 275 310]), grid on, hold on
shade(2*pi*ts/P, Tt_Min + 0*ts, 2*pi*ts/P, Tt_Max + 0*ts, 'FillType', [1 2;2 1]);
plot([1 1]*2*pi*t(p1)/P, [Tt_Min Tt_Max], 'r', 'LineWidth',3);
title(sprintf('$T_{\\mathrm{T}} \\in [%d,%d]\\, \\mathrm{K}$, $\\lambda = %g$ ($\\lambda^* = %g$).', ...
    [Tt_Min Tt_Max],round(lambda,3), lambdaStar), 'Interpreter', 'LaTeX', 'FontSize', 15)
% title(sprintf('$T_{\\mathrm{T}} \\in [%d,%d]\\, \\mathrm{K}$, $\\dot Q_{\\mathrm{c}} \\in [%g,%g]$, $\\lambda = %g$ ($\\lambda^* = %g$).', ...
%     [Tt_Min Tt_Max],minu, maxu, round(lambda,3), lambdaStar), 'Interpreter', 'LaTeX', 'FontSize', 15)

ylabel('Tank temp. [K]','FontSize',15,'Interpreter','latex')

text(pi/4,280,'$P_1$','FontSize',15,'Interpreter','latex','horizontalalignment','center')
text(pi,280,'$P_2$','FontSize',15,'Interpreter','latex','horizontalalignment','center')
text(7*pi/4,280,'$P_3$','FontSize',15,'Interpreter','latex','horizontalalignment','center')
text(9*pi/4,280,'$P_1$','FontSize',15,'Interpreter','latex','horizontalalignment','center')
text(3*pi,280,'$P_2$','FontSize',15,'Interpreter','latex','horizontalalignment','center')
text(15*pi/4,280,'$P_3$','FontSize',15,'Interpreter','latex','horizontalalignment','center')

plot([0 0 1 1 3 3 4 4 5 5 7 7 8 8 9 9]*pi/2,repmat([-2 2 2 -2],[1 4])*500,'--','Color',pcz_get_plot_colors([],2),'LineWidth',2)
plot([0 0 4 4 8 8]*pi/2,[2 -2 -2 2 2 -2]*500,'-','Color',pcz_get_plot_colors([],2),'LineWidth',2)

xticks((0:0.25:T/P)*2*pi);
xticklabels(labels)

PersistStandalone.latexify_axis(15)

ax2 = subplot(212); hold off
plot(2*pi*t/P,u(1,:),'.:', 'LineWidth', 1.5, 'MarkerSize', 16), hold on
axis tight, grid on

ylabel('Control input','FontSize',15,'Interpreter','latex')
xlabel('Time $t$ [sec]','FontSize',15,'Interpreter','latex')

title(sprintf('Heat flux $\\dot Q_{\\mathrm{c}} \\in [%g,%g]$.', ...
    minu, maxu), 'Interpreter', 'LaTeX', 'FontSize', 15)

text(pi/4,280,'$P_1$','FontSize',15,'Interpreter','latex','horizontalalignment','center')
text(pi,280,'$P_2$','FontSize',15,'Interpreter','latex','horizontalalignment','center')
text(7*pi/4,280,'$P_3$','FontSize',15,'Interpreter','latex','horizontalalignment','center')
text(9*pi/4,280,'$P_1$','FontSize',15,'Interpreter','latex','horizontalalignment','center')
text(3*pi,280,'$P_2$','FontSize',15,'Interpreter','latex','horizontalalignment','center')
text(15*pi/4,280,'$P_3$','FontSize',15,'Interpreter','latex','horizontalalignment','center')

ax2.YLim = [min(u(1,:)) max(u(1,:))];
ax2.XLim = [0 2*pi*T/P];

plot([0 0 1 1 3 3 4 4 5 5 7 7 8 8 9 9]*pi/2,repmat([-2 2 2 -2],[1 4])*500,'--','Color',pcz_get_plot_colors([],2),'LineWidth',2)
plot([0 0 4 4 8 8]*pi/2,[2 -2 -2 2 2 -2]*500,'-','Color',pcz_get_plot_colors([],2),'LineWidth',2)

xticks((0:0.25:T/P)*2*pi);
xticklabels(labels)

PersistStandalone.latexify_axis(15)


pdfname = persist.file_simple('fig',sprintf('MPC_res%d_per%d_Tt%d_%d_dQc%g_lambda%g.pdf',...
    resolution,round(T/P),[Tt_Min Tt_Max],maxu,round(lambda,3)));

matname = persist.file_simple('mat',sprintf('MPC_res%d_per%d_Tt%d_%d_dQc%g_lambda%g.mat',...
    resolution,round(T/P),[Tt_Min Tt_Max],maxu,round(lambda,3)));


%{

print(pdfname,'-dpdf')

print(pngname,'-dpng','-r500')

save(matname)

%}

%% Cikkbe

labels = {
    '0'
    % '$\frac{\pi}{4}$'
    '$\frac{\pi}{2}$'
    % '$\frac{3\pi}{4}$'
    '$\pi$'
    % '$\frac{5\pi}{4}$'
    '$\frac{3\pi}{2}$'
    % '$\frac{7\pi}{4}$'
    '$2\pi$'
    % '$\frac{9\pi}{4}$'
    '$\frac{5\pi}{2}$'
    % '$\frac{11\pi}{4}$'
    '$3\pi$'
    % '$\frac{13\pi}{4}$'
    '$\frac{7\pi}{2}$'
    % '$\frac{7\pi}{4}$'
    '$~~~~4\pi \cdot \frac{P}{2 \pi}$'
    };

fig = figure(3);
ax1 = subplot(311); hold off
plot(2*pi*t/P, x(:,end),'.:', 'LineWidth', 1.5, 'MarkerSize', 16),
axis([0 2*pi*T/P 275 310]), grid on, hold on
shade(2*pi*ts/P, Tt_Min + 0*ts, 2*pi*ts/P, Tt_Max + 0*ts, 'FillType', [1 2;2 1]);
plot([1 1]*2*pi*t(p1)/P, [Tt_Min Tt_Max], 'r', 'LineWidth',3);
title(sprintf('$T_{\\mathrm{T}} \\in [%d,%d]\\, \\mathrm{K}$, $\\lambda = %g$ ($\\lambda^* = %g$).', ...
    [Tt_Min Tt_Max],round(lambda,3), lambdaStar), 'Interpreter', 'LaTeX', 'FontSize', 15)
% title(sprintf('$T_{\\mathrm{T}} \\in [%d,%d]\\, \\mathrm{K}$, $\\dot Q_{\\mathrm{c}} \\in [%g,%g]$, $\\lambda = %g$ ($\\lambda^* = %g$).', ...
%     [Tt_Min Tt_Max],minu, maxu, round(lambda,3), lambdaStar), 'Interpreter', 'LaTeX', 'FontSize', 15)

ylabel('Tank temp. [K]','FontSize',13,'Interpreter','latex')

text(pi/4,280,'$P_1$','FontSize',15,'Interpreter','latex','horizontalalignment','center')
text(pi,280,'$P_2$','FontSize',15,'Interpreter','latex','horizontalalignment','center')
text(7*pi/4,280,'$P_3$','FontSize',15,'Interpreter','latex','horizontalalignment','center')
text(9*pi/4,280,'$P_1$','FontSize',15,'Interpreter','latex','horizontalalignment','center')
text(3*pi,280,'$P_2$','FontSize',15,'Interpreter','latex','horizontalalignment','center')
text(15*pi/4,280,'$P_3$','FontSize',15,'Interpreter','latex','horizontalalignment','center')

plot([0 0 1 1 3 3 4 4 5 5 7 7 8 8 9 9]*pi/2,repmat([-2 2 2 -2],[1 4])*500,'--','Color',pcz_get_plot_colors([],2),'LineWidth',2)
plot([0 0 4 4 8 8]*pi/2,[2 -2 -2 2 2 -2]*500,'-','Color',pcz_get_plot_colors([],2),'LineWidth',2)

xticks((0:0.25:T/P)*2*pi);
xticklabels(labels)

PersistStandalone.latexify_axis(15)

ax2 = subplot(312); hold off
plot(2*pi*t/P, x(:,1:6),'.-')

axis([0 2*pi*T/P 250 370]), grid on, hold on
title(sprintf('Surface temperature $T_i \\in [%d,%d]\\, \\mathrm{K}$, $i = 1 \\dots 6$.', ...
    floor(min(min(x(:,1:6)))), ceil(max(max(x(:,1:6))))), 'Interpreter', 'LaTeX', 'FontSize', 15)
% title(sprintf('$T_{\\mathrm{T}} \\in [%d,%d]\\, \\mathrm{K}$, $\\dot Q_{\\mathrm{c}} \\in [%g,%g]$, $\\lambda = %g$ ($\\lambda^* = %g$).', ...
%     [Tt_Min Tt_Max],minu, maxu, round(lambda,3), lambdaStar), 'Interpreter', 'LaTeX', 'FontSize', 15)

ylabel('Faces temp. [K]','FontSize',13,'Interpreter','latex')

plot([0 0 1 1 3 3 4 4 5 5 7 7 8 8 9 9]*pi/2,repmat([-2 2 2 -2],[1 4])*500,'--','Color',pcz_get_plot_colors([],2),'LineWidth',2)
plot([0 0 4 4 8 8]*pi/2,[2 -2 -2 2 2 -2]*500,'-','Color',pcz_get_plot_colors([],2),'LineWidth',2)

xticks((0:0.25:T/P)*2*pi);
xticklabels(labels)

PersistStandalone.latexify_axis(15)

ax3 = subplot(313); hold off
plot(2*pi*t/P,u(1,:),'.:', 'LineWidth', 1.5, 'MarkerSize', 16), hold on
axis tight, grid on

ylabel('Control input [W]','FontSize',13,'Interpreter','latex')
xlabel('Time $t$ [sec]','FontSize',13,'Interpreter','latex')

title(sprintf('Heat flux $\\dot Q_{\\mathrm{c}} \\in [%g,%g]\\, \\mathrm{W}$.', ...
    minu, maxu), 'Interpreter', 'LaTeX', 'FontSize', 15)

text(pi/4,280,'$P_1$','FontSize',15,'Interpreter','latex','horizontalalignment','center')
text(pi,280,'$P_2$','FontSize',15,'Interpreter','latex','horizontalalignment','center')
text(7*pi/4,280,'$P_3$','FontSize',15,'Interpreter','latex','horizontalalignment','center')
text(9*pi/4,280,'$P_1$','FontSize',15,'Interpreter','latex','horizontalalignment','center')
text(3*pi,280,'$P_2$','FontSize',15,'Interpreter','latex','horizontalalignment','center')
text(15*pi/4,280,'$P_3$','FontSize',15,'Interpreter','latex','horizontalalignment','center')

ax3.YLim = [min([ u(1,:) 0]) max(u(1,:))];
ax3.XLim = [0 2*pi*T/P];

plot([0 0 1 1 3 3 4 4 5 5 7 7 8 8 9 9]*pi/2,repmat([-2 2 2 -2],[1 4])*500,'--','Color',pcz_get_plot_colors([],2),'LineWidth',2)
plot([0 0 4 4 8 8]*pi/2,[2 -2 -2 2 2 -2]*500,'-','Color',pcz_get_plot_colors([],2),'LineWidth',2)

xticks((0:0.25:T/P)*2*pi);
xticklabels(labels)

PersistStandalone.latexify_axis(15)


pdfname = persist.file_simple('fig',sprintf('MPC_res%d_per%d_Tt%d_%d_dQc%g_lambda%g-new.pdf',...
    resolution,round(T/P),[Tt_Min Tt_Max],maxu,round(lambda,3)));

matname = persist.file_simple('mat',sprintf('MPC_res%d_per%d_Tt%d_%d_dQc%g_lambda%g.mat',...
    resolution,round(T/P),[Tt_Min Tt_Max],maxu,round(lambda,3)));


%{

% Position: [1 1 694 581]
    
print(pdfname,'-dpdf')

save(matname)

% print(pngname,'-dpng','-r500')

%}
