#Region Public

// Returns whether the exchange plan is available for the basic or Pro version.
// Parameters:
//  ExchangePlan - ExchangePlanObject - Object of the exchange plan. 
// Returns:
//  Boolean - the availability criterion.
//
Function ThisIsCreationOfExchangeNode(ExchangePlan) Export
	
	CheckResult = True;
	
	If StandardSubsystemsServer.IsBaseConfigurationVersion() Then
		
		CheckResult = AvailabilityOfExchangePlanInBasicVersion(ExchangePlan.Metadata().Name);
		
	EndIf;
	
	If Not CheckResult Then
		
		EventName = DataExchangeServer.DataExchangeEventLogEvent();
		ErrorMessage = NStr("vi = 'Không thể ghi lại tùy chỉnh đồng bộ dữ liệu do 
			|đã bật sử dụng chứng từ điều chỉnh (đảo ngược).';
			|ru = 'Нельзя записать настройки синхронизации данных из-за того, 
			|что включено использование исправительных документов (сторнирование).';
			|en = 'Cannot save data synchronization settings due to
			|the use of correction documents (reversal).'; fa = 'Cannot save data synchronization settings due to
			|the use of correction documents (reversal).';
			|it = 'Impossibile registrare le impostazioni di sincronizzazione dati perché
			| è abilitato l''uso di documenti correttivi (storno).';
			|pl = 'Nie można zapisać ustawień synchronizacji danych z ponieważ, 
			|jest włączone użycie dokumentów korygujących (stornowanie).';
			|tr = 'Düzeltme belgelerinin kullanımı etkin olduğu 
			|için veri senkronizasyon ayarları kaydedilemiyor (iptal).'", Common.DefaultLanguageCode());
		
		WriteLogEvent(EventName, EventLogLevel.Warning, , , ErrorMessage);
		
	EndIf;
	
	Return CheckResult;
	
EndFunction

// Returns whether the exchange plan is available for the basic or Pro version
//
// Parameters:
//   ExchangePlan - MetadataObject - Metadata of the exchange plan that you want to check whether it can be created.
//
// Returns:
//   Boolean - True, if the exchange plan node can be created in this configuration version.
//
Function CheckingPossibilityOfCreatingExchangeNode(ExchangePlan) Export
	
	
	If StandardSubsystemsServer.IsBaseConfigurationVersion() Then
		Return AvailabilityOfExchangePlanInBasicVersion(ExchangePlan.Name);
	EndIf;

	InformationAboutExchanges = GeneralInformationAboutConfiguredExchanges();
	
	If InformationAboutExchanges.EDExchange Or InformationAboutExchanges.XMLExchange 
		And GetFunctionalOption("UseDocumentCorrection") Then
		Return False;
	EndIf;

	
	Return True;
	
EndFunction

// Blocks changing the settings of the exchange plan node
// in the subordinate node of the distributed information database.
//
// Parameters:
//   Form - ClientApplicationForm - The form whose elements you want to block.
//
Procedure SetAvailabilityOfInformationBaseNodeSettings(Form) Export
	
	If DataExchangCashedTMERP.ItIsSubordinateNodeToRibsBySelection() Then
	
		TMCommonUseClientServer.SetFormItemProperty(
			Form.Items,
			"BlockingExplanationGroup",
			"Visible",
			True);

		For Each FormItem In Form.Items Do
			
			If TypeOf(FormItem) = Type("FormField") Then
				
				TMCommonUseClientServer.SetFormItemProperty(
					Form.Items,
					FormItem.Name,
					"Enabled",
					False);
					
			EndIf;
				
		EndDo; 
		
	EndIf;
	
EndProcedure

// Returns information about which types of exchanges are configured.
//
// Returns:
//   Structure:
//       * RIBExchange     - Boolean - RIB exchanges are used
//       * EDExchange      - Boolean - exchanges in the EnterpriseData format are used
//       * XMLExchange     - Boolean - exchanges are used according to xml rules.
//
Function GeneralInformationAboutConfiguredExchanges() Export

	InformationRecords = New Structure();
	InformationRecords.Insert("RIBExchange", False);
	InformationRecords.Insert("EDExchange",  False);
	InformationRecords.Insert("XMLExchange", False);
	
	
	Return InformationRecords;

EndFunction

// Creates a list of exchange plans available for creation
Procedure ExchangePlansList(SubsystemExchangePlans) Export
	
	
EndProcedure

// It is intended for accurate identification of the name of this configuration when configuring 
// data synchronization in the service model.
// If this configuration is based on the original configuration
// and should support exchange with other application solutions using an exchange plan
// taken from the original configuration, then return the name of the original configuration.
// For example, for the Myabuhgalteria configuration, which is a modified enterprise Accounting configuration,
// you should return enterprise Accounting.
//
// Used only for exchange plans in the service model.
//
// Returns:
//	String - the name of this or another configuration on behalf of which the data exchange is performed
//			(the name of the configuration as specified in the metadata).
//
// Example:
//  Return " Bookkeeping Enterprises";
//
Function SourceConfigurationName() Export
	Return "EnterpriseManagement";
EndFunction

// Handler for registering changes for the initial data upload.
// Used to override the standard change registration processing.
// During standard processing, changes to all data from the exchange plan will be registered.
// If the exchange plan has data migration restriction filters,
// using this handler will improve the performance of the initial data upload.
// In the handler, you should implement change registration based on data migration restriction filters.
// If the exchange plan uses migration restrictions by date or by date and company,
// you can use the universal procedure
// Abendanimation.Register your data to be sent to the shipping companies.
// The handler is only used for universal data exchange using exchange rules
// and for universal data exchange without exchange rules, and is not used for exchanges in the rib.
// Using the handler allows you to increase the performance
// of the initial data upload by an average of 2-4 times.
//
// Parameters:
//   Recipient           - ExchangePlanRef - the site plan of exchange to which you want to upload data.
//   StandardProcessing - Boolean           - This parameter is passed to indicate that standard (system)
//                                             event processing is performed. If this parameter is set to False in the body of the handler procedure, 
//                                             standard event processing will not be performed. Rejecting standard processing
//                                             does not cancel the action. The default value is True.
//   Filter                - Structure        - The structure containing the selection data.
//
Procedure RegisteringChangeForInitialUpload(Recipient, StandardProcessing, Filter) Export
	
	If TypeOf(Recipient) = Type("ExchangePlanRef.DataSynchronizationViaUniversalFormat") Then
		
		StandardProcessing = False;
		
		AttributesValues = Common.ObjectAttributesValues(Recipient, "UseFilterByCompanies, 
			|DocumentsExportStartDate, 
			|Companies, 
			|UnloadManagementCompany,
			|CatalogsSendingRules,
			|DocumentsSendingRules,
			|SettingsMode");
		
		Companies = ?(AttributesValues.UseFilterByCompanies,
			AttributesValues.Companies.Unload().UnloadColumn("Organization"), Undefined);
			
		If Companies = Undefined
			And Not AttributesValues.UnloadManagementCompany Then
			
			Query = New Query("SELECT
				|	Companies.Ref AS Organization
				|FROM
				|	Catalog.Companies AS Companies
				|WHERE
				|	Companies.DeletionMark = FALSE
				|	AND Companies.Ref <> VALUE(Catalog.Companies.ManagementCompany)
				|
				|GROUP BY
				|	Companies.Ref");
			
			Result = Query.Execute();
			
			If Not Result.IsEmpty() Then
				Companies = Result.Unload().UnloadColumn("Organization");
			EndIf;
			
		EndIf;
		
		If AttributesValues.CatalogsSendingRules <> "NotSynchronize"
			Or AttributesValues.DocumentsSendingRules = "AutoSynchronization" Then
			
			If Filter = Undefined Then
				
				Filter = New Array();
				ExchangePlanName = DataExchangeCached.GetExchangePlanName(Recipient);
				ExchangePlanContent = Metadata.ExchangePlans[ExchangePlanName].Content;
				
				For Each ExchangePlanContentItem In ExchangePlanContent Do
				
					If Common.IsCatalog(ExchangePlanContentItem.Metadata) Then
						
						MetadataOfExchangePlanCompositionElement = ExchangePlanContentItem.Metadata; // MetadataObject
						
						If AttributesValues.CatalogsSendingRules = "AutoSynchronization"
							Or (AttributesValues.CatalogsSendingRules = "SynchronizeAsNeeded"
							And MetadataOfExchangePlanCompositionElement.Name = "Companies") Then
							Filter.Add(ExchangePlanContentItem.Metadata);
						EndIf;
						
					ElsIf Common.IsDocument(ExchangePlanContentItem.Metadata) Then
						
						If AttributesValues.SettingsMode = "ExchangeOfUPRMC"
							And ExchangePlanContentItem.Metadata <> Metadata.Documents.PriceSetup Then
							Continue;
						EndIf;
						
						If AttributesValues.DocumentsSendingRules = "AutoSynchronization" Then
							Filter.Add(ExchangePlanContentItem.Metadata);
						EndIf;
						
					ElsIf Common.IsRegister(ExchangePlanContentItem.Metadata) Then
						
						If AttributesValues.CatalogsSendingRules = "AutoSynchronization" Then
							Filter.Add(ExchangePlanContentItem.Metadata);
						EndIf;
						
					EndIf;
					
				EndDo;
				
				If Filter.Count() = 0 Then
					Filter = Undefined;
				EndIf;
				
			EndIf;
			
			DataExchangeEventsTMERP.RegisterDataByExportStartDateAndCompanies(Recipient, 
				AttributesValues.DocumentsExportStartDate,
				Companies,
				Filter);
			
		EndIf;
	EndIf;
	
EndProcedure

// Returns whether the current exchanges that use the formation of contracts for the orders.
// 
// Returns:
//  Boolean - indicates the presence of nodes.
//
Function ThereAreExchangesWithFormationOfContractsForOrders() Export
	
	Return False;
	
EndFunction

// Informs the user about the prohibition of creating or changing an object in this 
// information database.
//
// Parameters:
//   Object - DocumentObject - A document that is checked for the possibility of creating 
//                             a distributed information database in a subordinate node.
//   Cancel  - Boolean - Flag for refusing to create a document. False by default.
//
Procedure ControlOfCreationOfDocumentsInDistributedInformationSecurity(Object, Cancel) Export
	Return;
EndProcedure

// Define metadata objects whose Manager modules restrict the ability to edit details
// using the export function getblockablerequisits of the Object.
//
// Parameters:
//   Objects - Map of KeyAndValue:
//     * Key - String - full name of the metadata object connected to the subsystem;
//     * Value - String - empty string.
//
// Example: 
//   Objects.Insert (Metadata.Documents.Customer's order.Full name(), "");
//
Procedure OnDefineObjectsWithLockedAttributes(Objects) Export
	//Stub
EndProcedure

// Returns the value of the management organization's link 
// for configuring selection, when configured via an external connection.
//
// Returns:
//  String - the link ID of the management organization.
//
Function ManagementOrganizationLink() Export
	Return ValueToStringInternal(Catalogs.Companies.ManagementCompany);
EndFunction

// Concatenates arrays, returning the result of the concatenation.
// 
// Returns:
//   Array - a combined array of values.
//
Function CombineArrays(Array1, Array2) Export
	
	CombinedArray = New Array;
	
	For Each ArrayElement In Array1 Do
	
		If CombinedArray.Find(ArrayElement) = Undefined Then
			CombinedArray.Add(ArrayElement);
		EndIf; 
	
	EndDo;
	
	For Each ArrayElement In Array2 Do
	
		If CombinedArray.Find(ArrayElement) = Undefined Then
			CombinedArray.Add(ArrayElement);
		EndIf; 
	
	EndDo;
	
	Return CombinedArray;
	
EndFunction

#Region GeneralProceduresAndFunctionsForRIBExchangePlans

Function RegistersForCreatingTasksForCalculatingCost() Export
	
	TypesOfRegisters = New Array();
	TypesOfRegisters.Add(Type("AccumulationRegisterRecordSet.ItemisedExpensesLots"));
	TypesOfRegisters.Add(Type("AccumulationRegisterRecordSet.MaterialsAndWorksInProduction"));
	TypesOfRegisters.Add(Type("AccumulationRegisterRecordSet.OtherExpenses"));
	TypesOfRegisters.Add(Type("AccumulationRegisterRecordSet.GoodsCostVariances"));
	TypesOfRegisters.Add(Type("AccumulationRegisterRecordSet.InventoryCost"));
	TypesOfRegisters.Add(Type("AccumulationRegisterRecordSet.GoodsToBeRegisteredInReportsToConsignor"));
	TypesOfRegisters.Add(Type("AccumulationRegisterRecordSet.CompanyGoods"));
	TypesOfRegisters.Add(Type("AccumulationRegisterRecordSet.CompanyGoodsForTransfer"));
	TypesOfRegisters.Add(Type("AccumulationRegisterRecordSet.GoodsTransferredToCommissionAgent"));
	
	Return TypesOfRegisters;
	
EndFunction

Function RegistersForCreatingTasksForCalculatingSettlementsWithClients() Export
	
	TypesOfRegisters = New Array();
	TypesOfRegisters.Add(Type("AccumulationRegisterRecordSet.CustomersARAPAccounting"));
	TypesOfRegisters.Add(Type("AccumulationRegisterRecordSet.CustomersARAPAccountingByDocuments"));
	
	Return TypesOfRegisters;
	
EndFunction

Function RegistersForCreatingTasksForCalculatingSettlementsWithSuppliers() Export
	
	TypesOfRegisters = New Array();
	TypesOfRegisters.Add(Type("AccumulationRegisterRecordSet.VendorsARAPAccounting"));
	TypesOfRegisters.Add(Type("AccumulationRegisterRecordSet.VendorsARAPAccountingByDocuments"));
	
	Return TypesOfRegisters;
	
EndFunction

Function RegistersForCheckingMonthClosingLock() Export
	
	Return Metadata.EventSubscriptions.JobsForMonthEndClosingBeforeWrite.Source.Types();
	
EndFunction

// Objects for generating FA and IA tasks.
// 
// Returns:
//  Array of MetadataObject
//
Function IncomingDataForGeneratingOSNMATasks() Export
	
	IncomingData = New Array;
	
	IncomingData.Add(Metadata.Documents.LeaseTermAdjustment);
	IncomingData.Add(Metadata.Documents.IntangibleAssetsCostAndAmortizationAdjustment);
	IncomingData.Add(Metadata.Documents.FixedAssetCostAndDepreciationAdjustment);
	IncomingData.Add(Metadata.Documents.FixedAssetsCostAdditions2_4);
	IncomingData.Add(Metadata.Documents.AllocateVariancesToFixedAssetCost);
	IncomingData.Add(Metadata.Documents.IATransfer2_4);
	IncomingData.Add(Metadata.Documents.FATransfer2_4);
	IncomingData.Add(Metadata.Documents.IARevaluation2_4);
	IncomingData.Add(Metadata.Documents.FARevaluation2_4);
	IncomingData.Add(Metadata.Documents.DisposeIntangibleAssets2_4);
	IncomingData.Add(Metadata.Documents.DisposeFixedAssets2_4);
	
	Return IncomingData;
	
EndFunction
// This method creates tasks for further calculation of offline registers (cost, settlements, etc.).
//
// Parameters:
//  ReceivedData - AccumulationRegisterRecordSet - The resulting set of records of the accumulation register, 
//                                                     based on which you want to create tasks.
//  NameOfRegisterToCreateRecord - String - Name of the offline register.
// 
Procedure CreateTasksForCalculatingOfflineRegisters(ReceivedData, NameOfRegisterToCreateRecord) Export
	
	DocumentJobs = ReceivedData.Filter.Recorder.Value;
	
	// Tasks for calculating the received data
	SetTable = New ValueTable();
	SetTable.Columns.Add("Period");
	
	If ReceivedData.Count() > 0 Then
		
		SetTable = ReceivedData.Unload();
		SetTable.GroupBy("Period");
		
		For Each TableRow In SetTable Do
			TableRow.Period = BegOfMonth(TableRow.Period);
			InformationRegisters[NameOfRegisterToCreateRecord].CreateRegisterEntry(TableRow.Period, DocumentJobs);
		EndDo;
		
	EndIf;
	
	// Tasks for recalculation of available data in the database
	Query = New Query("SELECT
		|	BEGINOFPERIOD(SelectableRegister.Period, MONTH) AS TaskPeriod
		|FROM
		|	&RegisterName AS SelectableRegister
		|WHERE
		|	SelectableRegister.Recorder = &Recorder");
		
	Query.Text = StrReplace(Query.Text, "&RegisterName", "AccumulationRegister." + ReceivedData.Metadata().Name);
	Query.SetParameter("Recorder", DocumentJobs);
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		If SetTable.Find(Selection.TaskPeriod, "Period") = Undefined Then
			InformationRegisters[NameOfRegisterToCreateRecord].CreateRegisterEntry(Selection.TaskPeriod, DocumentJobs);
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

// Returns whether the exchange plan is available in the basic version
// 
// Returns:
//   Boolean - checking the limitations of the basic version.
//
Function AvailabilityOfExchangePlanInBasicVersion(ExchangePlanName,InformUser = True)
	
	NumberOfExchangePlanNodes = 1;
	ListOfAvailableExchangePlans = DataExchangeCached.SSLExchangePlans();
	
	If ListOfAvailableExchangePlans.Find(ExchangePlanName) <> Undefined
		And DataExchangeEvents.AllExchangePlanNodes(ExchangePlanName).Count() < NumberOfExchangePlanNodes Then
		Return True;
	Else
		If InformUser Then
			Message = New UserMessage;
			Message.Text = NStr("vi = 'Đang sử dụng những hạn chế của phiên bản căn bản. Không thể tạo sơ đồ trao đổi đã chọn.';
								|ru = 'Используются ограничения базовой версии. Выбранный план обмена создать невозможно.';
								|en = 'Restrictions of the base version are used. Cannot create the selected exchange plan.'; fa = 'Restrictions of the base version are used. Cannot create the selected exchange plan.';
								|it = 'Vengono utilizzati i limiti della versione base. Non è possibile creare il piano di scambio selezionato.';
								|pl = 'Są stosowane ograniczenia wersji bazowej. Utworzenie wybranego planu wymiany jest nie możliwe.';
								|tr = 'Temel sürüm kısıtlamaları geçerlidir. Seçilen değişim planının oluşturulması mümkün değil.'");
			Message.Message();
		EndIf;
		Return False;
	EndIf;
	
EndFunction

// Returns a request in which an attempt is made to get exchange nodes with the "Accounting Department of the Enterprise".
//
// Returns:
//   Query - according to the nodes of the exchange plan "Synchronization of the above-mentioned universal format".
//
Function RequestExchangeNodesWithAccounting() Export
	
	Query = New Query("SELECT
		|	DataSynchronizationViaUniversalFormat.Ref
		|FROM
		|	ExchangePlan.DataSynchronizationViaUniversalFormat AS DataSynchronizationViaUniversalFormat
		|WHERE
		|	DataSynchronizationViaUniversalFormat.DeletionMark = FALSE
		|	AND NOT DataSynchronizationViaUniversalFormat.ThisNode
		|	AND DataSynchronizationViaUniversalFormat.SettingsMode IN (&OptionsArray)");

	OptionsArray = New Array();
	OptionsArray.Add(ExchangePlans.DataSynchronizationViaUniversalFormat.IdOfExchangeSetupBP30());
	OptionsArray.Add(ExchangePlans.DataSynchronizationViaUniversalFormat.IdOfExchangeSetupBPCORP30());
	OptionsArray.Add(ExchangePlans.DataSynchronizationViaUniversalFormat.IdOfExchangeSettingsIsUniversal());
	Query.SetParameter("OptionsArray", OptionsArray);
	
	Return Query;
	
EndFunction

// Returns a selection of the request with nodes where the upload start date is earlier than the reconciliation date.
//
// Returns:
//   QueryResultSelection - selection of nodes of the exchange plan "synchronizationdannyhcheresuniversal format".
//
Function NodesOfExchangePlansWithUploadStartDateEarlierThanRollUpDate(ConvolutionDate) Export
	
	Query = New Query("SELECT
	|	Ugh.Ref,
	|	Ugh.DocumentsExportStartDate,
	|	Ugh.DeletionMark
	|INTO ExchangeNodes
	|FROM
	|	ExchangePlan.DataSynchronizationViaUniversalFormat AS Ugh
	|WHERE
	|	Ugh.Ref <> &ThisNodeIsUV
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ExchangeNodes.Ref
	|FROM
	|	ExchangeNodes AS ExchangeNodes
	|WHERE
	|	ExchangeNodes.DocumentsExportStartDate <= &ConvolutionDate");
			
	Query.SetParameter("ConvolutionDate", ConvolutionDate);
	Query.SetParameter("ThisNodeIsUV",  ExchangePlans.DataSynchronizationViaUniversalFormat.ThisNode());
	
	NodesSelection = Query.Execute().Select();
	
	Return NodesSelection;
	
EndFunction

#EndRegion
