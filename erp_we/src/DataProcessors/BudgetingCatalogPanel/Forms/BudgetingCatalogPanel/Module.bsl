
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If GetFunctionalOption("TradeManagement") Then
		Title = NStr("vi = 'Tùy chỉnh và danh mục kế hoạch';
					|ru = 'Настройки и справочники по планированию';
					|en = 'Planning settings and catalogs'; fa = 'Planning settings and catalogs';
					|it = 'Impostazioni e directory per pianificazione';
					|pl = 'Ustawienia i przewodniki dla planowania';
					|tr = 'Planlamaya göre ayarlar ve kataloglar'");
	Else
		Title = NStr("vi = 'Tùy chỉnh và danh mục ngân sách và kế hoạch';
					|ru = 'Настройки и справочники по бюджетированию и планированию';
					|en = 'Budgeting and planning settings and catalogs'; fa = 'تنظیمات و فهرست‌های بودجه‌بندی و برنامه‌ریزی';
					|it = 'Impostazioni e directory per bilancio e pianificazione';
					|pl = 'Ustawienia i katalogi budżetowania i planowania';
					|tr = 'Bütçeleme ve planlama kapsamında ayarlar ve kataloglar'");
	EndIf;
	
	// Visibility settings at startup
	ManagingElements();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OpenBudgetingModels(Command)
	OpenForm("Catalog.BudgetingModels.ListForm", , ThisForm);
	Return; // not used in UT2
	
EndProcedure

&AtClient
Procedure OpenBudgetItems(Command)
	OpenForm("Catalog.BudgetFlowItems.ListForm", , ThisForm);
	Return; // not used in UT2
	
EndProcedure

&AtClient
Procedure OpenBudgetItemDimensions(Command)
	OpenForm("ChartOfCharacteristicTypes.BudgetFlowItemDimensions.ListForm", , ThisForm);
	Return; // not used in UT2
	
EndProcedure

&AtClient
Procedure OpenScripts(Command)
	OpenForm("Catalog.BudgetingScenarios.ListForm", , ThisForm);
	Return; // not used in UT2
	
EndProcedure

&AtClient
Procedure OpenBudgetProfiles(Command)
	OpenForm("Catalog.BudgetProfiles.ListForm", , ThisForm);
	Return; // not used in UT2
	
EndProcedure

&AtClient
Procedure OpenBudgetMetrics(Command)
	OpenForm("Catalog.BudgetBalanceItems.ListForm", , ThisForm);
	Return; // not used in UT2
	
EndProcedure

&AtClient
Procedure OpenRulesForCalculatingBalancesAndTurnover(Command)
	OpenForm("Catalog.RuleForCalculatingRelatedBudgetBalancesAndTurnovers.ListForm");
	Return;
	
EndProcedure

&AtClient
Procedure OpenNonFinancialIndicators(Command)
	OpenForm("Catalog.NonFinancialItemsOfBudgets.ListForm", , ThisForm);
	Return; // not used in UT2
	
EndProcedure

&AtClient
Procedure OpenTemplatesForEnteringNonFinancialIndicators(Command)
	OpenForm("Catalog.NonFinancialItemProfiles.ListForm", , ThisForm);
	Return; // not used in UT2
	
EndProcedure

&AtClient
Procedure OpenRulesForGettingActualData(Command)
	OpenForm("DataProcessor.SetUpRulesOfReceivingActualBudgetingData.Form");
	Return; // not used in UT2
	
EndProcedure

&AtClient
Procedure OpenStagesOfTheBudgetProcess(Command)
	OpenForm("Catalog.BudgetingSteps.ListForm", , ThisForm);
	Return; // in UT2 and KA2 is not used
	
EndProcedure

&AtClient
Procedure ExportBudgetingModel(Command)
	OpenForm("DataProcessor.BudgetingModelExportImportWizard.Form.Upload0", , ThisForm);
	Return; // in UT11 is not used
	
EndProcedure

&AtClient
Procedure ImportBudgetingModel(Command)
	OpenForm("DataProcessor.BudgetingModelExportImportWizard.Form.Load", , ThisForm);
	Return; // in UT11 is not used
	
EndProcedure

&AtClient
Procedure OpenPlanningDataSources(Command)
	
	OpenForm("Catalog.PlanningDataSources.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenPlanTypes(Command)
	
	OpenForm("Catalog.PlanProfiles.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenPlanningScenarios(Command)
	
	OpenForm("Catalog.SalesOperationsPlanningScenarios.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenSeasonalOdds(Command)
	
	OpenForm("InformationRegister.SeasonalIndexes.Form.SeasonalIndexes",, ThisForm);
	
EndProcedure

&AtClient
Procedure OpenSeasonalGroupsOfBusinessRegions(Command)
	
	OpenForm("Catalog.SeasonalGroupsOfBusinessRegions.ListForm",, ThisForm);
	
EndProcedure

&AtClient
Procedure OpenAllocationStandards(Command)
	
	OpenForm("Document.SalesPlansAllocationBaseByCategories.Form.EditForm",, ThisForm);
	
EndProcedure

&AtClient
Procedure OpenAccessGroupsOfBudgetProfiles(Command)
	OpenForm("Catalog.BudgetProfileAccessGroups.ListForm", , ThisForm);
	Return; // not used in UT2
	
EndProcedure

&AtClient
Procedure OpenAccessGroupsOfBudgetItemsAndIndicators(Command)
	OpenForm("Catalog.AccessGroupsOfBudgetFlowItemsAndIndicators.ListForm", , ThisForm);
	Return; // not used in UT2
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ManagingElements()
	
	// Budgeting
	UseBudgeting = GetFunctionalOption("UseBudgeting");
	
	AccessRightOfBudgetingModel                         = AccessRight("View", Metadata.Catalogs.BudgetingModels);
	RightOfAccessScenarios                                     = AccessRight("View", Metadata.Catalogs.BudgetingScenarios);
	RightOfAccessBudgetItems                               = AccessRight("View", Metadata.Catalogs.BudgetFlowItems);
	RightOfAccessToBudgetItems                      = AccessRight("View", Metadata.ChartsOfCharacteristicTypes.BudgetFlowItemDimensions);
	RightOfAccessBudgetIndicators                           = AccessRight("View", Metadata.Catalogs.BudgetBalanceItems);
	RightOfAccessRulesForCalculatingBalancesAndBudgetTurnover      = AccessRight("View", Metadata.Catalogs.RuleForCalculatingRelatedBudgetBalancesAndTurnovers);
	RightOfAccessNonFinancialIndicatorsOfBudgets               = AccessRight("View", Metadata.Catalogs.NonFinancialItemsOfBudgets);
	AccessRightsConfiguringRulesForGettingBudgetingFact  = AccessRight("View", Metadata.DataProcessors.SetUpRulesOfReceivingActualBudgetingData);
	RightOfAccessTypesOfBudgets                                 = AccessRight("View", Metadata.Catalogs.BudgetProfiles);
	RightToAccessAndUploadBudgetingModel = AccessRight("View", Metadata.DataProcessors.BudgetingModelExportImportWizard);
	RightOfAccessTemplatesForEnteringNonFinancialIndicators          = AccessRight("View", Metadata.Catalogs.NonFinancialItemProfiles);
	
	Items.BudgetingGroup.Visible                       = UseBudgeting;
	Items.OpenBudgetingModels.Visible                = AccessRightOfBudgetingModel;
	Items.ImportBudgetingModel.Visible              = AccessRightOfBudgetingModel And RightToAccessAndUploadBudgetingModel;
	Items.UploadTheBudgetingModelToAFile.Visible         = AccessRightOfBudgetingModel And RightToAccessAndUploadBudgetingModel;
	Items.OpenScripts.Visible                            = RightOfAccessScenarios;
	Items.OpenBudgetItems.Visible                      = RightOfAccessBudgetItems;
	Items.OpenBudgetItemDimensions.Visible             = RightOfAccessToBudgetItems;
	Items.OpenBudgetMetrics.Visible                  = RightOfAccessBudgetIndicators;
	Items.OpenRulesForCalculatingBalancesAndTurnover.Visible     = RightOfAccessRulesForCalculatingBalancesAndBudgetTurnover;
	Items.OpenNonFinancialIndicators.Visible              = RightOfAccessNonFinancialIndicatorsOfBudgets;
	Items.OpenRulesForGettingAFact.Visible               = AccessRightsConfiguringRulesForGettingBudgetingFact;
	Items.OpenBudgetProfiles.Visible                        = RightOfAccessTypesOfBudgets;
	Items.OpenTemplatesForEnteringNonFinancialIndicators.Visible = RightOfAccessTemplatesForEnteringNonFinancialIndicators;
	
	RightOfAccessStagesOfPreparationOfBudgets                           = False;
	UseBudgetProcess                                  = False;
	AccessRightAccessGroupsOfBudgetTypes                        = False;
	RightOfAccessGroupsOfAccessToBudgetItemsAndIndicators           = False;
	UseAccessGroupsOfItemKindsAndBudgetBalanceItems      = False;
	RightOfAccessStagesOfPreparationOfBudgets                      = AccessRight("View", Metadata.Catalogs.BudgetingSteps);
	UseBudgetProcess                             = GetFunctionalOption("UseBudgetProcess");
	AccessRightAccessGroupsOfBudgetTypes                   = AccessRight("View", Metadata.Catalogs.BudgetProfileAccessGroups);
	RightOfAccessGroupsOfAccessToBudgetItemsAndIndicators      = AccessRight("View", Metadata.Catalogs.AccessGroupsOfBudgetFlowItemsAndIndicators);
	UseAccessGroupsOfItemKindsAndBudgetBalanceItems = GetFunctionalOption("UseAccessGroupsOfItemKindsAndBudgetBalanceItems");
	Items.OpenBudgetPreparationStages.Visible                 = RightOfAccessStagesOfPreparationOfBudgets And UseBudgetProcess;
	Items.OpenAccessGroupsOfBudgetProfiles.Visible              = RightOfAccessGroupsOfAccessToBudgetItemsAndIndicators 
		And UseAccessGroupsOfItemKindsAndBudgetBalanceItems;
	Items.OpenAccessGroupsOfBudgetItemsAndIndicators.Visible = AccessRightAccessGroupsOfBudgetTypes 
		And UseAccessGroupsOfItemKindsAndBudgetBalanceItems;
	ThereIsDataToDisplayBudgeting = False;
	ThereIsDataToDisplayBudgeting = UseBudgeting
		And (AccessRightOfBudgetingModel
			Or RightOfAccessScenarios
			Or RightOfAccessBudgetItems
			Or RightOfAccessToBudgetItems
			Or RightOfAccessBudgetIndicators
			Or RightOfAccessRulesForCalculatingBalancesAndBudgetTurnover
			Or RightOfAccessNonFinancialIndicatorsOfBudgets
			Or AccessRightsConfiguringRulesForGettingBudgetingFact
			Or RightOfAccessTypesOfBudgets
			Or RightToAccessAndUploadBudgetingModel
			Or RightOfAccessTemplatesForEnteringNonFinancialIndicators
			Or (UseBudgetProcess And RightOfAccessStagesOfPreparationOfBudgets)
			Or (UseAccessGroupsOfItemKindsAndBudgetBalanceItems 
				And (AccessRightAccessGroupsOfBudgetTypes
					Or RightOfAccessGroupsOfAccessToBudgetItemsAndIndicators))
			);
	// Planning
	UsePlanning = 
		GetFunctionalOption("UsePurchasePlanning")
		Or GetFunctionalOption("UseSalesPlans")
		Or GetFunctionalOption("UseProductionPlanning")
		Or GetFunctionalOption("UseAssemblyDisassemblyPlanning")
		Or GetFunctionalOption("UseSalesPlansByCategories")
		Or GetFunctionalOption("UsePlanningOfInventoryConsumption");
	
	RightOfAccessPlanningDataSources = AccessRight("View", Metadata.Catalogs.PlanningDataSources);
	RightOfAccessPlanningScenarios        = AccessRight("View", Metadata.Catalogs.SalesOperationsPlanningScenarios);
	RightOfAccessTypesOfPlans                  = AccessRight("View", Metadata.Catalogs.PlanProfiles);
	RightOfAccessSeasonalCoefficients        = AccessRight("View", Metadata.InformationRegisters.SeasonalIndexes);
	RightOfAccessSeasonalGroupsOfBusinessRegions= AccessRight("View", Metadata.Catalogs.SeasonalGroupsOfBusinessRegions);
	RightOfAccessDistributionStandards      = AccessRight("View", Metadata.Documents.SalesPlansAllocationBaseByCategories);
	
	Items.OpenPlanningDataSources.Visible = RightOfAccessPlanningDataSources;
	Items.OpenPlanningScenarios.Visible = RightOfAccessPlanningScenarios;
	Items.OpenPlanTypes.Visible = RightOfAccessTypesOfPlans;
	Items.OpenSeasonalOdds.Visible = RightOfAccessSeasonalCoefficients;
	Items.OpenSeasonalGroupsOfBusinessRegions.Visible = RightOfAccessSeasonalGroupsOfBusinessRegions;
	Items.OpenAllocationStandards.Visible = RightOfAccessDistributionStandards;
	
			
	ThereIsDataToDisplayPlanning = UsePlanning
		And (RightOfAccessPlanningDataSources
			Or RightOfAccessPlanningScenarios
			Or RightOfAccessTypesOfPlans
			Or RightOfAccessSeasonalCoefficients
			Or RightOfAccessSeasonalGroupsOfBusinessRegions
			Or RightOfAccessDistributionStandards);
		
		
	If ThereIsDataToDisplayBudgeting Or ThereIsDataToDisplayPlanning Then
		Items.GroupTheNecessarySettingsAreNotSet.Visible = False;
	EndIf;
	
EndProcedure

#EndRegion
