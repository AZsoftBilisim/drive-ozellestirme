#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the settings for the set of printing forms used for the object
//
// Parameters:
//  ObjectType - String - the full name of the object for which you want to configure printing forms
//  ReferencesArrray - Array of AnyRef - links for which you need to get Bank details
//  UseVariant - Number - a variable that contains a description of which dimensions the setting is applied to.
//
// Returns:
//  See PrepareSetOfPrintedForms
//
Function PrintFormsSet(ObjectType, Val ReferencesArrray = Undefined, UseVariant = 0) Export
	
	ObjectsTable = TableOfObjectsForCompletePrinting();
	CurrentObject = ObjectsTable.Find(ObjectType, "ObjectType");
	UseVariant = 0;
	
	If CurrentObject = Undefined Then
		Return Undefined;
	EndIf;
	
	ThereIsACompany = CurrentObject.ThereIsACompany And ReferencesArrray <> Undefined;
	ThereIsAPartner = CurrentObject.ThereIsAPartner And ReferencesArrray <> Undefined;
	
	QueryText = "
	|SELECT
	|	PrintObjects.Ref AS Ref"
		+?(ThereIsACompany,", PrintObjects.Organization AS Organization","")
		+ ?(ThereIsAPartner,", PrintObjects.Partner","") + "
	|INTO TT_References
	|FROM
	|	" + ObjectType + " AS PrintObjects
	|WHERE
	|	PrintObjects.Ref IN(&ReferencesArrray)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ObjectPrintSettings.Settings AS Settings,
	|	1 AS Order,
	|	ISNULL(TT_References.Ref, UNDEFINED) AS Ref,
	|	NULL AS Organization,
	|	NULL AS Partner
	|INTO TT_PrintSettings
	|FROM
	|	InformationRegister.ObjectPrintSettings AS ObjectPrintSettings
	|		LEFT JOIN TT_References AS TT_References
	|		ON (TRUE)
	|WHERE
	|	ObjectPrintSettings.ObjectType = &ObjectType
	|	AND ObjectPrintSettings.Organization = VALUE(Catalog.Companies.EmptyRef)
	|	AND ObjectPrintSettings.Partner = VALUE(Catalog.Partners.EmptyRef)";
	
	If ThereIsACompany Then
		QueryText = QueryText + "
		|
		|UNION ALL
		|
		|SELECT
		|	ObjectPrintSettings.Settings,
		|	2,
		|	ISNULL(TT_References.Ref, UNDEFINED),
		|	NULL,
		|	ObjectPrintSettings.Partner
		|FROM
		|	InformationRegister.ObjectPrintSettings AS ObjectPrintSettings
		|		INNER JOIN TT_References AS TT_References
		|		ON (TT_References.Organization = ObjectPrintSettings.Organization)
		|WHERE
		|	ObjectPrintSettings.ObjectType = &ObjectType
		|	AND ObjectPrintSettings.Partner = VALUE(Catalog.Partners.EmptyRef)";
	EndIf;
	
	If ThereIsAPartner Then
		QueryText = QueryText + "
		|
		|UNION ALL
		|
		|SELECT
		|	ObjectPrintSettings.Settings,
		|	2,
		|	ISNULL(TT_References.Ref, UNDEFINED),
		|	NULL,
		|	ObjectPrintSettings.Partner
		|FROM
		|	InformationRegister.ObjectPrintSettings AS ObjectPrintSettings
		|		INNER JOIN TT_References AS TT_References
		|		ON (TT_References.Partner = ObjectPrintSettings.Partner)
		|WHERE
		|	ObjectPrintSettings.ObjectType = &ObjectType
		|	AND ObjectPrintSettings.Organization = VALUE(Catalog.Companies.EmptyRef)";
	EndIf;
	
	If CurrentObject.ThereIsAPartner And CurrentObject.ThereIsACompany And ReferencesArrray <> Undefined Then
		QueryText = QueryText + "
		|
		|UNION ALL
		|
		|SELECT
		|	ObjectPrintSettings.Settings,
		|	3,
		|	ISNULL(TT_References.Ref, UNDEFINED),
		|	ObjectPrintSettings.Organization,
		|	ObjectPrintSettings.Partner
		|FROM
		|	InformationRegister.ObjectPrintSettings AS ObjectPrintSettings
		|		INNER JOIN TT_References AS TT_References
		|		ON (TT_References.Partner = ObjectPrintSettings.Partner)
		|			AND (TT_References.Organization = ObjectPrintSettings.Organization)
		|WHERE
		|	ObjectPrintSettings.ObjectType = &ObjectType";
	EndIf;
	
	QueryText = QueryText + "
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VT_PrintSettingsGrouped.Ref AS Ref,
	|	VT_PrintSettingsGrouped.Order AS Order,
	|	TT_PrintSettings.Settings
	|FROM
	|	(SELECT
	|		MAX(TT_PrintSettings.Order) AS Order,
	|		TT_PrintSettings.Ref AS Ref
	|	FROM
	|		TT_PrintSettings AS TT_PrintSettings
	|	
	|	GROUP BY
	|		TT_PrintSettings.Ref) AS VT_PrintSettingsGrouped
	|		INNER JOIN TT_PrintSettings AS TT_PrintSettings
	|		ON VT_PrintSettingsGrouped.Order = TT_PrintSettings.Order
	|			AND VT_PrintSettingsGrouped.Ref = TT_PrintSettings.Ref";
	
	Query = New Query(QueryText);
	Query.SetParameter("ObjectType", ObjectType);
	If TypeOf(ReferencesArrray) <> Type("Array") Then
		NewArrayOfLinks_ = New Array;
		NewArrayOfLinks_.Add(ReferencesArrray);
		ReferencesArrray = NewArrayOfLinks_;
	EndIf;
	Query.SetParameter("ReferencesArrray", ReferencesArrray);
	QueryResult = Query.Execute();
	
	ObjectManager = Common.ObjectManagerByFullName(ObjectType);
	DefaultKit = ObjectManager.PrintFormsSet();
	PrintFormsCollection = PrepareSetOfPrintedForms();
	
	// adding external printing plates to the kit
	ExternalPrintFormsPrefix = "ExternalPrintForm";
	CollectionOfExternalPrintingPlates = PrepareSetOfPrintedForms();
	
	CommandsTable = AdditionalReportsAndDataProcessors.AdditionalCommands(Enums.AdditionalReportsAndDataProcessorsKinds.PrintForm, ObjectType, True);
	
	For Each PrintCommand In CommandsTable Do
		AddPrintedFormToKit(DefaultKit, ExternalPrintFormsPrefix + PrintCommand.Id, PrintCommand.Presentation, 0);
	EndDo;
	
	Selection = QueryResult.Select();
	For Each ObjectRef In ReferencesArrray Do
		If Selection.FindNext(ObjectRef, "Ref") Then
			SelectingSettings = Selection.Settings; // ValueStorage
			PrintSettings = SelectingSettings.Get(); // See PrepareSetOfPrintedForms
			PrintSettings.Columns.Add("Ref");
		Else
			PrintSettings = DefaultKit;
		EndIf;
		PrintSettings.FillValues(ObjectRef, "Ref");
		CommonClientServer.SupplementTable(PrintSettings,PrintFormsCollection);
		Selection.Reset();
	EndDo;
	
	If Selection.Next() Then
		If Selection.Order = 1 Or Selection.Order = 2 Then
				UseVariant = Selection.Order;
			Else
				UseVariant = 3;
		EndIf;
	EndIf;
	
	Return PrintFormsCollection;
	
