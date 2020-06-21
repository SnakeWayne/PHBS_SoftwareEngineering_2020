%??propertylist??ï¼?ç¬???ä¸???ä¸?sigmaï¼??¹ä¾¿è°???ï¼????¥ç??ä¹?ä¸?????openï¼??¤å???????°è¾¾å¼?ä»??¡ä»¶
classdef PairTradingSignal < handle
    
    properties(Access = public)
        startDate;
        %startDateLocation is the location of startDate in dateList
        startDateLocation;
        regressionBetaHistory = [];
        regressionAlphaHistory = [];
        forwardPrices = [];
        wr = 30;
        ws = 12;
        stockLocation;
        stockNum;
        %sigalParameters has six dimensions:stock1,stock2,dateLocation,wr,ws and properties
        %dateLocation is the location of date in dateList
        %properties have right parameters listed in propertyParameters
        signalParameters = zeros(1,1,1,1,1,9)
        propertyNameList =  {'validity','zScore','dislocation','expectedReturn','halfLife','sigma','alpha','beta','open'};
        stockUniverse;
        %dateList is 2210*2 cell; the first column is date code, the second column is actual date
        dateList;
    end
    
    methods
        function obj = PairTradingSignal(startDateCode)
            obj.startDate = startDateCode;
            %store stock prices into forwardPrices
            marketData = mclasses.staticMarketData.BasicMarketLoader.getInstance();
            generalData = marketData.getAggregatedDataStruct;
            stockSectorFilter = generalData.stock.sectorClassification.levelOne == 31;
            stockLocation = find(sum(stockSectorFilter) > 1);
            obj.stockLocation = stockLocation;
            obj.stockNum = length(stockLocation);
            obj.forwardPrices = generalData.stock.properties.fwd_close(:, stockLocation);
            %store actual stock name and code into stockUniverse
            code=generalData.stock.description.tickers.officialTicker(stockLocation);
            shortname = generalData.stock.description.tickers.shortName(stockLocation);
            obj.stockUniverse = [code,shortname];
            %for i-th stock, obj.stockUniverse{i,1} returns its stock code 
            %and obj.stockUniverse{i,2} returns its name
            %store actual date into dateList
            dateId = generalData.sharedInformation.allDates;
            realDate = generalData.sharedInformation.allDateStr;
            dateId = num2cell(dateId);
            realDate = cellstr(realDate);
            obj.dateList = [dateId, realDate];
            %initialize the obj.startDateLocation
            obj.startDateLocation = find(cell2mat(obj.dateList(:,1)) == obj.startDate);
        end
        
        %calculate ws-1 days' alpha and beta of all pairs before startDate
        function obj = initializeHistory(obj)
            for stock1 = 1:1:obj.stockNum-1
                for stock2 = stock1+1:1:obj.stockNum
                    for dateLocation = obj.startDateLocation - obj.ws + 1:1:obj.startDateLocation - 1
                        Y = obj.forwardPrices(dateLocation-obj.wr+1:dateLocation,stock1);
                        X = obj.forwardPrices(dateLocation-obj.wr+1:dateLocation,stock2);
                        %count the number of NaN in Y and X
                        YNaNNum = sum(isnan(Y));
                        XNaNNum = sum(isnan(X));
                        Y_stat = tabulate(Y);
                        X_stat = tabulate(X);
                        %if there are NaNs in Y and X or prices of stock1 or stock2 didn't change for more than 20% time period, fill NaN into regression history
                        if YNaNNum+XNaNNum >= 1 || max(Y_stat(:,3)) > 20|| max(X_stat(:,3)) > 20
                            obj.regressionAlphaHistory(stock1,stock2,dateLocation) = NaN;
                            obj.regressionBetaHistory(stock1,stock2,dateLocation) = NaN;
                        else
                            [b,~,~,~,~] = regress(Y,[ones(obj.wr,1), X]);
                            obj.regressionAlphaHistory(stock1,stock2,dateLocation) = b(1);
                            obj.regressionBetaHistory(stock1,stock2,dateLocation) = b(2);
                        end
                    end
                end
            end
        end
        
        %calculate the parameters of stock1 and stock2 at given date
        function obj = calculateParameters(obj,stock1,stock2,dateCode,alpha,beta,residual)
            dateLocation = find(cell2mat(obj.dateList(:,1)) == dateCode);
            %calculate dislocation
            dislocation = obj.forwardPrices(dateLocation,stock1)-beta*obj.forwardPrices(dateLocation,stock2) - alpha;
            obj.signalParameters(stock1,stock2,dateLocation,1,1,3) = dislocation;
            %calculate z-score
            zScore = dislocation/std(residual);
            obj.signalParameters(stock1,stock2,dateLocation,1,1,2) = zScore;
            %calculate halflife
            Y = residual(2:obj.ws);
            X = [ones(obj.ws-1,1),residual(1:obj.ws-1)];
            [b ,~ , ~ ,~ , ~] = regress(Y,X);
            if b(2) > 0
                lambda = -log(b(2));
                halfLife = log(2)/lambda;
            else
                halfLife = 0;
            end
            obj.signalParameters(stock1,stock2,dateLocation,1,1,5) = halfLife;  
            %calculate expeted return
            tradingCost = obj.forwardPrices(dateLocation,stock1)+abs(beta)*obj.forwardPrices(dateLocation,stock2);
            if halfLife > 0
                expectedReturn = abs(dislocation)/(2*tradingCost)/(halfLife/256);
            else
                expectedReturn = 0;
            end
            obj.signalParameters(stock1,stock2,dateLocation,1,1,4) = expectedReturn;
            %calculate entry point boundary
            sigma = std(residual);
            obj.signalParameters(stock1,stock2,dateLocation,1,1,6) = sigma;
            obj.signalParameters(stock1,stock2,dateLocation,1,1,7) = alpha;
            obj.signalParameters(stock1,stock2,dateLocation,1,1,8) = beta;
            %calculate open condition
            %halfLife<1,ä¸?å¼?ä»?ï¼?dislocation/cost<0.04%,ä¸?å¼?ä»?ï¼???2sigma??2.5sigmaä¹??´å?ä»?
            if abs(dislocation)/tradingCost <= 0.0004
                obj.signalParameters(stock1,stock2,dateLocation,1,1,9) = 0;
            elseif abs(zScore) >= 2 
                obj.signalParameters(stock1,stock2,dateLocation,1,1,9) = 1;
            else
                obj.signalParameters(stock1,stock2,dateLocation,1,1,9) = 0;
            end
        end
        
        
        %calculate all the pairs parameters
        function obj = generateSignals(obj,dateCode)
            dateLocation = find(cell2mat(obj.dateList(:,1)) == dateCode);
            for stock1 = 1:1:obj.stockNum-1
                for stock2 = stock1+1:1:obj.stockNum
                    %calculate the current day's alpha and beta and store them into regression history
                    Y = obj.forwardPrices(dateLocation-obj.wr+1:dateLocation,stock1);
                    X = obj.forwardPrices(dateLocation-obj.wr+1:dateLocation,stock2);
                    YNaNNum = sum(isnan(Y));
                    XNaNNum = sum(isnan(X));
                    Y_stat = tabulate(Y);
                    X_stat = tabulate(X);
                    if YNaNNum+XNaNNum >= 1 || max(Y_stat(:,3)) > 20 || max(X_stat(:,3)) > 20
                        obj.regressionAlphaHistory(stock1,stock2,dateLocation) = NaN;
                        obj.regressionBetaHistory(stock1,stock2,dateLocation) = NaN;
                    else
                        [b,~,~,~,~] = regress(Y,[ones(obj.wr,1), X]);
                        obj.regressionAlphaHistory(stock1,stock2,dateLocation) = b(1);
                        obj.regressionBetaHistory(stock1,stock2,dateLocation) = b(2); 
                    end
                    alphaNaNNum = sum(isnan(obj.regressionAlphaHistory(stock1,stock2,dateLocation - obj.ws + 1:dateLocation)));
                    betaNaNNum = sum(isnan(obj.regressionBetaHistory(stock1,stock2,dateLocation - obj.ws + 1:dateLocation)));
                    %if there are NaNs in regression history, then this pair is not valid and set all the parameters 0.
                    stockPrice1 = obj.forwardPrices(dateLocation - obj.ws + 1:dateLocation,stock1);
                    stockPrice2 = obj.forwardPrices(dateLocation - obj.ws + 1:dateLocation,stock2);
                    stock_stat1 = tabulate(stockPrice1);
                    stock_stat2 = tabulate(stockPrice2);
                    %å¦????¡ä»·è¶?è¿?30%å¯?wsçª??£æ????ä¸???ï¼?è®¤ä¸º?°æ??????ï¼?
                    if alphaNaNNum+betaNaNNum >= 1 || max(stock_stat1(:,3)) > 30 || max(stock_stat2(:,3)) > 30
                        obj.signalParameters(stock1,stock2,dateLocation,1,1,:) = zeros(9,1);
                    else
                        alphaSeries = zeros(obj.ws,1);
                        betaSeries = zeros(obj.ws,1);
                        alphaSeries(:,1) = obj.regressionAlphaHistory(stock1,stock2,dateLocation - obj.ws + 1:dateLocation);
                        betaSeries(:,1) = obj.regressionBetaHistory(stock1,stock2,dateLocation - obj.ws + 1:dateLocation);
                        %å¯?beta??alpha??stabilityæ£?éª?ï¼??¹æ?ä¸ºå?¹å??1/3????1/3å¯¹å?????wilconxç§©å??æ£?éª?
                        wilNum = floor(obj.ws/2);
                        [~,h_alpha] = ranksum(alphaSeries(1:wilNum,1),alphaSeries(obj.ws-wilNum+1:obj.ws,1));
                        [~,h_beta] = ranksum(betaSeries(1:wilNum,1),betaSeries(obj.ws-wilNum+1:obj.ws,1));
                        %å¦???alpha??betaæ³¢å?¨è?å¤§ï??????°å?¨é?¨ä?ä¸?0
                        if (h_alpha == 1) || (h_beta == 1)
                            obj.signalParameters(stock1,stock2,dateLocation,1,1,:) = zeros(9,1);
                        else
                            averageAlpha = mean(obj.regressionAlphaHistory(stock1,stock2,dateLocation - obj.ws + 1:dateLocation));
                            averageBeta = mean(obj.regressionBetaHistory(stock1,stock2,dateLocation - obj.ws + 1:dateLocation));
                            residual = stockPrice1 - averageAlpha - averageBeta*stockPrice2;
                            [~,p] = adftest(residual);
                            %if residual series is staionary, then calculate and store parameters 
                            if p <= 0.05
                                obj.signalParameters(stock1,stock2,dateLocation,1,1,1) = 1;
                                obj.calculateParameters(stock1,stock2,dateCode,averageAlpha,averageBeta,residual);
                            %if residual series is not stationary, then all the parameters are 0
                            else
                                obj.signalParameters(stock1,stock2,dateLocation,1,1,:) = zeros(9,1);
                            end
                        end
                    end
                end
            end
        end
    end   
end
