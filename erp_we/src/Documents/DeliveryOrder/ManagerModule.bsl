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
	
	DocumentMechanisms.Add("GoodsDelivery");
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentObject.DeliveryOrder, DocumentRef.DeliveryOrder - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  ValueList of String, Structure - a collection of elements - tables of values - data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.DeliveryOrder") Then
		
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
		
		QueryTextGoodsDelivery(Query, QueryTexts, Registers, DocumentObject, AddlParameters);
		
	EndIf;
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

#Region GenerateFrom

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
EndProcedure

#EndRegion

#Region InterfaceImplementation

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
	
	Return;
	
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
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(Sender)
	|	AND ValueAllowed(Recipient)";
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

// Parameters:
//  OrderDocument - DocumentObject.DeliveryOrder
//  NewGoodsLines - Array of FormDataCollectionItem, LineOfATabularSection:
//  * ReferenceOrder - DefinedType.DeliveryReferenceOrder25
//  * DeliveryLineCode - Number
//
Procedure UpdateAdditionalParameters(OrderDocument, NewGoodsLines) Export
	
	References = New Array; // Array of DefinedType.DeliveryReferenceOrder25
	For Each String In NewGoodsLines Do
		References.Add(String.ReferenceOrder);
	EndDo;
	
	AdditionalParametersForNewLines = GoodsDelivery.AllAdditionalParametersFromDocumentStrings(References);
	
	AddedOptionsForSpecialConditions = New Map;
	If ValueIsFilled(OrderDocument.SpecialTransportationConditionsDescription) Then
		
		HashOfCurrentSpecialConditions = GoodsDelivery.HashOfSignificantCharactersOfString(OrderDocument.SpecialTransportationConditionsDescription);
		AddedOptionsForSpecialConditions.Insert(HashOfCurrentSpecialConditions, True);
		
	EndIf;
	
	AddedOptionsForAdditionalInformation = New Map;
	If ValueIsFilled(OrderDocument.AdditionalInformation) Then
		
		HashOfCurrentAdditionalInformation = GoodsDelivery.HashOfSignificantCharactersOfString(OrderDocument.AdditionalInformation);
		AddedOptionsForAdditionalInformation.Insert(HashOfCurrentAdditionalInformation, True);
		
	EndIf;
	
	Filter = New Structure;
	Filter.Insert("DocumentDeliveries", Undefined);
	Filter.Insert("RowCode", 0);
	
	EmptyTime = '00010101';
	NewDeliveryTimeFrom = EmptyTime;
	NewDeliveryTimeBy = EmptyTime;
	
	For Each String In NewGoodsLines Do
		
		Filter.DocumentDeliveries = String.ReferenceOrder;
		Filter.RowCode = String.DeliveryLineCode;
		ParameterStrings = AdditionalParametersForNewLines.FindRows(Filter);
		
		If ParameterStrings.Count() = 0 Then
			
			Filter.RowCode = 0;
			ParameterStrings = AdditionalParametersForNewLines.FindRows(Filter);
			
		EndIf;
		
		If ParameterStrings.Count() = 0 Then
			Continue;
		EndIf;
		
		AdditionalLineParameters = ParameterStrings[0];
		
		If AdditionalLineParameters.DeliveryTimeFrom > NewDeliveryTimeFrom Then
			NewDeliveryTimeFrom = AdditionalLineParameters.DeliveryTimeFrom;
		EndIf;
		
		If AdditionalLineParameters.DeliveryTimeTo < NewDeliveryTimeBy
		   And ValueIsFilled(AdditionalLineParameters.DeliveryTimeTo) Then
			
			NewDeliveryTimeBy = AdditionalLineParameters.DeliveryTimeTo;
			
		EndIf;
		
		If Not ValueIsFilled(NewDeliveryTimeBy)
		   And ValueIsFilled(AdditionalLineParameters.DeliveryTimeTo) Then
			
			NewDeliveryTimeBy = AdditionalLineParameters.DeliveryTimeTo;
			
		EndIf;
		
		If ValueIsFilled(AdditionalLineParameters.SpecialTransportationConditionsDescription)
		   And AddedOptionsForSpecialConditions[AdditionalLineParameters.SpecialConditionsOfCarriageDescriptionHash] = Undefined Then
			
			OrderDocument.SpecialTransportationConditionsDescription = OrderDocument.SpecialTransportationConditionsDescription + Chars.LF
				+ AdditionalLineParameters.SpecialTransportationConditionsDescription;
			
			AddedOptionsForSpecialConditions.Insert(AdditionalLineParameters.SpecialConditionsOfCarriageDescriptionHash, True);
			
		EndIf;
		
		If ValueIsFilled(AdditionalLineParameters.AdditionalDeliveryInformation)
		   And AddedOptionsForAdditionalInformation[AdditionalLineParameters.AdditionalInformationOnDeliveryHash] = Undefined Then
			
			OrderDocument.AdditionalInformation = OrderDocument.AdditionalInformation + Chars.LF
				+ AdditionalLineParameters.AdditionalDeliveryInformation;
			
			AddedOptionsForAdditionalInformation.Insert(AdditionalLineParameters.AdditionalInformationOnDeliveryHash, True);
			
		EndIf;
		
	EndDo;
	
	If NewDeliveryTimeFrom > NewDeliveryTimeBy
	   And ValueIsFilled(NewDeliveryTimeBy) Then
		
		NewDeliveryTimeFrom = EmptyTime;
		NewDeliveryTimeBy = EmptyTime;
		
	EndIf;
	
	If Not ValueIsFilled(OrderDocument.DeliveryTimeFrom)
	   And Not ValueIsFilled(OrderDocument.DeliveryTimeTo) Then
		
		OrderDocument.DeliveryTimeFrom = NewDeliveryTimeFrom;
		OrderDocument.DeliveryTimeTo = NewDeliveryTimeBy;
		
	EndIf;
	
	OrderDocument.SpecialTransportationConditionsDescription = TrimAll(OrderDocument.SpecialTransportationConditionsDescription);
	OrderDocument.AdditionalInformation = TrimAll(OrderDocument.AdditionalInformation);
	
	If ValueIsFilled(OrderDocument.SpecialTransportationConditionsDescription) Then
		OrderDocument.SpecialTransportationConditions = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region Posting

