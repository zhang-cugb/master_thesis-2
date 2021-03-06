function [ res ] = n_u_tensor_jump_n_phi_tensor_jump_plus_plus_integral...
    ( params, grid, tria_index, local_vertex_index, qdeg )
%N_U_TENSOR_JUMP_N_PHI_TENSOR_JUMP_PLUS_PLUS_INTEGRAL Summary of this function goes here
%   Detailed explanation goes here

f = @(llcoord) n_u_tensor_jump_n_phi_tensor_jump_plus_plus_local( llcoord,...
    params, grid, tria_index, local_vertex_index);

res = intervalquadrature(qdeg,f)*grid.EL(tria_index,local_vertex_index);

end