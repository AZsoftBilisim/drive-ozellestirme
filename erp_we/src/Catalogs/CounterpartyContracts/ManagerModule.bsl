#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure
// End StandardSubsystems.ObjectsVersioning

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	Documents.IssuedLetterOfAuthority.AddGenerateCommand(GenerationCommands);
	Documents.PaymentRequest.AddGenerateCommand(GenerationCommands);
	Documents.CashVoucher.AddGenerateCommand(GenerationCommands);
	Documents.BankAccountIssue.AddGenerateCommand(GenerationCommands);
	Documents.CashAccountReceiptNote.AddGenerateCommand(GenerationCommands);
	Documents.BankAccountReceiptNote.AddGenerateCommand(GenerationCommands);
	Documents.CustomerCommercialInvoice.AddCreateBasedOnContractInvoiceCommand(GenerationCommands);
	Documents.CustomerCommercialInvoice.AddCreateBasedOnInvoiceForPaymentPrepaymentUnderContractCommand(GenerationCommands);
	
EndProcedure

// Adds an object creation command.
//
// Parameters:
//   GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
// 
// Returns:
//  Undefined, ValueTableRow - Add a create command based on
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Catalogs.CounterpartyContracts) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Catalogs.CounterpartyContracts.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Catalogs.CounterpartyContracts);
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Sets the status of contracts.
//
// Parameters:
//	Contracts - Array - An array of references to the treaties;
//	Status - EnumRef.CounterpartyContractStatuses - The status that will be set for contracts.
//
// Returns:
//	Number - the number of processed objects.
//
Function SetStatus(Contracts, Status) Export
	
	ReferencesArrray = New Array();
	ProcessedItemsCount = 0;
	
	For Each Contract In Contracts Do
		
		If TypeOf(Contract) = Type("DynamicListGroupRow") Then
			Continue;
		EndIf;
		
		ReferencesArrray.Add(Contract);
		
	EndDo;
	
	If ReferencesArrray = 0 Then
		Return ProcessedItemsCount;
	EndIf;
	
	Query = New Query(
	"SELECT
	|	CounterpartyContracts.Ref AS Ref,
	|	CounterpartyContracts.DeletionMark AS DeletionMark,
	|	CASE
	|		WHEN CounterpartyContracts.Status = &Status
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS StatusMatches
	|FROM
	|	Catalog.CounterpartyContracts AS CounterpartyContracts
	|WHERE
	|	CounterpartyContracts.Ref IN(&ReferencesArrray)");
	
	Query.SetParameter("ReferencesArrray", ReferencesArrray);
	Query.SetParameter("Status", Status);
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		If Selection.DeletionMark Then
			
			ErrorText = NStr("vi = 'Hợp đồng %Contract% đã đặt dấu xóa. Không thể thay đổi trạng thái';
							|ru = 'Договор %Contract% помечен на удаление. Невозможно изменить статус';
							|en = 'Contract %Contract% is marked for deletion. Cannot change the status'; fa = 'Contract %Contract% is marked for deletion. Cannot change the status';
							|it = 'Accordo %Contract% contrassegnato per la cancellazione. Impossibile modificare lo stato';
							|pl = 'Umowa %Contract% jest zaznaczona do usunięcia. Zmiana statusu nie jest możliwa';
							|tr = 'Sözleşme %Contract% silinmek üzere işaretlendi. Durum değiştirilemiyor'");
			ErrorText = StrReplace(ErrorText, "%Contract%", Selection.Ref);
			CommonClientServer.MessageToUser(ErrorText, Selection.Ref);
			Continue;
			
		EndIf;
		
		If Selection.StatusMatches Then
			
			ErrorText = NStr("vi = 'Hợp đồng %Contract% đã đặt trạng thái ""%Status%""';
							|ru = 'Договору %Contract% уже присвоен статус ""%Status%""';
							|en = 'Status ""%Status%"" has already been assigned to contract %Contract%'; fa = 'Status ""%Status%"" has already been assigned to contract %Contract%';
							|it = 'All''accordo %Contract% è già stato assegnato lo stato ""%Status%""';
							|pl = 'Umowie %Contract% przydzielono już status ""%Status%""';
							|tr = 'Sözleşmeye %Contract% halihazırda ""%Status%"" statüsü verilmiştir.'");
			ErrorText = StrReplace(ErrorText, "%Contract%", Selection.Ref);
			ErrorText = StrReplace(ErrorText, "%Status%", Status);
			CommonClientServer.MessageToUser(ErrorText, Selection.Ref);
			Continue;
			
		EndIf;
		
		Try
			LockDataForEdit(Selection.Ref);
		Except
			
			ErrorText = NStr("vi = 'Không thể phong tỏa %Contract%. %ErrorDescription%';
							|ru = 'Не удалось заблокировать %Contract%. %ErrorDescription%';
							|en = 'Failed to lock %Contract%. %ErrorDescription%'; fa = 'Failed to lock %Contract%. %ErrorDescription%';
							|it = 'Non è stato possibile bloccare %Contract%. %ErrorDescription%';
							|pl = 'Nie udało się zablokować %Contract%. %ErrorDescription%';
							|tr = '%Contract% Engellenemiyor. %ErrorDescription%'");
			ErrorText = StrReplace(ErrorText, "%Contract%", Selection.Ref);
			ErrorText = StrReplace(ErrorText, "%ErrorDescription%", BriefErrorDescription(ErrorInfo()));
			CommonClientServer.MessageToUser(ErrorText, Selection.Ref);
			
		EndTry;
		
		Object = Selection.Ref.GetObject();
		Object.Status = Status;
		
		If Status = Enums.CounterpartyContractStatuses.NotApproved Then
			If Object.Approved Then
				Object.Approved = False;
			EndIf;
		EndIf;
		
		If Not Object.CheckFilling() Then
			Continue;
		EndIf;
			
		Try
			
			Object.Write();
			ProcessedItemsCount = ProcessedItemsCount + 1;
			
		Except
			
			ErrorText = NStr("vi = 'Không thể ghi lại %Contract%. %ErrorDescription%';
							|ru = 'Не удалось записать %Contract%. %ErrorDescription%';
							|en = 'Failed to save %Contract%. %ErrorDescription%'; fa = 'Failed to save %Contract%. %ErrorDescription%';
							|it = 'Non è stato possibile scrivere %Contract%. %ErrorDescription%';
							|pl = 'Zapisywanie %Contract% nie powiodło się. %ErrorDescription%';
							|tr = '%Contract% Kaydedilemiyor. %ErrorDescription%'");
			ErrorText = StrReplace(ErrorText, "%Contract%", Selection.Ref);
			ErrorText = StrReplace(ErrorText, "%ErrorDescription%", BriefErrorDescription(ErrorInfo()));
			CommonClientServer.MessageToUser(ErrorText, Selection.Ref);
			
		EndTry
		
	EndDo;
	
	Return ProcessedItemsCount;
	
EndFunction

// The procedure fills in the Bank accounts of the document under the agreement.
//
// Parameters:
//	Contract - CatalogRef.CounterpartyContracts - Agreement specified in the document;
//	CompanyBankAccount - CatalogRef.CompaniesBankAccounts - Details of the document " Bank account of the organization";
//	CounterpartyBankAccount - CatalogRef.CounterpartyBankAccounts - Details of the document "counterparty's Bank account".
//
Procedure FillInBankAccountsUnderAgreement(Contract, CompanyBankAccount, CounterpartyBankAccount) Export
	
	ContractData = Common.ObjectAttributesValues(Contract, "BankAccount, CounterpartyBankAccount"); 
		
	If CompanyBankAccount <> Undefined And ValueIsFilled(ContractData.BankAccount) Then
		CompanyBankAccount = ContractData.BankAccount;
	EndIf;
	If CounterpartyBankAccount <> Undefined And ValueIsFilled(ContractData.CounterpartyBankAccount) Then
		CounterpartyBankAccount = ContractData.CounterpartyBankAccount;
	EndIf;
	
EndProcedure

// Returns accounting information for the agreement
//
// Parameters:
//	Contract - CatalogRef.CounterpartyContracts - Agreement specified in the document
//
// Returns:
//	Structure - Details of the contract with accounting information
//
Function AccountingInformationUnderAgreement(Contract) Export
	
	If ValueIsFilled(Contract) Then
		Return Common.ObjectAttributesValues(Contract,
			"ARAPCurrency, CashFlowItem, VATRate, LineOfBusiness, FinancialAccountingGroup");
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// Returns the default business operation
//
// Parameters:
//  ContractType - EnumRef.ContractTypes - The type of agreement that the business transaction is defined for.
//  PurchaseRegistrationOption - EnumRef.PurchaseRegistrationOptions - The option of making purchases
//
// Returns:
//  EnumRef.BusinessTransactions, Undefined - economic operation
Function BusinessOperation(ContractType, PurchaseRegistrationOption) Export
	Types = Enums.ContractTypes;
	Operations = Enums.BusinessTransactions;
	
	If ContractType = Types.ReceivingForCustody Then
		Return Operations.ReceivingForStorageWithRightOfSale;
	ElsIf ContractType = Types.TransferToCustody Then
		Return Operations.TransferToStorageWithRightOfSale;
	ElsIf ContractType = Types.SalesViaCommissionAgent Then
		Return Operations.SalesViaCommissionAgent;
	ElsIf ContractType = Types.TransferToTolling2_5 Then
		Return Operations.ProductionByToller2_5;
	ElsIf ContractType = Types.SubcontractingToTheEAEUCountries Then
		Return Operations.ProductionAtProcessorInEAEUCountries2_5;
	ElsIf ContractType = Types.ReceiptForTolling2_5 Then
		Return Operations.TollManufacturing2_5;
	ElsIf ContractType = Types.TransferToRental Or ContractType = Types.Sublease Then
		Return Operations.RenderRentalServices;
	EndIf;
	
	GoodsInTransit = (PurchaseRegistrationOption = Enums.PurchaseRegistrationOptions.GoodsInTransit);
	UninvoicedDeliveries = (PurchaseRegistrationOption = Enums.PurchaseRegistrationOptions.UninvoicedDeliveriesOfGoods)
					Or (PurchaseRegistrationOption = Enums.PurchaseRegistrationOptions.UninvoicedDeliveriesOfGoodsAndServices);
	
	PurchaseFromSupplierOperation = Operations.PurchaseFromSupplier;
	PurchaseFromSupplierOperation = 
		?(GoodsInTransit, Operations.PurchaseFromVendorGoodsInTransit, PurchaseFromSupplierOperation);
	PurchaseFromSupplierOperation = 
		?(UninvoicedDeliveries, Operations.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt, PurchaseFromSupplierOperation);
		
	ImportPurchaseOperation = Operations.PurchaseByImport;
	ImportPurchaseOperation = 
		?(GoodsInTransit, Operations.ImportGoodsInTransit, ImportPurchaseOperation);
		
	PurchaseOperationInEAEUCountries = Operations.ImportFromEAEU;
	PurchaseOperationInEAEUCountries = 
		?(GoodsInTransit, Operations.ImportFromEAEUGoodsInTransit, PurchaseOperationInEAEUCountries);
	PurchaseOperationInEAEUCountries = 
		?(UninvoicedDeliveries, Operations.ImportFromEAEUInvoicedDelivery, PurchaseOperationInEAEUCountries);
	
	BusinessOperation = 
		?(ContractType = Types.WithVendor,    PurchaseFromSupplierOperation,
		?(ContractType = Types.Import,          ImportPurchaseOperation,
		?(ContractType = Types.PurchaseEAEU,      PurchaseOperationInEAEUCountries,
		?(ContractType = Types.WithCustomer,    Operations.SaleToCustomer,
		?(ContractType = Types.WithConsignee,  Operations.TransferToCommissionAgent,
		?(ContractType = Types.WithConsignor,     Operations.ConsignmentProcurement,
		?(ContractType = Types.CustomerInvoiceOutsourcedSale,     Operations.DeliveryForPrincipal,
		Undefined)))))));
	
	Return BusinessOperation;
	
EndFunction

// Returns the default contract type
//
// Parameters:
// BusinessOperation - EnumRef.BusinessTransactions - A business transaction for which
//                                                                    the contract type is defined.
//
// Returns:
//  EnumRef.ContractTypes - type of contract.
//
Function ContractType(BusinessOperation) Export
	
	Types = Enums.ContractTypes;
	Operations = Enums.BusinessTransactions;
	If BusinessOperation = Operations.TransferToStorageWithRightOfSale Then
		Return Types.TransferToCustody;
	ElsIf BusinessOperation = Operations.ReceivingForStorageWithRightOfSale Then
		Return Types.ReceivingForCustody;
	ElsIf BusinessOperation = Operations.SalesViaCommissionAgent Then
		Return Types.SalesViaCommissionAgent;
	ElsIf BusinessOperation = Operations.ProductionByToller2_5 Then
		Return Types.TransferToTolling2_5;
	ElsIf BusinessOperation = Operations.ProductionAtProcessorInEAEUCountries2_5 Then
		Return Types.SubcontractingToTheEAEUCountries;
	ElsIf BusinessOperation = Operations.TollManufacturing2_5 Then
		Return Types.ReceiptForTolling2_5;
	EndIf;
	
	ProcurementOperations = PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.PurchaseFromSupplier);
	ImportOperations = PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.PurchaseByImport);
	OperationsInEAEUCountries = PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.ImportFromEAEU);
	
	Return
		?(BusinessOperation = Operations.SaleToCustomer 
			And GetFunctionalOption("UseCustomerContracts"), Types.WithCustomer,
		?(BusinessOperation = Operations.TransferToCommissionAgent, Types.WithConsignee,
		?(ProcurementOperations.Find(BusinessOperation) <> Undefined
			And GetFunctionalOption("UseContractsWithVendors"), Types.WithVendor,
		?(BusinessOperation = Operations.ConsignmentProcurement, Types.WithConsignor,
		?(ImportOperations.Find(BusinessOperation) <> Undefined, Types.Import,
		?(OperationsInEAEUCountries.Find(BusinessOperation) <> Undefined, Types.PurchaseEAEU,
		?(BusinessOperation = Operations.DeliveryForPrincipal, Types.CustomerInvoiceOutsourcedSale,
		Undefined)))))));
	
EndFunction

// Returns the names of blocked details for the BSP details blocking mechanism.
//
// Returns:
//	Array of String - names of the blocked details.
//
Function GetObjectAttributesToLock() Export
	
	Result = New Array;
	Result.Add("ContractType");
	Result.Add("Partner");
	Result.Add("Counterparty");
	Result.Add("Organization");
	Result.Add("ForeignCurrencyTransaction");
	Result.Add("ARAPCurrency");
	Result.Add("ARAPObjectSettings");
	Result.Add("LineOfBusiness");
	Result.Add("Department");
	Result.Add("FinancialAccountingGroup");
	Result.Add("PurchaseRegistrationOption; UsePaperworkForSeparatePurchasesOfGoods");
	Result.Add("RegisterReceipt");
	Result.Add("GoodsReceipt");
	Result.Add("AcceptanceOfServices");
	Result.Add("OptionForRegisteringServiceReceiptDocuments; UsePaperworkForSeparateProcurementOfServices");
	Result.Add("MonthlyReceiptOfServices");
    Result.Add("RegistrationOfReceiptOfServices");
	Result.Add("ProcedureToRecordUninvoicedDeliveriesTA");
	Result.Add("GoodsReceiptOption; RegisterReceipt, GoodsReceipt");
	Result.Add("CentralizedContract");
	Result.Add("TransferAndOffsetOfPaymentsBetweenBranchOfficesIsAllowed");
	Result.Add("ConsignmentSales25");
	Result.Add("ConductARAPAccountingThroughEndCustomers");
	Result.Add("PriceTypeAccountingPriceType");
	Result.Add("SalesPriceType");
	Result.Add("CommissionAgentPartner");
	Result.Add("CounterpartyCommissionAgent");
	Result.Add("ContractWithCommissionAgent");
	Result.Add("GroupOfFinancialARAPAccountingWithEndCustomer");
	Result.Add("DiscountRate");
	Result.Add("ApplicationDiscountingPeriod");
	Result.Add("ApplyInstallmentDiscountRate");
	Result.Add("ItIsAllowedToWorkWithSubsidiaryPartners");
	Result.Add("ContractRateOption");
	Result.Add("PaymentID");
	Result.Add("GoodsQualityIsGuaranteedByVendor");
	
	
	Return Result;
EndFunction

// Defines the details of the selected reference list item
//
// Parameters:
//	Ref - CatalogRef.CounterpartyContracts - a reference to a directory element.
//
// Returns:
//	Structure - details of the selected directory item.
//
Function ObjectAttributes(Ref) Export
	
	Query = New Query("
	|SELECT
	|	Data.Date AS Date,
	|	Data.Organization AS Organization,
	|	Data.Partner AS Partner,
	|	Data.Counterparty AS Counterparty,
	|	Data.ARAPCurrency AS ARAPCurrency,
	|	Data.BusinessOperation AS BusinessOperation,
	|	Data.Sum AS DocumentAmount,
	|	Data.Sum AS AmountARAP,
	|	&Ref AS Contract,
	|	Data.ARAPObjectSettings AS ARAPObjectSettings,
	|	NOT Data.DeletionMark AS Posted
	|FROM
	|	Catalog.CounterpartyContracts AS Data
	|WHERE
	|	Data.Ref = &Ref
	|");
	
	Query.SetParameter("Ref", Ref);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Date = Selection.Date;
		Organization = Selection.Organization;
		Partner = Selection.Partner;
		Counterparty = Selection.Counterparty;
		Contract = Selection.Contract;
		ARAPObjectSettings = Selection.ARAPObjectSettings;
		ARAPCurrency = Selection.ARAPCurrency;
		BusinessOperation = ?(ValueIsFilled(Selection.BusinessOperation), Selection.BusinessOperation, Enums.BusinessTransactions.SaleToCustomer);
		DocumentAmount = Selection.DocumentAmount;
		AmountARAP = ?(Selection.Posted, Selection.AmountARAP, 0);
	Else
		Date = Date(1,1,1);
		Organization = Catalogs.Companies.EmptyRef();
		Partner = Catalogs.Partners.EmptyRef();
		Counterparty = Catalogs.Counterparties.EmptyRef();
		Contract = Catalogs.CounterpartyContracts.EmptyRef();
		ARAPObjectSettings = Enums.ARAPObjectSettings.EmptyRef();
		ARAPCurrency = Catalogs.Currencies.EmptyRef();
		BusinessOperation = Enums.BusinessTransactions.SaleToCustomer;
		DocumentAmount = 0;
		AmountARAP = 0;
	EndIf;
	
	AttributesStructure1 = New Structure();
	AttributesStructure1.Insert("Date", Date);
	AttributesStructure1.Insert("Organization", Organization);
	AttributesStructure1.Insert("Partner", Partner);
	AttributesStructure1.Insert("Counterparty", Counterparty);
	AttributesStructure1.Insert("Contract", Contract);
	AttributesStructure1.Insert("ARAPObjectSettings", ARAPObjectSettings);
	AttributesStructure1.Insert("ARAPCurrency", ARAPCurrency);
	AttributesStructure1.Insert("BusinessOperation", BusinessOperation);
	AttributesStructure1.Insert("DocumentAmount", DocumentAmount);
	AttributesStructure1.Insert("AmountARAP", AmountARAP);
	
	Return AttributesStructure1;

EndFunction

// Returns a flag for use as an aggregating entity in items to be received.
//
// Parameters:
//  GoodsReceiptOption - EnumRef.GoodsReceiptOptions - link to the acceptance option.
//
// Returns:
//  Boolean - whether or not the contract is used during acceptance.
//
Function AgreementIsUsedDuringAcceptance(Val GoodsReceiptOption) Export
	
	If Not ValueIsFilled(GoodsReceiptOption) Then
		GoodsReceiptOption = Constants.GoodsReceiptOption.Get();
	EndIf;
	
	Result = False;
	If GoodsReceiptOption = Enums.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices
		Or GoodsReceiptOption = Enums.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices 
		Or GoodsReceiptOption = Enums.GoodsReceiptOptions.ByContractsAfterInvoices Then

		Result = True;

	EndIf;

	Return Result;

EndFunction

// Returns the structure of parameters for filling in sales VAT taxation.
//
// Parameters:
//  Object - CatalogObject.CounterpartyContracts - the contract for which you need to generate parameters.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation
//
Function ParametersForFillingInSalesVATTaxation(Object) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation();
	
	FillParameters.Organization = Object.Organization;
	FillParameters.LineOfBusiness = Object.LineOfBusiness;
	FillParameters.Department = Object.Department;
	FillParameters.Date = ?(ValueIsFilled(Object.ValidityStartDate),Object.ValidityStartDate, CurrentSessionDate());

	If Object.ContractType = Enums.ContractTypes.WithCustomer Then
		
		FillParameters.GoodsSales = True;
		FillParameters.ImplementationOfWorksServices = True;
		
	ElsIf Object.ContractType = Enums.ContractTypes.WithConsignee Then
		
		FillParameters.ConsignmentReportFromCustomer = True;
	ElsIf Object.ContractType = Enums.ContractTypes.ReceiptForTolling2_5
		Or False Then
		
		FillParameters.ReportToMaterialProvider = True;
	ElsIf Object.ContractType = Enums.ContractTypes.TransferToRental
		Or Object.ContractType = Enums.ContractTypes.Sublease Then
		
		FillParameters.ImplementationOfWorksServices = True;
	ElsIf Object.ContractType = Enums.ContractTypes.TransferToCustody Then
		
		FillParameters.RedemptionOfGoodsByCustodian = True;
		
	EndIf;
	
	Return FillParameters;
	
EndFunction

// Returns the structure of parameters for filling in the purchase VAT tax.
//
// Parameters:
//  Object - CatalogObject.CounterpartyContracts - the contract for which you need to generate parameters.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases
//
Function ParametersForFillingInVATTaxationPurchases(Object) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases();
	
	FillParameters.Counterparty = Object.Counterparty;
	FillParameters.Period = ?(ValueIsFilled(Object.ValidityStartDate),Object.ValidityStartDate, CurrentSessionDate());

	If Object.ContractType = Enums.ContractTypes.WithVendor Then
		
		FillParameters.PurchaseOfGoods = True;
		FillParameters.AcquisitionOfWorks = True;
		FillParameters.PurchaseOnArticles = True;
		
	ElsIf Object.ContractType = Enums.ContractTypes.ReceivingForCustody Then
		
		FillParameters.PurchaseOfGoods = True;
		
	ElsIf Object.ContractType = Enums.ContractTypes.TransferToTolling2_5 Then
		
		FillParameters.AcquisitionOfWorks        = True;
		FillParameters.PurchaseOnArticles     = True;
		FillParameters.ReceiptFromProcessing = True;
		
	ElsIf Object.ContractType = Enums.ContractTypes.SubcontractingToTheEAEUCountries Then
		
		FillParameters.AcquisitionOfWorks             = True;
		FillParameters.PurchaseOnArticles          = True;
		FillParameters.ReceiptFromProcessing      = True;
		FillParameters.ImportOfGoodsFromCustomsUnion = True;
	ElsIf Object.ContractType = Enums.ContractTypes.WithConsignor Then
		
		FillParameters.ConsignmentProcurement = True;
		
	ElsIf Object.ContractType = Enums.ContractTypes.PurchaseEAEU Then
		
		FillParameters.ImportOfGoodsFromCustomsUnion = True;
		
	ElsIf Object.ContractType = Enums.ContractTypes.Import Then
		
		FillParameters.ImportOfGoods = True;
		
	EndIf;
	
	Return FillParameters;
	
EndFunction

// Returns the structure of parameters for filling in the VAT activity type.
//
// Parameters:
//  Object - CatalogObject.CounterpartyContracts - 
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInVATActivityType
//
Function ParametersForFillingInVATActivityType(Object) Export

	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATActivityType();
	FillParameters.Organization = Object.Organization;
	FillParameters.LineOfBusiness = Object.LineOfBusiness;
	FillParameters.Date = ?(ValueIsFilled(Object.ValidityStartDate),Object.ValidityStartDate, CurrentSessionDate());
	
	If Object.ContractType = Enums.ContractTypes.WithVendor Then
		
		FillParameters.PurchaseOfGoods = True;
		FillParameters.AcquisitionOfWorks = True;
		
	ElsIf Object.ContractType = Enums.ContractTypes.ReceivingForCustody Then
		
		FillParameters.PurchaseOfGoods = True;
		 
	ElsIf Object.ContractType = Enums.ContractTypes.TransferToTolling2_5
		Or Object.ContractType = Enums.ContractTypes.SubcontractingToTheEAEUCountries
		Or False Then
		
		FillParameters.AcquisitionOfWorks = True;
		
	ElsIf Object.ContractType = Enums.ContractTypes.PurchaseEAEU Then
		
		FillParameters.PurchaseOfGoods = True;
		
	ElsIf Object.ContractType = Enums.ContractTypes.Import Then
		
		FillParameters.PurchaseOfGoods = True;
		
	EndIf;
	
	Return FillParameters;

EndFunction

// Returns parameters of the settlement mechanism.
//
// Parameters:
// 	FillingData - DocumentObject, CatalogObject, DocumentRef, CatalogRef, Structure, FormDataStructure - An object or collection for
//              calculating settlement parameters.
//
// Returns:
// 	Array of See ARAPAccountingServer.MechanismParameters
//
Function SettlementParameters_(FillingData = Undefined) Export
	
	If Common.RefTypeValue(FillingData) Then
		StructureFillingData = Common.ObjectAttributesValues(
			FillingData, 
			"ContractType,
			|Sum,
			|ContractWithCommissionAgent,
			|ConsignmentSales25,
			|ARAPObjectSettings");
		ContractType           = StructureFillingData.ContractType;
		Sum                 = StructureFillingData.Sum;
		ContractWithCommissionAgent = StructureFillingData.ContractWithCommissionAgent;
		ConsignmentSales25 = StructureFillingData.ConsignmentSales25;
		ARAPObjectSettings       = StructureFillingData.ARAPObjectSettings;
	ElsIf FillingData = Undefined Then
		ContractType = Undefined;
		Sum       = 0;
		ImplementationThroughEndClient = False;
		ConductARAPAccountingThroughEndCustomers = False;
		ARAPObjectSettings = Enums.ARAPObjectSettings.EmptyRef();
	Else
		ContractType = FillingData.ContractType;
		Sum       = FillingData.Sum;
		ContractWithCommissionAgent = FillingData.ContractWithCommissionAgent;
		ConsignmentSales25 = FillingData.ConsignmentSales25;
		If ContractType = Enums.ContractTypes.SalesViaCommissionAgent
			And ValueIsFilled(ContractWithCommissionAgent) Then
			ConductARAPAccountingThroughEndCustomers = Common.ObjectAttributeValue(ContractWithCommissionAgent, "ConductARAPAccountingThroughEndCustomers");
		Else
			ConductARAPAccountingThroughEndCustomers = False;
		EndIf;
		ARAPObjectSettings = FillingData.ARAPObjectSettings;
	EndIf;
	
	InfluencingAttributes = "ContractType,ContractWithCommissionAgent,ConsignmentSales25,ARAPObjectSettings";
	
	ParametersArray = New Array();
	
	#Region BasicStructure
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	
	ParametersStructure.IsCatalog                    = True;
	ParametersStructure.ItCanBeARAPObject    = ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts
	                                                       Or ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice;
	
	//Determines which register the parameters move, which common forms, enumerations and directories to use.
	If ContractType = Enums.ContractTypes.WithCustomer 
		Or ContractType = Enums.ContractTypes.WithConsignee
		Or ContractType = Enums.ContractTypes.TransferToCustody
		Or ContractType = Enums.ContractTypes.ReceiptForTolling2_5
		Or ContractType = Enums.ContractTypes.TransferToRental
		Or ContractType = Enums.ContractTypes.Sublease
		Or ContractType = Enums.ContractTypes.CustomerInvoiceOutsourcedSale
		Or ContractType = Enums.ContractTypes.SalesViaCommissionAgent Then
		ParametersStructure.PaymentType_                  = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
	Else
		ParametersStructure.PaymentType_                  = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
	EndIf;

	ParametersStructure.ChangesPaymentPlan = Sum <> 0;
	ParametersStructure.ModifiesDeliveryShipmentPlan = ParametersStructure.ChangesPaymentPlan;
	
	ParametersStructure.Date                             = "Object.Date"; 
	
	//Currency and amount of the transaction. The path to the object's details is required.
	ParametersStructure.DocumentCurrency                  = "Object.ARAPCurrency";
	ParametersStructure.DocumentAmount                   = "Object.Sum";
	
	If ContractType = Enums.ContractTypes.SalesViaCommissionAgent Then
		
		If Not ConductARAPAccountingThroughEndCustomers Then
			ParametersStructure.Partner                          = "Object.CommissionAgentPartner";
			ParametersStructure.Counterparty                       = "Object.CounterpartyCommissionAgent";
		Else
			ParametersStructure.Partner                          = "Object.Partner";
		EndIf;
		
	EndIf;
	
	ParametersStructure.Contract                          = "Object.Ref";
	ParametersStructure.ARAPObjectSettings                  = "Object.ARAPObjectSettings";
	ParametersStructure.Terms                       = "";
	
	//They are used to determine the value of payments in currency and in the form of editing payment rules.
	ParametersStructure.CompanyBankAccount        = "Object.BankAccount";
	ParametersStructure.CashAccount                            = "";
	ParametersStructure.PaymentMethod                      = "";
	
	ParametersStructure.Manager                         = "Object.Manager";
	ParametersStructure.IncomingDocumentNumber          = "Object.Number";
	ParametersStructure.IncomingDocumentDate           = "Object.Date";
	
	ParametersStructure.OperationWithSelfEmployedPerson             = "Object.ContractWithSelfEmployedPerson";
	
	If ContractType <> Enums.ContractTypes.WithConsignee 
		Or ConsignmentSales25 Then
		ParametersStructure.ARAPObject                   = "Object.ARAPObject";
	EndIf;
	
	//The name of the button that opens the Payment offset assistant for the current set of parameters.
	ParametersStructure.FormItems.PaymentSettlement            = ?(ContractType = Enums.ContractTypes.SalesViaCommissionAgent,
		"",
		"CreditPaymentForm");
	ParametersStructure.FormItems.LineOfBusiness = "LineOfBusiness";
	
	#Region MutualSettlementsStatus
	
	//The name of the hyperlink that displays the status of calculations and opens the corresponding report,
	ParametersStructure.FormItems.InscriptionCalculations                   = "DecorationSettlementState";
	
	#EndRegion
	
	#Region LimitsOnDebtUnderAgreement
	
	//Hyperlink displaying the status of the debt limit
	ParametersStructure.FormItems.DebtLimitationText    = "DecorationDebtLimitation";
	//A picture showing the shipment ban
	ParametersStructure.FormItems.DebtLimitation = "ImageShipmentProhibited"; 
	
	#EndRegion
	
	ParametersStructure.InfluencingAttributes = InfluencingAttributes;
	
	ParametersArray.Add(ParametersStructure);
	
	#EndRegion
	
	#Region AdditionalStructure
	
	If ContractType = Enums.ContractTypes.WithConsignee
		Or ContractType = Enums.ContractTypes.TransferToTolling2_5
		Or ContractType = Enums.ContractTypes.SubcontractingToTheEAEUCountries
		Or ContractType = Enums.ContractTypes.ReceiptForTolling2_5
		Or ContractType = Enums.ContractTypes.WithConsignor Then
		
		ParametersStructure = ARAPAccountingServer.MechanismParameters();
		
		ParametersStructure.IsCatalog                     = True;
		ParametersStructure.ItCanBeARAPObject    = ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts
		                                                       Or ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice;
		
		//Determines which register the parameters move, which common forms, enumerations and directories to use.
		If ContractType = Enums.ContractTypes.WithConsignee Then
			ParametersStructure.PaymentType_                  = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
		ElsIf ContractType = Enums.ContractTypes.WithConsignor Then
			ParametersStructure.PaymentType_                  = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
		ElsIf ContractType = Enums.ContractTypes.TransferToTolling2_5
				Or ContractType = Enums.ContractTypes.SubcontractingToTheEAEUCountries Then
			ParametersStructure.PaymentType_                  = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
		ElsIf ContractType = Enums.ContractTypes.ReceiptForTolling2_5 Then
			ParametersStructure.PaymentType_                  = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
		EndIf;
	
		ParametersStructure.ChangesPaymentPlan               = False;
		ParametersStructure.ModifiesDeliveryShipmentPlan     = False;
		
		ParametersStructure.Date                             = "Object.Date"; 
		
		//Currency and amount of the transaction. The path to the object's details is required.
		ParametersStructure.DocumentCurrency                  = "Object.ARAPCurrency";
		ParametersStructure.DocumentAmount                   = "Object.Sum";
		ParametersStructure.Partner                          = "Object.Partner";
		ParametersStructure.Contract                          = "Object.Ref";
		ParametersStructure.ARAPObjectSettings                  = "Object.ARAPObjectSettings";
		ParametersStructure.Terms                       = "";
		
		//They are used to determine the value of payments in currency and in the form of editing payment rules.
		ParametersStructure.CompanyBankAccount        = "Object.BankAccount";
		ParametersStructure.CashAccount                            = "";
		ParametersStructure.PaymentMethod                      = "";
		
		ParametersStructure.Manager                         = "Object.Manager";
		ParametersStructure.IncomingDocumentNumber          = "Object.Number";
		ParametersStructure.IncomingDocumentDate           = "Object.Date";
		
		ParametersStructure.InfluencingAttributes = InfluencingAttributes;
		
		ParametersArray.Add(ParametersStructure);
	
	EndIf;
	
	#EndRegion
	
	Return ParametersArray;
	
EndFunction

// The function returns the text of the request to receive goods for delivery by order
//
// Returns:
//  String - Query text
//
Function QueryTextGoodsToDeliver() Export
	
	QueryText =
	"SELECT
	|	GoodsToReceiveBalance.DocumentInflow AS Ref,
	|	GoodsToReceiveBalance.Products AS Products,
	|	GoodsToReceiveBalance.Characteristic AS Characteristic,
	|	GoodsToReceiveBalance.Purpose AS Purpose,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	GoodsToReceiveBalance.Warehouse AS Warehouse,
	|	GoodsToReceiveBalance.GoodsReceiptNotesToRegisterBalance AS Count
	|FROM
	|	AccumulationRegister.GoodsToReceive.Balance(, DocumentInflow IN (&References)) AS GoodsToReceiveBalance";
	
	Return QueryText;
	
EndFunction

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - Structure - description of the details to get values for using statistics
//
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "ContractType,Manager";
	Parameters.FillInIf.ObjectFieldsFilledIn = "ContractType";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"ARAPObjectSettings", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Organization, ForeignCurrencyTransaction";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Organization";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"BankAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Counterparty, ForeignCurrencyTransaction";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Counterparty";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"CounterpartyBankAccount", Parameters);
	
EndProcedure

// Fill in the document details with the values of the contract details.
// 
// Parameters:
//  Object - DocumentObject
//  Contract - CatalogRef.CounterpartyContracts
//  AttributesList - Structure - the
//                       name of the object's props is passed as the key, and as
//                       the value (optional) the name of the contract details.
Procedure FillInDocumentDetails(Object, Contract, AttributesList) Export
	
	If ValueIsFilled(Contract) Then
		
		ContractDetails_ = Common.ObjectAttributesValues(Contract, AttributesList);
		
		For Each CurrentAttribute In AttributesList Do
			If ValueIsFilled(ContractDetails_[CurrentAttribute.Key]) Then
				Object[CurrentAttribute.Key] = ContractDetails_[CurrentAttribute.Key];
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure

// Returns data for generating an electronic contract document
// 
// Parameters:
//  ObjectReference - CatalogRef.CounterpartyContracts
// 
// Returns:
//  QueryResultSelection - data on The Contract With The counterparty.
//
Function GetDataForED(ObjectReference) Export

	Query = New Query;
	Query.Text = "SELECT
	|	CounterpartyContracts.Number,
	|	CounterpartyContracts.Date,
	|	CounterpartyContracts.Sum,
	|	CounterpartyContracts.VATRate,
	|	CounterpartyContracts.ARAPCurrency.Description AS Currency_Name,
	|	CounterpartyContracts.ARAPCurrency.Code AS Currency_Code,
	|	CounterpartyContracts.ValidityStartDate,
	|	CounterpartyContracts.ValidityEndDate,
	|	CounterpartyContracts.ContractType,
	|	CounterpartyContracts.ARAPObjectSettings,  
	|	CounterpartyContracts.PaymentDueDate,
	|	CounterpartyContracts.Organization AS Organization,
	|	CounterpartyContracts.Organization.LegalEntityIndividual AS Company_LegalEntityIndividual,
	|	CounterpartyContracts.BankAccount,
	|	CounterpartyContracts.BankAccount.Bank.Code AS Company_BankAccount_bic,
	|	CounterpartyContracts.BankAccount.Bank.Description AS
	|		Company_BankAccount_BankName,
	|	CounterpartyContracts.BankAccount.AccountNumber AS Company_BankAccount_AccountNumber,
	|	CounterpartyContracts.BankAccount.Bank.CorrAccount AS Company_BankAccount_CorrespondentAccount,
	|	CounterpartyContracts.BankAccount.Bank.TIN AS Company_BankAccount_inn,
	|	CounterpartyContracts.Counterparty AS Counterparty,
	|	CounterpartyContracts.Counterparty.LegalEntityIndividual AS Counterparty_LegalEntityIndividual, 
	|	CounterpartyContracts.CounterpartyBankAccount,	
	|	CounterpartyContracts.Counterparty.RegistrationNumber AS Counterparty_IdOfLegalEntity,
	|	CounterpartyContracts.CounterpartyBankAccount.Bank.Code AS Counterparty_BankAccount_bic,
	|	CounterpartyContracts.CounterpartyBankAccount.Bank.Description AS
	|		Counterparty_BankAccount_BankName,
	|	CounterpartyContracts.CounterpartyBankAccount.AccountNumber AS Counterparty_BankAccount_AccountNumber,
	|	CounterpartyContracts.CounterpartyBankAccount.Bank.CorrAccount AS Counterparty_BankAccount_CorrespondentAccount,
	|	CounterpartyContracts.CounterpartyBankAccount.Bank.TIN AS Counterparty_BankAccount_in
	|FROM
	|	Catalog.CounterpartyContracts AS CounterpartyContracts
	|WHERE
	|	CounterpartyContracts.Ref = &Ref";

	Query.SetParameter("Ref", ObjectReference);
	Return Query.Execute().Select();

EndFunction

// Returns an indication that the specified Contract type is used for settlements with the client.
//
// Parameters:
//  ContractType - EnumRef.ContractTypes - the Contract type to be checked.
//
// Returns:
//  Boolean - True if it is a Contract with the client.
//
Function ThisIsContractWithClient(ContractType) Export
	
	ThisIsContractWithClient = False;
	
	If ContractType = Enums.ContractTypes.SalesViaCommissionAgent
		Or ARAPAccountingClientServer.TypesOfContractsWithClient().FindByValue(ContractType) <> Undefined Then
		ThisIsContractWithClient = True;
	EndIf;
	
	Return ThisIsContractWithClient;
	
EndFunction

// Checks the partner flags "Client" and "Supplier" depending on the business of operation and the type of Contract.
//
// Parameters:
//  Partner - CatalogRef.Partners - The partner for which the flags are checked
//  BusinessOperation - EnumRef.BusinessTransactions - Type of business of operation
//  ThisIsNewContract - Boolean - Indicates a new Contract
//  DisplayMessagesToUser - Boolean - Flag for displaying messages to the user
//  PartnerFlags - Structure - Partner flags "Client" and "Supplier" (Undefined by default)
//  MessageText - String - Message text for the user (default is "")
//
// Returns:
//  Boolean - Verification result (True if the verification was passed successfully)
Function CheckPartnerFlagsClientVendor(Partner,
											BusinessOperation,
											ThisIsNewContract,
											DisplayMessagesToUser,
											PartnerFlags = Undefined,
											MessageText = "") Export
	
	Cancel = False;
	
	If ValueIsFilled(Partner) Then
		
		ProcurementOperations = PurchasesServer.BusinessOperationsOnMain(
			Enums.BusinessTransactions.PurchaseFromSupplier);
		ImportOperations = PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.PurchaseByImport);
		OperationsInEAEUCountries = PurchasesServer.BusinessOperationsOnMain(
			Enums.BusinessTransactions.ImportFromEAEU);
		ProductionOperationsAtProcessor2_5 = PurchasesServer.BusinessOperationsOnMain(
			Enums.BusinessTransactions.ProductionByToller2_5);
			
		If PartnerFlags = Undefined Then
			PartnerFlags = Common.ObjectAttributesValues(Partner, "Client, Vendor");
		EndIf;
		
		If Not PartnerFlags.Client = True And Not PartnerFlags.Vendor = True Then
			Cancel = True;
			
			If ThisIsNewContract Then
				MessageText = NStr("vi = 'Có thể tạo hợp đồng với bạn hàng có dấu hiệu ""Khách hàng/Nhà cung cấp""';
									|ru = 'Создание договора возможно для партнеров с признаками ""Клиент/Поставщик""';
									|en = 'Contract may be created for partners with the ""Customer/Vendor"" flags'; fa = 'Contract may be created for partners with the ""Customer/Vendor"" flags';
									|it = 'La creazione dell''accordo è possibile per i partner con segno ""Cliente/fornitore""';
									|pl = 'Utworzenie umowy jest możliwe dla partnerów z oznakami ""Klient/Dostawca""';
									|tr = '""Müşteri/Tedarikçi"" niteliğine sahip iş ortakları için bir anlaşma oluşturmak mümkündür.'");
			Else
				MessageText = NStr("vi = 'Đối với bạn hàng được chọn, cần thiết lập dấu hiệu ""Khách hàng/Nhà cung cấp""';
									|ru = 'Для выбранного партнера должен быть установлен признак ""Клиент/Поставщик""';
									|en = 'The selected partner must have the ""Customer/Vendor"" checkbox selected'; fa = 'The selected partner must have the ""Customer/Vendor"" checkbox selected';
									|it = 'Для выбранного партнера должен быть установлен признак ""Клиент/Поставщик""';
									|pl = 'The selected partner must have the ""Customer/Vendor"" checkbox selected';
									|tr = 'Seçilen iş ortağı için ""Müşteri/Tedarikçi"" bayrağı yapılandırılmalıdır'");
			EndIf;
			
		ElsIf Not PartnerFlags.Client = True 
			And (BusinessOperation = Enums.BusinessTransactions.SaleToCustomer
			Or BusinessOperation = Enums.BusinessTransactions.TollManufacturing2_5
			Or BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
			Or BusinessOperation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale
			Or BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal
			Or BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgent) Then
			Cancel = True;
			
			If ThisIsNewContract Then
				MessageText = NStr("vi = 'Có thể tạo hợp đồng với khách hàng đối với bạn hàng có dấu hiệu ""Khách hàng""';
									|ru = 'Создание договора с клиентом возможно для партнеров с признаком ""Клиент""';
									|en = 'You can create a customer contract with partners that have the ""Customer"" flag'; fa = 'You can create a customer contract with partners that have the ""Customer"" flag';
									|it = 'È possibile creare un accordo con il cliente per i partner con contrassegno ""Cliente""';
									|pl = 'Tworzenie umowy z nabywcą jest możliwe dla partnerów z oznaką ""Nabywca""';
									|tr = '""Müşteri"" niteliğine sahip iş ortakları için bir müşteri sözleşmesi oluşturmak mümkündür'");
			Else
				MessageText = NStr("vi = 'Đối với bạn hàng được chọn, cần thiết lập dấu hiệu ""Khách hàng""';
									|ru = 'Для выбранного партнера должен быть установлен признак ""Клиент""';
									|en = 'The selected partner must have the ""Customer"" checkbox selected'; fa = 'The selected partner must have the ""Customer"" checkbox selected';
									|it = 'Для выбранного партнера должен быть установлен признак ""Клиент""';
									|pl = 'The selected partner must have the ""Customer"" checkbox selected';
									|tr = 'Seçilen iş ortağı için ""Müşteri"" bayrağı yapılandırılmalıdır'");
			EndIf;
			
		ElsIf Not PartnerFlags.Vendor = True
			And Not (ProcurementOperations.Find(BusinessOperation) = Undefined
			Or Not ImportOperations.Find(BusinessOperation) = Undefined
			Or Not OperationsInEAEUCountries.Find(BusinessOperation) = Undefined
			Or Not ProductionOperationsAtProcessor2_5.Find(BusinessOperation) = Undefined
			Or BusinessOperation = Enums.BusinessTransactions.TollManufacturing2_5
			Or BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement
			Or BusinessOperation = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale) Then
			Cancel = True;
			
			If ThisIsNewContract Then
				MessageText = NStr("vi = 'Có thể tạo hợp đồng với nhà cung cấp đối với bạn hàng có dấu hiệu ""Nhà cung cấp""';
									|ru = 'Создание договора с поставщиком возможно для партнеров с признаком ""Поставщик""';
									|en = 'You can create a contract with vendor only with partners that have the ""Vendor"" flag'; fa = 'You can create a contract with vendor only with partners that have the ""Vendor"" flag';
									|it = 'È possibile creare un accordo con il fornitore per i partner con contrassegno ""Fornitore""';
									|pl = 'Tworzenie umowy z dostawcą jest możliwe dla partnerów z oznaką ""Dostawca""';
									|tr = '""Tedarikçi"" niteliğine sahip iş ortakları için bir tedarikçi sözleşmesi oluşturmak mümkündür'");
			Else
				MessageText = NStr("vi = 'Đối với bạn hàng được chọn, cần thiết lập dấu hiệu ""Nhà cung cấp""';
									|ru = 'Для выбранного партнера должен быть установлен признак ""Поставщик""';
									|en = 'The selected partner must have the ""Vendor"" checkbox selected'; fa = 'The selected partner must have the ""Vendor"" checkbox selected';
									|it = 'Для выбранного партнера должен быть установлен признак ""Поставщик""';
									|pl = 'The selected partner must have the ""Vendor"" checkbox selected';
									|tr = 'Seçilen iş ortağı için ""Tedarikçi"" bayrağı yapılandırılmalıdır'");
			EndIf;
		EndIf;
		
	EndIf;
	
	If Cancel And DisplayMessagesToUser Then
		Common.MessageToUser(MessageText);
	EndIf;
	
	Return Not Cancel;

EndFunction

// Document parameters for the mechanism of filling in the Attributes of the controlled party in the document.
// 
// Parameters:
//  ObjectOrRef - CatalogObject.CounterpartyContracts, CatalogRef.CounterpartyContracts - Contract.
//  FieldNameControlledLotReference - String - field name, controlled Lot reference.
// 
// Returns:
//  See QualityControl.NewAttributesOfControlledLotReference
Function AttributesOfControlledLotReference(ObjectOrRef, FieldNameControlledLotReference) Export
	
	Attributes = QualityControl.NewAttributesOfControlledLotReference();
	ObjectAttributes = QualityControl.AttributesOfItemOrLink(ObjectOrRef,
		"Ref,
		|Partner,
		|Number,
		|BusinessOperation,
		|LineOfBusiness,
		|Counterparty,
		|Organization,
		|Department");
		
	Attributes.Lot = ObjectAttributes.Ref;
	Attributes.Contract = ObjectAttributes.Ref;
	Attributes.Partner = ObjectAttributes.Partner;
	Attributes.DateOfReceipt = '00010101';
	Attributes.ReasonForGoodsLock = Catalogs.GoodsLockReasons.InputQualityControlOfGoods;
	Attributes.ReceiptDocumentNumber = ObjectAttributes.Number;
	Attributes.DateOfReceiptDocument = '00010101';
	Attributes.LineOfBusiness = ObjectAttributes.LineOfBusiness;
	Attributes.Counterparty = ObjectAttributes.Counterparty;
	Attributes.Organization = ObjectAttributes.Organization;
	Attributes.Department = ObjectAttributes.Department;
	
	// The Attributes for Registering Records according to the Accumulation register "Goods for receipt", when the Lot reference is known, for example, for return
	// without registration in the document "Quality control Act". The logic of filling in the fields is synchronized with the Registered Records of the current
	// document, as an order in "Goods for receipt".
	Attributes.BusinessOperation = ObjectAttributes.BusinessOperation;
	Attributes.Sender = ObjectAttributes.Partner;
	
	Return Attributes;
	
EndFunction

// Returns an array of regular payments.
//
// Parameters:
//  StartDate - Date
//  EndDate - Date
//  Periodicity - EnumRef.Periodicity
//  Day - Number
//
// Returns:
//  Array of Date
//
Function DatesOfRegularPayments(Val StartDate, Val EndDate, Val Periodicity, Val Day) Export
	
	TimeIntervals = New ValueTable;
	TimeIntervals.Columns.Add("BeginOfPeriod", New TypeDescription("Date"));
	TimeIntervals.Columns.Add("EndOfPeriod", New TypeDescription("Date"));
	TimeIntervals.Columns.Add("PaymentDate", New TypeDescription("Date"));
	
	BeginningDateOfPeriod = PlanningClientServerCached.CalculateStartDateOfPeriod(StartDate, Periodicity);
	EndingDateOfPeriod = PlanningClientServerCached.CalculatePeriodEndDate(BeginningDateOfPeriod, 
		Periodicity);
	
	While BeginningDateOfPeriod < EndDate Do
		
		Page1 = TimeIntervals.Add();
		Page1.BeginOfPeriod = BeginningDateOfPeriod;
		Page1.EndOfPeriod = EndingDateOfPeriod;
		Page1.PaymentDate = Page1.BeginOfPeriod + (Day - 1) * 86400;
		
		If Page1.PaymentDate > Page1.EndOfPeriod Then
			Page1.PaymentDate = Page1.EndOfPeriod;
		EndIf;
		
		If Page1.PaymentDate < StartDate Then
			TimeIntervals.Delete(Page1);
		EndIf;
		
		BeginningDateOfPeriod = PlanningClientServerCached.CalculateStartDateOfPeriod(EndingDateOfPeriod+1,
			Periodicity);
		EndingDateOfPeriod = PlanningClientServerCached.CalculatePeriodEndDate(BeginningDateOfPeriod, 
			Periodicity);
	EndDo;
	
	Return TimeIntervals.UnloadColumn("PaymentDate");
	
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// See AccessManagementOverridable.OnFillListsWithAccessRestriction.
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AttachAdditionalTables
	|ThisList AS T
	|LEFT JOIN InformationRegister.PartnerHierarchy AS T2 
	|	ON T2.Parent = T.Partner
	|
	|LEFT JOIN Catalog.CounterpartyContracts.BranchOffices_ AS BranchOffices_
	|	ON BranchOffices_.Ref = T.Ref
	|;
	|AllowReadUpdate
	|WHERE
	|	ValueAllowed(T2.Partner)
	|	AND (ValueAllowed(T.Organization)
	|		OR ValueAllowed(BranchOffices_.Organization))
	|	AND ValueAllowed(T.BusinessOperation)
	|	AND ValueAllowed(T.Department)";
	
	Restriction.TextForExternalUsers1 =
	"AttachAdditionalTables
	|ThisList AS ThisList
	|
	|LEFT JOIN Catalog.ExternalUsers AS ExternalUsersPartners
	|	ON ExternalUsersPartners.AuthorizationObject = ThisList.Partner
	|
	|LEFT JOIN Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
	|	ON ContactPersonsForPartners.Owner = ThisList.Partner
	|
	|LEFT JOIN Catalog.ExternalUsers AS ExternalUsersContactPersons
	|	ON ExternalUsersContactPersons.AuthorizationObject = ContactPersonsForPartners.Ref
	|
	|LEFT JOIN InformationRegister.PartnerHierarchy AS PartnerHierarchy
	|	ON PartnerHierarchy.Parent = ThisList.Partner
	|;
	|AllowReadUpdate
	|WHERE
	|	ValueAllowed(ExternalUsersPartners.Ref)
	|	OR ValueAllowed(ExternalUsersContactPersons.Ref)
	|	OR ValueAllowed(PartnerHierarchy.Partner)";

EndProcedure

// End StandardSubsystems.AccessManagement

// When determining the available types of user alerts.
// 
// Parameters:
//  DescriptionOfNotificationKinds - See UserNotificationsOfEvents.DescriptionOfUserNotificationKinds
Procedure OnDeterminingAvailableUserNotificationKinds(DescriptionOfNotificationKinds) Export
	NotificationTypeGroupContracts = UserNotificationsOfEvents.NotificationTypeGroup("CounterpartyContracts");
	
	NewTypeOfAlerts = UserNotificationsOfEvents.AddDescriptionOfTypeOfUserAlerts(DescriptionOfNotificationKinds);
	NewTypeOfAlerts.NotificationTypeGroup = NotificationTypeGroupContracts;
	NewTypeOfAlerts.Id = "fc0af7b5-12da-43d8-a416-8c713dd5d4aa";
	NewTypeOfAlerts.Description = NStr("vi = 'Sắp đến ngày kết thúc hiệu lực hợp đồng';
										|ru = 'Приближение даты окончания действия договора';
										|en = 'Approach of contract expiration date'; fa = 'Approach of contract expiration date';
										|it = 'Approach of contract expiration date';
										|pl = 'Approach of contract expiration date';
										|tr = 'Sözleşmenin sona erme tarihi yaklaşıyor'", Common.DefaultLanguageCode());
	NewTypeOfAlerts.NotificationType = Enums.UserNotificationTypes.NonOperational;
	NewTypeOfAlerts.DCSTemplateName = Metadata.Catalogs.CounterpartyContracts.Templates.Notifications_ExpirationDateIsApproaching.FullName();
	NewTypeOfAlerts.NotificationTextTemplate = "vi = 'Kết thúc thời hạn hiệu lực của hợp đồng [ValidityEndDate].';
												|ru = 'Заканчивается срок действия договора [ValidityEndDate].';
												|en = 'The contract is expiring on [ValidityEndDate].';
												|it = 'The contract is expiring on [ValidityEndDate].';
												|pl = 'The contract is expiring on [ValidityEndDate].';
												|tr = 'Sözleşmenin geçerlilik süresi sona eriyor [ValidityEndDate].'"; // @NStr-1
	NewTypeOfAlerts.GroupedNotificationText = "vi = 'Kết thúc thời hạn hiệu lực của hợp đồng.';
												|ru = 'Заканчивается срок действия договора.';
												|en = 'The contract is expiring.';
												|it = 'The contract is expiring.';
												|pl = 'The contract is expiring.';
												|tr = 'Sözleşmenin geçerlilik süresi sona eriyor.'"; // @NStr-1
	
	NewTypeOfAlerts = UserNotificationsOfEvents.AddDescriptionOfTypeOfUserAlerts(DescriptionOfNotificationKinds);
	NewTypeOfAlerts.NotificationTypeGroup = NotificationTypeGroupContracts;
	NewTypeOfAlerts.Id = "88ea3524-fcef-48e5-907f-b339b1886347";
	NewTypeOfAlerts.Description = NStr("vi = 'Kết thúc thời hạn hiệu lực của hợp đồng';
										|ru = 'Окончание срока действия договора';
										|en = 'Contract expiration'; fa = 'Contract expiration';
										|it = 'Contract expiration';
										|pl = 'Contract expiration';
										|tr = 'Sözleşmenin geçerlilik süresinin sona ermesi'", Common.DefaultLanguageCode());
	NewTypeOfAlerts.NotificationType = Enums.UserNotificationTypes.NonOperational;
	NewTypeOfAlerts.DCSTemplateName = Metadata.Catalogs.CounterpartyContracts.Templates.Notifications_ExpirationDateIsOver.FullName();
	NewTypeOfAlerts.NotificationTextTemplate = "vi = 'Đã kết thúc thời hạn hiệu lực của hợp đồng [ValidityEndDate].';
												|ru = 'Закончился срок действия договора [ValidityEndDate].';
												|en = 'The contract is expired on [ValidityEndDate].';
												|it = 'The contract is expired on [ValidityEndDate].';
												|pl = 'The contract is expired on [ValidityEndDate].';
												|tr = 'Sözleşmenin geçerlilik süresi sona erdi [ValidityEndDate].'"; // @NStr-1
	NewTypeOfAlerts.GroupedNotificationText = "vi = 'Đã kết thúc thời hạn hiệu lực của hợp đồng.';
												|ru = 'Закончился срок действия договора.';
												|en = 'The contract is expired.';
												|it = 'The contract is expired.';
												|pl = 'The contract is expired.';
												|tr = 'Sözleşmenin geçerlilik süresi sona erdi.'"; // @NStr-1
EndProcedure

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

#EndRegion

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	Query = New Query;
	
	TextOfConnections = "";
	ConditionsText    = "";
	SelectionNumber_     = 0;
	
	If Parameters.Property("Partner") Then
		
		Query.SetParameter("Partner", Parameters.Partner);
		
		TextOfConnections = TextOfConnections + "
		|	INNER JOIN InformationRegister.PartnerHierarchy AS PartnerHierarchy
		|	ON Contracts.Partner = PartnerHierarchy.Parent
		|		AND PartnerHierarchy.Partner = &Partner
		|		AND (Contracts.ItIsAllowedToWorkWithSubsidiaryPartners
		|			OR PartnerHierarchy.Parent = &Partner)";
		
		StandardProcessing = False;
		
	EndIf;
	
	SelectionsAreUsed = Parameters.Property("Filter");
	If SelectionsAreUsed Then
		// Copy the value from the parameters for the possibility of modification:
		Filter = Common.CopyRecursive(Parameters.Filter);
	Else
		Filter = New Structure;
	EndIf;
	
	CheckAgreement = True;
	If SelectionsAreUsed Then
		If Filter.Property("BusinessOperation")
			And Filter.BusinessOperation = Enums.BusinessTransactions.ProductionByToller2_5 Then
			CheckAgreement = False;
		EndIf;
	EndIf;
	If SelectionsAreUsed
		And Filter.Property("SupplyAssignment") Then
		
		// We use the line of business from the destination to select Contracts with the procedure for calculating "Sub-agreements of contractors":
		SupplyAssignment = Filter.SupplyAssignment;
		Filter.Delete("SupplyAssignment"); // We don't use it directly in query selection.
		
		If Not Filter.Property("LineOfBusiness")
			And ValueIsFilled(SupplyAssignment) Then
				
			LinesOfBusiness = Catalogs.Assignments.AreasOfActivityOfAppointments(
				CommonClientServer.ValueInArray(SupplyAssignment));
			LineOfBusiness = LinesOfBusiness.Get(SupplyAssignment);
			
			StandardProcessing = False;
			Query.SetParameter("DestinationLineOfBusiness", LineOfBusiness);
			ConditionsText = ConditionsText + "
			|	AND (Contracts.LineOfBusiness IN (&DestinationLineOfBusiness, 
			|											VALUE(Catalog.LinesOfBusiness.EmptyRef))
			|		OR Contracts.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts))"; // query-part
				
		EndIf;
			
	EndIf;
	
	If CheckAgreement And Parameters.Property("Terms") Then
		
		If ValueIsFilled(Parameters.Terms)
			And TypeOf(Parameters.Terms) = Type("CatalogRef.TermsOfPurchaseFromVendors")
			And (Not SelectionsAreUsed
				Or Not Filter.Property("BusinessOperation")) Then
				
				// There is no selection of operation, but the agreement is specified.
				// We take as a selection an economic of operation from the agreement for data consistency:
				Filter.Insert(
					"BusinessOperation",
					Catalogs.TermsOfPurchaseFromVendors.BusinessTransactionFromAgreement(Parameters.Terms));
				
		EndIf;
		
		CounterpartyContactsAreUsedAccordingToAgreement = False;
		If ValueIsFilled(Parameters.Terms) Then
			SetPrivilegedMode(True);
			CounterpartyContactsAreUsedAccordingToAgreement = GeneralPurposeTMServerCall.ObjectAttributesValues(Parameters.Terms, "ContractsAreUsed");
			SetPrivilegedMode(False);
		EndIf;
		
		If CounterpartyContactsAreUsedAccordingToAgreement = False Then
			Query.SetParameter("Terms", Parameters.Terms);
			
			If GetFunctionalOption("ToUseTermsOfSales")
				And Type("CatalogRef.TermsOfSale") = TypeOf(Parameters.Terms) Then
				
				TextOfConnections = TextOfConnections + "
				|	INNER JOIN Catalog.TermsOfSale AS TermsOfSale
				|	ON Contracts.ForeignCurrencyTransaction = TermsOfSale.ForeignCurrencyTransaction
				|		AND TermsOfSale.Ref = &Terms";
				
				StandardProcessing = False;
				
			ElsIf GetFunctionalOption("UseTermsOfPurchases")
				And Type("CatalogRef.TermsOfPurchaseFromVendors") = TypeOf(Parameters.Terms)
				And ValueIsFilled(Parameters.Terms) Then
			
				TextOfConnections = TextOfConnections + "
				|	INNER JOIN Catalog.TermsOfPurchaseFromVendors AS TermsOfPurchaseFromVendors
				|	ON Contracts.ForeignCurrencyTransaction = TermsOfPurchaseFromVendors.ForeignCurrencyTransaction
				|		AND TermsOfPurchaseFromVendors.Ref = &Terms";
				
				StandardProcessing = False;
				
			EndIf;
		EndIf;
		
	EndIf;
	
	If Parameters.Property("VATTaxation") Then
		
		Query.SetParameter("CompanyActsAsAVATTaxAgent", 
			Parameters.VATTaxation = Enums.VATTaxationTypes.VATTaxAgent);
		
		ConditionsText = ConditionsText + "
		|	AND Contracts.CompanyActsAsAVATTaxAgent = &CompanyActsAsAVATTaxAgent";
		
		StandardProcessing = False;
		
	EndIf;
	
	If SelectionsAreUsed Then
		
		For Each CurrentFilter In Filter Do
			
			If CurrentFilter.Key = "Organization" Then
				
				ConditionsText = ConditionsText + "
				|	AND (Contracts.Organization IN (&Organization)
				|		OR Contracts.BranchOffices_.Organization IN (&Organization))";
				
				Query.SetParameter("Organization", CurrentFilter.Value);
				
				StandardProcessing = False;
				
				Continue;
				
			ElsIf CurrentFilter.Key = "Counterparty"
				And GetFunctionalOption("UsePartnersAsCounterparties") Then
				
				If Not Query.Parameters.Property("Partner") Then
					
					Query.SetParameter("Counterparty", CurrentFilter.Value);
					
					TextOfConnections = TextOfConnections + "
					|	INNER JOIN Catalog.Counterparties AS Counterparties
					|	ON Contracts.Partner = Counterparties.Partner
					|		AND Counterparties.Ref = &Counterparty";
					
					StandardProcessing = False;
					
				EndIf;
				
				Continue;
				
			ElsIf CurrentFilter.Key = "BusinessOperation" Then
				
				If CurrentFilter.Value = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle Then
					
					ConditionsText = ConditionsText + "
					|	AND Contracts.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomer)";
					
					StandardProcessing = False;
					
					Continue;
					
				ElsIf CurrentFilter.Value = Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt  
						Or CurrentFilter.Value = Enums.BusinessTransactions.ImportFromEAEU Then
						
					If CurrentFilter.Value = Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt Then 
						BusinessTransactions = PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.PurchaseFromSupplier);
					ElsIf CurrentFilter.Value = Enums.BusinessTransactions.ImportFromEAEU Then 
						BusinessTransactions = PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.ImportFromEAEU);
					EndIf;
					
					ConditionsText = ConditionsText + "
					|	AND Contracts.BusinessOperation IN (&BusinessTransactions)";
					
					Query.SetParameter("BusinessTransactions", BusinessTransactions);
					
					ListOfOptionsForServices = New ValueList;
                    ListOfOptionsForServices.Add(Enums.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsReversed);
					ListOfOptionsForServices.Add(Enums.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsInvoiced);
					
					ConditionsText = ConditionsText + "
					|	AND (Contracts.OptionForRegisteringServiceReceiptDocuments IN (&ListOfOptionsForServices)
					|		OR Contracts.PurchaseRegistrationOption = VALUE(Enum.PurchaseRegistrationOptions.UninvoicedDeliveriesOfGoodsAndServices))"; 
					Query.SetParameter("ListOfOptionsForServices", ListOfOptionsForServices);
					
					StandardProcessing = False;
					
					Continue;
					
				EndIf;
				
				If Parameters.Property("ShowPurchaseByImport")
					And (CurrentFilter.Value = Enums.BusinessTransactions.PurchaseFromSupplier
						Or CurrentFilter.Value = Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit
						Or CurrentFilter.Value = Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt) Then
					
					ConditionsText = ConditionsText + "
					|	AND Contracts.BusinessOperation IN(VALUE(Enum.BusinessTransactions.PurchaseByImport),
					|										VALUE(Enum.BusinessTransactions.ImportGoodsInTransit),
					|										VALUE(Enum.BusinessTransactions.PurchaseFromSupplier),
					|										VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
					|										VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt))";
					
					StandardProcessing = False;
					
					Continue;
					
				EndIf;
				
				If Parameters.Property("ShowSeparatePurchaseContracts")
					And (CurrentFilter.Value = Enums.BusinessTransactions.PurchaseFromSupplier
						Or CurrentFilter.Value = Enums.BusinessTransactions.PurchaseByImport
						Or CurrentFilter.Value = Enums.BusinessTransactions.ImportFromEAEU) Then
					
					ConditionsText = ConditionsText + "
					|	AND Contracts.BusinessOperation IN(&EconomicOperationsOfSeparatePurchase)";
					
					Query.SetParameter("EconomicOperationsOfSeparatePurchase",
												PurchasesServerCall.BusinessOperationsOnMain(CurrentFilter.Value));
					If Parameters.Property("ShowProductionAtProcessor") Then
					
						If GetFunctionalOption("UseProductionByThirdParty2_5") Then
							If CurrentFilter.Value = Enums.BusinessTransactions.PurchaseFromSupplier Then 
								CommonClientServer.SupplementArray(Query.Parameters.EconomicOperationsOfSeparatePurchase, 
											CommonClientServer.ValueInArray(Enums.BusinessTransactions.ProductionByToller2_5));
							ElsIf CurrentFilter.Value = Enums.BusinessTransactions.ImportFromEAEU Then 
								CommonClientServer.SupplementArray(Query.Parameters.EconomicOperationsOfSeparatePurchase, 
											CommonClientServer.ValueInArray(Enums.BusinessTransactions.ProductionAtProcessorInEAEUCountries2_5));
							EndIf;
						EndIf;
				
					EndIf;
					StandardProcessing = False;
					
					Continue;
					
				EndIf;
				
				If Parameters.Property("ProcessingInEAEUCountries") Then
					
					ConditionsText = ConditionsText + "
					|	AND Contracts.BusinessOperation IN(&ProcessingBusinessTransactions)";
					
					Query.SetParameter("ProcessingBusinessTransactions",
												PurchasesServerCall.BusinessOperationsOnMain(CurrentFilter.Value));
					
					StandardProcessing = False;
					
					Continue;
					
				EndIf;
				
			ElsIf CurrentFilter.Key = "ConsignmentSales25" Then
				
				ConditionsText = ConditionsText + "
				|	AND Contracts.ConsignmentSales25 = &ConsignmentSales25";
				
				Query.SetParameter("ConsignmentSales25", CurrentFilter.Value);
				
				StandardProcessing = False;
				
				Continue;
				
			ElsIf CurrentFilter.Key = "SuitableForSelectionInTheCustomerSContract" Then
				
				ConditionsText = ConditionsText + "
					|	AND CASE
					|		WHEN Contracts.ContractType = VALUE(Enum.ContractTypes.WithCustomer)
					|			AND Contracts.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomer)
					|			OR Contracts.ContractType = VALUE(Enum.ContractTypes.ReceiptForTolling2_5)
					|			THEN TRUE
					|		ELSE FALSE
					|	END = &SuitableForSelectionInTheCustomerSContract";
				
				Query.SetParameter("SuitableForSelectionInTheCustomerSContract", CurrentFilter.Value);
				
				StandardProcessing = False;
				
				Continue;
				
			EndIf;
			
			SelectionNumber_ = SelectionNumber_ + 1;
			
			ConditionsText = ConditionsText + "
			|	AND Contracts." + CurrentFilter.Key + " IN (&FilterValue" + TrimAll(SelectionNumber_) + ")";
			
			Query.SetParameter("FilterValue" + TrimAll(SelectionNumber_), CurrentFilter.Value);
			
		EndDo;
		
	EndIf;
	
	If Not StandardProcessing Then
		
		//The query text contains literals for redefining/substituting &textconditions &textconditions
		QueryText = "SELECT ALLOWED
		               |	Contracts.Ref AS Ref,
		               |	Contracts.Description AS Description,
		               |	Contracts.Description AS Coincidence,
		               |	1 AS Order
		               |INTO SearchContracts 
					   |FROM
		               |	Catalog.CounterpartyContracts AS Contracts
					   |
					   |,&TextOfConnections
					   |
		               |WHERE
		               |	Contracts.Description LIKE &SearchString ESCAPE ""~""
					   |	AND &ConditionsText
		               |
		               |UNION ALL
		               |
		               |SELECT
		               |	Contracts.Ref,
		               |	Contracts.Description,
		               |	Contracts.Number,
		               |	2
		               |FROM
		               |	Catalog.CounterpartyContracts AS Contracts
					   |
					   |,&TextOfConnections
					   |
		               |WHERE
		               |	Contracts.Number LIKE &SearchString ESCAPE ""~""
					   |	AND &ConditionsText
		               |;
		               |
		               |////////////////////////////////////////////////////////////////////////////////
		               |SELECT
		               |	SearchContracts.Ref AS Ref,
		               |	MIN(SearchContracts.Order) AS Order
		               |INTO ContractsInOrder
		               |FROM
		               |	SearchContracts AS SearchContracts
		               |
		               |GROUP BY
		               |	SearchContracts.Ref
		               |;
		               |
		               |////////////////////////////////////////////////////////////////////////////////
		               |SELECT
		               |	ISNULL(SearchContracts.Ref, VALUE(Catalog.CounterpartyContracts.EmptyRef)) AS Ref,
		               |	ISNULL(SearchContracts.Description, """") AS Description,
		               |	ISNULL(SearchContracts.Coincidence, """") AS Coincidence,
		               |	ISNULL(SearchContracts.Order, 0) AS Order
		               |FROM
		               |	ContractsInOrder AS ContractsInOrder
		               |		LEFT JOIN SearchContracts AS SearchContracts
		               |		ON ContractsInOrder.Ref = SearchContracts.Ref
		               |			AND ContractsInOrder.Order = SearchContracts.Order
		               |
		               |ORDER BY
		               |	ISNULL(SearchContracts.Order, 0),
		               |	ISNULL(SearchContracts.Coincidence, """"),
		               |	ISNULL(SearchContracts.Description, """")";
		
		QueryText = StrReplace(QueryText, ",&TextOfConnections", TextOfConnections);
		
		If Not IsBlankString(ConditionsText) Then
			
			QueryText = StrReplace(QueryText, "AND &ConditionsText", ConditionsText);
			
		Else

			QueryText = StrReplace(QueryText, "AND &ConditionsText", "");
			
		EndIf;
		
		Query.Text = QueryText;
		Query.SetParameter("SearchString", Common.GenerateSearchQueryString(Parameters.SearchString) + "%");
		
		ChoiceData = New ValueList;
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			
			TextValue = ?(
				Selection.Order = 1,
				Selection.Description,
				TrimR(Selection.Coincidence) + " (" + Selection.Description + ")");
				
			ChoiceData.Add(Selection.Ref, TextValue);
			
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region Assignments

// Returns a template for generating an assignment
//
// Parameters:
// 		Object - CatalogObject.CounterpartyContracts, FormDataStructure - the object to get the destination template for.
//
// Returns:
// 		See Catalogs.Assignments.NewSubmenuTemplate
//
Function DestinationPattern(Object) Export
	
	DestinationPattern = Catalogs.Assignments.NewSubmenuTemplate();
	
	If Object.ContractType = Enums.ContractTypes.CustomerInvoiceOutsourcedSale Then
		
		If LinesOfBusinessServer.ThisIsLineOfActivityWithSeparationOfGoodsAndWorks(Object.LineOfBusiness) Then
			DestinationPattern.LineOfBusiness = Object.LineOfBusiness;
		EndIf;
		
		DestinationPattern.Partner = Object.Partner;
		DestinationPattern.Contract = Object.Ref;
		DestinationPattern.AssignmentType = Enums.AssignmentTypes.DeliveryForPrincipal;
	ElsIf Object.ContractType = Enums.ContractTypes.TransferToTolling2_5
		Or Object.ContractType = Enums.ContractTypes.SubcontractingToTheEAEUCountries 
		Or False Then
		
		If LinesOfBusinessServer.ThisIsLineOfActivityWithSeparationOfGoodsAndWorks(Object.LineOfBusiness) Then
			DestinationPattern.LineOfBusiness = Object.LineOfBusiness;
		EndIf;
		
		DestinationPattern.Partner = Object.Partner;
		DestinationPattern.Contract = Object.Ref;
		
	ElsIf Object.ContractType = Enums.ContractTypes.ReceiptForTolling2_5 Then
		
		If LinesOfBusinessServer.ThisIsLineOfActivityWithSeparationOfGoodsAndWorks(Object.LineOfBusiness) Then
			DestinationPattern.LineOfBusiness = Object.LineOfBusiness;
		EndIf;
		
		DestinationPattern.Partner       = Object.Partner;
		DestinationPattern.Contract       = Object.Ref;
		DestinationPattern.AssignmentType = Enums.AssignmentTypes.Giveaway2_5;
	EndIf;
	
	Return DestinationPattern;
	
EndFunction

#EndRegion

#Region ToDoList

// Fills in the user's to-do list.
// Parameters: 
//  ToDoList - See ToDoListServer.ToDoList
Procedure OnFillToDoList(ToDoList) Export
	
	CommonQueryParameters = ToDoListInternal.CommonQueryParameters();
	
	FillOutBusinessContractsWithClients(ToDoList, CommonQueryParameters);
	FillOutContractsWithSuppliers(ToDoList, CommonQueryParameters);
	
EndProcedure

// Parameters: 
//  ToDoList - See ToDoListServer.ToDoList
Procedure FillOutBusinessContractsWithClients(ToDoList, CommonQueryParameters)
	
	FormName = "Catalog.CounterpartyContracts.Form.ListFormSales";
	
	// Let's determine whether the group's indicators are available to the current user
	Enabled =
		(CommonQueryParameters.IsFullUser
			Or AccessRight("View", Metadata.Catalogs.CounterpartyContracts))
		And ContractsWithClientsAreAvailable();
	
	If Not Enabled Then
		Return;
	EndIf;
	
	// The calculation of the indicators
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	COUNT(DISTINCT CASE
	|			WHEN ContractWithCustomer.Status = VALUE(Enum.CounterpartyContractStatuses.NotApproved)
	|				THEN ContractWithCustomer.Ref
	|		END) AS ContractsWithClientsUnderApproval,
	|	COUNT(DISTINCT CASE
	|			WHEN ContractWithCustomer.Status = VALUE(Enum.CounterpartyContractStatuses.NotApproved)
	|					AND (ContractWithCustomer.ValidityStartDate <> DATETIME(1, 1, 1)
	|							AND ContractWithCustomer.ValidityStartDate < &UpdateDate
	|						OR ContractWithCustomer.ValidityEndDate <> DATETIME(1, 1, 1)
	|							AND ContractWithCustomer.ValidityEndDate < &UpdateDate)
	|				THEN ContractWithCustomer.Ref
	|			WHEN ContractWithCustomer.Status = VALUE(Enum.CounterpartyContractStatuses.Valid)
	|					AND ContractWithCustomer.ValidityEndDate <> DATETIME(1, 1, 1)
	|					AND ContractWithCustomer.ValidityEndDate < &UpdateDate
	|				THEN ContractWithCustomer.Ref
	|		END) AS ContractsWithCustomersOverdue
	|FROM
	|	Catalog.CounterpartyContracts AS ContractWithCustomer
	|WHERE
	|	ContractWithCustomer.Status <> VALUE(Enum.CounterpartyContractStatuses.Closed)
	|	AND (ContractWithCustomer.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomer)
	|			OR ContractWithCustomer.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
	|			OR ContractWithCustomer.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToStorageWithRightOfSale))
	|	AND ContractWithCustomer.Manager = &User
	|	AND (NOT ContractWithCustomer.DeletionMark)";
	
	Result = ToDoListInternal.NumericUserTasksIndicators(Query, CommonQueryParameters);
	
	// Filling out cases.
	// Contract with clients
	UserTaskParent = ToDoList.Add();
	UserTaskParent.Id  = "ContractsWithCustomers_";
	UserTaskParent.Presentation  = NStr("vi = 'Hợp đồng với khách hàng';
										|ru = 'Договоры с клиентами';
										|en = 'Contracts with customers'; fa = 'قراردادهای با مشتریان';
										|it = 'Contratti con i clienti';
										|pl = 'Umowy z klientami';
										|tr = 'Müşteriler ile yapılan sözleşmeler'");
	UserTaskParent.Owner       = Metadata.Subsystems.Sales;
	
	// ContractsWithClientsUnderApproval
	FilterParameters = New Structure;
	FilterParameters.Insert("State", Enums.CounterpartyContractStates.PendingApproval);
	FilterParameters.Insert("Relevance", "");
	FilterParameters.Insert("EventDate", CommonQueryParameters.DateEmpty);
	FilterParameters.Insert("Manager", CommonQueryParameters.User);
	FilterParameters.Insert("Organization", Undefined);
	FilterParameters.Insert("Counterparty", Undefined);
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "ContractsWithClientsUnderApproval";
	ToDoItem.HasToDoItems       = Result.ContractsWithClientsUnderApproval > 0;
	ToDoItem.Presentation  = NStr("vi = 'Hợp đồng thỏa thuận';
									|ru = 'Договоры на согласовании';
									|en = 'Contracts pending approval'; fa = 'Contracts pending approval';
									|it = 'Gli accordi sono in corso di negoziazione';
									|pl = 'Umowy na uzgodnieniu';
									|tr = 'Müzakere aşamasındaki sözleşmeler'");
	ToDoItem.Count     = Result.ContractsWithClientsUnderApproval;
	ToDoItem.Important         = False;
	ToDoItem.Form          = FormName;
	ToDoItem.FormParameters = New Structure("QuickFilterStructure", FilterParameters);
	ToDoItem.Owner       = "ContractsWithCustomers_";
	
	// ContractsWithCustomersOverdue
	FilterParameters = New Structure;
	FilterParameters.Insert("State", Undefined);
	FilterParameters.Insert("Relevance", "Overdue1");
	FilterParameters.Insert("EventDate", CommonQueryParameters.DateEmpty);
	FilterParameters.Insert("Manager", CommonQueryParameters.User);
	FilterParameters.Insert("Organization", Undefined);
	FilterParameters.Insert("Counterparty", Undefined);
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "ContractsWithCustomersOverdue";
	ToDoItem.HasToDoItems       = Result.ContractsWithCustomersOverdue > 0;
	ToDoItem.Presentation  = NStr("vi = 'Hợp đồng quá hạn';
									|ru = 'Просроченные договоры';
									|en = 'Overdue contracts'; fa = 'Overdue contracts';
									|it = 'Accordi scaduti';
									|pl = 'Przeterminowane umowy';
									|tr = 'Vadesi geçmiş sözleşmeler'");
	ToDoItem.Count     = Result.ContractsWithCustomersOverdue;
	ToDoItem.Important         = True;
	ToDoItem.Form          = FormName;
	ToDoItem.FormParameters = New Structure("QuickFilterStructure", FilterParameters);
	ToDoItem.Owner       = "ContractsWithCustomers_";
	
	If Result.ContractsWithClientsUnderApproval > 0
		Or Result.ContractsWithCustomersOverdue > 0 Then
		UserTaskParent.HasToDoItems = True;
	EndIf;
	
EndProcedure

Procedure FillOutContractsWithSuppliers(ToDoList, CommonQueryParameters)
	
	FormName = "Catalog.CounterpartyContracts.Form.PurchasingListForm";
	
	// Let's determine whether the group's indicators are available to the current user
	Enabled =
		(CommonQueryParameters.IsFullUser
			Or AccessRight("View", Metadata.Catalogs.CounterpartyContracts))
		And ContractsWithSuppliersAreAvailable();
	
	If Not Enabled Then
		Return;
	EndIf;
	
	// The calculation of the indicators
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	COUNT(DISTINCT CASE
	|			WHEN SupplierContract.Status = VALUE(Enum.CounterpartyContractStatuses.NotApproved)
	|				THEN SupplierContract.Ref
	|		END) AS ContractsWithSuppliersUnderApproval,
	|	COUNT(DISTINCT CASE
	|			WHEN SupplierContract.Status = VALUE(Enum.CounterpartyContractStatuses.NotApproved)
	|					AND (SupplierContract.ValidityStartDate <> DATETIME(1, 1, 1)
	|							AND SupplierContract.ValidityStartDate < &UpdateDate
	|						OR SupplierContract.ValidityEndDate <> DATETIME(1, 1, 1)
	|							AND SupplierContract.ValidityEndDate < &UpdateDate)
	|				THEN SupplierContract.Ref
	|			WHEN SupplierContract.Status = VALUE(Enum.CounterpartyContractStatuses.Valid)
	|					AND SupplierContract.ValidityEndDate <> DATETIME(1, 1, 1)
	|					AND SupplierContract.ValidityEndDate < &UpdateDate
	|				THEN SupplierContract.Ref
	|		END) AS ContractsWithSuppliersOverdue
	|FROM
	|	Catalog.CounterpartyContracts AS SupplierContract
	|WHERE
	|	SupplierContract.Status <> VALUE(Enum.CounterpartyContractStatuses.Closed)
	|	AND (SupplierContract.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
	|	OR SupplierContract.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit)
	|	OR SupplierContract.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt)
	|	OR SupplierContract.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseByImport)
	|	OR SupplierContract.BusinessOperation = VALUE(Enum.BusinessTransactions.ImportGoodsInTransit)
	|	OR SupplierContract.BusinessOperation = VALUE(Enum.BusinessTransactions.ImportFromEAEU)
	|	OR SupplierContract.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
	|	OR SupplierContract.BusinessOperation = VALUE(Enum.BusinessTransactions.ReceivingForStorageWithRightOfSale))
	|	AND SupplierContract.Manager = &User
	|	AND (NOT SupplierContract.DeletionMark)";
	
	Result = ToDoListInternal.NumericUserTasksIndicators(Query, CommonQueryParameters);
	
	// Filling out cases.
	// Contracts with suppliers
	UserTaskParent = ToDoList.Add();
	UserTaskParent.Id  = "ContractsWithVendors";
	UserTaskParent.Presentation  = NStr("vi = 'Hợp đồng với nhà cung cấp';
										|ru = 'Договоры с поставщиками';
										|en = 'Contracts with vendors'; fa = 'قراردادهای با تأمین‌کنندگان';
										|it = 'Contratti con i fornitori';
										|pl = 'Warunki współpracy';
										|tr = 'Tedarikçilerle yapılan sözleşmeler'");
	UserTaskParent.Owner       = Metadata.Subsystems.Purchases;
	
	// ContractsWithSuppliersUnderApproval
	FilterParameters = New Structure;
	FilterParameters.Insert("State", Enums.CounterpartyContractStates.PendingApproval);
	FilterParameters.Insert("Relevance", "");
	FilterParameters.Insert("EventDate", CommonQueryParameters.DateEmpty);
	FilterParameters.Insert("Manager", CommonQueryParameters.User);
	FilterParameters.Insert("Organization", Undefined);
	FilterParameters.Insert("Counterparty", Undefined);
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "ContractsWithSuppliersUnderApproval";
	ToDoItem.HasToDoItems       = Result.ContractsWithSuppliersUnderApproval > 0;
	ToDoItem.Presentation  = NStr("vi = 'Hợp đồng thỏa thuận';
									|ru = 'Договоры на согласовании';
									|en = 'Contracts pending approval'; fa = 'Contracts pending approval';
									|it = 'Gli accordi sono in corso di negoziazione';
									|pl = 'Umowy na uzgodnieniu';
									|tr = 'Müzakere aşamasındaki sözleşmeler'");
	ToDoItem.Count     = Result.ContractsWithSuppliersUnderApproval;
	ToDoItem.Important         = False;
	ToDoItem.Form          = FormName;
	ToDoItem.FormParameters = New Structure("QuickFilterStructure", FilterParameters);
	ToDoItem.Owner       = "ContractsWithVendors";
	
	// ContractsWithSuppliersOverdue
	FilterParameters = New Structure;
	FilterParameters.Insert("State", Undefined);
	FilterParameters.Insert("Relevance", "Overdue1");
	FilterParameters.Insert("EventDate", CommonQueryParameters.DateEmpty);
	FilterParameters.Insert("Manager", CommonQueryParameters.User);
	FilterParameters.Insert("Organization", Undefined);
	FilterParameters.Insert("Counterparty", Undefined);
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "ContractsWithSuppliersOverdue";
	ToDoItem.HasToDoItems       = Result.ContractsWithSuppliersOverdue > 0;
	ToDoItem.Presentation  = NStr("vi = 'Hợp đồng quá hạn';
									|ru = 'Просроченные договоры';
									|en = 'Overdue contracts'; fa = 'Overdue contracts';
									|it = 'Accordi scaduti';
									|pl = 'Przeterminowane umowy';
									|tr = 'Vadesi geçmiş sözleşmeler'");
	ToDoItem.Count     = Result.ContractsWithSuppliersOverdue;
	ToDoItem.Important         = True;
	ToDoItem.Form          = FormName;
	ToDoItem.FormParameters = New Structure("QuickFilterStructure", FilterParameters);
	ToDoItem.Owner       = "ContractsWithVendors";
	
	If Result.ContractsWithSuppliersUnderApproval > 0
		Or Result.ContractsWithSuppliersOverdue > 0 Then
		UserTaskParent.HasToDoItems = True;
	EndIf;
	
EndProcedure

Function ContractsWithClientsAreAvailable()
	
	ArrayOfBusinessOperations = New Array;
	ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.SaleToCustomer);
	ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.TransferToCommissionAgent);
	ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.TransferToStorageWithRightOfSale);
	
	Return ThereIsRightToChangeContracts(ArrayOfBusinessOperations);
	
EndFunction

Function ContractsWithSuppliersAreAvailable()
	
	ArrayOfBusinessOperations = New Array;
	ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.PurchaseFromSupplier);
	ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.ConsignmentProcurement);
	ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale);
	
	Return ThereIsRightToChangeContracts(ArrayOfBusinessOperations);
	
EndFunction

Function ThereIsRightToChangeContracts(ArrayOfBusinessOperations)
	
	TableSets = AccessManagement.AccessValuesSetsTable();
	
	// Let's fill in the sets of access values to contracts
	Cnt = 1;
	For Each BusinessOperation In ArrayOfBusinessOperations Do
		TabRow = TableSets.Add();
		TabRow.SetNumber     = Cnt;
		TabRow.AccessValue = BusinessOperation;
		Cnt = Cnt+1;
	EndDo;
	
	Return AccessManagement.HasRole("AddEditCounterpartyContracts", TableSets);
	
EndFunction

#EndRegion

#Region Print

// Fills in the list of print commands.
// 
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	CounterpartyContractsLocalization.AddPrintCommands(PrintCommands);
EndProcedure

#EndRegion

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	ReportCommand = ARAPAccountingServer.StatementOfSettlementsWithPartners_AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "ItemForm,ListForm,ListFormSales";
	EndIf;
	
	ReportCommand = Reports.DetailedCalculationOfDiscountingInterestExpenseAccrual.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "ItemForm,PurchasingListForm";
	EndIf;
	
	ReportCommand = Reports.ActiveRebatesByContract.AddReportCommand(
		ReportsCommands,
		"CurrentRetroRebatesUnderContractContext");
	If ReportCommand <> Undefined Then
		
		AttachableCommands.AddCommandVisibilityCondition(
			ReportCommand,
			"ContractType",
			Enums.ContractTypes.WithCustomer,
			DataCompositionComparisonType.Equal);
		ReportCommand.VisibilityInForms = "ItemForm,ListFormSales,ListForm";
		
	EndIf;
	
	ReportCommand = Reports.ActiveVendorRebates.AddReportCommand(
		ReportsCommands, Parameters, "CurrentRebatesOfSuppliersContext");
	If ReportCommand <> Undefined Then
		
		Presentation = NStr("vi = 'Thưởng lũy kế của nhà cung cấp đang có hiệu lực';
							|ru = 'Действующие ретро-бонусы поставщика';
							|en = 'Active vendor rebates'; fa = 'تخفیف‌های حجمی فعال فروشنده';
							|it = 'Действующие ретро-бонусы поставщика';
							|pl = 'Active vendor rebates';
							|tr = 'Sağlayıcının geçerli retro bonusları'");
		ReportCommand.Presentation = Presentation;
		
		ContractTypes = RebatesClientServer.TypesOfProcurementContracts();
		AttachableCommands.AddCommandVisibilityCondition(
			ReportCommand,
			"ContractType",
			ContractTypes,
			DataCompositionComparisonType.InList);
		
	EndIf;
	Reports.DocumentFulfillmentStatus.AddContractExecutionStateCommand(ReportsCommands);
	
	CounterpartyContractsLocalization.AddReportCommands(ReportsCommands, Parameters);
EndProcedure

#EndRegion

#Region MessageTemplates

// Called when preparing message templates and allows you to redefine the list of details and attachments.
//
// Parameters:
//  Attributes               - ValueTree - list of template Attributes:
//         * Name            - String - the unique name of the shared prop.
//         * Presentation  - String - representation of general props.
//         * Type            - Type    - Type of props. By default, a string.
//         * Format         - String - Format for output values for numbers, dates, strings, and Boolean values.
//  Attachments                - ValueTable - Printed forms and attachments:
//         * Name            - String - the unique name of the attachment.
//         * Presentation  - String - representation of the option.
//         * FileType       - String - Attachment type that corresponds to the file extension: "pdf", "png", "jpg", mxl"
//                                      , etc.
//  AdditionalParameters - Structure - more information about the message template.
//
Procedure OnPrepareMessageTemplate(Attributes, Attachments, AdditionalParameters) Export
	
EndProcedure

// Called when creating messages based on a template to fill in the values of details and attachments.
//
// Parameters:
//  Message - Structure - structure with keys:
//    * AttributesValues - Map of KeyAndValue- list of Attributes used in the template:
//      * Key     - String - name of the prop in the template;
//      * Value - String - the fill value in the template.
//    * CommonAttributesValues - Map of KeyAndValue - list of common Attributes used in the template:
//      * Key     - String - name of the prop in the template;
//      * Value - String - the fill value in the template.
//    * Attachments - Map of KeyAndValue - the values of the requisites
//      * Key     - String - name of the attachment in the template;
//      * Value - BinaryData, String - binary data or an address in the attachment's temporary storage.
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//  AdditionalParameters - Structure -  additional information about the message template.
//
Procedure OnCreateMessage(Message, MessageSubject, AdditionalParameters) Export
	
EndProcedure

// Fills in the list of SMS recipients when sending a message generated by a template.
//
// Parameters:
//   SMSMessageRecipients - ValueTable - the list is received by SMS:
//     * PhoneNumber - String - phone number where the SMS message will be sent.
//     * Presentation - String - representation of the recipient of the SMS message.
//     * Contact       - CatalogRef - the contact that the phone number belongs to.
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//
Procedure OnFillRecipientsPhonesInMessage(SMSMessageRecipients, MessageSubject) Export
	
EndProcedure

// Fills in the list of email recipients when sending a message generated by a template.
//
// Parameters:
//   EmailRecipients - ValueTable - list of received emails:
//     * Address           - String - recipient's email address.
//     * Presentation   - String - submission of the email message.
//     * SendingOption - String - Options for sending emails: "To", "Copy", "Hidden Copy", " Reverse Address";
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//
Procedure OnFillRecipientsEmailsInMessage(EmailRecipients, MessageSubject) Export
	
EndProcedure

#EndRegion

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Catalogs.CounterpartyContracts.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.27.27";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("eadc8581-e029-11ed-8803-782b4641589c");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Catalogs.CounterpartyContracts.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Cập nhật danh mục ""Hợp đồng với đối tác"":';
								|ru = 'Обновление справочника ""Договоры с контрагентами"":';
								|en = 'Update the ""Contracts"" catalog:'; fa = 'Update the ""Contracts"" catalog:';
								|it = 'Update the ""Contracts"" catalog:';
								|pl = 'Update the ""Contracts"" catalog:';
								|tr = '“Cari hesaplarla sözleşmeler” katalogunun güncellenmesi:'"));
	ListOfDescriptions.Add(NStr("vi = 'Điền mục tin ""Phương án tiếp nhận dịch vụ"" cho hợp đồng đối tác.';
								|ru = 'Заполняет реквизит ""Вариант приемки услуг"" для договоров контрагентов.';
								|en = 'Fills in the ""Service receipt option"" attribute for counterparty contracts.'; fa = 'Fills in the ""Service receipt option"" attribute for counterparty contracts.';
								|it = 'Fills in the ""Service receipt option"" attribute for counterparty contracts.';
								|pl = 'Fills in the ""Service receipt option"" attribute for counterparty contracts.';
								|tr = 'Cari hesap sözleşmeleri için ""Hizmet kabul seçeneği"" alanını doldurur.'"));
	ListOfDescriptions.Add(NStr("vi = 'Điền mục tin ""Phương án xác định lịch thực hiện trong hợp đồng"" cho các hợp đồng của đối tác.';
								|ru = 'Заполняет реквизит ""Вариант определения графика исполнения в договоре"" для договоров контрагентов.';
								|en = 'Fills in the ""Option of defining execution schedule in contract"" attribute for counterparty contracts.'; fa = 'Fills in the ""Option of defining execution schedule in contract"" attribute for counterparty contracts.';
								|it = 'Fills in the ""Option of defining execution schedule in contract"" attribute for counterparty contracts.';
								|pl = 'Fills in the ""Option of defining execution schedule in contract"" attribute for counterparty contracts.';
								|tr = 'Cari hesap sözleşmeleri için “Sözleşmede gerçekleştirme planının belirlenme varyantı” özniteliğini doldurur.'"));
	
	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Catalogs.CounterpartyContracts.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Catalogs.CounterpartyContracts.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = EmptyRef().Metadata().FullName();
	SelectionParameters.OrderingFieldsOnUserOperations.Add("DATE DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("DATE DESC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	CounterpartyContracts.Ref AS Ref
	|FROM
	|	Catalog.CounterpartyContracts AS CounterpartyContracts
	|WHERE
	|	CounterpartyContracts.OptionOfDeterminingExecutionScheduleInContract
	|		= VALUE(Enum.OptionsForDeterminingExecutionScheduleInContract.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	CounterpartyContracts.Ref AS Ref
	|FROM
	|	Catalog.CounterpartyContracts AS CounterpartyContracts
	|WHERE
	|	CounterpartyContracts.ServiceReceiptOption = VALUE(Enum.GoodsReceiptOptions.EmptyRef)
	|	OR
	|		CounterpartyContracts.OptionForRegisteringServiceReceiptDocuments = VALUE(Enum.OptionsForRegisteringServiceDocuments.EmptyRef)
	|";
	
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

// An update handler.
// 
// Parameters:
//  Parameters - Structure - parameters.
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullObjectName = EmptyRef().Metadata().FullName();  
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);   
	
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(
			Parameters.Queue, FullObjectName);
		Return;
	EndIf;
	
	#Region QueryTexts
	
	QueryTexts = New Array;
	
	QueryTexts.Add(
		"SELECT
		|	CounterpartyContracts.Ref AS Ref,
		|	CounterpartyContracts.GoodsReceiptOption AS GoodsReceiptOption,
		|	CASE
		|		WHEN &UninvoicedDelivery
		|			THEN CASE
		|				WHEN
		|					CounterpartyContracts.PurchaseRegistrationOption = VALUE(Enum.PurchaseRegistrationOptions.UninvoicedDeliveriesOfGoodsAndServices)
		|					THEN VALUE(Enum.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsInvoiced)
		|				WHEN
		|					CounterpartyContracts.PurchaseRegistrationOption = VALUE(Enum.PurchaseRegistrationOptions.UninvoicedDeliveriesOfGoods)
		|					THEN VALUE(Enum.OptionsForRegisteringServiceDocuments.ReceiptOfServicesNotUsed)
		|				ELSE VALUE(Enum.OptionsForRegisteringServiceDocuments.ReceiptOfServicesNotUsed)
		|			END
		|		ELSE VALUE(Enum.OptionsForRegisteringServiceDocuments.ReceiptOfServicesNotUsed)
		|	END AS RegistrationOption,
		|	CounterpartyContracts.ExecutionScheduleIsSpecified AS ExecutionScheduleIsSpecified,
		|	CounterpartyContracts.OptionOfDeterminingExecutionScheduleInContract AS OptionOfDeterminingExecutionScheduleInContract
		|FROM
		|	Catalog.CounterpartyContracts AS CounterpartyContracts
		|WHERE
		|	CounterpartyContracts.Ref IN (&UpdatedData)");
	
	#EndRegion
	
	Query = New Query(StrConcat(QueryTexts, Common.QueryBatchSeparator()));
	Query.SetParameter("UpdatedData",         UpdatedData.UnloadColumn("Ref"));
	Query.SetParameter("UninvoicedDelivery", GetFunctionalOption("UseUninvoicedDeliveries")); 
	Selection = Query.Execute().Select();
	
	If Selection.Count() = 0 Then
		Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(
			Parameters.Queue, FullObjectName);
		Return;
	EndIf;
	
	ObjectsProcessed = 0;
	BadData = New Array;
	
	While Selection.Next() Do
		BeginTransaction();
		
		Try
			
			ExceptionReason = "Block";
			
			Block = New DataLock;
			
			LockItem = Block.Add(FullObjectName);
			LockItem.SetValue("Ref", Selection.Ref);
			LockItem.Mode = DataLockMode.Exclusive;
			
			Block.Lock();
			
			CatalogObject = Selection.Ref.GetObject();
			
			If CatalogObject = Undefined Then
				CommitTransaction();
				Continue;
			EndIf;
			
			ExceptionReason = "BadData";
			If Not ValueIsFilled(CatalogObject.ServiceReceiptOption) Then
				CatalogObject.ServiceReceiptOption = Selection.GoodsReceiptOption;
			EndIf;
			If Not ValueIsFilled(CatalogObject.OptionForRegisteringServiceReceiptDocuments) Then
				CatalogObject.OptionForRegisteringServiceReceiptDocuments = Selection.RegistrationOption;
			EndIf;
			If Not ValueIsFilled(Selection.OptionOfDeterminingExecutionScheduleInContract) Then
				CatalogObject.OptionOfDeterminingExecutionScheduleInContract = ?(Selection.ExecutionScheduleIsSpecified,
					Enums.OptionsForDeterminingExecutionScheduleInContract.Contract,
					Enums.OptionsForDeterminingExecutionScheduleInContract.SalesOrderCustomerInvoices);
			EndIf;
			
			ExceptionReason = "Record";
			
			If CatalogObject.Modified() Then
				InfobaseUpdate.WriteData(CatalogObject);
			Else
				InfobaseUpdate.MarkProcessingCompletion(Selection.Ref);
			EndIf;
			
			ObjectsProcessed = ObjectsProcessed + 1;
			CommitTransaction();
		Except
			RollbackTransaction();
			
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Selection.Ref);
			
			If ExceptionReason = "BadData" Then
				DataProblem = DataProblem(Selection.Ref, ErrorInfo());
				BadData.Add(DataProblem);
			ElsIf ExceptionReason <> "Block" Then
				RecordBadData(BadData, ObjectsProcessed);
				Raise NStr("vi = 'Lỗi phong tỏa khi ghi phần tử của danh mục ""Hợp đồng đối tác"".';
							|ru = 'Ошибка блокировки при записи элемента справочника ""Договоры контрагентов"".';
							|en = 'A locking error occurred when saving the ""Counterparty contracts"" catalog item.'; fa = 'A locking error occurred when saving the ""Counterparty contracts"" catalog item.';
							|it = 'A locking error occurred when saving the ""Counterparty contracts"" catalog item.';
							|pl = 'A locking error occurred when saving the ""Counterparty contracts"" catalog item.';
							|tr = '""Cari hesap sözleşmeleri"" katalog öğesi kaydedilirken kilitleme hatası.'");
			EndIf;
		EndTry;
	EndDo;
	
	If ObjectsProcessed > 0 Then
		RecordBadData(BadData, ObjectsProcessed)
	EndIf;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);

EndProcedure

Procedure RecordBadData(BadData, ObjectsProcessed)
	If ObjectsProcessed > 0 Then
		For Each DataProblem In BadData Do
			RepresentationOfTheReference = String(DataProblem.ObjectReference);
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể điền mục tin ""%1"" do:
						|%2.';
						|ru = 'Не удалось заполнить реквизиты ""%1"" по причине:
						|%2.';
						|en = 'Cannot fill in the ""%1"" attributes. Reason:
						|%2.'; fa = 'Cannot fill in the ""%1"" attributes. Reason:
						|%2.';
						|it = 'Cannot fill in the ""%1"" attributes. Reason:
						|%2.';
						|pl = 'Cannot fill in the ""%1"" attributes. Reason:
						|%2.';
						|tr = '""%1"" öznitelikleri şu sebeple doldurulamadı:
						|%2.'"), 
					RepresentationOfTheReference, ErrorProcessing.DetailErrorDescription(DataProblem.ErrorInfo));
			InfobaseUpdate.FileIssueWithData(DataProblem, MessageText);
			InfobaseUpdate.MarkProcessingCompletion(DataProblem.ObjectReference);
		EndDo;
	EndIf;
EndProcedure

Function DataProblem(ObjectReference, ErrorInfo)
	Return New Structure("ObjectReference, ErrorInfo", ObjectReference, ErrorInfo);
EndFunction

#EndRegion

#EndRegion

#EndIf
#EndIf
