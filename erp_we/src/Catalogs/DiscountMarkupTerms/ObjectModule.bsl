#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If DiscountMarkupCondition <> Enums.DiscountMarkupTerms.DuringSale Then
		NotCheckedAttributeArray.Add("TimeOfValidity");
	EndIf;
	
	If DiscountMarkupCondition <> Enums.DiscountMarkupTerms.LoyaltyCardIsNotRegistered
		And DiscountMarkupCondition <> Enums.DiscountMarkupTerms.ForLoyaltyCard Then
		NotCheckedAttributeArray.Add("LoyaltyCardKind");
	EndIf;
	
	If DiscountMarkupCondition <> Enums.DiscountMarkupTerms.LimitationByUserGroup Then
		NotCheckedAttributeArray.Add("UsersGroup");
	EndIf;
	
	If DiscountMarkupCondition <> Enums.DiscountMarkupTerms.ForAccumulatedSalesVolume 
		And DiscountMarkupCondition <> Enums.DiscountMarkupTerms.ForOneTimeSalesVolume Then
	
		NotCheckedAttributeArray.Add("CriteriaOfApplicationLimitationForSalesVolume");
		NotCheckedAttributeArray.Add("ComparisonTypeSSL");
		NotCheckedAttributeArray.Add("RestrictionCurrency");
		NotCheckedAttributeArray.Add("ProductSegmentRestrictions");
		
	Else
		
		If CriteriaOfApplicationLimitationForSalesVolume <> Enums.CriteriaOfLimitationOfUseOfDiscountsAndMarkupsForSalesVolume.Sum Then
			NotCheckedAttributeArray.Add("RestrictionCurrency");
		EndIf;
		
		If ItemFilterOption <> Enums.ItemFilterOptionsForDiscountMarkupCalculation.ProductSegment Then
			NotCheckedAttributeArray.Add("ProductSegmentRestrictions");
		EndIf;
		
	EndIf;
	
	If DiscountMarkupCondition <> Enums.DiscountMarkupTerms.ForAccumulatedSalesVolume Then
	
		NotCheckedAttributeArray.Add("AccumulationOption");
		NotCheckedAttributeArray.Add("OptionOfCumulativeQuantityDiscountPeriodDetermination");
		NotCheckedAttributeArray.Add("AccumulationPeriod");
		NotCheckedAttributeArray.Add("NumberOfAccumulationPeriods");
		
	Else
		
		If OptionOfCumulativeQuantityDiscountPeriodDetermination <> Enums.OptionsOfEstimatingCumulativeQuantityDiscountPeriod.WholePeriod Then
			NotCheckedAttributeArray.Add("AccumulationPeriod");
		EndIf;
		
	EndIf;
	
	If DiscountMarkupCondition <> Enums.DiscountMarkupTerms.ForOneTimeSalesVolume Then
	
		NotCheckedAttributeArray.Add("CriteriaOfApplicationLimitationForSalesVolume");
		
	EndIf;
	
	If DiscountMarkupCondition <> Enums.DiscountMarkupTerms.IncludeCustomerInSegment Then
	
		NotCheckedAttributeArray.Add("PartnersSegment");
		
	EndIf;
	
	TemplateError = NStr("vi = 'Thời gian kết thúc hiệu lực chiết khấu (phụ thu) nhỏ hơn thời gian bắt đầu trong dòng %LineNumber%';
						|ru = 'Время окончания действия скидки (наценки )меньше времени начала в строке %LineNumber%';
						|en = 'Discount (markup) validity end time is less than validity start time in line %LineNumber%'; fa = 'Discount (markup) validity end time is less than validity start time in line %LineNumber%';
						|it = 'L''ora di fine della validità dello sconto (del mark-up) è inferiore all''ora di inizio nella riga %LineNumber%';
						|pl = 'Termin zakończenia obowiązywania rabatu (marży )jest mniejszy od terminu rozpoczęcia w wierszu %LineNumber%';
						|tr = 'İndirimin (zammın) geçerlilik bitiş zamanı, %LineNumber% satırındaki başlangıç ​​zamanından daha önce'");
	For Each TabRow In TimeOfValidity Do
		
		If TabRow.EndTime < TabRow.BeginTime Then
			
			CommonClientServer.MessageToUser(StrReplace(TemplateError, "%LineNumber%", String(TabRow.LineNumber)),
				ThisObject,
				CommonClientServer.PathToTabularSection("TimeOfValidity", TabRow.LineNumber, "EndTime"),
				,
				Cancel);
			
		EndIf;
		
	EndDo;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	If Not IsFolder Then
		RestrictionCurrency = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting(RestrictionCurrency);
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	DiscountsMarkupsServer.BeforeWrite(ThisObject, Cancel);
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DiscountsMarkupsClientServer.ClearDetailsDependingOnApplicationCondition(ThisObject);
	
EndProcedure

#EndRegion

#EndIf
