//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array; // Array of String
	
	If TermDocument.IsEmpty() Then
		
		NotCheckedAttributeArray.Add("Counterparty");
		NotCheckedAttributeArray.Add("BeginOfPeriod");
		NotCheckedAttributeArray.Add("PeriodEnding");
		NotCheckedAttributeArray.Add("Currency");
		NotCheckedAttributeArray.Add("AccrualDocuments");
		
	Else
		
		Detailing = Enums.ARAPAccountingDrilldownsOfRebatesParticipants;
		TermsAndConditionsAttributes = Documents.ConditionsOfCustomerRebates.UpToDateData(TermDocument);
		
		If TermsAndConditionsAttributes.PartyCountDetails = Detailing.ByCounterparty Then
			NotCheckedAttributeArray.Add("AccrualDocuments.Partner");
		ElsIf TermsAndConditionsAttributes.PartyCountDetails = Detailing.ByCustomer Then
			NotCheckedAttributeArray.Add("AccrualDocuments.Counterparty");
		EndIf;
		
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

#EndRegion

#EndIf