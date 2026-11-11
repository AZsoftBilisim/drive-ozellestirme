////////////////////////////////////////////////////////////////////////////////
// Updating the information base of the Trade Management Library.
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
	
	LongDesc.Name    = "TradeManagement" + ?(StandardSubsystemsServer.IsBaseConfigurationVersion(), "Basic", "");
	LongDesc.Version = "11.5.27.61";
	LongDesc.DeferredHandlersExecutionMode = "Parallel";
	LongDesc.OnlineSupportID = ?(StandardSubsystemsServer.IsBaseConfigurationVersion(), "TradeBase", "Trade");
	
EndProcedure

#EndRegion

#Region InfobaseUpdateHandlers

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export
	
	InfobaseUpdateTM.WhenAddingUTUpdateHandlers(Handlers);
	
	GoodsDelivery.OnAddUpdateHandlers(Handlers);
	MonthEndTransactionsServer.OnAddUpdateHandlers(Handlers);

	UserNotificationsOfEvents.OnAddUpdateHandlers(Handlers);
	OnlineARAPAccountingServer.WhenAddingHandlerForSwitchingToNewSettlementArchitecture(Handlers);
	DocumentsPosting.OnAddUpdateHandlers(Handlers);
	
	Documents.GoodsQualityControlCertificate.OnAddUpdateHandlers(Handlers);
	Documents.DiscrepancyReportFollowingReceipt.OnAddUpdateHandlers(Handlers);
	Documents.ApplicationForBusinessTrip.OnAddUpdateHandlers(Handlers);
	Documents.SaleAdjustment.OnAddUpdateHandlers(Handlers);
	Documents.DiscrepancyReportFollowingShipment.OnAddUpdateHandlers(Handlers);
	Documents.GoodsReceiptNote.OnAddUpdateHandlers(Handlers);
	Documents.WriteOffOfShippedGoods.OnAddUpdateHandlers(Handlers);
	Documents.WriteOffDiscrepanciesBetweenReceiptAndPurchase.OnAddUpdateHandlers(Handlers);
	Documents.PurchaseOrder.OnAddUpdateHandlers(Handlers);
	Documents.PurchaseAdjustment.OnAddUpdateHandlers(Handlers);
	Documents.ReceivedTaxInvoicePrepayment.OnAddUpdateHandlers(Handlers);
	Documents.ARAPSettlement.OnAddUpdateHandlers(Handlers);
	Documents.VendorInvoice.OnAddUpdateHandlers(Handlers);
	Documents.TransferOrder.OnAddUpdateHandlers(Handlers);
	Documents.GoodsShipmentToCustomer.OnAddUpdateHandlers(Handlers);
	Documents.PaymentRequest.OnAddUpdateHandlers(Handlers);
	Documents.BankAccountIssue.OnAddUpdateHandlers(Handlers);
	
	Constants.UseShipmentWithDeferredTransferOfTitle.OnAddUpdateHandlers(Handlers);
	Constants.MonthEndClosingSettings.OnAddUpdateHandlers(Handlers);
	
	Documents.ElectronicTicketTransaction.OnAddUpdateHandlers(Handlers);
	
	ChartsOfCharacteristicTypes.AssetLiabilityItems.OnAddUpdateHandlers(Handlers);
	ChartsOfCharacteristicTypes.ExpenseItems.OnAddUpdateHandlers(Handlers);
	
	InformationRegisters.DatesOfCompanyGoodsReceipt.OnAddUpdateHandlers(Handlers);
	InformationRegisters.ExcisableGoodsCategories.OnAddUpdateHandlers(Handlers);
	
	InformationRegisters.DocumentsRegistry.OnAddUpdateHandlers(Handlers);
	AccumulationRegisters.PurchaseOrders.OnAddUpdateHandlers(Handlers);
	AccumulationRegisters.CashFlowPlansCustomers.OnAddUpdateHandlers(Handlers);
	AccumulationRegisters.CashFlowPlansVendors.OnAddUpdateHandlers(Handlers);
	AccumulationRegisters.GoodsForRegistrationOfSurplusesAndShortages.OnAddUpdateHandlers(Handlers);
	AccumulationRegisters.GoodsForIssue.OnAddUpdateHandlers(Handlers);
	AccumulationRegisters.GoodsToReceive.OnAddUpdateHandlers(Handlers);
	AccumulationRegisters.ProductStock.OnAddUpdateHandlers(Handlers);
	AccumulationRegisters.InventoryAndDemands.OnAddUpdateHandlers(Handlers);
	
	InformationRegisters.InventoryAllocation.OnAddUpdateHandlers(Handlers);
	InformationRegisters.AvailableStockBalances.OnAddUpdateHandlers(Handlers);
	InformationRegisters.PurchaseOrderStates.OnAddUpdateHandlers(Handlers);
	
	AccumulationRegisters.BankAccountCash.OnAddUpdateHandlers(Handlers);
	AccumulationRegisters.CashAccountBalance.OnAddUpdateHandlers(Handlers);
	
	AccumulationRegisters.ShipmentAndReturnReferences.OnAddUpdateHandlers(Handlers);
	AccumulationRegisters.CustomersARAPAccounting.OnAddUpdateHandlers(Handlers);
	AccumulationRegisters.VendorsARAPAccounting.OnAddUpdateHandlers(Handlers);
	AccumulationRegisters.CustomersARAPAccountingByDueDates.OnAddUpdateHandlers(Handlers);
	AccumulationRegisters.VendorsARAPAccountingByDueDates.OnAddUpdateHandlers(Handlers);
	AccumulationRegisters.FinancialInstrumentsARAP.OnAddUpdateHandlers(Handlers);
	
	InformationRegisters.JobsForAllocatingARAP.OnAddUpdateHandlers(Handlers);
	InformationRegisters.JobsOfBackdateAdditionalDocumentPosting.OnAddUpdateHandlers(Handlers);
	InformationRegisters.PerformMonthEndClosingOperations.OnAddUpdateHandlers(Handlers);
	AccumulationRegisters.OtherIncome.OnAddUpdateHandlers(Handlers);
	InformationRegisters.JobsForMonthEndClosing.OnAddUpdateHandlers(Handlers);
	InformationRegisters.FinancialAccountingPolicy.OnAddUpdateHandlers(Handlers);
	InformationRegisters.ItemsBarcodes.OnAddUpdateHandlers(Handlers);
	InformationRegisters.GoodsIssueNoteReregistrationQueue.OnAddUpdateHandlers(Handlers);
	InformationRegisters.ScheduleOfPayments.OnAddUpdateHandlers(Handlers);
	
	Catalogs.BackdateJobKinds.OnAddUpdateHandlers(Handlers);
	Catalogs.BusinessTransactionsSettings.OnAddUpdateHandlers(Handlers);
	Catalogs.ARAPObjects.OnAddUpdateHandlers(Handlers);
	Catalogs.TypesOfPrices.OnAddUpdateHandlers(Handlers);
	Catalogs.CCDNumbers.OnAddUpdateHandlers(Handlers);
	
	AccumulationRegisters.RevenueAndCOGS.OnAddUpdateHandlers(Handlers);
	AccumulationRegisters.OtherAssetsLiabilities.OnAddUpdateHandlers(Handlers);
	
	AccumulationRegisters.RegisterRecordsByExcises.OnAddUpdateHandlers(Handlers);
	
	Catalogs.InventoryKinds.OnAddUpdateHandlers(Handlers);
	Catalogs.ItemKinds.OnAddUpdateHandlers(Handlers);
	Catalogs.Companies.OnAddUpdateHandlers(Handlers);
	Catalogs.Counterparties.OnAddUpdateHandlers(Handlers);
	Catalogs.ControlledLots.OnAddUpdateHandlers(Handlers);
	Catalogs.Partners.OnAddUpdateHandlers(Handlers);
	Catalogs.Warehouses.OnAddUpdateHandlers(Handlers);
	Catalogs.BusinessStructure.OnAddUpdateHandlers(Handlers);
	Catalogs.LinesOfBusiness.OnAddUpdateHandlers(Handlers);
	Catalogs.InventoryAccountingGroups.OnAddUpdateHandlers(Handlers);
	Catalogs.FinancialAccountingGroupsOfARAP.OnAddUpdateHandlers(Handlers);
	Catalogs.IncomeExpensesAccountingGroups.OnAddUpdateHandlers(Handlers);
	Catalogs.GroupsOfFinancialAccountingOfCash.OnAddUpdateHandlers(Handlers);
	Catalogs.AnalyticalInventoryGroups.OnAddUpdateHandlers(Handlers);
	Catalogs.Projects.OnAddUpdateHandlers(Handlers);
	Catalogs.OperationCategories.OnAddUpdateHandlers(Handlers);
	Catalogs.TaxContributionKinds.OnAddUpdateHandlers(Handlers);
	Catalogs.MonthEndClosingOperations.OnAddUpdateHandlers(Handlers);
	Catalogs.GoodsLockReasons.OnAddUpdateHandlers(Handlers);
	Catalogs.TermsOfPurchaseFromVendors.OnAddUpdateHandlers(Handlers);
	Catalogs.DiscountsMarkups.OnAddUpdateHandlers(Handlers);
	Catalogs.DiscountMarkupTerms.OnAddUpdateHandlers(Handlers);
	Catalogs.CounterpartyContracts.OnAddUpdateHandlers(Handlers);
	Catalogs.MasterDataDuplicateSearchRules.OnAddUpdateHandlers(Handlers);
	
	Planning.OnAddUpdateHandlers(Handlers);
	
	
	InformationRegisters.SetUpAllocationByLinesOfBusiness.OnAddUpdateHandlers(Handlers);
	
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
	
	OutputUpdatesDetails = Not GetFunctionalOption("EnterpriseManagement");
	
	ServerStartupParameter = SessionParameters.ClientParametersAtServer.Get("LaunchParameter");
	If ServerStartupParameter<>Undefined Then
		If Find(ServerStartupParameter,"Trade103Data")<>0 Then
			OutputUpdatesDetails = False;
		EndIf;
	EndIf;
	
	// After the End of the exclusive update, we notify the user if the outdated functionality is used.
	If ExclusiveMode Then
		DataProcessors.TransitionReadiness26.SetNotificationConstantForOutdatedFunctionality(True);
	EndIf;
	
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
	Handler.PreviousConfigurationName = "TradeManagementBasic";
	Handler.Procedure = "InfobaseUpdateTM.UpgradeFromBasicVersionToPROF";
	
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
	
	If PreviousConfigurationName = "TradeManagementBasic" Then
		Parameters.ClearPreviousConfigurationInfo = False;
		Parameters.ConfigurationVersion = PreviousConfigurationVersion;
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
	
EndProcedure

#EndRegion

#Region UniversalUpdateProcedures

// Used for recording movements
//
// Parameters:
//   RegisterManager - InformationRegistersManager - 
//   RegisterName - String - register name.
//   Ref  - DocumentRef - link to the document.
//   TablesForRegisteredRecords - Array - an array containing the table values with the movements that you want to record.
//   RegisterOnExchangePlanNodes - Boolean - enables registration of exchange plans on nodes when writing an object.
//
Procedure WriteRecordSet(RegisterManager, RegisterName, Ref, TablesForRegisteredRecords = Undefined, RegisterOnExchangePlanNodes = False) Export

	RecordSet = RegisterManager[RegisterName].CreateRecordSet(); // InformationRegisterRecordSet - 
	RecordSet.Filter.Recorder.Set(Ref);
	If TablesForRegisteredRecords <> Undefined Then
		RecordSet.Load(TablesForRegisteredRecords["Table" + RegisterName]);
	EndIf; 
	
	InfobaseUpdate.WriteData(RecordSet, RegisterOnExchangePlanNodes);
	
EndProcedure

// Used for recording movements
//
// Parameters:
//   ManagerOfRegisters                 - AccumulationRegisterManager, InformationRegisterManager -
//   RegisterNames                    - Array - an array containing the register names.
//   Ref                      	   - DocumentRef - link to the document.
//   TablesForRegisteredRecords                - Array - an array containing the table values with the movements that you want to record.
//   RegisterOnExchangePlanNodes - Boolean - enables registration of exchange plans on nodes when writing an object.
// 
Procedure WriteRecordSets(ManagerOfRegisters, RegisterNames, Ref, TablesForRegisteredRecords = Undefined, RegisterOnExchangePlanNodes = False) Export

	Registers = New Structure(RegisterNames);
	
	For Each Register In Registers Do
		WriteRecordSet(ManagerOfRegisters, Register.Key, Ref, TablesForRegisteredRecords, RegisterOnExchangePlanNodes);
	EndDo;
	
EndProcedure

/// Additional options Preservationsociety()
// 
// Returns:
//  Structure - structure with properties:
//      * IsIndependentInformationRegister - Boolean - in the Data parameter of the function, a table is passed with the values of the dimensions
//                                                 for which data should be updated. the default value is False.
//      * NameOfTheDimensionToSelect - String - name of the independent data register dimension that will
//                                          be selected for overwriting the document record set (similar to the Registrar for
//                                          registers that are subordinate to registrars).
//      * UpdatedData - QueryResultSelection, ValueTable - 
//      * PassAdditionalProperties - Boolean - indicates whether additional properties should be passed to the recordset.
//      * AdditionalRecordsetProperties - Undefined, Structure - structure of additional properties passed to the recordset.
//
Function AdditionalOptionsForOverwritingRegisteredRecordsFromQueue() Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("IsIndependentInformationRegister",False);
	AdditionalParameters.Insert("NameOfTheDimensionToSelect","");
	AdditionalParameters.Insert("OrderFields", New Array);
	AdditionalParameters.Insert("Manager", Undefined);
	AdditionalParameters.Insert("NeedAdditionalRecordProcessing", False);
	AdditionalParameters.Insert("WriteInSingleTransaction", False);
	AdditionalParameters.Insert("UpdatedData");
	AdditionalParameters.Insert("PassAdditionalProperties", False);
	AdditionalParameters.Insert("AdditionalRecordsetProperties", Undefined);
	
	Return AdditionalParameters;
	
EndFunction

// Based on the data on the need to reformulate the Registered Records, it overwrites the Registered Records of the document.
//	For the function to work, it is necessary that the procedure for initializing the document data of the document manager module supports the Registers parameter.
//	see, for example, Document.PrikhodnyOrderNaTovary.Initialize Document data.
//
// Parameters:
//  FullNamesOfDocuments				 - String, Array, Undefined - name of the document that you want to re-form movements for. For Example, " Document.Prednisoneonline"
//																If there are several documents, you need to pass their names in the array.
//																When processing an independent register, the information must be passed Undefined.
//  FullRegistersNames				 - String, Array - name of the register to use for re-forming movements. For Example, " Accumulation Register.Tourinclude"
//																If there are several registers, their names must be passed in the array.
//  Queue								 - Number - the queue of pending data processing for the control data for the lock to other processors
//  AdditionalParameters	 - See InfobaseUpdateTM.AdditionalOptionsForOverwritingRegisteredRecordsFromQueue.
// 
// Returns:
//  Boolean - TRUE if processing of all movements is completed.
//
Function OverwriteRegisteredRecordsFromQueue(FullNamesOfDocuments, FullRegistersNames, Queue, AdditionalParameters = Undefined) Export
	
	If AdditionalParameters = Undefined Then
		AdditionalParameters = AdditionalOptionsForOverwritingRegisteredRecordsFromQueue();
	EndIf;
	
	ThereSStillWorkToDo = False;
	IsIndependentInformationRegister = AdditionalParameters.IsIndependentInformationRegister;
	UpdatedData = AdditionalParameters.UpdatedData;
	ThereIsUpdatedData = UpdatedData <> Undefined;
	FieldNameLogger = ?(IsIndependentInformationRegister, AdditionalParameters.NameOfTheDimensionToSelect, "Recorder");
	Registers = RegisterNamesInArray(FullRegistersNames);
	DocumentsList = DocumentNamesInArray(FullNamesOfDocuments);
	If TypeOf(DocumentsList) = Type("Array") Then 
		DocumentsList.Add("Document.ReversingEntry"); // The reverse is registered for the update automatically if the one being reversed has registered.  
	EndIf;
	DocumentTypes = ArrayOfNamesInMatchingTypes(DocumentsList, "DocumentRef", 1);
	
	If IsIndependentInformationRegister Or ThereIsUpdatedData Then
		IterableListOfDocuments = New Array;
		IterableListOfDocuments.Add(Undefined);
	Else
		IterableListOfDocuments = DocumentsList;
	EndIf;
	
	If ThereIsUpdatedData
		And UpdatedData.DataSet.Count() > 0 Then
		
		ArrayOfLoggers = New Array;
		ArrayOfDocumentsWithStorno = New Array;
		
		For Each DataPortion In UpdatedData.DataSet Do
			
			CommonClientServer.SupplementArray(ArrayOfLoggers, DataPortion.Data.UnloadColumn(FieldNameLogger));
			For Each DataString1 In DataPortion.Data Do
				
				MetadataOfDocument = DataString1[FieldNameLogger].Metadata();
				If Not MetadataOfDocument.Attributes.Find("ReversedDocument") = Undefined Then
					
					ArrayOfDocumentsWithStorno.Add(DataString1[FieldNameLogger]);
					
				EndIf;
				
			EndDo;
			
		EndDo;
		
		AttributesOfCourse = Common.ObjectsAttributeValue(ArrayOfLoggers, "Posted");
		AttributesFromPage = Common.ObjectsAttributeValue(ArrayOfDocumentsWithStorno, "ReversedDocument");
		
	EndIf;
	
	For Each FullDocumentName In IterableListOfDocuments Do
		If Not IsIndependentInformationRegister And Not ThereIsUpdatedData Then
			If AdditionalParameters.Manager = Undefined Then
				ManagerOfDocument = Common.ObjectManagerByFullName(FullDocumentName);
			Else
				ManagerOfDocument = AdditionalParameters.Manager;
			EndIf;
		EndIf;
		
		For Each FullRegisterName In Registers Do
			RegisterName = StrSplit(FullRegisterName,".",False)[1];
			RegisterManager = Common.ObjectManagerByFullName(FullRegisterName); // InformationRegisterManager - 
			SelectionParameters = NewSelectionParameters();
			
			If ThereIsUpdatedData Then
				SamplingByRegistrars = Undefined;
				SelectionParameters.DocumentTypes = DocumentTypes;
				SelectionParameters.FieldNameLogger = FieldNameLogger;
			Else
				AdditionalParametersForProcessing = InfobaseUpdate.AdditionalProcessingDataSelectionParameters();
				
				If IsIndependentInformationRegister Then
					AdditionalDataSources = New Map;
					AdditionalDataSources.Insert(FieldNameLogger);
					AdditionalParametersForProcessing.AdditionalDataSources = AdditionalDataSources;
					AdditionalParametersForProcessing.OrderFields = AdditionalParameters.OrderFields;
					SamplingByRegistrars = InfobaseUpdate.SelectStandaloneInformationRegisterDimensionsToProcess(
						Queue,
						FullRegisterName,
						AdditionalParametersForProcessing);
				Else
					Sources = ManagerOfDocument.AdditionalDataSourcesForRegisteredRecords(RegisterName);
					AdditionalParametersForProcessing.AdditionalDataSources = Sources;
					SamplingByRegistrars = InfobaseUpdate.SelectRegisterRecordersToProcess(
						Queue,
						FullDocumentName,
						FullRegisterName,
						AdditionalParametersForProcessing);
				EndIf;
			EndIf;
			
			If AdditionalParameters.WriteInSingleTransaction Then
				BeginTransaction();
			EndIf;
			
			While NextSelectionOrRowOfValueTable(SamplingByRegistrars, UpdatedData, SelectionParameters) Do
				
				ReversedDocument = Undefined;
				
				If TypeOf(SamplingByRegistrars) = Type("QueryResultSelection") Then
					
					MetadataOfDocument = SamplingByRegistrars[FieldNameLogger].Metadata(); // MetadataObjectDocument - 
					If MetadataOfDocument.Attributes.Find("ReversedDocument") <> Undefined Then
						
						ReversedDocument = Common.ObjectAttributeValue(SamplingByRegistrars[FieldNameLogger], "ReversedDocument");
						
					EndIf;
					
				Else
					
					ReversedDocument = AttributesFromPage.Get(SamplingByRegistrars[FieldNameLogger]);
					
				EndIf;
				
				If IsIndependentInformationRegister And FullNamesOfDocuments <> Undefined Then
					
					If FullNamesOfDocuments.Find(SamplingByRegistrars[FieldNameLogger].Metadata().FullName()) = Undefined Then
						Continue;
					EndIf;
					
				EndIf;
				
				If Not IsIndependentInformationRegister 
					And ReversedDocument <> Undefined Then
					// If the Registered Records of the document being canceled have not yet been processed, then skip processing
					If ValueIsFilled(ReversedDocument)
						And InfobaseUpdate.HasDataToProcess(Queue, FullRegisterName, ReversedDocument) Then
						Continue;
					EndIf;
				EndIf;
				
				If Not GenerateAndRecordRegisteredRecords(
							SamplingByRegistrars[FieldNameLogger],
							FullRegisterName,
							RegisterManager,
							AdditionalParameters,
							FieldNameLogger,
							AttributesOfCourse) Then
							
					Return False;
				EndIf;
				
			EndDo;
			
			If AdditionalParameters.WriteInSingleTransaction Then
				Try
					CommitTransaction();
				Except
					RollbackTransaction();
					
					MessageText = NStr("vi = 'Không thể cam kết lưu chuyển hồ sơ giao dịch trong đăng ký %RegisterName% vì: %Cause%';
										|ru = 'Не удалось зафиксировать транзакцию записи движения в регистр %RegisterName% по причине: %Cause%';
										|en = 'Cannot commit a transaction for saving record to register %RegisterName%. Reason:%Cause%'; fa = 'Cannot commit a transaction for saving record to register %RegisterName%. Reason:%Cause%';
										|it = 'Impossibile eseguire il commit della transazione del record di movimento nel registro %RegisterName% perché: %Cause%';
										|pl = 'Nie udało się zarejestrować transakcję zapisu ruchu do rejestru %RegisterName% z powodu: %Cause%';
										|tr = 'Hareket kaydı işlemi %RegisterName% kaydına işlenemedi çünkü: %Cause%'");
					MessageText = StrReplace(MessageText, "%Cause%", DetailErrorDescription(ErrorInfo()));
					MessageText = StrReplace(MessageText, "%RegisterName%", FullRegisterName);
					
					WriteLogEvent(InfobaseUpdate.EventLogEvent(),
												EventLogLevel.Warning,
												Metadata.FindByFullName(FullRegisterName),
												,
												MessageText);
						
					Return False;
				EndTry;
			EndIf;	
			
			
			If Not ThereSStillWorkToDo
				And InfobaseUpdate.HasDataToProcess(Queue, FullRegisterName) Then 
				ThereSStillWorkToDo = True;
			EndIf;
			If IsIndependentInformationRegister Then
				Break;
			EndIf;
		EndDo;
		
	EndDo;
	
	AllDone_ = Not ThereSStillWorkToDo;
	Return AllDone_;
	
EndFunction

// Adapts the request of the execution mechanism for use in the update information database function.Registratorsreferences,
// making it a request for all documents held.
// Parameters:
//  OriginalRequestText - String - the text of the query of the holding mechanism that either forms the table of movements, or
//										creates temporary tables used in the queries of the table-forming movements.
//										See InfobaseUpdateTM.ResultOfRequestAdaptation
//										The requirements for the request text are as follows.
//										  Combine all tables in the query that generates the table of the movements have the same synonym.
//										  If there are connections to other tables, then it is implemented in such a way 
//											that it will work correctly if the selection by reference is not set;
//										  Temporary tables are not used;
//										  Nested queries and groupings are not used;
//										  There is no ordering;
//										  the request parameters are calculated either from the header data, or are the values of constants;
// 										  For all fields of non-primitive types, the default values are filled in, as they are stored in the register;
//											this is either an empty type reference, or UNDEFINED (for fields of a composite type), then there should NOT be a NULL
//										  parameter setting the selection by reference called &Reference;
//										  There should be no sign at the end of the request ";"
// 										  In the query text that forms the movement table, only the fields that are significant
//											for the formation of movements should be selected (there are no fields for Line numbers, Order, etc.).
//  FullDocumentName				 - String - the full name of the document, as specified in the query language (for example, Document.Input of aggregates)
//  SynonymForDocumentTable			 - String - synonym of the document table used in the query
//  RedefiningParameterCalculation - Structure - by default, all parameters that are in the request are replaced with <Synonym of Document table>.The link.<Parameter Name>
//  												For the &Period parameter, <Synonym of Document Table> is substituted by default.The link.Date
//  												If the parameters are calculated differently, then in this structure the parameter name is passed in the key, in the value
//													  of the expression for its calculation.
//  TemporaryTableQueryTexts     - Map of KeyAndValue - query texts of temporary tables used in the query text
//                                                    of the execution engine.
//													  The match key is the name of the temporary table, and the Value is the text of the temporary table request.
//													  This parameter should be used when the motion generation mechanism relies on a
//													  pre-created temporary table rather than a physical table in the document.
//													  The temporary table selection fields must contain the "Link" field, which is a link to the physical table of the document being held.
//													  Nested temporary tables are not supported.
//
// Returns:
//  String - adapted text of the request.
//
Function AdaptRequestOfHoldingMechanism(Val OriginalRequestText,
														FullDocumentName,
														SynonymForDocumentTable,
														RedefiningParameterCalculation = Undefined,
														TemporaryTableQueryTexts = Undefined) Export
														
	If RedefiningParameterCalculation = Undefined Then
		RedefiningParameterCalculation = New Structure;
	EndIf;
	
	If StrFind(OriginalRequestText, "AS Recorder,") = 0 Then // @query-part
		
		OriginalRequestText = StrReplace(OriginalRequestText,
											"SELECT",
											"SELECT
											|	DocumentTableUpdatingInformationSecurity.Ref AS Recorder,");  //@query-part-1 @query-part-2
		
	EndIf;
				
	OriginalRequestText = StrReplace(OriginalRequestText,
										"WHERE",
										"
										|WHERE
										|	DocumentTableUpdatingInformationSecurity.Ref.Posted
										|	AND ");
	
	If TemporaryTableQueryTexts <> Undefined Then
		
		For Each Item In TemporaryTableQueryTexts Do
			
			For Each AnotherElement In TemporaryTableQueryTexts Do
				
				If Item.Key <> AnotherElement.Key Then
					
					If StrFind(AnotherElement.Value, Item.Key) <> 0 Then
						Raise NStr("vi = 'Văn bản yêu cầu thích nghi. Các bảng tạm thời lồng nhau không được hỗ trợ.';
									|ru = 'Адаптированный текст запроса. Вложенные временные таблицы не поддерживаются.';
									|en = 'Adapted query text. Nested temporary tables are not supported.'; fa = 'Adapted query text. Nested temporary tables are not supported.';
									|it = 'Testo di query personalizzato. Le tabelle temporanee nidificate non sono supportate.';
									|pl = 'Adaptowany tekst zapytania. Załączone tymczasowe tabele nie są obsługiwane.';
									|tr = 'Uyarlanmış sorgu metni. İç içe geçici tablolar desteklenmiyor.'");
					EndIf;
					
				EndIf;
				
			EndDo;
			
		EndDo;
		
		For Each Item In TemporaryTableQueryTexts Do
			SubstitutionOfTemporaryTable = ConvertTemporaryTableToNestedQuery(Item.Key, Item.Value);
			OriginalRequestText = StrReplace(OriginalRequestText, Item.Key, SubstitutionOfTemporaryTable);
		EndDo;
		
	EndIf;
	
	OriginalRequestText = StrReplace(OriginalRequestText,SynonymForDocumentTable,"DocumentTableUpdatingInformationSecurity");
	OriginalRequestText = StrReplace(OriginalRequestText,"DocumentTableUpdatingInformationSecurity.Ref = &Ref","TRUE");
	OriginalRequestText = StrReplace(OriginalRequestText,
											"DocumentTableUpdatingInformationSecurity.Ref IN (&Ref)",
											"TRUE");
	
	Query = New Query;
	Query.Text = OriginalRequestText;
	
	// The request parameters need to be ordered by name in reverse order,
	// because their names can start the same way, for example, "Number", "Print number".
	QueryOptions = New ValueList;
	For Each QueryParameter In Query.FindParameters() Do
		QueryOptions.Add(QueryParameter.Name);
	EndDo; 
	QueryOptions.SortByValue(SortDirection.Desc);
	
	MetadataOfDocument = Metadata.FindByFullName(FullDocumentName);
	
	For Each Parameter In QueryOptions Do
		
		ReplacementText = Undefined;
		
		If RedefiningParameterCalculation.Property(Parameter.Value) Then
			ReplacementText = RedefiningParameterCalculation[Parameter.Value];
			ReplacementText = StrReplace(ReplacementText, SynonymForDocumentTable, "DocumentTableUpdatingInformationSecurity");
		ElsIf Parameter.Value = "Ref" Then
			ReplacementText = "DocumentTableUpdatingInformationSecurity.Ref";
		ElsIf Parameter.Value = "Period" Then
			ReplacementText = "DocumentTableUpdatingInformationSecurity.Ref.Date";
		ElsIf MetadataOfDocument.Attributes.Find(Parameter.Value) <> Undefined
			Or Parameter.Value = "Posted"
			Or Parameter.Value = "DeletionMark"
			Or Parameter.Value = "Number"
			Or Parameter.Value = "Date" Then
			ReplacementText = "DocumentTableUpdatingInformationSecurity.Ref." + Parameter.Value;
		EndIf;	
		
		If ReplacementText <> Undefined Then
			OriginalRequestText = StrReplace(OriginalRequestText,"&" + Parameter.Value, ReplacementText);
		EndIf;
			
	EndDo;
	
	Return OriginalRequestText;
	
EndFunction

// Adapts the query of the independent register search engine.
// The result of the function is used in the data of the independent register for the transfer().
//
// Parameters:
//  OriginalRequestText			 - String - the text of the request for the holding mechanism that forms the table of movements.
//  FullDocumentName				 - String - the full name of the document, as specified in the query language (for example, Document.Input of aggregates)
//  SynonymForDocumentTable			 - String - synonym of the document table used in the query
//  RequestHasSource			 - Boolean - True if the request describes the source
//  RedefiningParameterCalculation - Structure - by default, all parameters that are in the request are replaced with < synonym of the document Table>.Link.<Parameter name>
//  												The &Period parameter is set to <synonym of the document Table>by default.Link.Date
//  												If the parameters are calculated differently, the parameter name is passed in the key in this structure, and the expression for its calculation is passed in the value.
//  TemporaryTableQueryTexts     - Map - query texts of temporary tables used in the query text
//                                                    of the execution engine.
//													  The match key is the name of the temporary table, and the Value is the text of the temporary table request.
//													  This parameter should be used when the motion generation mechanism relies on a
//													  pre-created temporary table rather than a physical table in the document.
//													  The temporary table selection fields must contain the "Link" field, which is a link to the physical table of the document being held.
//													  Nested temporary tables are not supported.
// 
// Returns:
//  String - adapted query text that can be executed for all documents.
//
Function AdaptRequestForIndependentRegister(Val OriginalRequestText,
														FullDocumentName,
														SynonymForDocumentTable,
														RequestHasSource,
														RedefiningParameterCalculation = Undefined,
														TemporaryTableQueryTexts = Undefined) Export
	
	If RedefiningParameterCalculation = Undefined Then
		RedefiningParameterCalculation = New Structure;
	EndIf;
	
	If Not RequestHasSource Then
		
		OriginalRequestText = OriginalRequestText + "
		|FROM
		|	" + FullDocumentName + " AS DocumentTableUpdatingInformationSecurity";
		
	EndIf;
	
	If TemporaryTableQueryTexts <> Undefined Then
		
		For Each Item In TemporaryTableQueryTexts Do
			
			For Each AnotherElement In TemporaryTableQueryTexts Do
				
				If Item.Key <> AnotherElement.Key Then
					
					If StrFind(AnotherElement.Value, Item.Key) <> 0 Then
						Raise NStr("vi = 'Văn bản yêu cầu thích nghi. Các bảng tạm thời lồng nhau không được hỗ trợ.';
									|ru = 'Адаптированный текст запроса. Вложенные временные таблицы не поддерживаются.';
									|en = 'Adapted query text. Nested temporary tables are not supported.'; fa = 'Adapted query text. Nested temporary tables are not supported.';
									|it = 'Testo di query personalizzato. Le tabelle temporanee nidificate non sono supportate.';
									|pl = 'Adaptowany tekst zapytania. Załączone tymczasowe tabele nie są obsługiwane.';
									|tr = 'Uyarlanmış sorgu metni. İç içe geçici tablolar desteklenmiyor.'");
					EndIf;
					
				EndIf;
				
			EndDo;
			
		EndDo;
		
		For Each Item In TemporaryTableQueryTexts Do
			SubstitutionOfTemporaryTable = ConvertTemporaryTableToNestedQuery(Item.Key, Item.Value);
			OriginalRequestText = StrReplace(OriginalRequestText, Item.Key, SubstitutionOfTemporaryTable);
		EndDo;
		
	EndIf;
	
	OriginalRequestText = StrReplace(OriginalRequestText,SynonymForDocumentTable,"DocumentTableUpdatingInformationSecurity");
	OriginalRequestText = StrReplace(OriginalRequestText,"DocumentTableUpdatingInformationSecurity.Ref = &Ref","TRUE");
	OriginalRequestText = StrReplace(OriginalRequestText,
											"DocumentTableUpdatingInformationSecurity.Ref IN (&Ref)",
											"TRUE");
	OriginalRequestText = StrReplace(OriginalRequestText,"DocumentTableUpdatingInformationSecurity.Comment",
		"CAST(DocumentTableUpdatingInformationSecurity.Ref.Comment AS STRING (100))");
	
	Query = New Query;
	Query.Text = OriginalRequestText;
	
	// The request parameters need to be ordered by name in reverse order,
	// because their names can start the same way, for example, "Number", "Print number".
	QueryOptions = New ValueList;
	For Each QueryParameter In Query.FindParameters() Do
		QueryOptions.Add(QueryParameter.Name);
	EndDo; 
	QueryOptions.SortByValue(SortDirection.Desc);
	
	MetadataOfDocument = Metadata.FindByFullName(FullDocumentName);
	
	For Each Parameter In QueryOptions Do
		
		ReplacementText = Undefined;
		
		If RedefiningParameterCalculation.Property(Parameter.Value) Then
			ReplacementText = RedefiningParameterCalculation[Parameter.Value];
			ReplacementText = StrReplace(ReplacementText, SynonymForDocumentTable, "DocumentTableUpdatingInformationSecurity");
		ElsIf Parameter.Value = "NumberForPrinting" Then
			ReplacementText = """""";
		ElsIf Parameter.Value = "Ref" Then
			ReplacementText = "DocumentTableUpdatingInformationSecurity.Ref";
		ElsIf Parameter.Value = "Comment" Then
			ReplacementText = "CAST(DocumentTableUpdatingInformationSecurity.Ref.Comment AS STRING (100))";
		ElsIf Parameter.Value = "Period" Then
			ReplacementText = "DocumentTableUpdatingInformationSecurity.Ref.Date";
		ElsIf MetadataOfDocument.Attributes.Find(Parameter.Value) <> Undefined 
			Or Parameter.Value = "Posted"
			Or Parameter.Value = "DeletionMark"
			Or Parameter.Value = "Number"
			Or Parameter.Value = "Date" Then
			ReplacementText = "DocumentTableUpdatingInformationSecurity.Ref." + Parameter.Value;
		EndIf;	
		
		If ReplacementText <> Undefined Then
			OriginalRequestText = StrReplace(OriginalRequestText,"&" + Parameter.Value, ReplacementText);
		EndIf;
		
	EndDo;
	
	Return OriginalRequestText;
	
EndFunction

// Result of adapting the request for the update informationbase function.Registratorsreferences.
// 
// Returns:
//  Structure - Fields:
//	* QueryText - String - must be declared necessarily, adapted from the text of the query
//	* ParameterValues - Structure - values of query parameters that are calculated from constants
//										(do not depend on a specific document).
//
Function ResultOfRequestAdaptation() Export
	
	ResultOfRequestAdaptation = New Structure;
	ResultOfRequestAdaptation.Insert("QueryText");
	ResultOfRequestAdaptation.Insert("ParameterValues", New Structure);
	
	Return ResultOfRequestAdaptation;
EndFunction

// Selects the registrars for which the Registered Recorded movements in the register differ from those 
// generated by the request of the holding mechanism.
//  
// Parameters:
//  ResultOfRequestAdaptation - See ResultOfRequestAdaptation.
// 		Requirements for requests:
// 			* The text should not contain references to temporary tables.
//			* All queries must be adapted for selection without selection by reference.
//			You can do this by using the Update Information Database functionut.Adapt the query mechanism 
//			if the query text meets its conditions. If not, you can try to adapt the text yourself.
// 			* in the query text forming the movement table, only fields that are SIGNIFICANT
//			for the formation of movements should be selected (there are no line number fields, Order, etc.);
// 			* there is no ordering; 
// 			* there is a "Registrar" field. 
//  FullRegisterName  - String - The full name of the register, as specified in the query language (for example, accumulation Register.Tourinclude)
//  FullDocumentName - String - the full name of the document, as it is set in the query language (for example, Document.Input of inputs).
//  UnusedFields - Array of String - A list of fields that do not need to be checked for data matches.
//
// Returns:
//  Array of DocumentRef - an array of links to documents for which you need to reformulate movements by register.
//
Function CallLoggers(ResultOfRequestAdaptation,
										FullRegisterName,
										FullDocumentName,
										UnusedFields = Undefined) Export
	
	Queue = Undefined;
	TextOfMotionGenerationRequest = ResultOfRequestAdaptation.QueryText;
	ParameterValues = ResultOfRequestAdaptation.ParameterValues;
	
	PartsOfRegisterName = StrSplit(FullRegisterName, ".", False);
	
	RegisterType_ = PartsOfRegisterName[0];
	RegisterName = PartsOfRegisterName[1];
	
	If RegisterType_ = "AccumulationRegister"
		Or RegisterType_ = "InformationRegister" Then
		RegisterMetadata = Metadata.FindByFullName(FullRegisterName);
	Else
		ExceptionText = NStr("vi = 'Hàm này chưa hỗ trợ làm việc với các biểu ghi loại %RegisterType_%.';
							|ru = 'Функция пока не поддерживает работу с регистрами типа %RegisterType_%.';
							|en = 'Function does not support operations with registers of type %RegisterType_%.'; fa = 'Function does not support operations with registers of type %RegisterType_%.';
							|it = 'La funzione non supporta ancora i registri di tipo %RegisterType_%.';
							|pl = 'Funkcja na razie nie obsługuje pracę z rejestrami typu %RegisterType_%.';
							|tr = 'İşlev henüz %RegisterType_% tipindeki kayıtlarla çalışmayı desteklenmiyor.'");
		ExceptionText = StrReplace(ExceptionText, "%RegisterType_%", RegisterType_);
		Raise ExceptionText;
	EndIf;
		
	RegisterText = "";
	
	SummaryQuerySelectionText = "";
	TextOfSummationQueryDimension = "
	|";	
	TextOfSummationRequestCondition = "
	|HAVING
	|	FALSE";	
	
	If RegisterType_ = "InformationRegister" Then
		TextOfMotionGenerationRequest = StrReplace(TextOfMotionGenerationRequest,
											"SELECT",
											"SELECT
											|	1 AS InformationSecurityUpdateControlField,");  //@query-part-1 @query-part-2
		RegisterText = "
						|	-1,";

		SummaryQuerySelectionText = "
										|	SUM(InformationSecurityUpdateControlField) AS InformationSecurityUpdateControlField,";
		TextOfSummationRequestCondition = TextOfSummationRequestCondition + "
		| OR SUM(InformationSecurityUpdateControlField) <> 0";
	EndIf;
	
	
	QuerySchema = New QuerySchema;
	QuerySchema.SetQueryText(TextOfMotionGenerationRequest);
	
	Query = QuerySchema.QueryBatch[0];
	
	AllColumns = New Array;
	
	// Fields for which it is not necessary to check whether the data in the information security System matches the request data.
	If UnusedFields = Undefined Then
		UnusedFields = New Array;
	EndIf; 
	
	For Each Column In Query.Columns Do
		
		AllColumns.Add(Column.Alias);
		
		If RegisterType_ = "AccumulationRegister"
			And RegisterMetadata.Resources.Find(Column.Alias) <> Undefined Then		
			
			RegisterText = RegisterText + "
			|	-RegisterTable." + Column.Alias + ",";
			
			If UnusedFields.Find(Column.Alias) = Undefined Then
				
				SummaryQuerySelectionText = SummaryQuerySelectionText + "
				|	SUM(NestedQuery." + Column.Alias + ") AS " + Column.Alias + ",";
				
				TextOfSummationRequestCondition = TextOfSummationRequestCondition + "
				|	OR SUM(NestedQuery." + Column.Alias + ") <> 0";
				
			EndIf;
			
		ElsIf Not Column.Alias = "InformationSecurityUpdateControlField" Then
			
			RegisterText = RegisterText + "
			|	RegisterTable." + Column.Alias + ",";
			
			If UnusedFields.Find(Column.Alias) = Undefined Then
				
				SummaryQuerySelectionText = SummaryQuerySelectionText + "
				|	NestedQuery." + Column.Alias + " AS " + Column.Alias + ",";
				
				TextOfSummationQueryDimension = TextOfSummationQueryDimension + " 
				|	NestedQuery." + Column.Alias + ",";
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	TextRequestThatGeneratesTraffic = "";
	
	For Each Dimension In RegisterMetadata.Dimensions Do
		
		If AllColumns.Find(Dimension.Name) <> Undefined
			Or UnusedFields.Find(Dimension.Name) <> Undefined Then
			Continue;
		EndIf;
		
		RegisterText = RegisterText + "
		|	RegisterTable." + Dimension.Name + ",";
		
		SummaryQuerySelectionText = SummaryQuerySelectionText + "
		|	NestedQuery." + Dimension.Name + " AS " + Dimension.Name + ",";
		
		TextOfSummationQueryDimension = TextOfSummationQueryDimension + " 
		|	NestedQuery." + Dimension.Name + ",";
		
		TextRequestThatGeneratesTraffic = TextRequestThatGeneratesTraffic + "
		|	&EmptyValue" + Dimension.Name + " AS " + Dimension.Name + ",";
		
		ParameterValues.Insert("EmptyValue" + Dimension.Name, Dimension.Type.AdjustValue());
		
	EndDo;
	
	For Each Resource In RegisterMetadata.Resources Do
		
		If AllColumns.Find(Resource.Name) <> Undefined
			Or UnusedFields.Find(Resource.Name) <> Undefined Then
			Continue;
		EndIf;
		
		If RegisterType_ = "AccumulationRegister" Then
			RegisterText = RegisterText + "
			|	-RegisterTable." + Resource.Name + ",";
			
			SummaryQuerySelectionText = SummaryQuerySelectionText + "
			|	SUM(NestedQuery." + Resource.Name + ") AS " + Resource.Name + ",";
			
			TextOfSummationRequestCondition = TextOfSummationRequestCondition + "
			|	OR SUM(NestedQuery." + Resource.Name + ") <> 0";
			
			TextRequestThatGeneratesTraffic = TextRequestThatGeneratesTraffic + "
			|	0 AS " + Resource.Name + ",";
		Else	
			RegisterText = RegisterText + "
			|	RegisterTable." + Resource.Name + ",";
			
			SummaryQuerySelectionText = SummaryQuerySelectionText + "
			|	NestedQuery." + Resource.Name + " AS " + Resource.Name + ",";
			
			TextOfSummationQueryDimension = TextOfSummationQueryDimension + " 
			|	NestedQuery." + Resource.Name + ",";
			
			TextRequestThatGeneratesTraffic = TextRequestThatGeneratesTraffic + "
			|	&EmptyValue" + Resource.Name + " AS " + Resource.Name + ",";
			
			ParameterValues.Insert("EmptyValue" + Resource.Name, Resource.Type.AdjustValue());
		EndIf;
	EndDo;
	
	For Each Attribute In RegisterMetadata.Attributes Do
		
		If AllColumns.Find(Attribute.Name) <> Undefined
			Or UnusedFields.Find(Attribute.Name) <> Undefined Then
			Continue;
		EndIf;
		
		RegisterText = RegisterText + "
		|	RegisterTable." + Attribute.Name + ",";
		
		SummaryQuerySelectionText = SummaryQuerySelectionText + "
		|	NestedQuery." + Attribute.Name + " AS " + Attribute.Name + ",";
		
		TextOfSummationQueryDimension = TextOfSummationQueryDimension + " 
		|	NestedQuery." + Attribute.Name + ",";
		
		TextRequestThatGeneratesTraffic = TextRequestThatGeneratesTraffic + "
		|	&EmptyValue" + Attribute.Name + " AS " + Attribute.Name + ",";
		
		ParameterValues.Insert("EmptyValue" + Attribute.Name, Attribute.Type.AdjustValue());
		
	EndDo;
	
	RegisterText = Left(RegisterText, StrLen(RegisterText) - 1);
	SummaryQuerySelectionText = Left(SummaryQuerySelectionText, StrLen(SummaryQuerySelectionText) - 1);
	TextOfSummationQueryDimension = Left(TextOfSummationQueryDimension, StrLen(TextOfSummationQueryDimension) - 1);
	
	If Not IsBlankString(TextRequestThatGeneratesTraffic) Then
		TextRequestThatGeneratesTraffic = Left(TextRequestThatGeneratesTraffic, StrLen(TextRequestThatGeneratesTraffic) - 1);
		If StrFindByRegularExpression(TextOfMotionGenerationRequest,"FROM(\s)*\(").Value = "" Then
			TextOfMotionGenerationRequest = StrReplace(TextOfMotionGenerationRequest,
												"FROM",
												",
												|" +TextRequestThatGeneratesTraffic + "
												|FROM");
		Else
			Replacement = ",
			|" +TextRequestThatGeneratesTraffic + "
			|FROM 
			|	(";
			TextOfMotionGenerationRequest = StrReplaceByRegularExpression(TextOfMotionGenerationRequest,"FROM(\s)*\(", Replacement);
			
		EndIf;
	EndIf;
			
	RegisterText = RegisterText + "
	|FROM
	|	" + FullRegisterName + " AS RegisterTable";
	
	If Queue <> Undefined Then
		RegisterText = RegisterText + "
		|		INNER JOIN " + FullRegisterName + ".Changes AS RegistrarsReadyForProcessing
		|		On RegisterTable.Recorder = RegistrarsReadyForProcessing.Recorder
		|			AND (RegistrarsReadyForProcessing.Node = &CurrentQueue)
		|		LEFT JOIN TTLockedRecorder AS TTLockedRecorder
		|		ON RegisterTable.Recorder = TTLockedRecorder.Recorder
		|		LEFT JOIN TTLockedReference AS TTLockedReference
		|		ON RegisterTable.Recorder = TTLockedReference.Ref";
	EndIf;
	
	TextOfResultingRequest = 
	"SELECT DISTINCT
	|	WrongRegisteredRecords.Recorder AS Recorder 
	|INTO WrongRegisteredRecords 
	|FROM
	|	(SELECT
	|		&SummaryQuerySelectionText
	|
	|	FROM (SELECT &TextOfMotionGenerationRequest
	|
	|	UNION ALL
	|
	|	SELECT 
	|		&RegisterText
	|	WHERE
	|		RegisterTable.Recorder REFS FullDocumentName
	|		AND &ReversingEntry
	|		AND TTLockedRecorder.Recorder IS NULL 
	|		AND TTLockedReference.Ref IS NULL
	|	) AS NestedQuery
	|GROUP BY 
	|	&TextOfSummationQueryDimension
	|HAVING &TextOfSummationRequestCondition ) AS WrongRegisteredRecords
	|INDEX BY 
	|	Recorder	
	|;
	|
	|////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentsRegistry.CorrectedDocument AS CorrectedDocument
	|INTO CorrectedDocuments
	|FROM
	|	WrongRegisteredRecords AS WrongRegisteredRecords
	|	LEFT JOIN
	|		InformationRegister.DocumentsRegistry AS DocumentsRegistry 
	|	ON
	|		WrongRegisteredRecords.Recorder = DocumentsRegistry.ReversedDocument
	|		AND NOT DocumentsRegistry.AdditionalRecord
	|WHERE
	|	NOT DocumentsRegistry.Ref IS NULL
	|	AND DocumentsRegistry.CorrectedDocument <> UNDEFINED
	|
	|INDEX BY
	|	CorrectedDocument
	|;
	|
	|SELECT
	|	WrongRegisteredRecords.Recorder AS Recorder
	|FROM
	|	WrongRegisteredRecords AS WrongRegisteredRecords
	|
	|UNION
	|
	|SELECT
	|	DocumentsRegistry.Ref AS Recorder
	|FROM
	|	CorrectedDocuments AS CorrectedDocuments
	|	LEFT JOIN
	|		InformationRegister.DocumentsRegistry AS DocumentsRegistry 
	|	ON
	|		CorrectedDocuments.CorrectedDocument = DocumentsRegistry.CorrectedDocument
	|		AND NOT DocumentsRegistry.AdditionalRecord
	|WHERE
	|	NOT DocumentsRegistry.Ref IS NULL	
	|";
	
	TextOfResultingRequest = StrReplace(TextOfResultingRequest, "FullDocumentName", FullDocumentName);
	If Queue = Undefined Then
		TextOfResultingRequest = StrReplace(TextOfResultingRequest, "AND TTLockedRecorder", "//"+"AND TTLockedRecorder");
		TextOfResultingRequest = StrReplace(TextOfResultingRequest, "AND TTLockedReference", "//"+"AND TTLockedReference");
	EndIf;
	TextOfResultingRequest = StrReplace(TextOfResultingRequest, "&SummaryQuerySelectionText", SummaryQuerySelectionText);
	TextOfResultingRequest = StrReplace(TextOfResultingRequest, "SELECT &TextOfMotionGenerationRequest", TextOfMotionGenerationRequest);
	TextOfResultingRequest = StrReplace(TextOfResultingRequest, "&RegisterText", RegisterText);
	TextOfResultingRequest = StrReplace(TextOfResultingRequest, "&TextOfSummationQueryDimension", TextOfSummationQueryDimension);
	TextOfResultingRequest = StrReplace(TextOfResultingRequest, "HAVING &TextOfSummationRequestCondition", TextOfSummationRequestCondition);
	
	If RegisterMetadata.Attributes.Find("ReversingEntry") <> Undefined Then
		TextOfResultingRequest = StrReplace(TextOfResultingRequest, "&ReversingEntry", "NOT RegisterTable.ReversingEntry");
	Else
		TextOfResultingRequest = StrReplace(TextOfResultingRequest, "&ReversingEntry", "TRUE");
	EndIf;
	
	SampleRequest = New Query;
	
	For Each Parameter In ParameterValues Do
		
		SampleRequest.SetParameter(Parameter.Key, Parameter.Value);
		
	EndDo;
	
	If Queue <> Undefined Then
		
		TempTablesManager = New TempTablesManager();
		
		InfobaseUpdate.CreateTemporaryTableOfDataProhibitedFromReadingAndEditing(Queue, FullDocumentName, TempTablesManager);
		InfobaseUpdate.CreateTemporaryTableOfDataProhibitedFromReadingAndEditing(Queue, FullRegisterName, TempTablesManager);
	
		TextOfResultingRequest = StrReplace(TextOfResultingRequest, "TTLockedRecorder","TTLocked" + RegisterName);
		TextOfResultingRequest = StrReplace(TextOfResultingRequest, "TTLockedReference","TTLocked" + StrSplit(FullDocumentName,".")[1]);
	
		SampleRequest.TempTablesManager = TempTablesManager;
		
		SampleRequest.SetParameter("CurrentQueue", ExchangePlans.InfobaseUpdate.NodeInQueue(Queue));
		
	EndIf;
	
	SampleRequest.Text = TextOfResultingRequest;
	
	Recorders = SampleRequest.Execute().Unload().UnloadColumn("Recorder");
	
	Return Recorders;
EndFunction

// Selects documents for which the movements recorded in the register differ from those generated by the request
// of the tracking mechanism. Used to independent the data registers, for example, Restraurants, Documenttypes, Documenttypename.
//
// Parameters:
//  ResultOfRequestAdaptation	 - See ResultOfRequestAdaptation.
//  FullRegisterName			 - String	 - The full name of the register, as specified in the query language (for example, accumulation Register.Tourinclude)
//  FullDocumentName			 - String	 - the full name of the document, as specified in the query language (for example, Document.Input of aggregates)
//  UnusedFields			 - Array of String	 - A list of fields that do not need to be checked for data matches.
// 
// Returns:
//  ValueTable - Contains the "Link" column.
//
Function IndependentRegisterDataForRecheck(ResultOfRequestAdaptation, FullRegisterName, FullDocumentName, UnusedFields = Undefined) Export
	
	SampleRequest = RequestForReflectionOfDocumentsInIndependentRegister(ResultOfRequestAdaptation, FullRegisterName, FullDocumentName, UnusedFields);
	
	QueryTextSamples = SampleRequest.Text;
	
	QueryText = 
	"
	|SELECT DISTINCT
	|	WrongRegisteredRecords.Ref AS Ref
	|FROM
	|	&QueryTextSamples AS WrongRegisteredRecords
	|WHERE
	|	WrongRegisteredRecords.Ref <> UNDEFINED";

	SampleRequest.Text = StrReplace(QueryText, "&QueryTextSamples", "(" + QueryTextSamples + ")");
	
	RegisterData = SampleRequest.Execute().Unload();
	
	Return RegisterData;

EndFunction

// Notifies the user that work with the form is temporarily restricted, because the transition to the new version of the program has not been completed.
//
Procedure InformYouThatFormIsTemporarilyRestricted() Export

	MessageText = NStr("vi = 'Làm việc với biểu mẫu tạm thời bị hạn mức, vì quá trình chuyển đổi sang phiên bản mới của chương trình được thực hiện. Đây là một quy trình có kế hoạch, nó không can thiệp vào công việc trong cơ sở thông tin và sẽ được hoàn thành sớm. Nếu bạn có bất kỳ khó khăn, xin vui lòng liên hệ với quản trị viên hoặc dịch vụ hỗ trợ.';
						|ru = 'Работа с формой временно ограничена, так как выполняется переход на новую версию программы. Это плановый процесс, он не мешает работе в информационной базе и скоро завершится. Если у вас возникли сложности - обратитесь к администратору или в службу поддержки.';
						|en = 'Operations with the form are temporarily restricted as migration to a new application version is not completed. This is a planned process. It does not interfere with the work in the infobase and will soon be over. If you have any difficulties, contact administrator or technical support.'; fa = 'Operations with the form are temporarily restricted as migration to a new application version is not completed. This is a planned process. It does not interfere with the work in the infobase and will soon be over. If you have any difficulties, contact administrator or technical support.';
						|it = 'L''utilizzo del modulo è temporaneamente limitato perché si passa alla nuova versione del programma. Questo è un processo pianificato, non interferisce con il lavoro nel database delle informazioni e sarà presto completato. In caso di difficoltà, contattare l''amministratore o il supporto tecnico.';
						|pl = 'Praca z formą tymczasowo jest ograniczona, ponieważ jest wykonywane przejście do nowej wersji programu. To jest proces planowy, on nie przeszkadza pracy w bazie informacyjnej i niedługo będzie zakończony. Jeżeli masz komplikacje - zwróć się do administratora lub służby pomocy.';
						|tr = 'Programın yeni bir versiyonuna geçiş süreci devam ettiğinden, form ile çalışma geçici olarak kısıtlanmıştır. Bu planlı bir süreçtir, infobase''deki çalışmaları engellememektedir ve yakında tamamlanacaktır. Herhangi bir sorun yaşarsanız, lütfen yöneticiniz veya destek servisinizle iletişime geçin.'");
	CommonClientServer.MessageToUser(MessageText); 
	
EndProcedure

// Notifies the user that work with the form is temporarily restricted, because the procedures for updating the information security for
// the metadata object have not been completed.
//
// Parameters:
//  FullNameOfObjectMetadata	 - String	 - full name of the metadata object that the information security update should be completed for. 
//
Procedure CheckWhetherFormCanBeOpened(FullNameOfObjectMetadata) Export
	
	If InfobaseUpdate.HasDataToProcess(Undefined, FullNameOfObjectMetadata) Then
		InformYouThatFormIsTemporarilyRestricted();
	EndIf;

EndProcedure

// Notifies the user that working with the document log is temporarily restricted because the update procedure has not been completed
// RS Registredocuments in the context of used journal documents.
//
// Parameters:
//  DocumentTypes - Array - list of document types for which the PC update should be completed.
//
Procedure CheckWhetherDocumentLogCanBeOpened(DocumentTypes) Export
	
	If GetFunctionalOption("DeferredUpdateCompletedSuccessfully") Then
		IsSubordinateDIBNode = Common.IsSubordinateDIBNode();
		If Not IsSubordinateDIBNode Then
			Return;
		ElsIf GetFunctionalOption("DeferredMasterNodeUpdateCompleted") Then
			Return;
		EndIf;
	EndIf;
	
	Query = New Query(
		"SELECT TOP 1
		|	TRUE
		|FROM
		|	InformationRegister.DocumentsRegistry.Changes AS ChangesTable
		|WHERE
		|	ChangesTable.Node REFS ExchangePlan.InfobaseUpdate
		|	AND VALUETYPE(ChangesTable.Ref) IN (&DocumentTypes)");
	Query.SetParameter("DocumentTypes", DocumentTypes);
	
	If Not Query.Execute().IsEmpty() Then
		InformYouThatFormIsTemporarilyRestricted();
	EndIf;
	
EndProcedure

// Records the values of constants by updating the information Database.Record data().
//
// Parameters:
//  ConstantValues - Structure - The key describes the name of the constant.
//
Procedure WriteConstantsValues(ConstantValues) Export

	For Each KeyAndValue In ConstantValues Do
		
		ValueManager = Constants[KeyAndValue.Key].CreateValueManager();
		
		ValueManager.Value = KeyAndValue.Value;
		
		InfobaseUpdate.WriteData(ValueManager, False);
			
	EndDo;
	
EndProcedure

// The procedure is to Report the unsuccessful processing
//
// Parameters:
//  ErrorInfo	 - ErrorInfo - the result of the function Informationsince()
//  Ref				 - AnyRef - The object being processed.
//
Procedure ReportFailedProcessing(ErrorInfo, Ref, RepresentationOfTheReference = Undefined) Export
	MessageText = NStr("vi = 'Không thể xử lý đối tượng: %Object% do: %Cause%';
						|ru = 'Не удалось обработать объект: %Object% по причине: %Cause%';
						|en = 'Cannot process object %Object%. Reason: %Cause%'; fa = 'Cannot process object %Object%. Reason: %Cause%';
						|it = 'Impossibile elaborare l''oggetto: %Object% motivo: %Cause%';
						|pl = 'Nie udało się przetworzyć obiekt: %Object% z powodu: %Cause%';
						|tr = '%Cause% nedeniyle nesne: %Object% işlenemedi'");
	MessageText = StrReplace(MessageText, "%Object%", ?(RepresentationOfTheReference = Undefined, Ref, RepresentationOfTheReference));
	MessageText = StrReplace(MessageText, "%Cause%", DetailErrorDescription(ErrorInfo));
	WriteLogEvent(InfobaseUpdate.EventLogEvent(),
							EventLogLevel.Warning,
							Ref.Metadata(),
							Ref,
							MessageText);
EndProcedure

// Checks whether the reference data to the information database object is correct.
// If the check is successful, it returns the information database object.
//
// Parameters:
//	Ref			- AnyRef	 - link to the information base object.
//	DataVersion	- String		 - the current version of the object's data.
//	Queue			- Number			 - a deferred data processing queue for monitoring data for blocking
//										by other handlers.
//
// Returns:
//	DocumentObject, CatalogObject, ChartOfAccountsObject, ChartOfCharacteristicTypesObject, Undefined - the object of the information base.
//
Function CheckGetObject(Ref,DataVersion,Queue) Export
	
	Object = Ref.GetObject();
	If Object = Undefined Then
		InfobaseUpdate.MarkProcessingCompletion(Ref);
		Return Undefined;
	EndIf;
	If Object.DataVersion <> DataVersion Then
		Return Undefined;
	EndIf;
	Return Object;
	
EndFunction

// Gets data to write to the register and writes it.
// 
// Parameters:
// 	Ref - DocumentRef - 
// 	FullRegisterName - String - 
// 	RegisterManager - InformationRegisterManager - 
// 	AdditionalParameters - See AdditionalOptionsForOverwritingRegisteredRecordsFromQueue
// 	FieldNameLogger - String - 
// Returns:
// 	Boolean - False if the movements could not be recorded.
Function GenerateAndRecordRegisteredRecords(Ref, FullRegisterName, RegisterManager, AdditionalParameters, FieldNameLogger = "Recorder", AttributesOfCourse = Undefined) Export
	
	RegisterName = StrSplit(FullRegisterName,".",False)[1];
	
	If Not AdditionalParameters.WriteInSingleTransaction Then
		BeginTransaction();
	EndIf;
	
	Try
		
		// We set a controlled lock to conduct a responsible reading of the object.
		Block = New DataLock;
		
		LockItem = Block.Add(Ref.Metadata().FullName());
		LockItem.SetValue("Ref", Ref);
		LockItem.Mode = DataLockMode.Shared;
		
		Block.Lock();
		
		RecordSet = RegisterManager.CreateRecordSet(); // InformationRegisterRecordSet - 
		RecordSet.Filter[FieldNameLogger].Set(Ref);
		
		If AdditionalParameters.PassAdditionalProperties Then
			CommonClientServer.SupplementStructure(RecordSet.AdditionalProperties,
			AdditionalParameters.AdditionalRecordsetProperties);
		EndIf;	
		
		If AdditionalParameters.IsIndependentInformationRegister Then
			RecordRegisteredRecords = Common.ObjectAttributeValue(Ref, FieldNameLogger) <> Undefined;
		Else
			
			If AttributesOfCourse = Undefined Then
				
				RecordRegisteredRecords = Common.ObjectAttributeValue(Ref, "Posted"); //responsible reading of the "Conducted" props
				
			Else
				
				RecordRegisteredRecords = AttributesOfCourse.Get(Ref);
				
			EndIf;
			
		EndIf;
		
		If TypeOf(RecordRegisteredRecords) <> Type("Boolean") Then
			RecordRegisteredRecords = False;
		EndIf;
		
		If RegisterName = "InventoryAndDemands" Then
			
			AccumulationRegisters.InventoryAndDemands.GenerateAndRecordRegisteredRecords(RecordSet, Ref, RecordRegisteredRecords); 
			
		Else
			
			If RecordRegisteredRecords Then
				
				TablesForRegisteredRecords = DocumentsPosting.DocumentDataForPosting(
					Ref, RegisterName);
					
				If TablesForRegisteredRecords.Property("Table" + RegisterName) Then
					DataTable = TablesForRegisteredRecords["Table" + RegisterName];
				
					If AdditionalParameters.NeedAdditionalRecordProcessing Then
						RecordSet.UploadWithProcessing(DataTable);
					Else
						RecordSet.Load(DataTable);
					EndIf;
				EndIf;
				
			EndIf;
			InfobaseUpdate.WriteData(RecordSet);
			
		EndIf;
		
		ReverseDocument = DocumentCorrection.ReverseDocument(Ref);
		If ReverseDocument <> Undefined Then
			AdditionalUpdateParametersAreReversed = Common.CopyRecursive(AdditionalParameters);
			AdditionalUpdateParametersAreReversed.WriteInSingleTransaction = True; 
			GenerateAndRecordRegisteredRecords(
				ReverseDocument,
				FullRegisterName,
				RegisterManager,
				AdditionalUpdateParametersAreReversed, 
				FieldNameLogger);
		EndIf;

		If Not AdditionalParameters.WriteInSingleTransaction Then
			CommitTransaction();
		EndIf;	
		
	Except
		
		If Not AdditionalParameters.WriteInSingleTransaction Then
			RollbackTransaction();
		EndIf;	
		
		MessageText = NStr("vi = 'Không thể ghi lại bản ghi kết chuyển trong biểu ghi ""%RegisterName%"" theo chứng từ %Ref% do nguyên nhân: %Cause%';
							|ru = 'Не удалось перезаписать движения в регистр ""%RegisterName%"" по документу %Ref% по причине: %Cause%';
							|en = 'Cannot overwrite records to register ""%RegisterName%"" using document %Ref%. Reason: %Cause%'; fa = 'Cannot overwrite records to register ""%RegisterName%"" using document %Ref%. Reason: %Cause%';
							|it = 'Non è stato possibile registrare nuovamente i movimenti nel registro ""%RegisterName%"" per il documento %Ref% a causa di: %Cause%';
							|pl = 'Nie udało się ponownie zapisać ruchu do rejestru ""%RegisterName%"" według dokumentu %Ref% z powodu: %Cause%';
							|tr = 'Şu nedenden dolayı %Ref% belgesi için ""%RegisterName%"" kaydındaki hareketlerin üzerine kaydedilemedi: %Cause%'");
		MessageText = StrReplace(MessageText, "%Ref%", Ref);
		MessageText = StrReplace(MessageText, "%Cause%", DetailErrorDescription(ErrorInfo()));
		MessageText = StrReplace(MessageText, "%RegisterName%", FullRegisterName);
		
		WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Warning,
			Ref.Metadata(), Ref, MessageText);
		
		If RecordSet <> Undefined Then
			InfobaseUpdate.FileIssueWithData(Ref,
				StrTemplate(NStr("vi = 'Không thể ghi đè bản ghi kết chuyển vào biểu ghi ""%1"" theo chứng từ %2';
								|ru = 'Не удалось перезаписать движения в регистр ""%1"" по документу %2';
								|en = 'Cannot overwrite records to the ""%1"" register by the %2 document'; fa = 'Cannot overwrite records to the ""%1"" register by the %2 document';
								|it = 'Не удалось перезаписать движения в регистр ""%1"" по документу %2';
								|pl = 'Cannot overwrite records to the ""%1"" register by the %2 document';
								|tr = 'Belge %2''de ""%1"" kaydındaki hareketlerin üzerine kaydedilemedi'"),
					FullRegisterName, Ref));
			InfobaseUpdate.MarkProcessingCompletion(RecordSet);
		EndIf;
		
		If AdditionalParameters.WriteInSingleTransaction Then
			Return False;
		EndIf;
		
	EndTry;

	Return True;
	
EndFunction

// Parameters:
//  Data - AnyRef
//         - Array
//         - InformationRegisterRecordSet, AccumulationRegisterRecordSet, AccountingRegisterRecordSet
//         - CalculationRegisterRecordSet - the data for which you need to register changes.
//         - ValueTable - measurement values of the independent data register. Requirements:
//                              a) all measurements of the register must be included in the main selection;
//                              b) the table should contain only columns corresponding by name to the measurements of the register,
//                                for which the need for processing was previously recorded;
//                              c) the recording of sets during the update process should take place with the same selection
//                                as the registration of the need for processing;
//                              d) in the additional parameters, you need to pass the corresponding attribute and the full name of the register.
//  AdditionalParameters - See InfobaseUpdate.AdditionalProcessingMarkParameters.
//
Procedure MarkInteractiveProcessing(Data, AdditionalParameters = Undefined) Export
	
	If InfobaseUpdate.DeferredUpdateCompleted() Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	InfobaseUpdate.Ref AS Ref
		|FROM
		|	ExchangePlan.InfobaseUpdate AS InfobaseUpdate
		|WHERE
		|	NOT InfobaseUpdate.ThisNode";
	RefsTable = Query.Execute().Unload();
	ArrayOfQueues = RefsTable.UnloadColumn("Ref");
	
	DataCopy = Data;
	If AdditionalParameters = Undefined Then
		AdditionalParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
	EndIf;
	
	If (TypeOf(Data) = Type("Array")
		Or TypeOf(Data) = Type("ValueTable"))
		And Data.Count() = 0 Then
		
		Return;
	EndIf;
	
	If AdditionalParameters.IsRegisterRecords Then
		
		Set = Common.ObjectManagerByFullName(AdditionalParameters.FullRegisterName).CreateRecordSet();
		
		If TypeOf(Data) = Type("Array") Then
			For Each ArrayRow In Data Do
				Set.Filter.Recorder.Set(ArrayRow);
				ExchangePlans.DeleteChangeRecords(ArrayOfQueues, Set);
			EndDo;
		Else
			Set.Filter.Recorder.Set(Data);
			ExchangePlans.DeleteChangeRecords(ArrayOfQueues, Set);
		EndIf;
		
	ElsIf AdditionalParameters.IsIndependentInformationRegister Then
		
		Set = Common.ObjectManagerByFullName(AdditionalParameters.FullRegisterName).CreateRecordSet();
		ObjectMetadata = Metadata.FindByFullName(AdditionalParameters.FullRegisterName);
		
		SetMissingFiltersInSet(Set, ObjectMetadata, Data);
		
		For Each TableRow In Data Do
			For Each Column In Data.Columns Do
				Set.Filter[Column.Name].Value = TableRow[Column.Name];
				Set.Filter[Column.Name].Use = True;
			EndDo;
			
			ExchangePlans.DeleteChangeRecords(ArrayOfQueues, Set);
		EndDo;
		
	Else
		If TypeOf(Data) = Type("MetadataObject") Then
			ExceptionText = NStr("vi = 'Không hỗ trợ đánh dấu thực hiện xử lý cập nhật toàn bộ đối tượng metadata. Cần đánh dấu xử lý dữ liệu chi tiết.';
								|ru = 'Не поддерживается отметка выполнения обработки обновления целиком объекта метаданных. Нужно отмечать обработку конкретных данных.';
								|en = 'Setting ""update processing completed"" flag to an entire metadata object is not supported. This flag can be set to specific data.'; fa = 'Setting ""update processing completed"" flag to an entire metadata object is not supported. This flag can be set to specific data.';
								|it = 'Non è supportata la quota altimetrica per l''elaborazione dell''aggiornamento dell''intero oggetto metadati. È necessario contrassegnare l''elaborazione di dati specifici.';
								|pl = 'Nie jest obsługiwane zaznaczenie wykonania przetwarzania aktualizacji w całości obiektu metadanych. Trzeba zaznaczać przetwarzanie konkretnych danych.';
								|tr = 'Meta veri nesnesinin tamamını güncelleştirme işleme yürütme işareti desteklenmiyor. Belirli verilerin işlenmesi işaretlenmelidir.'");
			Raise ExceptionText;
		EndIf;
		
		If TypeOf(Data) <> Type("Array") Then
			
			ObjectValueType = TypeOf(Data);
			ObjectMetadata  = Metadata.FindByType(ObjectValueType);
			
			If Common.IsInformationRegister(ObjectMetadata)
				And ObjectMetadata.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.Independent Then
				Set = Common.ObjectManagerByFullName(ObjectMetadata.FullName()).CreateRecordSet();
				For Each FilterElement In Data.Filter Do
					Set.Filter[FilterElement.Name].Value = FilterElement.Value;
					Set.Filter[FilterElement.Name].Use = FilterElement.Use;
				EndDo;
				SetMissingFiltersInSet(Set, ObjectMetadata, Data.Filter);
			ElsIf Common.IsRefTypeObject(ObjectMetadata)
				And Not Common.IsReference(ObjectValueType)
				And Data.IsNew() Then
				
				Return;
			ElsIf Common.IsConstant(ObjectMetadata) Then
				
				Return;
			Else
				Set = Data;
			EndIf;
			
			ExchangePlans.DeleteChangeRecords(ArrayOfQueues, Set);
			DataCopy = Set;
		Else
			For Each ArrayElement In Data Do
				ExchangePlans.DeleteChangeRecords(ArrayOfQueues, ArrayElement);
			EndDo;
		EndIf;
		
	EndIf;
	
EndProcedure

// Logs bad data as system problems.
// 
// Parameters:
//  BadData - Array of Structure - Bad data.
//  ObjectsProcessed - Number - Objects processed
//  Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//  AdditionalParameters - See InfobaseUpdate.AdditionalProcessingMarkParameters.
Procedure RecordBadData(BadData, ObjectsProcessed, Parameters, AdditionalParameters = Undefined) Export
	If ObjectsProcessed > 0 Then
		For Each DataProblem In BadData Do
			InfobaseUpdate.FileIssueWithData(DataProblem.ObjectReference,
				DataProblem.Recommendation, Parameters);
			InfobaseUpdate.MarkProcessingCompletion(DataProblem.ObjectReference,
				AdditionalParameters);
		EndDo;
	EndIf;
EndProcedure

// Description of the data problem.
// 
// Parameters:
//  ObjectReference - AnyRef - object reference
//  Recommendation - String - Recommendation to the user on how to fix the data problem.
//  ErrorInfo - String - Extended error information.
// 
// Returns:
//  Structure -  Data Problem:
// * ObjectReference - AnyRef
// * Recommendation - String
// * ErrorInfo -String
Function DataProblem(ObjectReference, Recommendation, ErrorInfo) Export
	Return New Structure("ObjectReference, Recommendation, ErrorInfo", ObjectReference, Recommendation, ErrorInfo);
EndFunction

#EndRegion

#EndRegion

#Region Private

Procedure SetMissingFiltersInSet(Set, SetMetadata, FiltersToSet)
	For Each Dimension In SetMetadata.Dimensions Do
		
		HasFilterByDimension = False;
		
		If TypeOf(FiltersToSet) = Type("ValueTable") Then
			HasFilterByDimension = FiltersToSet.Columns.Find(Dimension.Name) <> Undefined;
		Else //Filter
			HasFilterByDimension = FiltersToSet[Dimension.Name].Use;	
		EndIf;
		
		If Not HasFilterByDimension Then
			EmptyValue = Dimension.Type.AdjustValue();
			Set.Filter[Dimension.Name].Set(EmptyValue);
		EndIf;
	EndDo;
	
	If SetMetadata.MainFilterOnPeriod Then
		
		If TypeOf(FiltersToSet) = Type("ValueTable") Then
			HasFilterByDimension = FiltersToSet.Columns.Find("Period") <> Undefined;
		Else //Filter
			Period = FiltersToSet.Period; // DataCompositionFilterItem
			HasFilterByDimension = Period.Use;
		EndIf;
		
		If Not HasFilterByDimension Then
			EmptyValue = '00010101';
			Set.Filter.Period.Set(EmptyValue);
		EndIf;
		
	EndIf;
EndProcedure

// Returns:
//  Query - Request for differences in document reflection in an independent register
Function RequestForReflectionOfDocumentsInIndependentRegister(ResultOfRequestAdaptation, FullRegisterName, FullDocumentName, UnusedFields = Undefined) Export

	TextOfMotionGenerationRequest = ResultOfRequestAdaptation.QueryText;
	ParameterValues = ResultOfRequestAdaptation.ParameterValues;
	
	TextOfResultingRequest	= "";
	
	RegisterMetadata = Metadata.FindByFullName(FullRegisterName); // MetadataObjectInformationRegister - 
		
	TextOfSummationQueryDimension = "";	
	TextOfMotionGenerationRequest = StrReplace(TextOfMotionGenerationRequest,
										"SELECT",
										"SELECT
										|	1 AS InformationSecurityUpdateControlField,"); //@query-part-1 @query-part-2
	CaseFieldText = "
						|	-1,";
	SummaryQuerySelectionText = "
									|	SUM(InformationSecurityUpdateControlField) AS InformationSecurityUpdateControlField,";
	
	QuerySchema = New QuerySchema;
	QuerySchema.SetQueryText(TextOfMotionGenerationRequest);
	
	Query = QuerySchema.QueryBatch[0];
	
	AllColumns = New Array;
	
	// Fields for which it is not necessary to check whether the data in the information security System matches the request data.
	If UnusedFields = Undefined Then
		UnusedFields = New Array;
	EndIf; 
	
	For Each Column In Query.Columns Do
		
		AllColumns.Add(Column.Alias);
		
		If Column.Alias = "InformationSecurityUpdateControlField" Then
			Continue;
		EndIf;
		
		Field = RegisterMetadata.Dimensions.Find(Column.Alias); 
		
		If Field <> Undefined Then
			AddCaseTextBasedOnFieldMetadata(CaseFieldText, Field);
		Else
			Field = RegisterMetadata.Resources.Find(Column.Alias); 
			If Field <> Undefined Then
				AddCaseTextBasedOnFieldMetadata(CaseFieldText, Field);
			Else
				Field = RegisterMetadata.Attributes.Find(Column.Alias); 
				If Field <> Undefined Then
					AddCaseTextBasedOnFieldMetadata(CaseFieldText, Field);
				Else
					ExceptionText = NStr("vi = 'Trong truy vấn chọn dữ liệu chứng từ %FullDocumentName% để tạo các bản ghi kết chuyển theo biểu ghi %FullRegisterName% có một trường mà không có trường đó trong biểu ghi.';
										|ru = 'В запросе выборки данных документа %FullDocumentName% для формирования движений по регистру %FullRegisterName% присутствует поле, которого нет в регистре.';
										|en = 'Request for selecting data of the %FullDocumentName% document to generate records of the %FullRegisterName% register has a field missing in the register.'; fa = 'Request for selecting data of the %FullDocumentName% document to generate records of the %FullRegisterName% register has a field missing in the register.';
										|it = 'Nella query di selezione dei dati del documento %FullDocumentName% per generare movimenti di maiuscole e minuscole %FullRegisterName% è presente un campo che non è presente nel registro.';
										|pl = 'W zapytaniu selekcji danych dokumentu %FullDocumentName% do utworzenia ruchów w rejestrze %FullRegisterName% istnieje pole, którego nie ma w rejestrze.';
										|tr = '%FullDocumentName% kaydında hareketler oluşturmak için %FullRegisterName% belge veri seçimi isteği, kayıtta olmayan bir alan içerir. '");
					ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", FullDocumentName);
					ExceptionText = StrReplace(ExceptionText, "%FullRegisterName%", FullRegisterName);
					
					Raise ExceptionText;
				EndIf;
			EndIf;
		EndIf;
		
		If UnusedFields.Find(Column.Alias) = Undefined Then
			AddTextToSelectionTextOfSummationQueryBasedOnFieldMetadata(SummaryQuerySelectionText, Field);
			AddTextForGroupingSummingQueryByFieldMetadata(TextOfSummationQueryDimension, Field);
		EndIf;
				
	EndDo;
	
	TextRequestThatGeneratesTraffic = "";
	
	For Each Dimension In RegisterMetadata.Dimensions Do		
		
		ParameterValues.Insert("EmptyValue" + Dimension.Name, Dimension.Type.AdjustValue());
		
		If AllColumns.Find(Dimension.Name) <> Undefined
			Or UnusedFields.Find(Dimension.Name) <> Undefined Then
			Continue;
		EndIf;
		
		AddCaseTextBasedOnFieldMetadata(CaseFieldText, Dimension);
		AddTextToSelectionTextOfSummationQueryBasedOnFieldMetadata(SummaryQuerySelectionText, Dimension);
		AddTextForGroupingSummingQueryByFieldMetadata(TextOfSummationQueryDimension, Dimension);
		
		TextRequestThatGeneratesTraffic = TextRequestThatGeneratesTraffic + "
		|	&EmptyValue" + Dimension.Name + " AS " + Dimension.Name + ",";
		
	EndDo;
	
	For Each Resource In RegisterMetadata.Resources Do		
		
		ParameterValues.Insert("EmptyValue" + Resource.Name, Resource.Type.AdjustValue());
		
		If AllColumns.Find(Resource.Name) <> Undefined
			Or UnusedFields.Find(Resource.Name) <> Undefined Then
			Continue;
		EndIf;
		
		AddCaseTextBasedOnFieldMetadata(CaseFieldText, Resource);
		AddTextToSelectionTextOfSummationQueryBasedOnFieldMetadata(SummaryQuerySelectionText, Resource);
		AddTextForGroupingSummingQueryByFieldMetadata(TextOfSummationQueryDimension, Resource);
		
		TextRequestThatGeneratesTraffic = TextRequestThatGeneratesTraffic + "
		|	&EmptyValue" + Resource.Name + " AS " + Resource.Name + ",";
		
	EndDo;
	
	For Each Attribute In RegisterMetadata.Attributes Do		
		
		ParameterValues.Insert("EmptyValue" + Attribute.Name, Attribute.Type.AdjustValue());
		
		If AllColumns.Find(Attribute.Name) <> Undefined
			Or UnusedFields.Find(Attribute.Name) <> Undefined Then
			Continue;
		EndIf;
		
		AddCaseTextBasedOnFieldMetadata(CaseFieldText, Attribute);
		AddTextToSelectionTextOfSummationQueryBasedOnFieldMetadata(SummaryQuerySelectionText, Attribute);
		AddTextForGroupingSummingQueryByFieldMetadata(TextOfSummationQueryDimension, Attribute);
		
		TextRequestThatGeneratesTraffic = TextRequestThatGeneratesTraffic + "
		|	&EmptyValue" + Attribute.Name + " AS " + Attribute.Name + ",";
		
	EndDo;
	
	CaseFieldText = Left(CaseFieldText, StrLen(CaseFieldText) - 1);
	SummaryQuerySelectionText = Left(SummaryQuerySelectionText, StrLen(SummaryQuerySelectionText) - 1);
	TextOfSummationQueryDimension = Left(TextOfSummationQueryDimension, StrLen(TextOfSummationQueryDimension) - 1);
	
	If Not IsBlankString(TextRequestThatGeneratesTraffic) Then
		TextRequestThatGeneratesTraffic = Left(TextRequestThatGeneratesTraffic, StrLen(TextRequestThatGeneratesTraffic) - 1);
		TextOfMotionGenerationRequest = StrReplace(TextOfMotionGenerationRequest,
											"FROM",
											",
											|" +TextRequestThatGeneratesTraffic + "
											|FROM");
	EndIf;
	
	RegisterText = 
	"SELECT
	|&CaseFieldText
	|FROM
	|	&FullRegisterName AS RegisterTable
	|WHERE
	|	RegisterTable.Ref REFS FullDocumentName
	|	AND TRUE IN
	|			(SELECT
	|				TRUE
	|			FROM
	|				FullDocumentName AS DocumentRecorder
	|			WHERE
	|				RegisterTable.Ref = DocumentRecorder.Ref)";
	
	RegisterText = StrReplace(RegisterText, "&CaseFieldText", CaseFieldText);
	RegisterText = StrReplace(RegisterText, "&FullRegisterName", FullRegisterName);
	RegisterText = StrReplace(RegisterText, "FullDocumentName", FullDocumentName);
	
	TextOfResultingRequest =  
	"SELECT
	|&SummaryQuerySelectionText
	|FROM
	|	(SELECT &TextOfMotionGenerationRequest
	|
	|	UNION ALL
	|	
	|	SELECT &RegisterText
	|) AS NestedQuery 
	|GROUP BY
	|&TextOfSummationQueryDimension
	|HAVING
	|	SUM(InformationSecurityUpdateControlField) <> 0";
	
	TextOfResultingRequest = StrReplace(TextOfResultingRequest, "&SummaryQuerySelectionText", SummaryQuerySelectionText);
	TextOfResultingRequest = StrReplace(TextOfResultingRequest, "SELECT &TextOfMotionGenerationRequest", TextOfMotionGenerationRequest);
	TextOfResultingRequest = StrReplace(TextOfResultingRequest, "SELECT &RegisterText", RegisterText);
	TextOfResultingRequest = StrReplace(TextOfResultingRequest, "&TextOfSummationQueryDimension", TextOfSummationQueryDimension);
	
	SampleRequest = New Query;
	For Each Parameter In ParameterValues Do
		
		SampleRequest.SetParameter(Parameter.Key, Parameter.Value);
		
	EndDo;
	
	SampleRequest.Text = TextOfResultingRequest;
	
	Return SampleRequest;
	
EndFunction

Procedure AddCaseTextBasedOnFieldMetadata(RegisterText, Field)
	
	If Field.Name = "Comment" Then
		RegisterText = RegisterText + "
		|	CAST(RegisterTable." + Field.Name + " AS STRING (1000)),";
	ElsIf Field.Type.ContainsType(Type("CatalogRef.DocumentRegistryKeys")) Then
		RegisterText = RegisterText + "
		|	RegisterTable." + Field.Name + ".Key,";
	Else	
		RegisterText = RegisterText + "
		|	RegisterTable." + Field.Name + ",";
	EndIf;
	
EndProcedure

Procedure AddTextToSelectionTextOfSummationQueryBasedOnFieldMetadata(SummaryQuerySelectionText, Field)
	
	SummaryQuerySelectionText = SummaryQuerySelectionText + "
		|	CASE WHEN NestedQuery." + Field.Name + " IS NULL OR NestedQuery." + Field.Name + " = UNDEFINED THEN &EmptyValue" + Field.Name + " ELSE NestedQuery." + Field.Name + " END  AS " + Field.Name + ",";
		
EndProcedure

Procedure AddTextForGroupingSummingQueryByFieldMetadata(TextOfSummationQueryDimension, Field)
	
	TextOfSummationQueryDimension = TextOfSummationQueryDimension + "
		|	CASE WHEN NestedQuery." + Field.Name + " IS NULL OR NestedQuery." + Field.Name + " = UNDEFINED THEN &EmptyValue" + Field.Name + " ELSE NestedQuery." + Field.Name + " END,";
		
EndProcedure

Function ConvertTemporaryTableToNestedQuery(TableName, QueryText)
	
	//delete the PLACE
	FirstChar = StrFind(QueryText, "INTO");// @query-part
	LastChar = StrFind(QueryText, TableName, SearchDirection.FromBegin, FirstChar) + StrLen(TableName);
	SearchSubstitution = Mid(QueryText, FirstChar, LastChar - FirstChar);
	SubstitutionOfTemporaryTable = StrReplace(QueryText, SearchSubstitution, "");
	
	//deleting the INDEX BY section
	FirstChar = StrFind(SubstitutionOfTemporaryTable, "INDEX BY");
	If FirstChar > 0 Then
		SearchSubstitution = Mid(SubstitutionOfTemporaryTable, FirstChar);
		SubstitutionOfTemporaryTable = StrReplace(SubstitutionOfTemporaryTable, SearchSubstitution, "");
	EndIf;
	
	Return "(" + SubstitutionOfTemporaryTable + ")";
	
EndFunction

#Region FillingInEmptyIB

// Handler for the first launch of UT 11.
//
Procedure FirstRun() Export
	
	ThisIsTransitionFromBasicVersionToProf = Common.CommonSettingsStorageLoad("SwitchingFromBasicVersionToProf","ThisIsTransitionFromBasicVersionToProf");
	If ThisIsTransitionFromBasicVersionToProf <> Undefined And ThisIsTransitionFromBasicVersionToProf Then
		Return;
	EndIf;
	
	Catalogs.PackagesAndUnitsOfMeasure.FillInUnitsFromClassifier("006,113,166,796,055,168,112");
	
	FillInDefaultConstants();
	
	BusinessProcesses.SaleApproval.InitializeExecutorRoles();
	BusinessProcesses.PurchaseApproval.InitializeExecutorRoles();
	BusinessProcesses.PriceApproval.InitializeExecutorRoles();
	BusinessProcesses.ApprovalOfRequestForReturnOfGoodsFromCustomer.InitializeExecutorRoles();
	BusinessProcesses.ApprovalOfInventoryConsumptionOrder.InitializeExecutorRoles();
	
	Catalogs.Partners.FillInPredefinedPartners();
	Catalogs.Counterparties.FillInPredefinedCounterparties();

	Catalogs.DiscountsMarkups.FillInPredefinedElements();
	Catalogs.ProcessesStates.InitialFillingOfSequenceOfStagesOfSalesProcesses();
	Catalogs.CashFlowReportItems.FillInPredefinedCashFlowItems();
	FillInPropertiesOfContactInformationTypes();
	Catalogs.BusinessTransactionsSettings.FillInPredefinedSettingsForBusinessOperations();
	Catalogs.ReasonsForPurchaseOrderCancellation.FillInPredefinedElements();
	Catalogs.InstructionsForBank.FillInPredefinedElements();
	
	Catalogs.VATRates.CreateInitialFillItems();
	VATAccountingLocalization.BasicBidsNDS_CreateInitialFillItems();
	
	AuditOfSystemState.FillInSystemStateCheckCatalog();
	
	CalendarSchedules.UpdateMultipleBusinessCalendarsUsage();
	Catalogs.TimeBucketsForAgingAnalysis.CreateDefaultDebtClassificationOptionMonopoly();
	TargetValueMonitoring.FillInGoalStructureAndAnalysisOptions();
	
	ExchangePlans.SalesRepresentativeMobileApplication.InitialFillingOfNodeCodeOfThisIB();
	
	InformationRegisters.ItemsBarcodes.FillInConstantsOfBarcodingSubsystem();
	InfobaseUpdateCEL.UpdateSuppliedDrivers();
	
	InfobaseUpdateTM.DisableUnusedRoutineTasksInBasicVersion();
	
EndProcedure

// Fills constants with default values.
// Called when the IB is initially filled in after the following data is filled in
//	- Guide.Opakowaniowej.
//
Procedure FillInDefaultConstants()
	
	SetUnits();
	
	ConstantValues = SystemSettingsCached.GetDefaultValuesOfConstants();
	For Each KeyAndValue In ConstantValues Do
		Constants[KeyAndValue.Key].Set(KeyAndValue.Value);
	EndDo; 
	
	SupplyServer.DoNotUseNonOrderAssignmentsComputeAndWriteByInversion();
	RefreshReusableValues();
	
	If Not Common.FileInfobase() Then
		Constants.LimitAccessAtRecordLevelUniversally.Set(True);
	EndIf;
	
	Constants.UseToolForChangingDocumentListSettings.Set(True);
	
EndProcedure

// Fills in service constants-configuration IDs.
//
Procedure SetServiceConstants(Source = Undefined, Cancel = False, OnlySeparatedOnes = False) Export
	
	If Not Source = Undefined And Source.DataExchange.Load = True Then
		Return;
	EndIf;
	
	ConfigurationName = Metadata.Name;

	// Let's determine the correct values of service constants (functional options).
	ConstantValues = New Structure;
	If Not OnlySeparatedOnes = True Then
		ConstantValues.Insert("TradeManagement",		False);
		ConstantValues.Insert("ComplexAutomation",	False);
		ConstantValues.Insert("EnterpriseManagement",		False);
	EndIf;
	If SaaSOperations.SeparatedDataUsageAvailable() Then
		ConstantValues.Insert("LocalizationRFService",				True);
		ConstantValues.Insert("BaseVersion",				False);
		ConstantValues.Insert("NotBaseVersion",			True);
		ConstantValues.Insert("NotCPM",		True);
	EndIf;
	SubsystemsModules = New Array;
	ConfigurationSubsystemsOverridable.OnAddSubsystems(SubsystemsModules);
	
	If Not OnlySeparatedOnes = True Then
		SubsystemsModules = TMCommonUseClientServer.ConvertArrayToStructureOrMatch(SubsystemsModules, True);
	
		If SubsystemsModules.Property("InfobaseUpdatePM") Then
			ConstantValues.EnterpriseManagement = True;
		ElsIf SubsystemsModules.Property("InfobaseUpdateCA") Then
			ConstantValues.ComplexAutomation = True;
		ElsIf SubsystemsModules.Property("InfobaseUpdateTM") Then
			ConstantValues.TradeManagement = True;
		Else
			Raise NStr("vi = 'Không thể xác định định danh hệ thống của cấu hình.';
						|ru = 'Не удалось определить служебный идентификатор конфигурации.';
						|en = 'Cannot determine configuration service ID.'; fa = 'Cannot determine configuration service ID.';
						|it = 'Impossibile determinare l''identità del servizio di configurazione.';
						|pl = 'Nie udało się określić służbowy identyfikator konfiguracji.';
						|tr = 'Konfigürasyon hizmeti tanımlayıcısı belirlenemedi.'");
		EndIf;
	EndIf;
	
	If SaaSOperations.SeparatedDataUsageAvailable() Then
		If ConfigurationName = "TradeManagementBasic" Then
			ConstantValues.BaseVersion = True;
			ConstantValues.NotBaseVersion = False;
		ElsIf ConfigurationName = "ERPWE" 
			Or ConfigurationName = "ERPWEENG"
			Or ConfigurationName = "TradeManagement"
			Or ConfigurationName = "TradeManagementEng" Then
			ConstantValues.LocalizationRFService = False;
		EndIf;
	EndIf;
	
	// Let's set these values.
	SetPrivilegedMode(True);
	
	HasChanges = False;
	
	If Source = Undefined Then
		For Each KeyAndValue In ConstantValues Do
			
			If Constants[KeyAndValue.Key].Get() <> KeyAndValue.Value Then
				
				// The current value of the constant in the IB does not correspond to the correct one - we will fix it
				ValueManager = Constants[KeyAndValue.Key].CreateValueManager();
				
				ValueManager.Value = KeyAndValue.Value;
				
				InfobaseUpdate.WriteData(ValueManager, False);
				
				HasChanges = True;
				
			EndIf;
			
		EndDo;
	Else
		ValueFound = Undefined;
		If ConstantValues.Property(Source.Metadata().Name, ValueFound) Then 
			If Source.Value <> ValueFound Then
				MessageText = NStr("vi = 'Giá trị của hằng hệ thống không tương ứng với giá trị dự tính. Không thể hủy bỏ việc ghi lại.';
									|ru = 'Значение служебной константы не соответствует ожидаемому. Запись отменена.';
									|en = 'The value of the internal constant does not match the expected one. Saving is canceled.'; fa = 'The value of the internal constant does not match the expected one. Saving is canceled.';
									|it = 'The value of the internal constant does not match the expected one. Saving is canceled.';
									|pl = 'The value of the internal constant does not match the expected one. Saving is canceled.';
									|tr = 'Hizmet sabitinin değeri beklenen değer ile eşleşmiyor Giriş iptal edildi.'");
				Message(MessageText, MessageStatus.Important);
				Cancel = True;
			Else
				HasChanges = True;
			EndIf;
		EndIf;
	EndIf;
	
	If HasChanges Then
		RefreshReusableValues();
	EndIf;
	
	SetPrivilegedMode(False);
	
EndProcedure

// The procedure sets the value of the regulated accounting currency.
// Called when the IB is initially filled in.
//

// The procedure sets the values of constants associated with units of measurement
//
Procedure SetUnits()
	
	BasicUnitOfLength  = Catalogs.PackagesAndUnitsOfMeasure.FindByCode("006");
	BasicUnitOfWeight   = Catalogs.PackagesAndUnitsOfMeasure.FindByCode("166");
	BasicUnitOfVolumeMeasurement = Catalogs.PackagesAndUnitsOfMeasure.FindByCode("113");
	BasicUnitOfAreaMeasurement = Catalogs.PackagesAndUnitsOfMeasure.FindByCode("055");
	BasicUnitOfMeasurementPieces    = Catalogs.PackagesAndUnitsOfMeasure.FindByCode("796");
	BasicUnitOfMeasurementOfDraftProducts = Catalogs.PackagesAndUnitsOfMeasure.FindByCode("112");
	
	Constants.UnitOfMeasureForLength.Set(BasicUnitOfLength);
	Constants.UnitOfMeasureForWeight.Set(BasicUnitOfWeight);
	Constants.UnitOfMeasureForVolume.Set(BasicUnitOfVolumeMeasurement);
	Constants.UnitOfMeasureForArea.Set(BasicUnitOfAreaMeasurement);
	Constants.UnitOfMeasureOfQuantity.Set(BasicUnitOfMeasurementPieces);
	Constants.UnitOfMeasureOfDraughtProducts.Set(BasicUnitOfMeasurementOfDraftProducts);
	
EndProcedure

// Disables unused scheduled tasks for the basic version.
//
Procedure DisableUnusedRoutineTasksInBasicVersion() Export
	
	If Not StandardSubsystemsServer.IsBaseConfigurationVersion()
	 Or Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	UnusedTasks = New Structure(
		"ABCInventoryClassification,
		|ABCPartnerClassification,
		|ArchiveCashRegisterReceipts,
		|XYZInventoryClassification,
		|XYZPartnerClassification,
		|ArchiveCashRegisterReceipts,
		|CurrenciesRatesImport,
		|StartingAdditionalDataProcessors,
		|DataFillingForAccessRestriction,
		|ExchangeDataWith1CDocumentManagement,
		|UpdateAggregates,
		|UpdateDataOnGoodsAvailabilityForExternalUsers,
		|UpdatePeripheralsGoodsCodes,
		|UpdateItemsSoldTogether,
		|SMSDeliveryStatusUpdate,
		|BotsProcessing,
		|UserNotificationsOfEvents,
		|SendSMSMessage,
		|SegmentClearance,
		|RebuildAggregates,
		|SendReceiveEmails,
		|PostingToPartnersARAPAccounting,
		|CalculationOfAnalysisOptionDataSources,
		|CalculationOfPackageConsumptionForecast,
		|CreatePickingJobs,
		|CreateGoodsRecountJobs,
		|CreateTransferJobs,
		|CreatingSpendingOrders,
		|NewPerformerTaskNotifications,
		|ObsoleteSynchronizationDataDeletion,
		|DeleteDeferredCashRegisterReceipts,
		|SegmentGeneration");
	
	JobParameters = New Structure("Use", True);
	ArrayOfTasks = ScheduledJobsServer.FindJobs(JobParameters); // Array of ScheduledJob - 
	
	JobParameters = New Structure("Use", False);
	
	For Each Job In ArrayOfTasks Do
		
		If UnusedTasks.Property(Job.Metadata.Name) Then
			ScheduledJobsServer.ChangeJob(Job.UUID, JobParameters);
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region SwitchingToProfVersion

// Handler for switching to the PROF version.
//
Procedure UpgradeFromBasicVersionToPROF() Export
	
	Common.CommonSettingsStorageSave("SwitchingFromBasicVersionToProf","ThisIsTransitionFromBasicVersionToProf",True);
	
	BaseVersion = StandardSubsystemsServer.IsBaseConfigurationVersion();
	
	ConstantValues = New Structure;
	ConstantValues.Insert("BaseVersion",                   BaseVersion);
	ConstantValues.Insert("UseAccessManagement",  Not BaseVersion);
	ConstantValues.Insert("TradeManagement",             True);
	ConstantValues.Insert("EmployeeInChargeInDocuments",        Not BaseVersion);
	ConstantValues.Insert("NotBaseVersion",                 Not BaseVersion);
	
	For Each KeyAndValue In ConstantValues Do
		Constants[KeyAndValue.Key].Set(KeyAndValue.Value);
	EndDo; 
	
	RefreshReusableValues();
	
EndProcedure
 
#EndRegion

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure WhenAddingUTUpdateHandlers(Handlers) Export

#Region FirstRun

	Handler = Handlers.Add();
	Handler.Procedure = "InfobaseUpdateTM.FirstRun";
	Handler.Version = "";
	Handler.ExecutionMode = "Exclusively";
	Handler.InitialFilling = True;
	Handler.Comment = "";

#EndRegion

#Region CreatePredefinedPropertiesSets

	Handler = Handlers.Add();
	Handler.Version = "11.5.14.39";
	Handler.Procedure = "PropertyManagerInternal.CreatePredefinedPropertiesSets";
	Handler.ExecutionMode = "Seamless";

#EndRegion

#Region AddRightsToCounterpartiesBankAccountsToUserProfiles

	Handler = Handlers.Add();
	Handler.Procedure = "InfobaseUpdateTM.AddRightsToCounterpartiesBankAccountsToUserProfiles";
	Handler.Version = "11.5.23.14";
	Handler.ExecutionMode = "Seamless";
	Handler.Id = New UUID("ec8aba8b-695c-4fb8-98a0-6e3229f59213");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Catalogs.AccessGroupProfiles.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Catalogs.AccessGroupProfiles.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	Handler.Comment = NStr("vi = 'Bố sung hồ sơ tự tạo của nhóm truy cập bằng các vai trò mới
		|""Thêm thay đổi tài khoản ngân hàng của đối tác"", ""Đọc tài khoản ngân hàng của đối tác"" .';
		|ru = 'Дополняет пользовательские профили групп доступа новыми ролями
		|""Добавление изменение банковских счетов контрагентов"", ""Чтение банковских счетов контрагентов"" .';
		|en = 'Adds new roles (Add and edit counterparty bank accounts, Read counterparty bank accounts)
		|to the user access group profiles.'; fa = 'Adds new roles (Add and edit counterparty bank accounts, Read counterparty bank accounts)
		|to the user access group profiles.';
		|it = 'Adds new roles (Add and edit counterparty bank accounts, Read counterparty bank accounts)
		|to the user access group profiles.';
		|pl = 'Adds new roles (Add and edit counterparty bank accounts, Read counterparty bank accounts)
		|to the user access group profiles.';
		|tr = 'Erişim gruplarının kullanıcı profillerine yeni roller ekler
		|""Cari hesap banka hesabının eklenmesi ve değiştirilmesi"", ""Cari hesap banka muhasebesinin okunması"".'");

#EndRegion

#Region NumberOfBackdateJobQueueStreams

	Handler = Handlers.Add();
	Handler.Procedure = "InfobaseUpdateTM.SetNumberOfThreadsInNonOperationalJobQueue";
	Handler.Version = "11.5.23.17";
	Handler.ExecutionMode = "Seamless";
	Handler.Id = New UUID("f040a124-3d63-11ea-81fa-c7cc1f049a75");
	Handler.UpdateDataFillingProcedure = "InfobaseUpdateTM.NumberOfThreadsInNonOperationalJobQueue_RegisterDataForProcessingToUpgradeToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Comment = NStr("vi = 'Đang đặt số lượng luồng trong hàng đợi nhiệm vụ không hoạt động';
							|ru = 'Устанавливает количество потоков неоперативной очереди заданий';
							|en = 'Sets the number of backdate job queue threads'; fa = 'Sets the number of backdate job queue threads';
							|it = 'Sets the number of backdate job queue threads';
							|pl = 'Sets the number of backdate job queue threads';
							|tr = 'Operasyonel olmayan iş kuyruğunun iş parçacığı miktarını ayarlar'");
	Handler.SharedData = True;
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Constants.NumberOfBackdateJobQueueStreams.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Constants.NumberOfBackdateJobQueueStreams.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");

#EndRegion

#Region SetConstantOrderOfWorkWhenPerformingVMRMKTask
	
	Handler = Handlers.Add();
	Handler.Procedure = "InfobaseUpdateTM.SetConstantOrderOfWorkWhenPerformingVMRMKTask";
	Handler.Version = "11.5.26.53";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("9f48fee9-15ad-486b-8b8b-21b56fd73e24");
	Handler.UpdateDataFillingProcedure = "InfobaseUpdateTM.HowToWorkWhenCompletingTaskVMRMC_RegisterDataForProcessingToUpgradeToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Comment = NStr("vi = 'Đang thiết lập giá trị của hằng ""Trình tự làm việc khi thực hiện nhiệm vụ tại chỗ làm việc di động của thủ  kho"".';
							|ru = 'Устанавливает значение константы ""Порядок работы при выполнении задания в МРМК"".';
							|en = 'Sets the ""Procedure of job execution in MWPW"" constant value'; fa = 'Sets the ""Procedure of job execution in MWPW"" constant value';
							|it = 'Sets the ""Procedure of job execution in MWPW"" constant value';
							|pl = 'Sets the ""Procedure of job execution in MWPW"" constant value';
							|tr = '""MRMK görev yürütme prosedürü"" sabiti değerini ayarlar.'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Constants.OrderOfWorkWhenPerformingTaskMCW.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
		
	Editable1 = New Array;
	Editable1.Add(Metadata.Constants.OrderOfWorkWhenPerformingTaskMCW.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
#EndRegion

EndProcedure

// Fills in an empty field of the object with the default value of the props. 
//
// Parameters:
//  Parameters			 - Structure - update handler parameters passed to the handler when it is started 
//  FullObjectName	 - String - full name of the object, such as Document.Prednisoneonline 
//  AttributeName		 - String - name of the information to fill in
//  SourceValue	 - Arbitrary - the original value of the props. If the object has a different value at the time of processing,
//										it will be marked processed without changing the details.
//  FinalValue_	 - Arbitrary - the new value of the props that will be assigned during processing.
//
Procedure ReplacePropsValue(Parameters, FullObjectName, AttributeName, SourceValue, FinalValue_) Export
	
	ObjectsForProcessing = InfobaseUpdate.SelectRefsToProcess(Parameters.Queue, FullObjectName);
	ObjectMetadata = Metadata.FindByFullName(FullObjectName);
			
	
	While ObjectsForProcessing.Next() Do
		BeginTransaction();
		
		Try
			
			// We set a controlled lock to conduct a responsible reading of the object.
			Block = New DataLock;
			
			LockItem = Block.Add(FullObjectName);
			LockItem.SetValue("Ref", ObjectsForProcessing.Ref);
			
			Block.Lock();
			
			Object = ObjectsForProcessing.Ref.GetObject();
			
			If Object = Undefined Then
				RollbackTransaction();
				InfobaseUpdate.MarkProcessingCompletion(ObjectsForProcessing.Ref);
				Continue;
			EndIf;
			
			If Object[AttributeName] <> SourceValue Then
				InfobaseUpdate.MarkProcessingCompletion(Object);
			Else
				Object[AttributeName] = FinalValue_;
				InfobaseUpdate.WriteData(Object);
			EndIf;
			
		    CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			MessageText = NStr("vi = 'Không thể xử lý %ObjectName%: %Ref% theo nguyên nhân: %Cause%';
								|ru = 'Не удалось обработать %ObjectName%: %Ref% по причине: %Cause%';
								|en = 'Cannot process %ObjectName%: %Ref%. Reason: %Cause%'; fa = 'Cannot process %ObjectName%: %Ref%. Reason: %Cause%';
								|it = 'Impossibile elaborare %ObjectName%: %Ref%  a causa di : %Cause%';
								|pl = 'Przetwarzanie %ObjectName%: %Ref% nie powiodło się z powodu: %Cause%';
								|tr = '%Cause% nedeniyle %ObjectName% %Ref% işlenemedi'");
			MessageText = StrReplace(MessageText, "%ObjectName%", FullObjectName);
			MessageText = StrReplace(MessageText, "%Ref%", ObjectsForProcessing.Ref);
			MessageText = StrReplace(MessageText, "%Cause%", DetailErrorDescription(ErrorInfo()));
			
			WriteLogEvent(InfobaseUpdate.EventLogEvent(),
										EventLogLevel.Warning,
										ObjectMetadata,
										ObjectsForProcessing.Ref,
										MessageText);
			
		EndTry;
		
	EndDo;	
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
EndProcedure

// Registers objects for processing that have the passed-in value.
//
// Parameters:
//  Parameters			 - Structure - update handler parameters passed to the handler when it is started 
//  FullObjectName	 - String - full name of the object, such as Document.Prednisoneonline 
//  AttributeName		 - String - name of the information to fill in
//  SourceValue	 - Arbitrary - payment details will be marked for processing.
//
Procedure ReplaceValueOfPropsToRegisterDataForProcessing(Parameters, FullObjectName, AttributeName, SourceValue) Export
  
	Query = New Query;
	
	QueryText =
	"SELECT
	|	ObjectTable.Ref AS Ref 
	|FROM
	|	&FullObjectName AS ObjectTable
	|WHERE
	|	ObjectTable.AttributeName = &SourceValue";
		
	Query.SetParameter("SourceValue", SourceValue);
	
	QueryText = StrReplace(QueryText, "&FullObjectName", FullObjectName);
	QueryText = StrReplace(QueryText, "AttributeName", AttributeName);
	
	Query.Text = QueryText;
	
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

Procedure ReportFailedLock(Ref) Export
	MessageText = NStr("vi = 'Không thể khóa đối tượng: %Object% do: %Cause%';
						|ru = 'Не удалось заблокировать объект: %Object% по причине: %Cause%';
						|en = 'Cannot lock the object: %Object%. Reason: %Cause%'; fa = 'Cannot lock the object: %Object%. Reason: %Cause%';
						|it = 'Impossibile bloccare l''oggetto: %Object% motivo: %Cause%';
						|pl = 'Zablokowanie obiektu nie powiodło się: %Object% z powodu: %Cause%';
						|tr = 'Nesne kilitlenemedi: %Object% şu nedenle: %Cause%'");
	MessageText = StrReplace(MessageText, "%Object%", Ref);
	MessageText = StrReplace(MessageText, "%Cause%", DetailErrorDescription(ErrorInfo()));
	WriteLogEvent(InfobaseUpdate.EventLogEvent(),
							EventLogLevel.Warning,
							Ref.Metadata(),
							Ref,
							MessageText);
EndProcedure

Procedure FillInValueOfSeparationByDataAreas() Export
	
	If Constants.DoNotUseSeparationByDataAreas.Get() Then
		Constants.DoNotUseSeparationByDataAreasAndThisPA.Set(Constants.ComplexAutomation.Get());
		Constants.DoNotUseSeparationByDataAreasAndThisTM.Set(Constants.TradeManagement.Get());
	Else
		Constants.DoNotUseSeparationByDataAreasAndThisPA.Set(False);
		Constants.DoNotUseSeparationByDataAreasAndThisTM.Set(False);
	EndIf;
	
EndProcedure

#Region ContactInformation

Function ContactInformationKindParameters(Type)
	
	KindParameters = ContactsManager.ContactInformationKindParameters(Type);
	KindParameters.Type = Type;
	KindParameters.CanChangeEditMethod = True;
	KindParameters.Insert("AddressRussianOnly", False);
	
	Return KindParameters;
	
EndFunction

// The procedure for updating information security for the Catalog of types of contact information.
//
// Instructions:
// For each object, the owner of the CI, for each type of CI corresponding to it, add 
// a line of the form: Update the views (.....). At
// the same time, the order in which these calls will be made is important, the earlier the call for the type of CI,
// the higher this type of CI will be located on the Form of the object.
//
Procedure FillInPropertiesOfContactInformationTypes() Export
	
	// Standard Subsystems 
	// Standard subsystems.Users
	ParametersOfCIType = ContactInformationKindParameters(Enums.ContactInformationTypes.Email);
	ParametersOfCIType.Kind = Catalogs.ContactInformationKinds.UserEmail;
	ParametersOfCIType.Order = 1;
	UpdateKiView(ParametersOfCIType);
	
	ParametersOfCIType = ContactInformationKindParameters(Enums.ContactInformationTypes.Phone);
	ParametersOfCIType.Kind = Catalogs.ContactInformationKinds.UserPhone;
	ParametersOfCIType.Order = 2;
	UpdateKiView(ParametersOfCIType);
	// End StandardSubsystems.Users
	
	// StandardSubsystems.Companies
	ParametersOfCIType = ContactInformationKindParameters(Enums.ContactInformationTypes.Address);
	ParametersOfCIType.Kind = Catalogs.ContactInformationKinds.LegalAddressOfCompany;
	ParametersOfCIType.StoreChangeHistory = True;
	ParametersOfCIType.AddressRussianOnly = True;
	ParametersOfCIType.Order = 12;
	UpdateKiView(ParametersOfCIType);
	
	ParametersOfCIType = ContactInformationKindParameters(Enums.ContactInformationTypes.Address);
	ParametersOfCIType.Kind = Catalogs.ContactInformationKinds.ActualDataAddressOfCompany;
	ParametersOfCIType.Order = 13;
	UpdateKiView(ParametersOfCIType);
	
	ParametersOfCIType = ContactInformationKindParameters(Enums.ContactInformationTypes.Address);
	ParametersOfCIType.Kind = Catalogs.ContactInformationKinds.InternationalAddressOfCompany;
	ParametersOfCIType.Order = 14;
	UpdateKiView(ParametersOfCIType);
	
	ParametersOfCIType = ContactInformationKindParameters(Enums.ContactInformationTypes.Phone);
	ParametersOfCIType.Kind = Catalogs.ContactInformationKinds.CompanyPhone;
	ParametersOfCIType.Order = 15;
	UpdateKiView(ParametersOfCIType);
	
	ParametersOfCIType = ContactInformationKindParameters(Enums.ContactInformationTypes.Fax);
	ParametersOfCIType.Kind = Catalogs.ContactInformationKinds.CompanyFax;
	ParametersOfCIType.Order = 16;
	UpdateKiView(ParametersOfCIType);
	
	ParametersOfCIType = ContactInformationKindParameters(Enums.ContactInformationTypes.Email);
	ParametersOfCIType.Kind = Catalogs.ContactInformationKinds.EmailCompanies;
	ParametersOfCIType.Order = 17;
	UpdateKiView(ParametersOfCIType);
	
	ParametersOfCIType = ContactInformationKindParameters(Enums.ContactInformationTypes.Address);
	ParametersOfCIType.Kind = Catalogs.ContactInformationKinds.CompanyPostalAddress;
	ParametersOfCIType.Order = 18;
	UpdateKiView(ParametersOfCIType);
	
	ParametersOfCIType = ContactInformationKindParameters(Enums.ContactInformationTypes.Other);
	ParametersOfCIType.Kind = Catalogs.ContactInformationKinds.OtherInformationOfCompany;
	ParametersOfCIType.Order = 19;
	UpdateKiView(ParametersOfCIType);
	// The end of the standard subsystem.Organizations
	// End of the standardsystem 
	
	// Reference Book " Contractors"
	ParametersOfCIType = ContactInformationKindParameters(Enums.ContactInformationTypes.Address);
	ParametersOfCIType.Kind = Catalogs.ContactInformationKinds.ActualDataCounterpartyAddress;
	ParametersOfCIType.Order = 3;
	UpdateKiView(ParametersOfCIType);
		
	ParametersOfCIType = ContactInformationKindParameters(Enums.ContactInformationTypes.Address);
	ParametersOfCIType.Kind = Catalogs.ContactInformationKinds.LegalAddressOfCounterparty;
	ParametersOfCIType.Order = 4;
	UpdateKiView(ParametersOfCIType);
		
	ParametersOfCIType = ContactInformationKindParameters(Enums.ContactInformationTypes.Address);
	ParametersOfCIType.Kind = Catalogs.ContactInformationKinds.PostalAddressOfCounterparty;
	ParametersOfCIType.Order = 5;
	UpdateKiView(ParametersOfCIType);
		
	ParametersOfCIType = ContactInformationKindParameters(Enums.ContactInformationTypes.Address);
	ParametersOfCIType.Kind = Catalogs.ContactInformationKinds.InternationalAddressOfCounterparty;
	ParametersOfCIType.Order = 6;
	UpdateKiView(ParametersOfCIType);
		
	ParametersOfCIType = ContactInformationKindParameters(Enums.ContactInformationTypes.Phone);
	ParametersOfCIType.Kind = Catalogs.ContactInformationKinds.CounterpartySPhoneNumber;
	ParametersOfCIType.Order = 7;
	UpdateKiView(ParametersOfCIType);
		
	ParametersOfCIType = ContactInformationKindParameters(Enums.ContactInformationTypes.Fax);
	ParametersOfCIType.Kind = Catalogs.ContactInformationKinds.FaxCounterparties;
	ParametersOfCIType.Order = 8;
	UpdateKiView(ParametersOfCIType);
		
	ParametersOfCIType = ContactInformationKindParameters(Enums.ContactInformationTypes.Email);
	ParametersOfCIType.Kind = Catalogs.ContactInformationKinds.EmailCounterparty_;
	ParametersOfCIType.Order = 9;
	UpdateKiView(ParametersOfCIType);
		
	ParametersOfCIType = ContactInformationKindParameters(Enums.ContactInformationTypes.Other);
	ParametersOfCIType.Kind = Catalogs.ContactInformationKinds.OtherInformationOfCounterparties;
	ParametersOfCIType.Order = 10;
	UpdateKiView(ParametersOfCIType);
	
	// The Directory "Partners"
	ParametersOfCIType = ContactInformationKindParameters(Enums.ContactInformationTypes.Address);
	ParametersOfCIType.Kind = Catalogs.ContactInformationKinds.PartnerAddress;
	ParametersOfCIType.Order = 6;
	UpdateKiView(ParametersOfCIType);
	
	ParametersOfCIType = ContactInformationKindParameters(Enums.ContactInformationTypes.Phone);
	ParametersOfCIType.Kind = Catalogs.ContactInformationKinds.PartnerSPhoneNumber;
	ParametersOfCIType.Order = 7;
	UpdateKiView(ParametersOfCIType);
	
	ParametersOfCIType = ContactInformationKindParameters(Enums.ContactInformationTypes.Email);
	ParametersOfCIType.Kind = Catalogs.ContactInformationKinds.EmailPartner_;
	ParametersOfCIType.Order = 8;
	UpdateKiView(ParametersOfCIType);
	
	// Directory "Contact persons of partners"
	ParametersOfCIType = ContactInformationKindParameters(Enums.ContactInformationTypes.Phone);
	ParametersOfCIType.Kind = Catalogs.ContactInformationKinds.ContactPersonSPhoneNumber;
	ParametersOfCIType.Order = 9;
	UpdateKiView(ParametersOfCIType);
	
	ParametersOfCIType = ContactInformationKindParameters(Enums.ContactInformationTypes.Phone);
	ParametersOfCIType.Kind = Catalogs.ContactInformationKinds.ContactPersonSMobilePhoneNumber;
	ParametersOfCIType.Order = 10;
	UpdateKiView(ParametersOfCIType);
	
	ParametersOfCIType = ContactInformationKindParameters(Enums.ContactInformationTypes.Email);
	ParametersOfCIType.Kind = Catalogs.ContactInformationKinds.EmailContactPerson;
	ParametersOfCIType.Order = 11;
	UpdateKiView(ParametersOfCIType);
	
	// Reference book " Individuals"
	ParametersOfCIType = ContactInformationKindParameters(Enums.ContactInformationTypes.Email);
	ParametersOfCIType.Kind = Catalogs.ContactInformationKinds.EMailPersons;
	ParametersOfCIType.Order = 19;
	UpdateKiView(ParametersOfCIType);
	
	ParametersOfCIType = ContactInformationKindParameters(Enums.ContactInformationTypes.Phone);
	ParametersOfCIType.Kind = Catalogs.ContactInformationKinds.MobilePhoneOfPerson;
	ParametersOfCIType.Order = 20;
	UpdateKiView(ParametersOfCIType);
	
	ParametersOfCIType = ContactInformationKindParameters(Enums.ContactInformationTypes.Phone);
	ParametersOfCIType.Kind = Catalogs.ContactInformationKinds.WorkingPhoneNumberOfPerson;
	ParametersOfCIType.Order = 22;
	UpdateKiView(ParametersOfCIType);
	
	ParametersOfCIType = ContactInformationKindParameters(Enums.ContactInformationTypes.Address);
	ParametersOfCIType.Kind = Catalogs.ContactInformationKinds.AddressForInformingPersons;
	ParametersOfCIType.Order = 23;
	UpdateKiView(ParametersOfCIType);
	
	ParametersOfCIType = ContactInformationKindParameters(Enums.ContactInformationTypes.Phone);
	ParametersOfCIType.Kind = Catalogs.ContactInformationKinds.HomePhoneNumberOfPerson;
	ParametersOfCIType.Order = 24;
	UpdateKiView(ParametersOfCIType);
	
	ParametersOfCIType = ContactInformationKindParameters(Enums.ContactInformationTypes.Address);
	ParametersOfCIType.Kind = Catalogs.ContactInformationKinds.AddressOutsideRussianFederationPersons;
	ParametersOfCIType.Order = 25;
	UpdateKiView(ParametersOfCIType);
	
	ParametersOfCIType = ContactInformationKindParameters(Enums.ContactInformationTypes.Address);
	ParametersOfCIType.Kind = Catalogs.ContactInformationKinds.RegistrationAddressPersons;
	ParametersOfCIType.Order = 26;
	UpdateKiView(ParametersOfCIType);
	
	ParametersOfCIType = ContactInformationKindParameters(Enums.ContactInformationTypes.Address);
	ParametersOfCIType.Kind = Catalogs.ContactInformationKinds.ResidentialAddressPersons;
	ParametersOfCIType.Order = 27;
	UpdateKiView(ParametersOfCIType);
	
	// Reference " Warehouses"
	ParametersOfCIType = ContactInformationKindParameters(Enums.ContactInformationTypes.Address);
	ParametersOfCIType.Kind = Catalogs.ContactInformationKinds.WarehouseAddress;
	ParametersOfCIType.Order = 28;
	UpdateKiView(ParametersOfCIType);
	
	ParametersOfCIType = ContactInformationKindParameters(Enums.ContactInformationTypes.Phone);
	ParametersOfCIType.Kind = Catalogs.ContactInformationKinds.WarehousePhone;
	ParametersOfCIType.Order = 29;
	UpdateKiView(ParametersOfCIType);
	
	// Directory "Registration with the tax authority"
	ParametersOfCIType = ContactInformationKindParameters(Enums.ContactInformationTypes.Address);
	ParametersOfCIType.Kind = Catalogs.ContactInformationKinds.TaxAuthorityAddress;
	ParametersOfCIType.Order = 30;
	UpdateKiView(ParametersOfCIType);
	
	ParametersOfCIType = ContactInformationKindParameters(Enums.ContactInformationTypes.Phone);
	ParametersOfCIType.Kind = Catalogs.ContactInformationKinds.TaxAuthorityPhone;
	ParametersOfCIType.Order = 31;
	UpdateKiView(ParametersOfCIType);
	
	ParametersOfCIType = ContactInformationKindParameters(Enums.ContactInformationTypes.Address);
	ParametersOfCIType.Kind = Catalogs.ContactInformationKinds.ActualAddressOfBranchOffice;
	ParametersOfCIType.Order = 32;
	UpdateKiView(ParametersOfCIType);

	// Directory "Retail outlets"
	ParametersOfCIType = ContactInformationKindParameters(Enums.ContactInformationTypes.Address);
	ParametersOfCIType.Kind = Catalogs.ContactInformationKinds.OutletAddress;
	ParametersOfCIType.Order = 33;
	UpdateKiView(ParametersOfCIType);
	
EndProcedure

Procedure UpdateKiView(ParametersOfCIType)

	ValidationSettings = New Structure;
	ValidationSettings.Insert("AddressRussianOnly", 		ParametersOfCIType.AddressRussianOnly);
	ValidationSettings.Insert("CheckValidity", 		False);
	ValidationSettings.Insert("ProhibitInvalidEntry", 	False);
	ValidationSettings.Insert("HideObsoleteAddresses", 	False);
	ValidationSettings.Insert("IncludeCountryInPresentation", 	False);
	ValidationSettings.Insert("PhoneWithExtensionNumber", 	True);
	
	ContactsManager.SetContactInformationKindProperties(ParametersOfCIType);
	
EndProcedure

#EndRegion

#Region AddRightsToCounterpartiesBankAccountsToUserProfiles

Procedure AddRightsToCounterpartiesBankAccountsToUserProfiles() Export
	
	RolesToReplace = New Map();
	
	NewRoles = New Array();
	NewRoles.Add("AddEditInformationAboutPartners");
	NewRoles.Add("AddEditCounterpartyBankAccounts");
	
	RolesToReplace.Insert(NewRoles[0], NewRoles);
	
	NewRoles = New Array();
	NewRoles.Add("ReadInformationAboutPartners");
	NewRoles.Add("ReadCounterpartyBankAccounts");
	
	RolesToReplace.Insert(NewRoles[0], NewRoles);
	
	AccessManagement.ReplaceRolesInProfiles(RolesToReplace);
	
EndProcedure

#EndRegion

#Region NumberOfBackdateJobQueueStreams

Procedure NumberOfThreadsInNonOperationalJobQueue_RegisterDataForProcessingToUpgradeToNewVersion(Parameters) Export
	
	// Registration is not required
	Return;
	
EndProcedure

Procedure SetNumberOfThreadsInNonOperationalJobQueue(Parameters = Undefined) Export
	
	ThreadsCount = Constants.NumberOfBackdateJobQueueStreams.Get();
	If ThreadsCount = 0 Then
		ThreadsCount = 8;
	EndIf;
	
	Constants.NumberOfBackdateJobQueueStreams.Set(ThreadsCount);

EndProcedure

#EndRegion

#Region SettingConstant_OperatingProcedureWhenPerformingVMRMKTask

Procedure HowToWorkWhenCompletingTaskVMRMC_RegisterDataForProcessingToUpgradeToNewVersion(Parameters) Export
	
	// Registration is not required
	Return;
	
EndProcedure

Procedure SetConstantOrderOfWorkWhenPerformingVMRMKTask(ParametersOfUpdate) Export
	
	If Not ValueIsFilled(Constants.OrderOfWorkWhenPerformingTaskMCW.Get()) Then
		Constants.OrderOfWorkWhenPerformingTaskMCW.Set(Enums.OrderOfWorkWhenPerformingTaskMCW.FirstScanCell);
	EndIf;
	
	ParametersOfUpdate.ProcessingCompleted = True;
	
EndProcedure

#EndRegion

// Returns the selection parameters for the next selection or strokable Values().
//
// Returns:
//  Structure - indexes for traversing tables with data to update:
//   * BatchIndex - Number - index of the row in the portion table;
//   * IndexOfRowInChunk - Number - index of the data string in the portion.
//   * DocumentTypes - Map of KeyAndValue - See ArrayOfNamesInMatchingTypes.
//   * FieldNameLogger - String - usually "Registrar", but can be, for example, and "link".
//
Function NewSelectionParameters()
	
	SelectionParameters = New Structure;
	SelectionParameters.Insert("BatchIndex", 0);
	SelectionParameters.Insert("IndexOfRowInChunk", 0);
	SelectionParameters.Insert("DocumentTypes", New Map);
	SelectionParameters.Insert("FieldNameLogger", "Recorder");
	
	Return SelectionParameters;
	
EndFunction

// Converting an array of names to match types with these names.
//
// Parameters:
//  Names - Array - names (for example: documents).
//  TypePrefix - String - prefix for forming the full name of the type (for example: "Document link").
//  NameIndex - Number - index of the type name, starting from 0 (for example: 1 in " Document.Document name").
//
// Returns:
//  Map:
//   Key-Type - the generated type.
//   The Value Is Boolean-True.
//
Function ArrayOfNamesInMatchingTypes(Names, TypePrefix, NameIndex)
	
	MapTypes = New Map;
	
	If TypeOf(Names) = Type("Array") Then
		StringType = Type("String");
		Template = "%1.%2";
		
		For Each Name In Names Do
			If TypeOf(Name) = StringType Then
				Content = StrSplit(Name, ".");
				
				If Content.UBound() >= NameIndex Then
					TypeName = TrimAll(Content[NameIndex]);
					Type = Type(StrTemplate(Template, TypePrefix, TypeName));
					MapTypes[Type] = True;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	Return MapTypes;
	
EndFunction

// Iterator for a query selection or a table of values.
//
// If the Selection parameter is of the "query resultset" type, this parameter will contain data from the selection.
// Otherwise, the selection is made from the table parameter, but the data to be processed is still placed in the Selection parameter.
// Applicable for selecting values from a query or table in a single loop.
//
// Parameters:
//  Selection - QueryResultSelection - the sample request.
//          - ValueTableRow - the return value if the selection is performed from the table of values.
//  UpdatedData - QueryResultSelection, ValueTable -
//                      Used if the selection Is not specified (equal to Undefined).
//  SelectionParameters - See NewSelectionParameters.
//
// Returns:
//  Boolean - True if the Selection (return value) contains data to be processed.
//
Function NextSelectionOrRowOfValueTable(Selection, UpdatedData, SelectionParameters)
	
	If TypeOf(Selection) = Type("QueryResultSelection") Then
		Return Selection.Next();
	Else
		BatchIndex = SelectionParameters.BatchIndex;
		IndexOfRowInChunk = SelectionParameters.IndexOfRowInChunk;
		DocumentTypes = SelectionParameters.DocumentTypes;
		FieldNameLogger = SelectionParameters.FieldNameLogger;
		Selected = False;
		
		While Not Selected Do
			If BatchIndex >= UpdatedData.DataSet.Count() Or BatchIndex < 0 Then
				Return False;
			EndIf;
			
			Batch = UpdatedData.DataSet[BatchIndex].Data;
			PortionSize = Batch.Count();
			
			If IndexOfRowInChunk >= PortionSize Or IndexOfRowInChunk < 0 Then
				Return False;
			EndIf;
			
			PreliminarySelection = Batch[IndexOfRowInChunk];
			DocumentType = TypeOf(PreliminarySelection[FieldNameLogger]);
			
			If DocumentTypes.Count() = 0 Or DocumentTypes[DocumentType] = True Then
				Selection = PreliminarySelection;
				Selected = True;
			EndIf;
			
			SelectionParameters.IndexOfRowInChunk = SelectionParameters.IndexOfRowInChunk + 1;
			
			If SelectionParameters.IndexOfRowInChunk >= PortionSize Then
				SelectionParameters.BatchIndex = SelectionParameters.BatchIndex + 1;
				SelectionParameters.IndexOfRowInChunk = 0;
				Return Selected;
			EndIf;
		EndDo;
		
		Return True;
	EndIf;
	
EndFunction

// Get document names as an array.
//
// Parameters:
//  FullNamesOfDocuments - String, Array, Undefined - name of the document that you want to re-form movements for.
//                          For Example, " Document.Prednisoneonline".
//                          If there are several documents, you need to pass their names in the array.
//
// Returns:
//  Array - full names of the documents.
//
Function DocumentNamesInArray(FullNamesOfDocuments)
	
	If TypeOf(FullNamesOfDocuments) = Type("String") Then
		DocumentsList = StrSplit(FullNamesOfDocuments, ",", False);
		
		For IndexOf = 0 To DocumentsList.UBound() Do
			DocumentsList[IndexOf] = TrimAll(DocumentsList[IndexOf]);
		EndDo;
	Else
		DocumentsList = FullNamesOfDocuments;
	EndIf;
	
	Return DocumentsList;
	
EndFunction

// Get register names as an array.
//
// Parameters:
//  FullRegistersNames - String, Array - name of the register to use for re-forming movements.
//                         For Example, " Accumulation Register.Tourinclude".
//                         If there are several registers, their names must be passed in the array.
//
// Returns:
//  Array - full register names.
//
Function RegisterNamesInArray(FullRegistersNames)
	
	If TypeOf(FullRegistersNames) = Type("String") Then
		RegistersList = StrSplit(FullRegistersNames, ",", False);
	Else
		RegistersList = FullRegistersNames;
	EndIf;
	
	Return RegistersList;
	
EndFunction

// Checks whether the first digit of the version is filled in correctly.
//
// Parameters:
//   UpdateIterations     - Array - an array of structures describing information about updating each
//                                     library and configuration, with keys:
//       * Subsystem              - String - name of the library or configuration.
//       * Version                  - String - for example, "2.1.3.39". Version number of the library (configuration).
//       * IsMainConfiguration - Boolean - True if this is the main configuration and not the library.
//       * Handlers             - ValueTable - all library update handlers, column descriptions
//                                    see the Information Database update.New Update processing table.
//       * CompletedHandlers  - ValueTree - executed update handlers, grouped by
//                                   library and version number, description of columns
//                                    see the Information Database update.New Update processing table.
//       * MainServerModuleName - String - name of the library module (configuration) that provides
//                                        basic information about it: name, version, and so on.
//       * MainServerModule      - CommonModule - a General library module (configuration) that provides
//                                        basic information about the library: name, version, and so on.
//       * PreviousVersion             - String - for example, "2.1.3.30". Version number of the library (configuration) before the update.
//
Procedure CheckVersionNumbers(UpdateIterations) Export
	
	DataProcessor = DataProcessors.UpdateHandlersDetails.Create();
	VersionErrors = New Array;
	For Each Subsystem In DataProcessor.SubsystemsToDevelop() Do
		For Each Iteration In UpdateIterations Do
			If Subsystem <> Iteration.Subsystem Then
				Continue;
			EndIf;
			
			If StrOccurrenceCount(Iteration.Version, ".") = 0 Then
				Continue;
			EndIf;
			
			FirstDigitOfVersion = StrSplit(Iteration.Version,".")[0];
			Errors = New Array;
			For Each Handler In Iteration.Handlers Do
				If StrOccurrenceCount(Handler.Version, ".") = 0 Then
					Continue;
				EndIf;
				FirstDigitOfHandler = StrSplit(Handler.Version,".")[0];
				If Number(FirstDigitOfHandler) > Number(FirstDigitOfVersion) Then
					Errors.Add(Chars.Tab + Handler.Version + " " + Handler.Procedure);
				EndIf;
			EndDo;
			If Errors.Count() > 0 Then
				VersionErrors.Add(New Structure("Subsystem, Errors", Subsystem + " " + Iteration.Version, Errors));
			EndIf;
		EndDo;
	EndDo;
	
	If VersionErrors.Count() Then
		MessageText = 
			"Detected_ not map first digits rooms versions u handlers_.
			|NextPages handlers never not executed:" + Chars.LF;
		For Each LongDesc In VersionErrors Do
			Text = LongDesc.Subsystem + ":" + Chars.LF;
			Text = Text + StrConcat(LongDesc.Errors, Chars.LF);
			MessageText = MessageText + ?(IsBlankString(MessageText), "", Chars.LF) + Text;
		EndDo;
		Raise MessageText;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
