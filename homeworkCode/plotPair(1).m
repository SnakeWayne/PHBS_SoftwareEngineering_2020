function plotPair(obj,pairStruct,closeCause,endDate)
   stock1 = find(ismember(obj.signals.stockLocation,pairStruct.stock1)); %��Ʊindex
   stock2 = find(ismember(obj.signals.stockLocation,pairStruct.stock2));

   windTickers1 = aggregatedDataStruct.stock.description.tickers.windTicker(pairStruct.stock1);
   windTickers2 = aggregatedDataStruct.stock.description.tickers.windTicker(pairStruct.stock2);
   windName1 = aggregatedDataStruct.stock.description.tickers.shortName(pairStruct.stock1);
   windName2 = aggregatedDataStruct.stock.description.tickers.shortName(pairStruct.stock2);
   
   stockTicker1 =  windTickers1{1}; %stock1���״���
   stockTicker2 =  windTickers2{1}; %stock2���״���
   stockName1 = windName1{1}; %stock1���
   stockName2 = windName2{1}; %stock2���
   
   startDate=pairStruct.openDate;

   %returnIndex = find(ismember(obj.signals.propertyNameList, 'expectedReturn'));
   %validityIndex = find(ismember(obj.signals.propertyNameList, 'validity'));
   %zscoreIndex = find(ismember(obj.signals.propertyNameList, 'zScore'));
   alphaIndex = find(ismember(obj.signals.propertyNameList, 'alpha'));
   betaIndex = find(ismember(obj.signals.propertyNameList, 'beta'));
   sigmaIndex = find(ismember(obj.signals.propertyNameList, 'sigma'));
   %dislocationIndex = find(ismember(obj.signals.propertyNameList, 'dislocation'));

   extend_length=3; %startDate��endDate��ǰ���ӳ����죬���㻭ͼ
   startDateIndex = find( [obj.signals.dateList{:,1}]== startDate);
   startDateIndex_extend = startDateIndex-extend_length;
   endDateIndex = find( [obj.signals.dateList{:,1}]== endDate);
   endDateIndex_extend = endDateIndex+extend_length;

   %dislocation =  obj.signals.signalParameters(stock1,stock2,startDateIndex_extend:endDateIndex_extend,1,1,dislocationIndex);
   %Zscore =  obj.signals.signalParameters(stock1,stock2,startDateIndex_extend:endDateIndex_extend,1,1,zscoreIndex);
   beta_start = obj.signals.signalParameters(stock1,stock2,startDateIndex,1,1,betaIndex); %����ʱ��beta
   alpha_start = obj.signals.signalParameters(stock1,stock2,startDateIndex,1,1,alphaIndex); %����ʱ��mean
   sigma_start = obj.signals.signalParameters(stock1,stock2,startDateIndex,1,1,sigmaIndex); %����ʱ��sigma
   alpha_end = obj.signals.signalParameters(stock1,stock2,endDateIndex,1,1,alphaIndex); %�ز�ʱ��mean
   
   fwdPrice1 = aggregatedDataStruct.stock.properties.fwd_close(startDateIndex_extend:endDateIndex_extend,stock1);
   fwdPrice2 = aggregatedDataStruct.stock.properties.fwd_close(startDateIndex_extend:endDateIndex_extend,stock2);
   portfolio_value = fwdPrice1-beta_start*fwdPrice2; %���pair�Ĺɼ�����
   
   upboundStart = alpha_start+2*sigma_start; %����ʱ���Ͻ�
   lowboundStart = alpha_start-2*sigma_start; %����ʱ���½�
   
   
   %�����ǻ�ͼ����
   %��ͼ����
   figure
   len=length(portfolio_value); %���鳤��
   xaxis=((startDate-extend_length):(endDate+extend_length)); %ʱ����Ϊx��
   plot(xaxis,portfolio_value,'Color','black') %����pair�۸�����
   dateaxis('x',17)
   %������ֵ�����½�
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
   title({plottitle1;plottitle2}) %ע��pair��ƽ��ԭ��
   
   %ע�����֡�ƽ��ʱ��
   text(startDate,portfolio_value(extend_length+1),'*','color','r')
   text(startDate-0.5,0,[datestr(startDate,'yyyy-mm-dd'),'open position'],'FontWeight','bold','Color','red')
   text(endDate,portfolio_value(len-extend_length),'*','color','b')
   text(endDate-0.5,0,[datestr(endDate,'yyyy-mm-dd'),'close position'],'FontWeight','bold','Color','blue')

   
end