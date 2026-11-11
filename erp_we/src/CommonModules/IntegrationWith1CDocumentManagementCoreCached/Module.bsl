////////////////////////////////////////////////////////////////////////////////
// Subsystem "Integration with 1C:Document"
// Module 
////////////////////////////////////////////////////////////////////////////////

#Region Internal

// returns the Cur version of the 1C integration library:Document management.
//
// Returns:
//   See InfobaseUpdate.IBVersion
//
Function DMILVersion() Export
	
	Return InfobaseUpdate.IBVersion("DocumentManagementIntegrationLibrary");
	
EndFunction

// Gets the availability of the functionality of the version of the Document Management web service.
//
// Parameters:
//   ServiceVersion - String - a version of the Document Management web service containing the required functionality.
//   Optimistic - Boolean - a sign of the need to return True if the version of the service is still unknown.
//
// Returns:
//   See IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable
//
Function FunctionalityOfServiceVersionIsAvailable(ServiceVersion = "", Optimistic = False) Export
	
	Return IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable(
		ServiceVersion,
		Optimistic);
	
EndFunction

// Returns the ID of the current database, if any. If not, creates it and returns it.
//
// Returns:
//   String
//
Function DatabaseId_() Export
	
	ThisNode = ExchangePlans.IntegrationWith1CDocumentManagementSubsystemOverridable.ThisNode();
	NodeDescription = Common.ObjectAttributeValue(ThisNode, "Description");
	
	If Not StringFunctionsClientServer.IsUUID(NodeDescription) Then
		NodeDescription = String(New UUID);
		
		ThisNodeObject = ThisNode.GetObject();
		ThisNodeObject.DataExchange.Load = True;
		ThisNodeObject.Lock();
		ThisNodeObject.Description = NodeDescription;
		ThisNodeObject.Code = 0;
		ThisNodeObject.DataExchange.Load = True;
		ThisNodeObject.Write();
	EndIf;
	
	Return NodeDescription;
	
EndFunction

// Returns the value of the settings to set the filestransferencesdo.
//
// Parameters:
//   FileCatalogType - String - the full name of the metadata of the file owner in the IP.
//
// Returns:
//   Boolean
//   Undefined
//
Function SettingAskQuestionAboutTransferringFilesToDM(FileCatalogType) Export
	
	Return Common.CommonSettingsStorageLoad(
		FileCatalogType,
		"AskQuestionAboutTransferringFilesToDM");
	
EndFunction

// Returns True if the functional subsystem exists in the configuration.
//
// Parameters:
//   ShortNameOfSubsystem - String - The short name of the metadata object is subsystem, without hierarchy.
//
// Returns:
//   Boolean - True if the subsystem exists.
//
Function SubsystemExists(Val ShortNameOfSubsystem) Export
	
	ShortNameOfSubsystem = Lower(TrimAll(ShortNameOfSubsystem));
	
	For Each SubsystemName In SubsystemsNames() Do
		NameParts = StrSplit(SubsystemName.Key, ".", False);
		If ShortNameOfSubsystem = Lower(TrimAll(NameParts[NameParts.UBound()])) Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

// Returns the settings of the Workflow database.
//
// Returns:
//   See IntegrationWith1CDocumentManagementCore.GetSettings
//
Function GetSettings() Export
	
	Return IntegrationWith1CDocumentManagementCore.GetSettings();
	
EndFunction

// Creates a proxy for a Document Management web service. In case of an error during creation, an exception is raised.
//
// Parameters:
//   RaiseException1 - Boolean - True if an exception should be raised if it is impossible to get it.
//   AddressOfDocumentManagementWebService - String - the address of the web service BEFORE, or
//                                   - Undefined - indicates the need to use a previously saved address.
//
// Returns:
//   See IntegrationWith1CDocumentManagementCore.GetProxy
//
Function GetProxy(RaiseException1 = True, AddressOfDocumentManagementWebService = Undefined) Export
	
	AuthorizationSettings =
		IntegrationWith1CDocumentManagementCoreClientServer.AuthorizationSettingsIn1CDocumentManagement();
	AuthorizationSettings.Use_Cache = (AddressOfDocumentManagementWebService = Undefined);
	
	Return IntegrationWith1CDocumentManagementCore.GetProxy(
		RaiseException1,
		AuthorizationSettings,
		AddressOfDocumentManagementWebService);
	
