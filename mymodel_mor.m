% grid making and saving
% pdegrid
% save('mygrid','p','e','t')
clc
%% Parameter generation
% disp('Generating training and test parameter set')
% max_value_train1 = 10;
% min_value_train1 = 20;
% num_para_train1 = 10;
% max_value_test1 = 100;
% min_value_test1 = 90;
% num_para_test1 = 10;
% [ res1] = gen_parameters( max_value_train1, min_value_train1, ...
%     max_value_test1, min_value_test1, num_para_train1, num_para_test1 );
% max_value_train2 = 10;
% min_value_train2 = 20;
% num_para_train2 = 10;
% max_value_test2 = 100;
% min_value_test2 = 90;
% num_para_test2 = 10;
% [ res2] = gen_parameters( max_value_train2, min_value_train2, ...
%     max_value_test2, min_value_test2, num_para_train2, num_para_test2 );
% max_value_train3 = 10;
% min_value_train3 = 20;
% num_para_train3 = 10;
% max_value_test3 = 100;
% min_value_test3 = 90;
% num_para_test3 = 10;
% [ res3] = gen_parameters( max_value_train3, min_value_train3, ...
%     max_value_test3, min_value_test3, num_para_train3, num_para_test3 );
% parameter_training_set = [res1.train_para';res2.train_para';res3.train_para']';
% parameter_test_set = [res1.test_para';res2.test_para';res3.test_para']';
% disp('Parameter training and test set generation finished')

%% Actual grid
% ACTUAL GRID DO NOT DELETE

params.mesh_number = 3;
params.gridtype = 'triagrid';
params.grid_initfile = ['mygridnirav', num2str(params.mesh_number), '.mat'];
% params.bnd_rect_corner1=[-1,-1;-eps,eps]'; % for analytical
% params.bnd_rect_corner2=[eps,1+eps;eps,1-3*10^14*eps]';% for analytical ex.
params.bnd_rect_corner1=[-1,-1;100,10]'; % for benchmark problem
params.bnd_rect_corner2=[2,2;100,10-eps]'; % for benchmark problem
% params.bnd_rect_corner1=[-1,-1;1-eps,3*10^14*eps]'; % for standard
% params.bnd_rect_corner2=[eps,1+eps;1+eps,1-eps]'; % for standard
params.bnd_rect_index=[-1,-2];
grid=construct_grid(params);
show_sparsity = false; % Bool variable which plots sparsity pattern of
% % assembled matrix is set to true else(i.e. false) the sparsity pattern is not shown
params.show_sparsity = show_sparsity;
paramsP.show_sparsity = show_sparsity;

%ACTUAL GRID OVER

%% Test grid

%ONLY FOR TEST GRID

% params.xrange = [0,1];
% params.yrange = [0,1];
% params.xnumintervals = 10;
% params.ynumintervals = 10;
% params.bnd_rect_corner1=[-1,-1;-eps,eps]'; % for analytical
% params.bnd_rect_corner2=[2,2;eps,1-0.06]';% for analytical ex.
% % params.bnd_rect_corner1=[-1,-1;1-eps,0+3*10^14*eps]';
% % params.bnd_rect_corner2=[eps,1+eps;1+eps,1-eps]';
% params.bnd_rect_index=[-1,-2];
% params.gridtype = 'triagrid';
% grid = construct_grid(params);
% show_sparsity = false; % Bool variable which plots sparsity pattern of
% %assembled matrix is set to true else(i.e. false) the sparsity pattern is not shown
% params.show_sparsity = show_sparsity;
% paramsP.show_sparsity = show_sparsity;

%TEST GRID OVER

%% Plotting of grid
disp('Please check the grid')
figure()
plot(grid);
title('Grid')
% pause();
% close all
% for i = 1:1:size(parameter_training_set,1)
    %% Values setting
    params.parameter_training_set = parameter_training_set(i,:);
    params.pdeg = 2;
    paramsP.pdeg = params.pdeg-1;%taylor hood element
    params.dimrange = 2;
    paramsP.dimrange = 1;
    params.grid = grid;
    paramsP.grid = grid;
    
    nrep=[3 6 10 15];
    
    params.ndofs_per_element= nrep(params.pdeg)*params.dimrange;
    params.ndofs = params.ndofs_per_element*grid.nelements;
    params.dofs = zeros(params.ndofs,1);
    
    paramsP.ndofs_per_element= nrep(paramsP.pdeg)*paramsP.dimrange;
    paramsP.ndofs = paramsP.ndofs_per_element*grid.nelements;
    paramsP.dofs = zeros(paramsP.ndofs,1);
    
    df_info=ldginfo(params,grid);
    df=ldgdiscfunc(df_info);
    display(df);
    qdeg=3;
    params.mu=4;
    params.kinematic_viscosity = @(params) params.mu*1e-6;
    mu = params.kinematic_viscosity(params);
    c11 = params.parameter_training_set(1);% penalty parameter, must be large enough for coercivity
    
    %% Assembly of stiffness matrix
    
    [ params, paramsP, rhs, stifness_matrix] = assemble_stifness_matrix...
        ( params, paramsP, grid, qdeg, mu, c11 );
    
    %% Stokes problem
    
    tic;
    [ params, paramsP, achieved_residual_tol_schur] =...
        solve_plot_solution_schur( params, paramsP, grid, rhs, stifness_matrix);
    time_schur = toc;
    
    required_residual_tol = 0;%achieved_residual_tol_schur; % allowable residual
    max_iter = 1e5; % maximum number of iterations
    
    % tic;
    % [ params, paramsP, flag, achieved_residual_tol, actual_iter] = solve_plot_solution...
    %     ( params, paramsP, grid, rhs, stifness_matrix, required_residual_tol, max_iter);
    % times_solver = toc;
    
    %% Stiffness matrix tests
    
    % disp('Entering into stiffness matrix tests')
    % [ eigen_vectors, eigen_values, condition_number, rank_matrix] = stifness_matrix_test...
    % ( stifness_matrix, params, paramsP, grid, qdeg );
    
    %% Penalty parameter tests
    % c11_min = 1e-3;
    % c11_max = 1e5;
    % c11_num_interval = 10;
    % [ condition_number, c11 ] = c11_condition_number...
    %     ( params, paramsP, grid, qdeg, mu, c11_min, c11_max, c11_num_interval );
    % [ solution_norm, c11] = c11_solution( params, paramsP, grid, qdeg,...
    %     mu, required_residual_tol, max_iter, c11_min, c11_max, c11_num_interval);
    
    
    %% Navier Stokes
    tol_newton = 1e-12;
    max_iter_newton = 10;
    tol_solver = 1e-13;
    max_iter_solver = 100;
    
    [ params,paramsP,flag,relres_solver,iter_solver,...
        relres_newton, iter_newton, stifness_matrix_nonlinear ] =...
        newton_script( params,paramsP,grid,qdeg,mu,c11,...
        tol_newton,max_iter_newton,stifness_matrix, tol_solver, max_iter_solver);
    %
    % %% non linear Stiffness matrix tests
    % %
    % % disp('Entering into stiffness matrix tests')
    % % [ eigen_vectors, eigen_values, condition_number, rank_matrix] = stifness_matrix_test...
    % % ( stifness_matrix_nonlinear, params, paramsP, grid, qdeg );
    
    %% ERROR FUNCTION CALL
    
    % Analytical from paper
    
    % params.dof_analytical = @(glob)...
    %     [glob(1)^2*(1-glob(1))^2*(2*glob(2)-6*glob(2)^2+4*glob(2)^3) ...
    %     -glob(2)^2*(1-glob(2))^2*(2*glob(1)-6*glob(1)^2+4*glob(1)^3)];
    % params.dof_derivative_analytical = @(glob)...
    %      [(2*glob(2)-6*(glob(2))^2+4*(glob(2))^3) ...
    %      glob(1)^2*(1-glob(1))^2*(2-12*glob(2)+12*glob(2)^2);...
    %     -glob(2)^2*(1-glob(2))^2*(2-12*glob(1)+12*glob(1)^2) ...
    %     -(2*glob(1)-6*glob(1)^2+4*glob(1)^3)*(glob(2)^2+glob(2)^4-2*glob(2)^3)];
    % paramsP.dof_analytical = @(glob) (glob(1)*(1-glob(1)));
    % paramsP.dof_derivative_analytical = @(glob) [(1-2*glob(1)) 0];
    %
    % % Standard
    %
    % params.dof_analytical = @(glob) [glob(2)*(1-glob(2)) 0];
    % params.dof_derivative_analytical = @(glob) [0 1-2*glob(2);0 0];
    % paramsP.dof_analytical = @(glob) (1-glob(1));
    % paramsP.dof_derivative_analytical = @(glob) [-1 0];
    
    %% L^2 norm
    % [ error_l2_velocity ] = error_l2_norm_assembly( params, grid, qdeg );
    % [ error_l2_pressure ] = error_l2_norm_assembly( paramsP, grid, qdeg );
    %
    % %% h0 NORM Implemenetation needs to be verified
    % [ error_h0_velocity ] = error_h0_norm_assembly( params, grid, qdeg );
    % [ error_h0_pressure ] = error_h0_norm_assembly( paramsP, grid, qdeg );
    
    %% Miscelanneous
    % k = -2:1:5;
    % figure()
    % plot(10.^k,error_l2_velocity)
    % title('Error L^2 velocity vs penalty parameter')
    % xlabel('Penalty parameter')
    % ylabel('Error L^2 velocity')
    % figure()
    % plot(10.^k,error_l2_pressure)
    % title('Error L^2 pressure vs penalty parameter')
    % xlabel('Penalty parameter')
    % ylabel('Error L^2 pressure')
    params.snapshots_matrix(:,i) = params.dofs;
    paramsP.snapshots_matrix(:,i) = paramsP.dofs;
    %% Proper Orthogonal Decomposition
% end

% n_s = size(params.snapshots_matrix,2); % number of snapshots
% % params.snapshots_matrix = rand(params.ndofs,n_s);
% disp('Check affine decomposition')
% red_dim = 8;
% min_eigen = 1e-10;
% params.qdeg = qdeg;
% paramsP.qdeg = qdeg;
% [ pod_res_params] = pod( params, grid, red_dim, min_eigen,stifness_matrix);
% [ pod_res_paramsP] = pod( paramsP, grid, red_dim, min_eigen,stifness_matrix);
% disp('Implement galerkin formulation')