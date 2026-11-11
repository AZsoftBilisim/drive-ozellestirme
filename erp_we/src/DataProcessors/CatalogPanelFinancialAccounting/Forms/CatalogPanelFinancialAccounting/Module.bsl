

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	MultipleChartsOfAccountsInInternationalAccounting = GetFunctionalOption("UseSeveralChartsOfAccountsInFinancialAccounting");
	
	Items.OpenAChartOfAccounts.Visible = Not MultipleChartsOfAccountsInInternationalAccounting;
	Items.ToOpenTheChartOfAccounts.Visible = MultipleChartsOfAccountsInInternationalAccounting;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OpenInternationalChartOfAccounts(Command)
	OpenForm("ChartOfAccounts.International.ListForm", , ThisForm);
EndProcedure

&AtClient
Procedure OpenExtraDimensionTypes(Command)
	OpenForm("ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.ListForm", , ThisForm);
EndProcedure

&AtClient
Procedure OpenBusinessAccountPlans(Command)
	
	OpenForm("InformationRegister.FinancialAccountingChartsOfAccountsForCompanies.Form.Workplace", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenTransactionGenerationSettingsCatalog(Command)
	
	OpenForm("Catalog.FinancialAccountingPostingGenerationSetting.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure SetClosingDate(Command)
	
	OpenForm("InformationRegister.ClosingDatesOfFinancialAccountingPostingGeneration.Form.ClosingDatesOfAccountingPostingGeneration", , ThisForm);
	
EndProcedure

#Region FinancialAccountingGroups

&AtClient
Procedure OpenTheDirectoryOfTheFinancialAccountingGroupOfFunds(Command)

	OpenForm("Catalog.GroupsOfFinancialAccountingOfCash.ListForm", , ThisForm);

EndProcedure

&AtClient
Procedure OpenTheStandardOperationsDirectory(Command)

	OpenForm("Catalog.StandardTransactionsOfFinancialAccounting.ListForm", , ThisForm);

EndProcedure

&AtClient
Procedure OpenTheDirectoryOfTheGroupOfFinancialAccountingOfIncomeExpenses(Command)
	
	OpenForm("Catalog.IncomeExpensesAccountingGroups.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenTheDirectoryOfTheGroupOfFinancialAccountingCalculations(Command)
	
	OpenForm("Catalog.FinancialAccountingGroupsOfARAP.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenTheReferenceListOfTheItemSFinancialAccountingGroup(Command)
	
	OpenForm("Catalog.InventoryAccountingGroups.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenCatalogNonCurrentAssetsAccountingGroups(Command)
	
	OpenForm("Catalog.NonCurrentAssetsAccountingGroups.ListForm", , ThisForm);
	
EndProcedure

#EndRegion

#Region InternationalAccountingPostingGeneration

&AtClient
Procedure OpenTheSetupOfTransactionsBasedOnOperationalAccountingData(Command)
	
	FormParameters = FinancialAccountingClient.ParametersForOpeningTransactionConfigurationForms();
	FinancialAccountingUponOperationalAccountingDataClient.OpenSettingsForTransactionTemplates(FormParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure OpenTheSetupOfTransactionsBasedOnTheAccountingReglData(Command)
	
	FormParameters = FinancialAccountingClient.ParametersForOpeningTransactionConfigurationForms();
	FinancialAccountingUponLocalAccountingClient.OpenAccountsAndTurnoverMatchingSettings(FormParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure OpenTransactionSettingsForAccountingItems(Command)
	
	FormParameters = FinancialAccountingClient.ParametersForOpeningTransactionConfigurationForms();
	FinancialAccountingByFinancialRegisterDataClient.OpenInvoiceSettingsForAccountingObjects(FormParameters, ThisObject);
	
EndProcedure

#EndRegion

#Region FinancialReporting

&AtClient
Procedure OpenTheFinancialReportSetsDirectory(Command)
	
	OpenForm("Catalog.FinancialReportSets.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenTheTypesOfFinancialReportsDirectory(Command)
	
	OpenForm("Catalog.FinancialReportTypes.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure ToOpenTheDirectoryOfANonMonetaryIndicatorsReporting(Command)
	
	OpenForm("Catalog.NonMonetaryItems.ListForm", , ThisForm);
	
EndProcedure

#EndRegion

#Region AboutSiIa

&AtClient
Procedure OpenIAGroups(Command)
	
	OpenForm("Catalog.IntangibleAssetsGroups.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenFAGroups(Command)
	
	OpenForm("Catalog.FixedAssetsGroupsFinancialAccounting.ListForm", , ThisForm);
	
EndProcedure

#EndRegion

#EndRegion
