////////////////////////////////////////////////////////////////////////////////
// Updating the information base of the Enterprise Management library.
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
	
	LongDesc.Name    = "ERPWEENG";
	LongDesc.Version = "2.5.27.61";
	LongDesc.DeferredHandlersExecutionMode = "Parallel";
	LongDesc.OnlineSupportID = "ERPWEENG";
	

EndProcedure

#EndRegion

#Region InfobaseUpdateHandlers

// // See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export
	
	InfobaseUpdatePM.WhenAddingUPUpdateHandlers(Handlers);
	
	Catalogs.ManufacturingOperations.OnAddUpdateHandlers(Handlers);
	Documents.MaterialProviderOrder2_5.OnAddUpdateHandlers(Handlers);
	Documents.ReportToMaterialProvider2_5.OnAddUpdateHandlers(Handlers);
	Documents.ProductionStage2_2.OnAddUpdateHandlers(Handlers);
	Documents.EngineeringChangeOrder.OnAddUpdateHandlers(Handlers);
	Documents.ProductionOperation2_2.OnAddUpdateHandlers(Handlers);
	Tasks.BudgetTask.OnAddUpdateHandlers(Handlers);
	InformationRegisters.QueueOfProductionOperations.OnAddUpdateHandlers(Handlers);
	InformationRegisters.TechnologicalProcessesOfProductionStages.OnAddUpdateHandlers(Handlers);
	Catalogs.BudgetingSteps.OnAddUpdateHandlers(Handlers);
	InformationRegisters.OrderStructure.OnAddUpdateHandlers(Handlers);
	InformationRegisters.ProductionOrders.OnAddUpdateHandlers(Handlers);
	InformationRegisters.MultiplesOfLotsAndSemiFinishedProducts.OnAddUpdateHandlers(Handlers);
	InformationRegisters.ItemLinksByChangeOrders.OnAddUpdateHandlers(Handlers);
	InformationRegisters.AlternativeMaterials.OnAddUpdateHandlers(Handlers);
	InformationRegisters.ProductionStageStates.OnAddUpdateHandlers(Handlers);
	AccumulationRegisters.PlannedMaterialCosts.OnAddUpdateHandlers(Handlers);
	AccumulationRegisters.PlannedOtherCosts.OnAddUpdateHandlers(Handlers);
	AccumulationRegisters.PlannedLaborCosts.OnAddUpdateHandlers(Handlers);
	AccountingRegisters.International.OnAddUpdateHandlers(Handlers);
	AccountingRegisters.InternationalWithoutCorrespondence.OnAddUpdateHandlers(Handlers);
	
	//++ WE
	SalaryAndPersonnel.OnAddUpdateHandlers(Handlers);
	//-- WE
	
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
//  Handler.Previous Configuration Name = "Trade Management";
//  Handler.Procedure = "Updating the information database.Fill out Accounting policy";
//
Procedure OnAddApplicationMigrationHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.PreviousConfigurationName = "ComplexAutomation";
	Handler.Procedure = "PropertyManagerInternal.CreatePredefinedPropertiesSets";
	
	Handler = Handlers.Add();
	Handler.PreviousConfigurationName = "TradeManagement";
	Handler.Procedure = "PropertyManagerInternal.CreatePredefinedPropertiesSets";

	Handler = Handlers.Add();
	Handler.PreviousConfigurationName = "TradeManagement";
	Handler.Procedure = "InfobaseUpdatePM.UpdatingUTToERP";
	
	Handler = Handlers.Add();
	Handler.PreviousConfigurationName = "TradeManagement";
	Handler.Procedure = "Catalogs.BusinessTransactionsSettings.FillInPredefinedSettingsForBusinessOperations";
	
	Handler = Handlers.Add();
	Handler.PreviousConfigurationName = "ComplexAutomation";
	Handler.Procedure = "InfobaseUpdatePM.UpgradingKaToERP";
	
	Handler = Handlers.Add();
	Handler.PreviousConfigurationName = "ComplexAutomation";
	Handler.Procedure = "Catalogs.BusinessTransactionsSettings.FillInPredefinedSettingsForBusinessOperations";
	
	InfobaseUpdateLocalization.WhenAddingClickThroughHandlers(Handlers);
	
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
	
	If PreviousConfigurationName = "TradeManagement"
	 Or PreviousConfigurationName = "ComplexAutomation" Then
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
		"2.2.1.13",
		"Role.SectionInternationalFinancialAccounting",
		"Role.SubsystemFinancialAccounting",
		SubsystemDetails.Name);
	Common.AddRenaming(Total,
		"2.1.1.56",
		"Role.AddChangeReasonsForOperationSheetsExecutionDelays",
		"Role.AddEditReasonsForProductionStageExecutionDelays",
		SubsystemDetails.Name);
		
	Common.AddRenaming(Total,
		"2.1.1.56",
		"Role.ReadReasonsForOperationSheetsExecutionDelays",
		"Role.ReadReasonsForProductionStagesExecutionDelays",
		SubsystemDetails.Name);
		
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region FillingInEmptyIB

// Handler for the first launch of the up (ERP).
//
Procedure FirstRun() Export
	
	Catalogs.ProductCostElements.SetUpArticleCalculationOfPredefinedItems();
	Catalogs.FinancialAccountingChartsOfAccounts.CreateInternationalChartOfAccountsFirstRun();
	
EndProcedure

Procedure UpgradingKaToERP() Export
	
	Catalogs.ProductCostElements.SetUpArticleCalculationOfPredefinedItems();
	ProductionServer.EstablishUseOfParameterizationOfResourceSpecifications();
	ProductionServer.SetOptionsForWorkingWithProductionOperations();
	Constants.StartDateOfAccountingForOutputByOperations.Set(Date("19800101"));
	
	ConstantValues = New Structure;
	ConstantValues.Insert("ComplexAutomation", False);
	ConstantValues.Insert("EnterpriseManagement", True);

	#Region Assignment_options
	ConstantValues.Insert(Metadata.Constants.OptionOfMaterialAssignmentInProduction.Name,             Enums.OptionsOfMaterialAssignmentInProduction.ProductionOrder);
	ConstantValues.Insert(Metadata.Constants.OptionOfMaterialAssignmentInRM.Name,                 Enums.OptionsOfMaterialAssignmentInRM.RMOrder);
	ConstantValues.Insert(Metadata.Constants.OptionOfMaterialAssignmentUponSubcontractingServicesDelivered.Name,     Enums.AssignmentAtSubcontractingServicesDelivered.ContractWithMaterialProviderForProcessing);
	ConstantValues.Insert(Metadata.Constants.OptionOfManufacturedProductAssignmentUponSubcontractingServicesDelivered.Name,      Enums.AssignmentAtSubcontractingServicesDelivered.ContractWithMaterialProviderForProcessing);
	#EndRegion
	
	For Each KeyAndValue In ConstantValues Do
		Constants[KeyAndValue.Key].Set(KeyAndValue.Value);
	EndDo; 
	
	RefreshReusableValues();
	
EndProcedure

Procedure UpdatingUTToERP() Export
	
	ChartsOfCharacteristicTypes.BudgetFlowItemDimensions.FillInPredefinedBudgetItemAnalytics();
	Constants.AssetLiabilityRecordsArePopulated.Set(True);
	Constants.StartDateOfAccountingForOutputByOperations.Set(Date("19800101"));
	
	InfobaseUpdateTM.FillInValueOfSeparationByDataAreas();
	
	ConstantValues = New Structure;
	ConstantValues.Insert("TradeManagement", False);
	ConstantValues.Insert("EnterpriseManagement", True);
	
	#Region Assignment_options
	ConstantValues.Insert(Metadata.Constants.SubcontractorOptionOfAssignment2_5.Name,                   Enums.OptionsOfAssignmentDuringTransferToProcessing.DoNotAssign);
	ConstantValues.Insert(Metadata.Constants.OptionOfAssignmentAtTransferToSubcontractor2_5.Name,           Enums.OptionsOfAssignmentDuringTransferToProcessing.SubcontractOrder);
	ConstantValues.Insert(Metadata.Constants.OptionOfMaterialAssignmentInProduction.Name,             Enums.OptionsOfMaterialAssignmentInProduction.ProductionOrder);
	ConstantValues.Insert(Metadata.Constants.OptionOfMaterialAssignmentWhenTransferringToProduction.Name,  Enums.OptionsOfMaterialAssignmentWhenTransferringToProduction.AssignmentRecipient);
	ConstantValues.Insert(Metadata.Constants.OptionOfMaterialAssignmentInRM.Name,                 Enums.OptionsOfMaterialAssignmentInRM.RMOrder);
	ConstantValues.Insert(Metadata.Constants.OptionOfMaterialAssignmentUponSubcontractingServicesDelivered.Name,     Enums.AssignmentAtSubcontractingServicesDelivered.ContractWithMaterialProviderForProcessing);
	ConstantValues.Insert(Metadata.Constants.OptionOfManufacturedProductAssignmentUponSubcontractingServicesDelivered.Name,      Enums.AssignmentAtSubcontractingServicesDelivered.ContractWithMaterialProviderForProcessing);
	#EndRegion
	
	For Each KeyAndValue In ConstantValues Do
		Constants[KeyAndValue.Key].Set(KeyAndValue.Value);
	EndDo; 
	
	RefreshReusableValues();
	
