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
	KeyAttributes.Add("Accrual");
	TMCommonUse.CheckForDuplicatesOfTSStrings(ThisObject, "BasicEarnings", KeyAttributes, Cancel); 
	
	If BasicEarnings.Count() = 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Не введено ни одной строки в таблице ""%1""';
																					|vi = 'No line is entered into the ""%1"" table';
																					|en = 'No line is entered into the ""%1"" table'; fa = 'No line is entered into the ""%1"" table';
																					|it = 'No line is entered into the ""%1"" table';
																					|pl = 'No line is entered into the ""%1"" table';
																					|tr = '""%1"" tablosunda hiç satır girilmemiş'"), "Main earnings1");
		
		Common.MessageToUser(MessageText,
												Undefined,
												"BasicEarnings",
												"",
												Cancel);
	EndIf; 
	
	For Each TSItem In BasicEarnings Do
		AssignmentStructure = OperationalAccountingOfManufacturingPayrollAndHumanResources.PersonnelHistoryOfEmployee(Organization, TSItem.Employee, ChangeDate); 
		
		If Not ValueIsFilled(AssignmentStructure.JobTitle) Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Сотрудник %1 не работает в организации на дату %2';
																						|vi = 'Employee %1 does not work for the company as of %2';
																						|en = 'Employee %1 does not work for the company as of %2'; fa = 'Employee %1 does not work for the company as of %2';
																						|it = 'Employee %1 does not work for the company as of %2';
																						|pl = 'Employee %1 does not work for the company as of %2';
																						|tr = 'Çalışan %1, %2 tarihi itibarıyla iş yerinde çalışmıyor.'"), TSItem.Employee, ChangeDate);
			
			Common.MessageToUser(MessageText,
												ThisObject,
												CommonClientServer.PathToTabularSection("BasicEarnings", TSItem.LineNumber, "CancellationReason"),
												"",
												Cancel);    
		EndIf;
		
		If DocumentsPayrollAndHumanResourcesServer.ForThisAccrualYouNeedStandardHours(TSItem.Accrual)
			 And Not ValueIsFilled(TSItem.TimeKindForNorms) Then
		 
			MessageText = NStr("ru = 'Не указан вид времени для определения норм';
								|vi = 'No work time type is specified for determining standards';
								|en = 'No work time type is specified for determining standards'; fa = 'No work time type is specified for determining standards';
								|it = 'No work time type is specified for determining standards';
								|pl = 'No work time type is specified for determining standards';
								|tr = 'Normların belirlenmesi için zaman türü belirtilmemiş'");
		
			Common.MessageToUser(MessageText,
						ThisObject,
						CommonClientServer.PathToTabularSection("BasicEarnings", TSItem.LineNumber, "TimeKindForNorms"),
						"",
						Cancel);	
		 
		EndIf;	
		 
		AccrualValueIsAvailable = DocumentsPayrollAndHumanResourcesServer.MethodOfAccrualOfDeductionWithoutSpecifyingAmountServer(
			TSItem.Accrual, True);

		If TSItem.NewValue_ = 0 And Not TSItem.AdvancePaymentNew
			And Not AccrualValueIsAvailable Then

			PathToTop = CommonClientServer.PathToTabularSection("BasicEarnings",
				TSItem.LineNumber, "NewValue_");

			MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr(
				"ru = 'В табличной части для начисления ""%1"" надо указывать новое значение или аванс';
				|vi = 'Specify a new value or advance payment for the ""%1"" accrual in the table';
				|en = 'Specify a new value or advance payment for the ""%1"" accrual in the table'; fa = 'Specify a new value or advance payment for the ""%1"" accrual in the table';
				|it = 'Specify a new value or advance payment for the ""%1"" accrual in the table';
				|pl = 'Specify a new value or advance payment for the ""%1"" accrual in the table';
				|tr = 'Tablo kısmında ""%1"" tahakkuku için yeni değer veya avans belirtilmelidir.'"),
				TSItem.Accrual);

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
													BegOfMonth(ChangeDate), BasicEarnings.Unload(,"Employee"));	
		
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
	
	BasicEarnings.Clear();
	
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
