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
//  Document - DocumentRef.ConditionsOfCustomerRebates, DocumentObject.ConditionsOfCustomerRebates - link to the document or object for which you want to get data
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
	
	If TypeOf(Document) = Type("DocumentObject.ConditionsOfCustomerRebates") Then
		
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
		QueryTextTableCounterparties(QueryTexts, Registers, DocumentObject);
		QueryTextTableCounterpartiesTIN(QueryTexts, Registers, DocumentObject);
		QueryTextTablePartnersSegments(QueryTexts, Registers, DocumentObject);
		QueryTextTableContractsTermsOfSales(QueryTexts, Registers, DocumentObject);
		QueryTextTableGoods(QueryTexts, Registers, DocumentObject);
		QueryTextTableProductProperties_(QueryTexts, Registers, DocumentObject);
		QueryTextTableGoodsSegments(QueryTexts, Registers, DocumentObject);
		QueryTextTableCustomerRebates(QueryTexts, Registers, DocumentObject);
		QueryTextTableRebatesCalculationScales(QueryTexts, Registers, DocumentObject);
		
	EndIf;
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

#Region Other

// Parameters for clearing Attributes of participants' TS
// 
// Returns:
//  Structure - Parameters For Clearing Participants' Attributes:
//	* PartyList - EnumRef.RebatesParticipants -
//	* FilterParties - EnumRef.RebatesLists -
//	* GoodsIndicator - EnumRef.TargetSalesIndicatorsOfRebatesByGoods -
// 
Function ParametersForClearingParticipantsAttributes() Export
	
	NewParameters = New Structure;
	NewParameters.Insert("PartyList", Enums.RebatesParticipants.EmptyRef());
	NewParameters.Insert("FilterParties", Enums.RebatesLists.EmptyRef());
	NewParameters.Insert("GoodsIndicator", Enums.TargetSalesIndicatorsOfRebatesByGoods.EmptyRef());
	
	Return NewParameters;
	
EndFunction

// Performs cleaning of unused Attributes of participants in the terms of retro bonuses
// 
// Parameters:
//  Object - DocumentObject.ConditionsOfCustomerRebates -
//  	   - FormDataStructure: See Document.ConditionsOfCustomerRebates.Form.DocumentForm.Object -
//  Parameters - See ParametersForClearingParticipantsAttributes
//
Procedure ClearUnusedDetailsOfParticipants(Object, Parameters) Export
	
	ClearUnusedDetailsCounterparties(Object, Parameters);
	ClearUnusedDetailsOfCounterpartiesTIN(Object, Parameters);
	ClearUnusedBankingDetailsPartnerSegments(Object, Parameters);
	ClearUnusedAttributesContractsAgreements(Object, Parameters);
	
EndProcedure

// Sets the correct values for specifying the participants' plan
//
// Parameters:
//  Object - DocumentObject.ConditionsOfCustomerRebates - 
//		   - FormDataStructure: See Document.ConditionsOfCustomerRebates.Form.DocumentForm.Object -
//  Parameters - See ParametersForClearingParticipantsAttributes
//  ChangedMember - Undefined - Process all lines of the document
//  				   - CatalogRef.Partners, CatalogRef.Counterparties - changed values for processing 
//
Procedure EstablishSignsOfCalculationOfParticipantsPlan(Object, Parameters, ChangedMember = Undefined) Export
	
	If Object.WithoutCalculation
	 Or Object.FilterParties <> Enums.RebatesLists.Selected_ Then
		Return;
	EndIf;
	
	EstablishSignsOfSettlementForCounterpartyClient(Object, Parameters);
	
	ToEstablishSignsOfCalculationOfParticipantsPlanDiscrepancyBetweenCompositionAndCalculation(Object, Parameters);
	ToEstablishSignsOfCalculationOfParticipantsPlanCoincidenceOfCompositionAndCalculation(Object, Parameters, ChangedMember);
	EstablishSignsOfCalculationOfPlanContractAgreements(Object, Parameters, ChangedMember);
	
	ToEstablishSignsOfCalculatingCounterpartiesTINPlan(Object, Parameters);
	
EndProcedure

// Parameters for clearing the Attributes of TS products
// 
// Returns:
//  Structure - Parameters For Clearing Participants' Attributes:
//	* ContentOfGoods - EnumRef.RebatesItems -
//	* FilterOfProducts_ - EnumRef.RebatesLists -
//	* GoodsIndicator - EnumRef.TargetSalesIndicatorsOfRebatesByGoods -
//	* BaseOfCalculation - EnumRef.RebateCalculationBases -
//
Function ParametersForClearingGoodsAttributes() Export
	
	NewParameters = New Structure;
	NewParameters.Insert("ContentOfGoods", Enums.RebatesItems.EmptyRef());
	NewParameters.Insert("FilterOfProducts_", Enums.RebatesLists.EmptyRef());
	NewParameters.Insert("GoodsIndicator", Enums.TargetSalesIndicatorsOfRebatesByGoods.EmptyRef());
	NewParameters.Insert("BaseOfCalculation", Enums.RebateCalculationBases.EmptyRef());
	
	Return NewParameters;
	
EndFunction

// Performs cleaning of unused Attributes of goods and conditions of retro bonuses
// 
// Parameters:
//  Object - DocumentObject.ConditionsOfCustomerRebates -
//  	   - FormDataStructure: See Document.ConditionsOfCustomerRebates.Form.DocumentForm.Object -
//  Parameters - See ParametersForClearingGoodsAttributes
//
Procedure ClearUnusedGoodsDetails(Object, Parameters) Export
	
	If Parameters.ContentOfGoods = Enums.RebatesItems.Products Then
		
		Object.ProductProperties_.Clear();
		Object.GoodsSegments.Clear();
		
	ElsIf Parameters.ContentOfGoods = Enums.RebatesItems.ProductSegments Then
		
		Object.Goods.Clear();
		Object.ProductProperties_.Clear();
		
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
		Object.ProductProperties_.Clear();
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

// Gets up-to-date data on the specified condition (the document must be completed)
//
// Parameters:
//  TermDocument - DocumentRef.ConditionsOfCustomerRebates - Terms Document
// 
// Returns:
//  QueryResultSelection:
//	* WithoutCalculation - Boolean -
//	* ValidOnDate - Date -
//	* ValidTo - Date -
//	* Organization - CatalogRef.Companies -
//	* Currency - CatalogRef.Currencies -
//	* PartyCountDetails - EnumRef.ARAPAccountingDrilldownsOfRebatesParticipants -
//	* PartyCountDetailsPresentation - String -
//	* AccrualFrequency - EnumRef.RebatesFrequencies -
//	* ConditionFrequency - EnumRef.RebatesFrequencies -
//	* ConditionFrequencyPresentation - String -
//	* RecordingIsCompleted - Boolean -
//	* ContentOfGoods - EnumRef.RebatesItems -
//	* PartyList - EnumRef.RebatesParticipants -
//	* Attendees - EnumRef.RebatesLists -
//	* Goods - EnumRef.RebatesLists -
//	* ProductItemProperty - String -
//	* RestrictAccrualOverPlan - Boolean -
//	* GoodsIndicator - EnumRef.TargetSalesIndicatorsOfRebatesByGoods -
//	* GoodsIndicatorPresentation - String -
//	* SalesCalculationBase - EnumRef.RebateCalculationBases -
//	* ConsiderVAT - Boolean -
//	* AllocationProcedure - EnumRef.RebatesAllocationProcedures -
//	* DocumentTermsOfRetroBonusesPresentation - String -
// 
Function UpToDateData(TermDocument) Export
	
	Query = New Query;
	QueryText =
	"SELECT
	|	CustomerRebatesConditions.TermDocument.WithoutCalculation AS WithoutCalculation,
	|	CustomerRebatesConditions.ValidOnDate AS ValidOnDate,
	|	CustomerRebatesConditions.ValidTo AS ValidTo,
	|	CustomerRebatesConditions.Organization AS Organization,
	|	CustomerRebatesConditions.Currency AS Currency,
	|	CustomerRebatesConditions.PartyCountDetails AS PartyCountDetails,
	|	REFPRESENTATION(CustomerRebatesConditions.PartyCountDetails) AS PartyCountDetailsPresentation,
	|	CustomerRebatesConditions.AccrualFrequency AS AccrualFrequency,
	|	CustomerRebatesConditions.ConditionFrequency AS ConditionFrequency,
	|	REFPRESENTATION(CustomerRebatesConditions.ConditionFrequency) AS ConditionFrequencyPresentation,
	|	CustomerRebatesConditions.RecordingIsCompleted AS RecordingIsCompleted,
	|	CustomerRebatesConditions.ContentOfGoods AS ContentOfGoods,
	|	CustomerRebatesConditions.PartyList AS PartyList,
	|	CustomerRebatesConditions.Attendees AS Attendees,
	|	CustomerRebatesConditions.Goods AS Goods,
	|	CustomerRebatesConditions.Kind.ProductItemProperty AS ProductItemProperty,
	|	CustomerRebatesConditions.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
	|	CustomerRebatesConditions.CalculationScaleType AS CalculationScaleType,
	|	CustomerRebatesConditions.Kind.GoodsIndicator AS GoodsIndicator,
	|	REFPRESENTATION(CustomerRebatesConditions.Kind.GoodsIndicator) AS GoodsIndicatorPresentation,
	|	CustomerRebatesConditions.Kind.SalesCalculationBase AS SalesCalculationBase,
	|	CustomerRebatesConditions.Kind.ConsiderVAT AS ConsiderVAT,
	|	CustomerRebatesConditions.Kind.AllocationProcedure AS AllocationProcedure,
	|	REFPRESENTATION(CustomerRebatesConditions.TermDocument) AS DocumentTermsOfRetroBonusesPresentation
	|FROM
	|	InformationRegister.CustomerRebatesConditions AS CustomerRebatesConditions
	|WHERE
	|	CustomerRebatesConditions.TermDocument = &TermDocument";
	Query.Text = QueryText;
	Query.SetParameter("TermDocument", TermDocument);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	Return Selection;
	
EndFunction

// Determines whether the current user has the right to directly agree on the terms and conditions of retro customer bonuses
// 
// Returns:
//  Boolean
//
Function ThereIsRightOfApproval() Export
	
	Result = Users.RolesAvailable(Metadata.Roles.RightToApproveConditionsOfCustomerRebates.Name);
	
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
		
		NewCommand.Presentation = NStr("vi = 'Điều chỉnh điều kiện thưởng lũy kế cho khách hàng';
										|ru = 'Корректировка условий ретро-бонусов клиентов';
										|en = 'Correct conditions of customer rebates'; fa = 'Correct conditions of customer rebates';
										|it = 'Корректировка условий ретро-бонусов клиентов';
										|pl = 'Correct conditions of customer rebates';
										|tr = 'Müşterilerin retro bonuslarının şartlarının düzeltilmesi'");
		
		AttachableCommands.AddCommandVisibilityCondition(
			NewCommand,
			"WithoutCalculation",
			False);
		
		AttachableCommands.AddCommandVisibilityCondition(
			NewCommand,
			"Status",
			Enums.RebatesDocumentStatuses.Approved);
		
	EndIf;
	#EndRegion
	
	#Region CreatingAccrual
	NewCommand = Documents.AccrualOfCustomerRebates.AddGenerateCommand(
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
	
	#Region GroupAccrualOfRebates
	NewCommand = DataProcessors.BulkAccrualOfCustomerRebates.AddGenerateCommand(
		GenerationCommands, Parameters);
	If NewCommand <> Undefined Then
		
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
	
	Reports.CustomerRebateStatement.AddReportCommand(
		ReportsCommands, Parameters, "StatementOnCustomerRebatesContext");
	
	ReportCommand = Reports.CalculateCustomerRebates.AddCalculationOfCustomerRebatesCommand(
		ReportsCommands,
		"CalculationOfCustomerRebatesContext");
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
	
	Reports.CompositionOfCustomerRebates.AddReportCommand(
		ReportsCommands, Parameters, "CompositionOfRebatesCustomersContext");
	
	Reports.CompositionOfCustomerRebates.AddReportCommand(
		ReportsCommands, Parameters, "CompositionOfRebatesOfCustomersAccordingToDocumentContext");
	
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
//                                        that needs to be filled in from the addressable Data table.
//   ConflictsList - ValueTable - a list of ambiguous values for which there are several suitable options in the information security:
//       * Column       - String - name of the column where the ambiguity was detected
//       * Id - Number  - id of the row where an ambiguity was detected
//   FullTabularSectionName   - String - full name of the table part where data is loaded
//   AdditionalParameters   - Arbitrary - Any additional information
//
Procedure MapDataToImport(AddressOfUploadedData, AddressOfMappingTable, ConflictsList, FullTabularSectionName, AdditionalParameters) Export
	
	URBMetadata = Metadata.Documents.ConditionsOfCustomerRebates;
	
	DataToImport = GetFromTempStorage(AddressOfUploadedData); // ValueTable
	TableToFillIn_ = GetFromTempStorage(AddressOfMappingTable); // ValueTable
	
	If FullTabularSectionName = URBMetadata.TabularSections.Counterparties.FullName() Then
		
		CompareDownloadedDataTSCounterparties(
			DataToImport, TableToFillIn_, AdditionalParameters, ConflictsList);
		
	ElsIf FullTabularSectionName = URBMetadata.TabularSections.CounterpartiesTIN.FullName() Then
		
		For Each LineBeingLoaded In DataToImport Do
			
			TableRow = TableToFillIn_.Add();
			FillPropertyValues(TableRow, LineBeingLoaded);
			
		EndDo;
		
	ElsIf FullTabularSectionName = URBMetadata.TabularSections.GoodsSegments.FullName() Then
		
		CompareDownloadedDataTSGoodsSegments(
			DataToImport, TableToFillIn_, AdditionalParameters, ConflictsList);
		
	ElsIf FullTabularSectionName = URBMetadata.TabularSections.Goods.FullName() Then
		
		CompareDownloadedDataTSGoods(
			DataToImport, TableToFillIn_, AdditionalParameters, ConflictsList);
		
	ElsIf FullTabularSectionName = URBMetadata.TabularSections.PartnersSegments.FullName() Then
		
		CompareUploadedDataTSPartnerSegments(DataToImport, TableToFillIn_, AdditionalParameters, ConflictsList);
		
	ElsIf FullTabularSectionName = URBMetadata.TabularSections.ProductProperties_.FullName() Then
		
		CompareUploadedTSDataWithItemProperties(
			DataToImport, TableToFillIn_, AdditionalParameters, ConflictsList);
		
	EndIf;
	
	PutToTempStorage(TableToFillIn_, AddressOfMappingTable);
	
EndProcedure

// Returns a list of suitable IB objects for an ambiguous cell value.
// 
// Parameters:
//	FullTabularSectionName - String - full name of the table part where data is loaded.
//	ConflictsList - Array of Arbitrary - An array to fill in with ambiguous data.
//	ColumnName - String - Name of the column where the ambiguity occurred.
//	LoadedValuesString - ValueTableRow - Downloadable data, on the basis of which there was ambiguity.
//	AdditionalParameters - Arbitrary - Any additional information
//
Procedure FillInListOfAmbiguities(FullTabularSectionName, ConflictsList, ColumnName, LoadedValuesString, AdditionalParameters) Export
	
	URBMetadata = Metadata.Documents.ConditionsOfCustomerRebates;
	
	If FullTabularSectionName = URBMetadata.TabularSections.Counterparties.FullName() Then
		
		If ColumnName = "Counterparty" Then
			
			FillInListOfCounterpartiesAmbiguities(ConflictsList, LoadedValuesString);
			
		ElsIf ColumnName = "Partner" Then
			
			FillInListOfPartnerAmbiguities(ConflictsList, LoadedValuesString);
			
		EndIf;
		
	ElsIf FullTabularSectionName = URBMetadata.TabularSections.GoodsSegments.FullName() Then
		
		If ColumnName = "Segment" Then
			
			FillInListOfGoodsSegmentAmbiguities(ConflictsList, LoadedValuesString);
			
		EndIf;
			
	ElsIf FullTabularSectionName = URBMetadata.TabularSections.Goods.FullName() Then
		
		If ColumnName = "Products" Then
			
			FillInListOfNomenclatureAmbiguities(ConflictsList, LoadedValuesString);
			
		EndIf;
		
		If ColumnName = "Characteristic" Then
			
			FillInListOfAmbiguitiesOfCharacteristic(ConflictsList, LoadedValuesString);
			
		EndIf;
		
	ElsIf FullTabularSectionName = URBMetadata.TabularSections.PartnersSegments.FullName() Then
		
		If ColumnName = "Segment" Then
			
			FillInListOfPartnerSegmentAmbiguities(ConflictsList, LoadedValuesString);
			
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
	
	#Region PartnerGoodsSegmentsCancellation
	Item = Settings.Add();
	
	Item.Fields.Add("GoodsSegments.Canceled");
	Item.Fields.Add("PartnersSegments.Canceled");
	
	ConfigurationModule.NewFilter(Item.Condition, "Patch", True);
	
	Item.Properties.Insert("Visible", True);
	#EndRegion
	
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
	
	Item.Fields.Add("Counterparties");
	Item.Fields.Add("Counterparties.Counterparty");
	Item.Fields.Add("Counterparties.Partner");
	Item.Fields.Add("CounterpartiesTIN");
	Item.Fields.Add("CounterpartiesTIN.TIN");
	
	ConfigurationModule.NewFilter(Item.Condition, "FilterParties", ListCompositions.ExceptForSelectedOnes);
	ConfigurationModule.NewFilter(Item.Condition, "More.ThereAreAccruals", True);
	
	Item.Properties.Insert("ReadOnly", True);
	
	// Commands of participants
	Item = Settings.Add();
	
	Item.Fields.Add("CounterpartiesDownloadCounterpartiesFromFile");
	Item.Fields.Add("CounterpartiesTINDownloadCounterpartyTINFromFile");
	
	ConfigurationModule.NewFilter(Item.Condition, "FilterParties", ListCompositions.ExceptForSelectedOnes);
	ConfigurationModule.NewFilter(Item.Condition, "More.ThereAreAccruals", True);
	
	Item.Properties.Insert("Enabled", False);
	#EndRegion
	
	SettingUpTableOfParticipants(Settings, ConfigurationModule);
	SettingUpCounterpartyTINTable(Settings, ConfigurationModule);
	SettingUpContractAgreementsTable(Settings, ConfigurationModule);
	SettingUpPartnerSegmentsTable(Settings, ConfigurationModule);
	SettingUpGoodsTable(Settings, ConfigurationModule);
	SettingUpGoodsSegmentsTable(Settings, ConfigurationModule);
	SettingUpItemPropertiesTable(Settings, ConfigurationModule);
	SettingUpCalculationScaleTable(Settings, ConfigurationModule);
	
	SettingUpCalculationScaleGroupField(Settings, ConfigurationModule);
	SettingUpFieldDetailingCalculationOfParticipants(Settings, ConfigurationModule);
	SettingUpCurrencyField(Settings, ConfigurationModule);
	SettingUpBonusPercentageField(Settings, ConfigurationModule);
	SettingUpFieldSelectionOfParticipants(Settings, ConfigurationModule);
	SettingUpSelectionOfGoodsField(Settings, ConfigurationModule);
	SettingUpConditionTimeFenceField(Settings, ConfigurationModule);
	SettingUpAccrualTimeFenceField(Settings, ConfigurationModule);
	SettingUpAmountPlanField(Settings, ConfigurationModule);
	SettingUpFieldProhibitingAccrualsOverPlan(Settings, ConfigurationModule);
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
	
	FullDocumentName = "Document.ConditionsOfCustomerRebates";
	SynonymForDocumentTable = "";
	RequestHasSource = True;
	
	ParameterValues = ValuesOfHoldingParameters();
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting", """""");
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	Else
		
		ExceptionPattern = NStr("vi = 'Trong chứng từ %1 chưa tạo điều chỉnh nội dung truy vấn lập bản ghi kết chuyển theo biểu ghi %2.';
								|ru = 'В документе %1 не реализована адаптация текста запроса формирования движений по регистру %2.';
								|en = 'In the %1 document, adaptation of request for generating records of the %2 register is not implemented.'; fa = 'In the %1 document, adaptation of request for generating records of the %2 register is not implemented.';
								|it = 'В документе %1 не реализована адаптация текста запроса формирования движений по регистру %2.';
								|pl = 'W dokumencie %1 nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %2.';
								|tr = '%1 belgesinde, %2 kaydına göre hareketlerin düzenlenmesi isteğinin metin uyarlaması uygulanmadı.'");
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
	
	If GetFunctionalOption("DisplayFullNamesOfCustomerRebates") Then
		
		If Patch Then
			DocumentHeaderTemplate = NStr("vi = 'Điều chỉnh điều kiện thưởng lũy kế cho khách hàng %1';
											|ru = 'Корректировка условий ретро-бонусов клиентов %1';
											|en = 'Correct conditions of customer rebates %1'; fa = 'Correct conditions of customer rebates %1';
											|it = 'Корректировка условий ретро-бонусов клиентов %1';
											|pl = 'Correct conditions of customer rebates %1';
											|tr = '%1 müşterilerinin retro bonuslarının şartlarının düzeltilmesi'");
		Else
			DocumentHeaderTemplate = NStr("vi = 'Điều kiện thưởng lũy kế cho khách hàng %1';
											|ru = 'Условия ретро-бонусов клиентов %1';
											|en = 'Conditions of customer rebates %1'; fa = 'Conditions of customer rebates %1';
											|it = 'Условия ретро-бонусов клиентов %1';
											|pl = 'Conditions of customer rebates %1';
											|tr = '%1 müşterilerinin retro bonuslarının şartları'");
		EndIf;
		
	Else
		
		If Patch Then
			DocumentHeaderTemplate = NStr("vi = 'Điều chỉnh điều kiện thưởng lũy kế cho khách hàng %1';
											|ru = 'Корректировка условий ретро-бонусов клиентов %1';
											|en = 'Correct conditions of customer rebates %1'; fa = 'Correct conditions of customer rebates %1';
											|it = 'Корректировка условий ретро-бонусов клиентов %1';
											|pl = 'Correct conditions of customer rebates %1';
											|tr = '%1 müşterilerinin retro bonuslarının şartlarının düzeltilmesi'");
		Else
			DocumentHeaderTemplate = NStr("vi = 'Điều kiện thưởng lũy kế cho khách hàng %1';
											|ru = 'Условия РБ клиентов %1';
											|en = 'Terms of customer rebates %1'; fa = 'Terms of customer rebates %1';
											|it = 'Условия РБ клиентов %1';
											|pl = 'Terms of customer rebates %1';
											|tr = '%1 müşterilerinin retro bonuslarının şartları'");
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
	|	AND DocumentsRegistry.CorrectedDocument = VALUE(Document.ConditionsOfCustomerRebates.EmptyRef)
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
		|	Document.ConditionsOfCustomerRebates.GoodsSegments AS GoodsSegments
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
		|	InformationRegister.CustomerRebatesItemSegments AS GoodsSegments
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
// * Organization - CatalogRef.Companies -
// * Currency - CatalogRef.Currencies -
// * ValidOnDate- Date -
// * ValidTo- Date -
// * FilterParties - EnumRef.RebatesLists
// * PartyCountDetails - EnumRef.ARAPAccountingDrilldownsOfRebatesParticipants
// * SumPlan - DefinedType.MonetaryAmountNonNegative -
// * Patch - Boolean -
// * CorrectedDocument - DocumentRef.ConditionsOfCustomerRebates -
//
Function DocumentAttributes(Query)
	
	Query.Text =
	"SELECT
	|	DocumentData.Date AS Date,
	|	DocumentData.Number AS Number,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.ValidOnDate AS ValidOnDate,
	|	DocumentData.ValidTo AS ValidTo,
	|	DocumentData.FilterParties AS FilterParties,
	|	DocumentData.PartyCountDetails AS PartyCountDetails,
	|	DocumentData.SumPlan AS SumPlan,
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
		Common.MetadataObjectID("Document.ConditionsOfCustomerRebates"));
	
	If Attributes <> Undefined Then
		
		Values.Insert(
			"NumberForPrinting",
			ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
		
		Values.Insert("Period", Attributes.Date);
		Values.Insert("Organization", Attributes.Organization);
		Values.Insert("Currency", Attributes.Currency);
		Values.Insert("ValidOnDate", Attributes.ValidOnDate);
		Values.Insert("ValidTo", Attributes.ValidTo);
		Values.Insert("FilterParties", Attributes.FilterParties);
		Values.Insert("PartyCountDetails", Attributes.PartyCountDetails);
		Values.Insert("SumPlan", Attributes.SumPlan);
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
		
		QueryText = StrReplace(QueryText, "DocumentDataHeader", "Document.ConditionsOfCustomerRebates");
		
	Else
		
		QueryText = StrReplace(QueryText, "&NumberForPrinting", "DocumentData.Number");
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableConditions(QueryTexts, Registers, DocumentObject)
	
	RegisterName = "CustomerRebatesConditions";
	
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
	|	DocumentData.RebateKind AS Kind,
	|	DocumentData.LongDesc AS LongDesc,
	|	DocumentData.PartyList AS PartyList,
	|	DocumentData.FilterParties AS Attendees,
	|	DocumentData.ContentOfGoods AS ContentOfGoods,
	|	DocumentData.FilterOfProducts_ AS Goods,
	|	DocumentData.ConsiderVAT AS ConsiderVAT,
	|	DocumentData.BonusPercent AS BonusPercent,
	|	DocumentData.SumPlan AS SumPlan,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.ConditionFrequency AS ConditionFrequency,
	|	DocumentData.AccrualFrequency AS AccrualFrequency,
	|	DocumentData.PartyCountDetails AS PartyCountDetails,
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

Function QueryTextTableCounterparties(QueryTexts, Registers, DocumentObject)
	
	RegisterName = "CustomerRebatesCounterparties";
	
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
	|	TableData.Partner AS Partner,
	|	CASE
	|		WHEN &FilterParties <> VALUE(Enum.RebatesLists.Selected_)
	|			THEN 0
	|		WHEN TableData.PlanIsNotSpecified
	|			THEN 0
	|		WHEN TableData.SumPlan = 0
	|			THEN &SumPlan
	|		ELSE TableData.SumPlan
	|	END AS SumPlan,
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

Function QueryTextTableCounterpartiesTIN(QueryTexts, Registers, DocumentObject)
	
	RegisterName = "CustomerRebatesTIN";
	
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
	|	CASE
	|		WHEN &FilterParties <> VALUE(Enum.RebatesLists.Selected_)
	|			THEN 0
	|		WHEN &PartyCountDetails = VALUE(Enum.ARAPAccountingDrilldownsOfRebatesParticipants.ByCustomer)
	|			THEN 0
	|		WHEN TableData.SumPlan = 0
	|			THEN &SumPlan
	|		ELSE TableData.SumPlan
	|	END AS SumPlan,
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

Function QueryTextTablePartnersSegments(QueryTexts, Registers, DocumentObject)
	
	RegisterName = "CustomerRebatesPartnerSegments";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers)
	 Or DocumentObject.Status <> Enums.RebatesDocumentStatuses.Approved
	 Or DocumentObject.FilterParties = Enums.RebatesLists.All Then
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
	|	DocumentDataTablePartnerSegments AS TableData
	|WHERE
	|	TableData.Ref = &Ref
	|	AND NOT TableData.Canceled";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableContractsTermsOfSales(QueryTexts, Registers, DocumentObject)
	
	RegisterName = "CustomerRebatesContractsTermsOfSales";
	
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
	|	TableData.Contract AS Contract,
	|	TableData.Terms AS Terms,
	|	CASE
	|		WHEN TableData.PlanIsNotSpecified
	|			THEN 0
	|		WHEN TableData.SumPlan = 0
	|			THEN &SumPlan
	|		ELSE TableData.SumPlan
	|	END AS SumPlan,
	|	TableData.SalesSpecialByStandard AS IncludeSalesBySpecialTermsOfSales,
	|	TableData.LineNumber AS DocumentRowNumber,
	|	TableData.Ref AS RecorderDocument
	|FROM
	|	DocumentDataTableContractAgreements AS TableData
	|WHERE
	|	TableData.Ref = &Ref
	|	AND NOT TableData.Canceled";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableGoods(QueryTexts, Registers, DocumentObject)
	
	RegisterName = "CustomerRebatesItems";
	
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
	|	TableData.BasePrice AS BasePrice,
	|	TableData.LineNumber AS DocumentRowNumber,
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
	
	RegisterName = "CustomerRebatesItemProperties";
	
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

Function QueryTextTableGoodsSegments(QueryTexts, Registers, DocumentObject)
	
	RegisterName = "CustomerRebatesItemSegments";
	
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

Function QueryTextTableCustomerRebates(QueryTexts, Registers, DocumentObject)
	
	RegisterName = "CustomerRebates";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers)
	 Or DocumentObject.Status <> Enums.RebatesDocumentStatuses.Approved
	 Or Not DocumentObject.AccrueImmediately Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	TableData.Counterparty AS Counterparty,
	|	TableData.Partner AS Partner,
	|	CASE
	|		WHEN TableData.ValidOnDate = DATETIME(1, 1, 1)
	|			THEN &ValidOnDate
	|		ELSE TableData.ValidOnDate
	|	END AS BeginOfPeriod,
	|	CASE
	|		WHEN TableData.ValidTo = DATETIME(1, 1, 1)
	|			THEN &ValidTo
	|		ELSE TableData.ValidTo
	|	END AS PeriodEnding,
	|	TableData.Ref AS TermDocument,
	|	&Currency AS Currency,
	|	TableData.AmountBonus AS AmountBonus,
	|	0 AS ToCertify,
	|	0 AS ToSign,
	|	0 AS ToWriteOff
	|FROM
	|	DocumentDataTableCounterparties AS TableData
	|WHERE
	|	TableData.Ref = &Ref
	|	AND NOT TableData.Canceled";
	
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
	QueryTextDataTableOfCounterpartiesTIN(ListOfRequests);
	QueryTextDataTableCounterparties(ListOfRequests);
	QueryTextDataTableContractsAgreements(ListOfRequests);
	QueryTextDataTableGoods(ListOfRequests);
	QueryTextDataTableItemProperties(ListOfRequests);
	QueryTextDataTablePartnerSegments(ListOfRequests);
	QueryTextDataTableGoodsSegments(ListOfRequests);
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
	|	DocumentData.LongDesc AS LongDesc,
	|	DocumentData.RebateKind AS RebateKind,
	|	DocumentData.RebateKind.PartyList AS PartyList,
	|	DocumentData.FilterParties AS FilterParties,
	|	DocumentData.RebateKind.ContentOfGoods AS ContentOfGoods,
	|	DocumentData.FilterOfProducts_ AS FilterOfProducts_,
	|	DocumentData.RebateKind.ConsiderVAT AS ConsiderVAT,
	|	DocumentData.AccrueImmediately AS AccrueImmediately,
	|	DocumentData.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.ConditionFrequency AS ConditionFrequency,
	|	DocumentData.AccrualFrequency AS AccrualFrequency,
	|	DocumentData.SumPlan AS SumPlan,
	|	DocumentData.BonusPercent AS BonusPercent,
	|	DocumentData.PartyCountDetails AS PartyCountDetails,
	|	DocumentData.CalculationScaleType AS CalculationScaleType,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
	|	DocumentData.Patch AS Patch,
	|	DocumentData.ReversedDocument AS ReversedDocument,
	|	DocumentData.CorrectedDocument AS CorrectedDocument
	|INTO DocumentDataHeader
	|FROM
	|	Document.ConditionsOfCustomerRebates AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
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
	|	DataTable.Partner AS Partner,
	|	DataTable.SumPlan AS SumPlan,
	|	DataTable.PlanIsNotSpecified AS PlanIsNotSpecified,
	|	DataTable.AmountBonus AS AmountBonus,
	|	DataTable.ValidOnDate AS ValidOnDate,
	|	DataTable.ValidTo AS ValidTo,
	|	DataTable.Canceled AS Canceled
	|INTO DocumentDataTableCounterparties
	|FROM
	|	Document.ConditionsOfCustomerRebates.Counterparties AS DataTable
	|WHERE
	|	DataTable.Ref = &Ref
	|
	|INDEX BY
	|	Ref";
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

Procedure QueryTextDataTableOfCounterpartiesTIN(ListOfRequests)
	
	QueryText =
	"SELECT
	|	DataTable.Ref AS Ref,
	|	DataTable.LineNumber AS LineNumber,
	|	DataTable.TIN AS TIN,
	|	DataTable.SumPlan AS SumPlan,
	|	DataTable.ValidOnDate AS ValidOnDate,
	|	DataTable.ValidTo ValidTo,
	|	DataTable.Canceled AS Canceled
	|INTO DocumentDataTINTable
	|FROM
	|	Document.ConditionsOfCustomerRebates.CounterpartiesTIN AS DataTable
	|WHERE
	|	DataTable.Ref = &Ref
	|
	|INDEX BY
	|	Ref";
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

Procedure QueryTextDataTableContractsAgreements(ListOfRequests)
	
	QueryText =
	"SELECT
	|	DataTable.Ref AS Ref,
	|	DataTable.LineNumber AS LineNumber,
	|	DataTable.Contract AS Contract,
	|	DataTable.Terms AS Terms,
	|	DataTable.SalesSpecialByStandard AS SalesSpecialByStandard,
	|	DataTable.SumPlan AS SumPlan,
	|	DataTable.PlanIsNotSpecified AS PlanIsNotSpecified,
	|	DataTable.ValidOnDate AS ValidOnDate,
	|	DataTable.ValidTo AS ValidTo,
	|	DataTable.Canceled AS Canceled
	|INTO DocumentDataTableContractAgreements
	|FROM
	|	Document.ConditionsOfCustomerRebates.ContractsTermsOfSales AS DataTable
	|WHERE
	|	DataTable.Ref = &Ref
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
	|	DataTable.Percent AS Percent,
	|	DataTable.ValidOnDate AS ValidOnDate,
	|	DataTable.ValidTo AS ValidTo,
	|	DataTable.Canceled AS Canceled
	|INTO DocumentDataTableItems
	|FROM
	|	Document.ConditionsOfCustomerRebates.Goods AS DataTable
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
	|	Document.ConditionsOfCustomerRebates.ProductProperties_ AS DataTable
	|WHERE
	|	DataTable.Ref = &Ref
	|
	|INDEX BY
	|	Ref";
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

Procedure QueryTextDataTablePartnerSegments(ListOfRequests)
	
	QueryText =
	"SELECT
	|	DataTable.Ref AS Ref,
	|	DataTable.LineNumber AS LineNumber,
	|	DataTable.Segment AS Segment,
	|	DataTable.Canceled AS Canceled
	|INTO DocumentDataTablePartnerSegments
	|FROM
	|	Document.ConditionsOfCustomerRebates.PartnersSegments AS DataTable
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
	|	Document.ConditionsOfCustomerRebates.GoodsSegments AS DataTable
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
	|	Document.ConditionsOfCustomerRebates.CalculationScales AS DataTable
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
	MemberOptions = New ValueList; // ValueList of EnumRef.RebatesParticipants
	MemberOptions.Add(Enums.RebatesParticipants.Customers);
	MemberOptions.Add(Enums.RebatesParticipants.Counterparties);
	
	Item = Settings.Add();
	
	Item.Fields.Add("Counterparties");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.NewFilter(OrGroup, "FilterParties", ListCompositions.All);
	ConfigurationModule.NewFilter(
		OrGroup,
		"More.PartyList",
		MemberOptions,
		,
		DataCompositionComparisonType.NotInList);
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
	FilterofFields = BasicSelectionOfPeriodsOfTablesOfParticipants(ConfigurationModule);
	SettingUpTablePeriodFields(Settings, ConfigurationModule, "Counterparties", FilterofFields);
	SettingUpTableOfParticipantsFieldCounterpartiesAmountPlan(Settings, ConfigurationModule);
	FieldSetupCanceled(Settings, ConfigurationModule, "Counterparties.Canceled");
	SettingUpDecorationFieldCounterpartiesThereAreCharges(Settings, ConfigurationModule);
	SettingUpCommandsForFillingInParticipantTable(Settings, ConfigurationModule);
	
EndProcedure

Procedure SettingUpTableOfParticipantsFieldCounterpartiesAmountPlan(Settings, ConfigurationModule)
	
	LineUpsOfParticipants = Enums.RebatesParticipants;
	ListCompositions = Enums.RebatesLists;
	SalesFigures = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	ShouldDetailCalculation = Enums.ARAPAccountingDrilldownsOfRebatesParticipants;
	
	#Region BasicSelection
	FilterofFields = New DataCompositionFilter();
	
	OrGroup = RebatesServer.NewFiltersGroup(FilterofFields);
	ConfigurationModule.NewFilter(OrGroup, "CalculationScaleType", 0,, DataCompositionComparisonType.NotEqual);
	ConfigurationModule.NewFilter(OrGroup, "WithoutCalculation", True);
	ConfigurationModule.NewFilter(OrGroup, "FilterParties", ListCompositions.ExceptForSelectedOnes);
	ConfigurationModule.NewFilter(
		OrGroup, "More.GoodsIndicator", SalesFigures.Sum,, DataCompositionComparisonType.NotEqual);
	
	AndGroup = RebatesServer.NewFiltersGroup(OrGroup, DataCompositionFilterItemsGroupType.AndGroup);
	ConfigurationModule.NewFilter(AndGroup, "PartyCountDetails", ShouldDetailCalculation.ByCounterparty);
	ConfigurationModule.NewFilter(AndGroup, "More.PartyList", LineUpsOfParticipants.Customers);
	
	AndGroup = RebatesServer.NewFiltersGroup(OrGroup, DataCompositionFilterItemsGroupType.AndGroup);
	ConfigurationModule.NewFilter(AndGroup, "PartyCountDetails", ShouldDetailCalculation.ByCustomer);
	ConfigurationModule.NewFilter(AndGroup, "More.PartyList", LineUpsOfParticipants.Counterparties);
	#EndRegion
	
	#Region AmountPlanVisibility
	Item = Settings.Add();
	
	Item.Fields.Add("Counterparties.SumPlan");
	
	ConfigurationModule.CopyFilter(FilterofFields, Item.Condition);
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
	#Region AmountOfPlanIsViewOnly
	Item = Settings.Add();
	
	Item.Fields.Add("Counterparties.SumPlan");
	
	ConfigurationModule.NewFilter(Item.Condition, "More.ThereAreAccruals", True);
	
	Item.Properties.Insert("ReadOnly", True);
	#EndRegion
	
	#Region AmountPlanBeforeChange
	Item = Settings.Add();
	
	Item.Fields.Add("Counterparties.AmountPlanBeforeChange");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.CopyFilter(FilterofFields, OrGroup);
	ConfigurationModule.NewFilter(OrGroup, "Patch", False);
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
EndProcedure

Procedure SettingUpDecorationFieldCounterpartiesThereAreCharges(Settings, ConfigurationModule)
	
	ListCompositions = Enums.RebatesLists;
	LineUpsOfParticipants = Enums.RebatesParticipants;
	
	Item = Settings.Add();
	
	Item.Fields.Add("DecorationCounterpartiesHaveAccruals");
	
	ConfigurationModule.NewFilter(Item.Condition, "FilterParties", ListCompositions.ExceptForSelectedOnes);
	ConfigurationModule.NewFilter(Item.Condition, "More.ThereAreAccruals", True);
	
	CompositionOfParticipantsOfTable = New ValueList; // ValueList of EnumRef.RebatesParticipants
	CompositionOfParticipantsOfTable.Add(LineUpsOfParticipants.Counterparties);
	CompositionOfParticipantsOfTable.Add(LineUpsOfParticipants.Customers);
	
	ConfigurationModule.NewFilter(
		Item.Condition,
		"More.PartyList",
		CompositionOfParticipantsOfTable,
		,
		DataCompositionComparisonType.InList);
	
	Item.Properties.Insert("Visible", True);
	
EndProcedure

Procedure SettingUpCommandsForFillingInParticipantTable(Settings, ConfigurationModule)
	
	LineUpsOfParticipants = Enums.RebatesParticipants;
	
	Item = Settings.Add();
	
	Item.Fields.Add("CounterpartiesFillInBySegment");
	
	ConfigurationModule.NewFilter(Item.Condition, "More.PartyList", LineUpsOfParticipants.Counterparties);
	
	Item.Properties.Insert("Visible", False);
	
EndProcedure

#EndRegion

#Region SettingUpCounterpartyTINTable

Procedure SettingUpCounterpartyTINTable(Settings, ConfigurationModule)
	
	ListCompositions = Enums.RebatesLists;
	
	#Region GeneralListVisibilitySettings
	Item = Settings.Add();
	
	Item.Fields.Add("CounterpartiesTIN");
	
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
	SettingUpTablePeriodFields(Settings, ConfigurationModule, "CounterpartiesTIN", FilterofFields);
	SettingUpCounterpartyTINTableAmountFieldPlan(Settings, ConfigurationModule);
	FieldSetupCanceled(Settings, ConfigurationModule, "CounterpartiesTIN.Canceled");
	SettingUpDecorationTINFieldThereAreCharges(Settings, ConfigurationModule);
	
EndProcedure

Procedure SettingUpCounterpartyTINTableAmountFieldPlan(Settings, ConfigurationModule)
	
	LineUpsOfParticipants = Enums.RebatesParticipants;
	ListCompositions = Enums.RebatesLists;
	SalesFigures = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	ShouldDetailCalculation = Enums.ARAPAccountingDrilldownsOfRebatesParticipants;
	
	#Region BasicSelection
	FilterofFields = New DataCompositionFilter();
	
	OrGroup = RebatesServer.NewFiltersGroup(FilterofFields);
	ConfigurationModule.NewFilter(OrGroup, "CalculationScaleType", 0,, DataCompositionComparisonType.NotEqual);
	ConfigurationModule.NewFilter(OrGroup, "FilterParties", ListCompositions.ExceptForSelectedOnes);
	ConfigurationModule.NewFilter(
		OrGroup,
		"More.GoodsIndicator",
		SalesFigures.Sum,
		,
		DataCompositionComparisonType.NotEqual);
	
	AndGroup = RebatesServer.NewFiltersGroup(OrGroup, DataCompositionFilterItemsGroupType.AndGroup);
	ConfigurationModule.NewFilter(AndGroup, "More.GoodsIndicator", SalesFigures.Sum);
	ConfigurationModule.NewFilter(AndGroup, "CalculationScaleType", 0,, DataCompositionComparisonType.NotEqual); // Not the only value (in this case, we prohibit line-by-line refinement)
	
	AndGroup = RebatesServer.NewFiltersGroup(OrGroup, DataCompositionFilterItemsGroupType.AndGroup);
	ConfigurationModule.NewFilter(AndGroup, "PartyCountDetails", ShouldDetailCalculation.ByCustomer);
	ConfigurationModule.NewFilter(AndGroup, "More.PartyList", LineUpsOfParticipants.TIN);
	#EndRegion
	
	#Region AmountPlanVisibility
	Item = Settings.Add();
	
	Item.Fields.Add("CounterpartiesTIN.SumPlan");
	
	ConfigurationModule.CopyFilter(FilterofFields, Item.Condition);
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
	#Region AmountOfPlanIsViewOnly
	Item = Settings.Add();
	
	Item.Fields.Add("CounterpartiesTIN.SumPlan");
	
	ConfigurationModule.NewFilter(Item.Condition, "More.ThereAreFixes", True);
	
	Item.Properties.Insert("ReadOnly", True);
	#EndRegion
	
	#Region AmountPlanBeforeChange
	Item = Settings.Add();
	
	Item.Fields.Add("CounterpartiesTIN.AmountPlanBeforeChange");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.CopyFilter(FilterofFields, OrGroup);
	ConfigurationModule.NewFilter(OrGroup, "Patch", False);
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
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

#Region SettingUpContractAgreementsTable
Procedure SettingUpContractAgreementsTable(Settings, ConfigurationModule);
	
	LineUpsOfParticipants = Enums.RebatesParticipants;
		
	#Region Contract
	Item = Settings.Add();
	
	Item.Fields.Add("ContractsTermsOfSales.Contract");
	
	ConfigurationModule.NewFilter(
		Item.Condition,
		"More.PartyList",
		LineUpsOfParticipants.Contracts,
		,
		DataCompositionComparisonType.NotEqual);
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
	#Region Terms
	Item = Settings.Add();
	
	Item.Fields.Add("ContractsTermsOfSales.Terms");
	Item.Fields.Add("ContractsTermsOfSalesAgreementType");
	
	ConfigurationModule.NewFilter(
		Item.Condition,
		"More.PartyList",
		LineUpsOfParticipants.Terms1,
		,
		DataCompositionComparisonType.NotEqual);
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
		
	FilterofFields = BasicSelectionOfPeriodsOfTablesOfParticipants(ConfigurationModule);
	SettingUpTablePeriodFields(Settings, ConfigurationModule, "ContractsTermsOfSales", FilterofFields);
	SettingUpContractAgreementsTableSalesFieldIsIndividualByStandard(Settings, ConfigurationModule);
	SettingUpContractAgreementsTableAmountPlanField(Settings, ConfigurationModule);
	FieldSetupCanceled(Settings, ConfigurationModule, "ContractsTermsOfSales.Canceled");
	
EndProcedure

Procedure SettingUpContractAgreementsTableSalesFieldIsIndividualByStandard(Settings, ConfigurationModule)
	
	#Region Visible
	Item = Settings.Add();
	
	Item.Fields.Add("ContractsTermsOfSales.SalesSpecialByStandard");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	
	ConfigurationModule.NewFilter(
		OrGroup,
		"More.PartyList",
		Enums.RebatesParticipants.Terms1,
		,
		DataCompositionComparisonType.NotEqual);
	
	ConfigurationModule.NewFilter(
		OrGroup,
		"More.UseStandardAndIndividualTermsOfSalesWithCustomers",
		False);
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
EndProcedure

Procedure SettingUpContractAgreementsTableAmountPlanField(Settings, ConfigurationModule)
	
	LineUpsOfParticipants = Enums.RebatesParticipants;
	ShouldDetailCalculation = Enums.ARAPAccountingDrilldownsOfRebatesParticipants;
	SalesFigures = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	FilterofFields = New DataCompositionFilter();
	
	#Region BasicSelection
	OrGroup = RebatesServer.NewFiltersGroup(FilterofFields);
	ConfigurationModule.NewFilter(OrGroup, "CalculationScaleType", 0,, DataCompositionComparisonType.NotEqual);
	ConfigurationModule.NewFilter(
		OrGroup,
		"More.GoodsIndicator",
		SalesFigures.Sum,
		,
		DataCompositionComparisonType.NotEqual);
	
	ConfigurationModule.NewFilter(
		OrGroup,
		"PartyCountDetails",
		ShouldDetailCalculation.ByCounterparty,
		,
		DataCompositionComparisonType.NotEqual);
	
	ConfigurationModule.NewFilter(
		OrGroup,
		"More.PartyList",
		LineUpsOfParticipants.Contracts,
		,
		DataCompositionComparisonType.NotEqual);
	#EndRegion
	
	#Region AmountPlanVisibility
	Item = Settings.Add();
	
	Item.Fields.Add("ContractsTermsOfSales.SumPlan");
	
	ConfigurationModule.CopyFilter(FilterofFields, Item.Condition);
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
	#Region AmountOfPlanIsViewOnly
	Item = Settings.Add();
	
	Item.Fields.Add("ContractsTermsOfSales.SumPlan");
	
	ConfigurationModule.NewFilter(Item.Condition, "More.ThereAreAccruals", True);
	
	Item.Properties.Insert("ReadOnly", True);
	#EndRegion
	
	#Region AmountPlanBeforeChange
	Item = Settings.Add();
	
	Item.Fields.Add("ContractsTermsOfSales.AmountPlanBeforeChange");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.CopyFilter(FilterofFields, OrGroup);
	ConfigurationModule.NewFilter(OrGroup, "Patch", False);
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
EndProcedure

#EndRegion

Procedure SettingUpPartnerSegmentsTable(Settings, ConfigurationModule)
	
	ListCompositions = Enums.RebatesLists;
	
	#Region GeneralListVisibilitySettings
	Item = Settings.Add();
	
	Item.Fields.Add("PartnersSegments");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.NewFilter(OrGroup, "FilterParties", ListCompositions.All);
	ConfigurationModule.NewFilter(
		OrGroup,
		"More.PartyList",
		Enums.RebatesParticipants.PartnersSegments,
		,
		DataCompositionComparisonType.NotEqual);
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
EndProcedure

#Region SettingUpGoodsTable

Procedure SettingUpGoodsTable(Settings, ConfigurationModule)
	
	ListCompositions = Enums.RebatesLists;
	GoodsIndicators= Enums.TargetSalesIndicatorsOfRebatesByGoods;
	
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
	
	ConfigurationModule.NewFilter(Item.Condition, "More.SalesCalculationBase", SalesDatabases.RevenueBasePrices);
	
	Item.Properties.Insert("Visible", True);
	
EndProcedure

Procedure SettingUpGoodsQuantityPlanField(Settings, ConfigurationModule)
	
	ListCompositions = Enums.RebatesLists;
	GoodsIndicators = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	
	Item = Settings.Add();
	
	Item.Fields.Add("Goods.CountPlan");
	Item.Fields.Add("GoodsProductsUnitOfMeasure");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	
	ConfigurationModule.NewFilter(OrGroup, "FilterOfProducts_", ListCompositions.ExceptForSelectedOnes);
	
	ExclIndicators = New ValueList; // ValueList of EnumRef.TargetSalesIndicatorsOfRebatesByGoods
	ExclIndicators.Add(GoodsIndicators.Count);
	ExclIndicators.Add(GoodsIndicators.QuantityTotal);
	ExclIndicators.Add(GoodsIndicators.BatchOffer);
	ConfigurationModule.NewFilter(
		OrGroup, "More.GoodsIndicator", ExclIndicators,, DataCompositionComparisonType.NotInList);
	
	Item.Properties.Insert("Visible", False);
	
EndProcedure

Procedure SettingUpDecorationGoodsFieldThereAreCharges(Settings, ConfigurationModule)
	
	ListCompositions = Enums.RebatesLists;
	SalesFigures = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	
	Item = Settings.Add();
	
	Item.Fields.Add("DecorationGoodsThereAreAccruals");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.NewFilter(OrGroup, "FilterOfProducts_", ListCompositions.ExceptForSelectedOnes);
	
	ExclIndicators = New ValueList; // ValueList of EnumRef.TargetSalesIndicatorsOfRebatesByGoods
	ExclIndicators.Add(SalesFigures.QuantityTotal);
	ExclIndicators.Add(SalesFigures.BatchOffer);
	ConfigurationModule.NewFilter(
		OrGroup, "More.GoodsIndicator", ExclIndicators,, DataCompositionComparisonType.InList);
	ConfigurationModule.NewFilter(Item.Condition, "More.ThereAreAccruals", True);
	ConfigurationModule.NewFilter(
		Item.Condition,
		"More.ContentOfGoods",
		Enums.RebatesItems.Products,);
	
	Item.Properties.Insert("Visible", True);
	
EndProcedure

Procedure ConfiguringCommandsForFillingInGoodsTable(Settings, ConfigurationModule)
	
	GoodsIndicators = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	ListCompositions = Enums.RebatesLists;
	
	#Region AvailabilityByAccrualAvailability
	Item = Settings.Add();
	
	Item.Fields.Add("GoodsFillBonusPercentage");
	Item.Fields.Add("GoodsFillInQuantityPlan");
	Item.Fields.Add("GoodsToFillInBySegment");
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
	
	#Region GoodsFillBonusPercentage
	Item = Settings.Add();
	
	Item.Fields.Add("GoodsFillBonusPercentage");
	
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
	
	#Region GoodsFillInQuantityPlan
	Item = Settings.Add();
	
	Item.Fields.Add("GoodsFillInQuantityPlan");
	
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
	
	ConfigurationModule.NewFilter(Item.Condition, "More.SalesCalculationBase", SalesDatabases.RevenueBasePrices);
	
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
	
	#Region Visible
	Item = Settings.Add();
	
	Item.Fields.Add("Currency");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	
	AndGroup = RebatesServer.NewFiltersGroup(OrGroup, DataCompositionFilterItemsGroupType.AndGroup);
	ConfigurationModule.NewFilter(AndGroup, "WithoutCalculation", False);
	ConfigurationModule.NewFilter(AndGroup, "More.SalesCalculationBase", SalesDatabase.RevenueARAPAccounting);
	
	AndGroup = RebatesServer.NewFiltersGroup(OrGroup, DataCompositionFilterItemsGroupType.AndGroup);
	ConfigurationModule.NewFilter(AndGroup, "Organization", Catalogs.Companies.EmptyRef());
	ConfigurationModule.NewFilter(
		AndGroup,
		"More.SalesCalculationBase",
		SalesDatabase.RevenueLocalAccounting,
		,
		DataCompositionComparisonType.Equal);
	
	ConfigurationModule.NewFilter(OrGroup, "RebateKind", Catalogs.CustomerRebatesKinds.EmptyRef());
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
	#Region ReadOnly
	Item = Settings.Add();
	
	Item.Fields.Add("Currency");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.NewFilter(OrGroup, "WithoutCalculation", True);
	
	AndGroup = RebatesServer.NewFiltersGroup(OrGroup, DataCompositionFilterItemsGroupType.AndGroup);
	ConfigurationModule.NewFilter(
		AndGroup,
		"More.SalesCalculationBase",
		SalesDatabase.RevenueBasePrices);
	ConfigurationModule.NewFilter(AndGroup, "Patch", False);
	
	Item.Properties.Insert("ReadOnly", False);
	#EndRegion
	
EndProcedure

Procedure SettingUpBonusPercentageField(Settings, ConfigurationModule)
	
	ListCompositions = Enums.RebatesLists;
	
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
		ListCompositions.Selected_,
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
	
	LineUpsOfParticipants = Enums.RebatesParticipants;
	ListOfParticipantsView = New ValueList; // ValueList of EnumRef.RebatesParticipants
	ListOfParticipantsView.Add(LineUpsOfParticipants.Contracts);
	ListOfParticipantsView.Add(LineUpsOfParticipants.Terms1);
	
	#Region Visible
	Item = Settings.Add();
	
	Item.Fields.Add("FilterParties");
	
	ConfigurationModule.NewFilter(Item.Condition, "RebateKind", Catalogs.CustomerRebatesKinds.EmptyRef());
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
	#Region ReadOnly
	Item = Settings.Add();
	
	Item.Fields.Add("FilterParties");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.NewFilter(OrGroup, "Patch", True);
	ConfigurationModule.NewFilter(OrGroup, "WithoutCalculation", True);
	ConfigurationModule.NewFilter(
		OrGroup,
		"More.PartyList",
		ListOfParticipantsView,
		,
		DataCompositionComparisonType.InList);
	
	Item.Properties.Insert("ReadOnly", True);
	#EndRegion
	
EndProcedure

Procedure SettingUpSelectionOfGoodsField(Settings, ConfigurationModule)
	
	SalesDatabases = Enums.RebateCalculationBases;
	SalesFigures = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	
	#Region Visible
	Item = Settings.Add();
	
	Item.Fields.Add("FilterOfProducts_");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.NewFilter(OrGroup, "RebateKind", Catalogs.CustomerRebatesKinds.EmptyRef());
	ConfigurationModule.NewFilter(OrGroup, "WithoutCalculation", True);
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
	#Region ReadOnly
	Item = Settings.Add();
	
	Item.Fields.Add("FilterOfProducts_");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.NewFilter(OrGroup, "Patch", True);
	ConfigurationModule.NewFilter(OrGroup, "WithoutCalculation", True);
	
	ExclIndicators = New ValueList; // ValueList of EnumRef.TargetSalesIndicatorsOfRebatesByGoods
	ExclIndicators.Add(SalesFigures.NotUsed);
	ExclIndicators.Add(SalesFigures.Sum);
	ConfigurationModule.NewFilter(
		OrGroup, "More.GoodsIndicator", ExclIndicators,, DataCompositionComparisonType.NotInList);
	
	ConfigurationModule.NewFilter(OrGroup, "More.SalesCalculationBase", SalesDatabases.RevenueBasePrices);
	
	Item.Properties.Insert("ReadOnly", True);
	#EndRegion
	
EndProcedure

Procedure SettingUpConditionTimeFenceField(Settings, ConfigurationModule)
	
	SalesFigures = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	
	#Region Visible
	Item = Settings.Add();
	
	Item.Fields.Add("ConditionFrequency");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.NewFilter(OrGroup, "RebateKind", Catalogs.CustomerRebatesKinds.EmptyRef());
	ConfigurationModule.NewFilter(OrGroup, "More.GoodsIndicator", SalesFigures.NotUsed);
	
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
	
	#Region Visible
	Item = Settings.Add();
	
	Item.Fields.Add("AccrualFrequency");
	
	ConfigurationModule.NewFilter(Item.Condition, "RebateKind", Catalogs.CustomerRebatesKinds.EmptyRef());
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
	#Region ReadOnly
	Item = Settings.Add();
	
	Item.Fields.Add("AccrualFrequency");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.NewFilter(OrGroup, "Patch", True);
	ConfigurationModule.NewFilter(OrGroup, "WithoutCalculation", True);
	
	Item.Properties.Insert("ReadOnly", True);
	#EndRegion
	
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
	ConfigurationModule.NewFilter(OrGroup, "RebateKind", Catalogs.CustomerRebatesKinds.EmptyRef());
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

Procedure SettingUpFieldDetailingCalculationOfParticipants(Settings, ConfigurationModule)
	
	#Region Visible
	Item = Settings.Add();
	
	Item.Fields.Add("PartyCountDetails");
	
	ConfigurationModule.NewFilter(Item.Condition, "RebateKind", Catalogs.CustomerRebatesKinds.EmptyRef());
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
	#Region ReadOnly
	Item = Settings.Add();
	
	Item.Fields.Add("PartyCountDetails");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.NewFilter(OrGroup, "Patch", True);
	ConfigurationModule.NewFilter(OrGroup, "AccrueImmediately", True);
	
	Item.Properties.Insert("ReadOnly", True);
	#EndRegion
	
EndProcedure

#EndRegion

#Region DownloadingFromFiles

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
//  AdditionalParameters - Structure:
//  * FieldDisplaySettings - Structure:
//  ** Counterparty - Boolean
//  ** Partner - Boolean
//  ConflictsList - ValueTable - List of ambiguities:
//  * Column - String
//  * Id - Number
//
Procedure CompareDownloadedDataTSCounterparties(DataToImport, TableToFillIn_, AdditionalParameters, ConflictsList)
	
	If AdditionalParameters.Property("FieldDisplaySettings") Then
		
		FieldDisplaySettings = AdditionalParameters.FieldDisplaySettings;
		SelectCounterparties = FieldDisplaySettings.Counterparty;
		ToSelectPartners = FieldDisplaySettings.Partner;
		
	Else
		
		SelectCounterparties = False;
		ToSelectPartners = False;
		
	EndIf;
	
	InformationSecurityDataOnCounterpartiesPartners = InformationSecurityDataOnCounterpartiesPartners(SelectCounterparties, ToSelectPartners);
	
	For Each DataString1 In DataToImport Do
		
		NewRow = TableToFillIn_.Add();
		FillPropertyValues(NewRow, DataString1);
		
		If SelectCounterparties Then
			
			NewRow.Counterparty = ToSelectCounterpartyByBankingDetails(
				DataString1, InformationSecurityDataOnCounterpartiesPartners.CounterpartiesTable, ConflictsList);
			
		EndIf;
		
		If ToSelectPartners Then
			
			NewRow.Partner = ToFindPartnerByBankingDetails(
				DataString1, InformationSecurityDataOnCounterpartiesPartners.TableOfPartners, ConflictsList);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Parameters:
//  SelectCounterparties - Boolean - Select Counterparties
//  ToSelectPartners - Boolean - Select Partners
// 
// Returns:
//  Structure - Information Security Data On Counterparties Partners:
//  * CounterpartiesTable - ValueTable:
//  ** TIN - String
//  ** CRTR - String
//  ** Description - String
//  ** DescriptionFull - String
//  ** Counterparty - CatalogRef.Counterparties
//  * TableOfPartners - ValueTable:
//  ** Code - String
//  ** Description - String
//  ** Partner - CatalogRef.Partners
//
Function InformationSecurityDataOnCounterpartiesPartners(SelectCounterparties, ToSelectPartners)
	
	Result = New Structure;
	Result.Insert("CounterpartiesTable", New ValueTable);
	Result.Insert("TableOfPartners", New ValueTable);
	
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
	|	&SelectCounterparties
	|	AND NOT Counterparties.DeletionMark
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Partners.Code AS Code,
	|	Partners.Description AS Description,
	|	Partners.Ref AS Partner
	|FROM
	|	Catalog.Partners AS Partners
	|WHERE
	|	&ToSelectPartners
	|	AND Partners.Client
	|	AND NOT Partners.DeletionMark";
		
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("SelectCounterparties", SelectCounterparties);
	Query.SetParameter("ToSelectPartners", ToSelectPartners);
	
	ResultsArray = Query.ExecuteBatch();
	
	QueryResult = ResultsArray[0];
	
	TypesDetailsString = New TypeDescription("String");
	
	Result.CounterpartiesTable = QueryResult.Unload();
	Result.CounterpartiesTable.Columns.Add("NameSearch", TypesDetailsString);
	Result.CounterpartiesTable.Columns.Add("FullNameSearch", TypesDetailsString);
	
	FillInCounterpartySearchFields(Result.CounterpartiesTable);
	
	QueryResult = ResultsArray[1];
	Result.TableOfPartners = QueryResult.Unload();
	Result.TableOfPartners.Columns.Add("NameSearch", TypesDetailsString);
	
	FillInPartnerSearchFields(Result.TableOfPartners);
	
	Return Result;
	
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

// Parameters:
//  CounterpartiesTable - ValueTable:
//  * Code - String
//  * Description - String
//  * NameSearch - String
//
Procedure FillInPartnerSearchFields(CounterpartiesTable)
	
	For Each RowOfCounterparty In CounterpartiesTable Do
		
		Code = StrReplace(RowOfCounterparty.Code, " ", "");
		RowOfCounterparty.Code = Upper(Code);
		
		NameSearch = StrReplace(RowOfCounterparty.Description, " ", "");
		RowOfCounterparty.NameSearch = Upper(NameSearch);
		
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

Function ToFindPartnerByBankingDetails(RowToImport, TableOfPartners, ConflictsList)
	
	SearchStringCode = Upper(StrReplace(RowToImport.Code, " ", "")); 
	SearchBarPartner = Upper(StrReplace(RowToImport.PartnerName_, " ", ""));
	
	HasCode = ValueIsFilled(RowToImport.Code);
	ThereIsName = ValueIsFilled(RowToImport.PartnerName_);
	
	DataWasFound = False;
	
	If HasCode Then
		
		TheStructureOfTheSearch = New Structure;
		TheStructureOfTheSearch.Insert("Code", SearchStringCode);
		
		FoundRows = TableOfPartners.FindRows(TheStructureOfTheSearch);
		If FoundRows.Count() > 0 Then
			DataWasFound = True;
		EndIf;
		
	EndIf;
	
	If Not DataWasFound
	   And ThereIsName Then
		
		TheStructureOfTheSearch = New Structure;
		TheStructureOfTheSearch.Insert("NameSearch", SearchBarPartner);
		
		FoundRows = TableOfPartners.FindRows(TheStructureOfTheSearch);
		If FoundRows.Count() > 0 Then
			DataWasFound = True;
		EndIf;
		
	EndIf;
	
	FoundPartner = Catalogs.Partners.EmptyRef();
	
	If DataWasFound Then
		
		If FoundRows.Count() = 1 Then
			
			StringOfPartner = FoundRows[0];
			FoundPartner = StringOfPartner.Partner;
			
		Else
			
			StringOfAmbiguity = ConflictsList.Add();
			StringOfAmbiguity.Id = RowToImport.Id;
			StringOfAmbiguity.Column = "Partner";
			
		EndIf;
		
	EndIf;
	
	Return FoundPartner;
	
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
		"Counterparties.Description = &Description
		| OR Counterparties.DescriptionFull = &Description";
		
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
	
	TextAnd = TextOfCombiningRequestConditions();
	
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
	
	QueryResult = Query.Execute();
	If Not QueryResult.IsEmpty() Then
		
		Selection = QueryResult.Select();
		While Selection.Next() Do
			
			ConflictsList.Add(Selection.Ref);
			
		EndDo;
		
	EndIf;
	
EndProcedure

// Parameters:
//  ConflictsList - Array of CatalogRef.Partners
//  LoadedValuesString - ValueTableRow:
//  * PartnerName_ - String
//  * Code - String
//
Procedure FillInListOfPartnerAmbiguities(ConflictsList, LoadedValuesString)
	
	Query = New Query;
	
	TermsAndConditions_ = New Array; // Array of String
	
	If ValueIsFilled(LoadedValuesString.PartnerName_) Then
		
		ConditionText =
		"Partners.Description = &Description";
		
		TermsAndConditions_.Add(ConditionText);
		Query.SetParameter("Description", LoadedValuesString.PartnerName_);
		
	EndIf;
	
	If ValueIsFilled(LoadedValuesString.Code) Then
		
		ConditionText =
		"Partners.Code = &Code";
		TermsAndConditions_.Add(ConditionText);
		Query.SetParameter("Code", LoadedValuesString.Code);
		
	EndIf;
	
	TextAnd = TextOfCombiningRequestConditions();
	
	QueryText =
	"SELECT
	|	Partners.Ref AS Ref
	|FROM
	|	Catalog.Partners AS Partners
	|WHERE
	|	NOT Partners.DeletionMark
	|	AND Partners.Client";
	
	If TermsAndConditions_.Count() > 0 Then
		
		FullTextOfTermsAndConditions = StrConcat(TermsAndConditions_, TextAnd);
		QueryText = QueryText + TextAnd + FullTextOfTermsAndConditions;
		
	EndIf;
	
	Query.Text = QueryText;
	
	QueryResult = Query.Execute();
	If Not QueryResult.IsEmpty() Then
		
		Selection = QueryResult.Select();
		While Selection.Next() Do
			
			ConflictsList.Add(Selection.Ref);
			
		EndDo;
		
	EndIf;
	
EndProcedure

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
	
	QueryResult = Query.Execute();
	
	SegmentTable = QueryResult.Unload();
	
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
	
	TextAnd = TextOfCombiningRequestConditions();
	
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
	
	QueryResult = Query.Execute();
	If Not QueryResult.IsEmpty() Then
		
		Selection = QueryResult.Select();
		While Selection.Next() Do
			
			ConflictsList.Add(Selection.Ref);
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure CompareUploadedDataTSPartnerSegments(DataToImport, TableToFillIn_, AdditionalParameters, ConflictsList)
	
	PartnerSegmentTable = PartnerSegmentTable();
	
	For Each DataString1 In DataToImport Do
		
		NewRow = TableToFillIn_.Add();
		FillPropertyValues(NewRow, DataString1);
		
		NewRow.Segment =
			SelectPartnerSegmentBasedOnBankingDetails(DataString1, PartnerSegmentTable, ConflictsList);
		
	EndDo;
	
EndProcedure

Function PartnerSegmentTable()
	
	QueryText = 
	"SELECT
	|	PartnersSegments.Code AS Code,
	|	PartnersSegments.Description AS Description,
	|	PartnersSegments.Ref AS Segment
	|FROM
	|	Catalog.PartnersSegments AS PartnersSegments
	|WHERE
	|	NOT PartnersSegments.DeletionMark
	|	AND NOT PartnersSegments.IsFolder";
		
	Query = New Query;
	Query.Text = QueryText;
	
	QueryResult = Query.Execute();
	
	SegmentTable = QueryResult.Unload();
	
	TypesDetailsString = New TypeDescription("String");
	SegmentTable.Columns.Add("NameSearch", TypesDetailsString);
	FillInSearchFieldsByPartnerSegments(SegmentTable);
	
	Return SegmentTable;
	
EndFunction

// Fill in the field to search for Item segments.
// 
// Parameters:
//  SegmentTable - ValueTable:
//  * Code - String
//  * Description - String
//  * NameSearch - String
Procedure FillInSearchFieldsByPartnerSegments(SegmentTable)
	
	For Each SegmentLine In SegmentTable Do
		
		Code = StrReplace(SegmentLine.Code, " ", "");
		SegmentLine.Code = Upper(Code);
		
		NameSearch = StrReplace(SegmentLine.Description, " ", "");
		SegmentLine.NameSearch = Upper(NameSearch);
		
	EndDo;
	
EndProcedure

Function SelectPartnerSegmentBasedOnBankingDetails(RowToImport, SegmentTable, ConflictsList)
	
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
	
	FoundSegment = Catalogs.PartnersSegments.EmptyRef();
	
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

Procedure FillInListOfPartnerSegmentAmbiguities(ConflictsList, LoadedValuesString)
	
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
	
	TextAnd = TextOfCombiningRequestConditions();
	
	QueryText =
	"SELECT
	|	Segments.Ref AS Ref
	|FROM
	|	Catalog.PartnersSegments AS Segments
	|WHERE
	|	NOT Segments.DeletionMark
	|	AND NOT Segments.IsFolder";
	
	If TermsAndConditions_.Count() > 0 Then
		
		FullTextOfTermsAndConditions = StrConcat(TermsAndConditions_, TextAnd);
		QueryText = QueryText + TextAnd + FullTextOfTermsAndConditions;
		
	EndIf;
	
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
	|		LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|		ON (ProductKitConfigurations.Owner = Products.Ref)
	|			AND (ProductKitConfigurations.Owner.ItemsType = VALUE(Enum.ItemsTypes.Set))
	|			AND (ProductKitConfigurations.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef))
	|			AND (ProductKitConfigurations.Main)
	|WHERE
	|	NOT Products.IsFolder
	|	AND NOT Products.DeletionMark
	|	AND Products.ItemsType IN (&SupportedItemTypes)
	|	AND Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.DontUse)
	|	AND &TextOfSelectionCondition
	|
	|UNION
	|
	|SELECT
	|	Products.Ref,
	|	Products.Code,
	|	Products.SKU,
	|	Products.Description,
	|	Products.DescriptionFull,
	|	Products.UseVariants,
	|	CASE
	|		WHEN Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
	|			THEN Products.Ref
	|		WHEN Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
	|			THEN Products.ItemVariantsOwner
	|		WHEN Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
	|			THEN Products.ProductKind
	|		ELSE UNDEFINED
	|	END
	|FROM
	|	Catalog.Products AS Products
	|		INNER JOIN Catalog.ItemsCharacteristics AS ItemsCharacteristics
	|		ON (CASE
	|				WHEN Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
	|					THEN Products.Ref
	|				WHEN Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
	|					THEN Products.ItemVariantsOwner
	|				WHEN Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
	|					THEN Products.ProductKind
	|				ELSE UNDEFINED
	|			END = ItemsCharacteristics.Owner)
	|		LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|		ON (ProductKitConfigurations.Owner = Products.Ref)
	|			AND (ProductKitConfigurations.Owner.ItemsType = VALUE(Enum.ItemsTypes.Set))
	|			AND (ProductKitConfigurations.Characteristic = ItemsCharacteristics.Ref)
	|			AND (ProductKitConfigurations.Main)
	|WHERE
	|	Products.UseVariants <> VALUE(Enum.ItemVariantsUsageOptions.DontUse)
	|	AND NOT Products.DeletionMark
	|	AND Products.ItemsType IN (&SupportedItemTypes)
	|	AND NOT ItemsCharacteristics.DeletionMark
	|	AND &TextOfSelectionCondition
	|
	|INDEX BY
	|	Products
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ProductsTable.UseVariants AS UseVariants,
	|	ProductsTable.SignificanceForFeatureSelection AS SignificanceForFeatureSelection
	|INTO ParametersForSelectingCharacteristics
	|FROM
	|	ProductsTable AS ProductsTable
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
	|WHERE
	|	NOT FilterParameters.SignificanceForFeatureSelection = UNDEFINED
	|	AND NOT ItemsCharacteristics.DeletionMark
	|
	|INDEX BY
	|	SignificanceForFeatureSelection,
	|	Characteristic
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
		
	TextOfProductSelectionCriteria = "TRUE";
	
	ItemsTypes = RebatesServer.SupportedItemTypes();
	
	Query = New Query;
	Query.Text = StrReplace(QueryText, "&TextOfSelectionCondition", TextOfProductSelectionCriteria);
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
	
	ColumnNameBarcode = "Barcode";
	BarcodeTable = DataTable.Copy(, ColumnNameBarcode);
	BarcodeTable.GroupBy(ColumnNameBarcode);
	
	Barcodes = New Array; // Array of String
	For Each BarcodeString_ In BarcodeTable Do
		
		ValueOfLineBarcode = BarcodeString_[ColumnNameBarcode]; // String
		
		If Not IsBlankString(ValueOfLineBarcode) Then
			Barcodes.Add(ValueOfLineBarcode);
		EndIf;
		
	EndDo;
	
	If Barcodes.Count() > 0 Then
		
		QueryText =
		"SELECT DISTINCT
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
		
		QueryResult = Query.Execute();
		If Not QueryResult.IsEmpty() Then
			
			Selection = QueryResult.Select();
			While Selection.Next() Do
				
				DataString1 = BarcodeData_.Add();
				FillPropertyValues(DataString1, Selection);
				
			EndDo;
			
		EndIf;
		
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
	
	DataFound = FoundDataOnGoods();
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
	
	TextAnd = TextOfCombiningRequestConditions();
	
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
	
	QueryResult = Query.Execute();
	If Not QueryResult.IsEmpty() Then
		
		Selection = QueryResult.Select();
		While Selection.Next() Do
			
			ConflictsList.Add(Selection.Ref);
			
		EndDo;
		
	EndIf;
	
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
	|UNION
	|
	|SELECT
	|	Characteristics.Ref AS Ref
	|FROM
	|	Catalog.ItemsCharacteristics AS Characteristics
	|WHERE
	|	NOT Characteristics.DeletionMark
	|	AND Characteristics.Owner REFS Catalog.Products
	|	AND Characteristics.DescriptionFull = &Description";
	
	Query.Text = QueryText;
	
	QueryResult = Query.Execute();
	If Not QueryResult.IsEmpty() Then
		
		Selection = QueryResult.Select();
		While Selection.Next() Do
			
			ConflictsList.Add(Selection.Ref);
			
		EndDo;
		
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

// Search the linked table.
// 
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
				NewResultString.Products = StringFoundBySelection.Products;
				NewResultString.Characteristic = StringByKey.Characteristic;
				
			EndDo;
			
		EndDo;
		
	EndIf;
	
	Return Result;
	
EndFunction

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
			NewRow.Value = EnumerationValue; // Arbitrary
			
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
		|		INNER JOIN Document.ConditionsOfCustomerRebates AS Document
		|		ON (Document.Date BETWEEN BEGINOFPERIOD(TT_DataTable.Date, DAY) AND ENDOFPERIOD(TT_DataTable.Date, DAY))";
		
		QueryText = StrReplace(QueryText, "Document.ConditionsOfCustomerRebates", InformationAboutSource.FullName);
		
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

#EndRegion


#Region Other

Procedure EstablishSignsOfSettlementForCounterpartyClient(Object, Parameters)
	
	If Parameters.PartyList <> Enums.RebatesParticipants.Counterparties 
	   And Parameters.PartyList <> Enums.RebatesParticipants.Customers Then
		Return;
	EndIf;
	
	ShouldDetailCalculation = Enums.ARAPAccountingDrilldownsOfRebatesParticipants;
	
	If Object.PartyCountDetails = ShouldDetailCalculation.ByCounterpartyAndCustomer Then
		
		For Each ParticipantLine In Object.Counterparties Do
			
			ParticipantLine.PlanIsNotSpecified = False;
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure ToEstablishSignsOfCalculationOfParticipantsPlanDiscrepancyBetweenCompositionAndCalculation(Object, Parameters)
	
	If Parameters.PartyList <> Enums.RebatesParticipants.Counterparties 
	   And Parameters.PartyList <> Enums.RebatesParticipants.Customers Then
		Return;
	EndIf;
	
	ShouldDetailCalculation = Enums.ARAPAccountingDrilldownsOfRebatesParticipants;
	
	DetailsCounterpartyCompositionClient =
		(Object.PartyCountDetails = ShouldDetailCalculation.ByCounterparty
		 And Parameters.PartyList = Enums.RebatesParticipants.Customers);
	
	DetailsClientCompositionCounterparty =
		(Object.PartyCountDetails = ShouldDetailCalculation.ByCustomer
		 And Parameters.PartyList = Enums.RebatesParticipants.Counterparties);
	
	If DetailsCounterpartyCompositionClient
	 Or DetailsClientCompositionCounterparty Then
		
		For Each ParticipantLine In Object.Counterparties Do
			
			ParticipantLine.SumPlan = 0;
			ParticipantLine.PlanIsNotSpecified = True;
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure ToEstablishSignsOfCalculationOfParticipantsPlanCoincidenceOfCompositionAndCalculation(Object, Parameters, ChangedMember)
	
	If Parameters.PartyList <> Enums.RebatesParticipants.Counterparties 
	  And Parameters.PartyList <> Enums.RebatesParticipants.Customers Then
		Return;
	EndIf;
	
	ShouldDetailCalculation = Enums.ARAPAccountingDrilldownsOfRebatesParticipants;
	
	DetailsCounterpartyCompositionCounterparty =
		(Object.PartyCountDetails = ShouldDetailCalculation.ByCounterparty
		 And Parameters.PartyList = Enums.RebatesParticipants.Counterparties);
	
	DetailsClientCompositionClient =
		(Object.PartyCountDetails = ShouldDetailCalculation.ByCustomer
		 And Parameters.PartyList = Enums.RebatesParticipants.Customers);
	
	If DetailsClientCompositionClient Then
		
		KeyField = "Partner";
		
	ElsIf DetailsCounterpartyCompositionCounterparty Then
		
		KeyField = "Counterparty";
		
	EndIf;
	
	ParticipantsPlanIsNotSpecified = New Map;
	
	If DetailsCounterpartyCompositionCounterparty
	 Or DetailsClientCompositionClient Then
		
		For Each ParticipantLine In Object.Counterparties Do
			
			If ParticipantLine.Canceled Then
				Continue
			EndIf;
			
			ParticipantValue = ParticipantLine[KeyField]; // CatalogRef.Partners, CatalogRef.Counterparties
			If ChangedMember <> Undefined
			   And ChangedMember <> ParticipantValue Then
				Continue;
			EndIf;
			
			If ParticipantsPlanIsNotSpecified[ParticipantValue] <> Undefined Then
				
				ParticipantLine.SumPlan = 0;
				ParticipantLine.PlanIsNotSpecified = True;
				
			Else
				
				FilterStructure1 = New Structure;
				FilterStructure1.Insert(KeyField, ParticipantValue);
				FilterStructure1.Insert("Canceled", False);
				FoundRows = Object.Counterparties.FindRows(FilterStructure1);
				
				If FoundRows.Count() > 1 Then
					
					ParticipantLine.SumPlan = 0;
					ParticipantLine.PlanIsNotSpecified = True;
					ParticipantsPlanIsNotSpecified[ParticipantValue] = True;
					
				Else
					
					ParticipantLine.PlanIsNotSpecified = False;
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure EstablishSignsOfCalculationOfPlanContractAgreements(Object, Parameters, ChangedMember)
	
	If Parameters.PartyList <> Enums.RebatesParticipants.Contracts
	   And Parameters.PartyList <> Enums.RebatesParticipants.Terms1 Then
		Return;
	EndIf;
	
	CheckingPlanIndication = (Object.PartyCountDetails = PredefinedValue("Enum.ARAPAccountingDrilldownsOfRebatesParticipants.ByCounterparty"))
		And (Parameters.PartyList = Enums.RebatesParticipants.Contracts);
	ParticipantsPlanIsNotSpecified = New Map;
	
	For Each ParticipantLine In Object.ContractsTermsOfSales Do
		
		If ParticipantLine.Canceled Then
			Continue
		EndIf;
		
		If Not CheckingPlanIndication Then
			ParticipantLine.PlanIsNotSpecified = True;
		EndIf;
		
		ParticipantValue = ParticipantLine.Counterparty;
		
		If ChangedMember <> Undefined
		   And ChangedMember <> ParticipantValue Then
			Continue;
		EndIf;
		
		If ParticipantsPlanIsNotSpecified[ParticipantValue] <> Undefined Then
			
			ParticipantLine.SumPlan = 0;
			ParticipantLine.PlanIsNotSpecified = True;
			
		Else
			
			FilterStructure1 = New Structure;
			FilterStructure1.Insert("Counterparty", ParticipantValue);
			FilterStructure1.Insert("Canceled", False);
			FoundRows = Object.ContractsTermsOfSales.FindRows(FilterStructure1);
			
			If FoundRows.Count() > 1 Then
				
				ParticipantLine.SumPlan = 0;
				ParticipantLine.PlanIsNotSpecified = True;
				ParticipantsPlanIsNotSpecified[ParticipantValue] = True;
				
			ElsIf CheckingPlanIndication Then
				
				ParticipantLine.PlanIsNotSpecified = False;
				
			Else
				
				ParticipantLine.PlanIsNotSpecified = True;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure ToEstablishSignsOfCalculatingCounterpartiesTINPlan(Object, Parameters)
	
	If Parameters.PartyList <> Enums.RebatesParticipants.TIN Then
		Return;
	EndIf;
	
	ShouldDetailCalculation = Enums.ARAPAccountingDrilldownsOfRebatesParticipants;
	
	If Object.PartyCountDetails = ShouldDetailCalculation.ByCustomer Then
		
		For Each ParticipantLine In Object.CounterpartiesTIN Do
			
			ParticipantLine.SumPlan = 0;
			
		EndDo;
		
	EndIf;
	
EndProcedure

// Returns:
//  Array of See GoodsDataLine
//
Function FoundDataOnGoods();
	
	DataFound = New Array;
	Return DataFound;
	
EndFunction

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

Procedure ClearUnusedDetailsCounterparties(Object, Val Parameters)
	
	If Parameters.FilterParties = Enums.RebatesLists.All
	 Or (Parameters.PartyList <> Enums.RebatesParticipants.Counterparties
		  And Parameters.PartyList <> Enums.RebatesParticipants.Customers) Then
		
		Object.Counterparties.Clear();
		Return;
		
	EndIf;
	
	DateEmpty = Date(1, 1, 1);
	ExceptForSelectedOnes = (Parameters.FilterParties = Enums.RebatesLists.ExceptForSelectedOnes);
	Selected_ = (Parameters.FilterParties = Enums.RebatesLists.Selected_);
	PlanAccordingToScale = (Parameters.GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum
				   And Object.CalculationScaleType <> 0); // Not the only value
	
	ShouldDetailCalculation = Enums.ARAPAccountingDrilldownsOfRebatesParticipants;
	
	DetailsCounterpartyCompositionClient =
		(Object.PartyCountDetails = ShouldDetailCalculation.ByCounterparty
		 And Parameters.PartyList = Enums.RebatesParticipants.Customers);
	
	DetailsClientCompositionCounterparty =
		(Object.PartyCountDetails = ShouldDetailCalculation.ByCustomer
		 And Parameters.PartyList = Enums.RebatesParticipants.Counterparties);
	
	For Each TSRow In Object.Counterparties Do
		
		If Not Object.Patch Then
			
			TSRow.Canceled = False;
			TSRow.InitialString = False;
			
		EndIf;
		
		If Not TSRow.InitialString Then
			
			TSRow.StartDateBeforeChange = DateEmpty; 
			TSRow.EndDateBeforeChange = DateEmpty;
			TSRow.PlanIsNotSpecifiedBeforeChange = False;
			
		EndIf;
		
		If ExceptForSelectedOnes Then
			
			TSRow.AmountBonus = 0;
			TSRow.ValidOnDate = DateEmpty;
			TSRow.ValidTo = DateEmpty;
			TSRow.StartDateBeforeChange = DateEmpty;
			TSRow.EndDateBeforeChange = DateEmpty;
			
		EndIf;
		
		If Selected_
		   And (DetailsCounterpartyCompositionClient
			  Or DetailsClientCompositionCounterparty) Then
			
			TSRow.SumPlan = 0;
			
		EndIf;
		
		If PlanAccordingToScale
		 Or ExceptForSelectedOnes Then
			
			TSRow.SumPlan = 0;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure ClearUnusedDetailsOfCounterpartiesTIN(Object, Val Parameters)
	
	If Parameters.FilterParties = Enums.RebatesLists.All
	 Or Parameters.PartyList <> Enums.RebatesParticipants.TIN Then
		
		Object.CounterpartiesTIN.Clear();
		Return;
		
	EndIf;
	
	DateEmpty = Date(1, 1, 1);
	ExceptForSelectedOnes = (Parameters.FilterParties = Enums.RebatesLists.ExceptForSelectedOnes);
	PlanAccordingToScale = (Parameters.GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum
				   And Object.CalculationScaleType <> 0); // Not the only value
	
	For Each TSRow In Object.CounterpartiesTIN Do
		
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
		
		If ExceptForSelectedOnes
		 Or PlanAccordingToScale Then
			
			TSRow.SumPlan = 0;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure ClearUnusedBankingDetailsPartnerSegments(Object, Parameters)
	
	If Parameters.FilterParties = Enums.RebatesLists.All
	 Or Parameters.PartyList <> Enums.RebatesParticipants.PartnersSegments Then
		
		Object.PartnersSegments.Clear();
		Return;
		
	EndIf;
	
	If Parameters.FilterParties = Enums.RebatesLists.ExceptForSelectedOnes Then
		
		For Each TSRow In Object.PartnersSegments Do
			
			If Not Object.Patch Then
				
				TSRow.Canceled = False;
				TSRow.InitialString = False;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure ClearUnusedAttributesContractsAgreements(Object, Parameters)
	
	ShouldDetailCalculation = Enums.ARAPAccountingDrilldownsOfRebatesParticipants;
	LineUpsOfParticipants = Enums.RebatesParticipants;
	
	If Parameters.PartyList <> LineUpsOfParticipants.Contracts
	   And Parameters.PartyList <> LineUpsOfParticipants.Terms1 Then
		
		Object.ContractsTermsOfSales.Clear();
		Return;
		
	EndIf;
	
	DateEmpty = Date(1, 1, 1);
	ClearingAmountPlan =
		(Parameters.PartyList <> LineUpsOfParticipants.Contracts
		 Or Object.PartyCountDetails = ShouldDetailCalculation.ByCustomer
		 Or Object.CalculationScaleType <> 0);
	
	PlanIsNotSpecified = False;
	AttributesOfAgreements = New Map;
	If Parameters.PartyList = LineUpsOfParticipants.Terms1 Then
		
		PlanIsNotSpecified = True;
		TableOfDocumentAgreements = Object.ContractsTermsOfSales.Unload(, "Terms");
		DocumentAgreements = TableOfDocumentAgreements.UnloadColumn("Terms");
		DocumentAgreements = CommonClientServer.CollapseArray(DocumentAgreements);
		CommonClientServer.DeleteValueFromArray(
			DocumentAgreements, Catalogs.TermsOfSale.EmptyRef());
		
		AttributesNames = "Standard_";
		AttributesOfAgreements = Common.ObjectsAttributesValues(DocumentAgreements, AttributesNames);
		
	EndIf;
	
	For Each TSRow In Object.ContractsTermsOfSales Do
		
		If Parameters.PartyList = LineUpsOfParticipants.Terms1
		   And Not TSRow.Terms.IsEmpty() Then
			
			TermsFields = AttributesOfAgreements[TSRow.Terms];
			If TermsFields.Standard_ = True Then
				
				TSRow.Counterparty = Catalogs.Counterparties.EmptyRef();
				TSRow.Partner = Catalogs.Partners.EmptyRef();
				
			Else
				
				TSRow.SalesSpecialByStandard = False;
				
			EndIf;
			
			TSRow.Contract = Catalogs.CounterpartyContracts.EmptyRef();
			
		Else
			
			TSRow.SalesSpecialByStandard = False;
			TSRow.Terms = Catalogs.TermsOfSale.EmptyRef();
			
		EndIf;
		
		If ClearingAmountPlan Then
			TSRow.SumPlan = 0;
		EndIf;
		
		If PlanIsNotSpecified Then
			TSRow.PlanIsNotSpecified = True;
		EndIf;
		
		If Not Object.Patch Then
			
			TSRow.StartDateBeforeChange = DateEmpty;
			TSRow.EndDateBeforeChange = DateEmpty;
			TSRow.AmountPlanBeforeChange = 0;
			TSRow.Canceled = False;
			TSRow.InitialString = False;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure ClearUnusedItemTableAttributes(Object, Parameters, Val DataTable)
	
	GoodsIndicators = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	ProhibitionOfExceedingAmount =
			(Parameters.GoodsIndicator = GoodsIndicators.Sum
			 And Object.RestrictAccrualOverPlan);
	PercentageOnScale =
			(Parameters.GoodsIndicator = GoodsIndicators.Sum
			 And Object.CalculationScaleType <> 0);
	ThisIsNumberByRanges = RebatesClientServer.ThisIsNumberByRanges(
			Object.CalculationScaleType, Parameters.GoodsIndicator);
	DateEmpty = Date(1, 1, 1);
	
	For Each TSRow In DataTable Do
			
			If Not Object.Patch Then
				
				TSRow.Canceled = False;
				TSRow.InitialString = False;
				
			EndIf;
			
			If Not TSRow.InitialString Then
				
				TSRow.StartDateBeforeChange = DateEmpty;
				TSRow.EndDateBeforeChange = DateEmpty;
				
			EndIf;
			
			If Parameters.FilterOfProducts_ = Enums.RebatesLists.ExceptForSelectedOnes Then
				
				TSRow.ValidOnDate = DateEmpty;
				TSRow.StartDateBeforeChange = DateEmpty;
				TSRow.ValidTo = DateEmpty;
				TSRow.EndDateBeforeChange = DateEmpty;
				TSRow.CountPlan = 0;
				TSRow.BasePrice = 0;
				TSRow.Percent = 0;
				
			EndIf;
			
			If Parameters.FilterOfProducts_ = Enums.RebatesLists.Selected_ Then
				
				If (Parameters.GoodsIndicator <> GoodsIndicators.Count
					  And Parameters.GoodsIndicator <> GoodsIndicators.QuantityTotal
					  And Parameters.GoodsIndicator <> GoodsIndicators.BatchOffer) Then
					
					TSRow.CountPlan = 0;
					
				EndIf;
				
				If Parameters.BaseOfCalculation <> Enums.RebateCalculationBases.RevenueBasePrices Then
					
					TSRow.BasePrice = 0;
					
				EndIf;
				
				If Not RebatesClientServer.PeriodOfGoodsConditionsIsUsed(Parameters.GoodsIndicator) Then
					
					TSRow.ValidOnDate = DateEmpty;
					TSRow.StartDateBeforeChange = DateEmpty;
					TSRow.ValidTo = DateEmpty;
					TSRow.EndDateBeforeChange = DateEmpty;
					
				EndIf;
				
				If ProhibitionOfExceedingAmount
				 Or PercentageOnScale Then
					
					TSRow.Percent = 0;
					
				EndIf;
				
			EndIf;
			
			If Not ThisIsNumberByRanges Then
				
				TSRow.QuantityPlanRangeBound = 0;
				
			EndIf;
			
		EndDo;
EndProcedure

#EndRegion

#EndRegion

#EndIf