EndFunction

// Records the settings of the set of printing forms used for the document
//
// Parameters:
//		ObjectType - String - the full name of the object for which you want to configure printing forms
//		PrintFormsSet - See PrepareSetOfPrintedForms
//		RecordOrganization - Boolean - indicates whether the setting should be recorded in the organization's context
//		RecordingPartner - Boolean - indicates whether the setting should be recorded in the partner section
//		Ref - AnyRef - the link from which you want to extract the organization and/or partner.
//
Procedure RecordObjectPrintSettings(ObjectType, PrintFormsSet, RecordOrganization = False, RecordingPartner = False, Ref = Undefined) Export
	
	ObjectsTable = TableOfObjectsForCompletePrinting();
	CurrentObject = ObjectsTable.Find(ObjectType, "ObjectType");
	
	If CurrentObject = Undefined Then
		Return;
	EndIf;
	
	RecordingObjectPrintingSettings = InformationRegisters.ObjectPrintSettings.CreateRecordManager();
	RecordingObjectPrintingSettings.ObjectType = ObjectType;
	RecordingObjectPrintingSettings.Settings = New ValueStorage(PrintFormsSet);
	
	If RecordOrganization And RecordingPartner Then
		Attributes = Common.ObjectAttributesValues(Ref, "Partner,Organization");
		RecordingObjectPrintingSettings.Organization = Attributes.Organization;
		RecordingObjectPrintingSettings.Partner = Attributes.Partner;
	ElsIf RecordOrganization Then
		Attributes = Common.ObjectAttributesValues(Ref, "Organization");
		RecordingObjectPrintingSettings.Organization = Attributes.Organization;
	ElsIf RecordingPartner Then
		Attributes = Common.ObjectAttributesValues(Ref, "Partner");
		RecordingObjectPrintingSettings.Partner = Attributes.Partner;
	EndIf;
	
	SetPrivilegedMode(True);
	RecordingObjectPrintingSettings.Write();
	
EndProcedure

// Deletes the settings for the set of printing forms used for the item
//
// Parameters:
//		ObjectType - String - the full name of the object for which you want to configure printing forms
//		Organization - CatalogRef.Companies - the organization for which to delete settings
//		Partner - CatalogRef.Partners - the partner to delete the settings for.
//
Procedure DeleteObjectPrintingSettings(ObjectType, Organization, Partner) Export
	
	RecordingObjectPrintingSettings = InformationRegisters.ObjectPrintSettings.CreateRecordManager();
	RecordingObjectPrintingSettings.ObjectType  = ObjectType;
	RecordingObjectPrintingSettings.Organization = Organization;
	RecordingObjectPrintingSettings.Partner = Partner;
	RecordingObjectPrintingSettings.Delete();
	
EndProcedure

// Returns the settings for the set of printing forms used for the object
//
// Returns:
// ValueTable - Table of values with columns:
//  * Name           - String - internal name of the printed form.
//  * Presentation - String - custom representation of the printed form.
//  * Copies2   - Number - the number of copies to print.
//  * Print      - Boolean - indicates whether the printed form needs to be printed.
//  * Ref        - AnyRef
//
Function PrepareSetOfPrintedForms() Export
	
	PrintFormsSet = New ValueTable();
	PrintFormsSet.Columns.Add("Name");
	PrintFormsSet.Columns.Add("Presentation");
	PrintFormsSet.Columns.Add("Copies2");
	PrintFormsSet.Columns.Add("Print");
	PrintFormsSet.Columns.Add("Ref");
	
	Return PrintFormsSet;
	
EndFunction

// Adds a printed form to a table with a set of printed forms
// The "Print" flag is set to True if the number of printed forms is greater than zero.
//
// Parameters:
//  PrintFormsSet - See PrepareSetOfPrintedForms
//  Name - String - internal name of the print form
//  Presentation - String - presentation of the printed form
//  Copies2 - Number - number of copies to print
//
// Returns:
//  ValueTableRow - a line with the added printed form.
//
Function AddPrintedFormToKit(PrintFormsSet, Name, Presentation, Copies2 = 0) Export
	
	NewPrintingForm = PrintFormsSet.Add();
	NewPrintingForm.Name = Name;
	NewPrintingForm.Presentation = Presentation;
	NewPrintingForm.Copies2 = Copies2;
	NewPrintingForm.Print = Copies2 > 0;
	
	Return NewPrintingForm;
	
EndFunction

// Gets object parameters for printing a set of printed forms
//
// Parameters:
//		ObjectType - String - the full name of the object for which to get the options to print a complete set of printed forms.
//
// Returns:
//	Structure - Print options:
//		* KitPrintingIsAvailable - Boolean - indicates whether a set of printing forms can be printed for the object.
//		* ThereIsACompany         - Boolean - indicates whether the organization exists in the object.
//		* ThereIsAPartner             - Boolean - indicates whether there is a partner in the object.
//
Function ObjectParametersForCompletePrinting(ObjectType) Export
	
	ObjectParametersForCompletePrinting = New Structure();
	ObjectParametersForCompletePrinting.Insert("KitPrintingIsAvailable", False);
	ObjectParametersForCompletePrinting.Insert("ThereIsACompany", False);
	ObjectParametersForCompletePrinting.Insert("ThereIsAPartner", False);
	
	If ValueIsFilled(ObjectType) Then
	
		ObjectsTable = TableOfObjectsForCompletePrinting();
		CurrentObject = ObjectsTable.Find(ObjectType, "ObjectType");
		If CurrentObject <> Undefined Then
			FillPropertyValues(ObjectParametersForCompletePrinting, CurrentObject);
			ObjectParametersForCompletePrinting.KitPrintingIsAvailable = True;
		EndIf;
	
	EndIf;
	
	Return ObjectParametersForCompletePrinting;
	
EndFunction

