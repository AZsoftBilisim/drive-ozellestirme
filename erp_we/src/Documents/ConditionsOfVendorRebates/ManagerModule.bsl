//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array of String - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("Rebates");
	DocumentMechanisms.Add("DocumentsRegistry");
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef.ConditionsOfVendorRebates, DocumentObject.ConditionsOfVendorRebates - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//	ValueList of String - a list of values containing query texts and their names.
//						Returned if the 'Get Request texts' property of the Dopparameters parameter
//						is set to True.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.ConditionsOfVendorRebates") Then
		
		DocumentObject = Document;
		DocumentRef = Document.Ref;
		
	Else
		
		DocumentObject = Document.GetObject();
		DocumentRef = Document;
		
	EndIf;
	
	Query = New Query;
	QueryTexts = New ValueList; // ValueList of String
	
	GetDocumentData(Query, DocumentRef);
	
	If Not AddlParameters.GetQueryTexts Then
		
		FillInInitializationParameters(Query, DocumentRef);
		
		QueryTextTableDocumentsRegistry(QueryTexts, Registers, DocumentObject);
		QueryTextTableConditions(QueryTexts, Registers, DocumentObject);
		QueryTextTableGoods(QueryTexts, Registers, DocumentObject);
		QueryTextTableProductProperties_(QueryTexts, Registers, DocumentObject);
		QueryTextTableTIN(QueryTexts, Registers, DocumentObject);
		QueryTextTableCounterparties(QueryTexts, Registers, DocumentObject);
		QueryTextTableGoodsSegments(QueryTexts, Registers, DocumentObject);
		QueryTextTableVendors(QueryTexts, Registers, DocumentObject);
		QueryTextTableWarehouses(QueryTexts, Registers, DocumentObject);
		QueryTextTableVendorRebates(QueryTexts, Registers, DocumentObject);
		QueryTextTableRebatesCalculationScales(QueryTexts, Registers, DocumentObject);
		
	EndIf;
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

#Region InterfaceImplementation

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	#Region CreatingAdjustment
	NewCommand = DocumentCorrection.AddCorrectionCommand(
		GenerationCommands, EmptyRef().Metadata());
	
	If NewCommand <> Undefined Then
		
		NewCommand.Presentation = NStr("vi = 'Điều chỉnh điều kiện thưởng lũy kế của nhà cung cấp';
										|ru = 'Корректировка условий ретро-бонусов поставщиков';
										|en = 'Correct conditions of vendor rebates'; fa = 'Correct conditions of vendor rebates';
										|it = 'Корректировка условий ретро-бонусов поставщиков';
										|pl = 'Correct conditions of vendor rebates';
										|tr = 'Tedarikçi retro bonusu şartlarının düzeltilmesi'");
		
		AttachableCommands.AddCommandVisibilityCondition(
			NewCommand,
			"WithoutCalculation",
			False);
		
		AttachableCommands.AddCommandVisibilityCondition(
			NewCommand,
			"Status",
			Enums.RebatesDocumentStatuses.Approved);
			
		AttachableCommands.AddCommandVisibilityCondition(
			NewCommand,
			"AccrueImmediately",
			False);
		
	EndIf;
	#EndRegion
	
	#Region CreatingAccrual
	NewCommand = Documents.AccrualOfVendorRebates.AddGenerateCommand(
		GenerationCommands, Parameters);
	If NewCommand <> Undefined Then
		
		AttachableCommands.AddCommandVisibilityCondition(
			NewCommand,
			"WithoutCalculation",
			True);
		
		AttachableCommands.AddCommandVisibilityCondition(
			NewCommand,
			"AccrueImmediately",
			False);
		
		AttachableCommands.AddCommandVisibilityCondition(
			NewCommand,
			"Status",
			Enums.RebatesDocumentStatuses.Approved);
		
	EndIf;
	#EndRegion
	
EndProcedure

// Prepares the print data.
// 
// Parameters:
//  DataSources - See PrintManagementOverridable.WhenPreparingPrintData.DataSources
//  ExternalDataSets - See PrintManagementOverridable.WhenPreparingPrintData.ExternalDataSets
//  LanguageCode - See PrintManagementOverridable.WhenPreparingPrintData.LanguageCode
//  AdditionalParameters - See PrintManagementOverridable.WhenPreparingPrintData.AdditionalParameters
//
Procedure WhenPreparingPrintData(DataSources, ExternalDataSets, LanguageCode, AdditionalParameters) Export
	
	
EndProcedure

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// Fills in the list of print commands.
// 
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	
EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	Reports.CompositionOfVendorRebates.AddReportCommand(
		ReportsCommands, Parameters, "CompositionOfRebatesSuppliersContext");
	
	Reports.CompositionOfVendorRebates.AddReportCommand(
		ReportsCommands, Parameters, "CompositionOfRebatesOfSuppliersAccordingToDocumentContext");
	
	Reports.VendorRebateStatement.AddReportCommand(
		ReportsCommands, Parameters, "StatementOnDeferredExpensedContextOfCondition");
	
	ReportCommand = Reports.CalculateVendorRebates.AddCommandToCalculateSuppliersRebates(ReportsCommands);
	If ReportCommand <> Undefined Then
		
		AttachableCommands.AddCommandVisibilityCondition(
			ReportCommand,
			"WithoutCalculation",
			False,
			DataCompositionComparisonType.Equal);
		
		AttachableCommands.AddCommandVisibilityCondition(
			ReportCommand,
			"Status",
			Enums.RebatesDocumentStatuses.Approved,
			DataCompositionComparisonType.Equal);
		
	EndIf;
	
EndProcedure

// Description of the logic of access rights restrictions
//
// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)";

EndProcedure

// Returns the names of attributes, which should not appear in the list of details of the processing Gruposeincentivos.
//
//	Returns:
//		Array of String - an array of the names of the details.
//
Function AttributesToSkipInBatchProcessing() Export
	
	NotAttributesToEdit = New Array; // Array of String
	
	NotAttributesToEdit.Add("*");
		
	Return NotAttributesToEdit;
	
EndFunction

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	
	Fields.Add("Ref");
	Fields.Add("Number");
	Fields.Add("Date");
	Fields.Add("Patch");
	
EndProcedure

// Parameters:
//  Data - Structure - Document data:
//  * Ref - DocumentRef.ConditionsOfCustomerRebates
//  * Number - String -
//  * Date - Date
//  * Patch - Boolean
//  Presentation - String - Presentation
//  StandardProcessing - Boolean - Standard treatment
//
Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	StandardProcessing = False;
	
	If Data.Ref <> Undefined Then
		
		Presentation = RebatesServerCall.DocumentTitle(
			Data.Ref,
			Data.Number,
			Data.Date,
			Data.Patch);
		
	EndIf;
	
EndProcedure

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	If ValueIsFilled(Parameters.SearchString)
	   And Parameters.Property("PickupByCounterparty") Then
		
		StandardProcessing = False;
		
		Query = New Query;
		
		FilterCriterion = "TRUE";
		SelectionLineTemplate = "AND Documents.%1 = &%1"; // @Query-part
		ArrayOfSelectionStrings = New Array; // Array of String
		ArrayOfSelectionStrings.Add(FilterCriterion);
		
		For Each SelectionKeyAndValue In Parameters.Filter Do
			
			Field = SelectionKeyAndValue.Key; // String
			Simple = SelectionKeyAndValue.Value;
			
			FilterText1 = StringFunctionsClientServer.SubstituteParametersToString(
				SelectionLineTemplate,
				Field);
			ArrayOfSelectionStrings.Add(FilterText1);
			Query.SetParameter(Field, Simple);
			
		EndDo;
		
		FilterCriterion = StrConcat(ArrayOfSelectionStrings, " ");
		
		QueryText =
		"SELECT
		|	Documents.Ref AS Ref,
		|	Documents.Number AS Number,
		|	Documents.Date AS Date,
		|	Documents.DeletionMark AS DeletionMark
		|FROM
		|	InformationRegister.VendorRebatesVendors AS VendorRebatesVendors
		|		INNER JOIN Document.ConditionsOfVendorRebates AS Documents
		|		ON VendorRebatesVendors.TermDocument = Documents.Ref
		|WHERE
		|	(VendorRebatesVendors.Counterparty = &Counterparty
		|			OR VendorRebatesVendors.Counterparty = VALUE(Catalog.Counterparties.EmptyRef))
		|	AND Documents.Number LIKE &SearchString
		|	AND &FilterCriterion
		|
		|ORDER BY
		|	Date,
		|	Number";
		
		SearchStringParameter = Common.GenerateSearchQueryString(Parameters.SearchString) + "%";
		Query.SetParameter("SearchString", SearchStringParameter);
		Query.SetParameter("Counterparty", Parameters.Counterparty);
		Query.Text = StrReplace(QueryText, "&FilterCriterion", FilterCriterion); // @Query-part
		
		ChoiceData = New ValueList;
		ValueTextTemplate = "%1 (%2)";
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			
			ValueText = StrTemplate(ValueTextTemplate, TrimAll(Selection.Number), Selection.Date);
			
			ListValue = New Structure;
			ListValue.Insert("Value", Selection.Ref);
			ListValue.Insert("DeletionMark", Selection.DeletionMark);
			
			ChoiceData.Add(ListValue, ValueText);
			
		EndDo;
		
	EndIf;
	
EndProcedure

#EndIf

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

#Region DataImport

// Compares the data loaded in the table part of the full table part
// With the data in the IB, and fills in the parameters of the addressable Comparison and the list of one-Values.
//
// Parameters:
//   AddressOfUploadedData    - String - the address of the temporary storage with the table of values in which
//                               the downloaded data from the file is located.
//                               The composition of the columns: Identifier - Number - sequence number of the line, the remaining columns correspond to the columns of the Template Upload file.
//   AddressOfMappingTable - String - the address of the temporary storage with an empty table of values,
//                               which is a copy of the table part of the document 
//                               that needs to be filled in from the addressable Data table.
//   ConflictsList - ValueTable - a list of ambiguous values for which there are several suitable options in the information security:
//       * Column       - String - name of the column where the ambiguity was detected
//       * Id - Number  - id of the row where an ambiguity was detected
//   FullTabularSectionName   - String - full name of the table part where data is loaded
//   AdditionalParameters   - Arbitrary - Any additional information
//
Procedure MapDataToImport(AddressOfUploadedData, AddressOfMappingTable, ConflictsList, FullTabularSectionName, AdditionalParameters) Export
	
	URBMetadata = Metadata.Documents.ConditionsOfVendorRebates;
	
	DataToImport = GetFromTempStorage(AddressOfUploadedData); // ValueTable
	TableToFillIn_ = GetFromTempStorage(AddressOfMappingTable); // ValueTable
	
	If FullTabularSectionName = URBMetadata.TabularSections.Goods.FullName() Then
		
		CompareDownloadedDataTSGoods(
			DataToImport, TableToFillIn_, AdditionalParameters, ConflictsList);
		
	ElsIf FullTabularSectionName = URBMetadata.TabularSections.GoodsSegments.FullName() Then
		
		CompareDownloadedDataTSGoodsSegments(
			DataToImport, TableToFillIn_, AdditionalParameters, ConflictsList);
		
	ElsIf FullTabularSectionName = URBMetadata.TabularSections.ClientsCounterpartiesTIN.FullName() Then
		
		For Each LineBeingLoaded In DataToImport Do
			
			TableRow = TableToFillIn_.Add();
			FillPropertyValues(TableRow, LineBeingLoaded);
			
		EndDo;
		
	ElsIf FullTabularSectionName = URBMetadata.TabularSections.CustomerCounterparties.FullName() Then
		
		CompareDownloadedDataTSCounterpartiesOfClients(
			DataToImport, TableToFillIn_, AdditionalParameters, ConflictsList);
		
	ElsIf FullTabularSectionName = URBMetadata.TabularSections.ProductProperties_.FullName() Then
		
		CompareUploadedTSDataWithItemProperties(
			DataToImport, TableToFillIn_, AdditionalParameters, ConflictsList);
		
	EndIf;
	
	PutToTempStorage(TableToFillIn_, AddressOfMappingTable);
	
EndProcedure

// Fills in the list of suitable information security objects for an ambiguous cell value.
// 
// Parameters:
//	FullTabularSectionName - String - full name of the table part where data is loaded.
//	ConflictsList - Array of Arbitrary - An array to fill in with ambiguous data.
//	ColumnName - String - Name of the column where the ambiguity occurred.
//	LoadedValuesString - ValueTableRow - Downloadable data, on the basis of which there was ambiguity.
//	AdditionalParameters - Structure -Arbitrary - Any additional information
//
Procedure FillInListOfAmbiguities(FullTabularSectionName, ConflictsList, ColumnName, LoadedValuesString, AdditionalParameters) Export
	
	URBMetadata = Metadata.Documents.ConditionsOfVendorRebates;
	
	If FullTabularSectionName = URBMetadata.TabularSections.Goods.FullName() Then
		
		If ColumnName = "Products" Then
			
			FillInListOfNomenclatureAmbiguities(ConflictsList, LoadedValuesString);
			
		EndIf;
		
		If ColumnName = "Characteristic" Then
			
			FillInListOfAmbiguitiesOfCharacteristic(ConflictsList, LoadedValuesString);
			
		EndIf;
		
	ElsIf FullTabularSectionName = URBMetadata.TabularSections.GoodsSegments.FullName() Then
		
		If ColumnName = "Segment" Then
			
			FillInListOfGoodsSegmentAmbiguities(ConflictsList, LoadedValuesString);
			
		EndIf;
			
	ElsIf FullTabularSectionName = URBMetadata.TabularSections.CustomerCounterparties.FullName() Then
		
		If ColumnName = "Counterparty" Then
			
			FillInListOfCounterpartiesAmbiguities(ConflictsList, LoadedValuesString);
			
		EndIf;
		
	ElsIf FullTabularSectionName = URBMetadata.TabularSections.ProductProperties_.FullName() Then
		
		If ColumnName = "PropertyValue" Then
			
			FillInListOfAmbiguitiesOfPropertyValue(
				ConflictsList,
				LoadedValuesString,
				AdditionalParameters);
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

// Parameters for clearing Attributes of participants' TS
// 
// Returns:
//  Structure - Parameters For Clearing Participants' Attributes:
//	* PartyList - EnumRef.RebatesParticipants -
//	* FilterParties - EnumRef.RebatesLists -
// 
Function ParametersForClearingParticipantsAttributes() Export
	
	NewParameters = New Structure;
	NewParameters.Insert("PartyList", Enums.RebatesParticipants.EmptyRef());
	NewParameters.Insert("FilterParties", Enums.RebatesLists.EmptyRef());
	
	Return NewParameters;
	
EndFunction

// Performs cleaning of unused Attributes of participants in the terms of retro bonuses
// 
// Parameters:
//  Object - DocumentObject.ConditionsOfVendorRebates -
//  	   - FormDataStructure: See Document.ConditionsOfVendorRebates.Form.DocumentForm.Object -
//  Parameters - See ParametersForClearingParticipantsAttributes
//
Procedure ClearUnusedDetailsOfParticipants(Object, Parameters) Export
	
	ClearUnusedAttributesOfCounterpartiesOfClients(Object, Parameters);
	ClearUnusedAttributesOfINNOfCounterpartiesOfClients(Object, Parameters);
	
EndProcedure

// Parameters for clearing the Attributes of TS products
// 
// Returns:
//  Structure - Parameters For Clearing Participants' Attributes:
//	* ContentOfGoods - EnumRef.RebatesItems -
//	* FilterOfProducts_ - EnumRef.RebatesLists -
//	* GoodsIndicator - EnumRef.TargetSalesIndicatorsOfRebatesByGoods -
//	* BaseOfCalculation - EnumRef.RebateCalculationBases -
//	* BonusType - EnumRef.VendorRebateTypes -
//	* AccrueImmediately - Boolean -
//
Function ParametersForClearingGoodsAttributes() Export
	
	NewParameters = New Structure;
	NewParameters.Insert("ContentOfGoods", Enums.RebatesItems.EmptyRef());
	NewParameters.Insert("FilterOfProducts_", Enums.RebatesLists.EmptyRef());
	NewParameters.Insert("GoodsIndicator", Enums.TargetSalesIndicatorsOfRebatesByGoods.EmptyRef());
	NewParameters.Insert("BaseOfCalculation", Enums.RebateCalculationBases.EmptyRef());
	NewParameters.Insert("BonusType", Enums.VendorRebateTypes.EmptyRef());
	NewParameters.Insert("AccrueImmediately", False);
	
	Return NewParameters;
	
EndFunction

// Performs cleaning of unused Attributes of goods and conditions of retro bonuses
// 
// Parameters:
//  Object - DocumentObject.ConditionsOfVendorRebates-
//  	   - FormDataStructure: See Document.ConditionsOfVendorRebates.Form.DocumentForm.Object -
//  Parameters - See ParametersForClearingGoodsAttributes
//
Procedure ClearUnusedGoodsDetails(Object, Parameters) Export
	
	If Parameters.ContentOfGoods = Enums.RebatesItems.Products Then
		
		Object.ProductProperties_.Clear();
		Object.GoodsSegments.Clear();
		
	ElsIf Parameters.ContentOfGoods = Enums.RebatesItems.ProductSegments Then
		
		Object.ProductProperties_.Clear();
		Object.Goods.Clear();
	
	ElsIf Parameters.ContentOfGoods = Enums.RebatesItems.ProductItemProperty Then
		
		Object.Goods.Clear();
		Object.GoodsSegments.Clear();
		
	Else
		
		Object.Goods.Clear();
		Object.ProductProperties_.Clear();
		Object.GoodsSegments.Clear();
		
	EndIf;
	
	If Parameters.FilterOfProducts_ = Enums.RebatesLists.All Then
		
		Object.Goods.Clear();
		Object.GoodsSegments.Clear();
		
	Else
		
		ClearUnusedItemTableAttributes(Object, Parameters, Object.Goods);
		ClearUnusedItemTableAttributes(Object, Parameters, Object.ProductProperties_);
		
		If Not Object.Patch Then
			
			For Each TSRow In Object.GoodsSegments Do
				
				TSRow.Canceled = False;
				TSRow.InitialString = False;
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Parameters for clearing Attributes of TS warehouses
// 
// Returns:
//  Structure - Parameters For Clearing Warehouse Attributes:
//	* SelectionOfWarehouses_ - EnumRef.RebatesLists -
//
Function ParametersForClearingWarehouseAttributes() Export
	
	NewParameters = New Structure;
	NewParameters.Insert("SelectionOfWarehouses_", Enums.RebatesLists.EmptyRef());
	
	Return NewParameters;
	
EndFunction

// Performs cleaning of unused Attributes of warehouses conditions of retro bonuses of suppliers
// 
// Parameters:
//  Object - DocumentObject.ConditionsOfVendorRebates -
//  	   - FormDataStructure: See Document.ConditionsOfVendorRebates.Form.DocumentForm.Object -
//  Parameters - See ParametersForClearingWarehouseAttributes
//
Procedure ClearUnusedAttributesOfWarehouses(Object, Parameters) Export
	
	If Parameters.SelectionOfWarehouses_ = Enums.RebatesLists.All Then
		Object.Warehouses.Clear();
	EndIf;
	
EndProcedure

// Gets up-to-date data on the specified condition (the document must be completed)
//
// Parameters:
//  TermDocument - DocumentRef.ConditionsOfVendorRebates - Terms Document
// 
// Returns:
//  QueryResultSelection:
//	* WithoutCalculation - Boolean -
//	* ValidOnDate - Date -
//	* ValidTo - Date -
//	* Organization - CatalogRef.Companies -
//	* Counterparty - CatalogRef.Counterparties -
//	* Partner - CatalogRef.Partners -
//	* Contract - CatalogRef.CounterpartyContracts -
//	* Currency - CatalogRef.Currencies -
//	* AmountBonus - Number -
//	* AccrualFrequency - EnumRef.RebatesFrequencies -
//	* ConditionFrequency - EnumRef.RebatesFrequencies -
//	* ConditionFrequencyPresentation - String -
//	* RecordingIsCompleted - Boolean -
//	* ContentOfGoods - EnumRef.RebatesItems -
//	* PartyList - EnumRef.RebatesParticipants -
//	* Attendees - EnumRef.RebatesLists -
//	* Goods - EnumRef.RebatesLists -
//	* ProductItemProperty - String -
//	* Warehouses - EnumRef.RebatesLists -
//	* RestrictAccrualOverPlan - Boolean -
//	* DateOfRemainingGoods - Date -
//	* GoodsIndicator - EnumRef.TargetSalesIndicatorsOfRebatesByGoods -
//	* GoodsIndicatorPresentation - String -
//	* PartyCountDetails - EnumRef.ARAPAccountingDrilldownsOfRebatesParticipants -
//	* BaseOfCalculation - EnumRef.RebateCalculationBases -
//	* BonusType - EnumRef.VendorRebateTypes -
//	* ConsiderVAT - Boolean -
//	* AllocationProcedure - EnumRef.RebatesAllocationProcedures -
//	* DocumentTermsOfRetroBonusesPresentation - String -
// 
Function UpToDateData(TermDocument) Export
	
	Query = New Query;
	QueryText =
	"SELECT
	|	Data.TermDocument.WithoutCalculation AS WithoutCalculation,
	|	Data.ValidOnDate AS ValidOnDate,
	|	Data.ValidTo AS ValidTo,
	|	Data.Organization AS Organization,
	|	Data.Counterparty AS Counterparty,
	|	Data.Partner AS Partner,
	|	Data.Contract AS Contract,
	|	Data.Currency AS Currency,
	|	Data.AmountBonus AS AmountBonus,
	|	Data.AccrualFrequency AS AccrualFrequency,
	|	Data.ConditionFrequency AS ConditionFrequency,
	|	REFPRESENTATION(Data.ConditionFrequency) AS ConditionFrequencyPresentation,
	|	Data.RecordingIsCompleted AS RecordingIsCompleted,
	|	Data.ContentOfGoods AS ContentOfGoods,
	|	Data.PartyList AS PartyList,
	|	Data.Attendees AS Attendees,
	|	Data.Goods AS Goods,
	|	Data.Kind.ProductItemProperty AS ProductItemProperty,
	|	Data.Warehouses AS Warehouses,
	|	Data.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
	|	Data.CalculationScaleType AS CalculationScaleType,
	|	Data.DateOfRemainingGoods AS DateOfRemainingGoods,
	|	Data.Kind.GoodsIndicator AS GoodsIndicator,
	|	REFPRESENTATION(Data.Kind.GoodsIndicator) AS GoodsIndicatorPresentation,
	|	CASE
	|		WHEN Data.Kind.FulfilConditionsByCustomers
	|			THEN VALUE(Enum.ARAPAccountingDrilldownsOfRebatesParticipants.ByCounterparty)
	|		ELSE VALUE(Enum.ARAPAccountingDrilldownsOfRebatesParticipants.EmptyRef)
	|	END AS PartyCountDetails,
	|	Data.Kind.BaseOfCalculation AS BaseOfCalculation,
	|	Data.BonusType AS BonusType,
	|	Data.Kind.ConsiderVAT AS ConsiderVAT,
	|	Data.Kind.AllocationProcedure AS AllocationProcedure,
	|	REFPRESENTATION(Data.TermDocument) AS DocumentTermsOfRetroBonusesPresentation
	|FROM
	|	InformationRegister.VendorRebatesConditions AS Data
	|WHERE
	|	Data.TermDocument = &TermDocument";
	Query.Text = QueryText;
	Query.SetParameter("TermDocument", TermDocument);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	Return Selection;
	
EndFunction

// Returns supplier data for the specified condition, if they are the only ones (the document must be completed)
// 
// Parameters:
//  TermDocument - DocumentRef.ConditionsOfVendorRebates - Terms Document
// 
// Returns:
//  Structure:
// * Counterparty - CatalogRef.Counterparties -
// * Partner - CatalogRef.Partners -
// * Contract - CatalogRef.CounterpartyContracts -
// * Terms - CatalogRef.TermsOfPurchaseFromVendors -
//
Function CurrentSupplierData(TermDocument) Export
	
	Result = New Structure;
	Result.Insert("Counterparty", Catalogs.Counterparties.EmptyRef());
	Result.Insert("Partner", Catalogs.Partners.EmptyRef());
	Result.Insert("Contract", Catalogs.CounterpartyContracts.EmptyRef());
	Result.Insert("Terms", Catalogs.TermsOfPurchaseFromVendors.EmptyRef());
	
	QueryText =
	"SELECT
	|	COUNT(DISTINCT SupplierData.Counterparty) AS CounterpartyQuantity,
	|	MAX(SupplierData.Counterparty) AS Counterparty,
	|	COUNT(DISTINCT SupplierData.Partner) AS PartnerQuantity,
	|	MAX(SupplierData.Partner) AS Partner,
	|	COUNT(DISTINCT SupplierData.Contract) AS ContractQuantity,
	|	MAX(SupplierData.Contract) AS Contract,
	|	COUNT(DISTINCT SupplierData.Terms) AS AgreementQuantity,
	|	MAX(SupplierData.Terms) AS Terms
	|FROM
	|	InformationRegister.VendorRebatesVendors AS SupplierData
	|WHERE
	|	SupplierData.TermDocument = &TermDocument";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("TermDocument", TermDocument);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	If Selection.CounterpartyQuantity = 1 Then
		Result.Counterparty = Selection.Counterparty;
	EndIf;
	
	If Selection.PartnerQuantity = 1 Then
		Result.Partner = Selection.Partner;
	EndIf;
	
	If Selection.ContractQuantity = 1 Then
		Result.Contract = Selection.Contract;
	EndIf;
	
	If Selection.AgreementQuantity = 1 Then
		Result.Terms = Selection.Terms;
	EndIf;
	
	Return Result;
	
EndFunction

// Determines whether the current user has the right to directly agree on the terms and conditions of retro customer bonuses
// 
// Returns:
//  Boolean
//
Function ThereIsRightOfApproval() Export
	
	Result = Users.RolesAvailable(Metadata.Roles.RightToApproveConditionsOfVendorRebates.Name);
	
	Return Result;
	
EndFunction

// Allowed Status of the document to be installed for the current user
// 
// Returns:
//  Array of EnumRef.RebatesDocumentStatuses
//
Function AllowedInstallationStatus() Export
	
	AllowedStatuses = New Array; // Array of EnumRef.RebatesDocumentStatuses
	
	ThereIsAgreementThrough1CWorkflow = False;
	// IntegrationWith1CDocumentManagementSubsystem
	ThereIsAgreementThrough1CWorkflow = Constants.UseApprovalThrough1CDocumentManagement.Get();
	// End IntegrationWith1CDocumentManagementSubsystem
	
	If ThereIsAgreementThrough1CWorkflow Then
		
		AllowedStatuses.Add(Enums.RebatesDocumentStatuses.Draft);
		AllowedStatuses.Add(Enums.RebatesDocumentStatuses.NotApproved);
		
	Else
		
		AllowedStatuses.Add(Enums.RebatesDocumentStatuses.Draft);
		AllowedStatuses.Add(Enums.RebatesDocumentStatuses.AwaitingApproval);
		
		If ThereIsRightOfApproval() Then
		
			AllowedStatuses.Add(Enums.RebatesDocumentStatuses.Approved);
		
		EndIf;
		
		AllowedStatuses.Add(Enums.RebatesDocumentStatuses.NotApproved);
		
	EndIf;
	
	Return AllowedStatuses;
	
EndFunction

// Allowed document Status with the ability to change the document for the current user
// 
// Returns:
//  Array of EnumRef.RebatesDocumentStatuses
//
Function AllowedStatusesToBeChanged() Export
	
	AllowedStatuses = New Array; // Array of EnumRef.RebatesDocumentStatuses
	
	ThereIsAgreementThrough1CWorkflow = False;
	// IntegrationWith1CDocumentManagementSubsystem
	ThereIsAgreementThrough1CWorkflow = Constants.UseApprovalThrough1CDocumentManagement.Get();
	// End IntegrationWith1CDocumentManagementSubsystem
	
	If ThereIsAgreementThrough1CWorkflow Then
		
		AllowedStatuses.Add(Enums.RebatesDocumentStatuses.Draft);
		AllowedStatuses.Add(Enums.RebatesDocumentStatuses.NotApproved);
		
	Else
		
		AllowedStatuses.Add(Enums.RebatesDocumentStatuses.Draft);
		AllowedStatuses.Add(Enums.RebatesDocumentStatuses.AwaitingApproval);
		AllowedStatuses.Add(Enums.RebatesDocumentStatuses.NotApproved);
		
	EndIf;
	
	Return AllowedStatuses;
	
EndFunction

// Determines whether the document can be modified based on the transmitted Status
// 
// Parameters:
//  DocumentStatus - EnumRef.RebatesDocumentStatuses
// 
// Returns:
//  Boolean
//
Function ChangeByStatusIsAllowed(Val DocumentStatus) Export
	
	Result = True;
	
	If Not DocumentStatus.IsEmpty() Then
		
		AllowedStatuses = AllowedStatusesToBeChanged();
		Result = (AllowedStatuses.Find(DocumentStatus) <> Undefined);
		
	EndIf;
	
	Return Result;
	
EndFunction

// Defines the properties of form fields depending on the data
//
// Parameters:
//	Settings - ValueTable - table with columns:
//		* Fields - Array of String - fields for which display settings are defined
//		* Condition - DataCompositionFilter - terms of use settings
//		* Properties - Structure - property names and values
//
Procedure FillInFormFieldSettings(Settings) Export
	
	ConfigurationModule = FinancialReportingServer;
	ListCompositions = Enums.RebatesLists;
	
	#Region FieldsOfCorrectionHeader
	Item = Settings.Add();
	
	Item.Fields.Add("Organization");
	Item.Fields.Add("RebateKind");
	Item.Fields.Add("ValidOnDate");
	Item.Fields.Add("CalculationScaleType");
	
	ConfigurationModule.NewFilter(Item.Condition, "Patch", True);
	
	Item.Properties.Insert("ReadOnly", True);
	#EndRegion
	
	#Region SettingBasedOnAccruals
	// Elements of Participants
	Item = Settings.Add();
	
	Item.Fields.Add("CustomerCounterparties");
	Item.Fields.Add("CustomerCounterparties.Counterparty");
	Item.Fields.Add("ClientsCounterpartiesTIN");
	Item.Fields.Add("ClientsCounterpartiesTIN.TIN");
	
	ConfigurationModule.NewFilter(Item.Condition, "FilterParties", ListCompositions.ExceptForSelectedOnes);
	ConfigurationModule.NewFilter(Item.Condition, "More.ThereAreAccruals", True);
	
	Item.Properties.Insert("ReadOnly", True);
	
	// Commands of participants
	Item = Settings.Add();
	
	Item.Fields.Add("CustomerCounterpartiesDownloadClientsCounterpartiesFromFile");
	Item.Fields.Add("ClientsCounterpartiesTINDownloadTINFromFile");
	
	ConfigurationModule.NewFilter(Item.Condition, "FilterParties", ListCompositions.ExceptForSelectedOnes);
	ConfigurationModule.NewFilter(Item.Condition, "More.ThereAreAccruals", True);
	
	Item.Properties.Insert("Enabled", False);
	#EndRegion
	
	SettingUpTableOfParticipants(Settings, ConfigurationModule);
	SettingUpTableOfINNOfCounterpartiesOfClients(Settings, ConfigurationModule);
	SettingUpGoodsTable(Settings, ConfigurationModule);
	SettingUpGoodsSegmentsTable(Settings, ConfigurationModule);
	SettingUpItemPropertiesTable(Settings, ConfigurationModule);
	SettingUpWarehousesTable(Settings, ConfigurationModule);
	SettingUpVendorsTable(Settings, ConfigurationModule);
	SettingUpCalculationScaleTable(Settings, ConfigurationModule);
	
	SettingUpCalculationScaleGroupField(Settings, ConfigurationModule);
	SettingUpAddImmediatelyField(Settings, ConfigurationModule);
	SettingUpFieldProhibitingAccrualsOverPlan(Settings, ConfigurationModule);
	SettingUpCurrencyField(Settings, ConfigurationModule);
	SettingUpBonusPercentageField(Settings, ConfigurationModule);
	SettingUpFieldSelectionOfParticipants(Settings, ConfigurationModule);
	SettingUpSelectionOfGoodsField(Settings, ConfigurationModule);
	SettingUpWarehouseSelectionField(Settings, ConfigurationModule);
	SettingUpConditionTimeFenceField(Settings, ConfigurationModule);
	SettingUpAccrualTimeFenceField(Settings, ConfigurationModule);
	SettingUpAmountPlanField(Settings, ConfigurationModule);
	SettingUpBonusAmountField(Settings, ConfigurationModule);
	SettingUpBalanceDateField(Settings, ConfigurationModule);
	SettingUpPeriodFields(Settings, ConfigurationModule);
	SettingUpModeMultipleVendorsField(Settings, ConfigurationModule);
	SettingUpAgreementField(Settings, ConfigurationModule);
	SettingUpContractField(Settings, ConfigurationModule);
	SettingUpCounterpartyField(Settings, ConfigurationModule);
	SettingUpPartnerField(Settings, ConfigurationModule);
	SettingUpSegmentFixingCommands(Settings, ConfigurationModule);
	ConfiguringProviderData(Settings, ConfigurationModule);
	RebatesServer.SettingUpItemPropertyFieldPresentation(Settings);
	
EndProcedure

// Returns the adapted Query Text of Registered Records by case
// 
// Parameters:
//  RegisterName - String - Name of the register for receiving the adapted request 
// 
// Returns:
//  See InfobaseUpdateTM.ResultOfRequestAdaptation
// 
Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.ConditionsOfVendorRebates";
	SynonymForDocumentTable = "";
	RequestHasSource = True;
	
	ParameterValues = ValuesOfHoldingParameters();
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting", """""");
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	Else
		
		ExceptionPattern = NStr("vi = 'Trong chứng từ %1 đã không thực hiện việc điều chỉnh văn bản của yêu cầu Lập các chuyển động trong thanh ghi %2.';
								|ru = 'В документе %1 не реализована адаптация текста запроса формирования движений по регистру %2.';
								|en = 'In the %1 document, adaptation of the request for generating records of the %2 register is not implemented.'; fa = 'In the %1 document, adaptation of the request for generating records of the %2 register is not implemented.';
								|it = 'В документе %1 не реализована адаптация текста запроса формирования движений по регистру %2.';
								|pl = 'W dokumencie %1 nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %2.';
								|tr = '%1 belgesinde, %2 kaydına göre hareketlerin düzenlenmesi talebinin metin uyarlaması uygulanmadı.'");
		ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
			ExceptionPattern,
			FullDocumentName,
			RegisterName);
		
		Raise ExceptionText;
		
	EndIf;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
			QueryText,
			FullDocumentName,
			SynonymForDocumentTable,
			RequestHasSource,
			RedefiningParameterCalculation);
		
	Else
		
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
			QueryText,
			FullDocumentName,
			SynonymForDocumentTable,
			RedefiningParameterCalculation);
		
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

// Template for the document title, taking into account the correction attribute
// 
// Parameters:
//  Patch - Boolean - indicates that the document has been corrected
// 
// Returns:
//  String
//
Function DocumentHeaderTemplate(Patch) Export
	
	If GetFunctionalOption("DisplayFullNamesOfVendorRebates") Then
		
		If Patch Then
			DocumentHeaderTemplate = NStr("vi = 'Điều chỉnh điều kiện thưởng lũy kế của nhà cung cấp %1';
											|ru = 'Корректировка условий ретро-бонусов поставщика %1';
											|en = 'Correct conditions of %1 vendor rebates'; fa = 'Correct conditions of %1 vendor rebates';
											|it = 'Корректировка условий ретро-бонусов поставщика %1';
											|pl = 'Correct conditions of %1 vendor rebates';
											|tr = '%1 tedarikçi retro bonusu şartlarının düzeltilmesi'");
		Else
			DocumentHeaderTemplate = NStr("vi = 'Điều kiện thưởng lũy kế của nhà cung cấp %1';
											|ru = 'Условия ретро-бонусов поставщика %1';
											|en = 'Conditions of %1 vendor rebates'; fa = 'Conditions of %1 vendor rebates';
											|it = 'Условия ретро-бонусов поставщика %1';
											|pl = 'Conditions of %1 vendor rebates';
											|tr = '%1 tedarikçinin retro bonusu şartları'");
		EndIf;
		
	Else
		
		If Patch Then
			DocumentHeaderTemplate = NStr("vi = 'Điều chỉnh điều kiện thưởng lũy kế của nhà cung cấp %1';
											|ru = 'Корректировка условий ретро-бонусов поставщика %1';
											|en = 'Correct conditions of %1 vendor rebates'; fa = 'Correct conditions of %1 vendor rebates';
											|it = 'Корректировка условий ретро-бонусов поставщика %1';
											|pl = 'Correct conditions of %1 vendor rebates';
											|tr = '%1 tedarikçi retro bonusu şartlarının düzeltilmesi'");
		Else
			DocumentHeaderTemplate = NStr("vi = 'Điều kiện thưởng lũy kế của nhà cung cấp %1';
											|ru = 'Условия РБ поставщика %1';
											|en = 'Terms of %1 vendor rebates'; fa = 'Terms of %1 vendor rebates';
											|it = 'Условия РБ поставщика %1';
											|pl = 'Terms of %1 vendor rebates';
											|tr = '%1 tedarikçi retro bonusu şartları'");
		EndIf;
		
	EndIf;
	
	Return DocumentHeaderTemplate;
	
EndFunction

// Returns:
//  String
//
Function QueryTextOfCurrentConditionsDocument() Export
	
	QueryText =
	"SELECT TOP 1
	|	DocumentsRegistry.Ref AS Ref,
	|	DocumentsRegistry.IBDocumentDate AS DocumentDate
	|INTO VT_DocumentAdjustments
	|FROM
	|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|WHERE
	|	DocumentsRegistry.CorrectedDocument = &CorrectedDocument
	|	AND NOT DocumentsRegistry.AdditionalRecord
	|	AND DocumentsRegistry.Posted
	|	AND DocumentsRegistry.Status = &DocumentStatus
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	DocumentsRegistry.Ref AS Ref,
	|	DocumentsRegistry.IBDocumentDate AS DocumentDate
	|FROM
	|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|WHERE
	|	DocumentsRegistry.Ref = &CorrectedDocument
	|	AND DocumentsRegistry.CorrectedDocument = VALUE(Document.ConditionsOfVendorRebates.EmptyRef)
	|	AND NOT DocumentsRegistry.AdditionalRecord
	|	AND DocumentsRegistry.Posted
	|	AND DocumentsRegistry.Status = &DocumentStatus
	|
	|ORDER BY
	|	DocumentsRegistry.IBDocumentDate DESC
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	VT_DocumentAdjustments.Ref AS Ref
	|FROM
	|	VT_DocumentAdjustments AS VT_DocumentAdjustments";
	
	Return QueryText;
	
EndFunction

// Parameters:
//  AccordingToDocument - Boolean
// 
// Returns:
//  String
//
Function QueryTextForFixingItemSegments(AccordingToDocument) Export
	
	QueriesArray = New Array; // Array of String
	
	If AccordingToDocument Then
		
		QueryText = 
		"SELECT
		|	GoodsSegments.Segment AS Segment,
		|	GoodsSegments.Segment.GenerationMethod AS GenerationMethod
		|INTO TT_Segments
		|FROM
		|	Document.ConditionsOfVendorRebates.GoodsSegments AS GoodsSegments
		|WHERE
		|	GoodsSegments.Ref = &TermDocument
		|	AND NOT GoodsSegments.Canceled";
		
	Else
		
		QueryText =
		"SELECT DISTINCT
		|	GoodsSegments.Segment AS Segment,
		|	GoodsSegments.Segment.GenerationMethod AS GenerationMethod
		|INTO TT_Segments
		|FROM
		|	InformationRegister.VendorRebatesGoodsSegments AS GoodsSegments
		|WHERE
		|	GoodsSegments.TermDocument = &TermDocument
		|
		|INDEX BY
		|	Segment"; 
		
	EndIf;
	
	QueriesArray.Add(QueryText);
	
	QueryText =
	"SELECT DISTINCT
	|	SegmentProducts.Products AS Products,
	|	SegmentProducts.Characteristic AS Characteristic
	|FROM
	|	TT_Segments AS TT_Segments
	|		INNER JOIN InformationRegister.SegmentProducts AS SegmentProducts
	|		ON TT_Segments.Segment = SegmentProducts.Segment
	|		AND SegmentProducts.Products.ItemsType IN (&SupportedItemTypes)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_Segments.Segment AS Segment
	|FROM
	|	TT_Segments AS TT_Segments
	|WHERE
	|	TT_Segments.GenerationMethod = VALUE(Enum.SegmentGenerationMethods.GenerateDynamically)";
	
	QueriesArray.Add(QueryText);
	QueryText = StrConcat(QueriesArray, Common.QueryBatchSeparator());
	
	Return QueryText;
	
EndFunction

// Parameters:
//  TermDocument - DocumentRef.ConditionsOfVendorRebates
// 
// Returns:
//  Structure - The Cur Status of the calculations of the conditions document:
// * ConditionsDocumentIsRegistered - Boolean - 
// * ThereArePeriodsWithoutAccruals - Boolean - 
// * AccruedBonusesAreFullyActivated - Boolean - 
// * AccrualIsExpected - Boolean - 
// * RepaymentIsMoreThanAccrual - Boolean - 
// * ActIsExpected - Boolean - 
//
Function StatusOfCalculationsOfConditionsDocument(TermDocument) Export
	
	Result = New Structure;
	Result.Insert("ConditionsDocumentIsRegistered", False);
	Result.Insert("ThereArePeriodsWithoutAccruals", False);
	Result.Insert("AccruedBonusesAreFullyActivated", False);
	Result.Insert("AccrualIsExpected", False);
	Result.Insert("RepaymentIsMoreThanAccrual", False);
	Result.Insert("ActIsExpected", False);
	Result.Insert("DifferentStates_", False);
	
	Data = PaymentDataWithSupplier(TermDocument);
	ResultConditionData = Data.ResultConditionData;
	ResultResults = Data.ResultResults;
	TableOfAccrualPeriods = Data.ResultPeriods;
	
	If ResultConditionData.Next() Then
		
		ValidOnDate = ResultConditionData.ValidOnDate;
		ValidTo = ResultConditionData.ValidTo;
		BonusType = ResultConditionData.BonusType;
		AccrualFrequency = ResultConditionData.AccrualFrequency;
		Result.ConditionsDocumentIsRegistered = True;
		
		If ResultResults.Count() > 0 Then
			
			ExecuteCheck1 = Not (BonusType = Enums.VendorRebateTypes.Balance
									Or AccrualFrequency = Enums.RebatesFrequencies.Single);
			
			If ExecuteCheck1 Then
				
				Result.ThereArePeriodsWithoutAccruals = ThereAreGapsInPeriods(
					ValidOnDate, 
					ValidTo,
					TableOfAccrualPeriods);
					
			EndIf;
			
			FillInResultBasedOnResultsOfCheck(Result, ResultResults);
			
		Else
			
			Result.AccrualIsExpected = True;
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Parameters:
//  TermDocument - DocumentRef.ConditionsOfVendorRebates
// 
// Returns:
//  Boolean - The terms of Rebates of suppliers have been completed
//
Function SettlementsUnderTermsOfRebatesAreClosed(TermDocument) Export
	
	CalculationsAreClosed = False;
	Query = New Query;
	Query.SetParameter("TermDocument", TermDocument);
	Query.Text =
	"SELECT
	|	CompletedConditionsOfVendorRebates.Completed AS Completed
	|FROM
	|	InformationRegister.CompletedConditionsOfVendorRebates AS CompletedConditionsOfVendorRebates
	|WHERE
	|	CompletedConditionsOfVendorRebates.TermDocument = &TermDocument";
	
	Result = Query.Execute();
	If Not Result.IsEmpty() Then
		
		Selection = Result.Select();
		Selection.Next();
		CalculationsAreClosed = Selection.Completed; // Boolean
		
	EndIf;
	
	Return CalculationsAreClosed;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region Posting

// The details of the document
// 
// Parameters:
//  Query - Query - Query
// 
// Returns:
//  QueryResultSelection - The details of the document:
// * Date - Date -  
// * Number - String - 
// * BonusType - EnumRef.VendorRebateTypes
// * Organization - CatalogRef.Companies -
// * Currency - CatalogRef.Currencies -
// * ValidOnDate- Date -
// * ValidTo- Date -
// * DateOfRemainingGoods - Date -
// * FilterParties - EnumRef.RebatesLists
// * SumPlan - DefinedType.MonetaryAmountNonNegative -
// * ModeMultipleVendors - Boolean
// * Patch - Boolean -
// * CorrectedDocument - DocumentRef.ConditionsOfCustomerRebates -
//
Function DocumentAttributes(Query)
	
	Query.Text =
	"SELECT
	|	DocumentData.Date AS Date,
	|	DocumentData.Number AS Number,
	|	DocumentData.BonusType AS BonusType,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.ValidOnDate AS ValidOnDate,
	|	DocumentData.ValidTo AS ValidTo,
	|	DocumentData.DateOfRemainingGoods AS DateOfRemainingGoods,
	|	DocumentData.FilterParties AS FilterParties,
	|	DocumentData.SumPlan AS SumPlan,
	|	DocumentData.ModeMultipleVendors AS ModeMultipleVendors,
	|	DocumentData.Patch AS Patch,
	|	DocumentData.CorrectedDocument AS CorrectedDocument
	|FROM
	|	DocumentDataHeader AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	Return Attributes;
	
EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Attributes =	DocumentAttributes(Query);
	
	For Each KeyAndValue In ValuesOfHoldingParameters(Attributes) Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

// Parameters:
//  Attributes - See DocumentAttributes
// 
// Returns:
//  Structure 
//
Function ValuesOfHoldingParameters(Attributes = Undefined)
	
	Values = New Structure;
	
	Values.Insert(
		"MetadataIdentifier",
		Common.MetadataObjectID("Document.ConditionsOfVendorRebates"));
	
	If Attributes <> Undefined Then
		
		Values.Insert(
			"NumberForPrinting",
			ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
		
		Values.Insert("Period", Attributes.Date);
		Values.Insert("Organization", Attributes.Organization);
		Values.Insert("BonusType", Attributes.BonusType);
		Values.Insert("Currency", Attributes.Currency);
		Values.Insert("ValidOnDate", Attributes.ValidOnDate);
		Values.Insert("ValidTo", Attributes.ValidTo);
		Values.Insert("DateOfRemainingGoods", Attributes.DateOfRemainingGoods);
		Values.Insert("FilterParties", Attributes.FilterParties);
		Values.Insert("SumPlan", Attributes.SumPlan);
		Values.Insert("ModeMultipleVendors", Attributes.ModeMultipleVendors);
		Values.Insert("Patch", Attributes.Patch);
		Values.Insert("CorrectedDocument", Attributes.CorrectedDocument);
		
	EndIf;
	
	Return Values;
	
EndFunction

Function QueryTextTableDocumentsRegistry(QueryTexts, Registers, DocumentObject = Undefined)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date AS IBDocumentDate,
	|	DocumentData.Number AS IBDocumentNumber,
	|	&MetadataIdentifier AS RefType,
	|	DocumentData.Organization AS Organization,
	|	UNDEFINED AS BusinessOperation,
	|	UNDEFINED AS Partner,
	|	UNDEFINED AS Counterparty,
	|	UNDEFINED AS LineOfBusiness,
	|	VALUE(Catalog.Warehouses.EmptyRef) AS StorageLocation,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
	|	CAST(DocumentData.Comment AS STRING(100)) AS Comment,
	|	DocumentData.Currency AS Currency,
	|	0 AS Sum,
	|	DocumentData.Status AS Status,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	FALSE AS AdditionalRecord,
	|	DocumentData.LongDesc AS More,
	|	DocumentData.Date AS SourceDocumentDate,
	|	&NumberForPrinting AS SourceDocumentNumber,
	|	DocumentData.Patch AS ReverseTransactionCorrection,
	|	DocumentData.ReversedDocument AS ReversedDocument,
	|	DocumentData.CorrectedDocument AS CorrectedDocument,
	|	DocumentData.Date AS RecordingInAccountingDate,
	|	UNDEFINED AS Priority
	|FROM
	|	DocumentDataHeader AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	If DocumentObject = Undefined Then
		
		QueryText = StrReplace(QueryText, "DocumentDataHeader", "Document.ConditionsOfVendorRebates");
		
	Else
		
		QueryText = StrReplace(QueryText, "&NumberForPrinting", "DocumentData.Number");
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableConditions(QueryTexts, Registers, DocumentObject)
	
	RegisterName = "VendorRebatesConditions";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If DocumentObject.Status <> Enums.RebatesDocumentStatuses.Approved Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	DocumentData.ValidOnDate AS ValidOnDate,
	|	DocumentData.ValidTo AS ValidTo,
	|	CASE
	|		WHEN &Patch
	|			THEN &CorrectedDocument
	|		ELSE DocumentData.Ref
	|	END AS TermDocument,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.RebateKind AS Kind,
	|	DocumentData.BonusType AS BonusType,
	|	DocumentData.LongDesc AS LongDesc,
	|	DocumentData.PartyList AS PartyList,
	|	DocumentData.FilterParties AS Attendees,
	|	DocumentData.ContentOfGoods AS ContentOfGoods,
	|	DocumentData.FilterOfProducts_ AS Goods,
	|	DocumentData.SelectionOfWarehouses_ AS Warehouses,
	|	DocumentData.DateOfRemainingGoods AS DateOfRemainingGoods,
	|	DocumentData.ConsiderVAT AS ConsiderVAT,
	|	DocumentData.BonusPercent AS BonusPercent,
	|	DocumentData.SumPlan AS SumPlan,
	|	DocumentData.AmountBonus AS AmountBonus,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.ConditionFrequency AS ConditionFrequency,
	|	DocumentData.AccrualFrequency AS AccrualFrequency,
	|	DocumentData.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
	|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
	|	DocumentData.CalculationScaleType AS CalculationScaleType,
	|	DocumentData.Ref AS RecorderDocument
	|FROM
	|	DocumentDataHeader AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableGoods(QueryTexts, Registers, DocumentObject)
	
	RegisterName = "VendorRebatesGoods";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers)
	 Or DocumentObject.Status <> Enums.RebatesDocumentStatuses.Approved
	 Or DocumentObject.FilterOfProducts_ = Enums.RebatesLists.All Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	CASE
	|		WHEN TableData.ValidOnDate = DATETIME(1, 1, 1)
	|			THEN &ValidOnDate
	|		ELSE TableData.ValidOnDate
	|	END AS ValidOnDate,
	|	CASE
	|		WHEN TableData.ValidTo = DATETIME(1, 1, 1)
	|			THEN &ValidTo
	|		ELSE TableData.ValidTo
	|	END AS ValidTo,
	|	CASE
	|		WHEN &Patch
	|			THEN &CorrectedDocument
	|		ELSE TableData.Ref
	|	END AS TermDocument,
	|	TableData.Products AS Products,
	|	TableData.Characteristic AS Characteristic,
	|	TableData.CountPlan AS CountPlan,
	|	TableData.QuantityPlanRangeBound AS QuantityPlanRangeBound,
	|	TableData.Percent AS BonusPercent,
	|	TableData.LineNumber AS DocumentRowNumber,
	|	TableData.BasePrice AS BasePrice,
	|	TableData.BonusPerUnit AS BonusPerUnit,
	|	TableData.AmountBonus AS AmountBonus,
	|	TableData.Ref AS RecorderDocument
	|FROM
	|	DocumentDataTableItems AS TableData
	|WHERE
	|	TableData.Ref = &Ref
	|	AND NOT TableData.Canceled";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableProductProperties_(QueryTexts, Registers, DocumentObject)
	
	RegisterName = "VendorRebatesItemProperties";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers)
	 Or DocumentObject.Status <> Enums.RebatesDocumentStatuses.Approved
	 Or DocumentObject.FilterOfProducts_ = Enums.RebatesLists.All Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	CASE
	|		WHEN TableData.ValidOnDate = DATETIME(1, 1, 1)
	|			THEN &ValidOnDate
	|		ELSE TableData.ValidOnDate
	|	END AS ValidOnDate,
	|	CASE
	|		WHEN TableData.ValidTo = DATETIME(1, 1, 1)
	|			THEN &ValidTo
	|		ELSE TableData.ValidTo
	|	END AS ValidTo,
	|	CASE
	|		WHEN &Patch
	|			THEN &CorrectedDocument
	|		ELSE TableData.Ref
	|	END AS TermDocument,
	|	TableData.PropertyValue AS PropertyValue,
	|	TableData.CountPlan AS CountPlan,
	|	TableData.QuantityPlanRangeBound AS QuantityPlanRangeBound,
	|	TableData.Percent AS BonusPercent,
	|	TableData.BasePrice AS BasePrice,
	|	TableData.LineNumber AS DocumentRowNumber,
	|	TableData.Ref AS RecorderDocument
	|FROM
	|	DocumentDataTableItemProperties AS TableData
	|WHERE
	|	TableData.Ref = &Ref
	|	AND NOT TableData.Canceled";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTIN(QueryTexts, Registers, DocumentObject)
	
	RegisterName = "VendorRebatesTIN";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers)
	 Or DocumentObject.Status <> Enums.RebatesDocumentStatuses.Approved
	 Or DocumentObject.FilterParties = Enums.RebatesLists.All Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	CASE
	|		WHEN TableData.ValidOnDate = DATETIME(1, 1, 1)
	|			THEN &ValidOnDate
	|		ELSE TableData.ValidOnDate
	|	END AS ValidOnDate,
	|	CASE
	|		WHEN TableData.ValidTo = DATETIME(1, 1, 1)
	|			THEN &ValidTo
	|		ELSE TableData.ValidTo
	|	END AS ValidTo,
	|	CASE
	|		WHEN &Patch
	|			THEN &CorrectedDocument
	|		ELSE TableData.Ref
	|	END AS TermDocument,
	|	TableData.TIN AS TIN,
	|	TableData.LineNumber AS DocumentRowNumber,
	|	TableData.Ref AS RecorderDocument
	|FROM
	|	DocumentDataTINTable AS TableData
	|WHERE
	|	TableData.Ref = &Ref
	|	AND NOT TableData.Canceled";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableCounterparties(QueryTexts, Registers, DocumentObject)
	
	RegisterName = "VendorRebatesCounterparties";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers)
	 Or DocumentObject.Status <> Enums.RebatesDocumentStatuses.Approved
	 Or DocumentObject.FilterParties = Enums.RebatesLists.All Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	CASE
	|		WHEN TableData.ValidOnDate = DATETIME(1, 1, 1)
	|			THEN &ValidOnDate
	|		ELSE TableData.ValidOnDate
	|	END AS ValidOnDate,
	|	CASE
	|		WHEN TableData.ValidTo = DATETIME(1, 1, 1)
	|			THEN &ValidTo
	|		ELSE TableData.ValidTo
	|	END AS ValidTo,
	|	CASE
	|		WHEN &Patch
	|			THEN &CorrectedDocument
	|		ELSE TableData.Ref
	|	END AS TermDocument,
	|	TableData.Counterparty AS Counterparty,
	|	TableData.LineNumber AS DocumentRowNumber,
	|	TableData.Ref AS RecorderDocument
	|FROM
	|	DocumentDataTableCounterparties AS TableData
	|WHERE
	|	TableData.Ref = &Ref
	|	AND NOT TableData.Canceled";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableGoodsSegments(QueryTexts, Registers, DocumentObject)
	
	RegisterName = "VendorRebatesGoodsSegments";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers)
	 Or DocumentObject.Status <> Enums.RebatesDocumentStatuses.Approved
	 Or DocumentObject.FilterOfProducts_ = Enums.RebatesLists.All Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	CASE
	|		WHEN &Patch
	|			THEN &CorrectedDocument
	|		ELSE TableData.Ref
	|	END AS TermDocument,
	|	TableData.Segment AS Segment,
	|	TableData.LineNumber AS DocumentRowNumber,
	|	TableData.Ref AS RecorderDocument
	|FROM
	|	DocumentDataTableGoodsSegments AS TableData
	|WHERE
	|	TableData.Ref = &Ref
	|	AND NOT TableData.Canceled";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableVendors(QueryTexts, Registers, DocumentObject)
	
	RegisterName = "VendorRebatesVendors";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers)
	 Or DocumentObject.Status <> Enums.RebatesDocumentStatuses.Approved Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	CASE
	|		WHEN TableData.ValidOnDate = DATETIME(1, 1, 1)
	|			THEN &ValidOnDate
	|		ELSE TableData.ValidOnDate
	|	END AS ValidOnDate,
	|	CASE
	|		WHEN TableData.ValidTo = DATETIME(1, 1, 1)
	|			THEN &ValidTo
	|		ELSE TableData.ValidTo
	|	END AS ValidTo,
	|	CASE
	|		WHEN &Patch
	|			THEN &CorrectedDocument
	|		ELSE TableData.Ref
	|	END AS TermDocument,
	|	TableData.Counterparty AS Counterparty,
	|	TableData.Partner AS Partner,
	|	TableData.Contract AS Contract,
	|	TableData.Terms AS Terms,
	|	TableData.LineNumber AS DocumentRowNumber,
	|	TableData.Ref AS RecorderDocument
	|FROM
	|	DocumentDataTableSuppliers AS TableData
	|WHERE
	|	TableData.Ref = &Ref
	|	AND NOT TableData.Canceled
	|	AND &ModeMultipleVendors
	|
	|UNION ALL
	|
	|SELECT
	|	&ValidOnDate AS ValidOnDate,
	|	&ValidTo AS ValidTo,
	|	CASE
	|		WHEN &Patch
	|			THEN &CorrectedDocument
	|		ELSE TableData.Ref
	|	END AS TermDocument,
	|	TableData.Counterparty AS Counterparty,
	|	TableData.Partner AS Partner,
	|	TableData.Contract AS Contract,
	|	TableData.Terms AS Terms,
	|	1 AS DocumentRowNumber,
	|	TableData.Ref AS RecorderDocument
	|FROM
	|	DocumentDataHeader AS TableData
	|WHERE
	|	TableData.Ref = &Ref
	|	AND NOT &ModeMultipleVendors";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableWarehouses(QueryTexts, Registers, DocumentObject)
	
	RegisterName = "VendorRebatesWarehouses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers)
	 Or DocumentObject.Status <> Enums.RebatesDocumentStatuses.Approved
	 Or DocumentObject.SelectionOfWarehouses_ = Enums.RebatesLists.All Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	CASE
	|		WHEN &Patch
	|			THEN &CorrectedDocument
	|		ELSE TableData.Ref
	|	END AS TermDocument,
	|	TableData.Warehouse AS Warehouse,
	|	TableData.LineNumber AS DocumentRowNumber,
	|	TableData.Ref AS RecorderDocument
	|FROM
	|	DocumentDataTableWarehouses AS TableData
	|WHERE
	|	TableData.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableVendorRebates(QueryTexts, Registers, DocumentObject)
	
	RegisterName = "VendorRebates";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers)
	 Or DocumentObject.Status <> Enums.RebatesDocumentStatuses.Approved
	 Or Not DocumentObject.AccrueImmediately Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	VALUE(Enum.AccumulationRecordTypes.Receipt) AS TypeOfRegisterMovement,
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	TableData.Ref AS TermDocument,
	|	TableData.Counterparty AS Counterparty,
	|	TableData.Partner AS Partner,
	|	TableData.Contract AS Contract,
	|	TableData.ValidOnDate AS BeginOfPeriod,
	|	TableData.ValidTo AS PeriodEnding,
	|	&Currency AS Currency,
	|	TableData.AmountBonus AS Accrued
	|FROM
	|	DocumentDataHeader AS TableData
	|WHERE
	|	TableData.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableRebatesCalculationScales(QueryTexts, Registers, DocumentObject)
	
	RegisterName = "RebatesCalculationScales";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If DocumentObject.Status <> Enums.RebatesDocumentStatuses.Approved Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	CASE
	|		WHEN &Patch
	|			THEN &CorrectedDocument
	|		ELSE TableData.Ref
	|	END AS TermDocument,
	|	TableData.RangeFrom AS RangeFrom,
	|	TableData.RangeBy AS RangeBy,
	|	TableData.BonusPercent AS BonusPercent,
	|	TableData.Ref AS RecorderDocument
	|FROM
	|	DocumentDataCalculationScaleTable AS TableData
	|WHERE
	|	TableData.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#Region DocumentData

Procedure GetDocumentData(Query, DocumentRef)
	
	ListOfRequests = New Array; // Array of String
	
	QueryTextDocumentDataHeader(ListOfRequests);
	QueryTextDataTableGoods(ListOfRequests);
	QueryTextDataTableItemProperties(ListOfRequests);
	QueryTextDataTINTable(ListOfRequests);
	QueryTextDataTableCounterparties(ListOfRequests);
	QueryTextDataTableGoodsSegments(ListOfRequests);
	QueryTextDataTableVendors(ListOfRequests);
	QueryTextDataTableWarehouses(ListOfRequests);
	QueryTextDataCalculationScaleTable(ListOfRequests);
	
	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	
	Query.Text = QueryText;
	Query.TempTablesManager = New TempTablesManager();
	Query.SetParameter("Ref", DocumentRef);
	Query.Execute();
	
EndProcedure

Procedure QueryTextDocumentDataHeader(ListOfRequests)
	
	QueryText =
	"SELECT
	|	DocumentData.DeletionMark AS DeletionMark,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date AS Date,
	|	DocumentData.Number AS Number,
	|	DocumentData.Status AS Status,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.ValidOnDate AS ValidOnDate,
	|	DocumentData.ValidTo AS ValidTo,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Terms AS Terms,
	|	DocumentData.ModeMultipleVendors AS ModeMultipleVendors,
	|	DocumentData.LongDesc AS LongDesc,
	|	DocumentData.RebateKind AS RebateKind,
	|	DocumentData.BonusType AS BonusType,
	|	DocumentData.RebateKind.PartyList AS PartyList,
	|	DocumentData.FilterParties AS FilterParties,
	|	DocumentData.RebateKind.ContentOfGoods AS ContentOfGoods,
	|	DocumentData.FilterOfProducts_ AS FilterOfProducts_,
	|	DocumentData.SelectionOfWarehouses_ AS SelectionOfWarehouses_,
	|	DocumentData.DateOfRemainingGoods AS DateOfRemainingGoods,
	|	DocumentData.RebateKind.ConsiderVAT AS ConsiderVAT,
	|	DocumentData.AccrueImmediately AS AccrueImmediately,
	|	DocumentData.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.ConditionFrequency AS ConditionFrequency,
	|	DocumentData.AccrualFrequency AS AccrualFrequency,
	|	DocumentData.SumPlan AS SumPlan,
	|	DocumentData.AmountBonus AS AmountBonus,
	|	DocumentData.BonusPercent AS BonusPercent,
	|	DocumentData.CalculationScaleType AS CalculationScaleType,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
	|	DocumentData.Patch AS Patch,
	|	DocumentData.ReversedDocument AS ReversedDocument,
	|	DocumentData.CorrectedDocument AS CorrectedDocument
	|INTO DocumentDataHeader
	|FROM
	|	Document.ConditionsOfVendorRebates AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|INDEX BY
	|	Ref";
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

Procedure QueryTextDataTableGoods(ListOfRequests)
	
	QueryText =
	"SELECT
	|	DataTable.Ref AS Ref,
	|	DataTable.LineNumber AS LineNumber,
	|	DataTable.Products AS Products,
	|	DataTable.Characteristic AS Characteristic,
	|	DataTable.CountPlan AS CountPlan,
	|	DataTable.QuantityPlanRangeBound AS QuantityPlanRangeBound,
	|	DataTable.BasePrice AS BasePrice,
	|	DataTable.AmountBonus AS AmountBonus,
	|	DataTable.BonusPerUnit AS BonusPerUnit,
	|	DataTable.Percent AS Percent,
	|	DataTable.ValidOnDate AS ValidOnDate,
	|	DataTable.ValidTo AS ValidTo,
	|	DataTable.Canceled AS Canceled
	|INTO DocumentDataTableItems
	|FROM
	|	Document.ConditionsOfVendorRebates.Goods AS DataTable
	|WHERE
	|	DataTable.Ref = &Ref
	|
	|INDEX BY
	|	Ref";
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

Procedure QueryTextDataTableItemProperties(ListOfRequests)
	
	QueryText =
	"SELECT
	|	DataTable.Ref AS Ref,
	|	DataTable.LineNumber AS LineNumber,
	|	DataTable.PropertyValue AS PropertyValue,
	|	DataTable.CountPlan AS CountPlan,
	|	DataTable.QuantityPlanRangeBound AS QuantityPlanRangeBound,
	|	DataTable.BasePrice AS BasePrice,
	|	DataTable.Percent AS Percent,
	|	DataTable.ValidOnDate AS ValidOnDate,
	|	DataTable.ValidTo AS ValidTo,
	|	DataTable.Canceled AS Canceled
	|INTO DocumentDataTableItemProperties
	|FROM
	|	Document.ConditionsOfVendorRebates.ProductProperties_ AS DataTable
	|WHERE
	|	DataTable.Ref = &Ref
	|
	|INDEX BY
	|	Ref";
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

Procedure QueryTextDataTINTable(ListOfRequests)
	
	QueryText =
	"SELECT
	|	DataTable.Ref AS Ref,
	|	DataTable.LineNumber AS LineNumber,
	|	DataTable.TIN AS TIN,
	|	DataTable.ValidOnDate AS ValidOnDate,
	|	DataTable.ValidTo ValidTo,
	|	DataTable.Canceled AS Canceled
	|INTO DocumentDataTINTable
	|FROM
	|	Document.ConditionsOfVendorRebates.ClientsCounterpartiesTIN AS DataTable
	|WHERE
	|	DataTable.Ref = &Ref
	|
	|INDEX BY
	|	Ref";
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

Procedure QueryTextDataTableCounterparties(ListOfRequests)
	
	QueryText =
	"SELECT
	|	DataTable.Ref AS Ref,
	|	DataTable.LineNumber AS LineNumber,
	|	DataTable.Counterparty AS Counterparty,
	|	DataTable.ValidOnDate AS ValidOnDate,
	|	DataTable.ValidTo AS ValidTo,
	|	DataTable.Canceled AS Canceled
	|INTO DocumentDataTableCounterparties
	|FROM
	|	Document.ConditionsOfVendorRebates.CustomerCounterparties AS DataTable
	|WHERE
	|	DataTable.Ref = &Ref
	|
	|INDEX BY
	|	Ref";
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

Procedure QueryTextDataTableGoodsSegments(ListOfRequests)
	
	QueryText =
	"SELECT
	|	DataTable.Ref AS Ref,
	|	DataTable.LineNumber AS LineNumber,
	|	DataTable.Segment AS Segment,
	|	DataTable.Canceled AS Canceled
	|INTO DocumentDataTableGoodsSegments
	|FROM
	|	Document.ConditionsOfVendorRebates.GoodsSegments AS DataTable
	|WHERE
	|	DataTable.Ref = &Ref
	|
	|INDEX BY
	|	Ref";
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

Procedure QueryTextDataTableVendors(ListOfRequests)
	
	QueryText =
	"SELECT
	|	DataTable.Ref AS Ref,
	|	DataTable.LineNumber AS LineNumber,
	|	DataTable.Counterparty AS Counterparty,
	|	DataTable.Partner AS Partner,
	|	DataTable.Contract AS Contract,
	|	DataTable.Terms AS Terms,
	|	DataTable.ValidOnDate AS ValidOnDate,
	|	DataTable.ValidTo AS ValidTo,
	|	DataTable.Canceled AS Canceled
	|INTO DocumentDataTableSuppliers
	|FROM
	|	Document.ConditionsOfVendorRebates.Vendors AS DataTable
	|WHERE
	|	DataTable.Ref = &Ref
	|
	|INDEX BY
	|	Ref";
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

Procedure QueryTextDataTableWarehouses(ListOfRequests)
	
	QueryText =
	"SELECT
	|	DataTable.Ref AS Ref,
	|	DataTable.LineNumber AS LineNumber,
	|	DataTable.Warehouse AS Warehouse
	|INTO DocumentDataTableWarehouses
	|FROM
	|	Document.ConditionsOfVendorRebates.Warehouses AS DataTable
	|WHERE
	|	DataTable.Ref = &Ref
	|
	|INDEX BY
	|	Ref";
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

Procedure QueryTextDataCalculationScaleTable(ListOfRequests)
	
	QueryText =
	"SELECT
	|	DataTable.Ref AS Ref,
	|	DataTable.LineNumber AS LineNumber,
	|	DataTable.RangeFrom AS RangeFrom,
	|	DataTable.RangeBy AS RangeBy,
	|	DataTable.BonusPercent AS BonusPercent
	|INTO DocumentDataCalculationScaleTable
	|FROM
	|	Document.ConditionsOfVendorRebates.CalculationScales AS DataTable
	|WHERE
	|	DataTable.Ref = &Ref
	|
	|INDEX BY
	|	Ref";
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

#EndRegion

#EndRegion

#Region MethodsForConfiguringFormFields

#Region SettingUpTableOfParticipants

Procedure SettingUpTableOfParticipants(Settings, ConfigurationModule)
	
	ListCompositions = Enums.RebatesLists;
	
	#Region GeneralListVisibilitySettings
	Item = Settings.Add();
	
	Item.Fields.Add("CustomerCounterparties");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.NewFilter(OrGroup, "FilterParties", ListCompositions.All);
	ConfigurationModule.NewFilter(
		OrGroup,
		"More.PartyList",
		Enums.RebatesParticipants.Counterparties,
		,
		DataCompositionComparisonType.NotEqual);
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
	FilterofFields = BasicSelectionOfPeriodsOfTablesOfParticipants(ConfigurationModule);
	SettingUpTablePeriodFields(Settings, ConfigurationModule, "CustomerCounterparties", FilterofFields);
	FieldSetupCanceled(Settings, ConfigurationModule, "CustomerCounterparties.Canceled");
	SettingUpDecorationFieldCounterpartiesOfClientsThereAreCharges(Settings, ConfigurationModule);
	
EndProcedure

Procedure SettingUpDecorationFieldCounterpartiesOfClientsThereAreCharges(Settings, ConfigurationModule)
	
	ListCompositions = Enums.RebatesLists;
	
	Item = Settings.Add();
	
	Item.Fields.Add("DecorationContractorsCustomersHaveAccruals");
	
	ConfigurationModule.NewFilter(Item.Condition, "FilterParties", ListCompositions.ExceptForSelectedOnes);
	ConfigurationModule.NewFilter(Item.Condition, "More.ThereAreAccruals", True);
	ConfigurationModule.NewFilter(
		Item.Condition,
		"More.PartyList",
		Enums.RebatesParticipants.Counterparties);
	
	Item.Properties.Insert("Visible", True);
	
EndProcedure

Procedure SettingUpTableOfINNOfCounterpartiesOfClients(Settings, ConfigurationModule)
	
	ListCompositions = Enums.RebatesLists;
	
	#Region GeneralListVisibilitySettings
	Item = Settings.Add();
	
	Item.Fields.Add("ClientsCounterpartiesTIN");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.NewFilter(OrGroup, "FilterParties", ListCompositions.All);
	ConfigurationModule.NewFilter(
		OrGroup,
		"More.PartyList",
		Enums.RebatesParticipants.TIN,
		,
		DataCompositionComparisonType.NotEqual);
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
	FilterofFields = BasicSelectionOfPeriodsOfTablesOfParticipants(ConfigurationModule);
	SettingUpTablePeriodFields(Settings, ConfigurationModule, "ClientsCounterpartiesTIN", FilterofFields);
	FieldSetupCanceled(Settings, ConfigurationModule, "ClientsCounterpartiesTIN.Canceled");
	SettingUpDecorationTINFieldThereAreCharges(Settings, ConfigurationModule);
	
EndProcedure

Procedure SettingUpDecorationTINFieldThereAreCharges(Settings, ConfigurationModule)
	
	ListCompositions = Enums.RebatesLists;
	
	Item = Settings.Add();
	
	Item.Fields.Add("DecorationOfINNHasAccruals");
	
	ConfigurationModule.NewFilter(Item.Condition, "FilterParties", ListCompositions.ExceptForSelectedOnes);
	ConfigurationModule.NewFilter(Item.Condition, "More.ThereAreAccruals", True);
	ConfigurationModule.NewFilter(
		Item.Condition,
		"More.PartyList",
		Enums.RebatesParticipants.TIN);
	
	Item.Properties.Insert("Visible", True);
	
EndProcedure

#EndRegion

#Region SettingUpGoodsTable

Procedure SettingUpGoodsTable(Settings, ConfigurationModule)
	
	ListCompositions = Enums.RebatesLists;
	GoodsIndicators = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	
	#Region GeneralListVisibilitySettings
	Item = Settings.Add();
	
	Item.Fields.Add("Goods");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.NewFilter(OrGroup, "FilterOfProducts_", ListCompositions.All);
	ConfigurationModule.NewFilter(
		OrGroup,
		"More.ContentOfGoods",
		Enums.RebatesItems.Products,
		,
		DataCompositionComparisonType.NotEqual);
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
	#Region PeriodsBeforeCorrection
	Item = Settings.Add();
	
	Item.Fields.Add("Goods.StartDateBeforeChange");
	Item.Fields.Add("Goods.EndDateBeforeChange");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.NewFilter(OrGroup, "FilterOfProducts_", ListCompositions.ExceptForSelectedOnes);
	ConfigurationModule.NewFilter(OrGroup, "Patch", False);
	ConfigurationModule.NewFilter(OrGroup, "BonusType", Enums.VendorRebateTypes.Balance);
	
	ExclIndicators = New ValueList; // ValueList of EnumRef.TargetSalesIndicatorsOfRebatesByGoods
	ExclIndicators.Add(GoodsIndicators.QuantityTotal);
	ExclIndicators.Add(GoodsIndicators.BatchOffer);
	ConfigurationModule.NewFilter(
		OrGroup, "More.GoodsIndicator", ExclIndicators,, DataCompositionComparisonType.InList);
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
	#Region TimeIntervals
	Item = Settings.Add();
	
	Item.Fields.Add("Goods.ValidOnDate");
	Item.Fields.Add("Goods.ValidTo");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.NewFilter(OrGroup, "FilterOfProducts_", ListCompositions.ExceptForSelectedOnes);
	ConfigurationModule.NewFilter(OrGroup, "BonusType", Enums.VendorRebateTypes.Balance);
	
	ExclIndicators = New ValueList; // ValueList of EnumRef.TargetSalesIndicatorsOfRebatesByGoods
	ExclIndicators.Add(GoodsIndicators.QuantityTotal);
	ExclIndicators.Add(GoodsIndicators.BatchOffer);
	ConfigurationModule.NewFilter(
		OrGroup, "More.GoodsIndicator", ExclIndicators,, DataCompositionComparisonType.InList);
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
	#Region SettingBasedOnAccruals
	Item = Settings.Add();
	
	Item.Fields.Add("Goods");
	Item.Fields.Add("Goods.Products");
	Item.Fields.Add("Goods.Characteristic");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.NewFilter(OrGroup, "FilterOfProducts_", ListCompositions.ExceptForSelectedOnes);
	
	ExclIndicators = New ValueList; // ValueList of EnumRef.TargetSalesIndicatorsOfRebatesByGoods
	ExclIndicators.Add(GoodsIndicators.QuantityTotal);
	ExclIndicators.Add(GoodsIndicators.BatchOffer);
	ConfigurationModule.NewFilter(
		OrGroup, "More.GoodsIndicator", ExclIndicators,, DataCompositionComparisonType.InList);
	ConfigurationModule.NewFilter(Item.Condition, "More.ThereAreAccruals", True);
	
	Item.Properties.Insert("ReadOnly", True);
	#EndRegion
	
	SettingUpGoodsPercentageField(Settings, ConfigurationModule);
	SettingUpGoodsFieldBasePrice(Settings, ConfigurationModule);
	SettingUpGoodsQuantityPlanField(Settings, ConfigurationModule);
	RebatesServer.SettingUpRangeDesignationField("Goods", Settings);
	SettingUpGoodsFieldBonusPerUnit(Settings, ConfigurationModule);
	SettingUpGoodsFieldBonusAmount(Settings, ConfigurationModule);
	SettingUpDecorationGoodsFieldThereAreCharges(Settings, ConfigurationModule);
	FieldSetupCanceled(Settings, ConfigurationModule, "Goods.Canceled");
	ConfiguringCommandsForFillingInGoodsTable(Settings, ConfigurationModule);
	
EndProcedure

Procedure SettingUpGoodsPercentageField(Settings, ConfigurationModule)
	
	ListCompositions = Enums.RebatesLists;
	GoodsIndicators = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	
	Item = Settings.Add();
	
	Item.Fields.Add("Goods.Percent");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.NewFilter(OrGroup, "FilterOfProducts_", ListCompositions.ExceptForSelectedOnes);
	ConfigurationModule.NewFilter(OrGroup, "BonusType", Enums.VendorRebateTypes.Balance);
	
	AndGroup = RebatesServer.NewFiltersGroup(OrGroup, DataCompositionFilterItemsGroupType.AndGroup);
	ConfigurationModule.NewFilter(AndGroup, "FilterOfProducts_", ListCompositions.Selected_);
	ConfigurationModule.NewFilter(AndGroup, "More.GoodsIndicator", GoodsIndicators.Sum);
	OrGroup = RebatesServer.NewFiltersGroup(AndGroup);
	ConfigurationModule.NewFilter(OrGroup, "RestrictAccrualOverPlan", True);
	ConfigurationModule.NewFilter(OrGroup, "CalculationScaleType", 0,, DataCompositionComparisonType.NotEqual);
	
	Item.Properties.Insert("Visible", False);
	
EndProcedure

Procedure SettingUpGoodsFieldBasePrice(Settings, ConfigurationModule)
	
	SalesDatabases = Enums.RebateCalculationBases;
	
	Item = Settings.Add();
	
	Item.Fields.Add("Goods.BasePrice");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.NewFilter(OrGroup, "More.BaseOfCalculation", SalesDatabases.RevenueBasePrices);
	ConfigurationModule.NewFilter(OrGroup, "More.BaseOfCalculation", SalesDatabases.PurchaseAmountBasePrices);
	
	Item.Properties.Insert("Visible", True);
	
EndProcedure

Procedure SettingUpGoodsQuantityPlanField(Settings, ConfigurationModule)
	
	ListCompositions = Enums.RebatesLists;
	GoodsIndicators = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	TypesOfBonuses = Enums.VendorRebateTypes;
	
	Item = Settings.Add();
	
	Item.Fields.Add("Goods.CountPlan");
	Item.Fields.Add("GoodsProductsUnitOfMeasure");
	
	ConfigurationModule.NewFilter(Item.Condition, "FilterOfProducts_", ListCompositions.Selected_);
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.NewFilter(OrGroup, "BonusType", TypesOfBonuses.Balance);
	
	ExclIndicators = New ValueList; // ValueList of EnumRef.TargetSalesIndicatorsOfRebatesByGoods
	ExclIndicators.Add(GoodsIndicators.Count);
	ExclIndicators.Add(GoodsIndicators.QuantityTotal);
	ExclIndicators.Add(GoodsIndicators.BatchOffer);
	ConfigurationModule.NewFilter(
		OrGroup, "More.GoodsIndicator", ExclIndicators,, DataCompositionComparisonType.InList);
	
	Item.Properties.Insert("Visible", True);
	
EndProcedure

Procedure SettingUpGoodsFieldBonusPerUnit(Settings, ConfigurationModule)
	
	Item = Settings.Add();
	
	Item.Fields.Add("Goods.BonusPerUnit");
	
	ConfigurationModule.NewFilter(Item.Condition, "BonusType", Enums.VendorRebateTypes.Balance);
	
	Item.Properties.Insert("Visible", True);
	
EndProcedure

Procedure SettingUpGoodsFieldBonusAmount(Settings, ConfigurationModule)
	
	Item = Settings.Add();
	
	Item.Fields.Add("Goods.AmountBonus");
	
	ConfigurationModule.NewFilter(Item.Condition, "BonusType", Enums.VendorRebateTypes.Balance);
	ConfigurationModule.NewFilter(Item.Condition, "AccrueImmediately", True);
	
	Item.Properties.Insert("Visible", True);
	
EndProcedure

Procedure SettingUpDecorationGoodsFieldThereAreCharges(Settings, ConfigurationModule)
	
	ListCompositions = Enums.RebatesLists;
	GoodsIndicators = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	
	Item = Settings.Add();
	
	Item.Fields.Add("DecorationGoodsThereAreAccruals");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.NewFilter(OrGroup, "FilterOfProducts_", ListCompositions.ExceptForSelectedOnes);
	
	ExclIndicators = New ValueList; // ValueList of EnumRef.TargetSalesIndicatorsOfRebatesByGoods
	ExclIndicators.Add(GoodsIndicators.QuantityTotal);
	ExclIndicators.Add(GoodsIndicators.BatchOffer);
	ConfigurationModule.NewFilter(
		OrGroup, "More.GoodsIndicator", ExclIndicators,, DataCompositionComparisonType.InList);
	ConfigurationModule.NewFilter(Item.Condition, "More.ThereAreAccruals", True);
	ConfigurationModule.NewFilter(
		Item.Condition,
		"More.ContentOfGoods",
		Enums.RebatesItems.Products);
	
	Item.Properties.Insert("Visible", True);
	
EndProcedure

Procedure ConfiguringCommandsForFillingInGoodsTable(Settings, ConfigurationModule)
	
	GoodsCompositions = Enums.RebatesItems;
	ListCompositions = Enums.RebatesLists;
	GoodsIndicators = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	TypesOfBonuses = Enums.VendorRebateTypes;
	
	#Region AvailabilityByAccrualAvailability
	Item = Settings.Add();
	
	Item.Fields.Add("GoodsFillBonusPercentage");
	Item.Fields.Add("GoodsFillInQuantityPlan");
	Item.Fields.Add("GoodsFillInGoodsBySegment");
	Item.Fields.Add("GoodsImportGoodsFromFile");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.NewFilter(OrGroup, "FilterOfProducts_", ListCompositions.ExceptForSelectedOnes);
	
	ExclIndicators = New ValueList; // ValueList of EnumRef.TargetSalesIndicatorsOfRebatesByGoods
	ExclIndicators.Add(GoodsIndicators.QuantityTotal);
	ExclIndicators.Add(GoodsIndicators.BatchOffer);
	ConfigurationModule.NewFilter(
		OrGroup, "More.GoodsIndicator", ExclIndicators,, DataCompositionComparisonType.InList);
	ConfigurationModule.NewFilter(Item.Condition, "More.ThereAreAccruals", True);
	
	Item.Properties.Insert("Enabled", False);
	#EndRegion
	
	#Region GoodsFillInQuantityPlan
	Item = Settings.Add();
	
	Item.Fields.Add("GoodsFillInQuantityPlan");
	
	ConfigurationModule.NewFilter(Item.Condition, "More.ContentOfGoods", GoodsCompositions.Products);
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.NewFilter(OrGroup, "FilterOfProducts_", ListCompositions.ExceptForSelectedOnes);
	AndGroup = RebatesServer.NewFiltersGroup(OrGroup, DataCompositionFilterItemsGroupType.AndGroup);
	ConfigurationModule.NewFilter(
		AndGroup, "BonusType", TypesOfBonuses.Balance,, DataCompositionComparisonType.NotEqual);
	ExclIndicators = New ValueList; // ValueList of EnumRef.TargetSalesIndicatorsOfRebatesByGoods
	ExclIndicators.Add(GoodsIndicators.Count);
	ExclIndicators.Add(GoodsIndicators.QuantityTotal);
	ExclIndicators.Add(GoodsIndicators.BatchOffer);
	ConfigurationModule.NewFilter(
		AndGroup, "More.GoodsIndicator", ExclIndicators,, DataCompositionComparisonType.NotInList);
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
	#Region GoodsFillBonusPercentage
	Item = Settings.Add();
	
	Item.Fields.Add("GoodsFillBonusPercentage");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.NewFilter(OrGroup, "FilterOfProducts_", ListCompositions.ExceptForSelectedOnes);
	ConfigurationModule.NewFilter(OrGroup, "BonusType", TypesOfBonuses.Balance);
	
	AndGroup = RebatesServer.NewFiltersGroup(OrGroup, DataCompositionFilterItemsGroupType.AndGroup);
	ConfigurationModule.NewFilter(AndGroup, "FilterOfProducts_", ListCompositions.Selected_);
	ConfigurationModule.NewFilter(AndGroup, "More.GoodsIndicator", GoodsIndicators.Sum);
	ConfigurationModule.NewFilter(AndGroup, "RestrictAccrualOverPlan", True);
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
	#Region GoodsImportGoodsFromFile
	Item = Settings.Add();
	
	Item.Fields.Add("GoodsImportGoodsFromFile");
	
	ConfigurationModule.NewFilter(Item.Condition, "More.GoodsIndicator", GoodsIndicators.Count);
	ConfigurationModule.NewFilter(Item.Condition, "CalculationScaleType", 1); // By Ranges
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
	#Region GoodsArrangeByRange
	Item = Settings.Add();
	
	Item.Fields.Add("GoodsArrangeByRange");
	
	ConfigurationModule.NewFilter(Item.Condition, "More.GoodsIndicator", GoodsIndicators.Count);
	ConfigurationModule.NewFilter(Item.Condition, "CalculationScaleType", 1); // By Ranges
	
	Item.Properties.Insert("Visible", True);
	#EndRegion
	
EndProcedure

#EndRegion

#Region SettingUpItemPropertiesTable

Procedure SettingUpItemPropertiesTable(Settings, ConfigurationModule);
	
	ListCompositions = Enums.RebatesLists;
	GoodsIndicators = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	
	#Region GeneralListVisibilitySettings
	Item = Settings.Add();
	
	Item.Fields.Add("ProductProperties_");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.NewFilter(OrGroup, "FilterOfProducts_", ListCompositions.All);
	ConfigurationModule.NewFilter(
		OrGroup,
		"More.ContentOfGoods",
		Enums.RebatesItems.ProductItemProperty,
		,
		DataCompositionComparisonType.NotEqual);
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
	ExclIndicatorsOfPeriods = New ValueList; // ValueList of EnumRef.TargetSalesIndicatorsOfRebatesByGoods
	ExclIndicatorsOfPeriods.Add(GoodsIndicators.QuantityTotal);
	ExclIndicatorsOfPeriods.Add(GoodsIndicators.BatchOffer);
	
	#Region PeriodsBeforeCorrection
	Item = Settings.Add();
	
	Item.Fields.Add("ProductProperties_.StartDateBeforeChange");
	Item.Fields.Add("ProductProperties_.EndDateBeforeChange");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.NewFilter(OrGroup, "FilterOfProducts_", ListCompositions.ExceptForSelectedOnes);
	ConfigurationModule.NewFilter(OrGroup, "Patch", False);
	
	ConfigurationModule.NewFilter(
		OrGroup, "More.GoodsIndicator", ExclIndicatorsOfPeriods,, DataCompositionComparisonType.InList);
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
	#Region TimeIntervals
	Item = Settings.Add();
	
	Item.Fields.Add("ProductProperties_.ValidOnDate");
	Item.Fields.Add("ProductProperties_.ValidTo");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.NewFilter(OrGroup, "FilterOfProducts_", ListCompositions.ExceptForSelectedOnes);
	
	ConfigurationModule.NewFilter(
		OrGroup, "More.GoodsIndicator", ExclIndicatorsOfPeriods,, DataCompositionComparisonType.InList);
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
	#Region SettingBasedOnAccruals
	Item = Settings.Add();
	
	Item.Fields.Add("ProductProperties_");
	Item.Fields.Add("ProductProperties_.PropertyValue");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.NewFilter(OrGroup, "FilterOfProducts_", ListCompositions.ExceptForSelectedOnes);
	
	ExclIndicators = New ValueList; // ValueList of EnumRef.TargetSalesIndicatorsOfRebatesByGoods
	ExclIndicators.Add(GoodsIndicators.QuantityTotal);
	ExclIndicators.Add(GoodsIndicators.BatchOffer);
	ConfigurationModule.NewFilter(
		OrGroup, "More.GoodsIndicator", ExclIndicators,, DataCompositionComparisonType.InList);
	ConfigurationModule.NewFilter(Item.Condition, "More.ThereAreAccruals", True);
	
	Item.Properties.Insert("ReadOnly", True);
	#EndRegion
	
	ConfiguringItemPropertiesFieldPercentage(Settings, ConfigurationModule);
	ConfiguringItemPropertiesFieldBasePrice(Settings, ConfigurationModule);
	RebatesServer.ConfiguringItemPropertiesFieldQuantityPlan(Settings);
	RebatesServer.SettingUpRangeDesignationField("ProductProperties_", Settings);
	RebatesServer.SettingUpDecorationPropertiesFieldThereAreCharges(Settings);
	FieldSetupCanceled(Settings, ConfigurationModule, "ProductProperties_.Canceled");
	ConfiguringCommandsInItemPropertiesTable(Settings, ConfigurationModule);
	
EndProcedure

Procedure ConfiguringItemPropertiesFieldPercentage(Settings, ConfigurationModule)
	
	ListCompositions = Enums.RebatesLists;
	GoodsIndicators = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	
	Item = Settings.Add();
	
	Item.Fields.Add("ProductProperties_.Percent");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.NewFilter(OrGroup, "FilterOfProducts_", ListCompositions.ExceptForSelectedOnes);
	
	AndGroup = RebatesServer.NewFiltersGroup(OrGroup, DataCompositionFilterItemsGroupType.AndGroup);
	ConfigurationModule.NewFilter(AndGroup, "FilterOfProducts_", ListCompositions.Selected_);
	ConfigurationModule.NewFilter(AndGroup, "More.GoodsIndicator", GoodsIndicators.Sum);
	OrGroup = RebatesServer.NewFiltersGroup(AndGroup);
	ConfigurationModule.NewFilter(OrGroup, "RestrictAccrualOverPlan", True);
	ConfigurationModule.NewFilter(OrGroup, "CalculationScaleType", 0,, DataCompositionComparisonType.NotEqual);
	
	Item.Properties.Insert("Visible", False);
	
EndProcedure

Procedure ConfiguringItemPropertiesFieldBasePrice(Settings, ConfigurationModule)
	
	SalesDatabases = Enums.RebateCalculationBases;
	
	Item = Settings.Add();
	
	Item.Fields.Add("ProductProperties_.BasePrice");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.NewFilter(OrGroup, "More.BaseOfCalculation", SalesDatabases.RevenueBasePrices);
	ConfigurationModule.NewFilter(OrGroup, "More.BaseOfCalculation", SalesDatabases.PurchaseAmountBasePrices);
	
	Item.Properties.Insert("Visible", True);
	
EndProcedure

Procedure ConfiguringCommandsInItemPropertiesTable(Settings, ConfigurationModule)
	
	GoodsIndicators = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	ListCompositions = Enums.RebatesLists;
	
	#Region AvailabilityByAccrualAvailability
	Item = Settings.Add();
	
	Item.Fields.Add("ItemPropertiesFillInBonusPercentage");
	Item.Fields.Add("ItemPropertiesFillInQuantityPlan");
	Item.Fields.Add("ProductProperties_ImportPropertiesValuesfromFile");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.NewFilter(OrGroup, "FilterOfProducts_", ListCompositions.ExceptForSelectedOnes);
	
	ExclIndicators = New ValueList; // ValueList of EnumRef.TargetSalesIndicatorsOfRebatesByGoods
	ExclIndicators.Add(GoodsIndicators.QuantityTotal);
	ExclIndicators.Add(GoodsIndicators.BatchOffer);
	ConfigurationModule.NewFilter(
		OrGroup, "More.GoodsIndicator", ExclIndicators,, DataCompositionComparisonType.InList);
	ConfigurationModule.NewFilter(Item.Condition, "More.ThereAreAccruals", True);
	
	Item.Properties.Insert("Enabled", False);
	#EndRegion
	
	#Region ProductProperties_ImportPropertiesValuesfromFile
	Item = Settings.Add();
	
	Item.Fields.Add("ProductProperties_ImportPropertiesValuesfromFile");
	
	ConfigurationModule.NewFilter(Item.Condition, "More.GoodsIndicator", GoodsIndicators.Count);
	ConfigurationModule.NewFilter(Item.Condition, "CalculationScaleType", 1); // By Ranges
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
	#Region ItemPropertiesFillInBonusPercentage
	Item = Settings.Add();
	
	Item.Fields.Add("ItemPropertiesFillInBonusPercentage");
	
	GroupORMain = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.NewFilter(GroupORMain, "FilterOfProducts_", ListCompositions.ExceptForSelectedOnes);
	
	AndGroup = RebatesServer.NewFiltersGroup(GroupORMain, DataCompositionFilterItemsGroupType.AndGroup);
	ConfigurationModule.NewFilter(AndGroup, "FilterOfProducts_", ListCompositions.Selected_);
	ConfigurationModule.NewFilter(AndGroup, "More.GoodsIndicator", GoodsIndicators.Sum);
	OrGroup = RebatesServer.NewFiltersGroup(AndGroup);
	ConfigurationModule.NewFilter(OrGroup, "RestrictAccrualOverPlan", True);
	ConfigurationModule.NewFilter(OrGroup, "CalculationScaleType", 0,, DataCompositionComparisonType.NotEqual);
	
	AndGroup = RebatesServer.NewFiltersGroup(GroupORMain, DataCompositionFilterItemsGroupType.AndGroup);
	ConfigurationModule.NewFilter(AndGroup, "FilterOfProducts_", ListCompositions.Selected_);
	ConfigurationModule.NewFilter(AndGroup, "More.GoodsIndicator", GoodsIndicators.Count);
	ConfigurationModule.NewFilter(AndGroup, "CalculationScaleType", 0,, DataCompositionComparisonType.NotEqual);
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
	#Region ItemPropertiesFillInQuantityPlan
	Item = Settings.Add();
	
	Item.Fields.Add("ItemPropertiesFillInQuantityPlan");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.NewFilter(OrGroup, "FilterOfProducts_", ListCompositions.ExceptForSelectedOnes);
	ExclIndicators = New ValueList; // ValueList of EnumRef.TargetSalesIndicatorsOfRebatesByGoods
	ExclIndicators.Add(GoodsIndicators.Count);
	ExclIndicators.Add(GoodsIndicators.QuantityTotal);
	ExclIndicators.Add(GoodsIndicators.BatchOffer);
	ConfigurationModule.NewFilter(
		OrGroup, "More.GoodsIndicator", ExclIndicators,, DataCompositionComparisonType.NotInList);
	AndGroup = RebatesServer.NewFiltersGroup(OrGroup, DataCompositionFilterItemsGroupType.AndGroup);
	ConfigurationModule.NewFilter(AndGroup, "CalculationScaleType", 0,, DataCompositionComparisonType.NotEqual);
	ConfigurationModule.NewFilter(AndGroup, "More.GoodsIndicator", GoodsIndicators.Count);
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
	#Region ProductProperties_ArrangePropertyValuesByRange
	Item = Settings.Add();
	
	Item.Fields.Add("ProductProperties_ArrangePropertyValuesByRange");
	
	ConfigurationModule.NewFilter(Item.Condition, "More.GoodsIndicator", GoodsIndicators.Count);
	ConfigurationModule.NewFilter(Item.Condition, "CalculationScaleType", 1); // By Ranges
	
	Item.Properties.Insert("Visible", True);
	#EndRegion
	
EndProcedure

#EndRegion

Procedure SettingUpGoodsSegmentsTable(Settings, ConfigurationModule);
	
	ListCompositions = Enums.RebatesLists;
	
	#Region GeneralListVisibilitySettings
	Item = Settings.Add();
	
	Item.Fields.Add("GoodsSegments");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.NewFilter(OrGroup, "FilterOfProducts_", ListCompositions.All);
	ConfigurationModule.NewFilter(
		OrGroup,
		"More.ContentOfGoods",
		Enums.RebatesItems.ProductSegments,
		,
		DataCompositionComparisonType.NotEqual);
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
	#Region GoodsSegmentsCancellation
	Item = Settings.Add();
	
	Item.Fields.Add("GoodsSegments.Canceled");
	
	ConfigurationModule.NewFilter(Item.Condition, "Patch", True);
	
	Item.Properties.Insert("Visible", True);
	#EndRegion
	
EndProcedure

Procedure SettingUpWarehousesTable(Settings, ConfigurationModule);
	
	TypesOfBonuses = Enums.VendorRebateTypes;
	ListCompositions = Enums.RebatesLists;
	
	#Region Visible
	Item = Settings.Add();
	
	Item.Fields.Add("Warehouses");
	
	AndGroup = RebatesServer.NewFiltersGroup(Item.Condition, DataCompositionFilterItemsGroupType.AndGroup);
	
	ConfigurationModule.NewFilter(AndGroup, "BonusType", TypesOfBonuses.Balance);
	ConfigurationModule.NewFilter(AndGroup, "SelectionOfWarehouses_", ListCompositions.All,, DataCompositionComparisonType.NotEqual);
	ConfigurationModule.NewFilter(AndGroup, "AccrueImmediately", False);
	
	Item.Properties.Insert("Visible", True);
	#EndRegion
	
	#Region ReadOnly
	Item = Settings.Add();
	
	Item.Fields.Add("Warehouses");
	
	ConfigurationModule.NewFilter(Item.Condition, "Patch", True);
	
	Item.Properties.Insert("ReadOnly", True);
	#EndRegion
	
EndProcedure

Procedure SettingUpVendorsTable(Settings, ConfigurationModule)

	TypesOfBonuses = Enums.VendorRebateTypes;
	
	#Region Visible
	Item = Settings.Add();
	
	Item.Fields.Add("Vendors");
	
	ConfigurationModule.NewFilter(Item.Condition, "BonusType", TypesOfBonuses.Purchases);
	ConfigurationModule.NewFilter(Item.Condition, "ModeMultipleVendors", True);
	
	Item.Properties.Insert("Visible", True);
	#EndRegion
	
	FilterofFields = BasicSelectionOfPeriodsOfTablesOfParticipants(ConfigurationModule);
	SettingUpTablePeriodFields(Settings, ConfigurationModule, "Vendors", FilterofFields);
	FieldSetupCanceled(Settings, ConfigurationModule, "Vendors.Canceled");
	
EndProcedure

Procedure SettingUpCalculationScaleTable(Settings, ConfigurationModule);
	
	#Region BlockingByPresenceOfCharges
	Item = Settings.Add();
	
	Item.Fields.Add("CalculationScales");
	
	ConfigurationModule.NewFilter(Item.Condition, "More.ThereAreAccruals", True);
	
	Item.Properties.Insert("ReadOnly", True);
	#EndRegion
	
	#Region VisibilityOfFieldsByScaleType
	Item = Settings.Add();
	
	Item.Fields.Add("CalculationScalesRangeDesignation");
	Item.Fields.Add("CalculationScalesNameOfRange");
	
	ConfigurationModule.NewFilter(
		Item.Condition,
		"More.GoodsIndicator",
		Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum);
	ConfigurationModule.NewFilter(Item.Condition, "CalculationScaleType", 2); // Ranges
	
	Item.Properties.Insert("Visible", True);
	#EndRegion
	
EndProcedure

Procedure SettingUpTablePeriodFields(Settings, ConfigurationModule, TableName, FilterofFields)
	
	#Region PeriodsBeforeCorrection
	Item = Settings.Add();
	
	Item.Fields.Add(TableName + "StartDateBeforeChange");
	Item.Fields.Add(TableName + ".EndDateBeforeChange");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.CopyFilter(FilterofFields, OrGroup);
	ConfigurationModule.NewFilter(OrGroup, "Patch", False);
		
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
	#Region TimeIntervals
	Item = Settings.Add();
	
	Item.Fields.Add(TableName + ".ValidOnDate");
	Item.Fields.Add(TableName + ".ValidTo");
	
	ConfigurationModule.CopyFilter(FilterofFields, Item.Condition);
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
EndProcedure

Function BasicSelectionOfPeriodsOfTablesOfParticipants(ConfigurationModule)
	
	ListCompositions = Enums.RebatesLists;
	
	Filter = New DataCompositionFilter();
	
	ConfigurationModule.NewFilter(Filter, "FilterParties", ListCompositions.ExceptForSelectedOnes);
	
	Return Filter;
	
EndFunction

Procedure FieldSetupCanceled(Settings, ConfigurationModule, FieldName)
	
	Item = Settings.Add();
	
	Item.Fields.Add(FieldName);
	
	ConfigurationModule.NewFilter(Item.Condition, "Patch", True);
	
	Item.Properties.Insert("Visible", True);
	
EndProcedure

Procedure SettingUpCurrencyField(Settings, ConfigurationModule)
	
	SalesDatabase = Enums.RebateCalculationBases;
	TypesOfBonuses = Enums.VendorRebateTypes;
	TargetValues = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	
	#Region Visible
	Item = Settings.Add();
	
	If GetFunctionalOption("UseMultipleCurrencies") Then
		Item.Fields.Add("Currency");
	Else
		Item.Fields.Add("CurrentCurrency");
	EndIf;
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	
	ConfigurationModule.NewFilter(OrGroup, "RebateKind", Catalogs.VendorRebateKinds.EmptyRef());
	ConfigurationModule.NewFilter(OrGroup, "WithoutCalculation", True);
	ConfigurationModule.NewFilter(OrGroup, "BonusType", TypesOfBonuses.Balance);
	
	InclDatabaseOfMutualSettlements = New ValueList; // ValueList of EnumRef.RebateCalculationBases
	InclDatabaseOfMutualSettlements.Add(SalesDatabase.RevenueARAPAccounting);
	InclDatabaseOfMutualSettlements.Add(SalesDatabase.PurchaseAmountARAPAccounting);
	
	ConfigurationModule.NewFilter(
		OrGroup, 
		"More.BaseOfCalculation",
		InclDatabaseOfMutualSettlements,
		, 
		DataCompositionComparisonType.NotInList);
		
	AndGroup = RebatesServer.NewFiltersGroup(OrGroup, DataCompositionFilterItemsGroupType.AndGroup);
	
	ConfigurationModule.NewFilter(
		AndGroup,
		"More.GoodsIndicator",
		TargetValues.Sum);
		
	ConfigurationModule.NewFilter(
		AndGroup, 
		"More.BaseOfCalculation",
		InclDatabaseOfMutualSettlements,
		, 
		DataCompositionComparisonType.InList);
	
	Item.Properties.Insert("Visible", True);
	#EndRegion
	
	#Region ReadOnly
	Item = Settings.Add();
	
	Item.Fields.Add("Currency");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	
	ConfigurationModule.NewFilter(OrGroup, "RebateKind", Catalogs.VendorRebateKinds.EmptyRef());
	ConfigurationModule.NewFilter(OrGroup, "WithoutCalculation", True);
	ConfigurationModule.NewFilter(OrGroup, "BonusType", TypesOfBonuses.Balance);
	
	InclBaseBasePrices = New ValueList; // ValueList of EnumRef.RebateCalculationBases
	InclBaseBasePrices.Add(SalesDatabase.RevenueBasePrices);
	InclBaseBasePrices.Add(SalesDatabase.PurchaseAmountBasePrices);
	
	ConfigurationModule.NewFilter(
		OrGroup, 
		"More.BaseOfCalculation",
		InclBaseBasePrices,
		, 
		DataCompositionComparisonType.InList);
		
	AndGroup = RebatesServer.NewFiltersGroup(OrGroup, DataCompositionFilterItemsGroupType.AndGroup);
	
	ConfigurationModule.NewFilter(
		AndGroup,
		"More.GoodsIndicator",
		TargetValues.Sum);
		
	ConfigurationModule.NewFilter(
		AndGroup, 
		"More.BaseOfCalculation",
		InclDatabaseOfMutualSettlements,
		, 
		DataCompositionComparisonType.InList);
		
	ConfigurationModule.NewFilter(Item.Condition, "Patch", False);
	
	Item.Properties.Insert("ReadOnly", False);
	#EndRegion
	
EndProcedure

Procedure SettingUpBonusPercentageField(Settings, ConfigurationModule)
	
	#Region Visible
	Item = Settings.Add();
	
	Item.Fields.Add("BonusPercent");
	
	ConfigurationModule.NewFilter(Item.Condition, "CalculationScaleType", 0); // The only value
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	
	AndGroup = RebatesServer.NewFiltersGroup(OrGroup, DataCompositionFilterItemsGroupType.AndGroup);
	ConfigurationModule.NewFilter(AndGroup, "WithoutCalculation", False);
	ConfigurationModule.NewFilter(
		AndGroup,
		"FilterOfProducts_",
		Enums.RebatesLists.Selected_,
		,
		DataCompositionComparisonType.NotEqual);
		
	ConfigurationModule.NewFilter(
		OrGroup,
		"More.ContentOfGoods",
		Enums.RebatesItems.ProductSegments);
	
	AndGroup = RebatesServer.NewFiltersGroup(OrGroup, DataCompositionFilterItemsGroupType.AndGroup);
	ConfigurationModule.NewFilter(
		AndGroup,
		"More.GoodsIndicator",
		Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum);
	ConfigurationModule.NewFilter(AndGroup, "RestrictAccrualOverPlan", True);
	
	Item.Properties.Insert("Visible", True);
	#EndRegion
	
	#Region ReadOnly
	Item = Settings.Add();
	
	Item.Fields.Add("BonusPercent");
	
	ConfigurationModule.NewFilter(Item.Condition, "Patch", True);
	
	Item.Properties.Insert("ReadOnly", True);
	#EndRegion
	
EndProcedure

Procedure SettingUpFieldSelectionOfParticipants(Settings, ConfigurationModule)
	
	#Region Visible
	Item = Settings.Add();
	
	Item.Fields.Add("FilterParties");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.NewFilter(OrGroup, "RebateKind", Catalogs.VendorRebateKinds.EmptyRef());
	ConfigurationModule.NewFilter(
		OrGroup,
		"BonusType",
		Enums.VendorRebateTypes.Sales,
		,
		DataCompositionComparisonType.NotEqual);
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
	#Region ReadOnly
	Item = Settings.Add();
	
	Item.Fields.Add("FilterParties");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.NewFilter(OrGroup, "Patch", True);
	ConfigurationModule.NewFilter(OrGroup, "WithoutCalculation", True);
	
	Item.Properties.Insert("ReadOnly", True);
	#EndRegion
	
EndProcedure

Procedure SettingUpSelectionOfGoodsField(Settings, ConfigurationModule)
	
	SalesDatabases = Enums.RebateCalculationBases;
	GoodsIndicators = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	
	#Region Visible	
	Item = Settings.Add();
	
	Item.Fields.Add("FilterOfProducts_");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.NewFilter(OrGroup, "RebateKind", Catalogs.VendorRebateKinds.EmptyRef());
	ConfigurationModule.NewFilter(OrGroup, "WithoutCalculation", True);
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
	#Region ReadOnly
	Item = Settings.Add();
	
	Item.Fields.Add("FilterOfProducts_");
	
	AndGroup = RebatesServer.NewFiltersGroup(Item.Condition, DataCompositionFilterItemsGroupType.AndGroup);
	ConfigurationModule.NewFilter(AndGroup, "Patch", False);
	ConfigurationModule.NewFilter(AndGroup, "WithoutCalculation", False);
	ConfigurationModule.NewFilter(
		AndGroup,
		"BonusType",
		Enums.VendorRebateTypes.Balance,
		,
		DataCompositionComparisonType.NotEqual);
	
	ExclusiveIndicatorsOfGoods = New ValueList; // ValueList of EnumRef.TargetSalesIndicatorsOfRebatesByGoods
	ExclusiveIndicatorsOfGoods.Add(GoodsIndicators.NotUsed);
	ExclusiveIndicatorsOfGoods.Add(GoodsIndicators.Sum);
	ConfigurationModule.NewFilter(
		AndGroup, "More.GoodsIndicator", ExclusiveIndicatorsOfGoods,, DataCompositionComparisonType.InList);
	
	ExclusiveIndicatorsOfSalesBase = New ValueList; // ValueList of EnumRef.RebateCalculationBases
	ExclusiveIndicatorsOfSalesBase.Add(SalesDatabases.RevenueBasePrices);
	ExclusiveIndicatorsOfSalesBase.Add(SalesDatabases.PurchaseAmountBasePrices);
	ExclusiveIndicatorsOfSalesBase.Add(SalesDatabases.EmptyRef());
	
	ConfigurationModule.NewFilter(AndGroup, "More.BaseOfCalculation", ExclusiveIndicatorsOfSalesBase,, DataCompositionComparisonType.NotInList);
	
	Item.Properties.Insert("ReadOnly", False);
	#EndRegion
	
EndProcedure

Procedure SettingUpConditionTimeFenceField(Settings, ConfigurationModule)
	
	GoodsIndicators = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	
	#Region Visible
	Item = Settings.Add();
	
	Item.Fields.Add("ConditionFrequency");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.NewFilter(OrGroup, "RebateKind", Catalogs.VendorRebateKinds.EmptyRef());
	ConfigurationModule.NewFilter(
		OrGroup,
		"BonusType",
		Enums.VendorRebateTypes.Balance);
	ConfigurationModule.NewFilter(OrGroup, "More.GoodsIndicator", GoodsIndicators.NotUsed);
	
	ConfigurationModule.NewFilter(OrGroup, "WithoutCalculation", True);
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
	#Region ReadOnly
	Item = Settings.Add();
	
	Item.Fields.Add("ConditionFrequency");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.NewFilter(OrGroup, "Patch", True);
	ConfigurationModule.NewFilter(OrGroup, "AccrueImmediately", True);
	
	Item.Properties.Insert("ReadOnly", True);
	#EndRegion
	
EndProcedure

Procedure SettingUpAccrualTimeFenceField(Settings, ConfigurationModule)
	
	TypesOfBonuses = Enums.VendorRebateTypes;
	
	#Region Visible
	Item = Settings.Add();
	
	Item.Fields.Add("AccrualFrequency");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	
	ConfigurationModule.NewFilter(
		OrGroup, "RebateKind", Catalogs.VendorRebateKinds.EmptyRef());
	ConfigurationModule.NewFilter(OrGroup, "BonusType", TypesOfBonuses.Balance);
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
	#Region ReadOnly
	Item = Settings.Add();
	
	Item.Fields.Add("AccrualFrequency");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.NewFilter(OrGroup, "Patch", True);
	ConfigurationModule.NewFilter(OrGroup, "WithoutCalculation", True);
	ConfigurationModule.NewFilter(OrGroup, "BonusType", Enums.VendorRebateTypes.Balance);
	
	Item.Properties.Insert("ReadOnly", True);
	#EndRegion
	
EndProcedure

Procedure SettingUpAddImmediatelyField(Settings, ConfigurationModule);
	
	Item = Settings.Add();
	
	Item.Fields.Add("AccrueImmediately");
	
	ConfigurationModule.NewFilter(Item.Condition, "Patch", False);
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.NewFilter(OrGroup, "WithoutCalculation", True);
	ConfigurationModule.NewFilter(OrGroup, "BonusType", Enums.VendorRebateTypes.Balance);
	
	Item.Properties.Insert("Visible", True);
	
EndProcedure

Procedure SettingUpAmountPlanField(Settings, ConfigurationModule)
	
	GoodsIndicators = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	
	#Region Visible
	Item = Settings.Add();
	
	Item.Fields.Add("SumPlan");
	
	ConfigurationModule.NewFilter(Item.Condition, "More.GoodsIndicator", GoodsIndicators.Sum);
	ConfigurationModule.NewFilter(Item.Condition, "CalculationScaleType", 0); // One value
	
	Item.Properties.Insert("Visible", True);
	#EndRegion
	
	#Region ReadOnly
	Item = Settings.Add();
	
	Item.Fields.Add("SumPlan");
	
	ConfigurationModule.NewFilter(Item.Condition, "More.GoodsIndicator", GoodsIndicators.Sum);
	ConfigurationModule.NewFilter(Item.Condition, "More.ThereAreAccruals", True);
	
	Item.Properties.Insert("ReadOnly", True);
	#EndRegion
	
EndProcedure

Procedure SettingUpFieldProhibitingAccrualsOverPlan(Settings, ConfigurationModule)
	
	GoodsIndicators = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	
	#Region Visible
	Item = Settings.Add();
	
	Item.Fields.Add("RestrictAccrualOverPlan");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.NewFilter(OrGroup, "RebateKind", Catalogs.VendorRebateKinds.EmptyRef());
	ConfigurationModule.NewFilter(OrGroup, "WithoutCalculation", True);
	
	ExclIndicators = New ValueList; // ValueList of EnumRef.TargetSalesIndicatorsOfRebatesByGoods
	ExclIndicators.Add(GoodsIndicators.Count);
	ExclIndicators.Add(GoodsIndicators.Sum);
	ConfigurationModule.NewFilter(
		OrGroup, "More.GoodsIndicator", ExclIndicators,, DataCompositionComparisonType.NotInList);
	
	AndGroup = RebatesServer.NewFiltersGroup(OrGroup, DataCompositionFilterItemsGroupType.AndGroup);
	ConfigurationModule.NewFilter(AndGroup, "More.GoodsIndicator", GoodsIndicators.Sum);
	ConfigurationModule.NewFilter(AndGroup, "CalculationScaleType", 2); // By Ranges
	
	AndGroup = RebatesServer.NewFiltersGroup(OrGroup, DataCompositionFilterItemsGroupType.AndGroup);
	ConfigurationModule.NewFilter(AndGroup, "More.GoodsIndicator", GoodsIndicators.Count);
	ConfigurationModule.NewFilter(AndGroup, "CalculationScaleType", 1); // By Ranges
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
	#Region ReadOnly
	Item = Settings.Add();
	
	Item.Fields.Add("RestrictAccrualOverPlan");
	
	ConfigurationModule.NewFilter(Item.Condition, "Patch", True);
	
	Item.Properties.Insert("ReadOnly", True);
	#EndRegion
	
EndProcedure

Procedure SettingUpBalanceDateField(Settings, ConfigurationModule)
	
	TypesOfBonuses = Enums.VendorRebateTypes;
	
	#Region Visible
	Item = Settings.Add();
	
	Item.Fields.Add("DateOfRemainingGoods");
	
	ConfigurationModule.NewFilter(
		Item.Condition,
		"BonusType",
		TypesOfBonuses.Balance,
		,
		DataCompositionComparisonType.NotEqual);
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
EndProcedure

Procedure SettingUpPeriodFields(Settings, ConfigurationModule)
	
	TypesOfBonuses = Enums.VendorRebateTypes;
	
	#Region Visible
	Item = Settings.Add();
	
	Item.Fields.Add("ValidOnDate");
	Item.Fields.Add("ValidTo");
	Item.Fields.Add("SetDateInterval");
	
	ConfigurationModule.NewFilter(
		Item.Condition,
		"BonusType",
		TypesOfBonuses.Balance,
		,
		DataCompositionComparisonType.Equal);
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
	#Region ReadOnly
	Item = Settings.Add();
	
	Item.Fields.Add("ValidOnDate");
	
	ConfigurationModule.NewFilter(Item.Condition, "Patch", True);
	
	Item.Properties.Insert("ReadOnly", True);
	#EndRegion
	
	#Region Enabled
	Item = Settings.Add();
	
	Item.Fields.Add("SetDateInterval");
	
	ConfigurationModule.NewFilter(Item.Condition, "Patch", True);
	
	Item.Properties.Insert("Enabled", False);
	#EndRegion

EndProcedure

Procedure SettingUpWarehouseSelectionField(Settings, ConfigurationModule)
	
	TypesOfBonuses = Enums.VendorRebateTypes;
	
	#Region Visible
	Item = Settings.Add();
	
	Item.Fields.Add("SelectionOfWarehouses_");
	
	ConfigurationModule.NewFilter(Item.Condition, "BonusType", TypesOfBonuses.Balance);
	ConfigurationModule.NewFilter(Item.Condition, "AccrueImmediately", False);
	ConfigurationModule.NewFilter(Item.Condition, "More.UseSeveralWarehouses", True);
	
	Item.Properties.Insert("Visible", True);
	#EndRegion
	
	#Region ReadOnly
	Item = Settings.Add();
	
	Item.Fields.Add("SelectionOfWarehouses_");
	
	ConfigurationModule.NewFilter(Item.Condition, "Patch", True);
	
	Item.Properties.Insert("ReadOnly", True);
	#EndRegion
	
EndProcedure

Procedure SettingUpBonusAmountField(Settings, ConfigurationModule)
	
	#Region Visible
	Item = Settings.Add();
	
	Item.Fields.Add("AmountBonus");
	
	ConfigurationModule.NewFilter(
		Item.Condition,
		"WithoutCalculation",
		False);
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
	#Region ReadOnly
	Item = Settings.Add();
	
	Item.Fields.Add("AmountBonus");
	
	ConfigurationModule.NewFilter(Item.Condition, "Patch", True);
	
	Item.Properties.Insert("ReadOnly", True);
	#EndRegion
	
EndProcedure

Procedure SettingUpModeMultipleVendorsField(Settings, ConfigurationModule)
	
	TypesOfBonuses = Enums.VendorRebateTypes;
	
	#Region Visible
	Item = Settings.Add();
	
	Item.Fields.Add("ModeMultipleVendors");
	
	ConfigurationModule.NewFilter(
		Item.Condition,
		"BonusType",
		TypesOfBonuses.Purchases,
		,
		DataCompositionComparisonType.NotEqual);
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
EndProcedure

Procedure SettingUpAgreementField(Settings, ConfigurationModule)
	
	TypesOfBonuses = Enums.VendorRebateTypes;
	
	#Region Visible
	Item = Settings.Add();
	
	Item.Fields.Add("Terms");
	
	ConfigurationModule.NewFilter(
		Item.Condition,
		"BonusType",
		TypesOfBonuses.Purchases,
		,
		DataCompositionComparisonType.NotEqual);
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
	#Region ReadOnly
	Item = Settings.Add();
	
	Item.Fields.Add("Terms");
	
	ConfigurationModule.NewFilter(Item.Condition, "Patch", True);
	
	Item.Properties.Insert("ReadOnly", True);
	#EndRegion
	
EndProcedure

Procedure SettingUpContractField(Settings, ConfigurationModule)
	
	#Region ReadOnly
	Item = Settings.Add();
	
	Item.Fields.Add("Contract");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.NewFilter(
		OrGroup,
		"Patch",
		True);
	
	AndGroup = RebatesServer.NewFiltersGroup(OrGroup, DataCompositionFilterItemsGroupType.AndGroup);
	
	ConfigurationModule.NewFilter(
		AndGroup,
		"More.ContractsAreUsed",
		False);
		
	ConfigurationModule.NewFilter(
		AndGroup,
		"Terms", 
		Catalogs.TermsOfPurchaseFromVendors.EmptyRef(),
		,
		DataCompositionComparisonType.NotEqual);
	
	Item.Properties.Insert("ReadOnly", True);
	#EndRegion
	
EndProcedure

Procedure SettingUpCounterpartyField(Settings, ConfigurationModule)
	
	#Region ReadOnly
	Item = Settings.Add();
	
	Item.Fields.Add("Counterparty");
	
	ConfigurationModule.NewFilter(Item.Condition, "Patch", True);
	
	Item.Properties.Insert("ReadOnly", True);
	#EndRegion
	
EndProcedure

Procedure SettingUpPartnerField(Settings, ConfigurationModule)
	
	#Region ReadOnly
	Item = Settings.Add();
	
	Item.Fields.Add("Partner");
	
	ConfigurationModule.NewFilter(Item.Condition, "Patch", True);
	
	Item.Properties.Insert("ReadOnly", True);
	#EndRegion
	
EndProcedure

Procedure SettingUpSegmentFixingCommands(Settings, ConfigurationModule)
	
	#Region Visible
	
	Item = Settings.Add();
	
	Item.Fields.Add("DecorationFixComposition");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	
	ConfigurationModule.NewFilter(
		OrGroup,
		"Status",
		Enums.RebatesDocumentStatuses.Approved,
		,
		DataCompositionComparisonType.NotEqual);
	ConfigurationModule.NewFilter(OrGroup, "More.ThereIsRightToChangeURB", False);
	ConfigurationModule.NewFilter(OrGroup, "More.CompositionFixationIsAvailable", False);
	ConfigurationModule.NewFilter(OrGroup, "More.CompositionOfSegmentsIsFixed", True);
	
	Item.Properties.Insert("Visible", False);
	
	Item = Settings.Add();
	
	Item.Fields.Add("DecorationIsToCancelFixationOfComposition");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	
	ConfigurationModule.NewFilter(
		OrGroup,
		"Status",
		Enums.RebatesDocumentStatuses.Approved,
		,
		DataCompositionComparisonType.NotEqual);
	ConfigurationModule.NewFilter(OrGroup, "More.ThereIsRightToChangeURB", False);
	ConfigurationModule.NewFilter(OrGroup, "More.CompositionFixationIsAvailable", False);
	ConfigurationModule.NewFilter(OrGroup, "More.CompositionOfSegmentsIsFixed", False);
	
	Item.Properties.Insert("Visible", False);
	
	#EndRegion
	
EndProcedure

Procedure ConfiguringProviderData(Settings, ConfigurationModule)
	
	TypesOfBonuses = Enums.VendorRebateTypes;
	
	#Region AutoMarkIncomplete
	Item = Settings.Add();
	
	Item.Fields.Add("Counterparty");
	Item.Fields.Add("Partner");
	
	ConfigurationModule.NewFilter(
		Item.Condition,
		"BonusType",
		TypesOfBonuses.Purchases,
		,
		DataCompositionComparisonType.Equal);
	
	Item.Properties.Insert("AutoMarkIncomplete", False);
	#EndRegion
	
EndProcedure

Procedure SettingUpCalculationScaleGroupField(Settings, ConfigurationModule)
	
	#Region Visible
	Item = Settings.Add();
	
	Item.Fields.Add("GroupCalculationScale");
	
	ConfigurationModule.NewFilter(
		Item.Condition,
		"RebateKind",
		Catalogs.CustomerRebatesKinds.EmptyRef(),
		,
		DataCompositionComparisonType.NotEqual);
	
	ConfigurationModule.NewFilter(
		Item.Condition,
		"More.GoodsIndicator",
		Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum);
	
	ConfigurationModule.NewFilter(Item.Condition, "CalculationScaleType", 0,, DataCompositionComparisonType.NotEqual); // One value
	
	Item.Properties.Insert("Visible", True);
	#EndRegion
	
EndProcedure

#EndRegion


#Region Other

// Parameters:
//  TermDocument - DocumentRef.ConditionsOfVendorRebates
// 
// Returns:
//  Structure - Payment Data With The Supplier:
// * ResultConditionData - QueryResultSelection:
//  ** ValidOnDate - Date
//  ** ValidTo - Date
//  ** BonusType - EnumRef.VendorRebateTypes
//  ** AccrualFrequency - EnumRef.RebatesFrequencies
// * ResultResults - ValueTable:
//  ** Currency - CatalogRef.Currencies
//  ** AccruedBonusesAreFullyActivated - Boolean
//  ** RepaymentIsMoreThanAccrual - Boolean
//  ** ActIsExpected - Boolean
// * ResultPeriods - ValueTable:
//  ** BeginOfPeriod - Date
//  ** PeriodEnding - Date
//
Function PaymentDataWithSupplier(TermDocument)
	
	Query = New Query;
	Query.SetParameter("TermDocument", TermDocument);
	Query.Text =
	"SELECT
	|	VendorRebates.Currency AS Currency,
	|	VendorRebates.BeginOfPeriod AS BeginOfPeriod,
	|	VendorRebates.PeriodEnding AS PeriodEnding,
	|	CASE
	|		WHEN VendorRebates.TypeOfRegisterMovement = VALUE(Enum.AccumulationRecordTypes.Receipt)
	|			THEN VendorRebates.AccruedTurnover
	|		ELSE 0
	|	END AS Accrued,
	|	CASE
	|		WHEN VendorRebates.TypeOfRegisterMovement = VALUE(Enum.AccumulationRecordTypes.Expense)
	|			THEN VendorRebates.ToWriteOffTurnover + VendorRebates.WrittenOffTurnover + VendorRebates.CertifiedTurnover
	|		ELSE 0
	|	END AS Repaid_
	|INTO TT_Calculations
	|FROM
	|	AccumulationRegister.VendorRebates.Turnovers(, , , TermDocument = &TermDocument) AS VendorRebates
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TT_Calculations.BeginOfPeriod AS BeginOfPeriod,
	|	TT_Calculations.PeriodEnding AS PeriodEnding
	|FROM
	|	TT_Calculations AS TT_Calculations
	|WHERE
	|	TT_Calculations.Accrued > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_Calculations.Currency AS Currency,
	|	SUM(TT_Calculations.Accrued) > 0 AND SUM(TT_Calculations.Accrued) = SUM(TT_Calculations.Repaid_) AS AccruedBonusesAreFullyActivated,
	|	SUM(TT_Calculations.Accrued) < SUM(TT_Calculations.Repaid_) AS RepaymentIsMoreThanAccrual,
	|	SUM(TT_Calculations.Accrued) > SUM(TT_Calculations.Repaid_) AS ActIsExpected
	|FROM
	|	TT_Calculations AS TT_Calculations
	|
	|GROUP BY
	|	TT_Calculations.Currency
	|
	|HAVING
	|	(SUM(TT_Calculations.Accrued) <> 0
	|		OR SUM(TT_Calculations.Repaid_) <> 0)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VendorRebatesConditions.ValidOnDate AS ValidOnDate,
	|	VendorRebatesConditions.ValidTo AS ValidTo,
	|	VendorRebatesConditions.BonusType AS BonusType,
	|	VendorRebatesConditions.AccrualFrequency AS AccrualFrequency
	|FROM
	|	InformationRegister.VendorRebatesConditions AS VendorRebatesConditions
	|WHERE
	|	VendorRebatesConditions.TermDocument = &TermDocument";
	
	QueryResult = Query.ExecuteBatch(); // QueryResult
	ResultOfBorderRequest = QueryResult.UBound();
	ResultConditionData = QueryResult[ResultOfBorderRequest].Select();
	ResultResults = QueryResult[ResultOfBorderRequest - 1].Unload();
	ResultPeriods = QueryResult[ResultOfBorderRequest - 2].Unload();
	
	Result = New Structure;
	Result.Insert("ResultConditionData", ResultConditionData);
	Result.Insert("ResultResults", ResultResults);
	Result.Insert("ResultPeriods", ResultPeriods);
	
	Return Result;
	
EndFunction

Function ThereAreGapsInPeriods(ValidOnDate, ValidTo, TableOfAccrualPeriods)
	
	ThereArePeriodsWithoutAccruals = False;
	
	If TableOfAccrualPeriods.Count() > 0 Then
		
		ArrayBeginningOfPeriod = TableOfAccrualPeriods.UnloadColumn("BeginOfPeriod");
		EndOfPeriodArray = TableOfAccrualPeriods.UnloadColumn("PeriodEnding");
		
		BeginningOfAccrualPeriod = MinimumValueInArray(ArrayBeginningOfPeriod);
		EndOfAccrualPeriod = MaxValueInArray(EndOfPeriodArray);
		
		If BeginningOfAccrualPeriod > ValidOnDate
		 Or EndOfAccrualPeriod < ValidTo Then
			
			ThereArePeriodsWithoutAccruals = True;
			
		Else
			
			TableOfAccrualPeriods.Sort("BeginOfPeriod Asc, PeriodEnding Asc");
			CurrentReferenceDate = ValidOnDate;
			
			For Each CurrentPeriod In TableOfAccrualPeriods Do
				
				If EndOfDay(CurrentReferenceDate) + 1 >= BegOfDay(CurrentPeriod.BeginOfPeriod) Then
					
					CurrentReferenceDate = Max(CurrentPeriod.PeriodEnding, CurrentReferenceDate);
					
				Else
					
					Break;
					
				EndIf;
				
			EndDo;
			
			ThereArePeriodsWithoutAccruals = (CurrentReferenceDate < ValidTo);
			
		EndIf;
		
	Else
		
		ThereArePeriodsWithoutAccruals = True;
		
	EndIf;
	
	Return ThereArePeriodsWithoutAccruals;
	
EndFunction

// Parameters:
//  Array - Array of Date
// 
// Returns:
//  Date
//
Function MaxValueInArray(Array)
	
	If Array.Count() = 0 Then
		Return Date(1, 1, 1);
	EndIf;
	
	ListOfDates_ = New ValueList;
	ListOfDates_.LoadValues(Array);
	ListOfDates_.SortByValue(SortDirection.Desc);
	
	Return ListOfDates_[0].Value;
	
EndFunction

// Parameters:
//  Array - Array of Date
// 
// Returns:
//  Date 
//  Undefined
//
Function MinimumValueInArray(Array)
	
	If Array.Count() = 0 Then
		Return Date(3999, 12, 31, 23, 59, 59);
	EndIf;
	
	ListOfDates_ = New ValueList;
	ListOfDates_.LoadValues(Array);
	ListOfDates_.SortByValue(SortDirection.Asc);
	
	Return ListOfDates_[0].Value;
	
EndFunction

Procedure ClearUnusedAttributesOfCounterpartiesOfClients(Object, Val Parameters)
	
	If Parameters.FilterParties = Enums.RebatesLists.All
	 Or Parameters.PartyList <> Enums.RebatesParticipants.Counterparties Then
		
		Object.CustomerCounterparties.Clear();
		Return;
		
	EndIf;
	
	DateEmpty = Date(1, 1, 1);
	ExceptForSelectedOnes = (Parameters.FilterParties = Enums.RebatesLists.ExceptForSelectedOnes);
	
	For Each TSRow In Object.CustomerCounterparties Do
		
		If Not Object.Patch Then
			
			TSRow.Canceled = False;
			TSRow.InitialString = False;
			
		EndIf;
		
		If Not TSRow.InitialString Then
			
			TSRow.StartDateBeforeChange = DateEmpty; 
			TSRow.EndDateBeforeChange = DateEmpty;
			
		EndIf;
		
		If ExceptForSelectedOnes Then
			
			TSRow.ValidOnDate = DateEmpty;
			TSRow.ValidTo = DateEmpty;
			TSRow.StartDateBeforeChange = DateEmpty;
			TSRow.EndDateBeforeChange = DateEmpty;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure ClearUnusedAttributesOfINNOfCounterpartiesOfClients(Object, Val Parameters)
	
	If Parameters.FilterParties = Enums.RebatesLists.All
	 Or Parameters.PartyList <> Enums.RebatesParticipants.TIN Then
		
		Object.ClientsCounterpartiesTIN.Clear();
		Return;
		
	EndIf;
	
	DateEmpty = Date(1, 1, 1);
	ExceptForSelectedOnes = (Parameters.FilterParties = Enums.RebatesLists.ExceptForSelectedOnes);
	
	For Each TSRow In Object.ClientsCounterpartiesTIN Do
		
		If Not Object.Patch Then
			
			TSRow.Canceled = False;
			TSRow.InitialString = False;
			
		EndIf;
		
		If Not TSRow.InitialString Then
			
			TSRow.StartDateBeforeChange = DateEmpty; 
			TSRow.EndDateBeforeChange = DateEmpty;
			
		EndIf;
		
		If ExceptForSelectedOnes Then
			
			TSRow.ValidOnDate = DateEmpty;
			TSRow.ValidTo = DateEmpty;
			TSRow.StartDateBeforeChange = DateEmpty;
			TSRow.EndDateBeforeChange = DateEmpty;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure FillInResultBasedOnResultsOfCheck(Result, ResultResults)
	
	If Not Result.ThereArePeriodsWithoutAccruals Then
		
		If ResultResults.Count() > 1 Then
			
			ResultSummaryResults = ResultResults.Copy();
			Columns = "AccruedBonusesAreFullyActivated, RepaymentIsMoreThanAccrual, ActIsExpected";
			ResultSummaryResults.GroupBy(Columns);
			
			If ResultSummaryResults.Count() > 1 Then
				
				Result.DifferentStates_ = True;
				
			Else
				
				FillPropertyValues(Result, ResultSummaryResults[0]);
				
			EndIf;
			
		Else
			
			FillPropertyValues(Result, ResultResults[0]);
			
		EndIf;
		
	Else
		
		Result.AccrualIsExpected = True;
		
	EndIf;
	
EndProcedure

Procedure ClearUnusedItemTableAttributes(Object, Parameters, Val DataTable)
	
	DateEmpty = Date(1, 1, 1);
	GoodsIndicators = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	PercentageOnScale =
		(Parameters.GoodsIndicator = GoodsIndicators.Sum
		 And Object.CalculationScaleType <> 0);
	ProhibitionOfExceedingAmount =
		(Parameters.GoodsIndicator = GoodsIndicators.Sum
		 And Object.RestrictAccrualOverPlan);
	TheseAreGoodsByRanges = RebatesClientServer.ThisIsNumberByRanges(
		Object.CalculationScaleType, Parameters.GoodsIndicator);
	
	For Each TSRow In DataTable Do
			
		If Not Object.Patch Then
			
			TSRow.Canceled = False;
			TSRow.InitialString = False;
			
		EndIf;
		
		If Not TSRow.InitialString Then
			
			TSRow.StartDateBeforeChange = DateEmpty; 
			TSRow.EndDateBeforeChange = DateEmpty;
			
		EndIf;
		
		If Parameters.FilterOfProducts_ <> Enums.RebatesLists.Selected_
		 Or ProhibitionOfExceedingAmount
		 Or Parameters.BonusType = Enums.VendorRebateTypes.Balance
		 Or (Parameters.FilterOfProducts_ = Enums.RebatesLists.Selected_
		      And PercentageOnScale) Then
			
			TSRow.Percent = 0;
			
		EndIf;
		
		If Parameters.FilterOfProducts_ = Enums.RebatesLists.ExceptForSelectedOnes Then
			
			TSRow.CountPlan = 0;
			TSRow.BasePrice = 0;
			
		EndIf;
		
		If Parameters.FilterOfProducts_ = Enums.RebatesLists.ExceptForSelectedOnes
		 Or Parameters.BonusType = Enums.VendorRebateTypes.Balance
		 Or Not RebatesClientServer.PeriodOfGoodsConditionsIsUsed(Parameters.GoodsIndicator) Then
			
			TSRow.ValidOnDate = DateEmpty;
			TSRow.StartDateBeforeChange = DateEmpty;
			TSRow.ValidTo = DateEmpty;
			TSRow.EndDateBeforeChange = DateEmpty;
			
		EndIf;
		
		If Parameters.ContentOfGoods <> Enums.RebatesItems.ProductItemProperty
		   And (Parameters.BonusType <> Enums.VendorRebateTypes.Balance
		      Or Parameters.FilterOfProducts_ = Enums.RebatesLists.ExceptForSelectedOnes) Then
			
			TSRow.BonusPerUnit = 0;
			TSRow.AmountBonus = 0;
			
		EndIf;
		
		If Parameters.FilterOfProducts_ = Enums.RebatesLists.Selected_ Then
			
			If Parameters.BonusType <> PredefinedValue("Enum.VendorRebateTypes.Balance")
			   And (Parameters.GoodsIndicator <> GoodsIndicators.Count
				  And Parameters.GoodsIndicator <> GoodsIndicators.QuantityTotal
				  And Parameters.GoodsIndicator <> GoodsIndicators.BatchOffer) Then
				
				TSRow.CountPlan = 0;
				
			EndIf;
			
			If Parameters.BaseOfCalculation <> Enums.RebateCalculationBases.RevenueBasePrices
			   And Parameters.BaseOfCalculation <> Enums.RebateCalculationBases.PurchaseAmountBasePrices Then
				
				TSRow.BasePrice = 0;
				
			EndIf;
			
			If Parameters.BonusType = PredefinedValue("Enum.VendorRebateTypes.Balance")
			   And Not Parameters.AccrueImmediately Then
				
				TSRow.AmountBonus = 0;
				
			EndIf;
			
		EndIf;
		
		If Not TheseAreGoodsByRanges Then
			
			TSRow.QuantityPlanRangeBound = 0;
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region DownloadingFromFiles

// Returns:
//  Structure - Goods Data Line:
// * Products - CatalogRef.Products - 
// * Characteristic - CatalogRef.ItemsCharacteristics -
// 
Function GoodsDataLine();
	
	DataString1 = New Structure;
	DataString1.Insert("Products", Catalogs.Products.EmptyRef());
	DataString1.Insert("Characteristic", Catalogs.ItemsCharacteristics.EmptyRef());
	
	Return DataString1;
	
EndFunction

// Parameters:
//  ConflictsList - Array of CatalogRef.Products
//  LoadedValuesString - ValueTableRow:
//  * NomenclatureName - String
//  * SKU - String
//  * Code - String
//
Procedure FillInListOfNomenclatureAmbiguities(ConflictsList, LoadedValuesString)
	
	Query = New Query;
	
	TermsAndConditions_ = New Array; // Array of String
	
	If ValueIsFilled(LoadedValuesString.NomenclatureName) Then
		
		ConditionText =
		"(Products.Description = &Description
		| OR Products.DescriptionFull = &Description)";
		
		TermsAndConditions_.Add(ConditionText);
		Query.SetParameter("Description", LoadedValuesString.NomenclatureName);
		
	EndIf;
	
	If ValueIsFilled(LoadedValuesString.SKU) Then
		
		ConditionText =
		"Products.SKU = &SKU";
		TermsAndConditions_.Add(ConditionText);
		Query.SetParameter("SKU", LoadedValuesString.SKU);
		
	EndIf;
	
	If ValueIsFilled(LoadedValuesString.Code) Then
		
		ConditionText =
		"Products.Code = &Code";
		
		TermsAndConditions_.Add(ConditionText);
		Query.SetParameter("Code", LoadedValuesString.Code);
		
	EndIf;
	
	TextAnd = Chars.LF + "AND "; //@query-part
	
	QueryText =
	"SELECT
	|	Products.Ref AS Ref
	|FROM
	|	Catalog.Products AS Products
	|WHERE
	|	NOT Products.DeletionMark";
	
	If TermsAndConditions_.Count() > 0 Then
		
		FullTextOfTermsAndConditions = StrConcat(TermsAndConditions_, TextAnd);
		QueryText = QueryText + TextAnd + FullTextOfTermsAndConditions;
		
	EndIf;
	
	Query.Text = QueryText;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		ConflictsList.Add(Selection.Ref);
		
	EndDo;
	
EndProcedure

// Parameters:
//  ConflictsList - Array of CatalogRef.ItemsCharacteristics
//  LoadedValuesString - ValueTableRow:
//  * CharacteristicName - String
//
Procedure FillInListOfAmbiguitiesOfCharacteristic(ConflictsList, LoadedValuesString)
	
	If Not ValueIsFilled(LoadedValuesString.CharacteristicName) Then
		Return;
	EndIf;
	
	Query = New Query;
	
	Query.SetParameter("Description", LoadedValuesString.CharacteristicName);
	
	QueryText =
	"SELECT
	|	Characteristics.Ref AS Ref
	|FROM
	|	Catalog.ItemsCharacteristics AS Characteristics
	|WHERE
	|	NOT Characteristics.DeletionMark
	|	AND Characteristics.Owner REFS Catalog.Products
	|	AND Characteristics.Description = &Description
	|
	|UNION ALL
	|
	|SELECT
	|	Characteristics.Ref AS Ref
	|FROM
	|	Catalog.ItemsCharacteristics AS Characteristics
	|WHERE
	|	NOT Characteristics.DeletionMark
	|	AND Characteristics.Owner REFS Catalog.Products
	|	AND Characteristics.Description <> &Description
	|	AND Characteristics.DescriptionFull = &Description";
	
	Query.Text = QueryText;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		ConflictsList.Add(Selection.Ref);
		
	EndDo;
	
EndProcedure

// Parameters:
//  DataToImport - ValueTable:
//  * NomenclatureName - String
//  * SKU - String
//  * Barcode - String
//  * Code - String
//  * CharacteristicName - String
//  * Id - Number
//  TableToFillIn_ - ValueTable, Arbitrary - Table To Fill In
//  AdditionalParameters - Structure:
//  * FieldDisplaySettings - Structure:
//  ** Characteristic - Boolean
//  ConflictsList - ValueTable - List of ambiguities:
// * Column - String
// * Id - Number
//
Procedure CompareDownloadedDataTSGoods(DataToImport, TableToFillIn_, AdditionalParameters, ConflictsList)
	
	InformationSecurityDataByNomenclature = InformationSecurityDataOnNomenclatureAndCharacteristics();
	BarcodeTable = InformationSecurityDataByBarcodes(DataToImport);
	
	FieldDisplaySettings = AdditionalParameters.FieldDisplaySettings;
	UseCharacteristics = FieldDisplaySettings.Characteristic;
	
	For Each DataString1 In DataToImport Do
		
		NewRow = TableToFillIn_.Add();
		FillPropertyValues(NewRow, DataString1);
		
		ItemDataAndCharacteristics = SelectItemBasedOnBankingDetails(
			DataString1,
			InformationSecurityDataByNomenclature,
			BarcodeTable,
			UseCharacteristics,
			ConflictsList);
		
		FillPropertyValues(NewRow, ItemDataAndCharacteristics);
		
	EndDo;
	
EndProcedure

// Returns:
//  Structure - Information Security Data On Nomenclature And Characteristics:
// * ProductsTable - ValueTable:
// ** Code - String 
// ** SKU - String 
// ** Description - String 
// ** DescriptionFull - String 
// ** Products - CatalogRef.Products 
// ** UseVariants - Boolean 
// ** SignificanceForFeatureSelection - EnumRef.ItemVariantsUsageOptions
// * CharacteristicTable - ValueTable:
// ** ItemVariantName - String 
// ** FullNameOfTheCharacteristic_3 - String 
// ** Characteristic - CatalogRef.ItemsCharacteristics 
// ** SignificanceForFeatureSelection - EnumRef.ItemVariantsUsageOptions
//
Function InformationSecurityDataOnNomenclatureAndCharacteristics()
	
	Result = New Structure;
	Result.Insert("ProductsTable", New ValueTable);
	Result.Insert("CharacteristicTable", New ValueTable);
	
	QueryText = 
	"SELECT ALLOWED
	|	Products.Ref AS Products,
	|	Products.Code AS Code,
	|	Products.SKU AS SKU,
	|	Products.Description AS Description,
	|	Products.DescriptionFull AS DescriptionFull,
	|	Products.UseVariants AS UseVariants,
	|	UNDEFINED AS SignificanceForFeatureSelection
	|INTO ProductsTable
	|FROM
	|	Catalog.Products AS Products
	|WHERE
	|	NOT Products.IsFolder
	|	AND NOT Products.DeletionMark
	|	AND Products.ItemsType IN (&SupportedItemTypes)
	|	AND Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.DontUse)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	Products.Ref,
	|	Products.Code,
	|	Products.SKU,
	|	Products.Description,
	|	Products.DescriptionFull,
	|	Products.UseVariants,
	|	Products.Ref
	|FROM
	|	Catalog.Products AS Products
	|		INNER JOIN Catalog.ItemsCharacteristics AS ItemsCharacteristics
	|		ON Products.Ref = ItemsCharacteristics.Owner
	|WHERE
	|	NOT Products.IsFolder
	|	AND NOT Products.DeletionMark
	|	AND Products.ItemsType IN (&SupportedItemTypes)
	|	AND Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
	|	AND NOT ItemsCharacteristics.DeletionMark
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	Products.Ref,
	|	Products.Code,
	|	Products.SKU,
	|	Products.Description,
	|	Products.DescriptionFull,
	|	Products.UseVariants,
	|	Products.ItemVariantsOwner
	|FROM
	|	Catalog.Products AS Products
	|		INNER JOIN Catalog.ItemsCharacteristics AS ItemsCharacteristics
	|		ON Products.ItemVariantsOwner = ItemsCharacteristics.Owner
	|WHERE
	|	NOT Products.IsFolder
	|	AND NOT Products.DeletionMark
	|	AND Products.ItemsType IN (&SupportedItemTypes)
	|	AND Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
	|	AND NOT ItemsCharacteristics.DeletionMark
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	Products.Ref,
	|	Products.Code,
	|	Products.SKU,
	|	Products.Description,
	|	Products.DescriptionFull,
	|	Products.UseVariants,
	|	Products.ProductKind
	|FROM
	|	Catalog.Products AS Products
	|		INNER JOIN Catalog.ItemsCharacteristics AS ItemsCharacteristics
	|		ON Products.ProductKind = ItemsCharacteristics.Owner
	|WHERE
	|	NOT Products.IsFolder
	|	AND NOT Products.DeletionMark
	|	AND Products.ItemsType IN (&SupportedItemTypes)
	|	AND Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
	|	AND NOT ItemsCharacteristics.DeletionMark
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ProductData_1.UseVariants AS UseVariants,
	|	ProductData_1.SignificanceForFeatureSelection AS SignificanceForFeatureSelection
	|INTO ParametersForSelectingCharacteristics
	|FROM
	|	ProductsTable AS ProductData_1
	|
	|INDEX BY
	|	SignificanceForFeatureSelection
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	FilterParameters.SignificanceForFeatureSelection AS SignificanceForFeatureSelection,
	|	ItemsCharacteristics.Ref AS Characteristic,
	|	ItemsCharacteristics.Description AS Description,
	|	ItemsCharacteristics.DescriptionFull AS DescriptionFull
	|INTO CharacteristicTable
	|FROM
	|	ParametersForSelectingCharacteristics AS FilterParameters
	|		INNER JOIN Catalog.ItemsCharacteristics AS ItemsCharacteristics
	|		ON FilterParameters.SignificanceForFeatureSelection = ItemsCharacteristics.Owner
	|		 AND FilterParameters.SignificanceForFeatureSelection <> UNDEFINED
	|		 AND NOT ItemsCharacteristics.DeletionMark
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Har.Characteristic.Description AS ItemVariantName,
	|	Har.Characteristic.DescriptionFull AS FullNameOfTheCharacteristic_3,
	|	Har.Characteristic AS Characteristic,
	|	Har.SignificanceForFeatureSelection AS SignificanceForFeatureSelection
	|FROM
	|	CharacteristicTable AS Har
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Nom.Code AS Code,
	|	Nom.SKU AS SKU,
	|	Nom.Description AS Description,
	|	Nom.DescriptionFull AS DescriptionFull,
	|	Nom.Products AS Products,
	|	Nom.UseVariants AS UseVariants,
	|	Nom.SignificanceForFeatureSelection AS SignificanceForFeatureSelection
	|FROM
	|	ProductsTable AS Nom";
		
	ItemsTypes = RebatesServer.SupportedItemTypes();
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("SupportedItemTypes", ItemsTypes);
	
	ResultsArray = Query.ExecuteBatch();
	
	QueryResult = ResultsArray[3]; // QueryResult
	
	Result.CharacteristicTable = QueryResult.Unload();
	
	TypesDetailsString = New TypeDescription("String");
	
	Result.CharacteristicTable.Columns.Add("NameOfTheSearchFeature", TypesDetailsString);
	Result.CharacteristicTable.Columns.Add("FullNameOfCharacteristicSearch", TypesDetailsString);
	
	FillInSearchFieldsByCharacteristic(Result.CharacteristicTable);
	
	QueryResult = ResultsArray[4]; // QueryResult
	
	Result.ProductsTable = QueryResult.Unload();
	
	Result.ProductsTable.Columns.Add("ProductIDSearch", TypesDetailsString);
	Result.ProductsTable.Columns.Add("NameSearch", TypesDetailsString);
	Result.ProductsTable.Columns.Add("FullNameSearch", TypesDetailsString);
	
	FillInSearchFieldsByItem(Result.ProductsTable);
	
	Return Result;
	
EndFunction

// Parameters:
//  ProductsTable - ValueTable:
//  * Code - String
//  * SKU - String
//  * Description - String
//  * DescriptionFull - String
//  * ProductIDSearch - String
//  * NameSearch - String
//  * FullNameSearch - String
//
Procedure FillInSearchFieldsByItem(ProductsTable)
	
	For Each ProductsRow In ProductsTable Do
		
		Code = StrReplace(ProductsRow.Code, " ", "");
		ProductsRow.Code = Upper(Code);
		
		ProductIDSearch = StrReplace(ProductsRow.SKU, " ", "");
		ProductsRow.ProductIDSearch = Upper(ProductIDSearch);
		
		NameSearch = StrReplace(ProductsRow.Description, " ", "");
		ProductsRow.NameSearch = Upper(NameSearch);
		
		FullNameSearch = StrReplace(ProductsRow.DescriptionFull, " ", "");
		ProductsRow.FullNameSearch = Upper(FullNameSearch);
		
	EndDo;
	
EndProcedure

// Parameters:
//  CharacteristicTable - ValueTable:
//  * ItemVariantName - String
//  * FullNameOfTheCharacteristic_3 - String
//  * NameOfTheSearchFeature - String
//  * FullNameOfCharacteristicSearch - String
//
Procedure FillInSearchFieldsByCharacteristic(CharacteristicTable)
	
	For Each FeatureLine In CharacteristicTable Do
		
		NameOfTheSearchFeature =
			StrReplace(FeatureLine.ItemVariantName, " ", "");
		FeatureLine.NameOfTheSearchFeature = Upper(NameOfTheSearchFeature);
		
		FullNameOfCharacteristicSearch =
			StrReplace(FeatureLine.FullNameOfTheCharacteristic_3, " ", "");
		FeatureLine.FullNameOfCharacteristicSearch =
			Upper(FullNameOfCharacteristicSearch);
		
	EndDo;
	
EndProcedure

Function InformationSecurityDataByBarcodes(DataTable)
	
	BarcodeData_ = BarcodeDataTable();
	
	Barcodes = TMCommonUse.UniqueValuesFromTableColumn(DataTable, "Barcode");
	
	CollectionItemsCount = Barcodes.Count();
	
	// Clearing empty values
	For ReverseIndex = 1 To CollectionItemsCount Do
		
		IndexOf = CollectionItemsCount - ReverseIndex;
		If Not ValueIsFilled(Barcodes[IndexOf]) Then
			Barcodes.Delete(IndexOf);
		EndIf;
		
	EndDo;
	
	If Barcodes.Count() > 0 Then
		
		QueryText =
		"SELECT
		|	ItemsBarcodes.Barcode AS Barcode,
		|	ItemsBarcodes.Products AS Products,
		|	ItemsBarcodes.Characteristic AS Characteristic,
		|	ItemsBarcodes.Package AS Package
		|FROM
		|	InformationRegister.ItemsBarcodes AS ItemsBarcodes
		|WHERE
		|	ItemsBarcodes.Barcode IN (&Barcodes)
		|	AND ItemsBarcodes.Products.ItemsType IN (&SupportedItemTypes)";
		
		ItemsTypes = RebatesServer.SupportedItemTypes();
		
		Query = New Query;
		Query.Text = QueryText;
		Query.SetParameter("Barcodes", Barcodes);
		Query.SetParameter("SupportedItemTypes", ItemsTypes);
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			
			DataString1 = BarcodeData_.Add();
			FillPropertyValues(DataString1, Selection);
			
		EndDo;
		
	EndIf;
	
	Return BarcodeData_;
	
EndFunction

// Returns:
//  ValueTable:
// * Barcode - String
// * Products - CatalogRef.Products
// * Characteristic - CatalogRef.ItemsCharacteristics
// * Package - CatalogRef.PackagesAndUnitsOfMeasure
//
Function BarcodeDataTable()
	
	TypesDetailsString = New TypeDescription("String");
	DescriptionOfItemTypes = New TypeDescription("CatalogRef.Products");
	DescriptionOfTypesCharacteristic = New TypeDescription("CatalogRef.ItemsCharacteristics");
	DescriptionOfPackagingUnitTypes = New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure");
	
	Table = New ValueTable;
	Table.Columns.Add("Barcode", TypesDetailsString);
	Table.Columns.Add("Products", DescriptionOfItemTypes);
	Table.Columns.Add("Characteristic", DescriptionOfTypesCharacteristic);
	Table.Columns.Add("Package", DescriptionOfPackagingUnitTypes);
	
	Return Table;
	
EndFunction

Function SelectItemBasedOnBankingDetails(RowToImport, InformationSecurityDataByNomenclature, BarcodeTable, UseCharacteristics, ConflictsList)
	
	ProductsTable = InformationSecurityDataByNomenclature.ProductsTable;
	CharacteristicTable = InformationSecurityDataByNomenclature.CharacteristicTable;
	
	SearchBars = New Structure;
	Barcode = StrReplace(RowToImport.Barcode, " ", "");
	SearchBarBarcode = Upper(Barcode);
	SearchBars.Insert("Barcode", SearchBarBarcode);
	Code = StrReplace(RowToImport.Code, " ", "");
	SearchStringCode = Upper(Code);
	SearchBars.Insert("Code", SearchStringCode);
	SKU = StrReplace(RowToImport.SKU, " ", "");
	SearchStringArticle = Upper(SKU);
	SearchBars.Insert("SKU", SearchStringArticle);
	Products = StrReplace(RowToImport.NomenclatureName, " ", "");
	SearchStringProducts = Upper(Products);
	SearchBars.Insert("Products", SearchStringProducts);
	If UseCharacteristics Then
		
		Characteristic = StrReplace(RowToImport.CharacteristicName, " ", "");
		SearchStringCharacteristic = Upper(Characteristic);
		SearchBars.Insert("Characteristic", SearchStringCharacteristic);
		
	EndIf;
	
	ThereIsBarcode = ValueIsFilled(Barcode);
	HasCode = ValueIsFilled(Code);
	ThereIsArticle = ValueIsFilled(SKU);
	ThereIsProductRange = ValueIsFilled(Products);
	ThereIsCharacteristic = (UseCharacteristics And ValueIsFilled(SearchStringCharacteristic));
	
	DataFound = New Array; // Array of See GoodsDataLine
	DataWasFound = False;
	
	If ThereIsBarcode Then
		
		SelectProductsByBarcode(BarcodeTable, SearchBars, DataWasFound, DataFound);
		
	EndIf;
	
	If Not DataWasFound
	   And HasCode
	   And ThereIsCharacteristic Then
		
		SelectItemBasedOnFeatureCode(ProductsTable, CharacteristicTable, DataFound, SearchBars, DataWasFound);
		
	EndIf;
	
	If Not DataWasFound
	   And ThereIsArticle
	   And ThereIsProductRange
	   And ThereIsCharacteristic Then
		
		SelectItemByArticleItemCharacteristics(ProductsTable, CharacteristicTable, DataFound, SearchBars, DataWasFound);
		
	EndIf;
	
	If Not DataWasFound
	   And HasCode
	   And Not ThereIsCharacteristic Then
		
		SelectItemByCode(ProductsTable, DataFound, SearchBars, DataWasFound);
		
	EndIf;
	
	If Not DataWasFound
	   And ThereIsArticle
	   And ThereIsProductRange
	   And Not ThereIsCharacteristic Then
		
		SelectItemByArticleItem(ProductsTable, DataFound, SearchBars, DataWasFound);
		
	EndIf;
	
	If Not DataWasFound
	   And Not ThereIsArticle
	   And ThereIsProductRange
	   And ThereIsCharacteristic Then
		
		SelectItemByItemCharacteristics(ProductsTable, CharacteristicTable, DataFound, SearchBars, DataWasFound);
		
	EndIf;
	
	If Not DataWasFound
	   And ThereIsArticle
	   And Not ThereIsProductRange
	   And Not ThereIsCharacteristic Then
		
		SelectItemByArticle(ProductsTable, DataFound, SearchBars, DataWasFound);
		
	EndIf;
	
	If Not DataWasFound
	   And ThereIsArticle
	   And Not ThereIsProductRange
	   And ThereIsCharacteristic Then
		
		SelectItemByArticleCharacteristic(ProductsTable, CharacteristicTable, DataFound, SearchBars, DataWasFound);
		
	EndIf;
	
	If Not DataWasFound
	   And Not ThereIsArticle
	   And ThereIsProductRange
	   And Not ThereIsCharacteristic Then
		
		SelectItemByName(ProductsTable, DataFound, SearchBars, DataWasFound);
		
	EndIf;
	
	ResultStructure1 = New Structure;
	ResultStructure1.Insert("Products", Catalogs.Products.EmptyRef());
	If UseCharacteristics Then
		ResultStructure1.Insert("Characteristic", Catalogs.ItemsCharacteristics.EmptyRef());
	EndIf;
	
	If DataWasFound Then
		
		If DataFound.Count() = 1 Then
			
			ProductsRow = DataFound[0];
			FillPropertyValues(ResultStructure1, ProductsRow);
			
		Else
			
			FillInListsOfAmbiguitiesWhenSelectingItems(RowToImport, ConflictsList, UseCharacteristics);
			
		EndIf;
		
	EndIf;
	
	Return ResultStructure1;
	
EndFunction

Procedure FillInListsOfAmbiguitiesWhenSelectingItems(RowToImport, ConflictsList, UseCharacteristics)
	
	StringOfAmbiguity = ConflictsList.Add();
	StringOfAmbiguity.Id = RowToImport.Id;
	StringOfAmbiguity.Column = "Products";
	
	If UseCharacteristics Then
		
		StringOfAmbiguity = ConflictsList.Add();
		StringOfAmbiguity.Id = RowToImport.Id;
		StringOfAmbiguity.Column = "Characteristic";
		
	EndIf;
	
EndProcedure

Procedure SelectItemByName(ProductsTable, DataFound, SearchBars, DataWasFound)
	
	TheStructureOfTheSearch = New Structure("NameSearch", SearchBars.Products);
	FoundProductsByKey = ProductsTable.FindRows(TheStructureOfTheSearch);
	
	If FoundProductsByKey.Count() = 0 Then
		FoundProductsByKey = ProductsTable.FindRows(TheStructureOfTheSearch);
	EndIf;
	
	If FoundProductsByKey.Count() > 0 Then
		
		DataWasFound = True;
		For Each ProductsByKey In FoundProductsByKey Do
			AddDataOfFoundString(DataFound, ProductsByKey.Products);
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure SelectItemByArticleCharacteristic(ProductsTable, CharacteristicTable, DataFound, SearchBars, DataWasFound)

	TheStructureOfTheSearch = New Structure("ProductIDSearch", SearchBars.SKU);
	FoundProductsByKey = ProductsTable.FindRows(TheStructureOfTheSearch);
	
	SelectionByLinkedTable = New Structure("NameOfTheSearchFeature", SearchBars.Characteristic);
	FoundRows = SearchLinkedTable(
		FoundProductsByKey,
		CharacteristicTable,
		SelectionByLinkedTable);
	
	If FoundRows.Count() = 0 Then
		
		SelectionByLinkedTable = New Structure("FullNameOfCharacteristicSearch", SearchBars.Characteristic);
		FoundRows = SearchLinkedTable(
			FoundProductsByKey,
			CharacteristicTable,
			SelectionByLinkedTable);
		
	EndIf;
	
	If FoundRows.Count() > 0 Then
		
		DataWasFound = True;
		For Each FoundRow In FoundRows Do
			
			AddDataOfFoundString(
				DataFound,
				FoundRow.Products,
				FoundRow.Characteristic);
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure SelectItemByArticle(ProductsTable, DataFound, SearchBars, DataWasFound)
	
	TheStructureOfTheSearch = New Structure("ProductIDSearch", SearchBars.SKU);
	FoundProductsByKey = ProductsTable.FindRows(TheStructureOfTheSearch);
	
	If FoundProductsByKey.Count() > 0 Then
		
		DataWasFound = True;
		For Each ProductsByKey In FoundProductsByKey Do
			AddDataOfFoundString(DataFound, ProductsByKey.Products);
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure SelectItemByItemCharacteristics(ProductsTable, CharacteristicTable, DataFound, SearchBars, DataWasFound)

	TheStructureOfTheSearch = New Structure("NameOfTheSearchFeature", SearchBars.Characteristic);
	FoundKeyCharacteristics = CharacteristicTable.FindRows(TheStructureOfTheSearch);
	SelectionByLinkedTable = New Structure("NameSearch", SearchBars.Products);
	FoundRows = SearchLinkedTable(
		FoundKeyCharacteristics,
		ProductsTable,
		SelectionByLinkedTable);
	
	If FoundRows.Count() = 0 Then
		
		SelectionByLinkedTable = New Structure("FullNameSearch", SearchBars.Products);
		FoundRows = SearchLinkedTable(
			FoundKeyCharacteristics,
			ProductsTable,
			SelectionByLinkedTable);
		
		If FoundRows.Count() = 0 Then
			
			TheStructureOfTheSearch = New Structure("FullNameOfCharacteristicSearch", SearchBars.Characteristic);
			FoundKeyCharacteristics = CharacteristicTable.FindRows(TheStructureOfTheSearch);
			SelectionByLinkedTable = New Structure("NameSearch", SearchBars.Products);
			FoundRows = SearchLinkedTable(
				FoundKeyCharacteristics,
				ProductsTable,
				SelectionByLinkedTable);
			
			If FoundRows.Count() = 0 Then
				
				SelectionByLinkedTable = New Structure("FullNameSearch", SearchBars.Products);
				FoundRows = SearchLinkedTable(
					FoundKeyCharacteristics,
					ProductsTable,
					SelectionByLinkedTable);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If FoundRows.Count() = 0 Then
		
		TheStructureOfTheSearch = New Structure("NameSearch",	SearchBars.Products);
		FoundProductsByKey = ProductsTable.FindRows(TheStructureOfTheSearch);
		
		If FoundProductsByKey.Count() = 0 Then
			
			TheStructureOfTheSearch = New Structure("FullNameSearch", SearchBars.Products);
			FoundProductsByKey = ProductsTable.FindRows(TheStructureOfTheSearch);
			
		EndIf;
		
		For Each ProductsByKey In FoundProductsByKey Do
			
			TheStructureOfTheSearch = New Structure(
				"SignificanceForFeatureSelection", ProductsByKey.SignificanceForFeatureSelection);
			FoundKeyCharacteristics = CharacteristicTable.FindRows(TheStructureOfTheSearch);
			
			For Each KeyCharacteristics In FoundKeyCharacteristics Do
				
				AddDataOfFoundString(
					DataFound, ProductsByKey.Products, KeyCharacteristics.Characteristic);
				
			EndDo;
			
		EndDo;
		
	Else
		
		For Each FoundRow In FoundRows Do
			
			AddDataOfFoundString(
				DataFound,
				FoundRow.Products,
				FoundRow.Characteristic);
			
		EndDo;
		
	EndIf;
	
	If DataFound.Count() > 0 Then
		DataWasFound = True;
	EndIf;
	
EndProcedure

Procedure SelectItemByArticleItem(ProductsTable, DataFound, SearchBars, DataWasFound)
	
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("ProductIDSearch", SearchBars.SKU);
	TheStructureOfTheSearch.Insert("NameSearch", SearchBars.Products);
	
	FoundProductsByKey = ProductsTable.FindRows(TheStructureOfTheSearch);
	If FoundProductsByKey.Count() = 0 Then
		
		FoundProductsByKey = ProductsTable.FindRows(TheStructureOfTheSearch);
		If FoundProductsByKey.Count() = 0 Then
			
			SearchStructureArticle = New Structure("ProductIDSearch", SearchBars.SKU);
			FoundProductsByKey = ProductsTable.FindRows(SearchStructureArticle);
			
		EndIf;
		
	EndIf;
	
	If FoundProductsByKey.Count() > 0 Then
		
		DataWasFound = True;
		For Each ProductsByKey In FoundProductsByKey Do
			
			AddDataOfFoundString(DataFound, ProductsByKey.Products);
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure SelectItemByCode(ProductsTable, DataFound, SearchBars, DataWasFound)
	
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("Code", SearchBars.Code);
	TheStructureOfTheSearch.Insert("NameSearch", SearchBars.Products);
	FoundProductsByKey = ProductsTable.FindRows(TheStructureOfTheSearch);
	
	If FoundProductsByKey.Count() = 0 Then
		
		FoundProductsByKey = ProductsTable.FindRows(TheStructureOfTheSearch);
		If FoundProductsByKey.Count() = 0 Then
			
			SearchStructureCode = New Structure("Code", SearchBars.Code);
			FoundProductsByKey = ProductsTable.FindRows(SearchStructureCode);
			
		EndIf;
		
	EndIf;
	
	If FoundProductsByKey.Count() > 0 Then
		
		DataWasFound = True;
		For Each ProductsByKey In FoundProductsByKey Do
			
			AddDataOfFoundString(DataFound, ProductsByKey.Products);
			
		EndDo;
	
	EndIf;
	
EndProcedure

Procedure SelectItemByArticleItemCharacteristics(ProductsTable, CharacteristicTable, DataFound, SearchBars, DataWasFound)
	
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("ProductIDSearch", SearchBars.SKU);
	TheStructureOfTheSearch.Insert("NameSearch", SearchBars.Products);
	
	FoundProductsByKey = ProductsTable.FindRows(TheStructureOfTheSearch);
	
	SelectionByLinkedTable = New Structure("NameOfTheSearchFeature", SearchBars.Characteristic);
	FoundRows = SearchLinkedTable(
		FoundProductsByKey,
		CharacteristicTable,
		SelectionByLinkedTable);
	
	If FoundRows.Count() = 0 Then
		
		SelectionByLinkedTable = New Structure("FullNameOfCharacteristicSearch", SearchBars.Characteristic);
		FoundRows = SearchLinkedTable(
			FoundProductsByKey,
			CharacteristicTable,
			SelectionByLinkedTable);
		
	EndIf;
	
	If FoundRows.Count() = 0 Then
		
		TheStructureOfTheSearch = New Structure;
		TheStructureOfTheSearch.Insert("ProductIDSearch", SearchBars.SKU);
		TheStructureOfTheSearch.Insert("FullNameSearch", SearchBars.Products);
		FoundProductsByArticleFullName = ProductsTable.FindRows(TheStructureOfTheSearch);
		
		SelectionByLinkedTable = New Structure("NameOfTheSearchFeature", SearchBars.Characteristic);
		FoundRows = SearchLinkedTable(
			FoundProductsByArticleFullName,
			CharacteristicTable,
			SelectionByLinkedTable);
		
		If FoundRows.Count() = 0 Then
			
			SelectionByLinkedTable = New Structure;
			SelectionByLinkedTable.Insert("FullNameOfCharacteristicSearch", SearchBars.Characteristic);
			FoundRows = SearchLinkedTable(
				FoundProductsByArticleFullName,
				CharacteristicTable,
				SelectionByLinkedTable);
			
		EndIf;
		
	EndIf;
	
	If FoundRows.Count() > 0 Then
		
		DataWasFound = True;
		For Each FoundRow In FoundRows Do
			
			AddDataOfFoundString(
				DataFound, FoundRow.Products,
				FoundRow.Characteristic);
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure SelectItemBasedOnFeatureCode(ProductsTable, CharacteristicTable, DataFound, SearchBars, DataWasFound)
	
	TheStructureOfTheSearch = New Structure("Code", SearchBars.Code);
	FoundProductsByKey = ProductsTable.FindRows(TheStructureOfTheSearch);
	SelectionByLinkedTable = New Structure("NameOfTheSearchFeature", SearchBars.Characteristic);
	FoundRows = SearchLinkedTable(
		FoundProductsByKey,
		CharacteristicTable,
		SelectionByLinkedTable);
	
	If FoundRows.Count() = 0 Then
		
		SelectionByLinkedTable = New Structure;
		SelectionByLinkedTable.Insert("FullNameOfCharacteristicSearch", SearchBars.Characteristic);
		FoundRows = SearchLinkedTable(
			FoundProductsByKey,
			CharacteristicTable,
			SelectionByLinkedTable);
		
		If FoundRows.Count() = 0 Then
			
			EmptySelection = New Structure;
			FoundRows = SearchLinkedTable(
				FoundProductsByKey,
				CharacteristicTable,
				EmptySelection);
			
		EndIf;
		
	EndIf;
	
	If FoundRows.Count() > 0 Then
		
		DataWasFound = True;
		For Each FoundRow In FoundRows Do
			
			AddDataOfFoundString(
				DataFound,
				FoundRow.Products,
				FoundRow.Characteristic);
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure SelectProductsByBarcode(BarcodeTable, SearchBars, DataWasFound, DataFound)
	
	BarcodeSearchStructure = New Structure;
	BarcodeSearchStructure.Insert("Barcode", SearchBars.Barcode);
	
	FoundRows = BarcodeTable.FindRows(BarcodeSearchStructure);
	
	If FoundRows.Count() > 0 Then
		
		DataWasFound = True;
		BarcodeString_ = FoundRows[0];
		AddDataOfFoundString(DataFound, BarcodeString_.Products, BarcodeString_.Characteristic);
		
	EndIf;
	
EndProcedure

Procedure AddDataOfFoundString(FoundRows, Products, Characteristic = Undefined);
	
	Data = GoodsDataLine();
	Data.Products = Products;
	Data.Characteristic = Characteristic;
	
	FoundRows.Add(Data);
	
EndProcedure

// Parameters:
//  ArrayOfPreviouslyFound - Array of ValueTableRow - Array Of Previously Found
//  RelatedTable - ValueTable - Related Table:
// * Code - String - 
// * SKU - String - 
// * Description - String - 
// * DescriptionFull - String - 
// * Products - CatalogRef.Products - 
// * UseVariants - Boolean - 
// * SignificanceForFeatureSelection - EnumRef.ItemVariantsUsageOptions - 
//  SelectionByLinkedTable - Structure - Selection By Linked Table:
// 
// Returns:
//  ValueTable:
// * Products - CatalogRef.Products
// * Characteristic - CatalogRef.ItemsCharacteristics
//
Function SearchLinkedTable(ArrayOfPreviouslyFound, RelatedTable, SelectionByLinkedTable)
	
	Result = New ValueTable;
	Result.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	Result.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	
	If ArrayOfPreviouslyFound.Count() > 0 Then
		
		For Each StringByKey In ArrayOfPreviouslyFound Do
			
			FilterForSearch = New Structure;
			FilterForSearch.Insert("SignificanceForFeatureSelection", StringByKey.SignificanceForFeatureSelection);
			
			For Each FilterElement In SelectionByLinkedTable Do
				FilterForSearch.Insert(FilterElement.Key, FilterElement.Value);
			EndDo;
			
			FoundBySelection = RelatedTable.FindRows(FilterForSearch);
			For Each StringFoundBySelection In FoundBySelection Do
				
				NewResultString = Result.Add();
				FillPropertyValues(NewResultString, StringFoundBySelection);
				FillPropertyValues(NewResultString, StringByKey);
				
			EndDo;
			
		EndDo;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Parameters:
//  DataToImport - ValueTable:
//  * Segment_Name - String
//  * Code - String
//  * Id - Number
//  TableToFillIn_ - ValueTable:
//  * Segment - CatalogRef.ProductSegments
//  AdditionalParameters - Arbitrary - advanced setting
//  ConflictsList - ValueTable - List of ambiguities:
// * Column - String
// * Id - Number 
//
Procedure CompareDownloadedDataTSGoodsSegments(DataToImport, TableToFillIn_, AdditionalParameters, ConflictsList)
	
	GoodsSegmentTable = GoodsSegmentTable();
	
	For Each DataString1 In DataToImport Do
		
		NewRow = TableToFillIn_.Add();
		FillPropertyValues(NewRow, DataString1);
		
		NewRow.Segment = SelectInventorySegmentBasedOnBankingDetails(
			DataString1, GoodsSegmentTable, ConflictsList);
		
	EndDo;
	
EndProcedure

// Returns:
//  ValueTable - Goods Segment Table:
//  * Code - String
//  * Description - String
//  * Segment - CatalogRef.ProductSegments
//
Function GoodsSegmentTable()
	
	QueryText =
	"SELECT
	|	ProductSegments.Code AS Code,
	|	ProductSegments.Description AS Description,
	|	ProductSegments.Ref AS Segment
	|FROM
	|	Catalog.ProductSegments AS ProductSegments
	|WHERE
	|	NOT ProductSegments.DeletionMark
	|	AND NOT ProductSegments.IsFolder";
		
	Query = New Query;
	Query.Text = QueryText;
	
	SegmentTable = Query.Execute().Unload();
	
	TypesDetailsString = New TypeDescription("String");
	SegmentTable.Columns.Add("NameSearch", TypesDetailsString);
	FillInSearchFieldsForGoodsSegments(SegmentTable);
	
	Return SegmentTable;
	
EndFunction

// Parameters:
//  SegmentTable - ValueTable:
//  * Code - String
//  * Description - String
//  * NameSearch - String
//
Procedure FillInSearchFieldsForGoodsSegments(SegmentTable)
	
	For Each SegmentLine In SegmentTable Do
		
		Code = StrReplace(SegmentLine.Code, " ", "");
		SegmentLine.Code = Upper(Code);
		
		NameSearch = StrReplace(SegmentLine.Description, " ", "");
		SegmentLine.NameSearch = Upper(NameSearch);
		
	EndDo;
	
EndProcedure

Function SelectInventorySegmentBasedOnBankingDetails(RowToImport, SegmentTable, ConflictsList)
	
	SearchStringCode = Upper(StrReplace(RowToImport.Code, " ", "")); 
	SearchStringSegment = Upper(StrReplace(RowToImport.Segment_Name, " ", ""));
	
	HasCode = ValueIsFilled(RowToImport.Code);
	ThereIsName = ValueIsFilled(RowToImport.Segment_Name);
	
	DataWasFound = False;
	
	If HasCode Then
		
		TheStructureOfTheSearch = New Structure;
		TheStructureOfTheSearch.Insert("Code", SearchStringCode);
		
		FoundRows = SegmentTable.FindRows(TheStructureOfTheSearch);
		If FoundRows.Count() > 0 Then
			DataWasFound = True;
		EndIf;
		
	EndIf;
	
	If Not DataWasFound
	   And ThereIsName Then
		
		TheStructureOfTheSearch = New Structure;
		TheStructureOfTheSearch.Insert("NameSearch", SearchStringSegment);
		
		FoundRows = SegmentTable.FindRows(TheStructureOfTheSearch);
		If FoundRows.Count() > 0 Then
			DataWasFound = True;
		EndIf;
		
	EndIf;
	
	FoundSegment = Catalogs.ProductSegments.EmptyRef();
	
	If DataWasFound Then
		
		If FoundRows.Count() = 1 Then
			
			SegmentLine = FoundRows[0];
			FoundSegment = SegmentLine.Segment;
			
		Else
			
			StringOfAmbiguity = ConflictsList.Add();
			StringOfAmbiguity.Id = RowToImport.Id;
			StringOfAmbiguity.Column = "Segment";
			
		EndIf;
		
	EndIf;
	
	Return FoundSegment;
	
EndFunction

// Parameters:
//  ConflictsList - Array of CatalogRef.ProductSegments
//  LoadedValuesString - ValueTableRow:
//  * Segment_Name - String
//  * Code - String
//
Procedure FillInListOfGoodsSegmentAmbiguities(ConflictsList, LoadedValuesString)
	
	Query = New Query;
	
	TermsAndConditions_ = New Array; // Array of String
	
	If ValueIsFilled(LoadedValuesString.Segment_Name) Then
		
		ConditionText =
		"Segments.Description = &Description";
		
		TermsAndConditions_.Add(ConditionText);
		Query.SetParameter("Description", LoadedValuesString.Segment_Name);
		
	EndIf;
	
	If ValueIsFilled(LoadedValuesString.Code) Then
		
		ConditionText =
		"Segments.Code = &Code";
		TermsAndConditions_.Add(ConditionText);
		Query.SetParameter("Code", LoadedValuesString.Code);
		
	EndIf;
	
	TextAnd = Chars.LF + "AND "; //@query-part
	
	QueryText =
	"SELECT
	|	Segments.Ref AS Ref
	|FROM
	|	Catalog.ProductSegments AS Segments
	|WHERE
	|	NOT Segments.DeletionMark
	|	AND NOT Segments.IsFolder";
	
	If TermsAndConditions_.Count() > 0 Then
		
		FullTextOfTermsAndConditions = StrConcat(TermsAndConditions_, TextAnd);
		QueryText = QueryText + TextAnd + FullTextOfTermsAndConditions;
		
	EndIf;
	
	Query.Text = QueryText;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		ConflictsList.Add(Selection.Ref);
		
	EndDo;
	
EndProcedure

// Parameters:
//  DataToImport - ValueTable:
//  * TIN - String
//  * CRTR - String
//  * CounterpartyName_ - String
//  * Code - String - Partner Code
//  * PartnerName_ - String
//  * Id - Number
//  TableToFillIn_ - ValueTable:
//  * Counterparty - CatalogRef.Counterparties
//  * Partner - CatalogRef.Partners
//  AdditionalParameters - Arbitrary - advanced setting
//  ConflictsList - ValueTable - List of ambiguities:
//  * Column - String
//  * Id - Number
//
Procedure CompareDownloadedDataTSCounterpartiesOfClients(DataToImport, TableToFillIn_, AdditionalParameters, ConflictsList)
	
	CounterpartiesTable = InformationSecurityDataOnCounterparties();
	
	For Each DataString1 In DataToImport Do
		
		NewRow = TableToFillIn_.Add();
		FillPropertyValues(NewRow, DataString1);
		
		NewRow.Counterparty = ToSelectCounterpartyByBankingDetails(
			DataString1, CounterpartiesTable, ConflictsList);
		
	EndDo;
	
EndProcedure

// Returns:
//  ValueTable:
//  * TIN - String
//  * CRTR - String
//  * Description - String
//  * DescriptionFull - String
//  * Counterparty - CatalogRef.Counterparties
//
Function InformationSecurityDataOnCounterparties()
	
	QueryText = 
	"SELECT
	|	Counterparties.TIN AS TIN,
	|	Counterparties.CRTR AS CRTR,
	|	Counterparties.Description AS Description,
	|	Counterparties.DescriptionFull AS DescriptionFull,
	|	Counterparties.Ref AS Counterparty
	|FROM
	|	Catalog.Counterparties AS Counterparties
	|WHERE
	|	NOT Counterparties.DeletionMark";
		
	Query = New Query;
	Query.Text = QueryText;
	
	TypesDetailsString = New TypeDescription("String");
	
	CounterpartiesTable = Query.Execute().Unload();
	CounterpartiesTable.Columns.Add("NameSearch", TypesDetailsString);
	CounterpartiesTable.Columns.Add("FullNameSearch", TypesDetailsString);
	
	FillInCounterpartySearchFields(CounterpartiesTable);
	
	Return CounterpartiesTable;
	
EndFunction

// Parameters:
//  CounterpartiesTable - ValueTable:
//  * TIN - String
//  * CRTR - String
//  * Description - String
//  * DescriptionFull - String
//  * NameSearch - String
//  * FullNameSearch - String
//
Procedure FillInCounterpartySearchFields(CounterpartiesTable)
	
	For Each RowOfCounterparty In CounterpartiesTable Do
		
		TIN = StrReplace(RowOfCounterparty.TIN, " ", "");
		RowOfCounterparty.TIN = Upper(TIN);
		
		CRTR = StrReplace(RowOfCounterparty.CRTR, " ", "");
		RowOfCounterparty.CRTR = Upper(CRTR);
		
		NameSearch = StrReplace(RowOfCounterparty.Description, " ", "");
		RowOfCounterparty.NameSearch = Upper(NameSearch);
		
		FullNameSearch = StrReplace(RowOfCounterparty.DescriptionFull, " ", "");
		RowOfCounterparty.FullNameSearch = Upper(FullNameSearch);
		
	EndDo;
	
EndProcedure

Function ToSelectCounterpartyByBankingDetails(RowToImport, CounterpartiesTable, ConflictsList)
	
	INNSearchBar = Upper(StrReplace(RowToImport.TIN, " ", "")); 
	CHECKPOINTSearchBar = Upper(StrReplace(RowToImport.CRTR, " ", "")); 
	CounterpartySearchBar = Upper(StrReplace(RowToImport.CounterpartyName_, " ", ""));
	
	HasTIN = ValueIsFilled(RowToImport.TIN);
	ThereIsCheckpoint = ValueIsFilled(RowToImport.CRTR);
	ThereIsName = ValueIsFilled(RowToImport.CounterpartyName_);
	
	DataWasFound = False;
	
	// Search for all completed fields
	TheStructureOfTheSearch = New Structure;
	If HasTIN Then
		TheStructureOfTheSearch.Insert("TIN", INNSearchBar);
	EndIf;
	If ThereIsCheckpoint Then
		TheStructureOfTheSearch.Insert("CRTR", CHECKPOINTSearchBar);
	EndIf;
	If ThereIsName Then
		TheStructureOfTheSearch.Insert("NameSearch", CounterpartySearchBar);
	EndIf;
	
	FoundRows = CounterpartiesTable.FindRows(TheStructureOfTheSearch);
	If FoundRows.Count() > 0 Then
		DataWasFound = True;
	EndIf;
	
	If Not DataWasFound
	   And ThereIsName Then
		
		TheStructureOfTheSearch.Delete("NameSearch");
		TheStructureOfTheSearch.Insert("FullNameSearch", CounterpartySearchBar);
		
	EndIf;
	
	FoundRows = CounterpartiesTable.FindRows(TheStructureOfTheSearch);
	If FoundRows.Count() > 0 Then
		DataWasFound = True;
	EndIf;
	
	// Highest priority by INN
	If Not DataWasFound
	   And HasTIN
	   And ThereIsName Then
		
		TheStructureOfTheSearch = New Structure;
		TheStructureOfTheSearch.Insert("TIN", INNSearchBar);
		
		If ThereIsCheckpoint Then
			TheStructureOfTheSearch.Insert("CRTR", CHECKPOINTSearchBar);
		EndIf;
		
		FoundRows = CounterpartiesTable.FindRows(TheStructureOfTheSearch);
		If FoundRows.Count() > 0 Then
			DataWasFound = True;
		EndIf;
		
	EndIf;
	
	// Search by name
	If Not DataWasFound
	   And HasTIN
	   And ThereIsName Then
		
		TheStructureOfTheSearch.Insert("NameSearch", CounterpartySearchBar);
		FoundRows = CounterpartiesTable.FindRows(TheStructureOfTheSearch);
		If FoundRows.Count() > 0 Then
			DataWasFound = True;
		EndIf;
		
	EndIf;
	
	// Search by full name
	If Not DataWasFound
	   And HasTIN
	   And ThereIsName Then
		
		TheStructureOfTheSearch.Insert("FullNameSearch", CounterpartySearchBar);
		FoundRows = CounterpartiesTable.FindRows(TheStructureOfTheSearch);
		If FoundRows.Count() > 0 Then
			DataWasFound = True;
		EndIf;
		
	EndIf;
	
	CounterpartyFound = Catalogs.Counterparties.EmptyRef();
	
	If DataWasFound Then
		
		If FoundRows.Count() = 1 Then
			
			RowOfCounterparty = FoundRows[0];
			CounterpartyFound = RowOfCounterparty.Counterparty;
			
		Else
			
			StringOfAmbiguity = ConflictsList.Add();
			StringOfAmbiguity.Id = RowToImport.Id;
			StringOfAmbiguity.Column = "Counterparty";
			
		EndIf;
		
	EndIf;
	
	Return CounterpartyFound;
	
EndFunction

// Parameters:
//  ConflictsList - Array of CatalogRef.Counterparties
//  LoadedValuesString - ValueTableRow:
//  * CounterpartyName_ - String
//  * TIN - String
//  * CRTR - String
//
Procedure FillInListOfCounterpartiesAmbiguities(ConflictsList, LoadedValuesString)
	
	Query = New Query;
	
	TermsAndConditions_ = New Array; // Array of String
	
	If ValueIsFilled(LoadedValuesString.CounterpartyName_) Then
		
		ConditionText =
		"(Counterparties.Description = &Description
		| OR Counterparties.DescriptionFull = &Description)";
		
		TermsAndConditions_.Add(ConditionText);
		Query.SetParameter("Description", LoadedValuesString.CounterpartyName_);
		
	EndIf;
	
	If ValueIsFilled(LoadedValuesString.TIN) Then
		
		ConditionText =
		"Counterparties.TIN = &TIN";
		TermsAndConditions_.Add(ConditionText);
		Query.SetParameter("TIN", LoadedValuesString.TIN);
		
	EndIf;
	
	If ValueIsFilled(LoadedValuesString.CRTR) Then
		
		ConditionText =
		"Counterparties.CRTR = &CRTR";
		
		TermsAndConditions_.Add(ConditionText);
		Query.SetParameter("Description", LoadedValuesString.CRTR);
		
	EndIf;
	
	TextAnd = Chars.LF + "AND "; //@query-part
	
	QueryText =
	"SELECT
	|	Counterparties.Ref AS Ref
	|FROM
	|	Catalog.Counterparties AS Counterparties
	|WHERE
	|	NOT Counterparties.DeletionMark";
	
	If TermsAndConditions_.Count() > 0 Then
		
		FullTextOfTermsAndConditions = StrConcat(TermsAndConditions_, TextAnd);
		QueryText = QueryText + TextAnd + FullTextOfTermsAndConditions;
		
	EndIf;
	
	Query.Text = QueryText;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		ConflictsList.Add(Selection.Ref);
		
	EndDo;
	
EndProcedure

// Parameters:
//  DataToImport - ValueTable:
//   * Code - String
//   * Date - Date
//   * Number - String
//   * PropertyValue - Arbitrary
//   * Id - Number
//   * CountPlan - Number
//   * ValidOnDate - Date
//   * ValidTo- Date
//   * ErrorDescription - String
//   * Percent - String
//   * RowMappingResult - String
//  TableToFillIn_ -  ValueTable:
//   * PropertyValue - Arbitrary
//  AdditionalParameters - Structure:
//   * FieldDisplaySettings - Structure:
//    ** BasePrice - Boolean
//    ** CountPlan- Boolean
//    ** Period - Boolean
//    ** Percent - Boolean
//   * InformationAboutSource - Structure:
//    ** CodeLength - Number
//    ** DescriptionLength - Number
//    ** NumberLength - Number
//    ** Name - String
//    ** FullName - String
//    ** ProductItemPropertyPresentation - String
//    ** ContainsGroups - Boolean
//    ** Type - TypeDescription
//    ** IsDate - Boolean
//    ** IsNumber - Boolean
//    ** IsDocument - Boolean
//    ** IsEnum - Boolean
//    ** IsChartOfCharacteristicTypes - Boolean
//    ** IsCatalog - Boolean
//  ConflictsList - ValueTable - List of ambiguities:
// * Column - String - 
// * Id - Number
//  
Procedure CompareUploadedTSDataWithItemProperties(DataToImport, TableToFillIn_, AdditionalParameters, ConflictsList)
	
	InformationAboutSource = AdditionalParameters.InformationAboutSource;
	ToMatch = Not (InformationAboutSource.IsNumber 
					Or InformationAboutSource.IsDate);
	
	If ToMatch Then
		
		PropertyValueTable = PropertyValue(InformationAboutSource, DataToImport);
		
	EndIf;
	
	For Each DataString1 In DataToImport Do
		
		NewRow = TableToFillIn_.Add();
		FillPropertyValues(NewRow, DataString1);
		
		If ToMatch Then
			
			If InformationAboutSource.IsCatalog
			 Or InformationAboutSource.IsChartOfCharacteristicTypes Then
				
				NewRow.PropertyValue = SelectValueOfPlanReferenceListPropertyOfCharacteristicType(
					DataString1,
					PropertyValueTable,
					InformationAboutSource,
					ConflictsList);
				
			ElsIf InformationAboutSource.IsDocument Then
				
				NewRow.PropertyValue = SelectValueOfDocumentProperty(
					DataString1,
					PropertyValueTable,
					InformationAboutSource,
					ConflictsList);
				
			ElsIf InformationAboutSource.IsEnum Then
				
				NewRow.PropertyValue = SelectValueOfEnumerationProperty(
					DataString1,
					PropertyValueTable,
					InformationAboutSource);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Parameters:
//  InformationAboutSource - Structure - Source Information:
// * CodeLength - Number - 
// * DescriptionLength - Number - 
// * NumberLength - Number - 
// * Name - Number - 
// * FullName - String - 
// * ProductItemPropertyPresentation - String - 
// * ContainsGroups - Boolean - 
// * Type - TypeDescription - 
// * IsDate - Boolean - 
// * IsNumber - Boolean - 
// * IsDocument - Boolean - 
// * IsEnum - Boolean - 
// * IsChartOfCharacteristicTypes - Boolean - 
// * IsCatalog - Boolean - 
//  DataToImport - ValueTable, Arbitrary - Uploaded data:
// * Code - String
// * Date - Date 
// * PropertyValue - Arbitrary - 
// * Id - Number - 
// * CountPlan - Number - 
// * ValidOnDate - Date - 
// * ValidTo - Date - 
// * ErrorDescription - String - 
// * Percent - String - 
// * RowMappingResult - String - 
// 
// Returns:
//  ValueTable:
// * Value - Arbitrary
// * Date - Date
// * Code - String
// * Description - String
// * Ref - AnyRef
// * NameSearch - String
//
Function PropertyValue(InformationAboutSource, DataToImport)
	
	TypesDetailsString = New TypeDescription("String");
	
	If InformationAboutSource.IsEnum Then
		
		PropertyValueTable = NewEnumerationValueLookupTable();
		
		For Each EnumerationValue In Enums[InformationAboutSource.Name] Do
			
			NewRow = PropertyValueTable.Add();
			NewRow.Value = EnumerationValue;
			
			NameSearch = StrReplace(String(EnumerationValue), " ", "");
			NewRow.NameSearch = Upper(NameSearch);
			
		EndDo;
		
	ElsIf InformationAboutSource.IsDocument Then
		
		DataTable = DataToImport.Copy(,"Date, PropertyValue");
		
		QueryText = 
		"SELECT
		|	DataTable.Date AS Date,
		|	DataTable.PropertyValue AS Number
		|INTO TT_DataTable
		|FROM
		|	&DataTable AS DataTable
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED DISTINCT
		|	Document.Number AS Number,
		|	BEGINOFPERIOD(Document.Date, DAY) AS Date,
		|	Document.Ref AS Ref
		|FROM
		|	TT_DataTable AS TT_DataTable
		|		INNER JOIN Document.ConditionsOfVendorRebates AS Document
		|		ON (Document.Date BETWEEN BEGINOFPERIOD(TT_DataTable.Date, DAY) AND ENDOFPERIOD(TT_DataTable.Date, DAY))";
		
		QueryText = StrReplace(QueryText, "Document.ConditionsOfVendorRebates", InformationAboutSource.FullName);
		
		Query = New Query;
		Query.Text = QueryText;
		Query.SetParameter("DataTable", DataTable);
		QueryResult = Query.Execute();
		
		PropertyValueTable = QueryResult.Unload();
		FillInSearchFieldsForDocumentPropertyValues(PropertyValueTable);
		
	Else
		
		If InformationAboutSource.CodeLength > 0 Then
			
			QueryText = 
			"SELECT
			|	ValuesSource.Code AS Code,
			|	ValuesSource.Description AS Description,
			|	ValuesSource.Ref AS Ref
			|FROM
			|	&ValuesSource AS ValuesSource
			|WHERE
			|	NOT ValuesSource.DeletionMark";
			
		Else
			
			QueryText = 
			"SELECT
			|	ValuesSource.Description AS Description,
			|	ValuesSource.Ref AS Ref
			|FROM
			|	&ValuesSource AS ValuesSource
			|WHERE
			|	NOT ValuesSource.DeletionMark";
			
		EndIf;
		
		If InformationAboutSource.ContainsGroups Then
			
			QueryText = QueryText + "
			|	AND NOT ValuesSource.IsFolder";
			
		EndIf;
		
		QueryText = StrReplace(QueryText, "&ValuesSource", InformationAboutSource.FullName);
		
		Query = New Query;
		Query.Text = QueryText;
		
		QueryResult = Query.Execute();
		
		PropertyValueTable = QueryResult.Unload();
		PropertyValueTable.Columns.Add("NameSearch", TypesDetailsString);
		PropertyValueTable.Columns.Add("CodeSearch", TypesDetailsString);
		FillInSearchFieldsForDirectoryPropertyValues(PropertyValueTable, InformationAboutSource);
		
	EndIf;
	
	Return PropertyValueTable;
	
EndFunction

// Returns:
//  ValueTable - New value lookup table:
// * Value - Arbitrary 
// * NameSearch - String
// 
Function NewEnumerationValueLookupTable()
	
	ValueTable = New ValueTable();
	ValueTable.Columns.Add("Value");
	ValueTable.Columns.Add("NameSearch", New TypeDescription("String"));
	
	Return ValueTable;
	
EndFunction

// Parameters:
//  PropertyValueTable - ValueTable:
//   * Code - String
//   * Description - String
//   * NameSearch - String
//   * CodeSearch - String
//  InformationAboutSource - Structure - Source Information:
// * CodeLength - Number - 
// * DescriptionLength - Number - 
// * NumberLength - Number - 
// * Name - Number - 
// * FullName - String - 
// * ProductItemPropertyPresentation - String - 
// * ContainsGroups - Boolean - 
// * Type - TypeDescription - 
// * IsDate - Boolean - 
// * IsNumber - Boolean - 
// * IsDocument - Boolean - 
// * IsEnum - Boolean - 
// * IsChartOfCharacteristicTypes - Boolean - 
// * IsCatalog - Boolean 
// 
Procedure FillInSearchFieldsForDirectoryPropertyValues(PropertyValueTable, InformationAboutSource)
	
	For Each TableRow In PropertyValueTable Do
		
		If InformationAboutSource.CodeLength > 0 Then
			
			Code = StrReplace(TableRow.Code, " ", "");
			TableRow.Code = Upper(Code);
			TableRow.CodeSearch = Upper(Code);
			
		EndIf;
		
		NameSearch = StrReplace(TableRow.Description, " ", "");
		TableRow.NameSearch = Upper(NameSearch);
		
	EndDo;
	
EndProcedure 

// Parameters:
//  PropertyValueTable - ValueTable:
//   * Number - String
//
Procedure FillInSearchFieldsForDocumentPropertyValues(PropertyValueTable)
	
	For Each TableRow In PropertyValueTable Do
		
		Number = StrReplace(TableRow.Number, " ", "");
		TableRow.Number = Upper(Number);
		
	EndDo;
	
EndProcedure

Function SelectValueOfEnumerationProperty(RowToImport, PropertyValueTable, InformationAboutSource)
	
	SearchStringByName = Upper(StrReplace(String(RowToImport.PropertyValue), " ", ""));
	
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("NameSearch", SearchStringByName);
		
	FoundRows = PropertyValueTable.FindRows(TheStructureOfTheSearch);
	If FoundRows.Count() = 1 Then
		
		Return FoundRows[0].Value;
		
	Else
		
		Return Enums[InformationAboutSource.Name].EmptyRef();
		
	EndIf;
	
EndFunction

Function SelectValueOfPlanReferenceListPropertyOfCharacteristicType(RowToImport, PropertyValueTable, InformationAboutSource, ConflictsList)
	
	SourceName = InformationAboutSource.Name;
	
	If InformationAboutSource.CodeLength > 0 Then
		SearchStringCode = Upper(StrReplace(RowToImport.Code, " ", "")); 
	EndIf;
	
	SearchStringByName = Upper(StrReplace(String(RowToImport.PropertyValue), " ", ""));
	
	HasCode = (InformationAboutSource.CodeLength > 0 And ValueIsFilled(RowToImport.Code));
	ThereIsName = ValueIsFilled(RowToImport.PropertyValue);
	
	DataWasFound = False;
	
	If HasCode Then
		
		TheStructureOfTheSearch = New Structure;
		TheStructureOfTheSearch.Insert("CodeSearch", SearchStringCode);
		
		FoundRows = PropertyValueTable.FindRows(TheStructureOfTheSearch);
		If FoundRows.Count() > 0 Then
			DataWasFound = True;
		EndIf;
		
	EndIf;
	
	If Not DataWasFound
	   And ThereIsName Then
		
		TheStructureOfTheSearch = New Structure;
		TheStructureOfTheSearch.Insert("NameSearch", SearchStringByName);
		
		FoundRows = PropertyValueTable.FindRows(TheStructureOfTheSearch);
		If FoundRows.Count() > 0 Then
			DataWasFound = True;
		EndIf;
		
	EndIf;
	
	If InformationAboutSource.IsCatalog Then
		
		ValueFound = Catalogs[SourceName].EmptyRef();
		
	Else
		
		ValueFound = ChartsOfCharacteristicTypes[SourceName].EmptyRef();
		
	EndIf;
	
	If DataWasFound Then
		
		If FoundRows.Count() = 1 Then
			
			FoundRow = FoundRows[0];
			ValueFound = FoundRow.Ref;
			
		Else
			
			StringOfAmbiguity = ConflictsList.Add();
			StringOfAmbiguity.Id = RowToImport.Id;
			StringOfAmbiguity.Column = "PropertyValue";
			
		EndIf;
		
	EndIf;
	
	Return ValueFound;
	
EndFunction

Function SelectValueOfDocumentProperty(RowToImport, PropertyValueTable, InformationAboutSource, ConflictsList)
	
	SourceName = InformationAboutSource.Name;
	DataWasFound = False;
	StringSearchNumber = Upper(StrReplace(String(RowToImport.PropertyValue), " ", ""));
	
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("Date", BegOfDay(RowToImport.Date));
	TheStructureOfTheSearch.Insert("Number", StringSearchNumber);
	
	FoundRows = PropertyValueTable.FindRows(TheStructureOfTheSearch);
	
	If FoundRows.Count() > 0 Then
		DataWasFound = True;
	EndIf;
	
	If DataWasFound Then
		
		If FoundRows.Count() = 1 Then
			
			FoundRow = FoundRows[0];
			ValueFound = FoundRow.Ref;
			
		EndIf;
		
	Else
		
		ValueFound = Documents[SourceName].EmptyRef();
		
	EndIf;
	
	Return ValueFound;

EndFunction

// Parameters:
//  ConflictsList - Array of Arbitrary - List of ambiguities
//  LoadedValuesString - ValueTableRow:
//   * PropertyValue - Arbitrary
//   * Code - String
//  AdditionalParameters - Structure:
//   * FieldDisplaySettings - Structure:
//    ** BasePrice - Boolean
//    ** CountPlan- Boolean
//    ** Period - Boolean
//    ** Percent - Boolean
//   * InformationAboutSource - Structure:
//    ** CodeLength - Number
//    ** DescriptionLength - Number
//    ** NumberLength - Number
//    ** Name - String
//    ** FullName - String
//    ** ProductItemPropertyPresentation - String
//    ** ContainsGroups - Boolean
//    ** Type - TypeDescription
//    ** IsDate - Boolean
//    ** IsNumber - Boolean
//    ** IsDocument - Boolean
//    ** IsEnum - Boolean
//    ** IsChartOfCharacteristicTypes - Boolean
//    ** IsCatalog - Boolean
//
Procedure FillInListOfAmbiguitiesOfPropertyValue(ConflictsList, LoadedValuesString, AdditionalParameters)
	
	InformationAboutSource = AdditionalParameters.InformationAboutSource;
	Query = New Query;
	
	TermsAndConditions_ = New Array; // Array of String
	
	If ValueIsFilled(LoadedValuesString.PropertyValue) Then
		
		ConditionText =
		"ValuesSource.Description = &Description";
		
		TermsAndConditions_.Add(ConditionText);
		Query.SetParameter("Description", LoadedValuesString.PropertyValue);
		
	EndIf;
	
	If InformationAboutSource.CodeLength > 0
	   And ValueIsFilled(LoadedValuesString.Code) Then
		
		ConditionText =
		"ValuesSource.Code = &Code";
		TermsAndConditions_.Add(ConditionText);
		Query.SetParameter("Code", LoadedValuesString.Code);
		
	EndIf;
	
	TextAnd = TextOfCombiningRequestConditions();
	
	QueryText =
	"SELECT
	|	ValuesSource.Ref AS Ref
	|FROM
	|	&ValuesSource AS ValuesSource
	|WHERE
	|	NOT ValuesSource.DeletionMark";
	
	If InformationAboutSource.ContainsGroups Then
			
		QueryText = QueryText + "
		|	AND NOT ValuesSource.IsFolder";
		
	EndIf;
	
	If TermsAndConditions_.Count() > 0 Then
		
		FullTextOfTermsAndConditions = StrConcat(TermsAndConditions_, TextAnd);
		QueryText = QueryText + TextAnd + FullTextOfTermsAndConditions;
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "&ValuesSource", InformationAboutSource.FullName);
	
	Query.Text = QueryText;
	
	QueryResult = Query.Execute();
	If Not QueryResult.IsEmpty() Then
		
		Selection = QueryResult.Select();
		While Selection.Next() Do
			
			ConflictsList.Add(Selection.Ref);
			
		EndDo;
		
	EndIf;
	
EndProcedure

Function TextOfCombiningRequestConditions()
	
	TextAnd = NStr("vi = 'VÀ';
					|ru = 'И';
					|en = 'AND'; fa = 'و';
					|it = 'И';
					|pl = 'AND';
					|tr = 'VE'");
	MergeText = Chars.LF + TextAnd + " ";
	
	Return MergeText;
	
EndFunction

#EndRegion

#EndRegion

#EndIf