EndFunction

// Generates a table of correspondence of types of XDTO and types of objects of the information base
//
// Returns:
//   ValueTable - table with columns:
//     * TypeNameXDTO - String - the name of the type XDTO.
//     * ObjectTypeIS - Type - the type of IP object.
//     * TypeNameIS - String - the full name of the IP object type.
//
Function MapTypes() Export
	
	Table = New ValueTable;
	Table.Columns.Add("TypeNameXDTO", New TypeDescription("String"));
	Table.Columns.Add("ObjectTypeIS", New TypeDescription("Type"));
	
	// Supported directories.
	If CurrencyKind() <> Undefined Then
		IntegrationWith1CDocumentManagementCore.AddTypeMatchingString(
			Table,
			"DMCurrency",
			CurrencyKind());
	EndIf;
	If BankClassifierType() <> Undefined Then
		IntegrationWith1CDocumentManagementCore.AddTypeMatchingString(
			Table,
			"DMBank",
			BankClassifierType());
	EndIf;
	If TypeOfCountryInWorld() <> Undefined And FunctionalityOfServiceVersionIsAvailable("3.0.16.33") Then
		IntegrationWith1CDocumentManagementCore.AddTypeMatchingString(
			Table,
			"DMCountry",
			TypeOfCountryInWorld());
	EndIf;
	If TypeUsers() <> Undefined Then
		Settings = IntegrationWith1CDocumentManagementCoreServerCall.UseIntegration();
		If Settings.UseIntegrationBefore2 Then
			IntegrationWith1CDocumentManagementCore.AddTypeMatchingString(
				Table,
				"DMUser",
				TypeUsers());
		ElsIf Settings.UseIntegrationBefore3 Then
			IntegrationWith1CDocumentManagementCore.AddTypeMatchingString(
				Table,
				"DMEmployee",
				TypeUsers());
		EndIf;
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreOverridable.CompleteTypeMatching(Table);
	
	Table.Columns.Add("TypeNameIS", New TypeDescription("String"));
	
	For Each String In Table Do
		String.TypeNameIS = IntegrationWith1CDocumentManagementCoreServerCall.NameOfMetadataObjectByType(
			String.ObjectTypeIS);
	EndDo;
	
	Return Table;
	
EndFunction

// Gets the current 1C user:Document management.
//
// Returns:
//   See IntegrationWith1CDocumentManagementCore.Current1CDocumentManagementUser
//
Function Current1CDocumentManagementUser() Export
	
	Return IntegrationWith1CDocumentManagementCore.Current1CDocumentManagementUser();
	
EndFunction

// Returns the type of the Currency Catalog.
//
// Parameters:
//   ObjectType - Boolean - you need to return the link type or object type.
//
// Returns:
//   Type
//   Undefined
//
Function CurrencyKind(ObjectType = False) Export
	
	If Common.SubsystemExists("StandardSubsystems.Currencies") Then
		If ObjectType Then
			TypeName = "CatalogObject.Currencies";
		Else
			TypeName = "CatalogRef.Currencies";
		EndIf;
		Return Type(TypeName);
	EndIf;
	
EndFunction

// Returns the Bank Classifier Catalog type.
//
// Parameters:
//   ObjectType - Boolean - you need to return the link type or object type.
//
// Returns:
//   Type
//   Undefined
//
Function BankClassifierType(ObjectType = False) Export
	
	If Common.SubsystemExists("StandardSubsystems.Banks") Then
		If ObjectType Then
			TypeName = "CatalogObject.BankClassifier";
		Else
			TypeName = "CatalogRef.BankClassifier";
		EndIf;
		Return Type(TypeName);
	EndIf;
	
EndFunction

// Returns the Users Catalog type.
//
// Parameters:
//   ObjectType - Boolean - you need to return the link type or object type.
//
// Returns:
//   Type
//   Undefined
//
Function TypeUsers(ObjectType = False) Export
	
	If Common.SubsystemExists("StandardSubsystems.Users") Then
		If ObjectType Then
			TypeName = "CatalogObject.Users";
		Else
			TypeName = "CatalogRef.Users";
		EndIf;
		Return Type(TypeName);
	EndIf;
	
EndFunction

// Returns the Country Catalog type of the world.
//
// Parameters:
//   ObjectType - Boolean - you need to return the link type or object type.
//
// Returns:
//   Type
//   Undefined
//
Function TypeOfCountryInWorld(ObjectType = False) Export
	
	If Common.SubsystemExists("StandardSubsystems.ContactInformation") Then
		If ObjectType Then
			TypeName = "CatalogObject.WorldCountries";
		Else
			TypeName = "CatalogRef.WorldCountries";
		EndIf;
		Return Type(TypeName);
	EndIf;
	
EndFunction

// Returns an array of IP object types that support seamless integration.
//
// Returns:
//   Array of Type
//
Function TypesOfObjectsThatSupportIntegration() Export
	
	Types = New Array;
	
	Types = Metadata.DefinedTypes.IntegrationWith1CWorkflowAllLinksOverridable.Type.Types();
	
	IntegrationWith1CDocumentManagementCoreOverridable.WhenDefiningObjectTypesThatSupportIntegration(
		Types);
	
	Return Types;
	
EndFunction

// Returns the Workflow node. In case of absence, the node will be created.
//
// Returns:
//   ExchangePlanRef.IntegrationWith1CDocumentManagementSubsystemOverridable
//
Function DocumentFlowNode() Export
	
	ThisNode = ExchangePlans.IntegrationWith1CDocumentManagementSubsystemOverridable.ThisNode();
	
	Query = New Query(
		"SELECT
		|	IntegrationWith1CDocumentManagementSubsystemOverridable.Ref AS Ref,
		|	IntegrationWith1CDocumentManagementSubsystemOverridable.Description AS Description
		|FROM
		|	ExchangePlan.IntegrationWith1CDocumentManagementSubsystemOverridable AS IntegrationWith1CDocumentManagementSubsystemOverridable
		|WHERE
		|	IntegrationWith1CDocumentManagementSubsystemOverridable.Ref <> &ThisNode");
	Query.SetParameter("ThisNode", ThisNode);
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		Node = Selection.Ref;
	Else
		Node1CDocumentManagement = ExchangePlans.IntegrationWith1CDocumentManagementSubsystemOverridable.CreateNode();
		Node1CDocumentManagement.Description = NStr("vi = '1C:Document Management';
													|ru = '1С:Документооборот';
													|en = '1C:Document Management'; fa = '1C:Document Management';
													|it = '1C:Document Management';
													|pl = '1C:Document Management';
													|tr = '1C:Document Management'");
		Node1CDocumentManagement.Code = 1;
		Node1CDocumentManagement.Write();
		Node = Node1CDocumentManagement.Ref;
	EndIf;
	
	Return Node;
	
EndFunction

// Returns the XDTO factory that the Workflow service works with.
//
// Parameters:
//   Integration1CDocumentManagementXMLSchema - String - XML schema of the document management service.
//
// Returns:
//   XDTOFactory
//
Function DMFactory(Integration1CDocumentManagementXMLSchema) Export
	
	ReadingXMLSchema = New XMLReader;
	ReadingXMLSchema.SetString(Integration1CDocumentManagementXMLSchema);
	
	DOMBuilder = New DOMBuilder;
	DOMDocument = DOMBuilder.Read(ReadingXMLSchema);
	ReadingXMLSchema.Close();
	
	XMLSchemaBuilder = New XMLSchemaBuilder;
	XMLSchema = XMLSchemaBuilder.CreateXMLSchema(DOMDocument);
	
	XMLSchemaSet = New XMLSchemaSet;
	XMLSchemaSet.Add(XMLSchema);
	
	Return New XDTOFactory(XMLSchemaSet);
	
EndFunction

// determines whether the Cur session is a background job.
//
// Returns:
//   Boolean
//
Function IsBackgroundJob() Export
	
	Return GetCurrentInfoBaseSession().GetBackgroundJob() <> Undefined;
	
EndFunction

#EndRegion

#Region Private

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

// Returns a match between the names of "functional" subsystems and the value True.
// The" functional "subsystem has the" Include in command interface " checkbox unchecked.
//
// Returns:
//  FixedMap of KeyAndValue:
//   * Key - String
//   * Value - Boolean
//
Function SubsystemsNames()
	
	DisabledSubsystems = New Map;
	CommonOverridable.OnDetermineDisabledSubsystems(DisabledSubsystems);
	
	Names = New Map;
	InsertSubordinateSubsystemNames(Names, Metadata, DisabledSubsystems);
	
	Return New FixedMap(Names);
	
EndFunction

#EndRegion