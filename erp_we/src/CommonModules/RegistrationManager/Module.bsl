// Registration Registration Rules for ERP 2.5.26 (ED 1.22) dated 05/26/2026 14:53:46
#Region Internal

// Returns the registration view.
// Returns:
//  String
Function RulesInformation() Export

	Parameters = RegistrationParameters();
	TextTemplate1 = NStr("vi = 'Quy tắc ghi nhận đối tượng của cơ sở thông tin này (%1 phiên bản %2) từ %3';
						|ru = 'Правила регистрации объектов этой информационной базы (%1 версия %2) от %3';
						|en = 'Registration rules of objects of this infobase (%1 version %2) from %3'; fa = 'Registration rules of objects of this infobase (%1 version %2) from %3';
						|it = 'Regole di registrazione degli oggetti di questa infobase (%1 versione %2) di %3';
						|pl = 'Zasady rejestracji obiektów tej bazy informacyjnej (%1 wersja %2) z dn. %3';
						|tr = 'Bu infobase''deki nesneleri kaydetme kuralları (%1 sürüm %2) %3''ten'");
	
	Return StringFunctions.FormattedString(TextTemplate1, 
		Parameters.ConfigurationSynonym, Parameters.ConfigurationVersion, Parameters.CreationDateTime);	
	
EndFunction

// Returns key registration parameters in the form of a structure.
// Returns:
//  Structure
Function RegistrationParameters() Export
	Result = New Structure();
	Description = NStr("ru = 'Правила регистрации для ERP 2.5.26 (ED 1.22)';
						|vi = 'Registration rules for ERP 2.5.26 (ED 1.22)';
						|en = 'Registration rules for ERP 2.5.26 (ED 1.22)'; fa = 'Registration rules for ERP 2.5.26 (ED 1.22)';
						|it = 'Registration rules for ERP 2.5.26 (ED 1.22)';
						|pl = 'Registration rules for ERP 2.5.26 (ED 1.22)';
						|tr = 'ERP 2.5.26 (ED 1.22) için kayıt kuralları'");
	Result.Insert("Description", Description);
	Result.Insert("CreationDateTime", Date(2026,5,26,14,53,0));
	Result.Insert("ExchangePlan_", "DataSynchronizationViaUniversalFormat");
	Result.Insert("Configuration", "EnterpriseManagement");
	ConfigurationSynonym = "1From1:ERP Management_ by_enterprise 2";
	TextSynonymForConfiguration = NStr("vi = '%1';
										|ru = '%1';
										|en = '%1'; fa = '%1';
										|it = '%1';
										|pl = '%1';
										|tr = '%1'");
	TextSynonymForConfiguration = StringFunctionsClientServer.SubstituteParametersToString(TextSynonymForConfiguration, ConfigurationSynonym);
	Result.Insert("ConfigurationSynonym", TextSynonymForConfiguration);
	Result.Insert("ConfigurationVersion", "2.5.25.51");

	Return Result;
EndFunction

// Fills in the table of object registration rules.
//
// Parameters:
//  ObjectsRegistrationRules - ValueTable - the table of values to which the rules are added
//  RegistrationManagerName - String - Name of the Object Registration Rules Manager module 
Procedure InitializingRegistrationRules(ObjectsRegistrationRules, RegistrationManagerName) Export
	If ObjectsRegistrationRules.Columns.Find("Id") = Undefined Then
		ObjectsRegistrationRules.Columns.Add("Id");
	EndIf;
	AddPRO_Document_EnterBalances(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_EnterSettlementBalances(ObjectsRegistrationRules, RegistrationManagerName);
	
	AddPRO_Document_EnterCashBalances(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_EnterBalancesOnFinancialInstruments(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_EnterBalancesWithAccountablePersons(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_EnterProductBalances(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_ReturnOfGoodsToSupplier(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_OrderToSupplier(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_PurchaseAdjustment(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_PurchaseOfGoodsAndServices(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_PurchaseOfServicesOtherAssets(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_CustomsDeclarationImport(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_EmployeeDevelopment(ObjectsRegistrationRules, RegistrationManagerName);
	
	
	
	AddPRO_Document_ReturnOfGoodsBetweenOrganizations(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_ReportOnCommissionBetweenOrganizations(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_ReportOnCommissionBetweenOrganizationsOnWriteOffs(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_TransferOfGoodsBetweenOrganizations(ObjectsRegistrationRules, RegistrationManagerName);
	
	
	
	
	
	
	
	
	AddPRO_Document_DebtOffset(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_DebtOffset2(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_DebtOffset3(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_DepositingFundsToCashRegister(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_WithdrawalOfFundsFromCashRegisterOfCashRegister(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_PaymentCardOperation(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_ReportOfBankOnAcquiringOperations(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_ReportOfBankOnAcquiringOperations2(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_ReceiptOfNonCashFunds(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_CashReceiptOrder(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_SpendingCashOrder(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_DebitingNonCashFunds(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_CashReceiptOrder2(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_SpendingCashOrder2(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_AdvanceReport(ObjectsRegistrationRules, RegistrationManagerName);
	
	AddPRO_Document_RequestForSpendingFunds(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_AccrualOfLoansAndDeposits(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_PrimaryDocument(ObjectsRegistrationRules, RegistrationManagerName);
	
	AddPRO_Document_DebtAdjustment(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_ReportOfCompletedWorks(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_ReturnOfGoodsFromCustomer(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_CustomerOrder(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_ImplementationAdjustment(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_CommissionAgentSReport(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_CommissionAgentSReportOnDebiting(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_ReportToCommittee(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_ReportToCommitteeOnWriteOffs(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_SalesOfGoodsAndServices(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_SaleOfServicesOtherAssets(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_InvoiceForPaymentToClient(ObjectsRegistrationRules, RegistrationManagerName);
	
	
	
	
	AddPRO_Document_ReceiptOfGoodsFromCustodian(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_TransferOfGoodsToCustodian(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_ProcessorReport2_5(ObjectsRegistrationRules, RegistrationManagerName);
	
	
	
	
	AddPRO_Document_ReportToGiver2_5(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_AcceptanceOfGoodsForStorage(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_ShipmentOfGoodsFromStorage(ObjectsRegistrationRules, RegistrationManagerName);
	
	
	AddPRO_Document_ProductAndMaterialMovement(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_ProductionWithoutOrder(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_RevokingGiftCertificates(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_ReturnGiftCertificates(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_CashShift(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_RetailSalesReport(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_ImplementingGiftCertificates(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_RetailReturnsReport(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_InternalConsumption(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_RedemptionOfGoodsAcceptedForStorage(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_MovingOrder(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_RegisteringSurplusGoods(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_MovingGoods(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_ResortmentOfProducts(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_RecalculationOfGoods(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_OtherProductRegistration(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_ProductAssembly(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_WriteOff(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_WriteOffShortageOfGoods(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_ReportOnWriteOffOfGoodsFromStorage(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_PhysicalInventoryCountOfInventoryItemsInOperation(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_InvoiceAdvancePayment(ObjectsRegistrationRules, RegistrationManagerName);
	
	
	AddPRO_Document_InvoiceReceivedAdvance(ObjectsRegistrationRules, RegistrationManagerName);
	
	
	
	AddPRO_Document_SettingProductPrices(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_DocumentOfOperationWithElectronicTicket(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_BusinessTripRequest(ObjectsRegistrationRules, RegistrationManagerName);
	
	
	AddPRO_Document_ApplicationForImportOfGoods(ObjectsRegistrationRules, RegistrationManagerName);
	
	AddPRO_Document_Storno(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Document_ShipmentOfGoodsToCustomer(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_PLANOfTypesOfCharacteristics_IncomeItems(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_PLANOfTypesOfCharacteristics_ItemsOfExpenditure(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_InformationRegister_ClarificationOfInventoryOwnershipOfRetailOutlets(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_InformationRegister_DocumentsOfIndividuals(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_InformationRegister_AvailabilityOfProductsForExternalUsers(ObjectsRegistrationRules, RegistrationManagerName);
	
	
	AddPRO_InformationRegister_StateOfCustomerOrders(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_InformationRegister_FullNameOfPersons(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_InformationRegister_ProductBarcodes(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_InformationRegister_SegmentItem(ObjectsRegistrationRules, RegistrationManagerName);
	
	
	
	AddPRO_Catalog_Currency(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Catalog_BankClassifier(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Catalog_CountriesOfWorld(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Catalog__UnitsOfMeasurement(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Catalog_FuelTaxClassifier(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Catalog__UnitsOfMeasurement2(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Catalog_IntangibleAssets(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Catalog_ObjectsOfOperation(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Catalog_CounterpartyBankAccounts(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Catalog_LoanAndDepositAgreements(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Catalog_CounterpartyAgreements(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Catalog_Counterparties(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Catalog_ContractsBetweenOrganizations(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Catalog_Partners(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Catalog_AcquiringContracts(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Catalog_Counterparties2(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Catalog_ProductConfigurationOptions(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Catalog_TypesOfProducts(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Catalog_Brands(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Catalog_Products(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Catalog_CounterpartyProducts(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Catalog_CCDNumbers(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Catalog_ProductsAttachedFiles(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Catalog_SeriesProducts(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Catalog_ProductCharacteristics(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Catalog_PriceGroups(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Catalog_TypesOfProducts2(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Catalog_SeriesProducts2(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Catalog_ProductCharacteristics2(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Catalog_Products2(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Catalog_BonusLoyaltyPrograms(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Catalog_TypesOfGiftCertificates(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Catalog_EmployeeTypesOfWork(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Catalog_TypesOfPrices(ObjectsRegistrationRules, RegistrationManagerName);
	
	AddPRO_Catalog_LoyaltyCards(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Catalog_Users(ObjectsRegistrationRules, RegistrationManagerName);
	
	AddPRO_Catalog_Individuals(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Catalog_AcquiringTerminals(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Catalog_Reserves(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Catalog_Warehouses(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Catalog_Warehouses2(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Catalog_BankAccountsOfOrganizations(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Catalog_CashAccounts(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Catalog_CashRegister(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Catalog_ResponsiblePersonsOfOrganizations(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Catalog_ResponsiblePersonsOfOrganizations2(ObjectsRegistrationRules, RegistrationManagerName);
	
	AddPRO_Catalog_CompanyStructure(ObjectsRegistrationRules, RegistrationManagerName);
	
	
	AddPRO_Catalog_Organizations(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Catalog_AnalyticalAccountingGroupsForProducts(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Catalog_FinancialAccountingGroupsProducts(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Catalog_FinancialAccountingAndSettlementGroups(ObjectsRegistrationRules, RegistrationManagerName);
	
	AddPRO_Catalog_CashFlowItems(ObjectsRegistrationRules, RegistrationManagerName);
	
	AddPRO_Catalog_ContactPersonsForPartners(ObjectsRegistrationRules, RegistrationManagerName);
	AddPRO_Catalog_ItemSegments(ObjectsRegistrationRules, RegistrationManagerName);
	
EndProcedure

// Event handler before processing the registration rule 
// Parameters:
//  ORR - ValueTableRow - Object registration rule
//  Cancel - Boolean - Refusal to comply with the registration rule.
//  Object - ConstantValueManager
//         - CatalogObject
//         - DocumentObject
//         - ChartOfCharacteristicTypesObject
//         - ChartOfAccountsObject
//         - ChartOfCalculationTypesObject
//         - BusinessProcessObject
//         - TaskObject
//         - InformationRegisterRecordSet
//         - AccumulationRegisterRecordSet
//         - AccountingRegisterRecordSet
//         - CalculationRegisterRecordSet - the object for which the registration rule is executed.
//  MetadataObject - MetadataObject - The metadata object corresponding to the object.
//  Upload0 - Boolean - the context of the registration rule execution, if True, the object is unloaded.
Procedure BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0) Export
	If ORR.Id = "Document_PurchaseOrder" Then 
		ORR_Document_PurchaseOrder_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0);
	
	ElsIf ORR.Id = "Document_VendorInvoice" Then 
		ORR_Document_VendorInvoice_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0);
	ElsIf ORR.Id = "Document_ARAPSettlement" Then 
		ORR_Document_ARAPSettlement_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0);
	ElsIf ORR.Id = "Document_ARAPSettlement2" Then 
		ORR_Document_ARAPSettlement2_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0);
	ElsIf ORR.Id = "Document_ARAPSettlement3" Then 
		ORR_Document_ARAPSettlement3_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0);
	ElsIf ORR.Id = "Document_ReturnOfGoodsFromCustomer" Then 
		ORR_Document_ReturnOfGoodsFromCustomer_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0);
	ElsIf ORR.Id = "Document_SalesOrder" Then 
		ORR_Document_SalesOrder_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0);
	ElsIf ORR.Id = "Document_SaleAdjustment" Then 
		ORR_Document_SaleAdjustment_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0);
	ElsIf ORR.Id = "Document_BackflushProduction" Then 
		ORR_Document_BackflushProduction_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0);
	ElsIf ORR.Id = "Document_GiftCertificateSale" Then 
		ORR_Document_GiftCertificateSale_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0);
	ElsIf ORR.Id = "Document_RetailReturnsReport" Then 
		ORR_Document_RetailReturnsReport_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0);
	ElsIf ORR.Id = "Document_AssemblyFromComponents" Then 
		ORR_Document_AssemblyFromComponents_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0);
	ElsIf ORR.Id = "Document_Decomissioning" Then 
		ORR_Document_Decomissioning_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0);
	ElsIf ORR.Id = "Document_ReportOnVMIAdjustment" Then 
		ORR_Document_ReportOnVMIAdjustment_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0);
	ElsIf ORR.Id = "Document_PhysicalCountOfInventoryInOperation" Then 
		ORR_Document_PhysicalCountOfInventoryInOperation_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0);
	ElsIf ORR.Id = "Document_IssuedTaxInvoicePrepayment" Then 
		ORR_Document_IssuedTaxInvoicePrepayment_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0);
	
	ElsIf ORR.Id = "Document_ReceivedTaxInvoicePrepayment" Then 
		ORR_Document_ReceivedTaxInvoicePrepayment_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0);
	ElsIf ORR.Id = "Document_ReversingEntry" Then 
		ORR_Document_ReversingEntry_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0);
	ElsIf ORR.Id = "InformationRegister_DocumentsPersons" Then 
		ORR_InformationRegister_DocumentsPersons_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0);
	ElsIf ORR.Id = "InformationRegister_GoodsAvailabilityForExternalUsers" Then 
		ORR_InformationRegister_GoodsAvailabilityForExternalUsers_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0);
	
	
	ElsIf ORR.Id = "InformationRegister_FullNameOfPersons" Then 
		ORR_InformationRegister_FullNameOfPersons_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0);
	ElsIf ORR.Id = "Catalog_PackagesAndUnitsOfMeasure" Then 
		ORR_Catalog_PackagesAndUnitsOfMeasure_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0);
	ElsIf ORR.Id = "Catalog_PackagesAndUnitsOfMeasure2" Then 
		ORR_Catalog_PackagesAndUnitsOfMeasure2_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0);
	ElsIf ORR.Id = "Catalog_IntangibleAssets" Then 
		ORR_Catalog_IntangibleAssets_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0);
	ElsIf ORR.Id = "Catalog_Assets" Then 
		ORR_Catalog_Assets_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0);
	ElsIf ORR.Id = "Catalog_Partners" Then 
		ORR_Catalog_Partners_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0);
	
	EndIf;
EndProcedure

// Event handler for processing the registration rule
// Parameters:
//  Cancel - Boolean - Refusal to comply with the registration rule.
//  ORR - ValueTableRow - Object registration rule
//  Object - ConstantValueManager
//         - CatalogObject
//         - DocumentObject
//         - ChartOfCharacteristicTypesObject
//         - ChartOfAccountsObject
//         - ChartOfCalculationTypesObject
//         - BusinessProcessObject
//         - TaskObject
//         - InformationRegisterRecordSet
//         - AccumulationRegisterRecordSet
//         - AccountingRegisterRecordSet
//         - CalculationRegisterRecordSet - the object for which the registration rule is executed.
//  QueryText - String - the text of the request to identify the recipient nodes.
//  QueryOptions - Structure - request parameters for determining recipient nodes.
//  UseCache - Boolean - using the platform mechanism of reusable values.
//  Upload0 - Boolean - the context of the registration rule execution, if True, the object is unloaded. 
//  AdditionalProperties - Structure
Procedure OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties) Export
	If ORR.Id = "Document_OBEntry" Then 
		ORR_Document_OBEntry_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_OBEntryARAP" Then 
		ORR_Document_OBEntryARAP_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_OBEntryCash" Then 
		ORR_Document_OBEntryCash_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_OBEntryFinancialInstruments" Then 
		ORR_Document_OBEntryFinancialInstruments_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_OBEntryARAPAdvanceHolders" Then 
		ORR_Document_OBEntryARAPAdvanceHolders_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_OBEntryGoods" Then 
		ORR_Document_OBEntryGoods_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_ReturnOfGoodsToVendor" Then 
		ORR_Document_ReturnOfGoodsToVendor_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_PurchaseOrder" Then 
		ORR_Document_PurchaseOrder_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_PurchaseAdjustment" Then 
		ORR_Document_PurchaseAdjustment_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_VendorInvoice" Then 
		ORR_Document_VendorInvoice_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_VendorInvoiceServicesAndAssets" Then 
		ORR_Document_VendorInvoiceServicesAndAssets_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_CCDImport" Then 
		ORR_Document_CCDImport_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_WorkOutput" Then 
		ORR_Document_WorkOutput_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	
	
	
	
	
	ElsIf ORR.Id = "Document_IntercompanyGoodsReturn" Then 
		ORR_Document_IntercompanyGoodsReturn_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_CommissionReportIntercompany" Then 
		ORR_Document_CommissionReportIntercompany_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_CommissionWriteOffReportIntercompany" Then 
		ORR_Document_CommissionWriteOffReportIntercompany_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_CustomerInvoiceIntercompany" Then 
		ORR_Document_CustomerInvoiceIntercompany_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	ElsIf ORR.Id = "Document_ARAPSettlement" Then 
		ORR_Document_ARAPSettlement_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_ARAPSettlement2" Then 
		ORR_Document_ARAPSettlement2_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_ARAPSettlement3" Then 
		ORR_Document_ARAPSettlement3_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_DepositCashIntoCashRegister" Then 
		ORR_Document_DepositCashIntoCashRegister_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_CashWithdrawalFromCashRegister" Then 
		ORR_Document_CashWithdrawalFromCashRegister_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_PaymentCardTransaction" Then 
		ORR_Document_PaymentCardTransaction_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_BankReportOnAcquiringTransactions" Then 
		ORR_Document_BankReportOnAcquiringTransactions_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_BankReportOnAcquiringTransactions2" Then 
		ORR_Document_BankReportOnAcquiringTransactions2_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_BankAccountReceiptNote" Then 
		ORR_Document_BankAccountReceiptNote_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_CashAccountReceiptNote" Then 
		ORR_Document_CashAccountReceiptNote_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_CashVoucher" Then 
		ORR_Document_CashVoucher_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_BankAccountIssue" Then 
		ORR_Document_BankAccountIssue_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_CashAccountReceiptNote2" Then 
		ORR_Document_CashAccountReceiptNote2_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_CashVoucher2" Then 
		ORR_Document_CashVoucher2_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_ExpenseReport" Then 
		ORR_Document_ExpenseReport_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	
	ElsIf ORR.Id = "Document_PaymentRequest" Then 
		ORR_Document_PaymentRequest_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_LoanAndDepositInterestCharge" Then 
		ORR_Document_LoanAndDepositInterestCharge_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_SourceDocument" Then 
		ORR_Document_SourceDocument_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	
	ElsIf ORR.Id = "Document_ARAPAdjustment" Then 
		ORR_Document_ARAPAdjustment_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_CustomerInvoiceServices" Then 
		ORR_Document_CustomerInvoiceServices_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_ReturnOfGoodsFromCustomer" Then 
		ORR_Document_ReturnOfGoodsFromCustomer_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_SalesOrder" Then 
		ORR_Document_SalesOrder_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_SaleAdjustment" Then 
		ORR_Document_SaleAdjustment_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_ConsignmentReportFromCustomer" Then 
		ORR_Document_ConsignmentReportFromCustomer_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_WriteOffReportFromCommissionAgent" Then 
		ORR_Document_WriteOffReportFromCommissionAgent_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_ConsignmentReportToVendor" Then 
		ORR_Document_ConsignmentReportToVendor_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_PurchaseInvoiceConsignmentStockLost" Then 
		ORR_Document_PurchaseInvoiceConsignmentStockLost_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_CustomerInvoice" Then 
		ORR_Document_CustomerInvoice_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_CustomerInvoiceServicesAndAssets" Then 
		ORR_Document_CustomerInvoiceServicesAndAssets_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_CustomerCommercialInvoice" Then 
		ORR_Document_CustomerCommercialInvoice_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	
	
	
	
	
	
	
	ElsIf ORR.Id = "Document_ReceiptOfGoodsFromCustodian" Then 
		ORR_Document_ReceiptOfGoodsFromCustodian_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_TransferOfGoodsToBailee" Then 
		ORR_Document_TransferOfGoodsToBailee_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_SubcontractorReport2_5" Then 
		ORR_Document_SubcontractorReport2_5_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	
	
	
	
	
	
	
	
	ElsIf ORR.Id = "Document_ReportToMaterialProvider2_5" Then 
		ORR_Document_ReportToMaterialProvider2_5_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_GoodsReceiptForStorage" Then 
		ORR_Document_GoodsReceiptForStorage_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_GoodsShipmentFromStorage" Then 
		ORR_Document_GoodsShipmentFromStorage_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	
	
	
	
	ElsIf ORR.Id = "Document_MovementOfProductsAndMaterials" Then 
		ORR_Document_MovementOfProductsAndMaterials_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	
	
	ElsIf ORR.Id = "Document_BackflushProduction" Then 
		ORR_Document_BackflushProduction_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_GiftCertificateCancellation" Then 
		ORR_Document_GiftCertificateCancellation_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_ReturnOfGiftCards" Then 
		ORR_Document_ReturnOfGiftCards_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_CashRegisterShift" Then 
		ORR_Document_CashRegisterShift_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_RetailSalesReport" Then 
		ORR_Document_RetailSalesReport_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_GiftCertificateSale" Then 
		ORR_Document_GiftCertificateSale_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_InventoryConsumption" Then 
		ORR_Document_InventoryConsumption_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_RedemptionOfGoodsFromStorage" Then 
		ORR_Document_RedemptionOfGoodsFromStorage_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_TransferOrder" Then 
		ORR_Document_TransferOrder_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_InventorySurplusRecognition" Then 
		ORR_Document_InventorySurplusRecognition_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_InventoryTransfer" Then 
		ORR_Document_InventoryTransfer_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_GoodsMisgrading" Then 
		ORR_Document_GoodsMisgrading_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_InventoryRecount" Then 
		ORR_Document_InventoryRecount_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_OtherGoodsRecordingAsReceived" Then 
		ORR_Document_OtherGoodsRecordingAsReceived_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_AssemblyFromComponents" Then 
		ORR_Document_AssemblyFromComponents_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_Decomissioning" Then 
		ORR_Document_Decomissioning_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_WriteOffOfGoodsShortages" Then 
		ORR_Document_WriteOffOfGoodsShortages_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_ReportOnVMIAdjustment" Then 
		ORR_Document_ReportOnVMIAdjustment_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_PhysicalCountOfInventoryInOperation" Then 
		ORR_Document_PhysicalCountOfInventoryInOperation_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_IssuedTaxInvoicePrepayment" Then 
		ORR_Document_IssuedTaxInvoicePrepayment_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	
	
	ElsIf ORR.Id = "Document_ReceivedTaxInvoicePrepayment" Then 
		ORR_Document_ReceivedTaxInvoicePrepayment_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	
	
	
	ElsIf ORR.Id = "Document_PriceSetup" Then 
		ORR_Document_PriceSetup_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	
	
	ElsIf ORR.Id = "Document_ApplicationForImportationOfGoods" Then 
		ORR_Document_ApplicationForImportationOfGoods_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	
	ElsIf ORR.Id = "Document_ReversingEntry" Then 
		ORR_Document_ReversingEntry_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Document_GoodsShipmentToCustomer" Then 
		ORR_Document_GoodsShipmentToCustomer_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "InformationRegister_RefinementsOfRetailOutletInventoryAffiliation" Then 
		ORR_InformationRegister_RefinementsOfRetailOutletInventoryAffiliation_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "InformationRegister_GoodsAvailabilityForExternalUsers" Then 
		ORR_InformationRegister_GoodsAvailabilityForExternalUsers_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "InformationRegister_ItemsBarcodes" Then 
		ORR_InformationRegister_ItemsBarcodes_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Catalog_POSTerminals" Then 
		ORR_Catalog_POSTerminals_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Catalog_CompaniesBankAccounts" Then 
		ORR_Catalog_CompaniesBankAccounts_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Catalog_CashAccounts" Then 
		ORR_Catalog_CashAccounts_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	ElsIf ORR.Id = "Catalog_CashRegisters" Then 
		ORR_Catalog_CashRegisters_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
	EndIf;
EndProcedure

// The event handler obrabotkadditional registration rules 
// Parameters:
//  Cancel - Boolean - Refusal to comply with the registration rule.
//  ORR - ValueTableRow - Object registration rule
//  Object - ConstantValueManager
//         - CatalogObject
//         - DocumentObject
//         - ChartOfCharacteristicTypesObject
//         - ChartOfAccountsObject
//         - ChartOfCalculationTypesObject
//         - BusinessProcessObject
//         - TaskObject
//         - InformationRegisterRecordSet
//         - AccumulationRegisterRecordSet
//         - AccountingRegisterRecordSet
//         - CalculationRegisterRecordSet - the object for which the registration rule is executed.
//  QueryText - String - the text of the request to identify the recipient nodes.
//  QueryOptions - Structure - request parameters for determining recipient nodes.
//  UseCache - Boolean - using the platform mechanism of reusable values.
//  AdditionalProperties - Structure
Procedure OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties) Export
	If ORR.Id = "Document_OBEntry" Then 
		ORR_Document_OBEntry_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_OBEntryARAP" Then 
		ORR_Document_OBEntryARAP_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_OBEntryCash" Then 
		ORR_Document_OBEntryCash_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_OBEntryFinancialInstruments" Then 
		ORR_Document_OBEntryFinancialInstruments_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_OBEntryARAPAdvanceHolders" Then 
		ORR_Document_OBEntryARAPAdvanceHolders_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_OBEntryGoods" Then 
		ORR_Document_OBEntryGoods_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_ReturnOfGoodsToVendor" Then 
		ORR_Document_ReturnOfGoodsToVendor_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_PurchaseOrder" Then 
		ORR_Document_PurchaseOrder_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_PurchaseAdjustment" Then 
		ORR_Document_PurchaseAdjustment_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_VendorInvoice" Then 
		ORR_Document_VendorInvoice_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_VendorInvoiceServicesAndAssets" Then 
		ORR_Document_VendorInvoiceServicesAndAssets_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_CCDImport" Then 
		ORR_Document_CCDImport_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_WorkOutput" Then 
		ORR_Document_WorkOutput_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	
	
	
	
	
	ElsIf ORR.Id = "Document_IntercompanyGoodsReturn" Then 
		ORR_Document_IntercompanyGoodsReturn_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_CommissionReportIntercompany" Then 
		ORR_Document_CommissionReportIntercompany_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_CommissionWriteOffReportIntercompany" Then 
		ORR_Document_CommissionWriteOffReportIntercompany_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_CustomerInvoiceIntercompany" Then 
		ORR_Document_CustomerInvoiceIntercompany_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	ElsIf ORR.Id = "Document_ARAPSettlement" Then 
		ORR_Document_ARAPSettlement_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_ARAPSettlement2" Then 
		ORR_Document_ARAPSettlement2_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_ARAPSettlement3" Then 
		ORR_Document_ARAPSettlement3_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_DepositCashIntoCashRegister" Then 
		ORR_Document_DepositCashIntoCashRegister_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_CashWithdrawalFromCashRegister" Then 
		ORR_Document_CashWithdrawalFromCashRegister_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_PaymentCardTransaction" Then 
		ORR_Document_PaymentCardTransaction_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_BankReportOnAcquiringTransactions" Then 
		ORR_Document_BankReportOnAcquiringTransactions_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_BankReportOnAcquiringTransactions2" Then 
		ORR_Document_BankReportOnAcquiringTransactions2_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_BankAccountReceiptNote" Then 
		ORR_Document_BankAccountReceiptNote_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_CashAccountReceiptNote" Then 
		ORR_Document_CashAccountReceiptNote_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_CashVoucher" Then 
		ORR_Document_CashVoucher_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_BankAccountIssue" Then 
		ORR_Document_BankAccountIssue_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_CashAccountReceiptNote2" Then 
		ORR_Document_CashAccountReceiptNote2_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_CashVoucher2" Then 
		ORR_Document_CashVoucher2_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_ExpenseReport" Then 
		ORR_Document_ExpenseReport_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	
	ElsIf ORR.Id = "Document_PaymentRequest" Then 
		ORR_Document_PaymentRequest_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_LoanAndDepositInterestCharge" Then 
		ORR_Document_LoanAndDepositInterestCharge_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_SourceDocument" Then 
		ORR_Document_SourceDocument_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	
	ElsIf ORR.Id = "Document_ARAPAdjustment" Then 
		ORR_Document_ARAPAdjustment_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_CustomerInvoiceServices" Then 
		ORR_Document_CustomerInvoiceServices_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_ReturnOfGoodsFromCustomer" Then 
		ORR_Document_ReturnOfGoodsFromCustomer_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_SalesOrder" Then 
		ORR_Document_SalesOrder_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_SaleAdjustment" Then 
		ORR_Document_SaleAdjustment_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_ConsignmentReportFromCustomer" Then 
		ORR_Document_ConsignmentReportFromCustomer_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_WriteOffReportFromCommissionAgent" Then 
		ORR_Document_WriteOffReportFromCommissionAgent_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_ConsignmentReportToVendor" Then 
		ORR_Document_ConsignmentReportToVendor_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_PurchaseInvoiceConsignmentStockLost" Then 
		ORR_Document_PurchaseInvoiceConsignmentStockLost_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_CustomerInvoice" Then 
		ORR_Document_CustomerInvoice_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_CustomerInvoiceServicesAndAssets" Then 
		ORR_Document_CustomerInvoiceServicesAndAssets_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_CustomerCommercialInvoice" Then 
		ORR_Document_CustomerCommercialInvoice_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	
	
	
	
	
	
	
	ElsIf ORR.Id = "Document_ReceiptOfGoodsFromCustodian" Then 
		ORR_Document_ReceiptOfGoodsFromCustodian_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_TransferOfGoodsToBailee" Then 
		ORR_Document_TransferOfGoodsToBailee_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_SubcontractorReport2_5" Then 
		ORR_Document_SubcontractorReport2_5_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	
	
	
	
	
	
	
	
	ElsIf ORR.Id = "Document_ReportToMaterialProvider2_5" Then 
		ORR_Document_ReportToMaterialProvider2_5_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_GoodsReceiptForStorage" Then 
		ORR_Document_GoodsReceiptForStorage_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_GoodsShipmentFromStorage" Then 
		ORR_Document_GoodsShipmentFromStorage_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	
	
	
	
	ElsIf ORR.Id = "Document_MovementOfProductsAndMaterials" Then 
		ORR_Document_MovementOfProductsAndMaterials_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	
	
	ElsIf ORR.Id = "Document_BackflushProduction" Then 
		ORR_Document_BackflushProduction_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_GiftCertificateCancellation" Then 
		ORR_Document_GiftCertificateCancellation_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_ReturnOfGiftCards" Then 
		ORR_Document_ReturnOfGiftCards_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_CashRegisterShift" Then 
		ORR_Document_CashRegisterShift_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_RetailSalesReport" Then 
		ORR_Document_RetailSalesReport_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_GiftCertificateSale" Then 
		ORR_Document_GiftCertificateSale_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_InventoryConsumption" Then 
		ORR_Document_InventoryConsumption_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_RedemptionOfGoodsFromStorage" Then 
		ORR_Document_RedemptionOfGoodsFromStorage_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_TransferOrder" Then 
		ORR_Document_TransferOrder_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_InventorySurplusRecognition" Then 
		ORR_Document_InventorySurplusRecognition_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_InventoryTransfer" Then 
		ORR_Document_InventoryTransfer_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_GoodsMisgrading" Then 
		ORR_Document_GoodsMisgrading_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_InventoryRecount" Then 
		ORR_Document_InventoryRecount_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_OtherGoodsRecordingAsReceived" Then 
		ORR_Document_OtherGoodsRecordingAsReceived_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_AssemblyFromComponents" Then 
		ORR_Document_AssemblyFromComponents_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_Decomissioning" Then 
		ORR_Document_Decomissioning_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_WriteOffOfGoodsShortages" Then 
		ORR_Document_WriteOffOfGoodsShortages_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_ReportOnVMIAdjustment" Then 
		ORR_Document_ReportOnVMIAdjustment_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_PhysicalCountOfInventoryInOperation" Then 
		ORR_Document_PhysicalCountOfInventoryInOperation_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_IssuedTaxInvoicePrepayment" Then 
		ORR_Document_IssuedTaxInvoicePrepayment_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	
	
	ElsIf ORR.Id = "Document_ReceivedTaxInvoicePrepayment" Then 
		ORR_Document_ReceivedTaxInvoicePrepayment_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	
	
	
	ElsIf ORR.Id = "Document_PriceSetup" Then 
		ORR_Document_PriceSetup_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	
	ElsIf ORR.Id = "Document_ReversingEntry" Then 
		ORR_Document_ReversingEntry_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Document_GoodsShipmentToCustomer" Then 
		ORR_Document_GoodsShipmentToCustomer_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "InformationRegister_RefinementsOfRetailOutletInventoryAffiliation" Then 
		ORR_InformationRegister_RefinementsOfRetailOutletInventoryAffiliation_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "InformationRegister_GoodsAvailabilityForExternalUsers" Then 
		ORR_InformationRegister_GoodsAvailabilityForExternalUsers_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "InformationRegister_ItemsBarcodes" Then 
		ORR_InformationRegister_ItemsBarcodes_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Catalog_POSTerminals" Then 
		ORR_Catalog_POSTerminals_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Catalog_CompaniesBankAccounts" Then 
		ORR_Catalog_CompaniesBankAccounts_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Catalog_CashAccounts" Then 
		ORR_Catalog_CashAccounts_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	ElsIf ORR.Id = "Catalog_CashRegisters" Then 
		ORR_Catalog_CashRegisters_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
	EndIf;
EndProcedure

// Event handler after processing the registration rule 
// Parameters:    
//  ORR - ValueTableRow - Object registration rule
//  Cancel - Boolean - Refusal to comply with the registration rule.
//  Object - ConstantValueManager
//         - CatalogObject
//         - DocumentObject
//         - ChartOfCharacteristicTypesObject
//         - ChartOfAccountsObject
//         - ChartOfCalculationTypesObject
//         - BusinessProcessObject
//         - TaskObject
//         - InformationRegisterRecordSet
//         - AccumulationRegisterRecordSet
//         - AccountingRegisterRecordSet
//         - CalculationRegisterRecordSet - the object for which the registration rule is executed.
//  MetadataObject - MetadataObject - The metadata object corresponding to the object.
//  Recipients - Array - the list of recipient nodes where the object will be registered.
//  Upload0 - Boolean - the context of the registration rule execution, if True, the object is unloaded.
Procedure AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0) Export
	If ORR.Id = "Document_ReturnOfGoodsToVendor" Then 
		ORR_Document_ReturnOfGoodsToVendor_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0);
	ElsIf ORR.Id = "Document_PurchaseOrder" Then 
		ORR_Document_PurchaseOrder_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0);
	ElsIf ORR.Id = "Document_PurchaseAdjustment" Then 
		ORR_Document_PurchaseAdjustment_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0);
	ElsIf ORR.Id = "Document_VendorInvoice" Then 
		ORR_Document_VendorInvoice_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0);
	ElsIf ORR.Id = "Document_VendorInvoiceServicesAndAssets" Then 
		ORR_Document_VendorInvoiceServicesAndAssets_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0);
	ElsIf ORR.Id = "Document_CCDImport" Then 
		ORR_Document_CCDImport_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0);
	ElsIf ORR.Id = "Document_IntercompanyGoodsReturn" Then 
		ORR_Document_IntercompanyGoodsReturn_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0);
	ElsIf ORR.Id = "Document_CommissionReportIntercompany" Then 
		ORR_Document_CommissionReportIntercompany_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0);
	ElsIf ORR.Id = "Document_CustomerInvoiceIntercompany" Then 
		ORR_Document_CustomerInvoiceIntercompany_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0);
	ElsIf ORR.Id = "Document_ARAPSettlement" Then 
		ORR_Document_ARAPSettlement_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0);
	ElsIf ORR.Id = "Document_ARAPSettlement2" Then 
		ORR_Document_ARAPSettlement2_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0);
	ElsIf ORR.Id = "Document_ARAPSettlement3" Then 
		ORR_Document_ARAPSettlement3_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0);
	ElsIf ORR.Id = "Document_PaymentCardTransaction" Then 
		ORR_Document_PaymentCardTransaction_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0);
	ElsIf ORR.Id = "Document_BankAccountReceiptNote" Then 
		ORR_Document_BankAccountReceiptNote_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0);
	ElsIf ORR.Id = "Document_CashAccountReceiptNote" Then 
		ORR_Document_CashAccountReceiptNote_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0);
	ElsIf ORR.Id = "Document_CashVoucher" Then 
		ORR_Document_CashVoucher_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0);
	ElsIf ORR.Id = "Document_BankAccountIssue" Then 
		ORR_Document_BankAccountIssue_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0);
	ElsIf ORR.Id = "Document_CashAccountReceiptNote2" Then 
		ORR_Document_CashAccountReceiptNote2_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0);
	ElsIf ORR.Id = "Document_CashVoucher2" Then 
		ORR_Document_CashVoucher2_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0);
	
	ElsIf ORR.Id = "Document_LoanAndDepositInterestCharge" Then 
		ORR_Document_LoanAndDepositInterestCharge_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0);
	
	ElsIf ORR.Id = "Document_CustomerInvoiceServices" Then 
		ORR_Document_CustomerInvoiceServices_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0);
	ElsIf ORR.Id = "Document_ReturnOfGoodsFromCustomer" Then 
		ORR_Document_ReturnOfGoodsFromCustomer_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0);
	ElsIf ORR.Id = "Document_SalesOrder" Then 
		ORR_Document_SalesOrder_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0);
	ElsIf ORR.Id = "Document_SaleAdjustment" Then 
		ORR_Document_SaleAdjustment_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0);
	ElsIf ORR.Id = "Document_ConsignmentReportFromCustomer" Then 
		ORR_Document_ConsignmentReportFromCustomer_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0);
	ElsIf ORR.Id = "Document_ConsignmentReportToVendor" Then 
		ORR_Document_ConsignmentReportToVendor_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0);
	ElsIf ORR.Id = "Document_CustomerInvoice" Then 
		ORR_Document_CustomerInvoice_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0);
	ElsIf ORR.Id = "Document_CustomerInvoiceServicesAndAssets" Then 
		ORR_Document_CustomerInvoiceServicesAndAssets_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0);
	ElsIf ORR.Id = "Document_CustomerCommercialInvoice" Then 
		ORR_Document_CustomerCommercialInvoice_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0);
	ElsIf ORR.Id = "Document_GiftCertificateCancellation" Then 
		ORR_Document_GiftCertificateCancellation_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0);
	ElsIf ORR.Id = "Document_ReversingEntry" Then 
		ORR_Document_ReversingEntry_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0);
	ElsIf ORR.Id = "Document_GoodsShipmentToCustomer" Then 
		ORR_Document_GoodsShipmentToCustomer_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0);
	ElsIf ORR.Id = "InformationRegister_SalesOrderStates" Then 
		ORR_InformationRegister_SalesOrderStates_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0);
	ElsIf ORR.Id = "Catalog_Counterparties" Then 
		ORR_Catalog_Counterparties_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0);
	ElsIf ORR.Id = "Catalog_Counterparties2" Then 
		ORR_Catalog_Counterparties2_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0);
	ElsIf ORR.Id = "Catalog_Companies" Then 
		ORR_Catalog_Companies_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0);
	EndIf;
EndProcedure

#EndRegion
#Region Private
Procedure ExecuteRegistrationRulesForObject(Object, ExchangePlanName, Sender)
	DataExchangeEvents.ExecuteRegistrationRulesForObject(Object, ExchangePlanName, Sender);
EndProcedure

Function GetRecipients(Object, ExchangePlanName)
	Return DataExchangeEvents.GetRecipients(Object, ExchangePlanName);
EndFunction

Function AllExchangePlanNodes(ExchangePlanName)
	Return DataExchangeEvents.AllExchangePlanNodes(ExchangePlanName);
EndFunction
 
Procedure SetFilters(RegistrationRule, FilterByExchangePlanProperties, FilterByObjectProperties)
	DataProcessor = DataProcessors.ObjectsRegistrationRulesImport.Create();
	
	XMLRules = New XMLReader;
	
	//FilterByExchangePlanProperties
	RegistrationRule.FilterByExchangePlanProperties = DataExchangeServer.FilterByExchangePlanPropertiesTableInitialization().Copy();
	
	XMLRules.SetString(FilterByExchangePlanProperties);
	XMLRules.Read();
	DataProcessor.LoadFilterByExchangePlanPropertiesTree(XMLRules, RegistrationRule.FilterByExchangePlanProperties);
	
	DataProcessor.Registration = New Structure("ExchangePlanName", RegistrationRule.ExchangePlanName);
	DataProcessor.PrepareRecordRuleByExchangePlanProperties(RegistrationRule);
	
	//FilterByObjectProperties
	XMLRules.SetString(FilterByObjectProperties);
	XMLRules.Read();
	
	RegistrationRule.FilterByObjectProperties = DataExchangeServer.FilterByObjectPropertiesTableInitialization().Copy();
	DataProcessor.LoadFilterByObjectPropertiesTree(XMLRules, RegistrationRule.FilterByObjectProperties);
EndProcedure 

#Region Document_OBEntry
Procedure AddPRO_Document_EnterBalances(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_OBEntry";
	
	NewRule.MetadataObjectName3 = "Document.OBEntry";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_18(),
		FilterByObjectProperties_4());
EndProcedure

Procedure ORR_Document_OBEntry_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Return leftovers";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_OBEntry_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Return leftovers";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure
#EndRegion
#Region Document_OBEntryARAP
Procedure AddPRO_Document_EnterSettlementBalances(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_OBEntryARAP";
	
	NewRule.MetadataObjectName3 = "Document.OBEntryARAP";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_18(),
		FilterByObjectProperties_4());
EndProcedure

Procedure ORR_Document_OBEntryARAP_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Return leftovers";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_OBEntryARAP_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Return leftovers";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure
#EndRegion

#Region Document_OBEntryCash
Procedure AddPRO_Document_EnterCashBalances(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_OBEntryCash";
	
	NewRule.MetadataObjectName3 = "Document.OBEntryCash";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_18(),
		FilterByObjectProperties_4());
EndProcedure

Procedure ORR_Document_OBEntryCash_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Return leftovers";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_OBEntryCash_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Return leftovers";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure
#EndRegion
#Region Document_OBEntryFinancialInstruments
Procedure AddPRO_Document_EnterBalancesOnFinancialInstruments(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_OBEntryFinancialInstruments";
	
	NewRule.MetadataObjectName3 = "Document.OBEntryFinancialInstruments";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_18(),
		FilterByObjectProperties_4());
EndProcedure

Procedure ORR_Document_OBEntryFinancialInstruments_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Return leftovers";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_OBEntryFinancialInstruments_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Return leftovers";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure
#EndRegion
#Region Document_OBEntryARAPAdvanceHolders
Procedure AddPRO_Document_EnterBalancesWithAccountablePersons(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_OBEntryARAPAdvanceHolders";
	
	NewRule.MetadataObjectName3 = "Document.OBEntryARAPAdvanceHolders";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_18(),
		FilterByObjectProperties_4());
EndProcedure

Procedure ORR_Document_OBEntryARAPAdvanceHolders_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Return leftovers";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_OBEntryARAPAdvanceHolders_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Return leftovers";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure
#EndRegion
#Region Document_OBEntryGoods
Procedure AddPRO_Document_EnterProductBalances(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_OBEntryGoods";
	
	NewRule.MetadataObjectName3 = "Document.OBEntryGoods";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_18(),
		FilterByObjectProperties_4());
EndProcedure

Procedure ORR_Document_OBEntryGoods_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Return leftovers";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_OBEntryGoods_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Return leftovers";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure
#EndRegion
#Region Document_ReturnOfGoodsToVendor
Procedure AddPRO_Document_ReturnOfGoodsToSupplier(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_ReturnOfGoodsToVendor";
	
	NewRule.MetadataObjectName3 = "Document.ReturnOfGoodsToVendor";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = True;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_16(),
		FilterByObjectProperties_4());
EndProcedure

Procedure ORR_Document_ReturnOfGoodsToVendor_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Purchases";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_ReturnOfGoodsToVendor_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Purchases";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
	ReceiptDocuments = Object.Goods.Unload();
	ReceiptDocuments.GroupBy("DocumentInflow");
	For Each Page1 In ReceiptDocuments Do
		If Page1.DocumentInflow.PurchaseForActivity = PredefinedValue("Enum.VATTaxationTypes.SpaceActivity") Then
			Cancel = True;
			Break;
		EndIf;
	EndDo; 
EndProcedure

Procedure ORR_Document_ReturnOfGoodsToVendor_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0)
	If Not Upload0 And Recipients.Count() > 0 Then
		If Not Common.RefExists(Object.Ref) Then
			Return
		EndIf;
		Query = New Query("SELECT 
								|RelatedDocuments.Ref AS Ref
								|FROM
								|	FilterCriterion.RelatedDocuments(&FilterCriteriaValue) AS RelatedDocuments
								|WHERE
								|	VALUETYPE(RelatedDocuments.Ref) = TYPE(Document.ReceivedTaxInvoicePrepayment)
								|	");
								
		Query.SetParameter("FilterCriteriaValue",Object.Ref);
		
		Result = Query.Execute().Select();
		While Result.Next() Do
			TaxInvoice = Result.Ref.GetObject();
			ExecuteRegistrationRulesForObject(TaxInvoice, ORR.ExchangePlanName, Undefined);
		EndDo;
		
	EndIf;
EndProcedure
#EndRegion
#Region Document_PurchaseOrder
Procedure AddPRO_Document_OrderToSupplier(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_PurchaseOrder";
	
	NewRule.MetadataObjectName3 = "Document.PurchaseOrder";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = True;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = True;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_16(),
		FilterByObjectProperties_4());
EndProcedure

Procedure ORR_Document_PurchaseOrder_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0)
	FederalDistrict = GetFunctionalOption("UsePurchaseOrderStatuses");
	// Checking that there is at least one undelivered line in the order, otherwise we do not register
	If Object.Posted And (Not FederalDistrict Or Object.Status <> Enums.PurchaseOrderStatuses.NotApproved) Then
		ThereIsUnreleasedLine = False;
		For Each String In Object.Goods Do
			If Not String.Canceled Then
				ThereIsUnreleasedLine = True;
				Break;
			EndIf;		
		EndDo;
		If Not ThereIsUnreleasedLine Then
			Cancel = True;
		EndIf;	
	EndIf;
	If Object.PurchaseForActivity = PredefinedValue("Enum.VATTaxationTypes.SpaceActivity") Then
		Cancel = True;
	EndIf;
EndProcedure

Procedure ORR_Document_PurchaseOrder_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Purchases";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_PurchaseOrder_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Purchases";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure

Procedure ORR_Document_PurchaseOrder_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0)
	If Recipients.Count() > 0 Then
		// Orders to the supplier are registered only for the format version 1.3 and later.
		MaxIndex_ = Recipients.UBound();
		For IndexOf = 0 To MaxIndex_ Do
			CurIndx = MaxIndex_ - IndexOf;
			CurRecipient = Recipients[CurIndx];
			FormatVersion = Common.ObjectAttributeValue(CurRecipient, "ExchangeFormatVersion");
			
			NumberFormatVersion = StringFunctionsClientServer.StringToNumber(FormatVersion);
			
			If NumberFormatVersion = Undefined Then
				Recipients.Delete(CurIndx);
			EndIf;
		EndDo;
	EndIf;
EndProcedure
#EndRegion
#Region Document_PurchaseAdjustment
Procedure AddPRO_Document_PurchaseAdjustment(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_PurchaseAdjustment";
	
	NewRule.MetadataObjectName3 = "Document.PurchaseAdjustment";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = True;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_16(),
		Document_PurchaseAdjustment_FilterByObjectProperties());
EndProcedure

Function Document_PurchaseAdjustment_FilterByObjectProperties()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>Posted</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>true</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Posted</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>EnumRef.AdjustingEntryTypes</ObjectPropertyType>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>AdjustingEntryType</ObjectProperty1>
			|		<Kind>ValueAlgorithm</Kind>
			|		<ConstantValue>Value = Enums.AdjustingEntryTypes.AdjustmentByGoodsAndServices;</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>AdjustingEntryType</Description>
			|				<Type>EnumRef.AdjustingEntryTypes</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|</FilterByObjectProperties>";
EndFunction

Procedure ORR_Document_PurchaseAdjustment_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Purchases";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_PurchaseAdjustment_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Purchases";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
	
	
	If Object.DocumentBasis = Undefined Or TypeOf(Object.DocumentBasis) = Type("DocumentRef.SubcontractorReport2_5") Then
		Cancel = True;
	EndIf;
	
	If Not Object.DocumentBasis = Undefined 
			And CommonClientServer.HasAttributeOrObjectProperty(Object.DocumentBasis, "PurchaseForActivity") Then
			DocumentBasis = Object.DocumentBasis;
			If DocumentBasis.PurchaseForActivity = PredefinedValue("Enum.VATTaxationTypes.SpaceActivity") Then
			     Cancel = True;
			EndIf;
	EndIf;	
EndProcedure

Procedure ORR_Document_PurchaseAdjustment_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0)
EndProcedure
#EndRegion
#Region Document_VendorInvoice
Procedure AddPRO_Document_PurchaseOfGoodsAndServices(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_VendorInvoice";
	
	NewRule.MetadataObjectName3 = "Document.VendorInvoice";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = True;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = True;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_16(),
		FilterByObjectProperties_1());
EndProcedure

Procedure ORR_Document_VendorInvoice_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0)
	If Not Upload0 And Not Object.IsNew() Then
		// We will perform the PRO for the advance report specified in the document.
		AdvanceReportLinks = Common.ObjectAttributeValue(Object.Ref, "ExpenseReport");
		If ValueIsFilled(Object.ExpenseReport) And Common.RefExists(Object.ExpenseReport) Then
			ExecuteRegistrationRulesForObject(Object.ExpenseReport.GetObject(), ORR.ExchangePlanName, Undefined);
		EndIf;
		If ValueIsFilled(AdvanceReportLinks) And Common.RefExists(AdvanceReportLinks) Then
			ExecuteRegistrationRulesForObject(AdvanceReportLinks.GetObject(), ORR.ExchangePlanName, Undefined);
		EndIf;
	EndIf;
EndProcedure

Procedure ORR_Document_VendorInvoice_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Purchases";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_VendorInvoice_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Purchases";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure

Procedure ORR_Document_VendorInvoice_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0)
EndProcedure
#EndRegion
#Region Document_VendorInvoiceServicesAndAssets
Procedure AddPRO_Document_PurchaseOfServicesOtherAssets(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_VendorInvoiceServicesAndAssets";
	
	NewRule.MetadataObjectName3 = "Document.VendorInvoiceServicesAndAssets";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = True;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_18(),
		FilterByObjectProperties_1());
EndProcedure

Procedure ORR_Document_VendorInvoiceServicesAndAssets_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Purchases";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_VendorInvoiceServicesAndAssets_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Purchases";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure

Procedure ORR_Document_VendorInvoiceServicesAndAssets_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0)
EndProcedure
#EndRegion
#Region Document_CCDImport
Procedure AddPRO_Document_CustomsDeclarationImport(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_CCDImport";
	
	NewRule.MetadataObjectName3 = "Document.CCDImport";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = True;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_18(),
		FilterByObjectProperties_4());
EndProcedure

Procedure ORR_Document_CCDImport_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Purchases";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_CCDImport_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Purchases";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
	ReceiptDocuments = Object.Goods.Unload();
		ReceiptDocuments.GroupBy("DocumentInflow");
		For Each Page1 In ReceiptDocuments Do
			If Page1.DocumentInflow.PurchaseForActivity = PredefinedValue("Enum.VATTaxationTypes.SpaceActivity") Then
				Cancel = True;
				Break;
			EndIf;
		EndDo; 
EndProcedure

Procedure ORR_Document_CCDImport_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0)
	If Not Cancel
		And Not Upload0 
		And Recipients.Count() > 0 Then
		
		UninvoicedReceiptDocuments = Object.Goods.Unload(,"DocumentInflow");
		
		If UninvoicedReceiptDocuments.Count() > 0 Then
			
			UninvoicedReceiptDocuments.GroupBy("DocumentInflow");
			
			For Each ReceiptDocumentString In UninvoicedReceiptDocuments Do 
				If ValueIsFilled(ReceiptDocumentString.DocumentInflow) Then
					ExecuteRegistrationRulesForObject(ReceiptDocumentString.DocumentInflow.GetObject(), ORR.ExchangePlanName, Undefined);
				EndIf;
			EndDo;
			
		EndIf;
		
	EndIf;
EndProcedure
#EndRegion
#Region Document_WorkOutput
Procedure AddPRO_Document_EmployeeDevelopment(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_WorkOutput";
	
	NewRule.MetadataObjectName3 = "Document.WorkOutput";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		Document_DevelopmentOfEmployees_SelectionAccordingToPropertiesOfExchangePlan(),
		FilterByObjectProperties_4());
EndProcedure

Function Document_DevelopmentOfEmployees_SelectionAccordingToPropertiesOfExchangePlan()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>FALSE</IsConstantString>
			|		<ObjectPropertyType>DATE</ObjectPropertyType>
			|		<ExchangePlanProperty>DocumentsExportStartDate</ExchangePlanProperty>
			|		<ComparisonType>GreaterOrEqual</ComparisonType>
			|		<ObjectProperty1>DATE</ObjectProperty1>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>DATE</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>DocumentsExportStartDate</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|			<ExchangePlanProperty>[Companies].Organization</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Organization</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Companies]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<Group>
			|			<BooleanGroupValue>AND</BooleanGroupValue>
			|			<FilterElement>
			|				<IsConstantString>TRUE</IsConstantString>
			|				<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|				<ExchangePlanProperty>UseFilterByCompanies</ExchangePlanProperty>
			|				<ComparisonType>Equal</ComparisonType>
			|				<ObjectProperty1>FALSE</ObjectProperty1>
			|				<TableOfExchangePlanProperties>
			|					<Property>
			|						<Description>UseFilterByCompanies</Description>
			|						<TYPE>BOOLEAN</TYPE>
			|						<Kind>Attribute</Kind>
			|					</Property>
			|				</TableOfExchangePlanProperties>
			|			</FilterElement>
			|			<Group>
			|				<BooleanGroupValue>OR</BooleanGroupValue>
			|				<FilterElement>
			|					<IsConstantString>FALSE</IsConstantString>
			|					<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|					<ExchangePlanProperty>ManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>NotEqual</ComparisonType>
			|					<ObjectProperty1>Organization</ObjectProperty1>
			|					<ObjectPropertiesTable>
			|						<Property>
			|							<Description>Organization</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</ObjectPropertiesTable>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>ManagementCompany</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|				<FilterElement>
			|					<IsConstantString>TRUE</IsConstantString>
			|					<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|					<ExchangePlanProperty>UnloadManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>Equal</ComparisonType>
			|					<ObjectProperty1>TRUE</ObjectProperty1>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>UnloadManagementCompany</Description>
			|							<TYPE>BOOLEAN</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|			</Group>
			|		</Group>
			|	</Group>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>ExchangeUP2ZUP3</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>CashExchange</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeOfUPRMC</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>";
EndFunction

Procedure ORR_Document_WorkOutput_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Salary";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_WorkOutput_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Salary";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure
#EndRegion



#Region Document_IntercompanyGoodsReturn
Procedure AddPRO_Document_ReturnOfGoodsBetweenOrganizations(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_IntercompanyGoodsReturn";
	
	NewRule.MetadataObjectName3 = "Document.IntercompanyGoodsReturn";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = True;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_7(),
		FilterByObjectProperties_4());
EndProcedure

Procedure ORR_Document_IntercompanyGoodsReturn_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Sales";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_IntercompanyGoodsReturn_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Sales";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure

Procedure ORR_Document_IntercompanyGoodsReturn_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0)
	If Not Upload0 And Recipients.Count() > 0 Then
		If Not Common.RefExists(Object.Ref) Then
			Return
		EndIf;
		Query = New Query("SELECT 
								|RelatedDocuments.Ref AS Ref
								|FROM
								|	FilterCriterion.RelatedDocuments(&FilterCriteriaValue) AS RelatedDocuments
								|WHERE
								|	VALUETYPE(RelatedDocuments.Ref) = TYPE(Document.IssuedTaxInvoicePrepayment)
								|	OR VALUETYPE(RelatedDocuments.Ref) = TYPE(Document.ReceivedTaxInvoicePrepayment)
								|");
								
		Query.SetParameter("FilterCriteriaValue",Object.Ref);
		
		Result = Query.Execute().Select();
		While Result.Next() Do
			TaxInvoice = Result.Ref.GetObject();
			ExecuteRegistrationRulesForObject(TaxInvoice, ORR.ExchangePlanName, Undefined);
		EndDo;
		
	EndIf;
EndProcedure
#EndRegion
#Region Document_CommissionReportIntercompany
Procedure AddPRO_Document_ReportOnCommissionBetweenOrganizations(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_CommissionReportIntercompany";
	
	NewRule.MetadataObjectName3 = "Document.CommissionReportIntercompany";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = True;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_12(),
		FilterByObjectProperties_5());
EndProcedure

Procedure ORR_Document_CommissionReportIntercompany_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Sales";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_CommissionReportIntercompany_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Sales";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure

Procedure ORR_Document_CommissionReportIntercompany_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0)
EndProcedure
#EndRegion
#Region Document_CommissionWriteOffReportIntercompany
Procedure AddPRO_Document_ReportOnCommissionBetweenOrganizationsOnWriteOffs(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_CommissionWriteOffReportIntercompany";
	
	NewRule.MetadataObjectName3 = "Document.CommissionWriteOffReportIntercompany";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_12(),
		FilterByObjectProperties_5());
EndProcedure

Procedure ORR_Document_CommissionWriteOffReportIntercompany_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Sales";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_CommissionWriteOffReportIntercompany_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Sales";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure
#EndRegion
#Region Document_CustomerInvoiceIntercompany
Procedure AddPRO_Document_TransferOfGoodsBetweenOrganizations(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_CustomerInvoiceIntercompany";
	
	NewRule.MetadataObjectName3 = "Document.CustomerInvoiceIntercompany";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = True;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_7(),
		FilterByObjectProperties_4());
EndProcedure

Procedure ORR_Document_CustomerInvoiceIntercompany_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Sales";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_CustomerInvoiceIntercompany_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Sales";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure

Procedure ORR_Document_CustomerInvoiceIntercompany_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0)
EndProcedure
#EndRegion








#Region Document_ARAPSettlement
Procedure AddPRO_Document_DebtOffset(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_ARAPSettlement";
	
	NewRule.MetadataObjectName3 = "Document.ARAPSettlement";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = True;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = True;
		
	SetFilters(NewRule, 
		Document_DebtOffset_SelectionAccordingToPropertiesOfExchangePlan(),
		FilterByObjectProperties_4());
EndProcedure

Function Document_DebtOffset_SelectionAccordingToPropertiesOfExchangePlan()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>FALSE</IsConstantString>
			|		<ObjectPropertyType>DATE</ObjectPropertyType>
			|		<ExchangePlanProperty>DocumentsExportStartDate</ExchangePlanProperty>
			|		<ComparisonType>GreaterOrEqual</ComparisonType>
			|		<ObjectProperty1>DATE</ObjectProperty1>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>DATE</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>DocumentsExportStartDate</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|			<ExchangePlanProperty>[Companies].Organization</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Organization</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Companies]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|			<ExchangePlanProperty>[Companies].Organization</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>CounterpartyDebtor</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>CounterpartyDebtor</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Companies]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|			<ExchangePlanProperty>[Companies].Organization</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Creditor</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Creditor</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Companies]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<Group>
			|			<BooleanGroupValue>AND</BooleanGroupValue>
			|			<FilterElement>
			|				<IsConstantString>TRUE</IsConstantString>
			|				<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|				<ExchangePlanProperty>UseFilterByCompanies</ExchangePlanProperty>
			|				<ComparisonType>Equal</ComparisonType>
			|				<ObjectProperty1>FALSE</ObjectProperty1>
			|				<TableOfExchangePlanProperties>
			|					<Property>
			|						<Description>UseFilterByCompanies</Description>
			|						<TYPE>BOOLEAN</TYPE>
			|						<Kind>Attribute</Kind>
			|					</Property>
			|				</TableOfExchangePlanProperties>
			|			</FilterElement>
			|			<Group>
			|				<BooleanGroupValue>OR</BooleanGroupValue>
			|				<FilterElement>
			|					<IsConstantString>TRUE</IsConstantString>
			|					<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|					<ExchangePlanProperty>UnloadManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>Equal</ComparisonType>
			|					<ObjectProperty1>TRUE</ObjectProperty1>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>UnloadManagementCompany</Description>
			|							<TYPE>BOOLEAN</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|				<FilterElement>
			|					<IsConstantString>FALSE</IsConstantString>
			|					<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|					<ExchangePlanProperty>ManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>NotEqual</ComparisonType>
			|					<ObjectProperty1>Organization</ObjectProperty1>
			|					<ObjectPropertiesTable>
			|						<Property>
			|							<Description>Organization</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</ObjectPropertiesTable>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>ManagementCompany</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|			</Group>
			|		</Group>
			|	</Group>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeUP2ZUP3</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>CashExchange</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeOfUPRMC</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>";
EndFunction

Procedure ORR_Document_ARAPSettlement_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0)
	DataExchangeEventsTM.DocumentARAPSettlementBeforeProcessingORR(Object, Cancel);
EndProcedure

Procedure ORR_Document_ARAPSettlement_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "TreasuryAndARAPAccounting";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_ARAPSettlement_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "TreasuryAndARAPAccounting";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure

Procedure ORR_Document_ARAPSettlement_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0)
	DataExchangeEventsTM.DocumentDebtOffsetAfterProcessing(Object, Upload0, Recipients, ORR.ExchangePlanName);
EndProcedure
#EndRegion
#Region Document_ARAPSettlement2
Procedure AddPRO_Document_DebtOffset2(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_ARAPSettlement2";
	
	NewRule.MetadataObjectName3 = "Document.ARAPSettlement";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = True;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = True;
		
	SetFilters(NewRule, 
		Document_DebtOffset2_SelectionBasedOnPropertiesOfExchangePlan(),
		Document_DebtOffset2_SelectionByObjectProperties());
EndProcedure

Function Document_DebtOffset2_SelectionBasedOnPropertiesOfExchangePlan()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>FALSE</IsConstantString>
			|		<ObjectPropertyType>DATE</ObjectPropertyType>
			|		<ExchangePlanProperty>DocumentsExportStartDate</ExchangePlanProperty>
			|		<ComparisonType>GreaterOrEqual</ComparisonType>
			|		<ObjectProperty1>DATE</ObjectProperty1>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>DATE</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>DocumentsExportStartDate</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|			<ExchangePlanProperty>[Companies].Organization</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Organization</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Companies]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|			<ExchangePlanProperty>[Companies].Organization</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>CounterpartyDebtor</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>CounterpartyDebtor</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Companies]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|			<ExchangePlanProperty>[Companies].Organization</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Creditor</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Creditor</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Companies]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<Group>
			|			<BooleanGroupValue>AND</BooleanGroupValue>
			|			<FilterElement>
			|				<IsConstantString>TRUE</IsConstantString>
			|				<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|				<ExchangePlanProperty>UseFilterByCompanies</ExchangePlanProperty>
			|				<ComparisonType>Equal</ComparisonType>
			|				<ObjectProperty1>FALSE</ObjectProperty1>
			|				<TableOfExchangePlanProperties>
			|					<Property>
			|						<Description>UseFilterByCompanies</Description>
			|						<TYPE>BOOLEAN</TYPE>
			|						<Kind>Attribute</Kind>
			|					</Property>
			|				</TableOfExchangePlanProperties>
			|			</FilterElement>
			|			<Group>
			|				<BooleanGroupValue>OR</BooleanGroupValue>
			|				<FilterElement>
			|					<IsConstantString>TRUE</IsConstantString>
			|					<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|					<ExchangePlanProperty>UnloadManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>Equal</ComparisonType>
			|					<ObjectProperty1>TRUE</ObjectProperty1>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>UnloadManagementCompany</Description>
			|							<TYPE>BOOLEAN</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|				<FilterElement>
			|					<IsConstantString>FALSE</IsConstantString>
			|					<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|					<ExchangePlanProperty>ManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>NotEqual</ComparisonType>
			|					<ObjectProperty1>CounterpartyDebtor</ObjectProperty1>
			|					<ObjectPropertiesTable>
			|						<Property>
			|							<Description>CounterpartyDebtor</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</ObjectPropertiesTable>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>ManagementCompany</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|			</Group>
			|		</Group>
			|	</Group>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeUP2ZUP3</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>CashExchange</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeOfUPRMC</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>";
EndFunction

Function Document_DebtOffset2_SelectionByObjectProperties()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>Posted</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>TRUE</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Posted</Description>
			|				<TYPE>BOOLEAN</TYPE>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<ObjectPropertyType>EnumRef.ARAPSettlemenParticipantTypes</ObjectPropertyType>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>CounterpartyDebtorType</ObjectProperty1>
			|			<Kind>ValueAlgorithm</Kind>
			|			<ConstantValue>VALUE = Enums.ARAPSettlemenParticipantTypes.OrganizationClient;</ConstantValue>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>CounterpartyDebtorType</Description>
			|					<TYPE>EnumRef.ARAPSettlemenParticipantTypes</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|		</FilterElement>
			|		<FilterElement>
			|			<ObjectPropertyType>EnumRef.ARAPSettlemenParticipantTypes</ObjectPropertyType>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>CounterpartyDebtorType</ObjectProperty1>
			|			<Kind>ValueAlgorithm</Kind>
			|			<ConstantValue>VALUE = Enums.ARAPSettlemenParticipantTypes.CompanyVendor;</ConstantValue>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>CounterpartyDebtorType</Description>
			|					<TYPE>EnumRef.ARAPSettlemenParticipantTypes</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|		</FilterElement>
			|	</Group>
			|</FilterByObjectProperties>";
EndFunction

Procedure ORR_Document_ARAPSettlement2_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0)
	DataExchangeEventsTM.DocumentARAPSettlementBeforeProcessingORR(Object, Cancel);
EndProcedure

Procedure ORR_Document_ARAPSettlement2_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "TreasuryAndARAPAccounting";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_ARAPSettlement2_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "TreasuryAndARAPAccounting";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure

Procedure ORR_Document_ARAPSettlement2_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0)
	DataExchangeEventsTM.DocumentDebtOffsetAfterProcessing(Object, Upload0, Recipients, ORR.ExchangePlanName);
EndProcedure
#EndRegion
#Region Document_ARAPSettlement3
Procedure AddPRO_Document_DebtOffset3(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_ARAPSettlement3";
	
	NewRule.MetadataObjectName3 = "Document.ARAPSettlement";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = True;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = True;
		
	SetFilters(NewRule, 
		Document_DebtOffset3_SelectionBasedOnPropertiesOfExchangePlan(),
		Document_DebtOffset3_SelectionByObjectProperties());
EndProcedure

Function Document_DebtOffset3_SelectionBasedOnPropertiesOfExchangePlan()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>FALSE</IsConstantString>
			|		<ObjectPropertyType>DATE</ObjectPropertyType>
			|		<ExchangePlanProperty>DocumentsExportStartDate</ExchangePlanProperty>
			|		<ComparisonType>GreaterOrEqual</ComparisonType>
			|		<ObjectProperty1>DATE</ObjectProperty1>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>DATE</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>DocumentsExportStartDate</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|			<ExchangePlanProperty>[Companies].Organization</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Organization</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Companies]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|			<ExchangePlanProperty>[Companies].Organization</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>CounterpartyDebtor</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>CounterpartyDebtor</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Companies]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|			<ExchangePlanProperty>[Companies].Organization</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Creditor</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Creditor</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Companies]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<Group>
			|			<BooleanGroupValue>AND</BooleanGroupValue>
			|			<FilterElement>
			|				<IsConstantString>TRUE</IsConstantString>
			|				<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|				<ExchangePlanProperty>UseFilterByCompanies</ExchangePlanProperty>
			|				<ComparisonType>Equal</ComparisonType>
			|				<ObjectProperty1>FALSE</ObjectProperty1>
			|				<TableOfExchangePlanProperties>
			|					<Property>
			|						<Description>UseFilterByCompanies</Description>
			|						<TYPE>BOOLEAN</TYPE>
			|						<Kind>Attribute</Kind>
			|					</Property>
			|				</TableOfExchangePlanProperties>
			|			</FilterElement>
			|			<Group>
			|				<BooleanGroupValue>OR</BooleanGroupValue>
			|				<FilterElement>
			|					<IsConstantString>TRUE</IsConstantString>
			|					<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|					<ExchangePlanProperty>UnloadManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>Equal</ComparisonType>
			|					<ObjectProperty1>TRUE</ObjectProperty1>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>UnloadManagementCompany</Description>
			|							<TYPE>BOOLEAN</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|				<FilterElement>
			|					<IsConstantString>FALSE</IsConstantString>
			|					<ObjectPropertyType>CatalogRef.Counterparties</ObjectPropertyType>
			|					<ExchangePlanProperty>ManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>NotEqual</ComparisonType>
			|					<ObjectProperty1>Creditor</ObjectProperty1>
			|					<ObjectPropertiesTable>
			|						<Property>
			|							<Description>Creditor</Description>
			|							<TYPE>CatalogRef.Counterparties</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</ObjectPropertiesTable>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>ManagementCompany</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|			</Group>
			|		</Group>
			|	</Group>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeUP2ZUP3</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>CashExchange</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeOfUPRMC</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>";
EndFunction

Function Document_DebtOffset3_SelectionByObjectProperties()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>Posted</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>TRUE</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Posted</Description>
			|				<TYPE>BOOLEAN</TYPE>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<ObjectPropertyType>EnumRef.ARAPSettlemenParticipantTypes</ObjectPropertyType>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>CounterpartyCreditorType</ObjectProperty1>
			|			<Kind>ValueAlgorithm</Kind>
			|			<ConstantValue>VALUE = Enums.ARAPSettlemenParticipantTypes.OrganizationClient;</ConstantValue>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>CounterpartyCreditorType</Description>
			|					<TYPE>EnumRef.ARAPSettlemenParticipantTypes</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|		</FilterElement>
			|		<FilterElement>
			|			<ObjectPropertyType>EnumRef.ARAPSettlemenParticipantTypes</ObjectPropertyType>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>CounterpartyCreditorType</ObjectProperty1>
			|			<Kind>ValueAlgorithm</Kind>
			|			<ConstantValue>VALUE = Enums.ARAPSettlemenParticipantTypes.CompanyVendor;</ConstantValue>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>CounterpartyCreditorType</Description>
			|					<TYPE>EnumRef.ARAPSettlemenParticipantTypes</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|		</FilterElement>
			|	</Group>
			|</FilterByObjectProperties>";
EndFunction

Procedure ORR_Document_ARAPSettlement3_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0)
	DataExchangeEventsTM.DocumentARAPSettlementBeforeProcessingORR(Object, Cancel);
EndProcedure

Procedure ORR_Document_ARAPSettlement3_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "TreasuryAndARAPAccounting";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_ARAPSettlement3_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "TreasuryAndARAPAccounting";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure

Procedure ORR_Document_ARAPSettlement3_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0)
	DataExchangeEventsTM.DocumentDebtOffsetAfterProcessing(Object, Upload0, Recipients, ORR.ExchangePlanName);
EndProcedure
#EndRegion
#Region Document_DepositCashIntoCashRegister
Procedure AddPRO_Document_DepositingFundsToCashRegister(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_DepositCashIntoCashRegister";
	
	NewRule.MetadataObjectName3 = "Document.DepositCashIntoCashRegister";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_13(),
		FilterByObjectProperties_4());
EndProcedure

Procedure ORR_Document_DepositCashIntoCashRegister_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "TreasuryAndARAPAccounting";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_DepositCashIntoCashRegister_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "TreasuryAndARAPAccounting";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure
#EndRegion
#Region Document_CashWithdrawalFromCashRegister
Procedure AddPRO_Document_WithdrawalOfFundsFromCashRegisterOfCashRegister(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_CashWithdrawalFromCashRegister";
	
	NewRule.MetadataObjectName3 = "Document.CashWithdrawalFromCashRegister";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_13(),
		FilterByObjectProperties_4());
EndProcedure

Procedure ORR_Document_CashWithdrawalFromCashRegister_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "TreasuryAndARAPAccounting";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_CashWithdrawalFromCashRegister_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "TreasuryAndARAPAccounting";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure
#EndRegion
#Region Document_PaymentCardTransaction
Procedure AddPRO_Document_PaymentCardOperation(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_PaymentCardTransaction";
	
	NewRule.MetadataObjectName3 = "Document.PaymentCardTransaction";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = True;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_18(),
		FilterByObjectProperties_4());
EndProcedure

Procedure ORR_Document_PaymentCardTransaction_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "TreasuryAndARAPAccounting";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_PaymentCardTransaction_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "TreasuryAndARAPAccounting";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure

Procedure ORR_Document_PaymentCardTransaction_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0)
	If Not Upload0 And Recipients.Count() > 0 Then
		If Not Common.RefExists(Object.Ref) Then
			Return
		EndIf;
		Query = New Query("SELECT 
								|RelatedDocuments.Ref AS Ref
								|FROM
								|	FilterCriterion.RelatedDocuments(&FilterCriteriaValue) AS RelatedDocuments
								|WHERE
								|	VALUETYPE(RelatedDocuments.Ref) = TYPE(Document.IssuedTaxInvoicePrepayment)");
		Query.SetParameter("FilterCriteriaValue",Object.Ref);
		
		Result = Query.Execute().Select();
		While Result.Next() Do
			TaxInvoice = Result.Ref.GetObject();
			ExecuteRegistrationRulesForObject(TaxInvoice, ORR.ExchangePlanName, Undefined);
		EndDo;
		
	EndIf;
EndProcedure
#EndRegion
#Region Document_BankReportOnAcquiringTransactions
Procedure AddPRO_Document_ReportOfBankOnAcquiringOperations(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_BankReportOnAcquiringTransactions";
	
	NewRule.MetadataObjectName3 = "Document.BankReportOnAcquiringTransactions";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_18(),
		FilterByObjectProperties_5());
EndProcedure

Procedure ORR_Document_BankReportOnAcquiringTransactions_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "TreasuryAndARAPAccounting";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_BankReportOnAcquiringTransactions_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "TreasuryAndARAPAccounting";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure
#EndRegion
#Region Document_BankReportOnAcquiringTransactions2
Procedure AddPRO_Document_ReportOfBankOnAcquiringOperations2(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_BankReportOnAcquiringTransactions2";
	
	NewRule.MetadataObjectName3 = "Document.BankReportOnAcquiringTransactions";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		Document_ReportOfBankOnAcquiringOperations2_SelectionByPropertiesOfExchangePlan(),
		FilterByObjectProperties_4());
EndProcedure

Function Document_ReportOfBankOnAcquiringOperations2_SelectionByPropertiesOfExchangePlan()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>FALSE</IsConstantString>
			|		<ObjectPropertyType>DATE</ObjectPropertyType>
			|		<ExchangePlanProperty>DocumentsExportStartDate</ExchangePlanProperty>
			|		<ComparisonType>GreaterOrEqual</ComparisonType>
			|		<ObjectProperty1>DATE</ObjectProperty1>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>DATE</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>DocumentsExportStartDate</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|			<ExchangePlanProperty>[Companies].Organization</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Organization</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Companies]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<Group>
			|			<BooleanGroupValue>AND</BooleanGroupValue>
			|			<FilterElement>
			|				<IsConstantString>TRUE</IsConstantString>
			|				<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|				<ExchangePlanProperty>UseFilterByCompanies</ExchangePlanProperty>
			|				<ComparisonType>Equal</ComparisonType>
			|				<ObjectProperty1>FALSE</ObjectProperty1>
			|				<TableOfExchangePlanProperties>
			|					<Property>
			|						<Description>UseFilterByCompanies</Description>
			|						<TYPE>BOOLEAN</TYPE>
			|						<Kind>Attribute</Kind>
			|					</Property>
			|				</TableOfExchangePlanProperties>
			|			</FilterElement>
			|			<Group>
			|				<BooleanGroupValue>OR</BooleanGroupValue>
			|				<FilterElement>
			|					<IsConstantString>FALSE</IsConstantString>
			|					<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|					<ExchangePlanProperty>ManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>NotEqual</ComparisonType>
			|					<ObjectProperty1>Organization</ObjectProperty1>
			|					<ObjectPropertiesTable>
			|						<Property>
			|							<Description>Organization</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</ObjectPropertiesTable>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>ManagementCompany</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|				<FilterElement>
			|					<IsConstantString>TRUE</IsConstantString>
			|					<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|					<ExchangePlanProperty>UnloadManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>Equal</ComparisonType>
			|					<ObjectProperty1>TRUE</ObjectProperty1>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>UnloadManagementCompany</Description>
			|							<TYPE>BOOLEAN</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|			</Group>
			|		</Group>
			|	</Group>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>ExchangeFormatVersion</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>1.0.beta</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>ExchangeFormatVersion</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeUP2ZUP3</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>CashExchange</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeOfUPRMC</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>";
EndFunction

Procedure ORR_Document_BankReportOnAcquiringTransactions2_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "TreasuryAndARAPAccounting";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	
	// Special logic: there is no filter by amount, so the format version must be higher than 1.0.beta.
	QueryText = StrReplace(QueryText, "AND ExchangePlanMainTable.SettingsMode <> ""ExchangeUP2ZUP3""",
	"AND ExchangePlanMainTable.SettingsMode <> ""ExchangeUP2ZUP3"" AND ExchangePlanMainTable.ExchangeFormatVersion <> ""1.0.beta""");
	QueryText = StrReplace(QueryText, "AND OrganizationExchangePlan.Ref.SettingsMode <> ""ExchangeUP2ZUP3""",
	"AND OrganizationExchangePlan.Ref.SettingsMode <> ""ExchangeUP2ZUP3"" AND OrganizationExchangePlan.Ref.ExchangeFormatVersion <> ""1.0.beta""");
EndProcedure

Procedure ORR_Document_BankReportOnAcquiringTransactions2_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "TreasuryAndARAPAccounting";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
	
	// Special logic: there is no filter by amount, so the format version must be higher than 1.0.beta.
	QueryText = StrReplace(QueryText, "AND ExchangePlanMainTable.SettingsMode <> ""ExchangeUP2ZUP3""",
	"AND ExchangePlanMainTable.SettingsMode <> ""ExchangeUP2ZUP3"" AND ExchangePlanMainTable.ExchangeFormatVersion <> ""1.0.beta""");
	QueryText = StrReplace(QueryText, "AND OrganizationExchangePlan.Ref.SettingsMode <> ""ExchangeUP2ZUP3""",
	"AND OrganizationExchangePlan.Ref.SettingsMode <> ""ExchangeUP2ZUP3"" AND OrganizationExchangePlan.Ref.ExchangeFormatVersion <> ""1.0.beta""");
EndProcedure
#EndRegion
#Region Document_BankAccountReceiptNote
Procedure AddPRO_Document_ReceiptOfNonCashFunds(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_BankAccountReceiptNote";
	
	NewRule.MetadataObjectName3 = "Document.BankAccountReceiptNote";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = True;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_18(),
		Document_IncomingPaymentBankAccount_SelectionAccordingToPropertiesOfObject());
EndProcedure

Function Document_IncomingPaymentBankAccount_SelectionAccordingToPropertiesOfObject()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>Posted</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>true</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Posted</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>ProcessedByBank</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>true</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>ProcessedByBank</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|</FilterByObjectProperties>";
EndFunction

Procedure ORR_Document_BankAccountReceiptNote_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "TreasuryAndARAPAccounting";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_BankAccountReceiptNote_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "TreasuryAndARAPAccounting";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure

Procedure ORR_Document_BankAccountReceiptNote_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0)
	If Not Upload0 And Recipients.Count() > 0 Then
		If Not Common.RefExists(Object.Ref) Then
			Return
		EndIf;
		Query = New Query("SELECT 
								|RelatedDocuments.Ref AS Ref
								|FROM
								|	FilterCriterion.RelatedDocuments(&FilterCriteriaValue) AS RelatedDocuments
								|WHERE
								|	VALUETYPE(RelatedDocuments.Ref) = TYPE(Document.IssuedTaxInvoicePrepayment)");
		Query.SetParameter("FilterCriteriaValue",Object.Ref);
		
		Result = Query.Execute().Select();
		While Result.Next() Do
			TaxInvoice = Result.Ref.GetObject();
			ExecuteRegistrationRulesForObject(TaxInvoice, ORR.ExchangePlanName, Object.DataExchange.Sender);
		EndDo;
		
	EndIf;
EndProcedure
#EndRegion
#Region Document_CashAccountReceiptNote
Procedure AddPRO_Document_CashReceiptOrder(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_CashAccountReceiptNote";
	
	NewRule.MetadataObjectName3 = "Document.CashAccountReceiptNote";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = True;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_18(),
		Document_CashAccountReceiptNote_FilterByObjectProperties());
EndProcedure

Function Document_CashAccountReceiptNote_FilterByObjectProperties()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>Posted</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>true</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Posted</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>EnumRef.BusinessTransactions</ObjectPropertyType>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>BusinessOperation</ObjectProperty1>
			|		<Kind>ValueAlgorithm</Kind>
			|		<ConstantValue>Value = Enums.BusinessTransactions.CashReceiptFromCashRegister;</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>BusinessOperation</Description>
			|				<Type>EnumRef.BusinessTransactions</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|</FilterByObjectProperties>";
EndFunction

Procedure ORR_Document_CashAccountReceiptNote_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "TreasuryAndARAPAccounting";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_CashAccountReceiptNote_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "TreasuryAndARAPAccounting";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure

Procedure ORR_Document_CashAccountReceiptNote_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0)
	If Not Upload0 And Recipients.Count() > 0 Then
		If Not Common.RefExists(Object.Ref) Then
			Return
		EndIf;
		Query = New Query("SELECT 
								|RelatedDocuments.Ref AS Ref
								|FROM
								|	FilterCriterion.RelatedDocuments(&FilterCriteriaValue) AS RelatedDocuments
								|WHERE
								|	VALUETYPE(RelatedDocuments.Ref) = TYPE(Document.IssuedTaxInvoicePrepayment)");
		Query.SetParameter("FilterCriteriaValue",Object.Ref);
		
		Result = Query.Execute().Select();
		While Result.Next() Do
			TaxInvoice = Result.Ref.GetObject();
			ExecuteRegistrationRulesForObject(TaxInvoice, ORR.ExchangePlanName, Object.DataExchange.Sender);
		EndDo;
		
	EndIf;
EndProcedure
#EndRegion
#Region Document_CashVoucher
Procedure AddPRO_Document_SpendingCashOrder(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_CashVoucher";
	
	NewRule.MetadataObjectName3 = "Document.CashVoucher";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = True;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_18(),
		Document_CashVoucher_FilterByObjectProperties());
EndProcedure

Function Document_CashVoucher_FilterByObjectProperties()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>Posted</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>true</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Posted</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>EnumRef.BusinessTransactions</ObjectPropertyType>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>BusinessOperation</ObjectProperty1>
			|		<Kind>ValueAlgorithm</Kind>
			|		<ConstantValue>Value = Enums.BusinessTransactions.CashIssueToCashRegister;</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>BusinessOperation</Description>
			|				<Type>EnumRef.BusinessTransactions</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|</FilterByObjectProperties>";
EndFunction

Procedure ORR_Document_CashVoucher_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "TreasuryAndARAPAccounting";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_CashVoucher_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "TreasuryAndARAPAccounting";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure

Procedure ORR_Document_CashVoucher_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0)
	If Not Upload0 And Recipients.Count() > 0 Then
		If Not Common.RefExists(Object.Ref) Then
			Return
		EndIf;
		Query = New Query("SELECT 
								|RelatedDocuments.Ref AS Ref
								|FROM
								|	FilterCriterion.RelatedDocuments(&FilterCriteriaValue) AS RelatedDocuments
								|WHERE
								|	VALUETYPE(RelatedDocuments.Ref) = TYPE(Document.IssuedTaxInvoicePrepayment)
								|	OR VALUETYPE(RelatedDocuments.Ref) = TYPE(Document.ReceivedTaxInvoicePrepayment)");
								
		Query.SetParameter("FilterCriteriaValue",Object.Ref);
		
		Result = Query.Execute().Select();
		While Result.Next() Do
			TaxInvoice = Result.Ref.GetObject();
			ExecuteRegistrationRulesForObject(TaxInvoice, ORR.ExchangePlanName, Object.DataExchange.Sender);
		EndDo;
		
	EndIf;
EndProcedure
#EndRegion
#Region Document_BankAccountIssue
Procedure AddPRO_Document_DebitingNonCashFunds(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_BankAccountIssue";
	
	NewRule.MetadataObjectName3 = "Document.BankAccountIssue";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = True;
		
	SetFilters(NewRule, 
		Document_WriteOffOfNonCashFunds_SelectionAccordingToPropertiesOfExchangePlan(),
		Document_OutgoingSPaymentBankAccount_SelectionAccordingToPropertiesOfObject());
EndProcedure

Function Document_WriteOffOfNonCashFunds_SelectionAccordingToPropertiesOfExchangePlan()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>FALSE</IsConstantString>
			|		<ObjectPropertyType>DATE</ObjectPropertyType>
			|		<ExchangePlanProperty>DocumentsExportStartDate</ExchangePlanProperty>
			|		<ComparisonType>GreaterOrEqual</ComparisonType>
			|		<ObjectProperty1>DATE</ObjectProperty1>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>DATE</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>DocumentsExportStartDate</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|			<ExchangePlanProperty>[Companies].Organization</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Organization</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Companies]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<Group>
			|			<BooleanGroupValue>AND</BooleanGroupValue>
			|			<FilterElement>
			|				<IsConstantString>TRUE</IsConstantString>
			|				<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|				<ExchangePlanProperty>UseFilterByCompanies</ExchangePlanProperty>
			|				<ComparisonType>Equal</ComparisonType>
			|				<ObjectProperty1>FALSE</ObjectProperty1>
			|				<TableOfExchangePlanProperties>
			|					<Property>
			|						<Description>UseFilterByCompanies</Description>
			|						<TYPE>BOOLEAN</TYPE>
			|						<Kind>Attribute</Kind>
			|					</Property>
			|				</TableOfExchangePlanProperties>
			|			</FilterElement>
			|			<Group>
			|				<BooleanGroupValue>OR</BooleanGroupValue>
			|				<FilterElement>
			|					<IsConstantString>FALSE</IsConstantString>
			|					<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|					<ExchangePlanProperty>ManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>NotEqual</ComparisonType>
			|					<ObjectProperty1>Organization</ObjectProperty1>
			|					<ObjectPropertiesTable>
			|						<Property>
			|							<Description>Organization</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</ObjectPropertiesTable>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>ManagementCompany</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|				<FilterElement>
			|					<IsConstantString>FALSE</IsConstantString>
			|					<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|					<ExchangePlanProperty>ManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>NotEqual</ComparisonType>
			|					<ObjectProperty1>BankAccountBeneficiary.Owner</ObjectProperty1>
			|					<ObjectPropertiesTable>
			|						<Property>
			|							<Description>BankAccountBeneficiary</Description>
			|							<TYPE>CatalogRef.CompaniesBankAccounts</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|						<Property>
			|							<Description>Owner</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Property</Kind>
			|						</Property>
			|					</ObjectPropertiesTable>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>ManagementCompany</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|				<FilterElement>
			|					<IsConstantString>TRUE</IsConstantString>
			|					<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|					<ExchangePlanProperty>UnloadManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>Equal</ComparisonType>
			|					<ObjectProperty1>TRUE</ObjectProperty1>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>UnloadManagementCompany</Description>
			|							<TYPE>BOOLEAN</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|			</Group>
			|		</Group>
			|	</Group>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeUP2ZUP3</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>CashExchange</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeOfUPRMC</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>";
EndFunction

Function Document_OutgoingSPaymentBankAccount_SelectionAccordingToPropertiesOfObject()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>Posted</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>true</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Posted</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>ProcessedByBank</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>true</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>ProcessedByBank</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>PaymentWithConversion</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>false</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>PaymentWithConversion</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|</FilterByObjectProperties>";
EndFunction

Procedure ORR_Document_BankAccountIssue_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "TreasuryAndARAPAccounting";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_BankAccountIssue_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "TreasuryAndARAPAccounting";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure

Procedure ORR_Document_BankAccountIssue_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0)
	If Not Upload0 And Recipients.Count() > 0 Then
		If Not Common.RefExists(Object.Ref) Then
			Return
		EndIf;
		Query = New Query("SELECT 
								|RelatedDocuments.Ref AS Ref
								|FROM
								|	FilterCriterion.RelatedDocuments(&FilterCriteriaValue) AS RelatedDocuments
								|WHERE
								|	VALUETYPE(RelatedDocuments.Ref) = TYPE(Document.IssuedTaxInvoicePrepayment)
								|	OR VALUETYPE(RelatedDocuments.Ref) = TYPE(Document.ReceivedTaxInvoicePrepayment)");
								
		Query.SetParameter("FilterCriteriaValue",Object.Ref);
		
		Result = Query.Execute().Select();
		While Result.Next() Do
			TaxInvoice = Result.Ref.GetObject();
			ExecuteRegistrationRulesForObject(TaxInvoice, ORR.ExchangePlanName, Object.DataExchange.Sender);
		EndDo;
		
	EndIf;
EndProcedure
#EndRegion
#Region Document_CashAccountReceiptNote2
Procedure AddPRO_Document_CashReceiptOrder2(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_CashAccountReceiptNote2";
	
	NewRule.MetadataObjectName3 = "Document.CashAccountReceiptNote";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = True;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_13(),
		Document_IncomingPaymentCashAccount2_SelectionAccordingToPropertiesOfObject());
EndProcedure

Function Document_IncomingPaymentCashAccount2_SelectionAccordingToPropertiesOfObject()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>Posted</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>true</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Posted</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>EnumRef.BusinessTransactions</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>BusinessOperation</ObjectProperty1>
			|		<Kind>ValueAlgorithm</Kind>
			|		<ConstantValue>Value = Enums.BusinessTransactions.CashReceiptFromCashRegister;</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>BusinessOperation</Description>
			|				<Type>EnumRef.BusinessTransactions</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|</FilterByObjectProperties>";
EndFunction

Procedure ORR_Document_CashAccountReceiptNote2_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "TreasuryAndARAPAccounting";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_CashAccountReceiptNote2_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "TreasuryAndARAPAccounting";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure

Procedure ORR_Document_CashAccountReceiptNote2_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0)
	If Not Upload0 And Recipients.Count() > 0 Then
		If Not Common.RefExists(Object.Ref) Then
			Return
		EndIf;
		Query = New Query("SELECT 
								|RelatedDocuments.Ref AS Ref
								|FROM
								|	FilterCriterion.RelatedDocuments(&FilterCriteriaValue) AS RelatedDocuments
								|WHERE
								|	VALUETYPE(RelatedDocuments.Ref) = TYPE(Document.IssuedTaxInvoicePrepayment)");
		Query.SetParameter("FilterCriteriaValue",Object.Ref);
		
		Result = Query.Execute().Select();
		While Result.Next() Do
			TaxInvoice = Result.Ref.GetObject();
			ExecuteRegistrationRulesForObject(TaxInvoice, ORR.ExchangePlanName, Object.DataExchange.Sender);
		EndDo;
		
	EndIf;
EndProcedure
#EndRegion
#Region Document_CashVoucher2
Procedure AddPRO_Document_SpendingCashOrder2(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_CashVoucher2";
	
	NewRule.MetadataObjectName3 = "Document.CashVoucher";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = True;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_13(),
		Document_OutgoingsPaymentCashAccount2_SelectionByObjectProperties());
EndProcedure

Function Document_OutgoingsPaymentCashAccount2_SelectionByObjectProperties()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>Posted</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>true</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Posted</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>EnumRef.BusinessTransactions</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>BusinessOperation</ObjectProperty1>
			|		<Kind>ValueAlgorithm</Kind>
			|		<ConstantValue>Value = Enums.BusinessTransactions.CashIssueToCashRegister;</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>BusinessOperation</Description>
			|				<Type>EnumRef.BusinessTransactions</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|</FilterByObjectProperties>";
EndFunction

Procedure ORR_Document_CashVoucher2_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "TreasuryAndARAPAccounting";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_CashVoucher2_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "TreasuryAndARAPAccounting";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure

Procedure ORR_Document_CashVoucher2_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0)
	If Not Upload0 And Recipients.Count() > 0 Then
		If Not Common.RefExists(Object.Ref) Then
			Return
		EndIf;
		Query = New Query("SELECT 
								|RelatedDocuments.Ref AS Ref
								|FROM
								|	FilterCriterion.RelatedDocuments(&FilterCriteriaValue) AS RelatedDocuments
								|WHERE
								|	VALUETYPE(RelatedDocuments.Ref) = TYPE(Document.IssuedTaxInvoicePrepayment)
								|	OR VALUETYPE(RelatedDocuments.Ref) = TYPE(Document.ReceivedTaxInvoicePrepayment)");
								
		Query.SetParameter("FilterCriteriaValue",Object.Ref);
		
		Result = Query.Execute().Select();
		While Result.Next() Do
			TaxInvoice = Result.Ref.GetObject();
			ExecuteRegistrationRulesForObject(TaxInvoice, ORR.ExchangePlanName, Object.DataExchange.Sender);
		EndDo;
		
	EndIf;
EndProcedure
#EndRegion
#Region Document_ExpenseReport
Procedure AddPRO_Document_AdvanceReport(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_ExpenseReport";
	
	NewRule.MetadataObjectName3 = "Document.ExpenseReport";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_18(),
		Document_AdvanceReport_SelectionByObjectProperties());
EndProcedure

Function Document_AdvanceReport_SelectionByObjectProperties()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>Posted</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>true</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Posted</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>EnumRef.ExpenseReportStatuses</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>Status</ObjectProperty1>
			|		<Kind>ValueAlgorithm</Kind>
			|		<ConstantValue>Value = Enums.ExpenseReportStatuses.Upholded;</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Status</Description>
			|				<Type>EnumRef.ExpenseReportStatuses</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|</FilterByObjectProperties>";
EndFunction

Procedure ORR_Document_ExpenseReport_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "TreasuryAndARAPAccounting";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_ExpenseReport_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "TreasuryAndARAPAccounting";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure
#EndRegion

#Region Document_PaymentRequest
Procedure AddPRO_Document_RequestForSpendingFunds(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_PaymentRequest";
	
	NewRule.MetadataObjectName3 = "Document.PaymentRequest";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		Document_ApplicationForSpendingFunds_SelectionByPropertiesOfExchangePlan(),
		Document_PaymentRequest_FilterByObjectProperties());
EndProcedure

Function Document_ApplicationForSpendingFunds_SelectionByPropertiesOfExchangePlan()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>FALSE</IsConstantString>
			|		<ObjectPropertyType>DATE</ObjectPropertyType>
			|		<ExchangePlanProperty>DocumentsExportStartDate</ExchangePlanProperty>
			|		<ComparisonType>GreaterOrEqual</ComparisonType>
			|		<ObjectProperty1>DATE</ObjectProperty1>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>DATE</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>DocumentsExportStartDate</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|			<ExchangePlanProperty>[Companies].Organization</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Organization</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Companies]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|			<ExchangePlanProperty>[Companies].Organization</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>CompanyRecipient</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>CompanyRecipient</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Companies]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|			<ExchangePlanProperty>[Companies].Organization</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>BankAccountBeneficiary.Owner</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>BankAccountBeneficiary</Description>
			|					<TYPE>CatalogRef.CompaniesBankAccounts</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Owner</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Property</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Companies]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<Group>
			|			<BooleanGroupValue>AND</BooleanGroupValue>
			|			<FilterElement>
			|				<IsConstantString>TRUE</IsConstantString>
			|				<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|				<ExchangePlanProperty>UseFilterByCompanies</ExchangePlanProperty>
			|				<ComparisonType>Equal</ComparisonType>
			|				<ObjectProperty1>FALSE</ObjectProperty1>
			|				<TableOfExchangePlanProperties>
			|					<Property>
			|						<Description>UseFilterByCompanies</Description>
			|						<TYPE>BOOLEAN</TYPE>
			|						<Kind>Attribute</Kind>
			|					</Property>
			|				</TableOfExchangePlanProperties>
			|			</FilterElement>
			|			<Group>
			|				<BooleanGroupValue>OR</BooleanGroupValue>
			|				<FilterElement>
			|					<IsConstantString>FALSE</IsConstantString>
			|					<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|					<ExchangePlanProperty>ManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>NotEqual</ComparisonType>
			|					<ObjectProperty1>Organization</ObjectProperty1>
			|					<ObjectPropertiesTable>
			|						<Property>
			|							<Description>Organization</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</ObjectPropertiesTable>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>ManagementCompany</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|				<FilterElement>
			|					<IsConstantString>FALSE</IsConstantString>
			|					<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|					<ExchangePlanProperty>ManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>NotEqual</ComparisonType>
			|					<ObjectProperty1>BankAccountBeneficiary.Owner</ObjectProperty1>
			|					<ObjectPropertiesTable>
			|						<Property>
			|							<Description>BankAccountBeneficiary</Description>
			|							<TYPE>CatalogRef.CompaniesBankAccounts</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|						<Property>
			|							<Description>Owner</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Property</Kind>
			|						</Property>
			|					</ObjectPropertiesTable>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>ManagementCompany</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|				<FilterElement>
			|					<IsConstantString>TRUE</IsConstantString>
			|					<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|					<ExchangePlanProperty>UnloadManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>Equal</ComparisonType>
			|					<ObjectProperty1>TRUE</ObjectProperty1>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>UnloadManagementCompany</Description>
			|							<TYPE>BOOLEAN</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|			</Group>
			|		</Group>
			|	</Group>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>UniversalExchange</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>CashExchange</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeOfUPRMC</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>";
EndFunction

Function Document_PaymentRequest_FilterByObjectProperties()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>Posted</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>true</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Posted</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>PaymentWithConversion</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>false</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>PaymentWithConversion</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|</FilterByObjectProperties>";
EndFunction

Procedure ORR_Document_PaymentRequest_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "TreasuryAndARAPAccounting";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_PaymentRequest_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "TreasuryAndARAPAccounting";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure
#EndRegion
#Region Document_LoanAndDepositInterestCharge
Procedure AddPRO_Document_AccrualOfLoansAndDeposits(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_LoanAndDepositInterestCharge";
	
	NewRule.MetadataObjectName3 = "Document.LoanAndDepositInterestCharge";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = True;
		
	SetFilters(NewRule, 
		Document_LoanAndDepositInterestCharge_FilterByExchangePlanProperties(),
		FilterByObjectProperties_4());
EndProcedure
Function Document_LoanAndDepositInterestCharge_FilterByExchangePlanProperties()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>FALSE</IsConstantString>
			|		<ObjectPropertyType>DATE</ObjectPropertyType>
			|		<ExchangePlanProperty>DocumentsExportStartDate</ExchangePlanProperty>
			|		<ComparisonType>GreaterOrEqual</ComparisonType>
			|		<ObjectProperty1>DATE</ObjectProperty1>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>DATE</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>DocumentsExportStartDate</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|			<ExchangePlanProperty>[Companies].Organization</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Organization</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Companies]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<Group>
			|			<BooleanGroupValue>AND</BooleanGroupValue>
			|			<FilterElement>
			|				<IsConstantString>TRUE</IsConstantString>
			|				<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|				<ExchangePlanProperty>UseFilterByCompanies</ExchangePlanProperty>
			|				<ComparisonType>Equal</ComparisonType>
			|				<ObjectProperty1>FALSE</ObjectProperty1>
			|				<TableOfExchangePlanProperties>
			|					<Property>
			|						<Description>UseFilterByCompanies</Description>
			|						<TYPE>BOOLEAN</TYPE>
			|						<Kind>Attribute</Kind>
			|					</Property>
			|				</TableOfExchangePlanProperties>
			|			</FilterElement>
			|			<Group>
			|				<BooleanGroupValue>OR</BooleanGroupValue>
			|				<FilterElement>
			|					<IsConstantString>FALSE</IsConstantString>
			|					<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|					<ExchangePlanProperty>ManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>NotEqual</ComparisonType>
			|					<ObjectProperty1>Organization</ObjectProperty1>
			|					<ObjectPropertiesTable>
			|						<Property>
			|							<Description>Organization</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</ObjectPropertiesTable>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>ManagementCompany</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|				<FilterElement>
			|					<IsConstantString>TRUE</IsConstantString>
			|					<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|					<ExchangePlanProperty>UnloadManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>Equal</ComparisonType>
			|					<ObjectProperty1>TRUE</ObjectProperty1>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>UnloadManagementCompany</Description>
			|							<TYPE>BOOLEAN</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|			</Group>
			|		</Group>
			|	</Group>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeUP2ZUP3</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>CashExchange</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeOfUPRMC</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>";
EndFunction
Procedure ORR_Document_LoanAndDepositInterestCharge_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "TreasuryAndARAPAccounting";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_LoanAndDepositInterestCharge_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "TreasuryAndARAPAccounting";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure

Procedure ORR_Document_LoanAndDepositInterestCharge_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0)
	If Not Upload0 And Recipients.Count() > 0 Then
		If Not Common.RefExists(Object.Ref) Then
			Return
		EndIf;
		Query = New Query("SELECT 
								|RelatedDocuments.Ref AS Ref
								|FROM
								|	FilterCriterion.RelatedDocuments(&FilterCriteriaValue) AS RelatedDocuments
								|WHERE
								|	VALUETYPE(RelatedDocuments.Ref) = TYPE(Document.IssuedTaxInvoicePrepayment)");
		Query.SetParameter("FilterCriteriaValue",Object.Ref);
		
		Result = Query.Execute().Select();
		While Result.Next() Do
			TaxInvoice = Result.Ref.GetObject();
			ExecuteRegistrationRulesForObject(TaxInvoice, ORR.ExchangePlanName, Object.DataExchange.Sender);
		EndDo;
		
	EndIf;
EndProcedure
#EndRegion
#Region Document_SourceDocument
Procedure AddPRO_Document_PrimaryDocument(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_SourceDocument";
	
	NewRule.MetadataObjectName3 = "Document.SourceDocument";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_18(),
		FilterByObjectProperties_4());
EndProcedure

Procedure ORR_Document_SourceDocument_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "TreasuryAndARAPAccounting, Warehouse, Purchases, Sales, Return leftovers";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_SourceDocument_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "TreasuryAndARAPAccounting, Warehouse, Purchases, Sales, Return leftovers";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure
#EndRegion

#Region Document_ARAPAdjustment
Procedure AddPRO_Document_DebtAdjustment(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_ARAPAdjustment";
	
	NewRule.MetadataObjectName3 = "Document.ARAPAdjustment";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_18(),
		Document_DebtAdjustment_SelectionByObjectProperties());
EndProcedure

Function Document_DebtAdjustment_SelectionByObjectProperties()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>Posted</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>true</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Posted</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>EnumRef.BusinessTransactions</ObjectPropertyType>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>BusinessOperation</ObjectProperty1>
			|		<Kind>ValueAlgorithm</Kind>
			|		<ConstantValue>Value = Enums.BusinessTransactions.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance;</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>BusinessOperation</Description>
			|				<Type>EnumRef.BusinessTransactions</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>EnumRef.BusinessTransactions</ObjectPropertyType>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>BusinessOperation</ObjectProperty1>
			|		<Kind>ValueAlgorithm</Kind>
			|		<ConstantValue>Value = Enums.BusinessTransactions.AccrualOfAccountsReceivable;</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>BusinessOperation</Description>
			|				<Type>EnumRef.BusinessTransactions</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|</FilterByObjectProperties>";
EndFunction

Procedure ORR_Document_ARAPAdjustment_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "TreasuryAndARAPAccounting";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_ARAPAdjustment_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "TreasuryAndARAPAccounting";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure
#EndRegion
#Region Document_CustomerInvoiceServices
Procedure AddPRO_Document_ReportOfCompletedWorks(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_CustomerInvoiceServices";
	
	NewRule.MetadataObjectName3 = "Document.CustomerInvoiceServices";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = True;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_18(),
		FilterByObjectProperties_4());
EndProcedure

Procedure ORR_Document_CustomerInvoiceServices_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Sales";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_CustomerInvoiceServices_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Sales";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure

Procedure ORR_Document_CustomerInvoiceServices_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0)
EndProcedure
#EndRegion
#Region Document_ReturnOfGoodsFromCustomer
Procedure AddPRO_Document_ReturnOfGoodsFromCustomer(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_ReturnOfGoodsFromCustomer";
	
	NewRule.MetadataObjectName3 = "Document.ReturnOfGoodsFromCustomer";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = True;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = True;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_16(),
		Document_ReturnOfGoodsFromCustomer_FilterByObjectProperties());
EndProcedure

Function Document_ReturnOfGoodsFromCustomer_FilterByObjectProperties()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>Posted</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>true</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Posted</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>EnumRef.VATTaxationTypes</ObjectPropertyType>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>VATTaxation</ObjectProperty1>
			|		<Kind>ValueAlgorithm</Kind>
			|		<ConstantValue>Value = PredefinedValue(""Enum.VATTaxationTypes.SubjectToVATFromPriceDifference"");</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>VATTaxation</Description>
			|				<Type>EnumRef.VATTaxationTypes</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|</FilterByObjectProperties>";
EndFunction

Procedure ORR_Document_ReturnOfGoodsFromCustomer_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0)
	DocumentBasis = Object.DocumentSalesOfGoodsAndServices;
	If ValueIsFilled(DocumentBasis) And TypeOf(DocumentBasis) = Type("DocumentRef.CustomerInvoice") Then
		AttributesStructure1 = Common.ObjectAttributesValues(DocumentBasis, "Posted,BusinessOperation");
		If Not AttributesStructure1.Posted  Then 
			Cancel = True;
		EndIf;
	EndIf;
EndProcedure

Procedure ORR_Document_ReturnOfGoodsFromCustomer_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Sales";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_ReturnOfGoodsFromCustomer_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Sales";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure

Procedure ORR_Document_ReturnOfGoodsFromCustomer_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0)
	If Not Upload0 And Recipients.Count() > 0 Then
		If Not Common.RefExists(Object.Ref) Then
			Return
		EndIf;
		Query = New Query("SELECT 
								|RelatedDocuments.Ref AS Ref
								|FROM
								|	FilterCriterion.RelatedDocuments(&FilterCriteriaValue) AS RelatedDocuments
								|WHERE
								|	VALUETYPE(RelatedDocuments.Ref) = TYPE(Document.IssuedTaxInvoicePrepayment)
								|");
								
		Query.SetParameter("FilterCriteriaValue",Object.Ref);
		
		Result = Query.Execute().Select();
		While Result.Next() Do
			TaxInvoice = Result.Ref.GetObject();
			ExecuteRegistrationRulesForObject(TaxInvoice, ORR.ExchangePlanName, Undefined);
		EndDo;
		
	EndIf;
EndProcedure
#EndRegion
#Region Document_SalesOrder
Procedure AddPRO_Document_CustomerOrder(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_SalesOrder";
	
	NewRule.MetadataObjectName3 = "Document.SalesOrder";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = True;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = True;
		
	SetFilters(NewRule, 
		Document_SalesOrder_SelectionAccordingToPropertiesOfExchangePlan(),
		FilterByObjectProperties_4());
EndProcedure

Function Document_SalesOrder_SelectionAccordingToPropertiesOfExchangePlan()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>FALSE</IsConstantString>
			|		<ObjectPropertyType>DATE</ObjectPropertyType>
			|		<ExchangePlanProperty>DocumentsExportStartDate</ExchangePlanProperty>
			|		<ComparisonType>GreaterOrEqual</ComparisonType>
			|		<ObjectProperty1>DATE</ObjectProperty1>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>DATE</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>DocumentsExportStartDate</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|			<ExchangePlanProperty>[Companies].Organization</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Organization</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Companies]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<Group>
			|			<BooleanGroupValue>AND</BooleanGroupValue>
			|			<FilterElement>
			|				<IsConstantString>TRUE</IsConstantString>
			|				<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|				<ExchangePlanProperty>UseFilterByCompanies</ExchangePlanProperty>
			|				<ComparisonType>Equal</ComparisonType>
			|				<ObjectProperty1>FALSE</ObjectProperty1>
			|				<TableOfExchangePlanProperties>
			|					<Property>
			|						<Description>UseFilterByCompanies</Description>
			|						<TYPE>BOOLEAN</TYPE>
			|						<Kind>Attribute</Kind>
			|					</Property>
			|				</TableOfExchangePlanProperties>
			|			</FilterElement>
			|			<Group>
			|				<BooleanGroupValue>OR</BooleanGroupValue>
			|				<FilterElement>
			|					<IsConstantString>FALSE</IsConstantString>
			|					<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|					<ExchangePlanProperty>ManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>NotEqual</ComparisonType>
			|					<ObjectProperty1>Organization</ObjectProperty1>
			|					<ObjectPropertiesTable>
			|						<Property>
			|							<Description>Organization</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</ObjectPropertiesTable>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>ManagementCompany</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|				<FilterElement>
			|					<IsConstantString>TRUE</IsConstantString>
			|					<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|					<ExchangePlanProperty>UnloadManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>Equal</ComparisonType>
			|					<ObjectProperty1>TRUE</ObjectProperty1>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>UnloadManagementCompany</Description>
			|							<TYPE>BOOLEAN</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|			</Group>
			|		</Group>
			|	</Group>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Warehouses</ObjectPropertyType>
			|			<ExchangePlanProperty>[Warehouses].Warehouse</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Warehouse</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Warehouse</Description>
			|					<TYPE>CatalogRef.Warehouses</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Warehouses]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Warehouse</Description>
			|					<TYPE>CatalogRef.Warehouses</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<FilterElement>
			|			<IsConstantString>TRUE</IsConstantString>
			|			<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|			<ExchangePlanProperty>UseFilterByWarehouses</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>FALSE</ObjectProperty1>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>UseFilterByWarehouses</Description>
			|					<TYPE>BOOLEAN</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|	</Group>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeUP2ZUP3</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeOfUPRMC</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>";
EndFunction

Procedure ORR_Document_SalesOrder_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0)
	//checking the use of the functional option Use the expanded ability of the Client
	FederalDistrict = GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder");
	If FederalDistrict Then
		If Object.Status = Enums.SalesOrderStatuses.NotApproved Then
			Cancel = True;
		EndIf;
	EndIf;
	
	// Checking that there is at least one undelivered line in the order, otherwise we do not register
	ThereIsUnreleasedLine = False;
	For Each String In Object.Goods Do
		If Not String.Canceled Then
			ThereIsUnreleasedLine = True;
			Break;
		EndIf;
	EndDo;
	
	If Not ThereIsUnreleasedLine Then
		Cancel = True;
	EndIf;
EndProcedure

Procedure ORR_Document_SalesOrder_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Sales";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_SalesOrder_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Sales";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure

Procedure ORR_Document_SalesOrder_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0)
	If Recipients.Count() > 0 And Object.DocumentAmount = 0 Then
		// Zero-sum orders are registered only for the format version 1.2 and later.
		MaxIndex_ = Recipients.UBound();
		For IndexOf = 0 To MaxIndex_ Do
			CurIndx = MaxIndex_ - IndexOf;
			CurRecipient = Recipients[CurIndx];
			FormatVersion = Common.ObjectAttributeValue(CurRecipient, "ExchangeFormatVersion");
			ToBeUnloaded = False;
			If Not (FormatVersion = "1.0.beta" Or Not ValueIsFilled(FormatVersion)) Then
				If Number(FormatVersion) >= Number("1.2") Then
					ToBeUnloaded = True;
				EndIf;
			EndIf;
			If Not ToBeUnloaded Then
				Recipients.Delete(CurIndx);
			EndIf;
		EndDo;
	EndIf;
EndProcedure
#EndRegion
#Region Document_SaleAdjustment
Procedure AddPRO_Document_ImplementationAdjustment(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_SaleAdjustment";
	
	NewRule.MetadataObjectName3 = "Document.SaleAdjustment";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = True;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = True;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_16(),
		Document_SaleAdjustment_FilterByObjectProperties());
EndProcedure

Function Document_SaleAdjustment_FilterByObjectProperties()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>Posted</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>true</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Posted</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>EnumRef.AdjustingEntryTypes</ObjectPropertyType>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>AdjustingEntryType</ObjectProperty1>
			|		<Kind>ValueAlgorithm</Kind>
			|		<ConstantValue>Value = Enums.AdjustingEntryTypes.AdjustmentByGoodsAndServices;</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>AdjustingEntryType</Description>
			|				<Type>EnumRef.AdjustingEntryTypes</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>EnumRef.VATTaxationTypes</ObjectPropertyType>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>VATTaxation</ObjectProperty1>
			|		<Kind>ValueAlgorithm</Kind>
			|		<ConstantValue>Value = PredefinedValue(""Enum.VATTaxationTypes.SubjectToVATFromPriceDifference"");</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>VATTaxation</Description>
			|				<Type>EnumRef.VATTaxationTypes</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>EnumRef.VATTaxationTypes</ObjectPropertyType>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>VATTaxation</ObjectProperty1>
			|		<Kind>ValueAlgorithm</Kind>
			|		<ConstantValue>Value = PredefinedValue(""Enum.VATTaxationTypes.SpaceActivity"");</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>VATTaxation</Description>
			|				<Type>EnumRef.VATTaxationTypes</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|</FilterByObjectProperties>";
EndFunction

Procedure ORR_Document_SaleAdjustment_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0)
	
	DocumentBasis = Common.ObjectAttributeValue(Object.Ref, "DocumentBasis");
	If ValueIsFilled(DocumentBasis) And TypeOf(DocumentBasis) = Type("DocumentRef.CustomerInvoice") Then
		AttributesStructure1 = Common.ObjectAttributesValues(DocumentBasis, "Posted,BusinessOperation");
		If Not AttributesStructure1.Posted Then 
			Cancel = True;
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(Object.DocumentBasis) Or TypeOf(Object.DocumentBasis) = Type("DocumentRef.ReportToMaterialProvider2_5") Then
		Cancel = True;
	EndIf;
	
	If Not ValueIsFilled(Object.DocumentBasis) Or TypeOf(Object.DocumentBasis) = Type("DocumentRef.SubcontractorReport2_5") Then
		Cancel = True;
	EndIf;
	
	
EndProcedure

Procedure ORR_Document_SaleAdjustment_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Sales";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_SaleAdjustment_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Sales";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure

Procedure ORR_Document_SaleAdjustment_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0)
EndProcedure
#EndRegion
#Region Document_ConsignmentReportFromCustomer
Procedure AddPRO_Document_CommissionAgentSReport(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_ConsignmentReportFromCustomer";
	
	NewRule.MetadataObjectName3 = "Document.ConsignmentReportFromCustomer";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = True;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_18(),
		FilterByObjectProperties_4());
EndProcedure

Procedure ORR_Document_ConsignmentReportFromCustomer_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataExchangeEventsTM.DocumentReportOfCommissionAgentToCommitteeWhenProcessingPro(Object, Cancel);
	If Not Cancel Then
		DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
		DataProcessingParameters.QueryText        = QueryText;
		DataProcessingParameters.QueryOptions    = QueryOptions;
		DataProcessingParameters.UseCache     = UseCache;
		DataProcessingParameters.Cancel               = Cancel;
		DataProcessingParameters.Object              = Object;
		DataProcessingParameters.AccountingSectionsByLine = "Sales";
	
		ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
		QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
		QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
		UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
		Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
		Object           = ParametersOfProcessingPROAfterProcessing.Object;
	EndIf;
EndProcedure

Procedure ORR_Document_ConsignmentReportFromCustomer_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataExchangeEventsTM.DocumentReportOfCommissionAgentToCommitteeWhenProcessingPro(Object, Cancel);
	If Not Cancel Then
		DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
		DataProcessingParameters.QueryText        = QueryText;
		DataProcessingParameters.QueryOptions    = QueryOptions;
		DataProcessingParameters.UseCache     = UseCache;
		DataProcessingParameters.Cancel               = Cancel;
		DataProcessingParameters.Object              = Object;
		DataProcessingParameters.Upload0            = Upload0;
		DataProcessingParameters.AccountingSectionsByLine = "Sales";
	
		ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
		QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
		QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
		UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
		Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
		Object           = ParametersOfProcessingPROAfterProcessing.Object;
		Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
	EndIf;
EndProcedure

Procedure ORR_Document_ConsignmentReportFromCustomer_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0)
EndProcedure
#EndRegion
#Region Document_WriteOffReportFromCommissionAgent
Procedure AddPRO_Document_CommissionAgentSReportOnDebiting(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_WriteOffReportFromCommissionAgent";
	
	NewRule.MetadataObjectName3 = "Document.WriteOffReportFromCommissionAgent";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_18(),
		FilterByObjectProperties_5());
EndProcedure

Procedure ORR_Document_WriteOffReportFromCommissionAgent_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Sales";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_WriteOffReportFromCommissionAgent_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Sales";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure
#EndRegion
#Region Document_ConsignmentReportToVendor
Procedure AddPRO_Document_ReportToCommittee(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_ConsignmentReportToVendor";
	
	NewRule.MetadataObjectName3 = "Document.ConsignmentReportToVendor";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = True;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_18(),
		FilterByObjectProperties_5());
EndProcedure

Procedure ORR_Document_ConsignmentReportToVendor_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataExchangeEventsTM.DocumentReportOfCommissionAgentToCommitteeWhenProcessingPro(Object, Cancel);
	If Not Cancel Then
		DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
		DataProcessingParameters.QueryText        = QueryText;
		DataProcessingParameters.QueryOptions    = QueryOptions;
		DataProcessingParameters.UseCache     = UseCache;
		DataProcessingParameters.Cancel               = Cancel;
		DataProcessingParameters.Object              = Object;
		DataProcessingParameters.AccountingSectionsByLine = "Sales";
	
		ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
		QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
		QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
		UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
		Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
		Object           = ParametersOfProcessingPROAfterProcessing.Object;
	EndIf;
EndProcedure

Procedure ORR_Document_ConsignmentReportToVendor_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataExchangeEventsTM.DocumentReportOfCommissionAgentToCommitteeWhenProcessingPro(Object, Cancel);
	If Not Cancel Then
		DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
		DataProcessingParameters.QueryText        = QueryText;
		DataProcessingParameters.QueryOptions    = QueryOptions;
		DataProcessingParameters.UseCache     = UseCache;
		DataProcessingParameters.Cancel               = Cancel;
		DataProcessingParameters.Object              = Object;
		DataProcessingParameters.Upload0            = Upload0;
		DataProcessingParameters.AccountingSectionsByLine = "Sales";
	
		ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
		QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
		QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
		UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
		Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
		Object           = ParametersOfProcessingPROAfterProcessing.Object;
		Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
	EndIf;
EndProcedure

Procedure ORR_Document_ConsignmentReportToVendor_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0)
EndProcedure
#EndRegion
#Region Document_PurchaseInvoiceConsignmentStockLost
Procedure AddPRO_Document_ReportToCommitteeOnWriteOffs(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_PurchaseInvoiceConsignmentStockLost";
	
	NewRule.MetadataObjectName3 = "Document.PurchaseInvoiceConsignmentStockLost";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_18(),
		FilterByObjectProperties_5());
EndProcedure

Procedure ORR_Document_PurchaseInvoiceConsignmentStockLost_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Sales";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_PurchaseInvoiceConsignmentStockLost_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Sales";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure
#EndRegion
#Region Document_CustomerInvoice
Procedure AddPRO_Document_SalesOfGoodsAndServices(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_CustomerInvoice";
	
	NewRule.MetadataObjectName3 = "Document.CustomerInvoice";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = True;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_16(),
		Document_SaleOfGoodsAndServices_SelectionByObjectProperties());
EndProcedure

Function Document_SaleOfGoodsAndServices_SelectionByObjectProperties()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>Posted</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>true</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Posted</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>EnumRef.StatusesOfCustomerInvoices</ObjectPropertyType>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>Status</ObjectProperty1>
			|		<Kind>ValueAlgorithm</Kind>
			|		<ConstantValue>Value = Enums.StatusesOfCustomerInvoices.ForPrepayment;</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Status</Description>
			|				<Type>EnumRef.StatusesOfCustomerInvoices</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>EnumRef.VATTaxationTypes</ObjectPropertyType>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>VATTaxation</ObjectProperty1>
			|		<Kind>ValueAlgorithm</Kind>
			|		<ConstantValue>Value = PredefinedValue(""Enum.VATTaxationTypes.SubjectToVATFromPriceDifference"");</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>VATTaxation</Description>
			|				<Type>EnumRef.VATTaxationTypes</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>EnumRef.VATTaxationTypes</ObjectPropertyType>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>VATTaxation</ObjectProperty1>
			|		<Kind>ValueAlgorithm</Kind>
			|		<ConstantValue>Value = PredefinedValue(""Enum.VATTaxationTypes.SpaceActivity"");</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>VATTaxation</Description>
			|				<Type>EnumRef.VATTaxationTypes</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>EnumRef.BusinessTransactions</ObjectPropertyType>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>BusinessOperation</ObjectProperty1>
			|		<Kind>ValueAlgorithm</Kind>
			|		<ConstantValue>Value = PredefinedValue(""Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit"");</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>BusinessOperation</Description>
			|				<Type>EnumRef.BusinessTransactions</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|</FilterByObjectProperties>";
EndFunction

Procedure ORR_Document_CustomerInvoice_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Sales";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_CustomerInvoice_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Sales";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure

Procedure ORR_Document_CustomerInvoice_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0)
EndProcedure
#EndRegion
#Region Document_CustomerInvoiceServicesAndAssets
Procedure AddPRO_Document_SaleOfServicesOtherAssets(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_CustomerInvoiceServicesAndAssets";
	
	NewRule.MetadataObjectName3 = "Document.CustomerInvoiceServicesAndAssets";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = True;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_18(),
		Document_SaleOfServicesOfOtherAssets_SelectionByObjectProperties());
EndProcedure

Function Document_SaleOfServicesOfOtherAssets_SelectionByObjectProperties()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>Posted</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>true</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Posted</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>EnumRef.BusinessTransactions</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>BusinessOperation</ObjectProperty1>
			|		<Kind>ValueAlgorithm</Kind>
			|		<ConstantValue>Value = Enums.BusinessTransactions.SaleToCustomer;</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>BusinessOperation</Description>
			|				<Type>EnumRef.BusinessTransactions</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>EnumRef.BusinessTransactions</ObjectPropertyType>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>BusinessOperation</ObjectProperty1>
			|		<Kind>ValueAlgorithm</Kind>
			|		<ConstantValue>Value = PredefinedValue(""Enum.BusinessTransactions.RenderRentalServices"") ;</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>BusinessOperation</Description>
			|				<Type>EnumRef.BusinessTransactions</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|</FilterByObjectProperties>";
EndFunction

Procedure ORR_Document_CustomerInvoiceServicesAndAssets_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Sales";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_CustomerInvoiceServicesAndAssets_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Sales";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure

Procedure ORR_Document_CustomerInvoiceServicesAndAssets_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0)
EndProcedure
#EndRegion
#Region Document_CustomerCommercialInvoice
Procedure AddPRO_Document_InvoiceForPaymentToClient(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_CustomerCommercialInvoice";
	
	NewRule.MetadataObjectName3 = "Document.CustomerCommercialInvoice";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = True;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_18(),
		FilterByObjectProperties_4());
EndProcedure

Procedure ORR_Document_CustomerCommercialInvoice_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Sales";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_CustomerCommercialInvoice_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Sales";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure

Procedure ORR_Document_CustomerCommercialInvoice_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0)
	If Not Upload0 And Recipients.Count() > 0 Then
		If Not Common.RefExists(Object.Ref) Then
			Return
		EndIf;
		Query = New Query("SELECT 
								|RelatedDocuments.Ref AS Ref
								|FROM
								|	FilterCriterion.RelatedDocuments(&FilterCriteriaValue) AS RelatedDocuments
								|WHERE
								|	VALUETYPE(RelatedDocuments.Ref) = TYPE(Document.IssuedTaxInvoicePrepayment)
								|");
								
		Query.SetParameter("FilterCriteriaValue",Object.Ref);
		
		Result = Query.Execute().Select();
		While Result.Next() Do
			TaxInvoice = Result.Ref.GetObject();
			ExecuteRegistrationRulesForObject(TaxInvoice, ORR.ExchangePlanName, Undefined);
		EndDo;
		
	EndIf;
EndProcedure
#EndRegion




#Region Document_ReceiptOfGoodsFromCustodian
Procedure AddPRO_Document_ReceiptOfGoodsFromCustodian(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_ReceiptOfGoodsFromCustodian";
	
	NewRule.MetadataObjectName3 = "Document.ReceiptOfGoodsFromCustodian";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_23(),
		Document_ReceiptOfGoodsFromCustodian_SelectionByObjectProperties());
EndProcedure

Function Document_ReceiptOfGoodsFromCustodian_SelectionByObjectProperties()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>Posted</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>TRUE</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Posted</Description>
			|				<TYPE>BOOLEAN</TYPE>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<ObjectPropertyType>EnumRef.BusinessTransactions</ObjectPropertyType>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>BusinessOperation</ObjectProperty1>
			|			<Kind>ValueAlgorithm</Kind>
			|			<ConstantValue>VALUE = Enums.BusinessTransactions.ReturnFromProcessingCompany2_5;</ConstantValue>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>BusinessOperation</Description>
			|					<TYPE>EnumRef.BusinessTransactions</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|		</FilterElement>
			|		<FilterElement>
			|			<ObjectPropertyType>EnumRef.BusinessTransactions</ObjectPropertyType>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>BusinessOperation</ObjectProperty1>
			|			<Kind>ValueAlgorithm</Kind>
			|			<ConstantValue>VALUE = Enums.BusinessTransactions.ReceiptFromToller2_5;</ConstantValue>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>BusinessOperation</Description>
			|					<TYPE>EnumRef.BusinessTransactions</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|		</FilterElement>
			|		<FilterElement>
			|			<ObjectPropertyType>EnumRef.BusinessTransactions</ObjectPropertyType>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>BusinessOperation</ObjectProperty1>
			|			<Kind>ValueAlgorithm</Kind>
			|			<ConstantValue>VALUE = Enums.BusinessTransactions.ReturnFromCommissionAgent;</ConstantValue>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>BusinessOperation</Description>
			|					<TYPE>EnumRef.BusinessTransactions</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|		</FilterElement>
			|	</Group>
			|</FilterByObjectProperties>";
EndFunction

Procedure ORR_Document_ReceiptOfGoodsFromCustodian_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Production, Sales, Warehouse";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_ReceiptOfGoodsFromCustodian_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Production, Sales, Warehouse";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure
#EndRegion
#Region Document_TransferOfGoodsToBailee
Procedure AddPRO_Document_TransferOfGoodsToCustodian(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_TransferOfGoodsToBailee";
	
	NewRule.MetadataObjectName3 = "Document.TransferOfGoodsToBailee";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_23(),
		FilterByObjectProperties_4());
EndProcedure

Procedure ORR_Document_TransferOfGoodsToBailee_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Production, Sales, Warehouse";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_TransferOfGoodsToBailee_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Production, Sales, Warehouse";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure
#EndRegion
#Region Document_SubcontractorReport2_5
Procedure AddPRO_Document_ProcessorReport2_5(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_SubcontractorReport2_5";
	
	NewRule.MetadataObjectName3 = "Document.SubcontractorReport2_5";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		Document_SubcontractorReport2_5_FilterByExchangePlanProperties(),
		FilterByObjectProperties_4());
EndProcedure

Function Document_SubcontractorReport2_5_FilterByExchangePlanProperties()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>FALSE</IsConstantString>
			|		<ObjectPropertyType>DATE</ObjectPropertyType>
			|		<ExchangePlanProperty>DocumentsExportStartDate</ExchangePlanProperty>
			|		<ComparisonType>GreaterOrEqual</ComparisonType>
			|		<ObjectProperty1>DATE</ObjectProperty1>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>DATE</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>DocumentsExportStartDate</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|			<ExchangePlanProperty>Companies.Organization</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Organization</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Companies]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<Group>
			|			<BooleanGroupValue>AND</BooleanGroupValue>
			|			<FilterElement>
			|				<IsConstantString>TRUE</IsConstantString>
			|				<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|				<ExchangePlanProperty>UseFilterByCompanies</ExchangePlanProperty>
			|				<ComparisonType>Equal</ComparisonType>
			|				<ObjectProperty1>FALSE</ObjectProperty1>
			|				<TableOfExchangePlanProperties>
			|					<Property>
			|						<Description>UseFilterByCompanies</Description>
			|						<TYPE>BOOLEAN</TYPE>
			|						<Kind>Attribute</Kind>
			|					</Property>
			|				</TableOfExchangePlanProperties>
			|			</FilterElement>
			|			<Group>
			|				<BooleanGroupValue>OR</BooleanGroupValue>
			|				<FilterElement>
			|					<IsConstantString>FALSE</IsConstantString>
			|					<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|					<ExchangePlanProperty>ManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>NotEqual</ComparisonType>
			|					<ObjectProperty1>Organization</ObjectProperty1>
			|					<ObjectPropertiesTable>
			|						<Property>
			|							<Description>Organization</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</ObjectPropertiesTable>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>ManagementCompany</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|				<FilterElement>
			|					<IsConstantString>TRUE</IsConstantString>
			|					<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|					<ExchangePlanProperty>UnloadManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>Equal</ComparisonType>
			|					<ObjectProperty1>TRUE</ObjectProperty1>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>UnloadManagementCompany</Description>
			|							<TYPE>BOOLEAN</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|			</Group>
			|		</Group>
			|	</Group>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeUP2ZUP3</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>CashExchange</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeOfUPRMC</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>";
EndFunction

Procedure ORR_Document_SubcontractorReport2_5_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Production";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_SubcontractorReport2_5_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Production";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure
#EndRegion




#Region Document_ReportToMaterialProvider2_5
Procedure AddPRO_Document_ReportToGiver2_5(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_ReportToMaterialProvider2_5";
	
	NewRule.MetadataObjectName3 = "Document.ReportToMaterialProvider2_5";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_16(),
		Document_ReportToMaterialProvider2_5_FilterByObjectProperties());
EndProcedure

Function Document_ReportToMaterialProvider2_5_FilterByObjectProperties()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>Posted</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>true</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Posted</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>EnumRef.VATTaxationTypes</ObjectPropertyType>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>VATTaxation</ObjectProperty1>
			|		<Kind>ValueAlgorithm</Kind>
			|		<ConstantValue>Value = PredefinedValue(""Enum.VATTaxationTypes.SpaceActivity"");;</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>VATTaxation</Description>
			|				<Type>EnumRef.VATTaxationTypes</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|</FilterByObjectProperties>";
EndFunction

Procedure ORR_Document_ReportToMaterialProvider2_5_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Production";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	
	// Special logic: filter by the version of the exchange format.
	QueryText = StrReplace(QueryText, "ExchangePlanMainTable.SettingsMode <> ""ExchangeUP2ZUP3""",
	"ExchangePlanMainTable.SettingsMode <> ""ExchangeUP2ZUP3"" AND ExchangePlanMainTable.ExchangeFormatVersion <> ""1.0"" AND ExchangePlanMainTable.ExchangeFormatVersion <> ""1.0.beta""");
	QueryText = StrReplace(QueryText, "OrganizationExchangePlan.Ref.SettingsMode <> ""ExchangeUP2ZUP3""",
	"OrganizationExchangePlan.Ref.SettingsMode <> ""ExchangeUP2ZUP3"" AND OrganizationExchangePlan.Ref.ExchangeFormatVersion <> ""1.0"" AND OrganizationExchangePlan.Ref.ExchangeFormatVersion <> ""1.0.beta""");
EndProcedure

Procedure ORR_Document_ReportToMaterialProvider2_5_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Production";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
	
	// Special logic: filter by the version of the exchange format.
	QueryText = StrReplace(QueryText, "ExchangePlanMainTable.SettingsMode <> ""ExchangeUP2ZUP3""",
	"ExchangePlanMainTable.SettingsMode <> ""ExchangeUP2ZUP3"" AND ExchangePlanMainTable.ExchangeFormatVersion <> ""1.0"" AND ExchangePlanMainTable.ExchangeFormatVersion <> ""1.0.beta""");
	QueryText = StrReplace(QueryText, "OrganizationExchangePlan.Ref.SettingsMode <> ""ExchangeUP2ZUP3""",
	"OrganizationExchangePlan.Ref.SettingsMode <> ""ExchangeUP2ZUP3"" AND OrganizationExchangePlan.Ref.ExchangeFormatVersion <> ""1.0"" AND OrganizationExchangePlan.Ref.ExchangeFormatVersion <> ""1.0.beta""");
EndProcedure
#EndRegion
#Region Document_GoodsReceiptForStorage
Procedure AddPRO_Document_AcceptanceOfGoodsForStorage(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_GoodsReceiptForStorage";
	
	NewRule.MetadataObjectName3 = "Document.GoodsReceiptForStorage";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_16(),
		FilterByObjectProperties_4());
EndProcedure

Procedure ORR_Document_GoodsReceiptForStorage_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Production, Warehouse";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	
	// Special logic: filter by the version of the exchange format.
	QueryText = StrReplace(QueryText, "ExchangePlanMainTable.SettingsMode <> ""ExchangeUP2ZUP3""",
	"ExchangePlanMainTable.SettingsMode <> ""ExchangeUP2ZUP3"" AND ExchangePlanMainTable.ExchangeFormatVersion <> ""1.0"" AND ExchangePlanMainTable.ExchangeFormatVersion <> ""1.0.beta""");
	QueryText = StrReplace(QueryText, "OrganizationExchangePlan.Ref.SettingsMode <> ""ExchangeUP2ZUP3""",
	"OrganizationExchangePlan.Ref.SettingsMode <> ""ExchangeUP2ZUP3"" AND OrganizationExchangePlan.Ref.ExchangeFormatVersion <> ""1.0"" AND OrganizationExchangePlan.Ref.ExchangeFormatVersion <> ""1.0.beta""");
EndProcedure

Procedure ORR_Document_GoodsReceiptForStorage_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Production, Warehouse";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
	
	// Special logic: filter by the version of the exchange format.
	QueryText = StrReplace(QueryText, "ExchangePlanMainTable.SettingsMode <> ""ExchangeUP2ZUP3""",
	"ExchangePlanMainTable.SettingsMode <> ""ExchangeUP2ZUP3"" AND ExchangePlanMainTable.ExchangeFormatVersion <> ""1.0"" AND ExchangePlanMainTable.ExchangeFormatVersion <> ""1.0.beta""");
	QueryText = StrReplace(QueryText, "OrganizationExchangePlan.Ref.SettingsMode <> ""ExchangeUP2ZUP3""",
	"OrganizationExchangePlan.Ref.SettingsMode <> ""ExchangeUP2ZUP3"" AND OrganizationExchangePlan.Ref.ExchangeFormatVersion <> ""1.0"" AND OrganizationExchangePlan.Ref.ExchangeFormatVersion <> ""1.0.beta""");
EndProcedure
#EndRegion
#Region Document_GoodsShipmentFromStorage
Procedure AddPRO_Document_ShipmentOfGoodsFromStorage(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_GoodsShipmentFromStorage";
	
	NewRule.MetadataObjectName3 = "Document.GoodsShipmentFromStorage";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_16(),
		FilterByObjectProperties_4());
EndProcedure

Procedure ORR_Document_GoodsShipmentFromStorage_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Production, Warehouse";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	
	// Special logic: filter by the version of the exchange format.
	QueryText = StrReplace(QueryText, "ExchangePlanMainTable.SettingsMode <> ""ExchangeUP2ZUP3""",
	"ExchangePlanMainTable.SettingsMode <> ""ExchangeUP2ZUP3"" AND ExchangePlanMainTable.ExchangeFormatVersion <> ""1.0"" AND ExchangePlanMainTable.ExchangeFormatVersion <> ""1.0.beta""");
	QueryText = StrReplace(QueryText, "OrganizationExchangePlan.Ref.SettingsMode <> ""ExchangeUP2ZUP3""",
	"OrganizationExchangePlan.Ref.SettingsMode <> ""ExchangeUP2ZUP3"" AND OrganizationExchangePlan.Ref.ExchangeFormatVersion <> ""1.0"" AND OrganizationExchangePlan.Ref.ExchangeFormatVersion <> ""1.0.beta""");
EndProcedure

Procedure ORR_Document_GoodsShipmentFromStorage_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Production, Warehouse";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
	
	// Special logic: filter by the version of the exchange format.
	QueryText = StrReplace(QueryText, "ExchangePlanMainTable.SettingsMode <> ""ExchangeUP2ZUP3""",
	"ExchangePlanMainTable.SettingsMode <> ""ExchangeUP2ZUP3"" AND ExchangePlanMainTable.ExchangeFormatVersion <> ""1.0"" AND ExchangePlanMainTable.ExchangeFormatVersion <> ""1.0.beta""");
	QueryText = StrReplace(QueryText, "OrganizationExchangePlan.Ref.SettingsMode <> ""ExchangeUP2ZUP3""",
	"OrganizationExchangePlan.Ref.SettingsMode <> ""ExchangeUP2ZUP3"" AND OrganizationExchangePlan.Ref.ExchangeFormatVersion <> ""1.0"" AND OrganizationExchangePlan.Ref.ExchangeFormatVersion <> ""1.0.beta""");
EndProcedure
#EndRegion


#Region Document_MovementOfProductsAndMaterials
Procedure AddPRO_Document_ProductAndMaterialMovement(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_MovementOfProductsAndMaterials";
	
	NewRule.MetadataObjectName3 = "Document.MovementOfProductsAndMaterials";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_15(),
		Document_MovementOfProductsAndMaterials_SelectionByObjectProperties());
EndProcedure

Function Document_MovementOfProductsAndMaterials_SelectionByObjectProperties()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>Posted</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>true</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Posted</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>EnumRef.BusinessTransactions</ObjectPropertyType>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>BusinessOperation</ObjectProperty1>
			|		<Kind>ValueAlgorithm</Kind>
			|		<ConstantValue>Value = Enums.BusinessTransactions.TransferOfSemiFinishedProducts;</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>BusinessOperation</Description>
			|				<Type>EnumRef.BusinessTransactions</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>EnumRef.StatusesOfProductsAndMaterialMovement</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>Status</ObjectProperty1>
			|		<Kind>ValueAlgorithm</Kind>
			|		<ConstantValue>Value = Enums.StatusesOfProductsAndMaterialMovement.Accepted;</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Status</Description>
			|				<Type>EnumRef.StatusesOfProductsAndMaterialMovement</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>InternalSubcontracting</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>false</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>InternalSubcontracting</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>EnumRef.VATTaxationTypes</ObjectPropertyType>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>VATTaxation</ObjectProperty1>
			|		<Kind>ValueAlgorithm</Kind>
			|		<ConstantValue>Value = PredefinedValue(""Enum.VATTaxationTypes.SpaceActivity"");</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>VATTaxation</Description>
			|				<Type>EnumRef.VATTaxationTypes</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|</FilterByObjectProperties>";
EndFunction

Procedure ORR_Document_MovementOfProductsAndMaterials_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Production";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_MovementOfProductsAndMaterials_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Production";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure
#EndRegion
#Region Document_BackflushProduction
Procedure AddPRO_Document_ProductionWithoutOrder(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_BackflushProduction";
	
	NewRule.MetadataObjectName3 = "Document.BackflushProduction";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = True;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_15(),
		FilterByObjectProperties_4());
EndProcedure

Procedure ORR_Document_BackflushProduction_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0)
	DataExchangeEventsTM.DocumentBackflushedProductionBeforeProcessingPRO(Object, Cancel);
EndProcedure

Procedure ORR_Document_BackflushProduction_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Production";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_BackflushProduction_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Production";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure
#EndRegion
#Region Document_GiftCertificateCancellation
Procedure AddPRO_Document_RevokingGiftCertificates(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_GiftCertificateCancellation";
	
	NewRule.MetadataObjectName3 = "Document.GiftCertificateCancellation";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = True;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_18(),
		FilterByObjectProperties_4());
EndProcedure

Procedure ORR_Document_GiftCertificateCancellation_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Sales";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_GiftCertificateCancellation_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Sales";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure

Procedure ORR_Document_GiftCertificateCancellation_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0)
	If Object.GiftCertificates.Total("AmountInCertificateCurrency") = 0 Then
		Cancel = True;
	EndIf;
EndProcedure
#EndRegion
#Region Document_ReturnOfGiftCards
Procedure AddPRO_Document_ReturnGiftCertificates(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_ReturnOfGiftCards";
	
	NewRule.MetadataObjectName3 = "Document.ReturnOfGiftCards";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		Document_ReturnOfGiftCards_FilterByExchangePlanProperties(),
		Document_RefundOfGiftCertificates_SelectionByObjectProperties());
EndProcedure

Function Document_ReturnOfGiftCards_FilterByExchangePlanProperties()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>FALSE</IsConstantString>
			|		<ObjectPropertyType>DATE</ObjectPropertyType>
			|		<ExchangePlanProperty>DocumentsExportStartDate</ExchangePlanProperty>
			|		<ComparisonType>GreaterOrEqual</ComparisonType>
			|		<ObjectProperty1>DATE</ObjectProperty1>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>DATE</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>DocumentsExportStartDate</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|			<ExchangePlanProperty>[Companies].Organization</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Organization</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Companies]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<Group>
			|			<BooleanGroupValue>AND</BooleanGroupValue>
			|			<FilterElement>
			|				<IsConstantString>TRUE</IsConstantString>
			|				<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|				<ExchangePlanProperty>UseFilterByCompanies</ExchangePlanProperty>
			|				<ComparisonType>Equal</ComparisonType>
			|				<ObjectProperty1>FALSE</ObjectProperty1>
			|				<TableOfExchangePlanProperties>
			|					<Property>
			|						<Description>UseFilterByCompanies</Description>
			|						<TYPE>BOOLEAN</TYPE>
			|						<Kind>Attribute</Kind>
			|					</Property>
			|				</TableOfExchangePlanProperties>
			|			</FilterElement>
			|			<Group>
			|				<BooleanGroupValue>OR</BooleanGroupValue>
			|				<FilterElement>
			|					<IsConstantString>FALSE</IsConstantString>
			|					<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|					<ExchangePlanProperty>ManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>NotEqual</ComparisonType>
			|					<ObjectProperty1>Organization</ObjectProperty1>
			|					<ObjectPropertiesTable>
			|						<Property>
			|							<Description>Organization</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</ObjectPropertiesTable>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>ManagementCompany</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|				<FilterElement>
			|					<IsConstantString>TRUE</IsConstantString>
			|					<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|					<ExchangePlanProperty>UnloadManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>Equal</ComparisonType>
			|					<ObjectProperty1>TRUE</ObjectProperty1>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>UnloadManagementCompany</Description>
			|							<TYPE>BOOLEAN</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|			</Group>
			|		</Group>
			|	</Group>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.CashRegisters</ObjectPropertyType>
			|			<ExchangePlanProperty>CashRegisters.CashRegister</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>CashRegister</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>CashRegister</Description>
			|					<TYPE>CatalogRef.CashRegisters</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[CashRegisters]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>CashRegister</Description>
			|					<TYPE>CatalogRef.CashRegisters</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<FilterElement>
			|			<IsConstantString>TRUE</IsConstantString>
			|			<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|			<ExchangePlanProperty>UseFilterByCashRegisters</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>FALSE</ObjectProperty1>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>UseFilterByCashRegisters</Description>
			|					<TYPE>BOOLEAN</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|	</Group>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeUP2ZUP3</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>CashExchange</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeOfUPRMC</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>";
EndFunction

Function Document_RefundOfGiftCertificates_SelectionByObjectProperties()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>Posted</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>true</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Posted</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>EnumRef.CashRegisterReceiptStatuses</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>Status</ObjectProperty1>
			|		<Kind>ValueAlgorithm</Kind>
			|		<ConstantValue>Value = Enums.CashRegisterReceiptStatuses.ReceiptIsIssued_;</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Status</Description>
			|				<Type>EnumRef.CashRegisterReceiptStatuses</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|</FilterByObjectProperties>";
EndFunction

Procedure ORR_Document_ReturnOfGiftCards_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Sales";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_ReturnOfGiftCards_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Sales";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure
#EndRegion
#Region Document_CashRegisterShift
Procedure AddPRO_Document_CashShift(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_CashRegisterShift";
	
	NewRule.MetadataObjectName3 = "Document.CashRegisterShift";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_13(),
		FilterByObjectProperties_4());
EndProcedure

Procedure ORR_Document_CashRegisterShift_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Sales";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_CashRegisterShift_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Sales";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure
#EndRegion
#Region Document_RetailSalesReport
Procedure AddPRO_Document_RetailSalesReport(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_RetailSalesReport";
	
	NewRule.MetadataObjectName3 = "Document.RetailSalesReport";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		Document_RetailSalesReport_FilterByExchangePlanProperties(),
		FilterByObjectProperties_4());
EndProcedure

Function Document_RetailSalesReport_FilterByExchangePlanProperties()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>FALSE</IsConstantString>
			|		<ObjectPropertyType>DATE</ObjectPropertyType>
			|		<ExchangePlanProperty>DocumentsExportStartDate</ExchangePlanProperty>
			|		<ComparisonType>GreaterOrEqual</ComparisonType>
			|		<ObjectProperty1>DATE</ObjectProperty1>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>DATE</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>DocumentsExportStartDate</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|			<ExchangePlanProperty>[Companies].Organization</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Organization</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Companies]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<Group>
			|			<BooleanGroupValue>AND</BooleanGroupValue>
			|			<FilterElement>
			|				<IsConstantString>TRUE</IsConstantString>
			|				<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|				<ExchangePlanProperty>UseFilterByCompanies</ExchangePlanProperty>
			|				<ComparisonType>Equal</ComparisonType>
			|				<ObjectProperty1>FALSE</ObjectProperty1>
			|				<TableOfExchangePlanProperties>
			|					<Property>
			|						<Description>UseFilterByCompanies</Description>
			|						<TYPE>BOOLEAN</TYPE>
			|						<Kind>Attribute</Kind>
			|					</Property>
			|				</TableOfExchangePlanProperties>
			|			</FilterElement>
			|			<Group>
			|				<BooleanGroupValue>OR</BooleanGroupValue>
			|				<FilterElement>
			|					<IsConstantString>FALSE</IsConstantString>
			|					<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|					<ExchangePlanProperty>ManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>NotEqual</ComparisonType>
			|					<ObjectProperty1>Organization</ObjectProperty1>
			|					<ObjectPropertiesTable>
			|						<Property>
			|							<Description>Organization</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</ObjectPropertiesTable>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>ManagementCompany</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|				<FilterElement>
			|					<IsConstantString>TRUE</IsConstantString>
			|					<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|					<ExchangePlanProperty>UnloadManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>Equal</ComparisonType>
			|					<ObjectProperty1>TRUE</ObjectProperty1>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>UnloadManagementCompany</Description>
			|							<TYPE>BOOLEAN</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|			</Group>
			|		</Group>
			|	</Group>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Warehouses</ObjectPropertyType>
			|			<ExchangePlanProperty>[Warehouses].Warehouse</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Warehouse</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Warehouse</Description>
			|					<TYPE>CatalogRef.Warehouses</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Warehouses]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Warehouse</Description>
			|					<TYPE>CatalogRef.Warehouses</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<FilterElement>
			|			<IsConstantString>TRUE</IsConstantString>
			|			<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|			<ExchangePlanProperty>UseFilterByWarehouses</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>FALSE</ObjectProperty1>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>UseFilterByWarehouses</Description>
			|					<TYPE>BOOLEAN</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|	</Group>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.CashRegisters</ObjectPropertyType>
			|			<ExchangePlanProperty>[CashRegisters].CashRegister</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>CashRegister</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>CashRegister</Description>
			|					<TYPE>CatalogRef.CashRegisters</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[CashRegisters]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>CashRegister</Description>
			|					<TYPE>CatalogRef.CashRegisters</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<FilterElement>
			|			<IsConstantString>TRUE</IsConstantString>
			|			<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|			<ExchangePlanProperty>UseFilterByCashRegisters</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>FALSE</ObjectProperty1>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>UseFilterByCashRegisters</Description>
			|					<TYPE>BOOLEAN</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|	</Group>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeUP2ZUP3</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>CashExchange</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeOfUPRMC</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>";
EndFunction

Procedure ORR_Document_RetailSalesReport_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Sales";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_RetailSalesReport_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Sales";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure
#EndRegion
#Region Document_GiftCertificateSale
Procedure AddPRO_Document_ImplementingGiftCertificates(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_GiftCertificateSale";
	
	NewRule.MetadataObjectName3 = "Document.GiftCertificateSale";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = True;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_13(),
		FilterByObjectProperties_4());
EndProcedure

Procedure ORR_Document_GiftCertificateSale_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0)
	Query = New Query;
	Query.Text = 
		"SELECT
		|	RetailSalesReport.Ref
		|FROM
		|	Document.RetailSalesReport AS RetailSalesReport
		|		INNER JOIN Document.GiftCertificateSale AS GiftCertificateSale
		|		ON RetailSalesReport.CashRegisterShift = GiftCertificateSale.CashRegisterShift
		|WHERE
		|	GiftCertificateSale.Ref = &Ref";
	
	Query.SetParameter("Ref", Object.Ref);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		ExecuteRegistrationRulesForObject(Selection.Ref.GetObject(), ORR.ExchangePlanName, Object.DataExchange.Sender);
	EndIf;
	
	Cancel = True;
EndProcedure

Procedure ORR_Document_GiftCertificateSale_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Sales";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_GiftCertificateSale_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Sales";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure
#EndRegion
#Region Document_RetailReturnsReport
Procedure AddPRO_Document_RetailReturnsReport(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_RetailReturnsReport";
	
	NewRule.MetadataObjectName3 = "Document.RetailReturnsReport";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = True;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		Document_RetailReturnsReport_FilterByExchangePlanProperties(),
		FilterByObjectProperties_4());
EndProcedure

Function Document_RetailReturnsReport_FilterByExchangePlanProperties()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>FALSE</IsConstantString>
			|		<ObjectPropertyType>DATE</ObjectPropertyType>
			|		<ExchangePlanProperty>DocumentsExportStartDate</ExchangePlanProperty>
			|		<ComparisonType>GreaterOrEqual</ComparisonType>
			|		<ObjectProperty1>DATE</ObjectProperty1>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>DATE</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>DocumentsExportStartDate</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|			<ExchangePlanProperty>Companies.Organization</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Organization</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Companies]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<Group>
			|			<BooleanGroupValue>AND</BooleanGroupValue>
			|			<FilterElement>
			|				<IsConstantString>TRUE</IsConstantString>
			|				<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|				<ExchangePlanProperty>UseFilterByCompanies</ExchangePlanProperty>
			|				<ComparisonType>Equal</ComparisonType>
			|				<ObjectProperty1>FALSE</ObjectProperty1>
			|				<TableOfExchangePlanProperties>
			|					<Property>
			|						<Description>UseFilterByCompanies</Description>
			|						<TYPE>BOOLEAN</TYPE>
			|						<Kind>Attribute</Kind>
			|					</Property>
			|				</TableOfExchangePlanProperties>
			|			</FilterElement>
			|			<Group>
			|				<BooleanGroupValue>OR</BooleanGroupValue>
			|				<FilterElement>
			|					<IsConstantString>FALSE</IsConstantString>
			|					<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|					<ExchangePlanProperty>ManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>NotEqual</ComparisonType>
			|					<ObjectProperty1>Organization</ObjectProperty1>
			|					<ObjectPropertiesTable>
			|						<Property>
			|							<Description>Organization</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</ObjectPropertiesTable>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>ManagementCompany</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|				<FilterElement>
			|					<IsConstantString>TRUE</IsConstantString>
			|					<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|					<ExchangePlanProperty>UnloadManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>Equal</ComparisonType>
			|					<ObjectProperty1>TRUE</ObjectProperty1>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>UnloadManagementCompany</Description>
			|							<TYPE>BOOLEAN</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|			</Group>
			|		</Group>
			|	</Group>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Warehouses</ObjectPropertyType>
			|			<ExchangePlanProperty>Warehouses.Warehouse</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Warehouse</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Warehouse</Description>
			|					<TYPE>CatalogRef.Warehouses</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Warehouses]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Warehouse</Description>
			|					<TYPE>CatalogRef.Warehouses</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<FilterElement>
			|			<IsConstantString>TRUE</IsConstantString>
			|			<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|			<ExchangePlanProperty>UseFilterByWarehouses</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>FALSE</ObjectProperty1>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>UseFilterByWarehouses</Description>
			|					<TYPE>BOOLEAN</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|	</Group>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.CashRegisters</ObjectPropertyType>
			|			<ExchangePlanProperty>[CashRegisters].CashRegister</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>CashRegister</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>CashRegister</Description>
			|					<TYPE>CatalogRef.CashRegisters</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[CashRegisters]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>CashRegister</Description>
			|					<TYPE>CatalogRef.CashRegisters</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<FilterElement>
			|			<IsConstantString>TRUE</IsConstantString>
			|			<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|			<ExchangePlanProperty>UseFilterByCashRegisters</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>FALSE</ObjectProperty1>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>UseFilterByCashRegisters</Description>
			|					<TYPE>BOOLEAN</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|	</Group>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeUP2ZUP3</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>CashExchange</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeOfUPRMC</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>";
EndFunction

Procedure ORR_Document_RetailReturnsReport_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0)
	Cancel = True;
	
	If Not Upload0 Then
		Query = New Query("SELECT
			|	RetailSalesReport.Ref AS Ref
			|FROM
			|	Document.RetailSalesReport AS RetailSalesReport
			|WHERE
			|	RetailSalesReport.CashRegisterShift = &CashRegisterShift
			|	AND RetailSalesReport.CashRegisterShift <> VALUE(Document.CashRegisterShift.EmptyRef)
			|	AND RetailSalesReport.VATTaxation = &VATTaxation
			|");
		Query.SetParameter("CashRegisterShift", Object.CashRegisterShift);
		Query.SetParameter("VATTaxation", Object.VATTaxation);
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			If Common.RefExists(Selection.Ref) Then	
				ExecuteRegistrationRulesForObject(Selection.Ref.GetObject(), ORR.ExchangePlanName, Object.DataExchange.Sender);
			EndIf;
		EndDo;
	EndIf;
EndProcedure
#EndRegion
#Region Document_InventoryConsumption
Procedure AddPRO_Document_InternalConsumption(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_InventoryConsumption";
	
	NewRule.MetadataObjectName3 = "Document.InventoryConsumption";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_16(),
		Document_InternalConsumption_SelectionByObjectProperties());
EndProcedure

Function Document_InternalConsumption_SelectionByObjectProperties()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>Posted</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>TRUE</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Posted</Description>
			|				<TYPE>BOOLEAN</TYPE>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<ObjectPropertyType>EnumRef.BusinessTransactions</ObjectPropertyType>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>BusinessOperation</ObjectProperty1>
			|			<Kind>ValueAlgorithm</Kind>
			|			<ConstantValue>VALUE = Enums.BusinessTransactions.GoodsConsumptionOnDemand;</ConstantValue>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>BusinessOperation</Description>
			|					<TYPE>EnumRef.BusinessTransactions</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|		</FilterElement>
			|		<FilterElement>
			|			<ObjectPropertyType>EnumRef.BusinessTransactions</ObjectPropertyType>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>BusinessOperation</ObjectProperty1>
			|			<Kind>ValueAlgorithm</Kind>
			|			<ConstantValue>VALUE = Enums.BusinessTransactions.TransferToOperation;</ConstantValue>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>BusinessOperation</Description>
			|					<TYPE>EnumRef.BusinessTransactions</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|		</FilterElement>
			|	</Group>
			|</FilterByObjectProperties>";
EndFunction

Procedure ORR_Document_InventoryConsumption_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Warehouse";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_InventoryConsumption_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Warehouse";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure
#EndRegion
#Region Document_RedemptionOfGoodsFromStorage
Procedure AddPRO_Document_RedemptionOfGoodsAcceptedForStorage(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_RedemptionOfGoodsFromStorage";
	
	NewRule.MetadataObjectName3 = "Document.RedemptionOfGoodsFromStorage";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_18(),
		FilterByObjectProperties_4());
EndProcedure

Procedure ORR_Document_RedemptionOfGoodsFromStorage_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Warehouse";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_RedemptionOfGoodsFromStorage_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Warehouse";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure
#EndRegion
#Region Document_TransferOrder
Procedure AddPRO_Document_MovingOrder(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_TransferOrder";
	
	NewRule.MetadataObjectName3 = "Document.TransferOrder";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		Document_RelocationOrder_SelectionByExchangePlanProperties(),
		Document_MovingOrder_SelectionByObjectProperties());
EndProcedure

Function Document_RelocationOrder_SelectionByExchangePlanProperties()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>FALSE</IsConstantString>
			|		<ObjectPropertyType>DATE</ObjectPropertyType>
			|		<ExchangePlanProperty>DocumentsExportStartDate</ExchangePlanProperty>
			|		<ComparisonType>GreaterOrEqual</ComparisonType>
			|		<ObjectProperty1>DATE</ObjectProperty1>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>DATE</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>DocumentsExportStartDate</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|			<ExchangePlanProperty>[Companies].Organization</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Organization</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Companies]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<Group>
			|			<BooleanGroupValue>AND</BooleanGroupValue>
			|			<FilterElement>
			|				<IsConstantString>TRUE</IsConstantString>
			|				<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|				<ExchangePlanProperty>UseFilterByCompanies</ExchangePlanProperty>
			|				<ComparisonType>Equal</ComparisonType>
			|				<ObjectProperty1>FALSE</ObjectProperty1>
			|				<TableOfExchangePlanProperties>
			|					<Property>
			|						<Description>UseFilterByCompanies</Description>
			|						<TYPE>BOOLEAN</TYPE>
			|						<Kind>Attribute</Kind>
			|					</Property>
			|				</TableOfExchangePlanProperties>
			|			</FilterElement>
			|			<Group>
			|				<BooleanGroupValue>OR</BooleanGroupValue>
			|				<FilterElement>
			|					<IsConstantString>FALSE</IsConstantString>
			|					<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|					<ExchangePlanProperty>ManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>NotEqual</ComparisonType>
			|					<ObjectProperty1>Organization</ObjectProperty1>
			|					<ObjectPropertiesTable>
			|						<Property>
			|							<Description>Organization</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</ObjectPropertiesTable>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>ManagementCompany</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|				<FilterElement>
			|					<IsConstantString>TRUE</IsConstantString>
			|					<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|					<ExchangePlanProperty>UnloadManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>Equal</ComparisonType>
			|					<ObjectProperty1>TRUE</ObjectProperty1>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>UnloadManagementCompany</Description>
			|							<TYPE>BOOLEAN</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|			</Group>
			|		</Group>
			|	</Group>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Warehouses</ObjectPropertyType>
			|			<ExchangePlanProperty>[Warehouses].Warehouse</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>DestinationWarehouse</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>DestinationWarehouse</Description>
			|					<TYPE>CatalogRef.Warehouses</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Warehouses]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Warehouse</Description>
			|					<TYPE>CatalogRef.Warehouses</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Warehouses</ObjectPropertyType>
			|			<ExchangePlanProperty>[Warehouses].Warehouse</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>SourceWarehouse</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>SourceWarehouse</Description>
			|					<TYPE>CatalogRef.Warehouses</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Warehouses]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Warehouse</Description>
			|					<TYPE>CatalogRef.Warehouses</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<FilterElement>
			|			<IsConstantString>TRUE</IsConstantString>
			|			<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|			<ExchangePlanProperty>UseFilterByWarehouses</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>FALSE</ObjectProperty1>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>UseFilterByWarehouses</Description>
			|					<TYPE>BOOLEAN</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|	</Group>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeUP2ZUP3</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|		<ExchangePlanProperty>UploadAnalyticsByWarehouse</ExchangePlanProperty>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>TRUE</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>UploadAnalyticsByWarehouse</Description>
			|				<TYPE>BOOLEAN</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>CashExchange</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeOfUPRMC</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>";
EndFunction

Function Document_MovingOrder_SelectionByObjectProperties()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>Posted</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>true</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Posted</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>EnumRef.BusinessTransactions</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>BusinessOperation</ObjectProperty1>
			|		<Kind>ValueAlgorithm</Kind>
			|		<ConstantValue>Value = Enums.BusinessTransactions.InventoryTransfer;</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>BusinessOperation</Description>
			|				<Type>EnumRef.BusinessTransactions</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|</FilterByObjectProperties>";
EndFunction

Procedure ORR_Document_TransferOrder_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Warehouse";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_TransferOrder_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Warehouse";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure
#EndRegion
#Region Document_InventorySurplusRecognition
Procedure AddPRO_Document_RegisteringSurplusGoods(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_InventorySurplusRecognition";
	
	NewRule.MetadataObjectName3 = "Document.InventorySurplusRecognition";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_16(),
		FilterByObjectProperties_4());
EndProcedure

Procedure ORR_Document_InventorySurplusRecognition_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Warehouse";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_InventorySurplusRecognition_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Warehouse";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure
#EndRegion
#Region Document_InventoryTransfer
Procedure AddPRO_Document_MovingGoods(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_InventoryTransfer";
	
	NewRule.MetadataObjectName3 = "Document.InventoryTransfer";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		Document_MovementOfGoods_SelectionByPropertiesOfExchangePlan(),
		Document_MovementOfGoods_SelectionByObjectProperties());
EndProcedure

Function Document_MovementOfGoods_SelectionByPropertiesOfExchangePlan()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>FALSE</IsConstantString>
			|		<ObjectPropertyType>DATE</ObjectPropertyType>
			|		<ExchangePlanProperty>DocumentsExportStartDate</ExchangePlanProperty>
			|		<ComparisonType>GreaterOrEqual</ComparisonType>
			|		<ObjectProperty1>DATE</ObjectProperty1>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>DATE</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>DocumentsExportStartDate</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|		<ExchangePlanProperty>UploadAnalyticsByWarehouse</ExchangePlanProperty>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>TRUE</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>UploadAnalyticsByWarehouse</Description>
			|				<TYPE>BOOLEAN</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|			<ExchangePlanProperty>[Companies].Organization</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Organization</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Companies]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<Group>
			|			<BooleanGroupValue>AND</BooleanGroupValue>
			|			<FilterElement>
			|				<IsConstantString>TRUE</IsConstantString>
			|				<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|				<ExchangePlanProperty>UseFilterByCompanies</ExchangePlanProperty>
			|				<ComparisonType>Equal</ComparisonType>
			|				<ObjectProperty1>FALSE</ObjectProperty1>
			|				<TableOfExchangePlanProperties>
			|					<Property>
			|						<Description>UseFilterByCompanies</Description>
			|						<TYPE>BOOLEAN</TYPE>
			|						<Kind>Attribute</Kind>
			|					</Property>
			|				</TableOfExchangePlanProperties>
			|			</FilterElement>
			|			<Group>
			|				<BooleanGroupValue>OR</BooleanGroupValue>
			|				<FilterElement>
			|					<IsConstantString>FALSE</IsConstantString>
			|					<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|					<ExchangePlanProperty>ManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>NotEqual</ComparisonType>
			|					<ObjectProperty1>Organization</ObjectProperty1>
			|					<ObjectPropertiesTable>
			|						<Property>
			|							<Description>Organization</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</ObjectPropertiesTable>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>ManagementCompany</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|				<FilterElement>
			|					<IsConstantString>TRUE</IsConstantString>
			|					<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|					<ExchangePlanProperty>UnloadManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>Equal</ComparisonType>
			|					<ObjectProperty1>TRUE</ObjectProperty1>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>UnloadManagementCompany</Description>
			|							<TYPE>BOOLEAN</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|			</Group>
			|		</Group>
			|	</Group>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Warehouses</ObjectPropertyType>
			|			<ExchangePlanProperty>[Warehouses].Warehouse</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>SourceWarehouse</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>SourceWarehouse</Description>
			|					<TYPE>CatalogRef.Warehouses</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Warehouses]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Warehouse</Description>
			|					<TYPE>CatalogRef.Warehouses</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Warehouses</ObjectPropertyType>
			|			<ExchangePlanProperty>[Warehouses].Warehouse</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>DestinationWarehouse</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>DestinationWarehouse</Description>
			|					<TYPE>CatalogRef.Warehouses</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Warehouses]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Warehouse</Description>
			|					<TYPE>CatalogRef.Warehouses</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<FilterElement>
			|			<IsConstantString>TRUE</IsConstantString>
			|			<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|			<ExchangePlanProperty>UseFilterByWarehouses</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>FALSE</ObjectProperty1>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>UseFilterByWarehouses</Description>
			|					<TYPE>BOOLEAN</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|	</Group>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeUP2ZUP3</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>CashExchange</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeOfUPRMC</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>";
EndFunction

Function Document_MovementOfGoods_SelectionByObjectProperties()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>Posted</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>true</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Posted</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>EnumRef.GoodsTransferStatuses</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>Status</ObjectProperty1>
			|		<Kind>ValueAlgorithm</Kind>
			|		<ConstantValue>Value = Enums.GoodsTransferStatuses.Accepted;</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Status</Description>
			|				<Type>EnumRef.GoodsTransferStatuses</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|</FilterByObjectProperties>";
EndFunction

Procedure ORR_Document_InventoryTransfer_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Warehouse";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_InventoryTransfer_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Warehouse";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure
#EndRegion
#Region Document_GoodsMisgrading
Procedure AddPRO_Document_ResortmentOfProducts(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_GoodsMisgrading";
	
	NewRule.MetadataObjectName3 = "Document.GoodsMisgrading";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_16(),
		FilterByObjectProperties_4());
EndProcedure

Procedure ORR_Document_GoodsMisgrading_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Warehouse";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_GoodsMisgrading_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Warehouse";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure
#EndRegion
#Region Document_InventoryRecount
Procedure AddPRO_Document_RecalculationOfGoods(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_InventoryRecount";
	
	NewRule.MetadataObjectName3 = "Document.InventoryRecount";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		Document_RecalculationOfGoods_SelectionAccordingToPropertiesOfExchangePlan(),
		Document_RecalculationOfGoods_SelectionByObjectProperties());
EndProcedure

Function Document_RecalculationOfGoods_SelectionAccordingToPropertiesOfExchangePlan()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>FALSE</IsConstantString>
			|		<ObjectPropertyType>DATE</ObjectPropertyType>
			|		<ExchangePlanProperty>DocumentsExportStartDate</ExchangePlanProperty>
			|		<ComparisonType>GreaterOrEqual</ComparisonType>
			|		<ObjectProperty1>DATE</ObjectProperty1>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>DATE</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>DocumentsExportStartDate</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Warehouses</ObjectPropertyType>
			|			<ExchangePlanProperty>[Warehouses].Warehouse</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Warehouse</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Warehouse</Description>
			|					<TYPE>CatalogRef.Warehouses</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Warehouses]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Warehouse</Description>
			|					<TYPE>CatalogRef.Warehouses</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<FilterElement>
			|			<IsConstantString>TRUE</IsConstantString>
			|			<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|			<ExchangePlanProperty>UseFilterByWarehouses</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>FALSE</ObjectProperty1>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>UseFilterByWarehouses</Description>
			|					<TYPE>BOOLEAN</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|	</Group>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeUP2ZUP3</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|		<ExchangePlanProperty>UploadAnalyticsByWarehouse</ExchangePlanProperty>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>TRUE</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>UploadAnalyticsByWarehouse</Description>
			|				<TYPE>BOOLEAN</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>CashExchange</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeOfUPRMC</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>";
EndFunction

Function Document_RecalculationOfGoods_SelectionByObjectProperties()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>Posted</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>true</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Posted</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>EnumRef.InventoryRecountStatuses</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>Status</ObjectProperty1>
			|		<Kind>ValueAlgorithm</Kind>
			|		<ConstantValue>Value = Enums.InventoryRecountStatuses.Completed2;</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Status</Description>
			|				<Type>EnumRef.InventoryRecountStatuses</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|</FilterByObjectProperties>";
EndFunction

Procedure ORR_Document_InventoryRecount_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Warehouse";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_InventoryRecount_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Warehouse";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure
#EndRegion
#Region Document_OtherGoodsRecordingAsReceived
Procedure AddPRO_Document_OtherProductRegistration(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_OtherGoodsRecordingAsReceived";
	
	NewRule.MetadataObjectName3 = "Document.OtherGoodsRecordingAsReceived";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_16(),
		Document_OtherRegistrationOfGoods_SelectionByObjectProperties());
EndProcedure

Function Document_OtherRegistrationOfGoods_SelectionByObjectProperties()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>Posted</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>TRUE</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Posted</Description>
			|				<TYPE>BOOLEAN</TYPE>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<ObjectPropertyType>EnumRef.BusinessTransactions</ObjectPropertyType>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>BusinessOperation</ObjectProperty1>
			|			<Kind>ValueAlgorithm</Kind>
			|			<ConstantValue>VALUE = Enums.BusinessTransactions.PutOutOfOperation;</ConstantValue>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>BusinessOperation</Description>
			|					<TYPE>EnumRef.BusinessTransactions</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|		</FilterElement>
			|		<FilterElement>
			|			<ObjectPropertyType>EnumRef.BusinessTransactions</ObjectPropertyType>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>BusinessOperation</ObjectProperty1>
			|			<Kind>ValueAlgorithm</Kind>
			|			<ConstantValue>VALUE = Enums.BusinessTransactions.ReceiptFromProduction;</ConstantValue>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>BusinessOperation</Description>
			|					<TYPE>EnumRef.BusinessTransactions</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|		</FilterElement>
			|	</Group>
			|</FilterByObjectProperties>";
EndFunction

Procedure ORR_Document_OtherGoodsRecordingAsReceived_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Warehouse";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_OtherGoodsRecordingAsReceived_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Warehouse";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure
#EndRegion
#Region Document_AssemblyFromComponents
Procedure AddPRO_Document_ProductAssembly(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_AssemblyFromComponents";
	
	NewRule.MetadataObjectName3 = "Document.AssemblyFromComponents";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = True;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_16(),
		Document_AssemblyOfGoods_SelectionByObjectProperties());
EndProcedure

Function Document_AssemblyOfGoods_SelectionByObjectProperties()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>Posted</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>true</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Posted</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>EnumRef.GoodsAssemblyStatuses</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>Status</ObjectProperty1>
			|		<Kind>ValueAlgorithm</Kind>
			|		<ConstantValue>Value = Enums.GoodsAssemblyStatuses.AssembledDisassembled;</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Status</Description>
			|				<Type>EnumRef.GoodsAssemblyStatuses</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|</FilterByObjectProperties>";
EndFunction

Procedure ORR_Document_AssemblyFromComponents_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0)
	If Object.AssemblyForActivity = PredefinedValue("Enum.VATTaxationTypes.SpaceActivity") Then
		Cancel = True;
	EndIf;
EndProcedure
Procedure ORR_Document_AssemblyFromComponents_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Warehouse, Production";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_AssemblyFromComponents_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Warehouse, Production";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure
#EndRegion
#Region Document_Decomissioning
Procedure AddPRO_Document_WriteOff(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_Decomissioning";
	
	NewRule.MetadataObjectName3 = "Document.Decomissioning";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = True;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_15(),
		FilterByObjectProperties_4());
EndProcedure

Procedure ORR_Document_Decomissioning_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0)
	If Not GetFunctionalOption("LocalizationRFService") Then
		Cancel = True;
	EndIf;
EndProcedure

Procedure ORR_Document_Decomissioning_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Warehouse";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_Decomissioning_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Warehouse";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure
#EndRegion
#Region Document_WriteOffOfGoodsShortages
Procedure AddPRO_Document_WriteOffShortageOfGoods(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_WriteOffOfGoodsShortages";
	
	NewRule.MetadataObjectName3 = "Document.WriteOffOfGoodsShortages";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_16(),
		FilterByObjectProperties_4());
EndProcedure

Procedure ORR_Document_WriteOffOfGoodsShortages_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Warehouse";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_WriteOffOfGoodsShortages_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Warehouse";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure
#EndRegion
#Region Document_ReportOnVMIAdjustment
Procedure AddPRO_Document_ReportOnWriteOffOfGoodsFromStorage(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_ReportOnVMIAdjustment";
	
	NewRule.MetadataObjectName3 = "Document.ReportOnVMIAdjustment";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = True;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_15(),
		FilterByObjectProperties_4());
EndProcedure

Procedure ORR_Document_ReportOnVMIAdjustment_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0)
	Cancel = True;
EndProcedure

Procedure ORR_Document_ReportOnVMIAdjustment_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Warehouse";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_ReportOnVMIAdjustment_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Warehouse";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure
#EndRegion
#Region Document_PhysicalCountOfInventoryInOperation
Procedure AddPRO_Document_PhysicalInventoryCountOfInventoryItemsInOperation(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_PhysicalCountOfInventoryInOperation";
	
	NewRule.MetadataObjectName3 = "Document.PhysicalCountOfInventoryInOperation";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = True;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		Document_PhysicalInventoryCountOfInventoryItemsOfOperation_SelectionAccordingToPropertiesOfExchangePlan(),
		FilterByObjectProperties_4());
EndProcedure

Function Document_PhysicalInventoryCountOfInventoryItemsOfOperation_SelectionAccordingToPropertiesOfExchangePlan()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>FALSE</IsConstantString>
			|		<ObjectPropertyType>DATE</ObjectPropertyType>
			|		<ExchangePlanProperty>DocumentsExportStartDate</ExchangePlanProperty>
			|		<ComparisonType>GreaterOrEqual</ComparisonType>
			|		<ObjectProperty1>DATE</ObjectProperty1>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>DATE</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>DocumentsExportStartDate</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|			<ExchangePlanProperty>Companies.Organization</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Organization</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Companies]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<Group>
			|			<BooleanGroupValue>AND</BooleanGroupValue>
			|			<FilterElement>
			|				<IsConstantString>TRUE</IsConstantString>
			|				<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|				<ExchangePlanProperty>UseFilterByCompanies</ExchangePlanProperty>
			|				<ComparisonType>Equal</ComparisonType>
			|				<ObjectProperty1>FALSE</ObjectProperty1>
			|				<TableOfExchangePlanProperties>
			|					<Property>
			|						<Description>UseFilterByCompanies</Description>
			|						<TYPE>BOOLEAN</TYPE>
			|						<Kind>Attribute</Kind>
			|					</Property>
			|				</TableOfExchangePlanProperties>
			|			</FilterElement>
			|			<Group>
			|				<BooleanGroupValue>OR</BooleanGroupValue>
			|				<FilterElement>
			|					<IsConstantString>FALSE</IsConstantString>
			|					<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|					<ExchangePlanProperty>ManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>NotEqual</ComparisonType>
			|					<ObjectProperty1>Organization</ObjectProperty1>
			|					<ObjectPropertiesTable>
			|						<Property>
			|							<Description>Organization</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</ObjectPropertiesTable>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>ManagementCompany</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|				<FilterElement>
			|					<IsConstantString>TRUE</IsConstantString>
			|					<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|					<ExchangePlanProperty>UnloadManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>Equal</ComparisonType>
			|					<ObjectProperty1>TRUE</ObjectProperty1>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>UnloadManagementCompany</Description>
			|							<TYPE>BOOLEAN</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|			</Group>
			|		</Group>
			|	</Group>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeOfUPRMC</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeOfUPRMC</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>CashExchange</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>";
EndFunction

Procedure ORR_Document_PhysicalCountOfInventoryInOperation_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0)
	If Not GetFunctionalOption("LocalizationRFService") Then
	       Cancel = True;
	EndIf;
EndProcedure

Procedure ORR_Document_PhysicalCountOfInventoryInOperation_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Warehouse";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_PhysicalCountOfInventoryInOperation_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Warehouse";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure
#EndRegion
#Region Document_IssuedTaxInvoicePrepayment
Procedure AddPRO_Document_InvoiceAdvancePayment(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_IssuedTaxInvoicePrepayment";
	
	NewRule.MetadataObjectName3 = "Document.IssuedTaxInvoicePrepayment";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = True;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		Document_IssuedTaxInvoicePrepayment_FilterByExchangePlanProperties(),
		FilterByObjectProperties_4());
EndProcedure

Function Document_IssuedTaxInvoicePrepayment_FilterByExchangePlanProperties()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>FALSE</IsConstantString>
			|		<ObjectPropertyType>DATE</ObjectPropertyType>
			|		<ExchangePlanProperty>DocumentsExportStartDate</ExchangePlanProperty>
			|		<ComparisonType>GreaterOrEqual</ComparisonType>
			|		<ObjectProperty1>DATE</ObjectProperty1>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>DATE</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>DocumentsExportStartDate</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|			<ExchangePlanProperty>[Companies].Organization</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Organization</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Companies]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<Group>
			|			<BooleanGroupValue>AND</BooleanGroupValue>
			|			<FilterElement>
			|				<IsConstantString>TRUE</IsConstantString>
			|				<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|				<ExchangePlanProperty>UseFilterByCompanies</ExchangePlanProperty>
			|				<ComparisonType>Equal</ComparisonType>
			|				<ObjectProperty1>FALSE</ObjectProperty1>
			|				<TableOfExchangePlanProperties>
			|					<Property>
			|						<Description>UseFilterByCompanies</Description>
			|						<TYPE>BOOLEAN</TYPE>
			|						<Kind>Attribute</Kind>
			|					</Property>
			|				</TableOfExchangePlanProperties>
			|			</FilterElement>
			|			<Group>
			|				<BooleanGroupValue>OR</BooleanGroupValue>
			|				<FilterElement>
			|					<IsConstantString>FALSE</IsConstantString>
			|					<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|					<ExchangePlanProperty>ManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>NotEqual</ComparisonType>
			|					<ObjectProperty1>Organization</ObjectProperty1>
			|					<ObjectPropertiesTable>
			|						<Property>
			|							<Description>Organization</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</ObjectPropertiesTable>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>ManagementCompany</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|				<FilterElement>
			|					<IsConstantString>TRUE</IsConstantString>
			|					<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|					<ExchangePlanProperty>UnloadManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>Equal</ComparisonType>
			|					<ObjectProperty1>TRUE</ObjectProperty1>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>UnloadManagementCompany</Description>
			|							<TYPE>BOOLEAN</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|			</Group>
			|		</Group>
			|	</Group>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeUP2ZUP3</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>CashExchange</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeOfUPRMC</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<Group>
			|		<BooleanGroupValue>AND</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>TRUE</IsConstantString>
			|			<ObjectPropertyType>STRING</ObjectPropertyType>
			|			<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|			<ComparisonType>NotEqual</ComparisonType>
			|			<ObjectProperty1>UpuppExchange</ObjectProperty1>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>SettingsMode</Description>
			|					<TYPE>STRING</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|	</Group>
			|</FilterByExchangePlanProperties>";
EndFunction

Procedure ORR_Document_IssuedTaxInvoicePrepayment_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0)
	ExcludedTypesOfFoundationDocuments = New Array;
	ExcludedTypesOfFoundationDocuments.Add(Type("DocumentRef.IntercompanyGoodsReturn"));
	ExcludedTypesOfFoundationDocuments.Add(Type("DocumentRef.GiftCertificateSale"));
	ExcludedTypesOfFoundationDocuments.Add(Type("DocumentRef.OBEntry"));
	ExcludedTypesOfFoundationDocuments.Add(Type("DocumentRef.GoodsShipmentToCustomer"));
	If ValueIsFilled(Object.Ref)Then
    Basis = Common.ObjectAttributeValue(Object.Ref, "DocumentBasis");
	Else	
		Basis = Object.DocumentBasis;
	EndIf;
	If Not ValueIsFilled(Basis) 
		Or ExcludedTypesOfFoundationDocuments.Find(TypeOf(Object.DocumentBasis)) <> Undefined Then
		Cancel = True;
	EndIf;
	If Not Basis = Undefined And CommonClientServer.HasAttributeOrObjectProperty(Basis.Ref, "DocumentBasis")
		And ExcludedTypesOfFoundationDocuments.Find(TypeOf(Basis.DocumentBasis)) <> Undefined Then
	    Cancel = True;
	EndIf;
EndProcedure

Procedure ORR_Document_IssuedTaxInvoicePrepayment_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Sales";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_IssuedTaxInvoicePrepayment_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Sales";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure
#EndRegion


#Region Document_ReceivedTaxInvoicePrepayment
Procedure AddPRO_Document_InvoiceReceivedAdvance(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_ReceivedTaxInvoicePrepayment";
	
	NewRule.MetadataObjectName3 = "Document.ReceivedTaxInvoicePrepayment";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = True;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_18(),
		FilterByObjectProperties_4());
EndProcedure

Procedure ORR_Document_ReceivedTaxInvoicePrepayment_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0)
	ExcludedTypesOfFoundationDocuments = New Array;
	ExcludedTypesOfFoundationDocuments.Add(Type("DocumentRef.IntercompanyGoodsReturn"));
	ExcludedTypesOfFoundationDocuments.Add(Type("DocumentRef.OBEntry"));
	
	If Not ValueIsFilled(Object.DocumentBasis) 
		Or ExcludedTypesOfFoundationDocuments.Find(TypeOf(Object.DocumentBasis)) <> Undefined Then
		Cancel = True;
	EndIf;
EndProcedure

Procedure ORR_Document_ReceivedTaxInvoicePrepayment_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Purchases";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_ReceivedTaxInvoicePrepayment_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Purchases";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure
#EndRegion



#Region Document_PriceSetup
Procedure AddPRO_Document_SettingProductPrices(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_PriceSetup";
	
	NewRule.MetadataObjectName3 = "Document.PriceSetup";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		Document_SettingProductPrices_SelectionAccordingToPropertiesOfExchangePlan(),
		Document_SettingProductPrices_SelectionByObjectProperties());
EndProcedure

Function Document_SettingProductPrices_SelectionAccordingToPropertiesOfExchangePlan()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>false</IsConstantString>
			|		<ObjectPropertyType>Date</ObjectPropertyType>
			|		<ExchangePlanProperty>DocumentsExportStartDate</ExchangePlanProperty>
			|		<ComparisonType>GreaterOrEqual</ComparisonType>
			|		<ObjectProperty1>Date</ObjectProperty1>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Date</Description>
			|				<Type>Date</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>DocumentsExportStartDate</Description>
			|				<Type>Date</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>true</IsConstantString>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ExchangePlanProperty>UploadProductPrices</ExchangePlanProperty>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>true</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>UploadProductPrices</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>";
EndFunction

Function Document_SettingProductPrices_SelectionByObjectProperties()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>Approved</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>true</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Approved</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>Posted</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>true</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Posted</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|</FilterByObjectProperties>";
EndFunction

Procedure ORR_Document_PriceSetup_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	UseCache = False;
		
		TypesOfPrices = Object.TypesOfPrices.UnloadColumn("PriceKind");
		
		Query = New Query("SELECT
			|	TypesOfPrices.Ref
			|FROM
			|	Catalog.TypesOfPrices AS TypesOfPrices
			|WHERE
			|	NOT TypesOfPrices.DeletionMark
			|	AND TypesOfPrices.Ref IN (&TypesOfPrices)");
							  
		Query.Parameters.Insert("TypesOfPrices", TypesOfPrices);
		
		TypesOfPrices = Query.Execute().Unload().UnloadColumn("Ref");
		
		If TypesOfPrices.Count() = 0 Then
			Cancel = True;
		Else
		
			QueryOptions.Insert("TypesOfPrices", TypesOfPrices);
			QueryOptions.Insert("AccountingSection1", "Sales");
			QueryOptions.Insert("AccountingSection2", "Purchases");
		    QueryOptions.Insert("MetadataObjectName", Object.Metadata().Name);
			QueryText = 
			"SELECT DISTINCT
			|	ExchangePlanMainTable.Ref AS Ref
			|FROM
			|	ExchangePlan.DataSynchronizationViaUniversalFormat AS ExchangePlanMainTable
			|		LEFT JOIN ExchangePlan.DataSynchronizationViaUniversalFormat.ProductPricesTypes AS DataSynchronizationViaUniversalFormatProductPricesTypes
			|		ON ExchangePlanMainTable.Ref = DataSynchronizationViaUniversalFormatProductPricesTypes.Ref
			|			AND (DataSynchronizationViaUniversalFormatProductPricesTypes.ProductPricesType IN (&ObjectProperty1_TypesOfPrices))
			|		LEFT JOIN
			|			ExchangePlan.DataSynchronizationViaUniversalFormat.AccountingSections AS ExchangePlanAccountingSections
			|		ON ExchangePlanMainTable.Ref = ExchangePlanAccountingSections.Ref
			|		AND (ExchangePlanAccountingSections.AccountingSection = &ObjectProperty1_AccountingSection1
			|			OR ExchangePlanAccountingSections.AccountingSection = &ObjectProperty1_AccountingSection2)
			|		AND ExchangePlanAccountingSections.ToExport
			|LEFT JOIN ExchangePlan.DataSynchronizationViaUniversalFormat.DocumentsKinds AS DataSynchronizationViaUniversalDocumentTypesFormat
			|	ON ExchangePlanMainTable.Ref = DataSynchronizationViaUniversalDocumentTypesFormat.Ref
			|		AND (CASE
			|			WHEN ExchangePlanMainTable.UseFilterByAccountingSectionAndDocument
			|				THEN DataSynchronizationViaUniversalDocumentTypesFormat.Ref = ExchangePlanMainTable.Ref
			|						AND DataSynchronizationViaUniversalDocumentTypesFormat.MetadataObjectName = &ObjectProperty1_MetadataObjectName
			|			ELSE TRUE
			|	 	END)
			|WHERE
			|	ExchangePlanMainTable.DocumentsExportStartDate <= &ObjectProperty1_Date
			|	AND ExchangePlanMainTable.Ref <> &SynchronizeDataViaUniversalFormatOfThisNode
			|	AND NOT ExchangePlanMainTable.DeletionMark
			|   AND DataSynchronizationViaUniversalFormatProductPricesTypes.ProductPricesType IS NOT NULL
			|	AND ISNULL(ExchangePlanAccountingSections.ToExport, FALSE)
			|	AND &FilterCriterionByFlagAttribute
			|	AND CASE
			|			WHEN ISNULL(ExchangePlanMainTable.UseFilterByAccountingSectionAndDocument, FALSE) = TRUE
			|				THEN DataSynchronizationViaUniversalDocumentTypesFormat.MetadataObjectName = &ObjectProperty1_MetadataObjectName 
			|			ELSE TRUE
			|		END";
			
			QueryText = StrReplace(QueryText, "&SynchronizeDataViaUniversalFormatOfThisNode", "&DataSynchronizationViaUniversalFormat" + "ThisNode");
		
		EndIf;
EndProcedure

Procedure ORR_Document_PriceSetup_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	UseCache = False;
		
		TypesOfPrices = Object.TypesOfPrices.UnloadColumn("PriceKind");
		
		Query = New Query("SELECT
			|	TypesOfPrices.Ref
			|FROM
			|	Catalog.TypesOfPrices AS TypesOfPrices
			|WHERE
			|	NOT TypesOfPrices.DeletionMark
			|	AND TypesOfPrices.Ref IN (&TypesOfPrices)");
							  
		Query.Parameters.Insert("TypesOfPrices", TypesOfPrices);
		
		TypesOfPrices = Query.Execute().Unload().UnloadColumn("Ref");
		
		If TypesOfPrices.Count() = 0 Then
			Cancel = True;
		Else
		
			QueryOptions.Insert("TypesOfPrices", TypesOfPrices);
			QueryOptions.Insert("AccountingSection1", "Sales");
			QueryOptions.Insert("AccountingSection2", "Purchases");
		    QueryOptions.Insert("MetadataObjectName", Object.Metadata().Name);
			QueryText = 
			"SELECT DISTINCT
			|	ExchangePlanMainTable.Ref AS Ref
			|FROM
			|	ExchangePlan.DataSynchronizationViaUniversalFormat AS ExchangePlanMainTable
			|		LEFT JOIN ExchangePlan.DataSynchronizationViaUniversalFormat.ProductPricesTypes AS DataSynchronizationViaUniversalFormatProductPricesTypes
			|		ON ExchangePlanMainTable.Ref = DataSynchronizationViaUniversalFormatProductPricesTypes.Ref
			|			AND (DataSynchronizationViaUniversalFormatProductPricesTypes.ProductPricesType IN (&ObjectProperty1_TypesOfPrices))
			|		LEFT JOIN
			|			ExchangePlan.DataSynchronizationViaUniversalFormat.AccountingSections AS ExchangePlanAccountingSections
			|		ON ExchangePlanMainTable.Ref = ExchangePlanAccountingSections.Ref
			|		AND (ExchangePlanAccountingSections.AccountingSection = &ObjectProperty1_AccountingSection1
			|			OR ExchangePlanAccountingSections.AccountingSection = &ObjectProperty1_AccountingSection2)
			|		AND ExchangePlanAccountingSections.ToExport 
			|LEFT JOIN ExchangePlan.DataSynchronizationViaUniversalFormat.DocumentsKinds AS DataSynchronizationViaUniversalDocumentTypesFormat
			|	ON ExchangePlanMainTable.Ref = DataSynchronizationViaUniversalDocumentTypesFormat.Ref
			|		AND (CASE
			|			WHEN ExchangePlanMainTable.UseFilterByAccountingSectionAndDocument
			|				THEN DataSynchronizationViaUniversalDocumentTypesFormat.Ref = ExchangePlanMainTable.Ref
			|						AND DataSynchronizationViaUniversalDocumentTypesFormat.MetadataObjectName = &ObjectProperty1_MetadataObjectName
			|			ELSE TRUE
			|	 	END)
			|WHERE
			|	ExchangePlanMainTable.DocumentsExportStartDate <= &ObjectProperty1_Date
			|	AND ExchangePlanMainTable.Ref <> &SynchronizeDataViaUniversalFormatOfThisNode
			|	AND NOT ExchangePlanMainTable.DeletionMark
			|   AND DataSynchronizationViaUniversalFormatProductPricesTypes.ProductPricesType IS NOT NULL
			|	AND ISNULL(ExchangePlanAccountingSections.ToExport, FALSE)
			|	AND &FilterCriterionByFlagAttribute
			|	AND CASE
			|			WHEN ISNULL(ExchangePlanMainTable.UseFilterByAccountingSectionAndDocument, FALSE) = TRUE
			|				THEN DataSynchronizationViaUniversalDocumentTypesFormat.MetadataObjectName = &ObjectProperty1_MetadataObjectName 
			|			ELSE TRUE
			|		END";
			
			QueryText = StrReplace(QueryText, "&SynchronizeDataViaUniversalFormatOfThisNode", "&DataSynchronizationViaUniversalFormat" + "ThisNode");
		
		EndIf;
EndProcedure
#EndRegion
#Region Document_Booking
Procedure AddPRO_DocumentOfOperationWithElectronicTicket(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_ElectronicTicketTransaction";
	
	NewRule.MetadataObjectName3 = "Document.ElectronicTicketTransaction";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_3(),
		FilterByObjectProperties_4());
EndProcedure

#EndRegion
#Region Document_ApplicationForBusinessTrip
Procedure AddPRO_Document_BusinessTripRequest(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_ApplicationForBusinessTrip";
	
	NewRule.MetadataObjectName3 = "Document.ApplicationForBusinessTrip";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_3(),
		FilterByObjectProperties_4());
EndProcedure

#EndRegion


#Region Document_ApplicationForImportationOfGoods
Procedure AddPRO_Document_ApplicationForImportOfGoods(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_ApplicationForImportationOfGoods";
	
	NewRule.MetadataObjectName3 = "Document.ApplicationForImportationOfGoods";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		Document_ApplicationForImportOfGoods_SelectionAccordingToPropertiesOfExchangePlan(),
		FilterByObjectProperties_4());
EndProcedure

Function Document_ApplicationForImportOfGoods_SelectionAccordingToPropertiesOfExchangePlan()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>FALSE</IsConstantString>
			|		<ObjectPropertyType>DATE</ObjectPropertyType>
			|		<ExchangePlanProperty>DocumentsExportStartDate</ExchangePlanProperty>
			|		<ComparisonType>GreaterOrEqual</ComparisonType>
			|		<ObjectProperty1>DATE</ObjectProperty1>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>DATE</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>DocumentsExportStartDate</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|			<ExchangePlanProperty>Companies.Organization</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Organization</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Companies]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<Group>
			|			<BooleanGroupValue>AND</BooleanGroupValue>
			|			<FilterElement>
			|				<IsConstantString>TRUE</IsConstantString>
			|				<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|				<ExchangePlanProperty>UseFilterByCompanies</ExchangePlanProperty>
			|				<ComparisonType>Equal</ComparisonType>
			|				<ObjectProperty1>FALSE</ObjectProperty1>
			|				<TableOfExchangePlanProperties>
			|					<Property>
			|						<Description>UseFilterByCompanies</Description>
			|						<TYPE>BOOLEAN</TYPE>
			|						<Kind>Attribute</Kind>
			|					</Property>
			|				</TableOfExchangePlanProperties>
			|			</FilterElement>
			|			<Group>
			|				<BooleanGroupValue>OR</BooleanGroupValue>
			|				<FilterElement>
			|					<IsConstantString>FALSE</IsConstantString>
			|					<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|					<ExchangePlanProperty>ManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>NotEqual</ComparisonType>
			|					<ObjectProperty1>Organization</ObjectProperty1>
			|					<ObjectPropertiesTable>
			|						<Property>
			|							<Description>Organization</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</ObjectPropertiesTable>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>ManagementCompany</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|				<FilterElement>
			|					<IsConstantString>TRUE</IsConstantString>
			|					<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|					<ExchangePlanProperty>UnloadManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>Equal</ComparisonType>
			|					<ObjectProperty1>TRUE</ObjectProperty1>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>UnloadManagementCompany</Description>
			|							<TYPE>BOOLEAN</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|			</Group>
			|		</Group>
			|	</Group>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>CashExchange</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeOfUPRMC</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeUP2ZUP3</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>";
EndFunction

Procedure ORR_Document_ApplicationForImportationOfGoods_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Purchases";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure
#EndRegion

#Region Document_ReversingEntry
Procedure AddPRO_Document_Storno(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_ReversingEntry";
	
	NewRule.MetadataObjectName3 = "Document.ReversingEntry";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = True;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = True;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_18(),
		FilterByObjectProperties_4());
EndProcedure

Procedure ORR_Document_ReversingEntry_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0)
	DataExchangeEventsTM.DocumentIsStornoBeforeProcessingABOUT(Object, Cancel);
EndProcedure

Procedure ORR_Document_ReversingEntry_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "TreasuryAndARAPAccounting, Warehouse, Purchases, Sales, Return leftovers";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_ReversingEntry_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "TreasuryAndARAPAccounting, Warehouse, Purchases, Sales, Return leftovers";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure

Procedure ORR_Document_ReversingEntry_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0)
	If Not Cancel And Recipients.Count() > 0 Then
		
		DocumentObject = Object.ReversedDocument.GetObject();
		
		Recipients = GetRecipients(DocumentObject, ORR.ExchangePlanName);
		
		If Not Upload0 Then
			
			CommonClientServer.DeleteValueFromArray(Recipients, Object.DataExchange.Sender);
			
			If Recipients.Count() > 0 Then
				
				ExchangePlans.RecordChanges(Recipients, DocumentObject);
				
			EndIf;
		
		EndIf;
		
	EndIf;
EndProcedure
#EndRegion
#Region Document_GoodsShipmentToCustomer
Procedure AddPRO_Document_ShipmentOfGoodsToCustomer(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Document_GoodsShipmentToCustomer";
	
	NewRule.MetadataObjectName3 = "Document.GoodsShipmentToCustomer";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = True;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_16(),
		Document_ShipmentOfGoodsToClient_SelectionByObjectProperties());
EndProcedure

Function Document_ShipmentOfGoodsToClient_SelectionByObjectProperties()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>Posted</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>true</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Posted</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>EnumRef.VATTaxationTypes</ObjectPropertyType>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>VATTaxation</ObjectProperty1>
			|		<Kind>ValueAlgorithm</Kind>
			|		<ConstantValue>Value = PredefinedValue(""Enum.VATTaxationTypes.SubjectToVATFromPriceDifference"");</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>VATTaxation</Description>
			|				<Type>EnumRef.VATTaxationTypes</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>EnumRef.VATTaxationTypes</ObjectPropertyType>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>VATTaxation</ObjectProperty1>
			|		<Kind>ValueAlgorithm</Kind>
			|		<ConstantValue>Value = PredefinedValue(""Enum.VATTaxationTypes.SpaceActivity"");</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>VATTaxation</Description>
			|				<Type>EnumRef.VATTaxationTypes</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|</FilterByObjectProperties>";
EndFunction

Procedure ORR_Document_GoodsShipmentToCustomer_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Sales";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_Document_GoodsShipmentToCustomer_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Sales";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure

Procedure ORR_Document_GoodsShipmentToCustomer_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0)
EndProcedure
#EndRegion
#Region ChartOfCharacteristicTypes_IncomeItems
Procedure AddPRO_PLANOfTypesOfCharacteristics_IncomeItems(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "ChartOfCharacteristicTypes_IncomeItems";
	
	NewRule.MetadataObjectName3 = "ChartOfCharacteristicTypes.IncomeItems";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "ExportModeOnDemand";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		EmptySelectionByExchangePlanProperties(),
		EmptySelectionByObjectProperties());
EndProcedure

#EndRegion
#Region ChartOfCharacteristicTypes_ExpenseItems
Procedure AddPRO_PLANOfTypesOfCharacteristics_ItemsOfExpenditure(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "ChartOfCharacteristicTypes_ExpenseItems";
	
	NewRule.MetadataObjectName3 = "ChartOfCharacteristicTypes.ExpenseItems";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "ExportModeOnDemand";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		EmptySelectionByExchangePlanProperties(),
		EmptySelectionByObjectProperties());
EndProcedure

#EndRegion
#Region InformationRegister_RefinementsOfRetailOutletInventoryAffiliation
Procedure AddPRO_InformationRegister_ClarificationOfInventoryOwnershipOfRetailOutlets(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "InformationRegister_RefinementsOfRetailOutletInventoryAffiliation";
	
	NewRule.MetadataObjectName3 = "InformationRegister.RefinementsOfRetailOutletInventoryAffiliation";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "CatalogsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		InformationRegister_ClarificationOfInventoryOwnershipOfOutlets_SelectionAccordingToPropertiesOfExchangePlan(),
		InformationRegister_ClarificationOfInventoryOwnershipOfRetailOutlets_SelectionByObjectProperties());
EndProcedure

Function InformationRegister_ClarificationOfInventoryOwnershipOfOutlets_SelectionAccordingToPropertiesOfExchangePlan()
	Return "<FilterByExchangePlanProperties>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>TRUE</IsConstantString>
			|			<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|			<ExchangePlanProperty>UseFilterByWarehouses</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>FALSE</ObjectProperty1>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>UseFilterByWarehouses</Description>
			|					<TYPE>BOOLEAN</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Warehouses</ObjectPropertyType>
			|			<ExchangePlanProperty>Warehouses.Warehouse</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Warehouse</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Warehouse</Description>
			|					<TYPE>CatalogRef.Warehouses</TYPE>
			|					<Kind>Dimension</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Warehouses]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Warehouse</Description>
			|					<TYPE>CatalogRef.Warehouses</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|	</Group>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>TRUE</IsConstantString>
			|			<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|			<ExchangePlanProperty>UseFilterByCompanies</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>FALSE</ObjectProperty1>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>UseFilterByCompanies</Description>
			|					<TYPE>BOOLEAN</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|			<ExchangePlanProperty>Companies.Organization</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>CompanyCustomer</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>CompanyCustomer</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Dimension</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Companies]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|	</Group>
			|	<Group>
			|		<BooleanGroupValue>AND</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>TRUE</IsConstantString>
			|			<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|			<ExchangePlanProperty>UploadProductPrices</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>TRUE</ObjectProperty1>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>UploadProductPrices</Description>
			|					<TYPE>BOOLEAN</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.TypesOfPrices</ObjectPropertyType>
			|			<ExchangePlanProperty>ProductPricesTypes.ProductPricesType</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Warehouse.RetailPriceType</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Warehouse</Description>
			|					<TYPE>CatalogRef.Warehouses</TYPE>
			|					<Kind>Dimension</Kind>
			|				</Property>
			|				<Property>
			|					<Description>RetailPriceType</Description>
			|					<TYPE>CatalogRef.TypesOfPrices</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[ProductPricesTypes]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>ProductPricesType</Description>
			|					<TYPE>CatalogRef.TypesOfPrices</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|	</Group>
			|</FilterByExchangePlanProperties>";
EndFunction

Function InformationRegister_ClarificationOfInventoryOwnershipOfRetailOutlets_SelectionByObjectProperties()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>EnumRef.TypesOfWarehouses</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>Warehouse.WarehouseStore</ObjectProperty1>
			|		<Kind>ValueAlgorithm</Kind>
			|		<ConstantValue>Value = Enums.TypesOfWarehouses.RetailStore;</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Warehouse</Description>
			|				<Type>CatalogRef.Warehouses</Type>
			|				<Kind>Dimension</Kind>
			|			</Property>
			|			<Property>
			|				<Description>WarehouseStore</Description>
			|				<Type>EnumRef.TypesOfWarehouses</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>Warehouse.DeletionMark</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>false</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Warehouse</Description>
			|				<Type>CatalogRef.Warehouses</Type>
			|				<Kind>Dimension</Kind>
			|			</Property>
			|			<Property>
			|				<Description>DeletionMark</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>CompanyCustomer.DeletionMark</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>false</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>CompanyCustomer</Description>
			|				<Type>CatalogRef.Companies</Type>
			|				<Kind>Dimension</Kind>
			|			</Property>
			|			<Property>
			|				<Description>DeletionMark</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|</FilterByObjectProperties>";
EndFunction

Procedure ORR_InformationRegister_RefinementsOfRetailOutletInventoryAffiliation_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Warehouse";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_InformationRegister_RefinementsOfRetailOutletInventoryAffiliation_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Warehouse";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure
#EndRegion
#Region InformationRegister_DocumentsPersons
Procedure AddPRO_InformationRegister_DocumentsOfIndividuals(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "InformationRegister_DocumentsPersons";
	
	NewRule.MetadataObjectName3 = "InformationRegister.DocumentsPersons";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "CatalogsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = True;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		InformationRegister_DocumentsOfIndividuals_SelectionAccordingToPropertiesOfExchangePlan(),
		InformationRegister_DocumentsOfIndividuals_SelectionByObjectProperties());
EndProcedure

Function InformationRegister_DocumentsOfIndividuals_SelectionAccordingToPropertiesOfExchangePlan()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>true</IsConstantString>
			|		<ObjectPropertyType>String</ObjectPropertyType>
			|		<ExchangePlanProperty>ExchangeFormatVersion</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>1.0.beta</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>ExchangeFormatVersion</Description>
			|				<Type>String</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>true</IsConstantString>
			|		<ObjectPropertyType>String</ObjectPropertyType>
			|		<ExchangePlanProperty>ExchangeFormatVersion</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>1.0</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>ExchangeFormatVersion</Description>
			|				<Type>String</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>true</IsConstantString>
			|		<ObjectPropertyType>String</ObjectPropertyType>
			|		<ExchangePlanProperty>ExchangeFormatVersion</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>1.1</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>ExchangeFormatVersion</Description>
			|				<Type>String</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>true</IsConstantString>
			|		<ObjectPropertyType>String</ObjectPropertyType>
			|		<ExchangePlanProperty>ExchangeFormatVersion</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>1.2</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>ExchangeFormatVersion</Description>
			|				<Type>String</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>true</IsConstantString>
			|		<ObjectPropertyType>String</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>CashExchange</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<Type>String</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>true</IsConstantString>
			|		<ObjectPropertyType>String</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeOfUPRMC</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<Type>String</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>";
EndFunction

Function InformationRegister_DocumentsOfIndividuals_SelectionByObjectProperties()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>Person.DeletionMark</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>false</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Person</Description>
			|				<Type>CatalogRef.Counterparties</Type>
			|				<Kind>Dimension</Kind>
			|			</Property>
			|			<Property>
			|				<Description>DeletionMark</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>DocumentKind.DeletionMark</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>false</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>DocumentKind</Description>
			|				<Type>CatalogRef.DocumentKindsOfPersons</Type>
			|				<Kind>Dimension</Kind>
			|			</Property>
			|			<Property>
			|				<Description>DeletionMark</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>ThisIsAnIdentityDocument</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>true</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>ThisIsAnIdentityDocument</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Resource</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|</FilterByObjectProperties>";
EndFunction

Procedure ORR_InformationRegister_DocumentsPersons_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0)
	Cancel = (TypeOf(Object.Filter.Person.Value) <> Type("CatalogRef.Persons"));
EndProcedure
#EndRegion
#Region InformationRegister_GoodsAvailabilityForExternalUsers
Procedure AddPRO_InformationRegister_AvailabilityOfProductsForExternalUsers(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "InformationRegister_GoodsAvailabilityForExternalUsers";
	
	NewRule.MetadataObjectName3 = "InformationRegister.GoodsAvailabilityForExternalUsers";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "DocumentsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = True;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		InformationRegister_AvailabilityOfGoodsToExternalUsers_SelectionByExchangePlanProperties(),
		EmptySelectionByObjectProperties());
EndProcedure

Function InformationRegister_AvailabilityOfGoodsToExternalUsers_SelectionByExchangePlanProperties()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>true</IsConstantString>
			|		<ObjectPropertyType>String</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeUP2ZUP3</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<Type>String</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<Group>
			|		<BooleanGroupValue>And</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>true</IsConstantString>
			|			<ObjectPropertyType>Boolean</ObjectPropertyType>
			|			<ExchangePlanProperty>UploadInformativeBalance</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>true</ObjectProperty1>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>UploadInformativeBalance</Description>
			|					<Type>Boolean</Type>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<FilterElement>
			|			<IsConstantString>false</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Warehouses</ObjectPropertyType>
			|			<ExchangePlanProperty>[WarehousesOfInformativeBalance].Warehouse</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Warehouse</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Warehouse</Description>
			|					<Type>CatalogRef.Warehouses</Type>
			|					<Kind>Dimension</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[WarehousesOfInformativeBalance]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Warehouse</Description>
			|					<Type>CatalogRef.Warehouses</Type>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|	</Group>
			|</FilterByExchangePlanProperties>";
EndFunction

Procedure ORR_InformationRegister_GoodsAvailabilityForExternalUsers_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0)
	// It is necessary to clean the recipient table, as there may be situations where recipient nodes are already filled in before processing the registration rules.  
	Object.DataExchange.Recipients.Clear()
EndProcedure

Procedure ORR_InformationRegister_GoodsAvailabilityForExternalUsers_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Warehouse";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_InformationRegister_GoodsAvailabilityForExternalUsers_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Warehouse";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure
#EndRegion


#Region InformationRegister_SalesOrderStates
Procedure AddPRO_InformationRegister_StateOfCustomerOrders(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "InformationRegister_SalesOrderStates";
	
	NewRule.MetadataObjectName3 = "InformationRegister.SalesOrderStates";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "CatalogsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = True;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_8(),
		EmptySelectionByObjectProperties());
EndProcedure

Procedure ORR_InformationRegister_SalesOrderStates_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0)
	OrderDocument = Object.Filter.OrderDocument.Value;
	
	If ValueIsFilled(OrderDocument)
		And Common.RefExists(OrderDocument) Then
		Recipients = GetRecipients(OrderDocument.GetObject(), ORR.ExchangePlanName);
	Else
		Recipients = AllExchangePlanNodes(ORR.ExchangePlanName)
	EndIf;
EndProcedure
#EndRegion
#Region InformationRegister_FullNameOfPersons
Procedure AddPRO_InformationRegister_FullNameOfPersons(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "InformationRegister_FullNameOfPersons";
	
	NewRule.MetadataObjectName3 = "InformationRegister.FullNameOfPersons";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "CatalogsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = True;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		InformationRegister_FIOOfIndividuals_SelectionByPropertiesOfExchangePlan(),
		InformationRegister_FullNameOfPersons_FilterByObjectProperties());
EndProcedure

Function InformationRegister_FIOOfIndividuals_SelectionByPropertiesOfExchangePlan()
	Return "<FilterByExchangePlanProperties>
			|	<Group>
			|		<BooleanGroupValue>AND</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>TRUE</IsConstantString>
			|			<ObjectPropertyType>STRING</ObjectPropertyType>
			|			<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|			<ComparisonType>NotEqual</ComparisonType>
			|			<ObjectProperty1>CashExchange</ObjectProperty1>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>SettingsMode</Description>
			|					<TYPE>STRING</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<Group>
			|			<BooleanGroupValue>OR</BooleanGroupValue>
			|			<FilterElement>
			|				<IsConstantString>FALSE</IsConstantString>
			|				<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|				<ExchangePlanProperty>[Companies].Organization</ExchangePlanProperty>
			|				<ComparisonType>Equal</ComparisonType>
			|				<ObjectProperty1>Individual</ObjectProperty1>
			|				<ObjectPropertiesTable>
			|					<Property>
			|						<Description>Individual</Description>
			|						<TYPE>CatalogRef.Companies</TYPE>
			|						<Kind>Dimension</Kind>
			|					</Property>
			|				</ObjectPropertiesTable>
			|				<TableOfExchangePlanProperties>
			|					<Property>
			|						<Description>[Companies]</Description>
			|						<Kind>TabularSection</Kind>
			|					</Property>
			|					<Property>
			|						<Description>Organization</Description>
			|						<TYPE>CatalogRef.Companies</TYPE>
			|						<Kind>Attribute</Kind>
			|					</Property>
			|				</TableOfExchangePlanProperties>
			|			</FilterElement>
			|			<Group>
			|				<BooleanGroupValue>AND</BooleanGroupValue>
			|				<FilterElement>
			|					<IsConstantString>TRUE</IsConstantString>
			|					<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|					<ExchangePlanProperty>UseFilterByCompanies</ExchangePlanProperty>
			|					<ComparisonType>Equal</ComparisonType>
			|					<ObjectProperty1>FALSE</ObjectProperty1>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>UseFilterByCompanies</Description>
			|							<TYPE>BOOLEAN</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|				<Group>
			|					<BooleanGroupValue>OR</BooleanGroupValue>
			|					<FilterElement>
			|						<IsConstantString>FALSE</IsConstantString>
			|						<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|						<ExchangePlanProperty>ManagementCompany</ExchangePlanProperty>
			|						<ComparisonType>NotEqual</ComparisonType>
			|						<ObjectProperty1>Individual</ObjectProperty1>
			|						<ObjectPropertiesTable>
			|							<Property>
			|								<Description>Individual</Description>
			|								<TYPE>CatalogRef.Companies</TYPE>
			|								<Kind>Dimension</Kind>
			|							</Property>
			|						</ObjectPropertiesTable>
			|						<TableOfExchangePlanProperties>
			|							<Property>
			|								<Description>ManagementCompany</Description>
			|								<TYPE>CatalogRef.Companies</TYPE>
			|								<Kind>Attribute</Kind>
			|							</Property>
			|						</TableOfExchangePlanProperties>
			|					</FilterElement>
			|					<FilterElement>
			|						<IsConstantString>TRUE</IsConstantString>
			|						<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|						<ExchangePlanProperty>UnloadManagementCompany</ExchangePlanProperty>
			|						<ComparisonType>Equal</ComparisonType>
			|						<ObjectProperty1>TRUE</ObjectProperty1>
			|						<TableOfExchangePlanProperties>
			|							<Property>
			|								<Description>UnloadManagementCompany</Description>
			|								<TYPE>BOOLEAN</TYPE>
			|								<Kind>Attribute</Kind>
			|							</Property>
			|						</TableOfExchangePlanProperties>
			|					</FilterElement>
			|				</Group>
			|			</Group>
			|		</Group>
			|	</Group>
			|</FilterByExchangePlanProperties>";
EndFunction

Function InformationRegister_FullNameOfPersons_FilterByObjectProperties()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>Individual.DeletionMark</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>false</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Individual</Description>
			|				<Type>CatalogRef.Companies</Type>
			|				<Kind>Dimension</Kind>
			|			</Property>
			|			<Property>
			|				<Description>DeletionMark</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|</FilterByObjectProperties>";
EndFunction

Procedure ORR_InformationRegister_FullNameOfPersons_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0)
	Cancel = True;
	Individual = Object.Filter.Individual.Value;
	
	If Not Upload0
		And Common.RefExists(Individual) Then	
		ExecuteRegistrationRulesForObject(Individual.GetObject(), ORR.ExchangePlanName, Object.DataExchange.Sender);	
	EndIf;
EndProcedure
#EndRegion
#Region InformationRegister_ItemsBarcodes
Procedure AddPRO_InformationRegister_ProductBarcodes(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "InformationRegister_ItemsBarcodes";
	
	NewRule.MetadataObjectName3 = "InformationRegister.ItemsBarcodes";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "CatalogsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		InformationRegister_BarcodesOfItem_SelectionAccordingToPropertiesOfExchangePlan(),
		InformationRegister_ItemsBarcodes_FilterByObjectProperties());
EndProcedure

Function InformationRegister_BarcodesOfItem_SelectionAccordingToPropertiesOfExchangePlan()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>true</IsConstantString>
			|		<ObjectPropertyType>String</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeUP2ZUP3</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<Type>String</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>";
EndFunction

Function InformationRegister_ItemsBarcodes_FilterByObjectProperties()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>Products.DeletionMark</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>true</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Products</Description>
			|				<Type>CatalogRef.Products</Type>
			|				<Kind>Resource</Kind>
			|			</Property>
			|			<Property>
			|				<Description>DeletionMark</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|</FilterByObjectProperties>";
EndFunction

Procedure ORR_InformationRegister_ItemsBarcodes_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.AccountingSectionsByLine = "Warehouse, Purchases, Sales, Production";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
EndProcedure

Procedure ORR_InformationRegister_ItemsBarcodes_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	DataProcessingParameters = DataExchangeEventsTM.InitializeDataProcessingParameters();
	
	DataProcessingParameters.QueryText        = QueryText;
	DataProcessingParameters.QueryOptions    = QueryOptions;
	DataProcessingParameters.UseCache     = UseCache;
	DataProcessingParameters.Cancel               = Cancel;
	DataProcessingParameters.Object              = Object;
	DataProcessingParameters.Upload0            = Upload0;
	DataProcessingParameters.AccountingSectionsByLine = "Warehouse, Purchases, Sales, Production";
	
	ParametersOfProcessingPROAfterProcessing = DataExchangeEventsTM.WhenProcessingData(DataProcessingParameters);
	
	QueryText     = ParametersOfProcessingPROAfterProcessing.QueryText;
	QueryOptions = ParametersOfProcessingPROAfterProcessing.QueryOptions;
	UseCache  = ParametersOfProcessingPROAfterProcessing.UseCache;
	Cancel            = ParametersOfProcessingPROAfterProcessing.Cancel;
	Object           = ParametersOfProcessingPROAfterProcessing.Object;
	Upload0         = ParametersOfProcessingPROAfterProcessing.Upload0;
EndProcedure
#EndRegion
#Region InformationRegister_SegmentProducts
Procedure AddPRO_InformationRegister_SegmentItem(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "InformationRegister_SegmentProducts";
	
	NewRule.MetadataObjectName3 = "InformationRegister.SegmentProducts";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "CatalogsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_4(),
		InformationRegister_SegmentItemList_SelectionByItemProperties());
EndProcedure

Function InformationRegister_SegmentItemList_SelectionByItemProperties()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>Products.DeletionMark</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>false</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Products</Description>
			|				<Type>CatalogRef.Products</Type>
			|				<Kind>Dimension</Kind>
			|			</Property>
			|			<Property>
			|				<Description>DeletionMark</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>Segment.DeletionMark</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>false</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Segment</Description>
			|				<Type>CatalogRef.ProductSegments</Type>
			|				<Kind>Dimension</Kind>
			|			</Property>
			|			<Property>
			|				<Description>DeletionMark</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|</FilterByObjectProperties>";
EndFunction

#EndRegion



#Region Catalog_Currencies
Procedure AddPRO_Catalog_Currency(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_Currencies";
	
	NewRule.MetadataObjectName3 = "Catalog.Currencies";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "ExportModeOnDemand";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		EmptySelectionByExchangePlanProperties(),
		FilterByObjectProperties_10());
EndProcedure

#EndRegion
#Region Catalog_BankClassifier
Procedure AddPRO_Catalog_BankClassifier(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_BankClassifier";
	
	NewRule.MetadataObjectName3 = "Catalog.BankClassifier";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "ExportModeOnDemand";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		EmptySelectionByExchangePlanProperties(),
		FilterByObjectProperties_10());
EndProcedure

#EndRegion
#Region Catalog_WorldCountries
Procedure AddPRO_Catalog_CountriesOfWorld(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_WorldCountries";
	
	NewRule.MetadataObjectName3 = "Catalog.WorldCountries";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "ExportModeOnDemand";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		EmptySelectionByExchangePlanProperties(),
		FilterByObjectProperties_10());
EndProcedure

#EndRegion
#Region Catalog_PackagesAndUnitsOfMeasure
Procedure AddPRO_Catalog__UnitsOfMeasurement(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_PackagesAndUnitsOfMeasure";
	
	NewRule.MetadataObjectName3 = "Catalog.PackagesAndUnitsOfMeasure";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "CatalogsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = True;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_8(),
		Catalog_PackagesAndUnitsOfMeasure_FilterByObjectProperties());
EndProcedure

Function Catalog_PackagesAndUnitsOfMeasure_FilterByObjectProperties()
	Return "<FilterByObjectProperties>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<ObjectPropertyType>CatalogRef.PackagingGroups</ObjectPropertyType>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Owner</ObjectProperty1>
			|			<Kind>ValueAlgorithm</Kind>
			|			<ConstantValue>VALUE = Catalogs.PackagingGroups.BasicUnitsOfMeasure;</ConstantValue>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Owner</Description>
			|					<TYPE>CatalogRef.PackagingGroups</TYPE>
			|					<Kind>Property</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|		</FilterElement>
			|		<FilterElement>
			|			<ObjectPropertyType>CatalogRef.PackagingGroups</ObjectPropertyType>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Owner.PackagingGroup</ObjectProperty1>
			|			<Kind>ValueAlgorithm</Kind>
			|			<ConstantValue>VALUE = Catalogs.PackagingGroups.SpecialForItem;</ConstantValue>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Owner</Description>
			|					<TYPE>CatalogRef.PackagingGroups</TYPE>
			|					<Kind>Property</Kind>
			|				</Property>
			|				<Property>
			|					<Description>PackagingGroup</Description>
			|					<TYPE>CatalogRef.PackagingGroups</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|		</FilterElement>
			|	</Group>
			|</FilterByObjectProperties>";
EndFunction

Procedure ORR_Catalog_PackagesAndUnitsOfMeasure_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0)
	If Not Object.Owner = Catalogs.PackagingGroups.BasicUnitsOfMeasure
		And Not (ValueIsFilled(Object.Owner) And TypeOf(Object.Owner) = Type("CatalogRef.Products")) Then
		Cancel = True;
	EndIf;
EndProcedure
#EndRegion
#Region Catalog_FEACN
Procedure AddPRO_Catalog_FuelTaxClassifier(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_FEACN";
	
	NewRule.MetadataObjectName3 = "Catalog.FEACN";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "CatalogsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		Catalog_FEACN_FilterByExchangePlanProperties(),
		FilterByObjectProperties_10());
EndProcedure

Function Catalog_FEACN_FilterByExchangePlanProperties()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>true</IsConstantString>
			|		<ObjectPropertyType>String</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>CashExchange</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<Type>String</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>";
EndFunction

#EndRegion
#Region Catalog_PackagesAndUnitsOfMeasure2
Procedure AddPRO_Catalog__UnitsOfMeasurement2(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_PackagesAndUnitsOfMeasure2";
	
	NewRule.MetadataObjectName3 = "Catalog.PackagesAndUnitsOfMeasure";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "ExportModeOnDemand";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = True;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_10(),
		EmptySelectionByObjectProperties());
EndProcedure

Procedure ORR_Catalog_PackagesAndUnitsOfMeasure2_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0)
	If Not Object.Owner = Catalogs.PackagingGroups.BasicUnitsOfMeasure
		And Not (ValueIsFilled(Object.Owner) And TypeOf(Object.Owner) = Type("CatalogRef.Products")) Then
		Cancel = True;
	EndIf;
EndProcedure
#EndRegion
#Region Catalog_IntangibleAssets
Procedure AddPRO_Catalog_IntangibleAssets(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_IntangibleAssets";
	
	NewRule.MetadataObjectName3 = "Catalog.IntangibleAssets";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "CatalogsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = True;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_9(),
		Catalog_IntangibleAssets_FilterByObjectProperties());
EndProcedure

Function Catalog_IntangibleAssets_FilterByObjectProperties()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>DeletionMark</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>false</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>DeletionMark</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>IsFolder</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>false</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>IsFolder</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>EnumRef.IntangibleAssetsAccountingItemKinds</ObjectPropertyType>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>KindOfAccountingObject</ObjectProperty1>
			|		<Kind>ValueAlgorithm</Kind>
			|		<ConstantValue>Value = PredefinedValue(""Enum.IntangibleAssetsAccountingItemKinds.RDExpenses"")</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>KindOfAccountingObject</Description>
			|				<Type>EnumRef.IntangibleAssetsAccountingItemKinds</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|</FilterByObjectProperties>";
EndFunction

Procedure ORR_Catalog_IntangibleAssets_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0)
	Cancel = True;
EndProcedure
#EndRegion
#Region Catalog_Assets
Procedure AddPRO_Catalog_ObjectsOfOperation(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_Assets";
	
	NewRule.MetadataObjectName3 = "Catalog.Assets";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "CatalogsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = True;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_9(),
		FilterByObjectProperties_6());
EndProcedure

Procedure ORR_Catalog_Assets_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0)
	Cancel = True;
EndProcedure
#EndRegion
#Region Catalog_CounterpartyBankAccounts
Procedure AddPRO_Catalog_CounterpartyBankAccounts(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_CounterpartyBankAccounts";
	
	NewRule.MetadataObjectName3 = "Catalog.CounterpartyBankAccounts";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "CatalogsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_21(),
		FilterByObjectProperties_10());
EndProcedure

#EndRegion
#Region Catalog_LoanAndDepositContracts
Procedure AddPRO_Catalog_LoanAndDepositAgreements(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_LoanAndDepositContracts";
	
	NewRule.MetadataObjectName3 = "Catalog.LoanAndDepositContracts";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "CatalogsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_6(),
		FilterByObjectProperties_10());
EndProcedure

#EndRegion
#Region Catalog_CounterpartyContracts
Procedure AddPRO_Catalog_CounterpartyAgreements(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_CounterpartyContracts";
	
	NewRule.MetadataObjectName3 = "Catalog.CounterpartyContracts";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "CatalogsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_6(),
		FilterByObjectProperties_10());
EndProcedure

#EndRegion
#Region Catalog_Counterparties
Procedure AddPRO_Catalog_Counterparties(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_Counterparties";
	
	NewRule.MetadataObjectName3 = "Catalog.Counterparties";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "CatalogsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = True;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_8(),
		FilterByObjectProperties_10());
EndProcedure

Procedure ORR_Catalog_Counterparties_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0)
	If Recipients.Count() > 0 Then
			// For the exchange, we will delete the registration of NON-Suppliers
			ThisIsSupplier = Undefined;
			MaxIndex_ = Recipients.UBound();
			For IndexOf = 0 To MaxIndex_ Do
				CurIndx = MaxIndex_ - IndexOf;
				CurRecipient = Recipients[CurIndx];
				If CurRecipient.SettingsMode = "CashExchange" Then
					If ThisIsSupplier = Undefined Then
						ThisIsSupplier = Common.ObjectAttributeValue(Object.Partner, "Vendor");
					EndIf;
					If Not ThisIsSupplier = Undefined And Not ThisIsSupplier Then
						Recipients.Delete(CurIndx);
					EndIf;
				EndIf;
			EndDo;
		EndIf;
EndProcedure
#EndRegion
#Region Catalog_IntercompanyContracts
Procedure AddPRO_Catalog_ContractsBetweenOrganizations(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_IntercompanyContracts";
	
	NewRule.MetadataObjectName3 = "Catalog.IntercompanyContracts";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "CatalogsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		Catalog_IntercompanyContracts_FilterByExchangePlanProperties(),
		FilterByObjectProperties_10());
EndProcedure

Function Catalog_IntercompanyContracts_FilterByExchangePlanProperties()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeUP2ZUP3</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>CashExchange</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|			<ExchangePlanProperty>[Companies].Organization</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Organization</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Companies]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|			<ExchangePlanProperty>[Companies].Organization</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>CompanyRecipient</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>CompanyRecipient</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Companies]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<Group>
			|			<BooleanGroupValue>AND</BooleanGroupValue>
			|			<FilterElement>
			|				<IsConstantString>TRUE</IsConstantString>
			|				<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|				<ExchangePlanProperty>UseFilterByCompanies</ExchangePlanProperty>
			|				<ComparisonType>Equal</ComparisonType>
			|				<ObjectProperty1>FALSE</ObjectProperty1>
			|				<TableOfExchangePlanProperties>
			|					<Property>
			|						<Description>UseFilterByCompanies</Description>
			|						<TYPE>BOOLEAN</TYPE>
			|						<Kind>Attribute</Kind>
			|					</Property>
			|				</TableOfExchangePlanProperties>
			|			</FilterElement>
			|			<Group>
			|				<BooleanGroupValue>OR</BooleanGroupValue>
			|				<FilterElement>
			|					<IsConstantString>FALSE</IsConstantString>
			|					<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|					<ExchangePlanProperty>ManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>NotEqual</ComparisonType>
			|					<ObjectProperty1>Organization</ObjectProperty1>
			|					<ObjectPropertiesTable>
			|						<Property>
			|							<Description>Organization</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</ObjectPropertiesTable>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>ManagementCompany</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|				<FilterElement>
			|					<IsConstantString>FALSE</IsConstantString>
			|					<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|					<ExchangePlanProperty>ManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>NotEqual</ComparisonType>
			|					<ObjectProperty1>CompanyRecipient</ObjectProperty1>
			|					<ObjectPropertiesTable>
			|						<Property>
			|							<Description>CompanyRecipient</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</ObjectPropertiesTable>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>ManagementCompany</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|				<FilterElement>
			|					<IsConstantString>TRUE</IsConstantString>
			|					<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|					<ExchangePlanProperty>UnloadManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>Equal</ComparisonType>
			|					<ObjectProperty1>TRUE</ObjectProperty1>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>UnloadManagementCompany</Description>
			|							<TYPE>BOOLEAN</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|			</Group>
			|		</Group>
			|	</Group>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeOfUPRMC</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>";
EndFunction

#EndRegion
#Region Catalog_Partners
Procedure AddPRO_Catalog_Partners(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_Partners";
	
	NewRule.MetadataObjectName3 = "Catalog.Partners";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "CatalogsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = True;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		Catalog_Partners_FilterByExchangePlanProperties(),
		FilterByObjectProperties_10());
EndProcedure

Function Catalog_Partners_FilterByExchangePlanProperties()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>true</IsConstantString>
			|		<ObjectPropertyType>String</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>CashExchange</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<Type>String</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>";
EndFunction

Procedure ORR_Catalog_Partners_BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0)
	Cancel = True;
	
	   // If the Partner has not yet been registered in the IB, cancel the algorithm.
	   If Not ValueIsFilled(Object.Ref) Then
	       Return;
	   EndIf;
	
		If Not Upload0 Then
			If Object.Vendor Then
				Query = New Query(
				"SELECT
				|	Counterparties.Ref AS Ref
				|FROM
				|	Catalog.Counterparties AS Counterparties
				|WHERE
				|	Counterparties.Partner = &Partner
				|	AND NOT Counterparties.DeletionMark");
				Query.SetParameter("Partner", Object.Ref);
				Selection = Query.Execute().Select();
				While Selection.Next() Do
					If Common.RefExists(Selection.Ref) Then
						ExecuteRegistrationRulesForObject(Selection.Ref.GetObject(), ORR.ExchangePlanName, Object.DataExchange.Sender);
					EndIf;
				EndDo;
			EndIf;
		EndIf;
EndProcedure
#EndRegion
#Region Catalog_AcquiringContracts
Procedure AddPRO_Catalog_AcquiringContracts(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_AcquiringContracts";
	
	NewRule.MetadataObjectName3 = "Catalog.AcquiringContracts";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "CatalogsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_6(),
		FilterByObjectProperties_10());
EndProcedure

#EndRegion
#Region Catalog_Counterparties2
Procedure AddPRO_Catalog_Counterparties2(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_Counterparties2";
	
	NewRule.MetadataObjectName3 = "Catalog.Counterparties";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "ExportModeOnDemand";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = True;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_10(),
		FilterByObjectProperties_10());
EndProcedure

Procedure ORR_Catalog_Counterparties2_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0)
	If Recipients.Count() > 0 Then
			// For the exchange, we will delete the registration of NON-Suppliers
			ThisIsSupplier = Undefined;
			MaxIndex_ = Recipients.UBound();
			For IndexOf = 0 To MaxIndex_ Do
				CurIndx = MaxIndex_ - IndexOf;
				CurRecipient = Recipients[CurIndx];
				If CurRecipient.SettingsMode = "CashExchange" Then
					If ThisIsSupplier = Undefined Then
						ThisIsSupplier = Common.ObjectAttributeValue(Object.Partner, "Vendor");
					EndIf;
					If Not ThisIsSupplier = Undefined And Not ThisIsSupplier Then
						Recipients.Delete(CurIndx);
					EndIf;
				EndIf;
			EndDo;
		EndIf;
EndProcedure
#EndRegion
#Region Catalog_ProductKitConfigurations
Procedure AddPRO_Catalog_ProductConfigurationOptions(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_ProductKitConfigurations";
	
	NewRule.MetadataObjectName3 = "Catalog.ProductKitConfigurations";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "ExportModeOnDemand";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		EmptySelectionByExchangePlanProperties(),
		EmptySelectionByObjectProperties());
EndProcedure

#EndRegion
#Region Catalog_ItemKinds
Procedure AddPRO_Catalog_TypesOfProducts(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_ItemKinds";
	
	NewRule.MetadataObjectName3 = "Catalog.ItemKinds";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "CatalogsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_8(),
		Catalog_ItemKinds_FilterByObjectProperties());
EndProcedure

Function Catalog_ItemKinds_FilterByObjectProperties()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>DeletionMark</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>false</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>DeletionMark</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>EnumRef.ItemsTypes</ObjectPropertyType>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ItemsType</ObjectProperty1>
			|		<Kind>ValueAlgorithm</Kind>
			|		<ConstantValue>Value = Enums.ItemsTypes.Set;</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>ItemsType</Description>
			|				<Type>EnumRef.ItemsTypes</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>IsFolder</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>false</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>IsFolder</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|</FilterByObjectProperties>";
EndFunction

#EndRegion
#Region Catalog_Brands
Procedure AddPRO_Catalog_Brands(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_Brands";
	
	NewRule.MetadataObjectName3 = "Catalog.Brands";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "CatalogsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_19(),
		FilterByObjectProperties_6());
EndProcedure

#EndRegion
#Region Catalog_Products
Procedure AddPRO_Catalog_Products(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_Products";
	
	NewRule.MetadataObjectName3 = "Catalog.Products";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "CatalogsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		Catalog_Products_FilterByExchangePlanProperties(),
		FilterByObjectProperties_8());
EndProcedure

Function Catalog_Products_FilterByExchangePlanProperties()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>true</IsConstantString>
			|		<ObjectPropertyType>String</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeUP2ZUP3</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<Type>String</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>true</IsConstantString>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ExchangePlanProperty>ExportItemsWithInventoryOnly</ExchangePlanProperty>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>false</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>ExportItemsWithInventoryOnly</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>true</IsConstantString>
			|		<ObjectPropertyType>String</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeOfUPRMC</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<Type>String</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>";
EndFunction

#EndRegion
#Region Catalog_ProductCrossReferences
Procedure AddPRO_Catalog_CounterpartyProducts(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_ProductCrossReferences";
	
	NewRule.MetadataObjectName3 = "Catalog.ProductCrossReferences";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "CatalogsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_8(),
		FilterByObjectProperties_6());
EndProcedure

#EndRegion
#Region Catalog_CCDNumbers
Procedure AddPRO_Catalog_CCDNumbers(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_CCDNumbers";
	
	NewRule.MetadataObjectName3 = "Catalog.CCDNumbers";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "CatalogsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_21(),
		FilterByObjectProperties_10());
EndProcedure

#EndRegion
#Region Catalog_ProductsAttachedFiles
Procedure AddPRO_Catalog_ProductsAttachedFiles(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_ProductsAttachedFiles";
	
	NewRule.MetadataObjectName3 = "Catalog.ProductsAttachedFiles";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "CatalogsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_8(),
		Catalog_ProductsAttachedFiles_FilterByObjectProperties());
EndProcedure

Function Catalog_ProductsAttachedFiles_FilterByObjectProperties()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>DeletionMark</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>false</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>DeletionMark</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>EnumRef.ItemsTypes</ObjectPropertyType>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>FileOwner.ItemsType</ObjectProperty1>
			|		<Kind>ValueAlgorithm</Kind>
			|		<ConstantValue>Value = Enums.ItemsTypes.Set;</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>FileOwner</Description>
			|				<Type>CatalogRef.Products</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|			<Property>
			|				<Description>ItemsType</Description>
			|				<Type>EnumRef.ItemsTypes</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>FileOwner.DeletionMark</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>false</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>FileOwner</Description>
			|				<Type>CatalogRef.Products</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|			<Property>
			|				<Description>DeletionMark</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|</FilterByObjectProperties>";
EndFunction

#EndRegion
#Region Catalog_ItemsBatches
Procedure AddPRO_Catalog_SeriesProducts(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_ItemsBatches";
	
	NewRule.MetadataObjectName3 = "Catalog.ItemsBatches";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "CatalogsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_1(),
		FilterByObjectProperties_10());
EndProcedure

#EndRegion
#Region Catalog_ItemsCharacteristics
Procedure AddPRO_Catalog_ProductCharacteristics(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_ItemsCharacteristics";
	
	NewRule.MetadataObjectName3 = "Catalog.ItemsCharacteristics";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "CatalogsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_1(),
		Catalog_ItemsCharacteristics_FilterByObjectProperties());
EndProcedure

Function Catalog_ItemsCharacteristics_FilterByObjectProperties()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>DeletionMark</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>false</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>DeletionMark</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>EnumRef.ItemsTypes</ObjectPropertyType>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>Owner.ItemsType</ObjectProperty1>
			|		<Kind>ValueAlgorithm</Kind>
			|		<ConstantValue>Value = Enums.ItemsTypes.Set;</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Owner</Description>
			|				<Type>CatalogRef.ItemKinds</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|			<Property>
			|				<Description>ItemsType</Description>
			|				<Type>EnumRef.ItemsTypes</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>EnumRef.ItemVariantsUsageOptions</ObjectPropertyType>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>Owner.UseVariants</ObjectProperty1>
			|		<Kind>ValueAlgorithm</Kind>
			|		<ConstantValue>Value = Enums.ItemVariantsUsageOptions.DontUse;</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Owner</Description>
			|				<Type>CatalogRef.ItemKinds</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|			<Property>
			|				<Description>UseVariants</Description>
			|				<Type>EnumRef.ItemVariantsUsageOptions</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|</FilterByObjectProperties>";
EndFunction

#EndRegion
#Region Catalog_PriceGroups
Procedure AddPRO_Catalog_PriceGroups(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_PriceGroups";
	
	NewRule.MetadataObjectName3 = "Catalog.PriceGroups";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "ExportModeOnDemand";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_8(),
		Catalog_PriceGroups_FilterByObjectProperties());
EndProcedure

Function Catalog_PriceGroups_FilterByObjectProperties()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>DeletionMark</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>false</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>DeletionMark</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>IsFolder</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>false</ConstantValue>
			|	</FilterElement>
			|</FilterByObjectProperties>";
EndFunction

#EndRegion
#Region Catalog_ItemKinds2
Procedure AddPRO_Catalog_TypesOfProducts2(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_ItemKinds2";
	
	NewRule.MetadataObjectName3 = "Catalog.ItemKinds";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "CatalogsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_10(),
		FilterByObjectProperties_6());
EndProcedure

#EndRegion
#Region Catalog_ItemsBatches2
Procedure AddPRO_Catalog_SeriesProducts2(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_ItemsBatches2";
	
	NewRule.MetadataObjectName3 = "Catalog.ItemsBatches";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "ExportModeOnDemand";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_14(),
		FilterByObjectProperties_10());
EndProcedure

#EndRegion
#Region Catalog_ItemsCharacteristics2
Procedure AddPRO_Catalog_ProductCharacteristics2(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_ItemsCharacteristics2";
	
	NewRule.MetadataObjectName3 = "Catalog.ItemsCharacteristics";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "ExportModeOnDemand";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_14(),
		Catalog_ItemsCharacteristics2_FilterByObjectProperties());
EndProcedure

Function Catalog_ItemsCharacteristics2_FilterByObjectProperties()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>DeletionMark</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>false</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>DeletionMark</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>CatalogRef.ItemKinds,CatalogRef.Products</ObjectPropertyType>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>Owner.ItemsType</ObjectProperty1>
			|		<Kind>ValueAlgorithm</Kind>
			|		<ConstantValue>Value = Enums.ItemsTypes.Set;</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Owner</Description>
			|				<Type>CatalogRef.ItemKinds</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|			<Property>
			|				<Description>ItemsType</Description>
			|				<Type>EnumRef.ItemsTypes</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>CatalogRef.ItemKinds,CatalogRef.Products</ObjectPropertyType>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>Owner.UseVariants</ObjectProperty1>
			|		<Kind>ValueAlgorithm</Kind>
			|		<ConstantValue>Value = Enums.ItemVariantsUsageOptions.DontUse;</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Owner</Description>
			|				<Type>CatalogRef.ItemKinds</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|			<Property>
			|				<Description>UseVariants</Description>
			|				<Type>EnumRef.ItemVariantsUsageOptions</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|</FilterByObjectProperties>";
EndFunction

#EndRegion
#Region Catalog_Products2
Procedure AddPRO_Catalog_Products2(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_Products2";
	
	NewRule.MetadataObjectName3 = "Catalog.Products";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "ExportModeOnDemand";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		Catalog_Products2_FilterByExchangePlanProperties(),
		FilterByObjectProperties_8());
EndProcedure

Function Catalog_Products2_FilterByExchangePlanProperties()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>true</IsConstantString>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ExchangePlanProperty>ExportItemsWithInventoryOnly</ExchangePlanProperty>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>true</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>ExportItemsWithInventoryOnly</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>true</IsConstantString>
			|		<ObjectPropertyType>String</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>ExchangeOfUPRMC</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<Type>String</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>";
EndFunction

#EndRegion
#Region Catalog_LoyaltyPrograms
Procedure AddPRO_Catalog_BonusLoyaltyPrograms(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_LoyaltyPrograms";
	
	NewRule.MetadataObjectName3 = "Catalog.LoyaltyPrograms";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "CatalogsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_21(),
		FilterByObjectProperties_10());
EndProcedure

#EndRegion
#Region Catalog_GiftCertificateKinds
Procedure AddPRO_Catalog_TypesOfGiftCertificates(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_GiftCertificateKinds";
	
	NewRule.MetadataObjectName3 = "Catalog.GiftCertificateKinds";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "CatalogsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_21(),
		FilterByObjectProperties_10());
EndProcedure

#EndRegion
#Region Catalog_EmployeeWorkKinds
Procedure AddPRO_Catalog_EmployeeTypesOfWork(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_EmployeeWorkKinds";
	
	NewRule.MetadataObjectName3 = "Catalog.EmployeeWorkKinds";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "CatalogsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		Catalog_EmployeeWorkKinds_FilterByExchangePlanProperties(),
		FilterByObjectProperties_2());
EndProcedure

Function Catalog_EmployeeWorkKinds_FilterByExchangePlanProperties()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>true</IsConstantString>
			|		<ObjectPropertyType>String</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>ExchangeUP2ZUP3</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<Type>String</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>";
EndFunction

#EndRegion
#Region Catalog_TypesOfPrices
Procedure AddPRO_Catalog_TypesOfPrices(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_TypesOfPrices";
	
	NewRule.MetadataObjectName3 = "Catalog.TypesOfPrices";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "ExportModeOnDemand";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		EmptySelectionByExchangePlanProperties(),
		EmptySelectionByObjectProperties());
EndProcedure

#EndRegion

#Region Catalog_LoyaltyCards
Procedure AddPRO_Catalog_LoyaltyCards(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_LoyaltyCards";
	
	NewRule.MetadataObjectName3 = "Catalog.LoyaltyCards";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "CatalogsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_21(),
		Catalog_LoyaltyCards_FilterByObjectProperties());
EndProcedure

Function Catalog_LoyaltyCards_FilterByObjectProperties()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>DeletionMark</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>false</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>DeletionMark</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>Owner.Personalized</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>true</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Owner</Description>
			|				<Type>CatalogRef.LoyaltyCardKinds</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|			<Property>
			|				<Description>Personalized</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|</FilterByObjectProperties>";
EndFunction

#EndRegion
#Region Catalog_Users
Procedure AddPRO_Catalog_Users(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_Users";
	
	NewRule.MetadataObjectName3 = "Catalog.Users";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "ExportModeOnDemand";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_19(),
		EmptySelectionByObjectProperties());
EndProcedure

#EndRegion

#Region Catalog_Persons
Procedure AddPRO_Catalog_Individuals(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_Persons";
	
	NewRule.MetadataObjectName3 = "Catalog.Persons";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "CatalogsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		Catalog_Persons_FilterByExchangePlanProperties(),
		FilterByObjectProperties_10());
EndProcedure

Function Catalog_Persons_FilterByExchangePlanProperties()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>CashExchange</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>TRUE</IsConstantString>
			|			<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|			<ExchangePlanProperty>UseFilterByPersons</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>FALSE</ObjectProperty1>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>UseFilterByPersons</Description>
			|					<TYPE>BOOLEAN</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<Group>
			|			<BooleanGroupValue>AND</BooleanGroupValue>
			|			<FilterElement>
			|				<IsConstantString>TRUE</IsConstantString>
			|				<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|				<ExchangePlanProperty>UseFilterByPersons</ExchangePlanProperty>
			|				<ComparisonType>Equal</ComparisonType>
			|				<ObjectProperty1>TRUE</ObjectProperty1>
			|				<TableOfExchangePlanProperties>
			|					<Property>
			|						<Description>UseFilterByPersons</Description>
			|						<TYPE>BOOLEAN</TYPE>
			|						<Kind>Attribute</Kind>
			|					</Property>
			|				</TableOfExchangePlanProperties>
			|			</FilterElement>
			|			<FilterElement>
			|				<IsConstantString>FALSE</IsConstantString>
			|				<ObjectPropertyType>CatalogRef.Persons</ObjectPropertyType>
			|				<ExchangePlanProperty>Persons.Individual</ExchangePlanProperty>
			|				<ComparisonType>Equal</ComparisonType>
			|				<ObjectProperty1>Ref</ObjectProperty1>
			|				<ObjectPropertiesTable>
			|					<Property>
			|						<Description>Ref</Description>
			|						<TYPE>CatalogRef.Persons</TYPE>
			|						<Kind>Property</Kind>
			|					</Property>
			|				</ObjectPropertiesTable>
			|				<TableOfExchangePlanProperties>
			|					<Property>
			|						<Description>[Persons]</Description>
			|						<Kind>TabularSection</Kind>
			|					</Property>
			|					<Property>
			|						<Description>Individual</Description>
			|						<TYPE>CatalogRef.Persons</TYPE>
			|						<Kind>Attribute</Kind>
			|					</Property>
			|				</TableOfExchangePlanProperties>
			|			</FilterElement>
			|		</Group>
			|	</Group>
			|</FilterByExchangePlanProperties>";
EndFunction

#EndRegion
#Region Catalog_POSTerminals
Procedure AddPRO_Catalog_AcquiringTerminals(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_POSTerminals";
	
	NewRule.MetadataObjectName3 = "Catalog.POSTerminals";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "CatalogsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		Catalog_POSTerminals_FilterByExchangePlanProperties(),
		FilterByObjectProperties_6());
EndProcedure

Function Catalog_POSTerminals_FilterByExchangePlanProperties()
	Return "<FilterByExchangePlanProperties>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|			<ExchangePlanProperty>[Companies].Organization</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Owner.Organization</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Owner</Description>
			|					<TYPE>CatalogRef.AcquiringContracts</TYPE>
			|					<Kind>Property</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Companies]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<Group>
			|			<BooleanGroupValue>AND</BooleanGroupValue>
			|			<FilterElement>
			|				<IsConstantString>TRUE</IsConstantString>
			|				<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|				<ExchangePlanProperty>UseFilterByCompanies</ExchangePlanProperty>
			|				<ComparisonType>Equal</ComparisonType>
			|				<ObjectProperty1>FALSE</ObjectProperty1>
			|				<TableOfExchangePlanProperties>
			|					<Property>
			|						<Description>UseFilterByCompanies</Description>
			|						<TYPE>BOOLEAN</TYPE>
			|						<Kind>Attribute</Kind>
			|					</Property>
			|				</TableOfExchangePlanProperties>
			|			</FilterElement>
			|			<Group>
			|				<BooleanGroupValue>OR</BooleanGroupValue>
			|				<FilterElement>
			|					<IsConstantString>TRUE</IsConstantString>
			|					<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|					<ExchangePlanProperty>UnloadManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>Equal</ComparisonType>
			|					<ObjectProperty1>TRUE</ObjectProperty1>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>UnloadManagementCompany</Description>
			|							<TYPE>BOOLEAN</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|				<FilterElement>
			|					<IsConstantString>FALSE</IsConstantString>
			|					<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|					<ExchangePlanProperty>ManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>NotEqual</ComparisonType>
			|					<ObjectProperty1>Owner.Organization</ObjectProperty1>
			|					<ObjectPropertiesTable>
			|						<Property>
			|							<Description>Owner</Description>
			|							<TYPE>CatalogRef.AcquiringContracts</TYPE>
			|							<Kind>Property</Kind>
			|						</Property>
			|						<Property>
			|							<Description>Organization</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</ObjectPropertiesTable>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>ManagementCompany</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|			</Group>
			|		</Group>
			|	</Group>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeUP2ZUP3</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>CashExchange</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>TRUE</IsConstantString>
			|			<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|			<ExchangePlanProperty>UseFilterByPOSTerminals</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>FALSE</ObjectProperty1>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>UseFilterByPOSTerminals</Description>
			|					<TYPE>BOOLEAN</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<Group>
			|			<BooleanGroupValue>AND</BooleanGroupValue>
			|			<FilterElement>
			|				<IsConstantString>TRUE</IsConstantString>
			|				<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|				<ExchangePlanProperty>UseFilterByPOSTerminals</ExchangePlanProperty>
			|				<ComparisonType>Equal</ComparisonType>
			|				<ObjectProperty1>TRUE</ObjectProperty1>
			|				<TableOfExchangePlanProperties>
			|					<Property>
			|						<Description>UseFilterByPOSTerminals</Description>
			|						<TYPE>BOOLEAN</TYPE>
			|						<Kind>Attribute</Kind>
			|					</Property>
			|				</TableOfExchangePlanProperties>
			|			</FilterElement>
			|			<FilterElement>
			|				<IsConstantString>FALSE</IsConstantString>
			|				<ObjectPropertyType>CatalogRef.POSTerminals</ObjectPropertyType>
			|				<ExchangePlanProperty>POSTerminals.POSTerminal</ExchangePlanProperty>
			|				<ComparisonType>Equal</ComparisonType>
			|				<ObjectProperty1>Ref</ObjectProperty1>
			|				<ObjectPropertiesTable>
			|					<Property>
			|						<Description>Ref</Description>
			|						<TYPE>CatalogRef.POSTerminals</TYPE>
			|						<Kind>Property</Kind>
			|					</Property>
			|				</ObjectPropertiesTable>
			|				<TableOfExchangePlanProperties>
			|					<Property>
			|						<Description>[POSTerminals]</Description>
			|						<Kind>TabularSection</Kind>
			|					</Property>
			|					<Property>
			|						<Description>POSTerminal</Description>
			|						<TYPE>CatalogRef.POSTerminals</TYPE>
			|						<Kind>Attribute</Kind>
			|					</Property>
			|				</TableOfExchangePlanProperties>
			|			</FilterElement>
			|		</Group>
			|	</Group>
			|</FilterByExchangePlanProperties>";
EndFunction

Procedure ORR_Catalog_POSTerminals_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	QueryOptions.Insert("Organization", Common.ObjectAttributeValue(Object.Owner, "Organization"));
EndProcedure

Procedure ORR_Catalog_POSTerminals_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	QueryOptions.Insert("Organization", Common.ObjectAttributeValue(Object.Owner, "Organization"));
EndProcedure
#EndRegion
#Region Catalog_Reserves
Procedure AddPRO_Catalog_Reserves(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_Reserves";
	
	NewRule.MetadataObjectName3 = "Catalog.Reserves";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "ExportModeOnDemand";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		EmptySelectionByExchangePlanProperties(),
		FilterByObjectProperties_2());
EndProcedure

#EndRegion
#Region Catalog_Warehouses
Procedure AddPRO_Catalog_Warehouses(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_Warehouses";
	
	NewRule.MetadataObjectName3 = "Catalog.Warehouses";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "CatalogsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		Catalog_Warehouses_FilterByExchangePlanProperties(),
		FilterByObjectProperties_6());
EndProcedure

Function Catalog_Warehouses_FilterByExchangePlanProperties()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|		<ExchangePlanProperty>UploadAnalyticsByWarehouse</ExchangePlanProperty>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>TRUE</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>UploadAnalyticsByWarehouse</Description>
			|				<TYPE>BOOLEAN</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeUP2ZUP3</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>TRUE</IsConstantString>
			|			<ObjectPropertyType>STRING</ObjectPropertyType>
			|			<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|			<ComparisonType>NotEqual</ComparisonType>
			|			<ObjectProperty1>ExchangeOfUPRMC</ObjectProperty1>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>SettingsMode</Description>
			|					<TYPE>STRING</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<Group>
			|			<BooleanGroupValue>AND</BooleanGroupValue>
			|			<FilterElement>
			|				<IsConstantString>TRUE</IsConstantString>
			|				<ObjectPropertyType>STRING</ObjectPropertyType>
			|				<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|				<ComparisonType>Equal</ComparisonType>
			|				<ObjectProperty1>ExchangeOfUPRMC</ObjectProperty1>
			|				<TableOfExchangePlanProperties>
			|					<Property>
			|						<Description>SettingsMode</Description>
			|						<TYPE>STRING</TYPE>
			|						<Kind>Attribute</Kind>
			|					</Property>
			|				</TableOfExchangePlanProperties>
			|			</FilterElement>
			|			<Group>
			|				<BooleanGroupValue>OR</BooleanGroupValue>
			|				<FilterElement>
			|					<IsConstantString>TRUE</IsConstantString>
			|					<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|					<ExchangePlanProperty>UseFilterByWarehouses</ExchangePlanProperty>
			|					<ComparisonType>Equal</ComparisonType>
			|					<ObjectProperty1>FALSE</ObjectProperty1>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>UseFilterByWarehouses</Description>
			|							<TYPE>BOOLEAN</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|				<Group>
			|					<BooleanGroupValue>AND</BooleanGroupValue>
			|					<FilterElement>
			|						<IsConstantString>TRUE</IsConstantString>
			|						<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|						<ExchangePlanProperty>UseFilterByWarehouses</ExchangePlanProperty>
			|						<ComparisonType>Equal</ComparisonType>
			|						<ObjectProperty1>TRUE</ObjectProperty1>
			|						<TableOfExchangePlanProperties>
			|							<Property>
			|								<Description>UseFilterByWarehouses</Description>
			|								<TYPE>BOOLEAN</TYPE>
			|								<Kind>Attribute</Kind>
			|							</Property>
			|						</TableOfExchangePlanProperties>
			|					</FilterElement>
			|					<FilterElement>
			|						<IsConstantString>FALSE</IsConstantString>
			|						<ObjectPropertyType>CatalogRef.Warehouses</ObjectPropertyType>
			|						<ExchangePlanProperty>Warehouses.Warehouse</ExchangePlanProperty>
			|						<ComparisonType>Equal</ComparisonType>
			|						<ObjectProperty1>Ref</ObjectProperty1>
			|						<ObjectPropertiesTable>
			|							<Property>
			|								<Description>Ref</Description>
			|								<TYPE>CatalogRef.Warehouses</TYPE>
			|								<Kind>Property</Kind>
			|							</Property>
			|						</ObjectPropertiesTable>
			|						<TableOfExchangePlanProperties>
			|							<Property>
			|								<Description>[Warehouses]</Description>
			|								<Kind>TabularSection</Kind>
			|							</Property>
			|							<Property>
			|								<Description>Warehouse</Description>
			|								<TYPE>CatalogRef.Warehouses</TYPE>
			|								<Kind>Attribute</Kind>
			|							</Property>
			|						</TableOfExchangePlanProperties>
			|					</FilterElement>
			|				</Group>
			|			</Group>
			|		</Group>
			|	</Group>
			|</FilterByExchangePlanProperties>";
EndFunction

#EndRegion
#Region Catalog_Warehouses2
Procedure AddPRO_Catalog_Warehouses2(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_Warehouses2";
	
	NewRule.MetadataObjectName3 = "Catalog.Warehouses";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "ExportModeOnDemand";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		EmptySelectionByExchangePlanProperties(),
		Catalog_Warehouses2_FilterByObjectProperties());
EndProcedure

Function Catalog_Warehouses2_FilterByObjectProperties()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>IsFolder</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>true</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>IsFolder</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|</FilterByObjectProperties>";
EndFunction

#EndRegion
#Region Catalog_CompaniesBankAccounts
Procedure AddPRO_Catalog_BankAccountsOfOrganizations(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_CompaniesBankAccounts";
	
	NewRule.MetadataObjectName3 = "Catalog.CompaniesBankAccounts";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "CatalogsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		Catalog_CompaniesBankAccounts_FilterByExchangePlanProperties(),
		FilterByObjectProperties_10());
EndProcedure

Function Catalog_CompaniesBankAccounts_FilterByExchangePlanProperties()
	Return "<FilterByExchangePlanProperties>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|			<ExchangePlanProperty>[Companies].Organization</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Owner</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Owner</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Property</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Companies]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<Group>
			|			<BooleanGroupValue>AND</BooleanGroupValue>
			|			<FilterElement>
			|				<IsConstantString>TRUE</IsConstantString>
			|				<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|				<ExchangePlanProperty>UseFilterByCompanies</ExchangePlanProperty>
			|				<ComparisonType>Equal</ComparisonType>
			|				<ObjectProperty1>FALSE</ObjectProperty1>
			|				<TableOfExchangePlanProperties>
			|					<Property>
			|						<Description>UseFilterByCompanies</Description>
			|						<TYPE>BOOLEAN</TYPE>
			|						<Kind>Attribute</Kind>
			|					</Property>
			|				</TableOfExchangePlanProperties>
			|			</FilterElement>
			|			<Group>
			|				<BooleanGroupValue>OR</BooleanGroupValue>
			|				<FilterElement>
			|					<IsConstantString>FALSE</IsConstantString>
			|					<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|					<ExchangePlanProperty>ManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>NotEqual</ComparisonType>
			|					<ObjectProperty1>Owner</ObjectProperty1>
			|					<ObjectPropertiesTable>
			|						<Property>
			|							<Description>Owner</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Property</Kind>
			|						</Property>
			|					</ObjectPropertiesTable>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>ManagementCompany</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|				<FilterElement>
			|					<IsConstantString>TRUE</IsConstantString>
			|					<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|					<ExchangePlanProperty>UnloadManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>Equal</ComparisonType>
			|					<ObjectProperty1>TRUE</ObjectProperty1>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>UnloadManagementCompany</Description>
			|							<TYPE>BOOLEAN</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|			</Group>
			|		</Group>
			|	</Group>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeUP2ZUP3</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>CashExchange</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeOfUPRMC</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>";
EndFunction

Procedure ORR_Catalog_CompaniesBankAccounts_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	QueryOptions.Insert("Organization", Object.Owner);
EndProcedure

Procedure ORR_Catalog_CompaniesBankAccounts_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	QueryOptions.Insert("Organization", Object.Owner);
EndProcedure
#EndRegion
#Region Catalog_CashAccounts
Procedure AddPRO_Catalog_CashAccounts(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_CashAccounts";
	
	NewRule.MetadataObjectName3 = "Catalog.CashAccounts";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "CatalogsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		Catalog_CashAccounts_FilterByExchangePlanProperties(),
		FilterByObjectProperties_10());
EndProcedure

Function Catalog_CashAccounts_FilterByExchangePlanProperties()
	Return "<FilterByExchangePlanProperties>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|			<ExchangePlanProperty>[Companies].Organization</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Owner</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Owner</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Property</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Companies]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<Group>
			|			<BooleanGroupValue>AND</BooleanGroupValue>
			|			<FilterElement>
			|				<IsConstantString>TRUE</IsConstantString>
			|				<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|				<ExchangePlanProperty>UseFilterByCompanies</ExchangePlanProperty>
			|				<ComparisonType>Equal</ComparisonType>
			|				<ObjectProperty1>FALSE</ObjectProperty1>
			|				<TableOfExchangePlanProperties>
			|					<Property>
			|						<Description>UseFilterByCompanies</Description>
			|						<TYPE>BOOLEAN</TYPE>
			|						<Kind>Attribute</Kind>
			|					</Property>
			|				</TableOfExchangePlanProperties>
			|			</FilterElement>
			|			<Group>
			|				<BooleanGroupValue>OR</BooleanGroupValue>
			|				<FilterElement>
			|					<IsConstantString>TRUE</IsConstantString>
			|					<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|					<ExchangePlanProperty>UnloadManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>Equal</ComparisonType>
			|					<ObjectProperty1>TRUE</ObjectProperty1>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>UnloadManagementCompany</Description>
			|							<TYPE>BOOLEAN</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|				<FilterElement>
			|					<IsConstantString>FALSE</IsConstantString>
			|					<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|					<ExchangePlanProperty>ManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>NotEqual</ComparisonType>
			|					<ObjectProperty1>Owner</ObjectProperty1>
			|					<ObjectPropertiesTable>
			|						<Property>
			|							<Description>Owner</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Property</Kind>
			|						</Property>
			|					</ObjectPropertiesTable>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>ManagementCompany</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|			</Group>
			|		</Group>
			|	</Group>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeUP2ZUP3</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeOfUPRMC</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>";
EndFunction

Procedure ORR_Catalog_CashAccounts_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	QueryOptions.Insert("Organization", Object.Owner);
EndProcedure

Procedure ORR_Catalog_CashAccounts_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	QueryOptions.Insert("Organization", Object.Owner);
EndProcedure
#EndRegion
#Region Catalog_CashRegisters
Procedure AddPRO_Catalog_CashRegister(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_CashRegisters";
	
	NewRule.MetadataObjectName3 = "Catalog.CashRegisters";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "CatalogsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = True;
	NewRule.HasOnProcessHandlerAdditional = True;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		Catalog_CashRegisters_FilterByExchangePlanProperties(),
		FilterByObjectProperties_10());
EndProcedure

Function Catalog_CashRegisters_FilterByExchangePlanProperties()
	Return "<FilterByExchangePlanProperties>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|			<ExchangePlanProperty>[Companies].Organization</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Owner</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Owner</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Property</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Companies]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<Group>
			|			<BooleanGroupValue>AND</BooleanGroupValue>
			|			<FilterElement>
			|				<IsConstantString>TRUE</IsConstantString>
			|				<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|				<ExchangePlanProperty>UseFilterByCompanies</ExchangePlanProperty>
			|				<ComparisonType>Equal</ComparisonType>
			|				<ObjectProperty1>FALSE</ObjectProperty1>
			|				<TableOfExchangePlanProperties>
			|					<Property>
			|						<Description>UseFilterByCompanies</Description>
			|						<TYPE>BOOLEAN</TYPE>
			|						<Kind>Attribute</Kind>
			|					</Property>
			|				</TableOfExchangePlanProperties>
			|			</FilterElement>
			|			<Group>
			|				<BooleanGroupValue>OR</BooleanGroupValue>
			|				<FilterElement>
			|					<IsConstantString>TRUE</IsConstantString>
			|					<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|					<ExchangePlanProperty>UnloadManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>Equal</ComparisonType>
			|					<ObjectProperty1>TRUE</ObjectProperty1>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>UnloadManagementCompany</Description>
			|							<TYPE>BOOLEAN</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|				<FilterElement>
			|					<IsConstantString>FALSE</IsConstantString>
			|					<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|					<ExchangePlanProperty>ManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>NotEqual</ComparisonType>
			|					<ObjectProperty1>Owner</ObjectProperty1>
			|					<ObjectPropertiesTable>
			|						<Property>
			|							<Description>Owner</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Property</Kind>
			|						</Property>
			|					</ObjectPropertiesTable>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>ManagementCompany</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|			</Group>
			|		</Group>
			|	</Group>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeUP2ZUP3</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>TRUE</IsConstantString>
			|			<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|			<ExchangePlanProperty>UseFilterByCashRegisters</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>FALSE</ObjectProperty1>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>UseFilterByCashRegisters</Description>
			|					<TYPE>BOOLEAN</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<Group>
			|			<BooleanGroupValue>AND</BooleanGroupValue>
			|			<FilterElement>
			|				<IsConstantString>TRUE</IsConstantString>
			|				<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|				<ExchangePlanProperty>UseFilterByCashRegisters</ExchangePlanProperty>
			|				<ComparisonType>Equal</ComparisonType>
			|				<ObjectProperty1>TRUE</ObjectProperty1>
			|				<TableOfExchangePlanProperties>
			|					<Property>
			|						<Description>UseFilterByCashRegisters</Description>
			|						<TYPE>BOOLEAN</TYPE>
			|						<Kind>Attribute</Kind>
			|					</Property>
			|				</TableOfExchangePlanProperties>
			|			</FilterElement>
			|			<FilterElement>
			|				<IsConstantString>FALSE</IsConstantString>
			|				<ObjectPropertyType>CatalogRef.CashRegisters</ObjectPropertyType>
			|				<ExchangePlanProperty>CashRegisters.CashRegister</ExchangePlanProperty>
			|				<ComparisonType>Equal</ComparisonType>
			|				<ObjectProperty1>Ref</ObjectProperty1>
			|				<ObjectPropertiesTable>
			|					<Property>
			|						<Description>Ref</Description>
			|						<TYPE>CatalogRef.CashRegisters</TYPE>
			|						<Kind>Property</Kind>
			|					</Property>
			|				</ObjectPropertiesTable>
			|				<TableOfExchangePlanProperties>
			|					<Property>
			|						<Description>[CashRegisters]</Description>
			|						<Kind>TabularSection</Kind>
			|					</Property>
			|					<Property>
			|						<Description>CashRegister</Description>
			|						<TYPE>CatalogRef.CashRegisters</TYPE>
			|						<Kind>Attribute</Kind>
			|					</Property>
			|				</TableOfExchangePlanProperties>
			|			</FilterElement>
			|		</Group>
			|	</Group>
			|</FilterByExchangePlanProperties>";
EndFunction

Procedure ORR_Catalog_CashRegisters_OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties)
	QueryOptions.Insert("Organization", Object.Owner);
EndProcedure

Procedure ORR_Catalog_CashRegisters_OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties)
	QueryOptions.Insert("Organization", Object.Owner);
EndProcedure
#EndRegion
#Region Catalog_PersonsResponsibleAndCompanies
Procedure AddPRO_Catalog_ResponsiblePersonsOfOrganizations(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_PersonsResponsibleAndCompanies";
	
	NewRule.MetadataObjectName3 = "Catalog.PersonsResponsibleAndCompanies";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "CatalogsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		Catalog_PersonsResponsibleAndCompanies_FilterByExchangePlanProperties(),
		FilterByObjectProperties_10());
EndProcedure

Function Catalog_PersonsResponsibleAndCompanies_FilterByExchangePlanProperties()
	Return "<FilterByExchangePlanProperties>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>DATE</ObjectPropertyType>
			|			<ExchangePlanProperty>DocumentsExportStartDate</ExchangePlanProperty>
			|			<ComparisonType>GreaterOrEqual</ComparisonType>
			|			<ObjectProperty1>StartDate</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>StartDate</Description>
			|					<TYPE>DATE</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>DocumentsExportStartDate</Description>
			|					<TYPE>DATE</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>DATE</ObjectPropertyType>
			|			<ExchangePlanProperty>DocumentsExportStartDate</ExchangePlanProperty>
			|			<ComparisonType>GreaterOrEqual</ComparisonType>
			|			<ObjectProperty1>EndDate</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>EndDate</Description>
			|					<TYPE>DATE</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>DocumentsExportStartDate</Description>
			|					<TYPE>DATE</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|	</Group>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|			<ExchangePlanProperty>[Companies].Organization</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Owner</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Owner</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Property</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Companies]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<Group>
			|			<BooleanGroupValue>AND</BooleanGroupValue>
			|			<FilterElement>
			|				<IsConstantString>TRUE</IsConstantString>
			|				<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|				<ExchangePlanProperty>UseFilterByCompanies</ExchangePlanProperty>
			|				<ComparisonType>Equal</ComparisonType>
			|				<ObjectProperty1>FALSE</ObjectProperty1>
			|				<TableOfExchangePlanProperties>
			|					<Property>
			|						<Description>UseFilterByCompanies</Description>
			|						<TYPE>BOOLEAN</TYPE>
			|						<Kind>Attribute</Kind>
			|					</Property>
			|				</TableOfExchangePlanProperties>
			|			</FilterElement>
			|			<Group>
			|				<BooleanGroupValue>OR</BooleanGroupValue>
			|				<FilterElement>
			|					<IsConstantString>FALSE</IsConstantString>
			|					<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|					<ExchangePlanProperty>ManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>NotEqual</ComparisonType>
			|					<ObjectProperty1>Owner</ObjectProperty1>
			|					<ObjectPropertiesTable>
			|						<Property>
			|							<Description>Owner</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Property</Kind>
			|						</Property>
			|					</ObjectPropertiesTable>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>ManagementCompany</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|				<FilterElement>
			|					<IsConstantString>TRUE</IsConstantString>
			|					<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|					<ExchangePlanProperty>UnloadManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>Equal</ComparisonType>
			|					<ObjectProperty1>TRUE</ObjectProperty1>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>UnloadManagementCompany</Description>
			|							<TYPE>BOOLEAN</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|			</Group>
			|		</Group>
			|	</Group>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeUP2ZUP3</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>CashExchange</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeOfUPRMC</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>";
EndFunction

#EndRegion
#Region Catalog_PersonsResponsibleAndCompanies2
Procedure AddPRO_Catalog_ResponsiblePersonsOfOrganizations2(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_PersonsResponsibleAndCompanies2";
	
	NewRule.MetadataObjectName3 = "Catalog.PersonsResponsibleAndCompanies";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "CatalogsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		Catalog_PersonsResponsibleAndCompanies2_FilterByExchangePlanProperties(),
		Catalog_PersonsResponsibleAndCompanies2_FilterByObjectProperties());
EndProcedure

