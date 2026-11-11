#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If IsFolder Then
		Return;
	EndIf;
	
	NotCheckedAttributeArray = New Array;
	
	ParallelLoad = False;
	ThereIsPlot = False;
		
	If Not WorkCenterType.IsEmpty() Then
		
		AttributesStructure1 = New Structure;
		AttributesStructure1.Insert("ParallelLoad", "ParallelLoad");
		AttributesStructure1.Insert("DivisionToUseProductionSites",
			"Department.UseProductionSites");
		DetailsOfRCType = Common.ObjectAttributesValues(WorkCenterType, AttributesStructure1);
		
		ParallelLoad = DetailsOfRCType.ParallelLoad;
		ThereIsPlot = DetailsOfRCType.DivisionToUseProductionSites;
		
	EndIf;
	
	If Not ParallelLoad Then
		NotCheckedAttributeArray.Add("MaximumLoad");
	EndIf; 
	
	If Not ThereIsPlot Then
		NotCheckedAttributeArray.Add("ProductionArea");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure") 
		And FillingData.Property("WorkCenterType")
		And ValueIsFilled(FillingData.WorkCenterType)
		And Common.ObjectAttributeValue(FillingData.WorkCenterType, "IsFolder") Then
		
		FillingData.Delete("WorkCenterType");
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf