#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// This function defines the default financial accounting group.
//
// Returns the financial accounting group if one element of the reference list is found.
// Returns an empty Link otherwise.
//
// Parameters:
//	Organization - CatalogRef.Companies - Organization.
//	ARAPCurrency - CatalogRef.Currencies - The currency in which settlements are made.
//	BusinessOperation - EnumRef.BusinessTransactions, Undefined - Household. operation.
//	RecipientSStateBudget - Boolean -
//
// Returns:
//	CatalogRef.FinancialAccountingGroupsOfARAP - fin group. accounting by default.
//
Function GetDefaultFinancialAccountingGroup(Organization, ARAPCurrency, BusinessOperation = Undefined, RecipientSStateBudget = False) Export
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	ARAPInCurrency = ARAPCurrency <> LocalAccountingCurrency;
	
	FilterStructure1 = New Structure("ARAPInCurrency", ARAPInCurrency);
	If ValueIsFilled(BusinessOperation) Then
		FilterStructure1.Insert("BusinessOperation", BusinessOperation);
	EndIf;
	If RecipientSStateBudget Then
		FilterStructure1.Insert("RecipientSStateBudget", True);
	EndIf;
	
	ConvertSelectionParametersSelection(FilterStructure1);
	
	Query = New Query("
	|SELECT ALLOWED TOP 2
	|	CatalogData.Ref AS FinancialAccountingGroup
	|FROM
	|	Catalog.FinancialAccountingGroupsOfARAP AS CatalogData
	|WHERE
	|	NOT CatalogData.DeletionMark
	|	AND NOT CatalogData.IsFolder
	|	AND &AdditionalSelectionConditions
	|");
	
	AdditionalSelectionConditions = "TRUE";
	SelectionElementTemplate = "AND CatalogData.%1 = &%1";
	For Each FilterElement In FilterStructure1 Do
		AdditionalSelectionConditions = AdditionalSelectionConditions + Chars.LF + Chars.Tab + StrTemplate(SelectionElementTemplate, FilterElement.Key);
		Query.SetParameter(FilterElement.Key, FilterElement.Value);
	EndDo;
	Query.Text = StrReplace(Query.Text, "&AdditionalSelectionConditions", AdditionalSelectionConditions);
	
	Selection = Query.Execute().Select();
	If Selection.Count() = 1 And Selection.Next() Then
		FinancialAccountingGroup = Selection.FinancialAccountingGroup;
	Else
		FinancialAccountingGroup = Catalogs.FinancialAccountingGroupsOfARAP.EmptyRef();
	EndIf;
	
	Return FinancialAccountingGroup;

EndFunction

// the procedure converts the selection transmitted in the selection parameters into the correct selection within the Cur hfc
//		if an agreement or Contract has been submitted, the payment procedure is taken from the data of the corresponding value;
//		If a business transaction is transferred, then the correct type of calculations for selection is selected according to the correspondence.
//
//	Parameters:
//		Filter - Structure - Parameters are analyzed.Selection in processing the receipt of selection data.
//
Procedure ConvertSelectionParametersSelection(Filter) Export
	
	FilterToDelete = New Array;
	For Each FilterValue In Filter Do
		If TypeOf(FilterValue.Value) <> Type("Boolean") And Not ValueIsFilled(FilterValue.Value) Then
			FilterToDelete.Add(FilterValue.Key);
		EndIf;
	EndDo;
	For Each SelectionKeyForDeletion In FilterToDelete Do
		Filter.Delete(SelectionKeyForDeletion);
	EndDo;
	
	#Region ARAPInCurrency
	
	ARAPObject = Undefined;
	Filter.Property("Contract", ARAPObject);
	If Not ValueIsFilled(ARAPObject) Then
		Filter.Property("Terms", ARAPObject);
	EndIf;
	
	If ValueIsFilled(ARAPObject) Then
	
		ArrayOfDetailsToReceive = New Array;
		
		If Not Filter.Property("BusinessOperation")
			And TypeOf(ARAPObject) = Type("CatalogRef.CounterpartyContracts") Then
			ArrayOfDetailsToReceive.Add("BusinessOperation");
		EndIf;
		
		If Not Filter.Property("Organization") Then
			ArrayOfDetailsToReceive.Add("Organization");
		EndIf;
		
		If Not Filter.Property("ARAPInCurrency") And Not Filter.Property("ARAPCurrency") Then
			ArrayOfDetailsToReceive.Add("ARAPCurrency");
		EndIf;
		
		AttributesStructure1 = Common.ObjectAttributesValues(ARAPObject, ArrayOfDetailsToReceive);
		For Each AttributeValue In AttributesStructure1 Do
			If ValueIsFilled(AttributeValue.Value) Then
				Filter.Insert(AttributeValue.Key, AttributeValue.Value);
			EndIf;
		EndDo;
		
	EndIf;
	
	If Not (Filter.Property("ARAPInCurrency") And TypeOf(Filter.ARAPInCurrency) = Type("Boolean"))
		And Filter.Property("Organization") Then
		LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Filter.Organization);
		ARAPCurrency = Undefined;
		Filter.Property("ARAPCurrency", ARAPCurrency);
		If Not ValueIsFilled(ARAPCurrency) Then
			Filter.Property("ARAPInCurrency", ARAPCurrency);
		EndIf;
		If ValueIsFilled(ARAPCurrency) Then
			ARAPInCurrency = ARAPCurrency <> LocalAccountingCurrency;
			If ARAPInCurrency Then
				Filter.Insert("ARAPInCurrency", True);
			Else
				Filter.Insert("ARAPAccountingInLocalAccountingCurrency", True);
			EndIf;
		EndIf;
	EndIf;
	
	If Filter.Property("ARAPInCurrency") And TypeOf(Filter.ARAPInCurrency) <> Type("Boolean") Then
		Filter.Delete("ARAPInCurrency");
	EndIf;
	
	#EndRegion
	
	#Region Calculations
	
	If Filter.Property("BusinessOperation") And ValueIsFilled(Filter.BusinessOperation) Then
		
		Operations = Enums.BusinessTransactions;
		ComplianceWithXOICalculations = New Map;
		
		// For intercompany, the type of calculations is also selected depending on whether it is the recipient's or supplier's HFC.
		RecipientSStateBudget = Filter.Property("RecipientSStateBudget") And Filter.RecipientSStateBudget;
		
		#Region BusinessOperationsOfSuppliers
		ComplianceWithXOICalculations.Insert(Operations.PurchaseFromSupplier, "VendorsARAPAccounting");
		ComplianceWithXOICalculations.Insert(Operations.PurchaseFromVendorUninvoicedDelivery, "VendorsARAPAccounting");
		ComplianceWithXOICalculations.Insert(Operations.PurchaseFromVendorReceiptFromGoodsInTransit, "VendorsARAPAccounting");
		ComplianceWithXOICalculations.Insert(Operations.PurchaseFromVendorLocal, "VendorsARAPAccounting");
		ComplianceWithXOICalculations.Insert(Operations.PurchaseFromVendorGoodsInTransit, "VendorsARAPAccounting");
		ComplianceWithXOICalculations.Insert(Operations.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt, "VendorsARAPAccounting");
		
		ComplianceWithXOICalculations.Insert(Operations.PurchaseByImport, "VendorsARAPAccounting");
		ComplianceWithXOICalculations.Insert(Operations.ImportReceiptFromGoodsInTransit, "VendorsARAPAccounting");
		ComplianceWithXOICalculations.Insert(Operations.ImportGoodsInTransit, "VendorsARAPAccounting");
		
		ComplianceWithXOICalculations.Insert(Operations.ImportFromEAEU, "VendorsARAPAccounting");
		ComplianceWithXOICalculations.Insert(Operations.ImportFromEAEUUninvoicedDelivery, "VendorsARAPAccounting");
		ComplianceWithXOICalculations.Insert(Operations.ImportFromEAEUReceiptFromGoodsInTransit, "VendorsARAPAccounting");
		ComplianceWithXOICalculations.Insert(Operations.ImportFromEAEUGoodsInTransit, "VendorsARAPAccounting");
		ComplianceWithXOICalculations.Insert(Operations.ImportFromEAEUInvoicedDelivery, "VendorsARAPAccounting");
		
		ComplianceWithXOICalculations.Insert(Operations.ReceivingForStorageWithRightOfSale, "VendorsARAPAccounting");
		ComplianceWithXOICalculations.Insert(Operations.ReturnOfGoodsToVendor, "VendorsARAPAccounting");
		#EndRegion
		
		#Region BusinessOperationsOfClients
		ComplianceWithXOICalculations.Insert(Operations.SaleToCustomer, "CustomersARAPAccounting");
		ComplianceWithXOICalculations.Insert(Operations.TollManufacturing2_5, "CustomersARAPAccounting");
		ComplianceWithXOICalculations.Insert(Operations.ReturnOfGoodsFromCustomer, "CustomersARAPAccounting");
		ComplianceWithXOICalculations.Insert(Operations.ReturnFromRetailCustomer, "CustomersARAPAccounting");
		ComplianceWithXOICalculations.Insert(Operations.SaleWithDeferredTransferOfTitle, "CustomersARAPAccounting");
		ComplianceWithXOICalculations.Insert(Operations.TransferToStorageWithRightOfSale, "CustomersARAPAccounting");
		ComplianceWithXOICalculations.Insert(Operations.SalesViaCommissionAgent, "CustomersARAPAccounting");
		#EndRegion
		
		#Region EconomicOperationsOfPayments
		ComplianceWithXOICalculations.Insert(Operations.CashReceiptFromCustomer, "CustomersARAPAccounting,CommissionAgentsARAPAccounting,PurchaseSettlementsWithConsignors");
		ComplianceWithXOICalculations.Insert(Operations.CashReceiptFromOtherCompany, "CustomersARAPAccounting,CommissionAgentsARAPAccounting,PurchaseSettlementsWithConsignors");
		ComplianceWithXOICalculations.Insert(Operations.RefundFromVendor, "VendorsARAPAccounting,ConsignorsARAPAccounting,PurchaseSettlementsWithConsignors");
		ComplianceWithXOICalculations.Insert(Operations.RefundFromAnotherCompany, "VendorsARAPAccounting,ConsignorsARAPAccounting,PurchaseSettlementsWithConsignors");
		ComplianceWithXOICalculations.Insert(Operations.PaymentToVendor, "VendorsARAPAccounting,ConsignorsARAPAccounting,PurchaseSettlementsWithConsignors");
		ComplianceWithXOICalculations.Insert(Operations.CashPaymentToAnotherCompany, "VendorsARAPAccounting,ConsignorsARAPAccounting");
		ComplianceWithXOICalculations.Insert(Operations.RefundToCustomer, "CustomersARAPAccounting,CommissionAgentsARAPAccounting,PurchaseSettlementsWithConsignors");
		ComplianceWithXOICalculations.Insert(Operations.RefundToAnotherCompany, "CustomersARAPAccounting,CommissionAgentsARAPAccounting,PurchaseSettlementsWithConsignors");
		ComplianceWithXOICalculations.Insert(Operations.TransferOfTaxesAndContributions, "VendorsARAPAccounting");
		ComplianceWithXOICalculations.Insert(Operations.CustomsPayment, "VendorsARAPAccounting");
		ComplianceWithXOICalculations.Insert(Operations.TransferToDeposits, "DebtorsARAPAccounting");
		ComplianceWithXOICalculations.Insert(Operations.PaymentOnLoansAndBorrowingsReceived, "CreditorsARAPAccounting");
		ComplianceWithXOICalculations.Insert(Operations.PaymentToLessor, "LeaseContractARAPWithLessors");
		ComplianceWithXOICalculations.Insert(Operations.CashIssueAsLoanToCounterparty, "CreditorsARAPAccounting");
		#EndRegion
		
		#Region BusinessOperationsRest
		ComplianceWithXOICalculations.Insert(Operations.TransferToCommissionAgent, "CommissionAgentsARAPAccounting");
		ComplianceWithXOICalculations.Insert(Operations.ConsignmentProcurement, "ConsignorsARAPAccounting");
		ComplianceWithXOICalculations.Insert(Operations.AgentServicesDelivery, "ConsignorsARAPAccounting");
		ComplianceWithXOICalculations.Insert(Operations.DeliveryForPrincipal, "PurchaseSettlementsWithConsignors");
		ComplianceWithXOICalculations.Insert(Operations.IntercompanyGoodsReturn, ?(RecipientSStateBudget, "CustomersARAPAccounting", "VendorsARAPAccounting"));
		ComplianceWithXOICalculations.Insert(Operations.GoodsSaleToAnotherCompany, ?(RecipientSStateBudget, "VendorsARAPAccounting", "CustomersARAPAccounting"));
		ComplianceWithXOICalculations.Insert(Operations.ConsumptionReportSubcontractingServicesDeliveredIntercompany, ?(RecipientSStateBudget, "VendorsARAPAccounting", "CustomersARAPAccounting"));
		ComplianceWithXOICalculations.Insert(Operations.TransferOfGoodsToCommissionAgentInAnotherCompany, ?(RecipientSStateBudget, "ConsignorsARAPAccounting", "CommissionAgentsARAPAccounting"));
		ComplianceWithXOICalculations.Insert(Operations.PurchaseFromAnotherCompany, ?(RecipientSStateBudget, "VendorsARAPAccounting", "CustomersARAPAccounting"));
		ComplianceWithXOICalculations.Insert(Operations.ProductionByToller2_5, "SettlementsWithSubcontractor");
		ComplianceWithXOICalculations.Insert(Operations.ProductionAtProcessorInEAEUCountries2_5, "SettlementsWithSubcontractor");
		ComplianceWithXOICalculations.Insert(Operations.TransferToToller2_5, "SettlementsWithSubcontractor");
		ComplianceWithXOICalculations.Insert(Operations.BookingViaAgent, "BookingARAPAccounting");
		ComplianceWithXOICalculations.Insert(Operations.BookingViaAdvanceHolder, "BookingARAPAccounting");
		ComplianceWithXOICalculations.Insert(Operations.BookingFromVendor, "BookingARAPAccounting");
		ComplianceWithXOICalculations.Insert(Operations.TollManufacturing2_5, "ProvidersARAP");
		ComplianceWithXOICalculations.Insert(Operations.TransferToMaterialProvider2_5, "ProvidersARAP");
		#EndRegion
		
		// For loan/deposit agreements and between organizations, instead of HO, we transfer the nature or type of the agreement, respectively:
		ComplianceWithXOICalculations.Insert(Enums.ContractKindsOfFinancialInstruments.LoanOrBorrowing, "CreditorsARAPAccounting");
		ComplianceWithXOICalculations.Insert(Enums.ContractKindsOfFinancialInstruments.IssuedBorrowing, "DebtorsARAPAccounting");
		ComplianceWithXOICalculations.Insert(Enums.ContractKindsOfFinancialInstruments.Deposit, "DebtorsARAPAccounting");
		ComplianceWithXOICalculations.Insert(Enums.TypesOfIntercompanyContracts.PurchaseAndSale, ?(RecipientSStateBudget, "VendorsARAPAccounting", "CustomersARAPAccounting"));
		ComplianceWithXOICalculations.Insert(Enums.TypesOfIntercompanyContracts.Consignment, ?(RecipientSStateBudget, "ConsignorsARAPAccounting", "CommissionAgentsARAPAccounting"));
		
		ValueOfCalculations = ComplianceWithXOICalculations.Get(Filter.BusinessOperation);
		If ValueOfCalculations <> Undefined Then
			ArrayOfPossibleCalculations = StrSplit(ValueOfCalculations, ",");
			If ArrayOfPossibleCalculations.Count() = 1 Then
				Filter.Insert(ArrayOfPossibleCalculations.Get(0), True);
			Else
				For Each ARAPType In TypesOfCalculations() Do
					If ArrayOfPossibleCalculations.Find(ARAPType) = Undefined Then
						Filter.Insert(ARAPType, False);
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		
		Filter.Delete("BusinessOperation");
		
	EndIf;
	
	If Filter.Property("RecipientSStateBudget") Then
		Filter.Delete("RecipientSStateBudget");
	EndIf;
	
	#EndRegion
		
EndProcedure

#Region InterfaceImplementation

// Fills in the details of the expense account settings that affect the setup
// 	with the corresponding names of the accounting Analytics details.
//
// Parameters:
// 	MatchingNames - Map - the key is the name of the account that is used in setting up accounting accounts
// 		. the value is the corresponding name of the accounting Analytics account.
// 
Procedure FillInMatchingAccountSettingsDetails(MatchingNames) Export
	
	MatchingNames.CustomersARAPAccounting = "CustomersARAPAccounting";
	MatchingNames.VendorsARAPAccounting = "VendorsARAPAccounting";
	MatchingNames.CommissionAgentsARAPAccounting = "CommissionAgentsARAPAccounting";
	MatchingNames.ConsignorsARAPAccounting = "ConsignorsARAPAccounting";
	MatchingNames.PurchaseSettlementsWithConsignors = "PurchaseSettlementsWithConsignors";
	MatchingNames.SettlementsWithSubcontractor = "SettlementsWithSubcontractor";
	MatchingNames.ProvidersARAP = "ProvidersARAP";
	MatchingNames.CreditorsARAPAccounting = "CreditorsARAPAccounting";
	MatchingNames.DebtorsARAPAccounting = "DebtorsARAPAccounting";
	MatchingNames.LeaseContractARAPWithLessors = "LeaseContractARAPWithLessors";
	MatchingNames.ARAPInCurrency = "ARAPInCurrency";
	MatchingNames.BookingARAPAccounting = "BookingARAPAccounting";
	
EndProcedure
#EndRegion

#EndRegion

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	TMCommonUse.ProcessingOfObtainingDataForSelectingFinancialAccountingCalculationGroup(ChoiceData, Parameters, StandardProcessing);
	
	NationalLanguageSupportServer.ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing, Metadata.Catalogs.FinancialAccountingGroupsOfARAP);
	
EndProcedure

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	NationalLanguageSupportClientServer.PresentationFieldsGetProcessing(Fields, StandardProcessing);
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	NationalLanguageSupportClientServer.PresentationGetProcessing(Data, Presentation, StandardProcessing);
	
EndProcedure

#EndRegion

#Region Private

Function TypesOfCalculations() Export
	
	CommissionBetweenOrganizations = ?(GetFunctionalOption("UseCustomerInvoiceIntercompany"),
		TMCommonUseCached.UseMethodForTransferringGoodsBetweenOrganizations(
			Enums.GoodsTransferMethods.TransferToCommissionAgent), False);
	
	TypesOfCalculations = New Array;
	TypesOfCalculations.Add("CustomersARAPAccounting");
	TypesOfCalculations.Add("VendorsARAPAccounting");
	If GetFunctionalOption("UseSalesCommission") Or CommissionBetweenOrganizations Then
		TypesOfCalculations.Add("CommissionAgentsARAPAccounting");
	EndIf;
	If GetFunctionalOption("UsePurchaseCommission") Or CommissionBetweenOrganizations Then
		TypesOfCalculations.Add("ConsignorsARAPAccounting");
	EndIf;
	If GetFunctionalOption("ProvideAgentServicesOnPurchaseToPrincipals") Then
		TypesOfCalculations.Add("PurchaseSettlementsWithConsignors");
	EndIf;
	If GetFunctionalOption("UseLoanAndDepositContracts") Then
		TypesOfCalculations.Add("CreditorsARAPAccounting");
		TypesOfCalculations.Add("DebtorsARAPAccounting");
	EndIf;
	If GetFunctionalOption("UseProductionByThirdParty2_5") Then
		TypesOfCalculations.Add("SettlementsWithSubcontractor");
	EndIf;
	If NonCurrentAssets.VNAManagementIsUsed() Then
		TypesOfCalculations.Add("LeaseContractARAPWithLessors");
	EndIf;
	If GetFunctionalOption("UseTollManufacturing2_5") Then
		TypesOfCalculations.Add("ProvidersARAP");
	EndIf;
	TypesOfCalculations.Add("BookingARAPAccounting");
	
	Return TypesOfCalculations;
	
EndFunction

#Region InfobaseUpdate

Procedure CreateHFCForBookingCalculations() Export
	
	Query = New Query;
	Query.Text = "
	|SELECT TOP 1
	|	1
	|FROM
	|	Catalog.FinancialAccountingGroupsOfARAP
	|WHERE
	|	BookingARAPAccounting
	|";
	
	If Query.Execute().IsEmpty() Then
		
		BeginTransaction();
		
		Try
			
			CatalogObject = CreateItem();
			CatalogObject.BookingARAPAccounting = True;
			CatalogObject.Description = NStr("vi = 'Hạch toán với bên vận chuyển về vé điện tử';
											|ru = 'Расчеты с перевозчиками по электронным билетам';
											|en = 'AR/AP accounting with carriers by electronic tickets'; fa = 'AR/AP accounting with carriers by electronic tickets';
											|it = 'Calcoli con i vettori per biglietti elettronici';
											|pl = 'Rozliczenia z przewoźnikami według biletów elektronicznych';
											|tr = 'Elektron biletlere ilişkin taşıyıcılar ile hesaplar'");
			
			InfobaseUpdate.WriteObject(CatalogObject);
			
			
			CommitTransaction();
			
		Except
			RollbackTransaction();
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), EmptyRef());
		EndTry;
	EndIf;
	
EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Catalogs.FinancialAccountingGroupsOfARAP.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.24.25";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("c4a2aeae-bb17-4ccd-b131-aee7c2ad0578");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Catalogs.FinancialAccountingGroupsOfARAP.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Cập nhật danh mục ""Nhóm tùy chỉnh kế toán tài chính hạch toán công nợ"":';
								|ru = 'Обновление справочника ""Группы настроек фин. учета расчетов"":';
								|en = 'Update the ""AR/AP accounting groups"" catalog:'; fa = 'Update the ""AR/AP accounting groups"" catalog:';
								|it = 'Update the ""AR/AP accounting groups"" catalog:';
								|pl = 'Update the ""AR/AP accounting groups"" catalog:';
								|tr = '""Alacak/Borç hesabı master verileri"" kataloğunun güncellenmesi:'"));
	ListOfDescriptions.Add(NStr("vi = '- Điền mục tin đa ngôn ngữ của danh mục';
								|ru = '- Заполнение мультиязычных реквизитов справочника';
								|en = '- Fill multilingual catalog attributes'; fa = '- Fill multilingual catalog attributes';
								|it = '- Fill multilingual catalog attributes';
								|pl = '- Fill multilingual catalog attributes';
								|tr = '- Kataloğun çok dilli özniteliklerinin doldurulması'"));
	
	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Catalogs.FinancialAccountingGroupsOfARAP.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Catalogs.FinancialAccountingGroupsOfARAP.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Catalogs.FinancialAccountingGroupsOfARAP.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");

EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = EmptyRef().Metadata().FullName();
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	
	AdditionalLanguagesAreUsed = False;
	For Each AdditionalLanguageIsUsed In NationalLanguageSupportServer.LanguagesInfo().Used Do
		
		If AdditionalLanguageIsUsed.Value = True Then
			
			AdditionalLanguagesAreUsed = True;
			Break;
			
		EndIf;
		
	EndDo;
	
	If Not AdditionalLanguagesAreUsed Then
		
		Return;
		
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	FinancialAccountingGroupsOfARAP.Ref AS Ref
	|FROM
	|	Catalog.FinancialAccountingGroupsOfARAP AS FinancialAccountingGroupsOfARAP
	|WHERE
	|	NOT FinancialAccountingGroupsOfARAP.Description = """"
	|	AND FinancialAccountingGroupsOfARAP.DescriptionLanguage1 = """"
	|	
	|UNION 
	|
	|SELECT
	|	FinancialAccountingGroupsOfARAP.Ref AS Ref
	|FROM
	|	Catalog.FinancialAccountingGroupsOfARAP AS FinancialAccountingGroupsOfARAP
	|WHERE
	|	NOT FinancialAccountingGroupsOfARAP.Description = """"
	|	AND FinancialAccountingGroupsOfARAP.DescriptionLanguage2 = """"
	|";
	
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

// The update handler
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters 
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	Parameters.ProcessingCompleted = False;
	
	FullObjectName = EmptyRef().Metadata().FullName();
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		
		Parameters.ProcessingCompleted =
			InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
		Return;
		
	EndIf;
	
	ObjectsProcessed = 0;
	ObjectsWithIssuesCount = 0;
	ExceptionsWhenUpdating = New Array;
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Không thể xử lý danh mục ""Nhóm tùy chỉnh kế toán tài chính hạch toán công nợ"" theo hàm sự kiện:';
								|ru = 'Не удалось обработать справочник ""Группы настроек фин. учета расчетов"" по обработчику:';
								|en = 'Cannot process the ""AR/AP accounting groups"" catalog by the handler:'; fa = 'Cannot process the ""AR/AP accounting groups"" catalog by the handler:';
								|it = 'Cannot process the ""AR/AP accounting groups"" catalog by the handler:';
								|pl = 'Cannot process the ""AR/AP accounting groups"" catalog by the handler:';
								|tr = 'İşleyici tarafından ""Alacak/Borç hesabı master verileri"" kataloğu işlenemedi:'"));
	ListOfDescriptions.Add(NStr("vi = '- Điền mục tin đa ngôn ngữ của danh mục';
								|ru = '- Заполнение мультиязычных реквизитов справочника';
								|en = '- Fill multilingual catalog attributes'; fa = '- Fill multilingual catalog attributes';
								|it = '- Fill multilingual catalog attributes';
								|pl = '- Fill multilingual catalog attributes';
								|tr = '- Kataloğun çok dilli özniteliklerinin doldurulması'"));
	Query = New Query;
	Query.Text = 
	"SELECT
	|	DataForUpdate.Ref AS Ref
	|INTO TT
	|FROM
	|	&DataForUpdate AS DataForUpdate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT.Ref AS Ref,
	|	FinancialAccountingGroupsOfARAP.DataVersion AS DataVersion
	|FROM
	|	TT AS TT
	|		LEFT JOIN Catalog.FinancialAccountingGroupsOfARAP AS FinancialAccountingGroupsOfARAP
	|		ON TT.Ref = FinancialAccountingGroupsOfARAP.Ref";
	
	Query.SetParameter("DataForUpdate", UpdatedData);
	
	Catalog = Query.Execute().Select();
	
	While Catalog.Next() Do
		
		ExceptionReason = 0;
		Recommendation = "";
		
		BeginTransaction();
		
		Try
			
			ExceptionReason = 1; // IObjectLock
			
			Block = New DataLock;
			
			LockItem = Block.Add(FullObjectName);
			LockItem.SetValue("Ref", Catalog.Ref);
			LockItem.Mode = DataLockMode.Exclusive;
			
			Block.Lock();
			
			CatalogObject = InfobaseUpdateTM.CheckGetObject(
				Catalog.Ref, Catalog.DataVersion, Parameters.Queue); // CatalogObject
			
			ExceptionReason = 2; // BadData
			Recommendation = NStr("vi = 'Hãy kiểm tra thủ công dữ liệu danh mục.';
									|ru = 'Проверьте данные справочника вручную.';
									|en = 'Check the catalog data manually.'; fa = 'Check the catalog data manually.';
									|it = 'Проверьте данные справочника вручную.';
									|pl = 'Check the catalog data manually.';
									|tr = 'Dizin verilerini manuel olarak kontrol edin.'");
			
			ObjectModified = False;
			
			If CatalogObject <> Undefined Then
				
				If Not ValueIsFilled(CatalogObject.DescriptionLanguage1) Then
					
					CatalogObject.DescriptionLanguage1 = CatalogObject.Description;
					
				EndIf;
				
				If Not ValueIsFilled(CatalogObject.DescriptionLanguage2) Then
					
					CatalogObject.DescriptionLanguage2 = CatalogObject.Description;
					
				EndIf;
				
				ObjectModified = True;
				
			EndIf;
			
			ExceptionReason = 3; // Record
			
			If ObjectModified Then
				InfobaseUpdate.WriteData(CatalogObject);
			Else
				InfobaseUpdate.MarkProcessingCompletion(Catalog.Ref);
			EndIf;
			
			ObjectsProcessed = ObjectsProcessed + 1;
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Catalog.Ref);
			
			If ExceptionReason = 2 Then
				
				IssueDetails = InfobaseUpdateTM.DataProblem(
					Catalog.Ref, Recommendation, ErrorInfo());
				ExceptionsWhenUpdating.Add(IssueDetails);
				
			ElsIf ExceptionReason = 3 Then
				
				InfobaseUpdateTM.RecordBadData(
					ExceptionsWhenUpdating, ObjectsProcessed, Parameters);
				Raise StrConcat(ListOfDescriptions, Chars.LF);
				
			EndIf;
			
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted =
		InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
