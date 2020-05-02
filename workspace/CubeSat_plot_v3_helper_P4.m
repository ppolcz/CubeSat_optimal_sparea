function CubeSat_plot_v3_helper_P4(height)
%%
%  File: CubeSat_plot_v4_helper_P2.m
%  Directory: workspace
%  Author: Peter Polcz (ppolcz@gmail.com) 
% 
%  Created on 2020. May 01. (2019b)
% 

%%

labels = {
    '0'
    '$\pi$'
    '$2\pi$'
    '$3\pi$'
    '$4\pi$'
    '$5\pi$'
    '$6\pi$'
    '$7\pi$'
    '$~~~~8\pi \cdot \frac{P}{2 \pi}$'
    };
    
plot([0 0 2 2 4 4 6 6 8 8]*pi,[2 -2 -2 2 2 -2 -2 2 2 -2]*2000,'-','Color',pcz_get_plot_colors([],2),'LineWidth',2)

xticks((0:0.5:100)*2*pi);
xticklabels(labels)

end