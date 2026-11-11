#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)

	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);

	If Not IsFolder Then
		
		// Processing of props for radar
		If Not IsNew() Then
			AccessGroup = Ref;
		ElsIf ValueIsFilled(GetNewObjectRef()) Then
			AccessGroup = GetNewObjectRef();
		Else
			AccessGroup = Catalogs.PartnerAccessGroups.GetRef();
			SetNewObjectRef(AccessGroup);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf