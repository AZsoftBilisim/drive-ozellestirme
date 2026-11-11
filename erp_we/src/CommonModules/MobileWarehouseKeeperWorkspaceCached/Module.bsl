
#Region Public

// See StandardSubsystemsCached.CollectionNamesByBaseTypeNames
//
// Returns:
//  FixedMap of KeyAndValue:
//   * Key - String - The name of the base type in uppercase
//   * Value - String - Name of the collection of the base type
//
Function CollectionNamesByBaseTypeNames() Export
	
	CollectionsNames = New Map;
	CollectionsNames.Insert(Upper("Subsystem"), "Subsystems");
	CollectionsNames.Insert(Upper("CommonModule"), "CommonModules");
	CollectionsNames.Insert(Upper("SessionParameter"), "SessionParameters");
	CollectionsNames.Insert(Upper("Role"), "Roles");
	CollectionsNames.Insert(Upper("CommonAttribute"), "CommonAttributes");
	CollectionsNames.Insert(Upper("ExchangePlan"), "ExchangePlans");
	CollectionsNames.Insert(Upper("FilterCriterion"), "FilterCriteria");
	CollectionsNames.Insert(Upper("EventSubscription"), "EventSubscriptions");
	CollectionsNames.Insert(Upper("ScheduledJob"), "ScheduledJobs");
	CollectionsNames.Insert(Upper("FunctionalOption"), "FunctionalOptions");
	CollectionsNames.Insert(Upper("FunctionalOptionsParameter"), "FunctionalOptionsParameters");
	CollectionsNames.Insert(Upper("DefinedType"), "DefinedTypes");
	CollectionsNames.Insert(Upper("SettingsStorage"), "SettingsStorages");
	CollectionsNames.Insert(Upper("CommonForm"), "CommonForms");
	CollectionsNames.Insert(Upper("CommonCommand"), "CommonCommands");
	CollectionsNames.Insert(Upper("CommandGroup"), "CommandGroups");
	CollectionsNames.Insert(Upper("CommonTemplate"), "CommonTemplates");
	CollectionsNames.Insert(Upper("CommonPicture"), "CommonPictures");
	CollectionsNames.Insert(Upper("XDTOPackage"), "XDTOPackages");
	CollectionsNames.Insert(Upper("WebService"), "WebServices");
	CollectionsNames.Insert(Upper("HTTPService"), "HTTPServices");
	CollectionsNames.Insert(Upper("WSReference"), "WSReferences");
	CollectionsNames.Insert(Upper("IntegrationService"), "IntegrationServices");
	CollectionsNames.Insert(Upper("StyleItem"), "StyleItems");
	CollectionsNames.Insert(Upper("Style"), "Styles");
	CollectionsNames.Insert(Upper("Language"), "Languages");
	CollectionsNames.Insert(Upper("Constant"), "Constants");
	CollectionsNames.Insert(Upper("Catalog"), "Catalogs");
	CollectionsNames.Insert(Upper("Document"), "Documents");
	CollectionsNames.Insert(Upper("Sequence"), "Sequences");
	CollectionsNames.Insert(Upper("DocumentJournal"), "DocumentJournals");
	CollectionsNames.Insert(Upper("Enum"), "Enums");
	CollectionsNames.Insert(Upper("Report"), "Reports");
	CollectionsNames.Insert(Upper("DataProcessor"), "DataProcessors");
	CollectionsNames.Insert(Upper("ChartOfCharacteristicTypes"), "ChartsOfCharacteristicTypes");
	CollectionsNames.Insert(Upper("ChartOfAccounts"), "ChartsOfAccounts");
	CollectionsNames.Insert(Upper("ChartOfCalculationTypes"), "ChartsOfCalculationTypes");
	CollectionsNames.Insert(Upper("InformationRegister"), "InformationRegisters");
	CollectionsNames.Insert(Upper("AccumulationRegister"), "AccumulationRegisters");
	CollectionsNames.Insert(Upper("AccountingRegister"), "AccountingRegisters");
	CollectionsNames.Insert(Upper("CalculationRegister"), "CalculationRegisters");
	CollectionsNames.Insert(Upper("BusinessProcess"), "BusinessProcesses");
	CollectionsNames.Insert(Upper("Task"), "Tasks");
	CollectionsNames.Insert(Upper("ExternalDataSources"), "ExternalDataSource");
	
	Return New FixedMap(CollectionsNames);
	
EndFunction

// See StandardSubsystemsCached.SubsystemsNames
// 
Function SubsystemsNames() Export
	
	DisabledSubsystems = New Map;
	
	Names = New Map;
	InsertSubordinateSubsystemNames(Names, Metadata, DisabledSubsystems);
	
	Return New FixedMap(Names);
	
EndFunction
	
// See StandardSubsystemsCached.RefsByPredefinedItemsNames
// 
Function RefsByPredefinedItemsNames(FullMetadataObjectName) Export
	
	PredefinedValues = New Map;
	
	ObjectMetadata = MobileWarehouseKeeperWorkspace.MetadataObjectByFullName(FullMetadataObjectName);
	
	// If the metadata does not exist.
	If ObjectMetadata = Undefined Then 
		Return Undefined;
	EndIf;
	
	// If the metadata type is not suitable.
	If Not Metadata.Catalogs.Contains(ObjectMetadata)
		And Not Metadata.ChartsOfCharacteristicTypes.Contains(ObjectMetadata)
		And Not Metadata.ChartsOfAccounts.Contains(ObjectMetadata)
		And Not Metadata.ChartsOfCalculationTypes.Contains(ObjectMetadata) Then 
		
		Return Undefined;
	EndIf;
	
	PredefinedItemsNames = ObjectMetadata.GetPredefinedNames();
	
	// If there are no predefined metadata.
	If PredefinedItemsNames.Count() = 0 Then 
		Return New FixedMap(PredefinedValues);
	EndIf;
	
	// Filling in by default is a sign of absence in the IB (those present will be redefined).
	For Each PredefinedItemName In PredefinedItemsNames Do 
		PredefinedValues.Insert(PredefinedItemName, Null);
	EndDo;
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	CurrentTable.Ref AS Ref,
		|	CurrentTable.PredefinedDataName AS PredefinedDataName
		|FROM
		|	&CurrentTable AS CurrentTable
		|WHERE
		|	CurrentTable.Predefined";
	
	Query.Text = StrReplace(Query.Text, "&CurrentTable", FullMetadataObjectName);
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	Selection = Query.Execute().Select();
	
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
	// Filling in those present in the IB.
	While Selection.Next() Do
		PredefinedValues.Insert(Selection.PredefinedDataName, Selection.Ref);
	EndDo;
	
	Return New FixedMap(PredefinedValues);
	
EndFunction
	
// See StandardSubsystemsCached.SeparatedDataUsageAvailable
// Returns whether split data (which is part of separators) can be accessed.
// This attribute is specific to the session, but may change during the session if partitioning was enabled
// in the session itself, so you should check it immediately before accessing the split data.
// 
// Returns True if the configuration can't work in data separation mode
// (it doesn't contain any General details intended for data separation).
//
// Returns:
//   Boolean - True, if separation is not supported, either separation is disabled,
//                    or separation is enabled and separators are set.
//   Boolean is false if separation is enabled and separators are not set.
// 
Function SeparatedDataUsageAvailable() Export
	
	If MobileWarehouseKeeperWorkspace.SubsystemExists("CloudTechnology.Core") Then
		ModuleSaaSOperations = MobileWarehouseKeeperWorkspace.CommonModule("SaaSOperations");
		Return ModuleSaaSOperations.SeparatedDataUsageAvailable();
	Else
		Return True;
	EndIf;
	
EndFunction
		
// See StandardSubsystemsCached.DataSeparationEnabled
// Returns a flag for working in the data division mode by area
// (technically, this is a sign of conditional division).
// 
// Returns False if the configuration can't work in data separation mode
// (it doesn't contain General details intended for data separation).
//
// Returns:
//  Boolean - True if separation is enabled.
//  Boolean - False if partitioning is disabled or not supported.
// 
Function DataSeparationEnabled() Export
	
	If MobileWarehouseKeeperWorkspace.SubsystemExists("CloudTechnology.Core") Then
		ModuleSaaSOperations = MobileWarehouseKeeperWorkspace.CommonModule("SaaSOperations");
		Return ModuleSaaSOperations.DataSeparationEnabled();
	Else
		Return False;
	EndIf;
	
EndFunction

#EndRegion

#Region Internal

// Finds and returns the structure of document Attributes
// and Attributes of table parts related to other documents by document type.
//
//	Parameters:
//		DocumentTypePresentation - String - string Presentation of the type.
//		
//	Returns:
//		Structure - a structure with a key - the names of the tabular parts of the document and a string with the names of the associated TS Attributes:
//			*RelatedHeaderAttributes - Array of MetadataObjectAttribute - array with associated header Attributes.
//
Function LinkedAttributes(DocumentTypePresentation) Export
	
	LinkedAttributes = New Structure;
	
	RelatedHeaderAttributes = New Array;
	
	ObjectMetadata = Metadata.FindByType(Type(DocumentTypePresentation));
	
	For Each Attribute In ObjectMetadata.Attributes Do
		
		If Not Metadata.FilterCriteria.RelatedDocuments.Content.Contains(Attribute) Then
			Continue;
		EndIf; 
				
		For Each Current_Type In Attribute.Type.Types() Do
			AttributeMetadata = MetadataOfPropsType(Current_Type);
			If AttributeMetadata = Undefined Then
				Continue;
			EndIf;
		EndDo;
		
		RelatedHeaderAttributes.Add(Attribute);
		
	EndDo;
	
	LinkedAttributes.Insert("RelatedHeaderAttributes", RelatedHeaderAttributes);
	
	For Each TabularSection In ObjectMetadata.TabularSections Do
		
		AttributesNames = "";
		For Each Attribute In TabularSection.Attributes Do

			If Not Metadata.FilterCriteria.RelatedDocuments.Content.Contains(Attribute) Then
				Continue;
			EndIf;
				
			For Each Current_Type In Attribute.Type.Types() Do
				AttributeMetadata = MetadataOfPropsType(Current_Type);
				If AttributeMetadata = Undefined Then
					Continue;
				EndIf;
	
				AttributesNames = AttributesNames + ?(AttributesNames = "", "", ", ") + Attribute.Name;
				Break;
			EndDo
		EndDo;
		
		LinkedAttributes.Insert(TabularSection.Name, AttributesNames);
		
	EndDo;
	
	Return LinkedAttributes;
		
EndFunction

// Defines related documents by document type and Query Text for selecting subordinate documents
//
//	Parameters:
//		DocumentTypePresentation - String - string Presentation of the type.
//		
//	Returns:
//		String - The Query Text of subordinate documents.
//
Function QueryTextOfRelatedDocuments(DocumentTypePresentation) Export
	
	QueryTemplate = "SELECT ALLOWED
	|	TableAlias.Ref AS Ref
	|FROM
	|	TableName AS TableAlias
	|WHERE
	|	TableAlias.AttributeName = &DocumentReference";

	MergeQueryTemplate = "SELECT
	|	TableAlias.Ref AS Ref
	|FROM
	|	TableName AS TableAlias
	|WHERE
	|	TableAlias.AttributeName = &DocumentReference";

	QueryParts = New Array;
	TextOfRequestPart = "";

	For Each CompositionItem In Metadata.FilterCriteria.RelatedDocuments.Content Do

		If Not CompositionItem.Type.ContainsType(Type(DocumentTypePresentation)) Then
			Continue;
		EndIf;

		DataPath = CompositionItem.FullName();
		
		If StrFind(DataPath, "TabularSection") Then
			MetadataObject = CompositionItem.Parent().Parent();
		Else
			MetadataObject = CompositionItem.Parent();
		EndIf;
		
		If Not Common.MetadataObjectAvailableByFunctionalOptions(MetadataObject) 
			Or Not AccessRight("Read", MetadataObject) 
			Or Not Common.IsDocument(MetadataObject) Then
			Continue;
		EndIf;

		Point = StrFind(DataPath, ".", SearchDirection.FromEnd);
		AttributeName = Mid(DataPath, Point + 1);

		TableName = CompositionItem.Parent().FullName();
		TableName = StrReplace(TableName, "TabularSection.", "");

		Point = StrFind(TableName, ".", SearchDirection.FromEnd);
		TableAlias = "Table_" + Mid(TableName, Point + 1);

		TextOfRequestPart = ?(TextOfRequestPart = "", QueryTemplate, MergeQueryTemplate);
		TextOfRequestPart = StrReplace(TextOfRequestPart, "TableName", TableName);
		TextOfRequestPart = StrReplace(TextOfRequestPart, "TableAlias", TableAlias);
		TextOfRequestPart = StrReplace(TextOfRequestPart, "AttributeName", AttributeName);

		QueryParts.Add(TextOfRequestPart);

	EndDo;

	If QueryParts.Count() > 0 Then
		Separator = Chars.LF + "UNION" + Chars.LF;
		QueryText = StrConcat(QueryParts, Separator);
	Else
		Return Undefined;
	EndIf;
	
	Return QueryText;
		
EndFunction

#EndRegion

#Region Private

// See StandardSubsystemsCached .Insert the names of subordinate subsystems
//
Procedure InsertSubordinateSubsystemNames(Names, ParentSubsystem, DisabledSubsystems, ParentSubsystemName = "")
	
	For Each CurrentSubsystem In ParentSubsystem.Subsystems Do
		
		If CurrentSubsystem.IncludeInCommandInterface Then
			Continue;
		EndIf;
		
		CurrentSubsystemName = ParentSubsystemName + CurrentSubsystem.Name;
		If DisabledSubsystems.Get(CurrentSubsystemName) = True Then
			Continue;
		Else
			Names.Insert(CurrentSubsystemName, True);
		EndIf;
		
		If CurrentSubsystem.Subsystems.Count() = 0 Then
			Continue;
		EndIf;
		
		InsertSubordinateSubsystemNames(Names, CurrentSubsystem, DisabledSubsystems, CurrentSubsystemName + ".");
	EndDo;
	
EndProcedure

Function MetadataOfPropsType(AttributeType)
		
	Result = Undefined; 
	
	AttributeMetadata = Metadata.FindByType(AttributeType);
		
	If AttributeMetadata = Undefined Then
		Return Result;
	EndIf;

	If Not Common.MetadataObjectAvailableByFunctionalOptions(AttributeMetadata) 
		Or Not AccessRight("Read", AttributeMetadata) 
		Or Not Common.IsDocument(AttributeMetadata) Then
		Return Result;
	EndIf;
	
	Result = AttributeMetadata;
	Return Result;

EndFunction

#EndRegion

