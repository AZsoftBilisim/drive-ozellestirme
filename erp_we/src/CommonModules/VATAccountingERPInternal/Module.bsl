#Region Private

#Region GettingVATAccountingSettingsAndParameters

// Applicable types of VAT taxation
// 
// Parameters:
// 	Sales - Boolean -
// 	Purchases - Boolean -
// 	SeparateAccounting - Boolean -
// Returns:
// 	ValueList of EnumRef.VATTaxationTypes
//
Function ApplicableTypesOfVATTaxation(Sales = True, Purchases = True, SeparateAccounting = False) Export
	
	AccountingSettings = VATAccountingERP.AccountingSettings();
	
	TypesOfTaxation = New ValueList();
	If AccountingSettings.UseVATAccounting Then
		If Sales And Purchases Then
			Presentation = NStr("vi = 'Chịu thuế GTGT';
								|ru = 'Облагается НДС';
								|en = 'Subject to VAT'; fa = 'مشمول مالیات بر ارزش افزوده';
								|it = 'Soggetto ad IVA';
								|pl = 'Podlega VAT';
								|tr = 'Yurtiçi KDV oranları'");
		ElsIf Sales Then
			Presentation = NStr("vi = 'Có tính thuế GTGT';
								|ru = 'Продажа облагается НДС';
								|en = 'Sale is subject to VAT'; fa = 'فروش مشمول مالیات بر ارزش افزوده است';
								|it = 'Vendita è soggetta ad IVA';
								|pl = 'Sprzedaż opodatkowana VAT';
								|tr = 'Satış işlemi KDV''ye tabidir'");
		Else
			Presentation = NStr("vi = 'Mua hàng chịu thuế GTGT';
								|ru = 'Закупка облагается НДС';
								|en = 'Purchase is subject to VAT'; fa = 'خرید مشمول مالیات بر ارزش افزوده است';
								|it = 'Acquisto è soggetto ad IVA';
								|pl = 'Zakup podlega VAT';
								|tr = 'Satın alma işlemi KDV''ye tabidir'");
		EndIf;
		TypesOfTaxation.Add(Enums.VATTaxationTypes.SaleIsSubjectToVAT, Presentation);
	EndIf;
	
	If Sales And Purchases Then
		Presentation = NStr("vi = 'Không chịu thuế GTGT';
							|ru = 'Не облагается НДС';
							|en = 'Not subject to VAT'; fa = 'مشمول مالیات بر ارزش افزوده نیست';
							|it = 'Non soggetto ad IVA';
							|pl = 'Nie podlega VAT';
							|tr = 'KDV''den muaf'");
	ElsIf Sales Then
		Presentation = NStr("vi = 'Bán hàng không chịu thuế GTGT';
							|ru = 'Продажа не облагается НДС';
							|en = 'Sale is not subject to VAT'; fa = 'فروش مشمول مالیات بر ارزش افزوده نیست';
							|it = 'Vendita non è soggetta ad IVA';
							|pl = 'Sprzedaż zwolniona z VAT';
							|tr = 'Satış işlemi KDV''ye tabi değildir'");
	Else
		Presentation = NStr("vi = 'Mua hàng không chịu thuế GTGT';
							|ru = 'Закупка не облагается НДС';
							|en = 'Purchase is not subject to VAT'; fa = 'خرید مشمول مالیات بر ارزش افزوده نیست';
							|it = 'Acquisto non è soggetto ad IVA';
							|pl = 'Zakup nie podlega VAT';
							|tr = 'Satın alma işlemi KDV''ye tabi değildir'");
	EndIf;
	TypesOfTaxation.Add(Enums.VATTaxationTypes.SaleIsNotSubjectToVAT, Presentation);
	
	If Sales And AccountingSettings.SalesForExport Then
		TypesOfTaxation.Add(Enums.VATTaxationTypes.ExportSale, NStr("vi = 'Kết xuất';
																	|ru = 'Экспорт';
																	|en = 'Export'; fa = 'خروج اطلاعات';
																	|it = 'Esportazione';
																	|pl = 'Export';
																	|tr = 'İhracat'"));
	EndIf;
	
	If Purchases And AccountingSettings.VATReverseCharge Then
		TypesOfTaxation.Add(Enums.VATTaxationTypes.VATReverseCharge, NStr("vi = 'Đánh thuế GTGT đảo ngược';
																			|ru = 'Реверсивное обложение НДС';
																			|en = 'Reverse VAT charge'; fa = 'مالیات بر ارزش افزوده معکوس';
																			|it = 'IVA inversa';
																			|pl = 'Odwrotne obciążenie VAT';
																			|tr = 'KDV iadesi uygulama'"));
	EndIf;
	
	VATAccountingLocalization.SupplementApplicableTypesOfVATTaxation(TypesOfTaxation, AccountingSettings, Sales, Purchases);
		
	If SeparateAccounting Then
		ApplicableVATActivities = ApplicableVATActivities().UnloadValues();
		ApplicableTypesOfVATTaxation = TypesOfTaxation.UnloadValues();
		CommonClientServer.SupplementArray(ApplicableTypesOfVATTaxation, ApplicableVATActivities, True);
		TypesOfTaxation.LoadValues(ApplicableTypesOfVATTaxation);
	EndIf;
	
	Return TypesOfTaxation;
	
EndFunction

// Applicable activities VAT
// 
// Returns:
// 	ValueList of EnumRef.VATTaxationTypes -
Function ApplicableVATActivities() Export
	
	AccountingSettings = VATAccountingERP.AccountingSettings();
	
	VATActivities = New ValueList();
	
	VATActivities.Add(Enums.VATTaxationTypes.EmptyRef(), NStr("vi = 'Không thay đổi';
																|ru = 'Без изменений';
																|en = 'Without changes'; fa = 'بدون تغییرات';
																|it = 'Senza modifiche';
																|pl = 'Bez zmian';
																|tr = 'Değişiklik yapmadan'"));
	If AccountingSettings.UseVATAccounting Then
		VATActivities.Add(Enums.VATTaxationTypes.SaleIsSubjectToVAT, NStr("vi = 'Chịu thuế GTGT';
																			|ru = 'Облагаемую НДС';
																			|en = 'Subject to VAT'; fa = 'مشمول مالیات بر ارزش افزوده';
																			|it = 'Soggetta ad IVA';
																			|pl = 'Podlegającą VAT';
																			|tr = 'KDV''ye tabi olanı'"));
	EndIf;
	VATActivities.Add(Enums.VATTaxationTypes.SaleIsNotSubjectToVAT, NStr("vi = 'Không chịu thuế GTGT';
																		|ru = 'Не облагаемую НДС';
																		|en = 'VAT free'; fa = 'معاف از مالیات بر ارزش افزوده';
																		|it = 'Non soggetta ad IVA';
																		|pl = 'Nie podlegającą VAT';
																		|tr = 'KDV''ye tabi olmayanı'"));
	If AccountingSettings.SeparateVATAccounting Then
		VATActivities.Add(Enums.VATTaxationTypes.DeterminedByAllocation, NStr("vi = 'Xác định phân bổ';
																				|ru = 'Определяется распределением';
																				|en = 'Determined by allocation'; fa = 'تعیین‌شده بر اساس تسهیم';
																				|it = 'Determinato dalla allocazione';
																				|pl = 'Określane jest podziałem';
																				|tr = 'Dağıtımla tanımlanmaktadır'"));
	EndIf;
	VATAccountingLocalization.SupplementApplicableActivitiesWithVAT(VATActivities, AccountingSettings);
	
	Return VATActivities;
	
EndFunction

#EndRegion

#Region AccountingForIncomingVAT

Procedure SetParameterTypesOfTaxationVATReceipts(Query) Export
	
	If Query.Parameters.Property("TypesOfTaxationVATReceipts") Then
		Return;
	EndIf;
	
	Query.SetParameter("TypesOfTaxationVATReceipts", VATAccountingERP.TypesOfActivitiesVATIsAcceptedForReimbursement());
	
EndProcedure

// Parameters:
//  FillParameters - See VATAccountingERPClientServer.ParametersForFillingInVATActivityType
// Returns:
//  Array of EnumRef.VATTaxationTypes
//
Function AvailableVATActivities(FillParameters) Export
	
	// We will prepare an array of activities available for operations
	ActivitiesAvailableByOperation = New Structure;
	
	If FillParameters.PurchaseOfGoods Then
		ArrayOfAvailable = New Array;
		ArrayOfAvailable.Add(Enums.VATTaxationTypes.SaleIsSubjectToVAT);
		ArrayOfAvailable.Add(Enums.VATTaxationTypes.SaleIsNotSubjectToVAT);  
		ArrayOfAvailable.Add(Enums.VATTaxationTypes.DeterminedByAllocation); 
		ActivitiesAvailableByOperation.Insert("PurchaseOfGoods", ArrayOfAvailable);
	EndIf;
	
	If FillParameters.AcquisitionOfWorks Then
		ArrayOfAvailable = New Array;
		ArrayOfAvailable.Add(Enums.VATTaxationTypes.SaleIsSubjectToVAT);
		ArrayOfAvailable.Add(Enums.VATTaxationTypes.SaleIsNotSubjectToVAT);
		ArrayOfAvailable.Add(Enums.VATTaxationTypes.DeterminedByAllocation);
		ActivitiesAvailableByOperation.Insert("AcquisitionOfWorks", ArrayOfAvailable);
	EndIf;
	
	If FillParameters.PurchaseOnArticles Then
		ArrayOfAvailable = New Array;
		ArrayOfAvailable.Add(Enums.VATTaxationTypes.SaleIsSubjectToVAT);
		ArrayOfAvailable.Add(Enums.VATTaxationTypes.SaleIsNotSubjectToVAT);
		ArrayOfAvailable.Add(Enums.VATTaxationTypes.DeterminedByAllocation);
		ActivitiesAvailableByOperation.Insert("PurchaseOnArticles", ArrayOfAvailable);
	EndIf;
	
	If FillParameters.MovementOfGoodsInWarehouses Then
		ArrayOfAvailable = New Array;
		ActivitiesAvailableByOperation.Insert("MovementOfGoodsInWarehouses", ArrayOfAvailable);
	EndIf;
	
	If FillParameters.MovementBetweenBranches Then
		ArrayOfAvailable = New Array;
		ActivitiesAvailableByOperation.Insert("MovementBetweenBranches", ArrayOfAvailable);
	EndIf;
	
	If FillParameters.MovementOfGoodsAndWorksInProduction Then
		ArrayOfAvailable = New Array;
		ArrayOfAvailable.Add(Enums.VATTaxationTypes.DeterminedByAllocation);
		ActivitiesAvailableByOperation.Insert("MovementOfGoodsAndWorksInProduction", ArrayOfAvailable);
	EndIf;
	
	If FillParameters.WriteOffOfGoodsAndWorksForItems Then
		ArrayOfAvailable = New Array;
		ActivitiesAvailableByOperation.Insert("WriteOffOfGoodsAndWorksForItems", ArrayOfAvailable);
	EndIf;
	
	If FillParameters.OutputOfProductsAndWorks Then
		ArrayOfAvailable = New Array;
		ArrayOfAvailable.Add(Enums.VATTaxationTypes.SaleIsSubjectToVAT);
		ArrayOfAvailable.Add(Enums.VATTaxationTypes.SaleIsNotSubjectToVAT);
		ArrayOfAvailable.Add(Enums.VATTaxationTypes.DeterminedByAllocation);
		ActivitiesAvailableByOperation.Insert("OutputOfProductsAndWorks", ArrayOfAvailable);
	EndIf;
	
	If FillParameters.AssemblyDisassemblyOfGoods Then
		ArrayOfAvailable = New Array;
		ActivitiesAvailableByOperation.Insert("AssemblyDisassemblyOfGoods", ArrayOfAvailable);
	EndIf;
	
	If FillParameters.TransferToOperation Then
		ArrayOfAvailable = New Array;
		ActivitiesAvailableByOperation.Insert("TransferToOperation", ArrayOfAvailable);
	EndIf;
	
	If FillParameters.OtherDisposalOfGoods Then
		ArrayOfAvailable = New Array;
		ActivitiesAvailableByOperation.Insert("OtherDisposalOfGoods", ArrayOfAvailable);
	EndIf;
	
	If FillParameters.LeasingPropertyOnBalanceSheet Then
		ArrayOfAvailable = New Array;
		ArrayOfAvailable.Add(Enums.VATTaxationTypes.SaleIsSubjectToVAT);
		ArrayOfAvailable.Add(Enums.VATTaxationTypes.SaleIsNotSubjectToVAT);
		ActivitiesAvailableByOperation.Insert("LeasingPropertyOnBalanceSheet", ArrayOfAvailable);
	EndIf;
	
	// Let's prepare an array of activities that are not available by settings
	UnavailableVATActivities = New Array;
	InformationSecurityAccountingParameters = VATAccountingERP.AccountingSettings();
	OrganizationAccountingParameters = VATAccountingERP.AccountingParametersForOrganization(FillParameters.Organization, FillParameters.Date);
	
	If ValueIsFilled(FillParameters.Organization) Then
		MainActivityVATProcurement = OrganizationAccountingParameters.MainActivityVATProcurement;
		SeparateVATAccounting = OrganizationAccountingParameters.SeparateVATAccounting;
	Else
		MainActivityVATProcurement = InformationSecurityAccountingParameters.MainActivityVATProcurement;
		SeparateVATAccounting = InformationSecurityAccountingParameters.SeparateVATAccounting;
	EndIf;
	
	If MainActivityVATProcurement = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT Then
		UnavailableVATActivities.Add(Enums.VATTaxationTypes.SaleIsSubjectToVAT);
	ElsIf MainActivityVATProcurement = Enums.VATTaxationTypes.SaleIsSubjectToVAT 
		 And Not SeparateVATAccounting Then
		UnavailableVATActivities.Add(Enums.VATTaxationTypes.SaleIsNotSubjectToVAT);
	EndIf;
	If Not SeparateVATAccounting Then
		UnavailableVATActivities.Add(Enums.VATTaxationTypes.DeterminedByAllocation);
	EndIf;
	
	VATAccountingLocalization.AddAvailableUnavailableVATActivitiesByParameters(
		ActivitiesAvailableByOperation, UnavailableVATActivities, FillParameters);
	
	// We will take into account the availability of the operation
	AvailableVATActivities = New Array;
	If ActivitiesAvailableByOperation.Count() > 0 Then
		AvailableVATActivities = ApplicableVATActivities().UnloadValues();
		For Each KeyAndValue In ActivitiesAvailableByOperation Do
			AvailableVATActivities = TMCommonUseClientServer.IntersectionOfArrays(AvailableVATActivities, KeyAndValue.Value);
		EndDo;
	EndIf;
	
	// We will take into account the unavailability of the accounting settings of the organization
	AvailableVATActivities = CommonClientServer.ArraysDifference(AvailableVATActivities, UnavailableVATActivities);
	
	Return AvailableVATActivities;
	
EndFunction

// Parameters:
//  FillParameters - See VATAccountingERPClientServer.ParametersForFillingInVATActivityType
// Returns:
//  Array of EnumRef.VATTaxationTypes
//
Function VATFreePurchases(FillParameters) Export
	
	ApplicableTypesOfTaxation = ApplicableTypesOfVATTaxation(False, True).UnloadValues();
	
	TypesOfTaxationNotAvailableByParameters = New Array;
	If FillParameters.ImportOfGoods Or FillParameters.ImportOfGoodsFromCustomsUnion Then
		TypesOfTaxationNotAvailableByParameters.Add(Enums.VATTaxationTypes.SaleIsSubjectToVAT);
	EndIf;
	If FillParameters.ReceiptOfGoodsInTransit Then
		TypesOfTaxationNotAvailableByParameters.Add(Enums.VATTaxationTypes.SaleIsSubjectToVAT);
	EndIf;
	
	If Not FillParameters.PurchaseOfGoods 
		And Not FillParameters.AcquisitionOfWorks 
		And Not FillParameters.PurchaseOnArticles
		And Not FillParameters.ReceiptFromProcessing Then
		TypesOfTaxationNotAvailableByParameters.Add(Enums.VATTaxationTypes.VATReverseCharge);
	EndIf;
	
	If FillParameters.ThisIsOperationBetweenOrganizations Then
		TypesOfTaxationNotAvailableByParameters.Add(Enums.VATTaxationTypes.VATReverseCharge);
	EndIf;
	
	VATAccountingLocalization.AddPurchaseTaxTypesThatAreNotAvailableForTransaction(TypesOfTaxationNotAvailableByParameters, FillParameters);

	Return CommonClientServer.ArraysDifference(ApplicableTypesOfTaxation, TypesOfTaxationNotAvailableByParameters);
	
EndFunction

// Returns:
//  Array of EnumRef.VATTaxationTypes
//
Function TaxationOfVATSalesForExport() Export
	
	Result = New Array();
	Result.Add(Enums.VATTaxationTypes.ExportSale);
	// Until the transfer of the cost price and revenue to modularity.
	Result.Add(Enums.VATTaxationTypes.ExportOfCommoditiesServicesWorks);
	Result.Add(Enums.VATTaxationTypes.ExportOfNonResourceGoods);
	Return Result;
	
EndFunction

#EndRegion

#Region AccountingForOutgoingVAT

// Generates a list of available values for setting up VAT accounting and the reflected transaction.
//
// Parameters:
// 	FillParameters - See VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation
//
// Returns:
// 	Array of EnumRef.VATTaxationTypes - Available values for VAT taxation of purchases.
// 
Function AvailableSalesVATTaxation(FillParameters) Export
	
	InformationSecurityAccountingParameters = VATAccountingERP.AccountingSettings();
	OrganizationAccountingParameters = VATAccountingERP.AccountingParametersForOrganization(
									FillParameters.Organization, FillParameters.Date, FillParameters.Warehouse, FillParameters.Department);
	
	VATAvailableByOperation = New Structure();
	
	If FillParameters.GoodsSales Then
		ArrayOfAvailable = New Array;
		ArrayOfAvailable.Add(Enums.VATTaxationTypes.SaleIsSubjectToVAT);
		ArrayOfAvailable.Add(Enums.VATTaxationTypes.SaleIsNotSubjectToVAT);
		ArrayOfAvailable.Add(Enums.VATTaxationTypes.ExportSale);
		VATAvailableByOperation.Insert("GoodsSales", ArrayOfAvailable);
	EndIf;
	
	If FillParameters.ImplementationOfWorksServices Then
		ArrayOfAvailable = New Array;
		ArrayOfAvailable.Add(Enums.VATTaxationTypes.SaleIsSubjectToVAT);
		ArrayOfAvailable.Add(Enums.VATTaxationTypes.SaleIsNotSubjectToVAT);
		ArrayOfAvailable.Add(Enums.VATTaxationTypes.ExportSale);
		VATAvailableByOperation.Insert("ImplementationOfWorksServices", ArrayOfAvailable);
	EndIf;
	
	If FillParameters.OtherAssetSale Then
		ArrayOfAvailable = New Array;
		ArrayOfAvailable.Add(Enums.VATTaxationTypes.SaleIsSubjectToVAT);
		ArrayOfAvailable.Add(Enums.VATTaxationTypes.SaleIsNotSubjectToVAT);
		ArrayOfAvailable.Add(Enums.VATTaxationTypes.ExportSale);
		VATAvailableByOperation.Insert("OtherAssetSale", ArrayOfAvailable);
	EndIf;
	
	If FillParameters.ReturnablePackagingRedemptionByCustomer Then
		ArrayOfAvailable = New Array;
		ArrayOfAvailable.Add(Enums.VATTaxationTypes.SaleIsSubjectToVAT);
		ArrayOfAvailable.Add(Enums.VATTaxationTypes.SaleIsNotSubjectToVAT);
		VATAvailableByOperation.Insert("ReturnablePackagingRedemptionByCustomer", ArrayOfAvailable);
	EndIf;
	
	If FillParameters.RedemptionOfGoodsByCustodian Then
		ArrayOfAvailable = New Array;
		ArrayOfAvailable.Add(Enums.VATTaxationTypes.SaleIsSubjectToVAT);
		ArrayOfAvailable.Add(Enums.VATTaxationTypes.SaleIsNotSubjectToVAT);
		VATAvailableByOperation.Insert("RedemptionOfGoodsByCustodian", ArrayOfAvailable);
	EndIf;
	
	If FillParameters.TransferToCommissionAgent Then
		ArrayOfAvailable = New Array;
		ArrayOfAvailable.Add(Enums.VATTaxationTypes.EmptyRef());
		VATAvailableByOperation.Insert("TransferToCommissionAgent", ArrayOfAvailable);
	EndIf;
	
	If FillParameters.ReportToMaterialProvider Then
		ArrayOfAvailable = New Array;
		ArrayOfAvailable.Add(Enums.VATTaxationTypes.SaleIsSubjectToVAT);
		ArrayOfAvailable.Add(Enums.VATTaxationTypes.SaleIsNotSubjectToVAT);
		ArrayOfAvailable.Add(Enums.VATTaxationTypes.ExportSale);
		VATAvailableByOperation.Insert("ReportToMaterialProvider", ArrayOfAvailable);
	EndIf;
	
	If FillParameters.ConsignmentReportFromCustomer Then
		ArrayOfAvailable = New Array;
		ArrayOfAvailable.Add(Enums.VATTaxationTypes.SaleIsSubjectToVAT);
		ArrayOfAvailable.Add(Enums.VATTaxationTypes.SaleIsNotSubjectToVAT);
		VATAvailableByOperation.Insert("ConsignmentReportFromCustomer", ArrayOfAvailable);
	EndIf;
	
	If FillParameters.ReturnOfGoodsFromCommissionAgent Then
		ArrayOfAvailable = New Array;
		ArrayOfAvailable.Add(Enums.VATTaxationTypes.EmptyRef());
		VATAvailableByOperation.Insert("ReturnOfGoodsFromCommissionAgent", ArrayOfAvailable);
	EndIf;
	
	If FillParameters.ReturnOfGoodsFromCustomer Then
		ArrayOfAvailable = New Array;
		ArrayOfAvailable.Add(Enums.VATTaxationTypes.SaleIsSubjectToVAT);
		ArrayOfAvailable.Add(Enums.VATTaxationTypes.SaleIsNotSubjectToVAT);
		ArrayOfAvailable.Add(Enums.VATTaxationTypes.ExportSale);
		VATAvailableByOperation.Insert("ReturnOfGoodsFromCustomer", ArrayOfAvailable);
	EndIf;
	
	If FillParameters.Retail_ Then
		ArrayOfAvailable = New Array;
		ArrayOfAvailable.Add(OrganizationAccountingParameters.TaxationOfRetailVAT);
		VATAvailableByOperation.Insert("Retail_", ArrayOfAvailable);
	EndIf;
	
	If FillParameters.PurchasingReportToConsignorPrincipal Then
		ArrayOfAvailable = New Array;
		ArrayOfAvailable.Add(Enums.VATTaxationTypes.SaleIsSubjectToVAT);
		ArrayOfAvailable.Add(Enums.VATTaxationTypes.SaleIsNotSubjectToVAT);
		VATAvailableByOperation.Insert("PurchasingReportToConsignorPrincipal", ArrayOfAvailable);
	EndIf;
	
	If FillParameters.TransferToStorage Then
		ArrayOfAvailable = New Array;
		ArrayOfAvailable.Add(Enums.VATTaxationTypes.EmptyRef());
		VATAvailableByOperation.Insert("TransferToStorage", ArrayOfAvailable);
	EndIf;
	
	If FillParameters.ReturnFromStorage Then
		ArrayOfAvailable = New Array;
		ArrayOfAvailable.Add(Enums.VATTaxationTypes.EmptyRef());
		VATAvailableByOperation.Insert("ReturnFromStorage", ArrayOfAvailable);
	EndIf;
	
	// Not available by settings
	UnavailableVATTaxes = New Array;
	If Not InformationSecurityAccountingParameters.SalesForExport Or FillParameters.ThisIsOperationBetweenOrganizations Then
		UnavailableVATTaxes.Add(Enums.VATTaxationTypes.ExportSale);
	EndIf;
	
	VATAccountingLocalization.SupplementAvailableSalesThatAreNotAvailableForVATTaxationByParameters(
		VATAvailableByOperation, UnavailableVATTaxes, FillParameters);
	
	// We will take into account the availability of the operation
	AvailableVATTaxes = New Array;
	For Each KeyAndValue In VATAvailableByOperation Do
		CommonClientServer.SupplementArray(AvailableVATTaxes, KeyAndValue.Value, True);
	EndDo;
	ApplicableTypesOfVATTaxation = ApplicableTypesOfVATTaxation(True, False).UnloadValues();
	TMCommonUseClientServer.IntersectionOfArrays(AvailableVATTaxes, ApplicableTypesOfVATTaxation);
	
	// We will take into account the unavailability of the accounting settings of the organization
	AvailableVATTaxes = CommonClientServer.ArraysDifference(AvailableVATTaxes, UnavailableVATTaxes);
	
	Return AvailableVATTaxes;
	
EndFunction

#EndRegion

#Region JobsForMonthEndClosing

//Parameters:
// Query - String
//
//Returns:
// Map of String
//
Function MatchingRequestsToControlRegisters(Query) Export
	Query.SetParameter("UseSeparateFAAccountingByTaxation",
		GetFunctionalOption("UseSeparateFAAccountingByTaxation"));
	Query.SetParameter("TypesOfResidueEntryDocuments", LocalAccntingServer.BalanceEntryDocuments());
	MatchingQueryTexts = New Map();
	MatchingQueryTexts.Insert("FACostUpdate", QueryTextFACost(Query));
	MatchingQueryTexts.Insert("IACostUpdate", QueryTextIACost(Query));
	MatchingQueryTexts.Insert("VATInvoicedUpdate", QueryTextVATInvoiced(Query));
	MatchingQueryTexts.Insert("ChangesTableRevenueAndCOGS", QueryTextRevenueAndCOGS(Query));
	MatchingQueryTexts.Insert("ChangesTableLotsVATForAllocation", QueryTextLotsVATForAllocation(Query));
	MatchingQueryTexts.Insert("ChangesTableRecordsCounterpartyIncomeExpenses", QueryTextRecordsCounterpartyIncomeExpenses(Query));
	MatchingQueryTexts.Insert("ChangesTableRevenueServicesAndAssets", QueryTextRevenueServicesAndAssets(Query));
	
	VATAccountingLocalization.AddMatchingRequestsToControlRegisters(MatchingQueryTexts, Query);
	
	Return MatchingQueryTexts;
	
EndFunction

Function QueryTextFACost(Query)
	
	QueryText =
	"SELECT DISTINCT
	|	BEGINOFPERIOD(Table.Period, MONTH) AS Month,
	|	VALUE(Catalog.MonthEndClosingOperations.VATAllocation) AS Operation,
	|	Table.Organization AS Organization,
	|	Table.Document AS Document
	|FROM
	|	FACostUpdate AS Table
	|WHERE
	|	&UseSeparateFAAccountingByTaxation
	|	AND NOT VALUETYPE(Table.Document) IN (TYPE(Document.VATAllocation), &TypesOfResidueEntryDocuments)
	|	AND NOT &RegisteredRecordsAreRecordedWhenCalculatingCostOfVNA
	|	AND NOT &RegisteredRecordsAreRecordedWhenUpdatingRegisteredRecordsFA
	|	AND NOT &RegisteredRecordsAreRecordedWhenFormationOfVNARegisteredRecordsIsDelayed
	|
	|UNION
	|
	|SELECT DISTINCT
	|	BEGINOFPERIOD(ENDOFPERIOD(Table.Period, QUARTER), MONTH) AS Month,
	|	VALUE(Catalog.MonthEndClosingOperations.VATAllocation) AS Operation,
	|	Table.Organization AS Organization,
	|	Table.Document AS Document
	|FROM
	|	FACostUpdate AS Table
	|WHERE
	|	&UseSeparateFAAccountingByTaxation
	|	AND NOT VALUETYPE(Table.Document) IN (TYPE(Document.VATAllocation), &TypesOfResidueEntryDocuments)
	|	AND NOT &RegisteredRecordsAreRecordedWhenCalculatingCostOfVNA
	|	AND NOT &RegisteredRecordsAreRecordedWhenUpdatingRegisteredRecordsFA
	|	AND NOT &RegisteredRecordsAreRecordedWhenFormationOfVNARegisteredRecordsIsDelayed
	|";

	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(QueryText);
	
	Return StructureOfQueryTexts_
	
EndFunction

Function QueryTextIACost(Query)
	
	QueryText = 
	"SELECT DISTINCT
	|	BEGINOFPERIOD(Table.Period, MONTH) AS Month,
	|	VALUE(Catalog.MonthEndClosingOperations.VATAllocation) AS Operation,
	|	Table.Organization AS Organization,
	|	Table.Document AS Document
	|FROM
	|	IACostUpdate AS Table
	|WHERE
	|	&UseSeparateFAAccountingByTaxation
	|	AND NOT VALUETYPE(Table.Document) IN (TYPE(Document.VATAllocation), &TypesOfResidueEntryDocuments)
	|	AND NOT &RegisteredRecordsAreRecordedWhenCalculatingCostOfVNA
	|	AND NOT &RegisteredRecordsAreRecordedWhenFormationOfVNARegisteredRecordsIsDelayed
	|
	|UNION
	|
	|SELECT DISTINCT
	|	BEGINOFPERIOD(ENDOFPERIOD(Table.Period, QUARTER), MONTH) AS Month,
	|	VALUE(Catalog.MonthEndClosingOperations.VATAllocation) AS Operation,
	|	Table.Organization AS Organization,
	|	Table.Document AS Document
	|FROM
	|	IACostUpdate AS Table
	|WHERE
	|	&UseSeparateFAAccountingByTaxation
	|	AND NOT VALUETYPE(Table.Document) IN (TYPE(Document.VATAllocation), &TypesOfResidueEntryDocuments)
	|	AND NOT &RegisteredRecordsAreRecordedWhenCalculatingCostOfVNA
	|	AND NOT &RegisteredRecordsAreRecordedWhenFormationOfVNARegisteredRecordsIsDelayed
	|";
	
	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(QueryText);
	
	Return StructureOfQueryTexts_
	
EndFunction

Function QueryTextVATInvoiced(Query)
	
	QueryText =
	"SELECT DISTINCT
	|	BEGINOFPERIOD(VATAllocation.Date, MONTH) AS Month,
	|	VALUE(Catalog.MonthEndClosingOperations.VATAllocation) AS Operation,
	|	Table.Organization AS Organization,
	|	UNDEFINED AS Document
	|FROM
	|	VATInvoicedUpdate AS Table
	|	INNER JOIN Document.VATAllocation AS VATAllocation
	|		ON VATAllocation.Organization = Table.Organization
	|		AND VATAllocation.Date > ENDOFPERIOD(Table.Period, MONTH)
	|		AND VATAllocation.Date = ENDOFPERIOD(VATAllocation.Date, QUARTER)
	|		AND VATAllocation.Posted
	|WHERE
	|	&UseSeparateFAAccountingByTaxation
	|	AND Table.Event = VALUE(Enum.EventsChargedVAT.VATAcceptedForDeduction)
	|	AND TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				AccumulationRegister.LotsVATForAllocation AS T
	|			WHERE
	|				T.Period > ENDOFPERIOD(Table.Period, MONTH)
	|				AND T.ExpenseReceiptDocument = Table.TaxInvoice)";

	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(QueryText);
	
	Return StructureOfQueryTexts_
	
EndFunction

Function QueryTextRevenueAndCOGS(Query)
	
	QueryText = 
	"SELECT DISTINCT
	|	BEGINOFPERIOD(Table.Period, MONTH) AS Month,
	|	VALUE(Catalog.MonthEndClosingOperations.VATAllocation) AS Operation,
	|	Table.AccountingDimensionByPartners.Organization AS Organization,
	|	Table.Recorder AS Document
	|FROM
	|	ChangesTableRevenueAndCOGS AS Table
	|	INNER JOIN
	|		Document.VATAllocation AS VATAllocation
	|	ON
	|		ENDOFPERIOD(Table.Period, MONTH) = ENDOFPERIOD(VATAllocation.Date, MONTH)
	|		AND Table.AccountingDimensionByPartners.Organization = VATAllocation.Organization
	|		AND NOT VATAllocation.Patch
	|		AND VATAllocation.Posted
	|
	|UNION
	|
	|SELECT DISTINCT
	|	BEGINOFPERIOD(ENDOFPERIOD(Table.Period, QUARTER), MONTH) AS Month,
	|	VALUE(Catalog.MonthEndClosingOperations.VATAllocation) AS Operation,
	|	Table.AccountingDimensionByPartners.Organization AS Organization,
	|	Table.Recorder AS Document
	|FROM
	|	ChangesTableRevenueAndCOGS AS Table
	|	INNER JOIN
	|		Document.VATAllocation AS VATAllocation
	|	ON
	|		ENDOFPERIOD(Table.Period, QUARTER) = ENDOFPERIOD(VATAllocation.Date, MONTH)
	|		AND Table.AccountingDimensionByPartners.Organization = VATAllocation.Organization
	|		AND NOT VATAllocation.Patch
	|		AND VATAllocation.Posted
	|";
	
	VATAccountingLocalization.AddTextOfRequestRevenueAndCostOfSales(QueryText, Query);
	
	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(QueryText);
	Return StructureOfQueryTexts_
EndFunction

Function QueryTextLotsVATForAllocation(Query)
	
	TempTablesQueryText =
	"SELECT
	|	ChangesTableLotsVATForAllocation.Organization AS Organization,
	|	CASE 
	|		WHEN Companies.RegistrationDate = DATETIME(1, 1, 1)
	|			THEN FALSE
	|		ELSE BEGINOFPERIOD(Companies.RegistrationDate, MONTH) = BEGINOFPERIOD(ChangesTableLotsVATForAllocation.Period, MONTH)
	|			AND DATEDIFF(ENDOFPERIOD(ChangesTableLotsVATForAllocation.Period, QUARTER), Companies.RegistrationDate, DAY) <= 10 
	|	END AS ThisIsExtendedPeriod
	|INTO TTOperationIsInExtendedPeriod
	|FROM
	|	ChangesTableLotsVATForAllocation AS ChangesTableLotsVATForAllocation
	|		LEFT JOIN Catalog.Companies AS Companies
	|		ON (Companies.Ref = ChangesTableLotsVATForAllocation.Organization)
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Companies.Ref AS Organization,
	|	Companies.ParentCompany AS ParentCompany,
	|	CASE
	|		WHEN TTOperationIsInExtendedPeriod.Organization IS NULL
	|			THEN ChangingParties.Period
	|		ELSE DATEADD(ENDOFPERIOD(ChangingParties.Period, QUARTER), SECOND, 1)
	|	END AS Period,
	|	ChangingParties.Recorder AS Recorder,
	|	ChangingParties.CostAllocationOptionLocal AS CostAllocationOptionLocal,
	|	MAX(VATAccountingSettings.Period) AS AccountingPolicyPeriod
	|INTO PeriodsForSettingUpVATAccountingForNDSKByDistribution
	|FROM
	|	ChangesTableLotsVATForAllocation AS ChangingParties
	|	INNER JOIN
	|		Catalog.Companies AS Companies
	|	ON
	|		Companies.Ref = ChangingParties.Organization
	|	LEFT JOIN
	|		InformationRegister.VATAccountingSettings AS VATAccountingSettings
	|	ON
	|		Companies.ParentCompany = VATAccountingSettings.Organization
	|		AND ChangingParties.Period >= VATAccountingSettings.Period
	|	LEFT JOIN TTOperationIsInExtendedPeriod AS TTOperationIsInExtendedPeriod
	|		
	|	ON ChangingParties.Organization = TTOperationIsInExtendedPeriod.Organization
	|		AND (TTOperationIsInExtendedPeriod.ThisIsExtendedPeriod)
	|WHERE
	|	NOT VALUETYPE(ChangingParties.Recorder) IN (&TypesOfResidueEntryDocuments)
	|
	|GROUP BY
	|	Companies.Ref,
	|	Companies.ParentCompany,
	|	CASE
	|		WHEN TTOperationIsInExtendedPeriod.Organization IS NULL
	|			THEN ChangingParties.Period
	|		ELSE DATEADD(ENDOFPERIOD(ChangingParties.Period, QUARTER), SECOND, 1)
	|	END,
	|	ChangingParties.Recorder,
	|	ChangingParties.CostAllocationOptionLocal
	|	
	|INDEX BY
	|	Organization,
	|	Period
	|
	|;";
	
	TextDestroyW = "PeriodsForSettingUpVATAccountingForNDSKByDistribution, TTOperationIsInExtendedPeriod";
	
	QueryText = 
	"SELECT DISTINCT
	|	CASE
	|		WHEN ISNULL(VATAccountingSettings.FrequencyOfVATAllocation, VALUE(Enum.Periodicity.QUARTER))
	|				 = VALUE(Enum.Periodicity.QUARTER) THEN
	|			BEGINOFPERIOD(ENDOFPERIOD(Table.Period, QUARTER), MONTH)
	|		WHEN VATAccountingSettings.FrequencyOfVATAllocation = VALUE(Enum.Periodicity.MONTH) THEN
	|			BEGINOFPERIOD(Table.Period,MONTH)
	|	END AS Month,
	|	VALUE(Catalog.MonthEndClosingOperations.VATAllocation) AS Operation,
	|	Table.Organization AS Organization,
	|	Table.Recorder AS Document
	|FROM
	|	PeriodsForSettingUpVATAccountingForNDSKByDistribution AS Table
	|	LEFT JOIN
	|		InformationRegister.VATAccountingSettings AS VATAccountingSettings
	|	ON
	|		Table.ParentCompany = VATAccountingSettings.Organization
	|		AND Table.AccountingPolicyPeriod = VATAccountingSettings.Period
	|
	|UNION
	|
	|SELECT DISTINCT
	|	CASE
	|		WHEN TTOperationIsInExtendedPeriod.Organization IS NULL
	|			THEN ENDOFPERIOD(Table.Period, MONTH)
	|		ELSE ENDOFPERIOD(DATEADD(ENDOFPERIOD(Table.Period, MONTH), SECOND, 1), MONTH)
	|	END AS Month,
	|	VALUE(Catalog.MonthEndClosingOperations.VATAllocation) AS Operation,
	|	Table.Organization AS Organization,
	|	Table.Recorder AS Document
	|FROM
	|	ChangesTableLotsVATForAllocation AS Table
	|	LEFT JOIN
	|		Document.VATAllocation AS VATAllocation
	|	ON
	|		ENDOFPERIOD(Table.Period, MONTH) = ENDOFPERIOD(VATAllocation.Date, MONTH)
	|		AND Table.Organization = VATAllocation.Organization
	|		AND NOT VATAllocation.Patch
	|		AND VATAllocation.Posted
	|	LEFT JOIN
	|		InformationRegister.VATAccountingSettings AS VATAccountingSettings
	|	ON
	|		Table.Organization.ParentCompany = VATAccountingSettings.Organization
	|		AND Table.Period >= VATAccountingSettings.Period
	|	LEFT JOIN TTOperationIsInExtendedPeriod AS TTOperationIsInExtendedPeriod
	|	
	|	ON Table.Organization = TTOperationIsInExtendedPeriod.Organization
	|		AND (TTOperationIsInExtendedPeriod.ThisIsExtendedPeriod)
	|WHERE
	|	ISNULL(Table.CostAllocationOptionLocal, UNDEFINED) = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|	AND (ISNULL(VATAccountingSettings.AllocateVATToCapitalExpenditureInReceiptMonth, FALSE)
	|			AND Table.VATActivityType = VALUE(Enum.VATTaxationTypes.FixedAssetsCommissioning)
	|		OR NOT VATAllocation.Ref IS NULL)
	|	AND NOT VALUETYPE(Table.Recorder) IN (&TypesOfResidueEntryDocuments)
	|";

	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(QueryText,
		TempTablesQueryText,
		TextDestroyW);
	
	Return StructureOfQueryTexts_
	
EndFunction

Function QueryTextRecordsCounterpartyIncomeExpenses(Query)

	QueryText = 
	"SELECT DISTINCT
	|	BEGINOFPERIOD(Table.Period, MONTH) AS Month,
	|	VALUE(Catalog.MonthEndClosingOperations.VATAllocation) AS Operation,
	|	Table.Organization AS Organization,
	|	Table.Recorder AS Document
	|FROM
	|	ChangesTableRecordsCounterpartyIncomeExpenses AS Table
	|	INNER JOIN
	|		Document.VATAllocation AS VATAllocation
	|	ON
	|		ENDOFPERIOD(Table.Period, MONTH) = ENDOFPERIOD(VATAllocation.Date, MONTH)
	|		AND Table.Organization = VATAllocation.Organization
	|		AND NOT VATAllocation.Patch
	|		AND VATAllocation.Posted
	|
	|UNION
	|
	|SELECT DISTINCT
	|	BEGINOFPERIOD(ENDOFPERIOD(Table.Period, QUARTER), MONTH) AS Month,
	|	VALUE(Catalog.MonthEndClosingOperations.VATAllocation) AS Operation,
	|	Table.Organization AS Organization,
	|	Table.Recorder AS Document
	|FROM
	|	ChangesTableRecordsCounterpartyIncomeExpenses AS Table
	|	INNER JOIN
	|		Document.VATAllocation AS VATAllocation
	|	ON
	|		ENDOFPERIOD(Table.Period, QUARTER) = ENDOFPERIOD(VATAllocation.Date, MONTH)
	|		AND Table.Organization = VATAllocation.Organization
	|		AND NOT VATAllocation.Patch
	|		AND VATAllocation.Posted
	|";
	
	VATAccountingLocalization.SupplementTextOfMovementRequestCounterpartyIncomeExpenses(QueryText);
	
	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(QueryText);
	
	Return StructureOfQueryTexts_
	
EndFunction

Function QueryTextRevenueServicesAndAssets(Query)

	QueryText = 
	"SELECT DISTINCT
	|	BEGINOFPERIOD(Table.Period, MONTH) AS Month,
	|	VALUE(Catalog.MonthEndClosingOperations.VATAllocation) AS Operation,
	|	Table.Organization AS Organization,
	|	Table.Recorder AS Document
	|FROM
	|	ChangesTableRevenueServicesAndAssets AS Table
	|	INNER JOIN
	|		Document.VATAllocation AS VATAllocation
	|	ON
	|		ENDOFPERIOD(Table.Period, MONTH) = ENDOFPERIOD(VATAllocation.Date, MONTH)
	|		AND Table.Organization = VATAllocation.Organization
	|		AND NOT VATAllocation.Patch
	|		AND VATAllocation.Posted
	|
	|UNION
	|
	|SELECT DISTINCT
	|	BEGINOFPERIOD(ENDOFPERIOD(Table.Period, QUARTER), MONTH) AS Month,
	|	VALUE(Catalog.MonthEndClosingOperations.VATAllocation) AS Operation,
	|	Table.Organization AS Organization,
	|	Table.Recorder AS Document
	|FROM
	|	ChangesTableRevenueServicesAndAssets AS Table
	|	INNER JOIN
	|		Document.VATAllocation AS VATAllocation
	|	ON
	|		ENDOFPERIOD(Table.Period, QUARTER) = ENDOFPERIOD(VATAllocation.Date, MONTH)
	|		AND Table.Organization = VATAllocation.Organization
	|		AND NOT VATAllocation.Patch
	|		AND VATAllocation.Posted
	|";
	
	VATAccountingLocalization.RequestTextOtherRevenue(QueryText);
	
	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(QueryText);
	
	Return StructureOfQueryTexts_
	
EndFunction

#EndRegion

#Region JobsForGeneratingVATRecords

Procedure GenerateTasksBasedOnVATDistributionDocuments(ReferencesArrray) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	BEGINOFPERIOD(Lots.Period, MONTH) AS Month,
	|	Lots.Organization AS Organization,
	|	Lots.ExpenseReceiptDocument AS TaxInvoice
	|FROM
	|	AccumulationRegister.LotsVATForAllocation AS Lots
	|WHERE
	|	Lots.CorVATActivityTypes <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|	AND Lots.VATActivityType <> Lots.CorVATActivityTypes
	|	AND Lots.Recorder IN(&Ref)
	|
	|UNION
	|
	|SELECT DISTINCT
	|	BEGINOFPERIOD(VATInvoiced.Period, MONTH) AS Month,
	|	VATInvoiced.Organization AS Organization,
	|	VATInvoiced.TaxInvoice AS TaxInvoice
	|FROM
	|	AccumulationRegister.VATInvoiced AS VATInvoiced
	|WHERE
	|	VATInvoiced.Recorder IN (&Ref)
	|	AND VATInvoiced.PeriodEndTransaction";
	
	Query.SetParameter("Ref", ReferencesArrray);
	
	Selection = Query.Execute().Select();
	InformationRegisters.JobsForGeneratingVATRecords.CreateRegisterEntriesBasedOnSampleData(Selection, , False);
	
EndProcedure

Procedure GenerateTasksBasedOnDocumentsInvoiceAdvancePayment(ReferencesArrray) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	BEGINOFPERIOD(Operation.Date, MONTH) AS Month,
	|	Operation.Organization AS Organization,
	|	Operation.DocumentBasis AS TaxInvoice
	|FROM
	|	Document.IssuedTaxInvoicePrepayment AS Operation
	|WHERE
	|	Operation.Ref IN(&Ref)
	|";
	
	Query.SetParameter("Ref", ReferencesArrray);
	
	Selection = Query.Execute().Select(QueryResultIteration.Linear);
	
	InformationRegisters.JobsForGeneratingVATRecords.CreateRegisterEntriesBasedOnSampleData(Selection, , False);
	
EndProcedure

Procedure GenerateTasksBasedOnDocumentsInvoiceReceivedAdvance(ReferencesArrray) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	BEGINOFPERIOD(Operation.Date, MONTH) AS Month,
	|	Operation.Organization AS Organization,
	|	Operation.DocumentBasis AS TaxInvoice
	|FROM
	|	Document.ReceivedTaxInvoicePrepayment AS Operation
	|WHERE
	|	Operation.Ref IN(&Ref)
	|";
	
	Query.SetParameter("Ref", ReferencesArrray);
	
	Selection = Query.Execute().Select(QueryResultIteration.Linear);
	
	InformationRegisters.JobsForGeneratingVATRecords.CreateRegisterEntriesBasedOnSampleData(Selection, , False);
	
EndProcedure

#EndRegion

#Region Other

//Returns:
// Array of MetadataObject
Function IncomingMechanismData() Export
	
	IncomingData = New Array;
	IncomingData.Add(Metadata.AccumulationRegisters.VATInvoiced);
	IncomingData.Add(Metadata.AccumulationRegisters.VATPrepaymentsToVendor);
	IncomingData.Add(Metadata.AccumulationRegisters.VATPrepaymentsFromCustomer);
	IncomingData.Add(Metadata.Documents.IssuedTaxInvoicePrepayment);
	IncomingData.Add(Metadata.Documents.ReceivedTaxInvoicePrepayment);
	
	VATAccountingLocalization.SupplementIncomingDataForRoutineOperation(IncomingData);
	
	Return IncomingData;
	
EndFunction

//Returns:
// Array of EnumRef.InventoryTypes
Function InventoryTypesOwn() Export
	
	InventoryTypesOwn = Enums.InventoryTypes.InventoryTypesOwn();
	InventoryTypesOwn.Add(Enums.InventoryTypes.EmptyRef());
	
	Return InventoryTypesOwn;
	
EndFunction

//Returns:
// Array of EnumRef.ItemsTypes
Function ProductProductTypes() Export
	
	ItemsTypes = New Array();
	ItemsTypes.Add(Enums.ItemsTypes.OwnGoods);
	ItemsTypes.Add(Enums.ItemsTypes.ReusablePackage);
	
	Return ItemsTypes;
	
EndFunction

//Returns:
// Array of EnumRef.ItemsTypes
Function TypesOfProductsServiceWork() Export
	
	ItemsTypes = New Array();
	ItemsTypes.Add(Enums.ItemsTypes.OperationService);
	ItemsTypes.Add(Enums.ItemsTypes.Work_5);
	
	Return ItemsTypes;
	
EndFunction

//Parameters:
// ParameterKey_ - See VATAccountingERP.FillInSalesVATTaxation
// ParameterValues - See VATAccountingERP.FillInSalesVATTaxation
// CachedParameterValues - See VATAccountingERP.FillInSalesVATTaxation
//Returns:
// Arbitrary
Function ChangedParameters(ParameterKey_, ParameterValues, CachedParameterValues) Export
	
	Result = New Structure();
	
	If TypeOf(CachedParameterValues) <> Type("Structure") Then
		Return Result;
	EndIf;
	
	PastParameterValues = Undefined;
	If Not CachedParameterValues.Property(ParameterKey_, PastParameterValues) Then
		Return Result;
	EndIf;
	
	If TMCommonUseClientServer.StructuresAreEqual(ParameterValues, PastParameterValues) Then
		Return Result;
	EndIf;
	
	For Each KeyAndValue In ParameterValues Do
		If ValueIsFilled(KeyAndValue.Value)
			And KeyAndValue.Value <> PastParameterValues[KeyAndValue.Key] Then
			Result.Insert(KeyAndValue.Key);
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

Procedure UpdateCachedParameterValues(ParameterKey_, ParameterValues, CachedParameterValues) Export
	
	If TypeOf(CachedParameterValues) <> Type("Structure") Then
		CachedParameterValues = New Structure();
	EndIf;
	
	If Not CachedParameterValues.Property(ParameterKey_) Then
		CachedParameterValues.Insert(ParameterKey_, ParameterValues);
	Else
		FillPropertyValues(CachedParameterValues[ParameterKey_], ParameterValues);
	EndIf;
	
EndProcedure

Procedure ConfigureJointSelectionOfContractorsOrganizations(Item, Counterparty = Null) Export

	If GetFunctionalOption("UseCustomerInvoiceIntercompany") Then
		If Counterparty = Undefined Then
			Counterparty = Catalogs.Counterparties.EmptyRef();
		EndIf;
		NewArray = New Array();
		NewArray.Add(New ChoiceParameter("SelectionOfCounterpartiesAndOrganizations", True));
		Item.ChoiceParameters = New FixedArray(NewArray);
 	Else
		Item.TypeRestriction = New TypeDescription("CatalogRef.Counterparties");	
		Item.ChooseType = False;
	EndIf;
	
EndProcedure

// The VAT rate field in the request text is processed and conditions for selecting the calculated rate are added
// 
// Parameters:
// 	Query - Query -
// 	BidField - String - Full path to the bid field.
//
Procedure SelectEstimatedVATRate(Query, BidField) Export
	
	TextPattern = StrTemplate("CASE
	|		WHEN ISNULL(%1.Rate1, 0) > 0
	|			AND %1.CalculatedRate = FALSE
	|			THEN %1.RelevantCalculatedRate
	|		ELSE %1
	|	END", BidField);
	
	Query.Text = StrReplace(Query.Text, BidField, TextPattern);
	
EndProcedure

// Returns the value of the Reflect YY flag in the Input document.
// 
// Parameters:
// 	DocumentBasis - DocumentRef.SourceDocument - the calculation document in the Input of the units document
//
// Returns:
// 	Boolean
//
Function EnteringResiduesInVU(DocumentBasis) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	EnteringBalancesSettlementsWithPartners.Ref.RecordInMA RecordInMA
	|FROM
	|	Document.OBEntryARAP.PartnersARAPAccounting AS EnteringBalancesSettlementsWithPartners
	|WHERE
	|	EnteringBalancesSettlementsWithPartners.DocumentOfARAPAccounting = &DocumentBasis
	|	AND EnteringBalancesSettlementsWithPartners.Ref.Posted
	|";
	
	Query.SetParameter("DocumentBasis", DocumentBasis);
	
	RecordInMA = False;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		RecordInMA = Selection.RecordInMA;
	EndDo;
	
	Return RecordInMA
	
EndFunction

//Returns:
// Number
Function NumberOfTasksForVATCalculation() Export

	ParameterValues = Constants.MonthEndClosingSettings.CreateValueManager().SetValuesOfOperationParameters(
  							Catalogs.MonthEndClosingOperations.PostingGenerationInVATAccounting);
							
	Return ParameterValues.NumberOfTasksForVATCalculation;

EndFunction

//Returns:
// Number
Function RoundingErrorWriteOffThreshold() Export

	ParameterValues = Constants.MonthEndClosingSettings.CreateValueManager().SetValuesOfOperationParameters(
  							Catalogs.MonthEndClosingOperations.PostingGenerationInVATAccounting);
							
	Return ParameterValues.RoundingErrorWriteOffThreshold;

EndFunction

// Determines whether the Operation is in the extended tax period.
//
// Parameters:
//   Organization - CatalogRef.Companies - The company to check
//   DateOfTransaction - Date - 
//   RegistrationDate - Date - date of registration of the company
//
// Returns:
//   Boolean - True if the company is in an extended period
//
Function OperationIsInExtendedPeriod(Organization, DateOfTransaction, RegistrationDate = '00010101') Export
	
	ThisIsExtendedPeriod = True;
	
	
	Return ThisIsExtendedPeriod;
	
EndFunction

#EndRegion

#Region RoutineVATOperation

// Generates purchase and sales book entries.
// 
// Parameters:
// 	 EndOfPeriod - Date - The period for which the reflection should be performed
// 	 CompanyArray - Array of CatalogRef.Companies, Undefined - The organization, which is necessary to form the record books.
// 																If Undefined, then for all organizations.
// 	 ArrayOfInvoices_ - Array of DocumentRef, Undefined - Invoices (receipt documents) for which you need to create book entries.
// 																If Undefined, then for all invoices.
//
Procedure CompleteTasksForGeneratingVATRegisteredRecords(EndOfPeriod, CompanyArray = Undefined, ArrayOfInvoices_ = Undefined) Export
	
	SetPrivilegedMode(True);
	
	CheckBlockingIncomingDataWhenUpdatingInformationSecurity();
	
	TaskNumberBeforeCalculation = InformationRegisters.JobsForGeneratingVATRecords.IncreaseTaskNumber();
	
	Month = MonthToCalculate(EndOfPeriod, TaskNumberBeforeCalculation, CompanyArray, ArrayOfInvoices_);
	While Month <> Undefined Do
		
		CalculationParameters = New Structure;
		CalculationParameters.Insert("JobNumber",                        TaskNumberBeforeCalculation);
		CalculationParameters.Insert("BeginOfPeriod",                       BegOfMonth(Month));
		CalculationParameters.Insert("EndOfPeriod",                        EndOfMonth(Month));
		CalculationParameters.Insert("CompanyArray",                   CompanyArray);
		CalculationParameters.Insert("ArrayOfInvoices_",                  ArrayOfInvoices_);
		CalculationParameters.Insert("SettingsTable",                     New ValueTable);
		CalculationParameters.Insert("RoundingErrorWriteOffThreshold", RoundingErrorWriteOffThreshold());
		CalculationParameters.Insert("ISFBeginningOfPeriod",                    Undefined);
		CalculationParameters.Insert("ISFEndOfPeriod",                     Undefined);
		CalculationParameters.Insert("ArrayOfRegisterMeasurements",             Undefined);
		
		While GetJobs(CalculationParameters) Do
			BeginTransaction();
			Try
				PerformCalculationWithTimeMeasurement(CalculationParameters);
				If Not Common.FileInfobase() Then
					BlockTaskRegister(CalculationParameters);
				EndIf;
				FixResult(CalculationParameters);
				CommitTransaction();
				
			Except
				
				RollbackTransaction();
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Không thể hoàn thành do %1';
							|ru = 'Не удалось выполнить по причине %1';
							|en = 'Cannot execute. Reason: %1'; fa = 'Cannot execute. Reason: %1';
							|it = 'Non è stato possibile eseguire il comando a causa di %1';
							|pl = 'Nie udało się wykonać z powodu %1';
							|tr = '%1 nedeniyle başarısız oldu'"),
						DetailErrorDescription(ErrorInfo()));
						
				WriteLogEvent(
					NStr("vi = 'Tạo bản ghi kết chuyển theo Thuế GTGT.';
						|ru = 'Формирование движений по НДС.';
						|en = 'Generation of VAT records.'; fa = 'Generation of VAT records.';
						|it = 'Generazione di movimenti IVA.';
						|pl = 'Formowanie przepływów wg VAT.';
						|tr = 'KDV kayıtlarını oluşturma.'", Common.DefaultLanguageCode()), 
					EventLogLevel.Error, , , MessageText); 
					
				Raise MessageText;
				
			EndTry;
		EndDo;
		
		Month = MonthToCalculate(EndOfPeriod, TaskNumberBeforeCalculation, CompanyArray, ArrayOfInvoices_);
		
	EndDo;
	
EndProcedure

Procedure BlockTaskRegister(CalculationParameters)
	
	Block = New DataLock;
	
	LockItem = Block.Add("InformationRegister.JobsForGeneratingVATRecords");
	LockItem.SetValue("JobNumber", New Range(Undefined, CalculationParameters.JobNumber));
	
	LockSource = New ValueTable;
	LockSource.Columns.Add("Organization", New TypeDescription("CatalogRef.Companies"));
	LockSource.Columns.Add("TaxInvoice", New TypeDescription(Documents.AllRefsType().Types()));
	
	If CalculationParameters.ArrayOfInvoices_ <> Undefined Then
		LockSource.LoadColumn(CalculationParameters.ArrayOfInvoices_, "TaxInvoice");
		LockItem.DataSource = LockSource;
		LockItem.UseFromDataSource("TaxInvoice", "TaxInvoice");
	EndIf;
	If CalculationParameters.CompanyArray <> Undefined Then
		If TypeOf(CalculationParameters.CompanyArray) = Type("ValueList") Then
			LockSource.LoadColumn(CalculationParameters.CompanyArray.UnloadValues(), "Organization");
		ElsIf TypeOf(CalculationParameters.CompanyArray) = Type("CatalogRef.Companies") Then
			LockSource.LoadColumn(CommonClientServer.ValueInArray(CalculationParameters.CompanyArray), "Organization");
		Else
			LockSource.LoadColumn(CalculationParameters.CompanyArray, "Organization");
		EndIf;
		LockItem.DataSource = LockSource;
		LockItem.UseFromDataSource("Organization", "Organization");
	EndIf;
	
	LockItem.Mode = DataLockMode.Exclusive;
	
	Block.Lock();
	
EndProcedure

Procedure PerformCalculationWithTimeMeasurement(CalculationParameters)
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("VATAccounting.FormationOfRecordsOfBooksOfPurchasesAndSalesOnAcquiredValues");
	
	Query = New Query;
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.Text =
	"SELECT
	|	COUNT(*) AS JobsCount
	|FROM
	|	Jobs";
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		JobsCount = Selection.JobsCount;
	Else
		JobsCount = 0;
	EndIf;
	
	Query.Text =
	"SELECT DISTINCT
	|	T.Organization
	|FROM
	|	Jobs AS T";
	CalculationParameters.CompanyArray = Query.Execute().Unload().UnloadColumn("Organization");
	CalculationParameters.SettingsTable = VATAccountingSettingsForOrganizations(CalculationParameters.CompanyArray, CalculationParameters.EndOfPeriod);
	
	PerformTheCalculation(CalculationParameters);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, JobsCount);
	
EndProcedure

Procedure PerformTheCalculation(CalculationParameters)
	
	GetDocumentsStorno(CalculationParameters);
	CreateExtensionTableForARAPTransactions(CalculationParameters);
	
	GenerateVATSubmitted(CalculationParameters);
	GenerateVATAdvancesReceived(CalculationParameters);
	GenerateVATAdvancesIssued(CalculationParameters);
	GenerateVATRegisteredRecords(CalculationParameters);
	CreateAdjustmentForDeductingVATForExpenses(CalculationParameters);
	ReturnDocumentsToInternationalAccounting(CalculationParameters);
	VATAccountingLocalization.PerformTheCalculation(CalculationParameters);
	
EndProcedure

Procedure GetDocumentsStorno(CalculationParameters)
	
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	DocumentsRegistry.Ref               AS Ref,
	|	DocumentsRegistry.IBDocumentDate      AS Period,
	|	DocumentsRegistry.ReversedDocument AS ReversedDocument,
	|	DocumentRegisterCorrectedDocument.IBDocumentDate AS DateOfDocumentBeingCorrected
	|INTO DocumentsStorno
	|FROM
	|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|	LEFT JOIN
	|		InformationRegister.DocumentsRegistry AS DocumentRegisterCorrectedDocument
	|	ON
	|		DocumentsRegistry.CorrectedDocument = DocumentRegisterCorrectedDocument.Ref
	|		AND NOT DocumentsRegistry.AdditionalRecord
	|		AND DocumentRegisterCorrectedDocument.Posted
	|WHERE
	|	DocumentsRegistry.IBDocumentDate BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND DocumentsRegistry.ReverseTransactionCorrection
	|	AND NOT DocumentsRegistry.AdditionalRecord
	|	AND DocumentsRegistry.Posted
	|	AND TRUE IN (
	|		SELECT TOP 1
	|			TRUE
	|		FROM
	|			AccumulationRegister.VATInvoiced AS VATInvoiced
	|			INNER JOIN
	|				Jobs AS Jobs
	|			ON
	|				VATInvoiced.Organization = Jobs.Organization
	|				AND VATInvoiced.TaxInvoice = Jobs.TaxInvoice
	|		WHERE
	|			VATInvoiced.Recorder = DocumentsRegistry.ReversedDocument
	|		
	|		UNION ALL
	|		
	|		SELECT TOP 1
	|			TRUE
	|		FROM
	|			AccumulationRegister.VATPrepaymentsToVendor AS VATPrepaymentsToVendor
	|			INNER JOIN
	|				Jobs AS Jobs
	|			ON
	|				VATPrepaymentsToVendor.Organization = Jobs.Organization
	|				AND VATPrepaymentsToVendor.DocumentPayments = Jobs.TaxInvoice
	|		WHERE
	|			VATPrepaymentsToVendor.Recorder = DocumentsRegistry.ReversedDocument
	|		
	|		UNION ALL
	|		
	|		SELECT TOP 1
	|			TRUE
	|		FROM
	|			AccumulationRegister.VATPrepaymentsFromCustomer AS VATPrepaymentsFromCustomer
	|			INNER JOIN
	|				Jobs AS Jobs
	|			ON
	|				VATPrepaymentsFromCustomer.Organization = Jobs.Organization
	|				AND VATPrepaymentsFromCustomer.DocumentPayments = Jobs.TaxInvoice
	|		WHERE
	|			VATPrepaymentsFromCustomer.Recorder = DocumentsRegistry.ReversedDocument
	|		)
	|
	|UNION
	|
	|SELECT DISTINCT
	|	DocumentsRegistry.Ref               AS Ref,
	|	DocumentsRegistry.IBDocumentDate      AS Period,
	|	VATInvoiced.TaxInvoice 		  AS ReversedDocument,
	|	DocumentRegisterCorrectedDocument.IBDocumentDate AS DateOfDocumentBeingCorrected
	|FROM
	|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|	LEFT JOIN
	|		InformationRegister.DocumentsRegistry AS DocumentRegisterCorrectedDocument
	|	ON
	|		DocumentsRegistry.CorrectedDocument = DocumentRegisterCorrectedDocument.Ref
	|		AND NOT DocumentsRegistry.AdditionalRecord
	|		AND DocumentRegisterCorrectedDocument.Posted
	|	INNER JOIN
	|		AccumulationRegister.VATInvoiced AS VATInvoiced
	|	ON
	|		VATInvoiced.Recorder = DocumentsRegistry.ReversedDocument
	|		AND (VATInvoiced.TaxInvoice REFS Document.SourceDocument
	|			OR VATInvoiced.TaxInvoice REFS Document.ElectronicTicketTransaction)
	|WHERE
	|	DocumentsRegistry.IBDocumentDate BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND DocumentsRegistry.ReverseTransactionCorrection
	|	AND NOT DocumentsRegistry.AdditionalRecord
	|	AND DocumentsRegistry.Posted
	|	AND TRUE IN (
	|		SELECT TOP 1
	|			TRUE
	|		FROM
	|			AccumulationRegister.VATInvoiced AS VATInvoiced
	|			INNER JOIN
	|				Jobs AS Jobs
	|			ON
	|				VATInvoiced.Organization = Jobs.Organization
	|				AND VATInvoiced.TaxInvoice = Jobs.TaxInvoice
	|		WHERE
	|			VATInvoiced.Recorder = DocumentsRegistry.ReversedDocument
	|			AND VATInvoiced.Recorder REFS Document.ExpenseReport)
	|
	|UNION
	|
	|SELECT DISTINCT
	|	DocumentsRegistry.Ref               AS Ref,
	|	DocumentsRegistry.IBDocumentDate      AS Period,
	|	DocumentsRegistry.ReversedDocument AS ReversedDocument,
	|	DocumentRegisterCorrectedDocument.IBDocumentDate AS DateOfDocumentBeingCorrected
	|FROM
	|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|	LEFT JOIN
	|		InformationRegister.DocumentsRegistry AS DocumentRegisterCorrectedDocument
	|	ON
	|		DocumentsRegistry.CorrectedDocument = DocumentRegisterCorrectedDocument.Ref
	|		AND NOT DocumentsRegistry.AdditionalRecord
	|		AND DocumentRegisterCorrectedDocument.Posted
	|WHERE
	|	DocumentsRegistry.IBDocumentDate BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND DocumentsRegistry.ReverseTransactionCorrection
	|	AND NOT DocumentsRegistry.AdditionalRecord
	|	AND DocumentsRegistry.Posted
	|	AND TRUE IN (
	|		SELECT TOP 1
	|			TRUE
	|		FROM
	|			AccumulationRegister.VATRegisterRecords AS VATRegisterRecords
	|			INNER JOIN
	|				Jobs AS Jobs
	|			ON
	|				VATRegisterRecords.Organization = Jobs.Organization
	|				AND VATRegisterRecords.TaxInvoice = Jobs.TaxInvoice
	|		WHERE
	|			VATRegisterRecords.Recorder = DocumentsRegistry.ReversedDocument)
	|
	|INDEX BY
	|	ReversedDocument
	|";
	
	Query.SetParameter("BeginOfPeriod",      CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",       CalculationParameters.EndOfPeriod);
	Query.SetParameter("CompanyArray",  CalculationParameters.CompanyArray);
	Query.SetParameter("AllCompanies",     Not ValueIsFilled(CalculationParameters.CompanyArray));
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.Execute();
	
EndProcedure

Procedure CreateExtensionTableForARAPTransactions(CalculationParameters)
	
	Query = New Query;
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.Text = 
	"SELECT
	|	Jobs.TaxInvoice AS DocumentPayments,
	|	DocumentCorrections.CorrectedDocument AS OriginalARAPTransactionDocument
	|INTO OriginalARAPTransactionDocuments
	|FROM
	|	Jobs AS Jobs
	|		INNER JOIN InformationRegister.DocumentCorrections AS DocumentCorrections
	|		ON Jobs.TaxInvoice = DocumentCorrections.Recorder
	|
	|INDEX BY
	|	DocumentPayments
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Jobs.Organization AS Organization,
	|	Jobs.TaxInvoice AS DocumentPayments,
	|	CASE
	|		WHEN IssuedTaxInvoicePrepayment.Ref IS NULL
	|		AND ReceivedTaxInvoicePrepayment.Ref IS NULL
	|			THEN ISNULL(OriginalARAPTransactionDocuments.OriginalARAPTransactionDocument, Jobs.TaxInvoice)
	|		ELSE Jobs.TaxInvoice
	|	END AS OriginalARAPTransactionDocument
	|INTO ExpansionOfARAPTransactionTable
	|FROM
	|	Jobs AS Jobs
	|		LEFT JOIN OriginalARAPTransactionDocuments AS OriginalARAPTransactionDocuments
	|		ON Jobs.TaxInvoice = OriginalARAPTransactionDocuments.DocumentPayments
	|		LEFT JOIN Document.ReceivedTaxInvoicePrepayment AS ReceivedTaxInvoicePrepayment
	|		ON Jobs.TaxInvoice = ReceivedTaxInvoicePrepayment.DocumentBasis
	|		AND ReceivedTaxInvoicePrepayment.Posted = TRUE
	|		LEFT JOIN Document.IssuedTaxInvoicePrepayment AS IssuedTaxInvoicePrepayment
	|		ON Jobs.TaxInvoice = IssuedTaxInvoicePrepayment.DocumentBasis
	|		AND IssuedTaxInvoicePrepayment.Posted = TRUE
	|
	|INDEX BY
	|	Organization,
	|	DocumentPayments,
	|	OriginalARAPTransactionDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP OriginalARAPTransactionDocuments";
	
	Query.Execute();
	
EndProcedure

Function MonthToCalculate(EndOfPeriod, JobNumber, CompanyArray, ArrayOfInvoices_)
	
	Month = Undefined;
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	BEGINOFPERIOD(Jobs.Month, Month) AS Month
	|FROM
	|	InformationRegister.JobsForGeneratingVATRecords AS Jobs
	|WHERE
	|	(Jobs.Month <= &EndOfPeriod OR &EndOfPeriod = DATETIME(1,1,1))
	|	AND Jobs.JobNumber <= &JobNumber
	|	AND (&AllCompanies OR Jobs.Organization IN (&CompanyArray))
	|	AND (&AllInvoices OR Jobs.TaxInvoice IN (&ArrayOfInvoices_))
	|
	|ORDER BY
	|	BEGINOFPERIOD(Jobs.Month, Month) ASC
	|";
	
	Query.SetParameter("EndOfPeriod",       ?(EndOfPeriod = EndOfMonth(CurrentSessionDate()),'00010101',EndOfPeriod));
	Query.SetParameter("CompanyArray",  CompanyArray);
	Query.SetParameter("AllCompanies",     Not ValueIsFilled(CompanyArray));
	Query.SetParameter("ArrayOfInvoices_", ArrayOfInvoices_);
	Query.SetParameter("AllInvoices",    Not ValueIsFilled(ArrayOfInvoices_));
	Query.SetParameter("JobNumber",       JobNumber);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Month = Selection.Month;
	EndIf;
	
	Return Month;
	
EndFunction

Function GetJobs(CalculationParameters)
	
	CalculationParameters.Insert("TempTablesManager", New TempTablesManager);
	CalculationParameters.Insert("CalculationOfAdvancesIssued",   False);
	CalculationParameters.Insert("CalculationOfAdvancesReceived", False);
	
	If Not Common.FileInfobase() Then
		BeginTransaction();
		Try
			BlockTaskRegister(CalculationParameters);
			GetTasksForGeneratingVATRegisteredRecords(CalculationParameters);
			CommitTransaction();
		Except
			RollbackTransaction();
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể thực hiện do nguyên nhân %1';
					|ru = 'Не удалось выполнить по причине %1';
					|en = 'Cannot execute. Reason: %1'; fa = 'Cannot execute. Reason: %1';
					|it = 'Non è stato possibile eseguire il comando a causa di %1';
					|pl = 'Nie udało się wykonać z powodu %1';
					|tr = '%1 nedeniyle başarısız oldu'"),
				DetailErrorDescription(ErrorInfo()));
				WriteLogEvent(
				NStr("vi = 'Lập bản ghi kết chuyển theo thuế GTGT.';
					|ru = 'Формирование движений по НДС.';
					|en = 'Generation of VAT records.'; fa = 'Generation of VAT records.';
					|it = 'Generazione di movimenti IVA.';
					|pl = 'Formowanie przepływów wg VAT.';
					|tr = 'KDV kayıtlarını oluşturma.'", Common.DefaultLanguageCode()), 
				EventLogLevel.Error, , , MessageText); 
			Raise MessageText;
		EndTry;
	Else
		GetTasksForGeneratingVATRegisteredRecords(CalculationParameters);
	EndIf;
	
	If CostCalculationAppliedAlgorithms.TemporaryTableSize(CalculationParameters, "Jobs") > 0 Then
		ThereAreTasksForFormationOfRegisteredRecordsOnVAT = True;
	Else
		ThereAreTasksForFormationOfRegisteredRecordsOnVAT = False;
	EndIf;
	
	Return ThereAreTasksForFormationOfRegisteredRecordsOnVAT;
	
EndFunction

Procedure GetTasksForGeneratingVATRegisteredRecords(CalculationParameters)
	
	Query = New Query;
	Query.Text = "
	|SELECT DISTINCT TOP 100
	|	Jobs.Month,
	|	Jobs.JobNumber,
	|	Jobs.Organization,
	|	Jobs.TaxInvoice
	|INTO InitialTasks
	|FROM
	|	InformationRegister.JobsForGeneratingVATRecords AS Jobs
	|WHERE
	|	Jobs.Month BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND Jobs.JobNumber <= &JobNumber
	|	AND (&AllCompanies OR Jobs.Organization IN (&CompanyArray))
	|	AND (&AllInvoices OR Jobs.TaxInvoice IN (&ArrayOfInvoices_))
	|
	|INDEX BY
	|	Organization,
	|	TaxInvoice
	|;
	|/////////////////////////////////////
	|SELECT DISTINCT
	|	Jobs.Organization,
	|	Jobs.TaxInvoice
	|INTO Jobs
	|FROM
	|	InitialTasks AS Jobs
	|
	|INDEX BY
	|	Organization, 
	|	TaxInvoice
	|";
	
	Query.Text = StrReplace(Query.Text, "100", String(Format(NumberOfTasksForVATCalculation(),"NG=")));
	
	Query.SetParameter("BeginOfPeriod",      CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",       CalculationParameters.EndOfPeriod);
	Query.SetParameter("CompanyArray",  CalculationParameters.CompanyArray);
	Query.SetParameter("AllCompanies",     Not ValueIsFilled(CalculationParameters.CompanyArray));
	Query.SetParameter("ArrayOfInvoices_", CalculationParameters.ArrayOfInvoices_);
	Query.SetParameter("AllInvoices",    Not ValueIsFilled(CalculationParameters.ArrayOfInvoices_));
	Query.SetParameter("JobNumber",       CalculationParameters.JobNumber);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.Execute();
	
EndProcedure

Procedure FixResult(CalculationParameters)
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	CleaningTasks.Month                               AS Month,
	|	CleaningTasks.JobNumber                        AS JobNumber,
	|	CleaningTasks.Organization                         AS Organization,
	|	CleaningTasks.TaxInvoice                         AS TaxInvoice
	|FROM
	|	InitialTasks AS CleaningTasks
	|;
	|
	|//////////////////////////////////////
	|SELECT DISTINCT
	|	BEGINOFPERIOD(VATInvoiced.Period, MONTH) AS Month,
	|	&JobNumber                                 AS JobNumber,
	|	Jobs.Organization                           AS Organization,
	|	Jobs.TaxInvoice                           AS TaxInvoice
	|FROM
	|	InitialTasks AS Jobs
	|	
	|	INNER JOIN AccumulationRegister.VATInvoiced AS VATInvoiced
	|	ON VATInvoiced.Period > &EndOfPeriod
	|		AND VATInvoiced.Organization = Jobs.Organization
	|		AND VATInvoiced.TaxInvoice = Jobs.TaxInvoice
	|		AND VATInvoiced.Active
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	BEGINOFPERIOD(DocumentsRegistry.IBDocumentDate, MONTH) AS Month,
	|	&JobNumber                                 AS JobNumber,
	|	Jobs.Organization                           AS Organization,
	|	Jobs.TaxInvoice                           AS TaxInvoice
	|FROM
	|	InitialTasks AS Jobs
	|	
	|	INNER JOIN AccumulationRegister.VATInvoiced AS VATInvoiced
	|	ON VATInvoiced.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND VATInvoiced.Organization = Jobs.Organization
	|		AND VATInvoiced.TaxInvoice = Jobs.TaxInvoice
	|		AND VATInvoiced.Active
	|	
	|	INNER JOIN
	|		InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|	ON
	|		VATInvoiced.Recorder = DocumentsRegistry.ReversedDocument
	|		AND VATInvoiced.Organization = DocumentsRegistry.Organization
	|		AND DocumentsRegistry.IBDocumentDate > &EndOfPeriod
	|		AND DocumentsRegistry.Posted
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	BEGINOFPERIOD(VATPrepaymentsFromCustomer.Period, MONTH) AS Month,
	|	&JobNumber                                    AS JobNumber,
	|	Jobs.Organization                              AS Organization,
	|	Jobs.TaxInvoice                              AS TaxInvoice
	|FROM
	|	InitialTasks AS Jobs
	|	
	|	INNER JOIN AccumulationRegister.VATPrepaymentsFromCustomer AS VATPrepaymentsFromCustomer
	|	ON VATPrepaymentsFromCustomer.Period > &EndOfPeriod
	|		AND VATPrepaymentsFromCustomer.Organization = Jobs.Organization
	|		AND VATPrepaymentsFromCustomer.DocumentPayments = Jobs.TaxInvoice
	|		AND VATPrepaymentsFromCustomer.Active
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	BEGINOFPERIOD(CustomersARAPAccounting.Period, MONTH) AS Month,
	|	&JobNumber                                    AS JobNumber,
	|	Jobs.Organization                              AS Organization,
	|	Jobs.TaxInvoice                              AS TaxInvoice
	|FROM
	|	InitialTasks AS Jobs
	|	
	|	INNER JOIN AccumulationRegister.CustomersARAPAccountingByDocuments AS CustomersARAPAccounting
	|	ON CustomersARAPAccounting.Period > &EndOfPeriod
	|		AND CustomersARAPAccounting.AccountingDimensionByPartners.Organization = Jobs.Organization
	|		AND CustomersARAPAccounting.ARAPDocument = Jobs.TaxInvoice
	|		AND CustomersARAPAccounting.Active
	|		AND CustomersARAPAccounting.PrepaymentLocal <> 0
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	BEGINOFPERIOD(CustomersARAPAccounting.Period, MONTH) AS Month,
	|	&JobNumber                                    AS JobNumber,
	|	Jobs.Organization                              AS Organization,
	|	Jobs.TaxInvoice                              AS TaxInvoice
	|FROM
	|	InitialTasks AS Jobs
	|	
	|	INNER JOIN AccumulationRegister.CustomersARAPAccountingByDueDates AS CustomersARAPAccounting
	|	ON CustomersARAPAccounting.Period > &EndOfPeriod
	|		AND CustomersARAPAccounting.AccountingDimensionByPartners.Organization = Jobs.Organization
	|		AND CustomersARAPAccounting.ARAPDocument = Jobs.TaxInvoice
	|		AND CustomersARAPAccounting.Active
	|		AND CustomersARAPAccounting.PrepaymentLocal <> 0
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	BEGINOFPERIOD(CustomersARAPAccounting.Period, MONTH) AS Month,
	|	&JobNumber                                  AS JobNumber,
	|	Jobs.Organization                            AS Organization,
	|	DocumentsRegistry.Recorder                  AS TaxInvoice
	|FROM
	|	InitialTasks AS Jobs
	|	
	|	INNER JOIN InformationRegister.DocumentCorrections AS DocumentsRegistry
	|	ON Jobs.TaxInvoice = DocumentsRegistry.CorrectedDocument
	|		AND (DocumentsRegistry.Period > &EndOfPeriod)
	|		AND (DocumentsRegistry.Active)
	|	INNER JOIN AccumulationRegister.CustomersARAPAccountingByDueDates AS CustomersARAPAccounting
	|	ON CustomersARAPAccounting.Period > &EndOfPeriod
	|		AND CustomersARAPAccounting.ARAPDocument = DocumentsRegistry.CorrectedDocument
	|		AND CustomersARAPAccounting.Active
	|		AND CustomersARAPAccounting.PrepaymentLocal <> 0
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	BEGINOFPERIOD(VATPrepaymentsToVendor.Period, MONTH) AS Month,
	|	&JobNumber                                  AS JobNumber,
	|	Jobs.Organization                            AS Organization,
	|	Jobs.TaxInvoice                            AS TaxInvoice
	|FROM
	|	InitialTasks AS Jobs
	|	
	|	INNER JOIN AccumulationRegister.VATPrepaymentsToVendor AS VATPrepaymentsToVendor
	|	ON VATPrepaymentsToVendor.Period > &EndOfPeriod
	|		AND VATPrepaymentsToVendor.Organization = Jobs.Organization
	|		AND VATPrepaymentsToVendor.DocumentPayments = Jobs.TaxInvoice
	|		AND VATPrepaymentsToVendor.Active
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	BEGINOFPERIOD(VendorsARAPAccounting.Period, MONTH) AS Month,
	|	&JobNumber                                    AS JobNumber,
	|	Jobs.Organization                              AS Organization,
	|	Jobs.TaxInvoice                              AS TaxInvoice
	|FROM
	|	InitialTasks AS Jobs
	|	
	|	INNER JOIN AccumulationRegister.VendorsARAPAccountingByDocuments AS VendorsARAPAccounting
	|	ON VendorsARAPAccounting.Period > &EndOfPeriod
	|		AND VendorsARAPAccounting.AccountingDimensionByPartners.Organization = Jobs.Organization
	|		AND VendorsARAPAccounting.ARAPDocument = Jobs.TaxInvoice
	|		AND VendorsARAPAccounting.Active
	|		AND VendorsARAPAccounting.PrepaymentLocal <> 0
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	BEGINOFPERIOD(VendorsARAPAccounting.Period, MONTH) AS Month,
	|	&JobNumber                                    AS JobNumber,
	|	Jobs.Organization                              AS Organization,
	|	Jobs.TaxInvoice                              AS TaxInvoice
	|FROM
	|	InitialTasks AS Jobs
	|	
	|	INNER JOIN AccumulationRegister.VendorsARAPAccountingByDueDates AS VendorsARAPAccounting
	|	ON VendorsARAPAccounting.Period > &EndOfPeriod
	|		AND VendorsARAPAccounting.AccountingDimensionByPartners.Organization = Jobs.Organization
	|		AND VendorsARAPAccounting.ARAPDocument = Jobs.TaxInvoice
	|		AND VendorsARAPAccounting.Active
	|		AND VendorsARAPAccounting.PrepaymentLocal <> 0
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	BEGINOFPERIOD(VendorsARAPAccounting.Period, MONTH) AS Month,
	|	&JobNumber                                    AS JobNumber,
	|	Jobs.Organization                              AS Organization,
	|	DocumentsRegistry.Recorder                     AS TaxInvoice
	|FROM
	|	InitialTasks AS Jobs
	|	
	|	INNER JOIN InformationRegister.DocumentCorrections AS DocumentsRegistry
	|	ON Jobs.TaxInvoice = DocumentsRegistry.CorrectedDocument
	|		AND (DocumentsRegistry.Period > &EndOfPeriod)
	|		AND (DocumentsRegistry.Active)
	|	INNER JOIN AccumulationRegister.VendorsARAPAccountingByDueDates AS VendorsARAPAccounting
	|	ON VendorsARAPAccounting.Period > &EndOfPeriod
	|		AND VendorsARAPAccounting.ARAPDocument = DocumentsRegistry.Recorder
	|		AND VendorsARAPAccounting.Active
	|		AND VendorsARAPAccounting.PrepaymentLocal <> 0
	|
	|UNION ALL
	| 
	|SELECT DISTINCT
	|	BEGINOFPERIOD(LeasePayments.Period, MONTH) AS Month,
	|	&JobNumber                                    AS JobNumber,
	|	Jobs.Organization                              AS Organization,
	|	Jobs.TaxInvoice                              AS TaxInvoice
	|FROM
	|	InitialTasks AS Jobs
	|	
	|	INNER JOIN AccumulationRegister.FinancialInstrumentsARAP AS LeasePayments
	|	ON LeasePayments.Period > &EndOfPeriod
	|		AND LeasePayments.AccountingDimensionByPartners.Organization = Jobs.Organization
	|		AND LeasePayments.ARAPDocument = Jobs.TaxInvoice
	|		AND LeasePayments.AmountType IN (
	|			VALUE(Enum.TypesOfLeasePayments.DepositPayment),
	|			VALUE(Enum.TypesOfLeasePayments.BuyoutValuePrepayment))
	|		AND LeasePayments.Active
	|		AND LeasePayments.SumCompl > 0
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	BEGINOFPERIOD(&EndOfQuarter, MONTH) AS Month,
	|	&JobNumber                        AS JobNumber,
	|	Jobs.Organization                  AS Organization,
	|	Jobs.TaxInvoice                  AS TaxInvoice
	|FROM
	|	InitialTasks AS Jobs
	|
	|	LEFT JOIN
	|		AccountingPoliciesOnFrequencyOfVATCalculation AS AccountingPoliciesOnFrequencyOfVATCalculation
	|	ON 
	|		AccountingPoliciesOnFrequencyOfVATCalculation.Organization = Jobs.Organization
	|WHERE
	|	AccountingPoliciesOnFrequencyOfVATCalculation.FrequencyOfFormationOfVATDeductionsAndRecoveries = VALUE(Enum.Periodicity.QUARTER)
	|	AND &EndOfPeriod <> &EndOfQuarter
	|";
	
	Query.SetParameter("BeginOfPeriod",   CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",    CalculationParameters.EndOfPeriod);
	Query.SetParameter("JobNumber",    CalculationParameters.JobNumber);
	Query.SetParameter("EndOfQuarter",   EndOfQuarter(CalculationParameters.EndOfPeriod));
	
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	
	Result  = Query.ExecuteBatch();
	Result0 = Result[0]; // QueryResult - 
	Result1 = Result[1]; // QueryResult - 
	SelectionToDelete = Result0.Select();
	SelectionForRecording = Result1.Select();
	
	While SelectionToDelete.Next() Do
		RecordManager = InformationRegisters.JobsForGeneratingVATRecords.CreateRecordManager();
		FillPropertyValues(RecordManager, SelectionToDelete);
		RecordManager.Delete();
	EndDo;
	
	While SelectionForRecording.Next() Do
		RecordManager = InformationRegisters.JobsForGeneratingVATRecords.CreateRecordManager();
		FillPropertyValues(RecordManager, SelectionForRecording);
		RecordManager.Write();
	EndDo;
	
	VATAccountingLocalization.FixResult(CalculationParameters);
	
	CalculationParameters.TempTablesManager.Close();
	
EndProcedure

Procedure GetBatches_(CalculationParameters)
	
	VATAccountingLocalization.GetBatches_(CalculationParameters);
	
	TempTablesManager = CalculationParameters.TempTablesManager;
	If TempTablesManager.Tables.Find("Lots") = Undefined Then
		Query = New Query();
		Query.Text =
		"SELECT
		|	Lots.Period AS Period,
		|	Lots.Recorder AS Recorder,
		|	Lots.Organization AS Organization,
		|	Lots.LotVendorAttributes.Counterparty AS Counterparty,
		|	Lots.ExpenseReceiptDocument AS TaxInvoice,
		|	CASE 
		|		WHEN Lots.ExpenseReceiptDocument REFS Document.CCDImport 
		|			THEN VALUE(Enum.AssetKinds.CustomsPayments)
		|		ELSE Lots.LotVendorAttributes.AssetTaxClass 
		|	END AS AssetTaxClass,
		|	Lots.LotVendorAttributes.VATRate AS VATRate,
		|	Lots.VATActivityType AS VATActivityType,
		|	Lots.VATTaxation AS CorVATActivityTypes,
		|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS VATWriteOffItem,
		|	UNDEFINED AS DimensionVATWriteOff,
		|	Lots.LineOfBusiness AS DirectionOfActivityOfDepreciationOfVAT,
		|	Lots.LineOfBusiness AS LineOfBusiness,
		|	Lots.LineOfBusiness AS CorLineOfBusiness,
		|	UNDEFINED AS VATWriteOffDivision,
		|	Lots.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
		|	Lots.FinRecordID AS FinRecordID,
		|	Lots.BusinessTransactionSetting AS BusinessTransactionSetting,
		|	Lots.ReversingEntry AS ReversingEntry,
		|	CASE
		|		WHEN VALUETYPE(Lots.ExpenseReceiptDocument) = TYPE(Document.CCDImport)
		|			THEN 0
		|		ELSE Lots.LocalCost 
		|	END AS AmountExcludingVAT,
		|	Lots.VATLocal AS VAT,
		|	Lots.VATManag AS VATManag
		|INTO LotsPreliminary
		|FROM
		|	AccumulationRegister.ItemisedExpensesLots AS Lots
		|	
		|	INNER JOIN
		|		Jobs AS Jobs
		|	ON
		|		Jobs.Organization = Lots.Organization
		|		AND Jobs.TaxInvoice = Lots.ExpenseReceiptDocument
		|	
		|WHERE
		|	Lots.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND NOT Lots.ReversingEntry
		|	AND Lots.Active
		|	AND Lots.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND Lots.VATLocal <> 0
		|	AND Lots.VATTaxation <> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|	
		|UNION ALL
		|
		|SELECT
		|	Lots.Period AS Period,
		|	Lots.Recorder AS Recorder,
		|	Lots.Organization AS Organization,
		|	Lots.Vendor AS Counterparty,
		|	Lots.ExpenseReceiptDocument AS TaxInvoice,
		|	Lots.AssetTaxClass AS AssetTaxClass,
		|	Lots.VATRate AS VATRate,
		|	Lots.VATActivityType AS VATActivityType,
		|	Lots.CorVATActivityTypes AS CorVATActivityTypes,
		|	Lots.ExpenseItem_ AS VATWriteOffItem,
		|	Lots.ExpensesPostingDimension AS DimensionVATWriteOff,
		|	Lots.LineOfBusiness AS DirectionOfActivityOfDepreciationOfVAT,
		|	Lots.LineOfBusiness AS LineOfBusiness,
		|	Lots.LineOfBusiness AS CorLineOfBusiness,
		|	Lots.Department AS VATWriteOffDivision,
		|	Lots.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
		|	Lots.FinRecordID AS FinRecordID,
		|	Lots.BusinessTransactionSetting AS BusinessTransactionSetting,
		|	Lots.ReversingEntry AS ReversingEntry,
		|	Lots.LocalCost AS AmountExcludingVAT,
		|	Lots.VATLocal AS VAT,
		|	Lots.VATManag AS VATManag
		|FROM
		|	AccumulationRegister.LotsVATForAllocation AS Lots
		|	
		|	INNER JOIN
		|		Jobs AS Jobs
		|	ON
		|		Jobs.Organization = Lots.Organization
		|		AND Jobs.TaxInvoice = Lots.ExpenseReceiptDocument
		|		
		|WHERE
		|	Lots.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND Lots.Active
		|	AND Lots.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND Lots.VATLocal <> 0
		|	AND Lots.CorVATActivityTypes <> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Lots.Period AS Period,
		|	Lots.Recorder AS Recorder,
		|	Lots.Organization AS Organization,
		|	Lots.Counterparty AS Counterparty,
		|	Lots.TaxInvoice AS TaxInvoice,
		|	ISNULL(SourceDocumentsData.RecorderDate, DATETIME(1, 1, 1)) AS DateOfReceipt,
		|	Lots.AssetTaxClass AS AssetTaxClass,
		|	Lots.VATRate AS VATRate,
		|	Lots.VATActivityType AS VATActivityType,
		|	Lots.CorVATActivityTypes AS CorVATActivityTypes,
		|	Lots.VATWriteOffItem AS VATWriteOffItem,
		|	Lots.DimensionVATWriteOff AS DimensionVATWriteOff,
		|	Lots.DirectionOfActivityOfDepreciationOfVAT AS DirectionOfActivityOfDepreciationOfVAT,
		|	ISNULL(Lots.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)) AS LineOfBusiness,
		|	ISNULL(Lots.CorLineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)) AS CorLineOfBusiness,
		|	Lots.VATWriteOffDivision AS VATWriteOffDivision,
		|	Lots.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
		|	Lots.FinRecordID AS FinRecordID,
		|	Lots.BusinessTransactionSetting AS BusinessTransactionSetting,
		|	Lots.ReversingEntry AS ReversingEntry,
		|	SUM(Lots.AmountExcludingVAT) AS AmountExcludingVAT,
		|	SUM(Lots.VAT) AS VAT,
		|	SUM(Lots.VATManag) AS VATManag
		|INTO Lots
		|FROM
		|	LotsPreliminary AS Lots
		|		LEFT JOIN InformationRegister.SourceDocumentsData AS SourceDocumentsData
		|		ON Lots.Organization.ParentCompany = SourceDocumentsData.Organization.ParentCompany
		|			AND Lots.TaxInvoice = SourceDocumentsData.Document
		|
		|GROUP BY
		|	Lots.Period,
		|	Lots.Recorder,
		|	Lots.Organization,
		|	Lots.Counterparty,
		|	Lots.TaxInvoice,
		|	ISNULL(SourceDocumentsData.RecorderDate, DATETIME(1, 1, 1)),
		|	Lots.AssetTaxClass,
		|	Lots.VATRate,
		|	Lots.VATActivityType,
		|	Lots.CorVATActivityTypes,
		|	Lots.VATWriteOffItem,
		|	Lots.DimensionVATWriteOff,
		|	Lots.DirectionOfActivityOfDepreciationOfVAT,
		|	ISNULL(Lots.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)),
		|	ISNULL(Lots.CorLineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)),
		|	Lots.VATWriteOffDivision,
		|	Lots.DocumentSalesOfGoodsAndServices,
		|	Lots.FinRecordID,
		|	Lots.BusinessTransactionSetting,
		|	Lots.ReversingEntry
		|
		|INDEX BY
		|	Organization,
		|	TaxInvoice
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP LotsPreliminary
		|";
		
		Query.SetParameter("BeginOfPeriod",           CalculationParameters.BeginOfPeriod);
		Query.SetParameter("EndOfPeriod",            CalculationParameters.EndOfPeriod);
		
		Query.TempTablesManager = TempTablesManager;
		Query.Execute();
		
	EndIf;
	
EndProcedure

Procedure CheckBlockingIncomingDataWhenUpdatingInformationSecurity()
	
	SetPrivilegedMode(True);
	
	IncomingDataOfRaglamentalOperation = New Map;
	
	IncomingMechanismData = IncomingMechanismData();
	For Each Object In IncomingMechanismData Do
		IncomingDataOfRaglamentalOperation.Insert(Object);
	EndDo;
	
	MonthEndTransactionsServer.CheckBlockingIncomingDataWhenUpdatingInformationSecurity(
		IncomingDataOfRaglamentalOperation,
		NStr("vi = 'Lập bảng kê mua hàng và bán hàng';
			|ru = 'Формирование записей книг покупок и продаж.';
			|en = 'Generate purchase and sales ledger entries.'; fa = 'Generate purchase and sales ledger entries.';
			|it = 'Generazione delle scritture dei registri IVA acquisti e vendite.';
			|pl = 'Tworzenie wpisów księgi zakupów i sprzedaży.';
			|tr = 'Alış ve satış defteri kayıtlarının oluşturulması.'"));
	
EndProcedure

// Checks whether there are generated tasks by the end of the month for VAT movements
// 
// Parameters:
// 	ParametersStructure - Structure - Contains:
// 		* Organization   - CatalogRef.Companies -
// 		* EndDate - Date -
// Returns:
// 	Boolean - True, if the tasks are available
Function CheckAvailabilityOfTasksForGeneratingVATRegisteredRecords(ParametersStructure) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	TRUE
	|FROM
	|	InformationRegister.JobsForGeneratingVATRecords AS JobsForGeneratingVATRecords
	|WHERE
	|	JobsForGeneratingVATRecords.Month <= &EndDate
	|	AND JobsForGeneratingVATRecords.Organization = &Organization
	|";
	
	For Each KeyAndValue In ParametersStructure Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
	QueryResult = Query.Execute();
	
	Return Not QueryResult.IsEmpty();
	
EndFunction

#Region FormationOfMovementVATPresented

Procedure GenerateVATSubmitted(CalculationParameters)
	
	GetFrequencyOfVATDeductionsAndRecoveries(CalculationParameters);
	
	GetCurRegistrarsVATPresented(CalculationParameters);
	GetInvoicesDocuments(CalculationParameters);
	GetCorrectedInvoiceDocuments(CalculationParameters);
	GetAdjustmentInvoicesDocuments(CalculationParameters);
	
	GetBatches_(CalculationParameters);
	
	GetVATDeductionsForExpenses(CalculationParameters);
	GetVATPresentedBalanceAtBeginning(CalculationParameters);
	GetVATPresentedOnline(CalculationParameters);
	
	TableNamesOfVATRecordsPresented = New Array;
	TableNamesOfVATRecordsPresented.Add(CalculateVATRecordsSubmittedByStorno(CalculationParameters));
	TableNamesOfVATRecordsPresented.Add(CalculateVATRecordsSubmittedByISF(CalculationParameters));
	
	GetSectionsOfVATDeduction(CalculationParameters);
	
	TableNamesOfVATRecordsPresented.Add(CalculateRecordsOfVATChargedChangeOfActivity(CalculationParameters));
	TableNamesOfVATRecordsPresented.Add(CalculateRecordsOfVATChargedChangeOfBusinessDirection(CalculationParameters));
	
	GetRemainingVATPresentedAtEndOfPeriod(CalculationParameters);
	
	TableNamesOfVATRecordsPresented.Add(CalculateRecordsOfVATPresentedRecoveryUnderTypeOfActivity(CalculationParameters));
	GetSalesTaxBase0(CalculationParameters);
	GetVATLocks(CalculationParameters);
	GetReAdmittedToVATDeduction(CalculationParameters);
	
	TableNamesOfVATRecordsPresented.Add(CalculateRecordsOfVATPresentedRecoveryByCSF(CalculationParameters));
	TableNamesOfVATRecordsPresented.Add(CalculateRecordsOfVATPresentedAcceptanceForDeduction(CalculationParameters));
	
	TableNamesOfVATRecordsPresented.Add(CalculateVATRecordsPresentedByRoundingError(CalculationParameters));

	TableNamesOfVATRecordsPresented.Add(CalculateVATRecordsPresentedToYou(CalculationParameters, TableNamesOfVATRecordsPresented));
	
	RecordVATSubmitted(CalculationParameters, TableNamesOfVATRecordsPresented);
	ClearVATCharged(CalculationParameters, TableNamesOfVATRecordsPresented);
	
EndProcedure

Procedure GetSectionsOfVATDeduction(CalculationParameters)
	
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	BalanceAtBeginning.Organization AS Organization,
	|	BalanceAtBeginning.TaxInvoice AS TaxInvoice,
	|	BalanceAtBeginning.VATActivityType AS VATActivityType,
	|	BalanceAtBeginning.AssetTaxClass AS AssetTaxClass,
	|	BalanceAtBeginning.SaleExport AS SaleExport,
	|	BalanceAtBeginning.CorrectedTaxInvoice AS CorrectedTaxInvoice
	|INTO PossibleSectionsOfVATDeduction
	|FROM
	|	VATPresentedBalanceAtBeginning AS BalanceAtBeginning
	|
	|UNION
	|
	|SELECT DISTINCT
	|	OnlineRegisteredRecords.Organization AS Organization,
	|	OnlineRegisteredRecords.TaxInvoice AS TaxInvoice,
	|	OnlineRegisteredRecords.VATActivityType AS VATActivityType,
	|	OnlineRegisteredRecords.AssetTaxClass AS AssetTaxClass,
	|	OnlineRegisteredRecords.SaleExport AS SaleExport,
	|	OnlineRegisteredRecords.CorrectedTaxInvoice AS CorrectedTaxInvoice
	|FROM
	|	VATChargedOnlineTraffic AS OnlineRegisteredRecords
	|
	|UNION
	|
	|SELECT DISTINCT
	|	VATPresentedStorno.Organization AS Organization,
	|	VATPresentedStorno.TaxInvoice AS TaxInvoice,
	|	VATPresentedStorno.VATActivityType AS VATActivityType,
	|	VATPresentedStorno.AssetTaxClass AS AssetTaxClass,
	|	VATPresentedStorno.SaleExport AS SaleExport,
	|	VATPresentedStorno.CorrectedTaxInvoice AS CorrectedTaxInvoice
	|FROM
	|	VATPresentedStorno AS VATPresentedStorno
	|
	|UNION
	|
	|SELECT DISTINCT
	|	VATPresentedUnderISF.Organization AS Organization,
	|	VATPresentedUnderISF.TaxInvoice AS TaxInvoice,
	|	VATPresentedUnderISF.VATActivityType AS VATActivityType,
	|	VATPresentedUnderISF.AssetTaxClass AS AssetTaxClass,
	|	VATPresentedUnderISF.SaleExport AS SaleExport,
	|	VATPresentedUnderISF.CorrectedTaxInvoice AS CorrectedTaxInvoice
	|FROM
	|	VATPresentedUnderISF AS VATPresentedUnderISF
	|
	|UNION
	|
	|SELECT DISTINCT
	|	Lots.Organization AS Organization,
	|	Lots.TaxInvoice AS TaxInvoice,
	|	Lots.VATActivityType AS VATActivityType,
	|	Lots.AssetTaxClass AS AssetTaxClass,
	|	UNDEFINED AS SaleExport,
	|	CASE WHEN CorrectedInvoices.CorrectedTaxInvoice IS NULL
	|		THEN UNDEFINED
	|		ELSE CorrectedInvoices.CorrectedTaxInvoice
	|	END AS CorrectedTaxInvoice
	|FROM
	|	Lots AS Lots
	|
	|	LEFT JOIN
	|		CorrectedInvoices AS CorrectedInvoices
	|	ON
	|		Lots.Organization = CorrectedInvoices.Organization
	|		AND Lots.TaxInvoice = CorrectedInvoices.TaxInvoice
	|
	|UNION
	|
	|SELECT DISTINCT
	|	Lots.Organization AS Organization,
	|	Lots.TaxInvoice AS TaxInvoice,
	|	Lots.CorVATActivityTypes AS VATActivityType,
	|	Lots.AssetTaxClass AS AssetTaxClass,
	|	UNDEFINED AS SaleExport,
	|	CASE WHEN CorrectedInvoices.CorrectedTaxInvoice IS NULL
	|		THEN UNDEFINED
	|		ELSE CorrectedInvoices.CorrectedTaxInvoice
	|	END AS CorrectedTaxInvoice
	|FROM
	|	Lots AS Lots
	|
	|	LEFT JOIN
	|		CorrectedInvoices AS CorrectedInvoices
	|	ON
	|		Lots.Organization = CorrectedInvoices.Organization
	|		AND Lots.TaxInvoice = CorrectedInvoices.TaxInvoice
	|
	|UNION
	|
	|SELECT DISTINCT
	|	Lots.Organization AS Organization,
	|	Lots.TaxInvoice AS TaxInvoice,
	|	Lots.CorVATActivityTypes AS VATActivityType,
	|	Lots.AssetTaxClass AS AssetTaxClass,
	|	Lots.DocumentSalesOfGoodsAndServices AS SaleExport,
	|	CASE WHEN CorrectedInvoices.CorrectedTaxInvoice IS NULL
	|		THEN UNDEFINED
	|		ELSE CorrectedInvoices.CorrectedTaxInvoice
	|	END AS CorrectedTaxInvoice
	|FROM
	|	Lots AS Lots
	|
	|	LEFT JOIN
	|		CorrectedInvoices AS CorrectedInvoices
	|	ON
	|		Lots.Organization = CorrectedInvoices.Organization
	|		AND Lots.TaxInvoice = CorrectedInvoices.TaxInvoice
	|
	|INDEX BY
	|	Organization,
	|	TaxInvoice,
	|	CorrectedTaxInvoice
	|";
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.Execute();
	
	VATAccountingLocalization.GetSectionsOfVATDeduction(CalculationParameters);
	
	TempTablesManager = CalculationParameters.TempTablesManager;
	If TempTablesManager.Tables.Find("SectionsOfVATDeduction") = Undefined Then
		
		// If localization is not specified in the localization, then we deduct all input VAT without restrictions.
		// The deduction is formed within the framework of the invoices themselves.
		
		Query = New Query;
		Query.Text = 
		"SELECT
		|	SectionsOfVATDeduction.Organization AS Organization,
		|	SectionsOfVATDeduction.TaxInvoice AS TaxInvoice,
		|	SectionsOfVATDeduction.VATActivityType AS VATActivityType,
		|	SectionsOfVATDeduction.AssetTaxClass AS AssetTaxClass,
		|	SectionsOfVATDeduction.SaleExport AS SaleExport,
		|	
		|	VALUE(Enum.EventsChargedVAT.VATAcceptedForDeduction) AS Event,
		|	
		|	MAX(ISNULL(VATChargedOnlineTraffic.Period, DataOfPrimaryDocumentsInvoice.RecorderDate)) AS Period,
		|	MAX(ISNULL(VATChargedOnlineTraffic.Recorder, SectionsOfVATDeduction.TaxInvoice)) AS Recorder,
		|	SectionsOfVATDeduction.CorrectedTaxInvoice AS CorrectedTaxInvoice
		|	
		|INTO SectionsOfVATDeduction
		|FROM
		|	PossibleSectionsOfVATDeduction AS SectionsOfVATDeduction
		|	LEFT JOIN 
		|		InformationRegister.SourceDocumentsData AS DataOfPrimaryDocumentsInvoice
		|	ON
		|		SectionsOfVATDeduction.Organization = DataOfPrimaryDocumentsInvoice.Organization
		|		AND SectionsOfVATDeduction.TaxInvoice = DataOfPrimaryDocumentsInvoice.Document
		|	
		|	LEFT JOIN
		|		VATChargedOnlineTraffic AS VATChargedOnlineTraffic
		|	ON
		|		SectionsOfVATDeduction.Organization = VATChargedOnlineTraffic.Organization
		|		AND SectionsOfVATDeduction.TaxInvoice = VATChargedOnlineTraffic.TaxInvoice
		|		AND SectionsOfVATDeduction.VATActivityType = VATChargedOnlineTraffic.VATActivityType
		|		AND SectionsOfVATDeduction.AssetTaxClass = VATChargedOnlineTraffic.AssetTaxClass
		|		AND SectionsOfVATDeduction.SaleExport = VATChargedOnlineTraffic.SaleExport
		|	
		|WHERE
		|	SectionsOfVATDeduction.VATActivityType <> VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
		|
		|GROUP BY
		|	SectionsOfVATDeduction.Organization,
		|	SectionsOfVATDeduction.TaxInvoice,
		|	SectionsOfVATDeduction.VATActivityType,
		|	SectionsOfVATDeduction.AssetTaxClass,
		|	SectionsOfVATDeduction.SaleExport,
		|	SectionsOfVATDeduction.CorrectedTaxInvoice
		|";
		
		Query.TempTablesManager = TempTablesManager;
		Query.Execute();
	
	EndIf;
	
	
	//-- Localization
	
EndProcedure

Procedure GetInvoicesDocuments(CalculationParameters)

	VATAccountingLocalization.GetInvoicesDocuments(CalculationParameters);
	
	TempTablesManager = CalculationParameters.TempTablesManager;
	If TempTablesManager.Tables.Find("InvoicesDocuments") = Undefined Then
		Query = New Query;
		Query.Text = 
		"SELECT DISTINCT
		|	Jobs.Organization           AS Organization,
		|	Jobs.TaxInvoice           AS TaxInvoice,
		|	Jobs.TaxInvoice           AS Ref,
		|	ISNULL(SourceDocumentsData.RecorderDate, DATETIME(1, 1, 1)) AS DateOfPurchaseBookEntry
		|INTO InvoicesDocuments
		|FROM
		|	Jobs AS Jobs
		|	
		|	LEFT JOIN
		|		InformationRegister.SourceDocumentsData AS SourceDocumentsData
		|	ON
		|		Jobs.Organization = SourceDocumentsData.Organization
		|		AND Jobs.TaxInvoice = SourceDocumentsData.Document
		|
		|INDEX BY
		|	Organization, 
		|	TaxInvoice
		|";
		Query.SetParameter("BeginOfPeriod",     CalculationParameters.BeginOfPeriod);
		Query.SetParameter("EndOfPeriod",      CalculationParameters.EndOfPeriod);
		Query.SetParameter("CompanyArray", CalculationParameters.CompanyArray);
		Query.TempTablesManager = CalculationParameters.TempTablesManager;
		Query.Execute();
	
	EndIf;
	
EndProcedure

Procedure GetCorrectedInvoiceDocuments(CalculationParameters)
	
	VATAccountingLocalization.GetCorrectedInvoiceDocuments(CalculationParameters);
	
	TempTablesManager = CalculationParameters.TempTablesManager;
	If TempTablesManager.Tables.Find("CorrectedInvoices") = Undefined Then
		Query = New Query;
		Query.Text = 
		"SELECT
		|	VALUE(Catalog.Companies.EmptyRef) AS Organization,
		|	UNDEFINED      AS TaxInvoice,
		|	UNDEFINED      AS CorrectedTaxInvoice,
		|	UNDEFINED      AS Ref,
		|	DATETIME(1,1,1)  AS CorrectionDate,
		|	DATETIME(1,1,1)  AS DateReceived,
		|	DATETIME(1,1,1)  AS DateOfPurchaseBookEntry,
		|	FALSE              AS WritingAdditionalSheet,
		|	DATETIME(1,1,1)  AS AdjustmentPeriod
		|
		|INTO CorrectedInvoices
		|WHERE
		|	FALSE";
		Query.TempTablesManager = CalculationParameters.TempTablesManager;
		Query.Execute();
	EndIf;
	
EndProcedure

Procedure GetAdjustmentInvoicesDocuments(CalculationParameters)

	VATAccountingLocalization.GetAdjustmentInvoicesDocuments(CalculationParameters);
	
	TempTablesManager = CalculationParameters.TempTablesManager;
	If TempTablesManager.Tables.Find("AdjustmentInvoices") = Undefined Then
		Query = New Query;
		Query.Text = 
		"SELECT
		|	VALUE(Catalog.Companies.EmptyRef) AS Organization,
		|	UNDEFINED AS TaxInvoice
		|INTO AdjustmentInvoices
		|WHERE
		|	FALSE
		|";
		Query.TempTablesManager = CalculationParameters.TempTablesManager;
		Query.Execute();
	EndIf;
	
EndProcedure

Procedure GetVATDeductionsForExpenses(CalculationParameters)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Jobs.Organization                          AS Organization,
	|	Jobs.TaxInvoice                          AS TaxInvoice,
	|	VATWritingOffAsExpenses.Ref                  AS VATWritingOffAsExpenses,
	|	VATWritingOffAsExpenses.Department           AS Department,
	|	VATWritingOffAsExpenses.ExpenseItem          AS ExpenseItem,
	|	VATWritingOffAsExpenses.DimensionOfExpenses       AS DimensionOfExpenses,
	|	VATWritingOffAsExpenses.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	VATWritingOffAsExpenses.GLAccountSettings     AS GLAccountSettings
	|INTO VATDeductionsForExpenses
	|FROM
	|	Jobs AS Jobs
	|	INNER JOIN
	|		Document.VATWritingOffAsExpenses AS VATWritingOffAsExpenses
	|	ON
	|		VATWritingOffAsExpenses.Date <= &EndOfPeriod
	|		AND Jobs.Organization = VATWritingOffAsExpenses.Organization
	|		AND Jobs.TaxInvoice = VATWritingOffAsExpenses.TaxInvoice
	|		AND VATWritingOffAsExpenses.Posted
	|
	|INDEX BY
	|	Organization,
	|	TaxInvoice
	|";
	
	Query.SetParameter("BeginOfPeriod",     CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",  CalculationParameters.EndOfPeriod);
	Query.SetParameter("CompanyArray", CalculationParameters.CompanyArray);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;

	Query.Execute();
	
EndProcedure

Procedure GetVATPresentedBalanceAtBeginning(CalculationParameters)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	DD.Organization             AS Organization,
	|	DD.TaxInvoice             AS TaxInvoice,
	|	DD.Vendor               AS Vendor,
	|	DD.AssetTaxClass             AS AssetTaxClass,
	|	DD.VATRate               AS VATRate,
	|	DD.VATActivityType      AS VATActivityType,
	|	DD.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|	DD.SaleExport       AS SaleExport,
	|	DD.LineOfBusiness AS LineOfBusiness,
	|	DD.AmountExcludingVATBalance      AS AmountExcludingVAT,
	|	DD.VATBalance              AS VAT,
	|	DD.VATManagBalance           AS VATManag
	|INTO VATPresentedBalanceAtBeginningWithDirections
	|FROM
	|	AccumulationRegister.VATInvoiced.Balance(
	|		&BeginOfPeriod, 
	|		(Organization, TaxInvoice) IN (
	|			SELECT
	|				Jobs.Organization,
	|				Jobs.TaxInvoice
	|			FROM
	|				Jobs)) AS DD
	|;
	|
	|SELECT
	|	DD.Organization             AS Organization,
	|	DD.TaxInvoice             AS TaxInvoice,
	|	DD.Vendor               AS Vendor,
	|	DD.AssetTaxClass             AS AssetTaxClass,
	|	DD.VATRate               AS VATRate,
	|	DD.VATActivityType      AS VATActivityType,
	|	DD.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|	DD.SaleExport       AS SaleExport,
	|	SUM(DD.AmountExcludingVAT)      AS AmountExcludingVAT,
	|	SUM(DD.VAT)              AS VAT,
	|	SUM(DD.VATManag)           AS VATManag
	|INTO VATPresentedBalanceAtBeginning
	|FROM
	|	VATPresentedBalanceAtBeginningWithDirections AS DD
	|
	|GROUP BY
	|	DD.Organization,
	|	DD.TaxInvoice,
	|	DD.Vendor,
	|	DD.AssetTaxClass,
	|	DD.VATRate,
	|	DD.VATActivityType,
	|	DD.CorrectedTaxInvoice,
	|	DD.SaleExport
	|
	|INDEX BY
	|	Organization,
	|	TaxInvoice
	|";
	
	Query.SetParameter("BeginOfPeriod",     CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",      CalculationParameters.EndOfPeriod);
	Query.SetParameter("CompanyArray", CalculationParameters.CompanyArray);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.Execute();
	
EndProcedure

Procedure GetVATPresentedOnline(CalculationParameters)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	DD.Period                  AS Period,
	|	DD.Recorder             AS Recorder,
	|	DD.Organization             AS Organization,
	|	DD.TaxInvoice             AS TaxInvoice,
	|	DD.Vendor               AS Vendor,
	|	DD.AssetTaxClass             AS AssetTaxClass,
	|	DD.VATRate               AS VATRate,
	|	DD.VATActivityType  AS VATActivityType,
	|	DD.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|	DD.SaleExport       AS SaleExport,
	|	DD.LineOfBusiness AS LineOfBusiness,
	|	CASE
	|		WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN DD.AmountExcludingVAT
	|		ELSE -DD.AmountExcludingVAT
	|	END                      AS AmountExcludingVAT,
	|	CASE
	|		WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN DD.VAT
	|		ELSE -DD.VAT
	|	END                      AS VAT,
	|	CASE
	|		WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN DD.VATManag
	|		ELSE -DD.VATManag
	|	END                      AS VATManag
	|INTO VATChargedOnlineTraffic
	|FROM
	|	AccumulationRegister.VATInvoiced AS DD
	|	INNER JOIN
	|		Jobs AS Jobs
	|	ON
	|		DD.Organization = Jobs.Organization
	|		AND DD.TaxInvoice = Jobs.TaxInvoice
	|WHERE
	|	DD.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND NOT DD.PeriodEndTransaction
	|	AND DD.Active
	|
	|INDEX BY
	|	Organization, 
	|	TaxInvoice
	|";
	
	Query.SetParameter("BeginOfPeriod",     CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",      CalculationParameters.EndOfPeriod);
	Query.SetParameter("CompanyArray", CalculationParameters.CompanyArray);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	
	Query.Execute();
	
EndProcedure

Procedure GetCurRegistrarsVATPresented(CalculationParameters) 
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	VATInvoiced.Recorder AS Recorder,
	|	VATInvoiced.Organization AS Organization,
	|	VATInvoiced.Period AS Period
	|INTO CurRegistrarsVATCharged
	|FROM
	|	AccumulationRegister.VATInvoiced AS VATInvoiced
	|		INNER JOIN Jobs AS Jobs
	|		ON (Jobs.Organization = VATInvoiced.Organization)
	|			AND (Jobs.TaxInvoice = VATInvoiced.TaxInvoice)
	|WHERE
	|	VATInvoiced.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND VATInvoiced.PeriodEndTransaction
	|
	|INDEX BY
	|	Recorder
	|";
	
	Query.SetParameter("BeginOfPeriod",     CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",      CalculationParameters.EndOfPeriod);
	Query.SetParameter("CompanyArray", CalculationParameters.CompanyArray);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.Execute();
	
EndProcedure

Function CalculateVATRecordsSubmittedByStorno(CalculationParameters)

	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	ISNULL(DocumentsStornoRegistrar.Ref,
	|		ISNULL(DocumentsStornoInvoice.Ref, 
	|				DocumentsReverseCorrectedInvoice.Ref)) AS Ref,
	|	ISNULL(DocumentsStornoRegistrar.Period,
	|		ISNULL(DocumentsStornoInvoice.Period, 
	|				DocumentsReverseCorrectedInvoice.Period)) AS Period,
	|	ISNULL(DocumentsStornoRegistrar.ReversedDocument,
	|		ISNULL(DocumentsStornoInvoice.ReversedDocument, 
	|				DocumentsReverseCorrectedInvoice.ReversedDocument)) AS ReversedDocument,
	|	VATInvoiced.Recorder AS Recorder,
	|	VATInvoiced.Organization AS Organization,
	|	VATInvoiced.TaxInvoice AS TaxInvoice
	|INTO VATPresentedInReverse
	|FROM
	|	AccumulationRegister.VATInvoiced AS VATInvoiced
	|	INNER JOIN
	|		Jobs AS Jobs
	|	ON
	|		VATInvoiced.Organization = Jobs.Organization
	|		AND VATInvoiced.TaxInvoice = Jobs.TaxInvoice
	|	
	|	LEFT JOIN
	|		DocumentsStorno AS DocumentsStornoRegistrar
	|	ON
	|		VATInvoiced.Recorder = DocumentsStornoRegistrar.ReversedDocument
	|	
	|	LEFT JOIN
	|		DocumentsStorno AS DocumentsStornoInvoice
	|	ON
	|		VATInvoiced.TaxInvoice = DocumentsStornoInvoice.ReversedDocument
	|	
	|	LEFT JOIN
	|		DocumentsStorno AS DocumentsReverseCorrectedInvoice
	|	ON
	|		VATInvoiced.CorrectedTaxInvoice = DocumentsReverseCorrectedInvoice.ReversedDocument
	|	
	|	LEFT JOIN
	|		InformationRegister.DocumentsRegistry AS PastStornoRegistrar
	|	ON
	|		VATInvoiced.Recorder = PastStornoRegistrar.ReversedDocument
	|		AND PastStornoRegistrar.ReverseTransactionCorrection
	|		AND NOT PastStornoRegistrar.AdditionalRecord
	|		AND PastStornoRegistrar.Posted
	|		AND PastStornoRegistrar.IBDocumentDate < &BeginOfPeriod
	|	
	|	LEFT JOIN
	|		InformationRegister.DocumentsRegistry AS PastStornoInvoices
	|	ON
	|		VATInvoiced.TaxInvoice = PastStornoInvoices.ReversedDocument 
	|		AND PastStornoInvoices.ReverseTransactionCorrection
	|		AND NOT PastStornoInvoices.AdditionalRecord
	|		AND PastStornoInvoices.Posted
	|		AND PastStornoInvoices.IBDocumentDate < &BeginOfPeriod
	|	
	|	LEFT JOIN
	|		InformationRegister.DocumentsRegistry AS PastStornoCorrectionalInvoices
	|	ON
	|		VATInvoiced.CorrectedTaxInvoice <> UNDEFINED
	|		AND VATInvoiced.CorrectedTaxInvoice = PastStornoCorrectionalInvoices.ReversedDocument
	|		AND PastStornoCorrectionalInvoices.ReverseTransactionCorrection
	|		AND NOT PastStornoCorrectionalInvoices.AdditionalRecord
	|		AND PastStornoCorrectionalInvoices.Posted
	|		AND PastStornoCorrectionalInvoices.IBDocumentDate < &BeginOfPeriod
	|WHERE
	|	VATInvoiced.Period < &BeginOfPeriod 
	|	AND VATInvoiced.PeriodEndTransaction
	|	AND NOT VATInvoiced.ReversingEntry
	|	AND NOT (VALUETYPE(VATInvoiced.Recorder) = TYPE(Document.VATAllocation)
	|			AND VALUETYPE(DocumentsStornoRegistrar.Ref) <> TYPE(Document.VATAllocation))
	|	AND NOT (DocumentsStornoRegistrar.ReversedDocument IS NULL
	|		AND DocumentsStornoInvoice.ReversedDocument IS NULL
	|		AND DocumentsReverseCorrectedInvoice.ReversedDocument IS NULL)
	|	AND PastStornoRegistrar.Ref IS NULL
	|	AND PastStornoInvoices.Ref IS NULL
	|	AND PastStornoCorrectionalInvoices.Ref IS NULL
	|;
	|
	|//////////////////////////////////////////////
	|SELECT
	|	0                                           AS Priority,
	|	VATPresentedInReverse.Ref          AS Recorder,
	|	VATPresentedInReverse.Period          AS Period,
	|	VATPresentedInReverse.ReversedDocument  AS ReversedDocument,
	|	VATInvoiced.RecordType                AS RecordType,
	|	VATInvoiced.Organization                AS Organization,
	|	VATInvoiced.TaxInvoice                AS TaxInvoice,
	|	VATInvoiced.Vendor                  AS Vendor,
	|	VATInvoiced.AssetTaxClass                AS AssetTaxClass,
	|	VATInvoiced.VATRate                  AS VATRate,
	|	VATInvoiced.VATActivityType         AS VATActivityType,
	|	ISNULL(CorrectionalSF.CorrectedTaxInvoice, VATInvoiced.CorrectedTaxInvoice)    AS CorrectedTaxInvoice,
	|	VATInvoiced.SaleExport          AS SaleExport,
	|	VATInvoiced.LineOfBusiness    AS LineOfBusiness,
	|	-VATInvoiced.AmountExcludingVAT               AS AmountExcludingVAT,
	|	-VATInvoiced.VAT                       AS VAT,
	|	-VATInvoiced.VATManag                    AS VATManag,
	|	CASE 
	|		WHEN VATInvoiced.Event IN (
	|			VALUE(Enum.EventsChargedVAT.ExcludeVATFromCostExpenses),
	|			VALUE(Enum.EventsChargedVAT.IncludeVATInCostExpenses))
	|		THEN VALUE(Enum.EventsChargedVAT.VATWritingOffAsExpenses)
	|		ELSE VATInvoiced.Event
	|	END                                       AS Event,
	|	VATInvoiced.CorVATActivityTypes      AS CorVATActivityTypes,
	|	TRUE                                      AS PeriodEndTransaction,
	|	CASE
	|		WHEN VATInvoiced.Recorder = VATPresentedInReverse.ReversedDocument
	|			THEN TRUE 
	|		ELSE FALSE
	|	END AS ReversingEntry,
	|	VATInvoiced.Department              AS Department,
	|	VATInvoiced.RowID        AS RowID,
	|	VATInvoiced.CorLineOfBusiness AS CorLineOfBusiness,
	|	CASE 
	|		WHEN VATInvoiced.Event IN (
	|			VALUE(Enum.EventsChargedVAT.ExcludeVATFromCostExpenses),
	|			VALUE(Enum.EventsChargedVAT.IncludeVATInCostExpenses))
	|		THEN VALUE(ChartOfCharacteristicTypes.ExpenseItems.GoodsValueVariance)
	|		ELSE VATInvoiced.ExpenseItem
	|	END  AS ExpenseItem,
	|	CASE 
	|		WHEN VATInvoiced.Event IN (
	|			VALUE(Enum.EventsChargedVAT.ExcludeVATFromCostExpenses),
	|			VALUE(Enum.EventsChargedVAT.IncludeVATInCostExpenses))
	|		THEN VALUE(Catalog.Products.EmptyRef)
	|		ELSE VATInvoiced.DimensionOfExpenses
	|	END AS DimensionOfExpenses,
	|	VATInvoiced.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	VATInvoiced.FinRecordID AS FinRecordID
	|INTO VATPresentedStorno
	|FROM
	|	AccumulationRegister.VATInvoiced AS VATInvoiced
	|	INNER JOIN
	|		VATPresentedInReverse AS VATPresentedInReverse
	|	ON
	|		VATInvoiced.Recorder = VATPresentedInReverse.Recorder
	|		AND VATInvoiced.Organization = VATPresentedInReverse.Organization
	|		AND VATInvoiced.TaxInvoice = VATPresentedInReverse.TaxInvoice
	|
	|		LEFT JOIN 
	|			CorrectedInvoices AS CorrectionalSF
	|		ON
	|			VATInvoiced.Organization = CorrectionalSF.Organization
	|			AND VATInvoiced.TaxInvoice = CorrectionalSF.TaxInvoice
	|
	|WHERE
	|	VATInvoiced.PeriodEndTransaction
	|	AND NOT VATInvoiced.ReversingEntry
	|	AND VATInvoiced.Period < &BeginOfPeriod
	|;
	|";
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.SetParameter("BeginOfPeriod", CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", CalculationParameters.EndOfPeriod);

	Query.Execute();
	
	Return "VATPresentedStorno";
	
EndFunction

Procedure GetSalesTaxBase0(CalculationParameters)
	
	VATAccountingLocalization.GetSalesTaxBase0(CalculationParameters);
	
	TempTablesManager = CalculationParameters.TempTablesManager;
	If TempTablesManager.Tables.Find("SalesTaxBase0") = Undefined Then
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	VALUE(Catalog.Companies.EmptyRef) AS Organization,
		|	UNDEFINED AS TaxInvoice,
		|	0 AS VATOnPurchases,
		|	UNDEFINED AS DocumentShipments,
		|	"""" AS OperationCode,
		|	0 AS ConfirmationAmount
		|INTO TaxBaseOfImplementationOf0InContextOfOFOperationsCodes
		|WHERE
		|	FALSE";
		Query.TempTablesManager = CalculationParameters.TempTablesManager;
		Query.Execute();
	
	EndIf;
	
EndProcedure

Procedure GetVATLocks(CalculationParameters)
	
	VATAccountingLocalization.GetVATLocks(CalculationParameters);
	
	TempTablesManager = CalculationParameters.TempTablesManager;
	If TempTablesManager.Tables.Find("BlockingVATDeduction") = Undefined Then
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	VALUE(Catalog.Companies.EmptyRef) AS Organization,
		|	UNDEFINED AS TaxInvoice,
		|	0 AS VAT
		|INTO BlockingVATDeduction
		|WHERE
		|	FALSE
		|;
		|SELECT
		|	VALUE(Catalog.Companies.EmptyRef) AS Organization,
		|	UNDEFINED AS TaxInvoice,
		|	UNDEFINED AS SaleExport,
		|	0 AS VAT
		|INTO BlockingVATDeductionSalesExport
		|WHERE
		|	FALSE";
		Query.TempTablesManager = CalculationParameters.TempTablesManager;
		Query.Execute();
	
	EndIf;
	
EndProcedure

Procedure GetReAdmittedToVATDeduction(CalculationParameters)
	
	VATAccountingLocalization.GetReAdmittedToVATDeduction(CalculationParameters);
	
	TempTablesManager = CalculationParameters.TempTablesManager;
	If TempTablesManager.Tables.Find("ReAcceptedForVATDeduction") = Undefined Then
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	VALUE(Catalog.Companies.EmptyRef) AS Organization,
		|	UNDEFINED AS TaxInvoice,
		|	UNDEFINED AS Vendor,
		|	UNDEFINED AS AssetTaxClass,
		|	UNDEFINED AS VATRate,
		|	UNDEFINED AS CorrectedTaxInvoice,
		|	UNDEFINED AS LineOfBusiness,
		|	0 AS AmountExcludingVAT,
		|	0 AS VAT,
		|	0 AS VATManag
		|INTO ReAcceptedForVATDeduction
		|WHERE
		|	FALSE";
		Query.TempTablesManager = CalculationParameters.TempTablesManager;
		Query.Execute();
	
	EndIf;
	
EndProcedure

Function CalculateRecordsOfVATChargedChangeOfActivity(CalculationParameters)
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	RECORDAUTONUMBER()                  AS RecNo,
	|	DD.Priority                       AS Priority,
	|	DD.Period                          AS Period,
	|	DD.Recorder                     AS Recorder,
	|	DD.RecordType                     AS RecordType,
	|	DD.Organization                     AS Organization,
	|	DD.TaxInvoice                     AS TaxInvoice,
	|	DD.Vendor                       AS Vendor,
	|	DD.AssetTaxClass                     AS AssetTaxClass,
	|	DD.VATRate                       AS VATRate,
	|	DD.VATActivityType              AS VATActivityType,
	|	DD.CorrectedTaxInvoice         AS CorrectedTaxInvoice,
	|	DD.SaleExport               AS SaleExport,
	|	DD.LineOfBusiness         AS LineOfBusiness,
	|	DD.AmountExcludingVAT                     AS AmountExcludingVAT,
	|	DD.VAT                             AS VAT,
	|	DD.VATManag                          AS VATManag,
	|	DD.Event                         AS Event,
	|	DD.CorVATActivityTypes           AS CorVATActivityTypes,
	|	DD.Department                   AS Department,
	|	DD.CorLineOfBusiness      AS CorLineOfBusiness,
	|	DD.ExpenseItem                  AS ExpenseItem,
	|	DD.DimensionOfExpenses               AS DimensionOfExpenses,
	|	DD.RowID             AS RowID,
	|	DD.PeriodEndTransaction            AS PeriodEndTransaction,
	|	DD.ReversingEntry                          AS ReversingEntry,
	|	CASE
	|		WHEN CorrectionVATDistribution.Ref IS NULL 
	|			THEN FALSE
	|		ELSE
	|			TRUE
	|	END                              AS AttributedToPreviousQuarter,
	|	CASE
	|		WHEN CorrectionVATDistribution.Ref IS NULL 
	|			THEN UNDEFINED
	|		ELSE
	|			ENDOFPERIOD(CorrectionVATDistribution.BeginOfPeriod, QUARTER)
	|	END                              AS CorrectionPeriod,
	|	CASE
	|		WHEN CorrectionVATDistribution.Ref IS NULL 
	|			THEN UNDEFINED
	|		ELSE
	|			CorrectionVATDistribution.Date
	|	END                              AS DateOfCorrectionOfVATDistribution,
	|	DD.FinRecordID          AS FinRecordID,
	|	DD.BusinessTransactionSetting  AS BusinessTransactionSetting
	|INTO VATChargedChangeOfActivity
	|FROM (
	|	SELECT
	|		2                                      AS Priority,
	|		Lots.Period                          AS Period,
	|		Lots.Recorder                     AS Recorder,
	|		VALUE(AccumulationRecordType.Expense) AS RecordType,
	|		Lots.Organization                     AS Organization,
	|		Lots.TaxInvoice                     AS TaxInvoice,
	|		Lots.Counterparty                      AS Vendor,
	|		Lots.AssetTaxClass                     AS AssetTaxClass,
	|		Lots.VATRate                       AS VATRate,
	|		Lots.VATActivityType              AS VATActivityType,
	|		ISNULL(CorrectionalSF.CorrectedTaxInvoice, UNDEFINED) AS CorrectedTaxInvoice,
	|		UNDEFINED                           AS SaleExport,
	|		Lots.LineOfBusiness         AS LineOfBusiness,
	|		Lots.AmountExcludingVAT                     AS AmountExcludingVAT,
	|		Lots.VAT                             AS VAT,
	|		Lots.VATManag                          AS VATManag,
	|		CASE
	|			WHEN Lots.DocumentSalesOfGoodsAndServices <> UNDEFINED 
	|					AND Lots.CorVATActivityTypes IN (&TaxationOfVATSalesForExport)
	|				THEN VALUE(Enum.EventsChargedVAT.SaleOfGoodsAndServices)
	|			WHEN Lots.DocumentSalesOfGoodsAndServices <> UNDEFINED 
	|					AND Lots.CorVATActivityTypes IN (VALUE(Enum.VATTaxationTypes.ProductionWithLongCycle),
	|													VALUE(Enum.VATTaxationTypes.SpaceActivity))
	|				THEN VALUE(Enum.EventsChargedVAT.SaleOfGoodsAndServices)
	|			WHEN Lots.CorVATActivityTypes IN (&ActivitiesVATIsIncludedInCost) THEN
	|				CASE 
	|					WHEN Lots.VATWriteOffItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|						THEN VALUE(Enum.EventsChargedVAT.IncludeVATInCostExpenses)
	|					ELSE VALUE(Enum.EventsChargedVAT.VATWritingOffAsExpenses)
	|				END
	|			ELSE VALUE(Enum.EventsChargedVAT.VATActivityTypeChange)
	|		END                                             AS Event,
	|		Lots.CorVATActivityTypes                      AS CorVATActivityTypes,
	|		Lots.VATWriteOffDivision                   AS Department,
	|		ISNULL(Lots.DirectionOfActivityOfDepreciationOfVAT,Lots.CorLineOfBusiness) AS CorLineOfBusiness,
	|		Lots.VATWriteOffItem                          AS ExpenseItem,
	|		Lots.DimensionVATWriteOff                       AS DimensionOfExpenses,
	|		""""                                              AS RowID,
	|		TRUE                                            AS PeriodEndTransaction,
	|		Lots.FinRecordID                     AS FinRecordID,
	|		Lots.BusinessTransactionSetting             AS BusinessTransactionSetting,
	|		Lots.ReversingEntry                                     AS ReversingEntry
	|	FROM
	|		Lots AS Lots
	|		LEFT JOIN 
	|			CorrectedInvoices AS CorrectionalSF
	|		ON
	|			Lots.Organization = CorrectionalSF.Organization
	|			AND Lots.TaxInvoice = CorrectionalSF.TaxInvoice
	|		
	|		LEFT JOIN
	|			VATDeductionsForExpenses AS VATDeductionsForExpenses
	|		ON
	|			Lots.Organization = VATDeductionsForExpenses.Organization
	|			AND Lots.TaxInvoice = VATDeductionsForExpenses.TaxInvoice
	|	
	|	WHERE
	|		(Lots.VATActivityType IN (&TypesOfActivitiesVATIsAcceptedForReimbursement)
	|			OR Lots.VATActivityType = VALUE(Enum.VATTaxationTypes.EmptyRef))
	|		AND CASE
	|			WHEN Lots.DocumentSalesOfGoodsAndServices <> UNDEFINED 
	|					AND Lots.CorVATActivityTypes IN (&TaxationOfVATSalesForExport)
	|				THEN VALUE(Enum.EventsChargedVAT.SaleOfGoodsAndServices)
	|			WHEN Lots.DocumentSalesOfGoodsAndServices <> UNDEFINED 
	|					AND Lots.CorVATActivityTypes IN (VALUE(Enum.VATTaxationTypes.ProductionWithLongCycle),
	|													VALUE(Enum.VATTaxationTypes.SpaceActivity))
	|				THEN VALUE(Enum.EventsChargedVAT.SaleOfGoodsAndServices)
	|			WHEN Lots.CorVATActivityTypes IN (&ActivitiesVATIsIncludedInCost)
	|				THEN VALUE(Enum.EventsChargedVAT.VATWritingOffAsExpenses)
	|			WHEN Lots.VATActivityType <> Lots.CorVATActivityTypes
	|				THEN VALUE(Enum.EventsChargedVAT.VATActivityTypeChange)
	|			ELSE UNDEFINED
	|		END <> UNDEFINED
	|		AND VATDeductionsForExpenses.TaxInvoice IS NULL
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		3                                      AS Priority,
	|		Lots.Period                          AS Period,
	|		Lots.Recorder                     AS Recorder,
	|		VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|		Lots.Organization                     AS Organization,
	|		Lots.TaxInvoice                     AS TaxInvoice,
	|		Lots.Counterparty                      AS Vendor,
	|		Lots.AssetTaxClass                     AS AssetTaxClass,
	|		Lots.VATRate                       AS VATRate,
	|		Lots.CorVATActivityTypes           AS VATActivityType,
	|		ISNULL(CorrectionalSF.CorrectedTaxInvoice, UNDEFINED) AS CorrectedTaxInvoice,
	|		CASE
	|			WHEN Lots.CorVATActivityTypes IN (&TaxationOfVATSalesForExport)
	|				THEN Lots.DocumentSalesOfGoodsAndServices
	|			WHEN Lots.CorVATActivityTypes IN (VALUE(Enum.VATTaxationTypes.ProductionWithLongCycle),
	|													VALUE(Enum.VATTaxationTypes.SpaceActivity))
	|				THEN Lots.DocumentSalesOfGoodsAndServices
	|			ELSE UNDEFINED
	|		END                                  AS SaleExport,
	|		Lots.CorLineOfBusiness      AS LineOfBusiness,
	|		Lots.AmountExcludingVAT                     AS AmountExcludingVAT,
	|		Lots.VAT                             AS VAT,
	|		Lots.VATManag                          AS VATManag,
	|		CASE
	|			WHEN Lots.DocumentSalesOfGoodsAndServices <> UNDEFINED
	|					AND Lots.CorVATActivityTypes IN (&TaxationOfVATSalesForExport)
	|				THEN VALUE(Enum.EventsChargedVAT.SaleOfGoodsAndServices)
	|			WHEN Lots.DocumentSalesOfGoodsAndServices <> UNDEFINED 
	|					AND Lots.CorVATActivityTypes IN (VALUE(Enum.VATTaxationTypes.ProductionWithLongCycle),
	|													VALUE(Enum.VATTaxationTypes.SpaceActivity))
	|				THEN VALUE(Enum.EventsChargedVAT.SaleOfGoodsAndServices)
	|			WHEN Lots.VATActivityType IN (&ActivitiesVATIsIncludedInCost)
	|				THEN VALUE(Enum.EventsChargedVAT.ExcludeVATFromCostExpenses)
	|			ELSE VALUE(Enum.EventsChargedVAT.VATActivityTypeChange)
	|		END                             AS Event,
	|		Lots.VATActivityType   AS CorVATActivityTypes,
	|		Lots.VATWriteOffDivision   AS Department,
	|		Lots.LineOfBusiness    AS CorLineOfBusiness,
	|		UNDEFINED                      AS ExpenseItem,
	|		UNDEFINED                      AS DimensionOfExpenses,
	|		""""                              AS RowID,
	|		TRUE                            AS PeriodEndTransaction,
	|		Lots.FinRecordID     AS FinRecordID,
	|		Lots.BusinessTransactionSetting AS BusinessTransactionSetting,
	|		Lots.ReversingEntry                     AS ReversingEntry
	|	FROM
	|		Lots AS Lots
	|		
	|		LEFT JOIN
	|			CorrectedInvoices AS CorrectionalSF
	|		ON 
	|			Lots.Organization = CorrectionalSF.Organization
	|			AND Lots.TaxInvoice = CorrectionalSF.TaxInvoice
	|		
	|		LEFT JOIN
	|			VATDeductionsForExpenses AS VATDeductionsForExpenses
	|		ON
	|			Lots.Organization = VATDeductionsForExpenses.Organization
	|			AND Lots.TaxInvoice = VATDeductionsForExpenses.TaxInvoice
	|		
	|	WHERE
	|		Lots.CorVATActivityTypes IN (&TypesOfActivitiesVATIsAcceptedForReimbursement)
	|		AND CASE
	|			WHEN Lots.DocumentSalesOfGoodsAndServices <> UNDEFINED 
	|					AND Lots.CorVATActivityTypes IN (&TaxationOfVATSalesForExport)
	|				THEN VALUE(Enum.EventsChargedVAT.SaleOfGoodsAndServices)
	|			WHEN Lots.DocumentSalesOfGoodsAndServices <> UNDEFINED 
	|					AND Lots.CorVATActivityTypes IN (VALUE(Enum.VATTaxationTypes.ProductionWithLongCycle),
	|													VALUE(Enum.VATTaxationTypes.SpaceActivity))
	|				THEN VALUE(Enum.EventsChargedVAT.SaleOfGoodsAndServices)
	|			WHEN Lots.VATActivityType IN (&ActivitiesVATIsIncludedInCost)
	|				THEN VALUE(Enum.EventsChargedVAT.ExcludeVATFromCostExpenses)
	|			WHEN Lots.VATActivityType <> Lots.CorVATActivityTypes
	|				THEN VALUE(Enum.EventsChargedVAT.VATActivityTypeChange)
	|			ELSE UNDEFINED
	|		END <> UNDEFINED
	|		AND VATDeductionsForExpenses.TaxInvoice IS NULL
	|	
	|	UNION ALL
	|	
	|	// We will process the changes in the type of activity of the parties for which VAT was written off by the document Write-offs.
	|	SELECT
	|		2,
	|		Lots.Period,
	|		Lots.Recorder,
	|		VALUE(AccumulationRecordType.Expense),
	|		Lots.Organization,
	|		Lots.TaxInvoice,
	|		Lots.Counterparty,
	|		Lots.AssetTaxClass,
	|		Lots.VATRate,
	|		Lots.VATActivityType,
	|		ISNULL(CorrectionalSF.CorrectedTaxInvoice, UNDEFINED),
	|		UNDEFINED,
	|		Lots.LineOfBusiness,
	|		-Lots.AmountExcludingVAT,
	|		-Lots.VAT,
	|		-Lots.VATManag,
	|		VALUE(Enum.EventsChargedVAT.VATWritingOffAsExpenses),
	|		UNDEFINED,
	|		VATDeductionsForExpenses.Department     AS Department,
	|		Lots.CorLineOfBusiness      AS CorLineOfBusiness,
	|		VATDeductionsForExpenses.ExpenseItem    AS ExpenseItem,
	|		VATDeductionsForExpenses.DimensionOfExpenses AS DimensionOfExpenses,
	|		"""",
	|		TRUE,
	|		Lots.FinRecordID AS FinRecordID,
	|		VALUE(Catalog.BusinessTransactionsSettings.VATOnAcquiredAssetsWriteOff) AS BusinessTransactionSetting,
	|		Lots.ReversingEntry
	|	FROM
	|		Lots AS Lots
	|		
	|		LEFT JOIN 
	|			CorrectedInvoices AS CorrectionalSF
	|		ON 
	|			Lots.Organization = CorrectionalSF.Organization
	|			AND Lots.TaxInvoice = CorrectionalSF.TaxInvoice
	|		
	|		INNER JOIN 
	|			VATDeductionsForExpenses
	|		ON 
	|			Lots.Organization = VATDeductionsForExpenses.Organization
	|			AND Lots.TaxInvoice = VATDeductionsForExpenses.TaxInvoice
	|	
	|	WHERE
	|		Lots.CorVATActivityTypes = VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		AND Lots.CorVATActivityTypes <> Lots.VATActivityType
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		3,
	|		Lots.Period,
	|		Lots.Recorder,
	|		VALUE(AccumulationRecordType.Expense),
	|		Lots.Organization,
	|		Lots.TaxInvoice,
	|		Lots.Counterparty,
	|		Lots.AssetTaxClass,
	|		Lots.VATRate,
	|		Lots.VATActivityType,
	|		ISNULL(CorrectionalSF.CorrectedTaxInvoice, UNDEFINED),
	|		UNDEFINED,
	|		Lots.LineOfBusiness,
	|		Lots.AmountExcludingVAT,
	|		Lots.VAT,
	|		Lots.VATManag,
	|		VALUE(Enum.EventsChargedVAT.IncludeVATInCostExpenses),
	|		UNDEFINED,
	|		UNDEFINED     AS Department,
	|		Lots.CorLineOfBusiness AS CorLineOfBusiness,
	|		UNDEFINED     AS ExpenseItem,
	|		UNDEFINED     AS DimensionOfExpenses,
	|		"""",
	|		TRUE,
	|		Lots.FinRecordID AS FinRecordID,
	|		VALUE(Catalog.BusinessTransactionsSettings.VATOnAcquiredAssetsWriteOff) AS BusinessTransactionSetting,
	|		Lots.ReversingEntry
	|	FROM
	|		Lots AS Lots
	|		
	|		LEFT JOIN 
	|			CorrectedInvoices AS CorrectionalSF
	|		ON 
	|			Lots.Organization = CorrectionalSF.Organization
	|			AND Lots.TaxInvoice = CorrectionalSF.TaxInvoice
	|		
	|		INNER JOIN 
	|			VATDeductionsForExpenses
	|		ON 
	|			Lots.Organization = VATDeductionsForExpenses.Organization
	|			AND Lots.TaxInvoice = VATDeductionsForExpenses.TaxInvoice
	|	WHERE
	|		Lots.CorVATActivityTypes = VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		AND Lots.CorVATActivityTypes <> Lots.VATActivityType
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		2,
	|		Lots.Period,
	|		Lots.Recorder,
	|		VALUE(AccumulationRecordType.Receipt),
	|		Lots.Organization,
	|		Lots.TaxInvoice,
	|		Lots.Counterparty,
	|		Lots.AssetTaxClass,
	|		Lots.VATRate,
	|		Lots.CorVATActivityTypes,
	|		ISNULL(CorrectionalSF.CorrectedTaxInvoice, UNDEFINED),
	|		UNDEFINED,
	|		Lots.CorLineOfBusiness,
	|		Lots.AmountExcludingVAT,
	|		Lots.VAT,
	|		Lots.VATManag,
	|		VALUE(Enum.EventsChargedVAT.ExcludeVATFromCostExpenses),
	|		Lots.VATActivityType,
	|		UNDEFINED     AS Department,
	|		Lots.LineOfBusiness AS CorLineOfBusiness,
	|		UNDEFINED     AS ExpenseItem,
	|		UNDEFINED     AS DimensionOfExpenses,
	|		"""",
	|		TRUE,
	|		Lots.FinRecordID AS FinRecordID,
	|		VALUE(Catalog.BusinessTransactionsSettings.VATOnAcquiredAssetsWriteOff) AS BusinessTransactionSetting,
	|		Lots.ReversingEntry
	|	FROM
	|		Lots AS Lots
	|		
	|		LEFT JOIN 
	|			CorrectedInvoices AS CorrectionalSF
	|		ON 
	|			Lots.Organization = CorrectionalSF.Organization
	|			AND Lots.TaxInvoice = CorrectionalSF.TaxInvoice
	|		
	|		INNER JOIN 
	|			VATDeductionsForExpenses
	|		ON 
	|			Lots.Organization = VATDeductionsForExpenses.Organization
	|			AND Lots.TaxInvoice = VATDeductionsForExpenses.TaxInvoice
	|	WHERE
	|		Lots.VATActivityType = VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		AND Lots.CorVATActivityTypes <> Lots.VATActivityType
	|	) AS DD
	|	LEFT JOIN
	|		Document.VATAllocation AS CorrectionVATDistribution
	|	ON
	|		DD.Recorder = CorrectionVATDistribution.Ref
	|		AND CorrectionVATDistribution.Patch
	|		AND BEGINOFPERIOD(CorrectionVATDistribution.BeginOfPeriod, QUARTER) <> BEGINOFPERIOD(CorrectionVATDistribution.Date, QUARTER)
	|";
	
	Query.SetParameter("BeginOfPeriod",           CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",            CalculationParameters.EndOfPeriod);
	Query.SetParameter("CompanyArray",       CalculationParameters.CompanyArray);
	Query.SetParameter("TypesOfActivitiesVATIsAcceptedForReimbursement", VATAccountingERP.TypesOfActivitiesVATIsAcceptedForReimbursement());
	Query.SetParameter("ActivitiesVATIsIncludedInCost", VATAccountingERP.ActivitiesVATIsIncludedInCost());
	Query.SetParameter("TaxationOfVATSalesForExport", TaxationOfVATSalesForExport());
	
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.Execute();
	
	Return "VATChargedChangeOfActivity";
	
EndFunction

Function CalculateRecordsOfVATChargedChangeOfBusinessDirection(CalculationParameters)
	
	Query = New Query;
	Query.Text = 
	"
	// We will process the change of direction of activity
	|SELECT
	|	2                                      AS Priority,
	|	Lots.Period                          AS Period,
	|	Lots.Recorder                     AS Recorder,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	Lots.Organization                     AS Organization,
	|	Lots.TaxInvoice                     AS TaxInvoice,
	|	Lots.Counterparty                      AS Vendor,
	|	Lots.AssetTaxClass                     AS AssetTaxClass,
	|	Lots.VATRate                       AS VATRate,
	|	Lots.VATActivityType        AS VATActivityType,
	|	ISNULL(CorrectionalSF.CorrectedTaxInvoice, UNDEFINED) AS CorrectedTaxInvoice,
	|	UNDEFINED                           AS SaleExport,
	|	Lots.LineOfBusiness         AS LineOfBusiness,
	|	Lots.AmountExcludingVAT                     AS AmountExcludingVAT,
	|	Lots.VAT                             AS VAT,
	|	Lots.VATManag                          AS VATManag,
	|	VALUE(Enum.EventsChargedVAT.ChangeLineOfBusiness) AS Event,
	|	Lots.CorVATActivityTypes           AS CorVATActivityTypes,
	|	Lots.VATWriteOffDivision        AS Department,
	|	Lots.CorLineOfBusiness      AS CorLineOfBusiness,
	|	Lots.VATWriteOffItem               AS ExpenseItem,
	|	Lots.DimensionVATWriteOff            AS DimensionOfExpenses,
	|	""""                                   AS RowID,
	|	TRUE                                 AS PeriodEndTransaction,
	|	Lots.FinRecordID          AS FinRecordID,
	|	Lots.BusinessTransactionSetting  AS BusinessTransactionSetting,
	|	Lots.ReversingEntry                          AS ReversingEntry
	|INTO VATChargedChangeOfDirection_Preliminary
	|FROM
	|	Lots AS Lots
	|	LEFT JOIN CorrectedInvoices AS CorrectionalSF
	|		ON Lots.Organization = CorrectionalSF.Organization
	|			AND Lots.TaxInvoice = CorrectionalSF.TaxInvoice
	|	LEFT JOIN VATDeductionsForExpenses
	|		ON Lots.Organization = VATDeductionsForExpenses.Organization
	|			AND Lots.TaxInvoice = VATDeductionsForExpenses.TaxInvoice
	|	LEFT JOIN
	|		VATChargedChangeOfActivity AS ChangingTypeOfActivity
	|	ON
	|		Lots.Organization   = ChangingTypeOfActivity.Organization
	|		AND Lots.TaxInvoice = ChangingTypeOfActivity.TaxInvoice
	|		AND Lots.Counterparty   = ChangingTypeOfActivity.Vendor
	|		AND Lots.AssetTaxClass = ChangingTypeOfActivity.AssetTaxClass
	|		AND Lots.VATRate   = ChangingTypeOfActivity.VATRate
	|		AND Lots.VATActivityType = ChangingTypeOfActivity.VATActivityType
	|		AND Lots.Recorder = ChangingTypeOfActivity.Recorder
	|		AND Lots.FinRecordID = ChangingTypeOfActivity.FinRecordID
	|WHERE
	|	Lots.LineOfBusiness <> Lots.CorLineOfBusiness
	|	AND VATDeductionsForExpenses.TaxInvoice IS NULL
	|	AND ChangingTypeOfActivity.TaxInvoice IS NULL
	|
	|UNION ALL
	|
	|SELECT
	|	3,
	|	Lots.Period,
	|	Lots.Recorder,
	|	VALUE(AccumulationRecordType.Receipt),
	|	Lots.Organization,
	|	Lots.TaxInvoice,
	|	Lots.Counterparty,
	|	Lots.AssetTaxClass,
	|	Lots.VATRate,
	|	Lots.CorVATActivityTypes,
	|	ISNULL(CorrectionalSF.CorrectedTaxInvoice, UNDEFINED),
	|	UNDEFINED,
	|	Lots.CorLineOfBusiness,
	|	Lots.AmountExcludingVAT,
	|	Lots.VAT,
	|	Lots.VATManag,
	|	VALUE(Enum.EventsChargedVAT.ChangeLineOfBusiness),
	|	Lots.VATActivityType,
	|	UNDEFINED                      AS Department,
	|	Lots.LineOfBusiness    AS LineOfBusiness,
	|	UNDEFINED                      AS ExpenseItem,
	|	UNDEFINED                      AS DimensionOfExpenses,
	|	"""",
	|	TRUE,
	|	Lots.FinRecordID,
	|	Lots.BusinessTransactionSetting,
	|	Lots.ReversingEntry
	|FROM
	|	Lots AS Lots
	|	LEFT JOIN CorrectedInvoices AS CorrectionalSF
	|		ON Lots.Organization = CorrectionalSF.Organization
	|			AND Lots.TaxInvoice = CorrectionalSF.TaxInvoice
	|	LEFT JOIN VATDeductionsForExpenses
	|		ON Lots.Organization = VATDeductionsForExpenses.Organization
	|			AND Lots.TaxInvoice = VATDeductionsForExpenses.TaxInvoice
	|	LEFT JOIN
	|		VATChargedChangeOfActivity AS ChangingTypeOfActivity
	|	ON
	|		Lots.Organization   = ChangingTypeOfActivity.Organization
	|		AND Lots.TaxInvoice = ChangingTypeOfActivity.TaxInvoice
	|		AND Lots.Counterparty   = ChangingTypeOfActivity.Vendor
	|		AND Lots.AssetTaxClass = ChangingTypeOfActivity.AssetTaxClass
	|		AND Lots.VATRate   = ChangingTypeOfActivity.VATRate
	|		AND Lots.CorVATActivityTypes = ChangingTypeOfActivity.VATActivityType
	|		AND Lots.Recorder = ChangingTypeOfActivity.Recorder
	|		AND Lots.FinRecordID = ChangingTypeOfActivity.FinRecordID
	|	
	|WHERE
	|	Lots.LineOfBusiness <> Lots.CorLineOfBusiness
	|	AND VATDeductionsForExpenses.TaxInvoice IS NULL
	|	AND ChangingTypeOfActivity.TaxInvoice IS NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BalanceAndRegisteredRecords.Organization AS Organization,
	|	BalanceAndRegisteredRecords.TaxInvoice AS TaxInvoice,
	|	BalanceAndRegisteredRecords.Vendor AS Vendor,
	|	BalanceAndRegisteredRecords.AssetTaxClass AS AssetTaxClass,
	|	BalanceAndRegisteredRecords.VATRate AS VATRate,
	|	BalanceAndRegisteredRecords.VATActivityType AS VATActivityType,
	|	BalanceAndRegisteredRecords.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|	BalanceAndRegisteredRecords.SaleExport AS SaleExport,
	|	SUM(BalanceAndRegisteredRecords.AmountExcludingVAT) AS AmountExcludingVAT,
	|	SUM(BalanceAndRegisteredRecords.VAT) AS VAT,
	|	SUM(BalanceAndRegisteredRecords.VATManag) AS VATManag
	|INTO VATPresentedBalanceAtBeginningAndEndOfMovement
	|FROM
	|	(SELECT
	|		Balance.Organization AS Organization,
	|		Balance.TaxInvoice AS TaxInvoice,
	|		Balance.Vendor AS Vendor,
	|		Balance.AssetTaxClass AS AssetTaxClass,
	|		Balance.VATRate AS VATRate,
	|		Balance.VATActivityType AS VATActivityType,
	|		Balance.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|		Balance.SaleExport AS SaleExport,
	|		Balance.AmountExcludingVAT AS AmountExcludingVAT,
	|		Balance.VAT AS VAT,
	|		Balance.VATManag AS VATManag
	|	FROM
	|		VATPresentedBalanceAtBeginning AS Balance
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		OnlineRegisteredRecords.Organization,
	|		OnlineRegisteredRecords.TaxInvoice,
	|		OnlineRegisteredRecords.Vendor,
	|		OnlineRegisteredRecords.AssetTaxClass,
	|		OnlineRegisteredRecords.VATRate,
	|		OnlineRegisteredRecords.VATActivityType,
	|		OnlineRegisteredRecords.CorrectedTaxInvoice,
	|		OnlineRegisteredRecords.SaleExport,
	|		OnlineRegisteredRecords.AmountExcludingVAT,
	|		OnlineRegisteredRecords.VAT,
	|		OnlineRegisteredRecords.VATManag
	|	FROM
	|		VATChargedOnlineTraffic AS OnlineRegisteredRecords
	|	WHERE
	|		OnlineRegisteredRecords.VAT > 0
	|			AND OnlineRegisteredRecords.VATActivityType <> VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)) AS BalanceAndRegisteredRecords
	|
	|GROUP BY
	|	BalanceAndRegisteredRecords.VATRate,
	|	BalanceAndRegisteredRecords.CorrectedTaxInvoice,
	|	BalanceAndRegisteredRecords.VATActivityType,
	|	BalanceAndRegisteredRecords.SaleExport,
	|	BalanceAndRegisteredRecords.Vendor,
	|	BalanceAndRegisteredRecords.AssetTaxClass,
	|	BalanceAndRegisteredRecords.TaxInvoice,
	|	BalanceAndRegisteredRecords.Organization
	|;
	|
	|SELECT
	|	DD.Priority                  AS Priority,
	|	DD.Period                     AS Period,
	|	DD.Recorder                AS Recorder,
	|	DD.RecordType                AS RecordType,
	|	DD.Organization                AS Organization,
	|	DD.TaxInvoice                AS TaxInvoice,
	|	DD.Vendor                  AS Vendor,
	|	DD.AssetTaxClass                AS AssetTaxClass,
	|	DD.VATRate                  AS VATRate,
	|	DD.VATActivityType         AS VATActivityType,
	|	DD.CorrectedTaxInvoice    AS CorrectedTaxInvoice,
	|	DD.SaleExport          AS SaleExport,
	|	DD.LineOfBusiness    AS LineOfBusiness,
	|	CASE
	|		WHEN Balance.AmountExcludingVAT > DD.AmountExcludingVAT
	|			THEN DD.AmountExcludingVAT
	|		ELSE Balance.AmountExcludingVAT
	|	END                         AS AmountExcludingVAT,
	|	CASE
	|		WHEN Balance.VAT > DD.VAT
	|			THEN DD.VAT
	|		ELSE Balance.VAT
	|	END                         AS VAT,
	|	CASE
	|		WHEN Balance.VATManag > DD.VATManag
	|			THEN DD.VATManag
	|		ELSE Balance.VATManag
	|	END                         AS VATManag,
	|	DD.Event                    AS Event,
	|	DD.CorVATActivityTypes      AS CorVATActivityTypes,
	|	DD.Department              AS Department,
	|	DD.CorLineOfBusiness AS CorLineOfBusiness,
	|	DD.ExpenseItem             AS ExpenseItem,
	|	DD.DimensionOfExpenses          AS DimensionOfExpenses,
	|	DD.RowID        AS RowID,
	|	DD.PeriodEndTransaction       AS PeriodEndTransaction,
	|	DD.ReversingEntry                     AS ReversingEntry,
	|	DD.FinRecordID     AS FinRecordID,
	|	DD.BusinessTransactionSetting AS BusinessTransactionSetting
	|INTO VATChargedChangeOfDirection
	|FROM
	|	VATChargedChangeOfDirection_Preliminary AS DD
	|	INNER JOIN
	|		VATPresentedBalanceAtBeginningAndEndOfMovement AS Balance
	|	ON
	|		DD.Organization   = Balance.Organization
	|		AND DD.TaxInvoice = Balance.TaxInvoice
	|		AND DD.Vendor   = Balance.Vendor
	|		AND DD.AssetTaxClass = Balance.AssetTaxClass
	|		AND DD.VATRate   = Balance.VATRate
	|		AND DD.VATActivityType = Balance.VATActivityType
	|		AND DD.CorrectedTaxInvoice = Balance.CorrectedTaxInvoice
	|		AND DD.SaleExport = Balance.SaleExport
	|WHERE Balance.VAT > 0
	|";
	
	Query.SetParameter("BeginOfPeriod",           CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",            CalculationParameters.EndOfPeriod);
	Query.SetParameter("CompanyArray",       CalculationParameters.CompanyArray);
	
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.Execute();
	
	Return "VATChargedChangeOfDirection"
	
EndFunction

Function CalculateVATRecordsSubmittedByISF(CalculationParameters)
	 
	Query = New Query;
	Query.Text =
	"SELECT
	|	CorrectedInvoices.Ref           AS Recorder,
	|	CorrectedInvoices.DateReceived    AS Period,
	|	CorrectedInvoices.CorrectedTaxInvoice AS CurrentCorrectedInvoice,
	|	VATInvoiced.RecordType                AS RecordType,
	|	VATInvoiced.Organization                AS Organization,
	|	VATInvoiced.TaxInvoice                AS TaxInvoice,
	|	VATInvoiced.Vendor                  AS Vendor,
	|	VATInvoiced.AssetTaxClass                AS AssetTaxClass,
	|	VATInvoiced.VATRate                  AS VATRate,
	|	VATInvoiced.VATActivityType         AS VATActivityType,
	|	VATInvoiced.CorrectedTaxInvoice    AS CorrectedTaxInvoice,
	|	VATInvoiced.SaleExport          AS SaleExport,
	|	VATInvoiced.LineOfBusiness    AS LineOfBusiness,
	|	VATInvoiced.AmountExcludingVAT                AS AmountExcludingVAT,
	|	VATInvoiced.VAT                        AS VAT,
	|	VATInvoiced.VATManag                     AS VATManag,
	|	VATInvoiced.Event                    AS Event,
	|	VATInvoiced.CorVATActivityTypes      AS CorVATActivityTypes,
	|	VATInvoiced.Department              AS Department,
	|	VATInvoiced.RowID        AS RowID,
	|	VATInvoiced.CorLineOfBusiness AS CorLineOfBusiness,
	|	VATInvoiced.ExpenseItem             AS ExpenseItem,
	|	VATInvoiced.DimensionOfExpenses          AS DimensionOfExpenses,
	|	VATInvoiced.FinRecordID     AS FinRecordID,
	|	VATInvoiced.BusinessTransactionSetting AS BusinessTransactionSetting
	|INTO VATSubmittedCorrectedInvoices
	|FROM
	|	CorrectedInvoices AS CorrectedInvoices
	|	INNER JOIN
	|		AccumulationRegister.VATInvoiced AS VATInvoiced
	|	ON
	|		VATInvoiced.Organization = CorrectedInvoices.Organization
	|		AND VATInvoiced.TaxInvoice = CorrectedInvoices.TaxInvoice
	|		AND VATInvoiced.Period < &BeginOfPeriod
	|		AND VATInvoiced.CorrectedTaxInvoice <> CorrectedInvoices.CorrectedTaxInvoice
	|		AND VATInvoiced.Active
	|		AND NOT VATInvoiced.Recorder REFS Document.ReversingEntry
	|
	|UNION ALL
	|
	|SELECT
	|	CorrectedInvoices.Ref AS Recorder,
	|	CorrectedInvoices.DateReceived AS Period,
	|	CorrectedInvoices.CorrectedTaxInvoice,
	|	VATInvoiced.RecordType,
	|	VATInvoiced.Organization,
	|	VATInvoiced.TaxInvoice,
	|	VATInvoiced.Vendor,
	|	VATInvoiced.AssetTaxClass,
	|	VATInvoiced.VATRate,
	|	VATInvoiced.VATActivityType,
	|	VATInvoiced.CorrectedTaxInvoice,
	|	VATInvoiced.SaleExport,
	|	VATInvoiced.LineOfBusiness,
	|	VATInvoiced.AmountExcludingVAT,
	|	VATInvoiced.VAT,
	|	VATInvoiced.VATManag,
	|	VATInvoiced.Event,
	|	VATInvoiced.CorVATActivityTypes,
	|	VATInvoiced.Department,
	|	VATInvoiced.RowID,
	|	VATInvoiced.CorLineOfBusiness,
	|	VATInvoiced.ExpenseItem,
	|	VATInvoiced.DimensionOfExpenses,
	|	VATInvoiced.FinRecordID,
	|	VATInvoiced.BusinessTransactionSetting
	|FROM
	|	CorrectedInvoices AS CorrectedInvoices
	|	INNER JOIN
	|		AccumulationRegister.VATInvoiced AS VATInvoiced
	|	ON
	|		VATInvoiced.Organization = CorrectedInvoices.Organization
	|		AND VATInvoiced.TaxInvoice = CorrectedInvoices.TaxInvoice
	|		AND VATInvoiced.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND VATInvoiced.CorrectedTaxInvoice <> CorrectedInvoices.CorrectedTaxInvoice
	|		AND NOT VATInvoiced.PeriodEndTransaction
	|		AND VATInvoiced.Active
	|		AND NOT VATInvoiced.Recorder REFS Document.ReversingEntry
	|
	|INDEX BY
	|	Event
	|";
	Query.SetParameter("BeginOfPeriod", CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",  CalculationParameters.EndOfPeriod);
	Query.SetParameter("CompanyArray", CalculationParameters.CompanyArray);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.Execute();
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	1                                           AS Priority,
	|	VATInvoiced.Recorder                AS Recorder,
	|	CASE
	|		WHEN VATInvoiced.Period < &BeginOfPeriod
	|			THEN &EndOfPeriod
	|		ELSE VATInvoiced.Period
	|	END                                       AS Period,
	|	VATInvoiced.RecordType                AS RecordType,
	|	VATInvoiced.Organization                AS Organization,
	|	VATInvoiced.TaxInvoice                AS TaxInvoice,
	|	VATInvoiced.Vendor                  AS Vendor,
	|	VATInvoiced.AssetTaxClass                AS AssetTaxClass,
	|	VATInvoiced.VATRate                  AS VATRate,
	|	VATInvoiced.VATActivityType         AS VATActivityType,
	|	VATInvoiced.CorrectedTaxInvoice    AS CorrectedTaxInvoice,
	|	VATInvoiced.SaleExport          AS SaleExport,
	|	VATInvoiced.LineOfBusiness    AS LineOfBusiness,
	|	SUM(VATInvoiced.AmountExcludingVAT)         AS AmountExcludingVAT,
	|	SUM(VATInvoiced.VAT)                 AS VAT,
	|	SUM(VATInvoiced.VATManag)              AS VATManag,
	|	VATInvoiced.Event                    AS Event,
	|	VATInvoiced.CorVATActivityTypes      AS CorVATActivityTypes,
	|	TRUE                                      AS PeriodEndTransaction,
	|	FALSE                                        AS ReversingEntry,
	|	VATInvoiced.Department              AS Department,
	|	VATInvoiced.RowID        AS RowID,
	|	VATInvoiced.CorLineOfBusiness AS CorLineOfBusiness,
	|	VATInvoiced.ExpenseItem             AS ExpenseItem,
	|	VATInvoiced.DimensionOfExpenses          AS DimensionOfExpenses,
	|	VATInvoiced.FinRecordID     AS FinRecordID,
	|	VATInvoiced.BusinessTransactionSetting AS BusinessTransactionSetting
	|INTO VATPresentedUnderISF
	|FROM
	|	(SELECT
	|		VATInvoiced.Recorder,
	|		VATInvoiced.Period,
	|		VATInvoiced.RecordType,
	|		VATInvoiced.Organization,
	|		VATInvoiced.TaxInvoice,
	|		VATInvoiced.Vendor,
	|		VATInvoiced.AssetTaxClass,
	|		VATInvoiced.VATRate,
	|		VATInvoiced.VATActivityType,
	|		VATInvoiced.CorrectedTaxInvoice,
	|		VATInvoiced.SaleExport,
	|		VATInvoiced.LineOfBusiness,
	|		- VATInvoiced.AmountExcludingVAT AS AmountExcludingVAT,
	|		- VATInvoiced.VAT AS VAT,
	|		- VATInvoiced.VATManag AS VATManag,
	|		VATInvoiced.Event,
	|		VATInvoiced.CorVATActivityTypes,
	|		VATInvoiced.RowID,
	|		VATInvoiced.Department,
	|		VATInvoiced.CorLineOfBusiness,
	|		VATInvoiced.ExpenseItem,
	|		VATInvoiced.DimensionOfExpenses,
	|		VATInvoiced.FinRecordID,
	|		VATInvoiced.BusinessTransactionSetting
	|	FROM
	|		VATSubmittedCorrectedInvoices AS VATInvoiced
	|		
	|	UNION ALL
	|		
	|	SELECT
	|		VATInvoiced.Recorder,
	|		VATInvoiced.Period,
	|		VATInvoiced.RecordType,
	|		VATInvoiced.Organization,
	|		VATInvoiced.TaxInvoice,
	|		VATInvoiced.Vendor,
	|		VATInvoiced.AssetTaxClass,
	|		VATInvoiced.VATRate,
	|		VATInvoiced.VATActivityType,
	|		VATInvoiced.CurrentCorrectedInvoice,
	|		VATInvoiced.SaleExport,
	|		VATInvoiced.LineOfBusiness,
	|		VATInvoiced.AmountExcludingVAT AS AmountExcludingVAT,
	|		VATInvoiced.VAT AS VAT,
	|		VATInvoiced.VATManag AS VATManag,
	|		VATInvoiced.Event,
	|		VATInvoiced.CorVATActivityTypes,
	|		VATInvoiced.RowID,
	|		VATInvoiced.Department,
	|		VATInvoiced.CorLineOfBusiness,
	|		VATInvoiced.ExpenseItem,
	|		VATInvoiced.DimensionOfExpenses,
	|		VATInvoiced.FinRecordID,
	|		VATInvoiced.BusinessTransactionSetting
	|	FROM
	|		VATSubmittedCorrectedInvoices AS VATInvoiced
	|	WHERE
	|		NOT VATInvoiced.Event IN (
	|				VALUE(Enum.EventsChargedVAT.VATAcceptedForDeduction),
	|				VALUE(Enum.EventsChargedVAT.Rate0IsConfirmed),
	|				VALUE(Enum.EventsChargedVAT.NotRate0IsConfirmed),
	|				VALUE(Enum.EventsChargedVAT.ReverseVATForActivityType),
	|				VALUE(Enum.EventsChargedVAT.ReverseVATByCTI)
	|				)
	|	) AS VATInvoiced
	|
	|GROUP BY
	|	VATInvoiced.Recorder,
	|	CASE
	|		WHEN VATInvoiced.Period < &BeginOfPeriod
	|			THEN &EndOfPeriod
	|		ELSE VATInvoiced.Period
	|	END,
	|	VATInvoiced.RecordType,
	|	VATInvoiced.Organization,
	|	VATInvoiced.TaxInvoice,
	|	VATInvoiced.Vendor,
	|	VATInvoiced.AssetTaxClass,
	|	VATInvoiced.VATRate,
	|	VATInvoiced.VATActivityType,
	|	VATInvoiced.CorrectedTaxInvoice,
	|	VATInvoiced.SaleExport,
	|	VATInvoiced.LineOfBusiness,
	|	VATInvoiced.Event,
	|	VATInvoiced.CorVATActivityTypes,
	|	VATInvoiced.RowID,
	|	VATInvoiced.Department,
	|	VATInvoiced.CorLineOfBusiness,
	|	VATInvoiced.ExpenseItem,
	|	VATInvoiced.DimensionOfExpenses,
	|	VATInvoiced.FinRecordID,
	|	VATInvoiced.BusinessTransactionSetting
	|
	|HAVING 
	|	SUM(VATInvoiced.VAT) <> 0
	|
	|INDEX BY
	|	Recorder
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP VATSubmittedCorrectedInvoices
	|";
	
	Query.SetParameter("BeginOfPeriod", CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",  CalculationParameters.EndOfPeriod);
	Query.SetParameter("CompanyArray", CalculationParameters.CompanyArray);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.Execute();
	
	Return "VATPresentedUnderISF";
	
EndFunction

Function CalculateRecordsOfVATPresentedRecoveryUnderTypeOfActivity(CalculationParameters)
	
	VATAccountingLocalization.CalculateRecordsOfVATPresentedRecoveryUnderTypeOfActivity(CalculationParameters);
	
	TempTablesManager = CalculationParameters.TempTablesManager;
	If TempTablesManager.Tables.Find("VATPresentedRecoveryUnderTypeOfActivity") = Undefined Then
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	1 AS Priority,
		|	DATETIME(1, 1, 1) AS Period,
		|	UNDEFINED AS Recorder,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	VALUE(Catalog.Companies.EmptyRef) AS Organization,
		|	UNDEFINED AS TaxInvoice,
		|	VALUE(Catalog.Counterparties.EmptyRef) AS Vendor,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS AssetTaxClass,
		|	VALUE(Catalog.VATRates.EmptyRef) AS VATRate,
		|	VALUE(Enum.AssetKinds.EmptyRef) AS VATActivityType,
		|	UNDEFINED AS CorrectedTaxInvoice,
		|	UNDEFINED AS SaleExport,
		|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
		|	FALSE AS AttributedToPreviousQuarter,
		|	DATETIME(1, 1, 1) AS CorrectionPeriod,
		|	DATETIME(1, 1, 1) AS DateOfCorrectionOfVATDistribution,
		|	0 AS AmountExcludingVAT,
		|	0 AS VAT,
		|	0 AS VATManag,
		|	VALUE(Enum.EventsChargedVAT.EmptyRef) AS Event,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS CorVATActivityTypes,
		|	UNDEFINED AS Department,
		|	UNDEFINED AS CorLineOfBusiness,
		|	UNDEFINED AS ExpenseItem,
		|	UNDEFINED AS DimensionOfExpenses,
		|	"""" AS RowID,
		|	TRUE AS PeriodEndTransaction,
		|	FALSE AS ReversingEntry,
		|	VALUE(Catalog.BusinessTransactionsSettings.EmptyRef) AS BusinessTransactionSetting
		|INTO VATPresentedRecoveryUnderTypeOfActivity
		|WHERE
		|	FALSE";
		Query.TempTablesManager = CalculationParameters.TempTablesManager;
		Query.Execute();
	
	EndIf;
	
	TMCommonUse.AddIDsToTemporaryTable(
		"VATPresentedRecoveryUnderTypeOfActivity", CalculationParameters.TempTablesManager, "FinRecordID");
	
	Return "VATPresentedRecoveryUnderTypeOfActivity";
	
EndFunction

Procedure GetRemainingVATPresentedAtEndOfPeriod(CalculationParameters)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	VATInvoiced.Organization AS Organization,
	|	VATInvoiced.TaxInvoice,
	|	VATInvoiced.Vendor,
	|	VATInvoiced.AssetTaxClass,
	|	VATInvoiced.VATRate,
	|	VATInvoiced.VATActivityType,
	|	VATInvoiced.CorrectedTaxInvoice,
	|	VATInvoiced.SaleExport,
	|	VATInvoiced.LineOfBusiness,
	|	MAX(VATInvoiced.AttributedToPreviousQuarter)      AS AttributedToPreviousQuarter,
	|	MAX(VATInvoiced.CorrectionPeriod)               AS CorrectionPeriod,
	|	MAX(VATInvoiced.DateOfCorrectionOfVATDistribution)  AS DateOfCorrectionOfVATDistribution,
	|	SUM(VATInvoiced.AmountExcludingVAT) AS AmountExcludingVAT,
	|	SUM(VATInvoiced.VAT) AS VAT,
	|	SUM(VATInvoiced.VATManag) AS VATManag
	|INTO VATPresentedBalancesAtEndOfPeriod 
	|FROM
	|	(SELECT
	|		DD.Organization             AS Organization,
	|		DD.TaxInvoice             AS TaxInvoice,
	|		DD.Vendor               AS Vendor,
	|		DD.AssetTaxClass             AS AssetTaxClass,
	|		DD.VATRate               AS VATRate,
	|		DD.VATActivityType  AS VATActivityType,
	|		DD.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|		DD.SaleExport       AS SaleExport,
	|		DD.LineOfBusiness AS LineOfBusiness,
	|		FALSE                       AS AttributedToPreviousQuarter,
	|		DATETIME(1,1,1)           AS CorrectionPeriod,
	|		DATETIME(1,1,1)           AS DateOfCorrectionOfVATDistribution,
	|		DD.AmountExcludingVAT             AS AmountExcludingVAT,
	|		DD.VAT                     AS VAT,
	|		DD.VATManag                  AS VATManag
	|	FROM
	|		VATPresentedBalanceAtBeginningWithDirections AS DD
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DD.Organization,
	|		DD.TaxInvoice,
	|		DD.Vendor,
	|		DD.AssetTaxClass,
	|		DD.VATRate,
	|		DD.VATActivityType,
	|		DD.CorrectedTaxInvoice,
	|		DD.SaleExport,
	|		DD.LineOfBusiness,
	|		FALSE,
	|		DATETIME(1,1,1),
	|		DATETIME(1,1,1),
	|		DD.AmountExcludingVAT,
	|		DD.VAT,
	|		DD.VATManag
	|	FROM
	|		VATChargedOnlineTraffic AS DD
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DD.Organization,
	|		DD.TaxInvoice,
	|		DD.Vendor,
	|		DD.AssetTaxClass,
	|		DD.VATRate,
	|		DD.VATActivityType,
	|		DD.CorrectedTaxInvoice,
	|		DD.SaleExport,
	|		DD.LineOfBusiness,
	|		FALSE,
	|		DATETIME(1,1,1),
	|		DATETIME(1,1,1),
	|		CASE
	|			WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN DD.AmountExcludingVAT
	|			ELSE -DD.AmountExcludingVAT
	|		END,
	|		CASE
	|			WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN DD.VAT
	|			ELSE -DD.VAT
	|		END,
	|		CASE
	|			WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN DD.VATManag
	|			ELSE -DD.VATManag
	|		END
	|	FROM
	|		VATPresentedUnderISF AS DD
	|
	|	UNION ALL
	|	
	|	SELECT
	|		DD.Organization,
	|		DD.TaxInvoice,
	|		DD.Vendor,
	|		DD.AssetTaxClass,
	|		DD.VATRate,
	|		DD.VATActivityType,
	|		DD.CorrectedTaxInvoice,
	|		DD.SaleExport,
	|		DD.LineOfBusiness,
	|		DD.AttributedToPreviousQuarter,
	|		DD.CorrectionPeriod,
	|		DD.DateOfCorrectionOfVATDistribution,
	|		CASE
	|			WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN DD.AmountExcludingVAT
	|			ELSE -DD.AmountExcludingVAT
	|		END,
	|		CASE
	|			WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN DD.VAT
	|			ELSE -DD.VAT
	|		END,
	|		CASE
	|			WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN DD.VATManag
	|			ELSE -DD.VATManag
	|		END
	|	FROM
	|		VATChargedChangeOfActivity AS DD
	|
	|	UNION ALL
	|	
	|	SELECT
	|		DD.Organization,
	|		DD.TaxInvoice,
	|		DD.Vendor,
	|		DD.AssetTaxClass,
	|		DD.VATRate,
	|		DD.VATActivityType,
	|		DD.CorrectedTaxInvoice,
	|		DD.SaleExport,
	|		DD.LineOfBusiness,
	|		FALSE,
	|		DATETIME(1,1,1),
	|		DATETIME(1,1,1),
	|		CASE
	|			WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN DD.AmountExcludingVAT
	|			ELSE -DD.AmountExcludingVAT
	|		END,
	|		CASE
	|			WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN DD.VAT
	|			ELSE -DD.VAT
	|		END,
	|		CASE
	|			WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN DD.VATManag
	|			ELSE -DD.VATManag
	|		END
	|	FROM
	|		VATChargedChangeOfDirection AS DD
	|
	|	UNION ALL
	|	
	|	SELECT
	|		DD.Organization,
	|		DD.TaxInvoice,
	|		DD.Vendor,
	|		DD.AssetTaxClass,
	|		DD.VATRate,
	|		DD.VATActivityType,
	|		DD.CorrectedTaxInvoice,
	|		DD.SaleExport,
	|		DD.LineOfBusiness,
	|		FALSE,
	|		DATETIME(1,1,1),
	|		DATETIME(1,1,1),
	|		CASE
	|			WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN DD.AmountExcludingVAT
	|			ELSE -DD.AmountExcludingVAT
	|		END,
	|		CASE
	|			WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN DD.VAT
	|			ELSE -DD.VAT
	|		END,
	|		CASE
	|			WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN DD.VATManag
	|			ELSE -DD.VATManag
	|		END
	|	FROM
	|		VATPresentedStorno AS DD
	|
	|) AS VATInvoiced
	|	
	|LEFT JOIN
	|	AccountingPoliciesOnFrequencyOfVATCalculation AS AccountingPoliciesOnFrequencyOfVATCalculation
	|ON
	|	VATInvoiced.Organization = AccountingPoliciesOnFrequencyOfVATCalculation.Organization
	|	
	|WHERE
	|	AccountingPoliciesOnFrequencyOfVATCalculation.FrequencyOfFormationOfVATDeductionsAndRecoveries = VALUE(Enum.Periodicity.MONTH)
	|	OR &EndOfPeriod = &EndOfQuarter
	|
	|GROUP BY
	|	VATInvoiced.Organization,
	|	VATInvoiced.TaxInvoice,
	|	VATInvoiced.Vendor,
	|	VATInvoiced.AssetTaxClass,
	|	VATInvoiced.VATRate,
	|	VATInvoiced.VATActivityType,
	|	VATInvoiced.CorrectedTaxInvoice,
	|	VATInvoiced.SaleExport,
	|	VATInvoiced.LineOfBusiness
	|
	|HAVING
	|	SUM(VATInvoiced.AmountExcludingVAT) <> 0 
	|		OR SUM(VATInvoiced.VAT) <> 0
	|
	|INDEX BY
	|	Organization, 
	|	TaxInvoice,
	|	CorrectedTaxInvoice
	|";
	
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.SetParameter("EndOfPeriod",  CalculationParameters.EndOfPeriod);
	Query.SetParameter("EndOfQuarter", EndOfQuarter(CalculationParameters.EndOfPeriod));
	
	Query.Execute();
	
EndProcedure

Function CalculateRecordsOfVATPresentedAcceptanceForDeduction(CalculationParameters)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	BlockingVATDeduction.Organization AS Organization,
	|	BlockingVATDeduction.TaxInvoice AS TaxInvoice,
	|	BlockingVATDeduction.VAT AS VAT
	|FROM
	|	BlockingVATDeduction AS BlockingVATDeduction
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BlockingVATDeductionSalesExport.Organization AS Organization,
	|	BlockingVATDeductionSalesExport.TaxInvoice AS TaxInvoice,
	|	BlockingVATDeductionSalesExport.SaleExport AS SaleExport,
	|	BlockingVATDeductionSalesExport.VAT AS VAT
	|FROM
	|	BlockingVATDeductionSalesExport AS BlockingVATDeductionSalesExport
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VATInvoiced.Organization AS Organization,
	|	VATInvoiced.TaxInvoice AS TaxInvoice,
	|	VATInvoiced.Vendor AS Vendor,
	|	VATInvoiced.AssetTaxClass AS AssetTaxClass,
	|	VATInvoiced.VATRate AS VATRate,
	|	VATInvoiced.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|	VATInvoiced.LineOfBusiness AS LineOfBusiness,
	|	SUM(VATInvoiced.AmountExcludingVAT) AS AmountExcludingVAT,
	|	SUM(VATInvoiced.VAT) AS VAT,
	|	SUM(VATInvoiced.VATManag) AS VATManag
	|FROM
	|	(SELECT
	|		VATInvoiced.Organization              AS Organization,
	|		VATInvoiced.TaxInvoice              AS TaxInvoice,
	|		VATInvoiced.Vendor                AS Vendor,
	|		VATInvoiced.AssetTaxClass              AS AssetTaxClass,
	|		VATInvoiced.VATRate                AS VATRate,
	|		VATInvoiced.CorrectedTaxInvoice  AS CorrectedTaxInvoice,
	|		VATInvoiced.LineOfBusiness  AS LineOfBusiness,
	|		VATInvoiced.AmountExcludingVAT              AS AmountExcludingVAT,
	|		VATInvoiced.VAT                      AS VAT,
	|		VATInvoiced.VATManag                   AS VATManag
	|	FROM
	|		AccumulationRegister.VATInvoiced AS VATInvoiced
	|			INNER JOIN Jobs AS Jobs
	|			ON VATInvoiced.Organization = Jobs.Organization
	|				AND VATInvoiced.TaxInvoice = Jobs.TaxInvoice
	|	WHERE
	|		VATInvoiced.Period < &BeginOfPeriod
	|		AND VATInvoiced.Event = VALUE(Enum.EventsChargedVAT.ReverseVATForActivityType)
	|		AND VATInvoiced.Active
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		VATInvoiced.Organization,
	|		VATInvoiced.TaxInvoice,
	|		VATInvoiced.Vendor,
	|		VATInvoiced.AssetTaxClass,
	|		VATInvoiced.VATRate,
	|		VATInvoiced.CorrectedTaxInvoice,
	|		VATInvoiced.LineOfBusiness,
	|		VATInvoiced.AmountExcludingVAT,
	|		VATInvoiced.VAT,
	|		VATInvoiced.VATManag
	|	FROM
	|		VATPresentedRecoveryUnderTypeOfActivity AS VATInvoiced
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ReAcceptedForVATDeduction.Organization,
	|		ReAcceptedForVATDeduction.TaxInvoice,
	|		ReAcceptedForVATDeduction.Vendor,
	|		ReAcceptedForVATDeduction.AssetTaxClass,
	|		ReAcceptedForVATDeduction.VATRate,
	|		ReAcceptedForVATDeduction.CorrectedTaxInvoice,
	|		ReAcceptedForVATDeduction.LineOfBusiness,
	|		ReAcceptedForVATDeduction.AmountExcludingVAT,
	|		ReAcceptedForVATDeduction.VAT,
	|		ReAcceptedForVATDeduction.VATManag
	|	FROM
	|		ReAcceptedForVATDeduction AS ReAcceptedForVATDeduction) AS VATInvoiced
	|
	|GROUP BY
	|	VATInvoiced.Organization,
	|	VATInvoiced.TaxInvoice,
	|	VATInvoiced.Vendor,
	|	VATInvoiced.AssetTaxClass,
	|	VATInvoiced.VATRate,
	|	VATInvoiced.CorrectedTaxInvoice,
	|	VATInvoiced.LineOfBusiness
	|
	|HAVING
	|	SUM(VATInvoiced.VAT) > 0;
	|
	|///////////////////////////////////////////////////////////
	|
	|SELECT
	|	VATInvoiced.Organization AS Organization,
	|	VATInvoiced.TaxInvoice AS TaxInvoice,
	|	VATInvoiced.Vendor AS Vendor,
	|	VATInvoiced.AssetTaxClass AS AssetTaxClass,
	|	VATInvoiced.VATRate AS VATRate,
	|	VATInvoiced.VATActivityType AS VATActivityType,
	|	VATInvoiced.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|	VATInvoiced.SaleExport AS SaleExport,
	|	VATInvoiced.LineOfBusiness AS LineOfBusiness,
	|	MAX(VATInvoiced.AttributedToPreviousQuarter) AS AttributedToPreviousQuarter,
	|	MAX(VATInvoiced.CorrectionPeriod) AS CorrectionPeriod,
	|	MAX(VATInvoiced.DateOfCorrectionOfVATDistribution) AS DateOfCorrectionOfVATDistribution,
	|	SUM(VATInvoiced.AmountExcludingVAT) AS AmountExcludingVAT,
	|	SUM(VATInvoiced.VAT) AS VAT,
	|	SUM(VATInvoiced.VATManag) AS VATManag,
	|	SectionsOfVATDeduction.Recorder AS Recorder,
	|	CASE
	|		WHEN SectionsOfVATDeduction.Period < &BeginOfPeriod
	|			THEN &EndOfPeriod
	|		ELSE SectionsOfVATDeduction.Period
	|	END AS Period,
	|	SectionsOfVATDeduction.Event AS Event
	|FROM
	|	(SELECT
	|		VATInvoiced.Organization AS Organization,
	|		VATInvoiced.TaxInvoice AS TaxInvoice,
	|		VATInvoiced.Vendor AS Vendor,
	|		VATInvoiced.AssetTaxClass AS AssetTaxClass,
	|		VATInvoiced.VATRate AS VATRate,
	|		VATInvoiced.VATActivityType AS VATActivityType,
	|		VATInvoiced.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|		VATInvoiced.SaleExport AS SaleExport,
	|		VATInvoiced.LineOfBusiness AS LineOfBusiness,
	|		VATInvoiced.AttributedToPreviousQuarter AS AttributedToPreviousQuarter,
	|		VATInvoiced.CorrectionPeriod AS CorrectionPeriod,
	|		VATInvoiced.DateOfCorrectionOfVATDistribution AS DateOfCorrectionOfVATDistribution,
	|		VATInvoiced.AmountExcludingVAT AS AmountExcludingVAT,
	|		VATInvoiced.VAT AS VAT,
	|		VATInvoiced.VATManag AS VATManag
	|	FROM
	|		VATPresentedBalancesAtEndOfPeriod AS VATInvoiced
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		VATInvoiced.Organization,
	|		VATInvoiced.TaxInvoice,
	|		VATInvoiced.Vendor,
	|		VATInvoiced.AssetTaxClass,
	|		VATInvoiced.VATRate,
	|		VATInvoiced.VATActivityType,
	|		VATInvoiced.CorrectedTaxInvoice,
	|		VATInvoiced.SaleExport,
	|		VATInvoiced.LineOfBusiness,
	|		VATInvoiced.AttributedToPreviousQuarter,
	|		VATInvoiced.CorrectionPeriod,
	|		VATInvoiced.DateOfCorrectionOfVATDistribution,
	|		VATInvoiced.AmountExcludingVAT,
	|		VATInvoiced.VAT,
	|		VATInvoiced.VATManag
	|	FROM
	|		VATPresentedRecoveryUnderTypeOfActivity AS VATInvoiced
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		VATInvoiced.Organization,
	|		VATInvoiced.TaxInvoice,
	|		VATInvoiced.Vendor,
	|		VATInvoiced.AssetTaxClass,
	|		VATInvoiced.VATRate,
	|		VATInvoiced.VATActivityType,
	|		VATInvoiced.CorrectedTaxInvoice,
	|		VATInvoiced.SaleExport,
	|		VATInvoiced.LineOfBusiness,
	|		FALSE,
	|		DATETIME(1,1,1) AS CorrectionPeriod,
	|		DATETIME(1,1,1) AS DateOfCorrectionOfVATDistribution,
	|		VATInvoiced.AmountExcludingVAT,
	|		VATInvoiced.VAT,
	|		VATInvoiced.VATManag
	|	FROM
	|		VATPresentedRecoveryByCSF AS VATInvoiced) AS VATInvoiced
	|	
	|		INNER JOIN SectionsOfVATDeduction AS SectionsOfVATDeduction
	|		ON VATInvoiced.Organization = SectionsOfVATDeduction.Organization
	|			AND VATInvoiced.TaxInvoice = SectionsOfVATDeduction.TaxInvoice
	|			AND VATInvoiced.VATActivityType = SectionsOfVATDeduction.VATActivityType
	|			AND VATInvoiced.AssetTaxClass = SectionsOfVATDeduction.AssetTaxClass
	|			AND VATInvoiced.SaleExport = SectionsOfVATDeduction.SaleExport
	|			AND VATInvoiced.CorrectedTaxInvoice = SectionsOfVATDeduction.CorrectedTaxInvoice
	|
	|GROUP BY
	|	VATInvoiced.Organization,
	|	VATInvoiced.TaxInvoice,
	|	VATInvoiced.Vendor,
	|	VATInvoiced.AssetTaxClass,
	|	VATInvoiced.VATRate,
	|	VATInvoiced.VATActivityType,
	|	VATInvoiced.CorrectedTaxInvoice,
	|	VATInvoiced.SaleExport,
	|	VATInvoiced.LineOfBusiness,
	|	SectionsOfVATDeduction.Recorder,
	|	SectionsOfVATDeduction.Event,
	|	CASE
	|		WHEN SectionsOfVATDeduction.Period < &BeginOfPeriod
	|			THEN &EndOfPeriod
	|		ELSE SectionsOfVATDeduction.Period
	|	END
	|
	|HAVING
	|	SUM(VATInvoiced.VAT) <> 0 OR
	|	SUM(VATInvoiced.AmountExcludingVAT) <> 0
	|
	|ORDER BY
	|	VAT DESC
	|TOTALS
	|	SUM(VAT)
	|BY
	|	TaxInvoice
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TaxBaseOfImplementationOf0InContextOfOFOperationsCodes.Organization AS Organization,
	|	TaxBaseOfImplementationOf0InContextOfOFOperationsCodes.TaxInvoice AS TaxInvoice,
	|	TaxBaseOfImplementationOf0InContextOfOFOperationsCodes.VATOnPurchases AS VATOnPurchases,
	|	TaxBaseOfImplementationOf0InContextOfOFOperationsCodes.DocumentShipments AS SaleExport,
	|	TaxBaseOfImplementationOf0InContextOfOFOperationsCodes.OperationCode AS OperationCode,
	|	TaxBaseOfImplementationOf0InContextOfOFOperationsCodes.ConfirmationAmount AS ConfirmationAmount,
	|	UNDEFINED AS Vendor,
	|	UNDEFINED AS AssetTaxClass,
	|	UNDEFINED AS VATRate,
	|	UNDEFINED AS VATActivityType,
	|	UNDEFINED AS CorrectedTaxInvoice,
	|	UNDEFINED AS LineOfBusiness,
	|	FALSE AS AttributedToPreviousQuarter,
	|	DATETIME(1,1,1) AS CorrectionPeriod,
	|	DATETIME(1,1,1) AS DateOfCorrectionOfVATDistribution,
	|	0 AS AmountExcludingVAT,
	|	0 AS VAT,
	|	0 AS VATManag,
	|	UNDEFINED AS Recorder,
	|	UNDEFINED AS Period,
	|	UNDEFINED AS Event
	|FROM
	|	TaxBaseOfImplementationOf0InContextOfOFOperationsCodes AS TaxBaseOfImplementationOf0InContextOfOFOperationsCodes
	|WHERE
	|	TaxBaseOfImplementationOf0InContextOfOFOperationsCodes.OperationCode <> """"";
	
	Query.SetParameter("BeginOfPeriod",           CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",            CalculationParameters.EndOfPeriod);
	Query.SetParameter("CompanyArray",       CalculationParameters.CompanyArray);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	
	QueryResult = Query.ExecuteBatch();
	
	VATBlocking = QueryResult[0].Unload();
	VATBlockingSalesExport = QueryResult[1].Unload();
	VATRecovered = QueryResult[2].Unload();
	VATRecovered.Indexes.Add("Organization, TaxInvoice, Vendor, AssetTaxClass, VATRate, LineOfBusiness"); 
	SamplingOfVATBalancesPresentedUnderSF = QueryResult[3].Select(QueryResultIteration.ByGroups);
	SalesTaxBaseIs0ForDistributionOfVATDeduction = QueryResult[4].Unload();
	SalesTaxBaseIs0ForDistributionOfVATDeduction.Indexes.Add("Organization, TaxInvoice, SaleExport");

	TableOfVATPresentedTaxDeductible = AccumulationRegisters.VATInvoiced.CreateRecordSet().UnloadColumns();
	TableOfVATPresentedTaxDeductible.Columns.Delete("Active");
	TableOfVATPresentedTaxDeductible.Columns.Add("RepeatedDeduction", New TypeDescription("Boolean"));
	TableOfVATPresentedTaxDeductible.Columns.Add("OperationCode", New TypeDescription("String", , New StringQualifiers(7)));
	TableOfVATPresentedTaxDeductible.Columns.Add("WritingAdditionalSheet", New TypeDescription("Boolean"));
	TableOfVATPresentedTaxDeductible.Columns.Add("AdjustmentPeriod", New TypeDescription("Date"));
	TableOfVATPresentedTaxDeductible.Columns.Add("DateOfCorrectionOfVATDistribution", New TypeDescription("Date"));
		
	While SamplingOfVATBalancesPresentedUnderSF.Next() Do
		
		FilterStructure1 = New Structure("TaxInvoice", SamplingOfVATBalancesPresentedUnderSF.TaxInvoice);
		FoundBlockingOnSF = VATBlocking.FindRows(FilterStructure1);
		If FoundBlockingOnSF.Count() > 0 Then
			If FoundBlockingOnSF[0].VAT = 0 Then
				BlockingAmount = SamplingOfVATBalancesPresentedUnderSF.VAT;
			Else
				BlockingAmount = FoundBlockingOnSF[0].VAT;
			EndIf;
		Else
			BlockingAmount = 0;
		EndIf;
		
		SamplingBySFMeasurements = SamplingOfVATBalancesPresentedUnderSF.Select();
		
		While SamplingBySFMeasurements.Next() Do
			
			VATSelectionStructureRestored = New Structure();
			VATSelectionStructureRestored.Insert("Organization");
			VATSelectionStructureRestored.Insert("TaxInvoice");
			VATSelectionStructureRestored.Insert("Vendor");
			VATSelectionStructureRestored.Insert("AssetTaxClass");
			VATSelectionStructureRestored.Insert("VATRate");
			VATSelectionStructureRestored.Insert("LineOfBusiness");

			FillPropertyValues(VATSelectionStructureRestored, SamplingBySFMeasurements);
			
			RecoveredVATForSF = VATRecovered.FindRows(VATSelectionStructureRestored);
			If RecoveredVATForSF.Count() > 0 Then
				VATRestored = RecoveredVATForSF[0].VAT;
			Else
				VATRestored = 0;
			EndIf;
		
			Character = ?(SamplingBySFMeasurements.VAT > 0, 1, -1);
			
			If SamplingBySFMeasurements.VAT > 0 Then
				If ValueIsFilled(SamplingBySFMeasurements.SaleExport) Then
					SelectionStructureSalesExport = New Structure();
					SelectionStructureSalesExport.Insert("TaxInvoice");
					SelectionStructureSalesExport.Insert("SaleExport");
					FillPropertyValues(SelectionStructureSalesExport, SamplingBySFMeasurements);
					AmountOfBlockingImplementationExport = VATBlockingSalesExport.FindRows(SelectionStructureSalesExport);
					If AmountOfBlockingImplementationExport.Count() > 0 Then
						AmountOfBlockingBySFMeasurement = Min(SamplingBySFMeasurements.VAT, Min(BlockingAmount, AmountOfBlockingImplementationExport[0].VAT));
					Else
						AmountOfBlockingBySFMeasurement = 0;
					EndIf;
				Else
					AmountOfBlockingBySFMeasurement = Min(SamplingBySFMeasurements.VAT, BlockingAmount);
				EndIf;
				VAT_Deduction = SamplingBySFMeasurements.VAT - AmountOfBlockingBySFMeasurement;
				BlockingAmount = BlockingAmount - AmountOfBlockingBySFMeasurement;
			Else
				VAT_Deduction = SamplingBySFMeasurements.VAT;
			EndIf;
			
			If SamplingBySFMeasurements.VAT = 0 Then
				Continue;
			EndIf;
			
			If VAT_Deduction = 0 Then
				Continue;
			EndIf;
			
			Amounts = New Structure();
			Amounts.Insert("VAT_Deduction");
			Amounts.Insert("VAT");
			Amounts.Insert("AmountExcludingVAT");
			Amounts.Insert("VATManag");
			
			Amounts.VAT_Deduction = VAT_Deduction;
			FillPropertyValues(Amounts, SamplingBySFMeasurements);
			
			SelectionStructureOfOperationCodes0 = New Structure();
			SelectionStructureOfOperationCodes0.Insert("Organization");
			SelectionStructureOfOperationCodes0.Insert("TaxInvoice");
			SelectionStructureOfOperationCodes0.Insert("SaleExport");
			FillPropertyValues(SelectionStructureOfOperationCodes0, SamplingBySFMeasurements);
			LinesTaxBaseOfImplementation0 = SalesTaxBaseIs0ForDistributionOfVATDeduction.FindRows(SelectionStructureOfOperationCodes0);
			Coefficients = New Array;
			For Each LineTaxBaseOfImplementation0ForDistributionOfVATDeduction In LinesTaxBaseOfImplementation0 Do
				Coefficients.Add(LineTaxBaseOfImplementation0ForDistributionOfVATDeduction.ConfirmationAmount);
				FillPropertyValues(LineTaxBaseOfImplementation0ForDistributionOfVATDeduction, SamplingBySFMeasurements);
			EndDo;
			
			// The entire deduction is attributed to the invoice.
			If Amounts.VAT_Deduction * Character > 0 Then
				If VATRestored > 0 Then
					VAT = Min(Amounts.VAT_Deduction, VATRestored);
					If Coefficients.Count() = 0 Then
						ShareOfAvailableVAT = VAT / Amounts.VAT;
						AddVATDeductionLine(TableOfVATPresentedTaxDeductible, Amounts, ShareOfAvailableVAT, SamplingBySFMeasurements, True);
					Else
						DistributionOfAmountToBeDeducted = Common.DistributeAmountInProportionToCoefficients(VAT, Coefficients);
						For Indus = 0 To LinesTaxBaseOfImplementation0.Count() - 1 Do
							ShareOfAvailableVAT = DistributionOfAmountToBeDeducted[Indus] / Amounts.VAT;
							AddVATDeductionLine(TableOfVATPresentedTaxDeductible, Amounts, ShareOfAvailableVAT, LinesTaxBaseOfImplementation0[Indus], True);
						EndDo;
					EndIf;
					VATRestored = VATRestored - VAT;
					Amounts.VAT_Deduction = Amounts.VAT_Deduction - VAT;
				EndIf;
				If Amounts.VAT_Deduction * Character > 0 Then
					If Coefficients.Count() = 0 Then
						If Amounts.VAT_Deduction * Character <= CalculationParameters.RoundingErrorWriteOffThreshold Then
							Continue;
						Else
							ShareOfAvailableVAT = Amounts.VAT_Deduction / Amounts.VAT;
							AddVATDeductionLine(TableOfVATPresentedTaxDeductible, Amounts, ShareOfAvailableVAT, SamplingBySFMeasurements, False);
						EndIf;
					Else
						DistributionOfAmountToBeDeducted = Common.DistributeAmountInProportionToCoefficients(Amounts.VAT_Deduction, Coefficients);
						For Indus = 0 To LinesTaxBaseOfImplementation0.Count() - 1 Do
							ShareOfAvailableVAT = ?(Amounts.VAT_Deduction <> 0, DistributionOfAmountToBeDeducted[Indus] / Amounts.VAT, 0);
							AddVATDeductionLine(TableOfVATPresentedTaxDeductible, Amounts, ShareOfAvailableVAT, LinesTaxBaseOfImplementation0[Indus], False);
						EndDo;
					EndIf;
				EndIf;
			EndIf;
			
		EndDo;
	
	EndDo;
	
	Query.Text =
	"SELECT
	|	4 AS Priority,
	|	TableOfVATPresentedTaxDeductible.Period AS Period,
	|	TableOfVATPresentedTaxDeductible.Recorder AS Recorder,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	TableOfVATPresentedTaxDeductible.Organization AS Organization,
	|	TableOfVATPresentedTaxDeductible.TaxInvoice AS TaxInvoice,
	|	TableOfVATPresentedTaxDeductible.Vendor AS Vendor,
	|	TableOfVATPresentedTaxDeductible.AssetTaxClass AS AssetTaxClass,
	|	TableOfVATPresentedTaxDeductible.VATRate AS VATRate,
	|	TableOfVATPresentedTaxDeductible.VATActivityType AS VATActivityType,
	|	TableOfVATPresentedTaxDeductible.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|	TableOfVATPresentedTaxDeductible.SaleExport AS SaleExport,
	|	TableOfVATPresentedTaxDeductible.LineOfBusiness AS LineOfBusiness,
	|	TableOfVATPresentedTaxDeductible.AmountExcludingVAT AS AmountExcludingVAT,
	|	TableOfVATPresentedTaxDeductible.VAT AS VAT,
	|	TableOfVATPresentedTaxDeductible.VATManag AS VATManag,
	|	TableOfVATPresentedTaxDeductible.Event AS Event,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS CorVATActivityTypes,
	|	TableOfVATPresentedTaxDeductible.Department AS Department,
	|	TableOfVATPresentedTaxDeductible.CorLineOfBusiness AS CorLineOfBusiness,
	|	TableOfVATPresentedTaxDeductible.ExpenseItem AS ExpenseItem,
	|	TableOfVATPresentedTaxDeductible.DimensionOfExpenses AS DimensionOfExpenses,
	|	"""" AS RowID,
	|	TRUE AS PeriodEndTransaction,
	|	TableOfVATPresentedTaxDeductible.RepeatedDeduction AS RepeatedDeduction,
	|	TableOfVATPresentedTaxDeductible.OperationCode AS OperationCode,
	|	FALSE AS ReversingEntry,
	|	VALUE(Catalog.BusinessTransactionsSettings.VATDeduction) AS BusinessTransactionSetting
	|INTO VATPresentedAcceptanceForDeduction
	|FROM
	|	&TableOfVATPresentedTaxDeductible AS TableOfVATPresentedTaxDeductible";
	
	Query.SetParameter("TableOfVATPresentedTaxDeductible", TableOfVATPresentedTaxDeductible);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	
	Query.Execute();
	
	TMCommonUse.AddIDsToTemporaryTable(
		"VATPresentedAcceptanceForDeduction", CalculationParameters.TempTablesManager, "FinRecordID");
		
	Return "VATPresentedAcceptanceForDeduction";

EndFunction

Function CalculateRecordsOfVATPresentedRecoveryByCSF(CalculationParameters)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	2                                                                         AS Priority,
	|	CASE 
	|		WHEN ISNULL(CorrectedInvoices.DateOfPurchaseBookEntry, InvoicesDocuments.DateOfPurchaseBookEntry) >= &BeginOfPeriod
	|			THEN ISNULL(CorrectedInvoices.DateOfPurchaseBookEntry, InvoicesDocuments.DateOfPurchaseBookEntry)
	|		ELSE
	|			&EndOfPeriod
	|	END                                                                     AS Period,
	|	ISNULL(CorrectedInvoices.Ref, InvoicesDocuments.Ref)   AS Recorder,
	|	VALUE(AccumulationRecordType.Receipt)                                    AS RecordType,
	|	DD.Organization                                                            AS Organization,
	|	DD.TaxInvoice                                                            AS TaxInvoice,
	|	DD.Vendor                                                              AS Vendor,
	|	DD.AssetTaxClass                                                            AS AssetTaxClass,
	|	DD.VATRate                                                              AS VATRate,
	|	DD.VATActivityType                                                     AS VATActivityType,
	|	DD.CorrectedTaxInvoice                                                AS CorrectedTaxInvoice,
	|	DD.SaleExport                                                      AS SaleExport,
	|	DD.LineOfBusiness                                                AS LineOfBusiness,
	|	-DD.AmountExcludingVAT                                                           AS AmountExcludingVAT,
	|	-DD.VAT                                                                   AS VAT,
	|	-DD.VATManag                                                                AS VATManag,
	|	VALUE(Enum.EventsChargedVAT.ReverseVATByCTI)     AS Event,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef)                AS CorVATActivityTypes,
	|	UNDEFINED                                                              AS Department,
	|	UNDEFINED                                                              AS CorLineOfBusiness,
	|	UNDEFINED                                                              AS ExpenseItem,
	|	UNDEFINED                                                              AS DimensionOfExpenses,
	|	""""                                                                      AS RowID,
	|	TRUE                                                                    AS PeriodEndTransaction,
	|	FALSE                                                                      AS ReversingEntry,
	|	VALUE(Catalog.BusinessTransactionsSettings.ReverseVAT)     AS BusinessTransactionSetting
	|	
	|INTO VATPresentedRecoveryByCSF
	|FROM
	|	VATPresentedBalancesAtEndOfPeriod AS DD
	|	
	|	INNER JOIN
	|		AdjustmentInvoices AS AdjustmentInvoices
	|	ON
	|		DD.TaxInvoice = AdjustmentInvoices.TaxInvoice
	|		AND DD.Organization = AdjustmentInvoices.Organization
	|	
	|	INNER JOIN
	|		InvoicesDocuments AS InvoicesDocuments
	|	ON
	|		DD.Organization = InvoicesDocuments.Organization
	|		AND DD.TaxInvoice = InvoicesDocuments.TaxInvoice
	|	
	|	LEFT JOIN
	|		CorrectedInvoices AS CorrectedInvoices
	|	ON
	|		DD.Organization = CorrectedInvoices.Organization
	|		AND DD.TaxInvoice = CorrectedInvoices.TaxInvoice
	|		AND DD.CorrectedTaxInvoice = CorrectedInvoices.CorrectedTaxInvoice
	|WHERE
	|	DD.VATActivityType IN (&TypesOfActivitiesVATIsAcceptedForReimbursement)
	|	AND DD.VAT < 0
	|";
	
	Query.SetParameter("BeginOfPeriod",           CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",            CalculationParameters.EndOfPeriod);
	Query.SetParameter("CompanyArray",       CalculationParameters.CompanyArray);
	Query.SetParameter("TypesOfActivitiesVATIsAcceptedForReimbursement", VATAccountingERP.TypesOfActivitiesVATIsAcceptedForReimbursement());
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.Execute();
	
	TMCommonUse.AddIDsToTemporaryTable(
		"VATPresentedRecoveryByCSF", CalculationParameters.TempTablesManager, "FinRecordID");
	
	Return "VATPresentedRecoveryByCSF"
	
EndFunction

Function CalculateVATRecordsPresentedByRoundingError(CalculationParameters)
	
	Query = New Query;
	
	If CalculationParameters.RoundingErrorWriteOffThreshold > 0 Then
		
		Query.Text =
		"SELECT
		|	TotalVATPresentedBalancesAtEndOfPeriod.Organization AS Organization,
		|	TotalVATPresentedBalancesAtEndOfPeriod.TaxInvoice AS TaxInvoice,
		|	TotalVATPresentedBalancesAtEndOfPeriod.Vendor AS Vendor,
		|	TotalVATPresentedBalancesAtEndOfPeriod.AssetTaxClass AS AssetTaxClass,
		|	TotalVATPresentedBalancesAtEndOfPeriod.VATRate AS VATRate,
		|	TotalVATPresentedBalancesAtEndOfPeriod.VATActivityType AS VATActivityType,
		|	TotalVATPresentedBalancesAtEndOfPeriod.CorrectedTaxInvoice AS CorrectedTaxInvoice,
		|	TotalVATPresentedBalancesAtEndOfPeriod.SaleExport AS SaleExport,
		|	TotalVATPresentedBalancesAtEndOfPeriod.LineOfBusiness AS LineOfBusiness,
		|	SUM(TotalVATPresentedBalancesAtEndOfPeriod.AmountExcludingVAT) AS AmountExcludingVAT,
		|	SUM(TotalVATPresentedBalancesAtEndOfPeriod.VAT) AS VAT,
		|	SUM(TotalVATPresentedBalancesAtEndOfPeriod.VATManag) AS VATManag
		|INTO RoundingErrors_
		|FROM
		|	(SELECT
		|		VATPresentedBalancesAtEndOfPeriod.Organization AS Organization,
		|		VATPresentedBalancesAtEndOfPeriod.TaxInvoice AS TaxInvoice,
		|		VATPresentedBalancesAtEndOfPeriod.Vendor AS Vendor,
		|		VATPresentedBalancesAtEndOfPeriod.AssetTaxClass AS AssetTaxClass,
		|		VATPresentedBalancesAtEndOfPeriod.VATRate AS VATRate,
		|		VATPresentedBalancesAtEndOfPeriod.VATActivityType AS VATActivityType,
		|		VATPresentedBalancesAtEndOfPeriod.CorrectedTaxInvoice AS CorrectedTaxInvoice,
		|		VATPresentedBalancesAtEndOfPeriod.SaleExport AS SaleExport,
		|		VATPresentedBalancesAtEndOfPeriod.LineOfBusiness AS LineOfBusiness,
		|		VATPresentedBalancesAtEndOfPeriod.AmountExcludingVAT AS AmountExcludingVAT,
		|		VATPresentedBalancesAtEndOfPeriod.VAT AS VAT,
		|		VATPresentedBalancesAtEndOfPeriod.VATManag AS VATManag
		|	FROM
		|		VATPresentedBalancesAtEndOfPeriod AS VATPresentedBalancesAtEndOfPeriod
		|
		|	UNION
		|
		|	SELECT
		|		VATPresentedAcceptanceForDeduction.Organization AS Organization,
		|		VATPresentedAcceptanceForDeduction.TaxInvoice AS TaxInvoice,
		|		VATPresentedAcceptanceForDeduction.Vendor AS Vendor,
		|		VATPresentedAcceptanceForDeduction.AssetTaxClass AS AssetTaxClass,
		|		VATPresentedAcceptanceForDeduction.VATRate AS VATRate,
		|		VATPresentedAcceptanceForDeduction.VATActivityType AS VATActivityType,
		|		VATPresentedAcceptanceForDeduction.CorrectedTaxInvoice AS CorrectedTaxInvoice,
		|		VATPresentedAcceptanceForDeduction.SaleExport AS SaleExport,
		|		VATPresentedAcceptanceForDeduction.LineOfBusiness AS LineOfBusiness,
		|		-VATPresentedAcceptanceForDeduction.AmountExcludingVAT AS AmountExcludingVAT,
		|		-VATPresentedAcceptanceForDeduction.VAT AS VAT,
		|		-VATPresentedAcceptanceForDeduction.VATManag AS VATManag
		|	FROM
		|		VATPresentedAcceptanceForDeduction AS VATPresentedAcceptanceForDeduction
		|
		|	UNION
		|
		|	SELECT
		|		VATPresentedRecoveryByCSF.Organization AS Organization,
		|		VATPresentedRecoveryByCSF.TaxInvoice AS TaxInvoice,
		|		VATPresentedRecoveryByCSF.Vendor AS Vendor,
		|		VATPresentedRecoveryByCSF.AssetTaxClass AS AssetTaxClass,
		|		VATPresentedRecoveryByCSF.VATRate AS VATRate,
		|		VATPresentedRecoveryByCSF.VATActivityType AS VATActivityType,
		|		VATPresentedRecoveryByCSF.CorrectedTaxInvoice AS CorrectedTaxInvoice,
		|		VATPresentedRecoveryByCSF.SaleExport AS SaleExport,
		|		VATPresentedRecoveryByCSF.LineOfBusiness AS LineOfBusiness,
		|		VATPresentedRecoveryByCSF.AmountExcludingVAT AS AmountExcludingVAT,
		|		VATPresentedRecoveryByCSF.VAT AS VAT,
		|		VATPresentedRecoveryByCSF.VATManag AS VATManag
		|	FROM
		|		VATPresentedRecoveryByCSF AS VATPresentedRecoveryByCSF) AS
		|		TotalVATPresentedBalancesAtEndOfPeriod
		|GROUP BY
		|	TotalVATPresentedBalancesAtEndOfPeriod.Organization,
		|	TotalVATPresentedBalancesAtEndOfPeriod.TaxInvoice,
		|	TotalVATPresentedBalancesAtEndOfPeriod.Vendor,
		|	TotalVATPresentedBalancesAtEndOfPeriod.AssetTaxClass,
		|	TotalVATPresentedBalancesAtEndOfPeriod.VATRate,
		|	TotalVATPresentedBalancesAtEndOfPeriod.VATActivityType,
		|	TotalVATPresentedBalancesAtEndOfPeriod.CorrectedTaxInvoice,
		|	TotalVATPresentedBalancesAtEndOfPeriod.SaleExport,
		|	TotalVATPresentedBalancesAtEndOfPeriod.LineOfBusiness
		|HAVING
		|	SUM(TotalVATPresentedBalancesAtEndOfPeriod.VAT) <> 0
		|	AND SUM(TotalVATPresentedBalancesAtEndOfPeriod.VAT) <= &RoundingErrorWriteOffThreshold
		|	AND -SUM(TotalVATPresentedBalancesAtEndOfPeriod.VAT) <= &RoundingErrorWriteOffThreshold
		|	OR SUM(TotalVATPresentedBalancesAtEndOfPeriod.VAT) = 0
		|	AND SUM(TotalVATPresentedBalancesAtEndOfPeriod.AmountExcludingVAT) <> 0
		|	AND SUM(TotalVATPresentedBalancesAtEndOfPeriod.AmountExcludingVAT) <= &RoundingErrorWriteOffThreshold
		|	AND -SUM(TotalVATPresentedBalancesAtEndOfPeriod.AmountExcludingVAT) <= &RoundingErrorWriteOffThreshold
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	0                                                                           AS Priority,
		|	&EndOfPeriod                                                               AS Period,
		|	VALUE(AccumulationRecordType.Expense)                                      AS RecordType,
		|	CASE
		|		WHEN NOT ISNULL(CorrectedInvoices.Ref, InvoicesDocuments.Ref) IS NULL
		|			THEN ISNULL(CorrectedInvoices.Ref, InvoicesDocuments.Ref)
		|		ELSE RoundingErrors_.TaxInvoice
		|	END                                                                       AS Recorder,
		|	RoundingErrors_.Organization                                           AS Organization,
		|	RoundingErrors_.TaxInvoice                                           AS TaxInvoice,
		|	RoundingErrors_.Vendor                                             AS Vendor,
		|	RoundingErrors_.AssetTaxClass                                           AS AssetTaxClass,
		|	RoundingErrors_.VATRate                                             AS VATRate,
		|	RoundingErrors_.VATActivityType                                    AS VATActivityType,
		|	RoundingErrors_.CorrectedTaxInvoice                               AS CorrectedTaxInvoice,
		|	RoundingErrors_.SaleExport                                     AS SaleExport,
		|	RoundingErrors_.LineOfBusiness                               AS LineOfBusiness,
		|	RoundingErrors_.AmountExcludingVAT                                           AS AmountExcludingVAT,
		|	RoundingErrors_.VAT                                                   AS VAT,
		|	RoundingErrors_.VATManag                                                AS VATManag,
		|	VALUE(Enum.EventsChargedVAT.EmptyRef)                 AS Event,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef)                  AS CorVATActivityTypes,
		|	UNDEFINED                                                                AS Department,
		|	RoundingErrors_.LineOfBusiness                               AS CorLineOfBusiness,
		|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.GoodsValueVariance) AS ExpenseItem,
		|	UNDEFINED                                                                AS DimensionOfExpenses,
		|	""""                                                                        AS RowID,
		|	TRUE                                                                      AS PeriodEndTransaction,
		|	FALSE                                                                        AS RepeatedDeduction,
		|	FALSE                                                                        AS ReversingEntry,
		|	VALUE(Catalog.BusinessTransactionsSettings.VATOnAcquiredAssetsWriteOff) AS
		|		BusinessTransactionSetting
		|INTO VATPresentedRoundingErrors
		|FROM
		|	RoundingErrors_
		|		LEFT JOIN InvoicesDocuments AS InvoicesDocuments
		|		ON RoundingErrors_.Organization = InvoicesDocuments.Organization
		|		AND RoundingErrors_.TaxInvoice = InvoicesDocuments.TaxInvoice
		|		LEFT JOIN CorrectedInvoices AS CorrectedInvoices
		|		ON RoundingErrors_.Organization = CorrectedInvoices.Organization
		|		AND RoundingErrors_.TaxInvoice = CorrectedInvoices.TaxInvoice
		|		AND RoundingErrors_.CorrectedTaxInvoice = CorrectedInvoices.CorrectedTaxInvoice";
		
		Query.SetParameter("EndOfPeriod", CalculationParameters.EndOfPeriod);
		Query.SetParameter("RoundingErrorWriteOffThreshold", CalculationParameters.RoundingErrorWriteOffThreshold);
	Else
		Query.Text =
		"SELECT
		|	0                                             AS Priority,
		|	UNDEFINED                                  AS Period,
		|	UNDEFINED                                  AS RecordType,
		|	UNDEFINED                                  AS Recorder,
		|	VALUE(Catalog.Companies.EmptyRef) AS Organization,
		|	UNDEFINED                                  AS TaxInvoice,
		|	UNDEFINED                                  AS Vendor,
		|	UNDEFINED                                  AS AssetTaxClass,
		|	UNDEFINED                                  AS VATRate,
		|	UNDEFINED                                  AS VATActivityType,
		|	UNDEFINED                                  AS CorrectedTaxInvoice,
		|	UNDEFINED                                  AS SaleExport,
		|	UNDEFINED                                  AS LineOfBusiness,
		|	0                                             AS AmountExcludingVAT,
		|	0                                             AS VAT,
		|	0                                             AS VATManag,
		|	UNDEFINED                                  AS Event,
		|	UNDEFINED                                  AS CorVATActivityTypes,
		|	UNDEFINED                                  AS Department,
		|	UNDEFINED                                  AS CorLineOfBusiness,
		|	UNDEFINED                                  AS ExpenseItem,
		|	UNDEFINED                                  AS DimensionOfExpenses,
		|	""""                                          AS RowID,
		|	TRUE                                        AS PeriodEndTransaction,
		|	FALSE                                          AS RepeatedDeduction,
		|	FALSE                                          AS ReversingEntry,
		|	UNDEFINED                                  AS BusinessTransactionSetting
		|INTO VATPresentedRoundingErrors
		|WHERE
		|	FALSE";
	EndIf;
	
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.Execute();
	
	TMCommonUse.AddIDsToTemporaryTable(
		"VATPresentedRoundingErrors", CalculationParameters.TempTablesManager, "FinRecordID");
	
	Return "VATPresentedRoundingErrors"
	
EndFunction

Function CalculateVATRecordsPresentedToYou(CalculationParameters, TableNamesOfVATRecordsPresented)
	
	ArrayOfTextsLoggersRecord = New Array;
	ArrayOfTextsLoggersRecord.Add("
	|SELECT DISTINCT
	|	UNDEFINED AS Recorder
	|INTO LoggersRecord
	|WHERE
	|	FALSE");
	
	QueryTemplate = 
	"SELECT DISTINCT
	|	VATInvoiced.Recorder
	|FROM
	|	&TableName AS VATInvoiced";
	For Each NameOfRecordTable In TableNamesOfVATRecordsPresented Do
		QueryText = StrReplace(QueryTemplate, "&TableName", NameOfRecordTable);
		ArrayOfTextsLoggersRecord.Add(QueryText);
	EndDo;
	
	ArrayOfTextsLoggersRecord.Add("
	|SELECT DISTINCT
	|	VATInvoiced.Recorder
	|FROM
	|	CurRegistrarsVATCharged AS VATInvoiced");
	
	TextLoggersRecord = StrConcat(ArrayOfTextsLoggersRecord, TMCommonUse.QuerySeparatorInJoin(True));
	TextLoggersRecord = TextLoggersRecord +
	"
	|INDEX BY
	|	Recorder";
	
	QueryTextSave =
	"SELECT
	|	0                                               AS Priority,
	|	VATInvoiced.Period                         AS Period,
	|	VATInvoiced.Recorder                    AS Recorder,
	|	VATInvoiced.RecordType                    AS RecordType,
	|	VATInvoiced.Organization                    AS Organization,
	|	VATInvoiced.TaxInvoice                    AS TaxInvoice,
	|	VATInvoiced.Vendor                      AS Vendor,
	|	VATInvoiced.AssetTaxClass                    AS AssetTaxClass,
	|	VATInvoiced.VATRate                      AS VATRate,
	|	VATInvoiced.VATActivityType             AS VATActivityType,
	|	VATInvoiced.CorrectedTaxInvoice        AS CorrectedTaxInvoice,
	|	VATInvoiced.SaleExport              AS SaleExport,
	|	VATInvoiced.LineOfBusiness        AS LineOfBusiness,
	|	VATInvoiced.AmountExcludingVAT                    AS AmountExcludingVAT,
	|	VATInvoiced.VAT                            AS VAT,
	|	VATInvoiced.VATManag                         AS VATManag,
	|	VATInvoiced.Event                        AS Event,
	|	VATInvoiced.CorVATActivityTypes          AS CorVATActivityTypes,
	|	VATInvoiced.Department                  AS Department,
	|	VATInvoiced.CorLineOfBusiness     AS CorLineOfBusiness,
	|	VATInvoiced.ExpenseItem                 AS ExpenseItem,
	|	VATInvoiced.DimensionOfExpenses              AS DimensionOfExpenses,
	|	VATInvoiced.RowID            AS RowID,
	|	VATInvoiced.PeriodEndTransaction           AS PeriodEndTransaction,
	|	VATInvoiced.ReversingEntry                         AS ReversingEntry,
	|	VATInvoiced.FinRecordID         AS FinRecordID,
	|	VATInvoiced.BusinessTransactionSetting AS BusinessTransactionSetting
	|INTO VATPresented
	|FROM
	|	AccumulationRegister.VATInvoiced AS VATInvoiced
	|	
	|	INNER JOIN
	|		LoggersRecord AS LoggersRecord
	|	ON 
	|		VATInvoiced.Recorder = LoggersRecord.Recorder
	|	
	|	LEFT JOIN
	|		Jobs AS Jobs
	|	ON
	|		Jobs.Organization = VATInvoiced.Organization
	|		AND Jobs.TaxInvoice = VATInvoiced.TaxInvoice
	|WHERE
	|	VATInvoiced.Period < &BeginOfPeriod
	|		OR VATInvoiced.Period > &EndOfPeriod
	|		OR NOT VATInvoiced.PeriodEndTransaction
	|		OR Jobs.TaxInvoice IS NULL
	|;
	|
	|/////////////////////////////////////////////
	|DROP LoggersRecord
	|";

	Query = New Query;
	Query.Text = TextLoggersRecord + Common.QueryBatchSeparator() + QueryTextSave;
	Query.SetParameter("BeginOfPeriod",     CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",      CalculationParameters.EndOfPeriod);
	Query.SetParameter("CompanyArray", CalculationParameters.CompanyArray);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	
	Query.Execute();
	
	Return "VATPresented";
	
EndFunction

Procedure GetFrequencyOfVATDeductionsAndRecoveries(CalculationParameters)
	
	Query = New Query;
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	AccountingPoliciesTaxSettings.SupplementTemporaryTableManagerWithCurrentParametersForAccountingPolicies(
		Metadata.InformationRegisters.VATAccountingSettings.Name,
		Query.TempTablesManager,
		CalculationParameters.BeginOfPeriod,
		"TTVATAccountingSettings",
		CalculationParameters.CompanyArray);
		
	Query.Text = 
	"SELECT
	|	Companies.Ref AS Organization,
	|	ISNULL(VATAccountingSettings.FrequencyOfFormationOfVATDeductionsAndRecoveries, VALUE(Enum.Periodicity.MONTH)) AS FrequencyOfFormationOfVATDeductionsAndRecoveries
	|INTO AccountingPoliciesOnFrequencyOfVATCalculation
	|FROM
	|	Catalog.Companies AS Companies
	|	
	|	LEFT JOIN
	|		TTVATAccountingSettings AS VATAccountingSettings
	|	ON
	|		Companies.Ref = VATAccountingSettings.Organization
	|WHERE
	|	Companies.Ref IN (&CompanyArray)
	|";
	
	Query.SetParameter("CompanyArray", CalculationParameters.CompanyArray);
	
	Query.Execute();
	
EndProcedure

Procedure AddVATDeductionLine(TableAcceptanceToDeduction,
	                              Amounts,
	                              ShareOfAvailableVAT,
	                              SamplingBySFMeasurements,
	                              RepeatedDeduction = False)
	
	NewRow =  TableAcceptanceToDeduction.Add();
	FillPropertyValues(NewRow, SamplingBySFMeasurements);
	NewRow.RepeatedDeduction = RepeatedDeduction;
	
	NewRow.VAT         = Round(ShareOfAvailableVAT * Amounts.VAT, 2);
	NewRow.AmountExcludingVAT = Round(ShareOfAvailableVAT * Amounts.AmountExcludingVAT, 2);
	NewRow.VATManag      = Round(ShareOfAvailableVAT * Amounts.VATManag, 2);
	
	NewRow.WritingAdditionalSheet = SamplingBySFMeasurements.AttributedToPreviousQuarter;
	NewRow.AdjustmentPeriod = SamplingBySFMeasurements.CorrectionPeriod;
	NewRow.Period = ?(SamplingBySFMeasurements.AttributedToPreviousQuarter, SamplingBySFMeasurements.DateOfCorrectionOfVATDistribution, NewRow.Period);
	
EndProcedure

Procedure RecordVATSubmitted(CalculationParameters, TableNamesOfVATRecordsPresented)
	
	ArrayOfDataTexts = New Array;
	QueryTemplate = 
	"SELECT
	|	VATInvoiced.Priority AS Priority,
	|	VATInvoiced.Period AS Period,
	|	VATInvoiced.Recorder AS Recorder,
	|	VATInvoiced.RecordType AS RecordType,
	|	VATInvoiced.Organization AS Organization,
	|	VATInvoiced.TaxInvoice AS TaxInvoice,
	|	VATInvoiced.Vendor AS Vendor,
	|	VATInvoiced.AssetTaxClass AS AssetTaxClass,
	|	VATInvoiced.VATRate AS VATRate,
	|	VATInvoiced.VATActivityType AS VATActivityType,
	|	VATInvoiced.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|	VATInvoiced.SaleExport AS SaleExport,
	|	VATInvoiced.LineOfBusiness AS LineOfBusiness,
	|	VATInvoiced.AmountExcludingVAT AS AmountExcludingVAT,
	|	VATInvoiced.VAT AS VAT,
	|	VATInvoiced.VATManag AS VATManag,
	|	VATInvoiced.Event AS Event, 
	|	VATInvoiced.CorVATActivityTypes AS CorVATActivityTypes,
	|	VATInvoiced.Department  AS Department,
	|	VATInvoiced.CorLineOfBusiness AS CorLineOfBusiness,
	|	VATInvoiced.ExpenseItem AS ExpenseItem,
	|	VATInvoiced.DimensionOfExpenses AS DimensionOfExpenses,
	|	VATInvoiced.RowID AS RowID,
	|	VATInvoiced.PeriodEndTransaction AS PeriodEndTransaction,
	|	VATInvoiced.ReversingEntry AS ReversingEntry,
	|	VATInvoiced.FinRecordID AS FinRecordID,
	|	VATInvoiced.BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	&VATInvoiced AS VATInvoiced";
	For Each NameOfRecordTable In TableNamesOfVATRecordsPresented Do
		QueryText = StrReplace(QueryTemplate, "&VATInvoiced", NameOfRecordTable);
		ArrayOfDataTexts.Add(QueryText);
	EndDo;
	TextDataToWrite = StrConcat(ArrayOfDataTexts, TMCommonUse.QuerySeparatorInJoin());
	
	Query = New Query;
	Query.Text = 
		TextDataToWrite
		+ "
		|
		|
		|ORDER BY
		|	Recorder,
		|	Period,
		|	Priority
		|
		|TOTALS BY
		|	Recorder
		|";
	
	Query.SetParameter("BeginOfPeriod",     CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",      CalculationParameters.EndOfPeriod);
	Query.SetParameter("CompanyArray", CalculationParameters.CompanyArray);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	
	SampleDocument = Query.Execute().Select(QueryResultIteration.ByGroups);
	
	ArrayOfUnavailableRecorders = New Array;
	
	While SampleDocument.Next() Do
		
		If TypeOf(SampleDocument.Recorder) = Type("DocumentRef.SourceDocument") Then 
			
			ArrayOfUnavailableRecorders.Add(SampleDocument.Recorder);
			
		Else
		
			RecordSet = AccumulationRegisters.VATInvoiced.CreateRecordSet();
			RecordSet.Filter.Recorder.Set(SampleDocument.Recorder);
		
			// The dates of the ban are not checked, because we get here when performing tasks, 
			// and when creating tasks, the dates of the ban are controlled. 
			RecordSet.AdditionalProperties.Insert("SkipPeriodClosingCheck", True);
			
			Selection = SampleDocument.Select();
			While Selection.Next() Do
			
				NewRecord = RecordSet.Add();
				FillPropertyValues(NewRecord, Selection);
			
			EndDo;
		
			RecordSet.Write();
			
		EndIf;
		
	EndDo;
	
	If ArrayOfUnavailableRecorders.Count() Then
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
									NStr("vi = 'Khi thực hiện tính thuế GTGT đã xảy ra lỗi: thử tạo bản ghi sổ mua vào/bán ra theo chứng từ:
									|%1. 
									|Những chứng từ này không thể là cơ sở cho các bản ghi trong sổ. Để chỉnh sửa vấn đề, hãy tạo theo nó ""Hóa đơn GTGT đã nhận"" hoặc không sử dụng các chứng từ này làm chứng từ lô thuế GTGT.';
									|ru = 'При выполнении расчета НДС возникла ошибка: попытка формирования записей книг покупок/продаж по документам:
									|%1. 
									|Эти документы не могут быть основанием для записей в книгах. Для исправления проблемы оформите по нему ""Счет-фактуру полученный"" или не используйте эти документы в качестве документа партии НДС.';
									|en = 'An error occurred when calculating VAT: an attempt to generate purchase/sales ledger entries by documents:
									|%1. 
									|These documents cannot be base documents for entries in the ledgers. To eliminate the issue, register a Received tax invoice for these documents or do not use them as VAT lot documents.'; fa = 'An error occurred when calculating VAT: an attempt to generate purchase/sales ledger entries by documents:
									|%1. 
									|These documents cannot be base documents for entries in the ledgers. To eliminate the issue, register a Received tax invoice for these documents or do not use them as VAT lot documents.';
									|it = 'При выполнении расчета НДС возникла ошибка: попытка формирования записей книг покупок/продаж по документам:
									|%1. 
									|Эти документы не могут быть основанием для записей в книгах. Для исправления проблемы оформите по нему ""Счет-фактуру полученный"" или не используйте эти документы в качестве документа партии НДС.';
									|pl = 'An error occurred when calculating VAT: an attempt to generate purchase/sales ledger entries by documents:
									|%1. 
									|These documents cannot be base documents for entries in the ledgers. To eliminate the issue, register a Received tax invoice for these documents or do not use them as VAT lot documents.';
									|tr = 'KDV hesaplanırken hata oluştu: aşağıdaki belgelere dayalı olarak satın alma/satış defteri girdileri oluşturulmaya çalışılıyor:
									|%1.
									|Bu belgeler defterlerdeki girişler için temel olamaz. Sorunu düzeltmek için bir ""Vergi faturası"" düzenle veya bu belgeleri KDV lotları iş belgesi olarak kullanma.'", Common.DefaultLanguageCode()),
									StrConcat(ArrayOfUnavailableRecorders, ","+Chars.LF));
		
		WriteLogEvent(
					NStr("vi = 'Lập bản ghi kết chuyển theo thuế GTGT.';
						|ru = 'Формирование движений по НДС.';
						|en = 'Generate VAT records.'; fa = 'Generate VAT records.';
						|it = 'Generazione di movimenti IVA.';
						|pl = 'Formowanie przepływów wg VAT.';
						|tr = 'KDV kayıtlarını oluşturma.'", Common.DefaultLanguageCode()), 
					EventLogLevel.Error, , , MessageText); 
					
		Raise MessageText;
		
	EndIf;
	
EndProcedure

Procedure ClearVATCharged(CalculationParameters, TableNamesOfVATRecordsPresented)
	
	ArrayOfTextsLoggersRecord = New Array;
	ArrayOfTextsLoggersRecord.Add("
	|SELECT DISTINCT
	|	UNDEFINED AS Recorder
	|INTO LoggersRecord
	|WHERE
	|	FALSE");
	
	QueryTemplate = 
	"SELECT DISTINCT
	|	VATInvoiced.Recorder
	|FROM
	|	&TableName AS VATInvoiced";
	For Each NameOfRecordTable In TableNamesOfVATRecordsPresented Do
		QueryText = StrReplace(QueryTemplate, "&TableName", NameOfRecordTable);
		ArrayOfTextsLoggersRecord.Add(QueryText);
	EndDo;
	TextLoggersRecord = StrConcat(ArrayOfTextsLoggersRecord, TMCommonUse.QuerySeparatorInJoin(True));
	TextLoggersRecord = TextLoggersRecord +
	"
	|INDEX BY
	|	Recorder";
	
	TextObsoleteLoggers = "
	|SELECT
	|	OutdatedLoggers.Recorder
	|FROM
	|	CurRegistrarsVATCharged AS OutdatedLoggers
	|	LEFT JOIN
	|		LoggersRecord AS LoggersRecord
	|	ON
	|		OutdatedLoggers.Recorder = LoggersRecord.Recorder
	|
	|WHERE
	|	LoggersRecord.Recorder IS NULL
	|;
	|
	|//////////////////////////////////////////////
	|DROP LoggersRecord
	|";
	
	Query = New Query;
	Query.Text = TextLoggersRecord + Common.QueryBatchSeparator() + TextObsoleteLoggers;
	
	Query.SetParameter("BeginOfPeriod",     CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",  CalculationParameters.EndOfPeriod);
	Query.SetParameter("CompanyArray", CalculationParameters.CompanyArray);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	
	SampleDocument = Query.Execute().Select();
	While SampleDocument.Next() Do
		
		RecordSet = AccumulationRegisters.VATInvoiced.CreateRecordSet();
		RecordSet.Filter.Recorder.Set(SampleDocument.Recorder);
		RecordSet.Write(True);
		
	EndDo;

EndProcedure

#EndRegion

#Region VATGenerationAdvancesReceived

Procedure GenerateVATAdvancesReceived(CalculationParameters)
	
	Query = New Query;
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.Text =
	"SELECT TOP 1
	|	TRUE AS Field1
	|FROM
	|	Jobs AS Jobs
	|WHERE
	|	TRUE IN (TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					Document.IssuedTaxInvoicePrepayment AS TaxInv
	|					INNER JOIN ExpansionOfARAPTransactionTable AS VT_ARAPTransactions
	|					ON VT_ARAPTransactions.DocumentPayments = Jobs.TaxInvoice
	|				WHERE
	|					TaxInv.DocumentBasis = VT_ARAPTransactions.OriginalARAPTransactionDocument))";
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	Else
		CalculationParameters.CalculationOfAdvancesReceived = True;
	EndIf;
	
	ArrayOfDimensions_ = New Array;
	For Each Dimension In Metadata.AccumulationRegisters.VATPrepaymentsFromCustomer.Dimensions Do
		ArrayOfDimensions_.Add(Dimension.Name);
	EndDo;
	CalculationParameters.ArrayOfRegisterMeasurements = ArrayOfDimensions_;
	
	GetCurRegistrarsVATAdvancesReceived(CalculationParameters);
	
	GetInvoicesIssuedInAdvance(CalculationParameters);
	GetCorrectiveInvoicesIssuedInAdvance(CalculationParameters);
	
	GetCreditsForAdvancesReceived(CalculationParameters);
	
	TableNamesOfVATRecordAdvancesReceived = New Array;
	TableNamesOfVATRecordAdvancesReceived.Add(CalculateVATAdvancesReceivedStorno(CalculationParameters));
	TableNamesOfVATRecordAdvancesReceived.Add(CalculateVATAdvancesReceivedOnISF(CalculationParameters));
	TableNamesOfVATRecordAdvancesReceived.Add(CalculateVATAdvancesReceivedStornoOffsets(CalculationParameters));
	TableNamesOfVATRecordAdvancesReceived.Add(CalculateVATAdvancesReceivedTransfersArrival(CalculationParameters));
	TableNamesOfVATRecordAdvancesReceived.Add(CalculateVATAdvancesReceivedTransfersExpenses(CalculationParameters));
	TableNamesOfVATRecordAdvancesReceived.Add(CalculateVATAdvancesReceivedCredits(CalculationParameters));
	TableNamesOfVATRecordAdvancesReceived.Add(CalculateVATRecordsAdvancesReceivedSaving(CalculationParameters, TableNamesOfVATRecordAdvancesReceived));

	RecordVATAdvancesReceived(CalculationParameters, TableNamesOfVATRecordAdvancesReceived);
	ClearVATAdvancesReceived(CalculationParameters, TableNamesOfVATRecordAdvancesReceived);
	
EndProcedure

Procedure GetInvoicesIssuedInAdvance(CalculationParameters)
	
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	IssuedTaxInvoicePrepayment.Organization         AS Organization,
	|	IssuedTaxInvoicePrepayment.DocumentBasis   AS DocumentPayments,
	|	IssuedTaxInvoicePrepayment.Date                AS Period,
	|	IssuedTaxInvoicePrepayment.Ref              AS Ref,
	|	IssuedTaxInvoicePrepayment.RuleOfPrepaymentFilter AS RuleOfPrepaymentFilter,
	|	IssuedTaxInvoicePrepayment.Date                AS Date,
	|	IssuedTaxInvoicePrepayment.VATTaxation  AS VATTaxation,
	|	IssuedTaxInvoicePrepayment.Counterparty          AS Counterparty
	|INTO InvoicesIssuedInAdvance
	|FROM
	|	Document.IssuedTaxInvoicePrepayment AS IssuedTaxInvoicePrepayment
	|	INNER JOIN
	|		ExpansionOfARAPTransactionTable AS VT_ARAPTransactionDocuments
	|	ON
	|		VT_ARAPTransactionDocuments.Organization = IssuedTaxInvoicePrepayment.Organization
	|			AND VT_ARAPTransactionDocuments.OriginalARAPTransactionDocument = IssuedTaxInvoicePrepayment.DocumentBasis
	|
	|	LEFT JOIN
	|		InformationRegister.DocumentCorrections AS DocumentCorrections
	|	ON
	|		DocumentCorrections.CorrectedDocument = IssuedTaxInvoicePrepayment.Ref
	|			AND DocumentCorrections.Period <= &EndOfPeriod
	|			AND DocumentCorrections.DocumentToCorrectIsReversed
	|
	|WHERE
	|	IssuedTaxInvoicePrepayment.Posted
	|	AND NOT IssuedTaxInvoicePrepayment.Patch
	|	AND DocumentCorrections.CorrectedDocument IS NULL
	|INDEX BY
	|	Organization,
	|	DocumentPayments,
	|	Counterparty
	|";
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.SetParameter("EndOfPeriod", CalculationParameters.EndOfPeriod);
	Query.Execute();
	
EndProcedure

Procedure GetCorrectiveInvoicesIssuedInAdvance(CalculationParameters)
	
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	CorrectedTaxInvoice.Organization               AS Organization,
	|	CorrectedTaxInvoice.DocumentBasis         AS DocumentPayments,
	|	CorrectedTaxInvoice.Ref                    AS CorrectedTaxInvoice,
	|	CorrectedTaxInvoice.Date                      AS Period,
	|	CorrectedTaxInvoice.Date                      AS CorrectionDate,
	|	CorrectedTaxInvoice.CorrectionNumber          AS CorrectionNumber,
	|	CorrectedTaxInvoice.BaseDocumentTaxInvoice.Date AS Date,
	|	CorrectedTaxInvoice.Ref                    AS Ref,
	|	CorrectedTaxInvoice.RuleOfPrepaymentFilter       AS RuleOfPrepaymentFilter,
	|	CorrectedTaxInvoice.VATTaxation        AS VATTaxation,
	|	CorrectedTaxInvoice.Counterparty                AS Counterparty
	|INTO CorrectedInvoicesIssuedInAdvance
	|FROM
	|	ExpansionOfARAPTransactionTable AS VT_ARAPTransactionDocuments
	|	
	|	INNER JOIN
	|		Document.IssuedTaxInvoicePrepayment AS CorrectedTaxInvoice
	|	ON
	|		VT_ARAPTransactionDocuments.Organization = CorrectedTaxInvoice.Organization
	|		AND VT_ARAPTransactionDocuments.OriginalARAPTransactionDocument = CorrectedTaxInvoice.DocumentBasis
	|		AND CorrectedTaxInvoice.Patch
	|		AND CorrectedTaxInvoice.Posted
	|		AND CorrectedTaxInvoice.Date <= &EndOfPeriod
	|
	|	LEFT JOIN
	|		Document.IssuedTaxInvoicePrepayment AS OtherCorrectedInvoices
	|	ON 
	|		CorrectedTaxInvoice.Organization = OtherCorrectedInvoices.Organization
	|		AND CorrectedTaxInvoice.DocumentBasis = OtherCorrectedInvoices.DocumentBasis
	|		AND CorrectedTaxInvoice.CorrectionNumber < OtherCorrectedInvoices.CorrectionNumber
	|		AND OtherCorrectedInvoices.Posted
	|		AND OtherCorrectedInvoices.Patch
	|		AND OtherCorrectedInvoices.Date <= &EndOfPeriod
	|
	|	LEFT JOIN
	|		InformationRegister.DocumentCorrections AS DocumentCorrections
	|	ON
	|		DocumentCorrections.CorrectedDocument = CorrectedTaxInvoice.Ref
	|			AND DocumentCorrections.Period <= &EndOfPeriod
	|			AND DocumentCorrections.DocumentToCorrectIsReversed
	|
	|WHERE
	|	OtherCorrectedInvoices.Ref IS NULL
	|		AND DocumentCorrections.CorrectedDocument IS NULL
	|
	|INDEX BY
	|	Organization,
	|	DocumentPayments,
	|	Counterparty
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CorrectedInvoicesIssuedInAdvance.Organization             AS Organization,
	|	CorrectedInvoicesIssuedInAdvance.DocumentPayments          AS DocumentPayments,
	|	CorrectedInvoicesIssuedInAdvance.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|	CorrectedInvoicesIssuedInAdvance.Period                  AS Period,
	|	CorrectedInvoicesIssuedInAdvance.CorrectionDate         AS CorrectionDate,
	|	CorrectedInvoicesIssuedInAdvance.CorrectionNumber        AS CorrectionNumber,
	|	CorrectedInvoicesIssuedInAdvance.Date AS Date,
	|	CorrectedInvoicesIssuedInAdvance.Ref                  AS Ref,
	|	CorrectedInvoicesIssuedInAdvance.RuleOfPrepaymentFilter     AS RuleOfPrepaymentFilter,
	|	CorrectedInvoicesIssuedInAdvance.VATTaxation      AS VATTaxation,
	|	CorrectedInvoicesIssuedInAdvance.Counterparty              AS Counterparty
	|INTO CorrectedInvoicesIssuedAdvanceRecalculation
	|FROM
	|	CorrectedInvoicesIssuedInAdvance AS CorrectedInvoicesIssuedInAdvance
	|WHERE
	|	CorrectedInvoicesIssuedInAdvance.CorrectionDate BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|
	|INDEX BY
	|	Organization,
	|	DocumentPayments,
	|	Counterparty
	|;
	|
	|///////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(CorrectedInvoicesIssuedInAdvance.Date) AS Date
	|FROM
	|	CorrectedInvoicesIssuedAdvanceRecalculation AS CorrectedInvoicesIssuedInAdvance
	|";
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.SetParameter("BeginOfPeriod", CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", CalculationParameters.EndOfPeriod);
	
	QueryResult = Query.Execute();

	SelectionDetailRecords = QueryResult.Select();
	SelectionDetailRecords.Next();

	If ValueIsFilled(SelectionDetailRecords.Date) Then
		CalculationParameters.ISFBeginningOfPeriod = BegOfMonth(SelectionDetailRecords.Date);
		CalculationParameters.ISFEndOfPeriod = EndOfMonth(AddMonth(CalculationParameters.EndOfPeriod, -1));
	EndIf;

EndProcedure

Function AdvancesReceivedOnPaymentDocuments(CalculationParameters)
	
	If Not CostCalculationAppliedAlgorithms.TemporaryTableExists(
		CalculationParameters.TempTablesManager,
		"AdvancesReceived_Occurrences") Then

		AdvanceCalculationParameters = InitializeParametersForPreparationOfAdvancePaymentsForVATPurposes();
		
		AdvanceCalculationParameters.SelectionParametersForSettlementDocument.SelectionTableName_ = "Jobs";
		AdvanceCalculationParameters.SelectionParametersForSettlementDocument.FieldName          = "TaxInvoice";
		AdvanceCalculationParameters.EnableGiftCertificateData                  = True;
		AdvanceCalculationParameters.AnalyzeManAccountingAdditionally                     = True;
		
		PrepareVT_AdvancesReceived_Occurrences(
				CalculationParameters.TempTablesManager,
				AdvanceCalculationParameters,
				CalculationParameters.SettingsTable);
			
	EndIf;
	
	Query = New Query;
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.Text = 
	"SELECT
	|	Calculations.DocumentPayments AS DocumentPayments,
	|	Calculations.Counterparty,
	|	SUM(Calculations.Prepayment_) AS Prepayment_,
	|	SUM(Calculations.AdvanceMan) AS AdvanceMan
	|FROM
	|	(SELECT
	|		VT_ARAPTransactionDocuments.OriginalARAPTransactionDocument AS DocumentPayments,
	|		Calculations.Counterparty AS Counterparty,
	|		Calculations.AdvanceAmount AS Prepayment_,
	|		Calculations.AdvanceAmountOfMan AS AdvanceMan
	|	FROM
	|		AdvancesReceived_Occurrences AS Calculations
	|			INNER JOIN ExpansionOfARAPTransactionTable AS VT_ARAPTransactionDocuments
	|			ON Calculations.Organization = VT_ARAPTransactionDocuments.Organization
	|				AND Calculations.ARAPDocument = VT_ARAPTransactionDocuments.DocumentPayments
	|	) AS Calculations
	|
	|GROUP BY
	|	Calculations.DocumentPayments,
	|	Calculations.Counterparty";
	
	Return Query.Execute().Unload();
	
EndFunction

Procedure GetCreditsForAdvancesReceived(CalculationParameters)
	
	AdvanceCalculationParameters = InitializeParametersForPreparationOfAdvancePaymentsForVATPurposes();
	
	AdvanceCalculationParameters.StartDate                                            = CalculationParameters.BeginOfPeriod;
	AdvanceCalculationParameters.EndDate                                         = CalculationParameters.EndOfPeriod;
	AdvanceCalculationParameters.Companies                                           = CalculationParameters.CompanyArray;
	AdvanceCalculationParameters.EnableGiftCertificateData                  = True;
	AdvanceCalculationParameters.SelectionParametersForSettlementDocument.SelectionTableName_ = "Jobs";
	AdvanceCalculationParameters.SelectionParametersForSettlementDocument.FieldName          = "TaxInvoice";
	
	PrepareVT_AdvancesReceived_Repayments(
			CalculationParameters.TempTablesManager,
			AdvanceCalculationParameters,
			CalculationParameters.SettingsTable);
	
	Query = New Query;
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.Text =
	"SELECT
	|	Credits.DocumentRecorder               AS Recorder,
	|	Credits.MaturityDate                     AS Period,
	|	Credits.Organization                       AS Organization,
	|	Credits.LineOfBusiness           AS LineOfBusiness,
	|	Credits.Counterparty                        AS Counterparty,
	|	VT_ARAPTransactionDocuments.OriginalARAPTransactionDocument AS DocumentPayments,
	|	Credits.DocumentRecorder               AS PrepaymentsSettlementDocument,
	|	Credits.ARAPObject                    AS ARAPObject,
	|	Credits.ReversingEntry                            AS ReversingEntry,
	|	SUM(Credits.EventSign)                AS EventSign,
	|	SUM(Credits.RepaymentAmount)             AS OffsetAmount_
	|INTO OffsetsOfAdvancesReceived
	|FROM
	|	AdvancesReceivedToMaturity AS Credits
	|	INNER JOIN
	|		ExpansionOfARAPTransactionTable AS VT_ARAPTransactionDocuments
	|	ON
	|		VT_ARAPTransactionDocuments.Organization = Credits.Organization
	|			AND VT_ARAPTransactionDocuments.DocumentPayments = Credits.ARAPDocument
	|
	|GROUP BY
	|	Credits.DocumentRecorder,
	|	Credits.MaturityDate,
	|	Credits.Organization,
	|	Credits.LineOfBusiness,
	|	Credits.Counterparty,
	|	VT_ARAPTransactionDocuments.OriginalARAPTransactionDocument,
	|	Credits.ARAPObject,
	|	Credits.ReversingEntry
	|
	|INDEX BY
	|	Recorder
	|;
	|
	|DROP AdvancesReceivedToMaturity
	|";
	
	Query.Execute();
	
	//For ISF, it is necessary to calculate the repayment data starting from the date of the payment document
	ThereIsISF = Not CalculationParameters.TempTablesManager.Tables["CorrectedInvoicesIssuedAdvanceRecalculation"].GetData().IsEmpty();
	If ThereIsISF Then

		AdvanceCalculationParameters.StartDate                                            = CalculationParameters.ISFBeginningOfPeriod;
		AdvanceCalculationParameters.EndDate                                         = CalculationParameters.ISFEndOfPeriod;
		AdvanceCalculationParameters.SelectionParametersForSettlementDocument.SelectionTableName_ = "CorrectedInvoicesIssuedAdvanceRecalculation";
		AdvanceCalculationParameters.SelectionParametersForSettlementDocument.FieldName          = "DocumentPayments";
	
		PrepareVT_AdvancesReceived_Repayments(
			CalculationParameters.TempTablesManager,
			AdvanceCalculationParameters,
			CalculationParameters.SettingsTable);
			
		Query.Parameters.Insert("ISFEndOfPeriod",CalculationParameters.ISFEndOfPeriod);
		Query.Text =
		"SELECT
		|	CASE
		|		WHEN VALUETYPE(Credits.DocumentRecorder) = TYPE(Document.ReversingEntry) AND Credits.ReversingEntry THEN
		|			CAST(Credits.DocumentRecorder AS Document.ReversingEntry).ReversedDocument
		|		ELSE Credits.DocumentRecorder
		|	END                                    AS Recorder,
		|	CASE
		|		WHEN VALUETYPE(Credits.DocumentRecorder) = TYPE(Document.ReversingEntry) AND Credits.ReversingEntry THEN
		|			CAST(Credits.DocumentRecorder AS Document.ReversingEntry).ReversedDocument.Date
		|		ELSE Credits.MaturityDate
		|	END                                    AS Period,
		|	Credits.Organization                       AS Organization,
		|	Credits.LineOfBusiness           AS LineOfBusiness,
		|	Credits.Counterparty                        AS Counterparty,
		|	VT_ARAPTransactionDocuments.OriginalARAPTransactionDocument AS DocumentPayments,
		|	CASE
		|		WHEN VALUETYPE(Credits.DocumentRecorder) = TYPE(Document.ReversingEntry) AND Credits.ReversingEntry THEN
		|			CAST(Credits.DocumentRecorder AS Document.ReversingEntry).ReversedDocument
		|		ELSE Credits.DocumentRecorder
		|	END                                    AS PrepaymentsSettlementDocument,
		|	Credits.ARAPObject                    AS ARAPObject,
		|	FALSE                                     AS ReversingEntry,
		|	SUM(Credits.EventSign)                AS EventSign,
		|	SUM(Credits.RepaymentAmount)             AS OffsetAmount_
		|INTO OffsetsOfAdvancesReceivedInterim
		|FROM
		|	AdvancesReceivedToMaturity AS Credits
		|	INNER JOIN
		|		ExpansionOfARAPTransactionTable AS VT_ARAPTransactionDocuments
		|	ON
		|		VT_ARAPTransactionDocuments.Organization   = Credits.Organization
		|			AND VT_ARAPTransactionDocuments.DocumentPayments = Credits.ARAPDocument
		|
		|GROUP BY
		|	CASE
		|		WHEN VALUETYPE(Credits.DocumentRecorder) = TYPE(Document.ReversingEntry) AND Credits.ReversingEntry THEN
		|			CAST(Credits.DocumentRecorder AS Document.ReversingEntry).ReversedDocument
		|		ELSE Credits.DocumentRecorder
		|	END,
		|	Credits.Organization,
		|	Credits.LineOfBusiness,
		|	Credits.Counterparty,
		|	VT_ARAPTransactionDocuments.OriginalARAPTransactionDocument,
		|	Credits.ARAPObject,
		|	CASE
		|		WHEN VALUETYPE(Credits.DocumentRecorder) = TYPE(Document.ReversingEntry) AND Credits.ReversingEntry THEN
		|			CAST(Credits.DocumentRecorder AS Document.ReversingEntry).ReversedDocument.Date
		|		ELSE Credits.MaturityDate
		|	END
		|
		|UNION ALL
		|
		|SELECT
		|	Credits.Recorder             AS Recorder,
		|	Credits.Period                  AS Period,
		|	Credits.Organization             AS Organization,
		|	Credits.LineOfBusiness AS LineOfBusiness,
		|	Credits.Counterparty              AS Counterparty,
		|	Credits.DocumentPayments          AS DocumentPayments,
		|	Credits.PrepaymentsSettlementDocument    AS PrepaymentsSettlementDocument,
		|	Credits.ARAPObject          AS ARAPObject,
		|	Credits.ReversingEntry                  AS ReversingEntry,
		|	Credits.EventSign             AS EventSign,
		|	Credits.OffsetAmount_             AS OffsetAmount_
		|FROM
		|	OffsetsOfAdvancesReceived AS Credits
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP AdvancesReceivedToMaturity
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP OffsetsOfAdvancesReceived
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Credits.Recorder             AS Recorder,
		|	Credits.Period                  AS Period,
		|	Credits.Organization             AS Organization,
		|	Credits.LineOfBusiness AS LineOfBusiness,
		|	Credits.Counterparty              AS Counterparty,
		|	Credits.DocumentPayments          AS DocumentPayments,
		|	Credits.PrepaymentsSettlementDocument    AS PrepaymentsSettlementDocument,
		|	Credits.ARAPObject          AS ARAPObject,
		|	Credits.ReversingEntry                  AS ReversingEntry,
		|	SUM(Credits.EventSign)      AS EventSign,
		|	SUM(Credits.OffsetAmount_)      AS OffsetAmount_
		|INTO OffsetsOfAdvancesReceived
		|FROM
		|	OffsetsOfAdvancesReceivedInterim AS Credits
		|	
		|GROUP BY
		|	Credits.Recorder,
		|	Credits.Period,
		|	Credits.Organization,
		|	Credits.LineOfBusiness,
		|	Credits.Counterparty,
		|	Credits.DocumentPayments,
		|	Credits.PrepaymentsSettlementDocument,
		|	Credits.ARAPObject,
		|	Credits.ReversingEntry
		|
		|INDEX BY
		|	Recorder
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP OffsetsOfAdvancesReceivedInterim
		|";

		Query.Execute();

	EndIf;
	
EndProcedure

Function CalculateVATAdvancesReceivedOnISF(CalculationParameters)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	1                                                    AS Priority,
	|	VATPrepaymentsFromCustomer.Recorder                      AS Recorder,
	|	VATPrepaymentsFromCustomer.Period                           AS Period,
	|	VATPrepaymentsFromCustomer.RecordType                      AS RecordType,
	|	VATPrepaymentsFromCustomer.Organization                      AS Organization,
	|	VATPrepaymentsFromCustomer.DocumentPayments                   AS DocumentPayments,
	|	VATPrepaymentsFromCustomer.Counterparty                       AS Counterparty,
	|	VATPrepaymentsFromCustomer.CorrectedTaxInvoice          AS CorrectedTaxInvoice,
	|	VATPrepaymentsFromCustomer.Department                    AS Department,
	|	VATPrepaymentsFromCustomer.LineOfBusiness          AS LineOfBusiness,
	|	VATPrepaymentsFromCustomer.VATRate                        AS VATRate,
	|	SUM(VATPrepaymentsFromCustomer.AmountExcludingVAT)               AS AmountExcludingVAT,
	|	SUM(VATPrepaymentsFromCustomer.VAT)                       AS VAT,
	|	SUM(VATPrepaymentsFromCustomer.VATManag)                    AS VATManag,
	|	TRUE                                               AS PeriodEndTransaction,
	|	FALSE                                                 AS ReversingEntry,
	|	VATPrepaymentsFromCustomer.Event                          AS Event,
	|	VATPrepaymentsFromCustomer.PrepaymentsSettlementDocument             AS PrepaymentsSettlementDocument,
	|	VATPrepaymentsFromCustomer.FinRecordID           AS FinRecordID,
	|	VATPrepaymentsFromCustomer.BusinessTransactionSetting   AS BusinessTransactionSetting,
	|	VATPrepaymentsFromCustomer.ARAPObject                   AS ARAPObject
	|INTO VATAdvancesReceivedUnderISF
	|FROM
	|	(SELECT
	|		CorrectedInvoices.Ref                      AS Recorder,
	|		CorrectedInvoices.Period                      AS Period,
	|		VATPrepaymentsFromCustomer.RecordType                      AS RecordType,
	|		VATPrepaymentsFromCustomer.Organization                      AS Organization,
	|		VATPrepaymentsFromCustomer.DocumentPayments                   AS DocumentPayments,
	|		VATPrepaymentsFromCustomer.Counterparty                       AS Counterparty,
	|		VATPrepaymentsFromCustomer.CorrectedTaxInvoice          AS CorrectedTaxInvoice,
	|		VATPrepaymentsFromCustomer.Department                    AS Department,
	|		VATPrepaymentsFromCustomer.LineOfBusiness          AS LineOfBusiness,
	|		VATPrepaymentsFromCustomer.VATRate                        AS VATRate,
	|		-VATPrepaymentsFromCustomer.AmountExcludingVAT                     AS AmountExcludingVAT,
	|		-VATPrepaymentsFromCustomer.VAT                             AS VAT,
	|		-VATPrepaymentsFromCustomer.VATManag                          AS VATManag,
	|		VATPrepaymentsFromCustomer.Event                          AS Event,
	|		VATPrepaymentsFromCustomer.PrepaymentsSettlementDocument             AS PrepaymentsSettlementDocument,
	|		VATPrepaymentsFromCustomer.FinRecordID           AS FinRecordID,
	|		VATPrepaymentsFromCustomer.BusinessTransactionSetting   AS BusinessTransactionSetting,
	|		VATPrepaymentsFromCustomer.ARAPObject                   AS ARAPObject
	|	FROM
	|		CorrectedInvoicesIssuedInAdvance AS CorrectedInvoices
	|		INNER JOIN
	|			AccumulationRegister.VATPrepaymentsFromCustomer AS VATPrepaymentsFromCustomer
	|		ON
	|			VATPrepaymentsFromCustomer.Organization = CorrectedInvoices.Organization
	|			AND VATPrepaymentsFromCustomer.DocumentPayments = CorrectedInvoices.DocumentPayments
	|			AND VATPrepaymentsFromCustomer.Period < &BeginOfPeriod
	|			AND VATPrepaymentsFromCustomer.CorrectedTaxInvoice <> CorrectedInvoices.CorrectedTaxInvoice
	|			AND VATPrepaymentsFromCustomer.Active
	|
	|	UNION ALL
	|	
	|	SELECT
	|		CorrectedInvoices.Ref                      AS Recorder,
	|		CorrectedInvoices.Period                      AS Period,
	|		VATPrepaymentsFromCustomer.RecordType                      AS RecordType,
	|		VATPrepaymentsFromCustomer.Organization                      AS Organization,
	|		VATPrepaymentsFromCustomer.DocumentPayments                   AS DocumentPayments,
	|		VATPrepaymentsFromCustomer.Counterparty                       AS Counterparty,
	|		VATPrepaymentsFromCustomer.CorrectedTaxInvoice          AS CorrectedTaxInvoice,
	|		VATPrepaymentsFromCustomer.Department                    AS Department,
	|		VATPrepaymentsFromCustomer.LineOfBusiness          AS LineOfBusiness,
	|		VATPrepaymentsFromCustomer.VATRate                        AS VATRate,
	|		-VATPrepaymentsFromCustomer.AmountExcludingVAT                      AS AmountExcludingVAT,
	|		-VATPrepaymentsFromCustomer.VAT                             AS VAT,
	|		-VATPrepaymentsFromCustomer.VATManag                          AS VATManag,
	|		VATPrepaymentsFromCustomer.Event                         AS Event,
	|		VATPrepaymentsFromCustomer.PrepaymentsSettlementDocument             AS PrepaymentsSettlementDocument,
	|		VATPrepaymentsFromCustomer.FinRecordID           AS FinRecordID,
	|		VATPrepaymentsFromCustomer.BusinessTransactionSetting   AS BusinessTransactionSetting,
	|		VATPrepaymentsFromCustomer.ARAPObject                   AS ARAPObject
	|
	|	FROM
	|		CorrectedInvoicesIssuedInAdvance AS CorrectedInvoices
	|		INNER JOIN
	|			AccumulationRegister.VATPrepaymentsFromCustomer AS VATPrepaymentsFromCustomer
	|		ON
	|			VATPrepaymentsFromCustomer.Organization = CorrectedInvoices.Organization
	|			AND VATPrepaymentsFromCustomer.DocumentPayments = CorrectedInvoices.DocumentPayments
	|			AND VATPrepaymentsFromCustomer.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|			AND VATPrepaymentsFromCustomer.CorrectedTaxInvoice <> CorrectedInvoices.CorrectedTaxInvoice
	|			AND NOT VATPrepaymentsFromCustomer.PeriodEndTransaction
	|			AND VATPrepaymentsFromCustomer.Active
	|
	|	UNION ALL
	|
	|	SELECT
	|		CorrectedInvoices.Ref                      AS Recorder,
	|		CorrectedInvoices.Period                      AS Period,
	|		VATPrepaymentsFromCustomer.RecordType                      AS RecordType,
	|		VATPrepaymentsFromCustomer.Organization                      AS Organization,
	|		VATPrepaymentsFromCustomer.DocumentPayments                   AS DocumentPayments,
	|		VATPrepaymentsFromCustomer.Counterparty                       AS Counterparty,
	|		CorrectedInvoices.CorrectedTaxInvoice     AS CorrectedTaxInvoice,
	|		VATPrepaymentsFromCustomer.Department                    AS Department,
	|		VATPrepaymentsFromCustomer.LineOfBusiness          AS LineOfBusiness,
	|		VATPrepaymentsFromCustomer.VATRate                        AS VATRate,
	|		VATPrepaymentsFromCustomer.AmountExcludingVAT                      AS AmountExcludingVAT,
	|		VATPrepaymentsFromCustomer.VAT                              AS VAT,
	|		VATPrepaymentsFromCustomer.VATManag                           AS VATManag,
	|		VATPrepaymentsFromCustomer.Event                          AS Event,
	|		VATPrepaymentsFromCustomer.PrepaymentsSettlementDocument             AS PrepaymentsSettlementDocument,
	|		VATPrepaymentsFromCustomer.FinRecordID           AS FinRecordID,
	|		VATPrepaymentsFromCustomer.BusinessTransactionSetting   AS BusinessTransactionSetting,
	|		VATPrepaymentsFromCustomer.ARAPObject                   AS ARAPObject
	|	FROM
	|		CorrectedInvoicesIssuedInAdvance AS CorrectedInvoices
	|		INNER JOIN
	|			AccumulationRegister.VATPrepaymentsFromCustomer AS VATPrepaymentsFromCustomer
	|		ON
	|			VATPrepaymentsFromCustomer.Organization = CorrectedInvoices.Organization
	|			AND VATPrepaymentsFromCustomer.DocumentPayments = CorrectedInvoices.DocumentPayments
	|			AND VATPrepaymentsFromCustomer.Period < &BeginOfPeriod
	|			AND VATPrepaymentsFromCustomer.CorrectedTaxInvoice <> CorrectedInvoices.CorrectedTaxInvoice
	|			AND VATPrepaymentsFromCustomer.Active
	|			AND VATPrepaymentsFromCustomer.Event = VALUE(Enum.EventsVATFromPrepayments.WriteOffVATFromPrepaymentFromCustomer)
	|
	|	UNION ALL
	|
	|	SELECT
	|		CorrectedInvoices.Ref                      AS Recorder,
	|		CorrectedInvoices.Period                      AS Period,
	|		VATPrepaymentsFromCustomer.RecordType                      AS RecordType,
	|		VATPrepaymentsFromCustomer.Organization                      AS Organization,
	|		VATPrepaymentsFromCustomer.DocumentPayments                   AS DocumentPayments,
	|		VATPrepaymentsFromCustomer.Counterparty                       AS Counterparty,
	|		CorrectedInvoices.CorrectedTaxInvoice     AS CorrectedTaxInvoice,
	|		VATPrepaymentsFromCustomer.Department                    AS Department,
	|		VATPrepaymentsFromCustomer.LineOfBusiness          AS LineOfBusiness,
	|		VATPrepaymentsFromCustomer.VATRate                        AS VATRate,
	|		VATPrepaymentsFromCustomer.AmountExcludingVAT                      AS AmountExcludingVAT,
	|		VATPrepaymentsFromCustomer.VAT                              AS VAT,
	|		VATPrepaymentsFromCustomer.VATManag                           AS VATManag,
	|		VATPrepaymentsFromCustomer.Event                          AS Event,
	|		VATPrepaymentsFromCustomer.PrepaymentsSettlementDocument             AS PrepaymentsSettlementDocument,
	|		VATPrepaymentsFromCustomer.FinRecordID           AS FinRecordID,
	|		VATPrepaymentsFromCustomer.BusinessTransactionSetting   AS BusinessTransactionSetting,
	|		VATPrepaymentsFromCustomer.ARAPObject                   AS ARAPObject
	|
	|	FROM
	|		CorrectedInvoicesIssuedInAdvance AS CorrectedInvoices
	|		INNER JOIN
	|			AccumulationRegister.VATPrepaymentsFromCustomer AS VATPrepaymentsFromCustomer
	|		ON
	|			VATPrepaymentsFromCustomer.Organization = CorrectedInvoices.Organization
	|			AND VATPrepaymentsFromCustomer.DocumentPayments = CorrectedInvoices.DocumentPayments
	|			AND VATPrepaymentsFromCustomer.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|			AND VATPrepaymentsFromCustomer.CorrectedTaxInvoice <> CorrectedInvoices.CorrectedTaxInvoice
	|			AND NOT VATPrepaymentsFromCustomer.PeriodEndTransaction
	|			AND VATPrepaymentsFromCustomer.Active
	|			AND VATPrepaymentsFromCustomer.Event = VALUE(Enum.EventsVATFromPrepayments.WriteOffVATFromPrepaymentFromCustomer)) AS VATPrepaymentsFromCustomer
	|
	|GROUP BY
	|	VATPrepaymentsFromCustomer.Recorder,
	|	VATPrepaymentsFromCustomer.Period,
	|	VATPrepaymentsFromCustomer.RecordType,
	|	VATPrepaymentsFromCustomer.Organization,
	|	VATPrepaymentsFromCustomer.DocumentPayments,
	|	VATPrepaymentsFromCustomer.Counterparty,
	|	VATPrepaymentsFromCustomer.CorrectedTaxInvoice,
	|	VATPrepaymentsFromCustomer.Department,
	|	VATPrepaymentsFromCustomer.LineOfBusiness,
	|	VATPrepaymentsFromCustomer.VATRate,
	|	VATPrepaymentsFromCustomer.Event,
	|	VATPrepaymentsFromCustomer.PrepaymentsSettlementDocument,
	|	VATPrepaymentsFromCustomer.FinRecordID,
	|	VATPrepaymentsFromCustomer.BusinessTransactionSetting,
	|	VATPrepaymentsFromCustomer.ARAPObject
	|
	|HAVING
	|	SUM(VATPrepaymentsFromCustomer.AmountExcludingVAT) <> 0
	|		OR SUM(VATPrepaymentsFromCustomer.VAT) <> 0
	|
	|INDEX BY
	|	Organization,
	|	DocumentPayments
	|";
	
	Query.SetParameter("BeginOfPeriod", CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",  CalculationParameters.EndOfPeriod);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.Execute();
	
	Return "VATAdvancesReceivedUnderISF";
	
EndFunction

Procedure GetBalanceOfAdvancesReceivedBeforeTransfer(CalculationParameters)
	
	AdvanceCalculationParameters = InitializeParametersForPreparationOfAdvancePaymentsForVATPurposes();
	
	//For ISF, it is necessary to calculate the repayment data starting from the date of the payment document
	ThereIsISF = Not CalculationParameters.TempTablesManager.Tables["CorrectedInvoicesIssuedAdvanceRecalculation"].GetData().IsEmpty();
	If ThereIsISF Then
		
		Query = New Query;
		Query.TempTablesManager = CalculationParameters.TempTablesManager;
		Query.Text =
		"SELECT
		|	TT_TableOfPayment.OriginalARAPTransactionDocument AS DocumentPayments
		|INTO PaymentDocuments
		|FROM
		|	ExpansionOfARAPTransactionTable AS TT_TableOfPayment
		|		LEFT JOIN CorrectedInvoicesIssuedAdvanceRecalculation AS CorrectedInvoicesIssuedInAdvance
		|		ON TT_TableOfPayment.Organization = CorrectedInvoicesIssuedInAdvance.Organization
		|			AND TT_TableOfPayment.OriginalARAPTransactionDocument = CorrectedInvoicesIssuedInAdvance.DocumentPayments
		|WHERE
		|	CorrectedInvoicesIssuedInAdvance.DocumentPayments IS NULL";
	
		Query.Execute();
		
		AdvanceCalculationParameters.StartDate                                            = CalculationParameters.BeginOfPeriod;
		AdvanceCalculationParameters.EndDate                                         = CalculationParameters.EndOfPeriod;
		AdvanceCalculationParameters.Companies                                           = CalculationParameters.CompanyArray;
		AdvanceCalculationParameters.EnableGiftCertificateData                  = True;
		AdvanceCalculationParameters.SelectionParametersForSettlementDocument.SelectionTableName_ = "PaymentDocuments";
		AdvanceCalculationParameters.SelectionParametersForSettlementDocument.FieldName          = "DocumentPayments";
	
		PrepareBT_BalancesAdvancesReceivedBeforeTransfer(
			CalculationParameters.TempTablesManager,
			AdvanceCalculationParameters,
			CalculationParameters.SettingsTable);

		Query = New Query;
		Query.TempTablesManager = CalculationParameters.TempTablesManager;
		Query.Text =
		"SELECT
		|	Balance.Organization             AS Organization,
		|	Balance.DocumentPayments          AS DocumentPayments,
		|	Balance.Counterparty              AS Counterparty,
		|	Balance.CorrectedTaxInvoice AS CorrectedTaxInvoice,
		|	Balance.Department           AS Department,
		|	Balance.LineOfBusiness AS LineOfBusiness,
		|	Balance.ARAPObject          AS ARAPObject,
		|	Balance.VATRate               AS VATRate,
		|	Balance.AmountExcludingVAT             AS AmountExcludingVAT,
		|	Balance.VAT                     AS VAT,
		|	Balance.VATManag                  AS VATManag
		|INTO BalancesAdvancesReceivedBeforeTransferInterim
		|FROM
		|	BalancesAdvancesReceivedBeforeTransfer AS Balance
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP BalancesAdvancesReceivedBeforeTransfer
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP PaymentDocuments
		|;";

		Query.Execute();
		
		AdvanceCalculationParameters.StartDate                                            = CalculationParameters.ISFBeginningOfPeriod;
		AdvanceCalculationParameters.EndDate                                         = CalculationParameters.EndOfPeriod;
		AdvanceCalculationParameters.SelectionParametersForSettlementDocument.SelectionTableName_ = "CorrectedInvoicesIssuedAdvanceRecalculation";
		AdvanceCalculationParameters.SelectionParametersForSettlementDocument.FieldName          = "DocumentPayments";
	
		PrepareBT_BalancesAdvancesReceivedBeforeTransfer(
			CalculationParameters.TempTablesManager,
			AdvanceCalculationParameters,
			CalculationParameters.SettingsTable);
		
		Query.Text =
		"SELECT
		|	Balance.Organization             AS Organization,
		|	Balance.DocumentPayments          AS DocumentPayments,
		|	Balance.Counterparty              AS Counterparty,
		|	Balance.CorrectedTaxInvoice AS CorrectedTaxInvoice,
		|	Balance.Department           AS Department,
		|	Balance.LineOfBusiness AS LineOfBusiness,
		|	Balance.ARAPObject          AS ARAPObject,
		|	Balance.VATRate               AS VATRate,
		|	Balance.AmountExcludingVAT             AS AmountExcludingVAT,
		|	Balance.VAT                     AS VAT,
		|	Balance.VATManag                  AS VATManag
		|INTO BalancesAdvancesReceivedBeforeTransferTotal
		|FROM
		|	BalancesAdvancesReceivedBeforeTransferInterim AS Balance
		|
		|UNION ALL
		|
		|SELECT
		|	Balance.Organization             AS Organization,
		|	Balance.DocumentPayments          AS DocumentPayments,
		|	Balance.Counterparty              AS Counterparty,
		|	Balance.CorrectedTaxInvoice AS CorrectedTaxInvoice,
		|	Balance.Department           AS Department,
		|	Balance.LineOfBusiness AS LineOfBusiness,
		|	Balance.ARAPObject          AS ARAPObject,
		|	Balance.VATRate               AS VATRate,
		|	Balance.AmountExcludingVAT             AS AmountExcludingVAT,
		|	Balance.VAT                     AS VAT,
		|	Balance.VATManag                  AS VATManag
		|FROM
		|	BalancesAdvancesReceivedBeforeTransfer AS Balance
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP BalancesAdvancesReceivedBeforeTransferInterim
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP BalancesAdvancesReceivedBeforeTransfer
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Balance.Organization             AS Organization,
		|	Balance.DocumentPayments          AS DocumentPayments,
		|	Balance.Counterparty              AS Counterparty,
		|	Balance.CorrectedTaxInvoice AS CorrectedTaxInvoice,
		|	Balance.Department           AS Department,
		|	Balance.LineOfBusiness AS LineOfBusiness,
		|	Balance.ARAPObject          AS ARAPObject,
		|	Balance.VATRate               AS VATRate,
		|	Balance.AmountExcludingVAT             AS AmountExcludingVAT,
		|	Balance.VAT                     AS VAT,
		|	Balance.VATManag                  AS VATManag
		|INTO BalancesAdvancesReceivedBeforeTransfer
		|FROM
		|	BalancesAdvancesReceivedBeforeTransferTotal AS Balance
		|
		|INDEX BY
		|	Organization,
		|	DocumentPayments,
		|	Counterparty
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP BalancesAdvancesReceivedBeforeTransferTotal
		|";

		Query.Execute();

	Else
			
		AdvanceCalculationParameters.StartDate                                            = CalculationParameters.BeginOfPeriod;
		AdvanceCalculationParameters.EndDate                                         = CalculationParameters.EndOfPeriod;
		AdvanceCalculationParameters.Companies                                           = CalculationParameters.CompanyArray;
		AdvanceCalculationParameters.EnableGiftCertificateData                  = True;
		AdvanceCalculationParameters.SelectionParametersForSettlementDocument.SelectionTableName_ = "ExpansionOfARAPTransactionTable";
		AdvanceCalculationParameters.SelectionParametersForSettlementDocument.FieldName          = "OriginalARAPTransactionDocument"; 
		
		PrepareBT_BalancesAdvancesReceivedBeforeTransfer(
			CalculationParameters.TempTablesManager,
			AdvanceCalculationParameters,
			CalculationParameters.SettingsTable);

	EndIf; 
	
EndProcedure

Function CalculateVATAdvancesReceivedTransfersArrival(CalculationParameters)
	
	GetBalanceOfAdvancesReceivedBeforeTransfer(CalculationParameters);

	AdvanceCalculationParameters = InitializeParametersForPreparationOfAdvancePaymentsForVATPurposes();
	
	AdvanceCalculationParameters.StartDate                                            = CalculationParameters.BeginOfPeriod;
	AdvanceCalculationParameters.EndDate                                         = CalculationParameters.EndOfPeriod;
	AdvanceCalculationParameters.Companies                                           = CalculationParameters.CompanyArray;
	AdvanceCalculationParameters.EnableGiftCertificateData                  = True;
	AdvanceCalculationParameters.SelectionParametersForSettlementDocument.SelectionTableName_ = "Jobs";
	AdvanceCalculationParameters.SelectionParametersForSettlementDocument.FieldName          = "TaxInvoice";
	
	PrepareVT_SettlementsWithClients_TransfersOfAdvances(
			CalculationParameters.TempTablesManager,
			AdvanceCalculationParameters,
			CalculationParameters.SettingsTable);

	//For ISF, it is necessary to calculate the repayment data starting from the date of the payment document
	ThereIsISF = Not CalculationParameters.TempTablesManager.Tables["CorrectedInvoicesIssuedAdvanceRecalculation"].GetData().IsEmpty();
	If ThereIsISF Then

		Query = New Query;
		Query.TempTablesManager = CalculationParameters.TempTablesManager;
		Query.Text =
		"SELECT
		|	DD.Organization                    AS Organization,
		|	DD.PrepaymentsSettlementDocument           AS PrepaymentsSettlementDocument,
		|	DD.DocumentPayments                 AS DocumentPayments,
		|	DD.AccountingDimensionByPartners      AS AccountingDimensionByPartners,
		|	DD.ARAPObject                 AS ARAPObject,
		|	DD.Counterparty                     AS Counterparty,
		|	DD.LineOfBusiness        AS LineOfBusiness,
		|	DD.Department                  AS Department,
		|	DD.CorPartnerAccountingDimension   AS CorPartnerAccountingDimension,
		|	DD.CorARAPObject              AS CorARAPObject,
		|	DD.CorCounterparty                  AS CorCounterparty,
		|	DD.CorLineOfBusiness     AS CorLineOfBusiness,
		|	DD.DebitBusinessUnit               AS DebitBusinessUnit,
		|	DD.Period                         AS Period,
		|	DD.BusinessTransactionSetting AS BusinessTransactionSetting,
		|	DD.FinRecordID         AS FinRecordID,
		|	DD.ReversingEntry                         AS ReversingEntry,
		|	DD.Currency                         AS Currency,
		|	DD.Prepayment                     AS Prepayment,
		|	DD.PrepaymentLocal                 AS PrepaymentLocal,
		|	DD.PrepaymentMan                  AS PrepaymentMan
		|INTO SettlementsWithClients_TransfersOfAdvancesInterim
		|FROM
		|	SettlementsWithClients_TransfersOfAdvances AS DD
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP SettlementsWithClients_TransfersOfAdvances
		|;
		|";

		Query.Execute();
		
		AdvanceCalculationParameters.StartDate                                            = CalculationParameters.ISFBeginningOfPeriod;
		AdvanceCalculationParameters.EndDate                                         = CalculationParameters.ISFEndOfPeriod;
		AdvanceCalculationParameters.SelectionParametersForSettlementDocument.SelectionTableName_ = "CorrectedInvoicesIssuedAdvanceRecalculation";
		AdvanceCalculationParameters.SelectionParametersForSettlementDocument.FieldName          = "DocumentPayments";
	
		PrepareVT_SettlementsWithClients_TransfersOfAdvances(
			CalculationParameters.TempTablesManager,
			AdvanceCalculationParameters,
			CalculationParameters.SettingsTable);
		
		Query.Text =
		"SELECT
		|	DD.Organization                    AS Organization,
		|	DD.PrepaymentsSettlementDocument           AS PrepaymentsSettlementDocument,
		|	DD.DocumentPayments                 AS DocumentPayments,
		|	DD.AccountingDimensionByPartners      AS AccountingDimensionByPartners,
		|	DD.ARAPObject                 AS ARAPObject,
		|	DD.Counterparty                     AS Counterparty,
		|	DD.LineOfBusiness        AS LineOfBusiness,
		|	DD.Department                  AS Department,
		|	DD.CorPartnerAccountingDimension   AS CorPartnerAccountingDimension,
		|	DD.CorARAPObject              AS CorARAPObject,
		|	DD.CorCounterparty                  AS CorCounterparty,
		|	DD.CorLineOfBusiness     AS CorLineOfBusiness,
		|	DD.DebitBusinessUnit               AS DebitBusinessUnit,
		|	DD.Period                         AS Period,
		|	DD.BusinessTransactionSetting AS BusinessTransactionSetting,
		|	DD.FinRecordID         AS FinRecordID,
		|	DD.ReversingEntry                         AS ReversingEntry,
		|	DD.Currency                         AS Currency,
		|	DD.Prepayment                     AS Prepayment,
		|	DD.PrepaymentLocal                 AS PrepaymentLocal,
		|	DD.PrepaymentMan                  AS PrepaymentMan
		|INTO SettlementsWithClients_TransfersOfAdvancesTotal
		|FROM
		|	SettlementsWithClients_TransfersOfAdvancesInterim AS DD
		|
		|UNION ALL
		|
		|SELECT
		|	DD.Organization                    AS Organization,
		|	DD.PrepaymentsSettlementDocument           AS PrepaymentsSettlementDocument,
		|	DD.DocumentPayments                 AS DocumentPayments,
		|	DD.AccountingDimensionByPartners      AS AccountingDimensionByPartners,
		|	DD.ARAPObject                 AS ARAPObject,
		|	DD.Counterparty                     AS Counterparty,
		|	DD.LineOfBusiness        AS LineOfBusiness,
		|	DD.Department                  AS Department,
		|	DD.CorPartnerAccountingDimension   AS CorPartnerAccountingDimension,
		|	DD.CorARAPObject              AS CorARAPObject,
		|	DD.CorCounterparty                  AS CorCounterparty,
		|	DD.CorLineOfBusiness     AS CorLineOfBusiness,
		|	DD.DebitBusinessUnit               AS DebitBusinessUnit,
		|	DD.Period                         AS Period,
		|	DD.BusinessTransactionSetting AS BusinessTransactionSetting,
		|	DD.FinRecordID         AS FinRecordID,
		|	DD.ReversingEntry                         AS ReversingEntry,
		|	DD.Currency                         AS Currency,
		|	DD.Prepayment                     AS Prepayment,
		|	DD.PrepaymentLocal                 AS PrepaymentLocal,
		|	DD.PrepaymentMan                  AS PrepaymentMan
		|FROM
		|	SettlementsWithClients_TransfersOfAdvances AS DD
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP SettlementsWithClients_TransfersOfAdvancesInterim
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP SettlementsWithClients_TransfersOfAdvances
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DD.Organization                    AS Organization,
		|	DD.PrepaymentsSettlementDocument           AS PrepaymentsSettlementDocument,
		|	DD.DocumentPayments                 AS DocumentPayments,
		|	DD.AccountingDimensionByPartners      AS AccountingDimensionByPartners,
		|	DD.ARAPObject                 AS ARAPObject,
		|	DD.Counterparty                     AS Counterparty,
		|	DD.LineOfBusiness        AS LineOfBusiness,
		|	DD.Department                  AS Department,
		|	DD.CorPartnerAccountingDimension   AS CorPartnerAccountingDimension,
		|	DD.CorARAPObject              AS CorARAPObject,
		|	DD.CorCounterparty                  AS CorCounterparty,
		|	DD.CorLineOfBusiness     AS CorLineOfBusiness,
		|	DD.DebitBusinessUnit               AS DebitBusinessUnit,
		|	DD.Period                         AS Period,
		|	DD.BusinessTransactionSetting AS BusinessTransactionSetting,
		|	DD.FinRecordID         AS FinRecordID,
		|	DD.ReversingEntry                         AS ReversingEntry,
		|	DD.Currency                         AS Currency,
		|	DD.Prepayment                     AS Prepayment,
		|	DD.PrepaymentLocal                 AS PrepaymentLocal,
		|	DD.PrepaymentMan                  AS PrepaymentMan
		|INTO SettlementsWithClients_TransfersOfAdvances
		|FROM
		|	SettlementsWithClients_TransfersOfAdvancesTotal AS DD
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP SettlementsWithClients_TransfersOfAdvancesTotal
		|";

		Query.Execute();

	EndIf;
	
	Query = New Query;
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.Text = 
	"SELECT
	|	ISNULL(CorrectedInvoicesIssuedInAdvance.Ref, InvoicesIssuedInAdvance.Ref) AS Ref,
	|	ISNULL(CorrectedInvoicesIssuedInAdvance.RuleOfPrepaymentFilter, InvoicesIssuedInAdvance.RuleOfPrepaymentFilter) AS RuleOfPrepaymentFilter,
	|	ISNULL(CorrectedInvoicesIssuedInAdvance.Date, InvoicesIssuedInAdvance.Date) AS Date,
	|	CASE
	|		WHEN NOT CorrectedInvoicesIssuedInAdvance.Ref IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                                                             AS Patch,
	|	ISNULL(CorrectedInvoicesIssuedInAdvance.CorrectionDate, DATETIME(1,1,1)) AS CorrectionDate,
	|	DD.Organization AS Organization,
	|	DD.DocumentPayments AS DocumentPayments,
	|	DD.Counterparty AS Counterparty,
	|	DD.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|	DD.Department AS Department,
	|	DD.LineOfBusiness AS LineOfBusiness,
	|	DD.ARAPObject AS ARAPObject,
	|	DD.VATRate AS VATRate,
	|	DD.AmountExcludingVAT AS AmountExcludingVAT,
	|	DD.VAT AS VAT,
	|	DD.VATManag AS VATManag
	|FROM
	|	BalancesAdvancesReceivedBeforeTransfer AS DD
	|	LEFT JOIN
	|		InvoicesIssuedInAdvance AS InvoicesIssuedInAdvance
	|	ON
	|		DD.Organization = InvoicesIssuedInAdvance.Organization
	|		AND DD.DocumentPayments = InvoicesIssuedInAdvance.DocumentPayments
	|		AND (CASE
	|				WHEN VALUETYPE(DD.DocumentPayments) = TYPE(Document.OBEntry)
	|					THEN DD.Counterparty = InvoicesIssuedInAdvance.Counterparty
	|				ELSE TRUE
	|			END)
	|
	|	LEFT JOIN
	|		CorrectedInvoicesIssuedInAdvance AS CorrectedInvoicesIssuedInAdvance
	|	ON
	|		DD.Organization = CorrectedInvoicesIssuedInAdvance.Organization
	|		AND DD.DocumentPayments = CorrectedInvoicesIssuedInAdvance.DocumentPayments
	|		AND (CASE
	|				WHEN VALUETYPE(DD.DocumentPayments) = TYPE(Document.OBEntry)
	|					THEN DD.Counterparty = CorrectedInvoicesIssuedInAdvance.Counterparty
	|				ELSE TRUE
	|			END)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FALSE                                      AS ThereIsDataOnRevenue,
	|	1 AS                                     EventSign,
	|	DD.Period                                 AS Period,
	|	DD.Counterparty                             AS Counterparty,
	|	DD.Department                          AS Department,
	|	DD.LineOfBusiness                AS LineOfBusiness,
	|	DD.FinRecordID                 AS FinRecordID,
	|	DD.ARAPObject                         AS ARAPObject,
	|	TT_PaymentDocuments.OriginalARAPTransactionDocument AS DocumentPayments,
	|	DD.PrepaymentLocal                         AS OffsetAmount_,
	|	DD.PrepaymentMan                          AS ManSCreditAmount,
	|	DD.PrepaymentsSettlementDocument                   AS PrepaymentsSettlementDocument,
	|	FALSE                                      AS ReversingEntry
	|FROM
	|	SettlementsWithClients_TransfersOfAdvances AS DD
	|	INNER JOIN
	|		ExpansionOfARAPTransactionTable AS TT_PaymentDocuments
	|	ON
	|		DD.Organization = TT_PaymentDocuments.Organization
	|		AND DD.DocumentPayments = TT_PaymentDocuments.DocumentPayments
	|	LEFT JOIN
	|		InvoicesIssuedInAdvance AS InvoicesIssuedInAdvance
	|	ON
	|		DD.Organization = InvoicesIssuedInAdvance.Organization
	|		AND TT_PaymentDocuments.OriginalARAPTransactionDocument = InvoicesIssuedInAdvance.DocumentPayments
	|		AND (CASE
	|				WHEN VALUETYPE(TT_PaymentDocuments.OriginalARAPTransactionDocument) = TYPE(Document.OBEntry)
	|					THEN DD.Counterparty = InvoicesIssuedInAdvance.Counterparty
	|				ELSE TRUE
	|			END)
	|
	|	LEFT JOIN
	|		CorrectedInvoicesIssuedInAdvance AS CorrectedInvoicesIssuedInAdvance
	|	ON
	|		DD.Organization = CorrectedInvoicesIssuedInAdvance.Organization
	|		AND TT_PaymentDocuments.OriginalARAPTransactionDocument = CorrectedInvoicesIssuedInAdvance.DocumentPayments
	|		AND (CASE
	|				WHEN VALUETYPE(TT_PaymentDocuments.OriginalARAPTransactionDocument) = TYPE(Document.OBEntry)
	|					THEN DD.Counterparty = CorrectedInvoicesIssuedInAdvance.Counterparty
	|				ELSE TRUE
	|			END)
	|WHERE
	|	DD.Period > ISNULL(CorrectedInvoicesIssuedInAdvance.Date, InvoicesIssuedInAdvance.Date)
	|	AND DD.ReversingEntry = FALSE
	|	
	|UNION ALL
	|	
	|SELECT
	|	FALSE                                      AS ThereIsDataOnRevenue,
	|	1                                         AS EventSign,
	|	DD.Period                                 AS Period,
	|	DD.CorCounterparty                          AS Counterparty,
	|	DD.CorLineOfBusiness             AS LineOfBusiness,
	|	DD.DebitBusinessUnit                       AS Department,
	|	DD.FinRecordID                 AS FinRecordID,
	|	DD.CorARAPObject                      AS ARAPObject,
	|	TT_PaymentDocuments.OriginalARAPTransactionDocument AS DocumentPayments,
	|	-DD.PrepaymentLocal                        AS OffsetAmount_,
	|	-DD.PrepaymentMan                         AS ManSCreditAmount,
	|	DD.PrepaymentsSettlementDocument                   AS PrepaymentsSettlementDocument,
	|	FALSE                                      AS ReversingEntry
	|FROM
	|	SettlementsWithClients_TransfersOfAdvances AS DD
	|	INNER JOIN
	|		ExpansionOfARAPTransactionTable AS TT_PaymentDocuments
	|	ON
	|		DD.Organization = TT_PaymentDocuments.Organization
	|		AND DD.DocumentPayments = TT_PaymentDocuments.DocumentPayments
	|	LEFT JOIN
	|		InvoicesIssuedInAdvance AS InvoicesIssuedInAdvance
	|	ON
	|		DD.Organization = InvoicesIssuedInAdvance.Organization
	|		AND TT_PaymentDocuments.OriginalARAPTransactionDocument = InvoicesIssuedInAdvance.DocumentPayments
	|		AND (CASE
	|				WHEN VALUETYPE(TT_PaymentDocuments.OriginalARAPTransactionDocument) = TYPE(Document.OBEntry)
	|					THEN DD.Counterparty = InvoicesIssuedInAdvance.Counterparty
	|				ELSE TRUE
	|			END)
	|
	|	LEFT JOIN
	|		CorrectedInvoicesIssuedInAdvance AS CorrectedInvoicesIssuedInAdvance
	|	ON
	|		DD.Organization = CorrectedInvoicesIssuedInAdvance.Organization
	|		AND TT_PaymentDocuments.OriginalARAPTransactionDocument = CorrectedInvoicesIssuedInAdvance.DocumentPayments
	|		AND (CASE
	|				WHEN VALUETYPE(TT_PaymentDocuments.OriginalARAPTransactionDocument) = TYPE(Document.OBEntry)
	|					THEN DD.Counterparty = CorrectedInvoicesIssuedInAdvance.Counterparty
	|				ELSE TRUE
	|			END)
	|WHERE
	|	DD.Period > ISNULL(CorrectedInvoicesIssuedInAdvance.Date, InvoicesIssuedInAdvance.Date)
	|	AND DD.ReversingEntry = TRUE
	|	
	|";
	
	Result = Query.ExecuteBatch();
	TransfersOfAdvances = Result[1].Unload();
	
	VATPrepaymentsFromCustomer = AccumulationRegisters.VATPrepaymentsFromCustomer.CreateRecordSet().UnloadColumns();
	VATPrepaymentsFromCustomer.Columns.Delete("Active");
	VATPrepaymentsFromCustomer.Columns.Add("Patch", New TypeDescription("Boolean"));
	VATPrepaymentsFromCustomer.Columns.Add("DateOfAdvancePayment", New TypeDescription("Date"));
	
	If TransfersOfAdvances.Count()>0 Then 
		
		AccrualsFromReceivedAdvance = Result[0].Unload(); // ValueTable -
		AccrualsFromReceivedAdvance.Indexes.Add("DocumentPayments, LineOfBusiness, ARAPObject, Patch, CorrectionDate");
		
		AccrualsFromAdvanceReceivedTotals = AccrualsFromReceivedAdvance.Copy(,"DocumentPayments, LineOfBusiness, ARAPObject, Patch, CorrectionDate"); // ValueTable -
		AccrualsFromAdvanceReceivedTotals.GroupBy("DocumentPayments, ARAPObject, LineOfBusiness, Patch, CorrectionDate");
		
		AdvancesOnPaymentDocuments = AdvancesReceivedOnPaymentDocuments(CalculationParameters); // ValueTable - 
		AdvancesToPaymentDocuments = AdvancesOnPaymentDocuments.Copy(,"DocumentPayments, Prepayment_, AdvanceMan");
		AdvancesToPaymentDocuments.GroupBy("DocumentPayments", "Prepayment_, AdvanceMan");
		AdvancesToPaymentDocuments.Indexes.Add("DocumentPayments");
		
		StagesOfOffset = New Array;
		StagesOfOffset.Add(New Structure("DocumentPayments, LineOfBusiness, ARAPObject"));
		StagesOfOffset.Add(New Structure("DocumentPayments, ARAPObject"));
		StagesOfOffset.Add(New Structure("DocumentPayments, LineOfBusiness"));
		StagesOfOffset.Add(New Structure("DocumentPayments"));
		
		For Each SelectionStructureOfSetOff In StagesOfOffset Do
			For Each String In AccrualsFromAdvanceReceivedTotals Do
				
				AdvanceLine_ = AdvancesToPaymentDocuments.Find(String.DocumentPayments);
				If AdvanceLine_ = Undefined Then
					Continue;
				EndIf;
				
				AdvanceSelectionStructure = New Structure();
				AdvanceSelectionStructure.Insert("DocumentPayments", String.DocumentPayments);
				AdvanceSelectionStructure.Insert("LineOfBusiness", String.LineOfBusiness);
				AdvanceSelectionStructure.Insert("ARAPObject", String.ARAPObject);
				AdvanceSelectionStructure.Insert("Patch", String.Patch);
				AdvanceSelectionStructure.Insert("CorrectionDate", String.CorrectionDate);
				LinesCalculatingVAT = AccrualsFromReceivedAdvance.FindRows(AdvanceSelectionStructure);
				
				FillPropertyValues(SelectionStructureOfSetOff, AdvanceSelectionStructure);
				AdvanceTransferLines = TransfersOfAdvances.FindRows(SelectionStructureOfSetOff);
				
				SetOffAdvanceReceived(CalculationParameters, AdvanceLine_, LinesCalculatingVAT, AdvanceTransferLines, VATPrepaymentsFromCustomer, "Receipt");
				
			EndDo;
		EndDo;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	VATPrepaymentsFromCustomer.Recorder AS Recorder,
	|	VATPrepaymentsFromCustomer.Period AS Period,
	|	VATPrepaymentsFromCustomer.Organization AS Organization,
	|	VATPrepaymentsFromCustomer.DocumentPayments AS DocumentPayments,
	|	VATPrepaymentsFromCustomer.Counterparty AS Counterparty,
	|	VATPrepaymentsFromCustomer.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|	VATPrepaymentsFromCustomer.Department AS Department,
	|	VATPrepaymentsFromCustomer.LineOfBusiness AS LineOfBusiness,
	|	VATPrepaymentsFromCustomer.VATRate AS VATRate,
	|	VATPrepaymentsFromCustomer.AmountExcludingVAT AS AmountExcludingVAT,
	|	VATPrepaymentsFromCustomer.VAT AS VAT,
	|	VATPrepaymentsFromCustomer.VATManag AS VATManag,
	|	VATPrepaymentsFromCustomer.Event AS Event,
	|	VATPrepaymentsFromCustomer.PrepaymentsSettlementDocument AS PrepaymentsSettlementDocument,
	|	VATPrepaymentsFromCustomer.PeriodEndTransaction AS PeriodEndTransaction,
	|	VATPrepaymentsFromCustomer.FinRecordID AS FinRecordID,
	|	VATPrepaymentsFromCustomer.ReversingEntry AS ReversingEntry,
	|	VATPrepaymentsFromCustomer.Patch AS Patch,
	|	VATPrepaymentsFromCustomer.DateOfAdvancePayment AS DateOfAdvancePayment,
	|	VATPrepaymentsFromCustomer.ARAPObject AS ARAPObject
	|INTO VATAdvancesReceivedTransfers
	|FROM
	|	&VATPrepaymentsFromCustomer AS VATPrepaymentsFromCustomer
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	2 AS Priority,
	|	VATPrepaymentsFromCustomer.Recorder AS Recorder,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	VATPrepaymentsFromCustomer.Period AS Period,
	|	VATPrepaymentsFromCustomer.Organization AS Organization,
	|	VATPrepaymentsFromCustomer.DocumentPayments AS DocumentPayments,
	|	VATPrepaymentsFromCustomer.Counterparty AS Counterparty,
	|	VATPrepaymentsFromCustomer.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|	VATPrepaymentsFromCustomer.Department AS Department,
	|	VATPrepaymentsFromCustomer.LineOfBusiness AS LineOfBusiness,
	|	VATPrepaymentsFromCustomer.VATRate AS VATRate,
	|	SUM(VATPrepaymentsFromCustomer.AmountExcludingVAT) AS AmountExcludingVAT,
	|	SUM(VATPrepaymentsFromCustomer.VAT) AS VAT,
	|	SUM(VATPrepaymentsFromCustomer.VATManag) AS VATManag,
	|	VATPrepaymentsFromCustomer.Event AS Event,
	|	VATPrepaymentsFromCustomer.PrepaymentsSettlementDocument AS PrepaymentsSettlementDocument,
	|	VATPrepaymentsFromCustomer.PeriodEndTransaction AS PeriodEndTransaction,
	|	VATPrepaymentsFromCustomer.FinRecordID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.SettlementOfPrepayment) AS BusinessTransactionSetting,
	|	VATPrepaymentsFromCustomer.ReversingEntry AS ReversingEntry,
	|	VATPrepaymentsFromCustomer.Patch AS Patch,
	|	VATPrepaymentsFromCustomer.DateOfAdvancePayment AS DateOfAdvancePayment,
	|	VATPrepaymentsFromCustomer.ARAPObject AS ARAPObject
	|INTO VATAdvancesReceivedTransfersReceipt
	|FROM
	|	VATAdvancesReceivedTransfers AS VATPrepaymentsFromCustomer
	|
	|GROUP BY
	|	VATPrepaymentsFromCustomer.Recorder,
	|	VATPrepaymentsFromCustomer.Period,
	|	VATPrepaymentsFromCustomer.Organization,
	|	VATPrepaymentsFromCustomer.DocumentPayments,
	|	VATPrepaymentsFromCustomer.Counterparty,
	|	VATPrepaymentsFromCustomer.CorrectedTaxInvoice,
	|	VATPrepaymentsFromCustomer.Department,
	|	VATPrepaymentsFromCustomer.LineOfBusiness,
	|	VATPrepaymentsFromCustomer.VATRate,
	|	VATPrepaymentsFromCustomer.Event,
	|	VATPrepaymentsFromCustomer.PrepaymentsSettlementDocument,
	|	VATPrepaymentsFromCustomer.PeriodEndTransaction,
	|	VATPrepaymentsFromCustomer.FinRecordID,
	|	VATPrepaymentsFromCustomer.ReversingEntry,
	|	VATPrepaymentsFromCustomer.Patch,
	|	VATPrepaymentsFromCustomer.DateOfAdvancePayment,
	|	VATPrepaymentsFromCustomer.ARAPObject
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP VATAdvancesReceivedTransfers
	|";
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.SetParameter("VATPrepaymentsFromCustomer", VATPrepaymentsFromCustomer);
	Query.Execute();
	
	Return "VATAdvancesReceivedTransfersReceipt";
	
EndFunction

Function CalculateVATAdvancesReceivedTransfersExpenses(CalculationParameters)
	
	Query = New Query;
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.Text = 
	"SELECT
	|	AccrualFromPrepaymentFromCustomer.Organization AS Organization,
	|	AccrualFromPrepaymentFromCustomer.DocumentPayments AS DocumentPayments,
	|	AccrualFromPrepaymentFromCustomer.Counterparty AS Counterparty,
	|	AccrualFromPrepaymentFromCustomer.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|	AccrualFromPrepaymentFromCustomer.Department           AS Department,
	|	AccrualFromPrepaymentFromCustomer.LineOfBusiness AS LineOfBusiness,
	|	AccrualFromPrepaymentFromCustomer.ARAPObject          AS ARAPObject,
	|	AccrualFromPrepaymentFromCustomer.VATRate               AS VATRate,
	|	SUM(AccrualFromPrepaymentFromCustomer.AmountExcludingVAT)      AS AmountExcludingVAT,
	|	SUM(AccrualFromPrepaymentFromCustomer.VAT)              AS VAT,
	|	SUM(AccrualFromPrepaymentFromCustomer.VATManag)           AS VATManag
	|INTO VATAccrualAdvancesReceived
	|FROM
	|	(SELECT
	|		DD.Organization              AS Organization,
	|		DD.DocumentPayments           AS DocumentPayments,
	|		DD.Counterparty               AS Counterparty,
	|		DD.CorrectedTaxInvoice  AS CorrectedTaxInvoice,
	|		DD.Department            AS Department,
	|		DD.LineOfBusiness  AS LineOfBusiness,
	|		DD.VATRate                AS VATRate,
	|		DD.ARAPObject           AS ARAPObject,
	|		DD.AmountExcludingVAT              AS AmountExcludingVAT,
	|		DD.VAT                      AS VAT,
	|		DD.VATManag                   AS VATManag
	|	FROM
	|		BalancesAdvancesReceivedBeforeTransfer AS DD
	|
	|	UNION ALL
	|
	|	SELECT
	|		DD.Organization             AS Organization,
	|		DD.DocumentPayments          AS DocumentPayments,
	|		DD.Counterparty              AS Counterparty,
	|		DD.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|		DD.Department           AS Department,
	|		DD.LineOfBusiness AS LineOfBusiness,
	|		DD.VATRate               AS VATRate,
	|		DD.ARAPObject          AS ARAPObject,
	|		DD.AmountExcludingVAT             AS AmountExcludingVAT,
	|		DD.VAT                     AS VAT,
	|		DD.VATManag                  AS VATManag
	|	FROM
	|		VATAdvancesReceivedTransfersReceipt AS DD
	|	) AS AccrualFromPrepaymentFromCustomer
	|
	|GROUP BY
	|	AccrualFromPrepaymentFromCustomer.Organization,
	|	AccrualFromPrepaymentFromCustomer.DocumentPayments,
	|	AccrualFromPrepaymentFromCustomer.Counterparty,
	|	AccrualFromPrepaymentFromCustomer.CorrectedTaxInvoice,
	|	AccrualFromPrepaymentFromCustomer.Department,
	|	AccrualFromPrepaymentFromCustomer.LineOfBusiness,
	|	AccrualFromPrepaymentFromCustomer.VATRate,
	|	AccrualFromPrepaymentFromCustomer.ARAPObject
	|
	|HAVING
	|	(SUM(AccrualFromPrepaymentFromCustomer.AmountExcludingVAT) <> 0
	|		OR SUM(AccrualFromPrepaymentFromCustomer.VAT) <> 0)
	|
	|INDEX BY
	|	Organization,
	|	DocumentPayments
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(CorrectedInvoicesIssuedInAdvance.Ref, InvoicesIssuedInAdvance.Ref) AS Ref,
	|	ISNULL(CorrectedInvoicesIssuedInAdvance.RuleOfPrepaymentFilter, InvoicesIssuedInAdvance.RuleOfPrepaymentFilter) AS RuleOfPrepaymentFilter,
	|	ISNULL(CorrectedInvoicesIssuedInAdvance.Date, InvoicesIssuedInAdvance.Date) AS Date,
	|	CASE
	|		WHEN NOT CorrectedInvoicesIssuedInAdvance.Ref IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                                                             AS Patch,
	|	ISNULL(CorrectedInvoicesIssuedInAdvance.CorrectionDate, DATETIME(1,1,1)) AS CorrectionDate,
	|	DD.Organization AS Organization,
	|	DD.DocumentPayments AS DocumentPayments,
	|	DD.Counterparty AS Counterparty,
	|	DD.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|	DD.Department AS Department,
	|	DD.LineOfBusiness AS LineOfBusiness,
	|	DD.ARAPObject AS ARAPObject,
	|	DD.VATRate AS VATRate,
	|	DD.AmountExcludingVAT AS AmountExcludingVAT,
	|	DD.VAT AS VAT,
	|	DD.VATManag AS VATManag
	|FROM
	|	VATAccrualAdvancesReceived AS DD
	|	LEFT JOIN
	|		InvoicesIssuedInAdvance AS InvoicesIssuedInAdvance
	|	ON
	|		DD.Organization = InvoicesIssuedInAdvance.Organization
	|		AND DD.DocumentPayments = InvoicesIssuedInAdvance.DocumentPayments
	|		AND (CASE
	|				WHEN VALUETYPE(DD.DocumentPayments) = TYPE(Document.OBEntry)
	|					THEN DD.Counterparty = InvoicesIssuedInAdvance.Counterparty
	|				ELSE TRUE
	|			END)
	|
	|	LEFT JOIN
	|		CorrectedInvoicesIssuedInAdvance AS CorrectedInvoicesIssuedInAdvance
	|	ON
	|		DD.Organization = CorrectedInvoicesIssuedInAdvance.Organization
	|		AND DD.DocumentPayments = CorrectedInvoicesIssuedInAdvance.DocumentPayments
	|		AND (CASE
	|				WHEN VALUETYPE(DD.DocumentPayments) = TYPE(Document.OBEntry)
	|					THEN DD.Counterparty = CorrectedInvoicesIssuedInAdvance.Counterparty
	|				ELSE TRUE
	|			END)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FALSE                                      AS ThereIsDataOnRevenue,
	|	1                                         AS EventSign,
	|	DD.Period                                 AS Period,
	|	DD.CorCounterparty                          AS Counterparty,
	|	DD.CorLineOfBusiness             AS LineOfBusiness,
	|	DD.DebitBusinessUnit                       AS Department,
	|	DD.FinRecordID                 AS FinRecordID,
	|	DD.CorARAPObject                      AS ARAPObject,
	|	TT_PaymentDocuments.OriginalARAPTransactionDocument AS DocumentPayments,
	|	DD.PrepaymentLocal                         AS OffsetAmount_,
	|	DD.PrepaymentMan                          AS ManSCreditAmount,
	|	DD.PrepaymentsSettlementDocument                   AS PrepaymentsSettlementDocument,
	|	DD.ReversingEntry                                 AS ReversingEntry
	|FROM
	|	SettlementsWithClients_TransfersOfAdvances AS DD
	|	INNER JOIN
	|		ExpansionOfARAPTransactionTable AS TT_PaymentDocuments
	|	ON
	|		DD.Organization = TT_PaymentDocuments.Organization
	|		AND DD.DocumentPayments = TT_PaymentDocuments.DocumentPayments
	|
	|	LEFT JOIN
	|		InvoicesIssuedInAdvance AS InvoicesIssuedInAdvance
	|	ON
	|		DD.Organization = InvoicesIssuedInAdvance.Organization
	|		AND TT_PaymentDocuments.OriginalARAPTransactionDocument = InvoicesIssuedInAdvance.DocumentPayments
	|		AND (CASE
	|				WHEN VALUETYPE(TT_PaymentDocuments.OriginalARAPTransactionDocument) = TYPE(Document.OBEntry)
	|					THEN DD.Counterparty = InvoicesIssuedInAdvance.Counterparty
	|				ELSE TRUE
	|			END)
	|
	|	LEFT JOIN
	|		CorrectedInvoicesIssuedInAdvance AS CorrectedInvoicesIssuedInAdvance
	|	ON
	|		DD.Organization = CorrectedInvoicesIssuedInAdvance.Organization
	|		AND TT_PaymentDocuments.OriginalARAPTransactionDocument = CorrectedInvoicesIssuedInAdvance.DocumentPayments
	|		AND (CASE
	|				WHEN VALUETYPE(TT_PaymentDocuments.OriginalARAPTransactionDocument) = TYPE(Document.OBEntry)
	|					THEN DD.Counterparty = CorrectedInvoicesIssuedInAdvance.Counterparty
	|				ELSE TRUE
	|			END)
	|WHERE
	|	DD.Period > ISNULL(CorrectedInvoicesIssuedInAdvance.Date, InvoicesIssuedInAdvance.Date)
	|	AND DD.ReversingEntry = FALSE
	|
	|UNION ALL
	|
	|SELECT
	|	FALSE                                     AS ThereIsDataOnRevenue,
	|	1                                         AS EventSign,
	|	DD.Period                                 AS Period,
	|	DD.Counterparty                             AS Counterparty,
	|	DD.LineOfBusiness                AS LineOfBusiness,
	|	DD.Department                          AS Department,
	|	DD.FinRecordID                 AS FinRecordID,
	|	DD.ARAPObject                         AS ARAPObject,
	|	TT_PaymentDocuments.OriginalARAPTransactionDocument AS DocumentPayments,
	|	-DD.PrepaymentLocal                        AS OffsetAmount_,
	|	-DD.PrepaymentMan                         AS ManSCreditAmount,
	|	DD.PrepaymentsSettlementDocument                   AS PrepaymentsSettlementDocument,
	|	FALSE                                      AS ReversingEntry
	|FROM
	|	SettlementsWithClients_TransfersOfAdvances AS DD
	|	INNER JOIN
	|		ExpansionOfARAPTransactionTable AS TT_PaymentDocuments
	|	ON
	|		DD.Organization = TT_PaymentDocuments.Organization
	|		AND DD.DocumentPayments = TT_PaymentDocuments.DocumentPayments
	|
	|	LEFT JOIN
	|		InvoicesIssuedInAdvance AS InvoicesIssuedInAdvance
	|	ON
	|		DD.Organization = InvoicesIssuedInAdvance.Organization
	|		AND TT_PaymentDocuments.OriginalARAPTransactionDocument = InvoicesIssuedInAdvance.DocumentPayments
	|		AND (CASE
	|				WHEN VALUETYPE(TT_PaymentDocuments.OriginalARAPTransactionDocument) = TYPE(Document.OBEntry)
	|					THEN DD.Counterparty = InvoicesIssuedInAdvance.Counterparty
	|				ELSE TRUE
	|			END)
	|
	|	LEFT JOIN
	|		CorrectedInvoicesIssuedInAdvance AS CorrectedInvoicesIssuedInAdvance
	|	ON
	|		DD.Organization = CorrectedInvoicesIssuedInAdvance.Organization
	|		AND TT_PaymentDocuments.OriginalARAPTransactionDocument = CorrectedInvoicesIssuedInAdvance.DocumentPayments
	|		AND (CASE
	|				WHEN VALUETYPE(TT_PaymentDocuments.OriginalARAPTransactionDocument) = TYPE(Document.OBEntry)
	|					THEN DD.Counterparty = CorrectedInvoicesIssuedInAdvance.Counterparty
	|				ELSE TRUE
	|			END)
	|WHERE
	|	DD.Period > ISNULL(CorrectedInvoicesIssuedInAdvance.Date, InvoicesIssuedInAdvance.Date)
	|	AND DD.ReversingEntry = TRUE
	|
	|;
	|
	|//////////////////////////////////////////////////////
	|DROP VATAccrualAdvancesReceived
	|";
	
	Result = Query.ExecuteBatch();
	TransfersOfAdvances = Result[2].Unload();
	
	VATPrepaymentsFromCustomer = AccumulationRegisters.VATPrepaymentsFromCustomer.CreateRecordSet().UnloadColumns();
	VATPrepaymentsFromCustomer.Columns.Delete("Active");
	VATPrepaymentsFromCustomer.Columns.Add("Patch", New TypeDescription("Boolean"));
	VATPrepaymentsFromCustomer.Columns.Add("DateOfAdvancePayment", New TypeDescription("Date"));
	
	If TransfersOfAdvances.Count()>0 Then 
		
		AccrualsFromReceivedAdvance = Result[1].Unload(); // ValueTable -
		AccrualsFromReceivedAdvance.Indexes.Add("DocumentPayments, LineOfBusiness, ARAPObject, Patch, CorrectionDate");
		
		AccrualsFromAdvanceReceivedTotals = AccrualsFromReceivedAdvance.Copy(,"DocumentPayments, LineOfBusiness, ARAPObject, Patch, CorrectionDate"); // ValueTable -
		AccrualsFromAdvanceReceivedTotals.GroupBy("DocumentPayments, ARAPObject, LineOfBusiness, Patch, CorrectionDate");
		
		AdvancesOnPaymentDocuments = AdvancesReceivedOnPaymentDocuments(CalculationParameters); // ValueTable - 
		AdvancesToPaymentDocuments = AdvancesOnPaymentDocuments.Copy(, "DocumentPayments, Prepayment_, AdvanceMan");
		AdvancesToPaymentDocuments.GroupBy("DocumentPayments", "Prepayment_, AdvanceMan");
		AdvancesToPaymentDocuments.Indexes.Add("DocumentPayments");
			
		StagesOfOffset = New Array;
		StagesOfOffset.Add(New Structure("DocumentPayments, LineOfBusiness, ARAPObject"));
		StagesOfOffset.Add(New Structure("DocumentPayments, ARAPObject"));
		StagesOfOffset.Add(New Structure("DocumentPayments, LineOfBusiness"));
		StagesOfOffset.Add(New Structure("DocumentPayments"));
		
		For Each SelectionStructureOfSetOff In StagesOfOffset Do
			For Each String In AccrualsFromAdvanceReceivedTotals Do
				
				AdvanceLine_ = AdvancesToPaymentDocuments.Find(String.DocumentPayments);
				If AdvanceLine_ = Undefined Then
					Continue;
				EndIf;
				
				AdvanceSelectionStructure = New Structure();
				AdvanceSelectionStructure.Insert("DocumentPayments", String.DocumentPayments);
				AdvanceSelectionStructure.Insert("LineOfBusiness", String.LineOfBusiness);
				AdvanceSelectionStructure.Insert("ARAPObject", String.ARAPObject);
				AdvanceSelectionStructure.Insert("Patch", String.Patch);
				AdvanceSelectionStructure.Insert("CorrectionDate", String.CorrectionDate);
				LinesCalculatingVAT = AccrualsFromReceivedAdvance.FindRows(AdvanceSelectionStructure);
				
				FillPropertyValues(SelectionStructureOfSetOff, AdvanceSelectionStructure);
				AdvanceTransferLines = TransfersOfAdvances.FindRows(SelectionStructureOfSetOff);
				
				SetOffAdvanceReceived(CalculationParameters, AdvanceLine_, LinesCalculatingVAT, AdvanceTransferLines, VATPrepaymentsFromCustomer, "Expense");
				
			EndDo;
		EndDo;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	VATPrepaymentsFromCustomer.Recorder AS Recorder,
	|	VATPrepaymentsFromCustomer.Period AS Period,
	|	VATPrepaymentsFromCustomer.Organization AS Organization,
	|	VATPrepaymentsFromCustomer.DocumentPayments AS DocumentPayments,
	|	VATPrepaymentsFromCustomer.Counterparty AS Counterparty,
	|	VATPrepaymentsFromCustomer.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|	VATPrepaymentsFromCustomer.Department AS Department,
	|	VATPrepaymentsFromCustomer.LineOfBusiness AS LineOfBusiness,
	|	VATPrepaymentsFromCustomer.VATRate AS VATRate,
	|	VATPrepaymentsFromCustomer.AmountExcludingVAT AS AmountExcludingVAT,
	|	VATPrepaymentsFromCustomer.VAT AS VAT,
	|	VATPrepaymentsFromCustomer.VATManag AS VATManag,
	|	VATPrepaymentsFromCustomer.Event AS Event,
	|	VATPrepaymentsFromCustomer.PrepaymentsSettlementDocument AS PrepaymentsSettlementDocument,
	|	VATPrepaymentsFromCustomer.PeriodEndTransaction AS PeriodEndTransaction,
	|	VATPrepaymentsFromCustomer.FinRecordID AS FinRecordID,
	|	VATPrepaymentsFromCustomer.ReversingEntry AS ReversingEntry,
	|	VATPrepaymentsFromCustomer.Patch AS Patch,
	|	VATPrepaymentsFromCustomer.DateOfAdvancePayment AS DateOfAdvancePayment,
	|	VATPrepaymentsFromCustomer.ARAPObject AS ARAPObject
	|INTO VATAdvancesReceivedTransfers
	|FROM
	|	&VATPrepaymentsFromCustomer AS VATPrepaymentsFromCustomer
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	2 AS Priority,
	|	VATPrepaymentsFromCustomer.Recorder AS Recorder,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	VATPrepaymentsFromCustomer.Period AS Period,
	|	VATPrepaymentsFromCustomer.Organization AS Organization,
	|	VATPrepaymentsFromCustomer.DocumentPayments AS DocumentPayments,
	|	VATPrepaymentsFromCustomer.Counterparty AS Counterparty,
	|	VATPrepaymentsFromCustomer.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|	VATPrepaymentsFromCustomer.Department AS Department,
	|	VATPrepaymentsFromCustomer.LineOfBusiness AS LineOfBusiness,
	|	VATPrepaymentsFromCustomer.VATRate AS VATRate,
	|	SUM(VATPrepaymentsFromCustomer.AmountExcludingVAT) AS AmountExcludingVAT,
	|	SUM(VATPrepaymentsFromCustomer.VAT) AS VAT,
	|	SUM(VATPrepaymentsFromCustomer.VATManag) AS VATManag,
	|	VATPrepaymentsFromCustomer.Event AS Event,
	|	VATPrepaymentsFromCustomer.PrepaymentsSettlementDocument AS PrepaymentsSettlementDocument,
	|	VATPrepaymentsFromCustomer.PeriodEndTransaction AS PeriodEndTransaction,
	|	VATPrepaymentsFromCustomer.FinRecordID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.SettlementOfPrepayment) AS BusinessTransactionSetting,
	|	VATPrepaymentsFromCustomer.ReversingEntry AS ReversingEntry,
	|	VATPrepaymentsFromCustomer.Patch AS Patch,
	|	VATPrepaymentsFromCustomer.DateOfAdvancePayment AS DateOfAdvancePayment,
	|	VATPrepaymentsFromCustomer.ARAPObject AS ARAPObject
	|INTO VATAdvancesReceivedTransfersExpense
	|FROM
	|	VATAdvancesReceivedTransfers AS VATPrepaymentsFromCustomer
	|
	|GROUP BY
	|	VATPrepaymentsFromCustomer.Recorder,
	|	VATPrepaymentsFromCustomer.Period,
	|	VATPrepaymentsFromCustomer.Organization,
	|	VATPrepaymentsFromCustomer.DocumentPayments,
	|	VATPrepaymentsFromCustomer.Counterparty,
	|	VATPrepaymentsFromCustomer.CorrectedTaxInvoice,
	|	VATPrepaymentsFromCustomer.Department,
	|	VATPrepaymentsFromCustomer.LineOfBusiness,
	|	VATPrepaymentsFromCustomer.VATRate,
	|	VATPrepaymentsFromCustomer.Event,
	|	VATPrepaymentsFromCustomer.PrepaymentsSettlementDocument,
	|	VATPrepaymentsFromCustomer.PeriodEndTransaction,
	|	VATPrepaymentsFromCustomer.FinRecordID,
	|	VATPrepaymentsFromCustomer.ReversingEntry,
	|	VATPrepaymentsFromCustomer.Patch,
	|	VATPrepaymentsFromCustomer.DateOfAdvancePayment,
	|	VATPrepaymentsFromCustomer.ARAPObject
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP VATAdvancesReceivedTransfers
	|";
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.SetParameter("VATPrepaymentsFromCustomer", VATPrepaymentsFromCustomer);
	Query.Execute();
	
	Return "VATAdvancesReceivedTransfersExpense";
	
EndFunction

Function CalculateVATAdvancesReceivedStorno(CalculationParameters)
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	DocumentsStorno.Ref AS Ref,
	|	DocumentsStorno.Period AS Period,
	|	DocumentsStorno.ReversedDocument AS ReversedDocument,
	|	VATPrepaymentsFromCustomer.Organization AS Organization,
	|	VATPrepaymentsFromCustomer.DocumentPayments AS DocumentPayments
	|INTO VATAdvancesReceivedSelectionStorno
	|FROM
	|	AccumulationRegister.VATPrepaymentsFromCustomer AS VATPrepaymentsFromCustomer
	|	INNER JOIN
	|		Jobs AS Jobs
	|	ON
	|		VATPrepaymentsFromCustomer.Organization = Jobs.Organization
	|		AND VATPrepaymentsFromCustomer.DocumentPayments = Jobs.TaxInvoice
	|	
	|	LEFT JOIN
	|		DocumentsStorno AS DocumentsStorno
	|	ON
	|		VATPrepaymentsFromCustomer.Recorder = DocumentsStorno.ReversedDocument
	|	
	|WHERE
	|	VATPrepaymentsFromCustomer.Period < &BeginOfPeriod 
	|	AND VATPrepaymentsFromCustomer.PeriodEndTransaction
	|	AND NOT VATPrepaymentsFromCustomer.ReversingEntry
	|	AND NOT DocumentsStorno.ReversedDocument IS NULL
	|
	|INDEX BY
	|	ReversedDocument
	|;
	|
	|//////////////////////////////////////////////
	|SELECT
	|	0 AS Priority,
	|	VATAdvancesReceivedSelectionStorno.Ref AS Recorder,
	|	VATAdvancesReceivedSelectionStorno.Period AS Period,
	|	VATPrepaymentsFromCustomer.RecordType AS RecordType,
	|	VATPrepaymentsFromCustomer.Organization AS Organization,
	|	VATPrepaymentsFromCustomer.DocumentPayments AS DocumentPayments,
	|	VATPrepaymentsFromCustomer.Counterparty AS Counterparty,
	|	VATPrepaymentsFromCustomer.ARAPObject AS ARAPObject,
	|	VATPrepaymentsFromCustomer.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|	VATPrepaymentsFromCustomer.Department AS Department,
	|	VATPrepaymentsFromCustomer.LineOfBusiness AS LineOfBusiness,
	|	VATPrepaymentsFromCustomer.VATRate  AS VATRate,
	|	-VATPrepaymentsFromCustomer.AmountExcludingVAT  AS AmountExcludingVAT,
	|	-VATPrepaymentsFromCustomer.VAT AS VAT,
	|	-VATPrepaymentsFromCustomer.VATManag AS VATManag,
	|	VATPrepaymentsFromCustomer.Event AS Event,
	|	VATPrepaymentsFromCustomer.PrepaymentsSettlementDocument AS PrepaymentsSettlementDocument,
	|	VATPrepaymentsFromCustomer.PeriodEndTransaction AS PeriodEndTransaction,
	|	VATPrepaymentsFromCustomer.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	VATPrepaymentsFromCustomer.FinRecordID AS FinRecordID,
	|	TRUE AS ReversingEntry
	|INTO VATAdvancesReceivedStorno
	|FROM
	|	VATAdvancesReceivedSelectionStorno AS VATAdvancesReceivedSelectionStorno
	|	INNER JOIN
	|		AccumulationRegister.VATPrepaymentsFromCustomer AS VATPrepaymentsFromCustomer
	|	ON
	|		VATPrepaymentsFromCustomer.Recorder = VATAdvancesReceivedSelectionStorno.ReversedDocument
	|		AND VATPrepaymentsFromCustomer.Organization = VATAdvancesReceivedSelectionStorno.Organization
	|		AND VATPrepaymentsFromCustomer.DocumentPayments = VATAdvancesReceivedSelectionStorno.DocumentPayments
	|
	|WHERE
	|	VATPrepaymentsFromCustomer.PeriodEndTransaction
	|	AND NOT VATPrepaymentsFromCustomer.ReversingEntry
	|	AND VATPrepaymentsFromCustomer.Period < &BeginOfPeriod
	|;
	|";
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.SetParameter("BeginOfPeriod", CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", CalculationParameters.EndOfPeriod);

	Query.Execute();
	
	Return "VATAdvancesReceivedStorno";
	
EndFunction

Function VATAccrualAdvancesReceived(CalculationParameters)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	AccrualFromPrepaymentFromCustomer.Organization AS Organization,
	|	AccrualFromPrepaymentFromCustomer.DocumentPayments AS DocumentPayments,
	|	AccrualFromPrepaymentFromCustomer.Counterparty AS Counterparty,
	|	AccrualFromPrepaymentFromCustomer.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|	AccrualFromPrepaymentFromCustomer.Department           AS Department,
	|	AccrualFromPrepaymentFromCustomer.LineOfBusiness AS LineOfBusiness,
	|	AccrualFromPrepaymentFromCustomer.ARAPObject          AS ARAPObject,
	|	AccrualFromPrepaymentFromCustomer.VATRate               AS VATRate,
	|	SUM(AccrualFromPrepaymentFromCustomer.AmountExcludingVAT)      AS AmountExcludingVAT,
	|	SUM(AccrualFromPrepaymentFromCustomer.VAT)              AS VAT,
	|	SUM(AccrualFromPrepaymentFromCustomer.VATManag)           AS VATManag
	|INTO VATAccrualAdvancesReceived
	|FROM
	|	(SELECT
	|		DD.Organization              AS Organization,
	|		DD.DocumentPayments           AS DocumentPayments,
	|		DD.Counterparty               AS Counterparty,
	|		DD.CorrectedTaxInvoice  AS CorrectedTaxInvoice,
	|		DD.Department            AS Department,
	|		DD.LineOfBusiness  AS LineOfBusiness,
	|		DD.VATRate                AS VATRate,
	|		DD.ARAPObject           AS ARAPObject,
	|		DD.AmountExcludingVAT              AS AmountExcludingVAT,
	|		DD.VAT                      AS VAT,
	|		DD.VATManag                   AS VATManag
	|	FROM
	|		BalancesAdvancesReceivedBeforeTransfer AS DD
	|
	|	UNION ALL
	|
	|	SELECT
	|		DD.Organization             AS Organization,
	|		DD.DocumentPayments          AS DocumentPayments,
	|		DD.Counterparty              AS Counterparty,
	|		DD.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|		DD.Department           AS Department,
	|		DD.LineOfBusiness AS LineOfBusiness,
	|		DD.VATRate               AS VATRate,
	|		DD.ARAPObject          AS ARAPObject,
	|		DD.AmountExcludingVAT             AS AmountExcludingVAT,
	|		DD.VAT                     AS VAT,
	|		DD.VATManag                  AS VATManag
	|	FROM
	|		VATAdvancesReceivedTransfersReceipt AS DD
	|
	|	UNION ALL
	|
	|	SELECT
	|		DD.Organization             AS Organization,
	|		DD.DocumentPayments          AS DocumentPayments,
	|		DD.Counterparty              AS Counterparty,
	|		DD.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|		DD.Department           AS Department,
	|		DD.LineOfBusiness AS LineOfBusiness,
	|		DD.VATRate               AS VATRate,
	|		DD.ARAPObject          AS ARAPObject,
	|		-DD.AmountExcludingVAT            AS AmountExcludingVAT,
	|		-DD.VAT                    AS VAT,
	|		-DD.VATManag                 AS VATManag
	|	FROM
	|		VATAdvancesReceivedTransfersExpense AS DD) AS AccrualFromPrepaymentFromCustomer
	|
	|GROUP BY
	|	AccrualFromPrepaymentFromCustomer.Organization,
	|	AccrualFromPrepaymentFromCustomer.DocumentPayments,
	|	AccrualFromPrepaymentFromCustomer.Counterparty,
	|	AccrualFromPrepaymentFromCustomer.CorrectedTaxInvoice,
	|	AccrualFromPrepaymentFromCustomer.Department,
	|	AccrualFromPrepaymentFromCustomer.LineOfBusiness,
	|	AccrualFromPrepaymentFromCustomer.VATRate,
	|	AccrualFromPrepaymentFromCustomer.ARAPObject
	|
	|HAVING
	|	(SUM(AccrualFromPrepaymentFromCustomer.AmountExcludingVAT) <> 0
	|		OR SUM(AccrualFromPrepaymentFromCustomer.VAT) <> 0)
	|
	|INDEX BY
	|	Organization,
	|	DocumentPayments,
	|	Counterparty
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(CorrectedInvoicesIssuedInAdvance.Ref, InvoicesIssuedInAdvance.Ref) AS Ref,
	|	ISNULL(CorrectedInvoicesIssuedInAdvance.RuleOfPrepaymentFilter, InvoicesIssuedInAdvance.RuleOfPrepaymentFilter) AS RuleOfPrepaymentFilter,
	|	ISNULL(CorrectedInvoicesIssuedInAdvance.Date, InvoicesIssuedInAdvance.Date) AS Date,
	|	CASE
	|		WHEN NOT CorrectedInvoicesIssuedInAdvance.Ref IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                                                             AS Patch,
	|	ISNULL(CorrectedInvoicesIssuedInAdvance.CorrectionDate, DATETIME(1,1,1)) AS CorrectionDate,
	|	VATAccrualAdvancesReceived.Organization             AS Organization,
	|	VATAccrualAdvancesReceived.DocumentPayments          AS DocumentPayments,
	|	VATAccrualAdvancesReceived.Counterparty              AS Counterparty,
	|	VATAccrualAdvancesReceived.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|	VATAccrualAdvancesReceived.Department           AS Department,
	|	VATAccrualAdvancesReceived.LineOfBusiness AS LineOfBusiness,
	|	VATAccrualAdvancesReceived.VATRate               AS VATRate,
	|	VATAccrualAdvancesReceived.ARAPObject          AS ARAPObject,
	|	VATAccrualAdvancesReceived.AmountExcludingVAT             AS AmountExcludingVAT,
	|	VATAccrualAdvancesReceived.VAT                     AS VAT,
	|	VATAccrualAdvancesReceived.VATManag                  AS VATManag
	|FROM
	|	VATAccrualAdvancesReceived AS VATAccrualAdvancesReceived
	|	LEFT JOIN
	|		InvoicesIssuedInAdvance AS InvoicesIssuedInAdvance
	|	ON
	|		VATAccrualAdvancesReceived.Organization = InvoicesIssuedInAdvance.Organization
	|		AND VATAccrualAdvancesReceived.DocumentPayments = InvoicesIssuedInAdvance.DocumentPayments
	|		AND (CASE
	|				WHEN VALUETYPE(VATAccrualAdvancesReceived.DocumentPayments) = TYPE(Document.OBEntry)
	|					THEN VATAccrualAdvancesReceived.Counterparty = InvoicesIssuedInAdvance.Counterparty
	|				ELSE TRUE
	|			END)
	|
	|	LEFT JOIN
	|		CorrectedInvoicesIssuedInAdvance AS CorrectedInvoicesIssuedInAdvance
	|	ON
	|		VATAccrualAdvancesReceived.Organization = CorrectedInvoicesIssuedInAdvance.Organization
	|		AND VATAccrualAdvancesReceived.DocumentPayments = CorrectedInvoicesIssuedInAdvance.DocumentPayments
	|		AND (CASE
	|				WHEN VALUETYPE(VATAccrualAdvancesReceived.DocumentPayments) = TYPE(Document.OBEntry)
	|					THEN VATAccrualAdvancesReceived.Counterparty = CorrectedInvoicesIssuedInAdvance.Counterparty
	|				ELSE TRUE
	|			END)
	|;
	|
	|//////////////////////////////////////////////////////
	|DROP VATAccrualAdvancesReceived
	|";
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.SetParameter("BeginOfPeriod", CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",  CalculationParameters.EndOfPeriod);
	
	Return Query.Execute().Unload();
	
EndFunction

Function CalculateVATAdvancesReceivedCredits(CalculationParameters)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Revenue.Recorder AS Recorder,
	|	SUM(Revenue.OwnRevenueWithVAT) AS OwnRevenueWithVAT,
	|	SUM(Revenue.OwnRevenueExcludingVAT) AS OwnRevenueExcludingVAT,
	|	SUM(Revenue.CommissionIncomeWithVAT) AS CommissionIncomeWithVAT,
	|	SUM(Revenue.CommissionRevenueExcludingVAT) AS CommissionRevenueExcludingVAT
	|INTO RevenueData_1
	|FROM
	|	(SELECT
	|		OffsetsOfAdvancesReceived.Recorder AS Recorder,
	|		CASE
	|			WHEN RevenueAndCOGS.InventoryType IN (&InventoryTypesOwn)
	|					AND NOT RevenueAndCOGS.VATTaxation IN (&TypesOfVATTaxationNonTaxable)
	|				THEN RevenueAndCOGS.RevenueAmountIncludingVATLocal
	|			ELSE 0
	|		END AS OwnRevenueWithVAT,
	|		CASE
	|			WHEN RevenueAndCOGS.InventoryType IN (&InventoryTypesOwn)
	|					AND RevenueAndCOGS.VATTaxation IN (&TypesOfVATTaxationNonTaxable)
	|				THEN RevenueAndCOGS.RevenueAmountIncludingVATLocal
	|			ELSE 0
	|		END AS OwnRevenueExcludingVAT,
	|		CASE
	|			WHEN NOT RevenueAndCOGS.InventoryType IN (&InventoryTypesOwn)
	|					AND NOT RevenueAndCOGS.VATTaxation IN (&TypesOfVATTaxationNonTaxable)
	|				THEN RevenueAndCOGS.RevenueAmountIncludingVATLocal
	|			ELSE 0
	|		END AS CommissionIncomeWithVAT,
	|		CASE
	|			WHEN NOT RevenueAndCOGS.InventoryType IN (&InventoryTypesOwn)
	|					AND RevenueAndCOGS.VATTaxation IN (&TypesOfVATTaxationNonTaxable)
	|				THEN RevenueAndCOGS.RevenueAmountIncludingVATLocal
	|			ELSE 0
	|		END AS CommissionRevenueExcludingVAT
	|	FROM
	|		OffsetsOfAdvancesReceived AS OffsetsOfAdvancesReceived
	|			INNER JOIN AccumulationRegister.RevenueAndCOGS AS RevenueAndCOGS
	|			ON OffsetsOfAdvancesReceived.Recorder = RevenueAndCOGS.Recorder
	|	WHERE
	|		OffsetsOfAdvancesReceived.ReversingEntry <> TRUE
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		OffsetsOfAdvancesReceived.Recorder,
	|		CASE
	|			WHEN NOT RevenueServicesAndAssets.VATTaxation IN (&TypesOfVATTaxationNonTaxable)
	|				THEN RevenueServicesAndAssets.RevenueExcludingVATLocal + RevenueServicesAndAssets.VATLocal
	|			ELSE 0
	|		END,
	|		CASE
	|			WHEN RevenueServicesAndAssets.VATTaxation IN (&TypesOfVATTaxationNonTaxable)
	|				THEN RevenueServicesAndAssets.RevenueExcludingVATLocal
	|			ELSE 0
	|		END,
	|		0,
	|		0
	|	FROM
	|		OffsetsOfAdvancesReceived AS OffsetsOfAdvancesReceived
	|			INNER JOIN AccumulationRegister.RevenueServicesAndAssets AS RevenueServicesAndAssets
	|			ON OffsetsOfAdvancesReceived.Recorder = RevenueServicesAndAssets.Recorder
	|	WHERE
	|		OffsetsOfAdvancesReceived.ReversingEntry <> TRUE) AS Revenue
	|
	|GROUP BY
	|	Revenue.Recorder
	|
	|HAVING
	|	(SUM(Revenue.OwnRevenueWithVAT) <> 0
	|		OR SUM(Revenue.OwnRevenueExcludingVAT) <> 0
	|		OR SUM(Revenue.CommissionIncomeWithVAT) <> 0
	|		OR SUM(Revenue.CommissionRevenueExcludingVAT) <> 0)
	|
	|INDEX BY
	|	Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OffsetsOfAdvancesReceived.Recorder AS Recorder,
	|	OffsetsOfAdvancesReceived.Period AS Period,
	|	OffsetsOfAdvancesReceived.Organization AS Organization,
	|	OffsetsOfAdvancesReceived.LineOfBusiness AS LineOfBusiness,
	|	OffsetsOfAdvancesReceived.Counterparty AS Counterparty,
	|	OffsetsOfAdvancesReceived.DocumentPayments AS DocumentPayments,
	|	OffsetsOfAdvancesReceived.PrepaymentsSettlementDocument AS PrepaymentsSettlementDocument,
	|	OffsetsOfAdvancesReceived.ARAPObject AS ARAPObject,
	|	OffsetsOfAdvancesReceived.EventSign AS EventSign,
	|	OffsetsOfAdvancesReceived.OffsetAmount_ AS OffsetAmount_,
	|	OffsetsOfAdvancesReceived.ReversingEntry AS ReversingEntry,
	|	CASE
	|		WHEN NOT RevenueData_1.Recorder IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThereIsDataOnRevenue,
	|	ISNULL(RevenueData_1.OwnRevenueWithVAT, 0) AS OwnRevenueWithVAT,
	|	ISNULL(RevenueData_1.OwnRevenueExcludingVAT, 0) AS OwnRevenueExcludingVAT,
	|	ISNULL(RevenueData_1.CommissionIncomeWithVAT, 0) AS CommissionIncomeWithVAT,
	|	ISNULL(RevenueData_1.CommissionRevenueExcludingVAT, 0) AS CommissionRevenueExcludingVAT
	|FROM
	|	OffsetsOfAdvancesReceived AS OffsetsOfAdvancesReceived
	|		LEFT JOIN RevenueData_1 AS RevenueData_1
	|		ON OffsetsOfAdvancesReceived.Recorder = RevenueData_1.Recorder
	|		LEFT JOIN DocumentsForOffsettingAdvancesReceivedStorno AS CreditDocumentsStorno
	|		ON OffsetsOfAdvancesReceived.DocumentPayments = CreditDocumentsStorno.DocumentPayments
	|			AND OffsetsOfAdvancesReceived.ARAPObject = CreditDocumentsStorno.ARAPObject
	|			AND OffsetsOfAdvancesReceived.PrepaymentsSettlementDocument = CreditDocumentsStorno.Document
	|			AND (BEGINOFPERIOD(OffsetsOfAdvancesReceived.Period, MONTH) = BEGINOFPERIOD(CreditDocumentsStorno.Period, MONTH))
	|WHERE
	|	OffsetsOfAdvancesReceived.ReversingEntry <> TRUE
	|	AND CreditDocumentsStorno.Document IS NULL
	|
	|ORDER BY
	|	Period";
	
	Query.SetParameter("BeginOfPeriod", CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",  CalculationParameters.EndOfPeriod);
	Query.SetParameter("TypesOfVATTaxationNonTaxable",  VATAccountingERP.TypesOfVATTaxationNonTaxable());
	Query.SetParameter("InventoryTypesOwn",              InventoryTypesOwn());
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	
	ApplyingPrepayments = Query.Execute().Unload(); // ValueTable - 
	ApplyingPrepayments.Indexes.Add("DocumentPayments,LineOfBusiness,ARAPObject");
	ApplyingPrepayments.Indexes.Add("DocumentPayments,LineOfBusiness");
	ApplyingPrepayments.Indexes.Add("DocumentPayments,ARAPObject");
	ApplyingPrepayments.Indexes.Add("DocumentPayments");
	
	VATPrepaymentsFromCustomer = AccumulationRegisters.VATPrepaymentsFromCustomer.CreateRecordSet().UnloadColumns();
	VATPrepaymentsFromCustomer.Columns.Delete("Active");
	VATPrepaymentsFromCustomer.Columns.Add("Patch", New TypeDescription("Boolean"));
	VATPrepaymentsFromCustomer.Columns.Add("DateOfAdvancePayment", New TypeDescription("Date"));
	
	If ApplyingPrepayments.Count()>0 Then
		
		TypesWithSelectionByCounterparty = New Array;
		TypesWithSelectionByCounterparty.Add(Type("DocumentRef.OBEntry"));
		
		AccrualsFromReceivedAdvance = VATAccrualAdvancesReceived(CalculationParameters); // ValueTable -
		AccrualsFromReceivedAdvance.Indexes.Add("DocumentPayments, LineOfBusiness, ARAPObject, Patch, CorrectionDate");
		
		AccrualsFromAdvanceReceivedTotals = AccrualsFromReceivedAdvance.Copy(,"DocumentPayments, Counterparty, LineOfBusiness, ARAPObject, Patch, CorrectionDate"); // ValueTable -
		
		AdvancesOnPaymentDocuments = AdvancesReceivedOnPaymentDocuments(CalculationParameters); // ValueTable - 
		AdvancesToPaymentDocuments = AdvancesOnPaymentDocuments.Copy(,"DocumentPayments, Counterparty, Prepayment_, AdvanceMan");
		AdvancesToPaymentDocuments.GroupBy("DocumentPayments, Counterparty", "Prepayment_, AdvanceMan");
		AdvancesToPaymentDocuments.Indexes.Add("DocumentPayments, Counterparty");
		AdvancesToPaymentDocuments.Indexes.Add("DocumentPayments");
		
		StagesOfOffset = New Array;
		StagesOfOffset.Add(New Structure("DocumentPayments, LineOfBusiness, ARAPObject"));
		StagesOfOffset.Add(New Structure("DocumentPayments, ARAPObject"));
		StagesOfOffset.Add(New Structure("DocumentPayments, LineOfBusiness"));
		StagesOfOffset.Add(New Structure("DocumentPayments"));
		
		For Each SelectionStructureOfSetOff In StagesOfOffset Do
			For Each String In AccrualsFromAdvanceReceivedTotals Do
				
				SelectionByCounterparty = TypesWithSelectionByCounterparty.Find(TypeOf(String.DocumentPayments)) <> Undefined;
				
				AdvanceSelectionStructure = New Structure();
				AdvanceSelectionStructure.Insert("DocumentPayments", String.DocumentPayments);
				If SelectionByCounterparty Then
					AdvanceSelectionStructure.Insert("Counterparty", String.Counterparty);
				EndIf;
				AdvancePaymentLines = AdvancesToPaymentDocuments.FindRows(AdvanceSelectionStructure);
				If AdvancePaymentLines.Count() = 0 Then
					Continue;
				Else
					AdvanceLine_ = AdvancePaymentLines[0];
				EndIf;
				
				AdvanceSelectionStructure = New Structure();
				AdvanceSelectionStructure.Insert("DocumentPayments", String.DocumentPayments);
				AdvanceSelectionStructure.Insert("LineOfBusiness", String.LineOfBusiness);
				AdvanceSelectionStructure.Insert("ARAPObject", String.ARAPObject);
				AdvanceSelectionStructure.Insert("Patch", String.Patch);
				AdvanceSelectionStructure.Insert("CorrectionDate", String.CorrectionDate);
				If SelectionByCounterparty Then
					AdvanceSelectionStructure.Insert("Counterparty", String.Counterparty);
					SelectionStructureOfSetOff.Insert("Counterparty");
				EndIf;

				LinesCalculatingVAT = AccrualsFromReceivedAdvance.FindRows(AdvanceSelectionStructure);
				
				FillPropertyValues(SelectionStructureOfSetOff, AdvanceSelectionStructure);
				LinesOffsettingAdvance = ApplyingPrepayments.FindRows(SelectionStructureOfSetOff);
				
				SetOffAdvanceReceived(CalculationParameters, AdvanceLine_, LinesCalculatingVAT, LinesOffsettingAdvance, VATPrepaymentsFromCustomer, "Credit_");
				
			EndDo;
		EndDo;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	2                                           AS Priority,
	|	VATPrepaymentsFromCustomer.Recorder             AS Recorder,
	|	VALUE(AccumulationRecordType.Expense)      AS RecordType,
	|	VATPrepaymentsFromCustomer.Period                  AS Period,
	|	VATPrepaymentsFromCustomer.Organization             AS Organization,
	|	VATPrepaymentsFromCustomer.DocumentPayments          AS DocumentPayments,
	|	VATPrepaymentsFromCustomer.Counterparty              AS Counterparty,
	|	VATPrepaymentsFromCustomer.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|	VATPrepaymentsFromCustomer.Department           AS Department,
	|	VATPrepaymentsFromCustomer.LineOfBusiness AS LineOfBusiness,
	|	VATPrepaymentsFromCustomer.VATRate               AS VATRate,
	|	VATPrepaymentsFromCustomer.AmountExcludingVAT             AS AmountExcludingVAT,
	|	VATPrepaymentsFromCustomer.VAT                     AS VAT,
	|	VATPrepaymentsFromCustomer.VATManag                  AS VATManag,
	|	VATPrepaymentsFromCustomer.Event                 AS Event,
	|	VATPrepaymentsFromCustomer.PrepaymentsSettlementDocument    AS PrepaymentsSettlementDocument,
	|	VATPrepaymentsFromCustomer.PeriodEndTransaction    AS PeriodEndTransaction,
	|	VATPrepaymentsFromCustomer.FinRecordID  AS FinRecordID,
	|	VATPrepaymentsFromCustomer.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	VATPrepaymentsFromCustomer.ReversingEntry                  AS ReversingEntry,
	|	VATPrepaymentsFromCustomer.Patch             AS Patch,
	|	VATPrepaymentsFromCustomer.DateOfAdvancePayment        AS DateOfAdvancePayment,
	|	VATPrepaymentsFromCustomer.ARAPObject          AS ARAPObject
	|INTO VATAdvancesReceivedCredits
	|FROM
	|	&VATPrepaymentsFromCustomer AS VATPrepaymentsFromCustomer
	|";
	
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.SetParameter("VATPrepaymentsFromCustomer", VATPrepaymentsFromCustomer);
	Query.Execute();
	
	Return "VATAdvancesReceivedCredits";
	
EndFunction

Procedure SetOffAdvanceReceived(CalculationParameters, AdvancePaymentLineForPaymentDocument, AdvancePaymentLinesVATAccrual, AdvanceCreditLines, TableVATAdvancesReceived, AllocationOption)
	
	If AdvancePaymentLinesVATAccrual.Count() = 0 Then
		Return;
	EndIf;

	AdvancePaymentAmountWithoutVAT = New Array();
	AdvancePaymentVATAmount = New Array();
	AdvancePaymentAmountOfVATMan = New Array();
	
	AdvancePaymentAmountWithoutVAT_0    = 0;
	AdvanceAmountWithVAT      = 0;
	
	RuleOfPrepaymentFilter = AdvancePaymentLinesVATAccrual[0].RuleOfPrepaymentFilter;
	AccrualDate = AdvancePaymentLinesVATAccrual[0].Date;
	Patch = AdvancePaymentLinesVATAccrual[0].Patch;
	CorrectionDate = AdvancePaymentLinesVATAccrual[0].CorrectionDate;
	
	For Each AdvanceLine_ In AdvancePaymentLinesVATAccrual Do
		AdvancePaymentAmountWithoutVAT.Add(AdvanceLine_.AmountExcludingVAT);
		AdvancePaymentVATAmount.Add(AdvanceLine_.VAT);
		AdvancePaymentAmountOfVATMan.Add(AdvanceLine_.VATManag);
		
		AdvancePaymentAmountWithoutVAT_0    = AdvancePaymentAmountWithoutVAT_0 + AdvanceLine_.AmountExcludingVAT;
		AdvanceAmountWithVAT      = AdvanceAmountWithVAT + AdvanceLine_.AmountExcludingVAT + AdvanceLine_.VAT;
	EndDo; 
	
	OutstandingAdvanceAmount = AdvancePaymentLineForPaymentDocument.Prepayment_;
	
	For Each RepaidAdvanceOnSF In AdvanceCreditLines Do
		
		If AdvanceAmountWithVAT = 0 Then
			Break;
		EndIf;
		
		If RepaidAdvanceOnSF.OffsetAmount_ = 0 Then
			Continue;
		EndIf;
		
		If AllocationOption = "Credit_" Then
			OutstandingAdvanceAmount = OutstandingAdvanceAmount - RepaidAdvanceOnSF.OffsetAmount_;
		EndIf;
		
		//Selection of extra advance credits
		DateOfAdvancePayment = RepaidAdvanceOnSF.Period;
		
		If Not Patch And DateOfAdvancePayment < CalculationParameters.BeginOfPeriod Then
			Continue;
		EndIf;
		
		If Patch 
			 And DateOfAdvancePayment < CalculationParameters.BeginOfPeriod
			 And CorrectionDate < CalculationParameters.BeginOfPeriod Then
			Continue;
		EndIf;
		
		If RuleOfPrepaymentFilter <> Enums.ProcedureOfRegisteringTaxInvoicesForPrepayment.AllPayments 
			 And EndOfDay(DateOfAdvancePayment) < BegOfDay(AccrualDate) Then
			Continue;
		EndIf;
		
		If RuleOfPrepaymentFilter <> Enums.ProcedureOfRegisteringTaxInvoicesForPrepayment.AllPayments
			 And BegOfDay(DateOfAdvancePayment) = BegOfDay(AccrualDate) Then
			// When the advance and the offset of the advance have passed on the same day, the offset of the advance is not needed, it has already been taken into account in the SF for the advance.
			Continue;
		EndIf;
		
		AmountOfCreditOther = 0;
		If RepaidAdvanceOnSF.ThereIsDataOnRevenue Then
			
			// We will determine by proportion the amount of offset that relates to the sale of our own goods with VAT.
			Coefficients = New Array;
			Coefficients.Add(RepaidAdvanceOnSF.OwnRevenueWithVAT);
			Coefficients.Add(RepaidAdvanceOnSF.OwnRevenueExcludingVAT);
			Coefficients.Add(RepaidAdvanceOnSF.CommissionIncomeWithVAT);
			Coefficients.Add(RepaidAdvanceOnSF.CommissionRevenueExcludingVAT);
			
			DistributionOfSetOffAmount = Common.DistributeAmountInProportionToCoefficients(
											RepaidAdvanceOnSF.OffsetAmount_,
											Coefficients);
			OffsetAmount_ = ?(RepaidAdvanceOnSF.OffsetAmount_ > 0, DistributionOfSetOffAmount[0], 0);
			AmountOfCreditOther = RepaidAdvanceOnSF.OffsetAmount_ - OffsetAmount_;
		Else
			OffsetAmount_ = RepaidAdvanceOnSF.OffsetAmount_;
		EndIf;
		
		AmountIncludingVAT = Min(OffsetAmount_, AdvanceAmountWithVAT);
		If AllocationOption = "Credit_" Then
			BalanceOfAdvanceAmountWithVAT = (AdvanceAmountWithVAT - AmountIncludingVAT);
			If BalanceOfAdvanceAmountWithVAT > OutstandingAdvanceAmount Then
				AdjustmentSum = Max(0, BalanceOfAdvanceAmountWithVAT - OutstandingAdvanceAmount - AmountOfCreditOther);
					// We will adjust the amount from which the recovery is performed, taking into account the remainder of the outstanding advance.
				AmountIncludingVAT = AmountIncludingVAT + AdjustmentSum;
			EndIf;
		EndIf;
		
		If AmountIncludingVAT = 0 Then
			Continue;
		EndIf;
		
		AmountExcludingVAT    = Round(AdvancePaymentAmountWithoutVAT_0 * AmountIncludingVAT / AdvanceAmountWithVAT, 2);
		VATAmount       = AmountIncludingVAT - AmountExcludingVAT; 
		
		If AllocationOption = "Credit_" Then
			AdvancePaymentAmountWithoutVAT_0 = AdvancePaymentAmountWithoutVAT_0 - AmountExcludingVAT;
			AdvanceAmountWithVAT   = AdvanceAmountWithVAT - AmountIncludingVAT;
		EndIf;
		
		SignMultiplier = ?(RepaidAdvanceOnSF.ReversingEntry, -1, 1);
		
		If SignMultiplier * AmountExcludingVAT > 0 Then
			TotalAmountWithoutVAT = TMCommonUseClientServer.DistributeProportionally(AmountExcludingVAT, AdvancePaymentAmountWithoutVAT);
		EndIf;
		
		If SignMultiplier * VATAmount > 0 Then
			ArrayVATAmount = TMCommonUseClientServer.DistributeProportionally(VATAmount, AdvancePaymentVATAmount);
		EndIf; 
		
		Counter = -1;
		
		ResultString1Max = Undefined; // The maximum amount of the advance credit
		For Each AdvanceLine_ In AdvancePaymentLinesVATAccrual Do
			
			Counter = Counter + 1;
			
			Result_AmountWithoutVAT = ?(SignMultiplier * AmountExcludingVAT > 0, TotalAmountWithoutVAT[Counter], 0);
			_ndsResult = ?(SignMultiplier * VATAmount > 0, ArrayVATAmount[Counter], 0);
			
			If Result_AmountWithoutVAT = 0 
				 And _ndsResult = 0 Then
				Continue;
			EndIf;
			
			ResultString1 = TableVATAdvancesReceived.Add();
			
			FillPropertyValues(ResultString1, AdvanceLine_, StrConcat(CalculationParameters.ArrayOfRegisterMeasurements, ","));

			ResultString1.Recorder = AdvanceLine_.Ref;
			ResultString1.PrepaymentsSettlementDocument = RepaidAdvanceOnSF.PrepaymentsSettlementDocument;
			ResultString1.PeriodEndTransaction = True;
			ResultString1.BusinessTransactionSetting = Catalogs.BusinessTransactionsSettings.VATDeductionFromPrepaymentFromCustomer;
 			ResultString1.Patch = Patch;
			ResultString1.DateOfAdvancePayment = DateOfAdvancePayment;
			ResultString1.ReversingEntry = RepaidAdvanceOnSF.ReversingEntry;
			
			If Patch Then
				ResultString1.Period = Max(CorrectionDate, Max(DateOfAdvancePayment, CalculationParameters.BeginOfPeriod));
			Else
				ResultString1.Period = Max(AccrualDate, Max(DateOfAdvancePayment, CalculationParameters.BeginOfPeriod));
			EndIf;
			
			If AllocationOption <> "Credit_" Then
				If AllocationOption = "Receipt" Then
					ResultString1.LineOfBusiness = RepaidAdvanceOnSF.LineOfBusiness;
					ResultString1.Department = RepaidAdvanceOnSF.Department;
					ResultString1.ARAPObject = RepaidAdvanceOnSF.ARAPObject;
					ResultString1.Counterparty = RepaidAdvanceOnSF.Counterparty; 
				Else
					ResultString1.LineOfBusiness = AdvanceLine_.LineOfBusiness;
					ResultString1.Department = AdvanceLine_.Department;
					ResultString1.ARAPObject = AdvanceLine_.ARAPObject;
					ResultString1.Counterparty = AdvanceLine_.Counterparty; 
				EndIf;
			EndIf;
			
			If AllocationOption <> "Credit_" Then
				ResultString1.FinRecordID = RepaidAdvanceOnSF.FinRecordID;
			Else
				ResultString1.FinRecordID = String(New UUID());
			EndIf;
			
			ResultString1.AmountExcludingVAT = Result_AmountWithoutVAT;
			ResultString1.VAT = _ndsResult;
			// We will set off VAT upr. in proportion to VAT regl.
			If ResultString1.VAT <> 0 
					And (AdvanceLine_.VATManag <> 0 Or AllocationOption <> "Credit_") Then
					
				If AllocationOption <> "Credit_" And RepaidAdvanceOnSF.OffsetAmount_<>0 Then
					ResultString1.VATManag = RepaidAdvanceOnSF.ManSCreditAmount * ResultString1.VAT/RepaidAdvanceOnSF.OffsetAmount_;
					AmountExcludingVATMan = RepaidAdvanceOnSF.ManSCreditAmount * ResultString1.AmountExcludingVAT/RepaidAdvanceOnSF.OffsetAmount_;
					RepaidAdvanceOnSF.ManSCreditAmount = RepaidAdvanceOnSF.ManSCreditAmount - (AmountExcludingVATMan + ResultString1.VATManag);
				Else
					CoefficientsOfDistributionOfVATMan = New Array;
					CoefficientsOfDistributionOfVATMan.Add(ResultString1.VAT);
					CoefficientsOfDistributionOfVATMan.Add(AdvanceLine_.VAT - ResultString1.VAT);
					ArrayOfVATMan = TMCommonUseClientServer.DistributeProportionally(AdvanceLine_.VATManag, CoefficientsOfDistributionOfVATMan);
					ResultString1.VATManag = ArrayOfVATMan[0];
				EndIf;
			EndIf;
			
			TypesOfOperationsOfAdvanceTransfer = New Array;
			TypesOfOperationsOfAdvanceTransfer.Add(Enums.KindsOfARAPSettlements.CustomerPrepaymentOffsetBetweenTwoCompanies);
			TypesOfOperationsOfAdvanceTransfer.Add(Enums.KindsOfARAPSettlements.PrepaymentToVendorOffsetBetweenTwoCompanies);
			
			If TypeOf(RepaidAdvanceOnSF.PrepaymentsSettlementDocument) = Type("DocumentRef.ARAPSettlement")
				And TypesOfOperationsOfAdvanceTransfer.Find(Common.ObjectAttributeValue(RepaidAdvanceOnSF.PrepaymentsSettlementDocument, "OperationKind")) <> Undefined Then
				ResultString1.Event = Enums.EventsVATFromPrepayments.SettlementOfPrepayment;
			ElsIf TypeOf(RepaidAdvanceOnSF.PrepaymentsSettlementDocument) = Type("DocumentRef.ARAPSettlement")
				And Common.ObjectAttributeValue(RepaidAdvanceOnSF.PrepaymentsSettlementDocument, "OperationKind") = Enums.KindsOfARAPSettlements.ARAPClearingBetweenCompanies Then
				ResultString1.Event = Enums.EventsVATFromPrepayments.DeductionOnPrepaymentSettlement;
			ElsIf TypeOf(RepaidAdvanceOnSF.PrepaymentsSettlementDocument) = Type("DocumentRef.ReversingEntry") Then
				 ResultString1.Event = Enums.EventsVATFromPrepayments.DeductionOnPrepaymentSettlement;
			ElsIf RepaidAdvanceOnSF.EventSign < 0 Then
				ResultString1.Event = Enums.EventsVATFromPrepayments.DeductionOnPrepapaymentReturn;
			Else
				ResultString1.Event = Enums.EventsVATFromPrepayments.DeductionOnPrepaymentSettlement;
			EndIf;
			
			If ResultString1Max = Undefined
				Or ResultString1.AmountExcludingVAT >= ResultString1Max.AmountExcludingVAT Then
				ResultString1Max = ResultString1;
			EndIf;
			
			// We will reduce the amounts in the initial lines of the advance and the offset of the advance by the credited amount.
			AdvanceLine_.AmountExcludingVAT = AdvanceLine_.AmountExcludingVAT - ResultString1.AmountExcludingVAT;
			AdvanceLine_.VAT = AdvanceLine_.VAT - ResultString1.VAT;
			AdvanceLine_.VATManag = AdvanceLine_.VATManag - ResultString1.VATManag;
			
			RepaidAdvanceOnSF.OffsetAmount_ = RepaidAdvanceOnSF.OffsetAmount_ - (ResultString1.AmountExcludingVAT + ResultString1.VAT); 
			AdvancePaymentLineForPaymentDocument.Prepayment_ = AdvancePaymentLineForPaymentDocument.Prepayment_ - (ResultString1.AmountExcludingVAT + ResultString1.VAT);
			
			If AdvancePaymentLineForPaymentDocument.Prepayment_ = 0 Then
				ResultString1Max.AmountExcludingVAT = ResultString1Max.AmountExcludingVAT + AdvanceLine_.AmountExcludingVAT;
				ResultString1Max.VAT = ResultString1Max.VAT + AdvanceLine_.VAT;
				ResultString1Max.VATManag = ResultString1Max.VATManag + AdvanceLine_.VATManag;
			EndIf;
			
		EndDo;
	EndDo;
	
EndProcedure

Function CalculateVATRecordsAdvancesReceivedSaving(CalculationParameters, TableNamesOfVATRecordAdvancesReceived)
	
	ArrayOfTextsLoggersRecord = New Array;
	ArrayOfTextsLoggersRecord.Add("
	|SELECT DISTINCT
	|	UNDEFINED AS Recorder
	|INTO LoggersRecord
	|WHERE
	|	FALSE");
	
	QueryTemplate = 
	"SELECT DISTINCT
	|	VATPrepaymentsFromCustomer.Recorder
	|FROM
	|	&VATPrepaymentsFromCustomer AS VATPrepaymentsFromCustomer";
	For Each NameOfRecordTable In TableNamesOfVATRecordAdvancesReceived Do
		QueryText = StrReplace(QueryTemplate, "&VATPrepaymentsFromCustomer", NameOfRecordTable);
		ArrayOfTextsLoggersRecord.Add(QueryText);
	EndDo;
	
	ArrayOfTextsLoggersRecord.Add("
	|SELECT DISTINCT
	|	VATPrepaymentsFromCustomer.Recorder
	|FROM
	|	CurRegistrarsVATAdvancesReceived AS VATPrepaymentsFromCustomer");
	
	TextLoggersRecord = StrConcat(ArrayOfTextsLoggersRecord, TMCommonUse.QuerySeparatorInJoin(True));
	TextLoggersRecord = TextLoggersRecord +
	"
	|INDEX BY
	|	Recorder";
	
	QueryTextSave =
	"SELECT
	|	0                                                   AS Priority,
	|	VATPrepaymentsFromCustomer.Period                          AS Period,
	|	VATPrepaymentsFromCustomer.Recorder                     AS Recorder,
	|	VATPrepaymentsFromCustomer.RecordType                     AS RecordType,
	|	VATPrepaymentsFromCustomer.Organization                     AS Organization,
	|	VATPrepaymentsFromCustomer.DocumentPayments                  AS DocumentPayments,
	|	VATPrepaymentsFromCustomer.Counterparty                      AS Counterparty,
	|	VATPrepaymentsFromCustomer.CorrectedTaxInvoice         AS CorrectedTaxInvoice,
	|	VATPrepaymentsFromCustomer.Department                   AS Department,
	|	VATPrepaymentsFromCustomer.LineOfBusiness         AS LineOfBusiness,
	|	VATPrepaymentsFromCustomer.VATRate                       AS VATRate,
	|	VATPrepaymentsFromCustomer.ARAPObject                  AS ARAPObject,
	|	VATPrepaymentsFromCustomer.AmountExcludingVAT                     AS AmountExcludingVAT,
	|	VATPrepaymentsFromCustomer.VAT                             AS VAT,
	|	VATPrepaymentsFromCustomer.VATManag                          AS VATManag,
	|	VATPrepaymentsFromCustomer.Event                         AS Event,
	|	VATPrepaymentsFromCustomer.PrepaymentsSettlementDocument            AS PrepaymentsSettlementDocument,
	|	VATPrepaymentsFromCustomer.PeriodEndTransaction            AS PeriodEndTransaction,
	|	VATPrepaymentsFromCustomer.FinRecordID          AS FinRecordID,
	|	VATPrepaymentsFromCustomer.BusinessTransactionSetting  AS BusinessTransactionSetting,
	|	VATPrepaymentsFromCustomer.ReversingEntry                          AS ReversingEntry
	|INTO VATAdvancesReceivedSaving
	|FROM
	|	AccumulationRegister.VATPrepaymentsFromCustomer AS VATPrepaymentsFromCustomer
	|	
	|	INNER JOIN
	|		LoggersRecord AS LoggersRecord
	|	ON 
	|		VATPrepaymentsFromCustomer.Recorder = LoggersRecord.Recorder
	|	
	|	LEFT JOIN
	|		Jobs AS Jobs
	|	ON
	|		Jobs.Organization = VATPrepaymentsFromCustomer.Organization
	|		AND Jobs.TaxInvoice = VATPrepaymentsFromCustomer.DocumentPayments
	|WHERE
	|	VATPrepaymentsFromCustomer.Period < &BeginOfPeriod
	|		OR VATPrepaymentsFromCustomer.Period > &EndOfPeriod
	|		OR NOT VATPrepaymentsFromCustomer.PeriodEndTransaction
	|		OR Jobs.TaxInvoice IS NULL
	|;
	|
	|/////////////////////////////////////////////
	|DROP LoggersRecord
	|";

	Query = New Query;
	Query.Text = TextLoggersRecord + Common.QueryBatchSeparator() + QueryTextSave;
	Query.SetParameter("BeginOfPeriod",     CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",      CalculationParameters.EndOfPeriod);
	Query.SetParameter("CompanyArray", CalculationParameters.CompanyArray);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	
	Query.Execute();
	
	Return "VATAdvancesReceivedSaving";
	
EndFunction

Procedure GetCurRegistrarsVATAdvancesReceived(CalculationParameters) 
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	VATPrepaymentsFromCustomer.Recorder AS Recorder,
	|	VATPrepaymentsFromCustomer.Organization AS Organization,
	|	VATPrepaymentsFromCustomer.Period      AS Period
	|INTO CurRegistrarsVATAdvancesReceived
	|FROM
	|	AccumulationRegister.VATPrepaymentsFromCustomer AS VATPrepaymentsFromCustomer
	|		INNER JOIN Jobs AS Jobs
	|		ON (Jobs.Organization = VATPrepaymentsFromCustomer.Organization)
	|			AND (Jobs.TaxInvoice = VATPrepaymentsFromCustomer.DocumentPayments)
	|WHERE
	|	VATPrepaymentsFromCustomer.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND VATPrepaymentsFromCustomer.PeriodEndTransaction
	|
	|INDEX BY
	|	Recorder
	|";
	
	Query.SetParameter("BeginOfPeriod",     CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",  CalculationParameters.EndOfPeriod);
	Query.SetParameter("CompanyArray", CalculationParameters.CompanyArray);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.Execute();
	
EndProcedure

Procedure RecordVATAdvancesReceived(CalculationParameters, TableNamesOfVATRecordAdvancesReceived)
	
	ArrayOfDataTexts = New Array;
	QueryTemplate = 
	"SELECT
	|	VATPrepaymentsFromCustomer.Priority                       AS Priority,
	|	VATPrepaymentsFromCustomer.Period                          AS Period,
	|	VATPrepaymentsFromCustomer.Recorder                     AS Recorder,
	|	VATPrepaymentsFromCustomer.RecordType                     AS RecordType,
	|	VATPrepaymentsFromCustomer.Organization                     AS Organization,
	|	VATPrepaymentsFromCustomer.DocumentPayments                  AS DocumentPayments,
	|	VATPrepaymentsFromCustomer.Counterparty                      AS Counterparty,
	|	VATPrepaymentsFromCustomer.CorrectedTaxInvoice         AS CorrectedTaxInvoice,
	|	VATPrepaymentsFromCustomer.Department                   AS Department,
	|	VATPrepaymentsFromCustomer.LineOfBusiness         AS LineOfBusiness,
	|	VATPrepaymentsFromCustomer.VATRate                       AS VATRate,
	|	VATPrepaymentsFromCustomer.ARAPObject                  AS ARAPObject,
	|	VATPrepaymentsFromCustomer.AmountExcludingVAT                     AS AmountExcludingVAT,
	|	VATPrepaymentsFromCustomer.VAT                             AS VAT,
	|	VATPrepaymentsFromCustomer.VATManag                          AS VATManag,
	|	VATPrepaymentsFromCustomer.Event                         AS Event,
	|	VATPrepaymentsFromCustomer.PrepaymentsSettlementDocument            AS PrepaymentsSettlementDocument,
	|	VATPrepaymentsFromCustomer.PeriodEndTransaction            AS PeriodEndTransaction,
	|	VATPrepaymentsFromCustomer.FinRecordID          AS FinRecordID,
	|	VATPrepaymentsFromCustomer.BusinessTransactionSetting  AS BusinessTransactionSetting,
	|	VATPrepaymentsFromCustomer.ReversingEntry                          AS ReversingEntry
	|FROM
	|	&VATPrepaymentsFromCustomer AS VATPrepaymentsFromCustomer";
	For Each NameOfRecordTable In TableNamesOfVATRecordAdvancesReceived Do
		QueryText = StrReplace(QueryTemplate, "&VATPrepaymentsFromCustomer", NameOfRecordTable);
		ArrayOfDataTexts.Add(QueryText);
	EndDo;
	TextDataToWrite = StrConcat(ArrayOfDataTexts, TMCommonUse.QuerySeparatorInJoin());
	
	Query = New Query;
	Query.Text = 
		TextDataToWrite
		+ "
		|
		|
		|ORDER BY
		|	Recorder,
		|	Period,
		|	Priority
		|
		|TOTALS BY
		|	Recorder
		|";
	
	Query.SetParameter("BeginOfPeriod",     CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",      CalculationParameters.EndOfPeriod);
	Query.SetParameter("CompanyArray", CalculationParameters.CompanyArray);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	
	SampleDocument = Query.Execute().Select(QueryResultIteration.ByGroups);
	
	While SampleDocument.Next() Do
		
		RecordSet = AccumulationRegisters.VATPrepaymentsFromCustomer.CreateRecordSet();
		RecordSet.Filter.Recorder.Set(SampleDocument.Recorder);
		
		// The dates of the ban are not checked, because we get here when performing tasks, 
		// and when creating tasks, the dates of the ban are controlled. 
		RecordSet.AdditionalProperties.Insert("SkipPeriodClosingCheck", True);
		
		Selection = SampleDocument.Select();
		While Selection.Next() Do
			
			NewRecord = RecordSet.Add();
			FillPropertyValues(NewRecord, Selection);
			
		EndDo;
		
		RecordSet.Write();
		
	EndDo;
	
EndProcedure

Procedure ClearVATAdvancesReceived(CalculationParameters, TableNamesOfVATRecordAdvancesReceived)
	
	ArrayOfTextsLoggersRecord = New Array;
	ArrayOfTextsLoggersRecord.Add("
	|SELECT DISTINCT
	|	UNDEFINED AS Recorder
	|INTO LoggersRecord
	|WHERE
	|	FALSE");
	
	QueryTemplate = 
	"SELECT DISTINCT
	|	VATPrepaymentsFromCustomer.Recorder
	|FROM
	|	&TableName AS VATPrepaymentsFromCustomer";
	For Each NameOfRecordTable In TableNamesOfVATRecordAdvancesReceived Do
		QueryText = StrReplace(QueryTemplate, "&TableName", NameOfRecordTable);
		ArrayOfTextsLoggersRecord.Add(QueryText);
	EndDo;
	TextLoggersRecord = StrConcat(ArrayOfTextsLoggersRecord, TMCommonUse.QuerySeparatorInJoin(True));
	TextLoggersRecord = TextLoggersRecord +
	"
	|INDEX BY
	|	Recorder";
	
	TextObsoleteLoggers = 
	"SELECT
	|	OutdatedLoggers.Recorder
	|FROM
	|	CurRegistrarsVATAdvancesReceived AS OutdatedLoggers
	|	LEFT JOIN
	|		LoggersRecord AS LoggersRecord
	|	ON
	|		OutdatedLoggers.Recorder = LoggersRecord.Recorder
	|
	|WHERE
	|	LoggersRecord.Recorder IS NULL
	|;
	|
	|//////////////////////////////////////////////
	|DROP LoggersRecord
	|";
	
	Query = New Query;
	Query.Text = TextLoggersRecord + Common.QueryBatchSeparator() + TextObsoleteLoggers;
	
	Query.SetParameter("BeginOfPeriod",     CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",  CalculationParameters.EndOfPeriod);
	Query.SetParameter("CompanyArray", CalculationParameters.CompanyArray);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	
	SampleDocument = Query.Execute().Select();
	While SampleDocument.Next() Do
		
		RecordSet = AccumulationRegisters.VATPrepaymentsFromCustomer.CreateRecordSet();
		RecordSet.Filter.Recorder.Set(SampleDocument.Recorder);
		RecordSet.Write(True);
		
	EndDo;

EndProcedure

Function CalculateVATAdvancesReceivedStornoOffsets(CalculationParameters)
	
	Query = New Query;
	Query.Text = "SELECT
	|	OffsetsOfAdvancesReceived.Period AS Period,
	|	OffsetsOfAdvancesReceived.DocumentPayments AS DocumentPayments,
	|	OffsetsOfAdvancesReceived.ARAPObject AS ARAPObject,
	|	CAST(OffsetsOfAdvancesReceived.PrepaymentsSettlementDocument AS Document.ReversingEntry).ReversedDocument AS Document,
	|	OffsetsOfAdvancesReceived.PrepaymentsSettlementDocument AS PrepaymentsSettlementDocument
	|INTO DocumentsForOffsettingAdvancesReceivedStorno
	|FROM
	|	OffsetsOfAdvancesReceived AS OffsetsOfAdvancesReceived
	|WHERE
	|	OffsetsOfAdvancesReceived.ReversingEntry = TRUE
	|
	|GROUP BY
	|	OffsetsOfAdvancesReceived.Period,
	|	OffsetsOfAdvancesReceived.DocumentPayments,
	|	OffsetsOfAdvancesReceived.ARAPObject,
	|	CAST(OffsetsOfAdvancesReceived.PrepaymentsSettlementDocument AS Document.ReversingEntry).ReversedDocument,
	|	OffsetsOfAdvancesReceived.PrepaymentsSettlementDocument
	|
	|INDEX BY
	|	DocumentPayments,
	|	ARAPObject,
	|	Document
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	2 AS Priority,
	|	CreditDocumentsStorno.Period AS Period,
	|	VATPrepaymentsFromCustomer.Recorder AS Recorder,
	|	VATPrepaymentsFromCustomer.RecordType AS RecordType,
	|	VATPrepaymentsFromCustomer.Organization AS Organization,
	|	VATPrepaymentsFromCustomer.DocumentPayments AS DocumentPayments,
	|	VATPrepaymentsFromCustomer.Counterparty AS Counterparty,
	|	VATPrepaymentsFromCustomer.ARAPObject AS ARAPObject,
	|	VATPrepaymentsFromCustomer.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|	VATPrepaymentsFromCustomer.Department AS Department,
	|	VATPrepaymentsFromCustomer.LineOfBusiness AS LineOfBusiness,
	|	VATPrepaymentsFromCustomer.VATRate AS VATRate,
	|	-VATPrepaymentsFromCustomer.AmountExcludingVAT AS AmountExcludingVAT,
	|	-VATPrepaymentsFromCustomer.VAT AS VAT,
	|	-VATPrepaymentsFromCustomer.VATManag AS VATManag,
	|	VATPrepaymentsFromCustomer.Event AS Event,
	|	CreditDocumentsStorno.PrepaymentsSettlementDocument AS PrepaymentsSettlementDocument,
	|	ISNULL(CreditDocumentsStorno.Document.Date, VATPrepaymentsFromCustomer.Period) AS DateOfAdvancePayment,
	|	VATPrepaymentsFromCustomer.FinRecordID AS FinRecordID,
	|	VATPrepaymentsFromCustomer.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	TRUE AS PeriodEndTransaction,
	|	FALSE AS ReversingEntry
	|INTO VATAdvancesReceivedStornoOffsets
	|FROM
	|	AccumulationRegister.VATPrepaymentsFromCustomer AS VATPrepaymentsFromCustomer
	|		INNER JOIN DocumentsForOffsettingAdvancesReceivedStorno AS CreditDocumentsStorno
	|		ON VATPrepaymentsFromCustomer.PrepaymentsSettlementDocument = CreditDocumentsStorno.Document
	|			AND VATPrepaymentsFromCustomer.DocumentPayments = CreditDocumentsStorno.DocumentPayments
	|			AND VATPrepaymentsFromCustomer.ARAPObject = CreditDocumentsStorno.ARAPObject
	|		INNER JOIN InvoicesIssuedInAdvance AS InvoicesIssuedInAdvance
	|		ON VATPrepaymentsFromCustomer.Recorder = InvoicesIssuedInAdvance.Ref
	|WHERE
	|	VATPrepaymentsFromCustomer.PeriodEndTransaction
	|	AND NOT VATPrepaymentsFromCustomer.ReversingEntry
	|	AND VATPrepaymentsFromCustomer.Period < &BeginOfPeriod
	|	AND NOT VATPrepaymentsFromCustomer.DocumentPayments IN 
	|				(SELECT
	|					ISF.DocumentPayments AS Ref
	|				FROM
	|					CorrectedInvoicesIssuedInAdvance AS ISF)
	|
	|UNION ALL
	|
	|SELECT
	|	2 AS Priority,
	|	CreditDocumentsStorno.Period AS Period,
	|	VATPrepaymentsFromCustomer.Recorder AS Recorder,
	|	VATPrepaymentsFromCustomer.RecordType AS RecordType,
	|	VATPrepaymentsFromCustomer.Organization AS Organization,
	|	VATPrepaymentsFromCustomer.DocumentPayments AS DocumentPayments,
	|	VATPrepaymentsFromCustomer.Counterparty AS Counterparty,
	|	VATPrepaymentsFromCustomer.ARAPObject AS ARAPObject,
	|	VATPrepaymentsFromCustomer.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|	VATPrepaymentsFromCustomer.Department AS Department,
	|	VATPrepaymentsFromCustomer.LineOfBusiness AS LineOfBusiness,
	|	VATPrepaymentsFromCustomer.VATRate AS VATRate,
	|	-VATPrepaymentsFromCustomer.AmountExcludingVAT AS AmountExcludingVAT,
	|	-VATPrepaymentsFromCustomer.VAT AS VAT,
	|	-VATPrepaymentsFromCustomer.VATManag AS VATManag,
	|	VATPrepaymentsFromCustomer.Event AS Event,
	|	CreditDocumentsStorno.PrepaymentsSettlementDocument AS PrepaymentsSettlementDocument,
	|	ISNULL(CreditDocumentsStorno.Document.Date, VATPrepaymentsFromCustomer.Period) AS DateOfAdvancePayment,
	|	VATPrepaymentsFromCustomer.FinRecordID AS FinRecordID,
	|	VATPrepaymentsFromCustomer.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	TRUE AS PeriodEndTransaction,
	|	FALSE AS ReversingEntry
	|FROM
	|	AccumulationRegister.VATPrepaymentsFromCustomer AS VATPrepaymentsFromCustomer
	|		INNER JOIN DocumentsForOffsettingAdvancesReceivedStorno AS CreditDocumentsStorno
	|		ON VATPrepaymentsFromCustomer.PrepaymentsSettlementDocument = CreditDocumentsStorno.Document
	|			AND VATPrepaymentsFromCustomer.DocumentPayments = CreditDocumentsStorno.DocumentPayments
	|			AND VATPrepaymentsFromCustomer.ARAPObject = CreditDocumentsStorno.ARAPObject
	|		INNER JOIN CorrectedInvoicesIssuedInAdvance AS CorrectedInvoicesIssuedInAdvance
	|		ON VATPrepaymentsFromCustomer.Recorder = CorrectedInvoicesIssuedInAdvance.Ref
	|			AND VATPrepaymentsFromCustomer.CorrectedTaxInvoice = CorrectedInvoicesIssuedInAdvance.Ref
	|WHERE
	|	VATPrepaymentsFromCustomer.PeriodEndTransaction
	|	AND NOT VATPrepaymentsFromCustomer.ReversingEntry
	|	AND VATPrepaymentsFromCustomer.Period < &BeginOfPeriod";
	
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.SetParameter("BeginOfPeriod", CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", CalculationParameters.EndOfPeriod);

	Query.Execute();
	
	Return "VATAdvancesReceivedStornoOffsets";
	
EndFunction

#EndRegion

#Region VATGenerationAdvancesIssued

Procedure GenerateVATAdvancesIssued(CalculationParameters)
	
	Query = New Query;
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.Text =
	"SELECT TOP 1
	|	TRUE AS Field1
	|FROM
	|	Jobs AS Jobs
	|WHERE
	|	TRUE IN (TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					Document.ReceivedTaxInvoicePrepayment AS TaxInv
	|					INNER JOIN ExpansionOfARAPTransactionTable AS VT_ARAPTransactions
	|					ON VT_ARAPTransactions.DocumentPayments = Jobs.TaxInvoice
	|				WHERE
	|					TaxInv.DocumentBasis = VT_ARAPTransactions.OriginalARAPTransactionDocument))";
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	Else
		CalculationParameters.CalculationOfAdvancesIssued = True;
	EndIf;
	
	ArrayOfDimensions_ = New Array;
	For Each Dimension In Metadata.AccumulationRegisters.VATPrepaymentsToVendor.Dimensions Do
		ArrayOfDimensions_.Add(Dimension.Name);
	EndDo;
	CalculationParameters.ArrayOfRegisterMeasurements = ArrayOfDimensions_;
	
	GetCurRegistrarsVATAdvancesIssued(CalculationParameters);
		
	GetInvoicesReceivedInAdvance(CalculationParameters);
	GetCorrectiveInvoicesReceivedInAdvance(CalculationParameters);
	
	GetCreditsForAdvancesIssued(CalculationParameters);
	
	TableNamesOfVATRecordAdvancesIssued = New Array;
	TableNamesOfVATRecordAdvancesIssued.Add(CalculateVATAdvancesIssuedStorno(CalculationParameters));
	TableNamesOfVATRecordAdvancesIssued.Add(CalculateVATAdvancesIssuedUnderISF(CalculationParameters)); 
	TableNamesOfVATRecordAdvancesIssued.Add(CalculateVATAdvancesIssuedStornoOffsets(CalculationParameters));
	TableNamesOfVATRecordAdvancesIssued.Add(CalculateVATAdvancesIssuedTransfersExpenses(CalculationParameters));
	TableNamesOfVATRecordAdvancesIssued.Add(CalculateVATAdvancesIssuedTransfersArrival(CalculationParameters));
	TableNamesOfVATRecordAdvancesIssued.Add(CalculateVATAdvancesIssuedCredits(CalculationParameters));
	TableNamesOfVATRecordAdvancesIssued.Add(CalculateVATRecordsAdvancesIssuedSaving(CalculationParameters, TableNamesOfVATRecordAdvancesIssued));

	RecordVATAdvancesIssued(CalculationParameters, TableNamesOfVATRecordAdvancesIssued);
	ClearVATAdvancesIssued(CalculationParameters, TableNamesOfVATRecordAdvancesIssued);
	
EndProcedure

Procedure GetCurRegistrarsVATAdvancesIssued(CalculationParameters) 
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	VATPrepaymentsToVendor.Recorder AS Recorder,
	|	VATPrepaymentsToVendor.Organization AS Organization,
	|	VATPrepaymentsToVendor.Period      AS Period
	|INTO CurRegistrarsVATAdvancesIssued
	|FROM
	|	AccumulationRegister.VATPrepaymentsToVendor AS VATPrepaymentsToVendor
	|		INNER JOIN Jobs AS Jobs
	|		ON (Jobs.Organization = VATPrepaymentsToVendor.Organization)
	|			AND (Jobs.TaxInvoice = VATPrepaymentsToVendor.DocumentPayments)
	|WHERE
	|	VATPrepaymentsToVendor.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND VATPrepaymentsToVendor.PeriodEndTransaction
	|
	|INDEX BY
	|	Recorder
	|";
	
	Query.SetParameter("BeginOfPeriod",     CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",  CalculationParameters.EndOfPeriod);
	Query.SetParameter("CompanyArray", CalculationParameters.CompanyArray);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.Execute();
	
EndProcedure

Procedure GetInvoicesReceivedInAdvance(CalculationParameters)
	
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	ReceivedTaxInvoicePrepayment.Organization         AS Organization,
	|	ReceivedTaxInvoicePrepayment.Counterparty          AS Counterparty,
	|	ReceivedTaxInvoicePrepayment.DocumentBasis   AS DocumentPayments,
	|	ReceivedTaxInvoicePrepayment.Date                AS Period,
	|	ReceivedTaxInvoicePrepayment.Ref              AS Ref,
	|	ReceivedTaxInvoicePrepayment.Date                AS Date
	|INTO InvoicesReceivedInAdvance
	|FROM
	|	Document.ReceivedTaxInvoicePrepayment AS ReceivedTaxInvoicePrepayment
	|	INNER JOIN
	|		ExpansionOfARAPTransactionTable AS VT_ARAPTransactionDocuments
	|	ON
	|		VT_ARAPTransactionDocuments.Organization = ReceivedTaxInvoicePrepayment.Organization
	|			AND VT_ARAPTransactionDocuments.OriginalARAPTransactionDocument = ReceivedTaxInvoicePrepayment.DocumentBasis
	|
	|	LEFT JOIN
	|		InformationRegister.DocumentCorrections AS DocumentCorrections
	|	ON
	|		DocumentCorrections.CorrectedDocument = ReceivedTaxInvoicePrepayment.Ref
	|			AND DocumentCorrections.Period <= &EndOfPeriod
	|			AND DocumentCorrections.DocumentToCorrectIsReversed
	|
	|WHERE
	|	ReceivedTaxInvoicePrepayment.Posted
	|	AND NOT ReceivedTaxInvoicePrepayment.Patch
	|	AND DocumentCorrections.CorrectedDocument IS NULL
	|
	|INDEX BY
	|	Organization,
	|	DocumentPayments,
	|	Counterparty
	|";
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.SetParameter("EndOfPeriod", CalculationParameters.EndOfPeriod);
	Query.Execute();
	
EndProcedure

Procedure GetCorrectiveInvoicesReceivedInAdvance(CalculationParameters)
	
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	CorrectedTaxInvoice.Organization               AS Organization,
	|	CorrectedTaxInvoice.DocumentBasis         AS DocumentPayments,
	|	CorrectedTaxInvoice.Counterparty                AS Counterparty,
	|	CorrectedTaxInvoice.Ref                    AS CorrectedTaxInvoice,
	|	CorrectedTaxInvoice.Date                      AS Period,
	|	CorrectedTaxInvoice.Date                      AS CorrectionDate,
	|	CorrectedTaxInvoice.CorrectionNumber          AS CorrectionNumber,
	|	CorrectedTaxInvoice.BaseDocumentTaxInvoice.Date AS Date,
	|	CorrectedTaxInvoice.Ref                    AS Ref
	|INTO CorrectedInvoicesReceivedInAdvance
	|FROM
	|	ExpansionOfARAPTransactionTable AS VT_ARAPTransactionDocuments
	|	
	|	INNER JOIN
	|		Document.ReceivedTaxInvoicePrepayment AS CorrectedTaxInvoice
	|	ON
	|		VT_ARAPTransactionDocuments.Organization = CorrectedTaxInvoice.Organization
	|		AND VT_ARAPTransactionDocuments.OriginalARAPTransactionDocument = CorrectedTaxInvoice.DocumentBasis
	|		AND CorrectedTaxInvoice.Patch
	|		AND CorrectedTaxInvoice.Posted
	|		AND CorrectedTaxInvoice.Date <= &EndOfPeriod
	|
	|	LEFT JOIN
	|		Document.ReceivedTaxInvoicePrepayment AS OtherCorrectedInvoices
	|	ON 
	|		CorrectedTaxInvoice.Organization = OtherCorrectedInvoices.Organization
	|		AND CorrectedTaxInvoice.DocumentBasis = OtherCorrectedInvoices.DocumentBasis
	|		AND CorrectedTaxInvoice.CorrectionNumber < OtherCorrectedInvoices.CorrectionNumber
	|		AND OtherCorrectedInvoices.Posted
	|		AND OtherCorrectedInvoices.Patch
	|		AND OtherCorrectedInvoices.Date <= &EndOfPeriod
	|
	|	LEFT JOIN
	|		InformationRegister.DocumentCorrections AS DocumentCorrections
	|	ON
	|		DocumentCorrections.CorrectedDocument = CorrectedTaxInvoice.Ref
	|			AND DocumentCorrections.Period <= &EndOfPeriod
	|			AND DocumentCorrections.DocumentToCorrectIsReversed
	|
	|WHERE
	|	OtherCorrectedInvoices.Ref IS NULL
	|	AND DocumentCorrections.CorrectedDocument IS NULL
	|
	|INDEX BY
	|	Organization,
	|	DocumentPayments,
	|	Counterparty
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CorrectedInvoicesReceivedInAdvance.Organization             AS Organization,
	|	CorrectedInvoicesReceivedInAdvance.DocumentPayments          AS DocumentPayments,
	|	CorrectedInvoicesReceivedInAdvance.Counterparty              AS Counterparty,
	|	CorrectedInvoicesReceivedInAdvance.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|	CorrectedInvoicesReceivedInAdvance.Period                  AS Period,
	|	CorrectedInvoicesReceivedInAdvance.CorrectionDate         AS CorrectionDate,
	|	CorrectedInvoicesReceivedInAdvance.CorrectionNumber        AS CorrectionNumber,
	|	CorrectedInvoicesReceivedInAdvance.Date                    AS Date,
	|	CorrectedInvoicesReceivedInAdvance.Ref                  AS Ref
	|INTO CorrectedInvoicesReceivedAdvanceRecalculation
	|FROM
	|	CorrectedInvoicesReceivedInAdvance AS CorrectedInvoicesReceivedInAdvance
	|WHERE
	|	CorrectedInvoicesReceivedInAdvance.CorrectionDate BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|
	|INDEX BY
	|	Organization,
	|	DocumentPayments,
	|	Counterparty
	|;
	|
	|/////////////////////////////////////////////////////////////////////// 
	|SELECT
	|	MIN(CorrectedInvoicesReceivedInAdvance.Date) AS Date
	|FROM
	|	CorrectedInvoicesReceivedAdvanceRecalculation AS CorrectedInvoicesReceivedInAdvance
	|";
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.SetParameter("BeginOfPeriod", CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", CalculationParameters.EndOfPeriod);
	
	QueryResult = Query.Execute();

	SelectionDetailRecords = QueryResult.Select();
	SelectionDetailRecords.Next();

	If ValueIsFilled(SelectionDetailRecords.Date) Then
		CalculationParameters.ISFBeginningOfPeriod = BegOfMonth(SelectionDetailRecords.Date);
		CalculationParameters.ISFEndOfPeriod = EndOfMonth(AddMonth(CalculationParameters.EndOfPeriod, -1));
	EndIf;
	
EndProcedure

Function CalculateVATAdvancesIssuedStorno(CalculationParameters)

	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	DocumentsStorno.Ref AS Ref,
	|	DocumentsStorno.Period AS Period,
	|	DocumentsStorno.ReversedDocument AS ReversedDocument,
	|	VATPrepaymentsToVendor.Organization AS Organization,
	|	VATPrepaymentsToVendor.DocumentPayments AS DocumentPayments
	|INTO VATAdvancesIssuedSelectionStorno
	|FROM
	|	AccumulationRegister.VATPrepaymentsToVendor AS VATPrepaymentsToVendor
	|	INNER JOIN
	|		Jobs AS Jobs
	|	ON
	|		VATPrepaymentsToVendor.Organization = Jobs.Organization
	|		AND VATPrepaymentsToVendor.DocumentPayments = Jobs.TaxInvoice
	|	
	|	LEFT JOIN
	|		DocumentsStorno AS DocumentsStorno
	|	ON
	|		VATPrepaymentsToVendor.Recorder = DocumentsStorno.ReversedDocument
	|	
	|WHERE
	|	VATPrepaymentsToVendor.Period < &BeginOfPeriod 
	|	AND VATPrepaymentsToVendor.PeriodEndTransaction
	|	AND NOT VATPrepaymentsToVendor.ReversingEntry
	|	AND NOT DocumentsStorno.ReversedDocument IS NULL
	|
	|INDEX BY
	|	ReversedDocument
	|;
	|
	|//////////////////////////////////////////////
	|SELECT
	|	0 AS Priority,
	|	VATAdvancesIssuedSelectionStorno.Ref AS Recorder,
	|	VATAdvancesIssuedSelectionStorno.Period AS Period,
	|	VATPrepaymentsToVendor.RecordType AS RecordType,
	|	VATPrepaymentsToVendor.Organization AS Organization,
	|	VATPrepaymentsToVendor.DocumentPayments AS DocumentPayments,
	|	VATPrepaymentsToVendor.Counterparty AS Counterparty,
	|	VATPrepaymentsToVendor.ARAPObject AS ARAPObject,
	|	VATPrepaymentsToVendor.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|	VATPrepaymentsToVendor.Department AS Department,
	|	VATPrepaymentsToVendor.LineOfBusiness AS LineOfBusiness,
	|	VATPrepaymentsToVendor.VATRate  AS VATRate,
	|	-VATPrepaymentsToVendor.AmountExcludingVAT  AS AmountExcludingVAT,
	|	-VATPrepaymentsToVendor.VAT AS VAT,
	|	-VATPrepaymentsToVendor.VATManag AS VATManag,
	|	VATPrepaymentsToVendor.Event AS Event,
	|	VATPrepaymentsToVendor.PrepaymentsSettlementDocument AS PrepaymentsSettlementDocument,
	|	VATPrepaymentsToVendor.PeriodEndTransaction AS PeriodEndTransaction,
	|	VATPrepaymentsToVendor.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	VATPrepaymentsToVendor.FinRecordID AS FinRecordID,
	|	TRUE AS ReversingEntry
	|INTO VATAdvancesIssuedStorno
	|FROM
	|	VATAdvancesIssuedSelectionStorno AS VATAdvancesIssuedSelectionStorno
	|	INNER JOIN
	|		AccumulationRegister.VATPrepaymentsToVendor AS VATPrepaymentsToVendor
	|	ON
	|		VATPrepaymentsToVendor.Recorder = VATAdvancesIssuedSelectionStorno.ReversedDocument
	|		AND VATPrepaymentsToVendor.Organization = VATAdvancesIssuedSelectionStorno.Organization
	|		AND VATPrepaymentsToVendor.DocumentPayments = VATAdvancesIssuedSelectionStorno.DocumentPayments
	|
	|WHERE
	|	VATPrepaymentsToVendor.PeriodEndTransaction
	|	AND NOT VATPrepaymentsToVendor.ReversingEntry
	|	AND VATPrepaymentsToVendor.Period < &BeginOfPeriod
	|;
	|";
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.SetParameter("BeginOfPeriod", CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", CalculationParameters.EndOfPeriod);

	Query.Execute();
	
	Return "VATAdvancesIssuedStorno";
	
EndFunction

Function AdvancesIssuedOnPaymentDocuments(CalculationParameters)
	
	If Not CostCalculationAppliedAlgorithms.TemporaryTableExists(
		CalculationParameters.TempTablesManager,
		"AdvancesIssued_Occurrences") Then

		AdvanceCalculationParameters = InitializeParametersForPreparationOfAdvancePaymentsForVATPurposes();
		
		AdvanceCalculationParameters.SelectionParametersForSettlementDocument.SelectionTableName_ = "Jobs";
		AdvanceCalculationParameters.SelectionParametersForSettlementDocument.FieldName          = "TaxInvoice";
		AdvanceCalculationParameters.IncludeFinancialInstrumentData                  = True;
		AdvanceCalculationParameters.AnalyzeManAccountingAdditionally                     = True;
		
		PrepareVT_AdvancesIssued_Occurrences(
				CalculationParameters.TempTablesManager,
				AdvanceCalculationParameters,
				CalculationParameters.SettingsTable);
	EndIf;
	
	Query = New Query;
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.Text = 
	"SELECT
	|	Calculations.DocumentPayments AS DocumentPayments,
	|	Calculations.Counterparty AS Counterparty,
	|	SUM(Calculations.Prepayment_) AS Prepayment_,
	|	SUM(Calculations.AdvanceMan) AS AdvanceMan
	|FROM
	|	(SELECT
	|		VT_ARAPTransactionDocuments.OriginalARAPTransactionDocument AS DocumentPayments,
	|		Calculations.Counterparty AS Counterparty,
	|		Calculations.AdvanceAmount AS Prepayment_,
	|		Calculations.AdvanceAmountOfMan AS AdvanceMan
	|	FROM
	|		AdvancesIssued_Occurrences AS Calculations
	|			INNER JOIN ExpansionOfARAPTransactionTable AS VT_ARAPTransactionDocuments
	|			ON Calculations.Organization = VT_ARAPTransactionDocuments.Organization
	|				AND Calculations.ARAPDocument = VT_ARAPTransactionDocuments.DocumentPayments
	|	) AS Calculations
	|
	|GROUP BY
	|	Calculations.Counterparty,
	|	Calculations.DocumentPayments";
	
	Return Query.Execute().Unload();
	
EndFunction

Procedure GetCreditsForAdvancesIssued(CalculationParameters)
	
	AdvanceCalculationParameters = InitializeParametersForPreparationOfAdvancePaymentsForVATPurposes();
	
	AdvanceCalculationParameters.StartDate                                            = CalculationParameters.BeginOfPeriod;
	AdvanceCalculationParameters.EndDate                                         = CalculationParameters.EndOfPeriod;
	AdvanceCalculationParameters.Companies                                           = CalculationParameters.CompanyArray;
	AdvanceCalculationParameters.IncludeFinancialInstrumentData                  = True;
	AdvanceCalculationParameters.SelectionParametersForSettlementDocument.SelectionTableName_ = "Jobs";
	AdvanceCalculationParameters.SelectionParametersForSettlementDocument.FieldName          = "TaxInvoice";
	
	PrepareVT_AdvancesIssued_Repayments(
			CalculationParameters.TempTablesManager,
			AdvanceCalculationParameters,
			CalculationParameters.SettingsTable);
	
	Query = New Query;
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.Text =
	"SELECT
	|	Credits.DocumentRecorder               AS Recorder,
	|	Credits.MaturityDate                     AS Period,
	|	Credits.Organization                       AS Organization,
	|	Credits.LineOfBusiness           AS LineOfBusiness,
	|	Credits.Counterparty                        AS Counterparty,
	|	VT_ARAPTransactionDocuments.OriginalARAPTransactionDocument AS DocumentPayments,
	|	Credits.DocumentRecorder               AS PrepaymentsSettlementDocument,
	|	Credits.ARAPObject                    AS ARAPObject,
	|	Credits.ReversingEntry                            AS ReversingEntry,
	|	SUM(Credits.EventSign)                AS EventSign,
	|	SUM(Credits.RepaymentAmount)             AS OffsetAmount_
	|INTO OffsetsOfAdvancesIssued
	|FROM
	|	AdvancesIssued_Repayment AS Credits
	|	INNER JOIN
	|		ExpansionOfARAPTransactionTable AS VT_ARAPTransactionDocuments
	|	ON
	|		VT_ARAPTransactionDocuments.Organization = Credits.Organization
	|			AND VT_ARAPTransactionDocuments.DocumentPayments = Credits.ARAPDocument
	|
	|GROUP BY
	|	Credits.DocumentRecorder,
	|	Credits.MaturityDate,
	|	Credits.Organization,
	|	Credits.LineOfBusiness,
	|	Credits.Counterparty,
	|	VT_ARAPTransactionDocuments.OriginalARAPTransactionDocument,
	|	Credits.ARAPObject,
	|	Credits.ReversingEntry
	|
	|INDEX BY
	|	Recorder
	|;
	|
	|DROP AdvancesIssued_Repayment
	|";
	
	Query.Execute();
	
	//For ISF, it is necessary to calculate the repayment data starting from the date of the payment document
	ThereIsISF = Not CalculationParameters.TempTablesManager.Tables["CorrectedInvoicesReceivedAdvanceRecalculation"].GetData().IsEmpty();
	If ThereIsISF Then

		AdvanceCalculationParameters.StartDate                                            = CalculationParameters.ISFBeginningOfPeriod;
		AdvanceCalculationParameters.EndDate                                         = CalculationParameters.ISFEndOfPeriod;
		AdvanceCalculationParameters.SelectionParametersForSettlementDocument.SelectionTableName_ = "CorrectedInvoicesReceivedAdvanceRecalculation";
		AdvanceCalculationParameters.SelectionParametersForSettlementDocument.FieldName          = "DocumentPayments";
	
		PrepareVT_AdvancesIssued_Repayments(
			CalculationParameters.TempTablesManager,
			AdvanceCalculationParameters,
			CalculationParameters.SettingsTable);
	
		Query.Text =
		"SELECT
		|	CASE
		|		WHEN VALUETYPE(Credits.DocumentRecorder) = TYPE(Document.ReversingEntry) AND Credits.ReversingEntry THEN
		|			CAST(Credits.DocumentRecorder AS Document.ReversingEntry).ReversedDocument
		|		ELSE Credits.DocumentRecorder
		|	END                                    AS Recorder,
		|	CASE
		|		WHEN VALUETYPE(Credits.DocumentRecorder) = TYPE(Document.ReversingEntry) AND Credits.ReversingEntry THEN
		|			CAST(Credits.DocumentRecorder AS Document.ReversingEntry).ReversedDocument.Date
		|		ELSE Credits.MaturityDate
		|	END                                    AS Period,
		|	Credits.Organization                       AS Organization,
		|	Credits.LineOfBusiness           AS LineOfBusiness,
		|	Credits.Counterparty                        AS Counterparty,
		|	VT_ARAPTransactionDocuments.OriginalARAPTransactionDocument AS DocumentPayments,
		|	CASE
		|		WHEN VALUETYPE(Credits.DocumentRecorder) = TYPE(Document.ReversingEntry) AND Credits.ReversingEntry THEN
		|			CAST(Credits.DocumentRecorder AS Document.ReversingEntry).ReversedDocument
		|		ELSE Credits.DocumentRecorder
		|	END                                    AS PrepaymentsSettlementDocument,
		|	Credits.ARAPObject                    AS ARAPObject,
		|	Credits.ReversingEntry                            AS ReversingEntry,
		|	SUM(Credits.EventSign)                AS EventSign,
		|	SUM(Credits.RepaymentAmount)             AS OffsetAmount_
		|INTO OffsetsOfAdvancesIssuedInterim
		|FROM
		|	AdvancesIssued_Repayment AS Credits
		|	INNER JOIN
		|		ExpansionOfARAPTransactionTable AS VT_ARAPTransactionDocuments
		|	ON
		|		VT_ARAPTransactionDocuments.Organization = Credits.Organization
		|			AND VT_ARAPTransactionDocuments.DocumentPayments = Credits.ARAPDocument
		|
		|GROUP BY
		|	Credits.Organization,
		|	Credits.LineOfBusiness,
		|	Credits.Counterparty,
		|	VT_ARAPTransactionDocuments.OriginalARAPTransactionDocument,
		|	Credits.ARAPObject,
		|	Credits.ReversingEntry,
		|	CASE
		|		WHEN VALUETYPE(Credits.DocumentRecorder) = TYPE(Document.ReversingEntry) AND Credits.ReversingEntry THEN
		|			CAST(Credits.DocumentRecorder AS Document.ReversingEntry).ReversedDocument
		|		ELSE Credits.DocumentRecorder
		|	END,
		|	CASE
		|		WHEN VALUETYPE(Credits.DocumentRecorder) = TYPE(Document.ReversingEntry) AND Credits.ReversingEntry THEN
		|			CAST(Credits.DocumentRecorder AS Document.ReversingEntry).ReversedDocument.Date
		|		ELSE Credits.MaturityDate
		|	END
		|
		|UNION ALL
		|
		|SELECT
		|	Credits.Recorder             AS Recorder,
		|	Credits.Period                  AS Period,
		|	Credits.Organization             AS Organization,
		|	Credits.LineOfBusiness AS LineOfBusiness,
		|	Credits.Counterparty              AS Counterparty,
		|	Credits.DocumentPayments          AS DocumentPayments,
		|	Credits.PrepaymentsSettlementDocument    AS PrepaymentsSettlementDocument,
		|	Credits.ARAPObject          AS ARAPObject,
		|	Credits.ReversingEntry                  AS ReversingEntry,
		|	Credits.EventSign             AS EventSign,
		|	Credits.OffsetAmount_             AS OffsetAmount_
		|FROM
		|	OffsetsOfAdvancesIssued AS Credits
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP AdvancesIssued_Repayment
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP OffsetsOfAdvancesIssued
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Credits.Recorder             AS Recorder,
		|	Credits.Period                  AS Period,
		|	Credits.Organization             AS Organization,
		|	Credits.LineOfBusiness AS LineOfBusiness,
		|	Credits.Counterparty              AS Counterparty,
		|	Credits.DocumentPayments          AS DocumentPayments,
		|	Credits.PrepaymentsSettlementDocument    AS PrepaymentsSettlementDocument,
		|	Credits.ARAPObject          AS ARAPObject,
		|	Credits.ReversingEntry                  AS ReversingEntry,
		|	Credits.EventSign             AS EventSign,
		|	Credits.OffsetAmount_             AS OffsetAmount_
		|INTO OffsetsOfAdvancesIssued
		|FROM
		|	OffsetsOfAdvancesIssuedInterim AS Credits
		|
		|INDEX BY
		|	Recorder
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP OffsetsOfAdvancesIssuedInterim
		|";

		Query.Execute();

	EndIf;
	
EndProcedure

Function CalculateVATAdvancesIssuedUnderISF(CalculationParameters)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	1                                                  AS Priority,
	|	VATPrepaymentsToVendor.Recorder                      AS Recorder,
	|	VATPrepaymentsToVendor.Period                           AS Period,
	|	VATPrepaymentsToVendor.RecordType                      AS RecordType,
	|	VATPrepaymentsToVendor.Organization                      AS Organization,
	|	VATPrepaymentsToVendor.DocumentPayments                   AS DocumentPayments,
	|	VATPrepaymentsToVendor.Counterparty                       AS Counterparty,
	|	VATPrepaymentsToVendor.ARAPObject                   AS ARAPObject,
	|	VATPrepaymentsToVendor.CorrectedTaxInvoice          AS CorrectedTaxInvoice,
	|	VATPrepaymentsToVendor.Department                    AS Department,
	|	VATPrepaymentsToVendor.LineOfBusiness          AS LineOfBusiness,
	|	VATPrepaymentsToVendor.VATRate                        AS VATRate,
	|	SUM(VATPrepaymentsToVendor.AmountExcludingVAT)               AS AmountExcludingVAT,
	|	SUM(VATPrepaymentsToVendor.VAT)                       AS VAT,
	|	SUM(VATPrepaymentsToVendor.VATManag)                    AS VATManag,
	|	TRUE                                             AS PeriodEndTransaction,
	|	FALSE                                               AS ReversingEntry,
	|	VATPrepaymentsToVendor.Event                          AS Event,
	|	VATPrepaymentsToVendor.PrepaymentsSettlementDocument             AS PrepaymentsSettlementDocument,
	|	VATPrepaymentsToVendor.FinRecordID           AS FinRecordID,
	|	VATPrepaymentsToVendor.BusinessTransactionSetting   AS BusinessTransactionSetting
	|INTO VATAdvancesIssuedUnderISF
	|FROM
	|	(SELECT
	|		CorrectedInvoices.Ref                    AS Recorder,
	|		CorrectedInvoices.Period                    AS Period,
	|		VATPrepaymentsToVendor.RecordType                      AS RecordType,
	|		VATPrepaymentsToVendor.Organization                      AS Organization,
	|		VATPrepaymentsToVendor.DocumentPayments                   AS DocumentPayments,
	|		VATPrepaymentsToVendor.Counterparty                       AS Counterparty,
	|		VATPrepaymentsToVendor.ARAPObject                   AS ARAPObject,
	|		VATPrepaymentsToVendor.CorrectedTaxInvoice          AS CorrectedTaxInvoice,
	|		VATPrepaymentsToVendor.Department                    AS Department,
	|		VATPrepaymentsToVendor.LineOfBusiness          AS LineOfBusiness,
	|		VATPrepaymentsToVendor.VATRate                        AS VATRate,
	|		-VATPrepaymentsToVendor.AmountExcludingVAT                     AS AmountExcludingVAT,
	|		-VATPrepaymentsToVendor.VAT                             AS VAT,
	|		-VATPrepaymentsToVendor.VATManag                          AS VATManag,
	|		VATPrepaymentsToVendor.Event                          AS Event,
	|		VATPrepaymentsToVendor.PrepaymentsSettlementDocument             AS PrepaymentsSettlementDocument,
	|		VATPrepaymentsToVendor.FinRecordID           AS FinRecordID,
	|		VATPrepaymentsToVendor.BusinessTransactionSetting   AS BusinessTransactionSetting
	|	FROM
	|		CorrectedInvoicesReceivedInAdvance AS CorrectedInvoices
	|		INNER JOIN
	|			AccumulationRegister.VATPrepaymentsToVendor AS VATPrepaymentsToVendor
	|		ON
	|			VATPrepaymentsToVendor.Organization = CorrectedInvoices.Organization
	|			AND VATPrepaymentsToVendor.DocumentPayments = CorrectedInvoices.DocumentPayments
	|			AND VATPrepaymentsToVendor.Period < &BeginOfPeriod
	|			AND VATPrepaymentsToVendor.CorrectedTaxInvoice <> CorrectedInvoices.CorrectedTaxInvoice
	|			AND VATPrepaymentsToVendor.Active
	|
	|	UNION ALL
	|
	|	SELECT
	|		CorrectedInvoices.Ref                    AS Recorder,
	|		CorrectedInvoices.Period                    AS Period,
	|		VATPrepaymentsToVendor.RecordType                      AS RecordType,
	|		VATPrepaymentsToVendor.Organization                      AS Organization,
	|		VATPrepaymentsToVendor.DocumentPayments                   AS DocumentPayments,
	|		VATPrepaymentsToVendor.Counterparty                       AS Counterparty,
	|		VATPrepaymentsToVendor.ARAPObject                   AS ARAPObject,
	|		VATPrepaymentsToVendor.CorrectedTaxInvoice          AS CorrectedTaxInvoice,
	|		VATPrepaymentsToVendor.Department                    AS Department,
	|		VATPrepaymentsToVendor.LineOfBusiness          AS LineOfBusiness,
	|		VATPrepaymentsToVendor.VATRate                        AS VATRate,
	|		-VATPrepaymentsToVendor.AmountExcludingVAT                     AS AmountExcludingVAT,
	|		-VATPrepaymentsToVendor.VAT                             AS VAT,
	|		-VATPrepaymentsToVendor.VATManag                          AS VATManag,
	|		VATPrepaymentsToVendor.Event                          AS Event,
	|		VATPrepaymentsToVendor.PrepaymentsSettlementDocument             AS PrepaymentsSettlementDocument,
	|		VATPrepaymentsToVendor.FinRecordID           AS FinRecordID,
	|		VATPrepaymentsToVendor.BusinessTransactionSetting   AS BusinessTransactionSetting
	|
	|	FROM
	|		CorrectedInvoicesReceivedInAdvance AS CorrectedInvoices
	|		INNER JOIN
	|			AccumulationRegister.VATPrepaymentsToVendor AS VATPrepaymentsToVendor
	|		ON
	|			VATPrepaymentsToVendor.Organization = CorrectedInvoices.Organization
	|			AND VATPrepaymentsToVendor.DocumentPayments = CorrectedInvoices.DocumentPayments
	|			AND VATPrepaymentsToVendor.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|			AND VATPrepaymentsToVendor.CorrectedTaxInvoice <> CorrectedInvoices.CorrectedTaxInvoice
	|			AND NOT VATPrepaymentsToVendor.PeriodEndTransaction
	|			AND VATPrepaymentsToVendor.Active) AS VATPrepaymentsToVendor
	|
	|GROUP BY
	|	VATPrepaymentsToVendor.Recorder,
	|	VATPrepaymentsToVendor.Period,
	|	VATPrepaymentsToVendor.RecordType,
	|	VATPrepaymentsToVendor.Organization,
	|	VATPrepaymentsToVendor.DocumentPayments,
	|	VATPrepaymentsToVendor.Counterparty,
	|	VATPrepaymentsToVendor.ARAPObject,
	|	VATPrepaymentsToVendor.CorrectedTaxInvoice,
	|	VATPrepaymentsToVendor.Department,
	|	VATPrepaymentsToVendor.LineOfBusiness,
	|	VATPrepaymentsToVendor.VATRate,
	|	VATPrepaymentsToVendor.Event,
	|	VATPrepaymentsToVendor.PrepaymentsSettlementDocument,
	|	VATPrepaymentsToVendor.FinRecordID,
	|	VATPrepaymentsToVendor.BusinessTransactionSetting
	|
	|HAVING
	|	SUM(VATPrepaymentsToVendor.AmountExcludingVAT) <> 0 OR SUM(VATPrepaymentsToVendor.VAT) <> 0
	|
	|INDEX BY
	|	Organization,
	|	DocumentPayments
	|";
	
	Query.SetParameter("BeginOfPeriod", CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",  CalculationParameters.EndOfPeriod);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.Execute();
	
	Return "VATAdvancesIssuedUnderISF";
	
EndFunction

Function VATDeductionAdvancesIssued(CalculationParameters)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DeductionFromPrepaymentToVendor.Organization             AS Organization,
	|	DeductionFromPrepaymentToVendor.DocumentPayments          AS DocumentPayments,
	|	DeductionFromPrepaymentToVendor.Counterparty              AS Counterparty,
	|	DeductionFromPrepaymentToVendor.ARAPObject          AS ARAPObject,
	|	DeductionFromPrepaymentToVendor.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|	DeductionFromPrepaymentToVendor.Department           AS Department,
	|	DeductionFromPrepaymentToVendor.LineOfBusiness AS LineOfBusiness,
	|	DeductionFromPrepaymentToVendor.VATRate               AS VATRate,
	|	SUM(DeductionFromPrepaymentToVendor.AmountExcludingVAT)      AS AmountExcludingVAT,
	|	SUM(DeductionFromPrepaymentToVendor.VAT)              AS VAT,
	|	SUM(DeductionFromPrepaymentToVendor.VATManag)           AS VATManag
	|INTO VATDeductionAdvancesIssued
	|FROM
	|	(SELECT
	|		DD.Organization              AS Organization,
	|		DD.DocumentPayments           AS DocumentPayments,
	|		DD.Counterparty               AS Counterparty,
	|		DD.ARAPObject           AS ARAPObject,
	|		DD.CorrectedTaxInvoice  AS CorrectedTaxInvoice,
	|		DD.Department            AS Department,
	|		DD.LineOfBusiness  AS LineOfBusiness,
	|		DD.VATRate                AS VATRate,
	|		DD.AmountExcludingVAT              AS AmountExcludingVAT,
	|		DD.VAT                      AS VAT,
	|		DD.VATManag                   AS VATManag
	|	FROM
	|		BalancesAdvancesIssuedBeforeTransfer AS DD
	|	
	|	UNION ALL
	|
	|	SELECT
	|		DD.Organization             AS Organization,
	|		DD.DocumentPayments          AS DocumentPayments,
	|		DD.Counterparty              AS Counterparty,
	|		DD.ARAPObject          AS ARAPObject,
	|		DD.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|		DD.Department           AS Department,
	|		DD.LineOfBusiness AS LineOfBusiness,
	|		DD.VATRate               AS VATRate,
	|		DD.AmountExcludingVAT             AS AmountExcludingVAT,
	|		DD.VAT                     AS VAT,
	|		DD.VATManag                  AS VATManag
	|	FROM
	|		VATAdvancesIssuedTransfersExpense AS DD
	|
	|	UNION ALL
	|
	|	SELECT
	|		DD.Organization             AS Organization,
	|		DD.DocumentPayments          AS DocumentPayments,
	|		DD.Counterparty              AS Counterparty,
	|		DD.ARAPObject          AS ARAPObject,
	|		DD.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|		DD.Department           AS Department,
	|		DD.LineOfBusiness AS LineOfBusiness,
	|		DD.VATRate               AS VATRate,
	|		-DD.AmountExcludingVAT            AS AmountExcludingVAT,
	|		-DD.VAT                    AS VAT,
	|		-DD.VATManag                 AS VATManag
	|	FROM
	|		VATAdvancesIssuedTransfersReceipt AS DD
	|
	|	UNION ALL
	|
	|	SELECT
	|		DD.Organization             AS Organization,
	|		DD.DocumentPayments          AS DocumentPayments,
	|		DD.Counterparty              AS Counterparty,
	|		DD.ARAPObject          AS ARAPObject,
	|		DD.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|		DD.Department           AS Department,
	|		DD.LineOfBusiness AS LineOfBusiness,
	|		DD.VATRate               AS VATRate,
	|		CASE
	|			WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN DD.AmountExcludingVAT
	|			ELSE -DD.AmountExcludingVAT
	|		END                      AS AmountExcludingVAT,
	|		CASE
	|			WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN DD.VAT
	|			ELSE -DD.VAT
	|		END                      AS VAT,
	|		CASE
	|			WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN DD.VATManag
	|			ELSE -DD.VATManag
	|		END                      AS VATManag
	|	FROM
	|		VATAdvancesIssuedStorno AS DD
	|
	|	UNION ALL
	|
	|	SELECT
	|		DD.Organization             AS Organization,
	|		DD.DocumentPayments          AS DocumentPayments,
	|		DD.Counterparty              AS Counterparty,
	|		DD.ARAPObject          AS ARAPObject,
	|		DD.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|		DD.Department           AS Department,
	|		DD.LineOfBusiness AS LineOfBusiness,
	|		DD.VATRate               AS VATRate,
	|		CASE
	|			WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN DD.AmountExcludingVAT
	|			ELSE -DD.AmountExcludingVAT
	|		END                      AS AmountExcludingVAT,
	|		CASE
	|			WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN DD.VAT
	|			ELSE -DD.VAT
	|		END                      AS VAT,
	|		CASE
	|			WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN DD.VATManag
	|			ELSE -DD.VATManag
	|		END                      AS VATManag
	|	FROM
	|		VATAdvancesIssuedUnderISF AS DD
	|
	|	UNION ALL
	|
	|	SELECT
	|		DD.Organization              AS Organization,
	|		DD.DocumentPayments           AS DocumentPayments,
	|		DD.Counterparty               AS Counterparty,
	|		DD.ARAPObject           AS ARAPObject,
	|		DD.CorrectedTaxInvoice  AS CorrectedTaxInvoice,
	|		DD.Department            AS Department,
	|		DD.LineOfBusiness  AS LineOfBusiness,
	|		DD.VATRate                AS VATRate,
	|		-DD.AmountExcludingVAT             AS AmountExcludingVAT,
	|		-DD.VAT                     AS VAT,
	|		-DD.VATManag                  AS VATManag
	|	FROM
	|		VATAdvancesIssuedStornoOffsets AS DD
	|	WHERE
	|		DD.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|) AS DeductionFromPrepaymentToVendor
	|
	|GROUP BY
	|	DeductionFromPrepaymentToVendor.Organization,
	|	DeductionFromPrepaymentToVendor.DocumentPayments,
	|	DeductionFromPrepaymentToVendor.Counterparty,
	|	DeductionFromPrepaymentToVendor.ARAPObject,
	|	DeductionFromPrepaymentToVendor.CorrectedTaxInvoice,
	|	DeductionFromPrepaymentToVendor.Department,
	|	DeductionFromPrepaymentToVendor.LineOfBusiness,
	|	DeductionFromPrepaymentToVendor.VATRate
	|HAVING
	|	SUM(DeductionFromPrepaymentToVendor.AmountExcludingVAT)  <> 0
	|		OR SUM(DeductionFromPrepaymentToVendor.VAT)  <> 0
	|
	|INDEX BY
	|	Organization,
	|	DocumentPayments
	|;
	|
	|///////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(CorrectedInvoicesReceivedInAdvance.Ref,InvoicesReceivedInAdvance.Ref) AS Ref,
	|	ISNULL(CorrectedInvoicesReceivedInAdvance.Date, InvoicesReceivedInAdvance.Date) AS Date,
	|	CASE 
	|		WHEN NOT CorrectedInvoicesReceivedInAdvance.Ref IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                          AS Patch,
	|	ISNULL(CorrectedInvoicesReceivedInAdvance.CorrectionDate, DATETIME(1,1,1)) AS CorrectionDate,
	|	VATDeductionAdvancesIssued.Organization             AS Organization,
	|	VATDeductionAdvancesIssued.DocumentPayments          AS DocumentPayments,
	|	VATDeductionAdvancesIssued.Counterparty              AS Counterparty,
	|	VATDeductionAdvancesIssued.ARAPObject          AS ARAPObject,
	|	VATDeductionAdvancesIssued.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|	VATDeductionAdvancesIssued.Department           AS Department,
	|	VATDeductionAdvancesIssued.LineOfBusiness AS LineOfBusiness,
	|	VATDeductionAdvancesIssued.VATRate               AS VATRate,
	|	VATDeductionAdvancesIssued.AmountExcludingVAT             AS AmountExcludingVAT,
	|	VATDeductionAdvancesIssued.VAT                     AS VAT,
	|	VATDeductionAdvancesIssued.VATManag                  AS VATManag
	|FROM
	|	VATDeductionAdvancesIssued AS VATDeductionAdvancesIssued
	|	LEFT JOIN
	|		InvoicesReceivedInAdvance AS InvoicesReceivedInAdvance
	|	ON
	|		VATDeductionAdvancesIssued.Organization = InvoicesReceivedInAdvance.Organization
	|		AND VATDeductionAdvancesIssued.DocumentPayments = InvoicesReceivedInAdvance.DocumentPayments
	|		AND (CASE
	|				WHEN VALUETYPE(VATDeductionAdvancesIssued.DocumentPayments) IN (TYPE(Document.OBEntry),
	|																			TYPE(Document.ExpenseReport))
	|				THEN VATDeductionAdvancesIssued.Counterparty = InvoicesReceivedInAdvance.Counterparty
	|				ELSE TRUE
	|			END)
	|
	|	LEFT JOIN
	|		CorrectedInvoicesReceivedInAdvance AS CorrectedInvoicesReceivedInAdvance
	|	ON
	|		VATDeductionAdvancesIssued.Organization = CorrectedInvoicesReceivedInAdvance.Organization
	|		AND VATDeductionAdvancesIssued.DocumentPayments = CorrectedInvoicesReceivedInAdvance.DocumentPayments
	|		AND (CASE
	|				WHEN VALUETYPE(VATDeductionAdvancesIssued.DocumentPayments) IN (TYPE(Document.OBEntry),
	|																			TYPE(Document.ExpenseReport))
	|					THEN VATDeductionAdvancesIssued.Counterparty = CorrectedInvoicesReceivedInAdvance.Counterparty
	|				ELSE TRUE
	|			END)
	|;
	|
	|//////////////////////////////////////////////////////
	|DROP VATDeductionAdvancesIssued
	|";
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.SetParameter("BeginOfPeriod", CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",  CalculationParameters.EndOfPeriod);
	
	Return Query.Execute().Unload();
	
EndFunction

Function CalculateVATAdvancesIssuedCredits(CalculationParameters)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	OffsetsOfAdvancesIssued.Recorder AS Recorder,
	|	OffsetsOfAdvancesIssued.Period AS Period,
	|	OffsetsOfAdvancesIssued.Organization AS Organization,
	|	OffsetsOfAdvancesIssued.LineOfBusiness AS LineOfBusiness,
	|	OffsetsOfAdvancesIssued.Counterparty AS Counterparty,
	|	OffsetsOfAdvancesIssued.ARAPObject AS ARAPObject,
	|	OffsetsOfAdvancesIssued.DocumentPayments AS DocumentPayments,
	|	OffsetsOfAdvancesIssued.PrepaymentsSettlementDocument AS PrepaymentsSettlementDocument,
	|	OffsetsOfAdvancesIssued.EventSign AS EventSign,
	|	OffsetsOfAdvancesIssued.OffsetAmount_ AS OffsetAmount_,
	|	OffsetsOfAdvancesIssued.ReversingEntry AS ReversingEntry
	|FROM
	|	OffsetsOfAdvancesIssued AS OffsetsOfAdvancesIssued
	|		LEFT JOIN DocumentsForOffsettingAdvancesIssuedStorno AS CreditDocumentsStorno
	|		ON OffsetsOfAdvancesIssued.DocumentPayments = CreditDocumentsStorno.DocumentPayments
	|			AND OffsetsOfAdvancesIssued.ARAPObject = CreditDocumentsStorno.ARAPObject
	|			AND OffsetsOfAdvancesIssued.PrepaymentsSettlementDocument = CreditDocumentsStorno.Document
	|			AND (BEGINOFPERIOD(OffsetsOfAdvancesIssued.Period, MONTH) = BEGINOFPERIOD(CreditDocumentsStorno.Period, MONTH))
	|WHERE
	|	OffsetsOfAdvancesIssued.ReversingEntry <> TRUE
	|	AND CreditDocumentsStorno.Document IS NULL";


	Query.SetParameter("BeginOfPeriod", CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",  CalculationParameters.EndOfPeriod);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	
	ApplyingPrepayments = Query.Execute().Unload(); // ValueTable - 
	ApplyingPrepayments.Indexes.Add("DocumentPayments,LineOfBusiness,ARAPObject");
	ApplyingPrepayments.Indexes.Add("DocumentPayments,LineOfBusiness");
	ApplyingPrepayments.Indexes.Add("DocumentPayments,ARAPObject");
	ApplyingPrepayments.Indexes.Add("DocumentPayments");
	
	VATPrepaymentsToVendor = AccumulationRegisters.VATPrepaymentsToVendor.CreateRecordSet().UnloadColumns();
	VATPrepaymentsToVendor.Columns.Delete("Active");
	VATPrepaymentsToVendor.Columns.Add("Patch", New TypeDescription("Boolean"));
	VATPrepaymentsToVendor.Columns.Add("DateOfAdvancePayment", New TypeDescription("Date"));
	
	If ApplyingPrepayments.Count()>0 Then
		
		TypesWithSelectionByCounterparty = New Array;
		TypesWithSelectionByCounterparty.Add(Type("DocumentRef.OBEntry"));
		TypesWithSelectionByCounterparty.Add(Type("DocumentRef.ExpenseReport"));
		
		VATDeductionFromPrepaymentToVendor = VATDeductionAdvancesIssued(CalculationParameters); // ValueTable -
		VATDeductionFromPrepaymentToVendor.Indexes.Add("DocumentPayments,LineOfBusiness,ARAPObject,Patch,CorrectionDate, Counterparty");
		VATDeductionFromPrepaymentToVendor.Indexes.Add("DocumentPayments,LineOfBusiness,ARAPObject,Patch,CorrectionDate");
		
		DeductionOfNDSSOfIssuedAdvance = VATDeductionFromPrepaymentToVendor.Copy(,"DocumentPayments,Counterparty,LineOfBusiness,ARAPObject,Patch,CorrectionDate"); // ValueTable -
		DeductionOfNDSSOfIssuedAdvance.GroupBy("DocumentPayments,Counterparty,LineOfBusiness,ARAPObject,Patch,CorrectionDate");
		
		AdvancesOnPaymentDocuments = AdvancesIssuedOnPaymentDocuments(CalculationParameters); // ValueTable - 
		AdvancesToPaymentDocuments = AdvancesOnPaymentDocuments.Copy(, "DocumentPayments,Counterparty,Prepayment_,AdvanceMan");
		AdvancesToPaymentDocuments.GroupBy("DocumentPayments,Counterparty", "Prepayment_,AdvanceMan");
		AdvancesToPaymentDocuments.Indexes.Add("DocumentPayments, Counterparty");
		AdvancesToPaymentDocuments.Indexes.Add("DocumentPayments");
		
		StagesOfOffset = New Array;
		StagesOfOffset.Add(New Structure("DocumentPayments,LineOfBusiness,ARAPObject"));
		StagesOfOffset.Add(New Structure("DocumentPayments,ARAPObject"));
		StagesOfOffset.Add(New Structure("DocumentPayments,LineOfBusiness"));
		StagesOfOffset.Add(New Structure("DocumentPayments"));
		
		For Each SelectionStructureOfSetOff In StagesOfOffset Do
			For Each String In DeductionOfNDSSOfIssuedAdvance Do
				
				SelectionByCounterparty = TypesWithSelectionByCounterparty.Find(TypeOf(String.DocumentPayments)) <> Undefined;
				
				SelectingAdvanceLines = New Structure("DocumentPayments");
				If SelectionByCounterparty Then
					SelectingAdvanceLines.Insert("Counterparty");
				EndIf;
				
				FillPropertyValues(SelectingAdvanceLines, String);
				
				AdvanceLines = AdvancesToPaymentDocuments.FindRows(SelectingAdvanceLines);
				If AdvanceLines.Count() = 0 Then
					Continue;
				EndIf;
				AdvanceLine_ = AdvanceLines[0];
							
				AdvanceSelectionStructure = New Structure();
				AdvanceSelectionStructure.Insert("DocumentPayments", String.DocumentPayments);
				AdvanceSelectionStructure.Insert("LineOfBusiness", String.LineOfBusiness);
				AdvanceSelectionStructure.Insert("ARAPObject", String.ARAPObject);
				AdvanceSelectionStructure.Insert("Patch", String.Patch);
				AdvanceSelectionStructure.Insert("CorrectionDate", String.CorrectionDate);
				If SelectionByCounterparty Then
					AdvanceSelectionStructure.Insert("Counterparty", String.Counterparty);
					SelectionStructureOfSetOff.Insert("Counterparty");
				EndIf;
				LinesCalculatingVAT = VATDeductionFromPrepaymentToVendor.FindRows(AdvanceSelectionStructure);
				
				FillPropertyValues(SelectionStructureOfSetOff, AdvanceSelectionStructure);
				LinesOffsettingAdvance = ApplyingPrepayments.FindRows(SelectionStructureOfSetOff);
				If LinesOffsettingAdvance.Count() = 0 Then
					Continue;
				EndIf;
				
				SetOffAdvancePaymentIssued(CalculationParameters, AdvanceLine_, LinesCalculatingVAT, LinesOffsettingAdvance, VATPrepaymentsToVendor, "Credit_");
				
			EndDo;
		EndDo;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	2                                         AS Priority,
	|	VATPrepaymentsToVendor.Recorder             AS Recorder,
	|	VALUE(AccumulationRecordType.Receipt)    AS RecordType,
	|	VATPrepaymentsToVendor.Period                  AS Period,
	|	VATPrepaymentsToVendor.Organization             AS Organization,
	|	VATPrepaymentsToVendor.DocumentPayments          AS DocumentPayments,
	|	VATPrepaymentsToVendor.Counterparty              AS Counterparty,
	|	VATPrepaymentsToVendor.ARAPObject          AS ARAPObject,
	|	VATPrepaymentsToVendor.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|	VATPrepaymentsToVendor.Department           AS Department,
	|	VATPrepaymentsToVendor.LineOfBusiness AS LineOfBusiness,
	|	VATPrepaymentsToVendor.VATRate               AS VATRate,
	|	VATPrepaymentsToVendor.AmountExcludingVAT             AS AmountExcludingVAT,
	|	VATPrepaymentsToVendor.VAT                     AS VAT,
	|	VATPrepaymentsToVendor.VATManag                  AS VATManag,
	|	VATPrepaymentsToVendor.Event                 AS Event,
	|	VATPrepaymentsToVendor.PrepaymentsSettlementDocument    AS PrepaymentsSettlementDocument,
	|	VATPrepaymentsToVendor.PeriodEndTransaction    AS PeriodEndTransaction,
	|	VATPrepaymentsToVendor.FinRecordID  AS FinRecordID,
	|	VATPrepaymentsToVendor.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	VATPrepaymentsToVendor.ReversingEntry                  AS ReversingEntry,
	|	VATPrepaymentsToVendor.Patch             AS Patch,
	|	VATPrepaymentsToVendor.DateOfAdvancePayment        AS DateOfAdvancePayment
	|INTO VATAdvancesIssuedCredits
	|FROM
	|	&VATPrepaymentsToVendor AS VATPrepaymentsToVendor
	|";
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.SetParameter("VATPrepaymentsToVendor", VATPrepaymentsToVendor);
	Query.Execute();
	
	Return "VATAdvancesIssuedCredits";
	
EndFunction

Procedure SetOffAdvancePaymentIssued(CalculationParameters, AdvancePaymentLineForPaymentDocument, AdvancePaymentLinesVATAccrual, AdvanceCreditLines, TableOfVATAdvancesIssued, AllocationOption)
	
	If AdvancePaymentLinesVATAccrual.Count() = 0 Then
		Return;
	EndIf;

	AdvancePaymentAmountWithoutVAT = New Array();
	AdvancePaymentVATAmount = New Array();
	AdvancePaymentAmountOfVATMan = New Array();
	
	AdvancePaymentAmountWithoutVAT_0    = 0;
	AdvanceAmountWithVAT      = 0;
	
	AccrualDate = AdvancePaymentLinesVATAccrual[0].Date;
	Patch = AdvancePaymentLinesVATAccrual[0].Patch;
	CorrectionDate = AdvancePaymentLinesVATAccrual[0].CorrectionDate;
	
	SettlementsDoNotIncludeVAT = False;
	If ValueIsFilled(AdvancePaymentLinesVATAccrual[0].Ref) Then
		SettlementsDoNotIncludeVAT = VATAccountingLocalization.SettlementsDoNotIncludeVAT(Common.ObjectAttributeValue(
			AdvancePaymentLinesVATAccrual[0].Ref, "VATTaxation"));
	EndIf;
	
	For Each AdvanceLine_ In AdvancePaymentLinesVATAccrual Do
		AdvancePaymentAmountWithoutVAT.Add(AdvanceLine_.AmountExcludingVAT);
		AdvancePaymentVATAmount.Add(AdvanceLine_.VAT);
		AdvancePaymentAmountOfVATMan.Add(AdvanceLine_.VATManag);
		
		AdvancePaymentAmountWithoutVAT_0    = AdvancePaymentAmountWithoutVAT_0 + AdvanceLine_.AmountExcludingVAT;
		AdvanceAmountWithVAT      = AdvanceAmountWithVAT + AdvanceLine_.AmountExcludingVAT + AdvanceLine_.VAT;
	EndDo; 
	
	OutstandingAdvanceAmount = AdvancePaymentLineForPaymentDocument.Prepayment_;
	
	For Each RepaidAdvanceOnSF In AdvanceCreditLines Do
		
		If AdvanceAmountWithVAT = 0 Then
			Break;
		EndIf;
		
		If RepaidAdvanceOnSF.OffsetAmount_ = 0 Then
			Continue;
		EndIf;
		
		If SettlementsDoNotIncludeVAT Then
			RepaidAdvanceOnSF.OffsetAmount_ = RepaidAdvanceOnSF.OffsetAmount_ * (1 + VATAccountingERPClientServer.ValueOfVATRate(AdvanceLine_.VATRate)/100);
			OutstandingAdvanceAmount = OutstandingAdvanceAmount * (1 + VATAccountingERPClientServer.ValueOfVATRate(AdvanceLine_.VATRate)/100);
		EndIf;
		
		If AllocationOption = "Credit_" Then
			OutstandingAdvanceAmount = OutstandingAdvanceAmount - RepaidAdvanceOnSF.OffsetAmount_;
		EndIf;

		//Selection of extra advance credits
		DateOfAdvancePayment = RepaidAdvanceOnSF.Period;
		
		If Not Patch And DateOfAdvancePayment < CalculationParameters.BeginOfPeriod Then
			Continue;
		EndIf;
		
		If Patch 
			 And DateOfAdvancePayment < CalculationParameters.BeginOfPeriod
			 And CorrectionDate < CalculationParameters.BeginOfPeriod Then
			Continue;
		EndIf;
		
		If AllocationOption = "Credit_" And AccrualDate > DateOfAdvancePayment Then
			Continue;
		EndIf;
		
		If AllocationOption <> "Credit_" And
			BegOfDay(DateOfAdvancePayment) = BegOfDay(AccrualDate) Then
			// Transfers of the advance on the day of accrual are not taken into account, because they are already taken into account in the SF for the advance.
			Continue;
		EndIf;
		
		OffsetAmount_ = RepaidAdvanceOnSF.OffsetAmount_;
		
		AmountIncludingVAT = Min(OffsetAmount_, AdvanceAmountWithVAT);
		If AllocationOption = "Credit_" Then
			BalanceOfAdvanceAmountWithVAT = (AdvanceAmountWithVAT - AmountIncludingVAT);
			If BalanceOfAdvanceAmountWithVAT > OutstandingAdvanceAmount Then
				// We will adjust the amount from which the recovery is performed, taking into account the remainder of the outstanding advance.
				AmountIncludingVAT = AmountIncludingVAT + (BalanceOfAdvanceAmountWithVAT - OutstandingAdvanceAmount);
			EndIf;
		EndIf;
		
		If AmountIncludingVAT = 0 Then
			Continue;
		EndIf;
		
		AmountExcludingVAT    = Round(AdvancePaymentAmountWithoutVAT_0 * AmountIncludingVAT / AdvanceAmountWithVAT, 2);
		VATAmount       = AmountIncludingVAT - AmountExcludingVAT; 
		
		If AllocationOption = "Credit_" Then
			AdvancePaymentAmountWithoutVAT_0 = AdvancePaymentAmountWithoutVAT_0 - AmountExcludingVAT;
			AdvanceAmountWithVAT   = AdvanceAmountWithVAT - AmountIncludingVAT;
		EndIf;
		
		SignMultiplier = ?(RepaidAdvanceOnSF.ReversingEntry, -1, 1);
		
		If SignMultiplier * AmountExcludingVAT > 0 Then
			TotalAmountWithoutVAT = TMCommonUseClientServer.DistributeProportionally(AmountExcludingVAT, AdvancePaymentAmountWithoutVAT);
		EndIf;
		
		If SignMultiplier * VATAmount > 0 Then
			ArrayVATAmount = TMCommonUseClientServer.DistributeProportionally(VATAmount, AdvancePaymentVATAmount);
		EndIf; 
		
		Counter = -1;
		
		For Each AdvanceLine_ In AdvancePaymentLinesVATAccrual Do
			
			Counter = Counter + 1;
			
			Result_AmountWithoutVAT = ?(SignMultiplier * AmountExcludingVAT > 0, TotalAmountWithoutVAT[Counter], 0);
			_ndsResult = ?(SignMultiplier * VATAmount > 0, ArrayVATAmount[Counter], 0);
			
			If Result_AmountWithoutVAT = 0 
				 And _ndsResult = 0 Then
				Continue;
			EndIf;
			
			ResultString1 = TableOfVATAdvancesIssued.Add();
			
			FillPropertyValues(ResultString1, AdvanceLine_, StrConcat(CalculationParameters.ArrayOfRegisterMeasurements, ","));
			
			ResultString1.Recorder = AdvanceLine_.Ref;
			ResultString1.Patch = Patch;
			ResultString1.DateOfAdvancePayment = DateOfAdvancePayment;
			ResultString1.PrepaymentsSettlementDocument = RepaidAdvanceOnSF.PrepaymentsSettlementDocument;
			ResultString1.PeriodEndTransaction = True;
			ResultString1.BusinessTransactionSetting = Catalogs.BusinessTransactionsSettings.ReverseVATFromPrepayment;
			ResultString1.ReversingEntry = RepaidAdvanceOnSF.ReversingEntry;
			
			If Patch Then
				ResultString1.Period = Max(CorrectionDate, Max(DateOfAdvancePayment, CalculationParameters.BeginOfPeriod));
			Else
				ResultString1.Period = Max(AccrualDate, Max(DateOfAdvancePayment, CalculationParameters.BeginOfPeriod));
			EndIf;

			If AllocationOption <> "Credit_" Then
				If AllocationOption = "Expense" Then
					ResultString1.LineOfBusiness = RepaidAdvanceOnSF.LineOfBusiness;
					ResultString1.Department = RepaidAdvanceOnSF.Department;
					ResultString1.ARAPObject = RepaidAdvanceOnSF.ARAPObject;
					ResultString1.Counterparty = RepaidAdvanceOnSF.Counterparty;
				Else
					ResultString1.LineOfBusiness = AdvanceLine_.LineOfBusiness;
					ResultString1.Department = AdvanceLine_.Department;
					ResultString1.ARAPObject = AdvanceLine_.ARAPObject;
					ResultString1.Counterparty = AdvanceLine_.Counterparty;
				EndIf;
			EndIf;
			
			If AllocationOption <> "Credit_" Then
				ResultString1.FinRecordID = RepaidAdvanceOnSF.FinRecordID;
			Else
				ResultString1.FinRecordID = String(New UUID());
			EndIf;
						
			ResultString1.AmountExcludingVAT = Result_AmountWithoutVAT;
			ResultString1.VAT = _ndsResult;
			// We will set off VAT upr. in proportion to VAT regl.
			If ResultString1.VAT <> 0
					And (AdvanceLine_.VATManag <> 0 Or AllocationOption <> "Credit_") Then
					
				If AllocationOption <> "Credit_" And RepaidAdvanceOnSF.OffsetAmount_<>0 Then
					ResultString1.VATManag = RepaidAdvanceOnSF.ManSCreditAmount * ResultString1.VAT/RepaidAdvanceOnSF.OffsetAmount_;
				Else
					CoefficientsOfDistributionOfVATMan = New Array;
					CoefficientsOfDistributionOfVATMan.Add(ResultString1.VAT);
					CoefficientsOfDistributionOfVATMan.Add(AdvanceLine_.VAT - ResultString1.VAT);
					ArrayOfVATMan = TMCommonUseClientServer.DistributeProportionally(AdvanceLine_.VATManag, CoefficientsOfDistributionOfVATMan);
					ResultString1.VATManag = ArrayOfVATMan[0];
				EndIf;
			EndIf;
			
			TypesOfOperationsOfAdvanceTransfer = New Array;
			TypesOfOperationsOfAdvanceTransfer.Add(Enums.KindsOfARAPSettlements.CustomerPrepaymentOffsetBetweenTwoCompanies);
			TypesOfOperationsOfAdvanceTransfer.Add(Enums.KindsOfARAPSettlements.PrepaymentToVendorOffsetBetweenTwoCompanies);
			
			If TypeOf(RepaidAdvanceOnSF.PrepaymentsSettlementDocument) = Type("DocumentRef.ARAPSettlement")
				And TypesOfOperationsOfAdvanceTransfer.Find(Common.ObjectAttributeValue(RepaidAdvanceOnSF.PrepaymentsSettlementDocument, "OperationKind")) <> Undefined Then
				ResultString1.Event = Enums.EventsVATFromPrepayments.SettlementOfPrepayment;
			ElsIf TypeOf(RepaidAdvanceOnSF.PrepaymentsSettlementDocument) = Type("DocumentRef.ReversingEntry") Then
				ResultString1.Event = Enums.EventsVATFromPrepayments.ReverseOnPrepaymentSettlement;
			ElsIf RepaidAdvanceOnSF.EventSign < 0 Then
				ResultString1.Event = Enums.EventsVATFromPrepayments.ReverseOnPrepaymentRefund;
			Else
				ResultString1.Event = Enums.EventsVATFromPrepayments.ReverseOnPrepaymentSettlement;
			EndIf;
			
			// We will reduce the amounts in the initial lines of the advance and the offset of the advance by the credited amount.
			AdvanceLine_.AmountExcludingVAT = AdvanceLine_.AmountExcludingVAT - ResultString1.AmountExcludingVAT;
			AdvanceLine_.VAT = AdvanceLine_.VAT - ResultString1.VAT;
			AdvanceLine_.VATManag = AdvanceLine_.VATManag - ResultString1.VATManag;
			
			RepaidAdvanceOnSF.OffsetAmount_ = RepaidAdvanceOnSF.OffsetAmount_ - (ResultString1.AmountExcludingVAT + ResultString1.VAT);
			If SettlementsDoNotIncludeVAT Then
				AdvancePaymentLineForPaymentDocument.Prepayment_ = AdvancePaymentLineForPaymentDocument.Prepayment_ - ResultString1.AmountExcludingVAT;
			Else
				AdvancePaymentLineForPaymentDocument.Prepayment_ = AdvancePaymentLineForPaymentDocument.Prepayment_ - (ResultString1.AmountExcludingVAT + ResultString1.VAT);
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

Function CalculateVATRecordsAdvancesIssuedSaving(CalculationParameters, TableNamesOfVATRecordAdvancesIssued)
	
	ArrayOfTextsLoggersRecord = New Array;
	ArrayOfTextsLoggersRecord.Add("
	|SELECT DISTINCT
	|	UNDEFINED AS Recorder
	|INTO LoggersRecord
	|WHERE
	|	FALSE");
	
	QueryTemplate = 
	"SELECT DISTINCT
	|	VATPrepaymentsToVendor.Recorder
	|FROM
	|	&TableName AS VATPrepaymentsToVendor";
	For Each NameOfRecordTable In TableNamesOfVATRecordAdvancesIssued Do
		QueryText = StrReplace(QueryTemplate, "&TableName", NameOfRecordTable);
		ArrayOfTextsLoggersRecord.Add(QueryText);
	EndDo;
	
	ArrayOfTextsLoggersRecord.Add("
	|SELECT DISTINCT
	|	VATPrepaymentsToVendor.Recorder
	|FROM
	|	CurRegistrarsVATAdvancesIssued AS VATPrepaymentsToVendor");

	TextLoggersRecord = StrConcat(ArrayOfTextsLoggersRecord, TMCommonUse.QuerySeparatorInJoin(True));
	TextLoggersRecord = TextLoggersRecord +
	"
	|INDEX BY
	|	Recorder";
	
	QueryTextSave =
	"SELECT
	|	0                                                 AS Priority,
	|	VATPrepaymentsToVendor.Period                          AS Period,
	|	VATPrepaymentsToVendor.Recorder                     AS Recorder,
	|	VATPrepaymentsToVendor.RecordType                     AS RecordType,
	|	VATPrepaymentsToVendor.Organization                     AS Organization,
	|	VATPrepaymentsToVendor.DocumentPayments                  AS DocumentPayments,
	|	VATPrepaymentsToVendor.Counterparty                      AS Counterparty,
	|	VATPrepaymentsToVendor.ARAPObject                  AS ARAPObject,
	|	VATPrepaymentsToVendor.CorrectedTaxInvoice         AS CorrectedTaxInvoice,
	|	VATPrepaymentsToVendor.Department                   AS Department,
	|	VATPrepaymentsToVendor.LineOfBusiness         AS LineOfBusiness,
	|	VATPrepaymentsToVendor.VATRate                       AS VATRate,
	|	VATPrepaymentsToVendor.AmountExcludingVAT                     AS AmountExcludingVAT,
	|	VATPrepaymentsToVendor.VAT                             AS VAT,
	|	VATPrepaymentsToVendor.VATManag                          AS VATManag,
	|	VATPrepaymentsToVendor.Event                         AS Event,
	|	VATPrepaymentsToVendor.PrepaymentsSettlementDocument            AS PrepaymentsSettlementDocument,
	|	VATPrepaymentsToVendor.PeriodEndTransaction            AS PeriodEndTransaction,
	|	VATPrepaymentsToVendor.FinRecordID          AS FinRecordID,
	|	VATPrepaymentsToVendor.BusinessTransactionSetting  AS BusinessTransactionSetting,
	|	VATPrepaymentsToVendor.ReversingEntry                          AS ReversingEntry
	|INTO VATAdvancesIssuedToCustomers
	|FROM
	|	AccumulationRegister.VATPrepaymentsToVendor AS VATPrepaymentsToVendor
	|	
	|	INNER JOIN
	|		LoggersRecord AS LoggersRecord
	|	ON 
	|		VATPrepaymentsToVendor.Recorder = LoggersRecord.Recorder
	|	
	|	LEFT JOIN
	|		Jobs AS Jobs
	|	ON
	|		Jobs.Organization = VATPrepaymentsToVendor.Organization
	|		AND Jobs.TaxInvoice = VATPrepaymentsToVendor.DocumentPayments
	|WHERE
	|	VATPrepaymentsToVendor.Period < &BeginOfPeriod
	|		OR VATPrepaymentsToVendor.Period > &EndOfPeriod
	|		OR NOT VATPrepaymentsToVendor.PeriodEndTransaction
	|		OR Jobs.TaxInvoice IS NULL
	|;
	|
	|/////////////////////////////////////////////
	|DROP LoggersRecord
	|";

	Query = New Query;
	Query.Text = TextLoggersRecord + Common.QueryBatchSeparator() + QueryTextSave;
	Query.SetParameter("BeginOfPeriod",     CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",      CalculationParameters.EndOfPeriod);
	Query.SetParameter("CompanyArray", CalculationParameters.CompanyArray);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	
	Query.Execute();
	
	Return "VATAdvancesIssuedToCustomers";
	
EndFunction

Procedure RecordVATAdvancesIssued(CalculationParameters, TableNamesOfVATRecordAdvancesIssued)
	
	ArrayOfDataTexts = New Array;
	QueryTemplate = 
	"SELECT
	|	VATPrepaymentsToVendor.Priority                       AS Priority,
	|	VATPrepaymentsToVendor.Period                          AS Period,
	|	VATPrepaymentsToVendor.Recorder                     AS Recorder,
	|	VATPrepaymentsToVendor.RecordType                     AS RecordType,
	|	VATPrepaymentsToVendor.Organization                     AS Organization,
	|	VATPrepaymentsToVendor.DocumentPayments                  AS DocumentPayments,
	|	VATPrepaymentsToVendor.Counterparty                      AS Counterparty,
	|	VATPrepaymentsToVendor.ARAPObject                  AS ARAPObject,
	|	VATPrepaymentsToVendor.CorrectedTaxInvoice         AS CorrectedTaxInvoice,
	|	VATPrepaymentsToVendor.Department                   AS Department,
	|	VATPrepaymentsToVendor.LineOfBusiness         AS LineOfBusiness,
	|	VATPrepaymentsToVendor.VATRate                       AS VATRate,
	|	VATPrepaymentsToVendor.AmountExcludingVAT                     AS AmountExcludingVAT,
	|	VATPrepaymentsToVendor.VAT                             AS VAT,
	|	VATPrepaymentsToVendor.VATManag                          AS VATManag,
	|	VATPrepaymentsToVendor.Event                         AS Event,
	|	VATPrepaymentsToVendor.PrepaymentsSettlementDocument            AS PrepaymentsSettlementDocument,
	|	VATPrepaymentsToVendor.PeriodEndTransaction            AS PeriodEndTransaction,
	|	VATPrepaymentsToVendor.FinRecordID          AS FinRecordID,
	|	VATPrepaymentsToVendor.BusinessTransactionSetting  AS BusinessTransactionSetting,
	|	VATPrepaymentsToVendor.ReversingEntry                          AS ReversingEntry
	|FROM
	|	&VATPrepaymentsToVendor AS VATPrepaymentsToVendor";
	For Each NameOfRecordTable In TableNamesOfVATRecordAdvancesIssued Do
		QueryText = StrReplace(QueryTemplate, "&VATPrepaymentsToVendor", NameOfRecordTable);
		ArrayOfDataTexts.Add(QueryText);
	EndDo;
	TextDataToWrite = StrConcat(ArrayOfDataTexts, TMCommonUse.QuerySeparatorInJoin());
	
	Query = New Query;
	Query.Text = 
		TextDataToWrite
		+ "
		|                            
		|
		|ORDER BY
		|	Recorder,
		|	Period,
		|	Priority
		|
		|TOTALS BY
		|	Recorder
		|";
	
	Query.SetParameter("BeginOfPeriod",     CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",      CalculationParameters.EndOfPeriod);
	Query.SetParameter("CompanyArray", CalculationParameters.CompanyArray);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	
	SampleDocument = Query.Execute().Select(QueryResultIteration.ByGroups);
	
	While SampleDocument.Next() Do
		
		RecordSet = AccumulationRegisters.VATPrepaymentsToVendor.CreateRecordSet();
		RecordSet.Filter.Recorder.Set(SampleDocument.Recorder);
		
		// The dates of the ban are not checked, because we get here when performing tasks, 
		// and when creating tasks, the dates of the ban are controlled. 
		RecordSet.AdditionalProperties.Insert("SkipPeriodClosingCheck", True);
		
		Selection = SampleDocument.Select();
		While Selection.Next() Do
			
			NewRecord = RecordSet.Add();
			FillPropertyValues(NewRecord, Selection);
			
		EndDo;
		
		RecordSet.Write();
		
	EndDo;
	
EndProcedure

Procedure ClearVATAdvancesIssued(CalculationParameters, TableNamesOfVATRecordAdvancesIssued)
	
	ArrayOfTextsLoggersRecord = New Array;
	ArrayOfTextsLoggersRecord.Add("
	|SELECT DISTINCT
	|	UNDEFINED AS Recorder
	|INTO LoggersRecord
	|WHERE
	|	FALSE");
	
	QueryTemplate = 
	"SELECT DISTINCT
	|	VATPrepaymentsToVendor.Recorder
	|FROM
	|	&TableName AS VATPrepaymentsToVendor";
	For Each NameOfRecordTable In TableNamesOfVATRecordAdvancesIssued Do
		QueryText = StrReplace(QueryTemplate, "&TableName", NameOfRecordTable);
		ArrayOfTextsLoggersRecord.Add(QueryText);
	EndDo;
	TextLoggersRecord = StrConcat(ArrayOfTextsLoggersRecord, TMCommonUse.QuerySeparatorInJoin(True));
	TextLoggersRecord = TextLoggersRecord +
	"
	|INDEX BY
	|	Recorder";
	
	TextObsoleteLoggers = 
	"SELECT
	|	OutdatedLoggers.Recorder
	|FROM
	|	CurRegistrarsVATAdvancesIssued AS OutdatedLoggers
	|	LEFT JOIN
	|		LoggersRecord AS LoggersRecord
	|	ON
	|		OutdatedLoggers.Recorder = LoggersRecord.Recorder
	|
	|WHERE
	|	LoggersRecord.Recorder IS NULL
	|;
	|
	|//////////////////////////////////////////////
	|DROP LoggersRecord
	|";
	
	Query = New Query;
	Query.Text = TextLoggersRecord + Common.QueryBatchSeparator() + TextObsoleteLoggers;;
	
	Query.SetParameter("BeginOfPeriod",     CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",  CalculationParameters.EndOfPeriod);
	Query.SetParameter("CompanyArray", CalculationParameters.CompanyArray);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	
	SampleDocument = Query.Execute().Select();
	While SampleDocument.Next() Do
		
		RecordSet = AccumulationRegisters.VATPrepaymentsToVendor.CreateRecordSet();
		RecordSet.Filter.Recorder.Set(SampleDocument.Recorder);
		RecordSet.Write(True);
		
	EndDo;

EndProcedure

Procedure GetBalanceOfAdvancesIssuedBeforeTransfer(CalculationParameters)
	
	AdvanceCalculationParameters = InitializeParametersForPreparationOfAdvancePaymentsForVATPurposes();
	
	//For ISF, it is necessary to calculate the repayment data starting from the date of the payment document
	ThereIsISF = Not CalculationParameters.TempTablesManager.Tables["CorrectedInvoicesReceivedAdvanceRecalculation"].GetData().IsEmpty();
	If ThereIsISF Then
		
		Query = New Query;
		Query.TempTablesManager = CalculationParameters.TempTablesManager;
		Query.Text =
		"SELECT
		|	Jobs.TaxInvoice AS DocumentPayments
		|INTO PaymentDocuments
		|FROM
		|	Jobs AS Jobs
		|		LEFT JOIN CorrectedInvoicesReceivedAdvanceRecalculation AS CorrectedInvoicesReceivedInAdvance
		|		ON Jobs.Organization = CorrectedInvoicesReceivedInAdvance.Organization
		|			AND Jobs.TaxInvoice = CorrectedInvoicesReceivedInAdvance.DocumentPayments
		|WHERE
		|	CorrectedInvoicesReceivedInAdvance.DocumentPayments IS NULL";
		
		Query.Execute();
			
		AdvanceCalculationParameters.StartDate                                            = CalculationParameters.BeginOfPeriod;
		AdvanceCalculationParameters.EndDate                                         = CalculationParameters.EndOfPeriod;
		AdvanceCalculationParameters.Companies                                           = CalculationParameters.CompanyArray;
		AdvanceCalculationParameters.EnableGiftCertificateData                  = True;
		AdvanceCalculationParameters.SelectionParametersForSettlementDocument.SelectionTableName_ = "PaymentDocuments";
		AdvanceCalculationParameters.SelectionParametersForSettlementDocument.FieldName          = "DocumentPayments";
	
		PrepareVT_BalancesAdvancesIssuedBeforeTransfer(
			CalculationParameters.TempTablesManager,
			AdvanceCalculationParameters,
			CalculationParameters.SettingsTable);

		Query = New Query;
		Query.TempTablesManager = CalculationParameters.TempTablesManager;
		Query.Text =
		"SELECT
		|	Balance.Organization             AS Organization,
		|	Balance.DocumentPayments          AS DocumentPayments,
		|	Balance.Counterparty              AS Counterparty,
		|	Balance.CorrectedTaxInvoice AS CorrectedTaxInvoice,
		|	Balance.Department           AS Department,
		|	Balance.LineOfBusiness AS LineOfBusiness,
		|	Balance.ARAPObject          AS ARAPObject,
		|	Balance.VATRate               AS VATRate,
		|	Balance.AmountExcludingVAT             AS AmountExcludingVAT,
		|	Balance.VAT                     AS VAT,
		|	Balance.VATManag                  AS VATManag
		|INTO BalancesAdvancesIssuedBeforeTransferInterim
		|FROM
		|	BalancesAdvancesIssuedBeforeTransfer AS Balance
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP BalancesAdvancesIssuedBeforeTransfer
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP PaymentDocuments
		|;
		|";

		Query.Execute();
		
		AdvanceCalculationParameters.StartDate                                            = CalculationParameters.ISFBeginningOfPeriod;
		AdvanceCalculationParameters.EndDate                                         = CalculationParameters.EndOfPeriod;
		AdvanceCalculationParameters.SelectionParametersForSettlementDocument.SelectionTableName_ = "CorrectedInvoicesReceivedAdvanceRecalculation";
		AdvanceCalculationParameters.SelectionParametersForSettlementDocument.FieldName          = "DocumentPayments";
	
		PrepareVT_BalancesAdvancesIssuedBeforeTransfer(
			CalculationParameters.TempTablesManager,
			AdvanceCalculationParameters,
			CalculationParameters.SettingsTable);
		
		Query.Text =
		"SELECT
		|	Balance.Organization             AS Organization,
		|	Balance.DocumentPayments          AS DocumentPayments,
		|	Balance.Counterparty              AS Counterparty,
		|	Balance.CorrectedTaxInvoice AS CorrectedTaxInvoice,
		|	Balance.Department           AS Department,
		|	Balance.LineOfBusiness AS LineOfBusiness,
		|	Balance.ARAPObject          AS ARAPObject,
		|	Balance.VATRate               AS VATRate,
		|	Balance.AmountExcludingVAT             AS AmountExcludingVAT,
		|	Balance.VAT                     AS VAT,
		|	Balance.VATManag                  AS VATManag
		|INTO BalancesAdvancesIssuedBeforeTransferTotal
		|FROM
		|	BalancesAdvancesIssuedBeforeTransferInterim AS Balance
		|
		|UNION ALL
		|
		|SELECT
		|	Balance.Organization             AS Organization,
		|	Balance.DocumentPayments          AS DocumentPayments,
		|	Balance.Counterparty              AS Counterparty,
		|	Balance.CorrectedTaxInvoice AS CorrectedTaxInvoice,
		|	Balance.Department           AS Department,
		|	Balance.LineOfBusiness AS LineOfBusiness,
		|	Balance.ARAPObject          AS ARAPObject,
		|	Balance.VATRate               AS VATRate,
		|	Balance.AmountExcludingVAT             AS AmountExcludingVAT,
		|	Balance.VAT                     AS VAT,
		|	Balance.VATManag                  AS VATManag
		|FROM
		|	BalancesAdvancesIssuedBeforeTransfer AS Balance
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP BalancesAdvancesIssuedBeforeTransferInterim
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP BalancesAdvancesIssuedBeforeTransfer
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Balance.Organization             AS Organization,
		|	Balance.DocumentPayments          AS DocumentPayments,
		|	Balance.Counterparty              AS Counterparty,
		|	Balance.CorrectedTaxInvoice AS CorrectedTaxInvoice,
		|	Balance.Department           AS Department,
		|	Balance.LineOfBusiness AS LineOfBusiness,
		|	Balance.ARAPObject          AS ARAPObject,
		|	Balance.VATRate               AS VATRate,
		|	Balance.AmountExcludingVAT             AS AmountExcludingVAT,
		|	Balance.VAT                     AS VAT,
		|	Balance.VATManag                  AS VATManag
		|INTO BalancesAdvancesIssuedBeforeTransfer
		|FROM
		|	BalancesAdvancesIssuedBeforeTransferTotal AS Balance
		|
		|INDEX BY
		|	Organization,
		|	DocumentPayments,
		|	Counterparty
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP BalancesAdvancesIssuedBeforeTransferTotal
		|";

		Query.Execute();

	Else
			
		AdvanceCalculationParameters.StartDate                                            = CalculationParameters.BeginOfPeriod;
		AdvanceCalculationParameters.EndDate                                         = CalculationParameters.EndOfPeriod;
		AdvanceCalculationParameters.Companies                                           = CalculationParameters.CompanyArray;
		AdvanceCalculationParameters.EnableGiftCertificateData                  = True;
		AdvanceCalculationParameters.SelectionParametersForSettlementDocument.SelectionTableName_ = "ExpansionOfARAPTransactionTable";
		AdvanceCalculationParameters.SelectionParametersForSettlementDocument.FieldName          = "OriginalARAPTransactionDocument";
		
		PrepareVT_BalancesAdvancesIssuedBeforeTransfer(
			CalculationParameters.TempTablesManager,
			AdvanceCalculationParameters,
			CalculationParameters.SettingsTable);

	EndIf; 
	
EndProcedure

Function CalculateVATAdvancesIssuedTransfersExpenses(CalculationParameters)
	
	GetBalanceOfAdvancesIssuedBeforeTransfer(CalculationParameters);

	AdvanceCalculationParameters = InitializeParametersForPreparationOfAdvancePaymentsForVATPurposes();
	
	AdvanceCalculationParameters.StartDate                                            = CalculationParameters.BeginOfPeriod;
	AdvanceCalculationParameters.EndDate                                         = CalculationParameters.EndOfPeriod;
	AdvanceCalculationParameters.Companies                                           = CalculationParameters.CompanyArray;
	AdvanceCalculationParameters.EnableGiftCertificateData                  = True;
	AdvanceCalculationParameters.IncludeFinancialInstrumentData                  = True;
	AdvanceCalculationParameters.SelectionParametersForSettlementDocument.SelectionTableName_ = "Jobs";
	AdvanceCalculationParameters.SelectionParametersForSettlementDocument.FieldName          = "TaxInvoice";
	
	PrepareVT_TransfersOfAdvancesIssued(
			CalculationParameters.TempTablesManager,
			AdvanceCalculationParameters,
			CalculationParameters.SettingsTable);
			
	//For ISF, it is necessary to calculate the repayment data starting from the date of the payment document
	ThereIsISF = Not CalculationParameters.TempTablesManager.Tables["CorrectedInvoicesReceivedAdvanceRecalculation"].GetData().IsEmpty();
	If ThereIsISF Then

		Query = New Query;
		Query.TempTablesManager = CalculationParameters.TempTablesManager;
		Query.Text =
		"SELECT
		|	DD.Organization                    AS Organization,
		|	DD.TransferDocument               AS TransferDocument,
		|	DD.DocumentPayments                 AS DocumentPayments,
		|	DD.AccountingDimensionByPartners      AS AccountingDimensionByPartners,
		|	DD.ARAPObject                 AS ARAPObject,
		|	DD.Counterparty                     AS Counterparty,
		|	DD.LineOfBusiness        AS LineOfBusiness,
		|	DD.Department                  AS Department,
		|	DD.CorPartnerAccountingDimension   AS CorPartnerAccountingDimension,
		|	DD.CorARAPObject              AS CorARAPObject,
		|	DD.CorCounterparty                  AS CorCounterparty,
		|	DD.CorLineOfBusiness     AS CorLineOfBusiness,
		|	DD.DebitBusinessUnit               AS DebitBusinessUnit,
		|	DD.Period                         AS Period,
		|	DD.BusinessTransactionSetting AS BusinessTransactionSetting,
		|	DD.FinRecordID         AS FinRecordID,
		|	DD.ReversingEntry                         AS ReversingEntry,
		|	DD.Currency                         AS Currency,
		|	DD.Prepayment                     AS Prepayment,
		|	DD.PrepaymentLocal                 AS PrepaymentLocal,
		|	DD.PrepaymentMan                  AS PrepaymentMan
		|INTO TransfersOfAdvancesInterim
		|FROM
		|	TransfersOfAdvancesIssued AS DD
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TransfersOfAdvancesIssued
		|;
		|";

		Query.Execute();
		
		AdvanceCalculationParameters.StartDate                                            = CalculationParameters.ISFBeginningOfPeriod;
		AdvanceCalculationParameters.EndDate                                         = CalculationParameters.ISFEndOfPeriod;
		AdvanceCalculationParameters.SelectionParametersForSettlementDocument.SelectionTableName_ = "CorrectedInvoicesReceivedAdvanceRecalculation";
		AdvanceCalculationParameters.SelectionParametersForSettlementDocument.FieldName          = "DocumentPayments";
	
		PrepareVT_TransfersOfAdvancesIssued(
			CalculationParameters.TempTablesManager,
			AdvanceCalculationParameters,
			CalculationParameters.SettingsTable);
			
		Query.Text =
		"SELECT
		|	DD.Organization AS Organization,
		|	DD.TransferDocument AS TransferDocument,
		|	DD.DocumentPayments AS DocumentPayments,
		|	DD.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	DD.ARAPObject AS ARAPObject,
		|	DD.Counterparty AS Counterparty,
		|	DD.LineOfBusiness AS LineOfBusiness,
		|	DD.Department AS Department,
		|	DD.CorPartnerAccountingDimension AS CorPartnerAccountingDimension,
		|	DD.CorARAPObject AS CorARAPObject,
		|	DD.CorCounterparty AS CorCounterparty,
		|	DD.CorLineOfBusiness AS CorLineOfBusiness,
		|	DD.DebitBusinessUnit AS DebitBusinessUnit,
		|	DD.Period AS Period,
		|	DD.BusinessTransactionSetting AS BusinessTransactionSetting,
		|	DD.FinRecordID AS FinRecordID,
		|	DD.ReversingEntry AS ReversingEntry,
		|	DD.Currency AS Currency,
		|	DD.Prepayment AS Prepayment,
		|	DD.PrepaymentLocal AS PrepaymentLocal,
		|	DD.PrepaymentMan AS PrepaymentMan
		|INTO TransfersOfAdvancesTotal
		|FROM
		|	TransfersOfAdvancesInterim AS DD
		|
		|UNION ALL
		|
		|SELECT
		|	DD.Organization,
		|	DD.TransferDocument,
		|	DD.DocumentPayments,
		|	DD.AccountingDimensionByPartners,
		|	DD.ARAPObject,
		|	DD.Counterparty,
		|	DD.LineOfBusiness,
		|	DD.Department,
		|	DD.CorPartnerAccountingDimension,
		|	DD.CorARAPObject,
		|	DD.CorCounterparty,
		|	DD.CorLineOfBusiness,
		|	DD.DebitBusinessUnit,
		|	DD.Period,
		|	DD.BusinessTransactionSetting,
		|	DD.FinRecordID,
		|	DD.ReversingEntry,
		|	DD.Currency,
		|	DD.Prepayment,
		|	DD.PrepaymentLocal,
		|	DD.PrepaymentMan
		|FROM
		|	TransfersOfAdvancesIssued AS DD
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TransfersOfAdvancesInterim
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TransfersOfAdvancesIssued
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DD.Organization AS Organization,
		|	DD.TransferDocument AS TransferDocument,
		|	DD.DocumentPayments AS DocumentPayments,
		|	DD.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	DD.ARAPObject AS ARAPObject,
		|	DD.Counterparty AS Counterparty,
		|	DD.LineOfBusiness AS LineOfBusiness,
		|	DD.Department AS Department,
		|	DD.CorPartnerAccountingDimension AS CorPartnerAccountingDimension,
		|	DD.CorARAPObject AS CorARAPObject,
		|	DD.CorCounterparty AS CorCounterparty,
		|	DD.CorLineOfBusiness AS CorLineOfBusiness,
		|	DD.DebitBusinessUnit AS DebitBusinessUnit,
		|	DD.Period AS Period,
		|	DD.BusinessTransactionSetting AS BusinessTransactionSetting,
		|	DD.FinRecordID AS FinRecordID,
		|	DD.ReversingEntry AS ReversingEntry,
		|	DD.Currency AS Currency,
		|	DD.Prepayment AS Prepayment,
		|	DD.PrepaymentLocal AS PrepaymentLocal,
		|	DD.PrepaymentMan AS PrepaymentMan
		|INTO TransfersOfAdvancesIssued
		|FROM
		|	TransfersOfAdvancesTotal AS DD
		|
		|INDEX BY
		|	Organization,
		|	DocumentPayments
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TransfersOfAdvancesTotal";

		Query.Execute();

	EndIf;

	Query = New Query;
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.Text = 
	"SELECT
	|	ISNULL(CorrectedInvoicesReceivedInAdvance.Ref, InvoicesReceivedInAdvance.Ref) AS Ref,
	|	ISNULL(CorrectedInvoicesReceivedInAdvance.Date, InvoicesReceivedInAdvance.Date) AS Date,
	|	CASE
	|		WHEN NOT CorrectedInvoicesReceivedInAdvance.Ref IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                                                             AS Patch,
	|	ISNULL(CorrectedInvoicesReceivedInAdvance.CorrectionDate, DATETIME(1,1,1)) AS CorrectionDate,
	|	DD.Organization AS Organization,
	|	DD.DocumentPayments AS DocumentPayments,
	|	DD.Counterparty AS Counterparty,
	|	DD.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|	DD.Department AS Department,
	|	DD.LineOfBusiness AS LineOfBusiness,
	|	DD.ARAPObject AS ARAPObject,
	|	DD.VATRate AS VATRate,
	|	DD.AmountExcludingVAT AS AmountExcludingVAT,
	|	DD.VAT AS VAT,
	|	DD.VATManag AS VATManag
	|FROM
	|	BalancesAdvancesIssuedBeforeTransfer AS DD
	|	LEFT JOIN
	|		InvoicesReceivedInAdvance AS InvoicesReceivedInAdvance
	|	ON
	|		DD.Organization = InvoicesReceivedInAdvance.Organization
	|		AND DD.DocumentPayments = InvoicesReceivedInAdvance.DocumentPayments
	|		AND DD.Counterparty = InvoicesReceivedInAdvance.Counterparty
	|
	|	LEFT JOIN
	|		CorrectedInvoicesReceivedInAdvance AS CorrectedInvoicesReceivedInAdvance
	|	ON
	|		DD.Organization = CorrectedInvoicesReceivedInAdvance.Organization
	|		AND DD.DocumentPayments = CorrectedInvoicesReceivedInAdvance.DocumentPayments
	|		AND DD.Counterparty = CorrectedInvoicesReceivedInAdvance.Counterparty
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	1 AS EventSign,
	|	DD.Period AS Period,
	|	DD.Counterparty AS Counterparty,
	|	DD.Department AS Department,
	|	DD.LineOfBusiness AS LineOfBusiness,
	|	DD.FinRecordID AS FinRecordID,
	|	DD.ARAPObject AS ARAPObject,
	|	TT_PaymentDocuments.OriginalARAPTransactionDocument AS DocumentPayments,
	|	DD.PrepaymentLocal AS OffsetAmount_,
	|	DD.PrepaymentMan AS ManSCreditAmount,
	|	DD.TransferDocument AS PrepaymentsSettlementDocument,
	|	FALSE AS ReversingEntry
	|FROM
	|	TransfersOfAdvancesIssued AS DD
	|	INNER JOIN
	|		ExpansionOfARAPTransactionTable AS TT_PaymentDocuments
	|	ON
	|		DD.Organization = TT_PaymentDocuments.Organization
	|		AND DD.DocumentPayments = TT_PaymentDocuments.DocumentPayments
	|
	|WHERE
	|	DD.ReversingEntry = FALSE
	|
	|UNION ALL
	|
	|SELECT
	|	1 AS EventSign,
	|	DD.Period AS Period,
	|	DD.CorCounterparty AS Counterparty,
	|	DD.DebitBusinessUnit AS Department,
	|	DD.CorLineOfBusiness AS LineOfBusiness,
	|	DD.FinRecordID AS FinRecordID,
	|	DD.CorARAPObject AS ARAPObject,
	|	TT_PaymentDocuments.OriginalARAPTransactionDocument AS DocumentPayments,
	|	-DD.PrepaymentLocal AS OffsetAmount_,
	|	-DD.PrepaymentMan AS ManSCreditAmount,
	|	DD.TransferDocument AS PrepaymentsSettlementDocument,
	|	FALSE AS ReversingEntry
	|FROM
	|	TransfersOfAdvancesIssued AS DD
	|	INNER JOIN
	|		ExpansionOfARAPTransactionTable AS TT_PaymentDocuments
	|	ON
	|		DD.Organization = TT_PaymentDocuments.Organization
	|		AND DD.DocumentPayments = TT_PaymentDocuments.DocumentPayments
	|
	|WHERE
	|	DD.ReversingEntry = TRUE
	|";
	
	Result = Query.ExecuteBatch();
	ApplyingPrepayments = Result[1].Unload();
		
	VATPrepaymentsToVendor = AccumulationRegisters.VATPrepaymentsToVendor.CreateRecordSet().UnloadColumns();
	VATPrepaymentsToVendor.Columns.Delete("Active");
	VATPrepaymentsToVendor.Columns.Add("Patch", New TypeDescription("Boolean"));
	VATPrepaymentsToVendor.Columns.Add("DateOfAdvancePayment", New TypeDescription("Date"));
	
	If ApplyingPrepayments.Count()>0 Then
		
		AccrualsFromAdvancePaymentIssued = Result[0].Unload(); // ValueTable -
		AccrualsFromAdvancePaymentIssued.Indexes.Add("DocumentPayments, Counterparty, LineOfBusiness,ARAPObject,Patch,CorrectionDate");
		
		AccrualsFromAdvancePaymentTotals = AccrualsFromAdvancePaymentIssued.Copy(,"DocumentPayments, Counterparty, LineOfBusiness, ARAPObject, Patch, CorrectionDate"); // ValueTable -
		AccrualsFromAdvancePaymentTotals.GroupBy("DocumentPayments, Counterparty, ARAPObject, LineOfBusiness, Patch, CorrectionDate");
		
		AdvancesOnPaymentDocuments = AdvancesIssuedOnPaymentDocuments(CalculationParameters); // ValueTable - 
		AdvancesToPaymentDocuments = AdvancesOnPaymentDocuments.Copy(, "DocumentPayments, Counterparty, Prepayment_,AdvanceMan");
		AdvancesToPaymentDocuments.GroupBy("DocumentPayments, Counterparty", "Prepayment_,AdvanceMan");
		AdvancesToPaymentDocuments.Indexes.Add("DocumentPayments, Counterparty");
		
		StagesOfOffset = New Array;
		StagesOfOffset.Add(New Structure("DocumentPayments,Counterparty,LineOfBusiness,ARAPObject"));
		StagesOfOffset.Add(New Structure("DocumentPayments,Counterparty,ARAPObject"));
		StagesOfOffset.Add(New Structure("DocumentPayments,Counterparty,LineOfBusiness"));
		StagesOfOffset.Add(New Structure("DocumentPayments,Counterparty"));
		StagesOfOffset.Add(New Structure("DocumentPayments,LineOfBusiness,ARAPObject"));
		StagesOfOffset.Add(New Structure("DocumentPayments,ARAPObject"));
		StagesOfOffset.Add(New Structure("DocumentPayments,LineOfBusiness"));
		StagesOfOffset.Add(New Structure("DocumentPayments"));
		
		For Each SelectionStructureOfSetOff In StagesOfOffset Do
			For Each String In AccrualsFromAdvancePaymentTotals Do
				
				AdvanceSelectionStructure = New Structure();
				AdvanceSelectionStructure.Insert("DocumentPayments", String.DocumentPayments);
				AdvanceSelectionStructure.Insert("Counterparty", String.Counterparty);
				AdvancePaymentLines = AdvancesToPaymentDocuments.FindRows(AdvanceSelectionStructure);
				If AdvancePaymentLines.Count() = 0 Then
					Continue;
				Else
					AdvanceLine_ = AdvancePaymentLines[0];
				EndIf;
				
				AdvanceSelectionStructure = New Structure();
				AdvanceSelectionStructure.Insert("DocumentPayments", String.DocumentPayments);
				AdvanceSelectionStructure.Insert("Counterparty", String.Counterparty);
				AdvanceSelectionStructure.Insert("LineOfBusiness", String.LineOfBusiness);
				AdvanceSelectionStructure.Insert("ARAPObject", String.ARAPObject);
				AdvanceSelectionStructure.Insert("Patch", String.Patch);
				AdvanceSelectionStructure.Insert("CorrectionDate", String.CorrectionDate);
				LinesCalculatingVAT = AccrualsFromAdvancePaymentIssued.FindRows(AdvanceSelectionStructure);
				
				FillPropertyValues(SelectionStructureOfSetOff, AdvanceSelectionStructure);
				LinesOffsettingAdvance = ApplyingPrepayments.FindRows(SelectionStructureOfSetOff);
				
				SetOffAdvancePaymentIssued(CalculationParameters, AdvanceLine_, LinesCalculatingVAT, LinesOffsettingAdvance, VATPrepaymentsToVendor, "Expense");
				
			EndDo;
		EndDo;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	VATPrepaymentsToVendor.Recorder AS Recorder,
	|	VATPrepaymentsToVendor.Period AS Period,
	|	VATPrepaymentsToVendor.Organization AS Organization,
	|	VATPrepaymentsToVendor.DocumentPayments AS DocumentPayments,
	|	VATPrepaymentsToVendor.Counterparty AS Counterparty,
	|	VATPrepaymentsToVendor.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|	VATPrepaymentsToVendor.Department AS Department,
	|	VATPrepaymentsToVendor.LineOfBusiness AS LineOfBusiness,
	|	VATPrepaymentsToVendor.VATRate AS VATRate,
	|	VATPrepaymentsToVendor.AmountExcludingVAT AS AmountExcludingVAT,
	|	VATPrepaymentsToVendor.VAT AS VAT,
	|	VATPrepaymentsToVendor.VATManag AS VATManag,
	|	VATPrepaymentsToVendor.Event AS Event,
	|	VATPrepaymentsToVendor.PrepaymentsSettlementDocument AS PrepaymentsSettlementDocument,
	|	VATPrepaymentsToVendor.PeriodEndTransaction AS PeriodEndTransaction,
	|	VATPrepaymentsToVendor.FinRecordID AS FinRecordID,
	|	VATPrepaymentsToVendor.ReversingEntry AS ReversingEntry,
	|	VATPrepaymentsToVendor.Patch AS Patch,
	|	VATPrepaymentsToVendor.DateOfAdvancePayment AS DateOfAdvancePayment,
	|	VATPrepaymentsToVendor.ARAPObject AS ARAPObject
	|INTO VATAdvancesIssuedTransfers
	|FROM
	|	&VATPrepaymentsToVendor AS VATPrepaymentsToVendor
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	2 AS Priority,
	|	VATPrepaymentsToVendor.Recorder AS Recorder,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	VATPrepaymentsToVendor.Period AS Period,
	|	VATPrepaymentsToVendor.Organization AS Organization,
	|	VATPrepaymentsToVendor.DocumentPayments AS DocumentPayments,
	|	VATPrepaymentsToVendor.Counterparty AS Counterparty,
	|	VATPrepaymentsToVendor.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|	VATPrepaymentsToVendor.Department AS Department,
	|	VATPrepaymentsToVendor.LineOfBusiness AS LineOfBusiness,
	|	VATPrepaymentsToVendor.VATRate AS VATRate,
	|	SUM(VATPrepaymentsToVendor.AmountExcludingVAT) AS AmountExcludingVAT,
	|	SUM(VATPrepaymentsToVendor.VAT) AS VAT,
	|	SUM(VATPrepaymentsToVendor.VATManag) AS VATManag,
	|	VATPrepaymentsToVendor.Event AS Event,
	|	VATPrepaymentsToVendor.PrepaymentsSettlementDocument AS PrepaymentsSettlementDocument,
	|	VATPrepaymentsToVendor.PeriodEndTransaction AS PeriodEndTransaction,
	|	VATPrepaymentsToVendor.FinRecordID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.SettlementOfPrepayment) AS BusinessTransactionSetting,
	|	VATPrepaymentsToVendor.ReversingEntry AS ReversingEntry,
	|	VATPrepaymentsToVendor.Patch AS Patch,
	|	VATPrepaymentsToVendor.DateOfAdvancePayment AS DateOfAdvancePayment,
	|	VATPrepaymentsToVendor.ARAPObject AS ARAPObject
	|INTO VATAdvancesIssuedTransfersExpense
	|FROM
	|	VATAdvancesIssuedTransfers AS VATPrepaymentsToVendor
	|
	|GROUP BY
	|	VATPrepaymentsToVendor.Recorder,
	|	VATPrepaymentsToVendor.Period,
	|	VATPrepaymentsToVendor.Organization,
	|	VATPrepaymentsToVendor.DocumentPayments,
	|	VATPrepaymentsToVendor.Counterparty,
	|	VATPrepaymentsToVendor.CorrectedTaxInvoice,
	|	VATPrepaymentsToVendor.Department,
	|	VATPrepaymentsToVendor.LineOfBusiness,
	|	VATPrepaymentsToVendor.VATRate,
	|	VATPrepaymentsToVendor.Event,
	|	VATPrepaymentsToVendor.PrepaymentsSettlementDocument,
	|	VATPrepaymentsToVendor.PeriodEndTransaction,
	|	VATPrepaymentsToVendor.FinRecordID,
	|	VATPrepaymentsToVendor.ReversingEntry,
	|	VATPrepaymentsToVendor.Patch,
	|	VATPrepaymentsToVendor.DateOfAdvancePayment,
	|	VATPrepaymentsToVendor.ARAPObject
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP VATAdvancesIssuedTransfers
	|";
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.SetParameter("VATPrepaymentsToVendor", VATPrepaymentsToVendor);
	Query.Execute();
	
	Return "VATAdvancesIssuedTransfersExpense";
	
EndFunction

Function CalculateVATAdvancesIssuedTransfersArrival(CalculationParameters)
	
	Query = New Query;
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.Text = 
	"SELECT
	|	MIN(AccrualFromIssuedAdvance.Priority) AS Priority,
	|	AccrualFromIssuedAdvance.Organization AS Organization,
	|	AccrualFromIssuedAdvance.DocumentPayments AS DocumentPayments,
	|	AccrualFromIssuedAdvance.Counterparty AS Counterparty,
	|	AccrualFromIssuedAdvance.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|	AccrualFromIssuedAdvance.Department           AS Department,
	|	AccrualFromIssuedAdvance.LineOfBusiness AS LineOfBusiness,
	|	AccrualFromIssuedAdvance.ARAPObject          AS ARAPObject,
	|	AccrualFromIssuedAdvance.VATRate               AS VATRate,
	|	SUM(AccrualFromIssuedAdvance.AmountExcludingVAT)      AS AmountExcludingVAT,
	|	SUM(AccrualFromIssuedAdvance.VAT)              AS VAT,
	|	SUM(AccrualFromIssuedAdvance.VATManag)           AS VATManag
	|INTO VATAccrualAdvancesIssued
	|FROM
	|	(SELECT
	|		1                           AS Priority,
	|		DD.Organization              AS Organization,
	|		DD.DocumentPayments           AS DocumentPayments,
	|		DD.Counterparty               AS Counterparty,
	|		DD.CorrectedTaxInvoice  AS CorrectedTaxInvoice,
	|		DD.Department            AS Department,
	|		DD.LineOfBusiness  AS LineOfBusiness,
	|		DD.VATRate                AS VATRate,
	|		DD.ARAPObject           AS ARAPObject,
	|		DD.AmountExcludingVAT              AS AmountExcludingVAT,
	|		DD.VAT                      AS VAT,
	|		DD.VATManag                   AS VATManag
	|	FROM
	|		BalancesAdvancesIssuedBeforeTransfer AS DD
	|
	|	UNION ALL
	|
	|	SELECT
	|		2                          AS Priority,
	|		DD.Organization             AS Organization,
	|		DD.DocumentPayments          AS DocumentPayments,
	|		DD.Counterparty              AS Counterparty,
	|		DD.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|		DD.Department           AS Department,
	|		DD.LineOfBusiness AS LineOfBusiness,
	|		DD.VATRate               AS VATRate,
	|		DD.ARAPObject          AS ARAPObject,
	|		DD.AmountExcludingVAT             AS AmountExcludingVAT,
	|		DD.VAT                     AS VAT,
	|		DD.VATManag                  AS VATManag
	|	FROM
	|		VATAdvancesIssuedTransfersExpense AS DD
	|	) AS AccrualFromIssuedAdvance
	|
	|GROUP BY
	|	AccrualFromIssuedAdvance.Organization,
	|	AccrualFromIssuedAdvance.DocumentPayments,
	|	AccrualFromIssuedAdvance.Counterparty,
	|	AccrualFromIssuedAdvance.CorrectedTaxInvoice,
	|	AccrualFromIssuedAdvance.Department,
	|	AccrualFromIssuedAdvance.LineOfBusiness,
	|	AccrualFromIssuedAdvance.VATRate,
	|	AccrualFromIssuedAdvance.ARAPObject
	|
	|HAVING
	|	(SUM(AccrualFromIssuedAdvance.AmountExcludingVAT) <> 0
	|		OR SUM(AccrualFromIssuedAdvance.VAT) <> 0)
	|INDEX BY
	|	Organization,
	|	DocumentPayments
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(CorrectedInvoicesReceivedInAdvance.Ref, InvoicesReceivedInAdvance.Ref) AS Ref,
	|	ISNULL(CorrectedInvoicesReceivedInAdvance.Date, InvoicesReceivedInAdvance.Date) AS Date,
	|	CASE
	|		WHEN NOT CorrectedInvoicesReceivedInAdvance.Ref IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                                                             AS Patch,
	|	ISNULL(CorrectedInvoicesReceivedInAdvance.CorrectionDate, DATETIME(1,1,1)) AS CorrectionDate,
	|	DD.Organization AS Organization,
	|	DD.DocumentPayments AS DocumentPayments,
	|	DD.Counterparty AS Counterparty,
	|	DD.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|	DD.Department AS Department,
	|	DD.LineOfBusiness AS LineOfBusiness,
	|	DD.ARAPObject AS ARAPObject,
	|	DD.VATRate AS VATRate,
	|	DD.AmountExcludingVAT AS AmountExcludingVAT,
	|	DD.VAT AS VAT,
	|	DD.VATManag AS VATManag
	|FROM
	|	VATAccrualAdvancesIssued AS DD
	|	LEFT JOIN
	|		InvoicesReceivedInAdvance AS InvoicesReceivedInAdvance
	|	ON
	|		DD.Organization = InvoicesReceivedInAdvance.Organization
	|		AND DD.DocumentPayments = InvoicesReceivedInAdvance.DocumentPayments
	|		AND DD.Counterparty = InvoicesReceivedInAdvance.Counterparty
	|
	|	LEFT JOIN
	|		CorrectedInvoicesReceivedInAdvance AS CorrectedInvoicesReceivedInAdvance
	|	ON
	|		DD.Organization = CorrectedInvoicesReceivedInAdvance.Organization
	|		AND DD.DocumentPayments = CorrectedInvoicesReceivedInAdvance.DocumentPayments
	|		AND DD.Counterparty = CorrectedInvoicesReceivedInAdvance.Counterparty
	|
	|ORDER BY
	|	Priority
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	1 AS EventSign,
	|	DD.Period AS Period,
	|	DD.CorCounterparty AS Counterparty,
	|	DD.CorLineOfBusiness AS LineOfBusiness,
	|	DD.DebitBusinessUnit AS Department,
	|	DD.FinRecordID AS FinRecordID,
	|	DD.CorARAPObject AS ARAPObject,
	|	TT_PaymentDocuments.OriginalARAPTransactionDocument AS DocumentPayments,
	|	DD.PrepaymentLocal AS OffsetAmount_,
	|	DD.PrepaymentMan AS ManSCreditAmount,
	|	DD.TransferDocument AS PrepaymentsSettlementDocument,
	|	FALSE AS ReversingEntry
	|FROM
	|	TransfersOfAdvancesIssued AS DD
	|	INNER JOIN
	|		ExpansionOfARAPTransactionTable AS TT_PaymentDocuments
	|	ON
	|		DD.Organization = TT_PaymentDocuments.Organization
	|		AND DD.DocumentPayments = TT_PaymentDocuments.DocumentPayments
	|
	|WHERE
	|	DD.ReversingEntry = FALSE
	|
	|UNION ALL
	|
	|SELECT
	|	1 AS EventSign,
	|	DD.Period AS Period,
	|	DD.Counterparty AS Counterparty,
	|	DD.LineOfBusiness AS LineOfBusiness,
	|	DD.Department AS Department,
	|	DD.FinRecordID AS FinRecordID,
	|	DD.ARAPObject AS ARAPObject,
	|	TT_PaymentDocuments.OriginalARAPTransactionDocument AS DocumentPayments,
	|	-DD.PrepaymentLocal AS OffsetAmount_,
	|	-DD.PrepaymentMan AS ManSCreditAmount,
	|	DD.TransferDocument AS PrepaymentsSettlementDocument,
	|	FALSE AS ReversingEntry
	|FROM
	|	TransfersOfAdvancesIssued AS DD
	|	INNER JOIN
	|		ExpansionOfARAPTransactionTable AS TT_PaymentDocuments
	|	ON
	|		DD.Organization = TT_PaymentDocuments.Organization
	|		AND DD.DocumentPayments = TT_PaymentDocuments.DocumentPayments
	|
	|WHERE
	|	DD.ReversingEntry = TRUE
	|;
	|
	|//////////////////////////////////////////////////////
	|DROP VATAccrualAdvancesIssued
	|";
	
	Result = Query.ExecuteBatch();
	ApplyingPrepayments = Result[2].Unload();
		
	VATPrepaymentsToVendor = AccumulationRegisters.VATPrepaymentsToVendor.CreateRecordSet().UnloadColumns();
	VATPrepaymentsToVendor.Columns.Delete("Active");
	VATPrepaymentsToVendor.Columns.Add("Patch", New TypeDescription("Boolean"));
	VATPrepaymentsToVendor.Columns.Add("DateOfAdvancePayment", New TypeDescription("Date"));
	
	If ApplyingPrepayments.Count()>0 Then
		
		AccrualsFromAdvancePaymentIssued = Result[1].Unload(); // ValueTable -
		AccrualsFromAdvancePaymentIssued.Indexes.Add("DocumentPayments, Counterparty, LineOfBusiness, ARAPObject, Patch, CorrectionDate");

		AccrualsFromAdvancePaymentTotals = AccrualsFromAdvancePaymentIssued.Copy(,"DocumentPayments, Counterparty, LineOfBusiness, ARAPObject, Patch, CorrectionDate"); // ValueTable -
		AccrualsFromAdvancePaymentTotals.GroupBy("DocumentPayments, Counterparty, ARAPObject, LineOfBusiness, Patch, CorrectionDate");
		
		AdvancesOnPaymentDocuments = AdvancesIssuedOnPaymentDocuments(CalculationParameters); // ValueTable - 
		AdvancesToPaymentDocuments = AdvancesOnPaymentDocuments.Copy(, "DocumentPayments, Counterparty, Prepayment_,AdvanceMan");
		AdvancesToPaymentDocuments.GroupBy("DocumentPayments, Counterparty", "Prepayment_,AdvanceMan");
		AdvancesToPaymentDocuments.Indexes.Add("DocumentPayments, Counterparty");
		
		StagesOfOffset = New Array;
		StagesOfOffset.Add(New Structure("DocumentPayments,Counterparty,LineOfBusiness,ARAPObject"));
		StagesOfOffset.Add(New Structure("DocumentPayments,Counterparty,ARAPObject"));
		StagesOfOffset.Add(New Structure("DocumentPayments,Counterparty,LineOfBusiness"));
		StagesOfOffset.Add(New Structure("DocumentPayments,Counterparty"));
		
		For Each SelectionStructureOfSetOff In StagesOfOffset Do
			For Each String In AccrualsFromAdvancePaymentTotals Do
				
				AdvanceSelectionStructure = New Structure();
				AdvanceSelectionStructure.Insert("DocumentPayments", String.DocumentPayments);
				AdvanceSelectionStructure.Insert("Counterparty", String.Counterparty);
				AdvancePaymentLines = AdvancesToPaymentDocuments.FindRows(AdvanceSelectionStructure);
				If AdvancePaymentLines.Count() = 0 Then
					Continue;
				Else
					AdvanceLine_ = AdvancePaymentLines[0];
				EndIf;
				
				AdvanceSelectionStructure = New Structure();
				AdvanceSelectionStructure.Insert("DocumentPayments", String.DocumentPayments);
				AdvanceSelectionStructure.Insert("LineOfBusiness", String.LineOfBusiness);
				AdvanceSelectionStructure.Insert("Counterparty", String.Counterparty);
				AdvanceSelectionStructure.Insert("ARAPObject", String.ARAPObject);
				AdvanceSelectionStructure.Insert("Patch", String.Patch);
				AdvanceSelectionStructure.Insert("CorrectionDate", String.CorrectionDate);
				LinesCalculatingVAT = AccrualsFromAdvancePaymentIssued.FindRows(AdvanceSelectionStructure);
				
				FillPropertyValues(SelectionStructureOfSetOff, AdvanceSelectionStructure);
				LinesOffsettingAdvance = ApplyingPrepayments.FindRows(SelectionStructureOfSetOff);
				
				SetOffAdvancePaymentIssued(CalculationParameters, AdvanceLine_, LinesCalculatingVAT, LinesOffsettingAdvance, VATPrepaymentsToVendor, "Receipt");
				
			EndDo;
		EndDo;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	VATPrepaymentsToVendor.Recorder AS Recorder,
	|	VATPrepaymentsToVendor.Period AS Period,
	|	VATPrepaymentsToVendor.Organization AS Organization,
	|	VATPrepaymentsToVendor.DocumentPayments AS DocumentPayments,
	|	VATPrepaymentsToVendor.Counterparty AS Counterparty,
	|	VATPrepaymentsToVendor.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|	VATPrepaymentsToVendor.Department AS Department,
	|	VATPrepaymentsToVendor.LineOfBusiness AS LineOfBusiness,
	|	VATPrepaymentsToVendor.VATRate AS VATRate,
	|	VATPrepaymentsToVendor.AmountExcludingVAT AS AmountExcludingVAT,
	|	VATPrepaymentsToVendor.VAT AS VAT,
	|	VATPrepaymentsToVendor.VATManag AS VATManag,
	|	VATPrepaymentsToVendor.Event AS Event,
	|	VATPrepaymentsToVendor.PrepaymentsSettlementDocument AS PrepaymentsSettlementDocument,
	|	VATPrepaymentsToVendor.PeriodEndTransaction AS PeriodEndTransaction,
	|	VATPrepaymentsToVendor.FinRecordID AS FinRecordID,
	|	VATPrepaymentsToVendor.ReversingEntry AS ReversingEntry,
	|	VATPrepaymentsToVendor.Patch AS Patch,
	|	VATPrepaymentsToVendor.DateOfAdvancePayment AS DateOfAdvancePayment,
	|	VATPrepaymentsToVendor.ARAPObject AS ARAPObject
	|INTO VATAdvancesIssuedTransfers
	|FROM
	|	&VATPrepaymentsToVendor AS VATPrepaymentsToVendor
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	2 AS Priority,
	|	VATPrepaymentsToVendor.Recorder AS Recorder,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	VATPrepaymentsToVendor.Period AS Period,
	|	VATPrepaymentsToVendor.Organization AS Organization,
	|	VATPrepaymentsToVendor.DocumentPayments AS DocumentPayments,
	|	VATPrepaymentsToVendor.Counterparty AS Counterparty,
	|	VATPrepaymentsToVendor.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|	VATPrepaymentsToVendor.Department AS Department,
	|	VATPrepaymentsToVendor.LineOfBusiness AS LineOfBusiness,
	|	VATPrepaymentsToVendor.VATRate AS VATRate,
	|	SUM(VATPrepaymentsToVendor.AmountExcludingVAT) AS AmountExcludingVAT,
	|	SUM(VATPrepaymentsToVendor.VAT) AS VAT,
	|	SUM(VATPrepaymentsToVendor.VATManag) AS VATManag,
	|	VATPrepaymentsToVendor.Event AS Event,
	|	VATPrepaymentsToVendor.PrepaymentsSettlementDocument AS PrepaymentsSettlementDocument,
	|	VATPrepaymentsToVendor.PeriodEndTransaction AS PeriodEndTransaction,
	|	VATPrepaymentsToVendor.FinRecordID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.SettlementOfPrepayment) AS BusinessTransactionSetting,
	|	VATPrepaymentsToVendor.ReversingEntry AS ReversingEntry,
	|	VATPrepaymentsToVendor.Patch AS Patch,
	|	VATPrepaymentsToVendor.DateOfAdvancePayment AS DateOfAdvancePayment,
	|	VATPrepaymentsToVendor.ARAPObject AS ARAPObject
	|INTO VATAdvancesIssuedTransfersReceipt
	|FROM
	|	VATAdvancesIssuedTransfers AS VATPrepaymentsToVendor
	|
	|GROUP BY
	|	VATPrepaymentsToVendor.Recorder,
	|	VATPrepaymentsToVendor.Period,
	|	VATPrepaymentsToVendor.Organization,
	|	VATPrepaymentsToVendor.DocumentPayments,
	|	VATPrepaymentsToVendor.Counterparty,
	|	VATPrepaymentsToVendor.CorrectedTaxInvoice,
	|	VATPrepaymentsToVendor.Department,
	|	VATPrepaymentsToVendor.LineOfBusiness,
	|	VATPrepaymentsToVendor.VATRate,
	|	VATPrepaymentsToVendor.Event,
	|	VATPrepaymentsToVendor.PrepaymentsSettlementDocument,
	|	VATPrepaymentsToVendor.PeriodEndTransaction,
	|	VATPrepaymentsToVendor.FinRecordID,
	|	VATPrepaymentsToVendor.ReversingEntry,
	|	VATPrepaymentsToVendor.Patch,
	|	VATPrepaymentsToVendor.DateOfAdvancePayment,
	|	VATPrepaymentsToVendor.ARAPObject
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP VATAdvancesIssuedTransfers
	|";
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.SetParameter("VATPrepaymentsToVendor", VATPrepaymentsToVendor);
	Query.Execute();
	
	Return "VATAdvancesIssuedTransfersReceipt";
	
EndFunction

Function CalculateVATAdvancesIssuedStornoOffsets(CalculationParameters)
	
	Query = New Query;
	Query.Text = "SELECT
	|	OffsetsOfAdvancesIssued.Period AS Period,
	|	OffsetsOfAdvancesIssued.DocumentPayments AS DocumentPayments,
	|	OffsetsOfAdvancesIssued.ARAPObject AS ARAPObject,
	|	CAST(OffsetsOfAdvancesIssued.PrepaymentsSettlementDocument AS Document.ReversingEntry).ReversedDocument AS Document,
	|	OffsetsOfAdvancesIssued.PrepaymentsSettlementDocument AS PrepaymentsSettlementDocument
	|INTO DocumentsForOffsettingAdvancesIssuedStorno
	|FROM
	|	OffsetsOfAdvancesIssued AS OffsetsOfAdvancesIssued
	|WHERE
	|	OffsetsOfAdvancesIssued.ReversingEntry = TRUE
	|
	|GROUP BY
	|	OffsetsOfAdvancesIssued.Period,
	|	OffsetsOfAdvancesIssued.DocumentPayments,
	|	OffsetsOfAdvancesIssued.ARAPObject,
	|	CAST(OffsetsOfAdvancesIssued.PrepaymentsSettlementDocument AS Document.ReversingEntry).ReversedDocument,
	|	OffsetsOfAdvancesIssued.PrepaymentsSettlementDocument
	|
	|INDEX BY
	|	DocumentPayments,
	|	ARAPObject,
	|	Document
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	2 AS Priority,
	|	CreditDocumentsStorno.Period AS Period,
	|	VATPrepaymentsToVendor.Recorder AS Recorder,
	|	VATPrepaymentsToVendor.RecordType AS RecordType,
	|	VATPrepaymentsToVendor.Organization AS Organization,
	|	VATPrepaymentsToVendor.DocumentPayments AS DocumentPayments,
	|	VATPrepaymentsToVendor.Counterparty AS Counterparty,
	|	VATPrepaymentsToVendor.ARAPObject AS ARAPObject,
	|	VATPrepaymentsToVendor.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|	VATPrepaymentsToVendor.Department AS Department,
	|	VATPrepaymentsToVendor.LineOfBusiness AS LineOfBusiness,
	|	VATPrepaymentsToVendor.VATRate AS VATRate,
	|	-VATPrepaymentsToVendor.AmountExcludingVAT AS AmountExcludingVAT,
	|	-VATPrepaymentsToVendor.VAT AS VAT,
	|	-VATPrepaymentsToVendor.VATManag AS VATManag,
	|	VATPrepaymentsToVendor.Event AS Event,
	|	CreditDocumentsStorno.PrepaymentsSettlementDocument AS PrepaymentsSettlementDocument,
	|	ISNULL(CreditDocumentsStorno.Document.Date, VATPrepaymentsToVendor.Period) AS DateOfAdvancePayment,
	|	VATPrepaymentsToVendor.FinRecordID AS FinRecordID,
	|	VATPrepaymentsToVendor.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	TRUE AS PeriodEndTransaction,
	|	FALSE AS ReversingEntry
	|INTO VATAdvancesIssuedStornoOffsets
	|FROM
	|	AccumulationRegister.VATPrepaymentsToVendor AS VATPrepaymentsToVendor
	|		INNER JOIN DocumentsForOffsettingAdvancesIssuedStorno AS CreditDocumentsStorno
	|		ON VATPrepaymentsToVendor.PrepaymentsSettlementDocument = CreditDocumentsStorno.Document
	|			AND VATPrepaymentsToVendor.DocumentPayments = CreditDocumentsStorno.DocumentPayments
	|			AND VATPrepaymentsToVendor.ARAPObject = CreditDocumentsStorno.ARAPObject
	|		INNER JOIN InvoicesReceivedInAdvance AS InvoicesReceivedInAdvance
	|		ON VATPrepaymentsToVendor.Recorder = InvoicesReceivedInAdvance.Ref
	|WHERE
	|	VATPrepaymentsToVendor.PeriodEndTransaction
	|	AND NOT VATPrepaymentsToVendor.ReversingEntry
	|	AND VATPrepaymentsToVendor.Period < &BeginOfPeriod
	|	AND NOT VATPrepaymentsToVendor.DocumentPayments IN 
	|				(SELECT
	|					ISF.DocumentPayments AS Ref
	|				FROM
	|					CorrectedInvoicesReceivedInAdvance AS ISF)
	|
	|UNION ALL
	|
	|SELECT
	|	2 AS Priority,
	|	CreditDocumentsStorno.Period AS Period,
	|	VATPrepaymentsToVendor.Recorder AS Recorder,
	|	VATPrepaymentsToVendor.RecordType AS RecordType,
	|	VATPrepaymentsToVendor.Organization AS Organization,
	|	VATPrepaymentsToVendor.DocumentPayments AS DocumentPayments,
	|	VATPrepaymentsToVendor.Counterparty AS Counterparty,
	|	VATPrepaymentsToVendor.ARAPObject AS ARAPObject,
	|	VATPrepaymentsToVendor.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|	VATPrepaymentsToVendor.Department AS Department,
	|	VATPrepaymentsToVendor.LineOfBusiness AS LineOfBusiness,
	|	VATPrepaymentsToVendor.VATRate AS VATRate,
	|	-VATPrepaymentsToVendor.AmountExcludingVAT AS AmountExcludingVAT,
	|	-VATPrepaymentsToVendor.VAT AS VAT,
	|	-VATPrepaymentsToVendor.VATManag AS VATManag,
	|	VATPrepaymentsToVendor.Event AS Event,
	|	CreditDocumentsStorno.PrepaymentsSettlementDocument AS PrepaymentsSettlementDocument,
	|	ISNULL(CreditDocumentsStorno.Document.Date, VATPrepaymentsToVendor.Period) AS DateOfAdvancePayment,
	|	VATPrepaymentsToVendor.FinRecordID AS FinRecordID,
	|	VATPrepaymentsToVendor.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	TRUE AS PeriodEndTransaction,
	|	FALSE AS ReversingEntry
	|FROM
	|	AccumulationRegister.VATPrepaymentsToVendor AS VATPrepaymentsToVendor
	|		INNER JOIN DocumentsForOffsettingAdvancesIssuedStorno AS CreditDocumentsStorno
	|		ON VATPrepaymentsToVendor.PrepaymentsSettlementDocument = CreditDocumentsStorno.Document
	|			AND VATPrepaymentsToVendor.DocumentPayments = CreditDocumentsStorno.DocumentPayments
	|			AND VATPrepaymentsToVendor.ARAPObject = CreditDocumentsStorno.ARAPObject
	|		INNER JOIN CorrectedInvoicesReceivedInAdvance AS CorrectedInvoicesReceivedInAdvance
	|		ON VATPrepaymentsToVendor.Recorder = CorrectedInvoicesReceivedInAdvance.Ref
	|			AND VATPrepaymentsToVendor.CorrectedTaxInvoice = CorrectedInvoicesReceivedInAdvance.Ref
	|WHERE
	|	VATPrepaymentsToVendor.PeriodEndTransaction
	|	AND NOT VATPrepaymentsToVendor.ReversingEntry
	|	AND VATPrepaymentsToVendor.Period < &BeginOfPeriod";
	
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.SetParameter("BeginOfPeriod", CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", CalculationParameters.EndOfPeriod);

	Query.Execute();
	
	Return "VATAdvancesIssuedStornoOffsets";
	
EndFunction

#EndRegion

#Region VATTrafficFormation

Procedure GenerateVATRegisteredRecords(CalculationParameters)
	
	GetCurTrafficRegistrarsForVAT(CalculationParameters);
	
	NamesOfTablesOfVATTrafficRecords = New Array;
	NamesOfTablesOfVATTrafficRecords.Add(CalculateVATRegisteredRecordsReverse(CalculationParameters));
	NamesOfTablesOfVATTrafficRecords.Add(CalculateRegisteredRecordsOnVATPresented(CalculationParameters));
	NamesOfTablesOfVATTrafficRecords.Add(CalculateVATRegisteredRecordsReverseOnCorrectedInvoices(CalculationParameters));
	If CalculationParameters.CalculationOfAdvancesReceived Then
		NamesOfTablesOfVATTrafficRecords.Add(CalculateVATRegisteredRecordsReverseOnCorrectedInvoicesIssuedInAdvance(CalculationParameters));
		NamesOfTablesOfVATTrafficRecords.Add(CalculateRegisteredRecordsOnVATAdvancesReceived(CalculationParameters));
	EndIf;
	If CalculationParameters.CalculationOfAdvancesIssued Then
		NamesOfTablesOfVATTrafficRecords.Add(CalculateRegisteredRecordsOnVATReverseOnCorrectedInvoicesReceivedInAdvance(CalculationParameters));
		NamesOfTablesOfVATTrafficRecords.Add(CalculateRegisteredRecordsOnVATAdvancesIssued(CalculationParameters));
	EndIf;
	NamesOfTablesOfVATTrafficRecords.Add(CalculateMovementRecordsByVATSaving(CalculationParameters, NamesOfTablesOfVATTrafficRecords));

	RecordVATRegisteredRecords(CalculationParameters, NamesOfTablesOfVATTrafficRecords);
	ClearVATTraffic(CalculationParameters, NamesOfTablesOfVATTrafficRecords);
	
EndProcedure
	
Procedure GetCurTrafficRegistrarsForVAT(CalculationParameters) 
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	VATRegisterRecords.Recorder AS Recorder,
	|	VATRegisterRecords.Organization AS Organization,
	|	VATRegisterRecords.Period      AS Period
	|INTO CurVATTrafficRegistrars
	|FROM
	|	AccumulationRegister.VATRegisterRecords AS VATRegisterRecords
	|		INNER JOIN Jobs AS Jobs
	|		ON (Jobs.Organization = VATRegisterRecords.Organization)
	|			AND (Jobs.TaxInvoice = VATRegisterRecords.TaxInvoice)
	|WHERE
	|	VATRegisterRecords.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND VATRegisterRecords.PeriodEndTransaction
	|
	|INDEX BY
	|	Recorder
	|";
	
	Query.SetParameter("BeginOfPeriod",     CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",  CalculationParameters.EndOfPeriod);
	Query.SetParameter("CompanyArray", CalculationParameters.CompanyArray);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.Execute();
	
EndProcedure

Function CalculateVATRegisteredRecordsReverse(CalculationParameters)
	
	QueryTextArray = New Array;
	QueryText =
	"SELECT
	|	0 AS Priority,
	|	VATPresentedInReverse.Ref AS Recorder,
	|	VATPresentedInReverse.Period AS Period,
	|	VATPresentedInReverse.ReversedDocument AS ReversedDocument,
	|	VATRegisterRecords.Organization AS Organization,
	|	VATRegisterRecords.EntryType AS EntryType,
	|	VATRegisterRecords.Counterparty AS Counterparty,
	|	VATRegisterRecords.TaxInvoice AS TaxInvoice,
	|	VATRegisterRecords.VATRate AS VATRate,
	|	VATRegisterRecords.AssetTaxClass AS AssetTaxClass,
	|	-VATRegisterRecords.AmountExcludingVAT AS AmountExcludingVAT,
	|	-VATRegisterRecords.VAT AS VAT,
	|	-VATRegisterRecords.VATManag AS VATManag,
	|	VATRegisterRecords.ARAPObject AS ARAPObject,
	|	VATRegisterRecords.PeriodEndTransaction AS PeriodEndTransaction,
	|	VATRegisterRecords.FinRecordID AS FinRecordID,
	|	VATRegisterRecords.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	CASE
	|		WHEN VATRegisterRecords.Recorder = VATPresentedInReverse.ReversedDocument
	|			THEN TRUE 
	|		ELSE FALSE
	|	END AS ReversingEntry
	|INTO VATRegisteredRecordsReverse
	|FROM
	|	AccumulationRegister.VATRegisterRecords AS VATRegisterRecords
	|
	|	INNER JOIN
	|		VATPresentedInReverse AS VATPresentedInReverse
	|	ON
	|		VATRegisterRecords.Recorder = VATPresentedInReverse.Recorder
	|		AND VATRegisterRecords.Organization = VATPresentedInReverse.Organization
	|		AND VATRegisterRecords.TaxInvoice = VATPresentedInReverse.TaxInvoice
	|
	|WHERE
	|	VATRegisterRecords.PeriodEndTransaction
	|	AND NOT VATRegisterRecords.ReversingEntry
	|	AND VATRegisterRecords.Period < &BeginOfPeriod
	|";
	QueryTextArray.Add(QueryText);
	
	If CalculationParameters.CalculationOfAdvancesIssued Then
		QueryText =
		"SELECT
		|	0 AS Priority,
		|	VATAdvancesIssuedSelectionStorno.Ref AS Recorder,
		|	VATAdvancesIssuedSelectionStorno.Period AS Period,
		|	VATAdvancesIssuedSelectionStorno.ReversedDocument AS ReversedDocument,
		|	VATRegisterRecords.Organization AS Organization,
		|	VATRegisterRecords.EntryType AS EntryType,
		|	VATRegisterRecords.Counterparty AS Counterparty,
		|	VATRegisterRecords.TaxInvoice AS TaxInvoice,
		|	VATRegisterRecords.VATRate AS VATRate,
		|	VATRegisterRecords.AssetTaxClass AS AssetTaxClass,
		|	-VATRegisterRecords.AmountExcludingVAT AS AmountExcludingVAT,
		|	-VATRegisterRecords.VAT AS VAT,
		|	-VATRegisterRecords.VATManag AS VATManag,
		|	VATRegisterRecords.ARAPObject AS ARAPObject,
		|	VATRegisterRecords.PeriodEndTransaction AS PeriodEndTransaction,
		|	VATRegisterRecords.FinRecordID AS FinRecordID,
		|	VATRegisterRecords.BusinessTransactionSetting AS BusinessTransactionSetting,
		|	TRUE AS ReversingEntry
		|FROM
		|	AccumulationRegister.VATRegisterRecords AS VATRegisterRecords
		|
		|	INNER JOIN
		|		VATAdvancesIssuedSelectionStorno AS VATAdvancesIssuedSelectionStorno
		|	ON
		|		VATRegisterRecords.Recorder = VATAdvancesIssuedSelectionStorno.ReversedDocument
		|		AND VATRegisterRecords.Organization = VATAdvancesIssuedSelectionStorno.Organization
		|		AND VATRegisterRecords.TaxInvoice = VATAdvancesIssuedSelectionStorno.DocumentPayments
		|
		|WHERE
		|	VATRegisterRecords.PeriodEndTransaction
		|	AND NOT VATRegisterRecords.ReversingEntry
		|	AND VATRegisterRecords.Period < &BeginOfPeriod";
		QueryTextArray.Add(QueryText);
	EndIf;
	
	If CalculationParameters.CalculationOfAdvancesReceived Then
		QueryText =
		"SELECT
		|	0 AS Priority,
		|	VATAdvancesReceivedSelectionStorno.Ref AS Recorder,
		|	VATAdvancesReceivedSelectionStorno.Period AS Period,
		|	VATAdvancesReceivedSelectionStorno.ReversedDocument AS ReversedDocument,
		|	VATRegisterRecords.Organization AS Organization,
		|	VATRegisterRecords.EntryType AS EntryType,
		|	VATRegisterRecords.Counterparty AS Counterparty,
		|	VATRegisterRecords.TaxInvoice AS TaxInvoice,
		|	VATRegisterRecords.VATRate AS VATRate,
		|	VATRegisterRecords.AssetTaxClass AS AssetTaxClass,
		|	-VATRegisterRecords.AmountExcludingVAT AS AmountExcludingVAT,
		|	-VATRegisterRecords.VAT AS VAT,
		|	-VATRegisterRecords.VATManag AS VATManag,
		|	VATRegisterRecords.ARAPObject AS ARAPObject,
		|	VATRegisterRecords.PeriodEndTransaction AS PeriodEndTransaction,
		|	VATRegisterRecords.FinRecordID AS FinRecordID,
		|	VATRegisterRecords.BusinessTransactionSetting AS BusinessTransactionSetting,
		|	TRUE AS ReversingEntry
		|FROM
		|	AccumulationRegister.VATRegisterRecords AS VATRegisterRecords
		|
		|	INNER JOIN
		|		VATAdvancesReceivedSelectionStorno AS VATAdvancesReceivedSelectionStorno
		|	ON
		|		VATRegisterRecords.Recorder = VATAdvancesReceivedSelectionStorno.ReversedDocument
		|		AND VATRegisterRecords.Organization = VATAdvancesReceivedSelectionStorno.Organization
		|		AND VATRegisterRecords.TaxInvoice = VATAdvancesReceivedSelectionStorno.DocumentPayments
		|
		|WHERE
		|	VATRegisterRecords.PeriodEndTransaction
		|	AND NOT VATRegisterRecords.ReversingEntry
		|	AND VATRegisterRecords.Period < &BeginOfPeriod";
		QueryTextArray.Add(QueryText);
	EndIf;

	Query = New Query;
	Query.Text = StrConcat(QueryTextArray, TMCommonUse.QuerySeparatorInJoin());
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.SetParameter("BeginOfPeriod", CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", CalculationParameters.EndOfPeriod);
	Query.Execute();
	
	Return "VATRegisteredRecordsReverse";
	
EndFunction

Function CalculateRegisteredRecordsOnVATPresented(CalculationParameters)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	1 AS Priority,
	|	VATInvoiced.Period AS Period,
	|	VATInvoiced.Recorder AS Recorder,
	|	VATInvoiced.Organization AS Organization,
	|	VALUE(Enum.VATRegisterRecordTypes.Incoming) AS EntryType,
	|	VATInvoiced.Vendor AS Counterparty,
	|	VATInvoiced.TaxInvoice AS TaxInvoice,
	|	VATInvoiced.AssetTaxClass AS AssetTaxClass,
	|	VATInvoiced.VATRate AS VATRate,
	|
	|	- CASE
	|		WHEN VATInvoiced.AmountExcludingVAT = 0
	|				AND VATInvoiced.VATRate.Rate1 > 0
	|			THEN VATInvoiced.VAT * 100 / VATInvoiced.VATRate.Rate1
	|		ELSE VATInvoiced.AmountExcludingVAT
	|	END AS AmountExcludingVAT,
	|	- VATInvoiced.VAT AS VAT,
	|	- VATInvoiced.VATManag AS VATManag,
	|	UNDEFINED AS ARAPObject,
	|	TRUE AS PeriodEndTransaction,
	|	VATInvoiced.FinRecordID AS FinRecordID,
	|	VATInvoiced.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	VATInvoiced.ReversingEntry AS ReversingEntry
	|INTO RegisteredRecordsOnVATOnVATPresented
	|FROM
	|	VATPresentedRecoveryUnderTypeOfActivity AS VATInvoiced
	|
	|UNION ALL
	|
	|SELECT
	|	1 AS Priority,
	|	VATInvoiced.Period AS Period,
	|	VATInvoiced.Recorder AS Recorder,
	|	VATInvoiced.Organization AS Organization,
	|	VALUE(Enum.VATRegisterRecordTypes.Incoming) AS EntryType,
	|	VATInvoiced.Vendor AS Counterparty,
	|	VATInvoiced.TaxInvoice AS TaxInvoice,
	|	VATInvoiced.AssetTaxClass AS AssetTaxClass,
	|	VATInvoiced.VATRate AS VATRate,
	|
	|	- CASE
	|		WHEN VATInvoiced.AmountExcludingVAT = 0
	|				AND VATInvoiced.VATRate.Rate1 > 0
	|			THEN VATInvoiced.VAT * 100 / VATInvoiced.VATRate.Rate1
	|		ELSE VATInvoiced.AmountExcludingVAT
	|	END AS AmountExcludingVAT,
	|	- VATInvoiced.VAT AS VAT,
	|	- VATInvoiced.VATManag AS VATManag,
	|	UNDEFINED AS ARAPObject,
	|	TRUE AS PeriodEndTransaction,
	|	VATInvoiced.FinRecordID AS FinRecordID,
	|	VATInvoiced.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	VATInvoiced.ReversingEntry AS ReversingEntry
	|FROM
	|	VATPresentedRecoveryByCSF AS VATInvoiced
	|
	|UNION ALL
	|
	|SELECT
	|	1 AS Priority,
	|	VATInvoiced.Period AS Period,
	|	VATInvoiced.Recorder AS Recorder,
	|	VATInvoiced.Organization AS Organization,
	|	VALUE(Enum.VATRegisterRecordTypes.Incoming) AS EntryType,
	|	VATInvoiced.Vendor AS Counterparty,
	|	VATInvoiced.TaxInvoice AS TaxInvoice,
	|	VATInvoiced.AssetTaxClass AS AssetTaxClass,
	|	VATInvoiced.VATRate AS VATRate,
	|
	|	CASE
	|		WHEN VATInvoiced.AmountExcludingVAT = 0
	|				AND VATInvoiced.VATRate.Rate1 > 0
	|			THEN VATInvoiced.VAT * 100 / VATInvoiced.VATRate.Rate1
	|		ELSE VATInvoiced.AmountExcludingVAT
	|	END AS AmountExcludingVAT,
	|	VATInvoiced.VAT AS VAT,
	|	VATInvoiced.VATManag AS VATManag,
	|	UNDEFINED AS ARAPObject,
	|	TRUE AS PeriodEndTransaction,
	|	VATInvoiced.FinRecordID AS FinRecordID,
	|	VATInvoiced.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	VATInvoiced.ReversingEntry AS ReversingEntry
	|FROM
	|	VATPresentedAcceptanceForDeduction AS VATInvoiced
	|";
	
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.Execute();
	
	Return "RegisteredRecordsOnVATOnVATPresented";
	
EndFunction

Function CalculateRegisteredRecordsOnVATAdvancesReceived(CalculationParameters)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	2 AS Priority,
	|	VATAdvancesReceivedCredits.Period AS Period,
	|	VATAdvancesReceivedCredits.Recorder AS Recorder,
	|	VATAdvancesReceivedCredits.Organization AS Organization,
	|	VALUE(Enum.VATRegisterRecordTypes.Outgoing) AS EntryType,
	|	VATAdvancesReceivedCredits.Counterparty AS Counterparty,
	|	VATAdvancesReceivedCredits.DocumentPayments AS TaxInvoice,
	|	CASE
	|		WHEN VATAdvancesReceivedCredits.Event = VALUE(Enum.EventsVATFromPrepayments.DeductionOnPrepapaymentReturn)
	|			THEN VALUE(Enum.AssetKinds.RefundPrepaymentsFromCustomer)
	|		ELSE  VALUE(Enum.AssetKinds.PrepaymentsFromCustomer)
	|	END AS AssetTaxClass,
	|	VATAdvancesReceivedCredits.VATRate AS VATRate,
	|	-VATAdvancesReceivedCredits.AmountExcludingVAT AS AmountExcludingVAT,
	|	-VATAdvancesReceivedCredits.VAT AS VAT,
	|	-VATAdvancesReceivedCredits.VATManag AS VATManag,
	|	UNDEFINED AS ARAPObject,
	|	TRUE AS PeriodEndTransaction,
	|	VATAdvancesReceivedCredits.FinRecordID AS FinRecordID,
	|	VATAdvancesReceivedCredits.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	VATAdvancesReceivedCredits.ReversingEntry AS ReversingEntry
	|INTO RegisteredRecordsInVATOnAdvancesReceived
	|FROM
	|	VATAdvancesReceivedCredits AS VATAdvancesReceivedCredits
	|";
	
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.Execute();
	
	Return "RegisteredRecordsInVATOnAdvancesReceived";
	
EndFunction

Function CalculateRegisteredRecordsOnVATAdvancesIssued(CalculationParameters)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	2 AS Priority,
	|	VATAdvancesIssuedCredits.Period AS Period,
	|	VATAdvancesIssuedCredits.Recorder AS Recorder,
	|	VATAdvancesIssuedCredits.Organization AS Organization,
	|	VALUE(Enum.VATRegisterRecordTypes.Outgoing) AS EntryType,
	|	VATAdvancesIssuedCredits.Counterparty AS Counterparty,
	|	VATAdvancesIssuedCredits.DocumentPayments AS TaxInvoice,
	|	VALUE(Enum.AssetKinds.PrepaymentsFromCustomerTaxAgent) AS AssetTaxClass,
	|	VATAdvancesIssuedCredits.VATRate AS VATRate,
	|	-VATAdvancesIssuedCredits.AmountExcludingVAT AS AmountExcludingVAT,
	|	-VATAdvancesIssuedCredits.VAT AS VAT,
	|	-VATAdvancesIssuedCredits.VATManag AS VATManag,
	|	UNDEFINED AS ARAPObject,
	|	TRUE AS PeriodEndTransaction,
	|	VATAdvancesIssuedCredits.FinRecordID AS FinRecordID,
	|	VATAdvancesIssuedCredits.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	VATAdvancesIssuedCredits.ReversingEntry AS ReversingEntry
	|INTO RegisteredRecordsInVATOnAdvancesIssued
	|FROM
	|	VATAdvancesIssuedCredits AS VATAdvancesIssuedCredits
	|	LEFT JOIN
	|		InvoicesReceivedInAdvance AS InvoicesReceivedInAdvance
	|	ON 
	|		VATAdvancesIssuedCredits.Organization = InvoicesReceivedInAdvance.Organization
	|		AND VATAdvancesIssuedCredits.DocumentPayments = InvoicesReceivedInAdvance.DocumentPayments
	|	
	|	LEFT JOIN
	|		CorrectedInvoicesReceivedInAdvance AS CorrectedInvoicesReceivedInAdvance
	|	ON 
	|		VATAdvancesIssuedCredits.Organization = CorrectedInvoicesReceivedInAdvance.Organization
	|		AND VATAdvancesIssuedCredits.DocumentPayments = CorrectedInvoicesReceivedInAdvance.DocumentPayments
	|
	|WHERE
	|	ISNULL(CorrectedInvoicesReceivedInAdvance.Ref.VATTaxation,
	|			InvoicesReceivedInAdvance.Ref.VATTaxation) = VALUE(Enum.VATTaxationTypes.SubjectToVATAtCustomer)
	|
	|UNION ALL
	|
	|SELECT
	|	2 AS Priority,
	|	VATAdvancesIssuedCredits.Period AS Period,
	|	VATAdvancesIssuedCredits.Recorder AS Recorder,
	|	VATAdvancesIssuedCredits.Organization AS Organization,
	|	VALUE(Enum.VATRegisterRecordTypes.Incoming) AS EntryType,
	|	VATAdvancesIssuedCredits.Counterparty AS Counterparty,
	|	VATAdvancesIssuedCredits.DocumentPayments AS TaxInvoice,
	|	CASE
	|		WHEN ISNULL(CorrectedInvoicesReceivedInAdvance.Ref.VATTaxation,
	|						InvoicesReceivedInAdvance.Ref.VATTaxation) = VALUE(Enum.VATTaxationTypes.SubjectToVATAtCustomer)
	|			THEN VALUE(Enum.AssetKinds.PrepaymentsToVendorTaxAgent)
	|		ELSE VALUE(Enum.AssetKinds.PrepaymentsToVendor)
	|	END AS AssetTaxClass,
	|	VATAdvancesIssuedCredits.VATRate AS VATRate,
	|	-VATAdvancesIssuedCredits.AmountExcludingVAT AS AmountExcludingVAT,
	|	-VATAdvancesIssuedCredits.VAT AS VAT,
	|	-VATAdvancesIssuedCredits.VATManag AS VATManag,
	|	UNDEFINED AS ARAPObject,
	|	TRUE AS PeriodEndTransaction,
	|	VATAdvancesIssuedCredits.FinRecordID AS FinRecordID,
	|	VATAdvancesIssuedCredits.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	VATAdvancesIssuedCredits.ReversingEntry AS ReversingEntry
	|FROM
	|	VATAdvancesIssuedCredits AS VATAdvancesIssuedCredits
	|	LEFT JOIN
	|		InvoicesReceivedInAdvance AS InvoicesReceivedInAdvance
	|	ON 
	|		VATAdvancesIssuedCredits.Organization = InvoicesReceivedInAdvance.Organization
	|		AND VATAdvancesIssuedCredits.DocumentPayments = InvoicesReceivedInAdvance.DocumentPayments
	|	
	|	LEFT JOIN
	|		CorrectedInvoicesReceivedInAdvance AS CorrectedInvoicesReceivedInAdvance
	|	ON 
	|		VATAdvancesIssuedCredits.Organization = CorrectedInvoicesReceivedInAdvance.Organization
	|		AND VATAdvancesIssuedCredits.DocumentPayments = CorrectedInvoicesReceivedInAdvance.DocumentPayments
	|
	|";
	
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.Execute();
	
	Return "RegisteredRecordsInVATOnAdvancesIssued";
	
EndFunction

Function CalculateVATRegisteredRecordsReverseOnCorrectedInvoices(CalculationParameters)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	1 AS Priority,
	|	VATInvoiced.Period AS Period,
	|	VATInvoiced.Recorder AS Recorder,
	|	VATInvoiced.Organization AS Organization,
	|	VALUE(Enum.VATRegisterRecordTypes.Incoming) AS EntryType,
	|	VATInvoiced.Vendor AS Counterparty,
	|	VATInvoiced.TaxInvoice AS TaxInvoice,
	|	VATInvoiced.AssetTaxClass AS AssetTaxClass,
	|	VATInvoiced.VATRate AS VATRate,
	|
	|	CASE
	|		WHEN VATInvoiced.AmountExcludingVAT = 0
	|				AND VATInvoiced.VATRate.Rate1 > 0
	|			THEN VATInvoiced.VAT * 100 / VATInvoiced.VATRate.Rate1
	|		ELSE VATInvoiced.AmountExcludingVAT
	|	END AS AmountExcludingVAT,
	|	VATInvoiced.VAT AS VAT,
	|	VATInvoiced.VATManag AS VATManag,
	|	UNDEFINED AS ARAPObject,
	|	TRUE AS PeriodEndTransaction,
	|	VATInvoiced.FinRecordID AS FinRecordID,
	|	VATInvoiced.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	VATInvoiced.ReversingEntry AS ReversingEntry
	|INTO VATRegisteredRecordsReverseOnCorrectedInvoices
	|FROM
	|	VATPresentedUnderISF AS VATInvoiced
	|WHERE
	|	VATInvoiced.Event IN (
	|		VALUE(Enum.EventsChargedVAT.VATAcceptedForDeduction),
	|		VALUE(Enum.EventsChargedVAT.Rate0IsConfirmed),
	|		VALUE(Enum.EventsChargedVAT.NotRate0IsConfirmed),
	|		VALUE(Enum.EventsChargedVAT.ReverseVATByCTI)
	|	)
	|";
	
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.SetParameter("BeginOfPeriod", CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", CalculationParameters.EndOfPeriod);
	Query.Execute();
	
	Return "VATRegisteredRecordsReverseOnCorrectedInvoices";
	
EndFunction

Function CalculateVATRegisteredRecordsReverseOnCorrectedInvoicesIssuedInAdvance(CalculationParameters)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	1 AS Priority,
	|	VATRegisterRecords.Recorder AS Recorder,
	|	VATRegisterRecords.Period AS Period,
	|	VATRegisterRecords.Organization AS Organization,
	|	VATRegisterRecords.EntryType AS EntryType,
	|	VATRegisterRecords.Counterparty AS Counterparty,
	|	VATRegisterRecords.TaxInvoice AS TaxInvoice,
	|	VATRegisterRecords.AssetTaxClass AS AssetTaxClass,
	|	VATRegisterRecords.VATRate AS VATRate,
	|	SUM(VATRegisterRecords.AmountExcludingVAT) AS AmountExcludingVAT,
	|	SUM(VATRegisterRecords.VAT) AS VAT,
	|	SUM(VATRegisterRecords.VATManag) AS VATManag,
	|	TRUE AS PeriodEndTransaction,
	|	VATRegisterRecords.ARAPObject AS ARAPObject,
	|	VATRegisterRecords.FinRecordID AS FinRecordID,
	|	VATRegisterRecords.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	FALSE AS ReversingEntry
	|INTO VATRegisteredRecordsReverseOnCorrectedInvoicesIssuedInAdvance
	|FROM
	|	(SELECT
	|		CorrectedInvoices.Ref AS Recorder,
	|		CorrectedInvoices.Period AS Period,
	|		VATRegisterRecords.Organization AS Organization,
	|		VATRegisterRecords.EntryType AS EntryType,
	|		VATRegisterRecords.Counterparty AS Counterparty,
	|		VATRegisterRecords.TaxInvoice AS TaxInvoice,
	|		VATRegisterRecords.AssetTaxClass AS AssetTaxClass,
	|		VATRegisterRecords.VATRate AS VATRate,
	|		-VATRegisterRecords.AmountExcludingVAT AS AmountExcludingVAT,
	|		-VATRegisterRecords.VAT AS VAT,
	|		-VATRegisterRecords.VATManag AS VATManag,
	|		VATRegisterRecords.ARAPObject AS ARAPObject,
	|		VATRegisterRecords.FinRecordID AS FinRecordID,
	|		VATRegisterRecords.BusinessTransactionSetting AS BusinessTransactionSetting
	|	FROM
	|		CorrectedInvoicesIssuedInAdvance AS CorrectedInvoices
	|		INNER JOIN
	|			AccumulationRegister.VATRegisterRecords AS VATRegisterRecords
	|		ON
	|			VATRegisterRecords.Organization = CorrectedInvoices.Organization
	|			AND VATRegisterRecords.TaxInvoice = CorrectedInvoices.DocumentPayments
	|			AND VATRegisterRecords.Recorder <> CorrectedInvoices.CorrectedTaxInvoice
	|			AND VATRegisterRecords.Period < &BeginOfPeriod
	|			AND VATRegisterRecords.Active
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CorrectedInvoices.Ref AS Recorder,
	|		CorrectedInvoices.Period AS Period,
	|		VATRegisterRecords.Organization AS Organization,
	|		VATRegisterRecords.EntryType AS EntryType,
	|		VATRegisterRecords.Counterparty AS Counterparty,
	|		VATRegisterRecords.TaxInvoice AS TaxInvoice,
	|		VATRegisterRecords.AssetTaxClass AS AssetTaxClass,
	|		VATRegisterRecords.VATRate AS VATRate,
	|		-VATRegisterRecords.AmountExcludingVAT AS AmountExcludingVAT,
	|		-VATRegisterRecords.VAT AS VAT,
	|		-VATRegisterRecords.VATManag AS VATManag,
	|		VATRegisterRecords.ARAPObject AS ARAPObject,
	|		VATRegisterRecords.FinRecordID AS FinRecordID,
	|		VATRegisterRecords.BusinessTransactionSetting AS BusinessTransactionSetting
	|	FROM
	|		CorrectedInvoicesIssuedInAdvance AS CorrectedInvoices
	|		INNER JOIN
	|			AccumulationRegister.VATRegisterRecords AS VATRegisterRecords
	|		ON
	|			VATRegisterRecords.Organization = CorrectedInvoices.Organization
	|			AND VATRegisterRecords.TaxInvoice = CorrectedInvoices.DocumentPayments
	|			AND VATRegisterRecords.Recorder <> CorrectedInvoices.CorrectedTaxInvoice
	|			AND VATRegisterRecords.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|			AND NOT VATRegisterRecords.PeriodEndTransaction
	|			AND VATRegisterRecords.Active) AS VATRegisterRecords
	|
	|GROUP BY
	|	VATRegisterRecords.Recorder,
	|	VATRegisterRecords.Period,
	|	VATRegisterRecords.Organization,
	|	VATRegisterRecords.EntryType,
	|	VATRegisterRecords.Counterparty,
	|	VATRegisterRecords.TaxInvoice,
	|	VATRegisterRecords.AssetTaxClass,
	|	VATRegisterRecords.VATRate,
	|	VATRegisterRecords.ARAPObject,
	|	VATRegisterRecords.FinRecordID,
	|	VATRegisterRecords.BusinessTransactionSetting
	|HAVING
	|	SUM(VATRegisterRecords.VAT) <> 0 OR SUM(VATRegisterRecords.AmountExcludingVAT) <> 0
	|";
	
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.SetParameter("BeginOfPeriod", CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", CalculationParameters.EndOfPeriod);
	Query.Execute();
	
	Return "VATRegisteredRecordsReverseOnCorrectedInvoicesIssuedInAdvance";
	
EndFunction

Function CalculateRegisteredRecordsOnVATReverseOnCorrectedInvoicesReceivedInAdvance(CalculationParameters)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	1 AS Priority,
	|	VATRegisterRecords.Recorder AS Recorder,
	|	VATRegisterRecords.Period AS Period,
	|	VATRegisterRecords.Organization AS Organization,
	|	VATRegisterRecords.EntryType AS EntryType,
	|	VATRegisterRecords.Counterparty AS Counterparty,
	|	VATRegisterRecords.TaxInvoice AS TaxInvoice,
	|	VATRegisterRecords.AssetTaxClass AS AssetTaxClass,
	|	VATRegisterRecords.VATRate AS VATRate,
	|	SUM(VATRegisterRecords.AmountExcludingVAT) AS AmountExcludingVAT,
	|	SUM(VATRegisterRecords.VAT) AS VAT,
	|	SUM(VATRegisterRecords.VATManag) AS VATManag,
	|	TRUE AS PeriodEndTransaction,
	|	VATRegisterRecords.ARAPObject AS ARAPObject,
	|	VATRegisterRecords.FinRecordID AS FinRecordID,
	|	VATRegisterRecords.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	FALSE AS ReversingEntry
	|INTO VATRegisteredRecordsReverseOnCorrectedInvoicesReceivedInAdvance
	|FROM
	|	(SELECT
	|		CorrectedInvoices.Ref AS Recorder,
	|		CorrectedInvoices.Period AS Period,
	|		VATRegisterRecords.Organization AS Organization,
	|		VATRegisterRecords.EntryType AS EntryType,
	|		VATRegisterRecords.Counterparty AS Counterparty,
	|		VATRegisterRecords.TaxInvoice AS TaxInvoice,
	|		VATRegisterRecords.AssetTaxClass AS AssetTaxClass,
	|		VATRegisterRecords.VATRate AS VATRate,
	|		-VATRegisterRecords.AmountExcludingVAT AS AmountExcludingVAT,
	|		-VATRegisterRecords.VAT AS VAT,
	|		-VATRegisterRecords.VATManag AS VATManag,
	|		VATRegisterRecords.ARAPObject AS ARAPObject,
	|		VATRegisterRecords.FinRecordID AS FinRecordID,
	|		VATRegisterRecords.BusinessTransactionSetting AS BusinessTransactionSetting
	|	FROM
	|		CorrectedInvoicesReceivedInAdvance AS CorrectedInvoices
	|		INNER JOIN
	|			AccumulationRegister.VATRegisterRecords AS VATRegisterRecords
	|		ON
	|			VATRegisterRecords.Organization = CorrectedInvoices.Organization
	|			AND VATRegisterRecords.TaxInvoice = CorrectedInvoices.DocumentPayments
	|			AND VATRegisterRecords.Recorder <> CorrectedInvoices.CorrectedTaxInvoice
	|			AND VATRegisterRecords.Period < &BeginOfPeriod
	|			AND VATRegisterRecords.Active
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CorrectedInvoices.Ref AS Recorder,
	|		CorrectedInvoices.Period AS Period,
	|		VATRegisterRecords.Organization AS Organization,
	|		VATRegisterRecords.EntryType AS EntryType,
	|		VATRegisterRecords.Counterparty AS Counterparty,
	|		VATRegisterRecords.TaxInvoice AS TaxInvoice,
	|		VATRegisterRecords.AssetTaxClass AS AssetTaxClass,
	|		VATRegisterRecords.VATRate AS VATRate,
	|		-VATRegisterRecords.AmountExcludingVAT AS AmountExcludingVAT,
	|		-VATRegisterRecords.VAT AS VAT,
	|		-VATRegisterRecords.VATManag AS VATManag,
	|		VATRegisterRecords.ARAPObject AS ARAPObject,
	|		VATRegisterRecords.FinRecordID AS FinRecordID,
	|		VATRegisterRecords.BusinessTransactionSetting AS BusinessTransactionSetting
	|	FROM
	|		CorrectedInvoicesReceivedInAdvance AS CorrectedInvoices
	|		INNER JOIN
	|			AccumulationRegister.VATRegisterRecords AS VATRegisterRecords
	|		ON
	|			VATRegisterRecords.Organization = CorrectedInvoices.Organization
	|			AND VATRegisterRecords.TaxInvoice = CorrectedInvoices.DocumentPayments
	|			AND VATRegisterRecords.Recorder <> CorrectedInvoices.CorrectedTaxInvoice
	|			AND VATRegisterRecords.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|			AND NOT VATRegisterRecords.PeriodEndTransaction
	|			AND VATRegisterRecords.Active) AS VATRegisterRecords
	|
	|GROUP BY
	|	VATRegisterRecords.Recorder,
	|	VATRegisterRecords.Period,
	|	VATRegisterRecords.Organization,
	|	VATRegisterRecords.EntryType,
	|	VATRegisterRecords.Counterparty,
	|	VATRegisterRecords.TaxInvoice,
	|	VATRegisterRecords.AssetTaxClass,
	|	VATRegisterRecords.VATRate,
	|	VATRegisterRecords.ARAPObject,
	|	VATRegisterRecords.FinRecordID,
	|	VATRegisterRecords.BusinessTransactionSetting
	|HAVING
	|	SUM(VATRegisterRecords.VAT) <> 0 OR SUM(VATRegisterRecords.AmountExcludingVAT) <> 0
	|";
	
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.SetParameter("BeginOfPeriod", CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", CalculationParameters.EndOfPeriod);
	Query.Execute();
	
	Return "VATRegisteredRecordsReverseOnCorrectedInvoicesReceivedInAdvance";
	
EndFunction

Function CalculateMovementRecordsByVATSaving(CalculationParameters, NamesOfTablesOfVATTrafficRecords)
	
	ArrayOfTextsLoggersRecord = New Array;
	ArrayOfTextsLoggersRecord.Add(
		"SELECT DISTINCT
		|	UNDEFINED AS Recorder
		|INTO LoggersRecord
		|WHERE
		|	FALSE");
	
	QueryTemplate = 
	"SELECT DISTINCT
	|	VATRegisterRecords.Recorder
	|FROM
	|	&TableName AS VATRegisterRecords";
	For Each NameOfRecordTable In NamesOfTablesOfVATTrafficRecords Do
		QueryText = StrReplace(QueryTemplate, "&TableName", NameOfRecordTable);
		ArrayOfTextsLoggersRecord.Add(QueryText);
	EndDo;
	
	ArrayOfTextsLoggersRecord.Add(
		"SELECT DISTINCT
		|	VATRegisterRecords.Recorder
		|FROM
		|	CurVATTrafficRegistrars AS VATRegisterRecords
		|
		|" + "INDEX BY Recorder");
	QueryTextLoggersRecord = StrConcat(ArrayOfTextsLoggersRecord, TMCommonUse.QuerySeparatorInJoin(True));
	
	QueryTextSave = 
	"SELECT
	|	0 AS Priority,
	|	VATRegisterRecords.Period AS Period,
	|	VATRegisterRecords.Recorder AS Recorder,
	|	VATRegisterRecords.Organization AS Organization,
	|	VATRegisterRecords.EntryType AS EntryType,
	|	VATRegisterRecords.Counterparty AS Counterparty,
	|	VATRegisterRecords.TaxInvoice AS TaxInvoice,
	|	VATRegisterRecords.VATRate AS VATRate,
	|	VATRegisterRecords.AssetTaxClass AS AssetTaxClass,
	|	VATRegisterRecords.AmountExcludingVAT AS AmountExcludingVAT,
	|	VATRegisterRecords.VAT AS VAT,
	|	VATRegisterRecords.VATManag AS VATManag,
	|	VATRegisterRecords.ARAPObject AS ARAPObject,
	|	VATRegisterRecords.PeriodEndTransaction AS PeriodEndTransaction,
	|	VATRegisterRecords.FinRecordID AS FinRecordID,
	|	VATRegisterRecords.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	VATRegisterRecords.ReversingEntry AS ReversingEntry
	|INTO VATRegisteredRecords
	|FROM
	|	AccumulationRegister.VATRegisterRecords AS VATRegisterRecords
	|	
	|	LEFT JOIN 
	|		LoggersRecord AS LoggersRecord
	|	ON 
	|		VATRegisterRecords.Recorder = LoggersRecord.Recorder
	|	
	|	LEFT JOIN
	|		Jobs AS Jobs
	|	ON
	|		Jobs.Organization = VATRegisterRecords.Organization
	|		AND Jobs.TaxInvoice = VATRegisterRecords.TaxInvoice
	|WHERE
	|	NOT LoggersRecord.Recorder IS NULL
	|	AND (VATRegisterRecords.Period < &BeginOfPeriod
	|			OR VATRegisterRecords.Period > &EndOfPeriod
	|			OR NOT VATRegisterRecords.PeriodEndTransaction
	|			OR Jobs.TaxInvoice IS NULL)
	|;
	|
	|/////////////////////////////////////////////
	|DROP LoggersRecord
	|";

	Query = New Query;
	Query.Text = 
		QueryTextLoggersRecord
		+ Common.QueryBatchSeparator()
		+ QueryTextSave;
	Query.SetParameter("BeginOfPeriod",     CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",      CalculationParameters.EndOfPeriod);
	Query.SetParameter("CompanyArray", CalculationParameters.CompanyArray);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	
	Query.Execute();
	
	Return "VATRegisteredRecords";
	
EndFunction

Procedure RecordVATRegisteredRecords(CalculationParameters, NamesOfTablesOfVATTrafficRecords)
	
	ArrayOfDataTexts = New Array;
	QueryTemplate = 
	"SELECT
	|	VATRegisterRecords.Priority AS Priority,
	|	VATRegisterRecords.Period AS Period,
	|	VATRegisterRecords.Recorder AS Recorder,
	|	VATRegisterRecords.Organization AS Organization,
	|	VATRegisterRecords.EntryType AS EntryType,
	|	VATRegisterRecords.Counterparty AS Counterparty,
	|	VATRegisterRecords.TaxInvoice AS TaxInvoice,
	|	VATRegisterRecords.VATRate AS VATRate,
	|	VATRegisterRecords.AssetTaxClass AS AssetTaxClass,
	|	VATRegisterRecords.AmountExcludingVAT AS AmountExcludingVAT,
	|	VATRegisterRecords.VAT AS VAT,
	|	VATRegisterRecords.VATManag AS VATManag,
	|	VATRegisterRecords.ARAPObject AS ARAPObject,
	|	VATRegisterRecords.PeriodEndTransaction AS PeriodEndTransaction,
	|	VATRegisterRecords.FinRecordID AS FinRecordID,
	|	VATRegisterRecords.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	VATRegisterRecords.ReversingEntry AS ReversingEntry
	|FROM
	|	&VATRegisterRecords AS VATRegisterRecords";
	For Each NameOfRecordTable In NamesOfTablesOfVATTrafficRecords Do
		QueryText = StrReplace(QueryTemplate, "&VATRegisterRecords", NameOfRecordTable);
		ArrayOfDataTexts.Add(QueryText);
	EndDo;
	TextDataToWrite = StrConcat(ArrayOfDataTexts, TMCommonUse.QuerySeparatorInJoin());
	
	Query = New Query;
	Query.Text = 
		TextDataToWrite
		+ "
		|
		|
		|ORDER BY
		|	Recorder,
		|	Period,
		|	Priority
		|
		|TOTALS BY
		|	Recorder
		|";
	
	Query.SetParameter("BeginOfPeriod",     CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",      CalculationParameters.EndOfPeriod);
	Query.SetParameter("CompanyArray", CalculationParameters.CompanyArray);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	
	SampleDocument = Query.Execute().Select(QueryResultIteration.ByGroups);
	
	While SampleDocument.Next() Do
		
		RecordSet = AccumulationRegisters.VATRegisterRecords.CreateRecordSet();
		RecordSet.Filter.Recorder.Set(SampleDocument.Recorder);
		
		// The dates of the ban are not checked, because we get here when performing tasks, 
		// and when creating tasks, the dates of the ban are controlled. 
		RecordSet.AdditionalProperties.Insert("SkipPeriodClosingCheck", True);
		
		Selection = SampleDocument.Select();
		While Selection.Next() Do
			
			NewRecord = RecordSet.Add();
			FillPropertyValues(NewRecord, Selection);
			
		EndDo;
		
		RecordSet.Write();
		
	EndDo;
	
EndProcedure

Procedure ClearVATTraffic(CalculationParameters, NamesOfTablesOfVATTrafficRecords)
	
	ArrayOfTextsLoggersRecord = New Array;
	ArrayOfTextsLoggersRecord.Add(
		"SELECT
		|	UNDEFINED AS Recorder
		|INTO LoggersRecord
		|WHERE
		|	FALSE");
	
	QueryTemplate = 
	"SELECT DISTINCT
	|	VATRegisterRecords.Recorder
	|FROM
	|	&TableName AS VATRegisterRecords";
	For Each NameOfRecordTable In NamesOfTablesOfVATTrafficRecords Do
		QueryText = StrReplace(QueryTemplate, "&TableName", NameOfRecordTable);
		ArrayOfTextsLoggersRecord.Add(QueryText);
	EndDo;
	
	QueryTextLoggersRecord = StrConcat(ArrayOfTextsLoggersRecord, TMCommonUse.QuerySeparatorInJoin(True));
	QueryTextLoggersRecord = 
		QueryTextLoggersRecord
		+ "
		|INDEX BY
		|	Recorder";
	
	QueryTextOutdatedLoggers = 
	"SELECT
	|	OutdatedLoggers.Recorder
	|FROM
	|	CurVATTrafficRegistrars AS OutdatedLoggers
	|	LEFT JOIN
	|		LoggersRecord AS LoggersRecord
	|	ON
	|		OutdatedLoggers.Recorder = LoggersRecord.Recorder
	|
	|WHERE
	|	LoggersRecord.Recorder IS NULL
	|;
	|
	|//////////////////////////////////////////////
	|DROP LoggersRecord
	|";
	
	Query = New Query;
	Query.Text = QueryTextLoggersRecord
		+ Common.QueryBatchSeparator()
		+ QueryTextOutdatedLoggers;
	
	Query.SetParameter("BeginOfPeriod",     CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",  CalculationParameters.EndOfPeriod);
	Query.SetParameter("CompanyArray", CalculationParameters.CompanyArray);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	
	SampleDocument = Query.Execute().Select();
	While SampleDocument.Next() Do
		
		RecordSet = AccumulationRegisters.VATRegisterRecords.CreateRecordSet();
		RecordSet.Filter.Recorder.Set(SampleDocument.Recorder);
		RecordSet.Write(True);
		
	EndDo;

EndProcedure

#EndRegion

#Region FormationOfMovementOfAdjustmentOfDepreciationOfVATOnExpenses

Procedure CreateAdjustmentForDeductingVATForExpenses(CalculationParameters)
	
	GetCurRecordersOfVATDeductionForExpenses(CalculationParameters);
	CalculateVATWriteOffAdjustmentForExpenses(CalculationParameters);
	CalculateOtherExpensesSaving(CalculationParameters);
	CalculateRegisteredRecordsOnOtherAssetsLiabilitiesSaving(CalculationParameters);
	
	RecordVATOtherExpenses(CalculationParameters);
	RecordVATRegisteredRecordsOnOtherAssetsLiabilities(CalculationParameters);
	ClearVATOtherExpenses(CalculationParameters);
	ClearVATRegisteredRecordsOnOtherAssetsLiabilities(CalculationParameters);
	
EndProcedure

Procedure GetCurRecordersOfVATDeductionForExpenses(CalculationParameters)
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	OtherExpenses.Recorder AS Recorder
	|INTO CurRegistrarsOtherExpenses
	|FROM
	|	AccumulationRegister.OtherExpenses AS OtherExpenses
	|	INNER JOIN
	|		CurRegistrarsVATCharged AS VATInvoiced
	|	ON
	|		OtherExpenses.Recorder = VATInvoiced.Recorder
	|WHERE
	|	OtherExpenses.BusinessOperation = VALUE(Enum.BusinessTransactions.VATOnAcquiredAssetsWriteOff)
	|	AND NOT OtherExpenses.Recorder REFS Document.VATWritingOffAsExpenses
	|	AND NOT OtherExpenses.CalculationOfCost
	|
	|INDEX BY
	|	Recorder
	|;
	|SELECT DISTINCT
	|	OtherAssetsAndLiabilitiesRecords.Recorder AS Recorder
	|INTO CurrentRegistrarsOfMovementOnOtherAssetsLiabilities
	|FROM
	|	AccumulationRegister.OtherAssetsAndLiabilitiesRecords AS OtherAssetsAndLiabilitiesRecords
	|	INNER JOIN
	|		CurRegistrarsVATCharged AS VATInvoiced
	|	ON
	|		OtherAssetsAndLiabilitiesRecords.Recorder = VATInvoiced.Recorder
	|WHERE
	|	OtherAssetsAndLiabilitiesRecords.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.VATOnAcquiredAssetsWriteOff)
	|	AND NOT OtherAssetsAndLiabilitiesRecords.Recorder REFS Document.VATWritingOffAsExpenses
	|	AND NOT OtherAssetsAndLiabilitiesRecords.CalculationOfCost
	|
	|INDEX BY
	|	Recorder
	|";
	
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.Execute();
	
EndProcedure

Procedure CalculateVATWriteOffAdjustmentForExpenses(CalculationParameters)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	1                                        AS Priority,
	|	VATInvoiced.Period                  AS Period,
	|	VALUE(AccumulationRecordType.Receipt)   AS RecordType,
	|	VATInvoiced.Recorder             AS Recorder,
	|	VATInvoiced.Organization             AS Organization,
	|	VATInvoiced.Department           AS Department,
	|	VATInvoiced.LineOfBusiness AS LineOfBusiness,
	|	VATInvoiced.ExpenseItem          AS ExpenseItem,
	|	VATInvoiced.DimensionOfExpenses       AS DimensionOfExpenses,
	|	0                                        AS Sum,
	|	0                                        AS AmountExcludingVAT,
	|	VATInvoiced.VAT                     AS SumCompl,
	|	VATInvoiced.VATManag                  AS SumMan,
	|	CASE 
	|		WHEN NOT VATInvoiced.ExpenseItem.EnteredInTaxAccounting THEN
	|			VATInvoiced.VAT 
	|		ELSE 0
	|	END                                    AS PermanentDifference,
	|	0                                        AS CostTD,
	|	FALSE                                     AS ReversingEntry,
	|	VALUE(Enum.BusinessTransactions.VATOnAcquiredAssetsWriteOff) AS BusinessOperation,
	|	VATInvoiced.FinRecordID AS FinRecordID,
	|	VATInvoiced.BusinessTransactionSetting AS BusinessTransactionSetting
	|INTO OtherExpenses
	|FROM
	|	VATChargedChangeOfActivity AS VATInvoiced
	|	INNER JOIN 
	|		VATDeductionsForExpenses
	|	ON 
	|		VATInvoiced.Organization = VATDeductionsForExpenses.Organization
	|		AND VATInvoiced.TaxInvoice = VATDeductionsForExpenses.TaxInvoice
	|WHERE
	|	VATInvoiced.Event = VALUE(Enum.EventsChargedVAT.VATWritingOffAsExpenses)
	|	AND VALUETYPE(VATDeductionsForExpenses.ExpenseItem) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|;
	|
	|SELECT
	|	1                                         AS Priority,
	|	VATInvoiced.Period                   AS Period,
	|	VALUE(AccumulationRecordType.Receipt)    AS RecordType,
	|	VATDeductionsForExpenses.VATWritingOffAsExpenses AS Recorder,
	|	VATInvoiced.Organization              AS Organization,
	|	VATInvoiced.Department            AS Department,
	|	VATInvoiced.LineOfBusiness  AS LineOfBusiness,
	|	VATDeductionsForExpenses.ExpenseItem       AS AssetRef,
	|	VATDeductionsForExpenses.AssetsLiabilitiesDimension  AS Dimension,
	|	VATDeductionsForExpenses.GLAccountSettings      AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
	|
	|	0                                               AS AmountIncludingVAT,
	|	0                                               AS AmountExcludingVAT,
	|	VATInvoiced.VAT                            AS SumCompl,
	|	VATInvoiced.VATManag                         AS SumMan,
	|	VATInvoiced.VAT                            AS PermanentDifference,
	|	0                                               AS CostTD,
	|	
	|	VATInvoiced.RowID            AS FinRecordID,
	|	VATInvoiced.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	FALSE                                            AS ReversingEntry
	|INTO OtherAssetsAndLiabilitiesRecords
	|FROM
	|	VATChargedChangeOfActivity AS VATInvoiced
	|	INNER JOIN 
	|		VATDeductionsForExpenses
	|	ON 
	|		VATInvoiced.Organization = VATDeductionsForExpenses.Organization
	|		AND VATInvoiced.TaxInvoice = VATDeductionsForExpenses.TaxInvoice
	|WHERE
	|	VATInvoiced.Event = VALUE(Enum.EventsChargedVAT.VATWritingOffAsExpenses)
	|	AND VALUETYPE(VATDeductionsForExpenses.ExpenseItem) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|
	|UNION ALL
	|
	|SELECT
	|	1                                              AS Priority,
	|	VATPresentedStorno.Period                  AS Period,
	|	VALUE(AccumulationRecordType.Receipt)         AS RecordType,
	|	VATDeductionsForExpenses.VATWritingOffAsExpenses      AS Recorder,
	|	VATPresentedStorno.Organization             AS Organization,
	|	VATPresentedStorno.Department           AS Department,
	|	VATPresentedStorno.LineOfBusiness AS LineOfBusiness,
	|	VATDeductionsForExpenses.ExpenseItem            AS AssetRef,
	|	VATDeductionsForExpenses.AssetsLiabilitiesDimension  AS Dimension,
	|	VATDeductionsForExpenses.GLAccountSettings      AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
	|
	|	0                                                     AS AmountIncludingVAT,
	|	0                                                     AS AmountExcludingVAT,
	|	VATPresentedStorno.VAT                            AS SumCompl,
	|	VATPresentedStorno.VATManag                         AS SumMan,
	|	VATPresentedStorno.VAT                            AS PermanentDifference,
	|	0                                                     AS CostTD,
	|	
	|	VATPresentedStorno.RowID            AS FinRecordID,
	|	VATPresentedStorno.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	VATPresentedStorno.ReversingEntry                         AS ReversingEntry
	|FROM
	|	VATPresentedStorno AS VATPresentedStorno
	|	INNER JOIN 
	|		VATDeductionsForExpenses
	|	ON 
	|		VATPresentedStorno.Organization = VATDeductionsForExpenses.Organization
	|		AND VATPresentedStorno.TaxInvoice = VATDeductionsForExpenses.TaxInvoice
	|WHERE
	|	VATPresentedStorno.Event = VALUE(Enum.EventsChargedVAT.VATWritingOffAsExpenses)
	|	AND VALUETYPE(VATPresentedStorno.Recorder) <> TYPE(Document.VATAllocation)
	|	AND VALUETYPE(VATDeductionsForExpenses.ExpenseItem) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|
	|";
	
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.Execute();
	
EndProcedure

Procedure CalculateOtherExpensesSaving(CalculationParameters)
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	OtherExpenses.Recorder
	|INTO LoggersRecord
	|FROM
	|	OtherExpenses AS OtherExpenses
	|
	|UNION
	|
	|SELECT DISTINCT
	|	OtherExpenses.Recorder
	|FROM
	|	CurRegistrarsOtherExpenses AS OtherExpenses
	|;
	|
	|SELECT
	|	0 AS Priority,
	|	OtherExpenses.Period,
	|	OtherExpenses.RecordType,
	|	OtherExpenses.Recorder,
	|	OtherExpenses.Organization,
	|	OtherExpenses.Department,
	|	OtherExpenses.LineOfBusiness,
	|	OtherExpenses.ExpenseItem,
	|	OtherExpenses.DimensionOfExpenses,
	|	OtherExpenses.Sum,
	|	OtherExpenses.AmountExcludingVAT,
	|	OtherExpenses.SumCompl,
	|	OtherExpenses.SumMan,
	|	OtherExpenses.PermanentDifference,
	|	OtherExpenses.CostTD,
	|	OtherExpenses.BusinessOperation,
	|	OtherExpenses.ItemsLocationAttributes,
	|	OtherExpenses.AccountCr,
	|	OtherExpenses.AmountOfOtherAssets,
	|	OtherExpenses.RegistrationWithTaxAuthority,
	|	OtherExpenses.DocumentRegisterRecords,
	|	OtherExpenses.CorExpenseItem,
	|	OtherExpenses.CorCompany,
	|	OtherExpenses.CostShare,
	|	OtherExpenses.DebitBusinessUnit,
	|	OtherExpenses.CorExpenditureDimension,
	|	OtherExpenses.ProductsGroup,
	|	OtherExpenses.CorCostElement,
	|	OtherExpenses.CalculationOfCost,
	|	OtherExpenses.LotCalculation,
	|	OtherExpenses.RowID,
	|	OtherExpenses.CorLineOfBusiness,
	|	OtherExpenses.CorProvisionObject,
	|	OtherExpenses.AdjReserveKind,
	|	OtherExpenses.SourceKind,
	|	OtherExpenses.FinRecordID,
	|	OtherExpenses.BusinessTransactionSetting,
	|	OtherExpenses.ReversingEntry,
	|	OtherExpenses.DocumentCalculation,
	|	OtherExpenses.MonthEndClosingMode
	|	
	|INTO OtherExpensesSaving
	|FROM
	|	AccumulationRegister.OtherExpenses AS OtherExpenses
	|	
	|	INNER JOIN 
	|		LoggersRecord AS LoggersRecord
	|	ON 
	|		OtherExpenses.Recorder = LoggersRecord.Recorder
	|	
	|WHERE
	|	OtherExpenses.BusinessOperation <> VALUE(Enum.BusinessTransactions.VATOnAcquiredAssetsWriteOff)
	|	OR OtherExpenses.LotCalculation
	|	OR OtherExpenses.CalculationOfCost
	|	OR NOT OtherExpenses.Organization IN (&CompanyArray)
	|	OR OtherExpenses.Period < &BeginOfPeriod 
	|	OR OtherExpenses.Period > &EndOfPeriod 
	|;
	|
	|/////////////////////////////////////////////
	|DROP LoggersRecord";
	
	Query.SetParameter("BeginOfPeriod",     CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",      CalculationParameters.EndOfPeriod);
	Query.SetParameter("CompanyArray", CalculationParameters.CompanyArray);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	
	Query.Execute();
	
EndProcedure

Procedure CalculateRegisteredRecordsOnOtherAssetsLiabilitiesSaving(CalculationParameters)
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	OtherAssetsAndLiabilitiesRecords.Recorder
	|INTO LoggersRecord
	|FROM
	|	OtherAssetsAndLiabilitiesRecords AS OtherAssetsAndLiabilitiesRecords
	|
	|UNION
	|
	|SELECT DISTINCT
	|	OtherAssetsAndLiabilitiesRecords.Recorder
	|FROM
	|	CurrentRegistrarsOfMovementOnOtherAssetsLiabilities AS OtherAssetsAndLiabilitiesRecords
	|;
	|
	|SELECT
	|	0 AS Priority,
	|	OtherAssetsAndLiabilitiesRecords.Period,
	|	OtherAssetsAndLiabilitiesRecords.Recorder,
	|	OtherAssetsAndLiabilitiesRecords.Organization,
	|	OtherAssetsAndLiabilitiesRecords.Department,
	|	OtherAssetsAndLiabilitiesRecords.LineOfBusiness,
	|	OtherAssetsAndLiabilitiesRecords.AssetRef,
	|	OtherAssetsAndLiabilitiesRecords.Dimension,
	|	OtherAssetsAndLiabilitiesRecords.GLAccountSettings AS GLAccountSettings,
	|	OtherAssetsAndLiabilitiesRecords.DebitCredit AS DebitCredit,
	|	OtherAssetsAndLiabilitiesRecords.AmountExcludingVAT,
	|	OtherAssetsAndLiabilitiesRecords.AmountIncludingVAT,
	|	OtherAssetsAndLiabilitiesRecords.SumCompl,
	|	OtherAssetsAndLiabilitiesRecords.SumMan,
	|	OtherAssetsAndLiabilitiesRecords.PermanentDifference,
	|	OtherAssetsAndLiabilitiesRecords.CostTD,
	|	OtherAssetsAndLiabilitiesRecords.ReversingEntry,
	|	OtherAssetsAndLiabilitiesRecords.BusinessTransactionSetting,
	|	OtherAssetsAndLiabilitiesRecords.FinRecordID,
	|	OtherAssetsAndLiabilitiesRecords.CalculationOfCost,
	|	OtherAssetsAndLiabilitiesRecords.SourceKind
	|	
	|INTO RegisteredRecordsOnOtherAssetsLiabilitiesPreservation
	|FROM
	|	AccumulationRegister.OtherAssetsAndLiabilitiesRecords AS OtherAssetsAndLiabilitiesRecords
	|	
	|	INNER JOIN 
	|		LoggersRecord AS LoggersRecord
	|	ON 
	|		OtherAssetsAndLiabilitiesRecords.Recorder = LoggersRecord.Recorder
	|	
	|WHERE
	|	OtherAssetsAndLiabilitiesRecords.BusinessTransactionSetting <> VALUE(Catalog.BusinessTransactionsSettings.VATOnAcquiredAssetsWriteOff)
	|	OR NOT OtherAssetsAndLiabilitiesRecords.Organization IN (&CompanyArray)
	|	OR OtherAssetsAndLiabilitiesRecords.Period < &BeginOfPeriod 
	|	OR OtherAssetsAndLiabilitiesRecords.Period > &EndOfPeriod 
	|;
	|
	|/////////////////////////////////////////////
	|DROP LoggersRecord";
	
	Query.SetParameter("BeginOfPeriod",     CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",      CalculationParameters.EndOfPeriod);
	Query.SetParameter("CompanyArray", CalculationParameters.CompanyArray);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	
	Query.Execute();
	
EndProcedure

Procedure RecordVATOtherExpenses(CalculationParameters)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	OtherExpenses.Priority,
	|	OtherExpenses.Period,
	|	OtherExpenses.RecordType,
	|	OtherExpenses.Recorder,
	|	OtherExpenses.Organization,
	|	OtherExpenses.Department,
	|	OtherExpenses.LineOfBusiness,
	|	OtherExpenses.ExpenseItem,
	|	OtherExpenses.DimensionOfExpenses,
	|	OtherExpenses.Sum,
	|	OtherExpenses.AmountExcludingVAT,
	|	OtherExpenses.SumCompl,
	|	OtherExpenses.SumMan,
	|	OtherExpenses.PermanentDifference,
	|	OtherExpenses.CostTD,
	|	OtherExpenses.BusinessOperation,
	|	OtherExpenses.ItemsLocationAttributes,
	|	OtherExpenses.AccountCr,
	|	OtherExpenses.AmountOfOtherAssets,
	|	OtherExpenses.RegistrationWithTaxAuthority,
	|	OtherExpenses.DocumentRegisterRecords,
	|	OtherExpenses.CorExpenseItem,
	|	OtherExpenses.CorCompany,
	|	OtherExpenses.CostShare,
	|	OtherExpenses.DebitBusinessUnit,
	|	OtherExpenses.CorExpenditureDimension,
	|	OtherExpenses.ProductsGroup,
	|	OtherExpenses.CorCostElement,
	|	OtherExpenses.CalculationOfCost,
	|	OtherExpenses.LotCalculation,
	|	OtherExpenses.RowID,
	|	OtherExpenses.CorLineOfBusiness,
	|	OtherExpenses.CorProvisionObject,
	|	OtherExpenses.AdjReserveKind,
	|	OtherExpenses.SourceKind,
	|	OtherExpenses.FinRecordID,
	|	OtherExpenses.BusinessTransactionSetting,
	|	OtherExpenses.ReversingEntry,
	|	OtherExpenses.DocumentCalculation,
	|	OtherExpenses.MonthEndClosingMode
	|FROM
	|	OtherExpensesSaving AS OtherExpenses
	|
	|UNION ALL
	|
	|SELECT
	|	OtherExpenses.Priority,
	|	OtherExpenses.Period,
	|	OtherExpenses.RecordType,
	|	OtherExpenses.Recorder,
	|	OtherExpenses.Organization,
	|	OtherExpenses.Department,
	|	OtherExpenses.LineOfBusiness,
	|	OtherExpenses.ExpenseItem,
	|	OtherExpenses.DimensionOfExpenses,
	|	OtherExpenses.Sum,
	|	OtherExpenses.AmountExcludingVAT,
	|	OtherExpenses.SumCompl,
	|	OtherExpenses.SumMan,
	|	OtherExpenses.PermanentDifference,
	|	OtherExpenses.CostTD,
	|	OtherExpenses.BusinessOperation,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	OtherExpenses.FinRecordID,
	|	OtherExpenses.BusinessTransactionSetting,
	|	OtherExpenses.ReversingEntry,
	|	UNDEFINED,
	|	UNDEFINED
	|FROM
	|	OtherExpenses AS OtherExpenses
	|
	|ORDER BY
	|	Recorder,
	|	Period,
	|	Priority
	|
	|TOTALS BY
	|	Recorder
	|";
	
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	
	SampleDocument = Query.Execute().Select(QueryResultIteration.ByGroups);
	While SampleDocument.Next() Do
		
		RecordSet = AccumulationRegisters.OtherExpenses.CreateRecordSet();
		RecordSet.Filter.Recorder.Set(SampleDocument.Recorder);
		
		Selection = SampleDocument.Select();
		While Selection.Next() Do
			
			NewRecord = RecordSet.Add();
			FillPropertyValues(NewRecord, Selection);
			
		EndDo;
		
		RecordSet.Write();
		
	EndDo;

EndProcedure

Procedure RecordVATRegisteredRecordsOnOtherAssetsLiabilities(CalculationParameters)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	OtherAssetsAndLiabilitiesRecords.Priority,
	|	OtherAssetsAndLiabilitiesRecords.Period,
	|	OtherAssetsAndLiabilitiesRecords.Recorder,
	|	OtherAssetsAndLiabilitiesRecords.Organization,
	|	OtherAssetsAndLiabilitiesRecords.Department,
	|	OtherAssetsAndLiabilitiesRecords.LineOfBusiness,
	|	OtherAssetsAndLiabilitiesRecords.AssetRef,
	|	OtherAssetsAndLiabilitiesRecords.Dimension,
	|	OtherAssetsAndLiabilitiesRecords.GLAccountSettings,
	|	OtherAssetsAndLiabilitiesRecords.DebitCredit,
	|	OtherAssetsAndLiabilitiesRecords.AmountExcludingVAT,
	|	OtherAssetsAndLiabilitiesRecords.AmountIncludingVAT,
	|	OtherAssetsAndLiabilitiesRecords.SumCompl,
	|	OtherAssetsAndLiabilitiesRecords.SumMan,
	|	OtherAssetsAndLiabilitiesRecords.PermanentDifference,
	|	OtherAssetsAndLiabilitiesRecords.CostTD,
	|	OtherAssetsAndLiabilitiesRecords.ReversingEntry,
	|	OtherAssetsAndLiabilitiesRecords.BusinessTransactionSetting,
	|	OtherAssetsAndLiabilitiesRecords.FinRecordID,
	|	OtherAssetsAndLiabilitiesRecords.CalculationOfCost,
	|	OtherAssetsAndLiabilitiesRecords.SourceKind
	|FROM
	|	RegisteredRecordsOnOtherAssetsLiabilitiesPreservation AS OtherAssetsAndLiabilitiesRecords
	|
	|UNION ALL
	|
	|SELECT
	|	OtherAssetsAndLiabilitiesRecords.Priority,
	|	OtherAssetsAndLiabilitiesRecords.Period,
	|	OtherAssetsAndLiabilitiesRecords.Recorder,
	|	OtherAssetsAndLiabilitiesRecords.Organization,
	|	OtherAssetsAndLiabilitiesRecords.Department,
	|	OtherAssetsAndLiabilitiesRecords.LineOfBusiness,
	|	OtherAssetsAndLiabilitiesRecords.AssetRef,
	|	OtherAssetsAndLiabilitiesRecords.Dimension,
	|	OtherAssetsAndLiabilitiesRecords.GLAccountSettings,
	|	OtherAssetsAndLiabilitiesRecords.DebitCredit,
	|	OtherAssetsAndLiabilitiesRecords.AmountExcludingVAT,
	|	OtherAssetsAndLiabilitiesRecords.AmountIncludingVAT,
	|	OtherAssetsAndLiabilitiesRecords.SumCompl,
	|	OtherAssetsAndLiabilitiesRecords.SumMan,
	|	OtherAssetsAndLiabilitiesRecords.PermanentDifference,
	|	OtherAssetsAndLiabilitiesRecords.CostTD,
	|	OtherAssetsAndLiabilitiesRecords.ReversingEntry,
	|	OtherAssetsAndLiabilitiesRecords.BusinessTransactionSetting,
	|	OtherAssetsAndLiabilitiesRecords.FinRecordID,
	|	UNDEFINED,
	|	UNDEFINED
	|FROM
	|	OtherAssetsAndLiabilitiesRecords AS OtherAssetsAndLiabilitiesRecords
	|
	|ORDER BY
	|	Recorder,
	|	Period,
	|	Priority
	|
	|TOTALS BY
	|	Recorder
	|";
	
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	
	SampleDocument = Query.Execute().Select(QueryResultIteration.ByGroups);
	While SampleDocument.Next() Do
		
		RecordSet = AccumulationRegisters.OtherAssetsAndLiabilitiesRecords.CreateRecordSet();
		RecordSet.Filter.Recorder.Set(SampleDocument.Recorder);
		
		Selection = SampleDocument.Select();
		While Selection.Next() Do
			
			NewRecord = RecordSet.Add();
			FillPropertyValues(NewRecord, Selection);
			
		EndDo;
		
		RecordSet.Write();
		
	EndDo;

EndProcedure

Procedure ClearVATOtherExpenses(CalculationParameters)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	OutdatedLoggers.Recorder
	|FROM
	|	CurRegistrarsOtherExpenses AS OutdatedLoggers
	|	LEFT JOIN
	|		OtherExpenses AS OtherExpenses
	|	ON 
	|		OutdatedLoggers.Recorder = OtherExpenses.Recorder
	|		
	|	LEFT JOIN
	|		OtherExpensesSaving AS OtherExpensesSaving
	|	ON 
	|		OutdatedLoggers.Recorder = OtherExpensesSaving.Recorder
	|WHERE
	|	OtherExpenses.Recorder IS NULL
	|	AND OtherExpensesSaving.Recorder IS NULL
	|";
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	
	SampleDocument = Query.Execute().Select();
	While SampleDocument.Next() Do
		
		RecordSet = AccumulationRegisters.OtherExpenses.CreateRecordSet();
		RecordSet.Filter.Recorder.Set(SampleDocument.Recorder);
		RecordSet.Write(True);
		
	EndDo;

EndProcedure

Procedure ClearVATRegisteredRecordsOnOtherAssetsLiabilities(CalculationParameters)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	OutdatedLoggers.Recorder
	|FROM
	|	CurrentRegistrarsOfMovementOnOtherAssetsLiabilities AS OutdatedLoggers
	|	LEFT JOIN
	|		OtherAssetsAndLiabilitiesRecords AS OtherAssetsAndLiabilitiesRecords
	|	ON 
	|		OutdatedLoggers.Recorder = OtherAssetsAndLiabilitiesRecords.Recorder
	|		
	|	LEFT JOIN
	|		RegisteredRecordsOnOtherAssetsLiabilitiesPreservation AS RegisteredRecordsOnOtherAssetsLiabilitiesPreservation
	|	ON 
	|		OutdatedLoggers.Recorder = RegisteredRecordsOnOtherAssetsLiabilitiesPreservation.Recorder
	|WHERE
	|	OtherAssetsAndLiabilitiesRecords.Recorder IS NULL
	|	AND RegisteredRecordsOnOtherAssetsLiabilitiesPreservation.Recorder IS NULL
	|";
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	
	SampleDocument = Query.Execute().Select();
	While SampleDocument.Next() Do
		
		RecordSet = AccumulationRegisters.OtherAssetsAndLiabilitiesRecords.CreateRecordSet();
		RecordSet.Filter.Recorder.Set(SampleDocument.Recorder);
		RecordSet.Write(True);
		
	EndDo;

EndProcedure

// Displays error messages about specifying the VAT amount in the table part of the purchase document.
//
// Parameters:
// Selection         - QueryResultSelection - sampling from the query result
// DescriptionOfSalesDocument - Structure - Document description 
// Cancel           - Boolean - flag for refusing to carry out the document.
//
Procedure ReportErrorsCorrectnessOfPurchaseAmountAndVATAmount(Val Selection, DescriptionOfSalesDocument, Cancel) Export
	
	While Selection.Next() Do
		
		ErrorText = NStr("vi = 'Thuế GTGT %VATAmount% %Currency% thuế suất ""%VATRate%"" nhiều hơn dòng %Sum% %Currency%';
						|ru = 'Сумма НДС %VATAmount% %Currency% при ставке ""%VATRate%"" больше общей суммы по строке %Sum% %Currency%';
						|en = 'The VAT amount %VATAmount% %Currency% at rate %VATRate% exceeds the total amount for the line %Sum% %Currency%'; fa = 'The VAT amount %VATAmount% %Currency% at rate %VATRate% exceeds the total amount for the line %Sum% %Currency%';
						|it = 'Importo IVA %VATAmount% %Currency% при ставке ""%VATRate%"" больше общей суммы по строке %Sum% %Currency%';
						|pl = 'Wartość VAT %VATAmount% %Currency% przy stawce ""%VATRate%"" jest większa niż ogólna wartość wg wiersza %Sum% %Currency%';
						|tr = 'KDV tutarı %VATAmount% ""%VATRate%"" oranındaki %Currency%, satırındaki toplam tutardan büyük %Sum% %Currency%'");
		ErrorText = StrReplace(ErrorText, "%VATAmount%",          Selection.VATAmount);
		ErrorText = StrReplace(ErrorText, "%Sum%",             Selection.Sum);
		ErrorText = StrReplace(ErrorText, "%VATRate%",         Selection.VATRate);
		ErrorText = StrReplace(ErrorText, "%Currency%",            Selection.Currency);
		
		ErrorAddress = " " + NStr("vi = 'trong dòng %LineNumber% danh sách ""%PresentationOfTS%""';
									|ru = 'в строке %LineNumber% списка ""%PresentationOfTS%""';
									|en = 'in line %LineNumber% of the ""%PresentationOfTS%"" list'; fa = 'in line %LineNumber% of the ""%PresentationOfTS%"" list';
									|it = 'nella riga %LineNumber% dell''elenco ""%PresentationOfTS%""';
									|pl = 'w wierszu %LineNumber% listy ""%PresentationOfTS%""';
									|tr = '""%PresentationOfTS%"" listesinin %LineNumber% satırında'");
		ErrorAddress = StrReplace(ErrorAddress, "%LineNumber%",     Selection.LineNumber);
		ErrorAddress = StrReplace(ErrorAddress, "%PresentationOfTS%", DescriptionOfSalesDocument.PresentationOfTS);
		
		SalesServer.ReportErrorToUser(
			ErrorText + ErrorAddress,
			DescriptionOfSalesDocument.DocumentPurchases,
			CommonClientServer.PathToTabularSection(DescriptionOfSalesDocument.TSName, Selection.LineNumber, "VATAmount"),
			Cancel);
				
	EndDo;
	
EndProcedure

#EndRegion

#Region FinancialAccounting

Procedure ReturnDocumentsToInternationalAccounting(CalculationParameters)
	
#Region TextOfVATSubmitted
	
	TextOfVATSubmitted = "
	|SELECT DISTINCT
	|	VATInvoiced.Period AS Period,
	|	VATInvoiced.Recorder AS Document,
	|	VATInvoiced.Organization AS Organization,
	|	BEGINOFPERIOD(VATInvoiced.Period, DAY) AS DateRecord
	|INTO DocumentsToBeReflected
	|FROM
	|	VATPresentedAcceptanceForDeduction AS VATInvoiced
	|
	|UNION
	|
	|SELECT DISTINCT
	|	VATInvoiced.Period AS Period,
	|	VATInvoiced.Recorder AS Document,
	|	VATInvoiced.Organization AS Organization,
	|	BEGINOFPERIOD(VATInvoiced.Period, DAY) AS DateRecord
	|FROM
	|	VATChargedChangeOfActivity AS VATInvoiced
	|
	|UNION
	|
	|SELECT DISTINCT
	|	VATInvoiced.Period AS Period,
	|	VATInvoiced.Recorder AS Document,
	|	VATInvoiced.Organization AS Organization,
	|	BEGINOFPERIOD(VATInvoiced.Period, DAY) AS DateRecord
	|FROM
	|	VATChargedChangeOfDirection AS VATInvoiced
	|
	|UNION
	|
	|SELECT DISTINCT
	|	VATInvoiced.Period AS Period,
	|	VATInvoiced.Recorder AS Document,
	|	VATInvoiced.Organization AS Organization,
	|	BEGINOFPERIOD(VATInvoiced.Period, DAY) AS DateRecord
	|FROM
	|	VATPresentedRecoveryUnderTypeOfActivity AS VATInvoiced
	|
	|UNION
	|
	|SELECT DISTINCT
	|	VATInvoiced.Period AS Period,
	|	VATInvoiced.Recorder AS Document,
	|	VATInvoiced.Organization AS Organization,
	|	BEGINOFPERIOD(VATInvoiced.Period, DAY) AS DateRecord
	|FROM
	|	VATPresentedRecoveryByCSF AS VATInvoiced
	|
	|UNION
	|
	|SELECT DISTINCT
	|	VATInvoiced.Period AS Period,
	|	VATInvoiced.Recorder AS Document,
	|	VATInvoiced.Organization AS Organization,
	|	BEGINOFPERIOD(VATInvoiced.Period, DAY) AS DateRecord
	|FROM
	|	VATPresentedUnderISF AS VATInvoiced
	|
	|UNION
	|
	|SELECT DISTINCT
	|	VATInvoiced.Period AS Period,
	|	VATInvoiced.Recorder AS Document,
	|	VATInvoiced.Organization AS Organization,
	|	BEGINOFPERIOD(VATInvoiced.Period, DAY) AS DateRecord
	|FROM
	|	CurRegistrarsVATCharged AS VATInvoiced
	|";
	
#EndRegion
	
#Region TextVATAdvancesReceived
	
	TextVATAdvancesReceived = "
	|SELECT DISTINCT
	|	VATPrepaymentsFromCustomer.Period AS Period,
	|	VATPrepaymentsFromCustomer.Recorder AS Document,
	|	VATPrepaymentsFromCustomer.Organization AS Organization,
	|	BEGINOFPERIOD(VATPrepaymentsFromCustomer.Period, DAY) AS DateRecord
	|FROM
	|	VATAdvancesReceivedStorno AS VATPrepaymentsFromCustomer
	|WHERE
	|	VATPrepaymentsFromCustomer.VAT <> 0
	|
	|UNION
	|
	|SELECT DISTINCT
	|	VATPrepaymentsFromCustomer.Period AS Period,
	|	VATPrepaymentsFromCustomer.Recorder AS Document,
	|	VATPrepaymentsFromCustomer.Organization AS Organization,
	|	BEGINOFPERIOD(VATPrepaymentsFromCustomer.Period, DAY) AS DateRecord
	|FROM
	|	VATAdvancesReceivedUnderISF AS VATPrepaymentsFromCustomer
	|WHERE
	|	VATPrepaymentsFromCustomer.VAT <> 0
	|
	|UNION
	|
	|SELECT DISTINCT
	|	VATPrepaymentsFromCustomer.Period AS Period,
	|	VATPrepaymentsFromCustomer.Recorder AS Document,
	|	VATPrepaymentsFromCustomer.Organization AS Organization,
	|	BEGINOFPERIOD(VATPrepaymentsFromCustomer.Period, DAY) AS DateRecord
	|FROM
	|	VATAdvancesReceivedCredits AS VATPrepaymentsFromCustomer
	|WHERE
	|	VATPrepaymentsFromCustomer.VAT <> 0
	|
	|UNION
	|
	|SELECT DISTINCT
	|	VATPrepaymentsFromCustomer.Period AS Period,
	|	VATPrepaymentsFromCustomer.Recorder AS Document,
	|	VATPrepaymentsFromCustomer.Organization AS Organization,
	|	BEGINOFPERIOD(VATPrepaymentsFromCustomer.Period, DAY) AS DateRecord
	|FROM
	|	CurRegistrarsVATAdvancesReceived AS VATPrepaymentsFromCustomer
	|
	|UNION
	|
	|SELECT DISTINCT
	|	VATPrepaymentsFromCustomer.Period AS Period,
	|	VATPrepaymentsFromCustomer.Recorder AS Document,
	|	VATPrepaymentsFromCustomer.Organization AS Organization,
	|	BEGINOFPERIOD(VATPrepaymentsFromCustomer.Period, DAY) AS DateRecord
	|FROM
	|	VATAdvancesReceivedStornoOffsets AS VATPrepaymentsFromCustomer
	|WHERE
	|	VATPrepaymentsFromCustomer.VAT <> 0";
	
#EndRegion
	
#Region TextVATAdvancesIssued
	
	TextVATAdvancesIssued = "
	|SELECT DISTINCT
	|	VATPrepaymentsToVendor.Period AS Period,
	|	VATPrepaymentsToVendor.Recorder AS Document,
	|	VATPrepaymentsToVendor.Organization AS Organization,
	|	BEGINOFPERIOD(VATPrepaymentsToVendor.Period, DAY) AS DateRecord
	|FROM
	|	VATAdvancesIssuedStorno AS VATPrepaymentsToVendor
	|WHERE
	|	VATPrepaymentsToVendor.VAT <> 0
	|
	|UNION
	|
	|SELECT DISTINCT
	|	VATPrepaymentsToVendor.Period AS Period,
	|	VATPrepaymentsToVendor.Recorder AS Document,
	|	VATPrepaymentsToVendor.Organization AS Organization,
	|	BEGINOFPERIOD(VATPrepaymentsToVendor.Period, DAY) AS DateRecord
	|FROM
	|	VATAdvancesIssuedUnderISF AS VATPrepaymentsToVendor
	|WHERE
	|	VATPrepaymentsToVendor.VAT <> 0
	|
	|UNION
	|
	|SELECT DISTINCT
	|	VATPrepaymentsToVendor.Period AS Period,
	|	VATPrepaymentsToVendor.Recorder AS Document,
	|	VATPrepaymentsToVendor.Organization AS Organization,
	|	BEGINOFPERIOD(VATPrepaymentsToVendor.Period, DAY) AS DateRecord
	|FROM
	|	VATAdvancesIssuedCredits AS VATPrepaymentsToVendor
	|WHERE
	|	VATPrepaymentsToVendor.VAT <> 0
	|
	|UNION
	|
	|SELECT DISTINCT
	|	VATPrepaymentsToVendor.Period AS Period,
	|	VATPrepaymentsToVendor.Recorder AS Document,
	|	VATPrepaymentsToVendor.Organization AS Organization,
	|	BEGINOFPERIOD(VATPrepaymentsToVendor.Period, DAY) AS DateRecord
	|FROM
	|	CurRegistrarsVATAdvancesIssued AS VATPrepaymentsToVendor
	|
	|UNION
	|
	|SELECT DISTINCT
	|	VATPrepaymentsFromCustomer.Period AS Period,
	|	VATPrepaymentsFromCustomer.Recorder AS Document,
	|	VATPrepaymentsFromCustomer.Organization AS Organization,
	|	BEGINOFPERIOD(VATPrepaymentsFromCustomer.Period, DAY) AS DateRecord
	|FROM
	|	VATAdvancesIssuedStornoOffsets AS VATPrepaymentsFromCustomer
	|WHERE
	|	VATPrepaymentsFromCustomer.VAT <> 0";
	
#EndRegion
	
	ReflectionTexts = New Array;
	ReflectionTexts.Add(TextOfVATSubmitted);
	If CalculationParameters.CalculationOfAdvancesReceived Then
		ReflectionTexts.Add(TextVATAdvancesReceived);
	EndIf;
	If CalculationParameters.CalculationOfAdvancesIssued Then
		ReflectionTexts.Add(TextVATAdvancesIssued);
	EndIf;
	
	Query = New Query;
	Query.Text = StrConcat(ReflectionTexts, TMCommonUse.QuerySeparatorInJoin(True));
	
	Query.SetParameter("EndOfPeriod",      CalculationParameters.EndOfPeriod);
	Query.SetParameter("CompanyArray", CalculationParameters.CompanyArray);
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	
	Query.Execute();
	
	FinancialAccountingPostingServer.ReturnDocumentsToReflection(CalculationParameters.TempTablesManager);
	
	If CalculationParameters.CalculationOfAdvancesReceived Then
		Query.Text = 
		"SELECT DISTINCT
		|	VATPrepaymentsFromCustomer.Recorder AS Document,
		|	VATPrepaymentsFromCustomer.Organization AS Organization,
		|	BEGINOFPERIOD(VATPrepaymentsFromCustomer.Period, DAY) AS DateRecord
		|INTO CurRegistrarsAdvances
		|FROM
		|	CurRegistrarsVATAdvancesReceived AS VATPrepaymentsFromCustomer
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	VATPrepaymentsFromCustomer.Period AS Period,
		|	VATPrepaymentsFromCustomer.Recorder AS Document,
		|	VATPrepaymentsFromCustomer.Organization AS Organization,
		|	BEGINOFPERIOD(VATPrepaymentsFromCustomer.Period, DAY) AS DateRecord
		|INTO DocumentsForReflectionAdvances
		|FROM
		|	VATAdvancesReceivedStorno AS VATPrepaymentsFromCustomer
		|
		|UNION
		|
		|SELECT DISTINCT
		|	VATPrepaymentsFromCustomer.Period AS Period,
		|	VATPrepaymentsFromCustomer.Recorder AS Document,
		|	VATPrepaymentsFromCustomer.Organization AS Organization,
		|	BEGINOFPERIOD(VATPrepaymentsFromCustomer.Period, DAY) AS DateRecord
		|FROM
		|	VATAdvancesReceivedUnderISF AS VATPrepaymentsFromCustomer
		|
		|UNION
		|
		|SELECT DISTINCT
		|	VATPrepaymentsFromCustomer.Period AS Period,
		|	VATPrepaymentsFromCustomer.Recorder AS Document,
		|	VATPrepaymentsFromCustomer.Organization AS Organization,
		|	BEGINOFPERIOD(VATPrepaymentsFromCustomer.Period, DAY) AS DateRecord
		|FROM
		|	VATAdvancesReceivedCredits AS VATPrepaymentsFromCustomer
		|
		|UNION
		|
		|SELECT DISTINCT
		|	VATPrepaymentsFromCustomer.Period AS Period,
		|	VATPrepaymentsFromCustomer.Recorder AS Document,
		|	VATPrepaymentsFromCustomer.Organization AS Organization,
		|	BEGINOFPERIOD(VATPrepaymentsFromCustomer.Period, DAY) AS DateRecord
		|FROM
		|	VATAdvancesReceivedStornoOffsets AS VATPrepaymentsFromCustomer
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	CurRegistrarsAdvances.Document AS Document,
		|	CurRegistrarsAdvances.Organization AS Organization,
		|	CurRegistrarsAdvances.DateRecord AS DateRecord
		|INTO SampleRegistrationTable
		|FROM
		|	CurRegistrarsAdvances AS CurRegistrarsAdvances
		|		LEFT JOIN DocumentsForReflectionAdvances AS DocumentsForReflectionAdvances
		|		ON CurRegistrarsAdvances.Document = DocumentsForReflectionAdvances.Document
		|			AND CurRegistrarsAdvances.Organization = DocumentsForReflectionAdvances.Organization
		|			AND CurRegistrarsAdvances.DateRecord = DocumentsForReflectionAdvances.DateRecord
		|WHERE
		|	DocumentsForReflectionAdvances.Document IS NULL
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	SampleRegistrationTable.Document AS Document
		|INTO SelectiveRegistrationDocuments
		|FROM
		|	SampleRegistrationTable AS SampleRegistrationTable
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	DocumentPostingInFinancialAccounting.Period AS Period,
		|	DocumentPostingInFinancialAccounting.Recorder AS Document,
		|	DocumentPostingInFinancialAccounting.ChartOfAccounts AS ChartOfAccounts,
		|	DocumentPostingInFinancialAccounting.Organization AS Organization,
		|	DocumentPostingInFinancialAccounting.DateRecord AS DateRecord
		|INTO CurRegistrationTable
		|FROM
		|	InformationRegister.DocumentPostingInFinancialAccounting AS DocumentPostingInFinancialAccounting
		|		INNER JOIN SelectiveRegistrationDocuments AS SelectiveRegistrationDocuments
		|		ON DocumentPostingInFinancialAccounting.Recorder = SelectiveRegistrationDocuments.Document
		|WHERE
		|	DocumentPostingInFinancialAccounting.Active
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP CurRegistrarsAdvances
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP DocumentsForReflectionAdvances
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP SelectiveRegistrationDocuments";
	
		Query.Execute();
		
		If Not CalculationParameters.TempTablesManager.Tables["SampleRegistrationTable"].GetData().IsEmpty() Then
			FinancialAccountingPostingServer.ReturnDocumentsToReflectionSelectivelyInBatches(CalculationParameters.TempTablesManager);
		EndIf;
		
		TMCommonUse.DestroyTemporaryTables(
			CalculationParameters.TempTablesManager,
			"SampleRegistrationTable,CurRegistrationTable");
		
	EndIf;
	
	If CalculationParameters.CalculationOfAdvancesIssued Then
		Query.Text = 
		"SELECT DISTINCT
		|	VATPrepaymentsToVendor.Recorder AS Document,
		|	VATPrepaymentsToVendor.Organization AS Organization,
		|	BEGINOFPERIOD(VATPrepaymentsToVendor.Period, DAY) AS DateRecord
		|INTO CurRegistrarsAdvances
		|FROM
		|	CurRegistrarsVATAdvancesIssued AS VATPrepaymentsToVendor
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	VATPrepaymentsToVendor.Period AS Period,
		|	VATPrepaymentsToVendor.Recorder AS Document,
		|	VATPrepaymentsToVendor.Organization AS Organization,
		|	BEGINOFPERIOD(VATPrepaymentsToVendor.Period, DAY) AS DateRecord
		|INTO DocumentsForReflectionAdvances
		|FROM
		|	VATAdvancesIssuedStorno AS VATPrepaymentsToVendor
		|
		|UNION
		|
		|SELECT DISTINCT
		|	VATPrepaymentsToVendor.Period AS Period,
		|	VATPrepaymentsToVendor.Recorder AS Document,
		|	VATPrepaymentsToVendor.Organization AS Organization,
		|	BEGINOFPERIOD(VATPrepaymentsToVendor.Period, DAY) AS DateRecord
		|FROM
		|	VATAdvancesIssuedUnderISF AS VATPrepaymentsToVendor
		|
		|UNION
		|
		|SELECT DISTINCT
		|	VATPrepaymentsToVendor.Period AS Period,
		|	VATPrepaymentsToVendor.Recorder AS Document,
		|	VATPrepaymentsToVendor.Organization AS Organization,
		|	BEGINOFPERIOD(VATPrepaymentsToVendor.Period, DAY) AS DateRecord
		|FROM
		|	VATAdvancesIssuedCredits AS VATPrepaymentsToVendor
		|
		|UNION
		|
		|SELECT DISTINCT
		|	VATPrepaymentsToVendor.Period AS Period,
		|	VATPrepaymentsToVendor.Recorder AS Document,
		|	VATPrepaymentsToVendor.Organization AS Organization,
		|	BEGINOFPERIOD(VATPrepaymentsToVendor.Period, DAY) AS DateRecord
		|FROM
		|	VATAdvancesIssuedStornoOffsets AS VATPrepaymentsToVendor
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	CurRegistrarsAdvances.Document AS Document,
		|	CurRegistrarsAdvances.Organization AS Organization,
		|	CurRegistrarsAdvances.DateRecord AS DateRecord
		|INTO SampleRegistrationTable
		|FROM
		|	CurRegistrarsAdvances AS CurRegistrarsAdvances
		|		LEFT JOIN DocumentsForReflectionAdvances AS DocumentsForReflectionAdvances
		|		ON CurRegistrarsAdvances.Document = DocumentsForReflectionAdvances.Document
		|			AND CurRegistrarsAdvances.Organization = DocumentsForReflectionAdvances.Organization
		|			AND CurRegistrarsAdvances.DateRecord = DocumentsForReflectionAdvances.DateRecord
		|WHERE
		|	DocumentsForReflectionAdvances.Document IS NULL
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	SampleRegistrationTable.Document AS Document
		|INTO SelectiveRegistrationDocuments
		|FROM
		|	SampleRegistrationTable AS SampleRegistrationTable
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	DocumentPostingInFinancialAccounting.Period AS Period,
		|	DocumentPostingInFinancialAccounting.Recorder AS Document,
		|	DocumentPostingInFinancialAccounting.ChartOfAccounts AS ChartOfAccounts,
		|	DocumentPostingInFinancialAccounting.Organization AS Organization,
		|	DocumentPostingInFinancialAccounting.DateRecord AS DateRecord
		|INTO CurRegistrationTable
		|FROM
		|	InformationRegister.DocumentPostingInFinancialAccounting AS DocumentPostingInFinancialAccounting
		|		INNER JOIN SelectiveRegistrationDocuments AS SelectiveRegistrationDocuments
		|		ON DocumentPostingInFinancialAccounting.Recorder = SelectiveRegistrationDocuments.Document
		|WHERE
		|	DocumentPostingInFinancialAccounting.Active
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP CurRegistrarsAdvances
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP DocumentsForReflectionAdvances
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP SelectiveRegistrationDocuments";
	
		Query.Execute();
		
		If Not CalculationParameters.TempTablesManager.Tables["SampleRegistrationTable"].GetData().IsEmpty() Then
			FinancialAccountingPostingServer.ReturnDocumentsToReflectionSelectivelyInBatches(CalculationParameters.TempTablesManager);
		EndIf;
		
		TMCommonUse.DestroyTemporaryTables(
			CalculationParameters.TempTablesManager,
			"SampleRegistrationTable,CurRegistrationTable");
	EndIf;
	
	TMCommonUse.DestroyTemporaryTables(
		CalculationParameters.TempTablesManager,
		"DocumentsToBeReflected");
	
EndProcedure

#EndRegion

#EndRegion

#Region AnalysisOfAccountingOfAdvancesForVAT

// Creates a structure of parameters for the preparation of temporary tables with the calculations
// 
// Parameters:
//  InitialParameters - Undefined, Structure - custom structure with filled in values
// 
// Returns:
// 	Structure - LongDesc:
//   * StartDate                    - Date -
//   * EndDate                 - Date -
//   * Companies                   - Undefined, CatalogRef.Companies, Array of CatalogRef.Companies -
//   * ARAPDocument             - Undefined, DocumentRef - additional filter for the settlement document
//   * CreateEmptyTable          - Boolean - allows you to create a temporary table frame without data
//   * EnableSettlementData         - Boolean - By default, " True"
//   * EnableGiftCertificateData - Boolean - By default, " False"
//   * IncludeFinancialInstrumentData - Boolean - By default, " False"
//   * ManualIndexFields           - Array of String - the ability to override the index field of the result
//   * ExcludeTypesOfTaxationWithoutVAT - Boolean - By default, " True"
//   * AdvanceSelectionRule          - EnumRef.ProcedureOfRegisteringTaxInvoicesForPrepayment -
//   * EnableDebtCancellationOperations - Boolean - If "True", it will include debt write-offs in repayments.
//   * AnalyzeManAccountingAdditionally     - Boolean - If "True", in the absence of a calculated resource in the registers,
//                                                  the resource in the registers will be calculated using
//                                                  the "exchange Rates" register, otherwise the amount of accounting will be equal to 0.
//   * IncludeReferenceDataThatDoesNotRequireVAT - Boolean - By default, " False"
//   * SelectionParametersForSettlementDocument - Structure - For selection according to a temporary table with settlement documents, where:
//   	** FieldName                 - String - Name of the field that contains the document.
//   	                                      By default - "settlement Document".
//   	** SelectionTableName_        - String - name of the temporary table where the document is contained
//   
//   
//   Service columns - for caching during calculations.
//   
//   * ClearServiceColumns     - Boolean - By default, " True"
//   * Organizations_AdvancesReceived - Array of CatalogRef.Companies -
//   * Organizations_AdvancesIssued   - Array of CatalogRef.Companies -
//   * TypesOfTaxationWithoutVAT    - Array of EnumRef.VATTaxationTypes -
//   * ExcludeJUDAS                - Boolean - By default, " False"
//
Function InitializeParametersForPreparationOfAdvancePaymentsForVATPurposes(InitialParameters = Undefined) Export
	
	CalculationParameters_ = New Structure;
	
	DateEmpty = '00010101';
	
	CalculationParameters_.Insert("StartDate",           DateEmpty);
	CalculationParameters_.Insert("EndDate",        DateEmpty);
	CalculationParameters_.Insert("Companies",          Undefined);
	CalculationParameters_.Insert("ARAPDocument",    Undefined);
	CalculationParameters_.Insert("CreateEmptyTable", False);
	
	CalculationParameters_.Insert("EnableSettlementData",         True);
	CalculationParameters_.Insert("EnableGiftCertificateData", False);
	CalculationParameters_.Insert("IncludeFinancialInstrumentData", False);
	
	// For selection according to a temporary table with settlement documents
	SelectionParametersForSettlementDocument = New Structure;
	SelectionParametersForSettlementDocument.Insert("FieldName",                 "ARAPDocument");
	SelectionParametersForSettlementDocument.Insert("SelectionTableName_",        "");
	
	CalculationParameters_.Insert("SelectionParametersForSettlementDocument", SelectionParametersForSettlementDocument);
	
	CalculationParameters_.Insert("ManualIndexFields", New Array);
	
	CalculationParameters_.Insert("AdvanceSelectionRule",
		Enums.ProcedureOfRegisteringTaxInvoicesForPrepayment.EmptyRef());
	CalculationParameters_.Insert("IncludeReferenceDataThatDoesNotRequireVAT", False);
	CalculationParameters_.Insert("AnalyzeManAccountingAdditionally",               False);
	CalculationParameters_.Insert("EnableDebtCancellationOperations",           False);
	
	CalculationParameters_.Insert("ExcludeTypesOfTaxationWithoutVAT", True);
	
	// Initialization of service parameters
	CalculationParameters_.Insert("ClearServiceColumns",            True);
	CalculationParameters_.Insert("Organizations_AdvancesReceived",        New Array());
	CalculationParameters_.Insert("Organizations_AdvancesIssued",          New Array()); 
	CalculationParameters_.Insert("FillOutCompanies_AdvancesIssued", True);
	CalculationParameters_.Insert("TypesOfTaxationWithoutVAT",           VATAccountingERP.TypesOfVATTaxationNonTaxable(True));
	CalculationParameters_.Insert("ExcludeJUDAS",                       False);
	
	FillInPropertiesOfAdvancePaymentParameters(CalculationParameters_, InitialParameters);
	
	Return CalculationParameters_;
	
EndFunction

#Region PrepaymentsFromCustomer

// Prepare a temporary table "Advance payments_Occurrences"
// Creates a temporary table with columns:
// 	* company;
// 	* Settlement document;
// 	* Document Recorder;
// 	* Accounting objects;
// 	* Gift Certificate;
// 	* Directions of activity;
// 	* Counterparty;
// 	* Contract;
// 	* Type of tax;
// 	* Advance Payment DataAvance;
// 	* Document currency;
// 	* The sum of the advance;
// 	* SummaAvansaVal;
// 	* SummaAvansaUpr.
//
// Parameters:
//  TempTablesManager - TempTablesManager - 
//  CalculationParameters        - See InitializeParametersForPreparationOfAdvancePaymentsForVATPurposes
//  SettingsTable - ValueTable - with columns:
//		* Organization - CatalogRef.Companies -
//		* UseVATAccounting - Boolean - 
//		* BasicTaxationVATSales - EnumRef.VATTaxationTypes - 
//		* MainActivityVATProcurement - EnumRef.VATTaxationTypes - 
Procedure PrepareVT_AdvancesReceived_Occurrences(TempTablesManager, CalculationParameters, SettingsTable = Undefined) Export
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	FillInServiceParametersForCalculatingAdvances(CalculationParameters, SettingsTable);
	
	SetRequestParametersForPreparationOfAdvancePaymentsForVATPurposes(Query, CalculationParameters);
	
	If CostCalculationAppliedAlgorithms.TemporaryTableExists(TempTablesManager,
		"SettlementsWithCustomers_Advances") Then
		Query.Text = "DROP SettlementsWithCustomers_Advances";
		Query.Execute();
	EndIf;
	
	CalculationParametersForMutualSettlements =
		ARAPAccountingVAT.InitializeParametersForPreparationOfAdvancePayments(CalculationParameters);
	
	CalculationParametersForMutualSettlements.ManualIndexFields.Clear();
	CalculationParametersForMutualSettlements.TakeIntoAccountReservationOfAdvances = True;
	CalculationParametersForMutualSettlements.CreateEmptyTable        =
		CalculationParameters.CreateEmptyTable Or Not CalculationParameters.EnableSettlementData;
	
	If ValueIsFilled(CalculationParameters.Companies) Then
		CalculationParametersForMutualSettlements.EnableOrganizationSelection = True;
		CalculationParametersForMutualSettlements.Companies = CalculationParameters.Organizations_AdvancesReceived;
	EndIf;
	
	ARAPAccountingVAT.PrepareVT_SettlementsWithCustomers_Advances(
			TempTablesManager,
			CalculationParametersForMutualSettlements);
		
	PrepareVTOffsetsOfAdvancesReceivedByInvoicesAdjustmentsForReduction(
			TempTablesManager,
			CalculationParametersForMutualSettlements);
	
	Query.Text =
	"SELECT
	|	SourceDocumentsData.Organization                                     AS Organization,
	|	CertificateImplementation.Recorder                                         AS ARAPDocument,
	|	CertificateImplementation.Recorder                                         AS DocumentRecorder,
	|	&EmptyCalculationObject                                                     AS ARAPObject,
	|	CertificateImplementation.GiftCertificate                                AS GiftCertificate,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef)                 AS LineOfBusiness,
	|	VALUE(Catalog.Counterparties.RetailCustomer)                      AS Counterparty,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef)                    AS Contract,
	|	VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)        AS TaxationType,
	|	BEGINOFPERIOD(CertificateImplementation.Period, DAY)                         AS DateRecord,
	|	BEGINOFPERIOD(SourceDocumentsData.RecorderDate, DAY)           AS AdvanceDate,
	|
	|	MAX(ISNULL(CertificateImplementation.GiftCertificate.Owner.Currency,
	|		VALUE(Catalog.Currencies.EmptyRef)))                            AS DocumentCurrency,
	|
	|	SUM(CertificateImplementation.SumCompl)                                    AS AdvanceAmount,
	|	SUM(CertificateImplementation.Sum)                                        AS AdvanceAmountVal
	|INTO GiftCertificates_Advances_Preliminary
	|FROM
	|	AccumulationRegister.GiftCertificates AS CertificateImplementation
	|	
	|	INNER JOIN
	|		InformationRegister.SourceDocumentsData AS SourceDocumentsData
	|	ON
	|		CertificateImplementation.Recorder = SourceDocumentsData.Document
	|	
	|WHERE
	|	NOT &CreateEmptyTable
	|	AND &EnableGiftCertificateData
	|	AND CertificateImplementation.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND CertificateImplementation.Sum > 0
	|	AND CertificateImplementation.Period BETWEEN &StartDate AND &EndDate
	|	AND (SourceDocumentsData.Organization IN (&Organizations_AdvancesReceived))
	|	AND (&TextSelectionByParameters)
	|	AND VALUETYPE(CertificateImplementation.Recorder) IN (&TypesOfSettlementDocumentsReceived)
	|
	|GROUP BY
	|	SourceDocumentsData.Organization,
	|	CertificateImplementation.Recorder,
	|	CertificateImplementation.GiftCertificate,
	|	BEGINOFPERIOD(CertificateImplementation.Period, DAY),
	|	BEGINOFPERIOD(SourceDocumentsData.RecorderDate, DAY)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.DateRecord AS DateRecord,
	|	NestedQuery.LocalAccountingCurrency AS BaseCurrency,
	|	MAX(ExchangeRates.Period) AS Period
	|INTO ManAccounting_CoursePeriods
	|FROM
	|	(SELECT DISTINCT
	|		BEGINOFPERIOD(GiftCertificates.DateRecord, DAY) AS DateRecord,
	|		GiftCertificates.Organization.LocalAccountingCurrency AS LocalAccountingCurrency
	|	FROM
	|		GiftCertificates_Advances_Preliminary AS GiftCertificates
	|	WHERE
	|		&AnalyzeManAccountingAdditionally
	|	) AS NestedQuery
	|	
	|	LEFT JOIN
	|		InformationRegister.RelativeExchangeRates AS ExchangeRates
	|	ON
	|		NestedQuery.DateRecord >= ExchangeRates.Period
	|		AND NestedQuery.LocalAccountingCurrency = ExchangeRates.BaseCurrency
	|WHERE
	|	ExchangeRates.Currency = &CurrencyOfManAccounting
	|	AND NestedQuery.LocalAccountingCurrency <> &CurrencyOfManAccounting
	|
	|GROUP BY
	|	NestedQuery.DateRecord,
	|	NestedQuery.LocalAccountingCurrency
	|INDEX BY
	|	DateRecord
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CoursePeriods.DateRecord AS DateRecord,
	|	CoursePeriods.BaseCurrency AS BaseCurrency,
	|	CASE
	|		WHEN ExchangeRates.Currency IS NULL
	|			THEN 1
	|		WHEN ExchangeRates.CourseDenominator = 0
	|			THEN ExchangeRates.CourseNumerator
	|		ELSE ExchangeRates.CourseNumerator / ExchangeRates.CourseDenominator
	|	END                       AS Rate
	|INTO ManAccounting_Courses
	|FROM
	|	ManAccounting_CoursePeriods AS CoursePeriods
	|
	|	INNER JOIN
	|		InformationRegister.RelativeExchangeRates AS ExchangeRates
	|	ON
	|		CoursePeriods.Period = ExchangeRates.Period
	|		AND CoursePeriods.BaseCurrency = ExchangeRates.BaseCurrency
	|		AND ExchangeRates.Currency = &CurrencyOfManAccounting
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP ManAccounting_CoursePeriods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Calculations.Organization               AS Organization,
	|	Calculations.ARAPDocument         AS ARAPDocument,
	|	Calculations.DocumentRecorder       AS DocumentRecorder,
	|	Calculations.ARAPObject            AS ARAPObject,
	|	VALUE(Catalog.GiftCertificates.EmptyRef) AS GiftCertificate,
	|	Calculations.LineOfBusiness   AS LineOfBusiness,
	|	Calculations.Counterparty                AS Counterparty,
	|	Calculations.Contract                   AS Contract,
	|	&TextOfDefinitionOfTaxation  AS TaxationType,
	|	Calculations.AdvanceDate                AS AdvanceDate,
	|	Calculations.DocumentCurrency           AS DocumentCurrency,
	|	Calculations.AmountOfSchedAdvance           AS AdvanceAmount,
	|	Calculations.AdvanceAmountVal            AS AdvanceAmountVal,
	|	Calculations.AdvanceAmountOfMan            AS AdvanceAmountOfMan
	|INTO AdvancesReceived_Occurrences
	|FROM
	|	SettlementsWithCustomers_Advances AS Calculations
	|WHERE
	|	VALUETYPE(Calculations.ARAPDocument) IN (&TypesOfSettlementDocumentsReceived)
	|	AND (&ExcludeTypesOfTaxationWithoutVAT = FALSE
	|		OR NOT &TextOfDefinitionOfTaxation IN (&TypesOfTaxationWithoutVAT))
	|	AND &TextOfDefinitionOfTaxation <> VALUE(Enum.VATTaxationTypes.ProductionWithLongCycle)
	|	
	|	UNION ALL
	|
	|SELECT
	|	Credits.Organization                                                 AS Organization,
	|	Credits.DocumentPayments                                              AS ARAPDocument,
	|	Credits.DocumentRecorder                                         AS DocumentRecorder,
	|	Credits.ARAPObject                                              AS ARAPObject,
	|	VALUE(Catalog.GiftCertificates.EmptyRef)            AS GiftCertificate,
	|	Credits.LineOfBusiness                                     AS LineOfBusiness,
	|	Credits.Counterparty                                                  AS Counterparty,
	|	Credits.Contract                                                     AS Contract,
	|	Credits.VATTaxation                                          AS TaxationType,
	|	Credits.Date                                                        AS AdvanceDate,
	|	Credits.Currency                                                      AS DocumentCurrency,
	|	Credits.SumCompl                                                   AS AdvanceAmount,
	|	Credits.Sum                                                       AS AdvanceAmountVal,
	|	Credits.Sum                                                       AS AdvanceAmountOfMan
	|FROM
	|	OffsetsOfAdvancesReceivedByInvoicesAdjustmentsForReduction AS Credits
	|
	|UNION ALL
	|
	|SELECT
	|	GiftCertificates.Organization               AS Organization,
	|	GiftCertificates.ARAPDocument         AS ARAPDocument,
	|	GiftCertificates.DocumentRecorder       AS DocumentRecorder,
	|	GiftCertificates.ARAPObject            AS ARAPObject,
	|	GiftCertificates.GiftCertificate      AS GiftCertificate,
	|	GiftCertificates.LineOfBusiness   AS LineOfBusiness,
	|	GiftCertificates.Counterparty                AS Counterparty,
	|	GiftCertificates.Contract                   AS Contract,
	|	GiftCertificates.TaxationType        AS TaxationType,
	|	GiftCertificates.AdvanceDate                AS AdvanceDate,
	|	GiftCertificates.DocumentCurrency           AS DocumentCurrency,
	|	GiftCertificates.AdvanceAmount               AS AdvanceAmount,
	|	GiftCertificates.AdvanceAmountVal            AS AdvanceAmountVal,
	|	CAST(GiftCertificates.AdvanceAmount * 
	|		CASE
	|			WHEN GiftCertificates.Organization.LocalAccountingCurrency = &CurrencyOfManAccounting
	|				THEN 1
	|			WHEN ISNULL(ManCourses.Rate, 0) = 0
	|				THEN 0
	|			ELSE 1 / ManCourses.Rate
	|		END AS NUMBER(31,2))                      AS AdvanceAmountOfMan
	|FROM
	|	GiftCertificates_Advances_Preliminary AS GiftCertificates
	|	
	|	LEFT JOIN
	|		ManAccounting_Courses AS ManCourses
	|	ON
	|		GiftCertificates.DateRecord = ManCourses.DateRecord
	|		AND GiftCertificates.Organization.LocalAccountingCurrency = ManCourses.BaseCurrency
	|
	|INDEX BY
	|	ARAPDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP SettlementsWithCustomers_Advances;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP OffsetsOfAdvancesReceivedByInvoicesAdjustmentsForReduction;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP GiftCertificates_Advances_Preliminary;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP ManAccounting_Courses
	|
	|";
	
	PathParameters = InitializeParameters_Advances_FieldPathsAndReplacementText();
	PathParameters.FullPath_SettlementDocument = "CertificateImplementation.Recorder";
	RequestPostprocessing_Advances_ForSelectionByParameters(Query, CalculationParameters, PathParameters);
	
	ParametersOfButAllocation = InitializeParameters_Advances_TaxDetermination(False);
	RequestPostProcessing_Advances_TaxType(Query, CalculationParameters, ParametersOfButAllocation);
	
	QueryPostprocessing_Advances_SETIndexFields(Query, CalculationParameters, "AdvancesReceived_Occurrences");
	
	Query.Execute();
		
EndProcedure

// Prepare a temporary table "Advance payments_Repayments"
// Creates a temporary table with columns:
// 	* company;
// 	* Settlement document;
// 	* Document Recorder;
// 	* Gift Certificate;
// 	* Advance Payment DataAvance;
// 	* Data settlement;
// 	* Directions of activity;
// 	* Counterparty;
// 	* Contract;
// 	* Type of tax;
// 	* Type of event;
// 	* Document currency;
// 	* Eventsnak;
// 	* Repayment amounts;
// 	* Sum of cancellations;
// 	* The sum of the repayment of UPR.
//
// Parameters:
//  TempTablesManager - TempTablesManager - 
//  CalculationParameters        - See InitializeParametersForPreparationOfAdvancePaymentsForVATPurposes
//  SettingsTable - ValueTable - with columns:
//		* Organization - CatalogRef.Companies -
//		* UseVATAccounting - Boolean - 
//		* BasicTaxationVATSales - EnumRef.VATTaxationTypes - 
//		* MainActivityVATProcurement - EnumRef.VATTaxationTypes - 
Procedure PrepareVT_AdvancesReceived_Repayments(TempTablesManager, CalculationParameters, SettingsTable = Undefined) Export
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	FillInServiceParametersForCalculatingAdvances(CalculationParameters, SettingsTable);
	
	SetRequestParametersForPreparationOfAdvancePaymentsForVATPurposes(Query, CalculationParameters);
	
	If CostCalculationAppliedAlgorithms.TemporaryTableExists(TempTablesManager,
		"SettlementsWithCustomers_RepaymentOfAdvances") Then
		Query.Text = "DROP SettlementsWithCustomers_RepaymentOfAdvances";
		Query.Execute();
	EndIf;
	
	CalculationParametersForMutualSettlements =
		ARAPAccountingVAT.InitializeParametersForPreparationOfAdvancePayments(CalculationParameters);
	
	CalculationParametersForMutualSettlements.ManualIndexFields.Clear();
	CalculationParametersForMutualSettlements.TakeIntoAccountReservationOfAdvances = True;
	CalculationParametersForMutualSettlements.CreateEmptyTable        =
		CalculationParameters.CreateEmptyTable Or Not CalculationParameters.EnableSettlementData;
	If ValueIsFilled(CalculationParameters.Companies) Then
		CalculationParametersForMutualSettlements.EnableOrganizationSelection = True;
		CalculationParametersForMutualSettlements.Companies = CalculationParameters.Organizations_AdvancesReceived;
	EndIf;
	
	ARAPAccountingVAT.PrepareVT_SettlementsWithCustomers_RepaymentOfAdvances(
		TempTablesManager,
		CalculationParametersForMutualSettlements);
		
	PrepareVTOffsetsOfAdvancesReceivedByInvoices(
		TempTablesManager,
		CalculationParametersForMutualSettlements);
	
	Query.Text =
	"SELECT
	|	SourceDocumentsData.Organization                                     AS Organization,
	|	CertificateImplementation.Recorder                                         AS ARAPDocument,
	|	RegisterData.Recorder                                                AS DocumentRecorder,
	|	CertificateImplementation.GiftCertificate                                AS GiftCertificate,
	|	BEGINOFPERIOD(RegisterData.Period, DAY)                                AS DateRecord,
	|	BEGINOFPERIOD(SourceDocumentsData.RecorderDate, DAY)           AS AdvanceDate,
	|	RegisterData.Period                                                     AS MaturityDate,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef)                 AS LineOfBusiness,
	|	VALUE(Catalog.Counterparties.RetailCustomer)                      AS Counterparty,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef)                    AS Contract,
	|	VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)        AS TaxationType,
	|
	|	CASE WHEN VALUETYPE(RegisterData.Recorder) = TYPE(Document.ReturnOfGiftCards) THEN
	|		VALUE(Enum.BusinessTransactions.RefundToCustomer)
	|	ELSE
	|		VALUE(Enum.BusinessTransactions.CustomerPrepaymentSettlement)
	|	END                                                                     AS EventKind,
	|
	|	MAX(ISNULL(CertificateImplementation.GiftCertificate.Owner.Currency,
	|		VALUE(Catalog.Currencies.EmptyRef)))                            AS DocumentCurrency,
	|
	|	CASE WHEN VALUETYPE(RegisterData.Recorder) = TYPE(Document.ReturnOfGiftCards) THEN
	|		-1
	|	ELSE
	|		0
	|	END                                                                     AS EventSign,
	|
	|	CAST(SUM(RegisterData.Sum
	|		* (CertificateImplementation.SumCompl / CertificateImplementation.Sum))
	|		AS NUMBER(31,2))                                                      AS RepaymentAmount,
	|	SUM(RegisterData.Sum)                                               AS RepaymentAmountVal
	|INTO GiftCertificates_Credits_Preliminary
	|FROM
	|	AccumulationRegister.GiftCertificates AS RegisterData
	|	
	|	INNER JOIN
	|		AccumulationRegister.GiftCertificates AS CertificateImplementation
	|	ON
	|		&EnableGiftCertificateData
	|		AND CertificateImplementation.GiftCertificate = RegisterData.GiftCertificate
	|		AND CertificateImplementation.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	
	|	INNER JOIN
	|		InformationRegister.SourceDocumentsData AS SourceDocumentsData
	|	ON
	|		CertificateImplementation.Recorder = SourceDocumentsData.Document
	|	
	|WHERE
	|	NOT &CreateEmptyTable
	|	AND &EnableGiftCertificateData
	|	AND RegisterData.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND RegisterData.Sum > 0
	|	AND ENDOFPERIOD(RegisterData.Period, DAY) <> ENDOFPERIOD(CertificateImplementation.Period, DAY)
	|	AND RegisterData.Period BETWEEN &StartDate AND &EndDate
	|	AND (SourceDocumentsData.Organization IN (&Organizations_AdvancesReceived))
	|	AND (&TextSelectionByParameters)
	|	AND VALUETYPE(CertificateImplementation.Recorder) IN (&TypesOfSettlementDocumentsReceived)
	|
	|GROUP BY
	|	RegisterData.Recorder,
	|	RegisterData.Period,
	|	SourceDocumentsData.Organization,
	|	CertificateImplementation.Recorder,
	|	CertificateImplementation.GiftCertificate,
	|	BEGINOFPERIOD(SourceDocumentsData.RecorderDate, DAY)
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.DateRecord AS DateRecord,
	|	NestedQuery.LocalAccountingCurrency AS BaseCurrency,
	|	MAX(ExchangeRates.Period) AS Period
	|INTO ManAccounting_CoursePeriods
	|FROM
	|	(SELECT DISTINCT
	|		BEGINOFPERIOD(GiftCertificates.DateRecord, DAY) AS DateRecord,
	|		GiftCertificates.Organization.LocalAccountingCurrency AS LocalAccountingCurrency
	|	FROM
	|		GiftCertificates_Credits_Preliminary AS GiftCertificates
	|	WHERE
	|		&AnalyzeManAccountingAdditionally
	|	) AS NestedQuery
	|	
	|	LEFT JOIN
	|		InformationRegister.RelativeExchangeRates AS ExchangeRates
	|	ON
	|		NestedQuery.DateRecord >= ExchangeRates.Period
	|		AND NestedQuery.LocalAccountingCurrency = ExchangeRates.BaseCurrency
	|
	|WHERE
	|	ExchangeRates.Currency = &CurrencyOfManAccounting
	|	AND NestedQuery.LocalAccountingCurrency <> &CurrencyOfManAccounting
	|
	|GROUP BY
	|	NestedQuery.DateRecord,
	|	NestedQuery.LocalAccountingCurrency
	|
	|INDEX BY
	|	DateRecord
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CoursePeriods.DateRecord AS DateRecord,
	|	CoursePeriods.BaseCurrency AS BaseCurrency,
	|	CASE
	|		WHEN ExchangeRates.Currency IS NULL
	|			THEN 1
	|		WHEN ExchangeRates.CourseDenominator = 0
	|			THEN ExchangeRates.CourseNumerator
	|		ELSE ExchangeRates.CourseNumerator / ExchangeRates.CourseDenominator
	|	END                       AS Rate
	|INTO ManAccounting_Courses
	|FROM
	|	ManAccounting_CoursePeriods AS CoursePeriods
	|
	|	INNER JOIN
	|		InformationRegister.RelativeExchangeRates AS ExchangeRates
	|	ON
	|		CoursePeriods.Period = ExchangeRates.Period
	|		AND CoursePeriods.BaseCurrency = ExchangeRates.BaseCurrency
	|		AND ExchangeRates.Currency = &CurrencyOfManAccounting
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP ManAccounting_CoursePeriods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Repayments.Organization                AS Organization,
	|	Repayments.ARAPDocument          AS ARAPDocument,
	|	Repayments.DocumentRecorder        AS DocumentRecorder,
	|	VALUE(Catalog.GiftCertificates.EmptyRef) AS GiftCertificate,
	|	Repayments.AdvanceDate                 AS AdvanceDate,
	|	Repayments.MaturityDate              AS MaturityDate,
	|	Repayments.ExhDirectionOfActivity AS LineOfBusiness,
	|	Repayments.ExCounterparty              AS Counterparty,
	|	Repayments.Exodus                 AS Contract,
	|	&TextOfDefinitionOfTaxation     AS TaxationType,
	|	Repayments.EventKind                 AS EventKind,
	|	Repayments.ARAPObject             AS ARAPObject,
	|	Repayments.ReversingEntry                     AS ReversingEntry,
	|	MAX(Repayments.DocumentCurrency)  AS DocumentCurrency,
	|	SUM(CASE
	|			WHEN Repayments.EventKind = VALUE(Enum.BusinessTransactions.RefundToCustomer)
	|				THEN -1
	|			ELSE
	|				1
	|		END)                           AS EventSign,
	|	SUM(Repayments.LocalRepaymentAmount)  AS RepaymentAmount,
	|	SUM(Repayments.RepaymentAmountVal)   AS RepaymentAmountVal,
	|	SUM(Repayments.ManRepaymentAmount)   AS ManRepaymentAmount
	|INTO AdvancesReceivedToMaturity
	|FROM
	|	SettlementsWithCustomers_RepaymentOfAdvances AS Repayments
	|WHERE
	|	VALUETYPE(Repayments.ARAPDocument) IN (&TypesOfSettlementDocumentsReceived)
	|	AND (&EnableDebtCancellationOperations
	|		OR Repayments.EventKind <> VALUE(Enum.BusinessTransactions.APWriteOff))
	|	AND (&ExcludeTypesOfTaxationWithoutVAT = FALSE
	|		OR NOT &TextOfDefinitionOfTaxation IN (&TypesOfTaxationWithoutVAT))
	|	AND &TextOfDefinitionOfTaxation <> VALUE(Enum.VATTaxationTypes.ProductionWithLongCycle)
	|
	|GROUP BY
	|	Repayments.Organization,
	|	Repayments.ARAPDocument,
	|	Repayments.DocumentRecorder,
	|	Repayments.AdvanceDate,
	|	Repayments.MaturityDate,
	|	Repayments.ExhDirectionOfActivity,
	|	Repayments.ExCounterparty,
	|	Repayments.Exodus,
	|	&TextOfDefinitionOfTaxation,
	|	Repayments.EventKind,
	|	Repayments.ARAPObject,
	|	Repayments.ReversingEntry
	|
	|HAVING
	|	SUM(Repayments.LocalRepaymentAmount * CASE
	|			WHEN Repayments.ReversingEntry = TRUE
	|				THEN -1
	|			ELSE 1
	|		END) > 0
	|	
	|UNION ALL
	|
	|SELECT
	|	Credits.Organization                                                 AS Organization,
	|	Credits.DocumentPayments                                              AS ARAPDocument,
	|	Credits.DocumentRecorder                                         AS DocumentRecorder,
	|	VALUE(Catalog.GiftCertificates.EmptyRef)            AS GiftCertificate,
	|	DATETIME(1, 1, 1)                                                 AS AdvanceDate,
	|	Credits.Date                                                        AS MaturityDate,
	|	Credits.LineOfBusiness                                     AS LineOfBusiness,
	|	Credits.Counterparty                                                  AS Counterparty,
	|	Credits.Contract                                                     AS Contract,
	|	Credits.VATTaxation                                          AS TaxationType,
	|	VALUE(Enum.BusinessTransactions.CustomerPrepaymentSettlement)    AS EventKind,
	|	Credits.ARAPObject                                              AS ARAPObject,
	|	FALSE                                                               AS ReversingEntry,
	|	Credits.Currency                                                      AS DocumentCurrency,
	|	0                                                                  AS EventSign,
	|	Credits.SumCompl                                                   AS RepaymentAmount,
	|	Credits.Sum                                                       AS RepaymentAmountVal,
	|	Credits.Sum                                                       AS ManRepaymentAmount
	|FROM
	|	OffsetsOfAdvancesReceivedByInvoices AS Credits
	|
	|UNION ALL
	|
	|SELECT
	|	GiftCertificates.Organization                AS Organization,
	|	GiftCertificates.ARAPDocument          AS ARAPDocument,
	|	GiftCertificates.DocumentRecorder        AS DocumentRecorder,
	|	GiftCertificates.GiftCertificate       AS GiftCertificate,
	|	GiftCertificates.AdvanceDate                 AS AdvanceDate,
	|	GiftCertificates.MaturityDate              AS MaturityDate,
	|	GiftCertificates.LineOfBusiness    AS LineOfBusiness,
	|	GiftCertificates.Counterparty                 AS Counterparty,
	|	GiftCertificates.Contract                    AS Contract,
	|	GiftCertificates.TaxationType         AS TaxationType,
	|	GiftCertificates.EventKind                 AS EventKind,
	|	&EmptyCalculationObject                            AS ARAPObject,
	|	FALSE                                             AS ReversingEntry,
	|	GiftCertificates.DocumentCurrency            AS DocumentCurrency,
	|	GiftCertificates.EventSign                AS EventSign,
	|	GiftCertificates.RepaymentAmount             AS RepaymentAmount,
	|	GiftCertificates.RepaymentAmountVal          AS RepaymentAmountVal,
	|	CAST(GiftCertificates.RepaymentAmount * 
	|		CASE
	|			WHEN ISNULL(ManCourses.Rate, 0) = 0
	|				THEN 0
	|			ELSE 1 / ManCourses.Rate
	|		END AS NUMBER(31,2))                       AS ManRepaymentAmount
	|FROM
	|	GiftCertificates_Credits_Preliminary AS GiftCertificates
	|	
	|	LEFT JOIN
	|		ManAccounting_Courses AS ManCourses
	|	ON
	|		GiftCertificates.DateRecord = ManCourses.DateRecord
	|		AND GiftCertificates.Organization.LocalAccountingCurrency = ManCourses.BaseCurrency
	|
	|
	|INDEX BY
	|	ARAPDocument
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP SettlementsWithCustomers_RepaymentOfAdvances;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP OffsetsOfAdvancesReceivedByInvoices;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP GiftCertificates_Credits_Preliminary;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP ManAccounting_Courses
	|";
	
	PathParameters = InitializeParameters_Advances_FieldPathsAndReplacementText();
	PathParameters.FullPath_SettlementDocument = "CertificateImplementation.Recorder";
	RequestPostprocessing_Advances_ForSelectionByParameters(Query, CalculationParameters, PathParameters);
	
	ParametersOfButAllocation = InitializeParameters_Advances_TaxDetermination(False);
	ParametersOfButAllocation.ResourceField = "Repayments.SourceObjectOfCalculations_";
	RequestPostProcessing_Advances_TaxType(Query, CalculationParameters, ParametersOfButAllocation);
	
	QueryPostprocessing_Advances_SETIndexFields(Query, CalculationParameters, "AdvancesReceivedToMaturity");
	
	Query.Execute();
	
EndProcedure

// to prepare a temporary table "bazands_avanceis received"
//
// analyzes the advances received in the context of repayments and Balances.
// By specifying the advance selection rule, it determines whether it is necessary to generate an invoice and on what date.
// If the time was created earlier. tables "Advance payments_Occurrences" and "Advances received_Repayment",
// they will be destroyed.
//
// Creates a temporary table with columns:
// 	* company;
// 	* Directions of activity;
// 	* Counterparty;
// 	* Contract;
// 	* Type of tax;
// 	* Settlement document;
// 	* Accounting objects;
// 	* Advance Payment DataAvance;
// 	* Data settlement;
// 	* Document currency;
// 	* Document Recorder;
// 	* Accrue;
// 	* Dataformationsf;
// 	* Amount;
// 	* SummaVal;
// 	* SummaUpr.
//
// Parameters:
//  TempTablesManager - TempTablesManager - 
//  CalculationParameters        - See InitializeParametersForPreparationOfAdvancePaymentsForVATPurposes
//  SettingsTable - ValueTable - with columns:
//		* Organization - CatalogRef.Companies -
//		* UseVATAccounting - Boolean - 
//		* BasicTaxationVATSales - EnumRef.VATTaxationTypes - 
//		* MainActivityVATProcurement - EnumRef.VATTaxationTypes - 
Procedure PrepareVT_AdvancesReceived(TempTablesManager, CalculationParameters, SettingsTable = Undefined) Export
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	FillInServiceParametersForCalculatingAdvances(CalculationParameters, SettingsTable);
	
	SetRequestParametersForPreparationOfAdvancePaymentsForVATPurposes(Query, CalculationParameters);
	
	// Settlement data
	If CostCalculationAppliedAlgorithms.TemporaryTableExists(TempTablesManager,
		"AdvancesReceivedByRepaymentsAndBalances") Then
		Query.Text = "DROP AdvancesReceivedByRepaymentsAndBalances";
		Query.Execute();
	EndIf;
	
	CalculationParametersForMutualSettlements =
		ARAPAccountingVAT.InitializeParametersForPreparationOfAdvancePayments(CalculationParameters);
	CalculationParametersForMutualSettlements.ManualIndexFields.Clear();
	CalculationParametersForMutualSettlements.TakeIntoAccountReservationOfAdvances = True;
	CalculationParametersForMutualSettlements.CreateEmptyTable        =
		CalculationParameters.CreateEmptyTable Or Not CalculationParameters.EnableSettlementData;
	
	If ValueIsFilled(CalculationParameters.Companies) Then
		CalculationParametersForMutualSettlements.EnableOrganizationSelection = True;
		CalculationParametersForMutualSettlements.Companies = CalculationParameters.Organizations_AdvancesReceived;
	EndIf;
	
	ARAPAccountingVAT.PrepareVT_ReceivedAdvancesInTermsOfRepaymentsAndBalances(
			TempTablesManager,
			CalculationParametersForMutualSettlements);
	
	// Data other than settlements
	If CostCalculationAppliedAlgorithms.TemporaryTableExists(TempTablesManager,
		"AdvancesReceived_Occurrences") Then
		Query.Text = "DROP AdvancesReceived_Occurrences";
		Query.Execute();
	EndIf;
	
	If CostCalculationAppliedAlgorithms.TemporaryTableExists(TempTablesManager,
		"AdvancesReceivedToMaturity") Then
		Query.Text = "DROP AdvancesReceivedToMaturity";
		Query.Execute();
	EndIf;
	
	ParametersForCalculatingOccurrencesAndOffsetsOfAdvances = 
		InitializeParametersForPreparationOfAdvancePaymentsForVATPurposes(CalculationParameters);
	ParametersForCalculatingOccurrencesAndOffsetsOfAdvances.ManualIndexFields.Clear();
	ParametersForCalculatingOccurrencesAndOffsetsOfAdvances.ClearServiceColumns     = False;
	ParametersForCalculatingOccurrencesAndOffsetsOfAdvances.EnableSettlementData = False;
	
	PrepareVT_AdvancesReceived_Occurrences(
			TempTablesManager,
			ParametersForCalculatingOccurrencesAndOffsetsOfAdvances,
			SettingsTable);
	
	PrepareVT_AdvancesReceived_Repayments(
			TempTablesManager,
			ParametersForCalculatingOccurrencesAndOffsetsOfAdvances,
			SettingsTable);
			
	PrepareVTOffsetsOfAdvancesReceivedByInvoicesAdjustmentsForReduction(
			TempTablesManager,
			CalculationParametersForMutualSettlements);
	
	Query.Text =
	"SELECT
	|	AdvanceData.Organization               AS Organization,
	|	AdvanceData.LineOfBusiness   AS LineOfBusiness,
	|	AdvanceData.Counterparty                AS Counterparty,
	|	AdvanceData.Contract                   AS Contract,
	|	AdvanceData.TaxationType        AS TaxationType,
	|	AdvanceData.ARAPDocument         AS ARAPDocument,
	|	AdvanceData.GiftCertificate      AS GiftCertificate,
	|	AdvanceData.AdvanceDate                AS AdvanceDate,
	|	AdvanceData.DocumentCurrency           AS DocumentCurrency,
	|	AdvanceData.AdvanceAmount               AS AdvanceAmount,
	|	AdvanceData.AdvanceAmountVal            AS AdvanceAmountVal,
	|	AdvanceData.AdvanceAmountOfMan            AS AdvanceAmountOfMan
	|INTO Advances_GiftCertificates
	|FROM
	|	AdvancesReceived_Occurrences AS AdvanceData
	|WHERE
	|	AdvanceData.GiftCertificate <> UNDEFINED
	|	AND AdvanceData.GiftCertificate <> VALUE(Catalog.GiftCertificates.EmptyRef)
	|
	|INDEX BY
	|	GiftCertificate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Prepayments.Organization                  AS Organization,
	|	Prepayments.LineOfBusiness      AS LineOfBusiness,
	|	Prepayments.Counterparty                   AS Counterparty,
	|	Prepayments.Contract                      AS Contract,
	|	Prepayments.TaxationType           AS TaxationType,
	|	Prepayments.ARAPDocument            AS ARAPDocument,
	|	Prepayments.ARAPObject               AS ARAPObject,
	|	Prepayments.AdvanceDate                   AS AdvanceDate,
	|	Prepayments.MaturityDate                AS MaturityDate,
	|	Prepayments.DocumentRecorder          AS DocumentRecorder,
	|	MAX(Prepayments.DocumentCurrency)    AS DocumentCurrency,
	|	MAX(
	|		CASE
	|			WHEN Prepayments.TaxationType = &TypeOfVATTaxationIsEmpty
	|					OR NOT Prepayments.TaxationType IN (&TypesOfTaxationWithoutVAT)
	|				THEN
	|				CASE
	|					WHEN Prepayments.MaturityDate = &DateEmpty // If it is a balance, we charge VAT
	|						OR &AdvanceSelectionRule = VALUE(Enum.ProcedureOfRegisteringTaxInvoicesForPrepayment.AllPayments)
	|						OR &AdvanceSelectionRule = VALUE(Enum.ProcedureOfRegisteringTaxInvoicesForPrepayment.EmptyRef)
	|						THEN TRUE
	|					WHEN &AdvanceSelectionRule = VALUE(Enum.ProcedureOfRegisteringTaxInvoicesForPrepayment.AllExceptSettledDuringDay)
	|					THEN DATEDIFF(Prepayments.AdvanceDate, Prepayments.MaturityDate, DAY) > 0
	|					WHEN &AdvanceSelectionRule = VALUE(Enum.ProcedureOfRegisteringTaxInvoicesForPrepayment.NotSetOffWithinFiveCalendarDays)
	|						THEN (DATEDIFF(Prepayments.AdvanceDate, Prepayments.MaturityDate, DAY) >= 5
	|							OR ENDOFPERIOD(Prepayments.AdvanceDate, QUARTER) < Prepayments.MaturityDate)
	|					WHEN &AdvanceSelectionRule = VALUE(Enum.ProcedureOfRegisteringTaxInvoicesForPrepayment.NotSetOffBeforeMonthEnd)
	|						THEN Prepayments.MaturityDate > ENDOFPERIOD(Prepayments.AdvanceDate, MONTH)
	|					WHEN &AdvanceSelectionRule = VALUE(Enum.ProcedureOfRegisteringTaxInvoicesForPrepayment.NotSetOffBeforeQuarterEnd)
	|						THEN Prepayments.MaturityDate > ENDOFPERIOD(Prepayments.AdvanceDate, QUARTER)
	|					ELSE
	|						FALSE
	|				END
	|			ELSE
	|				FALSE
	|		END
	|	) AS AccrueVAT,
	|	MAX(
	|		CASE
	|			WHEN &AdvanceSelectionRule = VALUE(Enum.ProcedureOfRegisteringTaxInvoicesForPrepayment.AllPayments)
	|				OR &AdvanceSelectionRule = VALUE(Enum.ProcedureOfRegisteringTaxInvoicesForPrepayment.EmptyRef)
	|				THEN Prepayments.AdvanceDate
	|		WHEN &AdvanceSelectionRule = VALUE(Enum.ProcedureOfRegisteringTaxInvoicesForPrepayment.AllExceptSettledDuringDay)
	|				AND (Prepayments.MaturityDate = &DateEmpty
	|					OR DATEDIFF(Prepayments.AdvanceDate, Prepayments.MaturityDate, DAY) > 0)
	|				THEN ENDOFPERIOD(Prepayments.AdvanceDate, DAY)
	|		WHEN &AdvanceSelectionRule = VALUE(Enum.ProcedureOfRegisteringTaxInvoicesForPrepayment.NotSetOffWithinFiveCalendarDays)
	|				THEN CASE
	|					// This is the remainder and the estimated date of formation of the SF goes beyond the quarter
	|					WHEN Prepayments.MaturityDate = &DateEmpty
	|							AND ENDOFPERIOD(DATEADD(Prepayments.AdvanceDate, DAY, 4), DAY) > ENDOFPERIOD(&EndDate, QUARTER)
	|						// setting the end of the quarter
	|						THEN ENDOFPERIOD(&EndDate, QUARTER)
	|					// This is the balance and the estimated date of formation of the SF within the quarter
	|					WHEN Prepayments.MaturityDate = &DateEmpty
	|							AND ENDOFPERIOD(DATEADD(Prepayments.AdvanceDate, DAY, 4), DAY) <= ENDOFPERIOD(&EndDate, QUARTER)
	|						// we set the expected date of formation of the SF
	|						THEN ENDOFPERIOD(DATEADD(Prepayments.AdvanceDate, DAY, 4), DAY)
	|					// This is a set-off, but the maturity date is in another quarter
	|					WHEN ENDOFPERIOD(Prepayments.AdvanceDate, QUARTER) < Prepayments.MaturityDate
	|						// setting the end of the quarter
	|						THEN ENDOFPERIOD(Prepayments.AdvanceDate, QUARTER)
	|					// This is a set-off and the difference between the repayment date and the advance date is >= 5 days
	|					WHEN DATEDIFF(Prepayments.AdvanceDate, Prepayments.MaturityDate, DAY) >= 5
	|						// we set the expected date of formation of the SF
	|						THEN ENDOFPERIOD(DATEADD(Prepayments.AdvanceDate, DAY, 4), DAY)
	|					ELSE &DateEmpty
	|				END
	|			WHEN &AdvanceSelectionRule = VALUE(Enum.ProcedureOfRegisteringTaxInvoicesForPrepayment.NotSetOffBeforeMonthEnd)
	|				AND (Prepayments.MaturityDate = &DateEmpty
	|					OR Prepayments.MaturityDate > ENDOFPERIOD(Prepayments.AdvanceDate, MONTH))
	|				THEN ENDOFPERIOD(Prepayments.AdvanceDate, MONTH) 
	|			WHEN &AdvanceSelectionRule = VALUE(Enum.ProcedureOfRegisteringTaxInvoicesForPrepayment.NotSetOffBeforeQuarterEnd)
	|				AND (Prepayments.MaturityDate = &DateEmpty
	|					OR Prepayments.MaturityDate > ENDOFPERIOD(Prepayments.AdvanceDate, QUARTER))
	|				THEN ENDOFPERIOD(Prepayments.AdvanceDate, QUARTER)
	|			ELSE
	|				&DateEmpty
	|		END
	|	) AS DateOfSFFormation,
	|	SUM(Prepayments.Sum) AS Sum,
	|	SUM(Prepayments.SumCurr)  AS SumCurr,
	|	SUM(Prepayments.SumMan)  AS SumMan
	|INTO BaseNDS_AdvancesReceived
	|FROM
	|	(
	|	// Settlement data
	|	SELECT
	|		Prepayments.Organization                       AS Organization,
	|		Prepayments.ExhDirectionOfActivity        AS LineOfBusiness,
	|		Prepayments.ExCounterparty                     AS Counterparty,
	|		Prepayments.Exodus                        AS Contract,
	|		&TextOfDefinitionOfTaxation         AS TaxationType,
	|		Prepayments.ARAPDocument                 AS ARAPDocument,
	|		Prepayments.SourceObjectOfCalculations_            AS ARAPObject,
	|		Prepayments.AdvanceDate                        AS AdvanceDate,
	|		Prepayments.MaturityDate                     AS MaturityDate,
	|		Prepayments.DocumentRecorder               AS DocumentRecorder,
	|		Prepayments.DocumentCurrency                   AS DocumentCurrency,
	|		Prepayments.SumCompl                         AS Sum,
	|		Prepayments.SumCurr                          AS SumCurr,
	|		Prepayments.SumMan                          AS SumMan
	|	FROM
	|		AdvancesReceivedByRepaymentsAndBalances AS Prepayments
	|	
	|	UNION ALL
	|
	|	SELECT
	|		Credits.Organization                                                 AS Organization,
	|		Credits.LineOfBusiness                                     AS LineOfBusiness,
	|		Credits.Counterparty                                                  AS Counterparty,
	|		Credits.Contract                                                     AS Contract,
	|		Credits.VATTaxation                                          AS TaxationType,
	|		Credits.DocumentPayments                                              AS ARAPDocument,
	|		Credits.ARAPObject                                              AS ARAPObject,
	|		Credits.Date                                                        AS AdvanceDate,
	|		&DateEmpty                                                        AS MaturityDate,
	|		Credits.DocumentRecorder                                         AS DocumentRecorder,
	|		Credits.Currency                                                      AS DocumentCurrency,
	|		Credits.SumCompl                                                   AS Sum,
	|		Credits.Sum                                                       AS SumCurr,
	|		Credits.Sum                                                       AS SumMan
	|	FROM
	|		OffsetsOfAdvancesReceivedByInvoicesAdjustmentsForReduction AS Credits
	|
	|	UNION ALL
	|	
	|	// Other data
	|	SELECT
	|		Repayments.Organization                       AS Organization,
	|		Repayments.LineOfBusiness           AS LineOfBusiness,
	|		Repayments.Counterparty                        AS Counterparty,
	|		Repayments.Contract                           AS Contract,
	|		Repayments.TaxationType                AS TaxationType,
	|		Repayments.ARAPDocument                 AS ARAPDocument,
	|		&EmptyCalculationObject                       AS ARAPObject,
	|		Repayments.AdvanceDate                        AS AdvanceDate,
	|		Repayments.MaturityDate                     AS MaturityDate,
	|		Repayments.DocumentRecorder               AS DocumentRecorder,
	|		Repayments.DocumentCurrency                   AS DocumentCurrency,
	|		Repayments.RepaymentAmount                    AS Sum,
	|		Repayments.RepaymentAmountVal                 AS SumCurr,
	|		Repayments.ManRepaymentAmount                 AS SumMan
	|	FROM
	|		AdvancesReceivedToMaturity AS Repayments
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		AdvanceData.Organization               AS Organization,
	|		AdvanceData.LineOfBusiness   AS LineOfBusiness,
	|		AdvanceData.Counterparty                AS Counterparty,
	|		AdvanceData.Contract                   AS Contract,
	|		AdvanceData.TaxationType        AS TaxationType,
	|		AdvanceData.ARAPDocument         AS ARAPDocument,
	|		&EmptyCalculationObject                   AS ARAPObject,
	|		AdvanceData.AdvanceDate                AS AdvanceDate,
	|		DATETIME(1,1,1)                        AS MaturityDate,
	|		UNDEFINED                            AS DocumentRecorder,
	|		AdvanceData.DocumentCurrency           AS DocumentCurrency,
	|		CAST(BalancesOnAdvances.SumBalance *
	|			CASE
	|				WHEN AdvanceData.AdvanceAmountVal <> 0
	|					THEN AdvanceData.AdvanceAmount / AdvanceData.AdvanceAmountVal
	|				ELSE
	|					0
	|			END AS NUMBER(31,2))              AS Sum,
	|		BalancesOnAdvances.SumBalance           AS SumCurr,
	|		CAST(BalancesOnAdvances.SumBalance *
	|			CASE
	|				WHEN AdvanceData.AdvanceAmountOfMan <> 0
	|					THEN AdvanceData.AdvanceAmount / AdvanceData.AdvanceAmountOfMan
	|				ELSE
	|					0
	|			END AS NUMBER(31,2))              AS SumMan
	|	FROM
	|		AccumulationRegister.GiftCertificates.Balance(&EndDateIncluding,
	|			(GiftCertificate) IN 
	|					(SELECT 
	|						AdvanceData.GiftCertificate
	|					FROM
	|						Advances_GiftCertificates AS AdvanceData
	|					)
	|		) AS BalancesOnAdvances
	|		INNER JOIN
	|			Advances_GiftCertificates AS AdvanceData
	|		ON
	|			BalancesOnAdvances.GiftCertificate = AdvanceData.GiftCertificate
	|	
	|	) AS Prepayments
	|
	|WHERE
	|	(Prepayments.AdvanceDate BETWEEN &StartDate AND &EndDate)
	|	AND VALUETYPE(Prepayments.ARAPDocument) IN (&TypesOfSettlementDocumentsReceived)
	|	AND (&ExcludeTypesOfTaxationWithoutVAT = FALSE
	|			OR NOT Prepayments.TaxationType IN (&TypesOfTaxationWithoutVAT))
	|	AND Prepayments.TaxationType <> VALUE(Enum.VATTaxationTypes.ProductionWithLongCycle)
	|
	|GROUP BY
	|	Prepayments.Organization,
	|	Prepayments.LineOfBusiness,
	|	Prepayments.Counterparty,
	|	Prepayments.Contract,
	|	Prepayments.TaxationType,
	|	Prepayments.ARAPDocument,
	|	Prepayments.ARAPObject,
	|	Prepayments.AdvanceDate,
	|	Prepayments.MaturityDate,
	|	Prepayments.DocumentRecorder
	|
	|HAVING
	|	(&IncludeReferenceDataThatDoesNotRequireVAT
	|		OR
	|		MAX(
	|		CASE
	|			WHEN NOT Prepayments.TaxationType IN (&TypesOfTaxationWithoutVAT)
	|				THEN
	|				CASE
	|					WHEN Prepayments.MaturityDate = &DateEmpty // If it is a balance, we charge VAT
	|						OR &AdvanceSelectionRule = VALUE(Enum.ProcedureOfRegisteringTaxInvoicesForPrepayment.AllPayments)
	|						OR &AdvanceSelectionRule = VALUE(Enum.ProcedureOfRegisteringTaxInvoicesForPrepayment.EmptyRef)
	|						THEN TRUE
	|					WHEN &AdvanceSelectionRule = VALUE(Enum.ProcedureOfRegisteringTaxInvoicesForPrepayment.AllExceptSettledDuringDay)
	|					THEN DATEDIFF(Prepayments.AdvanceDate, Prepayments.MaturityDate, DAY) > 0
	|					WHEN &AdvanceSelectionRule = VALUE(Enum.ProcedureOfRegisteringTaxInvoicesForPrepayment.NotSetOffWithinFiveCalendarDays)
	|						THEN (DATEDIFF(Prepayments.AdvanceDate, Prepayments.MaturityDate, DAY) >= 5
	|							OR ENDOFPERIOD(Prepayments.AdvanceDate, QUARTER) < Prepayments.MaturityDate)
	|					WHEN &AdvanceSelectionRule = VALUE(Enum.ProcedureOfRegisteringTaxInvoicesForPrepayment.NotSetOffBeforeMonthEnd)
	|						THEN Prepayments.MaturityDate > ENDOFPERIOD(Prepayments.AdvanceDate, MONTH)
	|					WHEN &AdvanceSelectionRule = VALUE(Enum.ProcedureOfRegisteringTaxInvoicesForPrepayment.NotSetOffBeforeQuarterEnd)
	|						THEN Prepayments.MaturityDate > ENDOFPERIOD(Prepayments.AdvanceDate, QUARTER)
	|					ELSE
	|						FALSE
	|				END
	|			ELSE
	|				FALSE
	|		END)
	|	)
	|	AND SUM(Prepayments.SumCurr) <> 0
	|
	|INDEX BY
	|	ARAPDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP Advances_GiftCertificates
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP AdvancesReceived_Occurrences
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP AdvancesReceivedToMaturity
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP OffsetsOfAdvancesReceivedByInvoicesAdjustmentsForReduction
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP AdvancesReceivedByRepaymentsAndBalances
	|
	|";
	
	ParametersOfButAllocation = InitializeParameters_Advances_TaxDetermination(False);
	ParametersOfButAllocation.ResourceField = "Prepayments.SourceObjectOfCalculations_";
	RequestPostProcessing_Advances_TaxType(Query, CalculationParameters, ParametersOfButAllocation);
	
	QueryPostprocessing_Advances_SETIndexFields(Query, CalculationParameters, "BaseNDS_AdvancesReceived");
	
	Query.Execute();
	
EndProcedure

// Prepare a temporary table "calculation_transference_events".
// Creates a temporary table with columns.
// See ARAPAccountingVAT.PrepareVT_SettlementsWithClients_TransfersOfAdvances.
//
// Parameters:
//  TempTablesManager - TempTablesManager - 
//  CalculationParameters        - See InitializeParametersForPreparationOfAdvancePaymentsForVATPurposes
//  SettingsTable - ValueTable - with columns:
//		* Organization - CatalogRef.Companies -
//		* UseVATAccounting - Boolean - 
//		* BasicTaxationVATSales - EnumRef.VATTaxationTypes - 
//		* MainActivityVATProcurement - EnumRef.VATTaxationTypes - 
Procedure PrepareVT_SettlementsWithClients_TransfersOfAdvances(TempTablesManager, CalculationParameters, SettingsTable = Undefined) Export
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	FillInServiceParametersForCalculatingAdvances(CalculationParameters, SettingsTable);
	
	SetRequestParametersForPreparationOfAdvancePaymentsForVATPurposes(Query, CalculationParameters);
	
	If CostCalculationAppliedAlgorithms.TemporaryTableExists(TempTablesManager,
		"SettlementsWithClients_TransfersOfAdvances") Then
		Query.Text = "DROP SettlementsWithClients_TransfersOfAdvances";
		Query.Execute();
	EndIf;
	
	CalculationParametersForMutualSettlements =
		ARAPAccountingVAT.InitializeParametersForPreparationOfAdvancePayments(CalculationParameters);
	
	CalculationParametersForMutualSettlements.ManualIndexFields.Clear();
	CalculationParametersForMutualSettlements.CreateEmptyTable =
		CalculationParameters.CreateEmptyTable Or Not CalculationParameters.EnableSettlementData;
	If ValueIsFilled(CalculationParameters.Companies) Then
		CalculationParametersForMutualSettlements.EnableOrganizationSelection = True;
		CalculationParametersForMutualSettlements.Companies = CalculationParameters.Organizations_AdvancesReceived;
	EndIf;
	
	ARAPAccountingVAT.PrepareVT_SettlementsWithClients_TransfersOfAdvances(
		TempTablesManager,
		CalculationParametersForMutualSettlements);
	
EndProcedure

Procedure PrepareBT_BalancesAdvancesReceivedBeforeTransfer(TempTablesManager, CalculationParameters, SettingsTable = Undefined) Export
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	FillInServiceParametersForCalculatingAdvances(CalculationParameters, SettingsTable); 
	
	SetRequestParametersForPreparationOfAdvancePaymentsForVATPurposes(Query, CalculationParameters);
	
	Query.Text =
	"SELECT
	|	AccrualFromPrepaymentFromCustomer.Organization AS Organization,
	|	AccrualFromPrepaymentFromCustomer.DocumentPayments AS DocumentPayments,
	|	AccrualFromPrepaymentFromCustomer.Counterparty AS Counterparty,
	|	MAX(AccrualFromPrepaymentFromCustomer.CorrectedTaxInvoice) AS CorrectedTaxInvoice,
	|	AccrualFromPrepaymentFromCustomer.Department AS Department,
	|	AccrualFromPrepaymentFromCustomer.LineOfBusiness AS LineOfBusiness,
	|	AccrualFromPrepaymentFromCustomer.ARAPObject AS ARAPObject,
	|	AccrualFromPrepaymentFromCustomer.VATRate AS VATRate,
	|	SUM(AccrualFromPrepaymentFromCustomer.AmountExcludingVAT) AS AmountExcludingVAT,
	|	SUM(AccrualFromPrepaymentFromCustomer.VAT) AS VAT,
	|	SUM(AccrualFromPrepaymentFromCustomer.VATManag) AS VATManag
	|INTO BalancesAdvancesReceivedBeforeTransfer
	|FROM
	|	(SELECT
	|		DD.Organization AS Organization,
	|		DD.DocumentPayments AS DocumentPayments,
	|		DD.Counterparty AS Counterparty,
	|		DD.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|		DD.Department AS Department,
	|		DD.LineOfBusiness AS LineOfBusiness,
	|		DD.VATRate AS VATRate,
	|		DD.ARAPObject AS ARAPObject,
	|		DD.AmountExcludingVATBalance AS AmountExcludingVAT,
	|		DD.VATBalance AS VAT,
	|		DD.VATManagBalance AS VATManag
	|	FROM
	|		AccumulationRegister.VATPrepaymentsFromCustomer.Balance(
	|				&StartDate,
	|				Organization IN (&Organizations_AdvancesReceived)
	|					AND &TextSelectionByParameters) AS DD
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DD.Organization,
	|		DD.DocumentPayments,
	|		DD.Counterparty,
	|		DD.CorrectedTaxInvoice,
	|		DD.Department,
	|		DD.LineOfBusiness,
	|		DD.VATRate,
	|		DD.ARAPObject,
	|		CASE
	|			WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN DD.AmountExcludingVAT
	|			ELSE -DD.AmountExcludingVAT
	|		END,
	|		CASE
	|			WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN DD.VAT
	|			ELSE -DD.VAT
	|		END,
	|		CASE
	|			WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN DD.VATManag
	|			ELSE -DD.VATManag
	|		END
	|	FROM
	|		AccumulationRegister.VATPrepaymentsFromCustomer AS DD
	|	WHERE
	|		DD.Period BETWEEN &StartDate AND &EndDate
	|		AND NOT DD.PeriodEndTransaction
	|		AND DD.Organization IN(&Organizations_AdvancesReceived)
	|		AND &TextSelectionByParameters
	|		AND DD.Active
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DD.Organization,
	|		DD.DocumentPayments,
	|		DD.Counterparty,
	|		DD.CorrectedTaxInvoice,
	|		DD.Department,
	|		DD.LineOfBusiness,
	|		DD.VATRate,
	|		DD.ARAPObject,
	|		CASE
	|			WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN DD.AmountExcludingVAT
	|			ELSE -DD.AmountExcludingVAT
	|		END,
	|		CASE
	|			WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN DD.VAT
	|			ELSE -DD.VAT
	|		END,
	|		CASE
	|			WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN DD.VATManag
	|			ELSE -DD.VATManag
	|		END
	|	FROM
	|		VATAdvancesReceivedStorno AS DD
	|	WHERE
	|		&TextSelectionByParameters
	|
	|	UNION ALL
	|	
	|	SELECT
	|		DD.Organization,
	|		DD.DocumentPayments,
	|		DD.Counterparty,
	|		DD.CorrectedTaxInvoice,
	|		DD.Department,
	|		DD.LineOfBusiness,
	|		DD.VATRate,
	|		DD.ARAPObject,
	|		CASE
	|			WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN DD.AmountExcludingVAT
	|			ELSE -DD.AmountExcludingVAT
	|		END,
	|		CASE
	|			WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN DD.VAT
	|			ELSE -DD.VAT
	|		END,
	|		CASE
	|			WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN DD.VATManag
	|			ELSE -DD.VATManag
	|		END
	|	FROM
	|		VATAdvancesReceivedStornoOffsets AS DD
	|	WHERE
	|		&TextSelectionByParameters
	|
	|	UNION ALL
	|	
	|	SELECT
	|		DD.Organization,
	|		DD.DocumentPayments,
	|		DD.Counterparty,
	|		DD.CorrectedTaxInvoice,
	|		DD.Department,
	|		DD.LineOfBusiness,
	|		DD.VATRate,
	|		DD.ARAPObject,
	|		CASE
	|			WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN DD.AmountExcludingVAT
	|			ELSE -DD.AmountExcludingVAT
	|		END,
	|		CASE
	|			WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN DD.VAT
	|			ELSE -DD.VAT
	|		END,
	|		CASE
	|			WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN DD.VATManag
	|			ELSE -DD.VATManag
	|		END
	|	FROM
	|		VATAdvancesReceivedUnderISF AS DD
	|	WHERE
	|		NOT DD.Event IN (VALUE(Enum.EventsVATFromPrepayments.DeductionOnPrepaymentSettlement),
	|						VALUE(Enum.EventsVATFromPrepayments.DeductionOnPrepapaymentReturn))
	|		AND &TextSelectionByParameters) AS AccrualFromPrepaymentFromCustomer
	|
	|GROUP BY
	|	AccrualFromPrepaymentFromCustomer.Organization,
	|	AccrualFromPrepaymentFromCustomer.DocumentPayments,
	|	AccrualFromPrepaymentFromCustomer.Counterparty,
	|	AccrualFromPrepaymentFromCustomer.Department,
	|	AccrualFromPrepaymentFromCustomer.LineOfBusiness,
	|	AccrualFromPrepaymentFromCustomer.VATRate,
	|	AccrualFromPrepaymentFromCustomer.ARAPObject
	|
	|HAVING
	|	(SUM(AccrualFromPrepaymentFromCustomer.AmountExcludingVAT) <> 0
	|		OR SUM(AccrualFromPrepaymentFromCustomer.VAT) <> 0)
	|
	|INDEX BY
	|	Organization,
	|	DocumentPayments,
	|	Counterparty";
	PathParameters = InitializeParameters_Advances_FieldPathsAndReplacementText();
	PathParameters.FullPath_SettlementDocument = "DocumentPayments";
	RequestPostprocessing_Advances_ForSelectionByParameters(Query, CalculationParameters, PathParameters);
	
	Query.Execute();

EndProcedure

Procedure PrepareVT_BalancesAdvancesIssuedBeforeTransfer(TempTablesManager, CalculationParameters, SettingsTable = Undefined) Export
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	FillInServiceParametersForCalculatingAdvances(CalculationParameters, SettingsTable); 
	
	SetRequestParametersForPreparationOfAdvancePaymentsForVATPurposes(Query, CalculationParameters);
	
	Query.Text =
	"SELECT
	|	AccrualFromIssuedAdvance.Organization AS Organization,
	|	AccrualFromIssuedAdvance.DocumentPayments AS DocumentPayments,
	|	AccrualFromIssuedAdvance.Counterparty AS Counterparty,
	|	MAX(AccrualFromIssuedAdvance.CorrectedTaxInvoice) AS CorrectedTaxInvoice,
	|	AccrualFromIssuedAdvance.Department           AS Department,
	|	AccrualFromIssuedAdvance.LineOfBusiness AS LineOfBusiness,
	|	AccrualFromIssuedAdvance.ARAPObject          AS ARAPObject,
	|	AccrualFromIssuedAdvance.VATRate               AS VATRate,
	|	SUM(AccrualFromIssuedAdvance.AmountExcludingVAT)      AS AmountExcludingVAT,
	|	SUM(AccrualFromIssuedAdvance.VAT)              AS VAT,
	|	SUM(AccrualFromIssuedAdvance.VATManag)           AS VATManag
	|INTO BalancesAdvancesIssuedBeforeTransfer
	|FROM
	|	(SELECT
	|		DD.Organization              AS Organization,
	|		DD.DocumentPayments           AS DocumentPayments,
	|		DD.Counterparty               AS Counterparty,
	|		DD.CorrectedTaxInvoice  AS CorrectedTaxInvoice,
	|		DD.Department            AS Department,
	|		DD.LineOfBusiness  AS LineOfBusiness,
	|		DD.VATRate                AS VATRate,
	|		DD.ARAPObject           AS ARAPObject,
	|		-DD.AmountExcludingVATBalance      AS AmountExcludingVAT,
	|		-DD.VATBalance              AS VAT,
	|		-DD.VATManagBalance           AS VATManag
	|	FROM
	|		AccumulationRegister.VATPrepaymentsToVendor.Balance(
	|			&StartDate, 
	|			Organization IN (&Organizations_AdvancesIssued)
	|			AND &TextSelectionByParameters) AS DD
	|	
	|	UNION ALL
	|
	|	SELECT
	|		DD.Organization             AS Organization,
	|		DD.DocumentPayments          AS DocumentPayments,
	|		DD.Counterparty              AS Counterparty,
	|		DD.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|		DD.Department            AS Department,
	|		DD.LineOfBusiness AS LineOfBusiness,
	|		DD.VATRate               AS VATRate,
	|		DD.ARAPObject          AS ARAPObject,
	|		CASE
	|			WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN DD.AmountExcludingVAT
	|			ELSE -DD.AmountExcludingVAT
	|		END                      AS AmountExcludingVAT,
	|		CASE
	|			WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN DD.VAT
	|			ELSE -DD.VAT
	|		END                      AS VAT,
	|		CASE
	|			WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN DD.VATManag
	|			ELSE -DD.VATManag
	|		END                      AS VATManag
	|	FROM
	|		AccumulationRegister.VATPrepaymentsToVendor AS DD
	|		INNER JOIN
	|			Jobs AS Jobs
	|		ON
	|			DD.Organization = Jobs.Organization
	|			AND DD.DocumentPayments = Jobs.TaxInvoice
	|	WHERE
	|		DD.Period BETWEEN &StartDate AND &EndDate
	|		AND NOT DD.PeriodEndTransaction
	|		AND DD.Organization IN(&Organizations_AdvancesIssued)
	|		AND &TextSelectionByParameters
	|		AND DD.Active
	|
	|	UNION ALL
	|
	|	SELECT
	|		DD.Organization             AS Organization,
	|		DD.DocumentPayments          AS DocumentPayments,
	|		DD.Counterparty              AS Counterparty,
	|		DD.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|		DD.Department            AS Department,
	|		DD.LineOfBusiness AS LineOfBusiness,
	|		DD.VATRate               AS VATRate,
	|		DD.ARAPObject          AS ARAPObject,
	|		CASE
	|			WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN DD.AmountExcludingVAT
	|			ELSE -DD.AmountExcludingVAT
	|		END                      AS AmountExcludingVAT,
	|		CASE
	|			WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN DD.VAT
	|			ELSE -DD.VAT
	|		END                      AS VAT,
	|		CASE
	|			WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN DD.VATManag
	|			ELSE -DD.VATManag
	|		END                      AS VATManag
	|	FROM
	|		VATAdvancesIssuedStorno AS DD
	|	
	|	WHERE
	|		&TextSelectionByParameters
	|
	|	UNION ALL
	|	
	|	SELECT
	|		DD.Organization,
	|		DD.DocumentPayments,
	|		DD.Counterparty,
	|		DD.CorrectedTaxInvoice,
	|		DD.Department,
	|		DD.LineOfBusiness,
	|		DD.VATRate,
	|		DD.ARAPObject,
	|		CASE
	|			WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN DD.AmountExcludingVAT
	|			ELSE -DD.AmountExcludingVAT
	|		END,
	|		CASE
	|			WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN DD.VAT
	|			ELSE -DD.VAT
	|		END,
	|		CASE
	|			WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN DD.VATManag
	|			ELSE -DD.VATManag
	|		END
	|	FROM
	|		VATAdvancesIssuedStornoOffsets AS DD
	|	WHERE
	|		&TextSelectionByParameters
	|
	|	UNION ALL
	|
	|	SELECT
	|		DD.Organization             AS Organization,
	|		DD.DocumentPayments          AS DocumentPayments,
	|		DD.Counterparty              AS Counterparty,
	|		DD.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|		DD.Department            AS Department,
	|		DD.LineOfBusiness AS LineOfBusiness,
	|		DD.VATRate               AS VATRate,
	|		DD.ARAPObject          AS ARAPObject,
	|		CASE
	|			WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN DD.AmountExcludingVAT
	|			ELSE -DD.AmountExcludingVAT
	|		END                      AS AmountExcludingVAT,
	|		CASE
	|			WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN DD.VAT
	|			ELSE -DD.VAT
	|		END                      AS VAT,
	|		CASE
	|			WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN DD.VATManag
	|			ELSE -DD.VATManag
	|		END                      AS VATManag
	|	FROM
	|		VATAdvancesIssuedUnderISF AS DD
	|	
	|	WHERE
	|		&TextSelectionByParameters) AS AccrualFromIssuedAdvance
	|
	|GROUP BY
	|	AccrualFromIssuedAdvance.Organization,
	|	AccrualFromIssuedAdvance.DocumentPayments,
	|	AccrualFromIssuedAdvance.Counterparty,
	|	AccrualFromIssuedAdvance.Department,
	|	AccrualFromIssuedAdvance.LineOfBusiness,
	|	AccrualFromIssuedAdvance.VATRate,
	|	AccrualFromIssuedAdvance.ARAPObject
	|
	|HAVING
	|	(SUM(AccrualFromIssuedAdvance.AmountExcludingVAT) <> 0
	|		OR SUM(AccrualFromIssuedAdvance.VAT) <> 0)
	|
	|INDEX BY
	|	Organization,
	|	DocumentPayments,
	|	Counterparty
	|";

	PathParameters = InitializeParameters_Advances_FieldPathsAndReplacementText();
	PathParameters.FullPath_SettlementDocument = "DocumentPayments";
	RequestPostprocessing_Advances_ForSelectionByParameters(Query, CalculationParameters, PathParameters);
	
	Query.Execute();

EndProcedure

Procedure PrepareVTOffsetsOfAdvancesReceivedByInvoices(TempTablesManager, CalculationParameters)
	
	VATAccountingLocalization.GetOffsetsOfAdvancesReceivedByInvoices(TempTablesManager, CalculationParameters);
	
	If TempTablesManager.Tables.Find("OffsetsOfAdvancesReceivedByInvoices") = Undefined Then
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	VALUE(Catalog.Companies.EmptyRef) AS Organization,
		|	UNDEFINED AS DocumentRecorder,
		|	UNDEFINED AS Counterparty,
		|	UNDEFINED AS Contract,
		|	DATETIME(1,1,1) AS Date,
		|	UNDEFINED AS ARAPObject,
		|	UNDEFINED AS LineOfBusiness,
		|	UNDEFINED AS VATTaxation,
		|	UNDEFINED AS Currency,
		|	UNDEFINED AS DocumentPayments,
		|	0 AS SumCompl,
		|	0 AS Sum
		|INTO OffsetsOfAdvancesReceivedByInvoices
		|WHERE
		|	FALSE";
		Query.TempTablesManager = TempTablesManager;
		Query.Execute();
	
	EndIf;
	
EndProcedure

Procedure PrepareVTOffsetsOfAdvancesReceivedByInvoicesAdjustmentsForReduction(TempTablesManager, CalculationParameters)
	
	VATAccountingLocalization.GetOffsetsOfAdvancesReceivedByInvoicesAdjustmentsForReduction(TempTablesManager, CalculationParameters);
	
	If TempTablesManager.Tables.Find("OffsetsOfAdvancesReceivedByInvoicesAdjustmentsForReduction") = Undefined Then
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	VALUE(Catalog.Companies.EmptyRef) AS Organization,
		|	UNDEFINED AS DocumentRecorder,
		|	UNDEFINED AS Counterparty,
		|	UNDEFINED AS Contract,
		|	DATETIME(1,1,1) AS Date,
		|	UNDEFINED AS ARAPObject,
		|	UNDEFINED AS LineOfBusiness,
		|	UNDEFINED AS VATTaxation,
		|	UNDEFINED AS Currency,
		|	UNDEFINED AS DocumentPayments,
		|	0 AS SumCompl,
		|	0 AS Sum
		|INTO OffsetsOfAdvancesReceivedByInvoicesAdjustmentsForReduction
		|WHERE
		|	FALSE";
		Query.TempTablesManager = TempTablesManager;
		Query.Execute();
	
	EndIf;
	
EndProcedure

#EndRegion

#Region PrepaymentsToVendor

// Prepare a temporary table "Advance data_Occurrences"
// Creates a temporary table with columns:
// 	* company;
// 	* Settlement document;
// 	* Document Recorder;
// 	* Accounting objects;
// 	* Directions of activity;
// 	* Counterparty;
// 	* Contract;
// 	* Type of tax;
// 	* Advance Payment DataAvance;
// 	* Document currency;
// 	* The sum of the advance;
// 	* SummaAvansaVal;
// 	* SummaAvansaUpr.
//
// Parameters:
//  TempTablesManager - TempTablesManager - 
//  CalculationParameters        - See InitializeParametersForPreparationOfAdvancePaymentsForVATPurposes
//  SettingsTable - ValueTable - with columns:
//		* Organization - CatalogRef.Companies -
//		* UseVATAccounting - Boolean - 
//		* BasicTaxationVATSales - EnumRef.VATTaxationTypes - 
//		* MainActivityVATProcurement - EnumRef.VATTaxationTypes - 
Procedure PrepareVT_AdvancesIssued_Occurrences(TempTablesManager, CalculationParameters, SettingsTable = Undefined) Export
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	FillInServiceParametersForCalculatingAdvances(CalculationParameters, SettingsTable);
	
	SetRequestParametersForPreparationOfAdvancePaymentsForVATPurposes(Query, CalculationParameters);
	
	If CostCalculationAppliedAlgorithms.TemporaryTableExists(TempTablesManager,
		"SettlementsWithSuppliers_Advances") Then
		Query.Text = "DROP SettlementsWithSuppliers_Advances";
		Query.Execute();
	EndIf;
	
	CalculationParametersForMutualSettlements =
		ARAPAccountingVAT.InitializeParametersForPreparationOfAdvancePayments(CalculationParameters);
	CalculationParametersForMutualSettlements.ManualIndexFields.Clear();
	CalculationParametersForMutualSettlements.CreateEmptyTable =
		CalculationParameters.CreateEmptyTable Or Not CalculationParameters.EnableSettlementData;
	If ValueIsFilled(CalculationParameters.Companies) Then
		CalculationParametersForMutualSettlements.EnableOrganizationSelection = True;
		CalculationParametersForMutualSettlements.Companies = CalculationParameters.Organizations_AdvancesIssued;
	EndIf;
	
	ARAPAccountingVAT.PrepareVT_SettlementsWithSuppliers_Advances(
			TempTablesManager,
			CalculationParametersForMutualSettlements);
	
	Query.Text =
	"SELECT
	|	Calculations.Organization               AS Organization,
	|	Calculations.ARAPDocument         AS ARAPDocument,
	|	Calculations.DocumentRecorder       AS DocumentRecorder,
	|	Calculations.ARAPObject            AS ARAPObject,
	|	Calculations.LineOfBusiness   AS LineOfBusiness,
	|	Calculations.Counterparty                AS Counterparty,
	|	Calculations.Contract                   AS Contract,
	|	&TextOfDefinitionOfTaxation  AS TaxationType,
	|	Calculations.AdvanceDate                AS AdvanceDate,
	|	Calculations.DocumentCurrency           AS DocumentCurrency,
	|	Calculations.AmountOfSchedAdvance           AS AdvanceAmount,
	|	Calculations.AdvanceAmountVal            AS AdvanceAmountVal,
	|	Calculations.AdvanceAmountOfMan            AS AdvanceAmountOfMan
	|INTO AdvancesIssued_Occurrences
	|FROM
	|	SettlementsWithSuppliers_Advances AS Calculations
	|WHERE
	|	VALUETYPE(Calculations.ARAPDocument) IN (&TypesOfSettlementDocumentsIssued)
	|	AND (&ExcludeTypesOfTaxationWithoutVAT = FALSE
	|		OR NOT &TextOfDefinitionOfTaxation IN (&TypesOfTaxationWithoutVAT))
	|	AND &TextOfDefinitionOfTaxation <> VALUE(Enum.VATTaxationTypes.ProductionWithLongCycle)
	|
	|UNION ALL
	|
	|SELECT
	|	LeasePayments.AccountingDimensionByPartners.Organization             AS Organization,
	|	LeasePayments.ARAPDocument                                 AS ARAPDocument,
	|	LeasePayments.Recorder                                       AS DocumentRecorder,
	|	LeasePayments.Contract                                           AS ARAPObject,
	|	LeasePayments.Contract.LineOfBusiness                   AS LineOfBusiness,
	|	LeasePayments.AccountingDimensionByPartners.Counterparty              AS Counterparty,
	|	LeasePayments.AccountingDimensionByPartners.Contract                 AS Contract,
	|	CASE
	|		WHEN VALUETYPE(LeasePayments.Contract) = TYPE(Catalog.LeaseContract)
	|			THEN CAST(LeasePayments.Contract AS Catalog.LeaseContract).VATTaxation
	|		ELSE
	|			VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|	END AS TaxationType,
	|	BEGINOFPERIOD(LeasePayments.Period, DAY)                       AS AdvanceDate,
	|	MAX(LeasePayments.Currency)                                  AS DocumentCurrency,
	|	SUM(LeasePayments.SumCompl)                                  AS AdvanceAmount,
	|	SUM(LeasePayments.Sum)                                      AS AdvanceAmountVal,
	|	SUM(LeasePayments.SumMan)                                   AS AdvanceAmountOfMan
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP AS LeasePayments
	|	INNER JOIN
	|		InformationRegister.SourceDocumentsData AS SourceDocumentsData
	|	ON
	|		LeasePayments.ARAPDocument = SourceDocumentsData.Document
	|	
	|WHERE
	|	NOT &CreateEmptyTable
	|	AND &IncludeFinancialInstrumentData
	|	AND LeasePayments.Period BETWEEN &StartDate AND &EndDate
	|	AND LeasePayments.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND LeasePayments.AmountType IN (
	|		VALUE(Enum.TypesOfLeasePayments.DepositPayment),
	|		VALUE(Enum.TypesOfLeasePayments.RentalServicePrepayment),
	|		VALUE(Enum.TypesOfLeasePayments.BuyoutValuePrepayment))
	|	AND (LeasePayments.AccountingDimensionByPartners.Organization IN (&Organizations_AdvancesIssued))
	|	AND (&TextSelectionByParameters)
	|	AND VALUETYPE(LeasePayments.ARAPDocument) IN (&TypesOfSettlementDocumentsIssued)
	|	AND LeasePayments.Sum > 0
	|	AND CASE WHEN &ExcludeJUDAS
	|		THEN LeasePayments.BusinessTransactionSetting <> VALUE(Catalog.BusinessTransactionsSettings.LeaseTermAdjustment)
	|		ELSE TRUE
	|	END
	|
	|GROUP BY
	|	LeasePayments.AccountingDimensionByPartners.Organization,
	|	LeasePayments.ARAPDocument,
	|	LeasePayments.Recorder,
	|	LeasePayments.Contract,
	|	LeasePayments.Contract.LineOfBusiness,
	|	LeasePayments.AccountingDimensionByPartners.Counterparty,
	|	LeasePayments.AccountingDimensionByPartners.Contract,
	|	BEGINOFPERIOD(LeasePayments.Period, DAY)
	|
	|INDEX BY
	|	ARAPDocument
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP SettlementsWithSuppliers_Advances
	|";
	
	PathParameters = InitializeParameters_Advances_FieldPathsAndReplacementText();
	PathParameters.FullPath_SettlementDocument = "LeasePayments.ARAPDocument";
	RequestPostprocessing_Advances_ForSelectionByParameters(Query, CalculationParameters, PathParameters);
	
	ParametersOfButAllocation = InitializeParameters_Advances_TaxDetermination(True);
	RequestPostProcessing_Advances_TaxType(Query, CalculationParameters, ParametersOfButAllocation);
	
	QueryPostprocessing_Advances_SETIndexFields(Query, CalculationParameters, "AdvancesIssued_Occurrences");
	
	Query.Execute();
	
EndProcedure

// Prepare a temporary table "Advance data_Repayments"
// Creates a temporary table with columns:
// 	* company;
// 	* Settlement document;
// 	* Document Recorder;
// 	* Advance Payment DataAvance;
// 	* Data settlement;
// 	* Directions of activity;
// 	* Counterparty;
// 	* Contract;
// 	* Type of tax;
// 	* Type of event;
// 	* Document currency;
// 	* Eventsnak;
// 	* Repayment amounts;
// 	* Sum of cancellations;
// 	* The sum of the repayment of UPR.
//
// Parameters:
//  TempTablesManager - TempTablesManager - 
//  CalculationParameters        - See InitializeParametersForPreparationOfAdvancePaymentsForVATPurposes
//  SettingsTable - ValueTable - with columns:
//		* Organization - CatalogRef.Companies -
//		* UseVATAccounting - Boolean - 
//		* BasicTaxationVATSales - EnumRef.VATTaxationTypes - 
//		* MainActivityVATProcurement - EnumRef.VATTaxationTypes - 
Procedure PrepareVT_AdvancesIssued_Repayments(TempTablesManager, CalculationParameters, SettingsTable = Undefined) Export
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	FillInServiceParametersForCalculatingAdvances(CalculationParameters, SettingsTable);
	
	SetRequestParametersForPreparationOfAdvancePaymentsForVATPurposes(Query, CalculationParameters);
	
	If CostCalculationAppliedAlgorithms.TemporaryTableExists(TempTablesManager,
		"SettlementsWithSuppliers_RepaymentOfAdvances") Then
		Query.Text = "DROP SettlementsWithSuppliers_RepaymentOfAdvances";
		Query.Execute();
	EndIf;
	
	CalculationParametersForMutualSettlements =
		ARAPAccountingVAT.InitializeParametersForPreparationOfAdvancePayments(CalculationParameters);
	CalculationParametersForMutualSettlements.ManualIndexFields.Clear();
	CalculationParametersForMutualSettlements.CreateEmptyTable =
		CalculationParameters.CreateEmptyTable Or Not CalculationParameters.EnableSettlementData;
	
	If ValueIsFilled(CalculationParameters.Companies) Then
		CalculationParametersForMutualSettlements.EnableOrganizationSelection = True;
		CalculationParametersForMutualSettlements.Companies = CalculationParameters.Organizations_AdvancesIssued;
	EndIf;
		
	ARAPAccountingVAT.PrepareVT_SettlementsWithSuppliers_RepaymentOfAdvances(
		TempTablesManager,
		CalculationParametersForMutualSettlements);
	
	Query.Text =
	"SELECT
	|	Repayments.Organization                AS Organization,
	|	Repayments.ARAPDocument          AS ARAPDocument,
	|	Repayments.DocumentRecorder        AS DocumentRecorder,
	|	Repayments.AdvanceDate                 AS AdvanceDate,
	|	Repayments.MaturityDate              AS MaturityDate,
	|	Repayments.ExhDirectionOfActivity AS LineOfBusiness,
	|	Repayments.ExCounterparty              AS Counterparty,
	|	Repayments.Exodus                 AS Contract,
	|	Repayments.ARAPObject             AS ARAPObject,
	|	&TextOfDefinitionOfTaxation     AS TaxationType,
	|	Repayments.EventKind                 AS EventKind,
	|	Repayments.ReversingEntry                     AS ReversingEntry,
	|	MAX(Repayments.DocumentCurrency)  AS DocumentCurrency,
	|	SUM(CASE
	|			WHEN Repayments.EventKind = VALUE(Enum.BusinessTransactions.RefundFromVendor)
	|				THEN -1
	|			ELSE
	|				1
	|		END)                           AS EventSign,
	|	SUM(Repayments.LocalRepaymentAmount)  AS RepaymentAmount,
	|	SUM(Repayments.RepaymentAmountVal)   AS RepaymentAmountVal,
	|	SUM(Repayments.ManRepaymentAmount)   AS ManRepaymentAmount
	|INTO AdvancesIssued_Repayment
	|FROM
	|	SettlementsWithSuppliers_RepaymentOfAdvances AS Repayments
	|
	|WHERE
	|	VALUETYPE(Repayments.ARAPDocument) IN (&TypesOfSettlementDocumentsIssued)
	|	AND (&ExcludeTypesOfTaxationWithoutVAT = FALSE
	|		OR NOT &TextOfDefinitionOfTaxation IN (&TypesOfTaxationWithoutVAT))
	|	AND &TextOfDefinitionOfTaxation <> VALUE(Enum.VATTaxationTypes.ProductionWithLongCycle)
	|
	|GROUP BY
	|	Repayments.Organization,
	|	Repayments.ARAPDocument,
	|	Repayments.DocumentRecorder,
	|	Repayments.AdvanceDate,
	|	Repayments.MaturityDate,
	|	Repayments.ExhDirectionOfActivity,
	|	Repayments.ExCounterparty,
	|	Repayments.Exodus,
	|	Repayments.ARAPObject,
	|	&TextOfDefinitionOfTaxation,
	|	Repayments.EventKind,
	|	Repayments.ReversingEntry
	|
	|HAVING
	|	SUM(Repayments.LocalRepaymentAmount * CASE
	|			WHEN Repayments.ReversingEntry = TRUE
	|				THEN -1
	|			ELSE 1
	|		END) > 0
	|
	|UNION ALL
	|
	|SELECT
	|	LeasePayments.AccountingDimensionByPartners.Organization             AS Organization,
	|	LeasePayments.ARAPDocument                                 AS ARAPDocument,
	|	LeasePayments.Recorder                                       AS DocumentRecorder,
	|	BEGINOFPERIOD(SourceDocumentsData.RecorderDate, DAY)    AS AdvanceDate,
	|	LeasePayments.Period                                            AS MaturityDate,
	|	LeasePayments.Contract.LineOfBusiness                   AS LineOfBusiness,
	|	LeasePayments.AccountingDimensionByPartners.Counterparty              AS Counterparty,
	|	LeasePayments.AccountingDimensionByPartners.Contract                 AS Contract,
	|	LeasePayments.Contract                                           AS ARAPObject,
	|	VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT) AS TaxationType,
	|	VALUE(Enum.BusinessTransactions.CustomerPrepaymentSettlement)    AS EventKind,
	|	FALSE                                                               AS ReversingEntry,
	|	MAX(LeasePayments.Currency)                                  AS DocumentCurrency,
	|	1                                                                  AS EventSign,
	|	SUM(LeasePayments.SumCompl)                                  AS RepaymentAmount,
	|	SUM(LeasePayments.Sum)                                      AS RepaymentAmountVal,
	|	SUM(LeasePayments.SumMan)                                   AS ManRepaymentAmount
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP AS LeasePayments
	|	INNER JOIN
	|		InformationRegister.SourceDocumentsData AS SourceDocumentsData
	|	ON
	|		LeasePayments.ARAPDocument = SourceDocumentsData.Document
	|	
	|WHERE
	|	NOT &CreateEmptyTable
	|	AND &IncludeFinancialInstrumentData
	|	AND LeasePayments.Period BETWEEN &StartDate AND &EndDate
	|	AND LeasePayments.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND LeasePayments.AmountType IN (
	|		VALUE(Enum.TypesOfLeasePayments.DepositPayment),
	|		VALUE(Enum.TypesOfLeasePayments.RentalServicePrepayment),
	|		VALUE(Enum.TypesOfLeasePayments.BuyoutValuePrepayment))
	|	AND (LeasePayments.AccountingDimensionByPartners.Organization IN (&Organizations_AdvancesIssued))
	|	AND (&TextSelectionByParameters)
	|	AND VALUETYPE(LeasePayments.ARAPDocument) IN (&TypesOfSettlementDocumentsIssued)
	|	AND VALUETYPE(LeasePayments.Recorder) <> TYPE(Document.LeaseTermAdjustment)
	|	AND LeasePayments.Sum > 0
	|
	|GROUP BY
	|	LeasePayments.AccountingDimensionByPartners.Organization,
	|	LeasePayments.ARAPDocument,
	|	LeasePayments.Recorder,
	|	BEGINOFPERIOD(SourceDocumentsData.RecorderDate, DAY),
	|	LeasePayments.Period,
	|	LeasePayments.Contract.LineOfBusiness,
	|	LeasePayments.AccountingDimensionByPartners.Counterparty,
	|	LeasePayments.AccountingDimensionByPartners.Contract,
	|	LeasePayments.Contract
	|
	|INDEX BY
	|	ARAPDocument
	|
	|;
	|
	|DROP SettlementsWithSuppliers_RepaymentOfAdvances
	|
	|";
	
	PathParameters = InitializeParameters_Advances_FieldPathsAndReplacementText();
	PathParameters.FullPath_SettlementDocument = "LeasePayments.ARAPDocument";
	RequestPostprocessing_Advances_ForSelectionByParameters(Query, CalculationParameters, PathParameters);
	
	ParametersOfButAllocation = InitializeParameters_Advances_TaxDetermination(True);
	ParametersOfButAllocation.ResourceField = "Repayments.SourceObjectOfCalculations_";
	RequestPostProcessing_Advances_TaxType(Query, CalculationParameters, ParametersOfButAllocation);
	
	QueryPostprocessing_Advances_SETIndexFields(Query, CalculationParameters, "AdvancesIssued_Repayment");
	
	Query.Execute();
	
EndProcedure

// Prepare a temporary table "Transfer of data balances"
// Creates a temporary table with columns.
// See ARAPAccountingVAT.PrepareVT_SettlementsWithSuppliers_TransfersOfAdvances
//
// Parameters:
//  TempTablesManager - TempTablesManager - 
//  CalculationParameters        - See InitializeParametersForPreparationOfAdvancePaymentsForVATPurposes
//  SettingsTable - ValueTable - with columns:
//		* Organization - CatalogRef.Companies -
//		* UseVATAccounting - Boolean - 
//		* BasicTaxationVATSales - EnumRef.VATTaxationTypes - 
//		* MainActivityVATProcurement - EnumRef.VATTaxationTypes - 
Procedure PrepareVT_TransfersOfAdvancesIssued(TempTablesManager, CalculationParameters, SettingsTable = Undefined) Export
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	FillInServiceParametersForCalculatingAdvances(CalculationParameters, SettingsTable);
	
	SetRequestParametersForPreparationOfAdvancePaymentsForVATPurposes(Query, CalculationParameters);
	
	If CostCalculationAppliedAlgorithms.TemporaryTableExists(TempTablesManager,
		"SettlementsWithSuppliers_TransfersOfAdvances") Then
		Query.Text = "DROP SettlementsWithSuppliers_TransfersOfAdvances";
		Query.Execute();
	EndIf;
	
	CalculationParametersForMutualSettlements =
		ARAPAccountingVAT.InitializeParametersForPreparationOfAdvancePayments(CalculationParameters);
	
	CalculationParametersForMutualSettlements.ManualIndexFields.Clear();
	CalculationParametersForMutualSettlements.CreateEmptyTable =
		CalculationParameters.CreateEmptyTable Or Not CalculationParameters.EnableSettlementData;
	If ValueIsFilled(CalculationParameters.Companies) Then
		CalculationParametersForMutualSettlements.EnableOrganizationSelection = True;
		CalculationParametersForMutualSettlements.Companies = CalculationParameters.Organizations_AdvancesIssued;
	EndIf;
	
	ARAPAccountingVAT.PrepareVT_SettlementsWithSuppliers_TransfersOfAdvances(
		TempTablesManager,
		CalculationParametersForMutualSettlements);
		
	Query.Text =
	"SELECT
	|	VendorsARAPAccounting.Organization                                 AS Organization,
	|	VendorsARAPAccounting.TransferDocument                            AS TransferDocument,
	|	VendorsARAPAccounting.DocumentPayments                              AS DocumentPayments,
	|	VendorsARAPAccounting.AccountingDimensionByPartners                   AS AccountingDimensionByPartners,
	|	VendorsARAPAccounting.ARAPObject                              AS ARAPObject,
	|	VendorsARAPAccounting.Counterparty                                  AS Counterparty,
	|	VendorsARAPAccounting.LineOfBusiness                     AS LineOfBusiness,
	|	VendorsARAPAccounting.Department                               AS Department,
	|	VendorsARAPAccounting.CorPartnerAccountingDimension                AS CorPartnerAccountingDimension,
	|	VendorsARAPAccounting.CorARAPObject                           AS CorARAPObject,
	|	VendorsARAPAccounting.CorCounterparty                               AS CorCounterparty,
	|	VendorsARAPAccounting.CorLineOfBusiness                  AS CorLineOfBusiness,
	|	VendorsARAPAccounting.DebitBusinessUnit                            AS DebitBusinessUnit,
	|	VendorsARAPAccounting.Period                                      AS Period,
	|	VendorsARAPAccounting.BusinessTransactionSetting              AS BusinessTransactionSetting,
	|	VendorsARAPAccounting.FinRecordID                      AS FinRecordID,
	|	VendorsARAPAccounting.ReversingEntry                                      AS ReversingEntry,
	|	VendorsARAPAccounting.Currency                                      AS Currency,
	|	VendorsARAPAccounting.Prepayment                                  AS Prepayment,
	|	VendorsARAPAccounting.PrepaymentLocal                              AS PrepaymentLocal,
	|	VendorsARAPAccounting.PrepaymentMan                               AS PrepaymentMan
	|INTO TransfersOfAdvancesIssued
	|FROM SettlementsWithSuppliers_TransfersOfAdvances AS VendorsARAPAccounting
	|
	|UNION ALL
	|
	|SELECT
	|	LeasePayments.AccountingDimensionByPartners.Organization                    AS Organization,
	|	LeasePayments.Recorder                                              AS TransferDocument,
	|	LeasePayments.ARAPDocument                                        AS DocumentPayments,
	|	LeasePayments.AccountingDimensionByPartners                                AS AccountingDimensionByPartners,
	|	LeasePayments.Contract                                                  AS ARAPObject,
	|	LeasePayments.AccountingDimensionByPartners.Counterparty                     AS Counterparty,
	|	LeasePayments.Contract.LineOfBusiness                          AS LineOfBusiness,
	|	UNDEFINED                                                              AS Department,
	|	LeasePayments_Expense.AccountingDimensionByPartners                         AS CorPartnerAccountingDimension,
	|	LeasePayments_Expense.Contract                                           AS CorARAPObject,
	|	LeasePayments_Expense.AccountingDimensionByPartners.Counterparty              AS CorCounterparty,
	|	LeasePayments_Expense.Contract.LineOfBusiness                   AS CorLineOfBusiness,
	|	UNDEFINED                                                              AS DebitBusinessUnit,
	|	LeasePayments.Period                                                   AS Period,
	|	LeasePayments.BusinessTransactionSetting                           AS BusinessTransactionSetting,
	|	FALSE                                                                      AS Strono,
	|	LeasePayments.FinRecordID                                   AS FinRecordID,
	|	MAX(LeasePayments.Currency)                                         AS Currency,
	|	SUM(LeasePayments.Sum)                                             AS Prepayment,
	|	SUM(LeasePayments.SumCompl)                                         AS PrepaymentLocal,
	|	SUM(LeasePayments.SumMan)                                          AS PrepaymentMan
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP AS LeasePayments
	|	INNER JOIN
	|		InformationRegister.SourceDocumentsData AS SourceDocumentsData
	|	ON
	|		LeasePayments.ARAPDocument = SourceDocumentsData.Document
	|	INNER JOIN 
	|		Document.LeaseTermAdjustment AS LeaseTermAdjustment
	|	ON
	|		LeasePayments.Recorder = LeaseTermAdjustment.Ref
	|	INNER JOIN 
	|		AccumulationRegister.FinancialInstrumentsARAP AS LeasePayments_Expense
	|	ON LeasePayments_Expense.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND LeasePayments_Expense.Recorder = LeasePayments.Recorder
	|		AND LeasePayments_Expense.ARAPDocument = LeasePayments.ARAPDocument
	|		AND LeasePayments_Expense.FinRecordID = LeasePayments_Expense.FinRecordID
	|		AND (LeasePayments_Expense.Contract <> LeasePayments.Contract
	|			OR LeasePayments_Expense.AccountingDimensionByPartners.Counterparty <> LeasePayments.AccountingDimensionByPartners.Counterparty
	|			OR LeasePayments_Expense.AccountingDimensionByPartners.LineOfBusiness <> LeasePayments.AccountingDimensionByPartners.LineOfBusiness)
	|WHERE
	|	&IncludeFinancialInstrumentData
	|	AND LeasePayments.Period BETWEEN &StartDate AND &EndDate
	|	AND LeasePayments.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND LeasePayments.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.LeaseTermAdjustment)
	|	AND LeasePayments.AmountType IN (
	|		VALUE(Enum.TypesOfLeasePayments.DepositPayment),
	|		VALUE(Enum.TypesOfLeasePayments.RentalServicePrepayment),
	|		VALUE(Enum.TypesOfLeasePayments.BuyoutValuePrepayment))
	|	AND (LeasePayments.AccountingDimensionByPartners.Organization IN (&Organizations_AdvancesIssued))
	|	AND LeasePayments.Active
	|	AND NOT LeasePayments.ReversingEntry
	|	AND LeasePayments.Sum > 0
	|
	|GROUP BY
	|	LeasePayments.AccountingDimensionByPartners.Organization,
	|	LeasePayments.ARAPDocument,
	|	LeasePayments.Recorder,
	|	LeasePayments.Period,
	|	LeasePayments.Contract.LineOfBusiness,
	|	LeasePayments.AccountingDimensionByPartners.Counterparty,
	|	LeasePayments.Contract,
	|	LeasePayments.AccountingDimensionByPartners,
	|	LeasePayments_Expense.Contract.LineOfBusiness,
	|	LeasePayments_Expense.AccountingDimensionByPartners.Counterparty,
	|	LeasePayments_Expense.Contract,
	|	LeasePayments_Expense.AccountingDimensionByPartners,
	|	LeasePayments.BusinessTransactionSetting,
	|	LeasePayments.FinRecordID
	|
	|INDEX BY
	|	Organization,
	|	DocumentPayments
	|;
	|
	|DROP SettlementsWithSuppliers_TransfersOfAdvances
	|
	|";
	
	SetRequestParametersForPreparationOfAdvancePaymentsForVATPurposes(Query, CalculationParameters);
	
	Query.Execute();
	
EndProcedure

#EndRegion

#Region Utilities

// Fill in the properties of calculation parameters from the source structure
//
// Parameters:
//  Receiver - See InitializeParametersForPreparationOfAdvancePaymentsForVATPurposes
//  Source - Structure - structure containing at least one of the receiver properties
//
Procedure FillInPropertiesOfAdvancePaymentParameters(Receiver, Source)
	
	DestinationType  = TypeOf(Receiver);
	SourceType  = TypeOf(Source);
	
	If DestinationType = Type("Structure") And SourceType = Type("Structure") Then
			For Each ReceiverElement In Receiver Do
				SourceValue_ = Undefined;
				If Source.Property(ReceiverElement.Key, SourceValue_) Then
					FillInPropertiesOfAdvancePaymentParameters(Receiver[ReceiverElement.Key], SourceValue_);
				EndIf;
			EndDo;
	ElsIf DestinationType <> Type("Structure") And SourceType <> Type("Structure") Then
		Receiver = Common.CopyRecursive(Source);
	EndIf;
	
EndProcedure

// Sets the necessary parameters for executing requests for advances
//
// Parameters:
//  Query           - Query - 
//  CalculationParameters - See InitializeParametersForPreparationOfAdvancePaymentsForVATPurposes
Procedure SetRequestParametersForPreparationOfAdvancePaymentsForVATPurposes(Query, CalculationParameters)
	
	If Not ValueIsFilled(CalculationParameters.EndDate) Then
		EndDate        = Date(3000, 1, 1);
		EndDateIncluding = Undefined;
	Else
		EndDate        = CalculationParameters.EndDate;
		EndDateIncluding = New Boundary(EndDate);
	EndIf;
	
	DateEmpty        = '00010101';
	
	ARAPDocument = ?(ValueIsFilled(CalculationParameters.ARAPDocument),
							CalculationParameters.ARAPDocument, Undefined);
	
	If ValueIsFilled(CalculationParameters.SelectionParametersForSettlementDocument.SelectionTableName_)
		Or ValueIsFilled(ARAPDocument) Then
		EnableSelectionBasedOnSettlementDocument = True;
	Else
		EnableSelectionBasedOnSettlementDocument = False;
	EndIf;
	
	Query.SetParameter("StartDate",           CalculationParameters.StartDate);
	Query.SetParameter("EndDate",        EndDate);
	Query.SetParameter("EndDateIncluding", EndDateIncluding);
	Query.SetParameter("DateEmpty",           DateEmpty);
	Query.SetParameter("Organizations_AdvancesReceived", CalculationParameters.Organizations_AdvancesReceived);
	Query.SetParameter("Organizations_AdvancesIssued",   CalculationParameters.Organizations_AdvancesIssued);
	Query.SetParameter("ARAPDocument",    ARAPDocument);
	Query.SetParameter("CreateEmptyTable", CalculationParameters.CreateEmptyTable);
	Query.SetParameter("EmptyCalculationObject", Undefined);
	Query.SetParameter("CurrencyOfManAccounting",       Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("EnableSelectionBasedOnSettlementDocument", EnableSelectionBasedOnSettlementDocument);
	Query.SetParameter("AnalyzeManAccountingAdditionally",  CalculationParameters.AnalyzeManAccountingAdditionally);
	
	Query.SetParameter("EnableSettlementData",
		CalculationParameters.EnableSettlementData);
	Query.SetParameter("EnableGiftCertificateData",
		CalculationParameters.EnableGiftCertificateData);
	Query.SetParameter("IncludeFinancialInstrumentData",
		CalculationParameters.IncludeFinancialInstrumentData);
	
	Query.SetParameter("ExcludeTypesOfTaxationWithoutVAT",
		CalculationParameters.ExcludeTypesOfTaxationWithoutVAT);
	Query.SetParameter("TypesOfTaxationWithoutVAT",     CalculationParameters.TypesOfTaxationWithoutVAT);
	Query.SetParameter("TypeOfVATTaxationIsEmpty",   Enums.VATTaxationTypes.EmptyRef());
	
	Query.SetParameter("TypesOfSettlementDocumentsReceived",
		Metadata.Documents.IssuedTaxInvoicePrepayment.Attributes.DocumentBasis.Type.Types());
	Query.SetParameter("TypesOfSettlementDocumentsIssued",
		Metadata.Documents.ReceivedTaxInvoicePrepayment.Attributes.DocumentBasis.Type.Types());
	
	Query.SetParameter("AdvanceSelectionRule", CalculationParameters.AdvanceSelectionRule);
	Query.SetParameter("IncludeReferenceDataThatDoesNotRequireVAT",
		CalculationParameters.IncludeReferenceDataThatDoesNotRequireVAT);
	Query.SetParameter("EnableDebtCancellationOperations",
		CalculationParameters.EnableDebtCancellationOperations); 
	Query.SetParameter("ExcludeJUDAS", CalculationParameters.ExcludeJUDAS);
	
EndProcedure

// Post-processing a request to determine the type of taxation
//
// Parameters:
//  Query			 - Query - 
//  CalculationParameters - See InitializeParametersForPreparationOfAdvancePaymentsForVATPurposes
//  ParametersForDeterminingTaxation - See InitializeParameters_Advances_TaxDetermination
//
Procedure RequestPostProcessing_Advances_TaxType(Query, CalculationParameters, ParametersForDeterminingTaxation)
	
	TaxDefinitionTemplate = "ISNULL(%1.VATTaxation, &TypeOfVATTaxationIsEmpty)";
	
	TextOfDefinitionOfTaxation =
		StrTemplate(TaxDefinitionTemplate, ParametersForDeterminingTaxation.ResourceField);
	
	Query.Text =
		StrReplace(Query.Text, ParametersForDeterminingTaxation.TextToReplace, TextOfDefinitionOfTaxation);
	
EndProcedure

// Postprocessing of the request for selection of advances in the parameters - replaces "&Texturearray"
// 
// Parameters:
// 	Query - Query  -
// 	CalculationParameters - See InitializeParametersForPreparationOfAdvancePaymentsForVATPurposes
// 	PathParameters   - See InitializeParameters_Advances_FieldPathsAndReplacementText
Procedure RequestPostprocessing_Advances_ForSelectionByParameters(Query, CalculationParameters, PathParameters)
	
	MSelectionByParameters = New Array;
	
	FilterFieldName    = CalculationParameters.SelectionParametersForSettlementDocument.FieldName;
	SelectionTableName_ = CalculationParameters.SelectionParametersForSettlementDocument.SelectionTableName_;
	
	FullPath = PathParameters.FullPath_SettlementDocument;
	
	If ValueIsFilled(SelectionTableName_) Then
		
		TextTemplate1 = "%1 IN
		|			(SELECT
		|				%2 AS Ref
		|			FROM
		|				%3 AS T
		|			)
		|";
		
		MSelectionByParameters.Add(StrTemplate(TextTemplate1, FullPath, FilterFieldName, SelectionTableName_));
		
	Else
		
		TextTemplate1 = "(NOT &EnableSelectionBasedOnSettlementDocument OR %1 IN (&ARAPDocument))";
		MSelectionByParameters.Add(StrTemplate(TextTemplate1, FullPath));
		
	EndIf;
	
	TextSelectionByParameters = StrConcat(MSelectionByParameters, " And ");
	Query.Text = StrReplace(Query.Text, PathParameters.ReplacementText, TextSelectionByParameters);
	
EndProcedure

Procedure QueryPostprocessing_Advances_SETIndexFields(Query, CalculationParameters, TableName)
	
	MIndexFields = CalculationParameters.ManualIndexFields;
	
	If Not ValueIsFilled(MIndexFields) Then
		Return;
	EndIf;
	
	QuerySchema = New QuerySchema;
	
	QuerySchema.SetQueryText(Query.Text);
	
	For Each Package In QuerySchema.QueryBatch Do
		If Package.PlacementTable = TableName Then
			
			Package.Order.Clear();
			For Each IndexField In MIndexFields Do
				Package.Index.Add(IndexField);
			EndDo;
			
		EndIf;
	EndDo;
	
	Query.Text = QuerySchema.GetQueryText();
	
EndProcedure

// To initialize the parameters for determining net
//
// Parameters:
//  ThisIsAdvanceIssued - Boolean - "True" - Issued, "False" - Received
// 
// Returns:
//  Structure - Contains:
//  	* ResourceField      - String - Field where the n/a will be analyzed
//  	* TextToReplace  - String - Lines in the request that will be replaced with the text of the tax definition
//  	* ThisIsAdvanceIssued - Boolean - "True" - Issued, "False" - Received
//
Function InitializeParameters_Advances_TaxDetermination(ThisIsAdvanceIssued)
	
	ParametersStructure = New Structure;
	
	ParametersStructure.Insert("ResourceField",      "ARAPObject");
	ParametersStructure.Insert("TextToReplace",  "&TextOfDefinitionOfTaxation");
	ParametersStructure.Insert("ThisIsAdvanceIssued", ThisIsAdvanceIssued);
	
	Return ParametersStructure;
	
EndFunction

// Initialize parameters to specify paths to fields and text for replacing selection by parameters
//
// Returns:
//  Structure - Contains:
//  	* ReplacementText                  - String - Replaced text in the request
//  	* FullPath_SettlementDocument - String - Full path to the settlement document
//
Function InitializeParameters_Advances_FieldPathsAndReplacementText()
	
	ParametersStructure = New Structure;
	
	ParametersStructure.Insert("ReplacementText", "&TextSelectionByParameters");
	
	ParametersStructure.Insert("FullPath_SettlementDocument", "ARAPDocument");
	
	Return ParametersStructure;
	
EndFunction

Function VATAccountingSettingsForOrganizations(Companies, Period = Undefined)
	
	AccountingSettings = VATAccountingERP.AccountingSettings();
	
	DataTable = New ValueTable();
	
	DataTable.Columns.Add("Organization",         New TypeDescription("CatalogRef.Companies"));
	DataTable.Columns.Add("UseVATAccounting", New TypeDescription("Boolean"));
	DataTable.Columns.Add("BasicTaxationVATSales",
		New TypeDescription("EnumRef.VATTaxationTypes"));
	DataTable.Columns.Add("MainActivityVATProcurement",
		New TypeDescription("EnumRef.VATTaxationTypes"));
	
	For Each Organization In Companies Do
		
		DataString1 = DataTable.Add();
		
		DataString1.Organization = Organization;
		
		FillPropertyValues(DataString1, AccountingSettings);
		
	EndDo;
	
	If Not AccountingSettings.UseVATAccounting Then
		// If VAT accounting is not used, we use the values set for the entire IB
		Return DataTable;
	EndIf;
	
	For Each DataString1 In DataTable Do
		
		AccountingParametersForOrganization = VATAccountingERP.AccountingParametersForOrganization(DataString1.Organization, Period);
		
		FillPropertyValues(DataString1, AccountingParametersForOrganization);
		
	EndDo;
	
	Return DataTable;
	
EndFunction

Procedure FillInServiceParametersForCalculatingAdvances(CalculationParameters, SettingsTable)
	
	If Not CalculationParameters.ClearServiceColumns Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(CalculationParameters.EndDate) Then
		EndDate        = Date(3000, 1, 1);
	Else
		EndDate        = CalculationParameters.EndDate;
	EndIf;
	
	// Selection by organization
	
	If ValueIsFilled(CalculationParameters.Companies) Then
		
		If TypeOf(CalculationParameters.Companies) = Type("CatalogRef.Companies") Then
			MOrganizations = CommonClientServer.ValueInArray(CalculationParameters.Companies);
		ElsIf TypeOf(CalculationParameters.Companies) = Type("ValueList") Then
			MOrganizations = CalculationParameters.Companies.UnloadValues();
		Else
			MOrganizations = CalculationParameters.Companies;
		EndIf;
		
	Else
		
		MOrganizations = Catalogs.Companies.AvailableCompanies();
		
		CommonClientServer.DeleteAllValueOccurrencesFromArray(
			MOrganizations, 
			Catalogs.Companies.ManagementCompany);
			
	EndIf;
	
	// Filter organizations by attributes of VAT accounting settings
	
	TypesOfTaxationWithoutVAT = CalculationParameters.TypesOfTaxationWithoutVAT;
	
	If SettingsTable = Undefined Then
		SettingsTable = VATAccountingSettingsForOrganizations(MOrganizations, EndDate);
	EndIf;
	
	For Each SettingsString In SettingsTable Do
		
		If TypesOfTaxationWithoutVAT.Find(SettingsString.BasicTaxationVATSales) = Undefined Then
			CalculationParameters.Organizations_AdvancesReceived.Add(SettingsString.Organization);
		EndIf;
		
		If TypesOfTaxationWithoutVAT.Find(SettingsString.MainActivityVATProcurement) = Undefined 
			And CalculationParameters.FillOutCompanies_AdvancesIssued Then
			CalculationParameters.Organizations_AdvancesIssued.Add(SettingsString.Organization);
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion
