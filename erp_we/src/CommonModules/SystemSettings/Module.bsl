////////////////////////////////////////////////////////////////////////////////
// Server procedures and functions that control system settings
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Handler for subscribing to the event when recording Constants.
//
Procedure WhileSavingConstant(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	MetadataConstants = Source.ThisObject.Metadata(); //MetadataObject - 
	ConstantName		= MetadataConstants.Name;
	ConstantValue 	= Source.Value;
	
	// When the split mode is enabled, the cache of constant values is reset, 
	// because when setting dependent constants, the operation mode is checked to filter undivided constants.
	If ConstantName = "UseSeparationByDataAreas"
		Or ConstantName = "DoNotUseSeparationByDataAreas"
		Or ConstantName = "DoNotUseSeparationByDataAreasAndThisPA"
		Or ConstantName = "DoNotUseSeparationByDataAreasAndThisTM" Then
		RefreshReusableValues();
	EndIf;
	
	SynchronizeValuesOfSubordinateConstants(ConstantName, ConstantValue, Cancel);
	
EndProcedure

#EndRegion

#Region Internal

// Returns the name of the layout with exchange rules.
// You can redefine the name for localization purposes.
// 
// Returns:
// 	String - the name of the exchange rules.
Function NameOfExchangeRulesForUploadingLoadingInternationalAccountingModel() Export
	
	If Metadata.ScriptVariant = Metadata.ObjectProperties.ScriptVariant.Russian Then
		NameOfExchangeRules = "ExchangeRulesBasic_Ru";
	ElsIf Metadata.ScriptVariant = Metadata.ObjectProperties.ScriptVariant.English Then
		NameOfExchangeRules = "ExchangeRules__en";
	EndIf;
	SystemSettingsLocalization.AddNameOfRulesForExchangeAndUnloadingLoadingModelOfInternationalAccounting(NameOfExchangeRules);
	Return NameOfExchangeRules;
EndFunction

Function ValuesOfTechnologicalFunctionalOptionsWE() Export
	
	OptionValues = New Structure();
	OptionValues.Insert(Metadata.FunctionalOptions.EnterpriseManagement.Name, True);
	OptionValues.Insert(Metadata.FunctionalOptions.ComplexAutomation.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.TradeManagement.Name, False);

	OptionValues.Insert(Metadata.FunctionalOptions.CalculationOfPermanentAndTemporaryDifferencesIsKeptCommon.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.KeepSeparateNumberingOfTaxInvoicesIssuedForAdvances.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.KeepManagementAccountingOnSelfFinancingChartOfAccounts.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.KeepRecordsOfPaymentAccountingInPlaton.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.OutdatedClassifierUsageRNCPAndRNCEA.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.UseNonCurrentAssets2_2.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.UseFixedAssetDocumentsFinancialAccounting.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.UseVATDeclarationSection7Filling.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.UseImportedGoods.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.UseOnlinePayment.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.UseMaterialsInOperationContext.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.UsePayroll.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.UsePayrollTM.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.UseBranchOfficesWithSeparateBalanceSheets.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.UseElectronicDocumentExchangeWithCounterparties.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.UseSeparateFAAccountingByTaxation.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.UsePayrollExtended.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.UseLocal.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.UseConsolidatedDebtAdjustmentTransactionsForAcquisition.Name, True);
	OptionValues.Insert(Metadata.FunctionalOptions.UseConsolidatedDebtAdjustmentOperationsForSales.Name, True);
	OptionValues.Insert(Metadata.FunctionalOptions.CalculationOfPermanentAndTemporaryDifferencesIsKeptCommon.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.UseWaybill.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.UseNotificationsAboutControlledTransactions.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.UseProductionManagement.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.AccountingInFEACNUnitOfMeasurementIsUsed.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.LocalizationRFService.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.UTIIPayer.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.SupportOfBankingAndTreasuryStateContracts.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.RFPaymentsSupport.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.BuyGoodsSubjectToVATAtCustomer.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.SellGoodsSubjectToVATAtCustomer.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.LocalFAAccounting.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.InformationOnTargetFundTransactions.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.GenerateFinancialAccountingEntriesByLocalAccountingData.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.AccountForInventoryInERP2AndCAOperation.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.AccountForInventoryInOperationWE.Name, True);
	OptionValues.Insert(Metadata.FunctionalOptions.UseProductClassifiers.Name, False);
	
	Return OptionValues;
	
EndFunction

Function ValuesOfTechnologicalFunctionalOptionsOfUT() Export
	
	OptionValues = New Structure();
	OptionValues.Insert(Metadata.FunctionalOptions.EnterpriseManagement.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.ComplexAutomation.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.TradeManagement.Name, True);
	
	OptionValues.Insert(Metadata.FunctionalOptions.CalculationOfPermanentAndTemporaryDifferencesIsKeptCommon.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.UseBudgeting.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.UseNonCurrentAssets2_2.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.UseNonCurrentAssets2_4.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.UseVATDeclarationSection7Filling.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.UseMaterialsInOperationContext.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.UsePayrollTM.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.UseItemsBatchProduction.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.UseLocal.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.UseNotificationsAboutControlledTransactions.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.UseProductionManagement.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.UseProductionManagement2_2.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.AccountForInventoryInERP2AndCAOperation.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.AccountForInventoryInOperationWE.Name, False);
	
	Return OptionValues;
	
EndFunction

Function ValuesOfTechnologicalFunctionalOptionsOfSpacecraft() Export
	
	OptionValues = New Structure();
	OptionValues.Insert(Metadata.FunctionalOptions.EnterpriseManagement.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.ComplexAutomation.Name, True);
	OptionValues.Insert(Metadata.FunctionalOptions.TradeManagement.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.AccountForInventoryInERP2AndCAOperation.Name, True);
	OptionValues.Insert(Metadata.FunctionalOptions.UseBillOfMaterialsParameterization.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.UseBOMAssignmentParameters.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.StoreOperationsInBillsOfMaterials.Name, False);
	OptionValues.Insert(Metadata.FunctionalOptions.UseAlternativeMaterials.Name, False);
	
	Return OptionValues;
	
EndFunction

// Fills in the global search result.
// 
// Parameters:
//  SearchString                - String - search bar. 
//  GlobalSearchResults - GlobalSearchResult - contains search results.
//  AdditionalParameters     - Structure - advanced setting.
//
Procedure FillInResultOfGlobalSearchForSettingsByAccountingSections(SearchString, GlobalSearchResults, AdditionalParameters) Export

	SearchResults = ResultsOfGlobalSearchForSettingsByAccountingSections(SearchString);

	If SearchResults = Undefined Then
		Return;
	EndIf;

	For Each SearchResult In SearchResults Do
		GlobalSearchResults.Add(SearchResult.Value, SearchResult.Presentation, SearchResult.Picture,
			"SearchForSettingsByAccountingSections", SearchResult.ActionDetails);
	EndDo;

EndProcedure

#EndRegion

#Region Private

#Region ServiceConstants

Function CheckCorrespondenceOfValuesOfConstants() Export
	
	TableOfConstants  = SystemSettingsCached.GetTableOfConstantDependencies();
	ConstantValues = New Structure;
	
	DiscrepancyTable = New ValueTable;
	DiscrepancyTable.Columns.Add("NameOfParentConstant", New TypeDescription("String"));
	DiscrepancyTable.Columns.Add("NameOfSubordinateConstant",  New TypeDescription("String"));
	
	// We get the values of all constants, parent and subordinate
	For Each String In TableOfConstants Do
		If Not ConstantValues.Property(String.NameOfParentConstant) Then
			ConstantValues.Insert(String.NameOfParentConstant, Constants[String.NameOfParentConstant].Get());
		EndIf;
		If Not ConstantValues.Property(String.NameOfSubordinateConstant) Then
			ConstantValues.Insert(String.NameOfSubordinateConstant, Constants[String.NameOfSubordinateConstant].Get());
		EndIf;
	EndDo; 
	
	// Fill in the inconsistencies between the permissible and actual combinations of constant values
	For Each String In TableOfConstants Do
		If String.ValueOfParentConstant = ConstantValues[String.NameOfParentConstant]
		 And String.ValueOfSubordinateConstant <> ConstantValues[String.NameOfSubordinateConstant] Then
			MismatchLine = DiscrepancyTable.Add();
			FillPropertyValues(MismatchLine, String);
		EndIf;
	EndDo;
	
	DiscrepancyTable.Sort("NameOfParentConstant, NameOfSubordinateConstant");
	
	Return DiscrepancyTable;
	
EndFunction

// Parameters:
// 	TableOfConstants - See SystemSettings.InitializeTableOfConstantValues
// 	NameOfParentConstant - String -
// 	ValueOfParentConstant - Boolean - LongDesc
// 	NameOfSubordinateConstant - String - LongDesc
// 	ValueOfSubordinateConstant - Boolean - LongDesc
Procedure AddRowToConstantDependencyTable(TableOfConstants, NameOfParentConstant, ValueOfParentConstant, NameOfSubordinateConstant, ValueOfSubordinateConstant) Export 
	
	NewRow = TableOfConstants.Add();
	NewRow.NameOfParentConstant 	  = NameOfParentConstant;
	NewRow.ValueOfParentConstant = ValueOfParentConstant;
	NewRow.NameOfSubordinateConstant 	  = NameOfSubordinateConstant;
	NewRow.ValueOfSubordinateConstant  = ValueOfSubordinateConstant;
	
EndProcedure

Procedure AddStringOfInvertibleConstants(TableOfConstants, NameOfParentConstant, NameOfSubordinateConstant = "") Export
	
	If NameOfSubordinateConstant = "" Then
		NameOfSubordinateConstant = "Not" + NameOfParentConstant;
	EndIf;
	
	AddRowToConstantDependencyTable(TableOfConstants,
		NameOfParentConstant, False,   NameOfSubordinateConstant, True);
	AddRowToConstantDependencyTable(TableOfConstants,
		NameOfParentConstant, True, NameOfSubordinateConstant, False);
	
EndProcedure

Function GetStructureOfParentConstantsRecursively(StructureOfSubordinateConstants, TableOfConstants, ProcessedConstants) Export
	
	Result = New Structure;
	
	For Each DesiredConstant In StructureOfSubordinateConstants Do
		
		ParentConstants = TableOfConstants.FindRows(
			New Structure("NameOfSubordinateConstant", DesiredConstant.Key));
		
		For Each ParentLevelRow In ParentConstants Do
			
			If Result.Property(ParentLevelRow.NameOfParentConstant)
			 Or ProcessedConstants.Property(ParentLevelRow.NameOfParentConstant)
			 Or StructureOfSubordinateConstants.Property(ParentLevelRow.NameOfParentConstant) Then
				Continue;
			EndIf;
			
			Result.Insert(ParentLevelRow.NameOfParentConstant);
			ProcessedConstants.Insert(ParentLevelRow.NameOfParentConstant);
			
			ParentSParents = GetStructureOfParentConstantsRecursively(
				New Structure(ParentLevelRow.NameOfParentConstant),
				TableOfConstants,
				ProcessedConstants);
			
			For Each ParentOfParent In ParentSParents Do
				Result.Insert(ParentOfParent.Key);
			EndDo;
			
		EndDo;
		
	EndDo;
	
	Return Result;
	
EndFunction

Function GetStructureOfSubordinateConstantsRecursively(NameOfParentConstant, TableOfConstants, ProcessedConstants) Export
	
	Result = New Structure;
	
	SubordinateConstants = TableOfConstants.FindRows(
		New Structure("NameOfParentConstant", NameOfParentConstant));
	
	For Each SubordinateObjectRow In SubordinateConstants Do
		
		If Result.Property(SubordinateObjectRow.NameOfSubordinateConstant)
		 Or ProcessedConstants.Property(SubordinateObjectRow.NameOfSubordinateConstant) Then
			Continue;
		EndIf;
		
		Result.Insert(SubordinateObjectRow.NameOfSubordinateConstant);
		ProcessedConstants.Insert(SubordinateObjectRow.NameOfSubordinateConstant);
		
		SubordinatesOfSubordinates = GetStructureOfSubordinateConstantsRecursively(
			SubordinateObjectRow.NameOfSubordinateConstant,
			TableOfConstants,
			ProcessedConstants);
		
		For Each SubordinateOfSubordinate In SubordinatesOfSubordinates Do
			Result.Insert(SubordinateOfSubordinate.Key);
		EndDo;
		
	EndDo;
	
	Return Result;
	
EndFunction

// LongDesc
// 
// Returns:
// 	ValueTable - LongDesc:
// * NameOfParentConstant - String -
// * NameOfSubordinateConstant - String -
// * ValueOfParentConstant - Arbitrary - 
// * ValueOfSubordinateConstant - Arbitrary -
Function InitializeTableOfConstantValues() Export
	
	Result = New ValueTable;
	
	Result.Columns.Add("NameOfParentConstant", New TypeDescription("String"));
	Result.Columns.Add("NameOfSubordinateConstant",  New TypeDescription("String"));
	Result.Columns.Add("ValueOfParentConstant");
	Result.Columns.Add("ValueOfSubordinateConstant");
	
	Result.Indexes.Add("NameOfParentConstant");
	Result.Indexes.Add("NameOfSubordinateConstant");
	
	Return Result
	
EndFunction

Procedure SynchronizeValuesOfSubordinateConstants(ConstantName, ConstantValue, Cancel)
	
	If Cancel Then
		Return;
	EndIf;
	
	ConstantType	= TypeOf(ConstantValue);
	PrimitiveTypes = New TypeDescription("Number,String,Date,Boolean,Undefined");
	
	SetPrivilegedMode(True);
	
	// Synchronize "simple" dependent constants
	If PrimitiveTypes.ContainsType(ConstantType)
	 Or Common.RefTypeValue(ConstantValue) Then
		
		SubordinateConstants = SystemSettingsCached.GetValidValuesOfSubordinateConstants(ConstantName, ConstantValue);
		
		If ValueIsFilled(SubordinateConstants) Then
			
			For Each KeyAndValue In SubordinateConstants Do
				SetConstantValue(Constants[KeyAndValue.Key], KeyAndValue.Value);
			EndDo;
			
		EndIf;
		
	EndIf;
	
	// Synchronize "complex" dependent constants
	
	If ConstantName = "UseShipmentByRowsInSalesOrder"
	 Or ConstantName = "UseProduction" // orders of materials are included
	 Or ConstantName = "UseSubcontractOrders2_5" // orders to the processor are included
	 Or ConstantName = "UseRMManagement" // repair orders included
	 Or ConstantName = "UseProductionManagement" // production orders or material orders are included
	 Or ConstantName = "UseProductionManagement2_2" // production orders 2.1, 2.2 or materials order are included
	 Or ConstantName = "UseTollManufacturing2_5" // givers are included
	 Or ConstantName = "UseTransferOrders"
	 Or ConstantName = "UseInventoryConsumptionOrders"
	 Or ConstantName = "UseAssemblyDisassemblyOrders" Then
		
		ValueOfSubordinateConstant =
			Constants.UseShipmentByRowsInSalesOrder.Get()
			Or Constants.UseTransferOrders.Get()
			Or Constants.UseInventoryConsumptionOrders.Get()
			Or Constants.UseAssemblyDisassemblyOrders.Get();
		ValueOfSubordinateConstant = ValueOfSubordinateConstant
			Or Constants.UseSubcontractOrders2_5.Get()
			Or Constants.UseProduction.Get();
		ValueOfSubordinateConstant = ValueOfSubordinateConstant
			Or Constants.UseRMManagement.Get()
			Or Constants.UseProductionManagement.Get()
			Or Constants.UseProductionManagement2_2.Get()
			Or Constants.UseTollManufacturing2_5.Get();
		SetConstantValue(
			Constants.UseOrderSupplyWithAssignment, ValueOfSubordinateConstant And Constants.UseOrderSupplyWithAssignment.Get());
		
		SetConstantValue(Constants.UseOrdersAtLeastOneType, ValueOfSubordinateConstant);
		
	EndIf;
	If ConstantName = "UseTollManufacturing2_5"
		Or ConstantName = "UseMultipleCompanies" Then
		
		SetConstantValue(
			Constants.UseMultipleCompaniesAndSubcontracting25,
			Constants.UseTollManufacturing2_5.Get()
			And Constants.UseMultipleCompanies.Get());
		
	EndIf;
	
	If ConstantName = "UseProductionByThirdParty2_5"
		Or ConstantName = "UseMultipleCompanies" Then
		
		SetConstantValue(
			Constants.UseMultipleCompaniesAndProductionByThirdParty25,
			Constants.UseProductionByThirdParty2_5.Get()
			And Constants.UseMultipleCompanies.Get());
		
	EndIf;
	If ConstantName = "BaseVersion" And ConstantValue
		And Constants.UseAdvancedDemandFulfillment.Get() Then
	
		SetConstantValue(Constants.UseAdvancedDemandFulfillment, False);
	ElsIf ConstantName = "UseTollManufacturing2_5"
		Or False Then
		
		SupplyServer.UseControlOfMovementOfSeparateGoodsToCalculateAndWrite();
		SupplyServer.UseNonOrderingAssignmentsToCalculateAndWrite();
		

	ElsIf ConstantName = "UseOrderSupplyWithAssignment" Then
		
		SupplyServer.UseNonOrderingAssignmentsToCalculateAndWrite();
		
	ElsIf ConstantName = "UseAssignmentsWithoutOrder" Then
		
		SupplyServer.DoNotUseNonOrderAssignmentsComputeAndWriteByInversion();
		
	ElsIf ConstantName = "AllowAssignmentOfGoodsBeyondDemand" Then
		
		SupplyServer.UseControlOfMovementOfSeparateGoodsToCalculateAndWrite();
		
	ElsIf ConstantName = "UseGoodsTransfer" Then
		
		SupplyServer.UseControlOfMovementOfSeparateGoodsToCalculateAndWrite();
		
	ElsIf ConstantName = "UseProductionManagement2_2" Then
		
		SupplyServer.UseControlOfMovementOfSeparateGoodsToCalculateAndWrite();
			
	EndIf;
	
	DataProcessors.DemandFulfillment.SynchronizeValuesOfSubordinateConstants(ConstantName, ConstantValue, Cancel);
	Planning.SynchronizeValuesOfSubordinateConstants(ConstantName, ConstantValue, Cancel);
	
	If ConstantName = "UsePaymentByCards"
	 Or ConstantName = "UsePeripherals" Then
		
		If ConstantName = "UsePaymentByCards" Then
			ValueOfSubordinateConstant = ConstantValue And Constants.UsePeripherals.Get();
		Else
			ValueOfSubordinateConstant = ConstantValue And Constants.UsePaymentByCards.Get();
		EndIf;
		
		SetConstantValue(
			Constants.UsePeripheralsAndCardPayments, ValueOfSubordinateConstant);
	 	
	ElsIf ConstantName = "UseMultipleCashAccounts"
	 	  Or ConstantName = "UseMultipleBankAccounts" Then
		
		If ConstantName = "UseMultipleCashAccounts" Then
			ValueOfSubordinateConstant = ConstantValue Or Constants.UseMultipleBankAccounts.Get();
		Else
			ValueOfSubordinateConstant = ConstantValue Or Constants.UseMultipleCashAccounts.Get();
		EndIf;
		
		SetConstantValue(
			Constants.UseSeveralBankAccountsOrCashAccounts, ValueOfSubordinateConstant);
			
	ElsIf ConstantName = "UseMultipleCurrencies" Then
		
		If Not ConstantValue Then
			
			ValueOfSubordinateConstant = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting();
			
			SetConstantValue(
				Constants.ManagementAccountingCurrency, 	  ValueOfSubordinateConstant);
			SetConstantValue(
				Constants.DefaultBaseCurrency, ValueOfSubordinateConstant);
		EndIf;
		
	ElsIf ConstantName = "UseSalesOrders" 
		Or ConstantName = "UseRequestsForReturnOfGoodsFromCustomers" Then
		
		If Not Constants.UseSalesOrders.Get() 
			And Not Constants.UseRequestsForReturnOfGoodsFromCustomers.Get() Then
		
			SetConstantValue(
				Constants.UseAdvancedFeaturesOfSalesOrder,   False);
				
			EndIf;
			
	ElsIf ConstantName = "UseAdvancedFeaturesOfSalesOrder" Then
		
		If Not Constants.UseAdvancedFeaturesOfSalesOrder.Get() Then
		
			SetConstantValue(
				Constants.DoNotCloseSalesOrdersWithoutCompletePayment,   False);
			SetConstantValue(
				Constants.DoNotCloseSalesOrdersWithoutCompleteShipment, False);
			
		EndIf;
	ElsIf ConstantName = "UseApprovalOfRequestsForReturnOfGoodsFromCustomers"
	 Or ConstantName = "UseSalesOrderApproval"
	 Or ConstantName = "UseApprovalOfTermsOfSales" Then
		
		NameOfSubordinateConstant 	 = SubordinateMatchingConstant(ConstantName);
		ValueOfSubordinateConstant = ConstantValue;
		
		SetConstantValue(
			Constants[NameOfSubordinateConstant], ValueOfSubordinateConstant);
			
	ElsIf ConstantName = "UseSalesOpportunitiesToCustomer" Then
		
		SetConstantValue(
			Constants.UseOpportunityManagement, ConstantValue And Constants.UseOpportunityManagement.Get());
		SetConstantValue(
			Constants.UsePrimaryDemand, 	  ConstantValue And Constants.UsePrimaryDemand.Get());
		
	ElsIf ConstantName = "UseOpportunityManagement" Then
		
	SetConstantValue(
		Constants.UseSalesOrders, 	  			   ConstantValue Or Constants.UseSalesOrders.Get());
		
	ElsIf ConstantName = "ItemizeJobsForSalesRepresentatives"
	 Or ConstantName = "UseJobsToSalesRepresentatives" Then
		
		If ConstantName = "ItemizeJobsForSalesRepresentatives" Then
			ValueOfSubordinateConstant = Not ConstantValue
				And Constants.UseJobsToSalesRepresentatives.Get() = Enums.UseJobsToSalesRepresentatives.UsedForManagementBySalesRepresentatives;
		Else
			ValueOfSubordinateConstant = Not Constants.ItemizeJobsForSalesRepresentatives.Get()
				And ConstantValue = Enums.UseJobsToSalesRepresentatives.UsedForManagementBySalesRepresentatives;
		EndIf;
		
		SetConstantValue(
			Constants.NotItemizeJobsForSalesRepresentatives, ValueOfSubordinateConstant);
				
	ElsIf ConstantName = "UseDiscountAdjustmentsInSales"
		Or ConstantName = "UseDiscountsMarkupsInSales" Then
		
		If Not Constants.UseDiscountAdjustmentsInSales.Get()
			And Not Constants.UseDiscountsMarkupsInSales.Get() Then
		
			SetConstantValue(Constants.SelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments, False);
			SetConstantValue(Constants.DisplayDiscountsInPrintFormsOfSalesDocuments, Enums.OptionsOfDiscountsDisplayingInPrintForms.NotDisplayDiscounts);
		EndIf;
	ElsIf ConstantName = "UseCustomerCommercialInvoices" Then
		
		ValueOfSubordinateConstant = ?(Not ConstantValue, Constants.SelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments.Get(), False);
		
		SetConstantValue(Constants.DoNotUseCommercialInvoicesAndDoNotSelectDiscountDisplayOption, ?(Not ConstantValue, Not ValueOfSubordinateConstant, ValueOfSubordinateConstant));
		SetConstantValue(Constants.DoNotUseCommercialInvoicesAndSelectDiscountDisplayOption, ValueOfSubordinateConstant);
	ElsIf Find(ConstantName, "UseProductionManagement") > 0
		Or ConstantName = "UseProductionByThirdParty2_5" Then
		
		If ConstantName = "UseProductionManagement" Then
			ProductionIsUsed21 = ConstantValue;
			ProductionIsUsed22 = Constants.UseProductionManagement2_2.Get();
		ElsIf ConstantName = "UseProductionManagement2_2" Then
			ProductionIsUsed21 = Constants.UseProductionManagement.Get();
			ProductionIsUsed22 = ConstantValue;
		Else
			ProductionIsUsed21 = Constants.UseProductionManagement.Get();
			ProductionIsUsed22 = Constants.UseProductionManagement2_2.Get();
		EndIf;
		
		// subordinate constants
		If Not ProductionIsUsed22 Then
			SetConstantValue(Constants.ProductionManagementMethod, Enums.ProductionManagementMethod.WithoutCalculationOfProductionSchedule);
		EndIf;
		
		If (ConstantName = "UseProductionManagement" And ConstantValue)
			Or ConstantName = "UseProductionManagement2_2" Then
				ProductionServer.SetOptionsForWorkingWithProductionOperations(
					ProductionIsUsed21, ProductionIsUsed22);
		EndIf;
		SetConstantValue(
			Constants.EnabledOnlyProductionManagement22,
			Not ProductionIsUsed21
			And (ProductionIsUsed22
				Or Constants.UseProductionByThirdParty2_5.Get()));
	EndIf;
	
	If ConstantName = "UseShipmentByRowsInSalesOrder"
	 Or ConstantName = "UseSubcontractOrders2_5"
	 Or ConstantName = "UseRMManagement"
	 Or ConstantName = "UseProduction"
	 Or ConstantName = "UseTransferOrders"
	 Or ConstantName = "UseInventoryConsumptionOrders"
	 Or ConstantName = "UseAssemblyDisassemblyOrders" Then
		
		ValueOfSubordinateConstant =
			Constants.UseShipmentByRowsInSalesOrder.Get()
			Or Constants.UseTransferOrders.Get()
			Or Constants.UseInventoryConsumptionOrders.Get()
			Or Constants.UseAssemblyDisassemblyOrders.Get();
		ValueOfSubordinateConstant = ValueOfSubordinateConstant
			Or Constants.UseSubcontractOrders2_5.Get();
		ValueOfSubordinateConstant = ValueOfSubordinateConstant
			Or Constants.UseRMManagement.Get()
			Or Constants.UseProduction.Get();
		SetConstantValue(
			Constants.UseOrderSupplyWithAssignment,
			ValueOfSubordinateConstant
			And Constants.UseOrderSupplyWithAssignment.Get());
			
	EndIf;
	
	If ConstantName = "UseProduction"
		Or ConstantName = "UseProductionManagement" 
		Or ConstantName = "UseProductionManagement2_2"
		Or ConstantName = "UseSets" Then
		
		Production21 = Constants.UseProductionManagement.Get();
		Production22 = Constants.UseProductionManagement2_2.Get();
		
		
		If Not Production21 And Not Production22 Then
			SetConstantValue(Constants.UseBOMAssignmentParameters, False);
		EndIf;
		If Production22 And Constants.UseSets.Get() Then
			ValueOfSubordinateConstant = Enums.SourcesOfCompositionOfSetsInProduction.KitConfigurations;
			ValueOfSubordinateConstant = Constants.SourceOfCompositionOfSetsInProduction.Get();
		Else
			ValueOfSubordinateConstant = Enums.SourcesOfCompositionOfSetsInProduction.DontUse;
		EndIf;
		SetConstantValue(Constants.SourceOfCompositionOfSetsInProduction, ValueOfSubordinateConstant);
		
	EndIf;
	If ConstantName = "UseProductionByThirdParty2_5"
		Or ConstantName = "UseSubcontractOrders2_5"
		Or ConstantName = "UseProduction"
		Or ConstantName = "UseProductionManagement2_2" Then
		
		Production   = Constants.UseProduction.Get();
		Production22 = Constants.UseProductionManagement2_2.Get();
		
		If Constants.UseProductionByThirdParty2_5.Get()
			And Not Constants.UseSubcontractOrders2_5.Get()
			And (Production
				Or Production22) Then
			SetConstantValue(Constants.UseSubcontractOrders2_5, True);
		EndIf;
		
		If Constants.UseSubcontractOrders2_5.Get()
			And Not Constants.UseTollingOrderStatuses2_5.Get()
			And (Production
				Or Production22) Then
			SetConstantValue(Constants.UseTollingOrderStatuses2_5, True);
		EndIf;
		
	EndIf;
	
	
	If ConstantName = "UseAlternativeMaterials" Then
		
		If ConstantValue = False Then
			SetConstantValue(Constants.UseApprovalOfEngineeringChangeOrders, False);
		EndIf;
		
	EndIf;
	
	If ConstantName = Metadata.Constants.UseGoodsQuality.Name
		Or ConstantName = Metadata.Constants.UseProductionByThirdParty2_5.Name
		Or ConstantName = Metadata.Constants.UseTransferToCustodyWithRightOfSale.Name Then
		
		UseGoodsQuality = ConstantValue;
		UseProductionByThirdParty2_5 = ConstantValue;
		UseTransferToCustodyWithRightOfSale = ConstantValue;
		
		If Not ConstantName = Metadata.Constants.UseGoodsQuality.Name Then
			UseGoodsQuality = Constants.UseGoodsQuality.Get();
		EndIf;
		If Not ConstantName = Metadata.Constants.UseProductionByThirdParty2_5.Name Then
			UseProductionByThirdParty2_5 = Constants.UseProductionByThirdParty2_5.Get();
		EndIf;
		If Not ConstantName = Metadata.Constants.UseTransferToCustodyWithRightOfSale.Name Then
			UseTransferToCustodyWithRightOfSale =
				Constants.UseTransferToCustodyWithRightOfSale.Get();
		EndIf;
	
		SetConstantValue(
			Constants.UseCustodianGoodsDamage,
			UseGoodsQuality
			And (UseTransferToCustodyWithRightOfSale
				Or UseProductionByThirdParty2_5
				Or False));
		
	EndIf;
	
	If ConstantName = Metadata.Constants.UseGoodsQuality.Name
		Or ConstantName = Metadata.Constants.UseProductionByThirdParty2_5.Name
		Or ConstantName = Metadata.Constants.UseTransferToCustodyWithRightOfSale.Name Then
		
		UseGoodsQuality = ConstantValue;
		UseProductionByThirdParty2_5 = ConstantValue;
		UseTransferToCustodyWithRightOfSale = ConstantValue;
		
		If Not ConstantName = Metadata.Constants.UseGoodsQuality.Name Then
			UseGoodsQuality = Constants.UseGoodsQuality.Get();
		EndIf;
		If Not ConstantName = Metadata.Constants.UseProductionByThirdParty2_5.Name Then
			UseProductionByThirdParty2_5 = Constants.UseProductionByThirdParty2_5.Get();
		EndIf;
		If Not ConstantName = Metadata.Constants.UseTransferToCustodyWithRightOfSale.Name Then
			UseTransferToCustodyWithRightOfSale =
				Constants.UseTransferToCustodyWithRightOfSale.Get();
		EndIf;
	
		SetConstantValue(
			Constants.UseCustodianGoodsDamage,
			UseGoodsQuality
			And (UseTransferToCustodyWithRightOfSale
				Or UseProductionByThirdParty2_5
				Or False));
		
	EndIf;
	
	If ConstantName = Metadata.Constants.UseImports.Name 
		Or ConstantName = Metadata.Constants.UseGoodsInTransitFromVendors.Name Then
		
		UseImports = Constants.UseImports.Get();
		UseGoodsInTransitFromVendors = Constants.UseGoodsInTransitFromVendors.Get();
		
		SetConstantValue(Constants.UseImportedPurchasesOfGoodsInTransit, 
			UseImports And UseGoodsInTransitFromVendors);
		
	EndIf;
	
	If ConstantName = "UseSalesPlans"
		Or ConstantName = "UsePurchasePlanning"
		Or ConstantName = "UseAssemblyDisassemblyPlanning"
		Or ConstantName = "UsePlanningOfInventoryConsumption" Then
		
		SalesPlans =                Constants.UseSalesPlans.Get();
		SalesPlansByCategories =    Constants.UseSalesPlansByCategories.Get();
		PurchasePlans =               Constants.UsePurchasePlanning.Get();
		AssemblyDisassemblyPlans =        Constants.UseAssemblyDisassemblyPlanning.Get();
		InventoryConsumptionPlans = Constants.UsePlanningOfInventoryConsumption.Get();
		
		If Constants.TradeManagement.Get()
			And (SalesPlans
			Or SalesPlansByCategories
			Or PurchasePlans
			Or AssemblyDisassemblyPlans
			Or InventoryConsumptionPlans) Then
			
			SetConstantValue(Constants.UsePlansEquilibriumTM, True);
			
		Else
			
			SetConstantValue(Constants.UsePlansEquilibriumTM, False);
			
		EndIf;
		
	EndIf;
	
	If ConstantName = "UsePriceManagementSystem25" Then

		SetConstantValue(Constants.UseProductsVariantsForPricing, 
									ConstantValue And Constants.UseItemVariants.Get());
		SetConstantValue(Constants.UseItemsBatchForPricing, 	
									ConstantValue And Constants.UseItemsBatch.Get());
		SetConstantValue(Constants.UseItemPackagesForPricing, 
									ConstantValue And Constants.UseItemPackages.Get());
		
		If Not Constants.UsePriceManagementSystem25.Get() Then
			SetConstantValue(Constants.DateOfMigrationToPriceManagementSystem25, Date(1,1,1));
		EndIf;
			
	ElsIf ConstantName = "UseItemVariants" Then
		
		ValueOfSubordinateConstant = ConstantValue And Constants.UsePriceManagementSystem25.Get();
		SetConstantValue(Constants.UseProductsVariantsForPricing, ValueOfSubordinateConstant);
		
	ElsIf ConstantName = "UseItemsBatch" Then
		
		ValueOfSubordinateConstant = ConstantValue And Constants.UsePriceManagementSystem25.Get();
		SetConstantValue(Constants.UseItemsBatchForPricing, ValueOfSubordinateConstant);
		
	ElsIf ConstantName = "UseItemPackages" Then
		
		ValueOfSubordinateConstant = ConstantValue And Constants.UsePriceManagementSystem25.Get();
		SetConstantValue(Constants.UseItemPackagesForPricing, ValueOfSubordinateConstant);
		
	EndIf;
	
	If ConstantName = "UseTermsOfSales" Then
		
		CustomerAgreement = Constants.ToUseTermsOfSales.Get();
		OnlyConsignmentSales25 = Constants.OnlyConsignmentSales25.Get();
		ContractsWithCustomers_ = Constants.UseCustomerContracts.Get();
		
		If Not OnlyConsignmentSales25 And Not ContractsWithCustomers_ And Not CustomerAgreement Then
			SetConstantValue(Constants.UseSalesCommission, False);
		EndIf;
	EndIf;
	
	If ConstantName = Metadata.Constants.UseSalesCommission.Name Then
		
		If ConstantValue Then
			Fee20 = ConsignmentSalesServer.ConsignmentSaleIsUsed20();
			SetConstantValue(Constants.SelectConsignmentSalesVersion, Fee20);
			SetConstantValue(Constants.OnlyConsignmentSales25, Not Fee20);
			SetConstantValue(Constants.ConsignmentSaleIsUsed20, Fee20);
		Else
			SetConstantValue(Constants.SelectConsignmentSalesVersion, False);
			SetConstantValue(Constants.OnlyConsignmentSales25, False);
			SetConstantValue(Constants.ConsignmentSaleIsUsed20, False);
		EndIf;
		
	EndIf;
	
	If ConstantName = Metadata.Constants.ConsignmentSaleIsUsed20.Name Then
		
		TradeManagement = Constants.TradeManagement.Get();
		SetConstantValue(Constants.ConsignmentSaleIsUsedERPAR20, ConstantValue And Not TradeManagement);
		SetConstantValue(Constants.ConsignmentSaleIsUsedTM11, ConstantValue And TradeManagement);
		
	EndIf;
		
	If ConstantName = Metadata.Constants.UseMultiCountryAccounting.Name Then
		SetConstantValue(Constants.NotUseMultiCountryAccounting, Not ConstantValue);
		If ConstantValue Then
			SetConstantValue(Constants.LocalAccountingCurrency, Undefined);
		EndIf;
	EndIf;
			
	If ConstantName = Metadata.Constants.LocalAccountingCurrency.Name
		And Not Constants.UseMultiCountryAccounting.Get() Then
			Constants.DefaultBaseCurrency.Set(ConstantValue);
	EndIf;
	
	If ConstantName = Metadata.Constants.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving.Name Then
		NewValueForUsingAcceptableDeviation = ?(Constants.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving.Get() > 0, True, False);
		SetConstantValue(Constants.UseAllowableDeviationOfMeasuringGoodsShipmentReceiving, NewValueForUsingAcceptableDeviation);
	EndIf;
	
	If ConstantName = "UseCustomerInvoiceIntercompany"
		Or ConstantName = "UseInternalSubcontracting"
		Or False Then
		
		TransfersOfGoods       = Constants.UseCustomerInvoiceIntercompany.Get();
		InternalSubcontracting = Constants.UseInternalSubcontracting.Get();
		If Not TransfersOfGoods
			And Not InternalSubcontracting
			And True Then
			Constants.UseIntercompanyContracts.Set(False);
		EndIf;
		
	EndIf;
	
	If ConstantName = "UseCustomerInvoiceIntercompany"
		Or ConstantName = "UseInternalSubcontracting"
		Or ConstantName = "NewOnlineARAPAccounting"
		Or ConstantName = "NotNewOnlineARAPAccounting" Then
		
		TransfersOfGoods       = Constants.UseCustomerInvoiceIntercompany.Get();
		NewSettlements    = Constants.NewOnlineARAPAccounting.Get();
		NotNewSettlements  = Constants.NotNewOnlineARAPAccounting.Get();
		InternalSubcontracting = Constants.UseInternalSubcontracting.Get();
		If NewSettlements Then
			Constants.UseReportSettlementsBetweenCompanies.Set(False);
		EndIf;
		
		If Not NewSettlements Then
			Constants.UseReportStatementOfSettlementsBetweenCompanies.Set(False);
		EndIf;
		
		If Not TransfersOfGoods
			And Not InternalSubcontracting
			And True Then
			Constants.UseReportSettlementsBetweenCompanies.Set(False);
			Constants.UseReportStatementOfSettlementsBetweenCompanies.Set(False);
		EndIf;
		
		If Common.SeparatedDataUsageAvailable() Then
			
			If Not NewSettlements Then
				Constants.UseReportSettlementsBetweenCompanies.Set(
					TransfersOfGoods
					Or InternalSubcontracting
					Or False);
			EndIf;
			
			If NewSettlements Then
				Constants.UseReportStatementOfSettlementsBetweenCompanies.Set(
					TransfersOfGoods
					Or InternalSubcontracting
					Or False);
			EndIf;
			
			If TransfersOfGoods
				Or InternalSubcontracting
				Or False Then
				Constants.UseReportSettlementsBetweenCompanies.Set(NotNewSettlements);
				Constants.UseReportStatementOfSettlementsBetweenCompanies.Set(NewSettlements);
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If ConstantName = "UseCustomerContracts" Then
		
		If ConstantValue
			And Constants.UseShipmentWithDeferredTransferOfTitle.Get()
			And Not Constants.UseShipmentWithDeferredTransferOfTitle2_5.Get() Then
			Constants.UseShipmentWithDeferredTransferOfTitle2_5.Set(True);
		EndIf;
		
	EndIf;
	
	If ConstantName = "UseShipmentWithDeferredTransferOfTitle" Then
		
		If ConstantValue Then
			
			ThereAreShipmentDocumentsWithoutTransferOfOwnership2_0 =
				Constants.UseShipmentWithDeferredTransferOfTitle.ThereAreShipmentDocumentsWithoutTransferOfOwnership2_0();
			
			UseCustomerContracts = Constants.UseCustomerContracts.Get();
			UseStatusesOfGoodsServicesSales = Constants.UseStatusesOfGoodsServicesSales.Get();
			
			If ThereAreShipmentDocumentsWithoutTransferOfOwnership2_0 And UseStatusesOfGoodsServicesSales Then
				SetConstantValue(Constants.UseShipmentWithDeferredTransferOfTitle2_0, True);
			EndIf;
			
			If UseCustomerContracts Then
				SetConstantValue(Constants.UseShipmentWithDeferredTransferOfTitle2_5, True);
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If ConstantName = "UseStatusesOfGoodsServicesSales" Then
		
		If Not ConstantValue Then
			
			UseShippingWithoutSWTO2_5 = Constants.UseShipmentWithDeferredTransferOfTitle2_5.Get();
			
			If Not UseShippingWithoutSWTO2_5 Then
				SetConstantValue(Constants.UseShipmentWithDeferredTransferOfTitle, False);
			EndIf;
			
		EndIf;
		
	EndIf;
	If ConstantName = Metadata.Constants.UseProduction.Name
	 Or ConstantName = Metadata.Constants.UseSeveralWarehouses.Name Then
	 	
	 	UseProduction = Constants.UseProduction.Get();
		UseSeveralWarehouses = Constants.UseSeveralWarehouses.Get();
		SetConstantValue(Constants.UseMaterialOrdersForShopFloorStockroom, UseProduction And UseSeveralWarehouses);
	 	
	EndIf;
	SystemSettingsLocalization.SynchronizeValuesOfSubordinateConstants(ConstantName, ConstantValue, Cancel);
	
EndProcedure

Procedure SetConstantValue(ManagerOfConstant, ConstantValue) Export
	
	If ManagerOfConstant.Get() <> ConstantValue Then
		ManagerOfConstant.Set(ConstantValue);
	EndIf;
	
EndProcedure

Function SubordinateMatchingConstant(ConstantName)
	
	MatchingConstants = New Map();
	
	MatchingConstants.Insert("UseApprovalOfRequestsForReturnOfGoodsFromCustomers",
		"UseInternalApprovalOfRequestsForReturnOfGoodsFromCustomers");
	MatchingConstants.Insert("UseSalesOrderApproval",
		"UseInternalSalesOrderApproval");
	MatchingConstants.Insert("UseApprovalOfTermsOfSales",
		"UseInternalApprovalOfTermsOfSales");
		
	Return MatchingConstants.Get(ConstantName);
EndFunction

#EndRegion

Function ResultsOfGlobalSearchForSettingsByAccountingSections(SearchString)
	
	SearchResults = New Array;
	
	DescriptionOfActiveParameters = SystemSettingsCached.DescriptionOfDefaultWarehouseParameters();
	If StrFindAndHighlightByAppearance(DescriptionOfActiveParameters, SearchString) <> Undefined Then
		ResultsOfGlobalSearchForSettingsByAccountingSectionsWarehouses(SearchString, SearchResults);
	EndIf;
	
	DescriptionOfActiveParameters = SystemSettingsCached.DescriptionOfDefaultDivisionParameters();
	If StrFindAndHighlightByAppearance(DescriptionOfActiveParameters, SearchString) <> Undefined Then
		ResultsOfGlobalSearchForSettingsByAccountingSectionsEnterpriseStructure(SearchString, SearchResults);
	EndIf;
	
	Return SearchResults;
	
EndFunction

// Results of a global search for settings by accounting sections warehouses.
// 
// Parameters:
//  SearchString - String
//  SearchResults - Array of GlobalSearchResult 
Procedure ResultsOfGlobalSearchForSettingsByAccountingSectionsWarehouses(SearchString, SearchResults)
	
	NoteText = StyleColors.NoteText;
	ActiveParameters = SystemSettingsCached.ValidParametersForWarehouses();
	For Each CurrentParametersForWarehouse In ActiveParameters Do
		Warehouse = CurrentParametersForWarehouse.Ref;
		LongDesc = Catalogs.Warehouses.DescriptionOfActiveParameters(Warehouse, , 
			CurrentParametersForWarehouse);
		LongDesc = New FormattedString(LongDesc, , NoteText);
		FoundRow = StrFindAndHighlightByAppearance(LongDesc, SearchString);
		If FoundRow <> Undefined Then
			SearchResult = SystemSettingsClientServer.NewGlobalSearchResult();
			SearchResult.Value = Warehouse;
			
			RowsArray = New Array;
			RowsArray.Add(CurrentParametersForWarehouse.Presentation);
			RowsArray.Add(Chars.LF);
			RowsArray.Add(FoundRow);
			
			SearchResult.Presentation = New FormattedString(RowsArray);
			SearchResult.Picture = PictureLib.Catalog;
			
			SearchResults.Add(SearchResult);
		EndIf;
	EndDo;
	
EndProcedure

Procedure ResultsOfGlobalSearchForSettingsByAccountingSectionsEnterpriseStructure(SearchString, SearchResults)
	
	NoteText = StyleColors.NoteText;
	ActiveParameters = SystemSettingsCached.ValidParametersByDivision();
	For Each CurrentParametersByDivision In ActiveParameters Do
		Department = CurrentParametersByDivision.Ref;
		LongDesc = Catalogs.BusinessStructure.DescriptionOfActiveParameters(Department, , 
			CurrentParametersByDivision);
		LongDesc = New FormattedString(LongDesc, , NoteText);
		FoundRow = StrFindAndHighlightByAppearance(LongDesc, SearchString);
		If FoundRow <> Undefined Then
			SearchResult = SystemSettingsClientServer.NewGlobalSearchResult();
			SearchResult.Value = Department;
			
			RowsArray = New Array;
			RowsArray.Add(CurrentParametersByDivision.Presentation);
			RowsArray.Add(Chars.LF);
			RowsArray.Add(FoundRow);
			
			SearchResult.Presentation = New FormattedString(RowsArray);
			SearchResult.Picture = PictureLib.Catalog;
			
			SearchResults.Add(SearchResult);
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion