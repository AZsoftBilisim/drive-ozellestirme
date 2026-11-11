#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	CheckingValuesOfDetailsBeforeRecording();
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);

EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
		
EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	If MissingInData(FillingData, "Owner") Then
		Owner = Catalogs.BudgetingModels.DefaultBudgetingModel();
	EndIf;
	
	If Not IsFolder Then
		
		If MissingInData(FillingData, "Periodicity") Then
			Periodicity = Enums.Periodicity.Month;
		EndIf;
		
		If MissingInData(FillingData, "PlanningMethod") Then
			PlanningMethod = Enums.BudgetPreparationMethods.ForAFixedPeriod;
		EndIf;
		
		If MissingInData(FillingData, "LocationOptionOfActualDataOffset") Then
			LocationOptionOfActualDataOffset = Enums.LocationOptionsOfActualDataOffsets.WithinBudgetPeriod;
		EndIf;
		
		If MissingInData(FillingData, "NumberOfPeriodsOfRollingBudget") Then
			NumberOfPeriodsOfRollingBudget = 1;
		EndIf;
		
		If MissingInData(FillingData, "ActualDataLimitOffset") Then
			ActualDataLimitOffset = 1;
		EndIf;
		
		If MissingInData(FillingData, "ActualDataLimitTimeFence") Then
			ActualDataLimitTimeFence = Enums.Periodicity.Month;
		EndIf;
	
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If IsFolder Then
		Return;
	EndIf;
	
	NotCheckedAttributeArray = New Array;
	
	If Not Catalogs.BudgetProfileAccessGroups.AccessGroupsAreUsed() Then
		NotCheckedAttributeArray.Add("AccessGroup");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);

EndProcedure

#EndRegion

#Region Private

Procedure CheckingValuesOfDetailsBeforeRecording()
	
	If Not IsFolder
		And Not PlanningMethod = Enums.BudgetPreparationMethods.Rolling Then
		NumberOfPeriodsOfRollingBudget = 1;
	EndIf;
	
EndProcedure

Function MissingInData(FillingData, AttributeName)
	Var Value;
	
	If FillingData = Undefined Then
		Return True;
	EndIf;
	
	If Not FillingData.Property(AttributeName, Value)
		Or Value = Undefined Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

#EndRegion

#EndIf