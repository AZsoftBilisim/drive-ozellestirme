////////////////////////////////////////////////////////////////////////////////
// Updating the information base of the library Complex automation.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region LibraryOrConfigurationInformation

// Fills in basic information about the library or main configuration.
// A library whose name matches the name of the configuration in the metadata is defined as the main configuration.
// 
// Parameters:
//  LongDesc - Structure - information about the library:
//
//   * Name                 - String - name of the library, for example, "standard Subsystems".
//   * Version              - String - version in 4-digit format, for example, "2.1.3.1".
//
//   * RequiredSubsystems1 - Array - names of other libraries (String) that this library depends on.
//                                    Update handlers for such libraries must be called earlier
//                                    than the update handlers for this library.
//                                    If there are cyclic dependencies or, on the contrary, there are no dependencies,
//                                    the order of calling update handlers is determined by the order of adding modules
//                                    in the procedure for adding General module Subsystems
//                                    Configuration subsystems are undefined.
//   * DeferredHandlersExecutionMode - String - "Sequentially" - deferred update handlers are executed
//                                    sequentially in the range from the version number of the information database to
//                                    the configuration version number inclusive, or "in Parallel" - the deferred
//                                    handler passes control to the next handler after processing the first batch of data, and after
//                                    the last handler is executed, the cycle repeats again.
//
Procedure OnAddSubsystem(LongDesc) Export
	
	LongDesc.Name    = "ComplexAutomation";
	LongDesc.Version = "2.5.27.61";
	LongDesc.DeferredHandlersExecutionMode = "Parallel";
	LongDesc.OnlineSupportID = "ARAutomation";
	
EndProcedure

#EndRegion

#Region InfobaseUpdateHandlers

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export

	InfobaseUpdateCA.WhenAddingKAUpdateHandlers(Handlers);
	NonCurrentAssets.OnAddUpdateHandlers(Handlers);
	Catalogs.ProductCostElements.OnAddUpdateHandlers(Handlers);
	
	Documents.InternalAcceptanceCertificate.OnAddUpdateHandlers(Handlers);
	Documents.OrderOfMaterialsForProduction.OnAddUpdateHandlers(Handlers);
	Documents.BackflushProduction.OnAddUpdateHandlers(Handlers);
	ChartsOfCharacteristicTypes.BudgetFlowItemDimensions.OnAddUpdateHandlers(Handlers);
	Catalogs.BudgetBalanceItems.OnAddUpdateHandlers(Handlers);
	Catalogs.BudgetingLimits.OnAddUpdateHandlers(Handlers);
	Catalogs.RuleForCalculatingRelatedBudgetBalancesAndTurnovers.OnAddUpdateHandlers(Handlers);
	Catalogs.BudgetFlowItems.OnAddUpdateHandlers(Handlers);
	InformationRegisters.DocumentNameCacheForProcessingByRule.OnAddUpdateHandlers(Handlers);
	InformationRegisters.DeleteBudgetIndicatorLinks.OnAddUpdateHandlers(Handlers);
	
	AccumulationRegisters.RecordsIncomeExpensesOtherAssetsLiabilities.OnAddUpdateHandlers(Handlers);
	AccumulationRegisters.OtherAssetsAndLiabilitiesRecords.OnAddUpdateHandlers(Handlers);
	
	Catalogs.TypesOfEmployeeCompensations.OnAddUpdateHandlers(Handlers);
	Catalogs.NonCurrentAssetsAccountingGroups.OnAddUpdateHandlers(Handlers);
	Catalogs.AccrualAndDeductionKinds.OnAddUpdateHandlers(Handlers);
	Catalogs.BillsOfMaterials.OnAddUpdateHandlers(Handlers);
	
EndProcedure

// Called before procedures that handle updating is data.
//
Procedure BeforeUpdateInfobase() Export
	
EndProcedure

// Called after the is data update is complete.
// 
// Parameters:
//   PreviousVersion       - String - version before update. "0.0.0.0" for "empty" is.
//   CurrentVersion          - String - version after the update.
//   CompletedHandlers - ValueTree - a list of completed update handler procedures,
//                                             grouped by version number.
//   OutputUpdatesDetails - Boolean - (return value) if set to True,
//                                a form describing updates will be displayed. By default, True.
//   ExclusiveMode           - Boolean - True if the update was performed in exclusive mode.
//
// Example of bypassing executed update handlers:
//
//	For Each Version Of The Executed processors.Lines Cycle
//		
//		If The Version.Version = "*" Then
//			A handler that can be executed every time the version is changed.
//		Otherwise
//			A handler that is executed for a specific version.
//		The end if;
//		
//		For Each Handler From The Version.The lines of the Cycle
//			...
//		the end of the cycle;
//		
//	The end of the cycle;
//
Procedure AfterUpdateInfobase(Val PreviousVersion, Val CurrentVersion,
		Val CompletedHandlers, OutputUpdatesDetails, ExclusiveMode) Export
	
	InfobaseUpdateTM.AfterUpdateInfobase(PreviousVersion, CurrentVersion,
		CompletedHandlers, OutputUpdatesDetails, ExclusiveMode);
	
EndProcedure

// Called when preparing a table document describing changes in the program.
//
// Parameters:
//   Template - SpreadsheetDocument - description of updating all libraries and configurations.
//           The Template can be supplemented or replaced.
//            See the general Template description of the system changes.
//
Procedure OnPrepareUpdateDetailsTemplate(Val Template) Export
	
EndProcedure

// Adds transition handler procedures from another program (with a different configuration name) to the list.
// For example, to switch between different but related configurations: basic - > Prof. - > Corp.
// Called before starting updating the information security data.
//
// Parameters:
//  Handlers - ValueTable - with columns:
//    * PreviousConfigurationName - String - name of the configuration to be migrated from;
//    * Procedure                 - String - the full name of the procedure that handles the transition from the previous configuration programname. 
//                                  For example, "Updating the information database.Fill out Accounting policy"
//                                  It must be export.
//
// Example of adding a handler procedure to the list:
//  Handler = Handlers.Add();
//  Handler.Previous Configuration Name = "Complex Automation";
//  Handler.Procedure = "Updating the information database.Fill out Accounting policy";
//
Procedure OnAddApplicationMigrationHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.PreviousConfigurationName = "TradeManagement";
	Handler.Procedure = "InfobaseUpdateCA.UpgradeUTToKa";
	
	Handler = Handlers.Add();
	Handler.PreviousConfigurationName = "TradeManagement";
	Handler.Procedure = "Catalogs.BusinessTransactionsSettings.FillInPredefinedSettingsForBusinessOperations";
	
	InfobaseUpdateLocalization.WhenAddingTrafficHandlers(Handlers);
	
EndProcedure

// Allows you to override the data update mode of the information database.
// For use in rare (non-standard) cases of transition that are not provided for in
// the standard procedure for determining the update mode.
//
// Parameters:
//   DataUpdateMode - String - in the handler, you can assign one of the values:
//              "Initial filling" - if this is the first launch of an empty database (data area);
//              "Version update" - if the first launch is performed after updating the database configuration;
//              "Transition to another program" - if the first run is performed after updating the database configuration 
//                                          in which the name of the main configuration has changed.
//
//   StandardProcessing  - Boolean - if set to False, the standard procedure
//                                    for determining the update mode is not performed, 
//                                    but the value of the data update Mode is used.
//
Procedure OnDefineDataUpdateMode(DataUpdateMode, StandardProcessing) Export
	
EndProcedure

// Called after all transition handler procedures have been executed from another program (with a different configuration name),
// and before the start of updating the is data.
//
// Parameters:
//  PreviousConfigurationName    - String - name of the configuration before the transition.
//  PreviousConfigurationVersion - String - name of the previous configuration (before the transition).
//  Parameters                    - Structure: 
//    * ExecuteUpdateFromVersion   - Boolean - by default, True. If set to False, 
//        only the required update handlers (with the "* " version) will be executed.
//    * ConfigurationVersion           - String - version number after the transition. 
//        By default, it is equal to the value of the configuration version in the metadata properties.
//        To run, for example, all update handlers from the previous configuration Version, 
//        set the parameter value to previous configuration Version.
//        To run all update handlers at all, set the value to "0.0.0.1".
//    * ClearPreviousConfigurationInfo - Boolean - by default, True. 
//        If the previous configuration matches the name of the subsystem in the current configuration,
//        specify False.
//
Procedure OnCompleteApplicationMigration(Val PreviousConfigurationName, 
	Val PreviousConfigurationVersion, Parameters) Export
	
	If PreviousConfigurationName = "TradeManagement" Then
		Parameters.ClearPreviousConfigurationInfo = False;
		InfobaseUpdate.SetIBVersion(PreviousConfigurationName, PreviousConfigurationVersion, False);
	EndIf;
	
EndProcedure

#EndRegion

#Region RenamedMetadataObjects

// Fills in renaming metadata objects (subsystems and roles).
// More detailed See CommonOverridable.OnAddMetadataObjectsRenaming.
// 
// Parameters:
//   Total	- Structure - passed to the procedure by the basic Functionality subsystem.
//
Procedure OnAddMetadataObjectsRenaming(Total) Export
	
	SubsystemDetails = New Structure("Name, Version, DeferredHandlersExecutionMode, OnlineSupportID");
	OnAddSubsystem(SubsystemDetails);
	
	Common.AddRenaming(Total,
		"2.1.1.19",
		"Role.SectionProduction",
		"Role.ProductionSubsystem",
		SubsystemDetails.Name);
	
	Common.AddRenaming(Total,
		"2.1.1.59",
		"Subsystem.Production.Subsystem.IntershopManagement",
		"Subsystem.Production.Subsystem.IntershopManagement2_1",
		SubsystemDetails.Name);
		
	Common.AddRenaming(Total,
		"2.1.1.59",
		"Subsystem.Production.Subsystem.ShopManagement",
		"Subsystem.Production.Subsystem.ShopManagement2_1",
		SubsystemDetails.Name);
		
	Common.AddRenaming(Total,
		"2.1.1.59",
		"Subsystem.Production.Subsystem.InventoryAccounting",
		"Subsystem.Production.Subsystem.InventoryAccounting2_1",
		SubsystemDetails.Name);
		
	Common.AddRenaming(Total,
		"2.1.1.72",
		"Subsystem.Production.Subsystem.ProductionCosts",
		"Subsystem.Production.Subsystem.ProductionCosts2_1",
		SubsystemDetails.Name);
		
	Common.AddRenaming(Total,
		"2.1.1.72",
		"Subsystem.Production.Subsystem.CostAnalysis",
		"Subsystem.Production.Subsystem.CostAnalysis2_1",
		SubsystemDetails.Name);
		
	Common.AddRenaming(Total,
		"2.5.2.10",
		"Role.AddChangeRegistrationsOfDevelopments",
		"Role.AddEditAssetActivityRecords",
		SubsystemDetails.Name);	
	
	Common.AddRenaming(Total,
		"2.5.6.1",
		"Subsystem.NonCurrentAssets.Subsystem.Leasing",
		"Subsystem.NonCurrentAssets.Subsystem.Lease",
		SubsystemDetails.Name);
	
	Common.AddRenaming(Total,
		"2.5.6.1",
		"Role.ReadLeasingContracts",
		"Role.ReadLeaseContracts",
		SubsystemDetails.Name);
	
	Common.AddRenaming(Total,
		"2.5.6.1",
		"Role.AddChangePurchaseOfLeasingServices",
		"Role.AddEditLeaseServiceReceipts",
		SubsystemDetails.Name);
	
	Common.AddRenaming(Total,
		"2.5.6.1",
		"Role.ReadPurchaseOfLeasingServices",
		"Role.ReadInvoicesForLeaseServices",
		SubsystemDetails.Name);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region FillingInEmptyIB

// Handler for the first launch of the SPACECRAFT.
//
Procedure FirstRun() Export
	
	SetTargetPriceCurrency();
	SetCurrencyOfPricesForTypesOfWork();
	
	FillInUseBudgetingConstant();
	ChartsOfCharacteristicTypes.BudgetFlowItemDimensions.FillInPredefinedBudgetItemAnalytics();
	Catalogs.ProductCostElements.SetUpArticleCalculationOfPredefinedItems();
	Constants.AssetLiabilityRecordsArePopulated.Set(True);
	Constants.UseVATDeclarationSection7Filling.Set(True);
	
EndProcedure

