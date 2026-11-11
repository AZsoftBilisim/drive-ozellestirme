#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns a list of orders for processing documents.
// 
// Returns:
//  ValueList - a list of instructions for processing documents.
//
Function InstructionsForRegistrationOfDocuments() Export
	
	ValueTableResult = ComposeResultIntoCollectionOfValues();
	
	ListOfOrders_ = New ValueList;
	For Each Page1 In ValueTableResult Do
		If ListOfOrders_.FindByValue(Page1.ReferenceOrder) = Undefined Then
			ListOfOrders_.Add(Page1.ReferenceOrder);
		EndIf;
	EndDo;
	Return ListOfOrders_;
	
EndFunction

// Returns a list of items and specifications for the design of the warehouse acts.
// 
// Returns:
//  Structure - structure with fields:
//		* ItemList	- ValueList - list of items for registration of warehouse acts.
//		* ListOfCharacteristics	- ValueList - list of characteristics for registration of warehouse certificates.
//
Function ProductsAndCharacteristicsForRegistrationOfDocuments() Export
	
	ValueTableResult = ComposeResultIntoCollectionOfValues();
	
	UseItemVariants = GetFunctionalOption("UseItemVariants");
	Structure = New Structure("ItemList, ListOfCharacteristics");
	Structure.ItemList = New ValueList;
	Structure.ListOfCharacteristics = New ValueList;
	For Each Page1 In ValueTableResult Do
		If Structure.ItemList.FindByValue(Page1.Products) = Undefined Then
			Structure.ItemList.Add(Page1.Products);
		EndIf;
		If UseItemVariants Then
			If Structure.ListOfCharacteristics.FindByValue(Page1.Characteristic) = Undefined Then
				Structure.ListOfCharacteristics.Add(Page1.Characteristic);
			EndIf;
		EndIf;
	EndDo;
	Return Structure;

EndFunction

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)

	StandardProcessing = False;
	UserSettingsModified = False;
	TempTablesManager = New TempTablesManager;
	AddressOfSelectionTable = DataCompositionClientServer.GetParameter(SettingsComposer, "AddressOfSelectionTable").Value;
	
	SetRequiredSettings(UserSettingsModified);
	InitializeTemporaryTableManagerWithSelectionData(TempTablesManager, AddressOfSelectionTable);
	
	DataCompositionSchema.DataSets.ControlOfRegistrationOfDocuments.Query =
		QueryTextControlOfInventoryTransferDocumentRegistration(ValueIsFilled(AddressOfSelectionTable));
	
	// Generate a report
	ReportSettings = SettingsComposer.GetSettings();

	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);

	// We will remove selections for empty fields from the request for surpluses / shortages
	OriginalTemplateRequest = CompositionTemplate.DataSets.ControlOfRegistrationOfDocuments.Query;
	CompositionTemplate.DataSets.ControlOfRegistrationOfDocuments.Query = 
		RequestTextRegistrationOfSurplusesShortagesWithoutSelections(OriginalTemplateRequest);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True, , TempTablesManager);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
	
EndProcedure

#EndRegion

#Region Internal

Procedure InitializeTemporaryTableManagerWithSelectionData(TempTablesManager, AddressOfSelectionTable)
	
	If ValueIsFilled(AddressOfSelectionTable) Then
		TableFilters = GetFromTempStorage(AddressOfSelectionTable);
		
		Query = New Query;
		Query.TempTablesManager = TempTablesManager;
		Query.Text = 
		"SELECT
		|	TableFilters.Products		AS Products,
		|	TableFilters.Characteristic	AS Characteristic,
		|	TableFilters.Purpose		AS Purpose,
		|	TableFilters.Series			AS Series,
		|	TableFilters.Warehouse			AS Warehouse
		|INTO TableFilters
		|FROM
		|	&TableFilters AS TableFilters";
		
		Query.SetParameter("TableFilters", TableFilters);
		
		Query.Execute();
	EndIf;
	
EndProcedure

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - See ReportsClientServer.DefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	Settings.Events.OnCreateAtServer = True;
	Settings.Events.BeforeImportSettingsToComposer = True;
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - report form.
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	Parameters = ThisForm.Parameters;
	FormSettingsComposer = ThisForm.Report.SettingsComposer;
	ReportSettings = ThisForm.ReportSettings;
	
	Schema = GetFromTempStorage(ThisForm.ReportSettings.SchemaURL);
	Fields = Schema.DataSets.ControlOfRegistrationOfDocuments.Fields; // DataCompositionSchemaDataSetFields
	WarehouseField = Fields.Find("Warehouse");
	If WarehouseField <> Undefined Then
		EditParameters = WarehouseField.EditParameters.Items;
	EndIf;
EndProcedure

// Called before loading new settings. Used to change the layout scheme.
//   For example, if the report schema depends on the option key or report parameters.
//   For schema changes to take effect, call the ReportServer method.Connect the circuit().
//
// Parameters:
//   Context - Arbitrary - 
//       Parameters of the context in which the report is used.
//       Used for passing the ReportServer method parameters.Connect the circuit().
//   SchemaKey - String -
//       ID of the current configuration Builder schema.
//       By default, it is empty (this means that the linker is initialized based on the main schema).
//       Used for optimization to reinitialize the linker as rarely as possible).
//       It may not be used if reinitialization is performed unconditionally.
//   VariantKey - String, Undefined -
//       Name of the predefined or unique ID of the custom version of the report.
//       Undefined when calling for a decryption option or without context.
//   NewDCSettings - DataCompositionSettings, Undefined -
//       Report variant settings that will be loaded into the settings Builder after it is initialized.
//       Undefined when the option settings do not need to be loaded (already loaded earlier).
//   NewDCUserSettings - DataCompositionUserSettings, Undefined -
//       User settings that will be loaded into the Settings Composer after it is initialized.
//       It is uncertain when user settings do not need to be loaded (already loaded earlier).
//
// Examples:
// 1. The Composer of the report is initialized based on the scheme from the general Templates:
//	If the key of the scheme <> is "1" Then
//		Schema Key = "1";
//		SCHEMACD = Get a Public package("My Public Schemacompositions");
//		Server report.Connect a schema(This is an Object, Context, Schema, Schema Key);
//	The end if;
//
// 2. The scheme depends on the value of the parameter displayed in the user settings of the report:
//	If the type of ID is(New usersenastroykid) = Type("Custom setups of Data components") Then
//		Full Data objectName = "";
//		For Each Cd element From The New Userenastroykid.Elements of the Cycle
//			If the type of ID is (CD element) = Type("Parameter setter values") Then
//				Parameter Name = String(element).Parameter);
//				If Parameter Name = "Data objectmethod" Then
//					Full Data objectName = Data element.Value;
//				The end if;
//			The end if;
//		The end of the cycle;
//		If the Schema key <> is the full Data objectName, then
//			Schema Key = Full Data objectname;
//			Schemacd = New schemacomposedata;
//			Filling in the schema...
//			Server report.Connect a schema(This is an Object, Context, Schema, Schema Key);
//		The end if;
//	The end if;
//
Procedure BeforeImportSettingsToComposer(Context, SchemaKey, VariantKey, NewDCSettings, NewDCUserSettings) Export
	
	// Localization of the list of values
	AvailableValues = AvailableValuesForOperationTypeField();
	
	OperationKind = DataCompositionSchema.DataSets.ControlOfRegistrationOfDocuments.Fields.Find("OperationKind");
	OperationKind.SetAvailableValues(AvailableValues);
	
	ReportsServer.AttachSchema(ThisObject, Context, DataCompositionSchema, SchemaKey);
	
EndProcedure

#EndRegion

#Region Private

Procedure SetRequiredSettings(UserSettingsModified)
	
	TypesOfOperationsAndSynonyms = TypesOfOperationsAndSynonyms();
	
	// String literals
	PresentationOfRecommendations = Reports.ControlOfInventoryTransferDocumentRegistration.PresentationOfRecommendations();
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineRecommendationCreateAGoodsIssueNote", PresentationOfRecommendations["CreateGoodsIssueNotes"]);
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineRecommendationRegisterGoodsReturnFromCustomer", PresentationOfRecommendations["RegisterReturnOfGoodsFromCustomer"]);
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineRecommendationRegisterGoodsReceiptNotes", PresentationOfRecommendations["RegisterGoodsReceiptNotes"]);
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineRecommendationRegisterPurchaseOfGoodsAndServices", PresentationOfRecommendations["RegisterPurchaseOfGoodsAndServices"]);
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineRecommendationRegisterReceiptOfGoods", PresentationOfRecommendations["ProcessReceiptOfGoods"]);
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineRecommendationRegisterGoodsTransferInStatusReceived", PresentationOfRecommendations["MakeMovementOfGoodsWithStatusAccepted"]);
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineRecommendationRegisterAssemblyDocumentInStatusAssembledDisassembled", PresentationOfRecommendations["IssueBuildDocumentWithAssembledDisassembledStatus"]);
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineRecommendationRegisterDisassemblyDocumentInStatusAssembledDisassembled", PresentationOfRecommendations["IssueDisassemblyDocumentWithAssembledDisassembledStatus"]);
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineRecommendationRegisterOtherRecordingOfGoodsAsReceived", PresentationOfRecommendations["RegisterOtherGoodsRecordingAsReceived"]);
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineRecommendationRegisterWarehouseActsToRecordSurplus", PresentationOfRecommendations["RegisterWarehouseActsToRecordSurpluses"]);
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineRecommendationRegisterWarehouseActsToRecordShortages", PresentationOfRecommendations["RegisterWarehouseActsToRecordShortages"]);
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineRecommendationRegisterMaterialTransferToProductionInStatusReceived", PresentationOfRecommendations["SubmitMaterialsForProductionWithAcceptedStatus"]);
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineRecommendationRegisterMaterialReturnFromProduction", PresentationOfRecommendations["RegisterMaterialReturnFromProduction"]);
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineRecommendationRegisterProductRelease", PresentationOfRecommendations["RegisterProductRelease"]);
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineRecommendationRegisterRawMaterialReturnFromToller", PresentationOfRecommendations["RegisterRawMaterialReturnFromToller"]);
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineRecommendationRegisterReceiptFromToller", PresentationOfRecommendations["RegisterReceiptFromToller"]);
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineRecommendationRegisterReceiptOfRawMaterialsFromMaterialProvider", PresentationOfRecommendations["RegisterReceiptOfRawMaterialsFromMaterialProvider"]);
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineRecommendationRegisterGoodsIssueNotes", PresentationOfRecommendations["IssueSpendingOrdersForGoods"]);
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineRecommendationRegisterSellingOfGoodsAndServices", PresentationOfRecommendations["RegisterSalesOfGoodsAndServices"]);
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineRecommendationRegisterShipmentOfGoodsFromStorage", PresentationOfRecommendations["RegisterGoodsShipmentFromStorage"]);
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineRecommendationRegisterReceivingOfGoodsForStorage", PresentationOfRecommendations["RegisterGoodsReceivingForStorage"]);
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineRecommendationRegisterInternalConsumption", PresentationOfRecommendations["RegisterInventoryConsumption"]);
	
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineTypeOfDeviationProcessingOfFinancialDocuments", NStr("vi = 'Hãy lập chứng từ tài chính';
																														|ru = 'Оформление финансовых документов';
																														|en = 'Create financial documents'; fa = 'ایجاد اسناد مالی';
																														|it = 'Formalizzazione dei documenti finanziari';
																														|pl = 'Sporządzenie dokumentów finansowych';
																														|tr = 'Finansal belgelerin düzenlenmesi'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineTypeOfDeviationRegistrationOfWarehouseDocuments", NStr("vi = 'Hãy lập chứng từ kho bãi';
																															|ru = 'Оформление складских документов';
																															|en = 'Create warehouse documents'; fa = 'ایجاد اسناد انبار';
																															|it = 'Formalizzazione dei documenti di magazzino';
																															|pl = 'Sporządzenie dokumentów magazynowych';
																															|tr = 'Ambar belgelerinin düzenlenmesi'"));
	
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineTypeOfOperationShipmentToCustomers", TypesOfOperationsAndSynonyms["ShipmentToCustomers"]);
	DataCompositionClientServer.SetParameter(SettingsComposer, "OperationTypeRowRefundsFromCustomers", TypesOfOperationsAndSynonyms["ReturnsOfGoodsFromCustomers"]);
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineTypeOfOperationAcceptanceFromSuppliers", TypesOfOperationsAndSynonyms["ReceiptFromSuppliers"]);
	DataCompositionClientServer.SetParameter(SettingsComposer, "TypeOfOperationReturnsToSuppliers", TypesOfOperationsAndSynonyms["ReturnsOfGoodsToVendors"]);
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineTypeOfOperationInternalConsumption", TypesOfOperationsAndSynonyms["InventoryConsumption"]);
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineTypeOfOperationMovingGoods", TypesOfOperationsAndSynonyms["InventoryTransfer"]);
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineTypeOfOperationAssemblyDisassemblyOfGoods", TypesOfOperationsAndSynonyms["AssemblyDisassemblyOfGoods"]);
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineTypeOfOperationOtherProductRegistration", TypesOfOperationsAndSynonyms["OtherGoodsRecordingAsReceived"]);
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineTypeOfOperationTransferOfMaterialsToProduction", TypesOfOperationsAndSynonyms["MaterialTransferToProduction"]);
	DataCompositionClientServer.SetParameter(SettingsComposer, "RowTypeOfOperationReturnsOfMaterialsFromProduction", TypesOfOperationsAndSynonyms["ReturnsOfMaterialsFromProduction"]);
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineTypeOfOperationAcceptanceOfFinishedProducts", TypesOfOperationsAndSynonyms["ReceivingOfProducts"]);
	DataCompositionClientServer.SetParameter(SettingsComposer, "ThisTypeOfOperationProcessingRawMaterialsGiver", TypesOfOperationsAndSynonyms["MaterialProcessingOfMaterialProvider"]);
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineTypeOfOperationReturnsOfRawMaterialsToGivers", TypesOfOperationsAndSynonyms["ReturnsToMaterialProviders"]);
	DataCompositionClientServer.SetParameter(SettingsComposer, "ThisIsTypeOfOperationForTransferringProductsToGivers", TypesOfOperationsAndSynonyms["ProductTransfersToMaterialProviders"]);
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineTypeOfOperationProcessingOfRawMaterialsFromProcessor", TypesOfOperationsAndSynonyms["RawMaterialProcessingByToller"]);
	DataCompositionClientServer.SetParameter(SettingsComposer, "OperationTypeRowReturnsOfRawMaterialsFromProcessors", TypesOfOperationsAndSynonyms["ReturnsOfRawMaterialsFromTollers"]);
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineTypeOfTransactionReceiptOfProductsFromProcessors", TypesOfOperationsAndSynonyms["ProductReceiptFromTollers"]);
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineTypeOfOperationRegistrationOfSurplusesAndShortages", TypesOfOperationsAndSynonyms["SurplusesAndShortagesRegistration"]);
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineOperationKindShipmentOfGoodsReceivedFromStorage", TypesOfOperationsAndSynonyms["ShipReceivedGoodsFromStorage"]);
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineOperationKindGoodsReceivingForStorage", TypesOfOperationsAndSynonyms["GoodsReceiptForStorage"]);
	DataCompositionClientServer.SetParameter(SettingsComposer, "StringTransactionTypeTransferOfGoodsToTheCustodian", TypesOfOperationsAndSynonyms["TransferOfGoodsToBailee"]);
	
	// Adapting localization for selections
	Fields = DataCompositionSchema.DataSets.ControlOfRegistrationOfDocuments.Fields;
	
	RecommendationField = Fields.Find("Recommendation");
	LocalizeAvailableFieldValues(RecommendationField);
	
	DeviationTypeField = Fields.Find("VarianceType");
	LocalizeAvailableFieldValues(DeviationTypeField);
	
	OperationTypeField = Fields.Find("OperationKind");
	LocalizeAvailableFieldValues(OperationTypeField);
EndProcedure

Procedure LocalizeAvailableFieldValues(Field)
	AvailableValues = Field.GetAvailableValues();
	
	For Each AvailableValue In AvailableValues Do
		
		ParameterByNameOfAvailableValue = DataCompositionClientServer.GetParameter(SettingsComposer, AvailableValue.Value);
		
		If Not ParameterByNameOfAvailableValue = Undefined Then
			
			AvailableValue.Value = ParameterByNameOfAvailableValue.Value;
			AvailableValue.Presentation = ParameterByNameOfAvailableValue.Value;
			
		EndIf;
		
	EndDo;
	
	Field.SetAvailableValues(AvailableValues);
EndProcedure

