% grid making and saving
% pdegrid
% save('mygrid','p','e','t')
clc
%% Actual grid
% ACTUAL GRID DO NOT DELETE

% params.mesh_number = 3;
% params.gridtype = 'triagrid';
% params.grid_initfile = ['mygridnirav', num2str(params.mesh_number), '.mat'];
% % params.bnd_rect_corner1=[-1,-1;-eps,eps]'; % for analytical
% % params.bnd_rect_corner2=[eps,1+eps;eps,1-3*10^14*eps]';% for analytical ex.
% params.bnd_rect_corner1=[-1,-1;100,10]'; % for benchmark problem
% params.bnd_rect_corner2=[2,2;100,10-eps]'; % for benchmark problem
% % params.bnd_rect_corner1=[-1,-1;1-eps,3*10^14*eps]'; % for standard
% % params.bnd_rect_corner2=[eps,1+eps;1+eps,1-eps]'; % for standard
% params.bnd_rect_index=[-1,-2];
% grid=construct_grid(params);
% show_sparsity = false; % Bool variable which plots sparsity pattern of
% % assembled matrix is set to true else(i.e. false) the sparsity pattern is not shown
% params.show_sparsity = show_sparsity;
% paramsP.show_sparsity = show_sparsity;

%ACTUAL GRID OVER

%% Test grid

%ONLY FOR TEST GRID
h = [6 8];
pde = [2 3 4];
error_l2_velocity = zeros(length(h),length(pde));
error_l2_pressure = zeros(length(h),length(pde));
error_h0_velocity = zeros(length(h),length(pde));
error_l2_pressure = zeros(length(h),length(pde));
for i = 1:1:length(h)
    for j = 1:1:length(pde)
        h(i)
        pde(j)
        params.xrange = [0,1];
        params.yrange = [0,1];
        params.xnumintervals = h(i);
        params.ynumintervals = h(i);
        params.bnd_rect_corner1=[-1,-1;-eps,eps]'; % for analytical
        params.bnd_rect_corner2=[2,2;eps,1-(1/params.xnumintervals/1.8)]';% for analytical ex.
        params.bnd_rect_corner1=[-1,-1;1-eps,1/params.xnumintervals/1.8]';
        params.bnd_rect_corner2=[eps,1+eps;1+eps,1-eps]';
        params.bnd_rect_index=[-1,-2];
params.gridtype = 'triagrid';
grid = construct_grid(params);
show_sparsity = false; % Bool variable which plots sparsity pattern of
% assembled matrix is set to true else(i.e. false) the sparsity pattern is not shown
params.show_sparsity = show_sparsity;
paramsP.show_sparsity = show_sparsity;

%TEST GRID OVER

%% Plotting of grid
disp('Please check the grid')
figure()
plot(grid);
title('Grid')
% pause();
% close all
params.pdeg = pde(j);
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
qdeg=pde(j);
params.mu=4;
params.kinematic_viscosity = @(params) params.mu*1e-6;
mu = params.kinematic_viscosity(params);
c11 = 1e2;% penalty parameter, must be large enough for coercivity

%% Assembly of stiffness matrix

[ params, paramsP, rhs, stifness_matrix] = assemble_stifness_matrix...
    ( params, paramsP, grid, qdeg, mu, c11 );

%% Stokes problem

% tic;
% [ params, paramsP, achieved_residual_tol_schur] =...
%     solve_plot_solution_schur( params, paramsP, grid, rhs, stifness_matrix);
% time_schur = toc;

required_residual_tol = 0;%achieved_residual_tol_schur; % allowable residual
max_iter = 1e7; % maximum number of iterations

tic;
[ params, paramsP, flag, achieved_residual_tol, actual_iter] = solve_plot_solution...
    ( params, paramsP, grid, rhs, stifness_matrix, required_residual_tol, max_iter);
times_solver = toc;

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
%         tol_newton = 1e-12;
%         max_iter_newton = 30;
%         tol_solver = 1e-6;
%         max_iter_solver = 100;
% 
%         [ params,paramsP,flag,relres_solver,iter_solver,...
%             relres_newton, iter_newton, stifness_matrix_nonlinear ] =...
%             newton_script( params,paramsP,grid,qdeg,mu,c11,...
%             tol_newton,max_iter_newton,stifness_matrix, tol_solver, max_iter_solver);
%
%% non linear Stiffness matrix tests
%
% disp('Entering into stiffness matrix tests')
% [ eigen_vectors, eigen_values, condition_number, rank_matrix] = stifness_matrix_test...
% ( stifness_matrix_nonlinear, params, paramsP, grid, qdeg );

%% ERROR FUNCTION CALL

% Analytical from paper

%         params.dof_analytical = @(glob)...
%             [glob(1)^2*(1-glob(1))^2*(2*glob(2)-6*glob(2)^2+4*glob(2)^3) ...
%             -glob(2)^2*(1-glob(2))^2*(2*glob(1)-6*glob(1)^2+4*glob(1)^3)];
%         params.dof_derivative_analytical = @(glob)...
%             [(2*glob(2)-6*(glob(2))^2+4*(glob(2))^3) ...
%             glob(1)^2*(1-glob(1))^2*(2-12*glob(2)+12*glob(2)^2);...
%             -glob(2)^2*(1-glob(2))^2*(2-12*glob(1)+12*glob(1)^2) ...
%             -(2*glob(1)-6*glob(1)^2+4*glob(1)^3)*(glob(2)^2+glob(2)^4-2*glob(2)^3)];
%         paramsP.dof_analytical = @(glob) (glob(1)*(1-glob(1)));
%         paramsP.dof_derivative_analytical = @(glob) [(1-2*glob(1)) 0];
        %
% % Standard
%
params.dof_analytical = @(glob) [glob(2)*(1-glob(2)) 0];
params.dof_derivative_analytical = @(glob) [0 1-2*glob(2);0 0];
paramsP.dof_analytical = @(glob) (1-glob(1));
paramsP.dof_derivative_analytical = @(glob) [-1 0];

%% L^2 norm
[ error_l2_velocity(i,j)] = error_l2_norm_assembly( params, grid, qdeg );
[ error_l2_pressure(i,j)] = error_l2_norm_assembly( paramsP, grid, qdeg );
%
%% H_0 norm
[ error_h0_velocity(i,j)] = error_h0_norm_assembly( params, grid, qdeg );
[ error_h0_pressure(i,j)] = error_h0_norm_assembly( paramsP, grid, qdeg );
    end
end
save('ehvelocity.mat','error_h0_velocity');
save('ehpressure.mat','error_h0_pressure');
save('elpressure.mat','error_l2_pressure');
save('elvelocity.mat','error_l2_velocity');
save('pconvstepsize.mat','h');
p_convergence_plotter