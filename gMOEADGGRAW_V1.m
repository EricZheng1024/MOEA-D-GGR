classdef gMOEADGGRAW_V1 < ALGORITHM
% <multi/many> <real/binary/permutation>
% MOEA/D-GGR (generational) + AdaW using cone dominance + naive normalization
% delta --- 1 --- The probability of selecting candidates from neighborhood
% p --- 1 --- The parameter p of GNS
% Tm --- 0.1 --- The mating neighborhood size
% Tr --- 0.001 --- The replacement neighborhood size
% alpha --- 0.1 --- 
% 
%   Ref: "What Weights Work for You? Adapting Weights for Any Pareto Front
%   Shape in Decomposition-Based Evolutionary Multiobjective Optimisation"
%   (AdaW) and "Knee Point Based Evolutionary Multi-Objective Optimization
%   for Mission Planning Problems" (cone dominance)
% 
%   Author: Ruihao Zheng

    methods
        function main(Algorithm,Problem)
            %% Parameter setting
            [delta, p, Tm, Tr, alpha] = Algorithm.ParameterSet(1, 1, 0.1, 0.001, 0.1);

            %% initialization
            % Generate the weight vectors
            [W, Problem.N] = UniformPoint(Problem.N, Problem.M);
            Tm = ceil(Problem.N * Tm);
            Tr = ceil(Problem.N * Tr);
            % Detect the mating neighbors of each solution
            B = pdist2(W, W);
            W = 1./W ./ sum(1./W, 2);
            [~,B] = sort(B, 2);
            Bm = B(:, 1:Tm);
            % Generate random population
            Population = Problem.Initialization();
            % Initialize the reference point
            z = min(Population.objs, [], 1);
            % Dertermine the scalar function
            switch p
                case 1
                    type = 1.2;
                case inf
                    type = 2;
                otherwise
                    type = 7 + min(999, p)*0.001;
            end
            h = (prod(W,2).^(-1/Problem.M));
            % Repair the boundary weight generated by "UniformPoint"
            zero_counter = sum(W<=1e-6, 2);
            [~, I] = max(W, [], 2);
            for i = 1 : Problem.N
                W(i, I(i)) = W(i, I(i)) - zero_counter(i)*1e-6;
            end
            % Add boundary subproblems to the closest non-boundary
            % subproblem's neighborhood (Not available)

            % Generate an archive set (for AdaW)
            Archive = Population(NDSort(Population.objs,1)==1);


            %% Optimization
            while Algorithm.NotTerminated(Population)
                
                % Obtain the mating pool
                MatingPool = zeros(1, 2 * Problem.N);
                for i = 1 : Problem.N
                    % Choose the parents
                    if rand < delta
                        P = Bm(i, randperm(Tm));
                    else
                        P = randperm(Problem.N);
                    end
                    MatingPool(i) = P(1);
                    MatingPool(Problem.N + i) = P(2);
                end
                
                % Generate N offspring
                Offspring = OperatorGAhalf_2(Population(MatingPool));
                
                % Update the reference point
                z = min([z; Offspring.objs]);
                zmax = max(Archive.objs, [], 1);
                
                % Replacement
                Pt = [Population Offspring];
                objs_n = normalize_2(Pt.objs, z, zmax);  % normalization
                % Calculate the subproblem function values  O(N^2)
                g = zeros(size(objs_n,1), Problem.N);
                for i = 1 : Problem.N
                    g(:, i) = calSubpFitness(type, objs_n, zeros(1,Problem.M), W(i, :)) * h(i);
                end
                % Find the most suitable solution for each subproblem
                [~, I_subp] = min(g, [], 2);
                index_Pt = zeros(Problem.N, 1);
                select_counter = zeros(size(objs_n,1),1);
                for i = 1 : Problem.N
                    closest = find(I_subp==i & select_counter<Tr);  % a solution is selected at most Tr times.
                    if isempty(closest)
                        % index_Pt(i) = i;  % Pt should not be shuffled since we assume the i-th solution of Pt corresponds to the original solution of i-th subproblem.
                        [~,index_Pt(i)] = min(g(:,i));  % improve the convergence by this greedy method; it is helpful in finding the boundary of the concave PF when p=1
                        continue
                    end
                    [~, Ri] = min(g(closest, i));
                    index_Pt(i) = closest(Ri);
                    select_counter(closest(Ri)) = select_counter(closest(Ri)) + 1;
                end
                Population = Pt(index_Pt);

                % Maintenance operation in the archive set (for AdaW)
                Archive = [Archive,Offspring];
                Archive = ArchiveUpdate(Archive,2*Problem.N,z,zmax,alpha);

                % Update weights (for AdaW)
                if ~mod(ceil(Problem.FE/Problem.N),ceil(0.05*ceil(Problem.maxFE/Problem.N))) && Problem.FE <= Problem.maxFE*0.9
                    if length(Archive) > 1
                        [Population,W,h,B] = WeightUpdate(Population,W,1./W./sum(1./W,2),type,h,Archive,z,zmax,Tr,Problem);
                        Bm = B(:, 1:Tm);
                        % Br = B(:, 1:Tr);
                        % plot3(W_dir(:,1),W_dir(:,2),W_dir(:,3),'*'), view(135,30), grid on
                    end
                end
            end
        end
    end
end


%%
function objs_n = normalize_2(objs, lb, ub)
    objs_n = (objs - lb) ./ (ub - lb);
end


function [Population,W,h,B] = WeightUpdate(Population,W,W_dir,type,h,Archive,zmin,zmax,T,Problem)
% Weight Update
% Modified by Ruihao Zheng

%------------------------------- Copyright --------------------------------
% Copyright (c) 2024 BIMK Group. You are free to use the PlatEMO for
% research purposes. All publications which use this platform or any code
% in the platform should acknowledge the use of "PlatEMO" and reference "Ye
% Tian, Ran Cheng, Xingyi Zhang, and Yaochu Jin, PlatEMO: A MATLAB platform
% for evolutionary multi-objective optimization [educational forum], IEEE
% Computational Intelligence Magazine, 2017, 12(4): 73-87".
%--------------------------------------------------------------------------

    % Routine to find undeveloped individuals (correspondingly their weights) in the archive set
    % Normalisation
    N_arc = length(Archive);
    Archiveobjs = (Archive.objs-repmat(zmin,N_arc,1) ) ./ repmat(zmax-zmin,N_arc,1);
    Populationobjs = (Population.objs - repmat(zmin,Problem.N,1) )./repmat(zmax - zmin,Problem.N,1);
    zmin = (zmin-zmin)./(zmax-zmin);  % 实际上为0，计算标量化函数值的zmin可以不用去掉
    % Euclidean distance between individuals in the archive set and individuals in the Population
    dis1 = pdist2(Archiveobjs,Populationobjs);
    dis1 = sort(dis1,2);
    % Euclidean distance between any two individuals in the archive set
    dis2 = pdist2(Archiveobjs,Archiveobjs);
    dis2 = sort(dis2,2);
    % Calculate the niche size(median of the distances from their closest solution in the archive )
    niche_size = median(dis2(:,2));
    % Find undeveloped 
    index = dis1(:,1) >= niche_size;
    Archive_und = Archive(index);
    Archiveundobjs = Archiveobjs(index,:);  % not re-normalize since it is a significantly biased subset
    
    % If the undeveloped individuals are promising then add them into the evolutionary Population         
    % Obtain their corresponding weights.
    if ~isempty(Archive_und)
        W1_dir = (Archiveundobjs-zmin) ./ sum(Archiveundobjs-zmin,2);
        W1_dir(W1_dir==0) = 1e-6;  % avoid nan in W1
        W1 = 1./W1_dir./sum(1./W1_dir,2);
        h1 = (prod(W1,2).^(-1/Problem.M));
        for i = 1 : size(W1_dir,1)
            W_all = [W_dir;W1_dir(i,:)];
            B1 = pdist2(W_all,W_all);
            B1(logical(eye(length(B1)))) = inf;
            [~,B1] = sort(B1,2);
            B1 = B1(:,1:T);

            Population1objs = [Populationobjs;Archiveundobjs(i,:)];
            Population2objs = Population1objs(B1(end,:),:);

            Value_GLp_all = calSubpFitness(type, Population2objs, zeros(1,Problem.M), W1(i,:)) .* h1(i);
            Value_GLp     = calSubpFitness(type, Archiveundobjs(i,:), zeros(1,Problem.M), W1(i,:)) .* h1(i);

            index = find(Value_GLp_all<Value_GLp, 1);

            if isempty(index)
                % Put the wight into the W, as well as the corresponding solution
                W_dir = [W_dir; W1_dir(i,:)];
                W = [W; W1(i,:)];
                h = [h; h1(i)];
                Population = [Population Archive_und(i)];
                Populationobjs = [Populationobjs; Archiveundobjs(i,:)];

                % Update neighbour solutions after adding a weight
                P = B1(end,:);
                g_old = calSubpFitness(type, Populationobjs(P,:), zeros(1,Problem.M), W(P,:)) .* h(P);
                g_new = calSubpFitness(type, Archiveundobjs(i,:), zeros(1,Problem.M), W(P,:)) .* h(P);
                index2 = P(g_old > g_new);
                Population(index2) = Archive_und(i);
                Populationobjs(index2,:) = repmat(Archiveundobjs(i,:),length(index2),1);
            end
        end
    end
    
    % Delete the poorly performed weights until the size of W is reduced to N
    % find out the solution that is shared by the most weights in the population
    while length(Population) > Problem.N
        [~,ai,bi] = unique(Population.objs,'rows');
        PCObj = (Population.objs-repmat(zmin,length(Population),1))./repmat(zmax-zmin,length(Population),1);
        if length(ai) == length(bi)   % If every solution in the population corresponds to only one weight
            % Determine the radius of the niche
            d  = pdist2(PCObj,PCObj);
            d(logical(eye(length(d)))) = inf;
            sd = sort(d,2);
            num_obj = size(Population.objs,2);
            r  = median(sd(:,min(num_obj,size(sd,2))));
            R  = min(d./r,1);
            % Delete solution one by one
            while length(Population) > Problem.N
                [~,worst]  = max(1-prod(R,2));
                Population(worst)  = [];
                PCObj(worst,:) = [];
                R(worst,:) = [];
                R(:,worst) = [];
                W_dir(worst,:) = [];
                W(worst,:) = [];
                h(worst) = [];
            end
        else
            index = find(bi==mode(bi));
            Value_GLp2 = calSubpFitness(type, PCObj(index,:), zeros(1,Problem.M), W(index,:)) .* h(index);
            
            Index_max= find(Value_GLp2 == max(Value_GLp2));
            Population(index(Index_max(1)))=[];
            W_dir(index(Index_max(1)),:)=[];
            W(index(Index_max(1)),:)=[];
            h(index(Index_max(1)))=[];
        end
    end
    % Update the neighbours of each weight
    B = pdist2(W_dir,W_dir);
    [~,B] = sort(B,2);
    % B = B(:,1:T);
end


function Archive = ArchiveUpdate(Archive,N,zmin,zmax,alpha)
% Archive Update
% Modified by Ruihao Zheng

%------------------------------- Copyright --------------------------------
% Copyright (c) 2024 BIMK Group. You are free to use the PlatEMO for
% research purposes. All publications which use this platform or any code
% in the platform should acknowledge the use of "PlatEMO" and reference "Ye
% Tian, Ran Cheng, Xingyi Zhang, and Yaochu Jin, PlatEMO: A MATLAB platform
% for evolutionary multi-objective optimization [educational forum], IEEE
% Computational Intelligence Magazine, 2017, 12(4): 73-87".
%--------------------------------------------------------------------------

    arcobjs = (Archive.objs - zmin) ./ (zmax - zmin);  % normalization
    index = NDSort((1-alpha)*arcobjs + (alpha/length(zmin))*sum(arcobjs,2), 1) == 1;
    Archive = Archive(index);
    arcobjs = arcobjs(index,:);
    PCObj = arcobjs;
    if isempty(Archive)
        return;
    else
        if length(Archive) > N
            % Determine the radius of the niche
            d  = pdist2(PCObj,PCObj);
            d(logical(eye(length(d)))) = inf;
            sd = sort(d,2);
            r  = median(sd(:,min(size(PCObj,2),size(sd,2))));
            R  = min(d./r,1);
            % Delete solution one by one
            while length(Archive) > N
                [~,worst]  = max(1-prod(R,2));
                Archive(worst)  = [];
                R(worst,:) = [];
                R(:,worst) = [];
            end         
        end
    end
end
