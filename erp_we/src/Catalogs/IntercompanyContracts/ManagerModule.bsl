#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Adds an object creation command.
//
// Parameters:
//	GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTableRow, Undefined - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
Function AddGenerateCommand(GenerationCommands) Export
	
	Command = Undefined;
	
	If AccessRight("Insert", Metadata.Catalogs.IntercompanyContracts) Then
		Command = GenerationCommands.Add();
		Command.Manager = Metadata.Catalogs.IntercompanyContracts.FullName();
		Command.Presentation = TMCommonUse.ObjectPresentation(Metadata.Catalogs.IntercompanyContracts);
		Command.WriteMode = "Post";
		Command.FunctionalOptions = "UseIntercompanyContracts";
	EndIf;
	
	Return Command;
	
EndFunction

// Sets the status of contracts.
//
// Parameters:
//	Contracts - Array - An array of references to the contracts (Spravochnike.Agreements between organizations);
//	Status - EnumRef.CounterpartyContractStatuses - The status that will be set for contracts.
//
// Returns:
//	Number - the number of processed objects.
//
Function SetStatus(Contracts, Status) Export
	
	ReferencesArrray = New Array;
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
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	IntercompanyContracts.Ref AS Ref,
	|	IntercompanyContracts.DeletionMark AS DeletionMark,
	|	CASE
	|		WHEN IntercompanyContracts.Status = &Status
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS StatusMatches
	|FROM
	|	Catalog.IntercompanyContracts AS IntercompanyContracts
	|
	|WHERE
	|	IntercompanyContracts.Ref IN(&ReferencesArrray)";
	
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
			
			Common.MessageToUser(ErrorText, Selection.Ref);
			
			Continue;
		EndIf;
		
		If Selection.StatusMatches Then
			ErrorText = NStr("vi = 'Hợp đồng %Contract% đã đặt trạng thái ""%Status%""';
							|ru = 'Договору %Contract% уже присвоен статус ""%Status%""';
							|en = 'Status ""%Status%"" has already been assigned to contract %Contract%'; fa = 'Status ""%Status%"" has already been assigned to contract %Contract%';
							|it = 'All''accordo %Contract% è già stato assegnato lo stato ""%Status%""';
							|pl = 'Umowie %Contract% przydzielono już status ""%Status%""';
							|tr = 'Sözleşmeye %Contract% artık ""%Status%"" statüsü verilmiştir'");
			ErrorText = StrReplace(ErrorText, "%Contract%", Selection.Ref);
			ErrorText = StrReplace(ErrorText, "%Status%", Status);
			
			Common.MessageToUser(ErrorText, Selection.Ref);
			
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
							|tr = '%Contract% engellenemedi %ErrorDescription%'");
			ErrorText = StrReplace(ErrorText, "%Contract%", Selection.Ref);
			ErrorText = StrReplace(ErrorText, "%ErrorDescription%", BriefErrorDescription(ErrorInfo()));
			
			Common.MessageToUser(ErrorText, Selection.Ref);
			
			Continue;
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
							|tr = '%Contract% kaydedilemedi. %ErrorDescription%'");
			ErrorText = StrReplace(ErrorText, "%Contract%", Selection.Ref);
			ErrorText = StrReplace(ErrorText, "%ErrorDescription%", BriefErrorDescription(ErrorInfo()));
			
			Common.MessageToUser(ErrorText, Selection.Ref);
		EndTry
		
	EndDo;
	
	Return ProcessedItemsCount;
	
EndFunction

// The procedure fills in the Bank accounts of the document under the agreement.
//
// Parameters:
//	Contract - CatalogRef.CounterpartyContracts - Agreement specified in the document;
//	CompanyBankAccount - CatalogRef.CompaniesBankAccounts, Undefined - Attribute of the document
//		"Organization's Bank account". Undefined if the Attribute of the document is missing or does not require filling in.
//	RecipientCompanyBankAccount - CatalogRef.CompaniesBankAccounts, Undefined - Attribute of the document
//		"Recipient's Bank account". Undefined if the Attribute of the document is missing or does not require filling in.
//
Procedure FillInBankAccountsUnderAgreement(Contract, CompanyBankAccount, RecipientCompanyBankAccount) Export
	
	ContractData = Common.ObjectAttributesValues(Contract, "BankAccount, BankAccountOfBeneficiary"); 
		
	If CompanyBankAccount <> Undefined And ValueIsFilled(ContractData.BankAccount) Then
		CompanyBankAccount = ContractData.BankAccount;
	EndIf;
	If RecipientCompanyBankAccount <> Undefined
		And ValueIsFilled(ContractData.BankAccountOfBeneficiary) Then
		RecipientCompanyBankAccount = ContractData.BankAccountOfBeneficiary;
	EndIf;
	
EndProcedure 

// The procedure fills in the cash flow item under the agreement
//
// Parameters:
//	Contract - CatalogRef.IntercompanyContracts - Agreement specified in the document;
//	CashFlowItem - CatalogRef.CashFlowReportItems - Details of the document " cash flow Item";
//
Procedure FillInCashFlowItemUnderAgreement(Contract, CashFlowItem) Export
	
	If ValueIsFilled(Contract) Then
		CashFlowItem = Common.ObjectAttributeValue(Contract, "CashFlowItem"); 
	EndIf;
	
EndProcedure

// Returns the names of blocked details for the BSP details blocking mechanism.
//
// Returns:
//	Array of String - names of the blocked details.
//
Function GetObjectAttributesToLock() Export
	
	Result = New Array;
	Result.Add("ContractType");
	Result.Add("Organization");
	Result.Add("CompanyRecipient");
	Result.Add("Department");
	Result.Add("ForeignCurrencyTransaction");
	Result.Add("ARAPCurrency");
	Result.Add("ARAPObjectSettings");
	Result.Add("FinancialAccountingGroup");
	Result.Add("FinancialAccountingGroupOfRecipient");
	Result.Add("LineOfBusiness");
	
	Return Result;
	
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
	Parameters.StatisticsCollectionSections.UseAlways = "CompanyRecipient, ForeignCurrencyTransaction";
	Parameters.FillInIf.ObjectFieldsFilledIn = "CompanyRecipient";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"BankAccountOfBeneficiary", Parameters);
	
