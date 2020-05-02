%%
%  File: CubeSat_plot_v1.m
%  Directory: workspace
%  Author: Peter Polcz (ppolcz@gmail.com) 
% 
%  Created on 2020. May 01. (2019b)
% 
%%

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
title('Control input $\dot Q_c(t)$', 'Interpreter', 'LaTeX', 'FontSize', 20)
