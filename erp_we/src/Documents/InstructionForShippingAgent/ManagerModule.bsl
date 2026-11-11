// @strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// The function returns the text of the query to determine the details of the delivery.
//
// Returns:
//	String - Query text
//
Function QueryTextDeliveryDetails_() Export
	
	QueryText =
	"SELECT
	|	Header.Number             AS Number,
	|	Header.Posted          AS Posted,
	|	Header.Ref            AS Ref,
	|	Header.ExecutionDate    AS Date,
	|
	|	Header.Point
	|                           AS RecipientSender,
	|
	|	UNDEFINED            AS Carrier,
	|	Header.DeliveryMethod    AS DeliveryMethod,
	|	Header.DeliveryZone      AS Zone,
	|	Header.DeliveryAddress     AS Address,
	|
	|	Header.DeliveryAddressFieldValues
	|		                    AS FieldValueAddress,
	|
	|	Header.DeliveryTimeFrom    AS TimeFrom,
	|	Header.DeliveryTimeTo   AS TimeTo,
	|	AdditionalDeliveryInformation AS AdditionalInformation,
	|	Header.Warehouse             AS Warehouse,
	|	TRUE                  AS DeliverFully,
	|	TRUE                  AS SpecialTransportationConditions,
	|	Header.SpecialTransportationConditionsDescription AS SpecialTransportationConditionsDescription,
	|	FALSE AS SplitGoodsIssueNotesByReferences
	|
	|FROM
	|	Document.InstructionForShippingAgent AS Header
	|WHERE
	|	Header.Ref IN (&References)";
	
	Return QueryText;
	
EndFunction

// The function retrieves data from the base for filling out the order.
//
// Parameters:
//  Basis1 - Array of DocumentRef - reasons for entering orders to the freight forwarder.
// 
// Returns:
//  Structure - with properties:
//  * Warehouses - Array of CatalogRef.Warehouses -
//  * Items_2 - Array of CatalogRef.Partners, CatalogRef.Warehouses, CatalogRef.BusinessStructure -
//  * Contacts - Array of CatalogRef.ContactPersonsForPartners -
//  * TransportMethods - Array of EnumRef.TransportMethods -
//
Function BaseData(Basis1) Export
	
	QueryTemplate =
	"SELECT ALLOWED DISTINCT
	|VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse,
	|VALUE(Catalog.Partners.EmptyRef) AS Partner,
	|VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	|VALUE(Catalog.ContactPersonsForPartners.EmptyRef) AS ContactPerson
	|INTO BaseData
	|FROM #DocumentTable AS T
	|
	|WHERE T.Ref IN (&Basis1)";
	
	BasesByType = TMCommonUse.DecomposeArrayOfReferencesByType(Basis1);
	FirstQuery = True;
	QueryText = "";
	
	TransportMethods = New Array; // Array of EnumRef.TransportMethods
	
	For Each KeyAndValue In BasesByType Do
		ObjectMetadata = Metadata.FindByType(KeyAndValue.Key);
		ObjectTableName = ObjectMetadata.FullName();
		RequestTextByType = QueryTemplate;
		If Common.HasObjectAttribute("Warehouse", ObjectMetadata) Then
			RequestTextByType = StrReplace(RequestTextByType, "VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse", "Warehouse AS Warehouse");
		EndIf;
		If Common.HasObjectAttribute("Partner", ObjectMetadata) Then
			RequestTextByType = StrReplace(RequestTextByType, "VALUE(Catalog.Partners.EmptyRef) AS Partner", "Partner AS Partner");
		EndIf;
		If Common.HasObjectAttribute("Department", ObjectMetadata) Then
			RequestTextByType = StrReplace(RequestTextByType, "VALUE(Catalog.BusinessStructure.EmptyRef) AS Department", "Department AS Department");
		EndIf;
		If Common.HasObjectAttribute("ContactPerson", ObjectMetadata) Then
			RequestTextByType = StrReplace(RequestTextByType, "VALUE(Catalog.ContactPersonsForPartners.EmptyRef) AS ContactPerson", "ContactPerson AS ContactPerson");
		EndIf;
		AddRequestForReasons(QueryText, RequestTextByType, FirstQuery, ObjectTableName);
		
		RequestTextByType = QueryTemplate;
		If Common.HasObjectAttribute("SourceWarehouse", ObjectMetadata) Then
			RequestTextByType = StrReplace(RequestTextByType, "VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse", "SourceWarehouse AS Warehouse");
		EndIf;		
		AddRequestForReasons(QueryText, RequestTextByType, FirstQuery, ObjectTableName);
		
		RequestTextByType = QueryTemplate;
		If Common.HasObjectAttribute("DestinationWarehouse", ObjectMetadata) Then
			RequestTextByType = StrReplace(RequestTextByType, "VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse", "DestinationWarehouse AS Warehouse");
		EndIf;		
		AddRequestForReasons(QueryText, RequestTextByType, FirstQuery, ObjectTableName);
		
		ObjectMetadataTableParts = ObjectMetadata.TabularSections;
		
		For Each TS In ObjectMetadataTableParts Do
			If Not Common.HasObjectAttribute("Warehouse", TS) Then
				Continue;
			EndIf;
			NameOfTSTable = ObjectTableName + "." + TS.Name;
			RequestTextByType = QueryTemplate;
			RequestTextByType = StrReplace(RequestTextByType, "VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse", "Warehouse AS Warehouse");
			AddRequestForReasons(QueryText, RequestTextByType, FirstQuery, NameOfTSTable);
		EndDo;
		For Each TS In ObjectMetadataTableParts Do
			If Not Common.HasObjectAttribute("SourceWarehouse", TS) Then
				Continue;
			EndIf;
			NameOfTSTable = ObjectTableName + "." + TS.Name;
			RequestTextByType = QueryTemplate;
			RequestTextByType = StrReplace(RequestTextByType, "VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse", "SourceWarehouse AS Warehouse");			
			AddRequestForReasons(QueryText, RequestTextByType, FirstQuery, NameOfTSTable);
		EndDo;
		For Each TS In ObjectMetadataTableParts Do
			If Not Common.HasObjectAttribute("DestinationWarehouse", TS) Then
				Continue;
			EndIf;
			NameOfTSTable = ObjectTableName + "." + TS.Name;
			RequestTextByType = QueryTemplate;
			RequestTextByType = StrReplace(RequestTextByType, "VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse", "DestinationWarehouse AS Warehouse");
			AddRequestForReasons(QueryText, RequestTextByType, FirstQuery, NameOfTSTable);
		EndDo;
		
		If Metadata.DefinedTypes.ShipmentReferenceOrder.Type.ContainsType(KeyAndValue.Key) Then
			If TransportMethods.Find(Enums.TransportMethods.InstructionForShippingAgentFromWarehouse) = Undefined Then
				TransportMethods.Add(Enums.TransportMethods.InstructionForShippingAgentFromWarehouse);
			EndIf;
		ElsIf Metadata.DefinedTypes.ReceiptReferenceOrder.Type.ContainsType(KeyAndValue.Key) Then
			If TransportMethods.Find(Enums.TransportMethods.InstructionForShippingAgentToWarehouse) = Undefined Then
				TransportMethods.Add(Enums.TransportMethods.InstructionForShippingAgentToWarehouse);
			EndIf;
		Else
			If TransportMethods.Find(Enums.TransportMethods.InstructionForShippingAgentAtPoint) = Undefined Then
				TransportMethods.Add(Enums.TransportMethods.InstructionForShippingAgentAtPoint);
			EndIf;
		EndIf;
		
	EndDo;
	
	QueryText = QueryText + "
	|//////////////////////////////////////////
	|;
	|" +
	"SELECT ALLOWED
	|	T.Warehouse
	|FROM
	|	BaseData AS T
	|WHERE
	|	T.Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)
	|	AND NOT T.Warehouse.IsFolder
	|
	|GROUP BY
	|	T.Warehouse
	|
	|ORDER BY
	|	COUNT(*) DESC
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	T.Point
	|FROM
	|	(SELECT
	|		T.Partner AS Point,
	|		1 AS Order
	|	FROM
	|		BaseData AS T
	|	WHERE
	|		T.Partner <> VALUE(Catalog.Partners.EmptyRef)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		T.Department,
	|		2
	|	FROM
	|		BaseData AS T
	|	WHERE
	|		T.Department <> VALUE(Catalog.BusinessStructure.EmptyRef)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		T.Warehouse,
	|		3
	|	FROM
	|		BaseData AS T
	|	WHERE
	|		T.Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)
	|		AND NOT T.Warehouse.IsFolder) AS T
	|
	|GROUP BY
	|	T.Point,
	|	T.Order
	|
	|ORDER BY
	|	T.Order,
	|	COUNT(*) DESC
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.ContactPerson
	|FROM
	|	BaseData AS T
	|WHERE
	|	T.ContactPerson <> VALUE(Catalog.ContactPersonsForPartners.EmptyRef)
	|
	|GROUP BY
	|	T.ContactPerson
	|
	|ORDER BY
	|	COUNT(*) DESC";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Basis1", Basis1);
	SetPrivilegedMode(True);
	QueryResult = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	Warehouses = QueryResult[QueryResult.Count()-3].Unload().UnloadColumn("Warehouse");
	Items_2 = QueryResult[QueryResult.Count()-2].Unload().UnloadColumn("Point");
	Contacts = QueryResult[QueryResult.Count()-1].Unload().UnloadColumn("ContactPerson");
	
	ReturnStructure = New Structure;
	ReturnStructure.Insert("Warehouses", Warehouses);
	ReturnStructure.Insert("Items_2", Items_2);
	ReturnStructure.Insert("Contacts", Contacts);
	ReturnStructure.Insert("TransportMethods", TransportMethods);
	
	Return ReturnStructure;
	
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Description of the logic of access rights restrictions
//
// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	(ValueAllowed(Warehouse)
	|	OR DeliveryMethod = VALUE(Enum.TransportMethods.InstructionForShippingAgentAtPoint))
	|		AND ValueAllowed(Point, UNDEFINED AS TRUE)";

EndProcedure

// End StandardSubsystems.AccessManagement

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
//
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure
// End StandardSubsystems.ObjectsVersioning

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

#EndRegion

#EndIf

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Print

// Fills in the list of print commands.
// 
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	// Order to the freight forwarder
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "InstructionForShippingAgent";
	PrintCommand.Presentation = NStr("vi = 'Giao nhận đặt hàng';
									|ru = 'Поручение экспедитору';
									|en = 'Delivery request'; fa = 'درخواست تحویل';
									|it = 'Task a spedizioniere';
									|pl = 'Zamówienie na transport';
									|tr = 'Teslimat talebi'");
	PrintCommand.CheckPostingBeforePrint = True;
	
EndProcedure

// Generates a printable form.
//
// Parameters:
//  ObjectsArray - See PrintManagementOverridable.OnPrint.ObjectsArray
//  PrintParameters - See PrintManagementOverridable.OnPrint.PrintParameters
//  PrintFormsCollection - See PrintManagementOverridable.OnPrint.PrintFormsCollection
//  PrintObjects - See PrintManagementOverridable.OnPrint.PrintObjects
//  OutputParameters - See PrintManagementOverridable.OnPrint.OutputParameters
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "InstructionForShippingAgent") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"InstructionForShippingAgent",
			NStr("vi = 'Giao nhận đặt hàng';
				|ru = 'Поручение экспедитору';
				|en = 'Delivery request'; fa = 'درخواست تحویل';
				|it = 'Task a spedizioniere';
				|pl = 'Zamówienie na transport';
				|tr = 'Teslimat talebi'"),
			CreatePrintedFormOfInstructionsToFreightForwarder(ObjectsArray, PrintObjects, PrintParameters));
		
	EndIf;
	
EndProcedure

Function CreatePrintedFormOfInstructionsToFreightForwarder(ObjectsArray, PrintObjects, PrintParameters)
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_InstructionForShippingAgent";
	
	SetPrivilegedMode(True);
	
	DataForPrint = GetDataForPrintedFormInstructionsToFreightForwarder(ObjectsArray, PrintParameters);
	FillInTabularDocumentAssignmentToFreightForwarder(SpreadsheetDocument, DataForPrint, PrintObjects);
	
	SetPrivilegedMode(False);
	
	Return SpreadsheetDocument;
	
EndFunction

Function GetDataForPrintedFormInstructionsToFreightForwarder(ObjectsArray, PrintParameters)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	InstructionForShippingAgent.Ref AS Ref,
	|	InstructionForShippingAgent.Number AS OrderNumber_,
	|	InstructionForShippingAgent.Date AS Date,
	|	InstructionForShippingAgent.DeliveryMethod AS DeliveryMethod,
	|	InstructionForShippingAgent.Warehouse.Presentation AS Warehouse,
	|	PRESENTATION(InstructionForShippingAgent.Point) AS Point,
	|	InstructionForShippingAgent.ContactPerson.Presentation AS Contact,
	|	InstructionForShippingAgent.DeliveryAddress AS DeliveryAddress,
	|	InstructionForShippingAgent.DeliveryZone.Presentation AS DeliveryZone,
	|	InstructionForShippingAgent.DeliveryTimeFrom AS TimeFrom,
	|	InstructionForShippingAgent.DeliveryTimeTo AS TimeTo,
	|	InstructionForShippingAgent.AdditionalDeliveryInformation AS ItemInformation,
	|	InstructionForShippingAgent.SpecialTransportationConditionsDescription AS InstructionDescription,
	|	InstructionForShippingAgent.EmployeeResponsible.Presentation AS EmployeeResponsible
	|FROM
	|	Document.InstructionForShippingAgent AS InstructionForShippingAgent
	|WHERE
	|	InstructionForShippingAgent.Ref IN(&ObjectsArray)";
	
	Query.SetParameter("ObjectsArray", ObjectsArray);
	
	QueryResult = Query.Execute();
	DataForPrint = QueryResult.Unload();
	
	Return DataForPrint;
	
EndFunction

Procedure FillInTabularDocumentAssignmentToFreightForwarder(SpreadsheetDocument, DataForPrint, PrintObjects)
	
	PrintDataString = DataForPrint[0];
	Template = PrintManagement.PrintFormTemplate("Document.InstructionForShippingAgent.PF_MXL_InstructionForShippingAgent");
	
	// Region of the document
	BarcodeArea_ = Template.GetArea("BarcodeArea_");
	TitleArea = Template.GetArea("Title");
	ItemArea = Template.GetArea("AreaItem");
	AddressArea = Template.GetArea("DeliveryAreaAddress");
	DescriptionArea = Template.GetArea("AreaDescription_");
	LabelArea = Template.GetArea("Signatures");
	
	// Details of the document header
	DocumentAttributes = New Structure;
	DocumentAttributes.Insert("Number", PrintDataString.OrderNumber_);
	DocumentAttributes.Insert("Date", PrintDataString.Date);
	
	DocumentTitle = TMCommonUseClientServer.GenerateDocumentTitle(DocumentAttributes,
		NStr("vi = 'Giao nhận đặt hàng';
			|ru = 'Поручение экспедитору';
			|en = 'Delivery request'; fa = 'درخواست تحویل';
			|it = 'Task a spedizioniere';
			|pl = 'Zamówienie na transport';
			|tr = 'Teslimat talebi'", Common.DefaultLanguageCode()));
	
	// Filling in the parameters of the PF_MXL areas_Instructions to the Examiner
	HeaderDataStructure = New Structure;
	HeaderDataStructure.Insert("TitleText", DocumentTitle);
	TitleArea.Parameters.Fill(HeaderDataStructure);
	
	ItemArea.Parameters.Fill(PrintDataString);
	AddressArea.Parameters.Fill(PrintDataString);
	DescriptionArea.Parameters.Fill(PrintDataString);
	LabelArea.Parameters.Fill(PrintDataString);
	
	// Output of PF_MXL areas_Instructions to the Examiner
	BarcodingOfPrintForms.OutputBarcodeToTabularDocument(
		SpreadsheetDocument,
		Template,
		TitleArea,
		PrintDataString.Ref);
	
	SpreadsheetDocument.Put(TitleArea);
	
	If PrintDataString.DeliveryMethod = Enums.TransportMethods.InstructionForShippingAgentFromWarehouse
		Or PrintDataString.DeliveryMethod = Enums.TransportMethods.InstructionForShippingAgentToWarehouse Then
		
		AreaDirectionFromWhere = Template.GetArea("HeadingDirection");
		Warehouse_Area = Template.GetArea("AreaWarehouse");
		AreaDirectionTo = Template.GetArea("HeadingDirection");
		
		DataStructureFromWhere = New Structure;
		DataStructureFromWhere.Insert("Direction", NStr("vi = 'Địa chỉ gửi';
														|ru = 'Откуда';
														|en = 'From'; fa = 'از';
														|it = 'Da dove';
														|pl = 'From';
														|tr = 'Nereden'", Common.DefaultLanguageCode()));
		AreaDirectionFromWhere.Parameters.Fill(DataStructureFromWhere);
		
		Warehouse_Area.Parameters.Warehouse = PrintDataString.Warehouse;

		WhereDataStructure = New Structure;
		WhereDataStructure.Insert("Direction", NStr("vi = 'Địa chỉ nhận';
													|ru = 'Куда';
													|en = 'To'; fa = 'به';
													|it = 'Dove (destinazione)';
													|pl = 'To';
													|tr = 'Nereye'", Common.DefaultLanguageCode()));
		AreaDirectionTo.Parameters.Fill(WhereDataStructure);
		
		If PrintDataString.DeliveryMethod = Enums.TransportMethods.InstructionForShippingAgentFromWarehouse Then
			
			SpreadsheetDocument.Put(AreaDirectionFromWhere);
			SpreadsheetDocument.Put(Warehouse_Area);
			SpreadsheetDocument.Put(AreaDirectionTo);
			
		Else
			
			SpreadsheetDocument.Put(AreaDirectionTo);
			SpreadsheetDocument.Put(Warehouse_Area);
			SpreadsheetDocument.Put(AreaDirectionFromWhere);
			
		EndIf;
		
	Else
		AreaDirection = Template.GetArea("HeadingDirection");
		DirectionDataStructure = New Structure;
		DirectionDataStructure.Insert("Direction", NStr("vi = 'Ở đâu';
														|ru = 'Где';
														|en = 'Where'; fa = 'کجا';
														|it = 'Dove';
														|pl = 'Where';
														|tr = 'Nerede'", Common.DefaultLanguageCode()));
		AreaDirection.Parameters.Fill(DirectionDataStructure);
		
		SpreadsheetDocument.Put(AreaDirection);
	EndIf;
	
	SpreadsheetDocument.Put(ItemArea);
	
	If ValueIsFilled(PrintDataString.Contact) Then
		ContactArea_ = Template.GetArea("ContactArea");
		
		ContactArea_.Parameters.Fill(PrintDataString);
		SpreadsheetDocument.Put(ContactArea_);
	EndIf;
	
	SpreadsheetDocument.Put(AddressArea);
	
	If ValueIsFilled(PrintDataString.DeliveryZone) Then
		ZoneArea = Template.GetArea("AreaZone");
		
		ZoneArea.Parameters.Fill(PrintDataString);
		SpreadsheetDocument.Put(ZoneArea);
	EndIf;
	
	If ValueIsFilled(PrintDataString.TimeFrom)
		Or ValueIsFilled(PrintDataString.TimeTo) Then
		
		TimeDomain = Template.GetArea("AreaDeliveryTime");
		
		TimeFrom = Format(PrintDataString.TimeFrom, "DF=HH:MM");
		TimeTo = Format(PrintDataString.TimeTo, "DF=HH:MM");
		
		TimeDomain.Parameters.TimeFrom = TimeFrom;
		TimeDomain.Parameters.TimeTo = TimeTo;
		
		SpreadsheetDocument.Put(TimeDomain);
		
	EndIf;
	
	SpreadsheetDocument.Put(DescriptionArea);
	SpreadsheetDocument.Put(LabelArea);
	
EndProcedure

#EndRegion

#Region GenerateFrom

// Adds the command to create the document "order to the freight forwarder".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  - ValueTableRow: See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands -
//  - Undefined -
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.InstructionForShippingAgent) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.InstructionForShippingAgent.FullName();
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.InstructionForShippingAgent";
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.InstructionForShippingAgent);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "NotUseDeliveryManagement25";
		CreateBasedOnCommand.MultipleChoice = True;
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion 

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
EndProcedure

#EndRegion 

#Region InfobaseUpdate

Procedure AddRequestForReasons(QueryText, RequestTextForExtension, FirstQuery, TableName)
	
	If Not ValueIsFilled(RequestTextForExtension) Then
		Return;
	EndIf;
	RequestTextForExtension = StrReplace(RequestTextForExtension, "#DocumentTable", TableName);
	If FirstQuery Then
		FirstQuery = False;
		QueryText = RequestTextForExtension;
	Else
		RequestTextForExtension = StrReplace(RequestTextForExtension, "INTO BaseData", "");
		RequestTextForExtension = StrReplace(RequestTextForExtension, "ALLOWED", "");
		QueryText = QueryText +
		"
		|
		|UNION ALL
		|
		|"
		+ RequestTextForExtension;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf

