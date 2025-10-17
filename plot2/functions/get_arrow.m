function arrow = get_arrow(arrow_point)
    XL = get(gca, 'XLim');
    YL = get(gca, 'YLim');
    Xran = XL(2)-XL(1);
    Yran = YL(2)-YL(1);
    arrow_length = sqrt((0.15*Yran)^2+(0.15*Xran)^2);
    switch true
        case arrow_point(1) < (Xran/2+XL(1)) && arrow_point(2) < (Yran/2+YL(1))
            x_sign = 0.15;
            y_sign = 0.15;
            az = 45;
        case arrow_point(1) < (Xran/2+XL(1)) && arrow_point(2) > (Yran/2+YL(1))
            x_sign = 0.15;
            y_sign = -0.15;
            az = 135;
        case arrow_point(1) > (Xran/2+XL(1)) && arrow_point(2) < (Yran/2+YL(1))
            x_sign = -0.15;
            y_sign = 0.15;
            az = -45;
        case arrow_point(1) > (Xran/2+XL(1)) && arrow_point(2) > (Yran/2+YL(1))
            x_sign = -0.15;
            y_sign = -0.15;
            az = -135;
        otherwise 
            return 
    end

    updated_point = [arrow_point(1)-x_sign*Xran, arrow_point(2)-y_sign*Yran];
    arrow = [updated_point, x_sign*Xran, y_sign*Yran];
end