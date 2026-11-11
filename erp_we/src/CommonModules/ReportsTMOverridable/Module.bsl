////////////////////////////////////////////////////////////////////////////////
// Report Options - Report Form (redefined)
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// This procedure should describe additional dependencies
//   of configuration metadata objects that will be used to link report settings.
//
// Parameters:
//   MetadataObjectsLinks - ValueTable:
//       * SubordinateAttribute - String - name of the detail of the subordinate metadata object.
//       * SubordinatedType      - Type    - type of the subordinate metadata object.
//       * MasterType          - Type    - type of the leading metadata object.
//
Procedure AddMetadataObjectsConnections(MetadataObjectsLinks) Export
	
EndProcedure

// Called in the report form before displaying the settings.
//
// Parameters:
//  Form - ClientApplicationForm
//        - ManagedFormExtensionForReports
//        - Undefined - report form.
//  SettingProperties - Structure - description of the report settings that will be displayed in the report form, where:
//      * DCField - DataCompositionField - output setting.
//      * TypeDescription - TypeDescription - type of output setting.
//      * ValuesForSelection - ValueList - specify the objects that will be offered to the user in the selection list.
//                            Complements the list of objects that the user has already selected earlier.
//                            However, you should not assign a new list of values to this parameter.
//      * SelectionValuesQuery - Query - to specify the query to select objects that you want to Supplement 
//                               Values for the selection. The first column (with index 0) should select the object
//                               to add to the selection Value.Value.
//                               To disable AutoFill in the query property, select Values.The text should be written
//                               as an empty string.
//      * RestrictSelectionBySpecifiedValues - Boolean - specify True to restrict the user's selection
//                                                to the values specified in the selection Value (its final state).
//      * Type - String
//
Procedure OnDefineSelectionParameters(Form, SettingProperties) Export
	// Autofill parameters and selections for all reports
	If GetFunctionalOption("UseMultipleCurrencies") 
		And SettingProperties.TypeDescription.Types().Count() = 1
		And SettingProperties.TypeDescription.ContainsType(Type("CatalogRef.Currencies")) Then
		SettingProperties.SelectionValuesQuery = RequestForCurrencySelection();
		SettingProperties.RestrictSelectionBySpecifiedValues = True;
	EndIf;
	If SettingProperties.TypeDescription.ContainsType(Type("CatalogRef.Companies")) 
		And SettingProperties.TypeDescription.Types().Count() = 1 Then
		QueryText = 
		"SELECT ALLOWED
		|	Companies.Ref 
		|FROM
		|	Catalog.Companies AS Companies
		|WHERE
		|	&ManagementCompany";
		If GetFunctionalOption("UseManagementCompany") Then 
			ManagementCompany = "TRUE";
		Else
			ManagementCompany = "NOT Companies.Ref = VALUE(Catalog.Companies.ManagementCompany)";
		EndIf;
		QueryText = StrReplace(QueryText, "&ManagementCompany", ManagementCompany);
		SettingProperties.SelectionValuesQuery.Text = QueryText;
		SettingProperties.RestrictSelectionBySpecifiedValues = False;
	EndIf;
	If SettingProperties.TypeDescription.ContainsType(Type("EnumRef.BusinessTransactions")) Then
		SettingProperties.SelectionValuesQuery.Text = "";
		SettingProperties.RestrictSelectionBySpecifiedValues = False;
	EndIf;
	If Constants.BaseVersion.Get()
		And SettingProperties.TypeDescription.ContainsType(Type("CatalogRef.BusinessTransactionsSettings")) Then
		SettingProperties.SelectionValuesQuery.Text = "
		|SELECT
		|	BusinessTransactionsSettings.Ref
		|FROM
		|	Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
		|WHERE
		|	BusinessTransactionsSettings.Ref IN(
		|		VALUE(Catalog.BusinessTransactionsSettings.PurchaseFromSupplier),
		|		VALUE(Catalog.BusinessTransactionsSettings.PurchaseViaAdvanceHolder),
		|		VALUE(Catalog.BusinessTransactionsSettings.ConsignmentProcurement),
		|		VALUE(Catalog.BusinessTransactionsSettings.ReturnOfGoodsToVendor),
		|		VALUE(Catalog.BusinessTransactionsSettings.ReturnOfGoodsToConsignor),
		|		VALUE(Catalog.BusinessTransactionsSettings.SaleToCustomer),
		|		VALUE(Catalog.BusinessTransactionsSettings.TransferToCommissionAgent),
		|		VALUE(Catalog.BusinessTransactionsSettings.ReturnFromCommissionAgent),
		|		VALUE(Catalog.BusinessTransactionsSettings.ReturnOfGoodsFromCustomer),
		|		VALUE(Catalog.BusinessTransactionsSettings.ReturnFromRetailCustomer),
		|		VALUE(Catalog.BusinessTransactionsSettings.TransferOfGoodsBetweenBranchOffices),
		|		VALUE(Catalog.BusinessTransactionsSettings.InventoryTransfer),
		|		VALUE(Catalog.BusinessTransactionsSettings.GoodsConsumptionOnDemand),
		|		VALUE(Catalog.BusinessTransactionsSettings.InventoryConsumptionReverseTransaction),
		|		VALUE(Catalog.BusinessTransactionsSettings.CashIssueToCashRegister),
		|		VALUE(Catalog.BusinessTransactionsSettings.IssueCashToAdvanceHolder),
		|		VALUE(Catalog.BusinessTransactionsSettings.CashCollectionToBank),
		|		VALUE(Catalog.BusinessTransactionsSettings.CashCollectionFromBank),
		|		VALUE(Catalog.BusinessTransactionsSettings.CurrencyConversion),
		|		VALUE(Catalog.BusinessTransactionsSettings.PaymentToVendor),
		|		VALUE(Catalog.BusinessTransactionsSettings.TransferCashToAnotherAccount),
		|		VALUE(Catalog.BusinessTransactionsSettings.TransferOfTaxesAndContributions),
		|		VALUE(Catalog.BusinessTransactionsSettings.CashReceiptFromBank),
		|		VALUE(Catalog.BusinessTransactionsSettings.CashReceiptFromAnotherCashAccount),
		|		VALUE(Catalog.BusinessTransactionsSettings.CashReceiptFromOtherCompany),
		|		VALUE(Catalog.BusinessTransactionsSettings.CashReceiptFromCashRegister),
		|		VALUE(Catalog.BusinessTransactionsSettings.CashReceiptFromCustomer),
		|		VALUE(Catalog.BusinessTransactionsSettings.OtherCashReceipt),
		|		VALUE(Catalog.BusinessTransactionsSettings.CashDepositToBankAccount)
		|)";
		SettingProperties.RestrictSelectionBySpecifiedValues = True;
	EndIf;
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   Cancel - Boolean - indicates that the form was not created.
//   StandardProcessing - Boolean - indicates whether standard (system) event processing is performed.
//
Procedure OnCreateAtServer(Form, Cancel, StandardProcessing) Export
	
	FormEvents.OnCreateAtServer(Form, Cancel, StandardProcessing);
	
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   Form - ClientApplicationForm - report form or report settings.
//   NewDCSettings - DataCompositionSettings - settings to upload to the settings Builder.
//
Procedure BeforeLoadVariantAtServer(Form, NewDCSettings) Export
	
	SetLayoutTemplateInTaxiMode(Form, NewDCSettings);
	
	// Changing settings by functional options
	ConfigureSelectionParametersByFunctionalOptions(Form, NewDCSettings);
	
	// Conversion of extended selections "through a point"
	ConvertExtendedSelections(Form, NewDCSettings);
	
EndProcedure

// Adds registers for output to the report on movements in a field other than the logger.
// 
// Parameters:
//    Document - DocumentRef - the document is a collection of movements which need to be supplemented.
//    RegisterMatching - Map - compliance with data:
//        * Key     - MetadataObject - register as a metadata object.
//        * Value - String           - name of the Registrar's field.
//
Procedure SupplementComplianceOfTrafficReportRegistrars(Document, RegisterMatching) Export
	
	ARAPAccountingServer.SupplementComplianceOfTrafficReportRegistrars(Document, RegisterMatching);
	RebatesServer.SupplementComplianceOfTrafficReportRegistrars(Document, RegisterMatching);
	ProductionServer.SupplementComplianceOfTrafficReportRegistrars(Document, RegisterMatching);
	CalculationOfProductionPlan.SupplementComplianceOfTrafficReportRegistrars(Document, RegisterMatching);
EndProcedure

#EndRegion

#Region Private

Procedure ConfigureSelectionParametersByFunctionalOptions(Form, NewDCSettings)
	ReportName = TMReportOptionsOverridable.NameOfObjectKeyReport(Form);
	
	If Not GetFunctionalOption("UseMultipleCompanies") Then
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(NewDCSettings, "Organization");
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(NewDCSettings, "BusinessStructure.Organization");
		
		DataCompositionServer.RemoveParameterFromUserReportSettings(NewDCSettings, "ShowSales_");
	EndIf;
	
	If Not GetFunctionalOption("UseMultipleCashAccounts") Then
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(NewDCSettings, "CashAccount");
	EndIf;
	
	If Not GetFunctionalOption("UseMultipleBankAccounts") Then
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(NewDCSettings, "BankAccount");
	EndIf;
	
	If Not GetFunctionalOption("UseSeveralWarehouses") Then
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(NewDCSettings, "Warehouse");
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(NewDCSettings, "BusinessStructure.Warehouse");
	EndIf;
	
	If Not GetFunctionalOption("UseBusinessUnits") Then
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(NewDCSettings, "Department");
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(NewDCSettings, "TurnoverDimension.Department");
	EndIf;
	
	If GetFunctionalOption("UsePartnersAsCounterparties")
		And Not ReportName = "CustomersARAPStatement" 
		And Not ReportName = "VendorsARAPStatement" Then
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(NewDCSettings, "Counterparty");
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(NewDCSettings, "TurnoverDimension.Counterparty");
	EndIf;
	
	If Not GetFunctionalOption("UseItemVariants") Then
		DataCompositionServer.RemoveParameterFromUserReportSettings(NewDCSettings, "Characteristic");
		DataCompositionServer.RemoveParameterFromUserReportSettings(NewDCSettings, "DimensionOfProductItem.Characteristic");
		DataCompositionServer.RemoveDimensionFromAllReportSettings(NewDCSettings, "Characteristic");
		DataCompositionServer.RemoveDimensionFromAllReportSettings(NewDCSettings, "DimensionOfProductItem.Characteristic");
	EndIf;
	
	If Not GetFunctionalOption("UseItemsBatch") Then
		DataCompositionServer.RemoveParameterFromUserReportSettings(NewDCSettings, "Series");
		DataCompositionServer.RemoveParameterFromUserReportSettings(NewDCSettings, "DimensionOfProductItem.Series");
		DataCompositionServer.RemoveDimensionFromAllReportSettings(NewDCSettings, "Series");
		DataCompositionServer.RemoveDimensionFromAllReportSettings(NewDCSettings, "DimensionOfProductItem.Series");
	EndIf;
	
	// Currency settings are disabled only for reports without the "Cost" indicator
	
	If (ReportName = "AccountsReceivable"
		Or ReportName = "AccountsReceivableOverduePercentage"
		Or ReportName = "SalesMap"
		Or ReportName = "AccountsPayable"
		Or ReportName = "PaymentDisciplineOfCustomers"
		Or ReportName = "ReceiptsAndExpendituresAnalysis"
		Or ReportName = "BalanceSheetStatement"
		Or ReportName = "FinancialInstrumentsARAPStatement")
		And Not GetFunctionalOption("UseMultipleCurrencies")
		Or GetFunctionalOption("BaseVersion") Then
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(NewDCSettings, "Currency");
		DataCompositionServer.RemoveParameterFromUserReportSettings(NewDCSettings, "Currency");
		DataCompositionServer.RemoveParameterFromUserReportSettings(NewDCSettings, "ReportCurrency");
		DataCompositionServer.RemoveParameterFromUserReportSettings(NewDCSettings, "ReportData");
		DataCompositionServer.RemoveParameterFromUserReportSettings(NewDCSettings, "CashInformation");
		DataCompositionServer.RemoveParameterFromUserReportSettings(NewDCSettings, "SettlementsData");
		DataCompositionServer.RemoveParameterFromUserReportSettings(NewDCSettings, "WithdrawAmounts");
	EndIf;
	
	If ReportName = "ReceiptsAndExpendituresAnalysis"
		And Not Catalogs.LinesOfBusiness.AccountingByDirectionsIsUsed() Then
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(NewDCSettings, "LineOfBusiness");
	EndIf;
	
	If Not GetFunctionalOption("UseSeveralPriceTypes") Then
		DataCompositionServer.RemoveParameterFromUserReportSettings(NewDCSettings, "PriceKind");
		DataCompositionServer.RemoveParameterFromUserReportSettings(NewDCSettings, "EstimationOfStocksByTypeOfPrices");
	EndIf;
	
	If Not GetFunctionalOption("UseUnitsOfMeasureForReports") Then
		DataCompositionServer.RemoveParameterFromUserReportSettings(NewDCSettings, "QuantityUnits");
	EndIf;
	
	If Not GetFunctionalOption("UseCustomerContracts")
		And (ReportName = "AccountsReceivable"
		Or ReportName = "CustomersARAPAccounting"
		Or ReportName = "StatusOfCustomersARAP"
		Or ReportName = "CustomersARAPStatement"
		Or ReportName = "CustomersAccountsReceivable"
		Or ReportName = "CustomerDebtsByDeadlines"
		Or ReportName = "PaymentsFromCustomersByDeadlines") Then
		DataCompositionServer.RemoveDimensionFromAllReportSettings(NewDCSettings, "Contract");
		DataCompositionServer.DeleteSelectedFieldFromAllReportSettings(NewDCSettings, "Contract");
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(NewDCSettings, "Contract");
		DataCompositionServer.RemoveParameterFromUserReportSettings(NewDCSettings, "Contract");
	EndIf;
	
	If Not GetFunctionalOption("UseContractsWithVendors")
		And (ReportName = "AccountsPayable"
		Or ReportName = "VendorsARAPAccounting"
		Or ReportName = "StateOfVendorAccountsPayable"
		Or ReportName = "VendorsARAPStatement"
		Or ReportName = "VendorsAccountsPayable"
		Or ReportName = "VendorPayablesByDeadlines"
		Or ReportName = "PaymentsToVendorsByDeadlines") Then
		DataCompositionServer.RemoveDimensionFromAllReportSettings(NewDCSettings, "Contract");
		DataCompositionServer.DeleteSelectedFieldFromAllReportSettings(NewDCSettings, "Contract");
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(NewDCSettings, "Contract");
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(NewDCSettings, "TurnoverDimension.Contract");
		DataCompositionServer.RemoveParameterFromUserReportSettings(NewDCSettings, "Contract");
	EndIf;
	
	If Not GetFunctionalOption("UseCustomerContracts")
		And Not GetFunctionalOption("UseContractsWithVendors")
		And (ReportName = "PartnersARAPAccounting" 
		Or ReportName = "PartnersARAPAccountingStatement") Then
		DataCompositionServer.RemoveDimensionFromAllReportSettings(NewDCSettings, "Contract");
		DataCompositionServer.DeleteSelectedFieldFromAllReportSettings(NewDCSettings, "Contract");
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(NewDCSettings, "Contract");
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(NewDCSettings, "TurnoverDimension.Contract");
		DataCompositionServer.RemoveParameterFromUserReportSettings(NewDCSettings, "Contract");
	EndIf;
	
	If Not GetFunctionalOption("ControlIssueOfCashByPurposes")
		And (ReportName = "ControlOfAdvancesPaidToAdvanceHolderUnderRequest"
			Or ReportName = "CashTransactionControl") Then
		DataCompositionServer.RemoveDimensionFromAllReportSettings(NewDCSettings, "IssuancePurpose");
	EndIf;
	
	If ReportName = "DetailedCalculationOfCurrencyRevaluation"
		And (GetFunctionalOption("TradeManagement") 
			Or Not GetFunctionalOption("LocalizationRFService")) Then
		DataCompositionServer.RemoveDimensionFromAllReportSettings(NewDCSettings, "GLAccount");
		
		If NewDCSettings.Structure[0].Structure.Count() > 0 Then
		
			ReportGrouping = NewDCSettings.Structure[0].Structure[0];
			
			TableColumns1 = ReportGrouping.Columns[0];
			DataCompositionServer.DeleteGroupOfSelectedFieldFromAllReportSettings(TableColumns1, "AmountFA");
			DataCompositionServer.DeleteGroupOfSelectedFieldFromAllReportSettings(TableColumns1, "AmountFABefore");
			DataCompositionServer.DeleteGroupOfSelectedFieldFromAllReportSettings(TableColumns1, "IncomeWELL");
			DataCompositionServer.DeleteGroupOfSelectedFieldFromAllReportSettings(TableColumns1, "ConsumptionWELL");
			DataCompositionServer.DeleteGroupOfSelectedFieldFromAllReportSettings(TableColumns1, "TAAccrualIsRequired");
			DataCompositionServer.RemoveDimensionFromAllReportSettings(NewDCSettings, "GLAccount");
			
			GroupingSection = ReportGrouping.Rows[0];
			DataCompositionServer.RemoveSelectionItemFromAllReportSettings(GroupingSection, "AmountFA");
			DataCompositionServer.RemoveSelectionItemFromAllReportSettings(GroupingSection, "IncomeWELL");
			DataCompositionServer.RemoveSelectionItemFromAllReportSettings(GroupingSection, "ConsumptionWELL");
			DataCompositionServer.RemoveSelectionItemFromAllReportSettings(GroupingSection, "TAAccrualIsRequired");
			
			GroupingAnalytics = ReportGrouping.Rows[0].Structure[0];
			DataCompositionServer.RemoveSelectionItemFromAllReportSettings(GroupingAnalytics, "AmountFA");
			DataCompositionServer.RemoveSelectionItemFromAllReportSettings(GroupingAnalytics, "IncomeWELL");
			DataCompositionServer.RemoveSelectionItemFromAllReportSettings(GroupingAnalytics, "ConsumptionWELL");
			DataCompositionServer.RemoveSelectionItemFromAllReportSettings(GroupingAnalytics, "TAAccrualIsRequired");
		
			// enable hidden fields instead of deleted groups
			SumComplBefore = New DataCompositionField("SumComplBefore");
			AmountAtLocalExchangeRate = New DataCompositionField("AmountAtLocalExchangeRate");
			IncomeCompl = New DataCompositionField("IncomeCompl");
			ExpenseCompl = New DataCompositionField("ExpenseCompl");
			LocalAccrualIsRequired = New DataCompositionField("LocalAccrualIsRequired");
			
			FieldArray = New Array;
			DataCompositionServer.FindSelectedFieldRecursively(TableColumns1.Selection.Items, FieldArray, SumComplBefore);
			DataCompositionServer.FindSelectedFieldRecursively(TableColumns1.Selection.Items, FieldArray, AmountAtLocalExchangeRate);
			DataCompositionServer.FindSelectedFieldRecursively(TableColumns1.Selection.Items, FieldArray, IncomeCompl);
			DataCompositionServer.FindSelectedFieldRecursively(TableColumns1.Selection.Items, FieldArray, ExpenseCompl);
			DataCompositionServer.FindSelectedFieldRecursively(TableColumns1.Selection.Items, FieldArray, LocalAccrualIsRequired);
			
			For Each Item In FieldArray Do
				Item.Use = True;
			EndDo;
			
			// remove the Withdraw amounts TA flag
			FilterItems1 = NewDCSettings.Structure[0].Filter.Items;
			If FilterItems1.Count() = 3 Then
				FilterItems1.Delete(FilterItems1[2]);
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure ConvertExtendedSelections(ThisForm, SettingsComposer)
	For Each Filter In ThisForm.ParametersForm.Filter Do
		If TypeOf(Filter.Value) = Type("Array") Then
			FilterValuesList = New ValueList;
			FilterValuesList.LoadValues(Filter.Value);
		EndIf;
		If StrFind(Filter.Key, "_") Then
			If TypeOf(Filter.Value) = Type("Structure")
				And Filter.Value.Property("ComparisonType")
				And Filter.Value.Property("RightValue") Then
				FilterValue = Filter.Value.RightValue;
				TypeOfSelectionComparison = Filter.Value.ComparisonType;
			Else
				If TypeOf(Filter.Value) = Type("Array") Then
					FilterValue = FilterValuesList;
				Else
					FilterValue = Filter.Value;
				EndIf;
				If TypeOf(Filter.Value) = Type("ValueList")
					Or TypeOf(Filter.Value) = Type("Array") Then
					TypeOfSelectionComparison = DataCompositionComparisonType.InList;
				Else
					TypeOfSelectionComparison = DataCompositionComparisonType.Equal;
				EndIf;
			EndIf;
			DataCompositionClientServer.AddFilter(
				SettingsComposer, 
				StrReplace(Filter.Key, "_","."),
				FilterValue,
				TypeOfSelectionComparison,,
				New Structure("ToUserSettings", True));
			ThisForm.ParametersForm.Filter.Delete(Filter.Key);
		EndIf;
	EndDo;
EndProcedure

Function RequestForCurrencySelection()
	Query = New Query;
	Query.Text = "SELECT ALLOWED
	|	Currencies.Ref
	|FROM
	|	Catalog.Currencies AS Currencies
	|
	|ORDER BY
	|	Currencies.Code";
	
	Return Query;
EndFunction

// Sets the layout of the layout
// 
// Parameters:
// 	Form - ClientApplicationForm - 
// 	NewDCSettings - DataCompositionSettings - 
Procedure SetLayoutTemplateInTaxiMode(Form, NewDCSettings)
	
	If TMCommonUseClientServer.HasObjectAttribute(Form, "IsMobileClient")
		And Form.IsMobileClient Then
		LayoutTemplateParameterHasValue = "ReportAppearanceBeigeMobileClient";
	Else
		LayoutTemplateParameterHasValue = "ReportingBeige";
	EndIf;
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Taxi Then
		LayoutTemplateParameter = NewDCSettings.OutputParameters.Items.Find("AppearanceTemplate");
		If LayoutTemplateParameter.Value = "Main" 
			Or LayoutTemplateParameter.Value = "Main" Then
			LayoutTemplateParameter.Value = LayoutTemplateParameterHasValue;
			LayoutTemplateParameter.Use = True;
		EndIf;
		
		For Each StructureItem In NewDCSettings.Structure Do
			If TypeOf(StructureItem) = Type("DataCompositionNestedObjectSettings") Then
				LayoutTemplateParameter = StructureItem.Settings.OutputParameters.Items.Find("AppearanceTemplate");
				If LayoutTemplateParameter.Value = "Main" 
					Or LayoutTemplateParameter.Value = "Main" Then
					LayoutTemplateParameter.Value = LayoutTemplateParameterHasValue;
					LayoutTemplateParameter.Use = True;
				EndIf;
			EndIf;
		EndDo;
		
		// The form may not be a report form, but a report settings form.
		If Form.Items.Find("ReportSpreadsheetDocument") <> Undefined Then
			Form.Items.ReportSpreadsheetDocument.ViewScalingMode = ViewScalingMode.Normal;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion