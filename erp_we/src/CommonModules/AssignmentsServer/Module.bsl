////////////////////////////////////////////////////////////////
// The Server Assignments module contains procedures and functions for 
// working with assignments on the server.
//
////////////////////////////////////////////////////////////////

#Region Public

#Region FillType

// Fills in the Assignment type field in the table rows
//
// Parameters:
//  Table             - FormDataCollection - table being processed
//  Rows              - Array of FormDataCollectionItem - array of processed strings
//                      - Undefined
//  FillParameters - See AssignmentsClientServer.FillParameters
//
Procedure FillInDestinationTypeInTable(Table, Rows = Undefined, FillParameters = Undefined) Export
	
	If Table.Count() = 0 Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	*
	|INTO Table
	|FROM
	|	&Table AS Table
	|
	|INDEX BY
	|	Purpose,
	|	AssignmentType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.LineNumber              AS LineNumber,
	|	Table.Purpose.AssignmentType AS AssignmentType,
	|	CASE
	|		WHEN Table.Purpose.AssignmentType = &AssignmentType
	|				THEN &StringDestinationTypeNameOfFieldToBeFilledIn
	|		ELSE &StringDestinationType
	|	END                            AS FieldsToFillIn,
	|	&Simple                    AS SynonymOfFieldToFillIn
	|FROM
	|	Table AS Table
	|WHERE
	|	ISNULL(Table.Purpose.AssignmentType, VALUE(Enum.AssignmentTypes.EmptyRef)) <> Table.AssignmentType
	|";
	
	AssignmentType = Null;
	Simple  = Null;
	Columns       = "LineNumber, Purpose, AssignmentType";
	
	StringDestinationType                    = "AssignmentType";
	StringDestinationTypeNameOfFieldToBeFilledIn = "AssignmentType, NameOfFieldToFillIn";
	
	If ValueIsFilled(FillParameters) Then
		
		AssignmentType = FillParameters.AssignmentType;
		Simple  = FillParameters.Simple;
		TSFieldName     = FillParameters.TSFieldName;
		
		StringDestinationTypeNameOfFieldToBeFilledIn  =
			StrReplace(StringDestinationTypeNameOfFieldToBeFilledIn, "NameOfFieldToFillIn", FillParameters.NameOfFieldToFillIn);
		
		Query.Text  = StrReplace(Query.Text, "SynonymOfFieldToFillIn", FillParameters.NameOfFieldToFillIn);
		
		If ValueIsFilled(TSFieldName) Then
			Query.Text = StrReplace(Query.Text, "&Simple", StrTemplate("Table.%1", TSFieldName));
			Columns      = StrTemplate("LineNumber, Purpose, AssignmentType, %1", TSFieldName);
		EndIf;
		
	EndIf;

	Query.SetParameter("Table",                                Table.Unload(Rows, Columns));
	Query.SetParameter("AssignmentType",                          AssignmentType);
	Query.SetParameter("Simple",                           Simple);
	Query.SetParameter("StringDestinationType",                    StringDestinationType);
	Query.SetParameter("StringDestinationTypeNameOfFieldToBeFilledIn", StringDestinationTypeNameOfFieldToBeFilledIn);
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	While Selection.Next() Do
		FillPropertyValues(Table[Selection.LineNumber - 1], Selection, Selection.FieldsToFillIn);
	EndDo;
	
EndProcedure

// Fills in the service Attribute "Type of assignment" in the line according to the data of the specified assignment
//
// Parameters:
//  CurrentRow        - Structure            - data of the processed string.
//  CachedValues - Structure            - saved values of parameters used during processing.
//  FillParameters  - See AssignmentsClientServer.FillParameters
//
Procedure FillInDestinationType(CurrentRow, CachedValues, FillParameters = Undefined) Export
	
	AssignmentType = Undefined;
	
	If ValueIsFilled(CurrentRow.Purpose) Then
		
		PropertiesPurpose = CachedValues.AssignmentProperties.Get(CurrentRow.Purpose);
		
		If PropertiesPurpose = Undefined Then 
		
			AssignmentProperties = Catalogs.Assignments.AssignmentProperties(CurrentRow.Purpose);
			PropertiesPurpose = AssignmentProperties.Get(CurrentRow.Purpose);
				
			CachedValues.AssignmentProperties.Insert(CurrentRow.Purpose, PropertiesPurpose);
					
		EndIf;
		
		AssignmentType = PropertiesPurpose.AssignmentType;
		
	EndIf;
	
	CurrentRow.AssignmentType = AssignmentType;
	
	If ValueIsFilled(FillParameters)
	   And CurrentRow.AssignmentType = FillParameters.AssignmentType Then
	
		CurrentRow[FillParameters.NameOfFieldToFillIn] = ?(ValueIsFilled(FillParameters.TSFieldName),
																	CurrentRow[FillParameters.TSFieldName],
																	FillParameters.Simple);
		
	EndIf;
	
EndProcedure

// Constructor of the structure of parameters for embedding activities in a document.
//  Returns:
//   Structure - field structure:
//    * NamesOfTablePartsToFillInAssignment - String, Undefined -
//    * NamesOfTablePartsToCleanUpIncorrectAssignments - String, Undefined -
//    * StringProcessingConditions - Map of String -
//    * FillInAssignmentInHeader - Boolean
//    * NameOfFormElementIsSeparate - String, Undefined -
//    * NameOfGroupOfCommandElementsIsSeparate - String, Undefined -
//    * OrderDetailsName - String, Undefined -
//    * DocumentDefinesFunctionAssignmentTemplate - Boolean -
//    * NamesOfValueTablesForClearingIncorrectAssignments - String, Undefined -
Function ProcedureForFillingOutAssignmentsInDocument() Export
	
	FillOrder = New Structure();
	FillOrder.Insert("NamesOfTablePartsToFillInAssignment",          Undefined);
	FillOrder.Insert("NamesOfTablePartsToCleanUpIncorrectAssignments", Undefined);
	FillOrder.Insert("StringProcessingConditions",                                New Map());
	FillOrder.Insert("FillInAssignmentInHeader",                            False);
	FillOrder.Insert("NameOfFormElementIsSeparate",                          Undefined);
	FillOrder.Insert("NameOfGroupOfCommandElementsIsSeparate",                 Undefined);
	FillOrder.Insert("OrderDetailsName",                                 Undefined);
	FillOrder.Insert("DocumentDefinesFunctionAssignmentTemplate",          False);
	FillOrder.Insert("NamesOfValueTablesForClearingIncorrectAssignments",  Undefined);
	
	Return FillOrder;
	
EndFunction

Function ConditionsForProcessingAssignmentsInRows(ConditionTemplates) Export
	
	Conditions = StrSplit(ConditionTemplates, ",");
	
	StringProcessingConditions = New Array();
	
	If Conditions.Find("ItemsType") <> Undefined And Conditions.Find("RowCode") <> Undefined Then
		
		FieldsStructure = New Structure();
		FieldsStructure.Insert("ItemsType", Enums.ItemsTypes.OwnGoods);
		FieldsStructure.Insert("RowCode", 0);
		
		StringProcessingConditions.Add(FieldsStructure);
		
		FieldsStructure = New Structure();
		FieldsStructure.Insert("ItemsType", Enums.ItemsTypes.Work_5);
		FieldsStructure.Insert("RowCode", 0);
		
		StringProcessingConditions.Add(FieldsStructure);
		
	ElsIf Conditions.Find("ItemsType") <> Undefined Then
		
		FieldsStructure = New Structure();
		FieldsStructure.Insert("ItemsType", Enums.ItemsTypes.OwnGoods);
		
		StringProcessingConditions.Add(FieldsStructure);
		
		FieldsStructure = New Structure();
		FieldsStructure.Insert("ItemsType", Enums.ItemsTypes.Work_5);
		
		StringProcessingConditions.Add(FieldsStructure);
		
	EndIf;
	
	Return StringProcessingConditions;
	
EndFunction

// Default structure constructor for use in the document formdescription functions
// for filling in requests related to the activity Of document Manager modules.
//
// Returns:
//  Structure - structure with fields:
//   *IssuedByOrder - Boolean - indicates that the rows of the table parts can be made to order.
//   *ThisIsSourceOfNeed - Boolean - indicates that the document is a document of fixing a separate need (order).
//   *ThereIsVHFAppointment - Boolean - indicates that the rows of the table parts have the assignment attribute.
//   *InTSPurposeOfShipment - Boolean - indicates that in the rows of the table parts, the destination attribute is used to indicate
//                            the destination of the goods and works being shipped, and not accepted).
//   *TabSections - Structure - description of the table part of the document, used to override the general parameters set for
//                           all table parts.
//
Function ObjectStructure() Export
	
	FilterBusinessTransaction = New Array();
	FilterBusinessTransaction.Add("SHIPMENT");
	FilterBusinessTransaction.Add("INPAYMENT");
	DescriptionOfUpperPart = New Structure("FilterBusinessTransaction, IssuedByOrder", FilterBusinessTransaction, True);
	
	TabSections = New Structure();
	TabSections.Insert("Goods", DescriptionOfUpperPart);
	
	ObjectStructure = New Structure();
	ObjectStructure.Insert("TabSections", TabSections);
	ObjectStructure.Insert("IssuedByOrder", True);
	ObjectStructure.Insert("ThisIsSourceOfNeed", False);
	ObjectStructure.Insert("ThereIsVHFAppointment", True);
	ObjectStructure.Insert("InTSPurposeOfShipment", False);
	
	Return ObjectStructure;
	
EndFunction

//  Used in document forms. Fills in the details of the "Ship separately" form of the table part based on the fullness of the destination.
//
// Parameters:
//  Form - ClientApplicationForm - the form in which you need to initialize the details associated with the use
//                             of business lines.
//
Procedure ReFillInServiceDetailsOfTablePart(Form, IsOutdated = False) Export
	
	If IsOutdated Then
		DocumentProcessingProcedure = Form.FormMetadata;
	Else
		DocumentProcessingProcedure = Form.AssignmentsCachedValues.DocumentProcessingProcedure;
	EndIf;
	TagName = DocumentProcessingProcedure.NameOfFormElementIsSeparate;
	If TagName <> Undefined Then
		
		OrderDetailsName = DocumentProcessingProcedure.OrderDetailsName;
		Cache = Form.LineOfBusinessCachedValues;
		
		ThisIsInvoiceForOrder = Form.Object[OrderDetailsName];
		ThisIsBooleanTypeProp = TypeOf(ThisIsInvoiceForOrder) = Type("Boolean");
		
		If ValueIsFilled(Cache.DefaultAssignment)
			And (ThisIsBooleanTypeProp And Not ThisIsInvoiceForOrder
				Or Not ThisIsBooleanTypeProp And Not ValueIsFilled(ThisIsInvoiceForOrder)) Then
			UpdateFlagFromAssignmentOfTablePart(Form, IsOutdated);
		EndIf;
		
	EndIf;
	
EndProcedure

// Returns an assignment by business line.
//
// Parameters:
//  LineOfBusiness - CatalogRef.LinesOfBusiness - direction of activity.
//
// Returns:
//  CatalogRef.Assignments - an appointment related to the line of business.
//
Function PushingAssignment(LineOfBusiness) Export
	
	Purpose = Catalogs.Assignments.EmptyRef();
	If ValueIsFilled(LineOfBusiness) And GetFunctionalOption("UseOrderSupplyWithAssignment") Then
		
		Attributes = Common.ObjectAttributesValues(LineOfBusiness, "CostAccounting, Purpose");
		If Attributes.CostAccounting Then
			
			Purpose = Attributes.Purpose;
			
		EndIf;
		
	EndIf;
	
	Return Purpose;
	
EndFunction

#EndRegion

#Region CommonFormEventHandlers

// Used in forms of documents, in the same procedures, "Pictureisunrelated".
// Initializes the form details used during the user's interactive work. Fills in the assignment based on the
// direction of activity.
//
// Parameters:
//  Form - ClientApplicationForm - the form in which you need to initialize the details associated with the use
//   of business lines.
//  IsOutdated - Boolean - for compatibility with the direction of the activity of the server.Parish and Creation in the Server
//
Procedure OnReadCreateAtServer(Form, IsOutdated = False) Export
	
	FormObject = Form.Object; // DocumentObject - 
	ObjectManager = Common.ObjectManagerByRef(FormObject.Ref);
	If IsOutdated Then
		Cache = LineOfBusinessCachedValues();
		Form.LineOfBusinessCachedValues = Cache;
		DocumentProcessingProcedure = ObjectManager.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity(Form);
		Form.FormMetadata = DocumentProcessingProcedure;
	Else
		Cache = AssignmentsCachedValues();
		Form.AssignmentsCachedValues = Cache;
		DocumentProcessingProcedure = ObjectManager.ProcedureForFillingOutAssignmentsInDocument(Form);
		Cache.DocumentProcessingProcedure = DocumentProcessingProcedure;
	EndIf;
	
	Cache.UseOrderSupplyWithAssignment = GetFunctionalOption("UseOrderSupplyWithAssignment");
	Cache.UseLinesOfBusiness        = GetFunctionalOption("UseCostAccountingByLinesOfBusiness");
	
	DefaultAssignment = Catalogs.Assignments.EmptyRef();
	If DocumentProcessingProcedure.DocumentDefinesFunctionAssignmentTemplate Then
		
		DefaultAssignment = Catalogs.Assignments.EmptyRef();
		DestinationPattern = ObjectManager.DestinationPattern(Form.Object);
		If Not TMCommonUseClientServer.StructuresAreEqual(DestinationPattern, Catalogs.Assignments.NewSubmenuTemplate()) Then
			DefaultAssignment = Catalogs.Assignments.FindByTemplate(DestinationPattern);
		EndIf;
		
	Else
		If DocumentProcessingProcedure.NamesOfTablePartsToFillInAssignment <> Undefined Then
			DefaultAssignment = PushingAssignment(Form.Object.LineOfBusiness);
		EndIf;
	EndIf;

	// Recording form data.
	Cache.DefaultAssignment = DefaultAssignment;
		
	If DocumentProcessingProcedure.FillInAssignmentInHeader And Not ValueIsFilled(FormObject.Ref) Then
		
		// Initializing the assignment of a new document.
		DestinationPattern = ObjectManager.DestinationPattern(Form.Object);
		
		// If the current separation option is not on order.
		If DestinationPattern.OrderDocument = Undefined Then
			Form.Object.Purpose = Catalogs.Assignments.FindByTemplate(DestinationPattern);
		EndIf;
		
	EndIf;
	
	// Working with the flag Separately
	TagName = DocumentProcessingProcedure.NameOfFormElementIsSeparate;
	Utilities = New Structure("PropsNameIsSeparate");
	
	If TagName <> Undefined Then
		FormItem = Form.Items[TagName];
		FieldArray = StrSplit(FormItem.DataPath, ".");
		Utilities.PropsNameIsSeparate = FieldArray[2];
	EndIf; 
	DocumentProcessingProcedure.Insert("Utilities", Utilities);
	SetVisibilityOfElementsSeparately(Form, IsOutdated);
	ReFillInServiceDetailsOfTablePart(Form, IsOutdated);
	
EndProcedure

// It is used in document forms, in the "post-recording Server" procedures of the same name.
// Fills in the details of the "Ship separately" form in the table part based on the fullness of the destination.
//
// Parameters:
//  Form - ClientApplicationForm - the form in which you need to initialize the details associated with the use
//            of business lines.
//  IsOutdated - Boolean - for compatibility with the direction of the activity of the server.When changing the direction of activity
//
Procedure AfterWriteAtServer(Form, IsOutdated) Export
	
	ReFillInServiceDetailsOfTablePart(Form, IsOutdated);
	
EndProcedure

#EndRegion

#Region EventHandlersForElementsOnForms

// Fills in the default assignment in the document, in accordance with the changes in the template
// that occurred as a result of editing the Attributes of the document.
// Checks the assignments in the table part and fills them in accordance with the changed template.
// Parameters:
//  Form - ClientApplicationForm - the form of the document
//  IsOutdated - Boolean - for compatibility with the direction of the activity of the server.When changing the direction of activity
// Returns:
//  Array of FormDataCollectionItem - array of modified rows of the tabular part of the document.
//
Function WhenYouChangeDestinationTemplateInDocument(Form, IsOutdated = False) Export
	
	FoundRows = New Array();
	
	If IsOutdated Then
		Cache = Form.LineOfBusinessCachedValues;
		DocumentProcessingProcedure = Form.FormMetadata;
	Else
		Cache = Form.AssignmentsCachedValues;
		DocumentProcessingProcedure = Cache.DocumentProcessingProcedure;
	EndIf;
	
	If (Not Cache.UseLinesOfBusiness And IsOutdated) Or Not Cache.UseOrderSupplyWithAssignment Then
		Return FoundRows;
	EndIf;
	
	// Initialize the assignment for the modified document.
	FormObject = Form.Object; // DocumentObject - 
	ObjectManager = Common.ObjectManagerByRef(FormObject.Ref);
	
	If DocumentProcessingProcedure.FillInAssignmentInHeader Then
		
		DestinationPattern = ObjectManager.DestinationPattern(Form.Object);
		
		// If the template is filled in completely or the current separation option is not on order.
		If ValueIsFilled(FormObject.Ref) Or DestinationPattern.OrderDocument = Undefined Then
			Purpose = Catalogs.Assignments.FindByTemplate(DestinationPattern);
		Else
			Purpose = Undefined; // if such an appointment is not yet in the database, then it is necessary that the remnants of the old appointment are not selected.
		EndIf;
		
		// Recording form data.
		Form.Object.Purpose = Purpose;
		
	EndIf;
	
	// Getting form data.
	LineOfBusiness = Form.Object.LineOfBusiness;
	PushingAssignment = PushingAssignment(LineOfBusiness);
	DefaultAssignment = Catalogs.Assignments.EmptyRef();
	If DocumentProcessingProcedure.DocumentDefinesFunctionAssignmentTemplate Then
		
		DestinationPattern = ObjectManager.DestinationPattern(Form.Object);
		If Not TMCommonUseClientServer.StructuresAreEqual(DestinationPattern, Catalogs.Assignments.NewSubmenuTemplate()) Then
			DefaultAssignment = Catalogs.Assignments.FindByTemplate(DestinationPattern);
		EndIf;
		
	Else
		
		If DocumentProcessingProcedure.NamesOfTablePartsToFillInAssignment <> Undefined Then
			DefaultAssignment = PushingAssignment;
		EndIf;
		
	EndIf;

	// Recording form data.
	Cache.DefaultAssignment = DefaultAssignment;
	
	Result = New Array();
	If DocumentProcessingProcedure.NamesOfTablePartsToFillInAssignment <> Undefined Then
		
		OrderDetailsName = DocumentProcessingProcedure.OrderDetailsName;
		DefaultAssignment = Undefined;

		ThisIsInvoiceForOrder = False;
		ThisIsBooleanTypeProp = False;
		If OrderDetailsName <> Undefined Then
			ThisIsInvoiceForOrder = Form.Object[OrderDetailsName];
			ThisIsBooleanTypeProp = TypeOf(ThisIsInvoiceForOrder) = Type("Boolean");
		EndIf;
		
		DefaultAssignment = Undefined;
		If OrderDetailsName = Undefined
			Or ThisIsBooleanTypeProp And Not ThisIsInvoiceForOrder
			Or Not ThisIsBooleanTypeProp And Not ValueIsFilled(ThisIsInvoiceForOrder) Then
			DefaultAssignment = Cache.DefaultAssignment;
		EndIf;
		
		Result = FindRowsInCollections(
			Form,
			DocumentProcessingProcedure.NamesOfTablePartsToFillInAssignment,
			DocumentProcessingProcedure.StringProcessingConditions);
			
		For Each String In Result Do
			String.Purpose = DefaultAssignment;
		EndDo;
		
	EndIf;
	
	If DocumentProcessingProcedure.NamesOfTablePartsToCleanUpIncorrectAssignments <> Undefined Then
		
		DefaultAssignment = Cache.DefaultAssignment;
		
		AssignmentForMatching = DefaultAssignment;
		If Not ValueIsFilled(AssignmentForMatching) Then
			AssignmentForMatching = PushingAssignment;
		EndIf;
		
		FoundRows = FindRowsInCollections(
			Form,
			DocumentProcessingProcedure.NamesOfTablePartsToCleanUpIncorrectAssignments,
			DocumentProcessingProcedure.StringProcessingConditions);
			
		CheckDataInCollectionRows(FoundRows, AssignmentForMatching, DefaultAssignment);
		
		If Result.Count() > 0 Then
			CommonClientServer.SupplementArray(Result, FoundRows);
		Else
			Result = FoundRows;
		EndIf;
		
	EndIf;
	
	If DocumentProcessingProcedure.NamesOfValueTablesForClearingIncorrectAssignments <> Undefined Then
		
		DefaultAssignment = Cache.DefaultAssignment;
		
		AssignmentForMatching = DefaultAssignment;
		If Not ValueIsFilled(AssignmentForMatching) Then
			AssignmentForMatching = PushingAssignment;
		EndIf;
		
		FoundRows = FindRowsInCollectionsOfForm(
			Form,
			DocumentProcessingProcedure.NamesOfValueTablesForClearingIncorrectAssignments,
			DocumentProcessingProcedure.StringProcessingConditions);
			
		CheckDataInCollectionRows(FoundRows, AssignmentForMatching, DefaultAssignment);
		
		If Result.Count() > 0 Then
			CommonClientServer.SupplementArray(Result, FoundRows);
		Else
			Result = FoundRows;
		EndIf;
		
	EndIf;
	
	ReFillInServiceDetailsOfTablePart(Form, IsOutdated);
	
	// Working with the flag Separately
	SetVisibilityOfElementsSeparately(Form, IsOutdated);

	Return Result;
	
EndFunction

// Used in the order to processor document form when filling out a specification document.
// Initializes the form details used during the user's interactive work. Fills in the assignment based on the
// direction of activity.
//
// Parameters:
//  Form - ClientApplicationForm - the form in which you need to initialize the details associated with the use
//   of business lines.
//  IsOutdated - Boolean - for compatibility with the direction of the activity of the server.When filling in the Server specificationservers
//
Procedure WhenFillingInServerSpecification(Form, IsOutdated = False) Export
	
	If IsOutdated Then
		Cache = Form.LineOfBusinessCachedValues;
	Else
		Cache = Form.AssignmentsCachedValues;
	EndIf;
	
	If (Not Cache.UseLinesOfBusiness And IsOutdated) Or Not Cache.UseOrderSupplyWithAssignment Then
		Return;
	EndIf;
	
	// Getting form data.
	Purpose = Cache.DefaultAssignment;
	LineOfBusiness = Form.Object.LineOfBusiness;
	
	FillOutAppointment = ValueIsFilled(Purpose) Or ValueIsFilled(LineOfBusiness);
	
	If FillOutAppointment Then
		
		// Processing.
		FilterConditions = New Map();
		FilterConditions.Insert("RecyclableWaste", ConditionsForProcessingAssignmentsInRows("ItemsType"));
		FoundRows = FindRowsInCollections(Form, "RecyclableWaste", FilterConditions);
		PushingAssignment = PushingAssignment(LineOfBusiness);
		CheckDataInCollectionRows(
			FoundRows,
			PushingAssignment,
			Undefined);
		
	EndIf;
	
EndProcedure

// Used in document forms. Sets the conditional design of the flag Separately.
//
// Parameters:
//  Form - ClientApplicationForm - the form in which you need to set the conditional design.
//  IsOutdated - Boolean - for compatibility with the direction of the activity of the server.Set the conditional form of the flag separately
Procedure SetConditionalAppearanceOfFlagSeparately(Form, IsOutdated = False) Export
	
	If IsOutdated Then
		DocumentProcessingProcedure = Form.FormMetadata;
	Else
		DocumentProcessingProcedure = Form.AssignmentsCachedValues.DocumentProcessingProcedure;
	EndIf;
	
	TagName = DocumentProcessingProcedure.NameOfFormElementIsSeparate;
	If TagName <> Undefined Then
		
		FormItem = Form.Items[TagName];
		FieldArray = StrSplit(FormItem.DataPath, ".");
		PathToProductType = FieldArray[0] + "." + FieldArray[1] + "." + "ItemsType";

		ConditionalAppearance = Form.ConditionalAppearance;
		Item = ConditionalAppearance.Items.Add();
	
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(TagName);
		
		ListOfProductTypes = New ValueList();
		ListOfProductTypes.Add(Enums.ItemsTypes.OwnGoods);
		ListOfProductTypes.Add(Enums.ItemsTypes.Work_5);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(PathToProductType);
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
		ItemFilter.RightValue = ListOfProductTypes;
		
		Item.Appearance.SetParameterValue("Show", False);
		
	EndIf;
	
EndProcedure

// Used in document forms, in procedures that lead to changing the flag for orders.
// Controls the visibility of elements.
//
// Parameters:
//  Form - ClientApplicationForm - the form in which you need to respond to a change in the flag for orders.
//  IsOutdated - Boolean - for compatibility with the direction of the activity of the server.Set the visibility of the elements separately
//
Procedure SetVisibilityOfElementsSeparately(Form, IsOutdated = False) Export
	
	If IsOutdated Then
		DocumentProcessingProcedure = Form.FormMetadata;
	Else
		DocumentProcessingProcedure = Form.AssignmentsCachedValues.DocumentProcessingProcedure;
	EndIf;
	DefaultAssignment = Catalogs.Assignments.EmptyRef();
	If DocumentProcessingProcedure.NamesOfTablePartsToFillInAssignment <> Undefined Then
		DefaultAssignment = PushingAssignment(Form.Object.LineOfBusiness);
	EndIf;
	TagName = DocumentProcessingProcedure.NameOfFormElementIsSeparate;
	NameOfGroupOfCommandElements = DocumentProcessingProcedure.NameOfGroupOfCommandElementsIsSeparate;
	OrderDetailsName = DocumentProcessingProcedure.OrderDetailsName;
	
	If TagName <> Undefined Then
		
		ThisIsInvoiceForOrder = Form.Object[OrderDetailsName];
		ThisIsBooleanTypeProp = TypeOf(ThisIsInvoiceForOrder) = Type("Boolean");
		DisplayElements = ValueIsFilled(DefaultAssignment)
			And (ThisIsBooleanTypeProp And Not ThisIsInvoiceForOrder
				Or Not ThisIsBooleanTypeProp And Not ValueIsFilled(ThisIsInvoiceForOrder));
		Form.Items[TagName].Visible = DisplayElements;
		Form.Items[NameOfGroupOfCommandElements].Visible = DisplayElements;
		
	EndIf;
	 
EndProcedure

// Adds a request to the request package to get the data needed to fill in the data for the intended purpose.
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure AddQueryTextDetailsForIntendedPurpose(StructureOfActions, QueryDetails, CachedValues) Export
	
	Var ActionParameters;
	
	If BatchProcessingOfTablePartServer.YouNeedToPerformAction(
		"FillInServiceDetailsForPurpose",
		StructureOfActions,
		CachedValues,
		ActionParameters) Then
		
		If TypeOf(ActionParameters) = Type("Structure")
			And ActionParameters.Property("OnlyDestinationType")
			And ActionParameters.OnlyDestinationType = True Then
			QueryText = "
			|SELECT ALLOWED
			|	DataSource.IdOfTTRow AS IdOfTTRow,
			|	ISNULL(CatAssignments.AssignmentType, VALUE(Enum.AssignmentTypes.EmptyRef)) AS AssignmentType
			|FROM
			|	TTDataSource AS DataSource
			|	LEFT JOIN Catalog.Assignments AS CatAssignments
			|		ON DataSource.Purpose = CatAssignments.Ref";
		Else
			QueryText = "
			|SELECT ALLOWED
			|	DataSource.IdOfTTRow AS IdOfTTRow,
			|	ISNULL(CatAssignments.AssignmentType, VALUE(Enum.AssignmentTypes.EmptyRef)) AS AssignmentType,
			|	ISNULL(CatAssignments.OrderDocument, UNDEFINED) AS OrderDocument,
			|	ISNULL(CatAssignments.Partner, VALUE(Catalog.Partners.EmptyRef)) AS Partner,
			|	ISNULL(CatAssignments.Contract, VALUE(Catalog.CounterpartyContracts.EmptyRef)) AS Contract,
			|	ISNULL(CatAssignments.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)) AS LineOfBusiness
			|FROM
			|	TTDataSource AS DataSource
			|	LEFT JOIN Catalog.Assignments AS CatAssignments
			|		ON DataSource.Purpose = CatAssignments.Ref";
		EndIf;
		
		QueryDetails.QueriesTexts.Add(QueryText, "ServiceDetailsForPurpose");
		QueryDetails.PrivilegedMode = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// Sets the "Separate" flag for selected rows in the table part of the document form.
// Parameters:
//  Form - ClientApplicationForm - shape.
//  Set - Boolean - True if you need to set a flag, False if you need to reset the flag.
//  IsOutdated - Boolean - For compatibility with the direction of the activity of the server.Set the Label separately
Procedure SetUncheckSeparately(Form, Set, IsOutdated = False) Export
	
	If IsOutdated Then
		DocumentProcessingProcedure = Form.FormMetadata;
	Else
		DocumentProcessingProcedure = Form.AssignmentsCachedValues.DocumentProcessingProcedure;
	EndIf;
	
	Collection = 	CollectionShipSeparately(Form, IsOutdated);
	FormTable = Form.Items[DocumentProcessingProcedure.NamesOfTablePartsToFillInAssignment];
	For Each Id In FormTable.SelectedRows Do
		CollectionRow = Collection.FindByID(Id);
		If CollectionRow.ItemsType = Enums.ItemsTypes.OwnGoods
				Or CollectionRow.ItemsType = Enums.ItemsTypes.Work_5 Then
					UpdateFlagAndAssignmentInLine(Form, CollectionRow, Set, IsOutdated);
		EndIf;
	EndDo; 
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Procedure CheckDataInCollectionRows(Array, AssignmentForMatching, DefaultAssignment)
	
	If Not ValueIsFilled(Array) Then
		Return;
	EndIf;
	
	Table = New ValueTable();
	Table.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
	Table.Columns.Add("IndexOf", New TypeDescription("Number"));
	For IndexOf = 0 To Array.UBound() Do
		
		NewRow = Table.Add();
		NewRow.IndexOf = IndexOf;
		NewRow.Purpose = Array[IndexOf].Purpose;
		
	EndDo;
	
	Query = New Query();
	Query.Text =
		"SELECT
		|	Table.IndexOf AS IndexOf,
		|	Table.Purpose AS Purpose
		|INTO TTTable
		|FROM
		|	&Table AS Table
		|;
		|
		|////////////////////////////////////
		|SELECT
		|	Table.IndexOf AS IndexOf,
		|	&DefaultAssignment AS Purpose
		|FROM
		|	TTTable AS Table
		|
		|		LEFT JOIN Catalog.Assignments AS CatAssignments
		|		ON CatAssignments.Ref = Table.Purpose
		|
		|		LEFT JOIN Catalog.Assignments AS AssignmentForMatching
		|		ON AssignmentForMatching.Ref = &AssignmentForMatching
		|
		|WHERE
		|	Table.Purpose <> &DefaultAssignment
		|		AND CASE
		|			WHEN CatAssignments.Ref IS NULL
		|				THEN &DefaultAssignment <> VALUE(Catalog.Assignments.EmptyRef)
		|			WHEN AssignmentForMatching.Ref IS NULL
		|				THEN FALSE
		|			WHEN AssignmentForMatching.LineOfBusiness <> VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|					AND AssignmentForMatching.OrderDocument = UNDEFINED
		|					AND AssignmentForMatching.Partner = VALUE(Catalog.Partners.EmptyRef)
		|					AND AssignmentForMatching.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
		|				THEN
		|					CatAssignments.LineOfBusiness <> AssignmentForMatching.LineOfBusiness
		|			WHEN AssignmentForMatching.LineOfBusiness <> VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|					AND AssignmentForMatching.OrderDocument = UNDEFINED
		|				THEN CatAssignments.LineOfBusiness <> AssignmentForMatching.LineOfBusiness
		|					OR CatAssignments.Partner <> AssignmentForMatching.Partner
		|					OR CatAssignments.Contract <> AssignmentForMatching.Contract
		|			WHEN AssignmentForMatching.LineOfBusiness <> VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|					AND AssignmentForMatching.OrderDocument <> UNDEFINED
		|				THEN CatAssignments.LineOfBusiness <> AssignmentForMatching.LineOfBusiness
		|					OR CatAssignments.Partner <> AssignmentForMatching.Partner
		|					OR CatAssignments.Contract <> AssignmentForMatching.Contract
		|					OR CatAssignments.OrderDocument <> AssignmentForMatching.OrderDocument
		|			WHEN AssignmentForMatching.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|					AND AssignmentForMatching.OrderDocument = UNDEFINED
		|				THEN CatAssignments.Partner <> AssignmentForMatching.Partner
		|					OR CatAssignments.Contract <> AssignmentForMatching.Contract
		|			WHEN AssignmentForMatching.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|					AND AssignmentForMatching.OrderDocument <> UNDEFINED
		|				THEN CatAssignments.Partner <> VALUE(Catalog.Partners.EmptyRef)
		|					OR CatAssignments.Contract <> VALUE(Catalog.CounterpartyContracts.EmptyRef)
		|					OR CatAssignments.OrderDocument <> AssignmentForMatching.OrderDocument
		|			ELSE FALSE
		|		END";
		
	Query.SetParameter("AssignmentForMatching", AssignmentForMatching);
	Query.SetParameter("DefaultAssignment", DefaultAssignment);
	Query.SetParameter("Table", Table);
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		Array[Selection.IndexOf].Purpose = Selection.Purpose;
	EndDo;
	
EndProcedure

Function FindRowsInCollections(Form, TabNames, FilterConditions)
	
	TabSections = StrSplit(TabNames, ",");
	FoundRows = New Array();
	For Each TabSectionName In TabSections Do
		
		ConditionsOfSelectionOfFirstPart = FilterConditions.Get(TabSectionName);
		For Each TSRow In Form.Object[TabSectionName] Do
			
			If ConditionsOfSelectionOfFirstPart = Undefined Or SatisfiesTheFilter(TSRow, ConditionsOfSelectionOfFirstPart) Then
				
				FoundRows.Add(TSRow);
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	Return FoundRows;
	
EndFunction

Function FindRowsInCollectionsOfForm(Form, NamesOfTabValues, FilterConditions)
	
	TabVal = StrSplit(NamesOfTabValues, ",");
	FoundRows = New Array();
	For Each NameTabIcon In TabVal Do
		
		TabSelectionConditions = FilterConditions.Get(NameTabIcon);
		For Each SpecificationRow In Form[NameTabIcon] Do
			
			If TabSelectionConditions = Undefined Or SatisfiesTheFilter(SpecificationRow, TabSelectionConditions) Then
				
				FoundRows.Add(SpecificationRow);
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	Return FoundRows;
	
EndFunction

Function LineOfBusinessCachedValues()
	
	CachedValues = New Structure();
	CachedValues.Insert("UseLinesOfBusiness");
	CachedValues.Insert("UseOrderSupplyWithAssignment");
	CachedValues.Insert("DefaultAssignment");
	Return CachedValues;
	
EndFunction

Function AssignmentsCachedValues()
	
	CachedValues = New Structure();
	CachedValues.Insert("UseLinesOfBusiness");
	CachedValues.Insert("UseOrderSupplyWithAssignment");
	CachedValues.Insert("DefaultAssignment");
	CachedValues.Insert("DocumentProcessingProcedure");
	Return CachedValues;
	
EndFunction

Function SatisfiesTheFilter(ValueToCheck, FilterConditions)
	
	Result = True;
	For Each Condition In FilterConditions Do
		
		Result = True;
		For Each Field In Condition Do
			
			If ValueToCheck[Field.Key] <> Field.Value Then
				
				Result = False;
				Break;
				
			EndIf;
			
		EndDo;
		
		If Result Then
			Return Result;
		EndIf;
		
	EndDo;
	Return Result;
	
EndFunction

Procedure UpdateFlagAndAssignmentInLine(Form, CollectionRow, Set, IsOutdated)
	
	If IsOutdated Then
		Utilities = Form.FormMetadata.Utilities;
	Else
		Utilities = Form.AssignmentsCachedValues.DocumentProcessingProcedure.Utilities;
	EndIf;
	
	CollectionRow[Utilities.PropsNameIsSeparate] = Set;
	CollectionRow.Purpose = ?(Set,
		Form.LineOfBusinessCachedValues.DefaultAssignment,
		Catalogs.Assignments.EmptyRef());
	
EndProcedure

Procedure UpdateFlagFromAssignmentOfTablePart(Form, IsOutdated)
	If IsOutdated Then
		Utilities = Form.FormMetadata.Utilities;
	Else
		Utilities = Form.AssignmentsCachedValues.DocumentProcessingProcedure.Utilities;
	EndIf;
	Collection = CollectionShipSeparately(Form, IsOutdated);
	For Each CollectionRow In Collection Do
		CollectionRow[Utilities.PropsNameIsSeparate] = ValueIsFilled(CollectionRow.Purpose);
	EndDo;
EndProcedure

Function CollectionShipSeparately(Form, IsOutdated)
	If IsOutdated Then
		DocumentProcessingProcedure = Form.FormMetadata;
	Else
		DocumentProcessingProcedure = Form.AssignmentsCachedValues.DocumentProcessingProcedure;
	EndIf;
	TagName = DocumentProcessingProcedure.NameOfFormElementIsSeparate;
	FormItem = Form.Items[TagName];
	FieldArray = StrSplit(FormItem.DataPath, ".");
	Collection = Form[FieldArray[0]][FieldArray[1]];
	Return Collection; 
EndFunction
 
#EndRegion
