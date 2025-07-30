clear all
close all
clc

filename = ['C:\Users\grgo8200\Documents\GitHub\summer2025_loadpull_repo\data\coupledline_samplers\' ...
    'MMIC_coupledline_phase2025-07-29_11_19_Freq12.0to8.0'];
temp = CoupledLinePhaseClass(filename);

temp.scaling_samplers_cal