%% sym_CubeSat_1
%  
%  File: sym_CubeSat_1.m
%  Directory: 1_PhD_projects/98_CubeSat/CubeSat_MPC
%  Author: Peter Polcz (ppolcz@gmail.com) 
%  
%  Created on 2019. December 21. (2019b)
%

%% Symbolic matrices for offline planning

% State variables
x = sym('x',[7 1]);
assumeAlso(in(x,'real'));
z = x.^4;

syms dQc rho1 rho2 rho4 lambda lambdaStar real

% Input variables
u = [
    dQc
    lambda
    rho1
    rho2
    rho4
    ];

mv = [
    dQc
    lambda
    ];

% Parameters
params = lambdaStar;

Q_dot = 2;                       % the electctrical power dispated watt
Fft = 0.25;                      % the view factor
A = 0.01;                        % face area m^2
Te = 255;                        % Earth temperature K
Gs = 1367;                       % sun constant W/m^2
sigma = 5.669*10^(-8);           % Boltzmann constant [W/m^2 K^4]
AF = 0.28;                       % Albedo emission factor

m = 0.04;                        % total face mass Kg
ms = 0.0926;                     % tank mass Kg
mg = 0.0074;                     % fuel mass Kg

sigma_sc = 0.85;                 % Facial density of solar cell [kg/m2]
msc = sigma_sc * lambdaStar * A; % mass of lambdaStar perc of solar cell [kg]
ma = m - msc;                    % Aluminium mass [kg]

Cps = 504;                       % Stainless steel specific heat [J/(kg*K)]
cv = 743;                        % Netrogin specific heat [J/(kg*K)]
Cp = 980;                        % Aluminum specific heat [J/(kg*K)]
Cpsc = 1600;                     % Soler cell specific heat  [J/(kg*K)]

assc = 0.92;                     % solar absorptivity solar cell
as = 0.09;                       % solar absorptivity Aluminum
Esc = 0.85;                      % IR emissivity colar cell
E = 0.92;                        % IR emissivity Aluminum
air = E;                         % air = IR 

e11 = Gs*A*as;
e12 = Gs * A * (assc-as);
e2 = AF * Gs * A * as;

K0 = Fft * E * sigma * A;
K2 = air * sigma * A;            % TODO <--- HIBAS ESETLEG?
KT = ms * Cps + mg * cv;

K11 = E * sigma * A;
K12 = sigma * A * (Esc-E);

KAlsc = ma * Cp + msc * Cpsc;
KAl = m * Cp;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TIME-DEPENDENT TERMS AS `MEASURED DISTURBANCE INPUTS`

dx = sym(zeros(7,1));

% State equations
dx(1) = ( Q_dot - (K0+K11)*z(1) + K0*z(7)           + e11*rho1 + (e12*rho1 - K12*z(1))*lambda ) / KAlsc;
dx(2) = ( Q_dot - (K0+K11)*z(2) + K0*z(7)           + e11*rho2 + (e12*rho2 - K12*z(2))*lambda ) / KAlsc;
dx(3) = ( Q_dot - (K0+K11)*z(3) + K0*z(7) + K2*Te^4 + e2*rho1                                 ) / KAl;
dx(4) = ( Q_dot - (K0+K11)*z(4) + K0*z(7)           + e11*rho4 + (e12*rho4 - K12*z(4))*lambda ) / KAlsc;
dx(5) = ( Q_dot - (K0+K11)*z(5) + K0*z(7)                                                     ) / KAl;
dx(6) = ( Q_dot - (K0+K11)*z(6) + K0*z(7)                                                     ) / KAl;
dx(7) = ( sum(z(1:6)) - 6*z(7) ) * (K0/KT) + dQc/KT;


Jf = jacobian(dx,x);
Jg = jacobian(dx,mv);


matlabFunction(Jf,Jg,'vars',{ x u params },...
    'File','CubeSat_StateJacobianFcn_2.m','Optimize',1,...
    'Outputs', {'A','B'});