#Region DocumentData

Procedure GetDocumentData(Query, DocumentRef)
	
	ListOfRequests = New Array; // Array of String
	
	QueryTextDocumentDataHeader(ListOfRequests);
	QueryTextDataTableGoods(ListOfRequests);
	
	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	
	Query.Text = QueryText;
	Query.TempTablesManager = New TempTablesManager();
	Query.SetParameter("Ref", DocumentRef);
	Query.Execute();
	
EndProcedure

Procedure QueryTextDocumentDataHeader(ListOfRequests)
	
	QueryText =
	"SELECT
	|	DocumentData.Date AS Date,
	|	DocumentData.Number AS Number,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.Ref AS Ref,
	|	DocumentData.DateOfShipment AS DateOfShipment,
	|	DocumentData.DeliveryDirection AS DeliveryDirection,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.DeliveryMethod AS DeliveryMethod,
	|	DocumentData.DeliveryToCarrier AS DeliveryToCarrier,
	|	DocumentData.Sender AS Sender,
	|	DocumentData.SenderDeparturePoint AS SenderDeparturePoint,
	|	DocumentData.DepartureArea AS DepartureArea,
	|	DocumentData.Recipient AS Recipient,
	|	DocumentData.DeliveryPointRecipient AS DeliveryPointRecipient,
	|	DocumentData.DeliveryZone AS DeliveryZone,
	|	DocumentData.Carrier AS Carrier,
	|	DocumentData.CarrierDeliveryPoint AS CarrierDeliveryPoint,
	|	DocumentData.CarrierSDeliveryArea AS CarrierSDeliveryArea,
	|	DocumentData.DeliveryTimeFrom AS DeliveryTimeFrom,
	|	DocumentData.DeliveryTimeTo AS DeliveryTimeTo,
	|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.AdditionalInformation AS AdditionalInformation,
	|	DocumentData.SpecialTransportationConditions AS SpecialTransportationConditions,
	|	DocumentData.SpecialTransportationConditionsDescription AS SpecialTransportationConditionsDescription
	|INTO DocumentDataHeader
	|FROM
	|	Document.DeliveryOrder AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

