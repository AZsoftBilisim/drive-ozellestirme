
#Region Private

Procedure ProcessingOfDecryptionOfAssortmentExecution(ThisForm, Details, StandardProcessing) Export
	
	DetailsType = TypeOf(Details);
	If DetailsType = Type("Structure") Then
		StandardProcessing = False;
		If Details.GroupName = "ProductKind"
			Or Details.GroupName = "ProductCategory" Then
			
			NewSettings1 = Undefined; // DataCompositionSettings - 
			ProductRangeServerCall.CopyAndAddSettings(ThisForm.Report.SettingsComposer, NewSettings1, Details);
			
			NewSettings1.Filter.Items.Clear();
			For Each SettingsItem In NewSettings1.DataParameters.Items Do
				SettingsItem.Use = False;
			EndDo;
			
			Filter = CommonClientServer.CopyStructure(Details);
			
			OpeningParameters = New Structure;
			Details.Insert("UsedSettings", NewSettings1);
			OpeningParameters.Insert("Details", Details);
			OpeningParameters.Insert("DrillDownPeriod", Details.Period);
			OpeningParameters.Insert("FixedSettings", NewSettings1);
			OpeningParameters.Insert("ThisIsTheTranscript", True);
			OpeningParameters.Insert("NameOfDecryptionDimension", Details.GroupName);
			OpeningParameters.Insert("VariantKey", "ByCategoryContext");
			OpeningParameters.Insert("GenerateOnOpen", True);
			OpeningParameters.Insert("Filter", Filter);
			OpenForm(
				"Report.FulfillmentAnalysisOfProductRange.ObjectForm",
				OpeningParameters,
				ThisForm,
				True);
		EndIf;
	EndIf;
	
EndProcedure

// Parameters:
// 	ThisForm - ClientApplicationForm - required Attributes in the form:
//  * Report - ReportObject - 
// 	Details - Structure -
// 	StandardProcessing - Boolean -
Procedure ProcessingDecryptionOfComparativeAnalysisOfAssortment(ThisForm, Details, StandardProcessing) Export
	
	DetailsType = TypeOf(Details);
	If DetailsType = Type("Structure") Then
		StandardProcessing = False;
		If Details.GroupName = "ProductKind"
			Or Details.GroupName = "ProductCategory" Then
			
			CurrentArea = ThisForm.CurrentItem.CurrentArea; // SpreadsheetDocumentRange
			DrillDownColumnNumber = CurrentArea.Left;
			
			Details.Insert("AnalyzedPeriod", Undefined);
			Details.Insert("PeriodToCompareWith", Undefined);
			Details.Insert("DrillDownColumnNumber", DrillDownColumnNumber);
			
			For Each Item In ThisForm.Report.SettingsComposer.UserSettings.Items Do
				If TypeOf(Item) = Type("DataCompositionSettingsParameterValue") Then
					If TrimAll(Item.Parameter) = "AnalyzedPeriod" Then
						Details.AnalyzedPeriod = Item.Value;
					ElsIf TrimAll(Item.Parameter) = "PeriodToCompareWith" Then
						Details.PeriodToCompareWith = Item.Value;
					EndIf;
				EndIf;
			EndDo;
			
			NewSettings1 = Undefined;
			ProductRangeServerCall.CopyAndAddSettings(ThisForm.Report.SettingsComposer, NewSettings1, Details);
			
			OpeningParameters = New Structure;
			OpeningParameters.Insert("FixedSettings", NewSettings1);
			OpeningParameters.Insert("ThisIsTheTranscript", True);
			OpeningParameters.Insert("VariantKey", "ByProductContext");
			OpeningParameters.Insert("GenerateOnOpen", True);
			OpenForm(
				"Report.ProductRangeAndSalesTrends.ObjectForm",
				OpeningParameters,
				ThisForm,
				True,);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

