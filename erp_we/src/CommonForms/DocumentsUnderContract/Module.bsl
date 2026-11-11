
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Parameters.Property("PurposeUseKey") 
		And ValueIsFilled(Parameters.PurposeUseKey) Then
		PurposeUseKey = Parameters.PurposeUseKey;
	ElsIf Parameters.Property("FormAssignmentKey")
		And Not IsBlankString(Parameters.FormAssignmentKey) Then
		PurposeUseKey = Parameters.FormAssignmentKey;
	Else
		PurposeUseKey = DefaultFormAssignmentKey();
	EndIf;
	
	If TypeOf(Parameters.Contract) = Type("CatalogRef.LoanAndDepositContracts") Then
		
		ListProperties = Common.DynamicListPropertiesStructure();
		
		ListProperties.QueryText = StrReplace(DocumentsList.QueryText, "SELECT NULL AS Ref", RequestTextDocumentsOfLoanDepositAgreements());
		ListProperties.MainTable = DocumentsList.MainTable;
		ListProperties.DynamicDataRead = True;
		
		Common.SetDynamicListProperties(Items.DocumentsList, ListProperties);
	ElsIf TypeOf(Parameters.Contract) = Type("CatalogRef.LeaseContract") Then
		
		ListProperties = Common.DynamicListPropertiesStructure();
		
		ListProperties.QueryText = StrReplace(DocumentsList.QueryText, "SELECT NULL AS Ref", RequestTextDocumentsOfLeaseAgreements());
		ListProperties.MainTable = DocumentsList.MainTable;
		ListProperties.DynamicDataRead = True;
		
		Common.SetDynamicListProperties(Items.DocumentsList, ListProperties);
	ElsIf TypeOf(Parameters.Contract) = Type("CatalogRef.IntercompanyContracts")
		Or TypeOf(Parameters.Contract) = Type("CatalogRef.CounterpartyContracts") Then
		
		ListProperties = Common.DynamicListPropertiesStructure();
		
		ListProperties.QueryText = StrReplace(DocumentsList.QueryText, "SELECT NULL AS Ref", RequestTextDocumentsOfCounterpartiesAgreements());
		ListProperties.MainTable = DocumentsList.MainTable;
		ListProperties.DynamicDataRead = True;
		
		Common.SetDynamicListProperties(Items.DocumentsList, ListProperties);
		
	ElsIf TypeOf(Parameters.Contract) = Type("CatalogRef.AcquiringContracts") Then
		
		ListProperties = Common.DynamicListPropertiesStructure();
		
		ListProperties.QueryText = StrReplace(DocumentsList.QueryText, "SELECT NULL AS Ref", RequestTextDocumentsOfAcquiringAgreements());
		ListProperties.MainTable = DocumentsList.MainTable;
		ListProperties.DynamicDataRead = True;
		
		Common.SetDynamicListProperties(Items.DocumentsList, ListProperties);
	EndIf;
	
	DocumentsList.Parameters.SetParameterValue("Contract", Parameters.Contract);
	
	
	ContractType = TypeOf(Parameters.Contract);
	TypesOfContractDocuments = New Array;
	
	DocumentTypes = DocumentsList.SettingsComposer.Settings.Selection.SelectionAvailableFields.FindField(New DataCompositionField("Ref")).Type;
	For Each DocumentType In DocumentTypes.Types() Do
		MetadataOfDocument = Metadata.FindByType(DocumentType);
		ContractDetails = MetadataOfDocument.Attributes.Find("Contract");
		If ContractDetails <> Undefined And ContractDetails.Type.ContainsType(ContractType) Then
			TypesOfContractDocuments.Add(DocumentType);
		EndIf;
	EndDo;
	
	TypesOfContractDocuments.Add(Type("DocumentRef.PaymentRequest"));
	TypesOfContractDocuments.Add(Type("DocumentRef.CashAccountReceiptNote"));
	TypesOfContractDocuments.Add(Type("DocumentRef.CashVoucher"));
	TypesOfContractDocuments.Add(Type("DocumentRef.BankAccountReceiptNote"));
	TypesOfContractDocuments.Add(Type("DocumentRef.BankAccountIssue"));
	TypesOfContractDocuments.Add(Type("DocumentRef.LoanAndDepositInterestCharge"));
	TypesOfContractDocuments.Add(Type("DocumentRef.PaymentCardTransaction"));
	TypesOfContractDocuments.Add(Type("DocumentRef.BankReportOnAcquiringTransactions"));
	TypesOfContractDocuments.Add(Type("DocumentRef.SigningOfLeaseContract"));
	TypesOfContractDocuments.Add(Type("DocumentRef.ReceivingLeaseServices"));
	TypesOfContractDocuments.Add(Type("DocumentRef.VendorInvoiceLeasedAssets"));
	TypesOfContractDocuments.Add(Type("DocumentRef.LeaseTermination"));
	TypesOfContractDocuments.Add(Type("DocumentRef.LeaseTermAdjustment"));
	// StandardSubsystems.AttachableCommands
	If TypesOfContractDocuments.Count() Then
		PlacementParameters = AttachableCommands.PlacementParameters();
		PlacementParameters.Sources = New TypeDescription(TypesOfContractDocuments);
		PlacementParameters.CommandBar = Items.DocumentsListCommandBar;
		AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure PeriodStartDateEndDateOnChange(Item)
	
	DocumentsList.Parameters.SetParameterValue("BeginOfPeriod", Period.StartDate);
	DocumentsList.Parameters.SetParameterValue("EndOfPeriod", Period.EndDate);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDocumentsList

&AtClient
Procedure DocumentsListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure DocumentsListOnActivateRow(Item)
	
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	
EndProcedure

&AtClient
Procedure DocumentsListBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetDateInterval(Command)
	
	Notification = New CallbackDescription("SetDateIntervalCompletion", ThisObject);
	TMCommonUseClient.EditPeriod(Period,, Notification);
	
EndProcedure

&AtClient
Procedure SetDateIntervalCompletion(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	
	Period = ValueSelected;
	SetSelectionByPeriod();
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.DocumentsList);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.DocumentsList, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.DocumentsList);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "DocumentsList.Date", "DocumentsListDate");
	
EndProcedure

&AtClient
Procedure SetSelectionByPeriod()
	
	DocumentsList.Parameters.SetParameterValue("BeginOfPeriod", Period.StartDate);
	DocumentsList.Parameters.SetParameterValue("EndOfPeriod", Period.EndDate);
	
EndProcedure

&AtClientAtServerNoContext
Function DefaultFormAssignmentKey()
	
	Return "DocumentsUnderContract";
	
EndFunction

&AtServer
Function RequestTextDocumentsOfLoanDepositAgreements()
	
	QueryText = "
	|	SELECT
	|		DocumentData.Ref
	|	FROM
	|		InformationRegister.DocumentsRegistry AS DocumentData
	|	WHERE
	|		DocumentData.Contract = &Contract
	|		AND NOT DocumentData.AdditionalRecord
	|";
	
	If AccessRight("Read", Metadata.Documents.PaymentRequest) Then
		
		QueryText = QueryText + "UNION ALL" + "
		|SELECT
		|		DocumentData.Ref AS Ref
		|	FROM
		|		Document.PaymentRequest AS DocumentData
		|	WHERE
		|		DocumentData.Ref IN
		|				(SELECT
		|					TabularSectionData.Ref
		|				FROM
		|					Document.PaymentRequest.ARAPDetails AS TabularSectionData
		|				WHERE
		|					TabularSectionData.Ref = DocumentData.Ref
		|					AND TabularSectionData.LoanDepositContract = &Contract)
		|";
	EndIf;
	
	If AccessRight("Read", Metadata.Documents.CashVoucher) Then
		
		QueryText = QueryText + "UNION ALL" + "
		|SELECT
		|		DocumentData.Ref AS Ref
		|	FROM
		|		Document.CashVoucher AS DocumentData
		|	WHERE
		|		DocumentData.Ref IN
		|				(SELECT
		|					TabularSectionData.Ref
		|				FROM
		|					Document.CashVoucher.ARAPDetails AS TabularSectionData
		|				WHERE
		|					TabularSectionData.Ref = DocumentData.Ref
		|					AND TabularSectionData.LoanDepositContract = &Contract)
		|";
	EndIf;
	
	If AccessRight("Read", Metadata.Documents.BankAccountIssue) Then
		
		QueryText = QueryText + "UNION ALL" + "
		|SELECT
		|		DocumentData.Ref AS Ref
		|	FROM
		|		Document.BankAccountIssue AS DocumentData
		|	WHERE
		|		DocumentData.Ref IN
		|				(SELECT
		|					TabularSectionData.Ref
		|				FROM
		|					Document.BankAccountIssue.ARAPDetails AS TabularSectionData
		|				WHERE
		|					TabularSectionData.Ref = DocumentData.Ref
		|					AND TabularSectionData.LoanDepositContract = &Contract)
		|";
	EndIf;
	
	If AccessRight("Read", Metadata.Documents.CashAccountReceiptNote) Then
		
		QueryText = QueryText + "UNION ALL" + "
		|SELECT
		|		DocumentData.Ref AS Ref
		|	FROM
		|		Document.CashAccountReceiptNote AS DocumentData
		|	WHERE
		|		DocumentData.Ref IN
		|				(SELECT
		|					TabularSectionData.Ref
		|				FROM
		|					Document.CashAccountReceiptNote.ARAPDetails AS TabularSectionData
		|				WHERE
		|					TabularSectionData.Ref = DocumentData.Ref
		|					AND TabularSectionData.LoanDepositContract = &Contract)
		|";
	EndIf;
	
	If AccessRight("Read", Metadata.Documents.BankAccountReceiptNote) Then
		
		QueryText = QueryText + "UNION ALL" + "
		|SELECT
		|		DocumentData.Ref AS Ref
		|	FROM
		|		Document.BankAccountReceiptNote AS DocumentData
		|	WHERE
		|		DocumentData.Ref IN
		|				(SELECT
		|					TabularSectionData.Ref
		|				FROM
		|					Document.BankAccountReceiptNote.ARAPDetails AS TabularSectionData
		|				WHERE
		|					TabularSectionData.Ref = DocumentData.Ref
		|					AND TabularSectionData.LoanDepositContract = &Contract)
		|";
	EndIf;
	
	If AccessRight("Read", Metadata.Documents.LoanAndDepositInterestCharge) Then
		
		QueryText = QueryText + "UNION ALL" + "
		|SELECT
		|		DocumentData.Ref AS Ref
		|	FROM
		|		Document.LoanAndDepositInterestCharge AS DocumentData
		|	WHERE
		|		DocumentData.Ref IN
		|				(SELECT
		|					TabularSectionData.Ref
		|				FROM
		|					Document.LoanAndDepositInterestCharge.Accruals AS TabularSectionData
		|				WHERE
		|					TabularSectionData.Ref = DocumentData.Ref
		|					AND TabularSectionData.Contract = &Contract)
		|";
	EndIf;
	
	Return QueryText;
	
EndFunction

&AtServer
Function RequestTextDocumentsOfLeaseAgreements()
	
	QueryText = "
	|	SELECT
	|		DocumentData.Ref
	|	FROM
	|		InformationRegister.DocumentsRegistry AS DocumentData
	|	WHERE
	|		DocumentData.Contract = &Contract
	|		AND NOT DocumentData.AdditionalRecord
	|";
	
	If AccessRight("Read", Metadata.Documents.LeaseTermAdjustment) Then

		QueryText = QueryText + "UNION ALL" + "
		|SELECT DISTINCT
		|		DocumentData.Ref AS Ref
		|	FROM
		|		Document.LeaseTermAdjustment AS DocumentData
		|	WHERE
		|		DocumentData.NewContract = &Contract
		|		AND DocumentData.NewContract <> VALUE(Catalog.LeaseContract.EmptyRef)
		|";
	EndIf;
	
	If AccessRight("Read", Metadata.Documents.PaymentRequest) Then
		
		QueryText = QueryText + "UNION ALL" + "
		|SELECT DISTINCT
		|		DocumentData.Ref AS Ref
		|	FROM
		|		Document.PaymentRequest AS DocumentData
		|	WHERE
		|		DocumentData.Ref IN
		|				(SELECT
		|					TabularSectionData.Ref
		|				FROM
		|					Document.PaymentRequest.ARAPDetails AS TabularSectionData
		|				WHERE
		|					TabularSectionData.Ref = DocumentData.Ref
		|					AND TabularSectionData.LeaseContracts = &Contract)
		|		AND NOT DocumentData.Ref IN
		|			(SELECT
		|				DocumentData.Ref
		|			FROM
		|				InformationRegister.DocumentsRegistry AS DocumentData
		|			WHERE
		|				DocumentData.Contract = &Contract
		|				AND NOT DocumentData.AdditionalRecord)
		|";
	EndIf;
	
	If AccessRight("Read", Metadata.Documents.CashVoucher) Then
		
		QueryText = QueryText + "UNION ALL" + "
		|SELECT DISTINCT
		|		DocumentData.Ref AS Ref
		|	FROM
		|		Document.CashVoucher AS DocumentData
		|	WHERE
		|		DocumentData.Ref IN
		|				(SELECT
		|					TabularSectionData.Ref
		|				FROM
		|					Document.CashVoucher.ARAPDetails AS TabularSectionData
		|				WHERE
		|					TabularSectionData.Ref = DocumentData.Ref
		|					AND TabularSectionData.LeaseContracts = &Contract)
		|		AND NOT DocumentData.Ref IN
		|			(SELECT
		|				DocumentData.Ref
		|			FROM
		|				InformationRegister.DocumentsRegistry AS DocumentData
		|			WHERE
		|				DocumentData.Contract = &Contract
		|				AND NOT DocumentData.AdditionalRecord)
		|";
	EndIf;
	
	If AccessRight("Read", Metadata.Documents.BankAccountIssue) Then
		
		QueryText = QueryText + "UNION ALL" + "
		|SELECT DISTINCT
		|		DocumentData.Ref AS Ref
		|	FROM
		|		Document.BankAccountIssue AS DocumentData
		|	WHERE
		|		DocumentData.Ref IN
		|				(SELECT
		|					TabularSectionData.Ref
		|				FROM
		|					Document.BankAccountIssue.ARAPDetails AS TabularSectionData
		|				WHERE
		|					TabularSectionData.Ref = DocumentData.Ref
		|					AND TabularSectionData.LeaseContracts = &Contract)
		|		AND NOT DocumentData.Ref IN
		|			(SELECT
		|				DocumentData.Ref
		|			FROM
		|				InformationRegister.DocumentsRegistry AS DocumentData
		|			WHERE
		|				DocumentData.Contract = &Contract
		|				AND NOT DocumentData.AdditionalRecord)
		|";
	EndIf;
	
	If AccessRight("Read", Metadata.Documents.BankAccountReceiptNote) Then
		
		QueryText = QueryText + "UNION ALL" + "
		|SELECT DISTINCT
		|		DocumentData.Ref AS Ref
		|	FROM
		|		Document.BankAccountReceiptNote AS DocumentData
		|	WHERE
		|		DocumentData.Ref IN
		|				(SELECT
		|					TabularSectionData.Ref
		|				FROM
		|					Document.BankAccountReceiptNote.ARAPDetails AS TabularSectionData
		|				WHERE
		|					TabularSectionData.Ref = DocumentData.Ref
		|					AND TabularSectionData.LeaseContracts = &Contract)
		|		AND NOT DocumentData.Ref IN
		|			(SELECT
		|				DocumentData.Ref
		|			FROM
		|				InformationRegister.DocumentsRegistry AS DocumentData
		|			WHERE
		|				DocumentData.Contract = &Contract
		|				AND NOT DocumentData.AdditionalRecord)
		|";
	EndIf;
	
	If AccessRight("Read", Metadata.Documents.EntryOfCapitalAssetsBalance2_4) Then
		
		QueryText = QueryText + "UNION ALL" + "
		|SELECT DISTINCT
		|	BalanceInputs.Ref 
		|FROM
		|	(
		|		SELECT
		|			EntryOfCapitalAssetsBalance2_4FA.Ref AS Ref
		|		FROM
		|			Document.EntryOfCapitalAssetsBalance2_4.FA AS EntryOfCapitalAssetsBalance2_4FA
		|		WHERE
		|			EntryOfCapitalAssetsBalance2_4FA.Contract = &Contract
		|		
		|		UNION
		|		
		|		SELECT
		|			EntryOfCapitalAssetsBalance2_4LeasedAsset.Ref
		|		FROM
		|			Document.EntryOfCapitalAssetsBalance2_4.LeasedAsset AS EntryOfCapitalAssetsBalance2_4LeasedAsset
		|		WHERE
		|			EntryOfCapitalAssetsBalance2_4LeasedAsset.Contract = &Contract
		|		
		|		UNION
		|		
		|		SELECT
		|			EntryOfCapitalAssetsBalance2_4LeaseContractsARAP.Ref
		|		FROM
		|			Document.EntryOfCapitalAssetsBalance2_4.LeaseContractsARAP AS EntryOfCapitalAssetsBalance2_4LeaseContractsARAP
		|		WHERE
		|			EntryOfCapitalAssetsBalance2_4LeaseContractsARAP.Contract = &Contract
		|	) AS BalanceInputs
		|";
	EndIf;
	
	Return QueryText;
	
EndFunction


&AtServer
Function RequestTextDocumentsOfCounterpartiesAgreements()
	
	QueryText = "
	|	SELECT
	|		DocumentData.Ref
	|	FROM
	|		InformationRegister.DocumentsRegistry AS DocumentData
	|	WHERE
	|		DocumentData.Contract = &Contract
	|		AND NOT DocumentData.AdditionalRecord
	|";
	
	DecryptionRequestTexts = New Array;	
	If AccessRight("Read", Metadata.Documents.PaymentRequest) Then
				
		TextOfPaymentDecryptionRequest = "
		|SELECT
		|		DocumentData.Ref AS Ref
		|	FROM
		|		Document.PaymentRequest AS DocumentData
		|	WHERE
		|		DocumentData.Ref IN
		|				(SELECT
		|					TabularSectionData.Ref
		|				FROM
		|					Document.PaymentRequest.ARAPDetails AS TabularSectionData
		|				WHERE
		|					TabularSectionData.Ref = DocumentData.Ref
		|					AND TabularSectionData.ARAPObject.Object = &Contract
		|		
		|				UNION ALL
		|		
		|				SELECT
		|					TabularSectionData.Ref
		|				FROM
		|					Document.PaymentRequest.ARAPDetails AS TabularSectionData
		|				WHERE
		|					TabularSectionData.Ref = DocumentData.Ref
		|					AND TabularSectionData.ARAPObject.Contract = &Contract)
		|";
		
		DecryptionRequestTexts.Add(TextOfPaymentDecryptionRequest);
	EndIf;
	
	If AccessRight("Read", Metadata.Documents.CashVoucher) Then
		
		TextOfPaymentDecryptionRequest = "
		|SELECT
		|		DocumentData.Ref AS Ref
		|	FROM
		|		Document.CashVoucher AS DocumentData
		|	WHERE
		|		DocumentData.Ref IN
		|				(SELECT
		|					TabularSectionData.Ref
		|				FROM
		|					Document.CashVoucher.ARAPDetails AS TabularSectionData
		|				WHERE
		|					TabularSectionData.Ref = DocumentData.Ref
		|					AND TabularSectionData.ARAPObject.Object = &Contract
		|		
		|				UNION ALL
		|		
		|				SELECT
		|					TabularSectionData.Ref
		|				FROM
		|					Document.CashVoucher.ARAPDetails AS TabularSectionData
		|				WHERE
		|					TabularSectionData.Ref = DocumentData.Ref
		|					AND TabularSectionData.ARAPObject.Contract = &Contract)
		|";
		DecryptionRequestTexts.Add(TextOfPaymentDecryptionRequest);
		
	EndIf;
	
	If AccessRight("Read", Metadata.Documents.BankAccountIssue) Then
		
		TextOfPaymentDecryptionRequest = "
		|SELECT
		|		DocumentData.Ref AS Ref
		|	FROM
		|		Document.BankAccountIssue AS DocumentData
		|	WHERE
		|		DocumentData.Ref IN
		|				(SELECT
		|					TabularSectionData.Ref
		|				FROM
		|					Document.BankAccountIssue.ARAPDetails AS TabularSectionData
		|				WHERE
		|					TabularSectionData.Ref = DocumentData.Ref
		|					AND TabularSectionData.ARAPObject.Object = &Contract
		|		
		|				UNION ALL
		|		
		|				SELECT
		|					TabularSectionData.Ref
		|				FROM
		|					Document.BankAccountIssue.ARAPDetails AS TabularSectionData
		|				WHERE
		|					TabularSectionData.Ref = DocumentData.Ref
		|					AND TabularSectionData.ARAPObject.Contract = &Contract)
		|";
		DecryptionRequestTexts.Add(TextOfPaymentDecryptionRequest);
		
	EndIf;
	
	If AccessRight("Read", Metadata.Documents.CashAccountReceiptNote) Then
		
		TextOfPaymentDecryptionRequest = "
		|SELECT
		|		DocumentData.Ref AS Ref
		|	FROM
		|		Document.CashAccountReceiptNote AS DocumentData
		|	WHERE
		|		DocumentData.Ref IN
		|				(SELECT
		|					TabularSectionData.Ref
		|				FROM
		|					Document.CashAccountReceiptNote.ARAPDetails AS TabularSectionData
		|				WHERE
		|					TabularSectionData.Ref = DocumentData.Ref
		|					AND TabularSectionData.ARAPObject.Object = &Contract
		|		
		|				UNION ALL
		|		
		|				SELECT
		|					TabularSectionData.Ref
		|				FROM
		|					Document.CashAccountReceiptNote.ARAPDetails AS TabularSectionData
		|				WHERE
		|					TabularSectionData.Ref = DocumentData.Ref
		|					AND TabularSectionData.ARAPObject.Contract = &Contract)
		|";
		DecryptionRequestTexts.Add(TextOfPaymentDecryptionRequest);
		
	EndIf;
	
	If AccessRight("Read", Metadata.Documents.BankAccountReceiptNote) Then
		
		TextOfPaymentDecryptionRequest = "
		|SELECT
		|		DocumentData.Ref AS Ref
		|	FROM
		|		Document.BankAccountReceiptNote AS DocumentData
		|	WHERE
		|		DocumentData.Ref IN
		|				(SELECT
		|					TabularSectionData.Ref
		|				FROM
		|					Document.BankAccountReceiptNote.ARAPDetails AS TabularSectionData
		|				WHERE
		|					TabularSectionData.Ref = DocumentData.Ref
		|					AND TabularSectionData.ARAPObject.Object = &Contract
		|		
		|			UNION ALL
		|		
		|			SELECT
		|				TabularSectionData.Ref
		|			FROM
		|				Document.BankAccountReceiptNote.ARAPDetails AS TabularSectionData
		|			WHERE
		|				TabularSectionData.Ref = DocumentData.Ref
		|				AND TabularSectionData.ARAPObject.Contract = &Contract)
		|";
		DecryptionRequestTexts.Add(TextOfPaymentDecryptionRequest);
		
	EndIf;
	
	If AccessRight("Read", Metadata.Documents.PaymentCardTransaction) Then
		
		TextOfPaymentDecryptionRequest = "
		|SELECT
		|		DocumentData.Ref AS Ref
		|	FROM
		|		Document.PaymentCardTransaction AS DocumentData
		|	WHERE
		|		DocumentData.Ref IN
		|				(SELECT
		|					TabularSectionData.Ref
		|				FROM
		|					Document.PaymentCardTransaction.ARAPDetails AS TabularSectionData
		|				WHERE
		|					TabularSectionData.Ref = DocumentData.Ref
		|					AND TabularSectionData.ARAPObject.Object = &Contract
		|		
		|				UNION ALL
		|		
		|				SELECT
		|					TabularSectionData.Ref
		|				FROM
		|					Document.PaymentCardTransaction.ARAPDetails AS TabularSectionData
		|				WHERE
		|					TabularSectionData.Ref = DocumentData.Ref
		|					AND TabularSectionData.ARAPObject.Contract = &Contract)
		|";
		DecryptionRequestTexts.Add(TextOfPaymentDecryptionRequest);

	EndIf;
	
	If DecryptionRequestTexts.Count() Then
		
		TextOfPaymentDecryptionRequest = StrConcat(DecryptionRequestTexts, "UNION ALL"); //@Query-part
		
		// MERGE, because Links from the payment transcripts may duplicate Links from the registry.
		QueryText = QueryText + " UNION " + "
		|SELECT
		|		PaymentDecryptionData.Ref AS Ref
		|	FROM
		|	("
		+ TextOfPaymentDecryptionRequest + ") AS PaymentDecryptionData 
		|"; //@query-part-1 @query-part-2
	EndIf;
	
	Return QueryText;

EndFunction

&AtServer
Function RequestTextDocumentsOfAcquiringAgreements()
	
	QueryText = "
	|	SELECT
	|		DocumentData.Ref
	|	FROM
	|		InformationRegister.DocumentsRegistry AS DocumentData
	|	WHERE
	|		DocumentData.Contract = &Contract
	|		AND NOT DocumentData.AdditionalRecord
	|";
	
	Return QueryText;
	
EndFunction

#EndRegion