Procedure QueryTextDataTableGoods(ListOfRequests)
	
	QueryText =
	"SELECT
	|	DataTable.Ref AS Ref,
	|	DataTable.LineNumber AS LineNumber,
	|	DataTable.Products AS Products,
	|	DataTable.Characteristic AS Characteristic,
	|	DataTable.Series AS Series,
	|	DataTable.Count AS Count,
	|	DataTable.NumberOfPackages AS NumberOfPackages,
	|	DataTable.Package AS Package,
	|	DataTable.ReferenceOrder AS ReferenceOrder,
	|	DataTable.DeliveryLineCode AS DeliveryLineCode
	|INTO DocumentDataTableItems
	|FROM
	|	Document.DeliveryOrder.Goods AS DataTable
	|WHERE
	|	DataTable.Ref = &Ref";
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

#EndRegion

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Attributes = DocumentAttributes(Query);
	
	For Each KeyAndValue In ValuesOfHoldingParameters(Attributes) Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
	OperationLevel = GoodsDelivery.LevelOfOperationOfDocument(DocumentRef);
	Query.SetParameter("OperationLevel", OperationLevel);
	
EndProcedure

// Parameters:
//  Query - Query - Query
// 
// Returns:
//  QueryResultSelection - The details of the document:
//  * Date - Date
//  * Number - String
//  * DeletionMark - Boolean
//  * Posted - Boolean
//  * DateOfShipment - Date
//  * DeliveryDirection - EnumRef.DeliveryDirections
//  * Organization - CatalogRef.Companies
//  * DeliveryMethod - EnumRef.TransportMethods25
//  * DeliveryToCarrier - Boolean
//  * Carrier - CatalogRef.Partners
//  * Sender - CatalogRef.Warehouses
//  * SenderDeparturePoint - CatalogRef.DeliveryPoints
//  * Recipient - CatalogRef.Partners
//  * DeliveryPointRecipient - CatalogRef.DeliveryPoints
//  * DeliveryZone - CatalogRef.DeliveryZones
//  * CarrierDeliveryPoint - CatalogRef.DeliveryPoints
//  * DeliveryTimeFrom - Date
//  * DeliveryTimeTo - Date
//  * SpecialTransportationConditions - Boolean
//  * EmployeeResponsible - CatalogRef.Users
//
Function DocumentAttributes(Query)
	
	Query.Text =
	"SELECT
	|	DocumentDataHeader.Date AS Date,
	|	DocumentDataHeader.Number AS Number,
	|	DocumentDataHeader.DeletionMark AS DeletionMark,
	|	DocumentDataHeader.Posted AS Posted,
	|	DocumentDataHeader.DateOfShipment AS DateOfShipment,
	|	DocumentDataHeader.DeliveryDirection AS DeliveryDirection,
	|	DocumentDataHeader.Organization AS Organization,
	|	DocumentDataHeader.DeliveryMethod AS DeliveryMethod,
	|	DocumentDataHeader.DeliveryToCarrier AS DeliveryToCarrier,
	|	DocumentDataHeader.Carrier AS Carrier,
	|	DocumentDataHeader.Sender AS Sender,
	|	DocumentDataHeader.SenderDeparturePoint AS SenderDeparturePoint,
	|	DocumentDataHeader.DepartureArea AS DepartureArea,
	|	DocumentDataHeader.Recipient AS Recipient,
	|	DocumentDataHeader.DeliveryPointRecipient AS DeliveryPointRecipient,
	|	DocumentDataHeader.DeliveryZone AS DeliveryZone,
	|	DocumentDataHeader.CarrierDeliveryPoint AS CarrierDeliveryPoint,
	|	DocumentDataHeader.DeliveryTimeFrom AS DeliveryTimeFrom,
	|	DocumentDataHeader.DeliveryTimeTo AS DeliveryTimeTo,
	|	DocumentDataHeader.SpecialTransportationConditions AS SpecialTransportationConditions,
	|	DocumentDataHeader.EmployeeResponsible AS EmployeeResponsible
	|FROM
	|	DocumentDataHeader AS DocumentDataHeader";
	
	QueryResult = Query.Execute();
	Attributes = QueryResult.Select();
	Attributes.Next();
	
	Return Attributes;
	
EndFunction

// Parameters:
//  Attributes - See DocumentAttributes
// 
// Returns:
//  Structure - Request parameter values
//
Function ValuesOfHoldingParameters(Attributes)
	
	Values = New Structure;
	
	Values.Insert("Period", Attributes.Date);
	Values.Insert("Organization", Attributes.Organization);
	Values.Insert("DeliveryDirection", Attributes.DeliveryDirection);
	Values.Insert("DeliveryMethod", Attributes.DeliveryMethod);
	Values.Insert("DeliveryToCarrier", Attributes.DeliveryToCarrier);
	Values.Insert("Sender", Attributes.Sender);
	Values.Insert("Recipient", Attributes.Recipient);
	Values.Insert("Carrier", Attributes.Carrier);
	Values.Insert("SenderDeparturePoint", Attributes.SenderDeparturePoint);
	Values.Insert("DeliveryPointRecipient", Attributes.DeliveryPointRecipient);
	Values.Insert("CarrierDeliveryPoint", Attributes.CarrierDeliveryPoint);
	Values.Insert("DeliveryZone", Attributes.DeliveryZone);
	Values.Insert("EmployeeResponsible", Attributes.EmployeeResponsible);
	Values.Insert("SpecialTransportationConditions", Attributes.SpecialTransportationConditions);
		
	Return Values;
	
EndFunction

Function QueryTextGoodsDelivery(Query, QueryTexts, Registers, DocumentObject, AddlParameters = Undefined)
	
	RegisterName = "Delivery";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	BEGINOFPERIOD(&Period, DAY) AS Period,
	|	OrderHeader_.Organization AS Organization,
	|	VALUE(Enum.DeliveryTypes.OutgoingInfo) AS DeliveryType,
	|	OrderHeader_.DateOfShipment AS DateOfShipment,
	|	CASE
	|		WHEN OrderHeader_.DeliveryToCarrier
	|			THEN VALUE(Enum.TransportMethods25.OwnDelivery)
	|		ELSE OrderHeader_.DeliveryMethod
	|	END AS DeliveryMethod,
	|	OrderHeader_.Sender AS Sender,
	|	OrderHeader_.SenderDeparturePoint AS SenderPoint,
	|	OrderHeader_.DepartureArea AS Sender_Area,
	|	CASE
	|		WHEN OrderHeader_.DeliveryToCarrier
	|			THEN OrderHeader_.Carrier
	|		ELSE OrderHeader_.Recipient
	|	END AS Recipient,
	|	CASE
	|		WHEN OrderHeader_.DeliveryToCarrier
	|			THEN OrderHeader_.CarrierDeliveryPoint
	|		ELSE OrderHeader_.DeliveryPointRecipient
	|	END AS RecipientPoint,
	|	CASE
	|		WHEN OrderHeader_.DeliveryToCarrier
	|			THEN OrderHeader_.CarrierSDeliveryArea
	|		ELSE OrderHeader_.DeliveryZone
	|	END AS Recipient_Area,
	|	&Ref AS PlanningDocument,
	|	GoodsTable.ReferenceOrder AS ReferenceOrder,
	|	UNDEFINED AS Trip,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.DeliveryLineCode AS RowCode,
	|	1 AS Arm,
	|	GoodsTable.Package AS Package,
	|	CASE
	|		WHEN OrderHeader_.DeliveryMethod = VALUE(Enum.TransportMethods25.ByCarrier)
	|			THEN OrderHeader_.Carrier
	|		ELSE VALUE(Catalog.Partners.EmptyRef)
	|	END AS Carrier,
	|	0 AS ToDeliver,
	|	GoodsTable.Count AS ToTrip,
	|	CASE
	|		WHEN OrderHeader_.DeliveryMethod = VALUE(Enum.TransportMethods25.SelfPickup)
	|			THEN GoodsTable.Count
	|		ELSE 0
	|	END AS InTrip,
	|	0 AS InTransit,
	|	CASE
	|		WHEN OrderHeader_.DeliveryMethod = VALUE(Enum.TransportMethods25.SelfPickup)
	|			THEN GoodsTable.Count
	|		ELSE 0
	|	END AS Delivered,
	|	0 AS Canceled,
	|	0 AS ForAssembly,
	|	0 AS AssemblyInProgress,
	|	0 AS Assembled,
	|	&OperationLevel AS OperationLevel,
	|	NOT OrderHeader_.DeliveryToCarrier AS ThisIsFinalArm,
	|	1 AS MinimumArmNumber,
	|	FALSE AS PrimaryRegisterRecord,
	|	DATETIME(1, 1, 1) AS SourceShipmentDate,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose
	|FROM
	|	Document.DeliveryOrder.Goods AS GoodsTable
	|		INNER JOIN Document.DeliveryOrder AS OrderHeader_
	|		ON GoodsTable.Ref = OrderHeader_.Ref
	|WHERE
	|	GoodsTable.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	BEGINOFPERIOD(&Period, DAY) AS Period,
	|	OrderHeader_.Organization AS Organization,
	|	VALUE(Enum.DeliveryTypes.OutgoingInfo) AS DeliveryType,
	|	OrderHeader_.DateOfShipment AS DateOfShipment,
	|	VALUE(Enum.TransportMethods25.ByCarrier) AS DeliveryMethod,
	|	OrderHeader_.Carrier AS Sender,
	|	OrderHeader_.CarrierDeliveryPoint AS SenderPoint,
	|	OrderHeader_.CarrierSDeliveryArea AS Sender_Area,
	|	OrderHeader_.Recipient AS Recipient,
	|	OrderHeader_.DeliveryPointRecipient AS RecipientPoint,
	|	OrderHeader_.DeliveryZone AS Recipient_Area,
	|	&Ref AS PlanningDocument,
	|	GoodsTable.ReferenceOrder AS ReferenceOrder,
	|	UNDEFINED AS Trip,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.DeliveryLineCode AS RowCode,
	|	2 AS Arm,
	|	GoodsTable.Package AS Package,
	|	OrderHeader_.Carrier AS Carrier,
	|	0 AS ToDeliver,
	|	GoodsTable.Count AS ToTrip,
	|	0 AS InTrip,
	|	0 AS InTransit,
	|	0 AS Delivered,
	|	0 AS Canceled,
	|	0 AS ForAssembly,
	|	0 AS AssemblyInProgress,
	|	0 AS Assembled,
	|	&OperationLevel,
	|	TRUE,
	|	0,
	|	FALSE AS PrimaryRegisterRecord,
	|	DATETIME(1, 1, 1) AS SourceShipmentDate,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose
	|FROM
	|	Document.DeliveryOrder.Goods AS GoodsTable
	|		INNER JOIN Document.DeliveryOrder AS OrderHeader_
	|		ON GoodsTable.Ref = OrderHeader_.Ref
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND OrderHeader_.DeliveryToCarrier";
	
	QueryText = StrReplace(QueryText, "Document.DeliveryOrder.Goods", "DocumentDataTableItems");
	QueryText = StrReplace(QueryText, "Document.DeliveryOrder AS OrderHeader_", "DocumentDataHeader AS OrderHeader_");
		
	SynonymForDocumentTable = "GoodsTable";
	GoodsDelivery.SetParametersOfEventRequest(Query, AddlParameters);
	GoodsDelivery.AddDocumentReflectionRequest(Query, Registers, QueryTexts, QueryText, SynonymForDocumentTable);
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region GenerateFrom

// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  Undefined, ValueTableRow - Add a create command based on
//
Function AddGenerateCommand(GenerationCommands) Export
	
	CreateBasedOnCommand = Undefined;
	
	If AccessRight("Insert", Metadata.Documents.DeliveryOrder) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.DeliveryOrder.FullName();
		CreateBasedOnCommand.Presentation =
			TMCommonUse.ObjectPresentation(Metadata.Documents.DeliveryOrder);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "NotUseDeliveryManagement20";
		
	EndIf;
	
	Return CreateBasedOnCommand;
	
EndFunction

#EndRegion

#EndRegion

#EndIf