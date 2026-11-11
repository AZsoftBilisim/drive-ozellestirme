#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	If (CurrentSessionDate() >= LocalAccntingClientServer.BeginningOfApplicationFSBU5_2019()
			Or Not GetFunctionalOption("UseLocal"))
		And Not IsFolder Then
		
		MethodOfRepaymentOfCostOfAC = Enums.WaysToRepayCostOfInventory.OnCommissioning;
		MethodOfRepaymentOfCostTA = Enums.WaysToRepayCostOfInventory.OnCommissioning;

	EndIf;

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If IsFolder Then
		Return;
	EndIf;
	
	AttributesNotToCheck = New Array;
	
	If Not IsFolder Then
		ItemDetailsParameters = InventoryInOperationClientServer.ValuesOfPropertiesOfDependentDetails_CategoriesOfOperation(ThisObject);
		TMCommonUse.DisableVerificationOfObjectDetails(ItemDetailsParameters, AttributesNotToCheck);
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	If Not IsFolder Then
		
		ItemDetailsParameters = InventoryInOperationClientServer.ValuesOfPropertiesOfDependentDetails_CategoriesOfOperation(ThisObject);
		TMCommonUseClientServer.ClearUnusedProps(ThisObject, ItemDetailsParameters);
		
		If Not ConsiderRunningTime Then
			EstimatedRunningTime = 0;
			OperatingTimeUnitOfMeasure = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
		EndIf;
		
	EndIf;
EndProcedure

Procedure OnWrite(Cancel)
	
	If Cancel Or DataExchange.Load Then
		Return;
	EndIf;
	
EndProcedure

Procedure OnReadPresentationsAtServer() Export
	
	NationalLanguageSupportServer.OnReadPresentationsAtServer(ThisObject);
	
EndProcedure

#EndRegion

#EndIf