// Returns a table with a description of objects that
// can print a set of printed forms.
//
// Returns:
// ValueTable - Table of values with columns:
//  * ObjectType            - String - full name of the object.
//  * Presentation         - String - custom representation of the object.
//  * ThereIsACompany       - Boolean - indicates whether the organization exists in the object.
//  * ThereIsAPartner           - Boolean - indicates whether there is a partner in the object.
//  * ThereAreConditionsForAdding - Boolean - indicates whether there are conditions for adding the print commands "Kit of documents to the printer"
//                                     and "Kit of documents with settings..". If True, then the
//                                     object manager module should contain an export function to add a command to print a set of documents,
//                                     which returns the value Type("Boolean") - the result of fulfilling the conditions.
//  * HasVisibilityConditions  - Boolean - indicates the presence of conditions for the visibility of print commands "A set of documents to the printer"
//                                     and "A set of documents with settings.." . If True, then the module of the object manager
//                                     should contain an export procedure for determining the command for printing a set of documents,
//                                     in which the addition of conditions for the visibility of the command method is implemented. See AttachableCommands.AddCommandVisibilityCondition.
//
Function TableOfObjectsForCompletePrinting() Export
	
	ObjectsTable = New ValueTable();
	ObjectsTable.Columns.Add("ObjectType");
	ObjectsTable.Columns.Add("Presentation");
	ObjectsTable.Columns.Add("ThereIsACompany");
	ObjectsTable.Columns.Add("ThereIsAPartner");
	ObjectsTable.Columns.Add("ThereAreConditionsForAdding");
	ObjectsTable.Columns.Add("HasVisibilityConditions");
	
	// Sales order
	If GetFunctionalOption("UseSalesOrders") Then
		NewRow = ObjectsTable.Add();
		NewRow.ObjectType = Metadata.Documents.SalesOrder.FullName();
		NewRow.Presentation = Metadata.Documents.SalesOrder.Presentation();
		NewRow.ThereIsACompany = True;
		NewRow.ThereIsAPartner = True;
		NewRow.ThereAreConditionsForAdding = True;
		NewRow.HasVisibilityConditions = False;
	EndIf;
	
	// Request for return of goods from the client
	If GetFunctionalOption("UseRequestsForReturnOfGoodsFromCustomers") Then
		NewRow = ObjectsTable.Add();
		NewRow.ObjectType = Metadata.Documents.RequestForReturnOfGoodsFromCustomer.FullName();
		NewRow.Presentation = Metadata.Documents.RequestForReturnOfGoodsFromCustomer.Presentation();
		NewRow.ThereIsACompany = True;
		NewRow.ThereIsAPartner = True;
		NewRow.ThereAreConditionsForAdding = True;
		NewRow.HasVisibilityConditions = False;
	EndIf;
	
	// Invoice for payment
	If GetFunctionalOption("UseCustomerCommercialInvoices") Then
		NewRow = ObjectsTable.Add();
		NewRow.ObjectType = Metadata.Documents.CustomerCommercialInvoice.FullName();
		NewRow.Presentation = Metadata.Documents.CustomerCommercialInvoice.Presentation();
		NewRow.ThereIsACompany = True;
		NewRow.ThereIsAPartner = True;
		NewRow.ThereAreConditionsForAdding = True;
		NewRow.HasVisibilityConditions = False;
	EndIf;
	
	// LetterOfAuthority
	If GetFunctionalOption("UseAuthorizationLettersForInventoryReceipt") Then
		NewRow = ObjectsTable.Add();
		NewRow.ObjectType = Metadata.Documents.IssuedLetterOfAuthority.FullName();
		NewRow.Presentation = Metadata.Documents.IssuedLetterOfAuthority.Presentation();
		NewRow.ThereIsACompany = True;
		NewRow.ThereIsAPartner = True;
		NewRow.ThereAreConditionsForAdding = False;
		NewRow.HasVisibilityConditions = False;
	EndIf;
	
	// Cash receipt order
	NewRow = ObjectsTable.Add();
	NewRow.ObjectType = Metadata.Documents.CashAccountReceiptNote.FullName();
	NewRow.Presentation = Metadata.Documents.CashAccountReceiptNote.Presentation();
	NewRow.ThereIsACompany = True;
	NewRow.ThereIsAPartner = False;
	NewRow.ThereAreConditionsForAdding = False;
	NewRow.HasVisibilityConditions = False;
	
	// Shipment of Goods to the Customer
	If GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle2_5") Then
		NewRow = ObjectsTable.Add();
		NewRow.ObjectType = Metadata.Documents.GoodsShipmentToCustomer.FullName();
		NewRow.Presentation = Metadata.Documents.GoodsShipmentToCustomer.Presentation();
		NewRow.ThereIsACompany = True;
		NewRow.ThereIsAPartner = True;
		NewRow.ThereAreConditionsForAdding = True;
		NewRow.HasVisibilityConditions = False;
	EndIf;
	
	// Sales of goods and services
	NewRow = ObjectsTable.Add();
	NewRow.ObjectType = Metadata.Documents.CustomerInvoice.FullName();
	NewRow.Presentation = Metadata.Documents.CustomerInvoice.Presentation();
	NewRow.ThereIsACompany = True;
	NewRow.ThereIsAPartner = True;
	NewRow.ThereAreConditionsForAdding = True;
	NewRow.HasVisibilityConditions = False; 
	
	// Report of completed works
	NewRow = ObjectsTable.Add();
	NewRow.ObjectType = Metadata.Documents.CustomerInvoiceServices.FullName();
	NewRow.Presentation = Metadata.Documents.CustomerInvoiceServices.Presentation();
	NewRow.ThereIsACompany = True;
	NewRow.ThereIsAPartner = True;
	NewRow.ThereAreConditionsForAdding = True;
	NewRow.HasVisibilityConditions = False;
	
	// Goods transfer
	If GetFunctionalOption("UseGoodsTransfer") Then
		NewRow = ObjectsTable.Add();
		NewRow.ObjectType = Metadata.Documents.InventoryTransfer.FullName();
		NewRow.Presentation = Metadata.Documents.InventoryTransfer.Presentation();
		NewRow.ThereIsACompany = True;
		NewRow.ThereIsAPartner = False;
		NewRow.ThereAreConditionsForAdding = False;
		NewRow.HasVisibilityConditions = False;
	EndIf;
	
	// Transfer of goods to the custodian
	If GetFunctionalOption("UseTransferToCustodyWithRightOfSale") Then
		NewRow = ObjectsTable.Add();
		NewRow.ObjectType = Metadata.Documents.TransferOfGoodsToBailee.FullName();
		NewRow.Presentation = Metadata.Documents.TransferOfGoodsToBailee.Presentation();
		NewRow.ThereIsACompany = True;
		NewRow.ThereIsAPartner = True;
		NewRow.ThereAreConditionsForAdding = True;
		NewRow.HasVisibilityConditions = True;
	EndIf;
	
	// Shipment of goods from storage
	UseTransferToCustodyWithRightOfSale =
						GetFunctionalOption("UseTransferToCustodyWithRightOfSale");
	UseTransferToCustodyWithRightOfSale =
		UseTransferToCustodyWithRightOfSale
		Or GetFunctionalOption("UseTollManufacturing2_5");
	If UseTransferToCustodyWithRightOfSale Then
		NewRow = ObjectsTable.Add();
		NewRow.ObjectType = Metadata.Documents.GoodsShipmentFromStorage.FullName();
		NewRow.Presentation = Metadata.Documents.GoodsShipmentFromStorage.Presentation();
		NewRow.ThereIsACompany = True;
		NewRow.ThereIsAPartner = True;
		NewRow.ThereAreConditionsForAdding = True;
		NewRow.HasVisibilityConditions = False;
	EndIf;
	
	// Redemption of goods by the custodian
	UseSalesInvoiceVMISellingByCustodianOfGoods =
						GetFunctionalOption("UseTransferToCustodyWithRightOfSale");
	UseSalesInvoiceVMISellingByCustodianOfGoods =
						UseSalesInvoiceVMISellingByCustodianOfGoods
						Or GetFunctionalOption("UseProductionByThirdParty2_5");
	If UseSalesInvoiceVMISellingByCustodianOfGoods Then
		NewRow = ObjectsTable.Add();
		NewRow.ObjectType = Metadata.Documents.RedemptionOfGoodsByCustodian.FullName();
		NewRow.Presentation = Metadata.Documents.RedemptionOfGoodsByCustodian.Presentation();
		NewRow.ThereIsACompany = True;
		NewRow.ThereIsAPartner = True;
		NewRow.ThereAreConditionsForAdding = True;
		NewRow.HasVisibilityConditions = False;
	EndIf;
	
	// Report to material provider
	
	If GetFunctionalOption("UseTollManufacturing2_5") Then
		NewRow = ObjectsTable.Add();
		NewRow.ObjectType      = Metadata.Documents.ReportToMaterialProvider2_5.FullName();
		NewRow.Presentation   = Metadata.Documents.ReportToMaterialProvider2_5.Presentation();
		NewRow.ThereIsACompany = True;
		NewRow.ThereIsAPartner     = True;
		NewRow.ThereAreConditionsForAdding = True;
		NewRow.HasVisibilityConditions = False;
	EndIf;
	// Reusable package redemption by customer
	If GetFunctionalOption("UseReusablePackage") Then
		NewRow = ObjectsTable.Add();
		NewRow.ObjectType = Metadata.Documents.ReturnablePackagingRedemptionByCustomer.FullName();
		NewRow.Presentation = Metadata.Documents.ReturnablePackagingRedemptionByCustomer.Presentation();
		NewRow.ThereIsACompany = True;
		NewRow.ThereIsAPartner = False;
		NewRow.ThereAreConditionsForAdding = False;
		NewRow.HasVisibilityConditions = False;
	EndIf;
	
	If GetFunctionalOption("ProvideAgentServicesOnPurchaseToPrincipals") Then
		NewRow = ObjectsTable.Add();
		NewRow.ObjectType = Metadata.Documents.PurchasingReportToConsignorPrincipal.FullName();
		NewRow.Presentation = Metadata.Documents.PurchasingReportToConsignorPrincipal.Presentation();
		NewRow.ThereIsACompany = True;
		NewRow.ThereIsAPartner = False;
		NewRow.ThereAreConditionsForAdding = False;
		NewRow.HasVisibilityConditions = False;
	EndIf;
		
	Return ObjectsTable;
	
EndFunction

// Copies a row to the print form collection from the set print settings row
//
// Parameters:
// 	PrintFormsCollection - ValueTable - table of values passed to the Print() procedure of the manager module:
// 		* TemplateName - String
// 		* Copies2 - Number
// 		* UpperCaseName - String
// 	PrintSettings - ValueTableRow - the row of the table returned by the function Prepare Set of Printable Forms() contains:
// 		* Name - String
//
Procedure CopyPrintedFormToCollection(PrintFormsCollection, PrintSettings) Export
	
	NewRow = PrintFormsCollection.Add();
	NewRow.TemplateName = PrintSettings.Name;
	NewRow.Copies2 = PrintSettings.Copies2;
	NewRow.UpperCaseName = Upper(NewRow.TemplateName);
	
EndProcedure

// Complements the collection of printed forms with external printed forms
// Parameters:
// ObjectType - String - the full name of the object for which you want to configure printing forms
// AddOnKit - See PrepareSetOfPrintedForms
//
Procedure AddExternalPrintFormsToSet(ObjectType, AddOnKit) Export
	
	// adding external printing plates to the kit
	ExternalPrintFormsPrefix = "ExternalPrintForm";
	CollectionOfExternalPrintingPlates = PrepareSetOfPrintedForms();
	CommandsTable = AdditionalReportsAndDataProcessors.AdditionalCommands(Enums.AdditionalReportsAndDataProcessorsKinds.PrintForm, ObjectType, True);
	
	For Each PrintCommand In CommandsTable Do
		AddPrintedFormToKit(AddOnKit, ExternalPrintFormsPrefix + PrintCommand.Id, PrintCommand.Presentation, 0);
	EndDo;
	
	Owner = Common.MetadataObjectID(Metadata.FindByFullName(ObjectType), False);
	If ValueIsFilled(Owner) Then
		
		QueryText =
		"SELECT
		|	PrintFormTemplates.Id,
		|	PrintFormTemplates.Presentation AS Presentation,
		|	PrintFormTemplates.VisibilityCondition AS VisibilityConditions
		|FROM
		|	Catalog.PrintFormTemplates.DataSources AS PrintFormTemplatesDataSources
		|		LEFT JOIN Catalog.PrintFormTemplates AS PrintFormTemplates
		|		ON PrintFormTemplatesDataSources.Ref = PrintFormTemplates.Ref
		|WHERE
		|	PrintFormTemplatesDataSources.DataSource = &Owner
		|	AND PrintFormTemplates.Used
		|	AND NOT PrintFormTemplates.DeletionMark";
		
		Query = New Query(QueryText);
		Query.SetParameter("Owner", Owner);
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do
			PrintCommand = AddOnKit.Add();
			PrintCommand.Name = "PF_" + Selection.Id;
			PrintCommand.Presentation = Selection.Presentation;
			PrintCommand.Print = False;
			PrintCommand.Copies2 = 0;
		EndDo;
		
	EndIf;
	
EndProcedure

// Returns the set settings grouped by object.
//
// Parameters:
// PrintFormsCollection - ValueTable - table passed to the Print () procedure of the Manager module
// PrintFormsSet - ValueTable - objects to print
// ObjectsArray - Array - objects for which you need to create sets of printed forms
// TemplateName - String - name of the layout to print.
//
// Returns:
// ValueTable - Table of values with columns:
//  * Name           - String - internal name of the printed form.
//  * Presentation - String - custom representation of the printed form.
//  * Copies2   - Number - the number of copies to print.
//  * Print      - Boolean - indicates whether the printed form needs to be printed.
//  * Objects       - Array - links to objects that need to be printed.
//
Function SetsOfPrintingOnObjects(PrintFormsCollection, Val PrintFormsSet, Val ObjectsArray, Val TemplateName) Export
	
	PrintKits_ = PrintFormsSet.Copy(New Structure("Name,Print,", TemplateName, True)); // See PrepareSetOfPrintedForms
	SetsOfPrintingOnObjects = PrepareSetOfPrintedForms();
	SetsOfPrintingOnObjects.Columns.Add("Objects");
	SetsOfPrintingOnObjects.Columns.Delete("Ref");
	
	If PrintKits_.Count() > 0 Then
		If PrintKits_.Columns.Find("Ref") <> Undefined And ValueIsFilled(PrintKits_[0].Ref) Then
			
			PrintFormNumber = 0;
			
			For Each PrintKit In PrintKits_ Do
				NamePrefix = "";
				If ValueIsFilled(PrintKit.Ref) Then 
					PrintKitLinkMetadata = Metadata.FindByType(TypeOf(PrintKit.Ref));
					If PrintKitLinkMetadata <> Undefined Then
						NamePrefix = PrintKitLinkMetadata.Name + ".";
					EndIf;  
				EndIf;  
				PrintKit.Name = NamePrefix + TemplateName + String(PrintFormNumber);				
				PrintFormNumber = PrintFormNumber + 1;
				
				CopyPrintedFormToCollection(PrintFormsCollection, PrintKit);
				
				NewRow = SetsOfPrintingOnObjects.Add();
				FillPropertyValues(NewRow, PrintKit);
				ReferencesArrray = New Array();
				ReferencesArrray.Add(PrintKit.Ref);
				NewRow.Objects = ReferencesArrray;
				
			EndDo;
			
		Else
			
			CopyPrintedFormToCollection(PrintFormsCollection, PrintKits_[0]);
				
			NewRow = SetsOfPrintingOnObjects.Add();
			FillPropertyValues(NewRow, PrintKits_[0]);
			NewRow.Objects = ObjectsArray;
				
		EndIf;
		
	EndIf;
	
	Return SetsOfPrintingOnObjects;
		
EndFunction

// See AttachableCommandsOverridable.OnDefineAttachableCommandsKinds.
Procedure OnDefineAttachableCommandsKinds(AttachableCommandsKinds) Export
	
	TypePrint = AttachableCommandsKinds.Find("Print", "Name");
	IndexOf = AttachableCommandsKinds.IndexOf(TypePrint);
	Kind = AttachableCommandsKinds.Insert(IndexOf);
	FillPropertyValues(Kind, TypePrint);
	Kind.Name = "PrintingSetOfDocumentsWithSettings";
	
EndProcedure

// See AttachableCommandsOverridable.OnDefineAttachableObjectsSettingsComposition.
Procedure OnDefineAttachableObjectsSettingsComposition(InterfaceSettings4) Export
	
	Setting = InterfaceSettings4.Add();
	Setting.Key          = "AddPrintingOfSetOfDocumentsWithSettings";
	Setting.TypeDescription = New TypeDescription("Boolean");
	Setting.AttachableObjectsKinds = "Document";
	
EndProcedure

// See AttachableCommandsOverridable.OnDefineCommandsAttachedToObject.
Procedure OnDefineCommandsAttachedToObject(FormSettings, Sources, AttachedReportsAndDataProcessors, Commands) Export
	
	SourcesParameters = New Map;
	
	TableOfObjectsForCompletePrinting = TableOfObjectsForCompletePrinting();
	For Each String In TableOfObjectsForCompletePrinting Do
		TypeName = StrReplace(String.ObjectType, ".", "Ref.");
		
		CommandParameters = New Structure;
		CommandParameters.Insert("ObjectType", Type(TypeName));
		CommandParameters.Insert("ThereAreConditionsForAdding", String.ThereAreConditionsForAdding);
		CommandParameters.Insert("HasVisibilityConditions", String.HasVisibilityConditions);
		
		SourcesParameters.Insert(String.ObjectType, CommandParameters);
	EndDo;
	
	For Each Source In Sources.Rows Do
		
		SourceParameters = SourcesParameters[Source.FullName];
		If SourceParameters = Undefined Then
			Continue;
		EndIf;
		ObjectType = SourceParameters.ObjectType;
		
		ObjectManager = Source.Manager;
		
		If SourceParameters.ThereAreConditionsForAdding Then
			If Not ObjectManager.AddCommandsToPrintSetOfDocuments() Then
				Continue;
			EndIf;
		EndIf;
		
		//KitOfDocumentsForPrinter
		NewCommand = Commands.Add();
		NewCommand.Kind = "PrintingSetOfDocumentsWithSettings";
		NewCommand.Handler = "PrintManagementTMClient.StartPrintingSetOfDocuments";
		NewCommand.Id = "SetOfDocuments";
		NewCommand.Presentation = NStr("vi = 'Bộ chứng từ để in';
										|ru = 'Комплект документов на принтер';
										|en = 'Document set for printing'; fa = 'Document set for printing';
										|it = 'Pacchetto di documenti per la stampa';
										|pl = 'Komplet dokumentów na drukarkę';
										|tr = 'Yazıcı belgeleri seti'");
		NewCommand.ParameterType = ObjectType;
		NewCommand.WriteMode = "Post";
		NewCommand.Order = 1;
		
		If SourceParameters.HasVisibilityConditions Then
			ObjectManager.WhenDefiningCommandToPrintSetOfDocuments(NewCommand);
		EndIf;
		
		//SetOfDocumentsWithSettings
		NewCommand = Commands.Add();
		NewCommand.Kind = "PrintingSetOfDocumentsWithSettings";
		NewCommand.Handler = "PrintManagementTMClient.OpenFormForPrintingSetOfDocumentsWithSettings";
		NewCommand.Id = "SetOfDocumentsWithSettings";
		NewCommand.Presentation = NStr("vi = 'Bộ chứng từ có tùy chỉnh...';
										|ru = 'Комплект документов с настройкой...';
										|en = 'Document set with setting...'; fa = 'Document set with setting...';
										|it = 'Pacchetto di documenti con l''impostazione...';
										|pl = 'Komplet dokumentów z ustawieniami...';
										|tr = 'Ayarlar ile belgeleri seti...'");
		NewCommand.ParameterType = ObjectType;
		NewCommand.WriteMode = "Post";
		NewCommand.Order = 2;
		
		If SourceParameters.HasVisibilityConditions Then
			ObjectManager.WhenDefiningCommandToPrintSetOfDocuments(NewCommand);
		EndIf;
		
	EndDo;
EndProcedure

#EndRegion

#Region Internal

// Performs verification of the correctness of specifying the settings of the set of printed Forms
// 
// Parameters:
//  PrintFormsSet - See InformationRegister.ObjectPrintSettings.Form.RecordForm.PrintFormsSet
//  Cancel - Boolean - Cancel
//
Procedure KitOfPrintingPlatesIsSet(PrintFormsSet, Cancel) Export
	
	LineNumber = 0;
	For Each SetString_ In PrintFormsSet Do
		
		LineNumber = LineNumber + 1;
		
		If SetString_.Print
		   And SetString_.Copies2 = 0 Then
			
			DataPath = CommonClientServer.PathToTabularSection(
				"PrintFormsSet", LineNumber, "Copies2");
			
			MessageText = CommonClientServer.FillingErrorText(
				"Column",
				,
				NStr("vi = 'Bản in';
					|ru = 'Экземпляров';
					|en = 'Copies'; fa = 'نسخه‌ها';
					|it = 'Экземпляров';
					|pl = 'Copies';
					|tr = 'Örnekler'"),
				Format(LineNumber - 1, "NZ=0; NG=0;"),
				NStr("vi = 'Bộ mẫu in';
					|ru = 'Комплект печатных форм';
					|en = 'Print form set'; fa = 'مجموعه فرم چاپی';
					|it = 'Set di moduli di stampa';
					|pl = 'Komplet furmularzy wydruku';
					|tr = 'Yazdırma formu seti'"));
			
			Common.MessageToUser(MessageText,, DataPath,, Cancel);
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

#Region Print

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
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "SetOfDocuments") Then
		PrintFormsCollection.Clear();
		CreateSetOfPrintedForms(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects);
	EndIf;
	
EndProcedure

// Generates a set of printed forms based on the passed array of objects
// An array of objects can include various types of objects that support bundled printing.
//
// Parameters:
// ObjectsArray - Array - objects for which you need to create sets of printed forms
// PrintParameters - Structure - print options
// PrintFormsCollection - See PrepareSetOfPrintedForms 
// PrintObjects - See PrintManagementOverridable.OnPrint.PrintObjects
//
Procedure CreateSetOfPrintedForms(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects) Export
	
	MapTypes = TMCommonUse.MatchingArraysByObjectType(ObjectsArray);
	
	For Each CurObjectType In MapTypes Do
		
		PrintManager = Common.ObjectManagerByFullName(CurObjectType.Key);
		PrintManager.CreateSetOfPrintedForms(
			CurObjectType.Value,
			PrintParameters,
			PrintFormsCollection,
			PrintObjects);
		
	EndDo;
	
	If PrintFormsCollection.Count() = 0
		And ObjectsArray.Count() > 0 Then
		
		NewRow = PrintFormsCollection.Add();
		NewRow.SpreadsheetDocument = New SpreadsheetDocument;
		NewRow.Copies2 = 0;
		NewRow.TemplateSynonym = ObjectsArray[0].Metadata().Synonym;
		
	EndIf; 
	
EndProcedure

// Generates a set of external printing forms based on the passed array of objects
// An array of objects can include various types of objects that support bundled printing.
//
// Parameters:
// PrintManagerName - String - name of the document print Manager
// ObjectsArray - Array - objects for which you need to create sets of printed forms
// PrintParameters - Structure - print options
// PrintFormsCollection - See PrepareSetOfPrintedForms 
// PrintObjects - See PrintManagementOverridable.OnPrint.PrintObjects
//
Procedure FormSetOfExternalPrintingPlates(PrintManagerName, ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects) Export
	
	Var AddressOfSetOfPrintedForms;
	
	If TypeOf(PrintParameters) = Type("Structure") And PrintParameters.Property("AddressOfSetOfPrintedForms", AddressOfSetOfPrintedForms) Then
		
		PrintFormsSet = GetFromTempStorage(AddressOfSetOfPrintedForms);
		
	Else
		PrintFormsSet = PrintFormsSet(
			PrintManagerName,
			ObjectsArray, 
			Undefined);
		
	EndIf;
	
	StructureOfTypes = New Map;
	StructureOfTypes.Insert("Document.CustomerInvoice", ObjectsArray);
	
	OutputParameters = PrintManagement.PrepareOutputParametersStructure();
	ExternalPrintForms = PrintManagement.PrintFormsListFromExternalSources(PrintManagerName);
	
	ExternalPrintFormsPrefix = "ExternalPrintForm";
	
	For Each PrintForm In PrintFormsSet Do
		// search for the indication of an additional print manager in the name of the printed form
		AdditionalPrintManagerName = "";
		TemplateName = PrintForm.Name;
		Id = TemplateName;
		
		If StrFind(Id, ExternalPrintFormsPrefix) > 0 Then // this is an external printed form
			Id = Mid(Id, StrLen(ExternalPrintFormsPrefix) + 1);
		ElsIf PrintForm.Print
			
			And (StrStartsWith(Id, "PF_")
				Or StrFind(Id, ".PF_") > 0) Then
				
			PrintData = PrintManagement.GeneratePrintForms("PrintManagement",
				Id,
				ObjectsArray,
				PrintParameters);
			
			For Each CollectionRow In PrintData.PrintFormsCollection Do
				
				NewRow = PrintFormsCollection.Add();
				FillPropertyValues(NewRow, CollectionRow);
				NewRow.Copies2 = PrintForm.Copies2;
				
			EndDo;
			
		Else
			Continue;
		EndIf;
		
		CurKit = PrintFormsSet.Copy(New Structure("Name,Print,",TemplateName,True));
		If CurKit.Count() > 0 And PrintFormsCollection.Find(TemplateName, "TemplateName") = Undefined Then
			If CurKit.Columns.Find("Ref") <> Undefined And ValueIsFilled(PrintForm.Ref) Then
				
				For Each PrintForm In CurKit Do
					
					TemporaryArrayOfObjects = New Array;
					TemporaryArrayOfObjects.Add(PrintForm.Ref);
					
					TempCollectionForSinglePrintForm = PrintManagementTMServer.PreparePrintFormsCollection(Id);
					
					// printing of an external printing plate
					AdditionalReportsAndDataProcessors.PrintByExternalSource(
						ExternalPrintForm(Id, PrintManagerName),
						New Structure("CommandID, RelatedObjects", Id, TemporaryArrayOfObjects),
						TempCollectionForSinglePrintForm,
						New ValueList,
						OutputParameters);
					
					// Output the required number of copies (when printing sets)
					SpreadsheetDocument = TempCollectionForSinglePrintForm[0].SpreadsheetDocument;
					SpreadsheetDocument.Copies = PrintForm.Copies2;
					
					OutputTabularDocumentOfExternalPFVCollection(
						PrintFormsCollection, 
						PrintForm,
						TemplateName,
						SpreadsheetDocument);
					
				EndDo; 
			
			Else
				TempCollectionForSinglePrintForm = PrintManagementTMServer.PreparePrintFormsCollection(Id);
				
				// printing of an external printing plate
				AdditionalReportsAndDataProcessors.PrintByExternalSource(
					ExternalPrintForm(Id, PrintManagerName),
					New Structure("CommandID, RelatedObjects", Id, ObjectsArray),
					TempCollectionForSinglePrintForm,
					PrintObjects,
					OutputParameters);
					
				CopyPrintedFormToCollection(PrintFormsCollection, CurKit[0]);
				CurStructureOfTypes = StructureOfTypes;
			
				PrintManagement.OutputSpreadsheetDocumentToCollection(
					PrintFormsCollection,
					TemplateName,
					CurKit[0].Presentation,
					TempCollectionForSinglePrintForm[0].SpreadsheetDocument);
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

// Returns a reference to the source object of the external print form.
//
// Parameters:
//  Id              - String - form ID;
//  FullMetadataObjectName - String - full name of the metadata object to get a link
//                                        to the source of the external print form for.
//
// Returns:
//  See AdditionalReportsAndDataProcessors.PrintByExternalSource.AdditionalDataProcessorRef
Function ExternalPrintForm(Id, FullMetadataObjectName)
	ExternalPrintFormRef = Undefined;
	
	AdditionalReportsAndDataProcessors.OnReceiveExternalPrintForm(Id, FullMetadataObjectName, ExternalPrintFormRef);
	
	Return ExternalPrintFormRef;
EndFunction

// Adds a table document of an external printable form to the printable form collection.
//
// Parameters:
//  PrintFormsCollection - See PrepareSetOfPrintedForms
//  PrintSettings       - ValueTableRow of See PrepareSetOfPrintedForms
//  TemplateName             - String - layout name;
//  SpreadsheetDocument     - SpreadsheetDocument - printed form of the document;
//  Picture              - Picture - ;
//  FullTemplatePath     - String - path to the layout in the metadata tree.
//
Procedure OutputTabularDocumentOfExternalPFVCollection(PrintFormsCollection, PrintSettings, TemplateName, SpreadsheetDocument, Picture = Undefined, FullTemplatePath = "")
	
	NewRow = PrintFormsCollection.Add();
	NewRow.TemplateName = PrintSettings.Name;
	NewRow.Copies2 = PrintSettings.Copies2;
	NewRow.UpperCaseName = Upper(NewRow.TemplateName);
	NewRow.TemplateSynonym = PrintSettings.Presentation;
	NewRow.SpreadsheetDocument = SpreadsheetDocument;
	NewRow.Picture = Picture;
	NewRow.FullTemplatePath = FullTemplatePath;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
