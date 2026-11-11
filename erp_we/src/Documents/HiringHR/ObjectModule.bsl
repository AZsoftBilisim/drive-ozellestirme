#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)

	If Not ValueIsFilled(DateOfAdmission) Then
		DateOfAdmission = CurrentSessionDate();
	EndIf;
	
	InitializeDocument(FillingData);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
 	If EmployeeWasEmployedByCompanyEarlier() Then
			
		Text = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Сотрудник %1 уже был принят в организацию %2 ранее';
						|vi = 'Employee %1 is already hired in the ""%2"" company';
						|en = 'Employee %1 is already hired in the ""%2"" company'; fa = 'Employee %1 is already hired in the ""%2"" company';
						|it = 'Employee %1 is already hired in the ""%2"" company';
						|pl = 'Employee %1 is already hired in the ""%2"" company';
						|tr = 'Çalışan %1, %2 iş yerine daha önce zaten alınmıştı.'"),
					Employee, Organization);
		Common.MessageToUser(Text, ThisObject, , , Cancel);
		
	EndIf;	
	
	KeyAttributes = New Array;
	KeyAttributes.Add("Accrual");
	TMCommonUse.CheckForDuplicatesOfTSStrings(ThisObject, "Accruals", KeyAttributes, Cancel);
	
	KeyAttributes = New Array;
	KeyAttributes.Add("Retention");
	TMCommonUse.CheckForDuplicatesOfTSStrings(ThisObject, "Deductions", KeyAttributes, Cancel);  
	
	ValueOfBasicAccrualIsAvailable = DocumentsPayrollAndHumanResourcesServer.MethodOfAccrualOfDeductionWithoutSpecifyingAmountServer(BasicAccrual, True); 
	
	If BaseValue = 0 
		And Not ValueOfBasicAccrualIsAvailable Then 
	
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Для нового основного заробока ""%1"" не указано базовое начисление';
																					|vi = 'Specify the basic accrual for the new basic earnings (%1)';
																					|en = 'Specify the basic accrual for the new basic earnings (%1)'; fa = 'Specify the basic accrual for the new basic earnings (%1)';
																					|it = 'Specify the basic accrual for the new basic earnings (%1)';
																					|pl = 'Specify the basic accrual for the new basic earnings (%1)';
																					|tr = 'Yeni temel kazanç ""%1"" için temel tahakkuk belirtilmemiş.'"), BasicAccrual);
	
		Common.MessageToUser(MessageText,
					ThisObject,
					"BaseValue",
					"",
					Cancel) 
					
	EndIf;
				
	If Not BaseValue = 0 
		And ValueOfBasicAccrualIsAvailable Then 
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Для нового основного заробока ""%1"" не надо указывать базовое начисление';
																					|vi = 'Do not specify the basic accrual for the new basic earnings (%1)';
																					|en = 'Do not specify the basic accrual for the new basic earnings (%1)'; fa = 'Do not specify the basic accrual for the new basic earnings (%1)';
																					|it = 'Do not specify the basic accrual for the new basic earnings (%1)';
																					|pl = 'Do not specify the basic accrual for the new basic earnings (%1)';
																					|tr = 'Yeni temel kazanç ""%1"" için temel tahakkuk belirtilmemelidir.'"), BasicAccrual);
		
		Common.MessageToUser(MessageText,
					ThisObject,
					"BaseValue",
					"",
					Cancel);
					
	EndIf;
				
	ArrayOfAccrualLines = Accruals.FindRows(New Structure("Accrual", BasicAccrual));
	
	If ArrayOfAccrualLines.Count() > 0 Then  
		
		Common.MessageToUser(NStr("ru = 'В табличной части ""Прочие начисления"" не должно быть указно основное начисление';
									|vi = 'The ""Other accruals"" table must not contain main accrual';
									|en = 'The ""Other accruals"" table must not contain main accrual'; fa = 'The ""Other accruals"" table must not contain main accrual';
									|it = 'The ""Other accruals"" table must not contain main accrual';
									|pl = 'The ""Other accruals"" table must not contain main accrual';
									|tr = '""Diğer tahakkuklar"" tablo kısmında temel tahakkuk belirtilmemelidir.'"), ThisObject, "Accruals", ,Cancel);
		
	EndIf;
	
	CompanyOfEmployee = Common.ObjectAttributeValue(Employee, "ParentCompany");
	
	If Not Organization = CompanyOfEmployee Then
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Организация ""%1"" документа не соответствует организации ""%2"", установленной у сотрудника';
																					|vi = 'The ""%1"" company of the document does not correspond to the company specified for the employee (%2)';
																					|en = 'The ""%1"" company of the document does not correspond to the company specified for the employee (%2)'; fa = 'The ""%1"" company of the document does not correspond to the company specified for the employee (%2)';
																					|it = 'The ""%1"" company of the document does not correspond to the company specified for the employee (%2)';
																					|pl = 'The ""%1"" company of the document does not correspond to the company specified for the employee (%2)';
																					|tr = 'Belgenin ""%1"" iş yeri, çalışanda belirlenen ""%2"" iş yeri ile uyuşmuyor.'")
														, Organization, CompanyOfEmployee);
		
		Common.MessageToUser(MessageText,
					ThisObject,
					"Organization",
					"",
					Cancel);	
		
	EndIf;
	
	If DocumentsPayrollAndHumanResourcesServer.ForThisAccrualYouNeedStandardHours(BasicAccrual)
		 And Not ValueIsFilled(TimeKindForNorms) Then
		 
		MessageText = NStr("ru = 'Не указан вид времения, для определения норм';
							|vi = 'No work time type is specified for determining standards';
							|en = 'No work time type is specified for determining standards'; fa = 'No work time type is specified for determining standards';
							|it = 'No work time type is specified for determining standards';
							|pl = 'No work time type is specified for determining standards';
							|tr = 'Normların belirlenmesi için zaman türü belirtilmemiş.'");
		
		Common.MessageToUser(MessageText,
					ThisObject,
					"TimeKindForNorms",
					"",
					Cancel);	
		 
	EndIf;	
	 
	For Each AccrualElement In Accruals Do
	
		AccrualValueIsAvailable = DocumentsPayrollAndHumanResourcesServer.MethodOfAccrualOfDeductionWithoutSpecifyingAmountServer(AccrualElement.Accrual, False); 
		
		If AccrualElement.Value = 0
			And Not AccrualValueIsAvailable Then
				
			PathToTop = CommonClientServer.PathToTabularSection("Accruals", AccrualElement.LineNumber, "Value");
				
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'В табличной части ""Прочие начисления"" для начисления ""%1"" надо указывать значение';
																						|vi = 'Specify the value for the ""%1"" accrual in the ""Other accruals"" table';
																						|en = 'Specify the value for the ""%1"" accrual in the ""Other accruals"" table'; fa = 'Specify the value for the ""%1"" accrual in the ""Other accruals"" table';
																						|it = 'Specify the value for the ""%1"" accrual in the ""Other accruals"" table';
																						|pl = 'Specify the value for the ""%1"" accrual in the ""Other accruals"" table';
																						|tr = 'Tablo kısmında ""Diğer tahakkuklar"" için ""%1"" tahakkukunda değer belirtilmelidir.'"), AccrualElement.Accrual);
		
			Common.MessageToUser(MessageText,
						ThisObject,
						PathToTop,
						"",
						Cancel);	
				
		EndIf;
		
	EndDo;
	
	For Each RetentionElement In Deductions Do
	
		RetentionValueIsAvailable = DocumentsPayrollAndHumanResourcesServer.MethodOfAccrualOfDeductionWithoutSpecifyingAmountServer(RetentionElement.Retention, False); 
		
		If RetentionElement.Value = 0
			And Not RetentionValueIsAvailable Then
				
			PathToTop = CommonClientServer.PathToTabularSection("Deductions", RetentionElement.LineNumber, "Value");
				
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'В табличной части ""Удержания"" для удержания ""%1"" надо указывать значение';
																						|vi = 'Specify the value for the ""%1"" deduction in the ""Deductions"" table';
																						|en = 'Specify the value for the ""%1"" deduction in the ""Deductions"" table'; fa = 'Specify the value for the ""%1"" deduction in the ""Deductions"" table';
																						|it = 'Specify the value for the ""%1"" deduction in the ""Deductions"" table';
																						|pl = 'Specify the value for the ""%1"" deduction in the ""Deductions"" table';
																						|tr = 'Tablo kısmında ""Kesintiler"" için ""%1"" kesintisinde değer belirtilmelidir.'"), RetentionElement.Retention);
		
			Common.MessageToUser(MessageText,
						ThisObject,
						PathToTop,
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
		And DocumentsPayrollAndHumanResourcesServer.DocumentDataIsUsedToCalculateBlockedPOData(Ref, True) Then
		
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
	
	HRRecordkeepingPostingPayrollAndHumanResourcesServer.ControlOfCancellationOfPersonnelDocument(Employee, Organization, DateOfAdmission, ThisObject, Cancel); 
		
EndProcedure

Procedure OnCopy(CopiedObject)
	
	Employee = Catalogs.EmployeesHR.EmptyRef();
	
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

Function EmployeeWasEmployedByCompanyEarlier()
	
	If Not ValueIsFilled(Employee)
		Or Not ValueIsFilled(Organization) Then
		Return False;
	EndIf;
	
	Query = New Query();
	Query.Text = 
	"SELECT
	|	EmploymentRecord.Employee AS Employee
	|FROM
	|	InformationRegister.EmploymentRecord AS EmploymentRecord
	|WHERE
	|	EmploymentRecord.Organization = &Organization
	|	AND EmploymentRecord.Employee = &Employee
	|	AND EmploymentRecord.Period < &DateOfAdmission
	|	AND EmploymentRecord.Recorder <> &Ref";
	
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Employee", Employee);
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("DateOfAdmission", DateOfAdmission);
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction	

#EndRegion

#EndIf
