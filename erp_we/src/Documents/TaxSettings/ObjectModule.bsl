#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)

	InitializeDocument();

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	KeyAttributes = New Array;
	KeyAttributes.Add("TaxKind");
	KeyAttributes.Add("Accrual");
	TMCommonUse.CheckForDuplicatesOfTSStrings(ThisObject, "NonTaxableAccruals", KeyAttributes, Cancel);
	
	KeyAttributes = New Array;
	KeyAttributes.Add("TaxKind");
	KeyAttributes.Add("Tariff");
	TMCommonUse.CheckForDuplicatesOfTSStrings(ThisObject, "TaxRates", KeyAttributes, Cancel);

	KeyAttributes = New Array;
	KeyAttributes.Add("TaxKind");
	KeyAttributes.Add("DeductionKindHR");
	TMCommonUse.CheckForDuplicatesOfTSStrings(ThisObject, "StandardDeductions", KeyAttributes, Cancel);
	
	DocumentsPayrollAndHumanResourcesServer.CheckCorrectnessOfMonthOfRegistration(ThisObject, Cancel);	
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load  Then
		Return;
	EndIf;
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);	
	
	If WriteMode = DocumentWriteMode.UndoPosting
		And DocumentsPayrollAndHumanResourcesServer.DocumentDataIsUsedToCalculateBlockedPOData(Ref) Then
		
		DocumentsPayrollAndHumanResourcesServer.ReportErrorsCancellationOfEvent(Ref, Cancel);	
	EndIf;	
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
		
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
		
EndProcedure

Procedure OnCopy(CopiedObject)
	
	InitializeDocument();
	
EndProcedure

#EndRegion

#Region Private

Procedure InitializeDocument()
	
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	RegistrationMonth = BegOfMonth(CurrentSessionDate());
	Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	
	If Not ValueIsFilled(EmployeeResponsible) Then
		EmployeeResponsible = Users.CurrentUser();
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
