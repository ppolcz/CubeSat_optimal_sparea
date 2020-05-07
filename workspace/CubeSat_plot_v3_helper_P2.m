function CubeSat_plot_v3_helper_P2(height)
%%
%  File: CubeSat_plot_v3_helper_P2.m
%  Directory: workspace
%  Author: Peter Polcz (ppolcz@gmail.com) 
% 
%  Created on 2020. May 01. (2019b)
% 

%%

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

if ~isinf(height)
    text(pi/4,height,'$P_1$','FontSize',15,'Interpreter','latex','horizontalalignment','center','VerticalAlignment','bottom')
    text(pi,height,'$P_2$','FontSize',15,'Interpreter','latex','horizontalalignment','center','VerticalAlignment','bottom')
    text(7*pi/4,height,'$P_3$','FontSize',15,'Interpreter','latex','horizontalalignment','center','VerticalAlignment','bottom')
    text(9*pi/4,height,'$P_1$','FontSize',15,'Interpreter','latex','horizontalalignment','center','VerticalAlignment','bottom')
    text(3*pi,height,'$P_2$','FontSize',15,'Interpreter','latex','horizontalalignment','center','VerticalAlignment','bottom')
    text(15*pi/4,height,'$P_3$','FontSize',15,'Interpreter','latex','horizontalalignment','center','VerticalAlignment','bottom')
end
    
plot([0 0 1 1 3 3 4 4 5 5 7 7 8 8 9 9]*pi/2,repmat([-2 2 2 -2],[1 4])*2000,'--','Color',pcz_get_plot_colors([],2),'LineWidth',2)
plot([0 0 4 4 8 8]*pi/2,[2 -2 -2 2 2 -2]*2000,'-','Color',pcz_get_plot_colors([],2),'LineWidth',2)

xticks((0:0.25:100)*2*pi);
xticklabels(labels)

end