Function Catalog_PersonsResponsibleAndCompanies2_FilterByExchangePlanProperties()
	Return "<FilterByExchangePlanProperties>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|			<ExchangePlanProperty>[Companies].Organization</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Owner</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Owner</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Property</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Companies]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<Group>
			|			<BooleanGroupValue>AND</BooleanGroupValue>
			|			<FilterElement>
			|				<IsConstantString>TRUE</IsConstantString>
			|				<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|				<ExchangePlanProperty>UseFilterByCompanies</ExchangePlanProperty>
			|				<ComparisonType>Equal</ComparisonType>
			|				<ObjectProperty1>FALSE</ObjectProperty1>
			|				<TableOfExchangePlanProperties>
			|					<Property>
			|						<Description>UseFilterByCompanies</Description>
			|						<TYPE>BOOLEAN</TYPE>
			|						<Kind>Attribute</Kind>
			|					</Property>
			|				</TableOfExchangePlanProperties>
			|			</FilterElement>
			|			<Group>
			|				<BooleanGroupValue>OR</BooleanGroupValue>
			|				<FilterElement>
			|					<IsConstantString>TRUE</IsConstantString>
			|					<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|					<ExchangePlanProperty>UnloadManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>Equal</ComparisonType>
			|					<ObjectProperty1>TRUE</ObjectProperty1>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>UnloadManagementCompany</Description>
			|							<TYPE>BOOLEAN</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|				<FilterElement>
			|					<IsConstantString>FALSE</IsConstantString>
			|					<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|					<ExchangePlanProperty>ManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>NotEqual</ComparisonType>
			|					<ObjectProperty1>Owner</ObjectProperty1>
			|					<ObjectPropertiesTable>
			|						<Property>
			|							<Description>Owner</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Property</Kind>
			|						</Property>
			|					</ObjectPropertiesTable>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>ManagementCompany</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|			</Group>
			|		</Group>
			|	</Group>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeUP2ZUP3</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>CashExchange</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeOfUPRMC</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>";
EndFunction

Function Catalog_PersonsResponsibleAndCompanies2_FilterByObjectProperties()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>DeletionMark</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>false</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>DeletionMark</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>Date</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>EndDate</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>0001-01-01T00:00:00</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>EndDate</Description>
			|				<Type>Date</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|</FilterByObjectProperties>";
EndFunction

#EndRegion

#Region Catalog_BusinessStructure
Procedure AddPRO_Catalog_CompanyStructure(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_BusinessStructure";
	
	NewRule.MetadataObjectName3 = "Catalog.BusinessStructure";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "CatalogsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		Catalog_BusinessStructure_FilterByExchangePlanProperties(),
		FilterByObjectProperties_10());
EndProcedure

Function Catalog_BusinessStructure_FilterByExchangePlanProperties()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>true</IsConstantString>
			|		<ObjectPropertyType>String</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>CashExchange</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<Type>String</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>true</IsConstantString>
			|		<ObjectPropertyType>String</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeOfUPRMC</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<Type>String</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>";
EndFunction

#EndRegion


#Region Catalog_Companies
Procedure AddPRO_Catalog_Organizations(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_Companies";
	
	NewRule.MetadataObjectName3 = "Catalog.Companies";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "CatalogsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = True;
		
	SetFilters(NewRule, 
		Catalog_Companies_FilterByExchangePlanProperties(),
		FilterByObjectProperties_10());
EndProcedure

Function Catalog_Companies_FilterByExchangePlanProperties()
	Return "<FilterByExchangePlanProperties>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|			<ExchangePlanProperty>[Companies].Organization</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Ref</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Ref</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Property</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Companies]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<Group>
			|			<BooleanGroupValue>AND</BooleanGroupValue>
			|			<FilterElement>
			|				<IsConstantString>TRUE</IsConstantString>
			|				<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|				<ExchangePlanProperty>UseFilterByCompanies</ExchangePlanProperty>
			|				<ComparisonType>Equal</ComparisonType>
			|				<ObjectProperty1>FALSE</ObjectProperty1>
			|				<TableOfExchangePlanProperties>
			|					<Property>
			|						<Description>UseFilterByCompanies</Description>
			|						<TYPE>BOOLEAN</TYPE>
			|						<Kind>Attribute</Kind>
			|					</Property>
			|				</TableOfExchangePlanProperties>
			|			</FilterElement>
			|			<Group>
			|				<BooleanGroupValue>OR</BooleanGroupValue>
			|				<FilterElement>
			|					<IsConstantString>FALSE</IsConstantString>
			|					<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|					<ExchangePlanProperty>ManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>NotEqual</ComparisonType>
			|					<ObjectProperty1>Ref</ObjectProperty1>
			|					<ObjectPropertiesTable>
			|						<Property>
			|							<Description>Ref</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Property</Kind>
			|						</Property>
			|					</ObjectPropertiesTable>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>ManagementCompany</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|				<FilterElement>
			|					<IsConstantString>TRUE</IsConstantString>
			|					<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|					<ExchangePlanProperty>UnloadManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>Equal</ComparisonType>
			|					<ObjectProperty1>TRUE</ObjectProperty1>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>UnloadManagementCompany</Description>
			|							<TYPE>BOOLEAN</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|			</Group>
			|		</Group>
			|	</Group>
			|</FilterByExchangePlanProperties>";
EndFunction

Procedure ORR_Catalog_Companies_AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0)
EndProcedure
#EndRegion
#Region Catalog_AnalyticalInventoryGroups
Procedure AddPRO_Catalog_AnalyticalAccountingGroupsForProducts(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_AnalyticalInventoryGroups";
	
	NewRule.MetadataObjectName3 = "Catalog.AnalyticalInventoryGroups";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "ExportModeOnDemand";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_19(),
		EmptySelectionByObjectProperties());
EndProcedure

#EndRegion
#Region Catalog_InventoryAccountingGroups
Procedure AddPRO_Catalog_FinancialAccountingGroupsProducts(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_InventoryAccountingGroups";
	
	NewRule.MetadataObjectName3 = "Catalog.InventoryAccountingGroups";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "ExportModeOnDemand";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_19(),
		EmptySelectionByObjectProperties());
EndProcedure

#EndRegion
#Region Catalog_FinancialAccountingGroupsOfARAP
Procedure AddPRO_Catalog_FinancialAccountingAndSettlementGroups(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_FinancialAccountingGroupsOfARAP";
	
	NewRule.MetadataObjectName3 = "Catalog.FinancialAccountingGroupsOfARAP";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "ExportModeOnDemand";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_19(),
		EmptySelectionByObjectProperties());
EndProcedure

#EndRegion

#Region Catalog_CashFlowReportItems
Procedure AddPRO_Catalog_CashFlowItems(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_CashFlowReportItems";
	
	NewRule.MetadataObjectName3 = "Catalog.CashFlowReportItems";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "CatalogsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_21(),
		FilterByObjectProperties_10());
EndProcedure

#EndRegion

#Region Catalog_ContactPersonsForPartners
Procedure AddPRO_Catalog_ContactPersonsForPartners(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_ContactPersonsForPartners";
	
	NewRule.MetadataObjectName3 = "Catalog.ContactPersonsForPartners";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "CatalogsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		Catalog_ContactPersonsForPartners_FilterByExchangePlanProperties(),
		Catalog_ContactPersonsForPartners_FilterByObjectProperties());
EndProcedure

Function Catalog_ContactPersonsForPartners_FilterByExchangePlanProperties()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>true</IsConstantString>
			|		<ObjectPropertyType>String</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeOfUPRMC</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<Type>String</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>true</IsConstantString>
			|		<ObjectPropertyType>String</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeUP2ZUP3</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<Type>String</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>true</IsConstantString>
			|		<ObjectPropertyType>String</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>CashExchange</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<Type>String</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>";
EndFunction

Function Catalog_ContactPersonsForPartners_FilterByObjectProperties()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>DeletionMark</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>false</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>DeletionMark</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>CatalogRef.Partners</ObjectPropertyType>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>Owner</ObjectProperty1>
			|		<Kind>ValueAlgorithm</Kind>
			|		<ConstantValue>Value = Catalogs.Partners.UnknownPartner;</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Owner</Description>
			|				<Type>CatalogRef.Partners</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|</FilterByObjectProperties>";
EndFunction

#EndRegion
#Region Catalog_ProductSegments
Procedure AddPRO_Catalog_ItemSegments(ObjectsRegistrationRules, RegistrationManagerName)
	NewRule = ObjectsRegistrationRules.Add();
	
	NewRule.RegistrationManagerName = RegistrationManagerName; 
	NewRule.Id = "Catalog_ProductSegments";
	
	NewRule.MetadataObjectName3 = "Catalog.ProductSegments";
	NewRule.ExchangePlanName = "DataSynchronizationViaUniversalFormat";
	NewRule.FlagAttributeName = "CatalogsExportMode";	
	NewRule.RuleByObjectPropertiesEmpty = False; 
	NewRule.BatchExecutionOfHandlers = False;
	NewRule.HasBeforeProcessHandler = False;
	NewRule.HasOnProcessHandler = False;
	NewRule.HasOnProcessHandlerAdditional = False;
	NewRule.HasAfterProcessHandler = False;
		
	SetFilters(NewRule, 
		FilterByExchangePlanProperties_4(),
		FilterByObjectProperties_6());
EndProcedure

#EndRegion



Function FilterByObjectProperties_1()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>Posted</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>true</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Posted</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>EnumRef.VATTaxationTypes</ObjectPropertyType>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>PurchaseForActivity</ObjectProperty1>
			|		<Kind>ValueAlgorithm</Kind>
			|		<ConstantValue>Value = PredefinedValue(""Enum.VATTaxationTypes.SpaceActivity"");;</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>PurchaseForActivity</Description>
			|				<Type>EnumRef.VATTaxationTypes</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|</FilterByObjectProperties>" ;
EndFunction
Function FilterByObjectProperties_2()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>DeletionMark</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>false</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>DeletionMark</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|</FilterByObjectProperties>" ;
EndFunction

Function FilterByObjectProperties_4()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>Posted</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>true</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Posted</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|</FilterByObjectProperties>" ;
EndFunction

Function FilterByObjectProperties_5()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>Posted</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>true</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>Posted</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>Number</ObjectPropertyType>
			|		<ComparisonType>Greater</ComparisonType>
			|		<ObjectProperty1>DocumentAmount</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>0</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>DocumentAmount</Description>
			|				<Type>Number</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|</FilterByObjectProperties>" ;
EndFunction

Function FilterByObjectProperties_6()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>DeletionMark</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>false</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>DeletionMark</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>IsFolder</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>false</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>IsFolder</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|</FilterByObjectProperties>" ;
EndFunction


Function FilterByObjectProperties_8()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>DeletionMark</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>false</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>DeletionMark</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|	<FilterElement>
			|		<ObjectPropertyType>EnumRef.ItemsTypes</ObjectPropertyType>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ItemsType</ObjectProperty1>
			|		<Kind>ValueAlgorithm</Kind>
			|		<ConstantValue>Value = Enums.ItemsTypes.Set;</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>ItemsType</Description>
			|				<Type>EnumRef.ItemsTypes</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|</FilterByObjectProperties>" ;
EndFunction

Function FilterByObjectProperties_10()
	Return "<FilterByObjectProperties>
			|	<FilterElement>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>DeletionMark</ObjectProperty1>
			|		<Kind>ConstantValue</Kind>
			|		<ConstantValue>false</ConstantValue>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>DeletionMark</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|	</FilterElement>
			|</FilterByObjectProperties>" ;
EndFunction

Function EmptySelectionByObjectProperties()
	Return "<FilterByObjectProperties/>" ;
EndFunction

Function FilterByExchangePlanProperties_1()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>true</IsConstantString>
			|		<ObjectPropertyType>String</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeUP2ZUP3</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<Type>String</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>true</IsConstantString>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ExchangePlanProperty>ExportItemsWithInventoryOnly</ExchangePlanProperty>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>false</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>ExportItemsWithInventoryOnly</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>" ;
EndFunction

Function FilterByExchangePlanProperties_3()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>Smartway</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|			<ExchangePlanProperty>Companies.Organization</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Organization</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Companies]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<Group>
			|			<BooleanGroupValue>AND</BooleanGroupValue>
			|			<FilterElement>
			|				<IsConstantString>TRUE</IsConstantString>
			|				<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|				<ExchangePlanProperty>UseFilterByCompanies</ExchangePlanProperty>
			|				<ComparisonType>Equal</ComparisonType>
			|				<ObjectProperty1>FALSE</ObjectProperty1>
			|				<TableOfExchangePlanProperties>
			|					<Property>
			|						<Description>UseFilterByCompanies</Description>
			|						<TYPE>BOOLEAN</TYPE>
			|						<Kind>Attribute</Kind>
			|					</Property>
			|				</TableOfExchangePlanProperties>
			|			</FilterElement>
			|			<Group>
			|				<BooleanGroupValue>OR</BooleanGroupValue>
			|				<FilterElement>
			|					<IsConstantString>FALSE</IsConstantString>
			|					<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|					<ExchangePlanProperty>ManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>NotEqual</ComparisonType>
			|					<ObjectProperty1>Organization</ObjectProperty1>
			|					<ObjectPropertiesTable>
			|						<Property>
			|							<Description>Organization</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</ObjectPropertiesTable>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>ManagementCompany</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|				<FilterElement>
			|					<IsConstantString>TRUE</IsConstantString>
			|					<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|					<ExchangePlanProperty>UnloadManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>Equal</ComparisonType>
			|					<ObjectProperty1>TRUE</ObjectProperty1>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>UnloadManagementCompany</Description>
			|							<TYPE>BOOLEAN</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|			</Group>
			|		</Group>
			|	</Group>
			|</FilterByExchangePlanProperties>" ;
EndFunction

Function FilterByExchangePlanProperties_4()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>true</IsConstantString>
			|		<ObjectPropertyType>String</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>UniversalExchange</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<Type>String</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>" ;
EndFunction

Function FilterByExchangePlanProperties_6()
	Return "<FilterByExchangePlanProperties>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|			<ExchangePlanProperty>[Companies].Organization</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Organization</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Companies]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<Group>
			|			<BooleanGroupValue>AND</BooleanGroupValue>
			|			<FilterElement>
			|				<IsConstantString>TRUE</IsConstantString>
			|				<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|				<ExchangePlanProperty>UseFilterByCompanies</ExchangePlanProperty>
			|				<ComparisonType>Equal</ComparisonType>
			|				<ObjectProperty1>FALSE</ObjectProperty1>
			|				<TableOfExchangePlanProperties>
			|					<Property>
			|						<Description>UseFilterByCompanies</Description>
			|						<TYPE>BOOLEAN</TYPE>
			|						<Kind>Attribute</Kind>
			|					</Property>
			|				</TableOfExchangePlanProperties>
			|			</FilterElement>
			|			<Group>
			|				<BooleanGroupValue>OR</BooleanGroupValue>
			|				<FilterElement>
			|					<IsConstantString>FALSE</IsConstantString>
			|					<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|					<ExchangePlanProperty>ManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>NotEqual</ComparisonType>
			|					<ObjectProperty1>Organization</ObjectProperty1>
			|					<ObjectPropertiesTable>
			|						<Property>
			|							<Description>Organization</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</ObjectPropertiesTable>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>ManagementCompany</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|				<FilterElement>
			|					<IsConstantString>TRUE</IsConstantString>
			|					<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|					<ExchangePlanProperty>UnloadManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>Equal</ComparisonType>
			|					<ObjectProperty1>TRUE</ObjectProperty1>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>UnloadManagementCompany</Description>
			|							<TYPE>BOOLEAN</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|			</Group>
			|		</Group>
			|	</Group>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeUP2ZUP3</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>CashExchange</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeOfUPRMC</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>" ;
EndFunction

Function FilterByExchangePlanProperties_7()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>FALSE</IsConstantString>
			|		<ObjectPropertyType>DATE</ObjectPropertyType>
			|		<ExchangePlanProperty>DocumentsExportStartDate</ExchangePlanProperty>
			|		<ComparisonType>GreaterOrEqual</ComparisonType>
			|		<ObjectProperty1>DATE</ObjectProperty1>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>DATE</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>DocumentsExportStartDate</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|			<ExchangePlanProperty>[Companies].Organization</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Organization</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Companies]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|			<ExchangePlanProperty>[Companies].Organization</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>CompanyRecipient</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>CompanyRecipient</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Companies]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<Group>
			|			<BooleanGroupValue>AND</BooleanGroupValue>
			|			<FilterElement>
			|				<IsConstantString>TRUE</IsConstantString>
			|				<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|				<ExchangePlanProperty>UseFilterByCompanies</ExchangePlanProperty>
			|				<ComparisonType>Equal</ComparisonType>
			|				<ObjectProperty1>FALSE</ObjectProperty1>
			|				<TableOfExchangePlanProperties>
			|					<Property>
			|						<Description>UseFilterByCompanies</Description>
			|						<TYPE>BOOLEAN</TYPE>
			|						<Kind>Attribute</Kind>
			|					</Property>
			|				</TableOfExchangePlanProperties>
			|			</FilterElement>
			|			<Group>
			|				<BooleanGroupValue>OR</BooleanGroupValue>
			|				<FilterElement>
			|					<IsConstantString>FALSE</IsConstantString>
			|					<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|					<ExchangePlanProperty>ManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>NotEqual</ComparisonType>
			|					<ObjectProperty1>Organization</ObjectProperty1>
			|					<ObjectPropertiesTable>
			|						<Property>
			|							<Description>Organization</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</ObjectPropertiesTable>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>ManagementCompany</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|				<FilterElement>
			|					<IsConstantString>FALSE</IsConstantString>
			|					<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|					<ExchangePlanProperty>ManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>NotEqual</ComparisonType>
			|					<ObjectProperty1>CompanyRecipient</ObjectProperty1>
			|					<ObjectPropertiesTable>
			|						<Property>
			|							<Description>CompanyRecipient</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</ObjectPropertiesTable>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>ManagementCompany</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|				<FilterElement>
			|					<IsConstantString>TRUE</IsConstantString>
			|					<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|					<ExchangePlanProperty>UnloadManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>Equal</ComparisonType>
			|					<ObjectProperty1>TRUE</ObjectProperty1>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>UnloadManagementCompany</Description>
			|							<TYPE>BOOLEAN</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|			</Group>
			|		</Group>
			|	</Group>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Warehouses</ObjectPropertyType>
			|			<ExchangePlanProperty>[Warehouses].Warehouse</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Warehouse</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Warehouse</Description>
			|					<TYPE>CatalogRef.Warehouses</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Warehouses]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Warehouse</Description>
			|					<TYPE>CatalogRef.Warehouses</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<FilterElement>
			|			<IsConstantString>TRUE</IsConstantString>
			|			<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|			<ExchangePlanProperty>UseFilterByWarehouses</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>FALSE</ObjectProperty1>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>UseFilterByWarehouses</Description>
			|					<TYPE>BOOLEAN</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|	</Group>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeUP2ZUP3</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>CashExchange</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeOfUPRMC</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>" ;
EndFunction

Function FilterByExchangePlanProperties_8()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>true</IsConstantString>
			|		<ObjectPropertyType>String</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeUP2ZUP3</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<Type>String</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>true</IsConstantString>
			|		<ObjectPropertyType>String</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeOfUPRMC</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<Type>String</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>" ;
EndFunction
Function FilterByExchangePlanProperties_9()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>true</IsConstantString>
			|		<ObjectPropertyType>String</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeUP2ZUP3</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<Type>String</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>true</IsConstantString>
			|		<ObjectPropertyType>String</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>CashExchange</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<Type>String</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>true</IsConstantString>
			|		<ObjectPropertyType>String</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeOfUPRMC</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<Type>String</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>" ;
EndFunction
Function FilterByExchangePlanProperties_10()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>true</IsConstantString>
			|		<ObjectPropertyType>String</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>ExchangeOfUPRMC</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<Type>String</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>" ;
EndFunction

Function FilterByExchangePlanProperties_12()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>FALSE</IsConstantString>
			|		<ObjectPropertyType>DATE</ObjectPropertyType>
			|		<ExchangePlanProperty>DocumentsExportStartDate</ExchangePlanProperty>
			|		<ComparisonType>GreaterOrEqual</ComparisonType>
			|		<ObjectProperty1>DATE</ObjectProperty1>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>DATE</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>DocumentsExportStartDate</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|			<ExchangePlanProperty>[Companies].Organization</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Organization</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Companies]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|			<ExchangePlanProperty>[Companies].Organization</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Consignee</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Consignee</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Companies]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<Group>
			|			<BooleanGroupValue>AND</BooleanGroupValue>
			|			<FilterElement>
			|				<IsConstantString>TRUE</IsConstantString>
			|				<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|				<ExchangePlanProperty>UseFilterByCompanies</ExchangePlanProperty>
			|				<ComparisonType>Equal</ComparisonType>
			|				<ObjectProperty1>FALSE</ObjectProperty1>
			|				<TableOfExchangePlanProperties>
			|					<Property>
			|						<Description>UseFilterByCompanies</Description>
			|						<TYPE>BOOLEAN</TYPE>
			|						<Kind>Attribute</Kind>
			|					</Property>
			|				</TableOfExchangePlanProperties>
			|			</FilterElement>
			|			<Group>
			|				<BooleanGroupValue>OR</BooleanGroupValue>
			|				<FilterElement>
			|					<IsConstantString>FALSE</IsConstantString>
			|					<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|					<ExchangePlanProperty>ManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>NotEqual</ComparisonType>
			|					<ObjectProperty1>Organization</ObjectProperty1>
			|					<ObjectPropertiesTable>
			|						<Property>
			|							<Description>Organization</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</ObjectPropertiesTable>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>ManagementCompany</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|				<FilterElement>
			|					<IsConstantString>FALSE</IsConstantString>
			|					<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|					<ExchangePlanProperty>ManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>NotEqual</ComparisonType>
			|					<ObjectProperty1>Consignee</ObjectProperty1>
			|					<ObjectPropertiesTable>
			|						<Property>
			|							<Description>Consignee</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</ObjectPropertiesTable>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>ManagementCompany</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|				<FilterElement>
			|					<IsConstantString>TRUE</IsConstantString>
			|					<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|					<ExchangePlanProperty>UnloadManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>Equal</ComparisonType>
			|					<ObjectProperty1>TRUE</ObjectProperty1>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>UnloadManagementCompany</Description>
			|							<TYPE>BOOLEAN</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|			</Group>
			|		</Group>
			|	</Group>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeUP2ZUP3</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>CashExchange</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeOfUPRMC</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>" ;
EndFunction

Function FilterByExchangePlanProperties_13()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>FALSE</IsConstantString>
			|		<ObjectPropertyType>DATE</ObjectPropertyType>
			|		<ExchangePlanProperty>DocumentsExportStartDate</ExchangePlanProperty>
			|		<ComparisonType>GreaterOrEqual</ComparisonType>
			|		<ObjectProperty1>DATE</ObjectProperty1>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>DATE</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>DocumentsExportStartDate</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|			<ExchangePlanProperty>[Companies].Organization</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Organization</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Companies]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<Group>
			|			<BooleanGroupValue>AND</BooleanGroupValue>
			|			<FilterElement>
			|				<IsConstantString>TRUE</IsConstantString>
			|				<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|				<ExchangePlanProperty>UseFilterByCompanies</ExchangePlanProperty>
			|				<ComparisonType>Equal</ComparisonType>
			|				<ObjectProperty1>FALSE</ObjectProperty1>
			|				<TableOfExchangePlanProperties>
			|					<Property>
			|						<Description>UseFilterByCompanies</Description>
			|						<TYPE>BOOLEAN</TYPE>
			|						<Kind>Attribute</Kind>
			|					</Property>
			|				</TableOfExchangePlanProperties>
			|			</FilterElement>
			|			<Group>
			|				<BooleanGroupValue>OR</BooleanGroupValue>
			|				<FilterElement>
			|					<IsConstantString>FALSE</IsConstantString>
			|					<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|					<ExchangePlanProperty>ManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>NotEqual</ComparisonType>
			|					<ObjectProperty1>Organization</ObjectProperty1>
			|					<ObjectPropertiesTable>
			|						<Property>
			|							<Description>Organization</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</ObjectPropertiesTable>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>ManagementCompany</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|				<FilterElement>
			|					<IsConstantString>TRUE</IsConstantString>
			|					<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|					<ExchangePlanProperty>UnloadManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>Equal</ComparisonType>
			|					<ObjectProperty1>TRUE</ObjectProperty1>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>UnloadManagementCompany</Description>
			|							<TYPE>BOOLEAN</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|			</Group>
			|		</Group>
			|	</Group>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.CashRegisters</ObjectPropertyType>
			|			<ExchangePlanProperty>[CashRegisters].CashRegister</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>CashRegister</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>CashRegister</Description>
			|					<TYPE>CatalogRef.CashRegisters</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[CashRegisters]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>CashRegister</Description>
			|					<TYPE>CatalogRef.CashRegisters</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<FilterElement>
			|			<IsConstantString>TRUE</IsConstantString>
			|			<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|			<ExchangePlanProperty>UseFilterByCashRegisters</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>FALSE</ObjectProperty1>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>UseFilterByCashRegisters</Description>
			|					<TYPE>BOOLEAN</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|	</Group>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeUP2ZUP3</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>CashExchange</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeOfUPRMC</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>" ;
EndFunction

Function FilterByExchangePlanProperties_14()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>true</IsConstantString>
			|		<ObjectPropertyType>Boolean</ObjectPropertyType>
			|		<ExchangePlanProperty>ExportItemsWithInventoryOnly</ExchangePlanProperty>
			|		<ComparisonType>Equal</ComparisonType>
			|		<ObjectProperty1>true</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>ExportItemsWithInventoryOnly</Description>
			|				<Type>Boolean</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>" ;
EndFunction
Function FilterByExchangePlanProperties_15()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>FALSE</IsConstantString>
			|		<ObjectPropertyType>DATE</ObjectPropertyType>
			|		<ExchangePlanProperty>DocumentsExportStartDate</ExchangePlanProperty>
			|		<ComparisonType>GreaterOrEqual</ComparisonType>
			|		<ObjectProperty1>DATE</ObjectProperty1>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>DATE</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>DocumentsExportStartDate</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|			<ExchangePlanProperty>[Companies].Organization</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Organization</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Companies]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<Group>
			|			<BooleanGroupValue>AND</BooleanGroupValue>
			|			<FilterElement>
			|				<IsConstantString>TRUE</IsConstantString>
			|				<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|				<ExchangePlanProperty>UseFilterByCompanies</ExchangePlanProperty>
			|				<ComparisonType>Equal</ComparisonType>
			|				<ObjectProperty1>FALSE</ObjectProperty1>
			|				<TableOfExchangePlanProperties>
			|					<Property>
			|						<Description>UseFilterByCompanies</Description>
			|						<TYPE>BOOLEAN</TYPE>
			|						<Kind>Attribute</Kind>
			|					</Property>
			|				</TableOfExchangePlanProperties>
			|			</FilterElement>
			|			<Group>
			|				<BooleanGroupValue>OR</BooleanGroupValue>
			|				<FilterElement>
			|					<IsConstantString>FALSE</IsConstantString>
			|					<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|					<ExchangePlanProperty>ManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>NotEqual</ComparisonType>
			|					<ObjectProperty1>Organization</ObjectProperty1>
			|					<ObjectPropertiesTable>
			|						<Property>
			|							<Description>Organization</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</ObjectPropertiesTable>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>ManagementCompany</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|				<FilterElement>
			|					<IsConstantString>TRUE</IsConstantString>
			|					<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|					<ExchangePlanProperty>UnloadManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>Equal</ComparisonType>
			|					<ObjectProperty1>TRUE</ObjectProperty1>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>UnloadManagementCompany</Description>
			|							<TYPE>BOOLEAN</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|			</Group>
			|		</Group>
			|	</Group>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeUP2ZUP3</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>CashExchange</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeOfUPRMC</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>" ;
EndFunction
Function FilterByExchangePlanProperties_16()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>FALSE</IsConstantString>
			|		<ObjectPropertyType>DATE</ObjectPropertyType>
			|		<ExchangePlanProperty>DocumentsExportStartDate</ExchangePlanProperty>
			|		<ComparisonType>GreaterOrEqual</ComparisonType>
			|		<ObjectProperty1>DATE</ObjectProperty1>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>DATE</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>DocumentsExportStartDate</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|			<ExchangePlanProperty>[Companies].Organization</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Organization</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Companies]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<Group>
			|			<BooleanGroupValue>AND</BooleanGroupValue>
			|			<FilterElement>
			|				<IsConstantString>TRUE</IsConstantString>
			|				<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|				<ExchangePlanProperty>UseFilterByCompanies</ExchangePlanProperty>
			|				<ComparisonType>Equal</ComparisonType>
			|				<ObjectProperty1>FALSE</ObjectProperty1>
			|				<TableOfExchangePlanProperties>
			|					<Property>
			|						<Description>UseFilterByCompanies</Description>
			|						<TYPE>BOOLEAN</TYPE>
			|						<Kind>Attribute</Kind>
			|					</Property>
			|				</TableOfExchangePlanProperties>
			|			</FilterElement>
			|			<Group>
			|				<BooleanGroupValue>OR</BooleanGroupValue>
			|				<FilterElement>
			|					<IsConstantString>FALSE</IsConstantString>
			|					<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|					<ExchangePlanProperty>ManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>NotEqual</ComparisonType>
			|					<ObjectProperty1>Organization</ObjectProperty1>
			|					<ObjectPropertiesTable>
			|						<Property>
			|							<Description>Organization</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</ObjectPropertiesTable>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>ManagementCompany</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|				<FilterElement>
			|					<IsConstantString>TRUE</IsConstantString>
			|					<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|					<ExchangePlanProperty>UnloadManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>Equal</ComparisonType>
			|					<ObjectProperty1>TRUE</ObjectProperty1>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>UnloadManagementCompany</Description>
			|							<TYPE>BOOLEAN</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|			</Group>
			|		</Group>
			|	</Group>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Warehouses</ObjectPropertyType>
			|			<ExchangePlanProperty>[Warehouses].Warehouse</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Warehouse</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Warehouse</Description>
			|					<TYPE>CatalogRef.Warehouses</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Warehouses]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Warehouse</Description>
			|					<TYPE>CatalogRef.Warehouses</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<FilterElement>
			|			<IsConstantString>TRUE</IsConstantString>
			|			<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|			<ExchangePlanProperty>UseFilterByWarehouses</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>FALSE</ObjectProperty1>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>UseFilterByWarehouses</Description>
			|					<TYPE>BOOLEAN</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|	</Group>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeUP2ZUP3</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>CashExchange</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeOfUPRMC</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>" ;
EndFunction

Function FilterByExchangePlanProperties_18()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>FALSE</IsConstantString>
			|		<ObjectPropertyType>DATE</ObjectPropertyType>
			|		<ExchangePlanProperty>DocumentsExportStartDate</ExchangePlanProperty>
			|		<ComparisonType>GreaterOrEqual</ComparisonType>
			|		<ObjectProperty1>DATE</ObjectProperty1>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>DATE</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>DocumentsExportStartDate</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|			<ExchangePlanProperty>[Companies].Organization</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Organization</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Companies]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<Group>
			|			<BooleanGroupValue>AND</BooleanGroupValue>
			|			<FilterElement>
			|				<IsConstantString>TRUE</IsConstantString>
			|				<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|				<ExchangePlanProperty>UseFilterByCompanies</ExchangePlanProperty>
			|				<ComparisonType>Equal</ComparisonType>
			|				<ObjectProperty1>FALSE</ObjectProperty1>
			|				<TableOfExchangePlanProperties>
			|					<Property>
			|						<Description>UseFilterByCompanies</Description>
			|						<TYPE>BOOLEAN</TYPE>
			|						<Kind>Attribute</Kind>
			|					</Property>
			|				</TableOfExchangePlanProperties>
			|			</FilterElement>
			|			<Group>
			|				<BooleanGroupValue>OR</BooleanGroupValue>
			|				<FilterElement>
			|					<IsConstantString>FALSE</IsConstantString>
			|					<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|					<ExchangePlanProperty>ManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>NotEqual</ComparisonType>
			|					<ObjectProperty1>Organization</ObjectProperty1>
			|					<ObjectPropertiesTable>
			|						<Property>
			|							<Description>Organization</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</ObjectPropertiesTable>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>ManagementCompany</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|				<FilterElement>
			|					<IsConstantString>TRUE</IsConstantString>
			|					<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|					<ExchangePlanProperty>UnloadManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>Equal</ComparisonType>
			|					<ObjectProperty1>TRUE</ObjectProperty1>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>UnloadManagementCompany</Description>
			|							<TYPE>BOOLEAN</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|			</Group>
			|		</Group>
			|	</Group>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeUP2ZUP3</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>CashExchange</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeOfUPRMC</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>" ;
EndFunction

Function FilterByExchangePlanProperties_19()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>true</IsConstantString>
			|		<ObjectPropertyType>String</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeOfUPRMC</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<Type>String</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>" ;
EndFunction

Function FilterByExchangePlanProperties_21()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>true</IsConstantString>
			|		<ObjectPropertyType>String</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeUP2ZUP3</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<Type>String</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>true</IsConstantString>
			|		<ObjectPropertyType>String</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>CashExchange</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<Type>String</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>true</IsConstantString>
			|		<ObjectPropertyType>String</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeOfUPRMC</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<Type>String</Type>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>" ;
EndFunction


Function FilterByExchangePlanProperties_23()
	Return "<FilterByExchangePlanProperties>
			|	<FilterElement>
			|		<IsConstantString>FALSE</IsConstantString>
			|		<ObjectPropertyType>DATE</ObjectPropertyType>
			|		<ExchangePlanProperty>DocumentsExportStartDate</ExchangePlanProperty>
			|		<ComparisonType>GreaterOrEqual</ComparisonType>
			|		<ObjectProperty1>DATE</ObjectProperty1>
			|		<ObjectPropertiesTable>
			|			<Property>
			|				<Description>DATE</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Property</Kind>
			|			</Property>
			|		</ObjectPropertiesTable>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>DocumentsExportStartDate</Description>
			|				<TYPE>DATE</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|			<ExchangePlanProperty>Companies.Organization</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Organization</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Companies]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Organization</Description>
			|					<TYPE>CatalogRef.Companies</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<Group>
			|			<BooleanGroupValue>AND</BooleanGroupValue>
			|			<FilterElement>
			|				<IsConstantString>TRUE</IsConstantString>
			|				<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|				<ExchangePlanProperty>UseFilterByCompanies</ExchangePlanProperty>
			|				<ComparisonType>Equal</ComparisonType>
			|				<ObjectProperty1>FALSE</ObjectProperty1>
			|				<TableOfExchangePlanProperties>
			|					<Property>
			|						<Description>UseFilterByCompanies</Description>
			|						<TYPE>BOOLEAN</TYPE>
			|						<Kind>Attribute</Kind>
			|					</Property>
			|				</TableOfExchangePlanProperties>
			|			</FilterElement>
			|			<Group>
			|				<BooleanGroupValue>OR</BooleanGroupValue>
			|				<FilterElement>
			|					<IsConstantString>FALSE</IsConstantString>
			|					<ObjectPropertyType>CatalogRef.Companies</ObjectPropertyType>
			|					<ExchangePlanProperty>ManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>NotEqual</ComparisonType>
			|					<ObjectProperty1>Organization</ObjectProperty1>
			|					<ObjectPropertiesTable>
			|						<Property>
			|							<Description>Organization</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</ObjectPropertiesTable>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>ManagementCompany</Description>
			|							<TYPE>CatalogRef.Companies</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|				<FilterElement>
			|					<IsConstantString>TRUE</IsConstantString>
			|					<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|					<ExchangePlanProperty>UnloadManagementCompany</ExchangePlanProperty>
			|					<ComparisonType>Equal</ComparisonType>
			|					<ObjectProperty1>TRUE</ObjectProperty1>
			|					<TableOfExchangePlanProperties>
			|						<Property>
			|							<Description>UnloadManagementCompany</Description>
			|							<TYPE>BOOLEAN</TYPE>
			|							<Kind>Attribute</Kind>
			|						</Property>
			|					</TableOfExchangePlanProperties>
			|				</FilterElement>
			|			</Group>
			|		</Group>
			|	</Group>
			|	<Group>
			|		<BooleanGroupValue>OR</BooleanGroupValue>
			|		<FilterElement>
			|			<IsConstantString>FALSE</IsConstantString>
			|			<ObjectPropertyType>CatalogRef.Warehouses</ObjectPropertyType>
			|			<ExchangePlanProperty>Warehouses.Warehouse</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>Warehouse</ObjectProperty1>
			|			<ObjectPropertiesTable>
			|				<Property>
			|					<Description>Warehouse</Description>
			|					<TYPE>CatalogRef.Warehouses</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</ObjectPropertiesTable>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>[Warehouses]</Description>
			|					<Kind>TabularSection</Kind>
			|				</Property>
			|				<Property>
			|					<Description>Warehouse</Description>
			|					<TYPE>CatalogRef.Warehouses</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|		<FilterElement>
			|			<IsConstantString>TRUE</IsConstantString>
			|			<ObjectPropertyType>BOOLEAN</ObjectPropertyType>
			|			<ExchangePlanProperty>UseFilterByWarehouses</ExchangePlanProperty>
			|			<ComparisonType>Equal</ComparisonType>
			|			<ObjectProperty1>FALSE</ObjectProperty1>
			|			<TableOfExchangePlanProperties>
			|				<Property>
			|					<Description>UseFilterByWarehouses</Description>
			|					<TYPE>BOOLEAN</TYPE>
			|					<Kind>Attribute</Kind>
			|				</Property>
			|			</TableOfExchangePlanProperties>
			|		</FilterElement>
			|	</Group>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeUP2ZUP3</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>CashExchange</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|	<FilterElement>
			|		<IsConstantString>TRUE</IsConstantString>
			|		<ObjectPropertyType>STRING</ObjectPropertyType>
			|		<ExchangePlanProperty>SettingsMode</ExchangePlanProperty>
			|		<ComparisonType>NotEqual</ComparisonType>
			|		<ObjectProperty1>ExchangeOfUPRMC</ObjectProperty1>
			|		<TableOfExchangePlanProperties>
			|			<Property>
			|				<Description>SettingsMode</Description>
			|				<TYPE>STRING</TYPE>
			|				<Kind>Attribute</Kind>
			|			</Property>
			|		</TableOfExchangePlanProperties>
			|	</FilterElement>
			|</FilterByExchangePlanProperties>" ;
EndFunction

Function EmptySelectionByExchangePlanProperties()
	Return "<FilterByExchangePlanProperties/>" ;
EndFunction

#EndRegion
