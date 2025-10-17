function current = find_kappa(DCIVtable, voltage)
    [~, idxmin] = min(abs(DCIVtable.Voltage-voltage));
    if voltage < DCIVtable.Voltage(idxmin)
        slope = (DCIVtable.Current(idxmin)-DCIVtable.Current(idxmin-1))/(DCIVtable.Voltage(idxmin)-DCIVtable.Voltage(idxmin-1));

    else
        slope = (DCIVtable.Current(idxmin+1)-DCIVtable.Current(idxmin))/(DCIVtable.Voltage(idxmin+1)-DCIVtable.Voltage(idxmin));
    end
    current = (slope*(voltage-DCIVtable.Voltage(idxmin))+DCIVtable.Current(idxmin))*.001;
end