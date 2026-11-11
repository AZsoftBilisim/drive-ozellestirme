#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If IsNew() Then
		RefToNew = GetNewObjectRef();
		If RefToNew.IsEmpty() Then
			RefToNew = Catalogs.ProductionLots.GetRef();
			SetNewObjectRef(RefToNew);
		EndIf;
		UUID = RefToNew.UUID();
	ElsIf Not ValueIsFilled(UUID) Then
		UUID = Ref.UUID();
	EndIf;
	
	ExpenseGroup = CostGroupsServer.CostGroupPresentation(ThisObject);
	Description = Catalogs.ProductionLots.NameOfProductionBatch(ThisObject, ExpenseGroup);
	
EndProcedure

Procedure BeforeDelete(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If UsedForNavigation Then
		NotCheckedAttributeArray.Add("MainProductProducts");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	If Not Cancel And TMCommonUse.CheckObjectDetails(ThisObject, CheckedAttributes) Then
		Cancel = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region Other


#EndRegion

#EndRegion

#EndIf
