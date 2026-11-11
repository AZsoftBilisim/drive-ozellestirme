#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	FilledInBasedOnDataReceived	= False;
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		
		FillInBasedOnDataReceived(FillingData);
		FilledInBasedOnDataReceived = True;
		
	EndIf;
	
	If Not FilledInBasedOnDataReceived Then	
		InitializeDocument();
	EndIf;	

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	KeyAttributes = New Array;
	KeyAttributes.Add("Employee");
	TMCommonUse.CheckForDuplicatesOfTSStrings(ThisObject, "AccruedByEmployees", KeyAttributes, Cancel);
	
	DocumentsPayrollAndHumanResourcesServer.CheckCorrectnessOfMonthOfRegistration(ThisObject, Cancel);	
	
	NotCheckedAttributeArray = New Array;
	
	If Not GetFunctionalOption("UseBusinessUnits") Then
		NotCheckedAttributeArray.Add("Department");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	InputFrequency = Common.ObjectAttributeValue(Accrual, "InputFrequency");
	
	If InputFrequency = 2 Then
		
		CheckParameters = New Structure();
		CheckParameters.Insert("AccrualDeduction", Accrual);
		CheckParameters.Insert("ListOfEmployees",   AccruedByEmployees.UnloadColumn("Employee"));
		
		ListOfAccrualEmployees = DocumentsPayrollAndHumanResourcesServer.CheckEmployeeAccrualForTimeFence(
																		Date, CheckParameters, Cancel);

		For Each LineAccruedByEmployees In AccruedByEmployees Do
			
			IdentifiedEmployee = ListOfAccrualEmployees.Find(LineAccruedByEmployees.Employee);
			
			If IdentifiedEmployee <> Undefined Then
				Continue;
			EndIf;	                                  
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
								NStr("ru = 'Сотрудник: ""%1"" не имеет постоянного начисления: %2';
									|vi = 'Employee ""%1"" does not have a permanent accrual: %2';
									|en = 'Employee ""%1"" does not have a permanent accrual: %2'; fa = 'Employee ""%1"" does not have a permanent accrual: %2';
									|it = 'Employee ""%1"" does not have a permanent accrual: %2';
									|pl = 'Employee ""%1"" does not have a permanent accrual: %2';
									|tr = 'Çalışan: ""%1"" sürekli tahakkuka sahip değil: %2'"), 
																	LineAccruedByEmployees.Employee, Accrual);
																	
			Common.MessageToUser(MessageText,
												ThisObject,
												CommonClientServer.PathToTabularSection("AccruedByEmployees", LineAccruedByEmployees.LineNumber, "Employee"),
												"",
												Cancel);
			
		EndDo;	
		
	EndIf;	
	
	For Each LineAccruedByEmployees In AccruedByEmployees Do
		AssignmentStructure = OperationalAccountingOfManufacturingPayrollAndHumanResources.PersonnelHistoryOfEmployee(Organization, LineAccruedByEmployees.Employee, EndOfMonth(RegistrationMonth)); 
		
		If Not ValueIsFilled(AssignmentStructure.JobTitle) 
			Or AssignmentStructure.Department <> Department Then
			MessageText = StrTemplate(NStr("ru = 'Сотрудник %1 не работает в организации %2 подразделении: %3 на дату %4';
											|vi = 'Employee %1 does not work for the ""%2"" company, the ""%3"" business unit as of %4';
											|en = 'Employee %1 does not work for the ""%2"" company, the ""%3"" business unit as of %4'; fa = 'Employee %1 does not work for the ""%2"" company, the ""%3"" business unit as of %4';
											|it = 'Employee %1 does not work for the ""%2"" company, the ""%3"" business unit as of %4';
											|pl = 'Employee %1 does not work for the ""%2"" company, the ""%3"" business unit as of %4';
											|tr = 'Çalışan %1, %4 tarihi itibarıyla %2 iş yerinin %3 biriminde çalışmıyor.'"), 
													LineAccruedByEmployees.Employee, Organization, Department, EndOfMonth(RegistrationMonth));
			
			Common.MessageToUser(MessageText,
												ThisObject,
												CommonClientServer.PathToTabularSection("AccruedByEmployees", 
																			LineAccruedByEmployees.LineNumber, "Employee"),
												"",
												Cancel);
		EndIf;
	EndDo;
	
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
		
		ListOfEmployees = DocumentsPayrollAndHumanResourcesServer.PayrollBlocked(Organization, RegistrationMonth, AccruedByEmployees.Unload(,"Employee"));	
		
		If ListOfEmployees.Count() > 0 Then
			DocumentsPayrollAndHumanResourcesServer.ReportAboutPostErrors(Ref, RegistrationMonth, ListOfEmployees, Cancel);	  
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
	
	InitializeDocument();
	
EndProcedure

#EndRegion

#Region Private

Procedure FillInBasedOnDataReceived(Val FillingData)

	FillPropertyValues(ThisObject, FillingData);
	RegistrationMonth = FillingData.CalculationPeriod;  
	
	NewRow = AccruedByEmployees.Add();
	NewRow.Employee = FillingData.Employee;
	
EndProcedure

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
