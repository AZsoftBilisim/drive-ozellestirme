#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If IsFolder Then
		Return;
	EndIf;
	
	BudgetingServer.FillInAuxiliaryDetailsBeforeRecording(ThisObject);
	
	If Not IsNew() Then
		ComparisonAttributes = StrSplit("Code,Description,LongDesc", ",");
		InitialValuesOfDetails = Common.ObjectAttributesValues(Ref, ComparisonAttributes);
		For Each ComparisonProps In ComparisonAttributes Do
			If ThisObject[ComparisonProps] <> InitialValuesOfDetails[ComparisonProps] Then
				AdditionalProperties.Insert("UpdateElementsOfFinancialStatements", Description);
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	For Cnt = 1 To MaximumNumberOfAnalysts Do
		If ThisObject["FillInAnalyticsWithSpecifiedValue" + Cnt]
		   And ValueIsFilled(ThisObject["DimensionKind" + Cnt]) Then
			DimensionKind = ThisObject["DimensionKind" + Cnt];
			TypeOfAnalytics = DimensionKind.ValueType;
			ThisObject["DimensionValue" + Cnt] = BudgetingClientServer.ReducedAnalyticsValue(
				ThisObject["DimensionValue" + Cnt],
				TypeOfAnalytics);
		Else
			ThisObject["DimensionValue" + Cnt] = BudgetingClientServer.EmptyDimensionValue();
		EndIf;
	EndDo;
	
	SettingTransitionHistoryDetailsForNewFormulas();
	
	If ImportFromOtherSubsystems Then
		// We will make a cast of the settings for future comparison between them without analyzing each element.
		DCSettings = Undefined;
		If Not AdditionalProperties.Property("DCSettings", DCSettings) Then
			DCSettings = StorageOfDataCompositionSettings.Get();
		EndIf;
			
		SettingsHash = TMCommonUse.HashSumOfSerializableObject(DCSettings, HashFunction.MD5);
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	VerifiedObjectAttributes = New Array;
	If Not IsFolder Then
		If Not ByPeriods And Not SetAValueForEachPeriod Then
			VerifiedObjectAttributes.Add("Periodicity");
		EndIf;
		
		If Not ByPeriods Then
			VerifiedObjectAttributes.Add("SubperiodFrequency");
		EndIf;
		
		If IndicatorKind <> Enums.NonFinancialItemKinds.Cash_ Then
			VerifiedObjectAttributes.Add("DimensionCurrencies");
		ElsIf Not CurrencyIsDeterminedByDimension Then
			VerifiedObjectAttributes.Add("DimensionCurrencies");
		EndIf;
		
		If IndicatorKind <> Enums.NonFinancialItemKinds.Quantitative Then
			VerifiedObjectAttributes.Add("UnitOfMeasure");
			VerifiedObjectAttributes.Add("DimensionUnitsOfMeasurement");
		Else
			If UnitOfMeasureIsDeterminedByDimension Then
				VerifiedObjectAttributes.Add("UnitOfMeasure");
			Else
				VerifiedObjectAttributes.Add("DimensionUnitsOfMeasurement");
			EndIf;
		EndIf;
		
		If Not Catalogs.AccessGroupsOfBudgetFlowItemsAndIndicators.AccessGroupsAreUsed() Then
			VerifiedObjectAttributes.Add("AccessGroup");
		EndIf;
		
		BudgetingServer.CheckCompletionOfAnalyticsCurrencyUnitsOfMeasurement(ThisObject, Cancel);
		BudgetingServer.CheckAnalyticsCompletionByItem(ThisObject, Cancel);

	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, VerifiedObjectAttributes);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
		
	If IsFolder Then
		Return;
	EndIf;
	
	If AdditionalProperties.Property("UpdateElementsOfFinancialStatements") Then
		Catalogs.FinancialReportItems.UpdateTitlesForPrinting(Ref, Description);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure SettingTransitionHistoryDetailsForNewFormulas()
	
	If Not IsFolder Then
		
		If IsBlankString(DimensionPopulationExpression1HistoryOfTransitionToNewFormulas)
			And Not IsBlankString(DimensionPopulationExpression1) Then
			DimensionPopulationExpression1HistoryOfTransitionToNewFormulas = DimensionPopulationExpression1;
		EndIf;
		If IsBlankString(DimensionPopulationExpression2HistoryOfTransitionToNewFormulas)
			And Not IsBlankString(DimensionPopulationExpression2) Then
			DimensionPopulationExpression2HistoryOfTransitionToNewFormulas = DimensionPopulationExpression2;
		EndIf;
		If IsBlankString(DimensionPopulationExpression3HistoryOfTransitionToNewFormulas)
			And Not IsBlankString(DimensionPopulationExpression3) Then
			DimensionPopulationExpression2HistoryOfTransitionToNewFormulas = DimensionPopulationExpression3;
		EndIf;
		If IsBlankString(DimensionPopulationExpression4HistoryOfTransitionToNewFormulas)
			And Not IsBlankString(DimensionPopulationExpression4) Then
			DimensionPopulationExpression4HistoryOfTransitionToNewFormulas = DimensionPopulationExpression4;
		EndIf;
		If IsBlankString(DimensionPopulationExpression5HistoryOfTransitionToNewFormulas)
			And Not IsBlankString(DimensionPopulationExpression5) Then
			DimensionPopulationExpression5HistoryOfTransitionToNewFormulas = DimensionPopulationExpression5;
		EndIf;
		If IsBlankString(DimensionPopulationExpression6HistoryOfTransitionToNewFormulas)
			And Not IsBlankString(DimensionPopulationExpression6) Then
			DimensionPopulationExpression6HistoryOfTransitionToNewFormulas = DimensionPopulationExpression6;
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf