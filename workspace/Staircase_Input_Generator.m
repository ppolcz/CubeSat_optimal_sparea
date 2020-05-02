classdef Staircase_Input_Generator
%%
%  File: CubeSat_Input_Generator.m
%  Directory: workspace
%  Author: Peter Polcz (ppolcz@gmail.com) 
% 
%  Created on 2020. May 01. (2019b)

properties (GetAccess = public, SetAccess = private)
    P, T, Nr_per;
    t, u;
end

methods (Access = public)
    function obj = Staircase_Input_Generator(t,u,P,varargin)
        opts.hold = 0;
        opts = parsepropval(opts,varargin{:});
        
        obj.P = P;
        obj.T = t(end);
        obj.Nr_per = obj.T/obj.P;
        
        % Reshape time series
        t = t(:);
        if numel(t) ~= size(u,1)
            u = u';
        end
        
        if opts.hold == 0
        
            obj.t = [ t-1e-10 t ]';
            obj.t = obj.t(2:end);
            obj.t = obj.t(:);

            obj.u = cellfun(@(ui) {[ui ui]'}, num2cell(u,1));
            obj.u = cellfun(@(ui) {ui(1:end-1)}, obj.u);
            obj.u = cellfun(@(ui) {ui(:)}, obj.u);
            obj.u = horzcat(obj.u{:});
            
        elseif opts.hold == 1
            
            obj.t = t;
            obj.u = u;
            
        end
    end
    
    function u = subsref(obj, S)

        switch S(1).type
            case '()'
                
                % t_ is assumed to be non-negative
                t_orig = S.subs{1};

                % Periodically extend using the last period ...
                t_ = mod(t_orig, obj.T);
                t_ = t_ + ( obj.Nr_per - floor(t_./obj.P) - 1) * obj.P;
                
                % ... but keep the values t_ in [t(1) t(end)]
                t_(t_orig <= obj.T) = t_orig(t_orig <= obj.T);
                
                u = interp1(obj.t,obj.u,t_);
            case '{}'
                error('{} indexing not supported');
            case '.'
                if any(strcmp(fieldnames(obj),S(1).subs))
                    varargout{1} = builtin('subsref', obj, S);
                elseif nargout > 0
                    varargout = cell(1,nargout);
                    [varargout{:}] = builtin('subsref', obj, S);
                else
                    builtin('subsref', obj, S);
                end
        end

    end
end

end