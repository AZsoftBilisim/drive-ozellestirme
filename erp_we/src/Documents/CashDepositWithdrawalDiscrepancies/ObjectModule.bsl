
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	Author = Users.CurrentUser();
	
	If TypeOf(FillingData) = Type("DocumentRef.CashVoucher") Then
		FillInUsingExpenseCashOrder(FillingData, FillingData);
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef." + Metadata().Name) Then
		
		DocumentCorrection.FillInCorrection(ThisObject, FillingData);
		
	EndIf;
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	If Not TypeOf(FillingData) = Type("DocumentRef." + Metadata().Name) Then
		InitializeDocument(FillingData);
	Else
		EmployeeResponsible = Users.CurrentUser();
	EndIf;
	
	CashDepositWithdrawalDiscrepanciesLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
	If Not ValueIsFilled(EmployeeResponsible) Then
		EmployeeResponsible = Users.CurrentUser();
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.CashDepositWithdrawalDiscrepancies.ItemsAndDimensionsSelectionParameters(BusinessOperation);
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	ItemsAndDimensionsSelectionParameters = Documents.CashDepositWithdrawalDiscrepancies.ItemsAndDimensionsSelectionParameters(BusinessOperation);
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	CashDepositWithdrawalDiscrepanciesLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	TMCommonUse.FillInDocumentIDs(ThisObject);
	
	ItemsAndDimensionsSelectionParameters = Documents.CashDepositWithdrawalDiscrepancies.ItemsAndDimensionsSelectionParameters(BusinessOperation);
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	CashDepositWithdrawalDiscrepanciesLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	CashDepositWithdrawalDiscrepanciesLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	CashDepositWithdrawalDiscrepanciesLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	CashDepositWithdrawalDiscrepanciesLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	
	TMCommonUse.ClearDocumentIDs(ThisObject);
	
	Author = Users.CurrentUser();
	EmployeeResponsible = Users.CurrentUser();
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillInUsingExpenseCashOrder(Val OutgoPaymentCashAccountBasis, FillingData)
	
	SetPrivilegedMode(True);
	
	Query = New Query("
	|SELECT
	|	DocumentData.Organization        AS Organization,
	|	DocumentData.Department      AS Department,
	|	DocumentData.CashAccount              AS CashAccount,
	|	DocumentData.BankAccount     AS BankAccount,
	|	DocumentData.Currency             AS Currency,
	|	
	|	&Ref AS DocumentBasis,
	|	PRESENTATION(DocumentData.Ref) AS Basis,
	|	
	|	CASE WHEN ISNULL(Cash.SumBalance, 0) > 0 THEN
	|		ISNULL(Cash.SumBalance, 0)
	|	WHEN ISNULL(Cash.SumBalance, 0) < 0 THEN
	|		-ISNULL(Cash.SumBalance, 0)
	|	ELSE
	|		0
	|	END AS Sum,
	|	
	|	CASE WHEN ISNULL(Cash.SumBalance, 0) < 0 THEN
	|		VALUE(Enum.BusinessTransactions.RecordSurplusDuringCashCollection)
	|	ELSE
	|		VALUE(Enum.BusinessTransactions.RecordShortageOnCashCollection)
	|	END AS BusinessOperation
	|	
	|FROM
	|	Document.CashVoucher AS DocumentData
	|	
	|	LEFT JOIN
	|		AccumulationRegister.CashInTransit.Balance(, 
	|			CashTransferKind = VALUE(Enum.CashTransferKinds.CashDepositToBank)
	|		) AS Cash
	|	ON
	|		DocumentData.BankAccount = Cash.Recipient
	|		AND DocumentData.CashAccount = Cash.Sender
	|	
	|WHERE
	|	DocumentData.Ref = &Ref
	|");
	
	Query.SetParameter("Ref", OutgoPaymentCashAccountBasis); 
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần phản ánh chênh lệch khi chuyển tiền nội bộ trên cơ sở chứng từ %1';
				|ru = 'Не требуется отражать расхождение при инкассации денежных средств на основании документа %1';
				|en = 'It is not required to record discrepancy on cash deposit/withdrawal based on document %1'; fa = 'It is not required to record discrepancy on cash deposit/withdrawal based on document %1';
				|it = 'Non è necessario visualizzare le discrepanze d''incasso dei fondi monetari in base al documento %1';
				|pl = 'Nie jest wymagane odzwierciedlenie odchylenia przy pobieraniu środków pieniężnych na podstawie dokumentu %1';
				|tr = '%1 belgesine dayalı nakit yatırma tutarsızlığın yansıtılması gerekli değildir'"),
			OutgoPaymentCashAccountBasis);
		Raise Text;
	Else
		FillingData = New Structure;
		For Each Column In QueryResult.Columns Do
			FillingData.Insert(Column.Name);
		EndDo;
	
		Selection = QueryResult.Select();
		If Selection.Next() Then
			FillPropertyValues(FillingData, Selection);
		EndIf;
	EndIf;
	
EndProcedure

Procedure InitializeDocument(FillingData = Undefined)

	If TypeOf(FillingData) = Type("Structure") Then
		FillPropertyValues(ThisObject, FillingData);
	EndIf;
	
	If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("BusinessOperation") Then
		BusinessOperation = Enums.BusinessTransactions.RecordSurplusDuringCashCollection;
	EndIf;
	
	If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("Organization") Then
		Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	EndIf;
	
	If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("Currency") Then
		If Not ValueIsFilled(Currency) Then
			Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
		EndIf;
	EndIf;
	
	If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("BankAccount") Then
		ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Organization);
		ParametersOfAccount.Currency = Currency;
		BankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount,
			BankAccount);
	EndIf;
	
	If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("CashAccount") Then
		ParametersStructure = CashServer.DefaultParametersForFillingInCheckout();
		ParametersStructure.Organization = Organization;
		ParametersStructure.Currency = Currency;
		ParametersStructure.CashAccount = CashAccount;
		CashAccount = SettingsValueCached.GetOrganizationSDefaultSalesRegister(ParametersStructure);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
