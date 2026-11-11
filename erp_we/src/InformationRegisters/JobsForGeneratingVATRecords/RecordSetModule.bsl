#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If Not GetFunctionalOption("UseMultipleCompanies") Then
		
		// Before recording, let's try to determine the default organization
		NotCheckedAttributeArray = New Array;
		NotCheckedAttributeArray.Add("Organization");
		
		Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
		
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel, Replacing)
		
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If ExchangePlans.MasterNode() <> Undefined Then
		Cancel = True;
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If ThisObject.Count() = 1 And Not ValueIsFilled(ThisObject[0].Organization) Then
		// When interactively adding a register entry in the "one organization" mode, we will define the default organization.
		ThisObject[0].Organization = Catalogs.Companies.DefaultCompany();
		If ThisObject.Filter.Find("Organization") <> Undefined Then
			ThisObject.Filter.Organization.Value = ThisObject[0].Organization;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
