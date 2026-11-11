#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)

	If Not ValueIsFilled(ChangeDate) Then
		ChangeDate = CurrentSessionDate();
	EndIf;
	
	InitializeDocument(FillingData);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	KeyAttributes = New Array;
	KeyAttributes.Add("Employee");
	TMCommonUse.CheckForDuplicatesOfTSStrings(ThisObject, "ChangesTable", KeyAttributes, Cancel);
	
	If ChangesTable.Count() = 0 Then
		MessageText= NStr("ru = 'Не введено ни одной строки в таблице';
							|vi = 'No line is entered into the table';
							|en = 'No line is entered into the table'; fa = 'No line is entered into the table';
							|it = 'No line is entered into the table';
							|pl = 'No line is entered into the table';
							|tr = 'Tabloda hiç satır girilmemiş'");
		
		Common.MessageToUser(MessageText,
												Undefined,
												"ChangesTable",
												"",
												Cancel);
	EndIf;
	
	AccrualValueIsAvailable = DocumentsPayrollAndHumanResourcesServer.MethodOfAccrualOfDeductionWithoutSpecifyingAmountServer(Accrual, False); 
	
	For Each TSItem In ChangesTable Do
		AssignmentStructure = OperationalAccountingOfManufacturingPayrollAndHumanResources.PersonnelHistoryOfEmployee(Organization, TSItem.Employee, EndOfDay(ChangeDate)); 
		
		If Not ValueIsFilled(AssignmentStructure.JobTitle) Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Сотрудник %1 не работает в организации на дату %2';
																						|vi = 'Employee %1 does not work for the company as of %2';
																						|en = 'Employee %1 does not work for the company as of %2'; fa = 'Employee %1 does not work for the company as of %2';
																						|it = 'Employee %1 does not work for the company as of %2';
																						|pl = 'Employee %1 does not work for the company as of %2';
																						|tr = 'Çalışan %1, %2 tarihi itibarıyla iş yerinde çalışmıyor.'"), TSItem.Employee, ChangeDate);
			
			Common.MessageToUser(MessageText,
												ThisObject,
												CommonClientServer.PathToTabularSection("ChangesTable", TSItem.LineNumber, "CancellationReason"),
												"",
												Cancel);
		EndIf;
		
		If TSItem.NewValue_ = 0
			And Not AccrualValueIsAvailable 
			And Action = Enums.CompensationPlanActionsPayrollAndHumanResources.ApproveNew Then
				
			PathToTop = CommonClientServer.PathToTabularSection("ChangesTable",
				TSItem.LineNumber, "NewValue_");

			MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr(
				"ru = 'В табличной части для начисления ""%1"" надо указывать новое значение';
				|vi = 'Specify a new value for the ""%1"" accrual in the table';
				|en = 'Specify a new value for the ""%1"" accrual in the table'; fa = 'Specify a new value for the ""%1"" accrual in the table';
				|it = 'Specify a new value for the ""%1"" accrual in the table';
				|pl = 'Specify a new value for the ""%1"" accrual in the table';
				|tr = 'Tablo kısmında ""%1"" tahakkuku için yeni değer belirtilmelidir.'"),
				Accrual);

			Common.MessageToUser(MessageText, ThisObject, PathToTop, "", Cancel);	
				
		EndIf;
	EndDo;
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load  Then
		Return;
	EndIf;
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);	
	
	If WriteMode = DocumentWriteMode.UndoPosting
		And DocumentsPayrollAndHumanResourcesServer.DocumentDataIsUsedToCalculateBlockedPOData(Ref, True) Then
		
		DocumentsPayrollAndHumanResourcesServer.ReportErrorsCancellationOfEvent(Ref, Cancel);	

	ElsIf  WriteMode = DocumentWriteMode.Posting Then
		
		ListOfEmployees = DocumentsPayrollAndHumanResourcesServer.PayrollBlocked(Organization, 
													BegOfMonth(ChangeDate), ChangesTable.Unload(,"Employee"));	
		
		If ListOfEmployees.Count() > 0 Then
			DocumentsPayrollAndHumanResourcesServer.ReportAboutPostErrors(Ref, ChangeDate, ListOfEmployees, Cancel);	  
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
	
	ChangesTable.Clear();
	
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

#EndRegion

#EndIf
