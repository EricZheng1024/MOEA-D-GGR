function g = calSubpFitness(type, objs, z, W)
% Calculate the function values of the scalarization method
% 
%   Author: Ruihao Zheng
%   Last modified: 17/08/2022

    type2 = floor(type);
    switch type2
        case 1
            % weight sum approach
            switch round((type - type2) * 10)
                case 1
                    g = sum(objs ./ W, 2);
                case 2
                    g = sum((objs-z) .* W, 2);
                otherwise
                    g = sum(objs .* W, 2);
            end
        case 2
            % Tchebycheff approach
            switch round((type - type2) * 10)
                case 1
                    g = max(abs(objs-z) ./ W, [], 2);
                otherwise
                    g = max(abs(objs-z) .* W, [], 2);
            end
        case 7
            % p-norm scalarization
            if type - type2 == 0
                p = 2;
            else
                p = round((type - type2) * 1000, 2);  % p is only allowed to have two decimal places
            end
            if p == 2
                g = sum((abs(objs-z).* W).^p, 2).^(1/p);  % faster than vecnorm
            else
                g = vecnorm(abs(objs-z).* W, p, 2);
            end
    end
end
