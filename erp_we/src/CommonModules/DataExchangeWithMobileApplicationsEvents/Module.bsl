#Region Public

// Procedure-handler for the event" before Writing " directories to register changes to objects in the nodes of the exchange plan.
//
// Parameters:
//  Source       - CatalogObject - event source.
//  Cancel          - Boolean - flag for refusing to execute the handler.
// 
Procedure RegisterCatalogChangesForSharingWithSalesRepresentativeMobileApp(Source, Cancel) Export
	
	If Not GetFunctionalOption("WorkIsExecutedViaSalesRepresentatives") Then
		Return;
	EndIf;
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	If Source.IsNew() Then
		Source.AdditionalProperties.Insert("ItIsRequiredToCheckRegistration", True);
	Else	
		Source.AdditionalProperties.Insert("RemovalOfRegistrationOfChangesIsPossible", True);
		SelectiveObjectRegistration(Source, Cancel, "SalesRepresentativeMobileApplication");
	EndIf;

EndProcedure

// Procedure-handler of the event" before Writing " documents for registering changes to objects in the nodes of the exchange plan.
//
// Parameters:
//  Source       - DocumentObject - event source.
//  Cancel          - Boolean - flag for refusing to execute the handler.
//  WriteMode - DocumentWriteMode - Recording mode.
//  PostingMode - DocumentPostingMode -Mode of holding.
// 
Procedure RegisterDocumentChangesForSharingWithMobileAppSalesRepresentative(Source, Cancel, WriteMode, PostingMode) Export
	
	If Not GetFunctionalOption("WorkIsExecutedViaSalesRepresentatives") Then
		Return;
	EndIf;
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	Source.AdditionalProperties.Insert("RemovalOfRegistrationOfChangesIsPossible", Not Source.IsNew());
	SelectiveObjectRegistration(Source, Cancel, "SalesRepresentativeMobileApplication");

EndProcedure

// A procedure that handles the" pre-Write " event for registers to register changes in exchange plan nodes.
//
// Parameters:
//  Source       - InformationRegisterRecordSet - event source.
//  Cancel          - Boolean - flag for refusing to execute the handler.
//  Replacing      - Boolean - indicates whether an existing record set is being replaced.
// 
Procedure RegisterInformationRegisterChangesForExchangeWithMobileAppSalesRepresentative(Source, Cancel, Replacing) Export
	
	If Not GetFunctionalOption("WorkIsExecutedViaSalesRepresentatives") Then
		Return;
	EndIf;
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	Source.AdditionalProperties.Insert("RemovalOfRegistrationOfChangesIsPossible", True);
	SelectiveObjectRegistration(Source, Cancel, "SalesRepresentativeMobileApplication");

EndProcedure

// Procedure-handler for the event" Recording " directories for registering changes to objects in the nodes of the exchange plan.
//
// Parameters:
//  Source       - CatalogObject - event source.
//  Cancel          - Boolean - flag for refusing to execute the handler.
// 
Procedure RegisterCatalogChangesWhenRecordingForSharingWithMobileAppSalesRepresentative(Source, Cancel) Export
	
	If Not GetFunctionalOption("WorkIsExecutedViaSalesRepresentatives") Then
		Return;
	EndIf;
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	If Cancel Then
		Return;
	EndIf;
	
	ItIsRequiredToCheckRegistration = False;
	If Source.AdditionalProperties.Property("ItIsRequiredToCheckRegistration", ItIsRequiredToCheckRegistration) Then
		If ItIsRequiredToCheckRegistration Then			
			SelectiveObjectRegistration(Source, Cancel, "SalesRepresentativeMobileApplication");
		EndIf;
	EndIf;

EndProcedure

// Generates and returns an array containing the names of fields that can be overlaid with selections.
//
// Parameters:
//  ClassName - String - name of the class that the object belongs to (reference Books, Documents, etc.).
//  ObjectName - String - name of the metadata object for which an array of fields is generated.
//
// Returns:
//  Array - an array containing field names.
//
Function SelectionFieldsForObject(ClassName, ObjectName) Export

	FieldArray = New Array();

	If ClassName = "Catalogs" Then

		If ObjectName = "Partners" Then
			FieldArray.Add("ServedBySalesRepresentatives");
			FieldArray.Add("Client");
		ElsIf ObjectName = "TermsOfSale" Then
			FieldArray.Add("Status");
			FieldArray.Add("Standard_");
		ElsIf ObjectName = "CounterpartyContracts" Then
			FieldArray.Add("Status");
			FieldArray.Add("BusinessOperation");
		ElsIf ObjectName = "Counterparties" Then
			FieldArray.Add("Partner");
		ElsIf ObjectName = "ContactPersonsForPartners" Then
			FieldArray.Add("Owner");
		ElsIf ObjectName = "TypesOfPrices" Then
			FieldArray.Add("UseWhileSellingToCustomers");
		ElsIf ObjectName = "ProductPackages" Then
			FieldArray.Add("Owner");
		ElsIf ObjectName = "ItemsCharacteristics" Then
			FieldArray.Add("Owner");
		EndIf;

	ElsIf ClassName = "Documents" Then

		If ObjectName = "JobForSalesRepresentative" Then
			FieldArray.Add("Partner");
			FieldArray.Add("Status");
			FieldArray.Add("SalesRepresentative");
		EndIf;

	ElsIf ClassName = "InformationRegisters" Then

		If ObjectName = "ItemsPrices" Then
			FieldArray.Add("PriceKind");
			FieldArray.Add("Products");
		ElsIf ObjectName = "GoodsAvailabilityForExternalUsers" Then
			FieldArray.Add("Products");
			FieldArray.Add("Warehouse");
		EndIf;

	EndIf;

	Return FieldArray;

EndFunction

// Returns a structure containing the name of the table to select and an array of fields to select.
//
// Parameters:
//  MetadataObject - MetadataObject - the metadata object that you want to get the description structure for.
//  Changes - Boolean - indicates that the table for the selection is a table of changes.
//
// Returns:
//  Structure - a structure containing a description of the metadata object, with fields:
//  	* ClassName - String - name of the metadata object class.
//      * ObjectName - String - name of the metadata object
//      * TableName - String - name of the object table.
//
Function ObjectDetails(MetadataObject, Changes) Export

	If Metadata.Constants.Contains(MetadataObject) Then
		ClassName = "Constants";
		TableName = "Constants";
	ElsIf Metadata.Catalogs.Contains(MetadataObject) Then
		ClassName = "Catalogs";
		TableName = "Catalog." + MetadataObject.Name;
	ElsIf Metadata.Documents.Contains(MetadataObject) Then
		ClassName = "Documents";
		TableName = "Document." + MetadataObject.Name;
	ElsIf Metadata.InformationRegisters.Contains(MetadataObject) Then
		ClassName = "InformationRegisters";
		TableName = "InformationRegister." + MetadataObject.Name;
	EndIf;	
	
	// If only a selection of changes is required, then it is necessary to select from the change tables.
	If Changes Then
		TableName = TableName + ".Changes";
	EndIf;
	
	DetailsStructure1 = New Structure();
	DetailsStructure1.Insert("ClassName", ClassName);
	DetailsStructure1.Insert("ObjectName", MetadataObject.Name);
	DetailsStructure1.Insert("TableName", TableName);
	
	Return DetailsStructure1;

EndFunction

#EndRegion

#Region Private

// Performs selective registration of changes, taking into account the exchange rules.
//
// Parameters:
//  Object - CatalogObject, DocumentObject - the object whose changes are being registered.
//  Cancel - Boolean - refusal to write the object.
//  ExchangePlanName - String - the name of the exchange plan used.
//
Procedure SelectiveObjectRegistration(Object, Cancel, ExchangePlanName)
	
	// If a failure was made when recording the object, then no further analysis is required -
	// there will be no changes.
	If Cancel Then
		Return;
	EndIf;
	
	ObjectMetadata = Object.Metadata();
	
	// If the object is not part of the exchange plan, then there is nothing to register.
	If Not Metadata.ExchangePlans[ExchangePlanName].Content.Contains(ObjectMetadata) Then
		Return;
	EndIf;
	
	ObjectDescriptionStructure_ = ObjectDetails(ObjectMetadata, False);
	
	NodesSelection = ExchangePlans[ExchangePlanName].Select();

	While NodesSelection.Next() Do

		If Object.DataExchange.Load Then
			If Object.DataExchange.Sender = NodesSelection.Ref Then
				// For the node where the changes came from, they do not need to be registered.
				Continue;
			EndIf;
		EndIf;
		
		If NodesSelection.Ref <> ExchangePlans[ExchangePlanName].ThisNode() Then
			
			NotRegisterChanges = False;
			If Object.AdditionalProperties.Property("NotRegisterChanges", NotRegisterChanges) Then
				If NotRegisterChanges Then
					Continue;
				EndIf;
			EndIf;
			
			If ObjectMustBeRegisteredInNode(Object, ObjectDescriptionStructure_, NodesSelection.Ref) Then
				Object.DataExchange.Recipients.Add(NodesSelection.Ref);
			Else
				RemovalOfRegistrationOfChangesIsPossible = False;
				If Object.AdditionalProperties.Property("RemovalOfRegistrationOfChangesIsPossible", RemovalOfRegistrationOfChangesIsPossible) Then
					If RemovalOfRegistrationOfChangesIsPossible Then
						ExchangePlans.DeleteChangeRecords(NodesSelection.Ref, Object);
					EndIf;
				EndIf;
			EndIf;
		EndIf;

	EndDo;

EndProcedure

// Checks whether the object is subject to registration in the specified exchange node.
//
// Parameters:
//  Object - CatalogObject, DocumentObject - the object whose changes are being registered.
//  ObjectDescriptionStructure_ - Structure - structure containing the object description.
//  ExchangeNode - ExchangePlanRef - The exchange plan Sub-Asset for which the need for registration is checked.
//
// Returnable value:
//  Boolean - a sign of the need to register an object.
//
Function ObjectMustBeRegisteredInNode(Object, ObjectDescriptionStructure_, ExchangeNode)
	
	ClassName = ObjectDescriptionStructure_.ClassName;
	ObjectName = ObjectDescriptionStructure_.ObjectName;
	
	If ClassName = "Constants" Then
		// No selection conditions are set for constants, so we always register changes.
		Return True;
	Else
		
		FieldArray = SelectionFieldsForObject(ClassName, ObjectName);
		
		If ClassName = "Catalogs" Or ClassName = "Documents" Then
			
			If FieldArray.Find("Ref") = Undefined Then
				FieldArray.Add("Ref");
			EndIf;
			
			ObjectDataTable = New ValueTable();
			ObjectAttributeStructure = New Structure();
			
			For Each Field In FieldArray Do
				ObjectDataTable.Columns.Add(Field);
			EndDo;
			
			TableRow = ObjectDataTable.Add();
			For Each Field In FieldArray Do
				TableRow[Field] = Object[Field];
				ObjectAttributeStructure.Insert(Field, Object[Field]);
			EndDo;
		
			Return MobileApps.RegistrationOfObjectChangesIsRequired(ObjectAttributeStructure, ObjectDescriptionStructure_, FieldArray, ObjectDataTable, ExchangeNode);
			
		ElsIf ClassName = "InformationRegisters" Then
			
			Return True;
			
		EndIf;
		
	EndIf;	
	
	Return False;
	
EndFunction

#EndRegion
