#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)

	InitializeDocument();

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	KeyAttributes = New Array;
	KeyAttributes.Add("TaxKind");
	KeyAttributes.Add("DeductionKindHR");
	TMCommonUse.CheckForDuplicatesOfTSStrings(ThisObject, "EmployeeDeductions", KeyAttributes, Cancel);
	
	DocumentsPayrollAndHumanResourcesServer.CheckCorrectnessOfMonthOfRegistration(ThisObject, Cancel);	
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load  Then
		Return;
	EndIf;
	
	If WriteMode = DocumentWriteMode.UndoPosting
		And DocumentsPayrollAndHumanResourcesServer.DocumentDataIsUsedToCalculateBlockedPOData(Ref) Then
		
		DocumentsPayrollAndHumanResourcesServer.ReportErrorsCancellationOfEvent(Ref, Cancel);	

	ElsIf  WriteMode = DocumentWriteMode.Posting Then        
		
		ListOfEmployeesToCheck = New Array();
		ListOfEmployeesToCheck.Add(Employee);
		
		ListOfEmployees = DocumentsPayrollAndHumanResourcesServer.PayrollBlocked(Organization, 
													BegOfMonth(RegistrationMonth), ListOfEmployeesToCheck);	
		
		If ListOfEmployees.Count() > 0 Then
			DocumentsPayrollAndHumanResourcesServer.ReportAboutPostErrors(Ref, RegistrationMonth, ListOfEmployees, Cancel);	  
		EndIf;	
	EndIf;	
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
		
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
