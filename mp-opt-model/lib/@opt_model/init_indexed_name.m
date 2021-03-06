function om = init_indexed_name(om, set_type, name, dim_list)
%INIT_INDEXED_NAME  Initializes the dimensions for an indexed named set.
%
%   OM.INIT_INDEXED_NAME(SET_TYPE, NAME, DIM_LIST)
%
%   Initializes the dimensions for an indexed named variable, constraint
%   or cost set.
%
%   Variables, constraints and costs are referenced in OPT_MODEL in terms
%   of named sets. The specific type of named set being referenced is
%   given by SET_TYPE, with the following valid options:
%       SET_TYPE = 'var'   => variable set
%       SET_TYPE = 'lin'   => linear constraint set
%       SET_TYPE = 'nle'   => nonlinear equality constraint set
%       SET_TYPE = 'nli'   => nonlinear inequality constraint set
%       SET_TYPE = 'qdc'   => quadratic cost set
%       SET_TYPE = 'nlc'   => nonlinear cost set
%
%   Indexed Named Sets
%
%   A variable, constraint or cost set can be identified by a single NAME,
%   such as 'Pmismatch', or by a name that is indexed by one or more indices,
%   such as 'Pmismatch(3,4)'. For an indexed named set, before adding the
%   indexed variable, constraint or cost sets themselves, the dimensions of
%   the indexed set must be set by calling INIT_INDEXED_NAME, where
%   DIM_LIST is a cell array of the dimensions.
%
%   Examples:
%       %% linear constraints with indexed named set 'R(i,j)'
%       om.init_indexed_name('lin', 'R', {2, 3});
%       for i = 1:2
%         for j = 1:3
%           om.add_lin_constraint('R', {i, j}, A{i,j}, ...);
%         end
%       end
%
%   See also OPT_MODEL, ADD_VAR, ADD_LIN_CONSTRAINT, ADD_NLN_CONSTRAINT,
%            ADD_QUAD_COST and ADD_NLN_COST.

%   MP-Opt-Model
%   Copyright (c) 2008-2020, Power Systems Engineering Research Center (PSERC)
%   by Ray Zimmerman, PSERC Cornell
%
%   This file is part of MP-Opt-Model.
%   Covered by the 3-clause BSD License (see LICENSE file for details).
%   See https://github.com/MATPOWER/mp-opt-model for more info.

%% use column vector if single dimension
if length(dim_list) == 1
    dim_list = {dim_list{:}, 1};
end

%% call parent method (also checks for valid type for named set)
om = init_indexed_name@mp_idx_manager(om, set_type, name, dim_list);

%% add type-specific info about this named set
empty_cell  = cell(dim_list{:});
switch set_type
    case 'var'          %% variable set
        om.var.data.v0.(name)   = empty_cell;   %% initial value
        om.var.data.vl.(name)   = empty_cell;   %% lower bound
        om.var.data.vu.(name)   = empty_cell;   %% upper bound
        om.var.data.vt.(name)   = empty_cell;   %% variable type
    case 'lin'          %% linear constraint set
        om.lin.data.A.(name)   = empty_cell;
        om.lin.data.l.(name)   = empty_cell;
        om.lin.data.u.(name)   = empty_cell;
        om.lin.data.vs.(name)  = empty_cell;
    case {'nle', 'nli'} %% nonlinear constraint set
        om.(set_type).data.fcn.(name) = empty_cell;
        om.(set_type).data.hess.(name)= empty_cell;
        om.(set_type).data.vs.(name)  = empty_cell;
end
