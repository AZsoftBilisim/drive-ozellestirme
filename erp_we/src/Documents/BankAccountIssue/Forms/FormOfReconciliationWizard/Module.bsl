
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Parameters.Property("Basis") Then
		If ValueIsFilled(Parameters.Basis) Then
			
			If TypeOf(Parameters.Basis) = Type("DocumentRef.PaymentRequest") Then
				
				DocumentBasis = Parameters.Basis;
				
				Parameters.Property("BusinessOperation", BusinessOperation);
				
				Attributes = Common.ObjectAttributesValues(DocumentBasis, "Currency, Organization, BankAccount");
				Organization = Attributes.Organization;
				CurrencyBase = Attributes.Currency;
				
				If Parameters.Property("BankAccount") Then
					BankAccount = Parameters.BankAccount;
				ElsIf ValueIsFilled(Attributes.BankAccount) Then
					BankAccount = Attributes.BankAccount;
				Else
					ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Attributes.Organization);
					ParametersOfAccount.Currency = Attributes.Currency;
					BankAccount = Catalogs.CompaniesBankAccounts.GetDefaultBankAccount(ParametersOfAccount);
				EndIf;
				
				If Parameters.BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder Then
					FillInTableOfDocumentsForIndividuals();
				//++ WE
				ElsIf GetFunctionalOption("PayrollAndHumanResourcesWE") Then
					FillInTableOfDocumentsOnStatementsFromHRApplication();
				//-- WE
				Else
						FillInTableOfDocumentsForIndividuals();
				EndIf;
				
			//++ WE
			ElsIf TypeOf(Parameters.Basis) = Type("Structure") And GetFunctionalOption("PayrollAndHumanResourcesWE") Then
				Basis = Parameters.Basis;
				If Basis.Property("ArrayOfStatements") And Basis.ArrayOfStatements.Count() Then
					Organization = Common.ObjectsAttributeValue(
					Basis.ArrayOfStatements, "Organization").Get(Basis.ArrayOfStatements[0]);
					CurrencyBase = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
					CurrencyToFillIn = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
					ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount();
					ParametersOfAccount.Organization = Organization;
					ParametersOfAccount.Currency = CurrencyToFillIn;
					BankAccount =
						Catalogs.CompaniesBankAccounts.GetDefaultBankAccount(ParametersOfAccount);
				EndIf;
				CurrencyBase     = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
				FillInTableOfDocumentsOnHRStatement(Basis.ArrayOfStatements);
			//-- WE
			
			EndIf;
		EndIf;
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	For Each TableRow In DocumentsTable Do
		If Not ValueIsFilled(TableRow.DocumentWriteOff) Then
			TableRow.Mark = True;
		EndIf;
	EndDo;
	
	Items.DocumentsTableSum.Title =
		StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Số tiền (%1)';
																		|ru = 'Сумма (%1)';
																		|en = 'Amount (%1)'; fa = 'Amount (%1)';
																		|it = 'Totale (%1)';
																		|pl = 'Wartość (%1)';
																		|tr = 'Tutar (%1)'"), String(CurrencyBase));
		
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDocumentsTable

&AtClient
Procedure DocumentsTableMarkOnChange(Item)
	
	If ValueIsFilled(Item.Parent.CurrentData.DocumentWriteOff) Then
		Item.Parent.CurrentData.Mark = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure DocumentsTableDocumentWriteOffOnChange(Item)
	
	Item.Parent.CurrentData.Mark = False;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure UncheckAll(Command)
	
	SetLineCheckboxes(False);
	
EndProcedure

&AtClient
Procedure CheckAll(Command)
	
	SetLineCheckboxes(True);
	
EndProcedure

&AtClient
Procedure CreateDocuments(Command)

	ClearMessages();
	
	If Not ValueIsFilled(BankAccount) Then
		ErrorMessage = NStr("vi = 'Chưa điền trường ""Tài khoản ngân hàng"".';
							|ru = 'Поле ""Банковский счет"" не заполнено.';
							|en = 'The ""Bank account"" field is not filled in.'; fa = 'The ""Bank account"" field is not filled in.';
							|it = 'Campo ""Conto corrente"" non compilato.';
							|pl = 'Pole ""Rachunek bankowy"" nie jest wypełniony.';
							|tr = '""Banka hesabı"" alanı doldurulmamış.'");
		CommonClient.MessageToUser(ErrorMessage,, "BankAccount");
		Return;
	EndIf;
	
	RowIndex = 0;
	For Each TableRow In DocumentsTable Do
		
		If Not TableRow.Mark Then
			RowIndex = RowIndex + 1;
			Continue;
		EndIf;
		
		CreateWriteOffDocumentsOnServer(
			TableRow.Individual, TableRow.PersonalAccount, TableRow.Sum, TableRow.PoPaymentStatement, RowIndex);
		
		RowIndex = RowIndex + 1;
	EndDo; 
	
EndProcedure

&AtClient
Procedure OpenDocumentLog(Command)
	
	FilterParameters = New Structure("DocumentBasis", DocumentBasis); 
	OpenForm("Document.BankAccountIssue.ListForm", FilterParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SetLineCheckboxes(CreateDocuments_)
	
	For Each TableRow In DocumentsTable Do
		If Not ValueIsFilled(TableRow.DocumentWriteOff) Then
			TableRow.Mark = CreateDocuments_;
		EndIf;
	EndDo;
	
EndProcedure


//++ WE

&AtServer
Procedure FillInTableOfDocumentsOnStatementsFromHRApplication()
	
	Attributes = Common.ObjectAttributeValue(DocumentBasis, "ARAPDetails");
	FillInTableOfDocumentsOnHRStatement(
		Attributes.Unload().UnloadColumn("Statement"));
	
EndProcedure

&AtServer
Procedure FillInTableOfDocumentsOnHRStatement(Basis1)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	PayrollStatementHRContent.Individual AS Individual,
	|	PayrollStatementHRContent.BankAccount AS PersonalAccount,
	|	SUM(PayrollStatementHRContent.ToBePaid) AS Sum,
	|	PayrollStatementHRContent.Ref AS PoPaymentStatement,
	|	ISNULL(PaymentsAccordingToStatement.Ref, VALUE(Document.BankAccountIssue.EmptyRef)) AS DocumentWriteOff
	|FROM
	|	Document.PayrollStatementHR.Content AS PayrollStatementHRContent
	|		LEFT JOIN Document.BankAccountIssue.ARAPDetails AS PaymentsAccordingToStatement
	|		ON PayrollStatementHRContent.Individual = PaymentsAccordingToStatement.Ref.AdvanceHolder
	|			AND PayrollStatementHRContent.BankAccount = PaymentsAccordingToStatement.Ref.CounterpartyBankAccount
	|			AND PayrollStatementHRContent.Ref = PaymentsAccordingToStatement.Statement
	|			AND (NOT PaymentsAccordingToStatement.Ref.DeletionMark)
	|WHERE
	|	PayrollStatementHRContent.Ref IN(&ArrayOfStatements)
	|
	|GROUP BY
	|	PayrollStatementHRContent.Ref,
	|	PayrollStatementHRContent.BankAccount,
	|	ISNULL(PaymentsAccordingToStatement.Ref, VALUE(Document.BankAccountIssue.EmptyRef)),
	|	PayrollStatementHRContent.Individual";
	
	Query.SetParameter("ArrayOfStatements", Basis1);
	
	DocumentsTable.Load(Query.Execute().Unload());
	
EndProcedure

//-- WE

&AtServer
Procedure FillInTableOfDocumentsForIndividuals()
	
	TSPersonalAccountsOfStaff = Common.ObjectAttributeValue(DocumentBasis, "PersonalAccountsOfStaff");
	IndividualSVT = TSPersonalAccountsOfStaff.Unload();
	IndividualSVT.Columns.Add("DocumentWriteOff",);
	ArrayOfIndividuals = IndividualSVT.UnloadColumn("Individual");
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	WriteOffs.Ref AS DocumentWriteOff,
	|	WriteOffs.AdvanceHolder AS AdvanceHolder
	|FROM
	|	Document.BankAccountIssue AS WriteOffs
	|WHERE
	|	WriteOffs.BusinessOperation = VALUE(Enum.BusinessTransactions.SalaryPaymentToBankAccounts)
	|	AND WriteOffs.AdvanceHolder IN (&ArrayOfIndividuals)
	|	AND WriteOffs.PaymentRequest = &Ref
	|	AND NOT WriteOffs.DeletionMark
	|	
	|UNION ALL
	|	
	|SELECT
	|	WriteOffs.Ref AS DocumentWriteOff,
	|	WriteOffs.AdvanceHolder AS AdvanceHolder
	|FROM
	|	Document.BankAccountIssue AS WriteOffs
	|	INNER JOIN
	|		Document.BankAccountIssue.ARAPDetails AS Details
	|	ON
	|		Details.Ref = WriteOffs.Ref
	|		AND Details.PaymentRequest = &Ref
	|WHERE
	|	WriteOffs.BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
	|	AND WriteOffs.AdvanceHolder IN (&ArrayOfIndividuals)
	|	AND NOT WriteOffs.DeletionMark
	|";
	
	Query.SetParameter("ArrayOfIndividuals", ArrayOfIndividuals);
	Query.SetParameter("Ref", DocumentBasis);
	
	VTDocWriteOff = Query.Execute().Unload();
	For Each PLString In IndividualSVT Do
		FoundRow = VTDocWriteOff.Find(PLString.Individual, "AdvanceHolder");
		If FoundRow <> Undefined Then
			PLString.DocumentWriteOff = FoundRow.DocumentWriteOff;
		EndIf;
	EndDo;
	
	DocumentsTable.Load(IndividualSVT);
	
EndProcedure

&AtServer
Procedure CreateWriteOffDocumentsOnServer(Individual, PersonalAccount, Sum, PoPaymentStatement, RowIndex)
	
	DocumentWriteOffItem = Documents.BankAccountIssue.CreateDocument();
	
	If ValueIsFilled(BusinessOperation) Then
		DocumentWriteOffItem.BusinessOperation = BusinessOperation;
	Else
		DocumentWriteOffItem.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentToBankAccounts;
	EndIf;
	
	If TypeOf(DocumentBasis) = Type("DocumentRef.PaymentRequest") Then
		
		DocumentWriteOffItem.Fill(DocumentBasis);
		
		PurposeText = Common.ObjectAttributeValue(PersonalAccount, "PurposeText");
		If ValueIsFilled(PurposeText) Then
			DocumentWriteOffItem.PaymentPurposes = PurposeText;
		EndIf;
		
		CashFlowItem = Undefined;
		If DocumentWriteOffItem.ARAPDetails.Count() Then
			CashFlowItem = DocumentWriteOffItem.ARAPDetails[0].CashFlowItem;
			If Not ValueIsFilled(CashFlowItem) Then
				CashFlowItem = DocumentWriteOffItem.CashFlowItem;
			EndIf;
		EndIf;
		
		DocumentWriteOffItem.ARAPDetails.Clear();
		DecryptionString = DocumentWriteOffItem.ARAPDetails.Add();
		DecryptionString.PaymentRequest = DocumentBasis;
		DecryptionString.Sum                               = Sum;
		DecryptionString.CashFlowItem       = CashFlowItem;
		DecryptionString.Statement                           = PoPaymentStatement;
		
	//++ WE
	ElsIf GetFunctionalOption("PayrollAndHumanResourcesWE") Then 
		
		DetailsOfStatement = Common.ObjectAttributesValues(
			PoPaymentStatement, New Structure("Organization, Department, DateOfPayment"));
		
		CurrencyToFillIn = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(DetailsOfStatement.Organization);
		
		DocumentWriteOffItem.PaymentDocumentType = Enums.TypesOfPaymentDocuments.PaymentOrder;
		DocumentWriteOffItem.Organization            = DetailsOfStatement.Organization;
		DocumentWriteOffItem.Department          = DetailsOfStatement.Department;
		DocumentWriteOffItem.Currency                 = CurrencyToFillIn;
		DocumentWriteOffItem.BankPostingDate   = DetailsOfStatement.DateOfPayment;;
		
		DecryptionString = DocumentWriteOffItem.ARAPDetails.Add();
		DecryptionString.Statement = PoPaymentStatement;
	//-- WE

	EndIf;

	If Not ValueIsFilled(DocumentWriteOffItem.CashFlowItem) Then
		DocumentWriteOffItem.CashFlowItem =
			Catalogs.CashFlowReportItems.CashFlowItemForBusinessTransaction(
				DocumentWriteOffItem.BusinessOperation);
				
		For Each DecryptionString In DocumentWriteOffItem.ARAPDetails Do
			DecryptionString.CashFlowItem = DocumentWriteOffItem.CashFlowItem;
		EndDo;
	EndIf;
	
	DocumentWriteOffItem.Date                         = CurrentSessionDate();
	DocumentWriteOffItem.AdvanceHolder              = Individual;
	DocumentWriteOffItem.DocumentAmount               = Sum;
	DocumentWriteOffItem.BankAccount               = BankAccount;
	DocumentWriteOffItem.DocumentBasis            = DocumentBasis;
	
	
	If Not ValueIsFilled(DocumentWriteOffItem.Counterparty) Then
		DocumentWriteOffItem.CounterpartyBankAccount = PersonalAccount;
	EndIf;
	
	If DocumentWriteOffItem.ARAPDetails.Count() Then
		DocumentWriteOffItem.ARAPDetails[0].Sum = Sum;
	EndIf;
	
	DocumentWriteOffItem.Write(DocumentWriteMode.Posting);
	
	DocumentsTable[RowIndex].DocumentWriteOff = DocumentWriteOffItem.Ref;
	DocumentsTable[RowIndex].Mark          = False;
	
EndProcedure

#EndRegion