Function QueryTextSales()
	// String literals are localized in the report's SCD settings
	// Datasets - Fields - Available values.
	QueryText = "SELECT ALLOWED
	|	&LineTypeOfOperationShipmentToCustomers AS OperationKind,
	|	&LineTypeOfDeviationRegistrationOfWarehouseDocuments AS VarianceType,
	|	CASE
	|		WHEN GoodsForIssue.ToRegisterBalance <> 0
	|			THEN &LineRecommendationRegisterSellingOfGoodsAndServices
	|		WHEN GoodsForIssue.ToShipBalance - GoodsForIssue.ToRegisterBalance <> 0
	|			THEN &LineRecommendationCreateAGoodsIssueNote
	|	END AS Recommendation,
	|	CASE
	|		WHEN GoodsForIssue.ToShipBalance - GoodsForIssue.ToRegisterBalance <> 0
	|			THEN -GoodsForIssue.ToShipBalance
	|	END AS IncompleteWarehouseOperation,
	|	CASE
	|		WHEN GoodsForIssue.ToRegisterBalance > 0
	|			THEN GoodsForIssue.ToRegisterBalance
	|	END AS UnfinishedFinancialTransaction,
	|	ISNULL(DetailsOfOrder.IBDocumentDate, DATETIME(1,1,1)) AS DateOfTransaction,
	|	GoodsForIssue.DocumentShipments AS ReferenceOrder,
	|	GoodsForIssue.Warehouse AS Warehouse,
	|	GoodsForIssue.Products AS Products,
	|	GoodsForIssue.Characteristic AS Characteristic,
	|	GoodsForIssue.Series,
	|	GoodsForIssue.Purpose
	|{SELECT
	|	Warehouse.*,
	|	Products.*,
	|	Characteristic.*,
	|	Series.*,
	|	Purpose.*}
	|FROM
	|	AccumulationRegister.GoodsForIssue.Balance(
	|		&PeriodLimit,
	|		DocumentShipments IN(
	|			SELECT
	|				ShipmentReferences.Ref
	|			FROM
	|				OrdersForShipmentBySales AS ShipmentReferences)
	|		AND &SelectionOfGoodsByRegister
	|		{(DocumentShipments).* AS ReferenceOrder, (Warehouse).*, (Products).*, (Characteristic).*, (Series).*, (Purpose).*}
	|	) AS GoodsForIssue
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS DetailsOfOrder
	|		ON GoodsForIssue.DocumentShipments = DetailsOfOrder.Ref
	|			AND NOT DetailsOfOrder.AdditionalRecord
	|WHERE
	|	GoodsForIssue.ToShipBalance - GoodsForIssue.ToRegisterBalance <> 0
	|	OR GoodsForIssue.ToRegisterBalance > 0
	|{WHERE
	|	(&LineTypeOfOperationShipmentToCustomers) AS OperationKind,
	|	(&LineTypeOfDeviationRegistrationOfWarehouseDocuments) AS VarianceType,
	|	(CASE
	|			WHEN GoodsForIssue.ToShipBalance - GoodsForIssue.ToRegisterBalance <> 0
	|				THEN &LineRecommendationCreateAGoodsIssueNote
	|		END) AS Recommendation,
	|	(CASE
	|			WHEN GoodsForIssue.ToShipBalance - GoodsForIssue.ToRegisterBalance <> 0
	|				THEN -GoodsForIssue.ToShipBalance
	|		END) AS IncompleteWarehouseOperation}";
	
	Return QueryText;
EndFunction

Function QueryTextReturnsOfGoodsFromCustomers()
	// String literals are localized in the report's SCD settings
	// Datasets - Fields - Available values.
	QueryText = "SELECT ALLOWED
	|	&OperationTypeRowRefundsFromCustomers AS OperationKind,
	|	CASE
	|		WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|			THEN &LineTypeOfDeviationProcessingOfFinancialDocuments
	|		ELSE &LineTypeOfDeviationRegistrationOfWarehouseDocuments
	|	END AS VarianceType,
	|	CASE
	|		WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|			THEN &LineRecommendationRegisterGoodsReturnFromCustomer
	|		ELSE &LineRecommendationRegisterGoodsReceiptNotes
	|	END AS Recommendation,
	|	CASE
	|		WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|			THEN 0
	|		ELSE -GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance
	|	END AS IncompleteWarehouseOperation,
	|	CASE
	|		WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|			THEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance
	|		ELSE 0
	|	END AS UnfinishedFinancialTransaction,
	|	ISNULL(DetailsOfOrder.IBDocumentDate, DATETIME(1,1,1)) AS DateOfTransaction,
	|	GoodsReadyForReceipt.DocumentInflow AS ReferenceOrder,
	|	GoodsReadyForReceipt.Warehouse AS Warehouse,
	|	GoodsReadyForReceipt.Products AS Products,
	|	GoodsReadyForReceipt.Characteristic AS Characteristic,
	|	GoodsReadyForReceipt.Series AS Series,
	|	GoodsReadyForReceipt.Purpose AS Purpose
	|{SELECT
	|	Warehouse.*,
	|	Products.*,
	|	Characteristic.*,
	|	Series.*,
	|	Purpose.*}
	|FROM
	|	AccumulationRegister.GoodsToReceive.Balance(
	|		&PeriodLimit, 
	|		VALUETYPE(DocumentInflow) IN (TYPE(Document.RequestForReturnOfGoodsFromCustomer), 
	|			TYPE(Document.ReturnOfGoodsFromCustomer)) 
	|		AND &SelectionOfGoodsByRegister
	|		{(DocumentInflow).* AS ReferenceOrder, (Warehouse).*, (Products).*, (Characteristic).*, (Series).*, (Purpose).*}
	|	) AS GoodsReadyForReceipt
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS DetailsOfOrder
	|		ON GoodsReadyForReceipt.DocumentInflow = DetailsOfOrder.Ref
	|			AND NOT DetailsOfOrder.AdditionalRecord
	|{WHERE
	|	(&OperationTypeRowRefundsFromCustomers) AS OperationKind,
	|	(CASE
	|			WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|				THEN &LineTypeOfDeviationProcessingOfFinancialDocuments
	|			ELSE &LineTypeOfDeviationRegistrationOfWarehouseDocuments
	|		END) AS VarianceType,
	|	(CASE
	|			WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|				THEN &LineRecommendationRegisterGoodsReturnFromCustomer
	|			ELSE &LineRecommendationRegisterGoodsReceiptNotes
	|		END) AS Recommendation,
	|	(CASE
	|			WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|				THEN 0
	|			ELSE -GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance
	|		END) AS IncompleteWarehouseOperation,
	|	(CASE
	|			WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|				THEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance
	|			ELSE 0
	|		END) AS UnfinishedFinancialTransaction}";
	
	Return QueryText;
EndFunction

Function QueryTextPurchases()
	// String literals are localized in the report's SCD settings
	// Datasets - Fields - Available values.
	QueryText = 
	"SELECT ALLOWED
	|	&LineTypeOfOperationAcceptanceFromSuppliers AS OperationKind,
	|	CASE
	|		WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|			THEN &LineTypeOfDeviationProcessingOfFinancialDocuments
	|		ELSE &LineTypeOfDeviationRegistrationOfWarehouseDocuments
	|	END AS VarianceType,
	|	CASE
	|		WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|			THEN CASE
	|					WHEN GoodsReadyForReceipt.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
	|							OR GoodsReadyForReceipt.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
	|						THEN &LineRecommendationRegisterPurchaseOfGoodsAndServices
	|					ELSE &LineRecommendationRegisterReceiptOfGoods
	|				END
	|		ELSE &LineRecommendationRegisterGoodsReceiptNotes
	|	END AS Recommendation,
	|	CASE
	|		WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|			THEN 0
	|		ELSE -GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance
	|	END AS IncompleteWarehouseOperation,
	|	CASE
	|		WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|			THEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance
	|		ELSE 0
	|	END AS UnfinishedFinancialTransaction,
	|	ISNULL(DetailsOfOrder.IBDocumentDate, DATETIME(1, 1, 1)) AS DateOfTransaction,
	|	GoodsReadyForReceipt.DocumentInflow AS ReferenceOrder,
	|	GoodsReadyForReceipt.Warehouse AS Warehouse,
	|	GoodsReadyForReceipt.Products AS Products,
	|	GoodsReadyForReceipt.Characteristic AS Characteristic,
	|	GoodsReadyForReceipt.Series AS Series,
	|	GoodsReadyForReceipt.Purpose AS Purpose
	|{SELECT
	|	Warehouse.*,
	|	Products.*,
	|	Characteristic.*,
	|	Series.*,
	|	Purpose.*}
	|FROM
	|	AccumulationRegister.GoodsToReceive.Balance(
	|			&PeriodLimit,
	|			DocumentInflow IN
	|				(SELECT
	|					ReceiptOrders.Ref
	|				FROM
	|					PurchaseReceiptOrders AS ReceiptOrders)
	|		AND &SelectionOfGoodsByRegister
	|			{(DocumentInflow).* AS ReferenceOrder, (Warehouse).*, (Products).*, (Characteristic).*, (Series).*, (Purpose).*}
	|) AS GoodsReadyForReceipt
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DetailsOfOrder
	|		ON GoodsReadyForReceipt.DocumentInflow = DetailsOfOrder.Ref
	|			AND (NOT DetailsOfOrder.AdditionalRecord)
	|{WHERE
	|	(&LineTypeOfOperationAcceptanceFromSuppliers) AS OperationKind,
	|	(CASE
	|			WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|				THEN &LineTypeOfDeviationProcessingOfFinancialDocuments
	|			ELSE &LineTypeOfDeviationRegistrationOfWarehouseDocuments
	|		END) AS VarianceType,
	|	(CASE
	|			WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|				THEN CASE
	|						WHEN GoodsReadyForReceipt.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
	|								OR GoodsReadyForReceipt.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
	|							THEN &LineRecommendationRegisterPurchaseOfGoodsAndServices
	|						ELSE &LineRecommendationRegisterReceiptOfGoods
	|					END
	|			ELSE &LineRecommendationRegisterGoodsReceiptNotes
	|		END) AS Recommendation,
	|	(CASE
	|			WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|				THEN 0
	|			ELSE -GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance
	|		END) AS IncompleteWarehouseOperation,
	|	(CASE
	|			WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|				THEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance
	|			ELSE 0
	|		END) AS UnfinishedFinancialTransaction}";
	
	Return QueryText;
EndFunction

Function RequestTextForTemporaryPurchaseTables()
	
	QueryText = "
	|SELECT ALLOWED
	|	DocumentInflow.Ref AS Ref
	|INTO PurchaseReceiptOrders
	|FROM
	|	Catalog.TermsOfPurchaseFromVendors AS DocumentInflow
	|WHERE
	|	NOT DocumentInflow.DeletionMark
	|	AND DocumentInflow.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.ImportFromEAEU),
	|		VALUE(Enum.BusinessTransactions.PurchaseByImport),
	|		VALUE(Enum.BusinessTransactions.PurchaseFromSupplier),
	|		VALUE(Enum.BusinessTransactions.ConsignmentProcurement))
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentInflow.Ref AS Ref
	|FROM
	|	Catalog.CounterpartyContracts AS DocumentInflow
	|WHERE
	|	NOT DocumentInflow.DeletionMark
	|	AND DocumentInflow.GoodsReceiptOption IN (
	|		VALUE(Enum.GoodsReceiptOptions.ByContractsAfterInvoices),
	|		VALUE(Enum.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices),
	|		VALUE(Enum.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices))
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentInflow.Ref AS Ref
	|FROM
	|	Document.PurchaseOrder AS DocumentInflow
	|WHERE
	|	NOT DocumentInflow.DeletionMark
	|	AND DocumentInflow.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.ImportFromEAEU),
	|		VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit),
	|		VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
	|		VALUE(Enum.BusinessTransactions.PurchaseByImport),
	|		VALUE(Enum.BusinessTransactions.ImportGoodsInTransit),
	|		VALUE(Enum.BusinessTransactions.PurchaseFromSupplier),
	|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
	|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
	|		VALUE(Enum.BusinessTransactions.ConsignmentProcurement))
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentInflow.Ref AS Ref
	|FROM
	|	Document.VendorInvoice AS DocumentInflow
	|WHERE
	|	NOT DocumentInflow.DeletionMark
	|	AND DocumentInflow.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.ImportFromEAEU),
	|		VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit),
	|		VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
	|		VALUE(Enum.BusinessTransactions.PurchaseByImport),
	|		VALUE(Enum.BusinessTransactions.ImportGoodsInTransit),
	|		VALUE(Enum.BusinessTransactions.PurchaseFromSupplier),
	|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
	|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
	|		VALUE(Enum.BusinessTransactions.ConsignmentProcurement))
	|
	|INDEX BY
	|	Ref";
	
	Return QueryText;
	
EndFunction

Function QueryTextReturnsOfGoodsToVendors()
	// String literals are localized in the report's SCD settings
	// Datasets - Fields - Available values.
	QueryText = "SELECT ALLOWED
	|	&TypeOfOperationReturnsToSuppliers AS OperationKind,
	|	&LineTypeOfDeviationRegistrationOfWarehouseDocuments AS VarianceType,
	|	CASE
	|		WHEN GoodsForIssue.ToShipBalance - GoodsForIssue.ToRegisterBalance <> 0
	|			THEN &LineRecommendationCreateAGoodsIssueNote
	|	END AS Recommendation,
	|	CASE
	|		WHEN GoodsForIssue.ToShipBalance - GoodsForIssue.ToRegisterBalance <> 0
	|			THEN -GoodsForIssue.ToShipBalance
	|	END AS IncompleteWarehouseOperation,
	|	0 AS UnfinishedFinancialTransaction,
	|	ISNULL(DetailsOfOrder.IBDocumentDate, DATETIME(1,1,1)) AS DateOfTransaction,
	|	GoodsForIssue.DocumentShipments AS ReferenceOrder,
	|	GoodsForIssue.Warehouse AS Warehouse,
	|	GoodsForIssue.Products AS Products,
	|	GoodsForIssue.Characteristic AS Characteristic,
	|	GoodsForIssue.Series,
	|	GoodsForIssue.Purpose
	|{SELECT
	|	Warehouse.*,
	|	Products.*,
	|	Characteristic.*,
	|	Series.*,
	|	Purpose.*}
	|FROM
	|	AccumulationRegister.GoodsForIssue.Balance(
	|		&PeriodLimit, 
	|		VALUETYPE(DocumentShipments) IN (TYPE(Document.ReturnOfGoodsToVendor)) 
	|		AND &SelectionOfGoodsByRegister
	|		{(DocumentShipments).* AS ReferenceOrder, (Warehouse).*, (Products).*, (Characteristic).*, (Series).*, (Purpose).*}
	|	) AS GoodsForIssue
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS DetailsOfOrder
	|		ON GoodsForIssue.DocumentShipments = DetailsOfOrder.Ref
	|			AND NOT DetailsOfOrder.AdditionalRecord
	|WHERE
	|	GoodsForIssue.ToShipBalance - GoodsForIssue.ToRegisterBalance <> 0
	|{WHERE
	|	(&TypeOfOperationReturnsToSuppliers) AS OperationKind,
	|	(&LineTypeOfDeviationRegistrationOfWarehouseDocuments) AS VarianceType,
	|	(CASE
	|			WHEN GoodsForIssue.ToShipBalance - GoodsForIssue.ToRegisterBalance <> 0
	|				THEN &LineRecommendationCreateAGoodsIssueNote
	|		END) AS Recommendation,
	|	(CASE
	|			WHEN GoodsForIssue.ToShipBalance - GoodsForIssue.ToRegisterBalance <> 0
	|				THEN -GoodsForIssue.ToShipBalance
	|		END) AS IncompleteWarehouseOperation}";
	
	Return QueryText;
EndFunction

Function QueryTextInventoryConsumption()
	// String literals are localized in the report's SCD settings
	// Datasets - Fields - Available values.
	QueryText = "SELECT ALLOWED
	|	&LineTypeOfOperationInternalConsumption AS OperationKind,
	|	&LineTypeOfDeviationRegistrationOfWarehouseDocuments AS VarianceType,
	|	CASE
	|		WHEN GoodsForIssue.ToRegisterBalance <> 0
	|			THEN &LineRecommendationRegisterInternalConsumption
	|		WHEN GoodsForIssue.ToShipBalance - GoodsForIssue.ToRegisterBalance <> 0
	|			THEN &LineRecommendationCreateAGoodsIssueNote
	|	END AS Recommendation,
	|	CASE
	|		WHEN GoodsForIssue.ToShipBalance - GoodsForIssue.ToRegisterBalance <> 0
	|			THEN -GoodsForIssue.ToShipBalance
	|	END AS IncompleteWarehouseOperation,
	|	CASE
	|		WHEN GoodsForIssue.ToRegisterBalance > 0
	|			THEN GoodsForIssue.ToRegisterBalance
	|	END AS UnfinishedFinancialTransaction,
	|	ISNULL(DetailsOfOrder.IBDocumentDate, DATETIME(1,1,1)) AS DateOfTransaction,
	|	GoodsForIssue.DocumentShipments AS ReferenceOrder,
	|	GoodsForIssue.Warehouse AS Warehouse,
	|	GoodsForIssue.Products AS Products,
	|	GoodsForIssue.Characteristic AS Characteristic,
	|	GoodsForIssue.Series,
	|	GoodsForIssue.Purpose
	|{SELECT
	|	Warehouse.*,
	|	Products.*,
	|	Characteristic.*,
	|	Series.*,
	|	Purpose.*}
	|FROM
	|	AccumulationRegister.GoodsForIssue.Balance(
	|		&PeriodLimit, 
	|		VALUETYPE(DocumentShipments) IN (TYPE(Document.InventoryConsumptionOrder), 
	|			TYPE(Document.InventoryConsumption)
	|			,TYPE(Document.RMOrder)
	|		) 
	|		AND &SelectionOfGoodsByRegister
	|		{(DocumentShipments).* AS ReferenceOrder, (Warehouse).*, (Products).*, (Characteristic).*, (Series).*, (Purpose).*}
	|	) AS GoodsForIssue
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS DetailsOfOrder
	|		ON GoodsForIssue.DocumentShipments = DetailsOfOrder.Ref
	|			AND NOT DetailsOfOrder.AdditionalRecord
	|WHERE
	|	GoodsForIssue.ToShipBalance - GoodsForIssue.ToRegisterBalance <> 0
	|{WHERE
	|	(&LineTypeOfOperationInternalConsumption) AS OperationKind,
	|	(&LineTypeOfDeviationRegistrationOfWarehouseDocuments) AS VarianceType,
	|	(CASE
	|			WHEN GoodsForIssue.ToShipBalance - GoodsForIssue.ToRegisterBalance <> 0
	|				THEN &LineRecommendationCreateAGoodsIssueNote
	|		END) AS Recommendation,
	|	(CASE
	|			WHEN GoodsForIssue.ToShipBalance - GoodsForIssue.ToRegisterBalance <> 0
	|				THEN -GoodsForIssue.ToShipBalance
	|		END) AS IncompleteWarehouseOperation}";
	
	Return QueryText;