EndProcedure

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)
	|	OR ValueAllowed(CompanyRecipient)";

EndProcedure

// End StandardSubsystems.AccessManagement

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

// Returns parameters for filling in VAT taxation.
//
// Parameters:
//	Object - FormDataStructure,
//			Referenceslink.Agreements between organizations,
//			Reference object.Agreements between organizations - directory agreement between organizations.
//
// Returns:
//	See VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation.
//
Function ParametersForFillingInVATTaxation_(Object) Export
	
	AttributesNames =
		"ValidityStartDate,
		|ContractType,
		|Organization";
	
	CatalogAttributes = New Structure(AttributesNames);
	
	If TypeOf(Object) = Type("CatalogRef.IntercompanyContracts") Then
		CatalogAttributes = Common.ObjectAttributesValues(Object, CatalogAttributes);
	Else
		FillPropertyValues(CatalogAttributes, Object);
	EndIf;
	
	GoodsSales = CatalogAttributes.ContractType = Enums.TypesOfIntercompanyContracts.PurchaseAndSale;
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation();
	FillParameters.Date		= CatalogAttributes.ValidityStartDate;
	FillParameters.Organization	= CatalogAttributes.Organization;
	
	FillParameters.GoodsSales		= GoodsSales;
	FillParameters.ImplementationOfWorksServices	= GoodsSales;
	FillParameters.ConsignmentReportFromCustomer		= Not GoodsSales;
	
	FillParameters.ThisIsOperationBetweenOrganizations = True;
	
	Return FillParameters;
	
EndFunction

// Returns parameters for filling in the VAT activity type.
//
// Parameters:
//	Object - FormDataStructure,
//			Referenceslink.Agreements between organizations,
//			Reference object.Agreements between organizations - directory agreement between organizations.
//
// Returns:
//	See VATAccountingERPClientServer.ParametersForFillingInVATActivityType.
//
Function ParametersForFillingInVATActivityType(Object) Export
	
	AttributesNames =
		"ValidityStartDate,
		|ContractType,
		|CompanyRecipient,
		|LineOfBusiness";
	
	CatalogAttributes = New Structure(AttributesNames);
	
	If TypeOf(Object) = Type("CatalogRef.IntercompanyContracts") Then
		CatalogAttributes = Common.ObjectAttributesValues(Object, CatalogAttributes);
	Else
		FillPropertyValues(CatalogAttributes, Object);
	EndIf;
	
	PurchaseOfGoods = CatalogAttributes.ContractType = Enums.TypesOfIntercompanyContracts.PurchaseAndSale;
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATActivityType();
	FillParameters.Date					= CatalogAttributes.ValidityStartDate;
	FillParameters.Organization				= CatalogAttributes.CompanyRecipient;
	FillParameters.LineOfBusiness	= CatalogAttributes.LineOfBusiness;
	FillParameters.PurchaseOfGoods		= PurchaseOfGoods;
	FillParameters.AcquisitionOfWorks		= PurchaseOfGoods;
	
	Return FillParameters;
	
EndFunction

// Returns parameters of the settlement mechanism.
//
// Parameters:
// 	FillingData - DocumentObject, CatalogObject, DocumentRef, CatalogRef, Structure, FormDataStructure - An object or collection for
//              calculating settlement parameters.
//
// Returns:
// 	Array of See ARAPAccountingServer.MechanismParameters - parameters of the functions of the settlement mechanism.
//
Function SettlementParameters_(FillingData = Undefined) Export
	
	If Common.RefTypeValue(FillingData) Then
		DataFillingStructure = Common.ObjectAttributesValues(FillingData, "ContractType, Sum, ARAPObjectSettings");
		ContractType     = DataFillingStructure.ContractType;
		Sum           = DataFillingStructure.Sum;
		ARAPObjectSettings = DataFillingStructure.ARAPObjectSettings;
	ElsIf FillingData = Undefined Then
		ContractType     = Undefined;
		Sum           = 0;
		ARAPObjectSettings = Enums.ARAPObjectSettings.EmptyRef();
	Else
		ContractType     = FillingData.ContractType;
		Sum           = FillingData.Sum;
		ARAPObjectSettings = FillingData.ARAPObjectSettings;
	EndIf;
	
	InfluencingAttributes = "ContractType,ARAPObjectSettings";
	
	ParametersArray = New Array();
	
	#Region SenderOrganization
		
	#Region Sender
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	
	ParametersStructure.IsCatalog                    = True;
	ParametersStructure.ItCanBeARAPObject    = ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts
	                                                       Or ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice;
	
	ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
	
	// To display a hyperlink and offset payments.
	ParametersStructure.ChangesPaymentPlan = ContractType = Enums.TypesOfIntercompanyContracts.PurchaseAndSale
												And Sum <> 0;
	
	ParametersStructure.Date                             = "Object.Date"; 
	
	// Currency and amount of the transaction. The path to the object's details is required.
	ParametersStructure.DocumentCurrency                  = "Object.ARAPCurrency";
	ParametersStructure.DocumentAmount                   = "Object.Sum";
	ParametersStructure.Partner                          = Catalogs.Partners.OurEnterprise;
	ParametersStructure.Counterparty                       = "Object.CompanyRecipient";
	ParametersStructure.Contract                          = "Object.Ref";
	ParametersStructure.ARAPObjectSettings                  = "Object.ARAPObjectSettings";
	ParametersStructure.Terms                       = "";
	
	// They are used to determine the value of payments in currency and in the form of editing payment rules.
	ParametersStructure.CompanyBankAccount        = "Object.BankAccount";
	ParametersStructure.CounterpartyBankAccount        = "Object.BankAccountOfBeneficiary";
	ParametersStructure.CashAccount                            = "";
	ParametersStructure.PaymentMethod                      = "";
	
	ParametersStructure.Manager                         = "Object.Manager";
	ParametersStructure.IncomingDocumentNumber          = "Object.Number";
	ParametersStructure.IncomingDocumentDate           = "Object.Date";
	
	ParametersStructure.InfluencingAttributes = InfluencingAttributes;
	
	ParametersArray.Add(ParametersStructure);
	
	#EndRegion
	
	#Region SenderReward
	
	If ContractType = Enums.TypesOfIntercompanyContracts.Consignment Then
	
		ParametersStructure = ARAPAccountingServer.MechanismParameters();
		
		ParametersStructure.IsCatalog                    = True;
		ParametersStructure.ItCanBeARAPObject    = ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts
		                                                       Or ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice;
		
		ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
		
		ParametersStructure.ChangesPaymentPlan               = False;
		ParametersStructure.ModifiesDeliveryShipmentPlan     = False;
		
		ParametersStructure.Date                             = "Object.Date"; 
		
		// Currency and amount of the transaction. The path to the object's details is required.
		ParametersStructure.DocumentCurrency                  = "Object.ARAPCurrency";
		ParametersStructure.DocumentAmount                   = "Object.Sum";
		ParametersStructure.Partner                          = Catalogs.Partners.OurEnterprise;
		ParametersStructure.Counterparty                       = "Object.CompanyRecipient";
		ParametersStructure.Contract                          = "Object.Ref";
		ParametersStructure.ARAPObjectSettings                  = "Object.ARAPObjectSettings";
		ParametersStructure.Terms                       = "";
		
		// They are used to determine the value of payments in currency and in the form of editing payment rules.
		ParametersStructure.CompanyBankAccount        = "Object.BankAccount";
		ParametersStructure.CounterpartyBankAccount        = "Object.BankAccountOfBeneficiary";
		ParametersStructure.CashAccount                            = "";
		ParametersStructure.PaymentMethod                      = "";
		
		ParametersStructure.Manager                         = "Object.Manager";
		ParametersStructure.IncomingDocumentNumber          = "Object.Number";
		ParametersStructure.IncomingDocumentDate           = "Object.Date";
		
		ParametersStructure.InfluencingAttributes = InfluencingAttributes;
		
		ParametersArray.Add(ParametersStructure);
	
	EndIf;
	
	#EndRegion
	
	#EndRegion
	
	#Region CompanyRecipient
	
	#Region Recipient
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	
	ParametersStructure.IsCatalog                    = True;
	ParametersStructure.ItCanBeARAPObject    = ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts
	                                                       Or ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice;
	
	ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
	
	// To display a hyperlink
	ParametersStructure.ChangesPaymentPlan = ContractType = Enums.TypesOfIntercompanyContracts.PurchaseAndSale
											And Sum <> 0;
	
	ParametersStructure.Date                             = "Object.Date"; 
	
	// Currency and amount of the transaction. The path to the object's details is required.
	ParametersStructure.DocumentCurrency                  = "Object.ARAPCurrency";
	ParametersStructure.DocumentAmount                   = "Object.Sum";
	ParametersStructure.Organization                      = "Object.CompanyRecipient";
	ParametersStructure.Counterparty                       = "Object.Organization";
	ParametersStructure.Partner                          = Catalogs.Partners.OurEnterprise;
	ParametersStructure.Contract                          = "Object.Ref";
	ParametersStructure.ARAPObjectSettings                  = "Object.ARAPObjectSettings";
	ParametersStructure.Terms                       = "";
	
	// They are used to determine the value of payments in currency and in the form of editing payment rules.
	ParametersStructure.CompanyBankAccount        = "Object.BankAccountOfBeneficiary";
	ParametersStructure.CounterpartyBankAccount        = "Object.BankAccount";
	ParametersStructure.CashAccount                            = "";
	ParametersStructure.PaymentMethod                      = "";
	
	ParametersStructure.FinancialAccountingGroup           = "Object.FinancialAccountingGroupOfRecipient";
	ParametersStructure.Manager                         = "Object.Manager";
	ParametersStructure.IncomingDocumentNumber          = "Object.Number";
	ParametersStructure.IncomingDocumentDate           = "Object.Date";
	
	ParametersStructure.InfluencingAttributes = InfluencingAttributes;
	
	ParametersArray.Add(ParametersStructure);
	
	#EndRegion
	
	#Region RecipientReward
	
	If ContractType = Enums.TypesOfIntercompanyContracts.Consignment Then
	
		ParametersStructure = ARAPAccountingServer.MechanismParameters();
		
		ParametersStructure.IsCatalog                    = True;
		ParametersStructure.ItCanBeARAPObject    = ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts
		                                                       Or ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice;
		
		ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
		
		ParametersStructure.ChangesPaymentPlan = False;
		ParametersStructure.ModifiesDeliveryShipmentPlan = False;
		
		ParametersStructure.Date                             = "Object.Date"; 
		
		// Currency and amount of the transaction. The path to the object's details is required.
		ParametersStructure.DocumentCurrency                  = "Object.ARAPCurrency";
		ParametersStructure.DocumentAmount                   = "Object.Sum";
		ParametersStructure.Organization                      = "Object.CompanyRecipient";
		ParametersStructure.Counterparty                       = "Object.Organization";
		ParametersStructure.Partner                          = Catalogs.Partners.OurEnterprise;
		ParametersStructure.Contract                          = "Object.Ref";
		ParametersStructure.ARAPObjectSettings                  = "Object.ARAPObjectSettings";
		ParametersStructure.Terms                       = "";
		
		// They are used to determine the value of payments in currency and in the form of editing payment rules.
		ParametersStructure.CompanyBankAccount        = "Object.BankAccountOfBeneficiary";
		ParametersStructure.CounterpartyBankAccount        = "Object.BankAccount";
		ParametersStructure.CashAccount                            = "";
		ParametersStructure.PaymentMethod                      = "";
		
		ParametersStructure.FinancialAccountingGroup           = "Object.FinancialAccountingGroupOfRecipient";
		ParametersStructure.Manager                         = "Object.Manager";
		ParametersStructure.IncomingDocumentNumber          = "Object.Number";
		ParametersStructure.IncomingDocumentDate           = "Object.Date";
		
		ParametersStructure.InfluencingAttributes = InfluencingAttributes;
		
		ParametersArray.Add(ParametersStructure);
		
	EndIf;
	
	#EndRegion
	
	#EndRegion
	
	Return ParametersArray;
	
EndFunction

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure
// End StandardSubsystems.ObjectsVersioning

#EndRegion

#Region Private

#Region Print

// Fills in the list of print commands.
// 
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	IntercompanyContractsLocalization.AddPrintCommands(PrintCommands);
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
	
	IntercompanyContractsLocalization.AddReportCommands(ReportsCommands, Parameters);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