EndProcedure

#EndRegion

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure WhenAddingUPUpdateHandlers(Handlers) Export

#Region FirstRun

	Handler = Handlers.Add();
	Handler.Procedure = "InfobaseUpdatePM.FirstRun";
	Handler.Version = "";
	Handler.ExecutionMode = "Exclusively";
	Handler.InitialFilling = True;
	Handler.Comment = "";

#EndRegion


#Region SetConstantToUseCategoriesOfEmployeeWorkRates
	
	Handler = Handlers.Add();
	Handler.Procedure = "InfobaseUpdatePM.SetConstantToUseCategoriesOfEmployeeWorkRates";
	Handler.Version = "2.5.24.23";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("9c48fee9-15ad-486b-8b8b-21b56fd73e33");
	Handler.UpdateDataFillingProcedure = "InfobaseUpdatePM.RegisterDataForConstantUpdates";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Comment = NStr("vi = 'Đặt giá trị hằng ""Sử dụng cấp bậc để trả công cho nhân viên"".';
							|ru = 'Устанавливает значение константы ""Использовать разряды расценок работ сотрудников"".';
							|en = 'Sets the value of the ""Use labor grades of employee activity rates"" constant.'; fa = 'Sets the value of the ""Use labor grades of employee activity rates"" constant.';
							|it = 'Sets the value of the ""Use labor grades of employee activity rates"" constant.';
							|pl = 'Sets the value of the ""Use labor grades of employee activity rates"" constant.';
							|tr = '""Çalışanların iş ücret tarifelerinin derecesini kullan"" sabitinin değerini ayarlar.'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.InformationRegisters.EmployeeActivityRates.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Constants.UseLaborGradesOfEmployeeActivityRates.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
#EndRegion

EndProcedure

#EndRegion


#Region SettingConstant_UseCategoriesOfEmployeeWorkRates

Procedure SetConstantToUseCategoriesOfEmployeeWorkRates(ParametersOfUpdate) Export
	
	If Constants.UseLaborGradesOfEmployeeActivityRates.Get() Then
		ParametersOfUpdate.ProcessingCompleted = True;
		Return;
	EndIf;
	
	Query = New Query("
	|SELECT TOP 1
	|	Rates.WorkKind AS WorkKind
	|FROM
	|	InformationRegister.EmployeeActivityRates AS Rates
	|WHERE
	|	Rates.LaborGrade <> VALUE(Catalog.LaborGrades.EmptyRef)");
	
	SelectionDetailRecords = Query.Execute().Select();
	
	If SelectionDetailRecords.Next() Then
		Constants.UseLaborGradesOfEmployeeActivityRates.Set(True);
	EndIf;
	
	ParametersOfUpdate.ProcessingCompleted = True;
	
EndProcedure

#EndRegion

// Empty registration handler
Procedure RegisterDataForConstantUpdates(ParametersOfUpdate) Export
	
	// Registration is not required
	Return;
	
EndProcedure

#EndRegion