EndFunction

Function QueryTextInventoryTransfer()
	// String literals are localized in the report's SCD settings
	// Datasets - Fields - Available values.
	QueryText = "SELECT ALLOWED
	|	&LineTypeOfOperationMovingGoods AS OperationKind,
	|	&LineTypeOfDeviationRegistrationOfWarehouseDocuments AS VarianceType,
	|	CASE
	|		WHEN GoodsForIssue.ToShipBalance - GoodsForIssue.ToRegisterBalance <> 0
	|			THEN &LineRecommendationCreateAGoodsIssueNote
	|	END AS Recommendation,
	|	CASE
	|		WHEN GoodsForIssue.ToShipBalance - GoodsForIssue.ToRegisterBalance <> 0
	|			THEN -GoodsForIssue.ToShipBalance
	|	END AS IncompleteWarehouseOperation,
	|	0 AS UnfinishedFinancialTransaction,
	|	ISNULL(DetailsOfOrder.IBDocumentDate, DATETIME(1,1,1)) AS DateOfTransaction,
	|	GoodsForIssue.DocumentShipments AS ReferenceOrder,
	|	GoodsForIssue.Warehouse AS Warehouse,
	|	GoodsForIssue.Products AS Products,
	|	GoodsForIssue.Characteristic AS Characteristic,
	|	GoodsForIssue.Series,
	|	GoodsForIssue.Purpose
	|FROM
	|	AccumulationRegister.GoodsForIssue.Balance(
	|		&PeriodLimit, 
	|		VALUETYPE(DocumentShipments) IN (TYPE(Document.TransferOrder), 
	|			TYPE(Document.InventoryTransfer)) 
	|		AND &SelectionOfGoodsByRegister
	|		{(DocumentShipments).* AS ReferenceOrder, (Warehouse).*, (Products).*, (Characteristic).*, (Series).*, (Purpose).*}
	|	) AS GoodsForIssue
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS DetailsOfOrder
	|		ON GoodsForIssue.DocumentShipments = DetailsOfOrder.Ref
	|			AND NOT DetailsOfOrder.AdditionalRecord
	|WHERE
	|	GoodsForIssue.ToShipBalance - GoodsForIssue.ToRegisterBalance <> 0
	|{WHERE
	|	(&LineTypeOfOperationMovingGoods) AS OperationKind,
	|	(&LineTypeOfDeviationRegistrationOfWarehouseDocuments) AS VarianceType,
	|	(CASE
	|			WHEN GoodsForIssue.ToShipBalance - GoodsForIssue.ToRegisterBalance <> 0
	|				THEN &LineRecommendationCreateAGoodsIssueNote
	|		END) AS Recommendation,
	|	(CASE
	|			WHEN GoodsForIssue.ToShipBalance - GoodsForIssue.ToRegisterBalance <> 0
	|				THEN -GoodsForIssue.ToShipBalance
	|		END) AS IncompleteWarehouseOperation}
	|
	|UNION ALL
	|
	|SELECT
	|	&LineTypeOfOperationMovingGoods,
	|	CASE
	|		WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|			THEN &LineTypeOfDeviationProcessingOfFinancialDocuments
	|		ELSE &LineTypeOfDeviationRegistrationOfWarehouseDocuments
	|	END,
	|	CASE
	|		WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|			THEN &LineRecommendationRegisterGoodsTransferInStatusReceived
	|		ELSE &LineRecommendationRegisterGoodsReceiptNotes
	|	END,
	|	CASE
	|		WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|			THEN 0
	|		ELSE -GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance
	|	END,
	|	CASE
	|		WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|			THEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance
	|		ELSE 0
	|	END,
	|	ISNULL(DetailsOfOrder.IBDocumentDate, DATETIME(1,1,1)),
	|	GoodsReadyForReceipt.DocumentInflow,
	|	GoodsReadyForReceipt.Warehouse,
	|	GoodsReadyForReceipt.Products,
	|	GoodsReadyForReceipt.Characteristic,
	|	GoodsReadyForReceipt.Series,
	|	GoodsReadyForReceipt.Purpose
	|FROM
	|	AccumulationRegister.GoodsToReceive.Balance(
	|		&PeriodLimit, 
	|		VALUETYPE(DocumentInflow) IN (TYPE(Document.TransferOrder), 
	|			TYPE(Document.InventoryTransfer)) 
	|		AND &SelectionOfGoodsByRegister
	|		{(DocumentInflow).* AS ReferenceOrder, (Warehouse).*, (Products).*, (Characteristic).*, (Series).*, (Purpose).*}
	|	) AS GoodsReadyForReceipt
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS DetailsOfOrder
	|		ON GoodsReadyForReceipt.DocumentInflow = DetailsOfOrder.Ref
	|			AND NOT DetailsOfOrder.AdditionalRecord
	|{WHERE
	|	(&LineTypeOfOperationMovingGoods) AS OperationKind,
	|	(CASE
	|			WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|				THEN &LineTypeOfDeviationProcessingOfFinancialDocuments
	|			ELSE &LineTypeOfDeviationRegistrationOfWarehouseDocuments
	|		END) AS VarianceType,
	|	(CASE
	|			WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|				THEN &LineRecommendationRegisterGoodsTransferInStatusReceived
	|			ELSE &LineRecommendationRegisterGoodsReceiptNotes
	|		END) AS Recommendation,
	|	(CASE
	|			WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|				THEN 0
	|			ELSE -GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance
	|		END) AS IncompleteWarehouseOperation,
	|	(CASE
	|			WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|				THEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance
	|			ELSE 0
	|		END) AS UnfinishedFinancialTransaction}
	|
	|UNION ALL
	|
	|SELECT
	|	&LineTypeOfOperationMovingGoods,
	|	&LineTypeOfDeviationRegistrationOfWarehouseDocuments,
	|	&LineRecommendationRegisterGoodsTransferInStatusReceived,
	|	InventoryTransfer.Count,
	|	InventoryTransfer.Count,
	|	CASE
	|		WHEN NOT InventoryTransfer.Ref.TransferOrder.Ref IS NULL 
	|			THEN InventoryTransfer.Ref.TransferOrder.Date
	|		ELSE InventoryTransfer.Ref.Date
	|	END,
	|	CASE
	|		WHEN NOT InventoryTransfer.Ref.TransferOrder.Ref IS NULL 
	|			THEN InventoryTransfer.Ref.TransferOrder
	|		ELSE InventoryTransfer.Ref
	|	END,
	|	InventoryTransfer.Ref.DestinationWarehouse,
	|	InventoryTransfer.Products,
	|	InventoryTransfer.Characteristic,
	|	InventoryTransfer.Series,
	|	InventoryTransfer.Purpose
	|FROM
	|	Document.InventoryTransfer.Goods AS InventoryTransfer
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON InventoryTransfer.Ref = DocumentsRegistry.ReversedDocument
	|			AND DocumentsRegistry.Posted
	|			AND NOT DocumentsRegistry.AdditionalRecord
	|WHERE
	|	InventoryTransfer.Ref.Posted
	|	AND DocumentsRegistry.Ref IS NULL
	|	AND InventoryTransfer.Ref.Status <> VALUE(Enum.GoodsTransferStatuses.Accepted)
	|	AND InventoryTransfer.Ref.Date <= &EndOfDayDate
	|	AND &SelectionOfGoodsByMovement
	|{WHERE
	|	(&LineTypeOfOperationMovingGoods) AS OperationKind,
	|	(&LineTypeOfDeviationRegistrationOfWarehouseDocuments) AS VarianceType,
	|	(&LineRecommendationRegisterGoodsTransferInStatusReceived) AS Recommendation,
	|	InventoryTransfer.Count AS IncompleteWarehouseOperation,
	|	InventoryTransfer.Count AS UnfinishedFinancialTransaction}";
	
	Return QueryText;
EndFunction

Function QueryTextAssemblyDisassembly()
	// String literals are localized in the report's SCD settings
	// Datasets - Fields - Available values.
	QueryText = "SELECT ALLOWED
	|	&LineTypeOfOperationAssemblyDisassemblyOfGoods AS OperationKind,
	|	&LineTypeOfDeviationRegistrationOfWarehouseDocuments AS VarianceType,
	|	CASE
	|		WHEN GoodsForIssue.ToShipBalance - GoodsForIssue.ToRegisterBalance <> 0
	|			THEN &LineRecommendationCreateAGoodsIssueNote
	|	END AS Recommendation,
	|	CASE
	|		WHEN GoodsForIssue.ToShipBalance - GoodsForIssue.ToRegisterBalance <> 0
	|			THEN -GoodsForIssue.ToShipBalance
	|	END AS IncompleteWarehouseOperation,
	|	0 AS UnfinishedFinancialTransaction,
	|	ISNULL(DetailsOfOrder.IBDocumentDate, DATETIME(1,1,1)) AS DateOfTransaction,
	|	GoodsForIssue.DocumentShipments AS ReferenceOrder,
	|	GoodsForIssue.Warehouse AS Warehouse,
	|	GoodsForIssue.Products AS Products,
	|	GoodsForIssue.Characteristic AS Characteristic,
	|	GoodsForIssue.Series,
	|	GoodsForIssue.Purpose
	|{SELECT
	|	Warehouse.*,
	|	Products.*,
	|	Characteristic.*,
	|	Series.*,
	|	Purpose.*}
	|FROM
	|	AccumulationRegister.GoodsForIssue.Balance(
	|		&PeriodLimit, 
	|		VALUETYPE(DocumentShipments) IN (TYPE(Document.ByAssemblyDisassemblyOrder), 
	|			TYPE(Document.AssemblyFromComponents)) 
	|		AND &SelectionOfGoodsByRegister
	|		{(DocumentShipments).* AS ReferenceOrder, (Warehouse).*, (Products).*, (Characteristic).*, (Series).*, (Purpose).*}
	|	) AS GoodsForIssue
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS DetailsOfOrder
	|		ON GoodsForIssue.DocumentShipments = DetailsOfOrder.Ref
	|			AND NOT DetailsOfOrder.AdditionalRecord
	|WHERE
	|	GoodsForIssue.ToShipBalance - GoodsForIssue.ToRegisterBalance <> 0
	|{WHERE
	|	(&LineTypeOfOperationAssemblyDisassemblyOfGoods) AS OperationKind,
	|	(&LineTypeOfDeviationRegistrationOfWarehouseDocuments) AS VarianceType,
	|	(CASE
	|			WHEN GoodsForIssue.ToShipBalance - GoodsForIssue.ToRegisterBalance <> 0
	|				THEN &LineRecommendationCreateAGoodsIssueNote
	|		END) AS Recommendation,
	|	(CASE
	|			WHEN GoodsForIssue.ToShipBalance - GoodsForIssue.ToRegisterBalance <> 0
	|				THEN -GoodsForIssue.ToShipBalance
	|		END) AS IncompleteWarehouseOperation}
	|
	|UNION ALL
	|
	|SELECT
	|	&LineTypeOfOperationAssemblyDisassemblyOfGoods,
	|	CASE
	|		WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|			THEN &LineTypeOfDeviationProcessingOfFinancialDocuments
	|		ELSE &LineTypeOfDeviationRegistrationOfWarehouseDocuments
	|	END,
	|	CASE
	|		WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|			THEN CASE
	|					WHEN ISNULL(DetailsOfOrder.BusinessOperation, VALUE(Enum.BusinessTransactions.EmptyRef)) = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents)
	|						THEN &LineRecommendationRegisterDisassemblyDocumentInStatusAssembledDisassembled
	|					WHEN ISNULL(DetailsOfOrder.BusinessOperation, VALUE(Enum.BusinessTransactions.EmptyRef)) = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
	|						THEN &LineRecommendationRegisterAssemblyDocumentInStatusAssembledDisassembled
	|				END
	|		ELSE &LineRecommendationRegisterGoodsReceiptNotes
	|	END,
	|	CASE
	|		WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|			THEN 0
	|		ELSE -GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance
	|	END,
	|	CASE
	|		WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|			THEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance
	|		ELSE 0
	|	END,
	|	ISNULL(DetailsOfOrder.IBDocumentDate, DATETIME(1,1,1)),
	|	GoodsReadyForReceipt.DocumentInflow,
	|	GoodsReadyForReceipt.Warehouse,
	|	GoodsReadyForReceipt.Products,
	|	GoodsReadyForReceipt.Characteristic,
	|	GoodsReadyForReceipt.Series,
	|	GoodsReadyForReceipt.Purpose
	|FROM
	|	AccumulationRegister.GoodsToReceive.Balance(
	|		&PeriodLimit, 
	|		VALUETYPE(DocumentInflow) IN (TYPE(Document.ByAssemblyDisassemblyOrder), 
	|			TYPE(Document.AssemblyFromComponents)) 
	|		AND &SelectionOfGoodsByRegister
	|		{(DocumentInflow).* AS ReferenceOrder, (Warehouse).*, (Products).*, (Characteristic).*, (Series).*, (Purpose).*}
	|	) AS GoodsReadyForReceipt
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS DetailsOfOrder
	|		ON GoodsReadyForReceipt.DocumentInflow = DetailsOfOrder.Ref
	|			AND NOT DetailsOfOrder.AdditionalRecord
	|{WHERE
	|	(&LineTypeOfOperationAssemblyDisassemblyOfGoods) AS OperationKind,
	|	(CASE
	|			WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|				THEN &LineTypeOfDeviationProcessingOfFinancialDocuments
	|			ELSE &LineTypeOfDeviationRegistrationOfWarehouseDocuments
	|		END) AS VarianceType,
	|	(CASE
	|			WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|				THEN CASE
	|						WHEN ISNULL(DetailsOfOrder.BusinessOperation, VALUE(Enum.BusinessTransactions.EmptyRef)) = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents)
	|							THEN &LineRecommendationRegisterDisassemblyDocumentInStatusAssembledDisassembled
	|						WHEN ISNULL(DetailsOfOrder.BusinessOperation, VALUE(Enum.BusinessTransactions.EmptyRef)) = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
	|							THEN &LineRecommendationRegisterAssemblyDocumentInStatusAssembledDisassembled
	|					END
	|			ELSE &LineRecommendationRegisterGoodsReceiptNotes
	|		END) AS Recommendation,
	|	(CASE
	|			WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|				THEN 0
	|			ELSE -GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance
	|		END) AS IncompleteWarehouseOperation,
	|	(CASE
	|			WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|				THEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance
	|			ELSE 0
	|		END) AS UnfinishedFinancialTransaction}
	|
	|UNION ALL
	|
	|SELECT
	|	&LineTypeOfOperationAssemblyDisassemblyOfGoods,
	|	&LineTypeOfDeviationProcessingOfFinancialDocuments,
	|	&LineRecommendationRegisterDisassemblyDocumentInStatusAssembledDisassembled,
	|	0,
	|	AssemblyDisassemblyOfGoods.Count,
	|	CASE
	|		WHEN NOT AssemblyDisassemblyOfGoods.Ref.ByAssemblyDisassemblyOrder.Ref IS NULL 
	|			THEN AssemblyDisassemblyOfGoods.Ref.ByAssemblyDisassemblyOrder.Date
	|		ELSE AssemblyDisassemblyOfGoods.Ref.Date
	|	END,
	|	CASE
	|		WHEN NOT AssemblyDisassemblyOfGoods.Ref.ByAssemblyDisassemblyOrder.Ref IS NULL 
	|			THEN AssemblyDisassemblyOfGoods.Ref.ByAssemblyDisassemblyOrder
	|		ELSE AssemblyDisassemblyOfGoods.Ref
	|	END,
	|	AssemblyDisassemblyOfGoods.Ref.Warehouse,
	|	AssemblyDisassemblyOfGoods.Products,
	|	AssemblyDisassemblyOfGoods.Characteristic,
	|	AssemblyDisassemblyOfGoods.Series,
	|	AssemblyDisassemblyOfGoods.Purpose
	|FROM
	|	Document.AssemblyFromComponents.Goods AS AssemblyDisassemblyOfGoods
	|WHERE
	|	AssemblyDisassemblyOfGoods.Ref.Posted
	|	AND AssemblyDisassemblyOfGoods.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents)
	|	AND AssemblyDisassemblyOfGoods.Ref.Status <> VALUE(Enum.GoodsAssemblyStatuses.AssembledDisassembled)
	|	AND AssemblyDisassemblyOfGoods.Ref.Date <= &EndOfDayDate
	|	AND &SelectionOfGoodsForDisassembly
	|{WHERE
	|	(&LineTypeOfOperationAssemblyDisassemblyOfGoods) AS OperationKind,
	|	(&LineTypeOfDeviationProcessingOfFinancialDocuments) AS VarianceType,
	|	(&LineRecommendationRegisterDisassemblyDocumentInStatusAssembledDisassembled) AS Recommendation,
	|	AssemblyDisassemblyOfGoods.Count AS IncompleteWarehouseOperation,
	|	AssemblyDisassemblyOfGoods.Count AS UnfinishedFinancialTransaction}
	|
	|UNION ALL
	|
	|SELECT
	|	&LineTypeOfOperationAssemblyDisassemblyOfGoods,
	|	&LineTypeOfDeviationProcessingOfFinancialDocuments,
	|	&LineRecommendationRegisterAssemblyDocumentInStatusAssembledDisassembled,
	|	0,
	|	AssemblyDisassemblyOfGoods.Count,
	|	CASE
	|		WHEN NOT AssemblyDisassemblyOfGoods.ByAssemblyDisassemblyOrder.Ref IS NULL 
	|			THEN AssemblyDisassemblyOfGoods.ByAssemblyDisassemblyOrder.Date
	|		ELSE AssemblyDisassemblyOfGoods.Ref.Date
	|	END,
	|	CASE
	|		WHEN NOT AssemblyDisassemblyOfGoods.ByAssemblyDisassemblyOrder.Ref IS NULL 
	|			THEN AssemblyDisassemblyOfGoods.ByAssemblyDisassemblyOrder
	|		ELSE AssemblyDisassemblyOfGoods.Ref
	|	END,
	|	AssemblyDisassemblyOfGoods.Warehouse,
	|	AssemblyDisassemblyOfGoods.Products,
	|	AssemblyDisassemblyOfGoods.Characteristic,
	|	AssemblyDisassemblyOfGoods.Series,
	|	AssemblyDisassemblyOfGoods.Purpose
	|FROM
	|	Document.AssemblyFromComponents AS AssemblyDisassemblyOfGoods
	|WHERE
	|	AssemblyDisassemblyOfGoods.Posted
	|	AND AssemblyDisassemblyOfGoods.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
	|	AND AssemblyDisassemblyOfGoods.Status <> VALUE(Enum.GoodsAssemblyStatuses.AssembledDisassembled)
	|	AND AssemblyDisassemblyOfGoods.Date <= &EndOfDayDate
	|	AND &SelectionOfGoodsByAssembly
	|{WHERE
	|	(&LineTypeOfOperationAssemblyDisassemblyOfGoods) AS OperationKind,
	|	(&LineTypeOfDeviationProcessingOfFinancialDocuments) AS VarianceType,
	|	(&LineRecommendationRegisterAssemblyDocumentInStatusAssembledDisassembled) AS Recommendation,
	|	AssemblyDisassemblyOfGoods.Count AS UnfinishedFinancialTransaction}";
	
	Return QueryText;
EndFunction

Function RequestTextOtherAttributes()
	// String literals are localized in the report's SCD settings
	// Datasets - Fields - Available values.
	QueryText = "SELECT ALLOWED
	|	&LineTypeOfOperationOtherProductRegistration AS OperationKind,
	|	CASE
	|		WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|			THEN &LineTypeOfDeviationProcessingOfFinancialDocuments
	|		ELSE &LineTypeOfDeviationRegistrationOfWarehouseDocuments
	|	END AS VarianceType,
	|	CASE
	|		WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|			THEN &LineRecommendationRegisterOtherRecordingOfGoodsAsReceived
	|		ELSE &LineRecommendationRegisterGoodsReceiptNotes
	|	END AS Recommendation,
	|	CASE
	|		WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|			THEN 0
	|		ELSE -GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance
	|	END AS IncompleteWarehouseOperation,
	|	CASE
	|		WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|			THEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance
	|		ELSE 0
	|	END AS UnfinishedFinancialTransaction,
	|	ISNULL(DetailsOfOrder.IBDocumentDate, DATETIME(1,1,1)) AS DateOfTransaction,
	|	GoodsReadyForReceipt.DocumentInflow AS ReferenceOrder,
	|	GoodsReadyForReceipt.Warehouse AS Warehouse,
	|	GoodsReadyForReceipt.Products AS Products,
	|	GoodsReadyForReceipt.Characteristic AS Characteristic,
	|	GoodsReadyForReceipt.Series,
	|	GoodsReadyForReceipt.Purpose
	|{SELECT
	|	Warehouse.*,
	|	Products.*,
	|	Characteristic.*,
	|	Series.*,
	|	Purpose.*}
	|FROM
	|	AccumulationRegister.GoodsToReceive.Balance(
	|		&PeriodLimit, 
	|		VALUETYPE(DocumentInflow) IN (TYPE(Document.OtherGoodsRecordingAsReceived)) 
	|		AND &SelectionOfGoodsByRegister
	|		{(DocumentInflow).* AS ReferenceOrder, (Warehouse).*, (Products).*, (Characteristic).*, (Series).*, (Purpose).*}
	|	) AS GoodsReadyForReceipt
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS DetailsOfOrder
	|		ON GoodsReadyForReceipt.DocumentInflow = DetailsOfOrder.Ref
	|			AND NOT DetailsOfOrder.AdditionalRecord
	|{WHERE
	|	(&LineTypeOfOperationOtherProductRegistration) AS OperationKind,
	|	(CASE
	|			WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|				THEN &LineTypeOfDeviationProcessingOfFinancialDocuments
	|			ELSE &LineTypeOfDeviationRegistrationOfWarehouseDocuments
	|		END) AS VarianceType,
	|	(CASE
	|			WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|				THEN &LineRecommendationRegisterOtherRecordingOfGoodsAsReceived
	|			ELSE &LineRecommendationRegisterGoodsReceiptNotes
	|		END) AS Recommendation,
	|	(CASE
	|			WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|				THEN 0
	|			ELSE -GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance
	|		END) AS IncompleteWarehouseOperation,
	|	(CASE
	|			WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|				THEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance
	|			ELSE 0
	|		END) AS UnfinishedFinancialTransaction}";
	
	Return QueryText;
EndFunction

Function QueryTextRegistrationOfSurplusShortages()
	// String literals are localized in the report's SCD settings
	// Datasets - Fields - Available values.
	QueryText = "SELECT ALLOWED
	|	&LineTypeOfOperationRegistrationOfSurplusesAndShortages AS OperationKind,
	|	&LineTypeOfDeviationProcessingOfFinancialDocuments AS VarianceType,
	|	CASE
	|		WHEN UnderestimatedSurplusesAndShortages.ToCertificateRegistrationBalance > 0
	|			THEN &LineRecommendationRegisterWarehouseActsToRecordSurplus
	|		ELSE &LineRecommendationRegisterWarehouseActsToRecordShortages
	|	END AS Recommendation,
	|	0 AS IncompleteWarehouseOperation,
	|	UnderestimatedSurplusesAndShortages.ToCertificateRegistrationBalance AS UnfinishedFinancialTransaction,
	|	DATETIME(1, 1, 1) AS DateOfTransaction,
	|	UNDEFINED AS ReferenceOrder,
	|	UnderestimatedSurplusesAndShortages.Warehouse AS Warehouse,
	|	UnderestimatedSurplusesAndShortages.Products AS Products,
	|	UnderestimatedSurplusesAndShortages.Characteristic AS Characteristic,
	|	UnderestimatedSurplusesAndShortages.Series,
	|	UnderestimatedSurplusesAndShortages.Purpose
	|{SELECT
	|	Warehouse.*,
	|	Products.*,
	|	Characteristic.*,
	|	Series.*,
	|	Purpose.*}
	|FROM
	|	AccumulationRegister.GoodsForRegistrationOfSurplusesAndShortages.Balance(
	|		&PeriodLimit, 
	|		&SelectionOfGoodsByRegister
	|		{(Warehouse).*, (Products).*, (Characteristic).*, (Series).*, (Purpose).*}
	|	) AS UnderestimatedSurplusesAndShortages
	|{WHERE
	|	(&LineTypeOfOperationRegistrationOfSurplusesAndShortages) AS OperationKind,
	|	(&LineTypeOfDeviationProcessingOfFinancialDocuments) AS VarianceType,
	|	(CASE
	|			WHEN UnderestimatedSurplusesAndShortages.ToCertificateRegistrationBalance > 0
	|				THEN &LineRecommendationRegisterWarehouseActsToRecordSurplus
	|			ELSE &LineRecommendationRegisterWarehouseActsToRecordShortages
	|		END) AS Recommendation,
	|	UnderestimatedSurplusesAndShortages.ToCertificateRegistrationBalance AS UnfinishedFinancialTransaction}";
	
	Return QueryText;
EndFunction

Function QueryTextShipReceivedGoodsFromStorage()
	// String literals are localized in the report's SCD settings
	// Datasets - Fields - Available values.
	QueryText = "SELECT ALLOWED
	|	&LineOperationKindShipmentOfGoodsReceivedFromStorage AS OperationKind,
	|	CASE
	|		WHEN GoodsForIssue.ToShipBalance > 0
	|			THEN &LineTypeOfDeviationRegistrationOfWarehouseDocuments
	|		ELSE &LineTypeOfDeviationProcessingOfFinancialDocuments
	|	END AS VarianceType,
	|	CASE
	|		WHEN GoodsForIssue.ToShipBalance > 0
	|			THEN &LineRecommendationRegisterGoodsIssueNotes
	|		ELSE &LineRecommendationRegisterShipmentOfGoodsFromStorage
	|	END AS Recommendation,
	|	CASE
	|		WHEN GoodsForIssue.ToShipBalance > 0
	|			THEN -GoodsForIssue.ToShipBalance
	|		ELSE 0
	|	END AS IncompleteWarehouseOperation,
	|	CASE
	|		WHEN GoodsForIssue.ToShipBalance < 0
	|			THEN -GoodsForIssue.ToShipBalance
	|		ELSE 0
	|	END AS UnfinishedFinancialTransaction,
	|	ISNULL(DetailsOfOrder.IBDocumentDate, DATETIME(1,1,1)) AS DateOfTransaction,
	|	GoodsForIssue.DocumentShipments AS ReferenceOrder,
	|	GoodsForIssue.Warehouse AS Warehouse,
	|	GoodsForIssue.Products AS Products,
	|	GoodsForIssue.Characteristic AS Characteristic,
	|	GoodsForIssue.Series,
	|	GoodsForIssue.Purpose
	|{SELECT
	|	Warehouse.*,
	|	Products.*,
	|	Characteristic.*,
	|	Series.*,
	|	Purpose.*}
	|FROM
	|	AccumulationRegister.GoodsForIssue.Balance(
	|		&PeriodLimit,
	|		VALUETYPE(DocumentShipments) IN (TYPE(Document.GoodsShipmentFromStorage))
	|		AND &SelectionOfGoodsByRegister
	|		{(DocumentShipments).* AS ReferenceOrder, (Warehouse).*, (Products).*, (Characteristic).*, (Series).*, (Purpose).*}
	|	) AS GoodsForIssue
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DetailsOfOrder
	|		ON GoodsForIssue.DocumentShipments = DetailsOfOrder.Ref
	|			AND NOT DetailsOfOrder.AdditionalRecord
	|WHERE
	|	GoodsForIssue.ToShipBalance <> 0
	|{WHERE
	|	(&LineOperationKindShipmentOfGoodsReceivedFromStorage) AS OperationKind,
	|	(CASE
	|			WHEN GoodsForIssue.ToShipBalance > 0
	|				THEN &LineTypeOfDeviationRegistrationOfWarehouseDocuments
	|			ELSE &LineTypeOfDeviationProcessingOfFinancialDocuments
	|		END) AS VarianceType,
	|	(CASE
	|			WHEN GoodsForIssue.ToShipBalance > 0
	|				THEN &LineRecommendationRegisterGoodsIssueNotes
	|			ELSE &LineRecommendationRegisterShipmentOfGoodsFromStorage
	|		END) AS Recommendation,
	|	(CASE
	|			WHEN GoodsForIssue.ToShipBalance > 0
	|				THEN GoodsForIssue.ToShipBalance
	|			ELSE 0
	|		END) AS IncompleteWarehouseOperation,
	|	(CASE
	|			WHEN GoodsForIssue.ToShipBalance < 0
	|				THEN GoodsForIssue.ToShipBalance
	|			ELSE 0
	|		END) AS UnfinishedFinancialTransaction}";
	
	Return QueryText;
EndFunction

Function QueryTextGoodsReceiptForStorage()
	// String literals are localized in the report's SCD settings
	// Datasets - Fields - Available values.
	QueryText = "SELECT ALLOWED
	|	&LineOperationKindGoodsReceivingForStorage AS OperationKind,
	|	CASE
	|		WHEN GoodsToReceive.ToRegisterGoodsReceiptsBalance < 0
	|			THEN &LineTypeOfDeviationRegistrationOfWarehouseDocuments
	|		ELSE &LineTypeOfDeviationProcessingOfFinancialDocuments
	|	END AS VarianceType,
	|	CASE
	|		WHEN GoodsToReceive.ToRegisterGoodsReceiptsBalance < 0
	|			THEN &LineRecommendationRegisterGoodsReceiptNotes
	|		ELSE &LineRecommendationRegisterReceivingOfGoodsForStorage
	|	END AS Recommendation,
	|	CASE
	|		WHEN GoodsToReceive.ToRegisterGoodsReceiptsBalance < 0
	|			THEN -GoodsToReceive.ToRegisterGoodsReceiptsBalance
	|		ELSE 0
	|	END AS IncompleteWarehouseOperation,
	|	CASE
	|		WHEN GoodsToReceive.ToRegisterGoodsReceiptsBalance > 0
	|			THEN GoodsToReceive.ToRegisterGoodsReceiptsBalance
	|		ELSE 0
	|	END AS UnfinishedFinancialTransaction,
	|	ISNULL(DetailsOfOrder.IBDocumentDate, DATETIME(1,1,1)) AS DateOfTransaction,
	|	GoodsToReceive.DocumentInflow AS ReferenceOrder,
	|	GoodsToReceive.Warehouse AS Warehouse,
	|	GoodsToReceive.Products AS Products,
	|	GoodsToReceive.Characteristic AS Characteristic,
	|	GoodsToReceive.Series,
	|	GoodsToReceive.Purpose
	|{SELECT
	|	Warehouse.*,
	|	Products.*,
	|	Characteristic.*,
	|	Series.*,
	|	Purpose.*}
	|FROM
	|	AccumulationRegister.GoodsToReceive.Balance(
	|		&PeriodLimit,
	|		DocumentInflow IN (
	|			SELECT
	|				ReceiptOrders.Ref
	|			FROM
	|				OrdersForReceiptForAcceptanceForStorage AS ReceiptOrders)
	|		AND &SelectionOfGoodsByRegister
	|		{(DocumentInflow).* AS ReferenceOrder, (Warehouse).*, (Products).*, (Characteristic).*, (Series).*, (Purpose).*}
	|	) AS GoodsToReceive
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DetailsOfOrder
	|		ON GoodsToReceive.DocumentInflow = DetailsOfOrder.Ref
	|			AND NOT DetailsOfOrder.AdditionalRecord
	|WHERE
	|	GoodsToReceive.ToRegisterGoodsReceiptsBalance <> 0
	|{WHERE
	|	(&LineOperationKindGoodsReceivingForStorage) AS OperationKind,
	|	(CASE
	|			WHEN GoodsToReceive.ToRegisterGoodsReceiptsBalance < 0
	|				THEN &LineTypeOfDeviationRegistrationOfWarehouseDocuments
	|			ELSE &LineTypeOfDeviationProcessingOfFinancialDocuments
	|		END) AS VarianceType,
	|	(CASE
	|			WHEN GoodsToReceive.ToRegisterGoodsReceiptsBalance < 0
	|				THEN &LineRecommendationRegisterGoodsReceiptNotes
	|			ELSE &LineRecommendationRegisterReceivingOfGoodsForStorage
	|		END) AS Recommendation,
	|	(CASE
	|			WHEN GoodsToReceive.ToRegisterGoodsReceiptsBalance < 0
	|				THEN -GoodsToReceive.ToRegisterGoodsReceiptsBalance
	|			ELSE 0
	|		END) AS IncompleteWarehouseOperation,
	|	(CASE
	|			WHEN GoodsToReceive.ToRegisterGoodsReceiptsBalance > 0
	|				THEN GoodsToReceive.ToRegisterGoodsReceiptsBalance
	|			ELSE 0
	|		END) AS UnfinishedFinancialTransaction}";
	
	Return QueryText;
EndFunction

Function RequestTextForTemporaryTablesForAcceptanceOfGoodsForStorage()
	
	QueryText = "
	|SELECT ALLOWED
	|	DocumentInflow.Ref AS Ref
	|INTO OrdersForReceiptForAcceptanceForStorage
	|FROM
	|	Catalog.TermsOfPurchaseFromVendors AS DocumentInflow
	|WHERE
	|	NOT DocumentInflow.DeletionMark
	|	AND DocumentInflow.BusinessOperation = VALUE(Enum.BusinessTransactions.ReceivingForStorageWithRightOfSale)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentInflow.Ref AS Ref
	|FROM
	|	Document.PurchaseOrder AS DocumentInflow
	|WHERE
	|	NOT DocumentInflow.DeletionMark
	|	AND DocumentInflow.BusinessOperation = VALUE(Enum.BusinessTransactions.ReceivingForStorageWithRightOfSale)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentInflow.Ref AS Ref
	|FROM
	|	Document.GoodsReceiptForStorage AS DocumentInflow
	|WHERE
	|	NOT DocumentInflow.DeletionMark
	|
	|INDEX BY
	|	Ref";
	
	Return QueryText;
	
