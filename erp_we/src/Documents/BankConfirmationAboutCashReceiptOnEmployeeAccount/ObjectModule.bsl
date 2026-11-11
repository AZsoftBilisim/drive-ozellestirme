#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnCopy(CopiedObject)
	
	ImportErrors = "";
	EmployeeResponsible = Users.CurrentUser();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "EmployeesHR");
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	Return;
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure") Then
		
		ObjectMetadata = Metadata();
		For Each FillingParameter In FillingData Do
			If ObjectMetadata.Attributes.Find(FillingParameter.Key)<>Undefined Then
				ThisObject[FillingParameter.Key] = FillingParameter.Value;
			Else
				If Common.IsStandardAttribute(ObjectMetadata.StandardAttributes, FillingParameter.Key) Then
					ThisObject[FillingParameter.Key] = FillingParameter.Value;
				EndIf;
			EndIf;
		EndDo;
		
		If TypeOf(SourceDocument) = Type("DocumentRef.BankAccountIssue") Then
			BusinessOperation = SourceDocument.BusinessOperation;
		Else
			BusinessOperation = Enums.BusinessTransactions.SalaryPaymentByPayrollCardProgram;
		EndIf;
		
		If SourceDocument <> Undefined
			And SourceDocument.Metadata().Attributes.Find("Department") <> Undefined
			And GetFunctionalOption("UsePayrollTM") Then
			Department = SourceDocument.Department;
		EndIf;
		
		
		If FillingData.Property("EmployeesHR") Then
			
			EmployeesHR.Clear();
			
			For Each StringOfFillValues In FillingData.EmployeesHR Do
				
				NewRow = EmployeesHR.Add();
				FillPropertyValues(NewRow, StringOfFillValues);
				
				If Not ValueIsFilled(NewRow.SalaryCreditingResult) Then
					
					If FillingData.EmployeesHR.Columns.Find("SalaryCreditingResult") <> Undefined
						And TypeOf(StringOfFillValues.SalaryCreditingResult) = Type("String") Then
						NewRow.SalaryCreditingResult = Enums.SalaryCreditingResults[StringOfFillValues.SalaryCreditingResult];
					EndIf;
					
				EndIf;
				
			EndDo;
			
			If FillingData.EmployeesHR.Columns.Find("CurrencyCode_") <> Undefined Then
				Currency = Catalogs.Currencies.FindByCode(FillingData.EmployeesHR[0].CurrencyCode_);
			Else
				Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
			EndIf;
			
		EndIf;
		
		If TypeOf(SourceDocument) = Type("DocumentRef.BankAccountIssue") Then
			FillInDDSArticlesOnWriteOffDocument();
		EndIf;
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.BankAccountIssue") Then
		InstructionsForDebitingNonCashFunds(FillingData);
	EndIf;
	
	DocumentAmount = EmployeesHR.Total("Sum");
	
	If Not ValueIsFilled(EmployeeResponsible) Then
		EmployeeResponsible = Users.CurrentUser();
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	StandardProcessing = True;
	
	AdditionalProperties.Insert("FillingErrors", "");
	
	If StandardProcessing Then
		
		Query = New Query;
		
		Query.SetParameter("Ref", Ref);
		Query.SetParameter("SourceDocument", SourceDocument);
		Query.SetParameter("EmployeesHR", EmployeesHR.Unload());
		Query.SetParameter("HashOfFile", HashOfFile);
		
		Query.Text =
		"SELECT
		|	BankConfirmationAboutCashReceiptOnEmployeeAccount.Ref
		|FROM
		|	Document.BankConfirmationAboutCashReceiptOnEmployeeAccount AS BankConfirmationAboutCashReceiptOnEmployeeAccount
		|WHERE
		|	BankConfirmationAboutCashReceiptOnEmployeeAccount.SourceDocument = &SourceDocument
		|	AND BankConfirmationAboutCashReceiptOnEmployeeAccount.Ref <> &Ref
		|	AND BankConfirmationAboutCashReceiptOnEmployeeAccount.Posted
		|	AND BankConfirmationAboutCashReceiptOnEmployeeAccount.HashOfFile = &HashOfFile";
		
		SetPrivilegedMode(True);
		Result = Query.Execute();
		SetPrivilegedMode(False);
		
		If Not Result.IsEmpty() Then
			ErrorText = NStr("vi = 'Đã đăng ký xác nhận theo chứng từ gốc.';
							|ru = 'Подтверждение по первичному документу уже зарегистрировано.';
							|en = 'Confirmation of the source document is already registered.'; fa = 'Confirmation of the source document is already registered.';
							|it = 'Conferma per documento primario già registrata.';
							|pl = 'Potwierdzenie według dokumentu podstawowego zostało już zarejestrowane.';
							|tr = 'Birincil belgenin onayı zaten kaydedilmiştir.'");
			Common.MessageToUser(ErrorText, ThisObject, "SourceDocument", , Cancel);
			CashServer.AddFillInError(AdditionalProperties.FillingErrors, ErrorText);
		EndIf;
		
		If BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder Then
			
			DocumentsArray = New Array;
			DocumentsArray.Add(SourceDocument);
			If AdditionalProperties.Property("FillingErrors") Then
				CashServer.CheckFillingOfPersonalAccountsBySources(
					ThisObject, "EmployeesHR", DocumentsArray, Cancel, True, AdditionalProperties.FillingErrors);
			Else
				CashServer.CheckFillingOfPersonalAccountsBySources(ThisObject, "EmployeesHR", DocumentsArray, Cancel);
			EndIf;
			
		
		EndIf;
		
	EndIf;
	
	
	AttributesNotToCheck = New Array;
	AttributesNotToCheck.Add("PayrollCardProgram");
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If WriteMode = DocumentWriteMode.Posting Then
		ImportErrors = "";
	EndIf;
	
	If Not Common.SubsystemExists("SalaryPersonnelSubsystems") Then
		FillInShortCompositionOfDocument();
	EndIf;
	
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "EmployeesHR");
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.ClearDocumentRegisteredRecords(ThisObject, "OtherAssetsLiabilities");
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
		
	Return;
	
EndProcedure

#EndRegion

#Region Private


#Region ProceduresAndFunctionsForReceivingConfirmationFile


#EndRegion

Procedure InstructionsForDebitingNonCashFunds(FillingData)
	
	BaseOperation = Common.ObjectAttributeValue(FillingData, "BusinessOperation");
	
	If BaseOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder Then
		GetDataOfFillingOutPaymentToAccountable(FillingData, FillingData);
	EndIf;
	
	FillPropertyValues(ThisObject, FillingData);
	
	EmployeeResponsible = Users.CurrentUser();
	
EndProcedure

Procedure GetDataOfFillingOutPaymentToAccountable(Val Basis, FillingData) Export

	Query = New Query;
	Query.Text = 
		"SELECT
		|	WriteOffOfNonCashDS.Ref AS Ref,
		|	WriteOffOfNonCashDS.Ref AS SourceDocument,
		|	WriteOffOfNonCashDS.BusinessOperation AS BusinessOperation,
		|	WriteOffOfNonCashDS.Organization AS Organization,
		|	WriteOffOfNonCashDS.Department AS Department,
		|	WriteOffOfNonCashDS.Currency AS Currency,
		|	WriteOffOfNonCashDS.CounterpartyBankAccount AS CounterpartyBankAccount,
		|	WriteOffOfNonCashDS.CounterpartyBankAccount.Bank AS Bank,
		|	WriteOffOfNonCashDS.BankContractNumber AS BankContractNumber
		|INTO MainDataOfDocument
		|FROM
		|	Document.BankAccountIssue AS WriteOffOfNonCashDS
		|WHERE
		|	WriteOffOfNonCashDS.Ref = &Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MainDataOfDocument.Ref AS Ref,
		|	MainDataOfDocument.SourceDocument AS SourceDocument,
		|	MainDataOfDocument.BusinessOperation AS BusinessOperation,
		|	MainDataOfDocument.Organization AS Organization,
		|	MainDataOfDocument.Department AS Department,
		|	MainDataOfDocument.Currency AS Currency,
		|	MainDataOfDocument.CounterpartyBankAccount AS CounterpartyBankAccount,
		|	MainDataOfDocument.Bank AS Bank,
		|	MainDataOfDocument.BankContractNumber AS ContractNumber
		|FROM
		|	MainDataOfDocument AS MainDataOfDocument
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	PersonalAccountsOfStaff.Individual AS Individual,
		|	PersonalAccountsOfStaff.PersonalAccount.AccountNumber AS PersonalAccountNumber,
		|	PersonalAccountsOfStaff.CashFlowItem AS CashFlowItem,
		|	SUM(PersonalAccountsOfStaff.Sum) AS Sum,
		|	VALUE(Enum.SalaryCreditingResults.Credited) AS SalaryCreditingResult
		|FROM
		|	MainDataOfDocument AS MainDataOfDocument
		|		INNER JOIN Document.BankAccountIssue.PersonalAccountsOfStaff AS PersonalAccountsOfStaff
		|		ON MainDataOfDocument.Ref = PersonalAccountsOfStaff.Ref
		|
		|GROUP BY
		|	PersonalAccountsOfStaff.Individual,
		|	PersonalAccountsOfStaff.PersonalAccount.AccountNumber,
		|	PersonalAccountsOfStaff.CashFlowItem
		|";
	
	Query.SetParameter("Ref", Basis);
	
	QueryResultsArray = Query.ExecuteBatch();
	
	FillingData = New Structure;
	
	For Each Column In QueryResultsArray[QueryResultsArray.UBound() - 1].Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	MainData = QueryResultsArray[QueryResultsArray.UBound() - 1].Select();
	TabularSectionData = QueryResultsArray[QueryResultsArray.UBound()].Select();
	
	MainData.Next();
	FillPropertyValues(FillingData, MainData);
	

	While TabularSectionData.Next() Do
		
		NewRow = EmployeesHR.Add();
		FillPropertyValues(NewRow, TabularSectionData);
		
	EndDo;

EndProcedure

Procedure FillInDDSArticlesOnWriteOffDocument()
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	PersonalAccountsOfStaff.Individual AS Individual,
	|	PersonalAccountsOfStaff.PersonalAccount.AccountNumber AS PersonalAccountNumber,
	|	PersonalAccountsOfStaff.CashFlowItem AS CashFlowItem,
	|	PersonalAccountsOfStaff.Sum AS Sum
	|FROM
	|	Document.BankAccountIssue.PersonalAccountsOfStaff AS PersonalAccountsOfStaff
	|WHERE
	|	PersonalAccountsOfStaff.Ref = &Ref
	|	AND PersonalAccountsOfStaff.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
	|
	|";
	
	Query.SetParameter("Ref", SourceDocument);
	
	Selection = Query.Execute().Select();
	
	TheStructureOfTheSearch = New Structure("Individual, PersonalAccountNumber, Sum");
	
	For Each TSRow In EmployeesHR Do
		FillPropertyValues(TheStructureOfTheSearch, TSRow);
		If Selection.FindNext(TheStructureOfTheSearch) Then
			TSRow.CashFlowItem = Selection.CashFlowItem;
			Selection.Reset();
		EndIf;
	EndDo;
	
EndProcedure


Procedure FillInShortCompositionOfDocument()
	
	ListOfAbbreviatedFullNames = New Array;
	MaximumNumberOfCharacters = 100;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	EmployeesHR.Individual AS Individual
		|INTO ListOfIndividuals
		|FROM
		|	&EmployeesHR AS EmployeesHR
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	FullNameOfPersonsSliceLast.LastName AS LastName,
		|	FullNameOfPersonsSliceLast.Name AS Name,
		|	FullNameOfPersonsSliceLast.MiddleName AS MiddleName
		|FROM
		|	InformationRegister.FullNameOfPersons.SliceLast(
		|			&OnDate,
		|			Individual IN
		|				(SELECT DISTINCT
		|					ListOfIndividuals.Individual AS Individual
		|				FROM
		|					ListOfIndividuals AS ListOfIndividuals)) AS FullNameOfPersonsSliceLast";
	
	Query.SetParameter("EmployeesHR", EmployeesHR.Unload());
	Query.SetParameter("OnDate", Date);
	
	QueryResult = Query.Execute().Select();
	
	While QueryResult.Next() Do
		
		Initials = "";
		
		If Not IsBlankString(QueryResult.Name) Then
			Initials = Left(QueryResult.Name, 1) + ".";
		EndIf;
		
		If Not IsBlankString(QueryResult.MiddleName) Then
			Initials = Initials + " " + Left(QueryResult.MiddleName, 1) + ".";
		EndIf;
		
		InitialsAndLastName = QueryResult.LastName + ?(Initials <> "", " " + Initials, "");
		
		If StrLen(InitialsAndLastName) <= MaximumNumberOfCharacters Then
			ListOfAbbreviatedFullNames.Add(InitialsAndLastName);
			MaximumNumberOfCharacters = MaximumNumberOfCharacters - StrLen(InitialsAndLastName);
		Else
			Break;
		EndIf; 
		
	EndDo;
	
	If ListOfAbbreviatedFullNames.Count() <> 0 Then
		BriefDocumentComposition = StrConcat(ListOfAbbreviatedFullNames, ", ");
	EndIf;
	
EndProcedure

#EndRegion

#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf