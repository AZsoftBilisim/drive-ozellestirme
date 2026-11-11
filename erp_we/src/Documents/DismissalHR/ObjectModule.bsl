#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)

	If Not ValueIsFilled(DateOfDismissal) Then
		DateOfDismissal = CurrentSessionDate();
	EndIf;
	
	InitializeDocument(FillingData);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
 	If EmployeeWasFiredEarlier() Then
			
		Text = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Сотрудник %1 уже был уволен из организации %1 ранее';
						|vi = 'Employee %1 is already dismissed from the %1 company';
						|en = 'Employee %1 is already dismissed from the %1 company'; fa = 'Employee %1 is already dismissed from the %1 company';
						|it = 'Employee %1 is already dismissed from the %1 company';
						|pl = 'Employee %1 is already dismissed from the %1 company';
						|tr = 'Çalışan %1, %1 iş yerinden daha önce zaten çıkarılmıştı.'"),
					Employee, Organization);
		Common.MessageToUser(Text, ThisObject, , , Cancel);
		
	EndIf;
	
	AssignmentStructure = OperationalAccountingOfManufacturingPayrollAndHumanResources.PersonnelHistoryOfEmployee(Organization, Employee, DateOfDismissal); 
	
	If Not ValueIsFilled(AssignmentStructure.JobTitle) 
		And Not Posted Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Сотрудник %1 не работает в организации на дату %2';
																					|vi = 'Employee %1 does not work for the company as of %2';
																					|en = 'Employee %1 does not work for the company as of %2'; fa = 'Employee %1 does not work for the company as of %2';
																					|it = 'Employee %1 does not work for the company as of %2';
																					|pl = 'Employee %1 does not work for the company as of %2';
																					|tr = 'Çalışan %1, %2 tarihi itibarıyla iş yerinde çalışmıyor.'"), Employee, DateOfDismissal);
		
		Common.MessageToUser(MessageText,
		ThisObject,
		"Employee",
		"",
		Cancel);
	EndIf
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load  Then
		Return;
	EndIf;
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);	
	
	If WriteMode = DocumentWriteMode.UndoPosting
		And DocumentsPayrollAndHumanResourcesServer.DocumentDataIsUsedToCalculateBlockedPOData(Ref, False) Then
		
		DocumentsPayrollAndHumanResourcesServer.ReportErrorsCancellationOfEvent(Ref, Cancel);

	ElsIf  WriteMode = DocumentWriteMode.Posting Then        
		
		ListOfEmployeesToCheck = New Array();
		ListOfEmployeesToCheck.Add(Employee);
		
		ListOfEmployees = DocumentsPayrollAndHumanResourcesServer.PayrollBlocked(Organization, 
													BegOfMonth(DateOfDismissal), ListOfEmployeesToCheck);	
		
		If ListOfEmployees.Count() > 0 Then
			DocumentsPayrollAndHumanResourcesServer.ReportAboutPostErrors(Ref, DateOfDismissal, ListOfEmployees, Cancel);	  
		EndIf;	
		
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
	
	Employee = Catalogs.EmployeesHR.EmptyRef(); 
	Department = Catalogs.BusinessStructure.EmptyRef();
	JobTitle = Catalogs.JobTitles.EmptyRef();
    DateOfDismissal = CurrentSessionDate();
	WorkScheduleCalendar = Catalogs.Calendars.EmptyRef(); 
	EmploymentKind = Enums.EmploymentKindsPayrollAndHumanResources.EmptyRef();
	
	InitializeDocument(Undefined);
	
EndProcedure

#EndRegion

#Region Private

Procedure InitializeDocument(FillingData)
	
	If TypeOf(FillingData) = Type("Structure") Then
		
		If FillingData.Property("HeaderAttributes") Then
			FillPropertyValues(ThisObject, FillingData.HeaderAttributes);
		Else
			FillPropertyValues(ThisObject, FillingData);
		EndIf;
		
	Else
		
		Organization = SettingsValueCached.GetDefaultOrganization(Organization);
		
	EndIf;
	
	Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	
	If Not ValueIsFilled(EmployeeResponsible) Then
		EmployeeResponsible = Users.CurrentUser();
	EndIf;
	
EndProcedure

Function EmployeeWasFiredEarlier()
	
	If Not ValueIsFilled(Employee)
		Or Not ValueIsFilled(Organization)
		Or Not ValueIsFilled(DateOfDismissal) Then
		Return False;
	EndIf;
	
	Query = New Query();
	Query.Text = 
	"SELECT
	|	EmploymentRecordSliceLast.Employee AS Employee,
	|	EmploymentRecordSliceLast.EventKind AS EventKind,
	|	EmploymentRecordSliceLast.Period AS Period
	|FROM
	|	InformationRegister.EmploymentRecord.SliceLast(&SliceDate, Organization = &Organization
	|	AND Employee = &Employee
	|	AND NOT Recorder = &Ref) AS EmploymentRecordSliceLast
	|
	|ORDER BY
	|	Period DESC";
	
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Employee", Employee);
	Query.SetParameter("SliceDate", DateOfDismissal);
	Query.SetParameter("Ref", Ref);
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		
		Selection = QueryResult.Select();
		
		Selection.Next();
		
		If Selection.EventKind = Enums.HREventKindsPayrollAndHumanResources.Dismissal Then
			Return True;
		EndIf;
		
	EndIf;
	
	Return False;
	
EndFunction	

#EndRegion

#EndIf