EndFunction

Function QueryTextMaterialTransferToProduction()
	// String literals are localized in the report's SCD settings
	// Datasets - Fields - Available values.
	QueryText = "SELECT ALLOWED
	|	&LineTypeOfOperationTransferOfMaterialsToProduction AS OperationKind,
	|	&LineTypeOfDeviationRegistrationOfWarehouseDocuments AS VarianceType,
	|	CASE
	|		WHEN GoodsForIssue.ToShipBalance - GoodsForIssue.ToRegisterBalance <> 0
	|			THEN &LineRecommendationCreateAGoodsIssueNote
	|	END AS Recommendation,
	|	CASE
	|		WHEN GoodsForIssue.ToShipBalance - GoodsForIssue.ToRegisterBalance <> 0
	|			THEN -GoodsForIssue.ToShipBalance
	|	END AS IncompleteWarehouseOperation,
	|	0 AS UnfinishedFinancialTransaction,
	|	ISNULL(DetailsOfOrder.IBDocumentDate, DATETIME(1,1,1)) AS DateOfTransaction,
	|	GoodsForIssue.DocumentShipments AS ReferenceOrder,
	|	GoodsForIssue.Warehouse AS Warehouse,
	|	GoodsForIssue.Products AS Products,
	|	GoodsForIssue.Characteristic AS Characteristic,
	|	GoodsForIssue.Series,
	|	GoodsForIssue.Purpose
	|{SELECT
	|	Warehouse.*,
	|	Products.*,
	|	Characteristic.*,
	|	Series.*,
	|	Purpose.*}
	|FROM
	|	AccumulationRegister.GoodsForIssue.Balance(
	|		&PeriodLimit, 
	|		VALUETYPE(DocumentShipments) IN (
	|			TYPE(Document.MovementOfProductsAndMaterials), 
	|			TYPE(Document.OrderOfMaterialsForProduction)
	|) 
	|		AND &SelectionOfGoodsByRegister
	|		{(DocumentShipments).* AS ReferenceOrder, (Warehouse).*, (Products).*, (Characteristic).*, (Series).*, (Purpose).*}
	|	) AS GoodsForIssue
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS DetailsOfOrder
	|		ON GoodsForIssue.DocumentShipments = DetailsOfOrder.Ref
	|			AND NOT DetailsOfOrder.AdditionalRecord
	|WHERE
	|	GoodsForIssue.ToShipBalance - GoodsForIssue.ToRegisterBalance <> 0
	|	AND (GoodsForIssue.DocumentShipments REFS Document.MovementOfProductsAndMaterials
	|	AND ISNULL(DetailsOfOrder.BusinessOperation, 
	|		VALUE(Enum.BusinessTransactions.TransferToProduction)) IN (
	|			VALUE(Enum.BusinessTransactions.TransferToProduction),
	|			VALUE(Enum.BusinessTransactions.MaterialTransferToProduction),
	|			VALUE(Enum.BusinessTransactions.TransferOfMaterialsToStoreroom))
	|	OR NOT GoodsForIssue.DocumentShipments REFS Document.MovementOfProductsAndMaterials)
	|{WHERE
	|	(&LineTypeOfOperationTransferOfMaterialsToProduction) AS OperationKind,
	|	(&LineTypeOfDeviationRegistrationOfWarehouseDocuments) AS VarianceType,
	|	(CASE
	|			WHEN GoodsForIssue.ToShipBalance - GoodsForIssue.ToRegisterBalance <> 0
	|				THEN &LineRecommendationCreateAGoodsIssueNote
	|		END) AS Recommendation,
	|	(CASE
	|			WHEN GoodsForIssue.ToShipBalance - GoodsForIssue.ToRegisterBalance <> 0
	|				THEN -GoodsForIssue.ToShipBalance
	|		END) AS IncompleteWarehouseOperation}
	|";
	
	Return QueryText;
EndFunction

Function QueryTextReturnsOfMaterialsFromProduction()
	// String literals are localized in the report's SCD settings
	// Datasets - Fields - Available values.
	QueryText = "SELECT ALLOWED
	|	&RowTypeOfOperationReturnsOfMaterialsFromProduction AS OperationKind,
	|	CASE
	|		WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|			THEN &LineTypeOfDeviationProcessingOfFinancialDocuments
	|		ELSE &LineTypeOfDeviationRegistrationOfWarehouseDocuments
	|	END AS VarianceType,
	|	CASE
	|		WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|			THEN &LineRecommendationRegisterMaterialReturnFromProduction
	|		ELSE &LineRecommendationRegisterGoodsReceiptNotes
	|	END AS Recommendation,
	|	CASE
	|		WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|			THEN 0
	|		ELSE -GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance
	|	END AS IncompleteWarehouseOperation,
	|	CASE
	|		WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|			THEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance
	|		ELSE 0
	|	END AS UnfinishedFinancialTransaction,
	|	ISNULL(DetailsOfOrder.IBDocumentDate, DATETIME(1,1,1)) AS DateOfTransaction,
	|	GoodsReadyForReceipt.DocumentInflow AS ReferenceOrder,
	|	GoodsReadyForReceipt.Warehouse AS Warehouse,
	|	GoodsReadyForReceipt.Products AS Products,
	|	GoodsReadyForReceipt.Characteristic AS Characteristic,
	|	GoodsReadyForReceipt.Series AS Series,
	|	GoodsReadyForReceipt.Purpose AS Purpose
	|{SELECT
	|	Warehouse.*,
	|	Products.*,
	|	Characteristic.*,
	|	Series.*,
	|	Purpose.*}
	|FROM
	|	AccumulationRegister.GoodsToReceive.Balance(
	|		&PeriodLimit, 
	|		VALUETYPE(DocumentInflow) IN (
	|				TYPE(Document.MovementOfProductsAndMaterials)
	|				,TYPE(Document.ProductionStage2_2)
	|				) 
	|		AND &SelectionOfGoodsByRegister
	|		{(DocumentInflow).* AS ReferenceOrder, (Warehouse).*, (Products).*, (Characteristic).*, (Series).*, (Purpose).*}
	|	) AS GoodsReadyForReceipt
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS DetailsOfOrder
	|		ON GoodsReadyForReceipt.DocumentInflow = DetailsOfOrder.Ref
	|			AND NOT DetailsOfOrder.AdditionalRecord
	|WHERE
	|	(GoodsReadyForReceipt.DocumentInflow REFS Document.MovementOfProductsAndMaterials
	|	AND ISNULL(DetailsOfOrder.BusinessOperation, 
	|		VALUE(Enum.BusinessTransactions.ReturnFromProduction)) IN (
	|			VALUE(Enum.BusinessTransactions.ReturnFromProduction),
	|			VALUE(Enum.BusinessTransactions.ReturnOfMaterialsFromProduction),
	|			VALUE(Enum.BusinessTransactions.ReturnOfMaterialsFromStoreroom))
	|	OR NOT GoodsReadyForReceipt.DocumentInflow REFS Document.MovementOfProductsAndMaterials)
	|{WHERE
	|	(&RowTypeOfOperationReturnsOfMaterialsFromProduction) AS OperationKind,
	|	(CASE
	|			WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|				THEN &LineTypeOfDeviationProcessingOfFinancialDocuments
	|			ELSE &LineTypeOfDeviationRegistrationOfWarehouseDocuments
	|		END) AS VarianceType,
	|	(CASE
	|			WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|				THEN &LineRecommendationRegisterMaterialReturnFromProduction
	|			ELSE &LineRecommendationRegisterGoodsReceiptNotes
	|		END) AS Recommendation,
	|	(CASE
	|			WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|				THEN 0
	|			ELSE -GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance
	|		END) AS IncompleteWarehouseOperation,
	|	(CASE
	|			WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|				THEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance
	|			ELSE 0
	|		END) AS UnfinishedFinancialTransaction}";
	
	Return QueryText;
EndFunction

Function QueryTextReceivingOfProducts()
	// String literals are localized in the report's SCD settings
	// Datasets - Fields - Available values.
	QueryText = "SELECT ALLOWED
	|	&LineTypeOfOperationAcceptanceOfFinishedProducts AS OperationKind,
	|	CASE
	|		WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|			THEN &LineTypeOfDeviationProcessingOfFinancialDocuments
	|		ELSE &LineTypeOfDeviationRegistrationOfWarehouseDocuments
	|	END AS VarianceType,
	|	CASE
	|		WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|			THEN &LineRecommendationRegisterProductRelease
	|		ELSE &LineRecommendationRegisterGoodsReceiptNotes
	|	END AS Recommendation,
	|	CASE
	|		WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|			THEN 0
	|		ELSE -GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance
	|	END AS IncompleteWarehouseOperation,
	|	CASE
	|		WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|			THEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance
	|		ELSE 0
	|	END AS UnfinishedFinancialTransaction,
	|	ISNULL(DetailsOfOrder.IBDocumentDate, DATETIME(1,1,1)) AS DateOfTransaction,
	|	GoodsReadyForReceipt.DocumentInflow AS ReferenceOrder,
	|	GoodsReadyForReceipt.Warehouse AS Warehouse,
	|	GoodsReadyForReceipt.Products AS Products,
	|	GoodsReadyForReceipt.Characteristic AS Characteristic,
	|	GoodsReadyForReceipt.Series,
	|	GoodsReadyForReceipt.Purpose
	|{SELECT
	|	Warehouse.*,
	|	Products.*,
	|	Characteristic.*,
	|	Series.*,
	|	Purpose.*}
	|FROM
	|	AccumulationRegister.GoodsToReceive.Balance(
	|		&PeriodLimit, 
	|		VALUETYPE(DocumentInflow) IN (
	|			TYPE(Document.MovementOfProductsAndMaterials)
	|) 
	|		AND &SelectionOfGoodsByRegister
	|		{(DocumentInflow).* AS ReferenceOrder, (Warehouse).*, (Products).*, (Characteristic).*, (Series).*, (Purpose).*}
	|	) AS GoodsReadyForReceipt
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS DetailsOfOrder
	|		ON GoodsReadyForReceipt.DocumentInflow = DetailsOfOrder.Ref
	|			AND NOT DetailsOfOrder.AdditionalRecord
	|WHERE
	|	(GoodsReadyForReceipt.DocumentInflow REFS Document.MovementOfProductsAndMaterials
	|	AND ISNULL(DetailsOfOrder.BusinessOperation, 
	|		VALUE(Enum.BusinessTransactions.ProductsReleaseToWarehouse)) IN (
	|			VALUE(Enum.BusinessTransactions.ProductsReleaseToWarehouse),
	|			VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction),
	|			VALUE(Enum.BusinessTransactions.TransferOfProductsFromStoreroom))
	|	OR NOT GoodsReadyForReceipt.DocumentInflow REFS Document.MovementOfProductsAndMaterials)
	|{WHERE
	|	(&LineTypeOfOperationAcceptanceOfFinishedProducts) AS OperationKind,
	|	(CASE
	|			WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|				THEN &LineTypeOfDeviationProcessingOfFinancialDocuments
	|			ELSE &LineTypeOfDeviationRegistrationOfWarehouseDocuments
	|		END) AS VarianceType,
	|	(CASE
	|			WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|				THEN &LineRecommendationRegisterProductRelease
	|			ELSE &LineRecommendationRegisterGoodsReceiptNotes
	|		END) AS Recommendation,
	|	(CASE
	|			WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|				THEN 0
	|			ELSE -GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance
	|		END) AS IncompleteWarehouseOperation,
	|	(CASE
	|			WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|				THEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance
	|			ELSE 0
	|		END) AS UnfinishedFinancialTransaction}";
	
	Return QueryText;
EndFunction

Function QueryTextRawMaterialProcessingByToller()
	// String literals are localized in the report's SCD settings
	// Datasets - Fields - Available values.
	QueryText = "SELECT ALLOWED
	|	&LineTypeOfOperationProcessingOfRawMaterialsFromProcessor AS OperationKind,
	|	&LineTypeOfDeviationRegistrationOfWarehouseDocuments AS VarianceType,
	|	CASE
	|		WHEN GoodsForIssue.ToShipBalance - GoodsForIssue.ToRegisterBalance <> 0
	|			THEN &LineRecommendationCreateAGoodsIssueNote
	|	END AS Recommendation,
	|	CASE
	|		WHEN GoodsForIssue.ToShipBalance - GoodsForIssue.ToRegisterBalance <> 0
	|			THEN -GoodsForIssue.ToShipBalance
	|	END AS IncompleteWarehouseOperation,
	|	0 AS UnfinishedFinancialTransaction,
	|	ISNULL(DetailsOfOrder.IBDocumentDate, DATETIME(1,1,1)) AS DateOfTransaction,
	|	GoodsForIssue.DocumentShipments AS ReferenceOrder,
	|	GoodsForIssue.Warehouse AS Warehouse,
	|	GoodsForIssue.Products AS Products,
	|	GoodsForIssue.Characteristic AS Characteristic,
	|	GoodsForIssue.Series,
	|	GoodsForIssue.Purpose
	|{SELECT
	|	Warehouse.*,
	|	Products.*,
	|	Characteristic.*,
	|	Series.*,
	|	Purpose.*}
	|FROM
	|	AccumulationRegister.GoodsForIssue.Balance(
	|		&PeriodLimit,
	|		VALUETYPE(DocumentShipments) IN(
	|			TYPE(Document.SubcontractOrder2_5),
	|			TYPE(Document.TransferOfGoodsToBailee))
	|		AND &SelectionOfGoodsByRegister
	|	{(DocumentShipments).* AS ReferenceOrder, (Warehouse).*, (Products).*, (Characteristic).*, (Series).*, (Purpose).*}) AS GoodsForIssue
	|	
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS DetailsOfOrder
	|	ON GoodsForIssue.DocumentShipments = DetailsOfOrder.Ref
	|	AND NOT DetailsOfOrder.AdditionalRecord
	|	
	|WHERE
	|	CASE
	|		WHEN VALUETYPE(GoodsForIssue.DocumentShipments) = TYPE(Document.TransferOfGoodsToBailee)
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.TransferOfGoodsToBailee).BusinessOperation =
	|					VALUE(Enum.BusinessTransactions.TransferToToller2_5)
	|		ELSE TRUE
	|	END
	|	AND GoodsForIssue.ToShipBalance - GoodsForIssue.ToRegisterBalance <> 0
	|{WHERE
	|	(&LineTypeOfOperationProcessingOfRawMaterialsFromProcessor) AS OperationKind,
	|	(&LineTypeOfDeviationRegistrationOfWarehouseDocuments) AS VarianceType,
	|	(CASE
	|			WHEN GoodsForIssue.ToShipBalance - GoodsForIssue.ToRegisterBalance <> 0
	|				THEN &LineRecommendationCreateAGoodsIssueNote
	|		END) AS Recommendation,
	|	(CASE
	|			WHEN GoodsForIssue.ToShipBalance - GoodsForIssue.ToRegisterBalance <> 0
	|				THEN -GoodsForIssue.ToShipBalance
	|		END) AS IncompleteWarehouseOperation}";
	
	Return QueryText;
EndFunction

Function QueryTextReturnsOfRawMaterialsFromTollers()
	// String literals are localized in the report's SCD settings
	// Datasets - Fields - Available values.
	QueryText = "SELECT ALLOWED
	|	&OperationTypeRowReturnsOfRawMaterialsFromProcessors AS OperationKind,
	|	CASE
	|		WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|			THEN &LineTypeOfDeviationProcessingOfFinancialDocuments
	|		ELSE &LineTypeOfDeviationRegistrationOfWarehouseDocuments
	|	END AS VarianceType,
	|	CASE
	|		WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|			THEN &LineRecommendationRegisterRawMaterialReturnFromToller
	|		ELSE &LineRecommendationRegisterGoodsReceiptNotes
	|	END AS Recommendation,
	|	CASE
	|		WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|			THEN 0
	|		ELSE -GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance
	|	END AS IncompleteWarehouseOperation,
	|	CASE
	|		WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|			THEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance
	|		ELSE 0
	|	END AS UnfinishedFinancialTransaction,
	|	ISNULL(DetailsOfOrder.IBDocumentDate, DATETIME(1,1,1)) AS DateOfTransaction,
	|	GoodsReadyForReceipt.DocumentInflow AS ReferenceOrder,
	|	GoodsReadyForReceipt.Warehouse AS Warehouse,
	|	GoodsReadyForReceipt.Products AS Products,
	|	GoodsReadyForReceipt.Characteristic AS Characteristic,
	|	GoodsReadyForReceipt.Series AS Series,
	|	GoodsReadyForReceipt.Purpose AS Purpose
	|{SELECT
	|	Warehouse.*,
	|	Products.*,
	|	Characteristic.*,
	|	Series.*,
	|	Purpose.*}
	|FROM
	|	AccumulationRegister.GoodsToReceive.Balance(
	|		&PeriodLimit, 
	|		VALUETYPE(DocumentInflow) IN(
	|			TYPE(Document.ReceiptOfGoodsFromCustodian))
	|		AND &SelectionOfGoodsByRegister
	|		{(DocumentInflow).* AS ReferenceOrder, (Warehouse).*, (Products).*, (Characteristic).*, (Series).*, (Purpose).*}
	|	) AS GoodsReadyForReceipt
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS DetailsOfOrder
	|		ON GoodsReadyForReceipt.DocumentInflow = DetailsOfOrder.Ref
	|			AND NOT DetailsOfOrder.AdditionalRecord
	|WHERE
	|	CASE
	|		WHEN VALUETYPE(GoodsReadyForReceipt.DocumentInflow) = TYPE(Document.ReceiptOfGoodsFromCustodian)
	|			THEN CAST(GoodsReadyForReceipt.DocumentInflow AS Document.ReceiptOfGoodsFromCustodian).BusinessOperation = 
	|					VALUE(Enum.BusinessTransactions.ReturnFromProcessingCompany2_5)
	|		ELSE TRUE
	|	END
	|{WHERE
	|	(&OperationTypeRowReturnsOfRawMaterialsFromProcessors) AS OperationKind,
	|	(CASE
	|			WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|				THEN &LineTypeOfDeviationProcessingOfFinancialDocuments
	|			ELSE &LineTypeOfDeviationRegistrationOfWarehouseDocuments
	|		END) AS VarianceType,
	|	(CASE
	|			WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|				THEN &LineRecommendationRegisterRawMaterialReturnFromToller
	|			ELSE &LineRecommendationRegisterGoodsReceiptNotes
	|		END) AS Recommendation,
	|	(CASE
	|			WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|				THEN 0
	|			ELSE -GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance
	|		END) AS IncompleteWarehouseOperation,
	|	(CASE
	|			WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|				THEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance
	|			ELSE 0
	|		END) AS UnfinishedFinancialTransaction}";
	
	Return QueryText;
