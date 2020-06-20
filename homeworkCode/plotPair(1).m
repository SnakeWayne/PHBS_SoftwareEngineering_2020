function plotPair(obj,pairStruct,closeCause,endDate)
   stock1 = find(ismember(obj.signals.stockLocation,pairStruct.stock1)); %股票index
   stock2 = find(ismember(obj.signals.stockLocation,pairStruct.stock2));

   windTickers1 = aggregatedDataStruct.stock.description.tickers.windTicker(pairStruct.stock1);
   windTickers2 = aggregatedDataStruct.stock.description.tickers.windTicker(pairStruct.stock2);
   windName1 = aggregatedDataStruct.stock.description.tickers.shortName(pairStruct.stock1);
   windName2 = aggregatedDataStruct.stock.description.tickers.shortName(pairStruct.stock2);
   
   stockTicker1 =  windTickers1{1}; %stock1交易代码
   stockTicker2 =  windTickers2{1}; %stock2交易代码
   stockName1 = windName1{1}; %stock1简称
   stockName2 = windName2{1}; %stock2简称
   
   startDate=pairStruct.openDate;

   %returnIndex = find(ismember(obj.signals.propertyNameList, 'expectedReturn'));
   %validityIndex = find(ismember(obj.signals.propertyNameList, 'validity'));
   %zscoreIndex = find(ismember(obj.signals.propertyNameList, 'zScore'));
   alphaIndex = find(ismember(obj.signals.propertyNameList, 'alpha'));
   betaIndex = find(ismember(obj.signals.propertyNameList, 'beta'));
   sigmaIndex = find(ismember(obj.signals.propertyNameList, 'sigma'));
   %dislocationIndex = find(ismember(obj.signals.propertyNameList, 'dislocation'));

   extend_length=3; %startDate与endDate往前后延长几天，方便画图
   startDateIndex = find( [obj.signals.dateList{:,1}]== startDate);
   startDateIndex_extend = startDateIndex-extend_length;
   endDateIndex = find( [obj.signals.dateList{:,1}]== endDate);
   endDateIndex_extend = endDateIndex+extend_length;

   %dislocation =  obj.signals.signalParameters(stock1,stock2,startDateIndex_extend:endDateIndex_extend,1,1,dislocationIndex);
   %Zscore =  obj.signals.signalParameters(stock1,stock2,startDateIndex_extend:endDateIndex_extend,1,1,zscoreIndex);
   beta_start = obj.signals.signalParameters(stock1,stock2,startDateIndex,1,1,betaIndex); %开仓时的beta
   alpha_start = obj.signals.signalParameters(stock1,stock2,startDateIndex,1,1,alphaIndex); %开仓时的mean
   sigma_start = obj.signals.signalParameters(stock1,stock2,startDateIndex,1,1,sigmaIndex); %开仓时的sigma
   alpha_end = obj.signals.signalParameters(stock1,stock2,endDateIndex,1,1,alphaIndex); %关仓时的mean
   
   fwdPrice1 = aggregatedDataStruct.stock.properties.fwd_close(startDateIndex_extend:endDateIndex_extend,stock1);
   fwdPrice2 = aggregatedDataStruct.stock.properties.fwd_close(startDateIndex_extend:endDateIndex_extend,stock2);
   portfolio_value = fwdPrice1-beta_start*fwdPrice2; %这对pair的股价序列
   
   upboundStart = alpha_start+2*sigma_start; %开仓时的上界
   lowboundStart = alpha_start-2*sigma_start; %开仓时的下界
   
   
   %下面是画图部分
   %画图部分
   figure
   len=length(portfolio_value); %数组长度
   xaxis=((startDate-extend_length):(endDate+extend_length)); %时间作为x轴
   plot(xaxis,portfolio_value,'Color','black') %画出pair价格走势
   dateaxis('x',17)
   %画出均值、上下界
   line([startDate-extend_length,endDate+extend_length],[alpha_start,alpha_start],'linestyle','--','Color','red')
   text(startDate-extend_length-1,alpha_start,'Mean(open)','Color','red')
   line([startDate-extend_length,endDate+extend_length],[alpha_end,alpha_end],'linestyle','--','Color','blue')
   text(startDate-extend_length-1,alpha_end,'Mean(close)','Color','blue')
   line([startDate-extend_length,endDate+extend_length],[upboundStart,upboundStart],'linestyle',':','Color','red')
   text(startDate-extend_length-1,upboundStart,'Upper Bound','Color','red')
   line([startDate-extend_length,endDate+extend_length],[lowboundStart,lowboundStart],'linestyle',':','Color','blue')
   text(startDate-extend_length-1,lowboundStart,'Lower Bound','Color','blue')
   plottitle1=['stock pair ','(',stockName1,',',stockName2,')',' price movement'];
   plottitle2=['reason for closing the pair: ',closeCause];
   title({plottitle1;plottitle2}) %注明pair及平仓原因
   
   %注明开仓、平仓时间
   text(startDate,portfolio_value(extend_length+1),'*','color','r')
   text(startDate-0.5,0,[datestr(startDate,'yyyy-mm-dd'),'open position'],'FontWeight','bold','Color','red')
   text(endDate,portfolio_value(len-extend_length),'*','color','b')
   text(endDate-0.5,0,[datestr(endDate,'yyyy-mm-dd'),'close position'],'FontWeight','bold','Color','blue')

   
end