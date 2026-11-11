
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	FillPropertyValues(ThisObject, Parameters, "DimensionKind, KindOfSourceDimension, AddressOfMatchingAnalystValues");
	AttributesOfTypeOfAnalytics = Common.ObjectAttributesValues(DimensionKind, "Description, ValueType");
	AttributesOfSourceAnalyticsType = Common.ObjectAttributesValues(KindOfSourceDimension, "Description, ValueType");
	
	If Not IsBlankString(AddressOfMatchingAnalystValues) Then
		TableOfMatchingAnalystValues = GetFromTempStorage(AddressOfMatchingAnalystValues);
		MatchingAnalystValues.Load(TableOfMatchingAnalystValues.Copy(New Structure("DimensionKind", DimensionKind)));
	EndIf;
	
	Items.MatchingAnalystValuesSourceDimensionValue.Title = AttributesOfSourceAnalyticsType.Description;
	Items.MatchingAnalystValuesDimensionValue.Title = AttributesOfTypeOfAnalytics.Description;
	Items.MatchingAnalystValuesSourceDimensionValue.TypeRestriction = AttributesOfSourceAnalyticsType.ValueType;
	Items.MatchingAnalystValuesDimensionValue.TypeRestriction = AttributesOfTypeOfAnalytics.ValueType;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CompleteEditing(Command)
	
	PutMatchingOfAnalystValuesInRepository();
	
	NotifyChoice(AddressOfMatchingAnalystValues);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure PutMatchingOfAnalystValuesInRepository()
	
	TableOfMatchingAnalystValues = GetFromTempStorage(AddressOfMatchingAnalystValues);
	
	TheStructureOfTheSearch = New Structure("DimensionKind", DimensionKind);
	
	MapRows = TableOfMatchingAnalystValues.FindRows(TheStructureOfTheSearch);
	For Each MapRow In MapRows Do
		TableOfMatchingAnalystValues.Delete(MapRow);
	EndDo;
	For Each MapRow In MatchingAnalystValues Do
		NewRow = TableOfMatchingAnalystValues.Add();
		FillPropertyValues(NewRow, MapRow);
		NewRow.DimensionKind = DimensionKind;
	EndDo;
	
	PutToTempStorage(TableOfMatchingAnalystValues, AddressOfMatchingAnalystValues);
	
EndProcedure

#EndRegion