EndFunction

Function QueryTextProductReceiptFromTollers()
	// String literals are localized in the report's SCD settings
	// Datasets - Fields - Available values.
	QueryText = "SELECT ALLOWED
	|	&LineTypeOfTransactionReceiptOfProductsFromProcessors AS OperationKind,
	|	CASE
	|		WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|			THEN &LineTypeOfDeviationProcessingOfFinancialDocuments
	|		ELSE &LineTypeOfDeviationRegistrationOfWarehouseDocuments
	|	END AS VarianceType,
	|	CASE
	|		WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|			THEN &LineRecommendationRegisterReceiptFromToller
	|		ELSE &LineRecommendationRegisterGoodsReceiptNotes
	|	END AS Recommendation,
	|	CASE
	|		WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|			THEN 0
	|		ELSE -GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance
	|	END AS IncompleteWarehouseOperation,
	|	CASE
	|		WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|			THEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance
	|		ELSE 0
	|	END AS UnfinishedFinancialTransaction,
	|	ISNULL(DetailsOfOrder.IBDocumentDate, DATETIME(1,1,1)) AS DateOfTransaction,
	|	GoodsReadyForReceipt.DocumentInflow AS ReferenceOrder,
	|	GoodsReadyForReceipt.Warehouse AS Warehouse,
	|	GoodsReadyForReceipt.Products AS Products,
	|	GoodsReadyForReceipt.Characteristic AS Characteristic,
	|	GoodsReadyForReceipt.Series,
	|	GoodsReadyForReceipt.Purpose
	|{SELECT
	|	Warehouse.*,
	|	Products.*,
	|	Characteristic.*,
	|	Series.*,
	|	Purpose.*}
	|FROM
	|	AccumulationRegister.GoodsToReceive.Balance(
	|		&PeriodLimit, 
	|		VALUETYPE(DocumentInflow) IN(
	|			TYPE(Document.SubcontractOrder2_5))
	|		AND &SelectionOfGoodsByRegister
	|		{(DocumentInflow).* AS ReferenceOrder, (Warehouse).*, (Products).*, (Characteristic).*, (Series).*, (Purpose).*}
	|	) AS GoodsReadyForReceipt
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS DetailsOfOrder
	|		ON GoodsReadyForReceipt.DocumentInflow = DetailsOfOrder.Ref
	|			AND NOT DetailsOfOrder.AdditionalRecord
	|{WHERE
	|	(&LineTypeOfTransactionReceiptOfProductsFromProcessors) AS OperationKind,
	|	(CASE
	|			WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|				THEN &LineTypeOfDeviationProcessingOfFinancialDocuments
	|			ELSE &LineTypeOfDeviationRegistrationOfWarehouseDocuments
	|		END) AS VarianceType,
	|	(CASE
	|			WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|				THEN &LineRecommendationRegisterReceiptFromToller
	|			ELSE &LineRecommendationRegisterGoodsReceiptNotes
	|		END) AS Recommendation,
	|	(CASE
	|			WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|				THEN 0
	|			ELSE -GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance
	|		END) AS IncompleteWarehouseOperation,
	|	(CASE
	|			WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|				THEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance
	|			ELSE 0
	|		END) AS UnfinishedFinancialTransaction}";
	
	Return QueryText;
EndFunction

Function QueryTextMaterialProcessingOfMaterialProvider()
	// String literals are localized in the report's SCD settings
	// Datasets - Fields - Available values.
	QueryText = "SELECT ALLOWED
	|	&ThisTypeOfOperationProcessingRawMaterialsGiver AS OperationKind,
	|	CASE
	|		WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|			THEN &LineTypeOfDeviationProcessingOfFinancialDocuments
	|		ELSE &LineTypeOfDeviationRegistrationOfWarehouseDocuments
	|	END AS VarianceType,
	|	CASE
	|		WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|			THEN &LineRecommendationRegisterReceiptOfRawMaterialsFromMaterialProvider
	|		ELSE &LineRecommendationRegisterGoodsReceiptNotes
	|	END AS Recommendation,
	|	CASE
	|		WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|			THEN 0
	|		ELSE -GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance
	|	END AS IncompleteWarehouseOperation,
	|	CASE
	|		WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|			THEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance
	|		ELSE 0
	|	END AS UnfinishedFinancialTransaction,
	|	ISNULL(DetailsOfOrder.IBDocumentDate, DATETIME(1,1,1)) AS DateOfTransaction,
	|	GoodsReadyForReceipt.DocumentInflow AS ReferenceOrder,
	|	GoodsReadyForReceipt.Warehouse AS Warehouse,
	|	GoodsReadyForReceipt.Products AS Products,
	|	GoodsReadyForReceipt.Characteristic AS Characteristic,
	|	GoodsReadyForReceipt.Series,
	|	GoodsReadyForReceipt.Purpose
	|{SELECT
	|	Warehouse.*,
	|	Products.*,
	|	Characteristic.*,
	|	Series.*,
	|	Purpose.*}
	|FROM
	|	AccumulationRegister.GoodsToReceive.Balance(
	|		&PeriodLimit, 
	|		VALUETYPE(DocumentInflow) IN (
	|			TYPE(Document.MaterialProviderOrder2_5)) 
	|		AND &SelectionOfGoodsByRegister
	|		{(DocumentInflow).* AS ReferenceOrder, (Warehouse).*, (Products).*, (Characteristic).*, (Series).*, (Purpose).*}
	|	) AS GoodsReadyForReceipt
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS DetailsOfOrder
	|		ON GoodsReadyForReceipt.DocumentInflow = DetailsOfOrder.Ref
	|			AND NOT DetailsOfOrder.AdditionalRecord
	|{WHERE
	|	(&ThisTypeOfOperationProcessingRawMaterialsGiver) AS OperationKind,
	|	(CASE
	|			WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|				THEN &LineTypeOfDeviationProcessingOfFinancialDocuments
	|			ELSE &LineTypeOfDeviationRegistrationOfWarehouseDocuments
	|		END) AS VarianceType,
	|	(CASE
	|			WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|				THEN &LineRecommendationRegisterReceiptOfRawMaterialsFromMaterialProvider
	|			ELSE &LineRecommendationRegisterGoodsReceiptNotes
	|		END) AS Recommendation,
	|	(CASE
	|			WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|				THEN 0
	|			ELSE -GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance
	|		END) AS IncompleteWarehouseOperation,
	|	(CASE
	|			WHEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance > 0
	|				THEN GoodsReadyForReceipt.ToRegisterGoodsReceiptsBalance
	|			ELSE 0
	|		END) AS UnfinishedFinancialTransaction}";
	
	Return QueryText;
EndFunction


Function QueryTextProductTransfersToMaterialProviders()
	// String literals are localized in the report's SCD settings
	// Datasets - Fields - Available values.
	QueryText = "SELECT ALLOWED
	|	&ThisIsTypeOfOperationForTransferringProductsToGivers AS OperationKind,
	|	&LineTypeOfDeviationRegistrationOfWarehouseDocuments AS VarianceType,
	|	CASE
	|		WHEN GoodsForIssue.ToShipBalance - GoodsForIssue.ToRegisterBalance <> 0
	|			THEN &LineRecommendationCreateAGoodsIssueNote
	|	END AS Recommendation,
	|	CASE
	|		WHEN GoodsForIssue.ToShipBalance - GoodsForIssue.ToRegisterBalance <> 0
	|			THEN -GoodsForIssue.ToShipBalance
	|	END AS IncompleteWarehouseOperation,
	|	0 AS UnfinishedFinancialTransaction,
	|	ISNULL(DetailsOfOrder.IBDocumentDate, DATETIME(1,1,1)) AS DateOfTransaction,
	|	GoodsForIssue.DocumentShipments AS ReferenceOrder,
	|	GoodsForIssue.Warehouse AS Warehouse,
	|	GoodsForIssue.Products AS Products,
	|	GoodsForIssue.Characteristic AS Characteristic,
	|	GoodsForIssue.Series,
	|	GoodsForIssue.Purpose
	|{SELECT
	|	Warehouse.*,
	|	Products.*,
	|	Characteristic.*,
	|	Series.*,
	|	Purpose.*}
	|FROM
	|	AccumulationRegister.GoodsForIssue.Balance(
	|		&PeriodLimit, 
	|		VALUETYPE(DocumentShipments) IN (
	|			TYPE(Document.MaterialProviderOrder2_5))
	|		AND &SelectionOfGoodsByRegister
	|		{(DocumentShipments).* AS ReferenceOrder, (Warehouse).*, (Products).*, (Characteristic).*, (Series).*, (Purpose).*}
	|	) AS GoodsForIssue
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS DetailsOfOrder
	|		ON GoodsForIssue.DocumentShipments = DetailsOfOrder.Ref
	|			AND NOT DetailsOfOrder.AdditionalRecord
	|WHERE
	|	GoodsForIssue.ToShipBalance - GoodsForIssue.ToRegisterBalance <> 0
	|{WHERE
	|	(&ThisIsTypeOfOperationForTransferringProductsToGivers) AS OperationKind,
	|	(&LineTypeOfDeviationRegistrationOfWarehouseDocuments) AS VarianceType,
	|	(CASE
	|			WHEN GoodsForIssue.ToShipBalance - GoodsForIssue.ToRegisterBalance <> 0
	|				THEN &LineRecommendationCreateAGoodsIssueNote
	|		END) AS Recommendation,
	|	(CASE
	|			WHEN GoodsForIssue.ToShipBalance - GoodsForIssue.ToRegisterBalance <> 0
	|				THEN -GoodsForIssue.ToShipBalance
	|		END) AS IncompleteWarehouseOperation}";
	
	Return QueryText;
EndFunction

Function QueryTextControlOfInventoryTransferDocumentRegistration(ProductSelectionIsUsed_1)
	NumberOfConnectedRequests = 0;
	QueryText = "";
	
	Available2 = AvailableTypesOfOperationsAndQueries();
	QueryTexts = New Structure; 
	For Each Available In Available2 Do 
		QueryTexts.Insert(Available.NameOfRequestText, True);
	EndDo;
	
	// Check the rights to read documents
	RightToCustomerOrder						= AccessRight("Read", Metadata.Documents.SalesOrder);
	RightToSellGoodsAndServices			= AccessRight("Read", Metadata.Documents.CustomerInvoice);
	RightToReadRequestForReturnOfGoodsFromClient	= AccessRight("Read", Metadata.Documents.RequestForReturnOfGoodsFromCustomer);
	RightToReturnGoodsFromCustomer			= AccessRight("Read", Metadata.Documents.ReturnOfGoodsFromCustomer);
	
	RightToPlaceOrderWithSupplier					= AccessRight("Read", Metadata.Documents.PurchaseOrder);
	RightToPurchaseGoodsAndServices			= AccessRight("Read", Metadata.Documents.VendorInvoice);
	RightToEnterIntoAgreementsWithSuppliers			= AccessRight("Read", Metadata.Catalogs.TermsOfPurchaseFromVendors);
	RightToReturnGoodsToSupplier			= AccessRight("Read", Metadata.Documents.ReturnOfGoodsToVendor);
	
	RightToOrderForDomesticConsumption		= AccessRight("Read", Metadata.Documents.InventoryConsumptionOrder);
	RightReadingDomesticConsumption			= AccessRight("Read", Metadata.Documents.InventoryConsumption);
	
	RightToMoveOrder				= AccessRight("Read", Metadata.Documents.TransferOrder);
	RightToMovementOfGoods				= AccessRight("Read", Metadata.Documents.InventoryTransfer);
	
	RightToOrderAssembly					= AccessRight("Read", Metadata.Documents.ByAssemblyDisassemblyOrder);
	RightToAssembleGoods					= AccessRight("Read", Metadata.Documents.AssemblyFromComponents);
	
	RightToOtherRegistrationOfGoods		= AccessRight("Read", Metadata.Documents.OtherGoodsRecordingAsReceived);
	
	RightToShipGoodsFromStorage			= AccessRight("Read", Metadata.Documents.GoodsShipmentFromStorage);
	RightToAcceptanceOfGoodsForStorage			= AccessRight("Read", Metadata.Documents.GoodsReceiptForStorage);
	
	RightToTransferGoodsToCustodian			= AccessRight("Read", Metadata.Documents.TransferOfGoodsToBailee);
	RightToReceiveGoodsFromCustodian	= AccessRight("Read", Metadata.Documents.ReceiptOfGoodsFromCustodian);
	

	RightToOrderMaterialsForProduction		= AccessRight("Read", Metadata.Documents.OrderOfMaterialsForProduction);
	RightToMovementOfProductsAndMaterials		= AccessRight("Read", Metadata.Documents.MovementOfProductsAndMaterials);
	
	
	RightToTransferOrderToProcessor2_5			= AccessRight("Read", Metadata.Documents.SubcontractOrder2_5);
	
	RightToOrderGiver2_5					= AccessRight("Read", Metadata.Documents.MaterialProviderOrder2_5);
	
	// Let's check the register reading rights
	RightToPrepareGoodsForShipment					= AccessRight("Read", Metadata.AccumulationRegisters.GoodsForIssue);
	RightToPrepareGoodsForRegistrationOfReceipt		= AccessRight("Read", Metadata.AccumulationRegisters.GoodsToReceive);
	RightToPrepareGoodsForRegistrationOfSurplusShortages= AccessRight("Read", Metadata.AccumulationRegisters.GoodsForRegistrationOfSurplusesAndShortages);
	
	// Sales
	If RightToPrepareGoodsForShipment
		And RightToCustomerOrder
		And RightToSellGoodsAndServices 
		And RightToReadRequestForReturnOfGoodsFromClient
		And QueryTexts.Property("QueryTextSales") Then
		ConnectRequest(QueryText, QueryTextSales(), NumberOfConnectedRequests,
			QueryTextForTemporarySalesTables());
	EndIf;
	If RightToPrepareGoodsForRegistrationOfReceipt
		And RightToReadRequestForReturnOfGoodsFromClient
		And RightToReturnGoodsFromCustomer
		And QueryTexts.Property("QueryTextReturnsOfGoodsFromCustomers") Then
		ConnectRequest(QueryText, QueryTextReturnsOfGoodsFromCustomers(), NumberOfConnectedRequests);
	EndIf;
	
	// Purchases
	If RightToPrepareGoodsForRegistrationOfReceipt
		And RightToPlaceOrderWithSupplier
		And RightToPurchaseGoodsAndServices 
		And RightToEnterIntoAgreementsWithSuppliers
		And QueryTexts.Property("QueryTextPurchases") Then
		ConnectRequest(QueryText, QueryTextPurchases(), NumberOfConnectedRequests,
			RequestTextForTemporaryPurchaseTables());
	EndIf;
	If RightToPrepareGoodsForShipment
		And RightToReturnGoodsToSupplier
		And QueryTexts.Property("QueryTextReturnsOfGoodsToVendors") Then
		ConnectRequest(QueryText, QueryTextReturnsOfGoodsToVendors(), NumberOfConnectedRequests);
	EndIf;
	
	// Domestic consumption
	If RightToPrepareGoodsForShipment
		And RightToOrderForDomesticConsumption
		And RightReadingDomesticConsumption
		And QueryTexts.Property("QueryTextInventoryConsumption") Then
		ConnectRequest(QueryText, QueryTextInventoryConsumption(), NumberOfConnectedRequests);
	EndIf;
	
	// Goods transfer
	If RightToPrepareGoodsForShipment
		And RightToPrepareGoodsForRegistrationOfReceipt
		And RightToMoveOrder
		And RightToMovementOfGoods
		And QueryTexts.Property("QueryTextInventoryTransfer") Then
		ConnectRequest(QueryText, QueryTextInventoryTransfer(), NumberOfConnectedRequests);
	EndIf;
	
	// Assembly (disassembly)
	If RightToPrepareGoodsForShipment
		And RightToPrepareGoodsForRegistrationOfReceipt
		And RightToOrderAssembly
		And RightToAssembleGoods
		And QueryTexts.Property("QueryTextAssemblyDisassembly") Then
		ConnectRequest(QueryText, QueryTextAssemblyDisassembly(), NumberOfConnectedRequests);
	EndIf;
	
	// Other accounting
	If RightToPrepareGoodsForRegistrationOfReceipt
		And RightToOtherRegistrationOfGoods
		And QueryTexts.Property("RequestTextOtherAttributes") Then
		ConnectRequest(QueryText, RequestTextOtherAttributes(), NumberOfConnectedRequests);
	EndIf;
	
	// Registration of surpluses and shortages
	If RightToPrepareGoodsForRegistrationOfSurplusShortages
		And QueryTexts.Property("QueryTextRegistrationOfSurplusShortages") Then
		ConnectRequest(QueryText, QueryTextRegistrationOfSurplusShortages(), NumberOfConnectedRequests);
	EndIf;
	
	// Shipment of goods from storage
	If RightToPrepareGoodsForShipment
		And RightToShipGoodsFromStorage
		And QueryTexts.Property("QueryTextShipReceivedGoodsFromStorage") Then
		ConnectRequest(QueryText, QueryTextShipReceivedGoodsFromStorage(), NumberOfConnectedRequests);
	EndIf;
	
	// Acceptance of goods for storage
	If RightToPrepareGoodsForRegistrationOfReceipt
		And RightToPlaceOrderWithSupplier
		And RightToEnterIntoAgreementsWithSuppliers
		And RightToAcceptanceOfGoodsForStorage
		And QueryTexts.Property("QueryTextGoodsReceiptForStorage") Then
		ConnectRequest(QueryText, QueryTextGoodsReceiptForStorage(), NumberOfConnectedRequests,
			RequestTextForTemporaryTablesForAcceptanceOfGoodsForStorage());
	EndIf;
	
	// Transfer of goods to the custodian
	If RightToPrepareGoodsForShipment
		And RightToCustomerOrder
		And RightToTransferGoodsToCustodian
		And RightToReadRequestForReturnOfGoodsFromClient
		And QueryTexts.Property("QueryTextTransferOfGoodsToBailee") Then
		ConnectRequest(QueryText, QueryTextTransferOfGoodsToBailee(), NumberOfConnectedRequests,
			RequestTextForTemporaryTablesForTransferringGoodsToCustodian());
	EndIf;
	
	// Production
	If RightToPrepareGoodsForShipment
		And RightToMovementOfProductsAndMaterials
		And RightToOrderMaterialsForProduction
		And QueryTexts.Property("QueryTextMaterialTransferToProduction") Then
		ConnectRequest(QueryText, QueryTextMaterialTransferToProduction(), NumberOfConnectedRequests);
	EndIf;
	If RightToPrepareGoodsForRegistrationOfReceipt
		And RightToMovementOfProductsAndMaterials
		And QueryTexts.Property("QueryTextReturnsOfMaterialsFromProduction") Then
		ConnectRequest(QueryText, QueryTextReturnsOfMaterialsFromProduction(), NumberOfConnectedRequests);
	EndIf;
	If RightToPrepareGoodsForRegistrationOfReceipt
		And RightToMovementOfProductsAndMaterials
		And QueryTexts.Property("QueryTextReceivingOfProducts") Then
		ConnectRequest(QueryText, QueryTextReceivingOfProducts(), NumberOfConnectedRequests);
	EndIf;
	
	// Processing of raw materials at the processor
	
	If RightToPrepareGoodsForShipment
		And (RightToTransferOrderToProcessor2_5
				And RightToTransferGoodsToCustodian
			Or False)
		And QueryTexts.Property("QueryTextRawMaterialProcessingByToller") Then
		ConnectRequest(QueryText, QueryTextRawMaterialProcessingByToller(), NumberOfConnectedRequests);
	EndIf;
	If RightToPrepareGoodsForRegistrationOfReceipt
		And (RightToReceiveGoodsFromCustodian
			Or False)
		And QueryTexts.Property("QueryTextReturnsOfRawMaterialsFromTollers") Then
		ConnectRequest(QueryText, QueryTextReturnsOfRawMaterialsFromTollers(), NumberOfConnectedRequests);
	EndIf;
	If RightToPrepareGoodsForRegistrationOfReceipt
		And (RightToTransferOrderToProcessor2_5
				And RightToReceiveGoodsFromCustodian
			Or False)
		And QueryTexts.Property("QueryTextProductReceiptFromTollers") Then
		ConnectRequest(QueryText, QueryTextProductReceiptFromTollers(), NumberOfConnectedRequests);
	EndIf;
	// Processing of raw materials giver
	
	If RightToPrepareGoodsForRegistrationOfReceipt
		And (RightToOrderGiver2_5
			Or False)
		And QueryTexts.Property("QueryTextMaterialProcessingOfMaterialProvider") Then
		ConnectRequest(QueryText, QueryTextMaterialProcessingOfMaterialProvider(), NumberOfConnectedRequests);
	EndIf;
	If RightToPrepareGoodsForShipment
		And (RightToOrderGiver2_5
			Or False)
		And QueryTexts.Property("QueryTextProductTransfersToMaterialProviders") Then
		ConnectRequest(QueryText, QueryTextProductTransfersToMaterialProviders(), NumberOfConnectedRequests);
	EndIf;
	ReplaceProductSelectionParameters(QueryText, ProductSelectionIsUsed_1);
	
	Return QueryText;
EndFunction

Procedure ReplaceProductSelectionParameters(QueryText, ProductSelectionIsUsed_1)
	
	QueryTextSelectionOfGoodsByRegister = "TRUE";
	QueryTextSelectionOfGoodsByMovement = "TRUE";
	QueryTextSelectionOfGoodsForDisassembly = "TRUE";
	QueryTextSelectionOfGoodsByAssembly = "TRUE";

	If ProductSelectionIsUsed_1 Then
		QueryTextSelectionOfGoodsByRegister =
		"(Warehouse, Products, Characteristic, Purpose, Series) IN
		|					(SELECT
		|						TableFilters.Warehouse			AS Warehouse,
		|						TableFilters.Products		AS Products,
		|						TableFilters.Characteristic	AS Characteristic,
		|						TableFilters.Purpose		AS Purpose,
		|						TableFilters.Series			AS Series
		|					FROM
		|						TableFilters AS TableFilters)";
		QueryTextSelectionOfGoodsByMovement =
		"(InventoryTransfer.Ref.DestinationWarehouse, InventoryTransfer.Products, InventoryTransfer.Characteristic, InventoryTransfer.Purpose, InventoryTransfer.Series) IN
		|					(SELECT
		|						TableFilters.Warehouse			AS Warehouse,
		|						TableFilters.Products		AS Products,
		|						TableFilters.Characteristic	AS Characteristic,
		|						TableFilters.Purpose		AS Purpose,
		|						TableFilters.Series			AS Series
		|					FROM
		|						TableFilters AS TableFilters)";
		QueryTextSelectionOfGoodsForDisassembly =
		"(AssemblyDisassemblyOfGoods.Ref.Warehouse, AssemblyDisassemblyOfGoods.Products, AssemblyDisassemblyOfGoods.Characteristic, AssemblyDisassemblyOfGoods.Purpose, AssemblyDisassemblyOfGoods.Series) IN
		|					(SELECT
		|						TableFilters.Warehouse			AS Warehouse,
		|						TableFilters.Products		AS Products,
		|						TableFilters.Characteristic	AS Characteristic,
		|						TableFilters.Purpose		AS Purpose,
		|						TableFilters.Series			AS Series
		|					FROM
		|						TableFilters AS TableFilters)";
		QueryTextSelectionOfGoodsByAssembly =
		"(AssemblyDisassemblyOfGoods.Warehouse, AssemblyDisassemblyOfGoods.Products, AssemblyDisassemblyOfGoods.Characteristic, AssemblyDisassemblyOfGoods.Purpose, AssemblyDisassemblyOfGoods.Series) IN
		|					(SELECT
		|						TableFilters.Warehouse			AS Warehouse,
		|						TableFilters.Products		AS Products,
		|						TableFilters.Characteristic	AS Characteristic,
		|						TableFilters.Purpose		AS Purpose,
		|						TableFilters.Series			AS Series
		|					FROM
		|						TableFilters AS TableFilters)";
	EndIf;
	
	QueryText = StrReplace(QueryText, "&SelectionOfGoodsByRegister", QueryTextSelectionOfGoodsByRegister);
	QueryText = StrReplace(QueryText, "&SelectionOfGoodsByMovement", QueryTextSelectionOfGoodsByMovement);
	QueryText = StrReplace(QueryText, "&SelectionOfGoodsForDisassembly", QueryTextSelectionOfGoodsForDisassembly);
	QueryText = StrReplace(QueryText, "&SelectionOfGoodsByAssembly", QueryTextSelectionOfGoodsByAssembly);

EndProcedure

Procedure ConnectRequest(DynamicQueryText, ConnectingRequest, NumberOfConnectedRequests,
	TemporaryTableQueryText = Undefined)
	
	TemporaryTableQueryText = ?(ValueIsFilled(TemporaryTableQueryText),
		TemporaryTableQueryText + Common.QueryBatchSeparator(), "");
	
	If NumberOfConnectedRequests = 0 Then
		DynamicQueryText = DynamicQueryText + TemporaryTableQueryText + ConnectingRequest;
	Else
		DynamicQueryText = DynamicQueryText + Chars.LF + Chars.LF 
			+ "UNION ALL" + Chars.LF + Chars.LF;
			
		StringOfLayoutFields = "{SELECT
			|	Warehouse.*,
			|	Products.*,
			|	Characteristic.*,
			|	Series.*,
			|	Purpose.*}";
		
		EnablingRequestPreparation = StrReplace(ConnectingRequest, "ALLOWED", "");
		EnablingRequestPreparation = StrReplace(EnablingRequestPreparation, StringOfLayoutFields, "");
		
		DynamicQueryText = TemporaryTableQueryText + DynamicQueryText + EnablingRequestPreparation;
	EndIf;
	
	NumberOfConnectedRequests = NumberOfConnectedRequests + 1;
	
EndProcedure

Function RequestTextRegistrationOfSurplusesShortagesWithoutSelections(QueryText)
	QuerySchema = New QuerySchema;
	QuerySchema.SetQueryText(QueryText);
	OperatorIndex = Undefined;
	For Each TheOperatorOfTheRequestSchema In QuerySchema.QueryBatch[0].Operators Do
		If String(TheOperatorOfTheRequestSchema.SelectedFields[0]) = "&LineTypeOfOperationRegistrationOfSurplusesAndShortages" Then
			OperatorIndex = QuerySchema.QueryBatch[0].Operators.IndexOf(TheOperatorOfTheRequestSchema);
			Break;
		EndIf;
	EndDo;
	
	If OperatorIndex <> Undefined Then
		OperatorSelections = QuerySchema.QueryBatch[0].Operators[OperatorIndex].Filter; // QuerySchemaExpressions
		IndexesOfDeletedOperators = New Array;
		
		For Each OperatorSelection In OperatorSelections Do 
			SelectingStringOperator = String(OperatorSelection);
			If StrFind(SelectingStringOperator, "DATETIME(1, 1, 1)") > 0 
				Or StrFind(SelectingStringOperator, "NULL") > 0 Then
				IndexesOfDeletedOperators.Add(OperatorSelections.IndexOf(OperatorSelection));
			EndIf;
		EndDo;
		
		IndexAdjustment = 0;
		For Each IndexOfOperatorToDelete In IndexesOfDeletedOperators Do 
			OperatorSelections.Delete(IndexOfOperatorToDelete + IndexAdjustment);
			IndexAdjustment = IndexAdjustment - 1; 
		EndDo;
	EndIf;
	
	Return QuerySchema.GetQueryText();
EndFunction

Function AvailableTypesOfOperationsAndQueries()
	
	Available2 = New ValueTable;
	Available2.Columns.Add("OperationKind", Common.StringTypeDetails(200));
	Available2.Columns.Add("TypeOfOperationSynonym", Common.StringTypeDetails(200));
	Available2.Columns.Add("NameOfRequestText", Common.StringTypeDetails(200));
	
	TypesOfOperationsAndSynonyms = TypesOfOperationsAndSynonyms();
	
	// Are not disabled by a combination of functional options
	AddOperationTypeAndRequest(Available2, TypesOfOperationsAndSynonyms, "ShipmentToCustomers", "QueryTextSales");
	AddOperationTypeAndRequest(Available2, TypesOfOperationsAndSynonyms, "ReturnsOfGoodsFromCustomers", "QueryTextReturnsOfGoodsFromCustomers");
	AddOperationTypeAndRequest(Available2, TypesOfOperationsAndSynonyms, "ReceiptFromSuppliers", "QueryTextPurchases");
	AddOperationTypeAndRequest(Available2, TypesOfOperationsAndSynonyms, "ReturnsOfGoodsToVendors", "QueryTextReturnsOfGoodsToVendors");
	AddOperationTypeAndRequest(Available2, TypesOfOperationsAndSynonyms, "SurplusesAndShortagesRegistration", "QueryTextRegistrationOfSurplusShortages");
	
	// Disabled by a combination of functional options
	If GetFunctionalOption("UseInventoryConsumptionOrders")
		Or GetFunctionalOption("UseRMManagement") 
		Or GetFunctionalOption("UseInventoryConsumption") Then
		AddOperationTypeAndRequest(Available2, TypesOfOperationsAndSynonyms, "InventoryConsumption", "QueryTextInventoryConsumption");
	EndIf;
	If GetFunctionalOption("UseTransferOrders")
		Or GetFunctionalOption("UseGoodsTransfer") Then
		AddOperationTypeAndRequest(Available2, TypesOfOperationsAndSynonyms, "InventoryTransfer", "QueryTextInventoryTransfer");
	EndIf;
	If GetFunctionalOption("UseAssemblyDisassemblyOrders")
		Or GetFunctionalOption("UseAssemblyDisassembly") Then
		AddOperationTypeAndRequest(Available2, TypesOfOperationsAndSynonyms, "AssemblyDisassemblyOfGoods", "QueryTextAssemblyDisassembly");
	EndIf;
	If GetFunctionalOption("UseOtherGoodsRecordingAsReceived") Then
		AddOperationTypeAndRequest(Available2, TypesOfOperationsAndSynonyms, "OtherGoodsRecordingAsReceived", "RequestTextOtherAttributes");
	EndIf;
	If GetFunctionalOption("UseCustodyDuringPurchase") Then
		AddOperationTypeAndRequest(Available2, TypesOfOperationsAndSynonyms, "ShipReceivedGoodsFromStorage", "QueryTextShipReceivedGoodsFromStorage");
		AddOperationTypeAndRequest(Available2, TypesOfOperationsAndSynonyms, "GoodsReceiptForStorage", "QueryTextGoodsReceiptForStorage");
	EndIf;
	If GetFunctionalOption("UseTransferToCustodyWithRightOfSale") Then
		AddOperationTypeAndRequest(Available2, TypesOfOperationsAndSynonyms, "TransferOfGoodsToBailee", "QueryTextTransferOfGoodsToBailee");
	EndIf;
	If GetFunctionalOption("UseProduction") Then
		AddOperationTypeAndRequest(Available2, TypesOfOperationsAndSynonyms, "MaterialTransferToProduction", "QueryTextMaterialTransferToProduction");
		AddOperationTypeAndRequest(Available2, TypesOfOperationsAndSynonyms, "ReturnsOfMaterialsFromProduction", "QueryTextReturnsOfMaterialsFromProduction");
		AddOperationTypeAndRequest(Available2, TypesOfOperationsAndSynonyms, "ReceivingOfProducts", "QueryTextReceivingOfProducts");
	EndIf;
	If GetFunctionalOption("UseProductionByThirdParty2_5") Then
		AddOperationTypeAndRequest(Available2, TypesOfOperationsAndSynonyms, "RawMaterialProcessingByToller", "QueryTextRawMaterialProcessingByToller");
		AddOperationTypeAndRequest(Available2, TypesOfOperationsAndSynonyms, "ReturnsOfRawMaterialsFromTollers", "QueryTextReturnsOfRawMaterialsFromTollers");
		AddOperationTypeAndRequest(Available2, TypesOfOperationsAndSynonyms, "ProductReceiptFromTollers", "QueryTextProductReceiptFromTollers");
	EndIf;
	
	If GetFunctionalOption("UseTollManufacturing2_5") Then
		AddOperationTypeAndRequest(Available2, TypesOfOperationsAndSynonyms, "MaterialProcessingOfMaterialProvider", "QueryTextMaterialProcessingOfMaterialProvider");
		AddOperationTypeAndRequest(Available2, TypesOfOperationsAndSynonyms, "ProductTransfersToMaterialProviders", "QueryTextProductTransfersToMaterialProviders");
	EndIf;
	Return Available2;
	
EndFunction

Function AvailableValuesForOperationTypeField()
	
	AvailableTypesOfOperationsAndQueries = AvailableTypesOfOperationsAndQueries();
	AvailableValues = New ValueList;
	
	AvailableValues.LoadValues(AvailableTypesOfOperationsAndQueries.UnloadColumn("TypeOfOperationSynonym"));
	For Each AvailableValue In AvailableValues Do 
		AvailableValue.Presentation = AvailableValue.Value;
	EndDo;
	
	Return AvailableValues;
EndFunction

Procedure AddOperationTypeAndRequest(Table, TypesOfOperationsAndSynonyms, OperationKind, NameOfRequestText)
	
	NewRow = Table.Add();
	NewRow.OperationKind = OperationKind;
	NewRow.TypeOfOperationSynonym = TypesOfOperationsAndSynonyms[OperationKind];
	NewRow.NameOfRequestText = NameOfRequestText;
	
EndProcedure

Function TypesOfOperationsAndSynonyms()
	
	TypesOfOperationsAndSynonyms = New Map;
	
	TypesOfOperationsAndSynonyms.Insert("ShipmentToCustomers", NStr("vi = 'Xuất kho cho khách';
																	|ru = 'Отгрузка клиентам';
																	|en = 'Shipment to customers'; fa = 'ارسال به مشتریان';
																	|it = 'Spedizione ai clienti';
																	|pl = 'Wysyłka do klientów';
																	|tr = 'İstemciler için sevkiyat'"));
	TypesOfOperationsAndSynonyms.Insert("ReturnsOfGoodsFromCustomers", NStr("vi = 'Nhận hàng bán bị trả lại';
																			|ru = 'Возвраты товаров от клиентов';
																			|en = 'Sales returns'; fa = 'مرجوعی‌های فروش';
																			|it = 'Resi della merce dai clienti';
																			|pl = 'Zwroty towarów od klientów';
																			|tr = 'Müşteriden gelen ürün iadesi'"));
	TypesOfOperationsAndSynonyms.Insert("ReceiptFromSuppliers", NStr("vi = 'Nhập kho từ nhà cung cấp';
																	|ru = 'Приемка от поставщиков';
																	|en = 'Receipt from vendors'; fa = 'دریافت از فروشندگان';
																	|it = 'Accettazione dai fornitori';
																	|pl = 'Odbiór od dostawców';
																	|tr = 'Tedarikçilerden kabul'"));
	TypesOfOperationsAndSynonyms.Insert("ReturnsOfGoodsToVendors", NStr("vi = 'Trả lại hàng cho nhà cung cấp';
																		|ru = 'Возвраты товаров поставщикам';
																		|en = 'Returns of goods to vendors'; fa = 'برگشت کالا به تأمین‌کنندگان';
																		|it = 'Resi delle merci ai fornitori';
																		|pl = 'Zwroty towarów do dostawców';
																		|tr = 'Tedarikçilere ürün iadesi'"));
	TypesOfOperationsAndSynonyms.Insert("SurplusesAndShortagesRegistration", NStr("vi = 'Hãy lập bảng kê hàng thừa và hàng thiếu';
																					|ru = 'Оформление излишков и недостач';
																					|en = 'Surpluses and shortages registration'; fa = 'ثبت مازادها و کسری‌ها';
																					|it = 'Formalizzazione delle eccedenza e degli ammanchi';
																					|pl = 'Rejestrowanie nadwyżek i niedoborów';
																					|tr = 'Fazlalıklar ve eksikliklerin düzenlenmesi'"));
	TypesOfOperationsAndSynonyms.Insert("InventoryConsumption", NStr("vi = 'Tiêu dùng hàng hóa nội bộ';
																	|ru = 'Внутреннее потребление';
																	|en = 'Inventory consumption'; fa = 'مصرف موجودی';
																	|it = 'Consumo interno';
																	|pl = 'Konsumpcja wewnętrzna';
																	|tr = 'Stok tüketimi'"));
	TypesOfOperationsAndSynonyms.Insert("InventoryTransfer", NStr("vi = 'Điều chuyển hàng hóa nội bộ';
																	|ru = 'Перемещение товаров';
																	|en = 'Goods transfer'; fa = 'انتقال کالا';
																	|it = 'Trasferimento delle merci';
																	|pl = 'Przemieszczenie towarów';
																	|tr = 'Mal transferi'"));
	TypesOfOperationsAndSynonyms.Insert("AssemblyDisassemblyOfGoods", NStr("vi = 'Đóng bộ (tách bộ) hàng hóa';
																			|ru = 'Сборка (разборка) товаров';
																			|en = 'Product kitting'; fa = 'کیت‌سازی محصول';
																			|it = 'Assemblaggio (disassemblaggio) di merci';
																			|pl = 'Montaż (demontaż) towarów';
																			|tr = 'Ürünlerin montajı (demontajı)'"));
	TypesOfOperationsAndSynonyms.Insert("OtherGoodsRecordingAsReceived", NStr("vi = 'Ghi tăng khác';
																				|ru = 'Прочее оприходование товаров';
																				|en = 'Other receipt of goods'; fa = 'سایر دریافت‌های کالا';
																				|it = 'Altra registrazione in contabilità delle merci';
																				|pl = 'Inne rejestrowanie towarów';
																				|tr = 'Diğer ürünlerin envantere girişi'"));
	TypesOfOperationsAndSynonyms.Insert("MaterialTransferToProduction", NStr("vi = 'Chuyển giao nguyên vật liệu vào sản xuất';
																			|ru = 'Передача материалов в производство';
																			|en = 'Transfer of materials to production'; fa = 'انتقال مواد به تولید';
																			|it = 'Consegna materiali in produzione';
																			|pl = 'Przekazanie materiałów do produkcji';
																			|tr = 'Malzemelerin üretime aktarımı'"));
	TypesOfOperationsAndSynonyms.Insert("ReturnsOfMaterialsFromProduction", NStr("vi = 'Trả lại nguyên liệu từ sản xuất';
																				|ru = 'Возвраты материалов из производства';
																				|en = 'Returns of materials from production'; fa = 'مرجوعی مواد از تولید';
																				|it = 'Reso dei materiali dalla produzione';
																				|pl = 'Zwroty materiałów z produkcji';
																				|tr = 'Malzemelerin üretimden iadesi'"));
	TypesOfOperationsAndSynonyms.Insert("ReceivingOfProducts", NStr("vi = 'Nhập kho thành phẩm';
																	|ru = 'Приемка готовой продукции';
																	|en = 'Receiving of products'; fa = 'دریافت محصولات';
																	|it = 'Accettazione dei prodotti finiti';
																	|pl = 'Przyjmowanie produktu gotowego';
																	|tr = 'Hazır ürün kabulü'"));
	TypesOfOperationsAndSynonyms.Insert("RawMaterialProcessingByToller", NStr("vi = 'Gia công nguyên vật liệu của người nhận gia công';
																				|ru = 'Переработка сырья у переработчика';
																				|en = 'Raw material processing by subcontractor'; fa = 'فرآوری مواد اولیه توسط پیمانکار فرعی';
																				|it = 'Riciclaggio delle materie prime presso il subfornitore';
																				|pl = 'Przetwarzanie surowców u przetwórcy';
																				|tr = 'Fason üreticide hammadde işleme'"));
	TypesOfOperationsAndSynonyms.Insert("ReturnsOfRawMaterialsFromTollers", NStr("vi = 'Trả lại nguyên liệu từ gia công';
																				|ru = 'Возвраты сырья от переработчиков';
																				|en = 'Returns of raw materials from subcontractors'; fa = 'مرجوعی مواد اولیه از پیمانکاران فرعی';
																				|it = 'Reso delle materie prime dagli addetti alla lavorazione';
																				|pl = 'Zwrot surowców od przetwórców';
																				|tr = 'Fason üreticilerden hammaddelerin iadesi'"));
	TypesOfOperationsAndSynonyms.Insert("ProductReceiptFromTollers", NStr("vi = 'Biên nhận sản phẩm của gia công';
																			|ru = 'Поступления продукции от переработчиков';
																			|en = 'Product receipt from subcontractors'; fa = 'دریافت محصول از پیمانکاران فرعی';
																			|it = 'Arrivi dei prodotti dai riciclatori';
																			|pl = 'Wpływy produktów od przetwórców';
																			|tr = 'Fason üreticilerden ürünlerin alımı'"));
	TypesOfOperationsAndSynonyms.Insert("MaterialProcessingOfMaterialProvider", NStr("vi = 'Gia công nguyên vật liệu của người đặt gia công';
																					|ru = 'Переработка сырья давальца';
																					|en = 'Material processing of material provider'; fa = 'فرآوری مواد تأمین‌کننده مواد';
																					|it = 'Trasformazione delle materie prime del committente';
																					|pl = 'Przetwarzanie surowców właściciela surowców';
																					|tr = 'Müşteri hammaddelerin işlenmesi'"));
	TypesOfOperationsAndSynonyms.Insert("ReturnsToMaterialProviders", NStr("vi = 'Trả lại nguyên liệu cho khách hàng';
																			|ru = 'Возвраты сырья давальцам';
																			|en = 'Returns to material providers'; fa = 'مرجوعی به تأمین‌کنندگان مواد';
																			|it = 'Reso delle materie prime ai prestatori';
																			|pl = 'Zwrot surowca właścicielom surowców';
																			|tr = 'Hammaddelerin müşterilere iadesi'"));
	TypesOfOperationsAndSynonyms.Insert("ProductTransfersToMaterialProviders", NStr("vi = 'Bàn giao sản phẩm';
																					|ru = 'Передачи продукции давальцам';
																					|en = 'Product transfers to material providers'; fa = 'انتقال محصول به تأمین‌کنندگان مواد';
																					|it = 'Consegne dei prodotti ai prestatori';
																					|pl = 'Przekazywanie produkcji właścicielom surowców';
																					|tr = 'Ürünlerin müşterilere transferi'"));
	TypesOfOperationsAndSynonyms.Insert("ShipReceivedGoodsFromStorage", NStr("vi = 'Xuất kho hàng hóa nhận bảo quản';
																			|ru = 'Отгрузка принятых товаров с хранения';
																			|en = 'Ship received goods from storage'; fa = 'ارسال کالای دریافتی از انبار امانی';
																			|it = 'Spedizione delle merci depositate';
																			|pl = 'Wysyłka odebranych towarów z magazynu';
																			|tr = 'Kabul edilen ürünlerin ambardan sevkiyatı'"));
	TypesOfOperationsAndSynonyms.Insert("GoodsReceiptForStorage", NStr("vi = 'Nhập kho hàng hóa để lưu trữ';
																		|ru = 'Приемка товаров на хранение';
																		|en = 'VMI procurement'; fa = 'تدارکات VMI';
																		|it = 'Accettazione delle merci per il deposito';
																		|pl = 'Przyjęcie towarów do przechowania';
																		|tr = 'Malların depoya girişi'"));
	TypesOfOperationsAndSynonyms.Insert("TransferOfGoodsToBailee", NStr("vi = 'Chuyển hàng cho người trông coi';
																		|ru = 'Передача товаров хранителю';
																		|en = 'VMI fill-up'; fa = 'تکمیل موجودی VMI';
																		|it = 'Consegna di merci al depositario';
																		|pl = 'Przekazanie towaru do magazyniera';
																		|tr = 'Ürünlerin emanetçiye transferi'"));
	
	Return TypesOfOperationsAndSynonyms;
	
EndFunction

Function QueryTextForTemporarySalesTables()
	
	QueryText = "
	|SELECT ALLOWED
	|	DocumentSales.Ref AS Ref
	|INTO OrdersForShipmentBySales
	|FROM
	|	Document.SalesOrder AS DocumentSales
	|WHERE
	|	NOT DocumentSales.DeletionMark
	|	AND DocumentSales.BusinessOperation <> VALUE(Enum.BusinessTransactions.TransferToStorageWithRightOfSale)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentSales.Ref AS Ref
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer AS DocumentSales
	|WHERE
	|	NOT DocumentSales.DeletionMark
	|	AND DocumentSales.BusinessOperation <> VALUE(Enum.BusinessTransactions.ReturnFromCustodian)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentSales.Ref AS Ref
	|FROM
	|	Document.CustomerInvoice AS DocumentSales
	|WHERE
	|	NOT DocumentSales.DeletionMark
	|
	|INDEX BY
	|	Ref";
	
	Return QueryText;
	
EndFunction

Function RequestTextForTemporaryTablesForTransferringGoodsToCustodian()
	
	QueryText = "
	|SELECT ALLOWED
	|	DocumentSales.Ref AS Ref
	|INTO OrdersForShipmentByTransfers
	|FROM
	|	Document.SalesOrder AS DocumentSales
	|WHERE
	|	NOT DocumentSales.DeletionMark
	|	AND DocumentSales.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToStorageWithRightOfSale)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentSales.Ref AS Ref
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer AS DocumentSales
	|WHERE
	|	NOT DocumentSales.DeletionMark
	|	AND DocumentSales.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCustodian)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentSales.Ref AS Ref
	|FROM
	|	Document.TransferOfGoodsToBailee AS DocumentSales
	|WHERE
	|	NOT DocumentSales.DeletionMark
	|
	|INDEX BY
	|	Ref";
	
	Return QueryText;
	
EndFunction

Function QueryTextTransferOfGoodsToBailee()
	// String literals are localized in the report's SCD settings
	// Datasets - Fields - Available Values
	QueryText = "SELECT ALLOWED
	|	&StringTransactionTypeTransferOfGoodsToTheCustodian AS OperationKind,
	|	&LineTypeOfDeviationRegistrationOfWarehouseDocuments AS VarianceType,
	|	CASE
	|		WHEN GoodsForIssue.ToShipBalance - GoodsForIssue.ToRegisterBalance <> 0
	|			THEN &LineRecommendationCreateAGoodsIssueNote
	|	END AS Recommendation,
	|	CASE
	|		WHEN GoodsForIssue.ToShipBalance - GoodsForIssue.ToRegisterBalance <> 0
	|			THEN -GoodsForIssue.ToShipBalance
	|	END AS IncompleteWarehouseOperation,
	|	0 AS UnfinishedFinancialTransaction,
	|	ISNULL(DetailsOfOrder.IBDocumentDate, DATETIME(1,1,1)) AS DateOfTransaction,
	|	GoodsForIssue.DocumentShipments AS ReferenceOrder,
	|	GoodsForIssue.Warehouse AS Warehouse,
	|	GoodsForIssue.Products AS Products,
	|	GoodsForIssue.Characteristic AS Characteristic,
	|	GoodsForIssue.Series,
	|	GoodsForIssue.Purpose
	|{SELECT
	|	Warehouse.*,
	|	Products.*,
	|	Characteristic.*,
	|	Series.*,
	|	Purpose.*}
	|FROM
	|	AccumulationRegister.GoodsForIssue.Balance(
	|		&PeriodLimit, 
	|		DocumentShipments IN(
	|			SELECT
	|				ShipmentReferences.Ref
	|			FROM
	|				OrdersForShipmentByTransfers AS ShipmentReferences)
	|		AND &SelectionOfGoodsByRegister
	|		{(DocumentShipments).* AS ReferenceOrder, (Warehouse).*, (Products).*, (Characteristic).*, (Series).*, (Purpose).*}
	|	) AS GoodsForIssue
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS DetailsOfOrder
	|		ON GoodsForIssue.DocumentShipments = DetailsOfOrder.Ref
	|			AND NOT DetailsOfOrder.AdditionalRecord
	|WHERE
	|	GoodsForIssue.ToShipBalance - GoodsForIssue.ToRegisterBalance <> 0
	|{WHERE
	|	(&StringTransactionTypeTransferOfGoodsToTheCustodian) AS OperationKind,
	|	(&LineTypeOfDeviationRegistrationOfWarehouseDocuments) AS VarianceType,
	|	(CASE
	|			WHEN GoodsForIssue.ToShipBalance - GoodsForIssue.ToRegisterBalance <> 0
	|				THEN &LineRecommendationCreateAGoodsIssueNote
	|		END) AS Recommendation,
	|	(CASE
	|			WHEN GoodsForIssue.ToShipBalance - GoodsForIssue.ToRegisterBalance <> 0
	|				THEN -GoodsForIssue.ToShipBalance
	|		END) AS IncompleteWarehouseOperation}";
	
	Return QueryText;
	
EndFunction

Function ComposeResultIntoCollectionOfValues()
	
	TempTablesManager = New TempTablesManager;
	AddressOfSelectionTable = DataCompositionClientServer.GetParameter(SettingsComposer, "AddressOfSelectionTable").Value;
	InitializeTemporaryTableManagerWithSelectionData(TempTablesManager, AddressOfSelectionTable);
	ValueTableResult = New ValueTable;
	
	SetRequiredSettings(False);
	DataCompositionSchema.DataSets.ControlOfRegistrationOfDocuments.Query =
		QueryTextControlOfInventoryTransferDocumentRegistration(ValueIsFilled(AddressOfSelectionTable));
	
	// Generate a report
	ReportSettings = SettingsComposer.GetSettings();
	
	TemplateComposer = New DataCompositionTemplateComposer;
	
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema,
													ReportSettings,
													,
													,
													Type("DataCompositionValueCollectionTemplateGenerator"));
	
	// We will remove selections for empty fields from the request for surpluses / shortages
	OriginalTemplateRequest = CompositionTemplate.DataSets.ControlOfRegistrationOfDocuments.Query;
	
	CompositionTemplate.DataSets.ControlOfRegistrationOfDocuments.Query = 
		RequestTextRegistrationOfSurplusesShortagesWithoutSelections(OriginalTemplateRequest);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , , True, , TempTablesManager);
	
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	OutputProcessor.SetObject(ValueTableResult);
	OutputProcessor.Output(CompositionProcessor);
	
	Return ValueTableResult;

EndFunction

#EndRegion

#EndIf