#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not IsFolder Then
		Description = TrimAll(Description);
		While Find(Description,"  ") > 0 Do
			Description = StrReplace(Description, "  ", " ");
		EndDo;
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)

	NotCheckedAttributeArray = New Array;
	
	If Not AccessManagement.LimitAccessAtRecordLevel()
	 Or Not AccessManagementInternal.AccessKindUsed("GroupsOfIndividuals") Then
		NotCheckedAttributeArray.Add("AccessGroup");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

#EndRegion

#EndIf