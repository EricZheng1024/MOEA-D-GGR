function Offspring = OperatorGAhalf_2(Parent,Parameter)
%OperatorGAhalf_2 - A modified version of PlatEMO's OperatorGAhalf.
% 
%   For 'permutation' or 'binary', if the offspring generating by crossover
%   is identical to parents, mutation must be used.
% 
%   Author: Ruihao Zheng
%   Last modified: 17/08/2022

    %% Parameter setting
    if nargin > 1
        [prem_proC,perm_proM, bi_proC,bi_proM] = deal(Parameter{:});
    else
        [prem_proC,perm_proM, bi_proC,bi_proM] = deal(1,0.1,1,2);
    end
    if isa(Parent(1),'SOLUTION')
        calObj = true;
        Parent = Parent.decs;
    else
        calObj = false;
    end
    Parent1 = Parent(1:floor(end/2),:);
    Parent2 = Parent(floor(end/2)+1:floor(end/2)*2,:);
    [N,D]   = size(Parent1);
    Problem = PROBLEM.Current();
    
    switch Problem.encoding
        case 'permutation'
            %% Genetic operators for permutation based encoding
            % Order crossover
            Offspring = Parent1;
            if rand < prem_proC
                k = randi(D,1,N);
                iden_index = zeros(1, N);
                for i = 1 : N
                    Offspring(i,k(i)+1:end) = setdiff(Parent2(i,:),Parent1(i,1:k(i)),'stable');
                    if all(Offspring(i,:) == Parent1(i,:)) || all(Offspring(i,:) == Parent2(i,:))
                        % Record the offspring that is identical to parents
                        iden_index(i) = true;
                    end
                end
            end
            % Mutation
            k = randi(D,1,N);
            s = randi(D,1,N);
            for i = 1 : N
                if iden_index(i) || rand < perm_proM
                    P = k(i); Q = s(i);
                    if P > Q
                        % P should be less than Q
                        P = P + Q;
                        Q = P - Q;
                        P = P - Q;
                    end
                    Offspring(i,:) = Offspring(i, [1:P-1, Q:-1:P, Q+1:end]);
                else
%                     if s(i) < k(i)
%                         Offspring(i,:) = Offspring(i,[1:s(i)-1,k(i),s(i):k(i)-1,k(i)+1:end]);
%                     elseif s(i) > k(i)
%                         Offspring(i,:) = Offspring(i,[1:k(i)-1,k(i)+1:s(i)-1,k(i),s(i):end]);
%                     end
                end
            end
        case 'binary'
            %% Genetic operators for binary encoding
            % Uniform crossover
            k = rand(N,D) < 0.5;
            k(repmat(rand(N,1)>bi_proC,1,D)) = false;
            Offspring    = Parent1;
            Offspring(k) = Parent2(k);
            % Bit-flip mutation
            iden_index = all(Offspring == Parent1, 2) | all(Offspring == Parent2, 2);
            Site = rand(N,D) < bi_proM/D;
            for i = 1 : N
                % enhance the mutation of offspring identical to parents
                if iden_index(i)
                    Site(iden_index(i), randi([1 D])) = true;
                end
            end
            Offspring(Site) = ~Offspring(Site);
        otherwise
            Offspring = OperatorGAhalf(Parent);
    end
    if calObj
        Offspring = SOLUTION(Offspring);
    end
end