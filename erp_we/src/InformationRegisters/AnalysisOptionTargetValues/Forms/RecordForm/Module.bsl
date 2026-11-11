
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Record, ThisObject);

	If Common.ObjectAttributeValue(Record.AnalysisOption, "Owner.TargetTrend")
		= Enums.KindsOfTargetValueTrends.Span Then
		Record.TargetValueKind = Enums.TargetValueKindsOfAnalysisOptions.Span;
	Else
		Record.TargetValueKind = Enums.TargetValueKindsOfAnalysisOptions.Value;
	EndIf;
	
	SetFormItemsVisibility();
	
	SetDeviationUnits();
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	TargetValueKindsOfAnalysisOptions = Enums.TargetValueKindsOfAnalysisOptions;
	
	If CurrentObject.TargetValueKind = TargetValueKindsOfAnalysisOptions.Value Then
		CurrentObject.MinimumTargetRange = 0;
		CurrentObject.MaximumTargetRange = 0;
		
	ElsIf Record.TargetValueKind = TargetValueKindsOfAnalysisOptions.Span Then
		CurrentObject.TargetValue_ = 0;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AnalysisOptionOnChange(Item)
	
	SetDeviationUnits();
	
EndProcedure

&AtClient
Procedure KindOfVarianceFromTargetValueOnChange(Item)
	
	SetDeviationUnits();
	
	RecalculateGivenDeviations();
	
EndProcedure

&AtClient
Procedure TargetValueKindOnChange(Item)
	
	SetFormItemsVisibility();
	
	RecalculateGivenDeviations();
	
EndProcedure

&AtClient
Procedure NegativeBorderVarianceOnChange(Item)
	
	Record.AdjustedNegativeBorderVariance = AdjustedNegativeBorderVariance();
	
EndProcedure

&AtClient
Procedure PositiveBorderVarianceOnChange(Item)
	
	Record.AdjustedPositiveBorderVariance = AdjustedPositiveBorderVariance();
	
EndProcedure

&AtClient
Procedure MaximumTargetRangeOnChange(Item)
	
	RecalculateGivenDeviations();
	
EndProcedure

&AtClient
Procedure MinimumTargetRangeOnChange(Item)
	
	RecalculateGivenDeviations();
	
EndProcedure

&AtClient
Procedure TargetValue_OnChange(Item)
	
	RecalculateGivenDeviations();
	
EndProcedure

#EndRegion

#Region Private

#Region OnChangeAttributes

&AtServer 
Procedure RecalculateGivenDeviations()
	
	Record.AdjustedPositiveBorderVariance = AdjustedPositiveBorderVariance();
	Record.AdjustedNegativeBorderVariance = AdjustedNegativeBorderVariance();
	
EndProcedure

&AtServer 
Function AdjustedNegativeBorderVariance()
	
	CastedValue = 0;
	KindsOfTargetValueTrends = Enums.KindsOfTargetValueTrends;
	Trend = Common.ObjectAttributeValue(Record.AnalysisOption, "Owner.TargetTrend");
	TypesOfTargetValues = Enums.TargetValueKindsOfAnalysisOptions;
	TargetValueKind = Record.TargetValueKind;
	TypesOfDeviationsFromTargetValues = Enums.KindsOfVariancesFromTargetValues;
	KindOfVarianceFromTargetValue = Record.KindOfVarianceFromTargetValue;
	
	If Trend = KindsOfTargetValueTrends.ValueMaximization Then
		If TargetValueKind = TypesOfTargetValues.Value Then
			If KindOfVarianceFromTargetValue = TypesOfDeviationsFromTargetValues.Absolute Then
				CastedValue = Record.TargetValue_ - Record.NegativeBorderVariance;
			Else
				CastedValue = Record.TargetValue_*(100 - Record.NegativeBorderVariance)/100;
			EndIf;
			
		Else
			If KindOfVarianceFromTargetValue = TypesOfDeviationsFromTargetValues.Absolute Then
				CastedValue = Record.MinimumTargetRange - Record.NegativeBorderVariance;
			Else
				CastedValue = Record.MinimumTargetRange*(100 - Record.NegativeBorderVariance)/100;
			EndIf;
			
		EndIf;
	ElsIf Trend = KindsOfTargetValueTrends.ValueMinimization Then
		If TargetValueKind = TypesOfTargetValues.Value Then
			If KindOfVarianceFromTargetValue = TypesOfDeviationsFromTargetValues.Absolute Then
				CastedValue = Record.TargetValue_ + Record.NegativeBorderVariance;
			Else
				CastedValue = Record.TargetValue_*(100 + Record.NegativeBorderVariance)/100;
			EndIf;
			
		Else
			If KindOfVarianceFromTargetValue = TypesOfDeviationsFromTargetValues.Absolute Then
				CastedValue = Record.MaximumTargetRange + Record.NegativeBorderVariance;
			Else
				CastedValue = Record.MaximumTargetRange*(100 + Record.NegativeBorderVariance)/100;
			EndIf;
			
		EndIf;
	ElsIf Trend = KindsOfTargetValueTrends.Span Then
		If KindOfVarianceFromTargetValue = TypesOfDeviationsFromTargetValues.Absolute Then
			CastedValue = Record.MinimumTargetRange - Record.NegativeBorderVariance;
		Else
			CastedValue = Record.MinimumTargetRange*(100 - Record.NegativeBorderVariance)/100;
		EndIf;
		
	EndIf;
	
	Return CastedValue;
	
EndFunction

&AtServer 
Function AdjustedPositiveBorderVariance()
	
	CastedValue = 0;
	KindsOfTargetValueTrends = Enums.KindsOfTargetValueTrends;
	Trend = Common.ObjectAttributeValue(Record.AnalysisOption, "Owner.TargetTrend");
	TypesOfTargetValues = Enums.TargetValueKindsOfAnalysisOptions;
	TargetValueKind = Record.TargetValueKind;
	TypesOfDeviationsFromTargetValues = Enums.KindsOfVariancesFromTargetValues;
	KindOfVarianceFromTargetValue = Record.KindOfVarianceFromTargetValue;
	
	If Trend = KindsOfTargetValueTrends.ValueMaximization Then
		If TargetValueKind = TypesOfTargetValues.Value Then
			If KindOfVarianceFromTargetValue = TypesOfDeviationsFromTargetValues.Absolute Then
				CastedValue = Record.TargetValue_ + Record.PositiveBorderVariance;
			Else
				CastedValue = Record.TargetValue_*(100 + Record.PositiveBorderVariance)/100;
			EndIf;
			
		Else
			If KindOfVarianceFromTargetValue = TypesOfDeviationsFromTargetValues.Absolute Then
				CastedValue = Record.MaximumTargetRange + Record.PositiveBorderVariance;
			Else
				CastedValue = Record.MaximumTargetRange*(100 + Record.PositiveBorderVariance)/100;
			EndIf;
			
		EndIf;
	ElsIf Trend = KindsOfTargetValueTrends.ValueMinimization Then
		If TargetValueKind = TypesOfTargetValues.Value Then
			If KindOfVarianceFromTargetValue = TypesOfDeviationsFromTargetValues.Absolute Then
				CastedValue = Record.TargetValue_ - Record.PositiveBorderVariance;
			Else
				CastedValue = Record.TargetValue_*(100 - Record.PositiveBorderVariance)/100;
			EndIf;
			
		Else
			If KindOfVarianceFromTargetValue = TypesOfDeviationsFromTargetValues.Absolute Then
				CastedValue = Record.MinimumTargetRange - Record.PositiveBorderVariance;
			Else
				CastedValue = Record.MinimumTargetRange*(100 - Record.PositiveBorderVariance)/100;
			EndIf;
			
		EndIf;
	ElsIf Trend = KindsOfTargetValueTrends.Span Then
		If KindOfVarianceFromTargetValue = TypesOfDeviationsFromTargetValues.Absolute Then
			CastedValue = Record.MaximumTargetRange + Record.PositiveBorderVariance;
		Else
			CastedValue = Record.MaximumTargetRange*(100 + Record.PositiveBorderVariance)/100;
		EndIf;
	EndIf;
	
	Return CastedValue;
	
EndFunction

&AtServer 
Procedure SetFormItemsVisibility()
	
	// Visibility of range fields
	TargetValueKindsOfAnalysisOptions = Enums.TargetValueKindsOfAnalysisOptions;
	
	If Record.TargetValueKind = TargetValueKindsOfAnalysisOptions.Value Then
		VisibilityOfRangeFields = False;
	ElsIf Record.TargetValueKind = TargetValueKindsOfAnalysisOptions.Span Then
		VisibilityOfRangeFields = True;
	EndIf;
	
	Items.GroupTargetValue.Visible = Not VisibilityOfRangeFields;
	Items.GroupTargetRange.Visible = VisibilityOfRangeFields;
	
EndProcedure

&AtServer 
Procedure SetDeviationUnits()
	
	Dimensions = Common.ObjectAttributeValue(Record.AnalysisOption, "Owner.Dimensions");
	KindsOfVariancesFromTargetValues = Enums.KindsOfVariancesFromTargetValues;
	
	If Record.KindOfVarianceFromTargetValue = KindsOfVariancesFromTargetValues.Absolute Then
		Items.BoundaryPositiveDeviationUnitIsm.Title = Dimensions;
		Items.BoundaryNegativeDeviationUnitIsm.Title = Dimensions;
	Else
		Items.BoundaryPositiveDeviationUnitIsm.Title = "%";
		Items.BoundaryNegativeDeviationUnitIsm.Title = "%";
	EndIf;
	
	Items.TargetValueUnitIsm.Title = Dimensions;
	Items.TargetRangeMaximumUnitsIsm.Title = Dimensions;
	Items.TargetRangeMinimumUnitsIsm.Title = Dimensions;
	
	Items.TheReducedBoundaryPositiveDeviationUnitIsm.Title = Dimensions;
	Items.TheReducedBoundaryNegativeDeviationUnitIsm.Title = Dimensions;
	
EndProcedure

#EndRegion

#EndRegion
