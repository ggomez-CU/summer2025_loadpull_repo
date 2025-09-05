%% Newton's Method
clear all
close all
clc

filename = '/Users/gracegomez/Documents/Research Code Python/summer2025_loadpull_repo/data/PA_Spring2023/PhaseAlignment2025-08-14_14_44_Freq12.0to8.0/draincurrent_1.25mA';
temp = CoupledLinePhaseClass(filename);

%%
save data
%%
load data 
fplot = temp.freq;

loadangle = permute(mean((temp.complex_load),1),[2 3 1]);

for freq_idx =1:size(temp.freq,2)

    clearvars -except freq_idx
    load data
    loadangle = permute(mean((temp.complex_load),1),[2 3 1]);
    x1 = loadangle(:,freq_idx);
    v1 = permute(mean(temp.sampler1(:,:,freq_idx),1),[2 3 1]);
    v2 = permute(mean(temp.sampler2(:,:,freq_idx),1),[2 3 1]);

    % clear phs1 phs2 Av1 Av2 offset1 offset2 z0;
    syms a b c d e g h

    zL = 50*(x1(:)+1)./(1-x1(:));
    gammaL = (zL-h)./(zL+h);
    gm = c*abs(gammaL*exp(-j*a)+exp(j*a)).^2+e+ d*abs(gammaL*exp(-j*b)+exp(j*b)).^2+g;
    
    dd = v1(:);
    f = ( dd - gm )' * ( dd - gm ) ;
    sym_dfda = diff (f , a ) ;
    sym_dda_dfda = diff (f , a , a ) ; % 1
    sym_ddb_dfda = diff (f , a , b ) ; % 2
    sym_ddc_dfda = diff (f , a , c ) ; % 3
    sym_ddd_dfda = diff (f , a , d ) ; % 4
    sym_dde_dfda = diff (f , a , e ) ; % 5
    sym_ddg_dfda = diff (f , a , g ) ; % 6
    sym_ddh_dfda = diff (f , a , h ) ; % 7
    
    sym_dfdb = diff (f , b ) ;
    sym_ddb_dfdb = diff (f , b , b ) ; % 2
    sym_ddc_dfdb = diff (f , b , c ) ; % 3
    sym_ddd_dfdb = diff (f , b , d ) ; % 4
    sym_dde_dfdb = diff (f , b , e ) ; % 5
    sym_ddg_dfdb = diff (f , b , g ) ; % 6
    sym_ddh_dfdb = diff (f , b , h ) ; % 7
    
    sym_dfdc = diff (f , c ) ;
    sym_ddc_dfdc = diff (f , c , c ) ; % 3
    sym_ddd_dfdc = diff (f , c , d ) ; % 4
    sym_dde_dfdc = diff (f , c , e ) ; % 5
    sym_ddg_dfdc = diff (f , c , g ) ; % 6
    sym_ddh_dfdc = diff (f , c , h ) ; % 7
    
    sym_dfdd = diff (f , d ) ;
    sym_ddd_dfdd = diff (f , d , d ) ; % 4
    sym_dde_dfdd = diff (f , d , e ) ; % 5
    sym_ddg_dfdd = diff (f , d , g ) ; % 6
    sym_ddh_dfdd = diff (f , d , h ) ; % 7
    
    sym_dfde = diff (f , e ) ;
    sym_dde_dfde = diff (f , e , e ) ; % 5
    sym_ddg_dfde = diff (f , e , g ) ; % 6
    sym_ddh_dfde = diff (f , e , h ) ; % 7
    
    sym_dfdg = diff (f , g ) ;
    sym_ddg_dfdg = diff (f , g , g ) ; % 6
    sym_ddh_dfdg = diff (f , g , h ) ; % 7
    
    sym_dfdh = diff (f , h ) ;
    sym_ddh_dfdh = diff (f , h , h ) ; % 7


    max_itters =1e4;
    
    m = [pi/2,0,70,70,min(v1)*100,min(v2)*100,50];
    mstart = m;
    k = 1;
    objective_history = zeros(max_itters +1) ;
    objective_history (k) = sum( double ( subs ( f , {a , b , c , d, e , g, h} ,{ m(1) , m(2) , m(3) , m(4) , m(5) , m(6) , m(7)}) ) ) ;
    m_history = zeros (7 , max_itters +1) ;
    m_history (: ,1) = m ;
    converged = false ;
    figure ()
    lambda = 1; %not above

    while ~ converged
        clear J F H
        % compute gradient
        dfda = double ( subs ( sym_dfda , {a , b , c , d, e , g , h} ,{ m(1) , m(2) , m(3) , m(4) , m(5) , m(6) , m(7)}) );
        dfdb = double ( subs ( sym_dfdb , {a , b , c , d, e , g , h} ,{ m(1) , m(2) , m(3) , m(4) , m(5) , m(6) , m(7)}) );
        dfdc = double ( subs ( sym_dfdc , {a , b , c , d, e , g , h} ,{ m(1) , m(2) , m(3) , m(4) , m(5) , m(6) , m(7)}) );
        dfdd = double ( subs ( sym_dfdd , {a , b , c , d, e , g , h} ,{ m(1) , m(2) , m(3) , m(4) , m(5) , m(6) , m(7)}) );
        dfde = double ( subs ( sym_dfde , {a , b , c , d, e , g , h} ,{ m(1) , m(2) , m(3) , m(4) , m(5) , m(6) , m(7)}) );
        dfdg = double ( subs ( sym_dfdg , {a , b , c , d, e , g , h} ,{ m(1) , m(2) , m(3) , m(4) , m(5) , m(6) , m(7)}) );
        dfdh = double ( subs ( sym_dfdh , {a , b , c , d, e , g , h} ,{ m(1) , m(2) , m(3) , m(4) , m(5) , m(6) , m(7)}) );
        J = [ dfda dfdb dfdc dfdd dfde dfdg dfdh]';
    
        % compute hessian
        dda_dfda = double ( subs ( sym_dda_dfda , {a , b , c , d, e , g , h} ,{ m(1) , m(2) , m(3) , m(4) , m(5) , m(6) , m(7)}) );
        ddb_dfda = double ( subs ( sym_ddb_dfda , {a , b , c , d, e , g , h} ,{ m(1) , m(2) , m(3) , m(4) , m(5) , m(6) , m(7)}) );
        ddc_dfda = double ( subs ( sym_ddc_dfda , {a , b , c , d, e , g , h} ,{ m(1) , m(2) , m(3) , m(4) , m(5) , m(6) , m(7)}) );
        ddd_dfda = double ( subs ( sym_ddd_dfda , {a , b , c , d, e , g , h} ,{ m(1) , m(2) , m(3) , m(4) , m(5) , m(6) , m(7)}) );
        dde_dfda = double ( subs ( sym_dde_dfda , {a , b , c , d, e , g , h} ,{ m(1) , m(2) , m(3) , m(4) , m(5) , m(6) , m(7)}) );
        ddh_dfda = double ( subs ( sym_ddg_dfda , {a , b , c , d, e , g , h} ,{ m(1) , m(2) , m(3) , m(4) , m(5) , m(6) , m(7)}) );
        ddg_dfda = double ( subs ( sym_ddh_dfda , {a , b , c , d, e , g , h} ,{ m(1) , m(2) , m(3) , m(4) , m(5) , m(6) , m(7)}) );
    
        dda_dfdb = ddb_dfda ;
        ddb_dfdb = double ( subs ( sym_ddb_dfdb , {a , b , c , d, e , g , h} ,{ m(1) , m(2) , m(3) , m(4) , m(5) , m(6) , m(7)}) );
        ddc_dfdb = double ( subs ( sym_ddc_dfdb , {a , b , c , d, e , g , h} ,{ m(1) , m(2) , m(3) , m(4) , m(5) , m(6) , m(7)}) );
        ddd_dfdb = double ( subs ( sym_ddd_dfdb , {a , b , c , d, e , g , h} ,{ m(1) , m(2) , m(3) , m(4) , m(5) , m(6) , m(7)}) );
        dde_dfdb = double ( subs ( sym_dde_dfdb , {a , b , c , d, e , g , h} ,{ m(1) , m(2) , m(3) , m(4) , m(5) , m(6) , m(7)}) );
        ddh_dfdb = double ( subs ( sym_ddg_dfdb , {a , b , c , d, e , g , h} ,{ m(1) , m(2) , m(3) , m(4) , m(5) , m(6) , m(7)}) );
        ddg_dfdb = double ( subs ( sym_ddh_dfdb , {a , b , c , d, e , g , h} ,{ m(1) , m(2) , m(3) , m(4) , m(5) , m(6) , m(7)}) );

        dda_dfdc = ddc_dfda;
        ddb_dfdc = ddc_dfdb;
        ddc_dfdc = double ( subs ( sym_ddc_dfdc , {a , b , c , d, e , g , h} ,{ m(1) , m(2) , m(3) , m(4) , m(5) , m(6) , m(7)}) );
        ddd_dfdc = double ( subs ( sym_ddd_dfdc , {a , b , c , d, e , g , h} ,{ m(1) , m(2) , m(3) , m(4) , m(5) , m(6) , m(7)}) );
        dde_dfdc = double ( subs ( sym_dde_dfdc , {a , b , c , d, e , g , h} ,{ m(1) , m(2) , m(3) , m(4) , m(5) , m(6) , m(7)}) );
        ddh_dfdc = double ( subs ( sym_ddg_dfdc , {a , b , c , d, e , g , h} ,{ m(1) , m(2) , m(3) , m(4) , m(5) , m(6) , m(7)}) );
        ddg_dfdc = double ( subs ( sym_ddh_dfdc , {a , b , c , d, e , g , h} ,{ m(1) , m(2) , m(3) , m(4) , m(5) , m(6) , m(7)}) );

        dda_dfdd = ddd_dfda;
        ddb_dfdd = ddd_dfdb;
        ddc_dfdd = ddd_dfdc;
        ddd_dfdd = double ( subs ( sym_ddd_dfdd , {a , b , c , d, e , g , h} ,{ m(1) , m(2) , m(3) , m(4) , m(5) , m(6) , m(7)}) );
        dde_dfdd = double ( subs ( sym_dde_dfdd , {a , b , c , d, e , g , h} ,{ m(1) , m(2) , m(3) , m(4) , m(5) , m(6) , m(7)}) );
        ddh_dfdd = double ( subs ( sym_ddg_dfdd , {a , b , c , d, e , g , h} ,{ m(1) , m(2) , m(3) , m(4) , m(5) , m(6) , m(7)}) );
        ddg_dfdd = double ( subs ( sym_ddh_dfdd , {a , b , c , d, e , g , h} ,{ m(1) , m(2) , m(3) , m(4) , m(5) , m(6) , m(7)}) );

        dda_dfde = dde_dfda;
        ddb_dfde = dde_dfdb;
        ddc_dfde = dde_dfdc;
        ddd_dfde = dde_dfdd;
        dde_dfde = double ( subs ( sym_dde_dfde , {a , b , c , d, e , g , h} ,{ m(1) , m(2) , m(3) , m(4) , m(5) , m(6) , m(7)}) );
        ddh_dfde = double ( subs ( sym_ddg_dfde , {a , b , c , d, e , g , h} ,{ m(1) , m(2) , m(3) , m(4) , m(5) , m(6) , m(7)}) );
        ddg_dfde = double ( subs ( sym_ddh_dfde , {a , b , c , d, e , g , h} ,{ m(1) , m(2) , m(3) , m(4) , m(5) , m(6) , m(7)}) );

        dda_dfdg = ddg_dfda;
        ddb_dfdg = ddg_dfdb;
        ddc_dfdg = ddg_dfdc;
        ddd_dfdg = ddg_dfdd;
        dde_dfdg = ddg_dfde;
        ddh_dfdg = double ( subs ( sym_ddg_dfdg , {a , b , c , d, e , g , h} ,{ m(1) , m(2) , m(3) , m(4) , m(5) , m(6) , m(7)}) );
        ddg_dfdg = double ( subs ( sym_ddh_dfdg , {a , b , c , d, e , g , h} ,{ m(1) , m(2) , m(3) , m(4) , m(5) , m(6) , m(7)}) );

        dda_dfdh = ddh_dfda; 
        ddb_dfdh = ddh_dfdb;
        ddc_dfdh = ddh_dfdc;
        ddd_dfdh = ddh_dfdd;
        dde_dfdh = ddh_dfde;
        ddg_dfdh = ddh_dfdg;
        ddh_dfdh = double ( subs ( sym_ddh_dfdh , {a , b , c , d, e , g , h} ,{ m(1) , m(2) , m(3) , m(4) , m(5) , m(6) , m(7)}) );

    
        H = [ dda_dfda dda_dfdb dda_dfdc dda_dfdd dda_dfde dda_dfdg dda_dfdh;...
            ddb_dfda ddb_dfdb ddb_dfdc ddb_dfdd ddb_dfde ddb_dfdg ddb_dfdh;...
            ddc_dfda ddc_dfdb ddc_dfdc ddc_dfdd ddc_dfde ddc_dfdg ddc_dfdh;...
            ddd_dfda ddd_dfdb ddd_dfdc ddd_dfdd ddd_dfde ddd_dfdg ddd_dfdh;...
            dde_dfda dde_dfdb dde_dfdc dde_dfdd dde_dfde dde_dfdg dde_dfdh;...
            ddg_dfda ddg_dfdb ddg_dfdc ddg_dfdd ddg_dfde ddg_dfdg ddg_dfdh;...
            ddh_dfda ddh_dfdb ddh_dfdc ddh_dfdd ddh_dfde ddh_dfdg ddh_dfdh;];

        % Update Model
        % step = -2/lambda*(J' * F);
        F = double ( subs (f , {a , b , c , d, e , g , h} ,{ m(1) , m(2) , m(3) , m(4) , m(5) , m(6) , m(7)}) );
        % step = -2/lambda*(J' * F);
        step = -1* (H+ 1/lambda*(eyesize(H))) \ J;
        % for i = 1:1:size(bias)
        %     objective_history (i, k +1) = sum( double ( subs ( f , {a , b , c } ,{m(1) , m(2) ,m(3) }) ) ) ;
        % end
        % step = -1* inv(J) * objective_history(:,k+1)';
        step_length(1+k) = step*step';
        m = m + step ;
    
        % Convergence Progress
        % z = m(1) ./ (1 + exp(m(2)-w)) .* (1-1./(1 + exp(m(2)-w))) ./ (1 + (m(3)./(1 + exp(m(2)-bias))).^2.*yC.^2) ;
        % temp = yC'* yC - 2 * yC' * m(1) * z + m(1)^2 * z' * z 
        % for i = 1:1:size(bias)
        %     objective_history (i, k +1) = sum( double ( subs ( f , {d , x , y ,a , b , c } ,{yC(:,i) , w , bias(i), m(1) , m(2) ,m(3) }) ) ) ;
        % end
        objective_history(k+1) = sum( F );
        m_history (: , k +1) = m ;

        if (objective_history(k) < objective_history(k+1)) || any(isnan(m)) || cond(H+ 1/lambda*eye(size(H))) > 1e15
            lambda = lambda/2;
            m = m_history(:,k);
        elseif ((( step_length(k+1) < 10^-(2/lambda) ) || k+1 > max_itters) || lambda > 50)
            converged = true ;  
        else
            k = k+1;
            lambda = 1;
        end
    end
end

%%

sym_dfda = diff (f , a ) ;
sym_dda_dfda = diff (f , a , a ) ; % 1
sym_ddb_dfda = diff (f , a , b ) ; % 2
sym_ddc_dfda = diff (f , a , c ) ; % 3
sym_ddd_dfda = diff (f , a , d ) ; % 4
sym_dde_dfda = diff (f , a , e ) ; % 5
sym_ddg_dfda = diff (f , a , g ) ; % 6
sym_ddh_dfda = diff (f , a , h ) ; % 7

sym_dfdb = diff (f , b ) ;
sym_ddb_dfdb = diff (f , b , b ) ; % 2
sym_ddc_dfdb = diff (f , b , c ) ; % 3
sym_ddd_dfdb = diff (f , b , d ) ; % 4
sym_dde_dfdb = diff (f , b , e ) ; % 5
sym_ddg_dfdb = diff (f , b , g ) ; % 6
sym_ddh_dfdb = diff (f , b , h ) ; % 7

sym_dfdc = diff (f , c ) ;
sym_ddc_dfdc = diff (f , c , c ) ; % 3
sym_ddd_dfdc = diff (f , c , d ) ; % 4
sym_dde_dfdc = diff (f , c , e ) ; % 5
sym_ddg_dfdc = diff (f , c , g ) ; % 6
sym_ddh_dfdc = diff (f , c , h ) ; % 7

sym_dfdd = diff (f , d ) ;
sym_ddd_dfdd = diff (f , d , d ) ; % 4
sym_dde_dfdd = diff (f , d , e ) ; % 5
sym_ddg_dfdd = diff (f , d , g ) ; % 6
sym_ddh_dfdd = diff (f , d , h ) ; % 7

sym_dfde = diff (f , e ) ;
sym_dde_dfde = diff (f , e , e ) ; % 5
sym_ddg_dfde = diff (f , e , g ) ; % 6
sym_ddh_dfde = diff (f , e , h ) ; % 7

sym_dfdg = diff (f , g ) ;
sym_ddg_dfdg = diff (f , g , g ) ; % 6
sym_ddh_dfdg = diff (f , g , h ) ; % 7

sym_dfdh = diff (f , h ) ;
sym_ddh_dfdh = diff (f , h , h ) ; % 7

max_itters =1e4;

m = []
mstart = m;
k = 1;
objective_history = zeros ( size(bias,1), max_itters +1) ;
objective_history ( k) = sum( double ( subs ( f , {a , b , c , e } ,{ m(1) , m(2) , m(3) }) ) ) ;
m_history = zeros (4 , max_itters +1) ;
m_history (: ,1) = m ;
converged = false ;
figure ()
lambda = 1; %not above
%is the objective function decreasing? -> yes continue else change lambda.
%-> divide by 2
while ~ converged
    clear J F H
    % compute gradient
    dfda = double ( subs ( sym_dfda , {a , b , c , e } ,{ m(1) , m(2) , m(3) }) );
    dfdb = double ( subs ( sym_dfdb , {a , b , c , e } ,{ m(1) , m(2) , m(3) }) );
    dfdc = double ( subs ( sym_dfdc , {a , b , c , e } ,{ m(1) , m(2) , m(3) }) );
    J = [ dfda dfdb dfdc]';

    % compute hessian
    dda_dfda = sum( double ( subs ( sym_dda_dfda , {a , b , c , e } ,{ m(1) , m(2) ,m(3) , m(4) }) ) ) ;
    ddb_dfda = sum( double ( subs ( sym_ddb_dfda , {a , b , c , e } ,{ m(1) , m(2) ,m(3) , m(4) }) ) ) ;
    ddc_dfda = sum( double ( subs ( sym_ddc_dfda , {a , b , c , e } ,{ m(1) , m(2) ,m(3) , m(4) }) ) ) ;

    dda_dfdb = ddb_dfda ;
    ddb_dfdb = sum( double ( subs ( sym_ddb_dfdb , {a , b , c , e } ,{ m(1) , m(2) ,m(3) , m(4) }) ) ) ;
    ddc_dfdb = sum( double ( subs ( sym_ddc_dfdb , {a , b , c , e } ,{ m(1) , m(2) ,m(3) , m(4) }) ) ) ;

    dda_dfdc = ddc_dfda ;
    ddb_dfdc = ddc_dfdb ;
    ddc_dfdc = sum( double ( subs ( sym_ddc_dfdc , {a , b , c , e } ,{ m(1) , m(2) ,m(3) , m(4) }) ) ) ;

    dda_dfde = dde_dfda ;
    ddb_dfde = dde_dfdb ;
    ddc_dfde = dde_dfdc ;

    H = [ dda_dfda dda_dfdb dda_dfdc ; ddb_dfda ddb_dfdb ddb_dfdc ; ddc_dfda ddc_dfdb ddc_dfdc; dde_dfda dde_dfdb dde_dfdc;];

    % F = double ( subs (f , {a , b , c } ,{ m(1) , m(2) ,m(3) }) );
    % Update Model
    % step = -2/lambda*(J' * F);
    step = -1* (H+ 1/lambda*eye(size(H))) \ J;
    % for i = 1:1:size(bias)
    %     objective_history (i, k +1) = sum( double ( subs ( f , {a , b , c } ,{m(1) , m(2) ,m(3) }) ) ) ;
    % end
    % step = -1* inv(J) * objective_history(:,k+1)';
    step_length(1+k) = step'*step;
    m = m + step ;

    % Convergence Progress
    % z = m(1) ./ (1 + exp(m(2)-w)) .* (1-1./(1 + exp(m(2)-w))) ./ (1 + (m(3)./(1 + exp(m(2)-bias))).^2.*yC.^2) ;
    % temp = yC'* yC - 2 * yC' * m(1) * z + m(1)^2 * z' * z 
    % for i = 1:1:size(bias)
    %     objective_history (i, k +1) = sum( double ( subs ( f , {d , x , y ,a , b , c } ,{yC(:,i) , w , bias(i), m(1) , m(2) ,m(3) }) ) ) ;
    % end
    objective_history(k+1) = sum( double ( subs ( f , {a , b , c , e } ,{ m(1) , m(2) , m(3) , m(4) }) ) );
    m_history (: , k +1) = m ;
    subplot (4, 3 ,[1 4 7 10])
    scatter (1:(k+1) , objective_history(1: k +1) ) ;
    ax1 = gca;
    set(ax1,'yscale','log')
    subplot(4,3,2)
    scatter(1:(k+1) , m_history(1 ,1: k +1))
    yline(mtrue(1))
    set(ax1,'yscale','log')
    subplot(4,3,5)
    scatter(1:(k+1) , m_history(2 ,1: k +1))
    yline(mtrue(2))
    subplot(4,3,8)
    scatter(1:(k+1), m_history(3 ,1: k +1))
    yline(mtrue(3))
    set(ax1,'yscale','log')
    subplot(4,3,11)
    10^-(2/lambda)
    scatter(1:(k+1) , m_history(4 ,1: k +1))
    yline(mtrue(4))
    set(ax1,'yscale','log')

    subplot(4,3,[3 6 9 12])
    scatter (1:(k+1) , step_length(1:k +1) ) ;
    yline(10^-(2/lambda))
    ax1 = gca;
    set(ax1,'yscale','log')
    pause (1)

    if (objective_history(k) < objective_history(k+1)) || any(isnan(m)) || cond(H+ 1/lambda*eye(size(H))) > 1e15
        lambda = lambda/2;
        m = m_history(:,k);
    elseif ((( step_length(k+1) < 10^-(2/lambda) ) || k+1 > max_itters) || lambda > 50)
        converged = true ;  
    else
        k = k+1;
        lambda = 1;
    end

end


%%
dG =d(1:(size(d,1)/2));
dC =d((size(d,1)/2)+1:end);

figure()
title("Capacitance")
subplot(1,2,1)
title("Bias")
semilogx(fplot,yCmat(:,idxb))
hold on
% scatter(freq,reshape(dC,[size(bias,1),size(freq,1)]))
yyaxis right
Gm = double ( subs (gmC ,  {a , b , c , e } ,{ m(1) , m(2) , m(3) , m(4) }) );
semilogx (freq ,Gm)
set(gca, 'XScale', 'log');

subplot(1,2,2)
title("Freq")
hold on
plot(bplot,yCmat(idxf,:))
% scatter(bias,reshape(dC,[size(bias,1),size(freq,1)]))
yyaxis right
hold on
plot (bias ,Gm)

figure()
subplot(1,2,1)
Gm = double ( subs (gmG ,  {a , b , c , e } ,{ m(1) , m(2) , m(3) , m(4) }) );
plot(fplot,yGmat(:,idxb))
hold on
% scatter(freq,reshape(dG,[size(bias,1),size(freq,1)]))
yyaxis right
plot (freq ,Gm)
set(gca, 'XScale', 'log');

subplot(1,2,2)
plot(bplot,yGmat(idxf,:))
hold on
% scatter(bias,reshape(dG,[size(bias,1),size(freq,1)]))
yyaxis right
plot (bias ,Gm)

endtime = datestr(now, 'dd-mm-yy-HH-MM-SS');

