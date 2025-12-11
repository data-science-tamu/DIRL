cost_lossTPInspection = 0;

% Cost import
cell.lossThroughput_cost = unit_cost_lossThroughput ; % Cost: Individual Maintenance 
cell.proportionLossTPMaintenance = proportion_LossTPMaintenance;
cell.proportionLossTPInspection = proportion_LossTPInspection;
cell.failureToThroughput = failureToThroughput;
cell.fixedMaintenacetoCost = fixedMaintenacetoCost;
cell.fixedCostToInitiateMaintenace = fixedCostToInitiateMaintenace;

if inspection_everytime 
    cell.inspectionEverytime = true;
else
    cell.inspectionEverytime = false;
end

if proportion_LossTPInspection == 0
     cell.inspectionAction = false;
else
     cell.inspectionAction = true;
end

%% Loaf Setting from file
%Read setting file
cellSetting = readtable(settingFileName,'HeaderLines',0,'ReadVariableNames',true);
unit = 0;

nbCell = length(unique(cellSetting.processID));
for i = 1:nbCell
    indexProcessList = find(cellSetting.processID ==i);
    numType =  length(indexProcessList);
    for j = 1:numType
        qtyMCType = cellSetting.quantity(indexProcessList(j));
        unit = unit + qtyMCType;
        if j == 1
            process_thrput = ones(1,qtyMCType)*cellSetting.Throughput(indexProcessList(j)) ;
            process_mean_beta = ones(1,qtyMCType)* cellSetting.mean_beta(indexProcessList(j)) ;
            process_var_beta  = ones(1,qtyMCType)* cellSetting.var_beta(indexProcessList(j)) ;
            process_var_meas_err  = ones(1,qtyMCType)* cellSetting.var_measurement_err(indexProcessList(j)) ;
            process_th  = ones(1,qtyMCType)* cellSetting.Threshold(indexProcessList(j)) ;
            process_mean_unit0 = ones(1,qtyMCType)* cellSetting.mean_unit0(indexProcessList(j)) ;
            process_var_unit0  = ones(1,qtyMCType)* cellSetting.var_unit0(indexProcessList(j)) ;
            process_replace_cost = ones(1,qtyMCType)* cellSetting.replacement_cost(indexProcessList(j)) ;
            process_fix_cost  = ones(1,qtyMCType)* cellSetting.fix_cost(indexProcessList(j)) ;
            process_failure_cost  = ones(1,qtyMCType)* cellSetting.failure_cost(indexProcessList(j)) ;
        else
            process_thrput = [process_thrput ,ones(1,qtyMCType)*cellSetting.Throughput(indexProcessList(j)) ];
            process_mean_beta = [process_mean_beta ,ones(1,qtyMCType) * cellSetting.mean_beta(indexProcessList(j))] ;
            process_var_beta = [process_var_beta ,ones(1,qtyMCType) * cellSetting.var_beta(indexProcessList(j))] ;
            process_var_meas_err = [process_var_meas_err ,ones(1,qtyMCType) * cellSetting.var_measurement_err(indexProcessList(j))] ;
            process_th = [process_th ,ones(1,qtyMCType) * cellSetting.Threshold(indexProcessList(j))] ;
            process_mean_unit0 = [process_mean_unit0 ,ones(1,qtyMCType) * cellSetting.mean_unit0(indexProcessList(j))] ;
            process_var_unit0 = [process_var_unit0 ,ones(1,qtyMCType) * cellSetting.var_unit0(indexProcessList(j))] ;
            process_replace_cost = [process_replace_cost ,ones(1,qtyMCType) * cellSetting.replacement_cost(indexProcessList(j))] ;
            process_fix_cost = [process_fix_cost ,ones(1,qtyMCType) * cellSetting.fix_cost(indexProcessList(j))] ;
            process_failure_cost = [process_failure_cost ,ones(1,qtyMCType) * cellSetting.failure_cost(indexProcessList(j))] ;
        end
    end
    cell.thrput{i} = process_thrput;
    cell.mean_beta{i} = process_mean_beta;
    cell.var_beta{i} = process_var_beta;
    cell.var_meas_err{i} = process_var_meas_err;
    cell.th{i} = process_th;
    cell.mean_unit0{i} = process_mean_unit0;
    cell.var_unit0{i} = process_var_unit0;
    cell.replace_cost{i} = process_replace_cost;
    cell.fix_cost{i} = process_fix_cost;
    cell.failure_cost{i} = process_failure_cost;
end
    


%% Evaluate throughput
actual_cap =  cell.thrput;
process_num = length(actual_cap);
cap_per_process  = zeros(process_num,1);
run_component_id = 1;
for i= 1:process_num
   num_comp_per_process = length(actual_cap{i});
   cap_per_process(i) = sum(actual_cap{i});
   run_component_id = run_component_id + num_comp_per_process;
end
actual_thrput = min(cap_per_process);
fprintf('Max throughput in the complex setting is %d\n',actual_thrput);