Procedure UpgradeUTToKa() Export
	
	ChartsOfCharacteristicTypes.BudgetFlowItemDimensions.FillInPredefinedBudgetItemAnalytics();
	Catalogs.ProductCostElements.SetUpArticleCalculationOfPredefinedItems();
	Constants.AssetLiabilityRecordsArePopulated.Set(True);
	
	InfobaseUpdateTM.FillInValueOfSeparationByDataAreas();
	
	ConstantValues = New Structure;
	ConstantValues.Insert("TradeManagement", False);
	ConstantValues.Insert("ComplexAutomation", True);
	
#Region Assignment_options
	ConstantValues.Insert(Metadata.Constants.OptionOfMaterialAssignmentWhenTransferringToProduction.Name,  Enums.OptionsOfMaterialAssignmentWhenTransferringToProduction.AssignmentRecipient);
	ConstantValues.Insert(Metadata.Constants.SubcontractorOptionOfAssignment2_5.Name,                   Enums.OptionsOfAssignmentDuringTransferToProcessing.DoNotAssign);
	ConstantValues.Insert(Metadata.Constants.OptionOfAssignmentAtTransferToSubcontractor2_5.Name,           Enums.OptionsOfAssignmentDuringTransferToProcessing.SubcontractOrder);
#EndRegion
	
	For Each KeyAndValue In ConstantValues Do
		Constants[KeyAndValue.Key].Set(KeyAndValue.Value);
	EndDo; 
	
	If Constants.UseVATAccounting.Get() = True Then 
		Constants.UseVATDeclarationSection7Filling.Set(True);
	EndIf;
	
	RefreshReusableValues();
	
EndProcedure

// The procedure sets the value of the target price currency.
// Called when the IB is initially filled in.
//
Procedure SetTargetPriceCurrency()
	
	If Not ValueIsFilled(Constants.PlannedPriceCurrencyOfProductsMaterialsAndLabor.Get())
		And Not Constants.UseMultipleCurrencies.Get()Then
		
		Query = New Query(
			"SELECT TOP 2
			|	Currencies.Ref AS Ref
			|FROM
			|	Catalog.Currencies AS Currencies
			|WHERE
			|	NOT Currencies.DeletionMark");
		QueryResult = Query.Execute();
		
		If Not QueryResult.IsEmpty() Then
			Selection = QueryResult.Select();
			If Selection.Count() = 1 Then
				Selection.Next();
				
				Constants.PlannedPriceCurrencyOfProductsMaterialsAndLabor.Set(Selection.Ref);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

// The procedure sets the value of the currency of prices for types of work.
// Called when the IB is initially filled in.
//
Procedure SetCurrencyOfPricesForTypesOfWork()
	
	If Not ValueIsFilled(Constants.CurrencyOfActivityKindRates.Get())
		And Not Constants.UseMultipleCurrencies.Get()Then
		
		Query = New Query(
			"SELECT TOP 2
			|	Currencies.Ref AS Ref
			|FROM
			|	Catalog.Currencies AS Currencies
			|WHERE
			|	NOT Currencies.DeletionMark");
		QueryResult = Query.Execute();
		
		If Not QueryResult.IsEmpty() Then
			Selection = QueryResult.Select();
			If Selection.Count() = 1 Then
				Selection.Next();
				
				Constants.CurrencyOfActivityKindRates.Set(Selection.Ref);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure WhenAddingKAUpdateHandlers(Handlers) Export

#Region FirstRun

	Handler = Handlers.Add();
	Handler.Procedure = "InfobaseUpdateCA.FirstRun";
	Handler.Version = "";
	Handler.ExecutionMode = "Exclusively";
	Handler.InitialFilling = True;
	Handler.Comment = "";

#EndRegion

#Region SetConstantUseMaterialOrdersInProduction
	
	Handler = Handlers.Add();
	Handler.Procedure = "InfobaseUpdateCA.SetConstantUseMaterialOrdersInProduction";
	Handler.Version = "2.5.25.12";
	Handler.ExecutionMode = "Deferred";
	Handler.InitialFilling = True;
	Handler.Id = New UUID("25ff4063-a129-4519-82fd-d5ca8ab806e2");
	Handler.UpdateDataFillingProcedure = "InfobaseUpdateCA.RegisterDataForConstantUpdates";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Comment = NStr("vi = 'Điền ban đầu hằng ""Sử dụng đơn đặt hàng vật tư trong sản xuất"". ';
							|ru = 'Начальное заполнение константы ""Использовать заказы материалов в производство"".';
							|en = 'Initial filling of the ""Use material orders for shop floor stockroom"" constant.'; fa = 'Initial filling of the ""Use material orders for shop floor stockroom"" constant.';
							|it = 'Initial filling of the ""Use material orders for shop floor stockroom"" constant.';
							|pl = 'Initial filling of the ""Use material orders for shop floor stockroom"" constant.';
							|tr = '""Üretimde malzeme siparişlerinin düzeltilmesini kullan"" sabitinin ilk doldurulması.'");
	
	ObjectsToRead = New Array;
	ObjectsToRead.Add(Metadata.Constants.UseProduction.FullName());
	ObjectsToRead.Add(Metadata.Constants.UseSeveralWarehouses.FullName());
	ObjectsToRead.Add(Metadata.Constants.UseMaterialOrdersForShopFloorStockroom.FullName());
	
	Handler.ObjectsToRead = StrConcat(ObjectsToRead, ",");
	
	ObjectsToChange = New Array;
	ObjectsToChange.Add(Metadata.Constants.UseMaterialOrdersForShopFloorStockroom.FullName());
	Handler.ObjectsToChange = StrConcat(ObjectsToChange, ",");

#EndRegion
	
#Region ClearCacheOfAuxiliaryDataOfBudgetType

	Handler = Handlers.Add();
	Handler.Procedure = "InfobaseUpdateCA.ClearCacheOfAuxiliaryDataOfBudgetType";
	Handler.Version = "2.5.27.13";
	Handler.ExecutionMode = "Exclusively";
	Handler.InitialFilling = True;
	Handler.Id = New UUID("1c26f542-471a-4927-b3e0-c038c81fe901");
	Handler.Comment = NStr("vi = 'Xóa cache dữ liệu phụ trợ của dạng ngân sách"".';
							|ru = 'Очищает кэш вспомогательных данных вида бюджета"".';
							|en = 'Clears cache of budget profile service data"".'; fa = 'Clears cache of budget profile service data"".';
							|it = 'Pulisce cache di dati ausiliari della tipologia di budget"".';
							|pl = 'Wyczyszcza pamięć podręczną pomocniczych danych rodzaju budżetu"".';
							|tr = 'Bütçe görünümünün yardımcı veri önbelleğini temizler"".'");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.InformationRegisters.CacheOfAuxiliaryBudgetProfileData.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");

#EndRegion

EndProcedure

// Handler for the first launch of the SPACECRAFT.
// Includes the "use Budgeting" constant.
//
Procedure FillInUseBudgetingConstant() Export
	
	If Not GetFunctionalOption("ComplexAutomation") Then
		Return;
	EndIf;
	
	Constants.UseBudgeting.Set(True);
	Constants.InterfaceVersion82.Set(False);
	
EndProcedure

#Region ClearCacheOfAuxiliaryDataOfBudgetType

Procedure ClearCacheOfAuxiliaryDataOfBudgetType() Export
	
	InformationRegisters.CacheOfAuxiliaryBudgetProfileData.CreateRecordSet().Write();
	
EndProcedure

#EndRegion

#Region SetConstantUseVATDeclarationSection7Filling

Procedure SetConstantUseVATDeclarationSection7Filling() Export
	
	If Constants.UseVATAccounting.Get() = True Then
		Constants.UseVATDeclarationSection7Filling.Set(True);
	EndIf;
	
EndProcedure

#EndRegion

#Region SettingConstant_UseMaterialOrdersInProduction

Procedure SetConstantUseMaterialOrdersInProduction(ParametersOfUpdate) Export
	
	UseProduction = Constants.UseProduction.Get();
	UseSeveralWarehouses = Constants.UseSeveralWarehouses.Get();
	ConstantValue = UseProduction And UseSeveralWarehouses;
	
	If Constants.UseMaterialOrdersForShopFloorStockroom.Get() <> ConstantValue Then
		Constants.UseMaterialOrdersForShopFloorStockroom.Set(ConstantValue);
	EndIf; 	
	
	ParametersOfUpdate.ProcessingCompleted = True;
	
EndProcedure

// Empty registration handler
Procedure RegisterDataForConstantUpdates(ParametersOfUpdate) Export
	
	// Registration is not required
	Return;
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion
