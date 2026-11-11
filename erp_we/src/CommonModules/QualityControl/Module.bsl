#Region Public

// Returns the cache of data from the quality control mechanism for placing objects in the Attributes of the form.
// The mechanism serves the processing of tabular parts to fill in the quality Attributes:
// Controllableparty, quality control, subject to unblocking, Quality data confirmation.
// Parameters:
//  Object - DocumentObject
//  ObjectManager - DocumentManager
// Returns:
//  - Structure:
//    * Key - String -
//    * FillInCheckQualityDateOfQualityConfirmation - See QualityControl.New_ActionParameters
//    * FillInUnblockableDateOfQualityConfirmation - See QualityControl.New_ActionParameters
//    * FillInSenderSControlledLotReference - See QualityControl.New_ActionParameters
//  - Array of Structure - structure with fields:
//   * Key - String
//   * Parameters - Structure:
//    ** Key - String
//    ** FillInCheckQualityDateOfQualityConfirmation - See QualityControl.New_ActionParameters
//    ** FillInUnblockableDateOfQualityConfirmation - See QualityControl.New_ActionParameters
//    ** FillInSenderSControlledLotReference - See QualityControl.New_ActionParameters
Function DataCacheOfMechanism(Object, ObjectManager = Undefined) Export
	
	If ObjectManager = Undefined Then
		ObjectManager = Common.ObjectManagerByRef(Object.Ref);
	EndIf;
	Result = ObjectManager.QualityControlActionParameters(Object);
	DisableIfFOIsDisabled(Result);
	Return Result;
	
EndFunction

// The logic of standard documents is described below. The cases when the document makes movements around the warehouse taking into account the Lot reference are described
// In this case, the Query Texts of the document use a Lot reference from the Attributes of the header of the document and it must be filled
// before / when recording the object.
//
// Order-based Lot Reference
// In Items in warehouses and Items to be received:
// - "Never
// 
// Lot Reference based on the Invoice:
// In Items in warehouses:
// - Flag to check the quality
// - And the Warehouse is extraordinary
// - And NOT an economic operation of separate purchase
// The Items to be received:
// - Flag to check the quality
// - Only when placing an Order for moving or Moving items with the flag "Moving a controlled Lot reference" 
// 
// KP = Link (Cached in the document)
// 
// Lot reference based on the receipt of items in the warehouse:
// In Items in warehouses:
// - Flag to check the quality
// - And the Warehouse is extraordinary
// The Items to be received:
// - "Never
// 
// KP = Link (Cached in the document)
// 
// Lot reference based on the Order of the Receipt order
// In Items in warehouses:
// - Flag to check the quality
// In Items for receipt:
// Only when the order is an Order to move or Move items with the flag "Moving a controlled Lot reference"
//
// KP = Lot reference[Order], Cached in the document
// 
// In the schedule of receipt (inventory needs.Will arrive) the order itself is always written, not the Lot reference.
// Reserves of need.Cash is written according to the same logic as Items in warehouses.
//
// Parameters:
//  Warehouse - CatalogRef.Warehouses - warehouse,
//  BusinessOperation - EnumRef.BusinessTransactions - economic operation.
// Returns:
//  Structure - structure with fields:
//  * Warehouse - CatalogRef.Warehouses - warehouse,
//  * BusinessOperation - EnumRef.BusinessTransactions - economic operation.
Function DetailsOfDeterminingNeedForLotReferenceInDocument(Warehouse, BusinessOperation) Export
	
	Result = New Structure("Warehouse,BusinessOperation", Warehouse, BusinessOperation);
	Return Result;
	
EndFunction

// Determines, according to the receipt document, the ability to create a quality control report based on this document.
// Parameters:
//  Ref - DefinedType.QualityControlLot - link to the document.
// Returns:
//  Boolean - it is true if the registration of the quality control act is provided for upon receipt of this document.
Function QualityControlIsSupported(Ref) Export
	
	SetPrivilegedMode(True);
	
	ControlIsSupported = ValueIsFilled(Ref)
		And Metadata.DefinedTypes.QualityControlLot.Type.ContainsType(TypeOf(Ref));
	If TypeOf(Ref) = Type("DocumentRef.SubcontractOrder2_5") Then
		
		GroupCosts = Common.ObjectAttributeValue(Ref, "GroupCosts");
		If GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
			ControlIsSupported = False;
		EndIf;
		
	ElsIf TypeOf(Ref) = Type("DocumentRef.MovementOfProductsAndMaterials") Then
		
		BusinessOperation = Common.ObjectAttributeValue(Ref, "BusinessOperation");
		ControlIsSupported =
			BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromStoreroom
				Or BusinessOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom
				Or BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromStoreroom
				Or BusinessOperation = Enums.BusinessTransactions.TransferOfSemiFinishedProducts
				Or BusinessOperation = Enums.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices;
		
	EndIf;
	Return ControlIsSupported;
	
EndFunction

// Checks whether certain actions are allowed for the Lot reference in the quality control report, adds invalid actions to the array.
// Parameters:
//  ControlledLotReference - CatalogRef.ControlledLots -
//  ItemsToRemove - Array of EnumRef.ActionsOnGoodsInQualityControlCertificate -
Procedure RestrictActionSelectionDataByLotReference(ControlledLotReference, ItemsToRemove) Export
	
	SetPrivilegedMode(True);
	AttributesValues = Common.ObjectAttributesValues(ControlledLotReference, "BusinessOperation,Lot");
	BusinessOperation = AttributesValues.BusinessOperation;
	Lot = AttributesValues.Lot;
	SetPrivilegedMode(False);
	
	ActionsOnGoods = Enums.ActionsOnGoodsInQualityControlCertificate;
	
	If Not ValueIsFilled(BusinessOperation)
			Or Not ValueIsFilled(PurchasesServer.GetRefundTransactionOnReceipt(BusinessOperation)) Then
		ItemsToRemove.Add(ActionsOnGoods.RegisterReturn);
		ItemsToRemove.Add(ActionsOnGoods.ToReturnToVendor);
	EndIf;
	
	If PurchasesServer.ThisIsEconomicOperationOfSeparatePurchase(BusinessOperation) Then
		ItemsToRemove.Add(ActionsOnGoods.ToReturnToVendor);
		ItemsToRemove.Add(ActionsOnGoods.DoNotReceiveGoods);
		ItemsToRemove.Add(ActionsOnGoods.ChangeQuality);
	EndIf;
	
	If PurchasesServer.ThisIsEconomicOperationOfSeparatePurchase(BusinessOperation) 
			Or TypeOf(Lot) = Type("DocumentRef.RequestForGoodsQualityControl") Then
		ItemsToRemove.Add(ActionsOnGoods.ToReturnToVendor);
		ItemsToRemove.Add(ActionsOnGoods.DoNotReceiveGoods);
		ItemsToRemove.Add(ActionsOnGoods.ChangeQuality);
	EndIf;
	
EndProcedure

// Determines that the Lot reference is associated of operation of receipt according to the scheme of separate registration of purchases.
// Parameters:
//  ControlledLotReference - CatalogRef.ControlledLots - link to The Lot Reference.
// Returns:
//  Boolean - true if the Lot reference is associated with the receipt operation according to the separate procurement scheme.
Function ThisIsTwoWay(ControlledLotReference) Export
	
	SetPrivilegedMode(True);
	BusinessOperation = Common.ObjectAttributeValue(ControlledLotReference, "BusinessOperation");
	If Not ValueIsFilled(BusinessOperation) Then
		Return False;
	EndIf;
	SetPrivilegedMode(False);
	ReturnOperation = PurchasesServer.GetRefundTransactionOnReceipt(BusinessOperation);
	Return ValueIsFilled(ReturnOperation);
	
EndFunction

// Determines by the functional options and Attributes of the received Lot reference, whether the receipt document provides for the execution of a discrepancy report.
// Used when determining the ability to create a discrepancy report based on a quality control report.
// Parameters:
//  ControlledLotReference - CatalogRef.ControlledLots - The Lot reference of the received item.
// Returns:
//  Boolean - true if the discrepancy report is provided.
Function DiscrepancyReportIsSupported(ControlledLotReference) Export
	
	If Not GetFunctionalOption("UseNonConformanceCertificatesFollowingAcceptance")
			And Not GetFunctionalOption("UseDiscrepancyReportFollowingReceiptFromSubcontractor2_5")
			And Not GetFunctionalOption("UseCertificatesOfDiscrepanciesAfterAcceptanceForAcceptanceOfGiverSGoods2_5")
			And Not GetFunctionalOption("UseNonConformanceCertificatesFollowingTransfer") Then
			
		Return False;
		
	ElsIf ControlledLotReference = Undefined Then
		
		Return True;
	Else
		
		SetPrivilegedMode(True);
		BusinessOperation = Common.ObjectAttributeValue(ControlledLotReference, "BusinessOperation");
		SetPrivilegedMode(False);
		
		Return
			BusinessOperation = Enums.BusinessTransactions.InventoryTransfer
				And GetFunctionalOption("UseNonConformanceCertificatesFollowingTransfer")
				Or BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5
					And GetFunctionalOption("UseCertificatesOfDiscrepanciesAfterAcceptanceForAcceptanceOfGiverSGoods2_5")
				Or (BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier
						Or BusinessOperation = Enums.BusinessTransactions.PurchaseByImport
						Or BusinessOperation = Enums.BusinessTransactions.ImportFromEAEU
						Or BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement
						Or BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsFromCustomer
						Or BusinessOperation = Enums.BusinessTransactions.GoodsReceiptFromCustomer
						Or BusinessOperation = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale)
					And GetFunctionalOption("UseNonConformanceCertificatesFollowingAcceptance")
				Or BusinessOperation = Enums.BusinessTransactions.ReceiptFromToller2_5
					And GetFunctionalOption("UseDiscrepancyReportFollowingReceiptFromSubcontractor2_5")
			Or BusinessOperation = Enums.BusinessTransactions.TransferOfGoodsBetweenBranchOffices
				And GetFunctionalOption("UseNonConformanceCertificatesFollowingTransfer");
			
	EndIf;
	
EndFunction

// Fills in the Attributes of the controlled Party, necessary for Registering Records in documents, orders for admission.
// In the document manager module, the function of the details of the controlled party should be defined.
// See QualityControl.NewAttributesOfControlledLotReference.
// Filling is performed if the Attributes in the document are not filled in.
// Filling is also performed if the Attribute is filled in, but according to the data of the document being recorded, the value of the Party Key Attribute must be
// changed in the Attribute
// To fill in the database, an element of the Catalog of the controlled party that is suitable for the key is searched.
// If there is no such element, the Attribute will be filled in with the link of the new object. The object itself will be created in the procedure
// Create and update a controlled Document recordingparty.
// Quality control functions.Fill in the controlled partyperformance of the document and 
// Quality control.Create and update a controlled partyrecords should be used in documents together.
// In the event handlers of the object before recording and during recording, respectively.
// 
// Parameters:
//  Object - DocumentObject - Document.
//  KeyAttributes - See QualityControl.DetailsOfDeterminingNeedForLotReferenceInDocument.
//  ItemNames - String - The names of the table parts, to reflect the data of which a controlled Lot reference may be needed.
//                         Names are separated by commas. An empty name means that the Lot reference is needed to account for the item
//                         from the document header. For example, the kit assembly.
//  FieldNameControlledLotReference - String - The name of the controlled party field, if it is different from "Controlled Party".
//                              - Undefined - If the name of the controlled Lot reference field does not differ from "Controlled party".
Procedure FillInControlledLotReferenceBeforeWritingDocument(Object, KeyAttributes, ItemNames = "Goods",
			FieldNameControlledLotReference = "ControlledLotReference") Export
	
	SetPrivilegedMode(True);
	
	NeedLotReference = True;
	If PurchasesServer.PairsOfSeparatePurchaseOperations(True).Get(KeyAttributes.BusinessOperation)
			<> Undefined Then
		// This is a transfer of ownership. The document does not make any Registered Records for Items in warehouses.
		NeedLotReference = False;
	EndIf;
	If NeedLotReference And ValueIsFilled(KeyAttributes.Warehouse)
			And Not WarehousesServer.ThereIsWarehouseThatIsNotOrderForReceipt(KeyAttributes.Warehouse, Object.Date) Then
		// In the header, there is an warehouse or a group of warehouses that does not have nested non-order warehouses.
		// The document does not make any Registered Records for Items in warehouses.
		NeedLotReference = False;
	EndIf;
	
	BatchIsFull = ValueIsFilled(Object[FieldNameControlledLotReference]);
	
	QualityControlIsEnabled = GetFunctionalOption("UseGoodsQualityControl");
	ClearLotReference = BatchIsFull And (Not NeedLotReference Or Not QualityControlIsEnabled);
	If ClearLotReference Then
		
		TabSections = StrSplit(ItemNames, ",");
		For Each TabSectionName In TabSections Do
			
			NameWithoutSpaces = TrimAll(TabSectionName);
			If NameWithoutSpaces = "" And Object.ToControlQuality Then
				ClearLotReference = False;
				Break;
			ElsIf Object[TabSectionName].Find(True, "ToControlQuality") <> Undefined Then
				ClearLotReference = False;
				Break;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	If ClearLotReference Then
		Object[FieldNameControlledLotReference] = Catalogs.ControlledLots.EmptyRef();
		Return;
	EndIf;
	
	If Not NeedLotReference Or Not QualityControlIsEnabled
			Or Object.AdditionalProperties.DocumentsPosting.DocumentProperties.WriteMode <> DocumentWriteMode.Posting Then
		Return;
	EndIf;
	
	ObjectManager = Common.ObjectManagerByRef(Object.Ref);
	AttributesOfLotReferenceAfterChange = ObjectManager.AttributesOfControlledLotReference(Object, FieldNameControlledLotReference);
	
	FillIn = Not BatchIsFull;
	
	Required_Attributes = New Structure("Patch", False);
	FillPropertyValues(Required_Attributes, Object);
	
	If Not FillIn And Object.Modified() And Not Required_Attributes.Patch Then
		
		AttributesOfLotReferenceBeforeChange = ObjectManager.AttributesOfControlledLotReference(Object.Ref, FieldNameControlledLotReference);
		FillIn = AttributesOfLotReferenceBeforeChange.Lot = Undefined
						Or Not TMCommonUseClientServer.StructuresAreEqual(
									AttributesOfLotReferenceAfterChange,
									AttributesOfLotReferenceBeforeChange,
									"Lot");
		
	EndIf;
	
	If FillIn Then
		
		DataLock = New DataLock();
		
		LockItem = DataLock.Add("Catalog.ControlledLots");
		
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.SetValue("Lot", AttributesOfLotReferenceAfterChange.Lot);
		
		//@skip-check lock-out-of-try
		DataLock.Lock();
		
		Query = New Query(
			"SELECT
			|	Lots.Ref AS Ref
			|FROM
			|	Catalog.ControlledLots AS Lots
			|WHERE
			|	Lots.Lot = &Lot");
		Query.SetParameter("Lot", AttributesOfLotReferenceAfterChange.Lot);
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			Object[FieldNameControlledLotReference] = Selection.Ref;
		Else
			Object[FieldNameControlledLotReference] = Catalogs.ControlledLots.GetRef();
		EndIf; 
		
	EndIf;
	
	DataLock = New DataLock();
	
	LockItem = DataLock.Add("Catalog.ControlledLots");
	
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.SetValue("Lot", AttributesOfLotReferenceAfterChange.Lot);
	LockItem.SetValue("Ref", Object[FieldNameControlledLotReference]);
	
	//@skip-check lock-out-of-try
	DataLock.Lock();
	
EndProcedure

// Creates an element of the Catalog of the Controlled Party if there is no reference to the Attribute of the Controlled Party from the Object in the database.
// Fills in the Attributes, by reference to the Attributes of the controlled party from the Object, with data from the object according to the algorithm
// described in the object manager module in the Controlled Party Details function.
// 
// Parameters:
//  Object - DocumentObject - Document.
//  FieldNameControlledLotReference - String - The name of the controlled party field, if it is different from "Controlled Party".
//                              - Undefined - If the name of the controlled Lot reference field does not differ from "Controlled party".
Procedure CreateUpdateControlledLotReferenceWhenWritingDocument(Object, FieldNameControlledLotReference = "ControlledLotReference") Export
	
	SetPrivilegedMode(True);
	Ref = Object[FieldNameControlledLotReference];
	If Not ValueIsFilled(Ref) Then
		Return;
	EndIf;
	
	Write = False;
	
	ObjectManager = Common.ObjectManagerByRef(Object.Ref);
	PartyDetails = ObjectManager.AttributesOfControlledLotReference(Object, FieldNameControlledLotReference);
	PartyDetails.DateOfReceipt = BegOfDay(PartyDetails.DateOfReceipt);
	ClearIfNotCostAccounting(PartyDetails.LineOfBusiness);
	BatchFields = BatchFields();
	AttributesValues = Common.ObjectAttributesValues(Ref, BatchFields + ",DeletionMark");
	If AttributesValues.Lot = Undefined Then
		
		Write = True;
		
		ControlledLotReferenceObject = Catalogs.ControlledLots.CreateItem();
		ControlledLotReferenceObject.SetNewObjectRef(Ref);
		
	Else
		
		AttributesValues.DateOfReceipt = BegOfDay(AttributesValues.DateOfReceipt);
		ClearIfNotCostAccounting(AttributesValues.LineOfBusiness);
		If Not TMCommonUseClientServer.StructuresAreEqual(AttributesValues, PartyDetails, BatchFields)
					Or Object.DeletionMark <> AttributesValues.DeletionMark Then
			Write = True;
			ControlledLotReferenceObject = Ref.GetObject();
		EndIf;
		
	EndIf;
	
	If Write Then
		
		FillPropertyValues(ControlledLotReferenceObject, PartyDetails);
		If ControlledLotReferenceObject.Lot = Object.Ref Then
			ControlledLotReferenceObject.DeletionMark = Object.DeletionMark;
		EndIf;
		ControlledLotReferenceObject.Description = QualityControlClientServer.PresentationOfControlledLotReference(
			PartyDetails, Common.DefaultLanguageCode());
		ControlledLotReferenceObject.DeleteBusinessUnitProcessed = True;
		ControlledLotReferenceObject.Write();
		
	EndIf;
	
EndProcedure

// Returns the Attributes of the controlled batch.
// 
// Returns:
//  Structure - The structure whose fields are the Attributes of the Catalog of the controlled parties:
//   * Lot - DefinedType.QualityControlLot,Undefined,
//   * ReasonForGoodsLock - CatalogRef.GoodsLockReasons
//   * ScheduleGoodsUnlock - Boolean
//   * DateOfReceipt - Date - the date for calculating the date of unlocking when moving.
//   * QualityConfirmationDate - Date - the date for calculating the date of unlocking when moving.
//   * BusinessOperation - EnumRef.BusinessTransactions,
//   * Sender - DefinedType.SenderRecipientOfGoods,Undefined,
//   * ReceiptDocumentNumber - String - to form a view
//   * DateOfReceiptDocument - Date - to form a view
//   * Partner - CatalogRef.Partners
//   * Counterparty - CatalogRef.Counterparties
//   * Contract - CatalogRef.CounterpartyContracts
//   * LineOfBusiness - CatalogRef.LinesOfBusiness,
//   * Organization - CatalogRef.Companies,
//   * Department - CatalogRef.BusinessStructure
Function NewAttributesOfControlledLotReference() Export
	
	Attributes = New Structure();
	Attributes.Insert("Lot", Undefined);
	Attributes.Insert("ReasonForGoodsLock", Catalogs.GoodsLockReasons.EmptyRef());
	Attributes.Insert("ScheduleGoodsUnlock", True);
	Attributes.Insert("QualityConfirmationDate", '00010101');
	Attributes.Insert("DateOfReceipt", '00010101');
	Attributes.Insert("ReceiptDocumentNumber", "");
	Attributes.Insert("DateOfReceiptDocument", '00010101');
	
	// To close the "goods to access" in the Register Records of the act of quality control.
	Attributes.Insert("BusinessOperation", Enums.BusinessTransactions.EmptyRef());
	Attributes.Insert("Sender", Undefined);
	
	// Reference information from the Lot reference object.
	Attributes.Insert("Partner", Catalogs.Partners.EmptyRef());
	Attributes.Insert("Counterparty", Catalogs.Counterparties.EmptyRef());
	Attributes.Insert("Contract", Catalogs.CounterpartyContracts.EmptyRef());
	Attributes.Insert("LineOfBusiness", Catalogs.LinesOfBusiness.EmptyRef());
	Attributes.Insert("Organization", Catalogs.Companies.EmptyRef());
	// Information from the batch object for access restrictions.
	Attributes.Insert("Department", Catalogs.BusinessStructure.EmptyRef());
	
	Return Attributes;
	
EndFunction

// Retrieves object fields from an object or reference.
// 
// Parameters:
//  ObjectOrRef - DocumentObject, DocumentRef - Object.
//  ObjectFields - String - fields of the object, separated by commas.
// Returns:
//  Structure - A structure whose keys are field names and values are object field values.
Function AttributesOfItemOrLink(ObjectOrRef, ObjectFields) Export
	
	If Common.IsReference(TypeOf(ObjectOrRef)) Then
		ObjectAttributes = Common.ObjectAttributesValues(ObjectOrRef, ObjectFields);
	Else
		ObjectAttributes = New Structure(ObjectFields);
		FillPropertyValues(ObjectAttributes, ObjectOrRef, ObjectFields);
	EndIf;
	Return ObjectAttributes;
	
EndFunction

// Determines whether the document is a controlled Lot reference.
// 
// Parameters:
//  Ref - CatalogRef, DocumentRef - Ref.
// Returns:
//  Boolean - True if the link is a batch document.
Function ThisIsLotReferenceDocument(Ref) Export
	
	Return Metadata.DefinedTypes.QualityControlLot.Type.ContainsType(TypeOf(Ref))
		And Not TypeOf(Ref) = Type("CatalogRef.TermsOfPurchaseFromVendors")
		And Not TypeOf(Ref) = Type("CatalogRef.CounterpartyContracts");
	
EndFunction

// If quality control of goods is used, the completeness of the Quality confirmation Attributes is checked.
// 
// Parameters:
//  Object - DocumentObject - the object being checked.
//  NotCheckedAttributeArray - Array of String - The array of unverifiable Attributes will be supplemented with verified Attributes.
//  Cancel - Boolean - refusal to record a document. 
//  TabSectionName - String - the name of the table part in which the Attribute to be checked is
//              - Undefined - if the Attribute to be checked is in the document header.
//  Synonym - String - synonym for the name of the table part.
//  NameDateOfReceipt - String, Undefined - if there is no "Receipt date" field in the document, if there is a field and it is in the header, then the field name, if there is a field and it is in the table part, then the dot and the field name are merged, for example. "Data accesses".
//  FillingIsMandatory - Boolean - if false, then do not check.
Procedure ProcessingVerificationOfFillingInReceiptDocument(Object, NotCheckedAttributeArray, Cancel, TabSectionName, Synonym, NameDateOfReceipt, FillingIsMandatory = True) Export
	
	AttributeName = ?(TabSectionName = Undefined, "", TabSectionName + ".") + "QualityConfirmationDate";
	
	NameOfVHFField = Undefined;
	If NameDateOfReceipt <> Undefined And StrFind(NameDateOfReceipt, ".") > 0 Then
		NameOfVHFField = Mid(NameDateOfReceipt, 2);
	EndIf;
	If Not GetFunctionalOption("UseGoodsQualityControl") Then
		NotCheckedAttributeArray.Add(AttributeName);
		Return;
	EndIf;
		
	If TabSectionName <> Undefined Then
		
		NotCheckedAttributeArray.Add(AttributeName);
		
		If FillingIsMandatory Then
			
			For Each TableRow In Object[TabSectionName] Do
				
				If Not TableRow.ToControlQuality Then
					Continue;
				EndIf;
				
				If NameDateOfReceipt = Undefined Then
					DateOfReceipt = Object.Date;
				ElsIf NameOfVHFField = Undefined Then
					DateOfReceipt = ?(ValueIsFilled(Object[NameDateOfReceipt]),
						Object[NameDateOfReceipt], Object.Date);
				Else
					DateOfReceipt = TableRow[NameOfVHFField];
				EndIf;
				
				If ValueIsFilled(DateOfReceipt) And Not ValueIsFilled(TableRow.QualityConfirmationDate) Then
					
					ErrorText = StrTemplate(
						NStr("ru = 'В строке %1 списка %2 не заполнена колонка ""Проверить качество до"".';
							|vi = 'The ""Check quality before"" column in line %1 of the ""%2"" list is not filled in.';
							|en = 'The ""Check quality before"" column in line %1 of the ""%2"" list is not filled in.'; fa = 'The ""Check quality before"" column in line %1 of the ""%2"" list is not filled in.';
							|it = 'The ""Check quality before"" column in line %1 of the ""%2"" list is not filled in.';
							|pl = 'The ""Check quality before"" column in line %1 of the ""%2"" list is not filled in.';
							|tr = 'Liste %2 satırında %1 ""Kalite kontrol son tarihi"" sütunu doldurulmamış.'"),
						TableRow.LineNumber,
						Synonym);
					Field = CommonClientServer.PathToTabularSection(TabSectionName,
						TableRow.LineNumber, "QualityConfirmationDate");
					
					Common.MessageToUser(ErrorText, Object, Field, , Cancel);
					
				Else
					
					If BegOfDay(TableRow.QualityConfirmationDate) < BegOfDay(DateOfReceipt) Then
					
						ErrorText = StrTemplate(
							NStr("ru = 'В строке %1 списка %2 в колонке ""Проверить качество до"" указана дата меньше даты поступления %3.';
								|vi = 'In line %1 of the ""%2"" list, in the ""Check quality before"" column, the date is less than the date of receipt (%3).';
								|en = 'In line %1 of the ""%2"" list, in the ""Check quality before"" column, the date is less than the date of receipt (%3).'; fa = 'In line %1 of the ""%2"" list, in the ""Check quality before"" column, the date is less than the date of receipt (%3).';
								|it = 'In line %1 of the ""%2"" list, in the ""Check quality before"" column, the date is less than the date of receipt (%3).';
								|pl = 'In line %1 of the ""%2"" list, in the ""Check quality before"" column, the date is less than the date of receipt (%3).';
								|tr = 'Liste %2 satırının %1 ""Kalite kontrol son tarihi"" sütununda giriş tarihinden %3 küçük bir tarih belirtilmiş.'"),
							TableRow.LineNumber,
							Synonym,
							Format(DateOfReceipt, "DLF=D;"));
						Field = CommonClientServer.PathToTabularSection(TabSectionName,
							TableRow.LineNumber, "QualityConfirmationDate");
						
						Common.MessageToUser(ErrorText, Object, Field, , Cancel);
						
					EndIf;
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
	Else
		
		If Object.ToControlQuality Then
			
			If Not ValueIsFilled(Object.QualityConfirmationDate) Then
				
				If FillingIsMandatory Then
					
					// platform message
					
				Else
					
					NotCheckedAttributeArray.Add(AttributeName);
					
				EndIf;
				
			Else
				
				NotCheckedAttributeArray.Add(AttributeName);
				
				If NameDateOfReceipt = Undefined Then
					DateOfReceipt = Object.Date;
				Else
					DateOfReceipt = ?(ValueIsFilled(Object[NameDateOfReceipt]),
						Object[NameDateOfReceipt], Object.Date);
				EndIf;
				
				If BegOfDay(Object.QualityConfirmationDate) < BegOfDay(DateOfReceipt) Then
				
					ErrorText = StrTemplate(
						NStr("ru = 'Дата проверки качества не должна быть меньше даты поступления %1.';
							|vi = 'Quality check date cannot be earlier than the date of receipt (%1).';
							|en = 'Quality check date cannot be earlier than the date of receipt (%1).'; fa = 'Quality check date cannot be earlier than the date of receipt (%1).';
							|it = 'Quality check date cannot be earlier than the date of receipt (%1).';
							|pl = 'Quality check date cannot be earlier than the date of receipt (%1).';
							|tr = 'Kalite kontrol tarihi, giriş tarihinden %1 küçük olmamalıdır.'"),
						Format(DateOfReceipt, "DLF=D;"));
					
					Common.MessageToUser(ErrorText, Object, AttributeName, , Cancel);
					
				EndIf;
				
			EndIf;
			
		Else
			
			NotCheckedAttributeArray.Add(AttributeName);
			
		EndIf;
		
	EndIf;
	
EndProcedure

// If quality control of goods is used, the completeness of the Quality confirmation Attributes is checked.
// 
// Parameters:
//  Object - DocumentObject - the object being checked.
//  NotCheckedAttributeArray - Array of String - The array of unverifiable Attributes will be supplemented with verified Attributes.
//  Cancel - Boolean - refusal to record a document. 
//  TabSectionName - String - the name of the table part in which the Attribute to be checked is
//              - Undefined - if the Attribute to be checked is in the document header.
//  Synonym - String - synonym for the name of the table part.
//  NameDateOfReceipt - String, Undefined - if there is no "Receipt date" field in the document, if there is a field and it is in the header, then the field name, if there is a field and it is in the table part, then the dot and the field name are merged, for example. "Data accesses".
Procedure ProcessingVerificationOfDocumentCompletionOfMove(Object, NotCheckedAttributeArray, Cancel, TabSectionName, Synonym, NameDateOfReceipt) Export
	
	AttributeName = TabSectionName + ".QualityConfirmationDate";
	NotCheckedAttributeArray.Add(AttributeName);
	
	DateOfReceipt = ?(ValueIsFilled(Object[NameDateOfReceipt]), Object[NameDateOfReceipt], BegOfDay(Object.Date));
	
	If Not GetFunctionalOption("UseGoodsQualityControl") Then
		Return;
	EndIf;
	
	For Each TableRow In Object[TabSectionName] Do
		
		If Not TableRow.ToControlQuality Or Not TableRow.SubjectToUnlocking Then
			Continue;
		EndIf;
		
		If Not ValueIsFilled(TableRow.QualityConfirmationDate) Then
			
			ErrorText = StrTemplate(
				NStr("ru = 'В строке %1 списка %2 не заполнена колонка ""Проверить качество до"".';
					|vi = 'The ""Check quality before"" column in line %1 of the ""%2"" list is not filled.';
					|en = 'The ""Check quality before"" column in line %1 of the ""%2"" list is not filled.'; fa = 'The ""Check quality before"" column in line %1 of the ""%2"" list is not filled.';
					|it = 'The ""Check quality before"" column in line %1 of the ""%2"" list is not filled.';
					|pl = 'The ""Check quality before"" column in line %1 of the ""%2"" list is not filled.';
					|tr = 'Liste %2 satırında %1""Kalite kontrol son tarihi"" sütunu doldurulmamış.'"),
				TableRow.LineNumber,
				Synonym);
			Field = CommonClientServer.PathToTabularSection(TabSectionName,
				TableRow.LineNumber, "QualityConfirmationDate");
			
			Common.MessageToUser(ErrorText, Object, Field, , Cancel);
			
		ElsIf Not ValueIsFilled(TableRow.ControlledLotOfTheSender) Then
			
			If TableRow.QualityConfirmationDate < DateOfReceipt Then
			
				ErrorText = StrTemplate(
					NStr("ru = 'В строке %1 списка %2 в колонке ""Проверить качество до"" указана дата меньше даты поступления %3.';
						|vi = 'In line %1 of the ""%2"" list, in the ""Check quality before"" column, the date is less than the date of receipt (%3).';
						|en = 'In line %1 of the ""%2"" list, in the ""Check quality before"" column, the date is less than the date of receipt (%3).'; fa = 'In line %1 of the ""%2"" list, in the ""Check quality before"" column, the date is less than the date of receipt (%3).';
						|it = 'In line %1 of the ""%2"" list, in the ""Check quality before"" column, the date is less than the date of receipt (%3).';
						|pl = 'In line %1 of the ""%2"" list, in the ""Check quality before"" column, the date is less than the date of receipt (%3).';
						|tr = 'Liste %2 satırının %1 ""Kalite kontrol son tarihi"" sütununda giriş tarihinden %3 küçük bir tarih belirtilmiş.'"),
					TableRow.LineNumber,
					Synonym,
					Format(DateOfReceipt, "DLF=D;"));
				Field = CommonClientServer.PathToTabularSection(TabSectionName,
					TableRow.LineNumber, "QualityConfirmationDate");
				
				Common.MessageToUser(ErrorText, Object, Field, , Cancel);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// If quality control of goods is used, the completeness of the Quality confirmation Attributes is checked.
// 
// Parameters:
//  Object - DocumentObject - the object being checked.
//  NotCheckedAttributeArray - Array of String - The array of unverifiable Attributes will be supplemented with verified Attributes.
//  Cancel - Boolean - refusal to record a document. 
//  TabSectionName - String - the name of the table part in which the Attribute to be checked is
//              - Undefined - if the Attribute to be checked is in the document header.
//  Synonym - String - synonym for the name of the table part.
//  FillingIsMandatory - Boolean,String - if false, then do not check, if the string is the path to the field of the table part, if it is not filled in, then do not check.
//  ThereIsSubjectToUnblocking - Boolean - True if the object being checked has Attributes to be unblocked
Procedure ProcessingVerificationOfFillingInSurplusDocument(Object, NotCheckedAttributeArray, Cancel, TabSectionName, Synonym, FillingIsMandatory = True, ThereIsSubjectToUnblocking = True) Export
	
	AttributeName = TabSectionName + ".QualityConfirmationDate";
	
	NotCheckedAttributeArray.Add(AttributeName);
	
	If Not GetFunctionalOption("UseGoodsQualityControl")
			Or FillingIsMandatory = False Then
		Return;
	EndIf;
	
	NameOfVHFField = Undefined;
	If TypeOf(FillingIsMandatory) = Type("String") And StrFind(FillingIsMandatory, ".") > 0 Then
		NameOfVHFField = Mid(FillingIsMandatory, 2);
	EndIf;
	
	NotCheckedAttributeArray.Add(AttributeName);
	
	For Each TableRow In Object[TabSectionName] Do
		
		If ThereIsSubjectToUnblocking And Not TableRow.SubjectToUnlocking Then
			Continue;
		EndIf;
		
		If Not ValueIsFilled(TableRow.QualityConfirmationDate)
				And (NameOfVHFField = Undefined Or ValueIsFilled(TableRow[NameOfVHFField])) Then
			
			ErrorText = StrTemplate(
				NStr("ru = 'В строке %1 списка %2 не заполнена колонка ""Проверить качество до"".';
					|vi = 'The ""Check quality before"" column in line %1 of the ""%2"" list is not filled in.';
					|en = 'The ""Check quality before"" column in line %1 of the ""%2"" list is not filled in.'; fa = 'The ""Check quality before"" column in line %1 of the ""%2"" list is not filled in.';
					|it = 'The ""Check quality before"" column in line %1 of the ""%2"" list is not filled in.';
					|pl = 'The ""Check quality before"" column in line %1 of the ""%2"" list is not filled in.';
					|tr = 'Liste %2 satırında %1""Kalite kontrol son tarihi"" sütunu doldurulmamış.'"),
				TableRow.LineNumber,
				Synonym);
			Field = CommonClientServer.PathToTabularSection(TabSectionName,
				TableRow.LineNumber, "QualityConfirmationDate");
			
			Common.MessageToUser(ErrorText, Object, Field, , Cancel);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Checks that there are no two lines in the document with different values of the Check quality attribute, if the lines are the same in the connection fields with the series.
//
// Parameters:
//  Object - DocumentObject - The document being checked.
//  LinkFields - Array of String - Nomenclature Server.Parametersreferences.Communication fields.
//  NameOfItems - String - The name of the tabular part of the document.
//  SynonymProducts - String - synonym of the tabular part of the document.
//  Cancel - Boolean - if the check was performed with error messages, then this flag will be cocked.
Procedure ProcessingVerificationOfCorrectnessOfConnectionWithBatches(Object, Val LinkFields, NameOfItems, SynonymProducts, Cancel) Export
	
	If Object.SetOfSeries.Count() = 0
			Or Not GetFunctionalOption("UseGoodsQualityControl") Then
		Return;
	EndIf;
	
	LinkFields.Insert(0, "Characteristic");
	LinkFields.Insert(0, "Products");
	
	ValuesToControlQuality = New Map();
	
	For Each TableRow In Object[NameOfItems] Do
		
		If TableRow.BatchesIndicationStatus = 0 Or ValueIsFilled(TableRow.Series) Then
			Continue;
		EndIf;
		Cursor = ValuesToControlQuality;
		
		// The cursor descends to the values of the Check Quality attribute
		For IndexOf = 0 To LinkFields.Count() - 1 Do
			
			ValueOfLinkField = TableRow[LinkFields[IndexOf]];
			
			If Cursor[ValueOfLinkField] = Undefined Then
				Cursor.Insert(ValueOfLinkField, New Map());
			EndIf;
			
			Cursor = Cursor[ValueOfLinkField];
			
		EndDo;
		Cursor.Insert(TableRow.ToControlQuality, True);
		
		If Cursor[False] = True And Cursor[True] = True Then
			
			Cancel = True;
			
			ErrorAnalytics = New Array();
			For IndexOf = 0 To LinkFields.Count() - 1 Do
				ValueOfLinkField = TableRow[LinkFields[IndexOf]];
				If ValueIsFilled(ValueOfLinkField) Then
					ErrorAnalytics.Add(ValueOfLinkField);
				EndIf;
			EndDo;
			
			ErrorText = StrTemplate(
				NStr("ru = 'В списке %1 в строках товара %2 c учетом остатков по сериям различается значение поля ""Проверить качество до"".';
					|vi = 'In the %1 list, the value of the ""Check quality before"" field differs in product lines %2, taking into account the batch balance.';
					|en = 'In the %1 list, the value of the ""Check quality before"" field differs in product lines %2, taking into account the batch balance.'; fa = 'In the %1 list, the value of the ""Check quality before"" field differs in product lines %2, taking into account the batch balance.';
					|it = 'In the %1 list, the value of the ""Check quality before"" field differs in product lines %2, taking into account the batch balance.';
					|pl = 'In the %1 list, the value of the ""Check quality before"" field differs in product lines %2, taking into account the batch balance.';
					|tr = '%1 listesindeki %2 öğesinin satırlarında, partilere göre stoklar hesaba katıldığında ""Kalite kontrol son tarihi"" alanı değeri farklılık gösteriyor.'"),
				SynonymProducts,
				StrConcat(ErrorAnalytics, " / "));
				
			Common.MessageToUser(ErrorText);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Clears the Attributes to check the quality and data confirmation of the quality in the tabular part of the document.
// 
// Parameters:
//  TabPart - FormDataCollection - the tabular part in which the Attributes are cleared is to check the quality
//                                    and data confirmation of the quality.
//  Rows - Array of FormDataCollectionItem - It is passed if you do not need to process the entire
//                                                                 table part, but only some of its rows.
Procedure ClearCheckQualityInReceiptDocument(TabPart, Rows) Export
	
	If Rows.Count() = 0 Then
		Return;
	EndIf;
	
	For Each TableRow In Rows Do
		TableRow.ToControlQuality = False;
		TableRow.QualityConfirmationDate = '00010101'; // IsEmpty
	EndDo;
	
EndProcedure

// Adds missing columns to the table of values obtained by executing the DCS query.
// Parameters:
//  Analysts - ValueTable - table with columns:
//  * Purpose - CatalogRef.Assignments
//  * Series - CatalogRef.ItemsBatches
//  * Characteristic - CatalogRef.ItemsCharacteristics
//  * Premise - CatalogRef.Warerooms
Procedure AddColumnsDisabledByFOToAnalystTable(Analysts) Export
	
	If Analysts.Columns.Find("Purpose") = Undefined Then
		Analysts.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
	EndIf;
	If Analysts.Columns.Find("Series") = Undefined Then
		Analysts.Columns.Add("Series", New TypeDescription("CatalogRef.ItemsBatches"));
	EndIf;
	If Analysts.Columns.Find("Characteristic") = Undefined Then
		Analysts.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	EndIf;
	If Analysts.Columns.Find("Premise") = Undefined Then
		Analysts.Columns.Add("Premise", New TypeDescription("CatalogRef.Warerooms"));
	EndIf;
	
EndProcedure

// Balances for filling out the documents of the application for the quality control of goods and the act of quality control of goods.
// 
// Parameters:
//  Analysts - ValueTable - Analyst Table:
//   * ControlledLotReference - CatalogRef.ControlledLots - Controlled Lot Reference
//   * Products - CatalogRef.Products - Products
//   * Characteristic - CatalogRef.ItemsCharacteristics - Characteristic
//   * Warehouse - CatalogRef.Warehouses - Warehouse
//   * Purpose - CatalogRef.Assignments - Purpose
//   * Premise - CatalogRef.Warerooms - Premise
//   * Series - CatalogRef.ItemsBatches - Series
//  ExcludeControlRequests - Boolean - if true, then only incoming Lot references will be received.
//  Date - Date - The date of the document, to determine the address storage and the need to obtain data in the context of premises and cells
//  Recorder - DocumentRef.GoodsQualityControlCertificate, DocumentRef.RequestForGoodsQualityControl, Undefined - receive Balances minus the registrar's Register Records.
//  FillInWithGoodsOfProvenQuality - Boolean - If true, then it is necessary to fill with Balances of proven quality.
// Returns:
//  ValueTable - Balance table:
//   * ControlledLotReference - CatalogRef.ControlledLots - Controlled Lot Reference
//   * Products - CatalogRef.Products - Products
//   * Characteristic - CatalogRef.ItemsCharacteristics - Characteristic
//   * Warehouse - CatalogRef.Warehouses - Warehouse
//   * Purpose - CatalogRef.Assignments - Purpose
//   * Premise - CatalogRef.Warerooms - Premise
//   * Series - CatalogRef.ItemsBatches - Series
//   * Package - CatalogRef.PackagesAndUnitsOfMeasure - Package
//   * Count - Number - Balance
//   * NumberOfPackages - Number - Balance in packages
Function AnalystBalances(Analysts, ExcludeControlRequests, Val Date, Recorder = Undefined, FillInWithGoodsOfProvenQuality = False) Export
	
	SetPrivilegedMode(True);
	If Not ValueIsFilled(Date) Then
		Date = CurrentSessionDate();
	EndIf;
	
	AdjustingBalances = ValueIsFilled(Recorder);
	Texts = New Array();
	Text =
		"SELECT DISTINCT
		|	Analysts.ControlledLotReference AS ControlledLotReference,
		|	Analysts.Products AS Products,
		|	Analysts.Characteristic AS Characteristic,
		|	Analysts.Warehouse AS Warehouse,
		|	Analysts.Purpose AS Purpose,
		|	Analysts.Premise AS Premise,
		|	Analysts.Series AS Series
		|INTO AnalystsGoodsInWarehouses
		|FROM
		|	&Analysts AS Analysts
		|INDEX BY
		|	ControlledLotReference, Products, Characteristic, Warehouse, Purpose, Premise, Series
		|;
		|
		|///////////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	Analysts.ControlledLotReference AS ControlledLotReference,
		|	Analysts.Products AS Products,
		|	Analysts.Characteristic AS Characteristic,
		|	Analysts.Warehouse AS Warehouse,
		|	Analysts.Purpose AS Purpose,
		|	Analysts.Series AS Series
		|INTO AnalystsGoodsToShip
		|FROM
		|	AnalystsGoodsInWarehouses AS Analysts
		|WHERE
		|	Analysts.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|INDEX BY
		|	ControlledLotReference, Products, Characteristic, Warehouse, Purpose, Series
		|;
		|
		|///////////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	Analysts.Products AS Products,
		|	Analysts.Characteristic AS Characteristic,
		|	Analysts.Warehouse AS Warehouse,
		|	Analysts.Purpose AS Purpose,
		|	Analysts.Series AS Series
		|INTO AnalystsGoodsToShipWithoutLotReference
		|FROM
		|	AnalystsGoodsToShip AS Analysts
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose, Series
		|;
		|
		|///////////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	Analysts.ControlledLotReference AS ControlledLotReference,
		|	Analysts.Products AS Products,
		|	Analysts.Characteristic AS Characteristic,
		|	Analysts.Warehouse AS Warehouse,
		|	Analysts.Purpose AS Purpose
		|INTO InventoryAndDemandAnalysts
		|FROM
		|	AnalystsGoodsInWarehouses AS Analysts
		|INDEX BY
		|	ControlledLotReference, Products, Characteristic, Warehouse, Purpose";
		
	Texts.Add(Text);
	If Not AdjustingBalances Then
		
		Text =
			"SELECT
			|	ProductStock.ControlledLotReference AS ControlledLotReference,
			|	ProductStock.Products AS Products,
			|	ProductStock.Characteristic AS Characteristic,
			|	ProductStock.Warehouse AS Warehouse,
			|	ProductStock.Purpose AS Purpose,
			|	ProductStock.Premise AS Premise,
			|	ProductStock.Series AS Series,
			|	ProductStock.InStockBalance AS Count
			|INTO ProductStock
			|FROM
			|	AccumulationRegister.ProductStock.Balance(, (
			|			ControlledLotReference,
			|			Products,
			|			Characteristic,
			|			Warehouse,
			|			Purpose,
			|			Premise,
			|			Series)
			|		IN(
			|			SELECT
			|				Analysts.ControlledLotReference AS ControlledLotReference,
			|				Analysts.Products AS Products,
			|				Analysts.Characteristic AS Characteristic,
			|				Analysts.Warehouse AS Warehouse,
			|				Analysts.Purpose AS Purpose,
			|				Analysts.Premise AS Premise,
			|				Analysts.Series AS Series
			|			FROM
			|				AnalystsGoodsInWarehouses AS Analysts
			|			)) AS ProductStock
			|WHERE
			|	ProductStock.InStockBalance > 0
			|INDEX BY
			|	ControlledLotReference, Products, Characteristic, Warehouse, Purpose, Series";
			
	Else
		
		Text =
			"SELECT
			|	Set.ControlledLotReference AS ControlledLotReference,
			|	Set.Products AS Products,
			|	Set.Characteristic AS Characteristic,
			|	Set.Warehouse AS Warehouse,
			|	Set.Purpose AS Purpose,
			|	Set.Premise AS Premise,
			|	Set.Series AS Series,
			|	SUM(Set.Count) AS Count
			|INTO ProductStock
			|FROM(
			|	SELECT
			|		ProductStock.ControlledLotReference AS ControlledLotReference,
			|		ProductStock.Products AS Products,
			|		ProductStock.Characteristic AS Characteristic,
			|		ProductStock.Warehouse AS Warehouse,
			|		ProductStock.Purpose AS Purpose,
			|		ProductStock.Premise AS Premise,
			|		ProductStock.Series AS Series,
			|		ProductStock.InStockBalance AS Count
			|	FROM
			|		AccumulationRegister.ProductStock.Balance(, (
			|				ControlledLotReference,
			|				Products,
			|				Characteristic,
			|				Warehouse,
			|				Purpose,
			|				Premise,
			|				Series)
			|			IN(
			|				SELECT
			|					Analysts.ControlledLotReference AS ControlledLotReference,
			|					Analysts.Products AS Products,
			|					Analysts.Characteristic AS Characteristic,
			|					Analysts.Warehouse AS Warehouse,
			|					Analysts.Purpose AS Purpose,
			|					Analysts.Premise AS Premise,
			|					Analysts.Series AS Series
			|				FROM
			|					AnalystsGoodsInWarehouses AS Analysts
			|				)) AS ProductStock
			|	WHERE
			|		ProductStock.InStockBalance <> 0
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		ProductStock.ControlledLotReference AS ControlledLotReference,
			|		ProductStock.Products AS Products,
			|		ProductStock.Characteristic AS Characteristic,
			|		ProductStock.Warehouse AS Warehouse,
			|		ProductStock.Purpose AS Purpose,
			|		ProductStock.Premise AS Premise,
			|		ProductStock.Series AS Series,
			|		CASE
			|			WHEN ProductStock.RecordType = VALUE(AccumulationRecordType.Receipt)
			|				THEN -ProductStock.InStock
			|			ELSE ProductStock.InStock
			|		END AS Count
			|	FROM
			|		AccumulationRegister.ProductStock AS ProductStock
			|	WHERE
			|		ProductStock.Recorder = &Recorder
			|		AND(
			|				ProductStock.ControlledLotReference,
			|				ProductStock.Products,
			|				ProductStock.Characteristic,
			|				ProductStock.Warehouse,
			|				ProductStock.Purpose,
			|				ProductStock.Premise,
			|				ProductStock.Series)
			|			IN(
			|				SELECT
			|					Analysts.ControlledLotReference AS ControlledLotReference,
			|					Analysts.Products AS Products,
			|					Analysts.Characteristic AS Characteristic,
			|					Analysts.Warehouse AS Warehouse,
			|					Analysts.Purpose AS Purpose,
			|					Analysts.Premise AS Premise,
			|					Analysts.Series AS Series
			|				FROM
			|					AnalystsGoodsInWarehouses AS Analysts)
			|				) AS Set
			|GROUP BY
			|	Set.ControlledLotReference,
			|	Set.Products,
			|	Set.Characteristic,
			|	Set.Warehouse,
			|	Set.Purpose,
			|	Set.Premise,
			|	Set.Series
			|HAVING
			|	SUM(Set.Count) > 0
			|INDEX BY
			|	ControlledLotReference, Products, Characteristic, Warehouse, Purpose, Series";
		
	EndIf;
	
	Texts.Add(Text);
	If Not AdjustingBalances Then
		
		Text =
			"SELECT
			|	GoodsForIssue.DocumentShipments AS DocumentShipments,
			|	GoodsForIssue.Products AS Products,
			|	GoodsForIssue.Characteristic AS Characteristic,
			|	GoodsForIssue.Warehouse AS Warehouse,
			|	GoodsForIssue.Purpose AS Purpose,
			|	GoodsForIssue.Series AS Series,
			|	GoodsForIssue.ToShipBalance + GoodsForIssue.InReserveBalance AS Count
			|INTO GoodsToShipWithoutLotReference
			|FROM
			|	AccumulationRegister.GoodsForIssue.Balance(, (
			|			Products,
			|			Characteristic,
			|			Warehouse,
			|			Purpose,
			|			Series)
			|		IN(
			|			SELECT
			|				Analysts.Products AS Products,
			|				Analysts.Characteristic AS Characteristic,
			|				Analysts.Warehouse AS Warehouse,
			|				Analysts.Purpose AS Purpose,
			|				Analysts.Series AS Series
			|			FROM
			|				AnalystsGoodsToShipWithoutLotReference AS Analysts
			|			)) AS GoodsForIssue
			|WHERE
			|	GoodsForIssue.ToShipBalance + GoodsForIssue.InReserveBalance > 0
			|INDEX BY
			|	Products, Characteristic, Warehouse, Purpose, Series";
		
	Else
		
		Text =
			"SELECT
			|	Set.DocumentShipments AS DocumentShipments,
			|	Set.Products AS Products,
			|	Set.Characteristic AS Characteristic,
			|	Set.Warehouse AS Warehouse,
			|	Set.Purpose AS Purpose,
			|	Set.Series AS Series,
			|	SUM(Set.Count) AS Count
			|INTO GoodsToShipWithoutLotReference
			|FROM(
			|	SELECT
			|		GoodsForIssue.DocumentShipments AS DocumentShipments,
			|		GoodsForIssue.Products AS Products,
			|		GoodsForIssue.Characteristic AS Characteristic,
			|		GoodsForIssue.Warehouse AS Warehouse,
			|		GoodsForIssue.Purpose AS Purpose,
			|		GoodsForIssue.Series AS Series,
			|		GoodsForIssue.ToShipBalance + GoodsForIssue.InReserveBalance AS Count
			|	FROM
			|		AccumulationRegister.GoodsForIssue.Balance(, (
			|				Products,
			|				Characteristic,
			|				Warehouse,
			|				Purpose,
			|				Series)
			|			IN(
			|				SELECT
			|					Analysts.Products AS Products,
			|					Analysts.Characteristic AS Characteristic,
			|					Analysts.Warehouse AS Warehouse,
			|					Analysts.Purpose AS Purpose,
			|					Analysts.Series AS Series
			|				FROM
			|					AnalystsGoodsToShipWithoutLotReference AS Analysts
			|				)) AS GoodsForIssue
			|	WHERE
			|		GoodsForIssue.ToShipBalance + GoodsForIssue.InReserveBalance <> 0
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		GoodsForIssue.DocumentShipments AS DocumentShipments,
			|		GoodsForIssue.Products AS Products,
			|		GoodsForIssue.Characteristic AS Characteristic,
			|		GoodsForIssue.Warehouse AS Warehouse,
			|		GoodsForIssue.Purpose AS Purpose,
			|		GoodsForIssue.Series AS Series,
			|		CASE
			|			WHEN GoodsForIssue.RecordType = VALUE(AccumulationRecordType.Receipt)
			|				THEN - GoodsForIssue.ToShip - GoodsForIssue.InReserve
			|			ELSE GoodsForIssue.ToShip + GoodsForIssue.InReserve
			|		END AS Count
			|	FROM
			|		AccumulationRegister.GoodsForIssue AS GoodsForIssue
			|	WHERE
			|		GoodsForIssue.Recorder = &Recorder
			|			AND(
			|				GoodsForIssue.Products,
			|				GoodsForIssue.Characteristic,
			|				GoodsForIssue.Warehouse,
			|				GoodsForIssue.Purpose,
			|				GoodsForIssue.Series)
			|			IN(
			|				SELECT
			|					Analysts.Products AS Products,
			|					Analysts.Characteristic AS Characteristic,
			|					Analysts.Warehouse AS Warehouse,
			|					Analysts.Purpose AS Purpose,
			|					Analysts.Series AS Series
			|				FROM
			|					AnalystsGoodsToShipWithoutLotReference AS Analysts)
			|				) AS Set
			|GROUP BY
			|	Set.DocumentShipments,
			|	Set.Products,
			|	Set.Characteristic,
			|	Set.Warehouse,
			|	Set.Purpose,
			|	Set.Series
			|HAVING
			|	SUM(Set.Count) > 0
			|INDEX BY
			|	Products, Characteristic, Warehouse, Purpose, Series";
			
	EndIf;
	
	Texts.Add(Text);
	Text =
		"SELECT
		|	ISNULL(MovementOfGoods_1.ControlledLotReference, TransferOrders.ControlledLotOfTheSender) AS ControlledLotReference,
		|	GoodsForIssue.Products AS Products,
		|	GoodsForIssue.Characteristic AS Characteristic,
		|	GoodsForIssue.Warehouse AS Warehouse,
		|	GoodsForIssue.Purpose AS Purpose,
		|	GoodsForIssue.Series AS Series,
		|	GoodsForIssue.Count AS Count
		|INTO GoodsForIssue
		|FROM
		|	GoodsToShipWithoutLotReference AS GoodsForIssue
		|		LEFT JOIN Document.TransferOrder AS TransferOrders
		|		ON TransferOrders.Ref = GoodsForIssue.DocumentShipments
		|		AND TransferOrders.LockedGoodsTransfer
		|		LEFT JOIN Document.InventoryTransfer AS MovementOfGoods_1
		|		ON MovementOfGoods_1.Ref = GoodsForIssue.DocumentShipments
		|		AND MovementOfGoods_1.LockedGoodsTransfer
		|		INNER JOIN AnalystsGoodsToShip AS Analysts
		|		ON Analysts.Products = GoodsForIssue.Products
		|		AND Analysts.Characteristic = GoodsForIssue.Characteristic
		|		AND Analysts.Warehouse = GoodsForIssue.Warehouse
		|		AND Analysts.Purpose = GoodsForIssue.Purpose
		|		AND Analysts.Series = GoodsForIssue.Series
		|		AND Analysts.ControlledLotReference = ISNULL(MovementOfGoods_1.ControlledLotReference, TransferOrders.ControlledLotOfTheSender)
		|INDEX BY
		|	ControlledLotReference, Products, Characteristic, Warehouse, Purpose, Series
		|;
		|///////////////////////////////////////////////////////////////////////////////////////
		|
		|DROP AnalystsGoodsInWarehouses
		|;
		|
		|///////////////////////////////////////////////////////////////////////////////////////
		|DROP AnalystsGoodsToShipWithoutLotReference
		|;
		|
		|///////////////////////////////////////////////////////////////////////////////////////
		|DROP GoodsToShipWithoutLotReference
		|;
		|
		|///////////////////////////////////////////////////////////////////////////////////////
		|DROP AnalystsGoodsToShip
		|;
		|
		|///////////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ProductStock.ControlledLotReference AS ControlledLotReference,
		|	ProductStock.Products AS Products,
		|	ProductStock.Characteristic AS Characteristic,
		|	ProductStock.Warehouse AS Warehouse,
		|	ProductStock.Purpose AS Purpose,
		|	ProductStock.Series AS Series,
		|	SUM(ProductStock.Count) AS Count
		|INTO GoodsInWarehousesAreSummarized
		|FROM
		|	ProductStock AS ProductStock
		|GROUP BY
		|	ProductStock.ControlledLotReference,
		|	ProductStock.Products,
		|	ProductStock.Characteristic,
		|	ProductStock.Warehouse,
		|	ProductStock.Purpose,
		|	ProductStock.Series
		|INDEX BY
		|	ControlledLotReference, Products, Characteristic, Warehouse, Purpose, Series";
		
	Texts.Add(Text);
	If Not AdjustingBalances Then
		
		Text =
			"SELECT
			|	InventoryAndDemands.OrderDocument AS ControlledLotReference,
			|	InventoryAndDemands.Products AS Products,
			|	InventoryAndDemands.Characteristic AS Characteristic,
			|	InventoryAndDemands.Warehouse AS Warehouse,
			|	InventoryAndDemands.Purpose AS Purpose,
			|	InventoryAndDemands.LockedInStockBalance
			|		- InventoryAndDemands.ReserveAtWarehouseFromLockedBalance
			|		- InventoryAndDemands.ReserveAtWarehouseFromLockedBalance AS Count
			|INTO InventoryAndDemands
			|FROM
			|	AccumulationRegister.InventoryAndDemands.Balance(, (
			|			OrderDocument,
			|			Products,
			|			Characteristic,
			|			Warehouse,
			|			Purpose)
			|		IN(
			|			SELECT
			|				Analysts.ControlledLotReference AS OrderDocument,
			|				Analysts.Products AS Products,
			|				Analysts.Characteristic AS Characteristic,
			|				Analysts.Warehouse AS Warehouse,
			|				Analysts.Purpose AS Purpose
			|			FROM
			|				InventoryAndDemandAnalysts AS Analysts
			|			)) AS InventoryAndDemands
			|WHERE
			|	InventoryAndDemands.LockedInStockBalance
			|		- InventoryAndDemands.ReserveAtWarehouseFromLockedBalance
			|		- InventoryAndDemands.ReserveAtWarehouseFromLockedBalance > 0
			|INDEX BY
			|	ControlledLotReference, Products, Characteristic, Warehouse, Purpose";
		
	Else
		
		Text =
			"SELECT
			|	Set.ControlledLotReference AS ControlledLotReference,
			|	Set.Products AS Products,
			|	Set.Characteristic AS Characteristic,
			|	Set.Warehouse AS Warehouse,
			|	Set.Purpose AS Purpose,
			|	SUM(Set.Count) AS Count
			|INTO InventoryAndDemands
			|FROM(
			|	SELECT
			|		InventoryAndDemands.OrderDocument AS ControlledLotReference,
			|		InventoryAndDemands.Products AS Products,
			|		InventoryAndDemands.Characteristic AS Characteristic,
			|		InventoryAndDemands.Warehouse AS Warehouse,
			|		InventoryAndDemands.Purpose AS Purpose,
			|		InventoryAndDemands.LockedInStockBalance
			|			- InventoryAndDemands.ReserveAtWarehouseFromLockedBalance
			|			- InventoryAndDemands.ReserveAtWarehouseFromLockedBalance AS Count
			|	FROM
			|		AccumulationRegister.InventoryAndDemands.Balance(, (
			|				OrderDocument,
			|				Products,
			|				Characteristic,
			|				Warehouse,
			|				Purpose)
			|			IN(
			|				SELECT
			|					Analysts.ControlledLotReference AS OrderDocument,
			|					Analysts.Products AS Products,
			|					Analysts.Characteristic AS Characteristic,
			|					Analysts.Warehouse AS Warehouse,
			|					Analysts.Purpose AS Purpose
			|				FROM
			|					InventoryAndDemandAnalysts AS Analysts
			|				)) AS InventoryAndDemands
			|	WHERE
			|		InventoryAndDemands.LockedInStockBalance
			|			- InventoryAndDemands.ReserveAtWarehouseFromLockedBalance
			|			- InventoryAndDemands.ReserveAtWarehouseFromLockedBalance <> 0
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		InventoryAndDemands.OrderDocument AS ControlledLotReference,
			|		InventoryAndDemands.Products AS Products,
			|		InventoryAndDemands.Characteristic AS Characteristic,
			|		InventoryAndDemands.Warehouse AS Warehouse,
			|		InventoryAndDemands.Purpose AS Purpose,
			|		CASE
			|			WHEN InventoryAndDemands.RecordType = VALUE(AccumulationRecordType.Receipt)
			|				THEN
			|					- InventoryAndDemands.LockedInStock
			|						+ InventoryAndDemands.ReserveAtWarehouseFromLocked
			|						+ InventoryAndDemands.ReserveAtWarehouseFromLocked
			|			ELSE
			|				InventoryAndDemands.LockedInStock
			|					- InventoryAndDemands.ReserveAtWarehouseFromLocked
			|					- InventoryAndDemands.ReserveAtWarehouseFromLocked
			|		END AS Count
			|	FROM
			|		AccumulationRegister.InventoryAndDemands AS InventoryAndDemands
			|	WHERE
			|		InventoryAndDemands.Recorder = &Recorder
			|			AND(
			|				InventoryAndDemands.OrderDocument,
			|				InventoryAndDemands.Products,
			|				InventoryAndDemands.Characteristic,
			|				InventoryAndDemands.Warehouse,
			|				InventoryAndDemands.Purpose)
			|			IN(
			|				SELECT
			|					Analysts.ControlledLotReference AS OrderDocument,
			|					Analysts.Products AS Products,
			|					Analysts.Characteristic AS Characteristic,
			|					Analysts.Warehouse AS Warehouse,
			|					Analysts.Purpose AS Purpose
			|				FROM
			|					InventoryAndDemandAnalysts AS Analysts)
			|				) AS Set
			|GROUP BY
			|	Set.ControlledLotReference,
			|	Set.Products,
			|	Set.Characteristic,
			|	Set.Warehouse,
			|	Set.Purpose
			|HAVING
			|	SUM(Set.Count) > 0
			|INDEX BY
			|	ControlledLotReference, Products, Characteristic, Warehouse, Purpose";
		
	EndIf;
	
	Texts.Add(Text);
	Text =
		"DROP InventoryAndDemandAnalysts
		|;
		|
		|///////////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	ProductStock.Warehouse AS Warehouse,
		|	ProductStock.Premise AS Premise
		|INTO WarehousesAndPremises
		|FROM
		|	ProductStock AS ProductStock";
		
	Texts.Add(Text);
	
	Text = QueryTextBinLocationWarehousing();
	
	Texts.Add(Text);
	Text =
		"DROP WarehousesAndPremises
		|;
		|
		|///////////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	ProductStock.Products AS Products,
		|	ProductStock.Characteristic AS Characteristic,
		|	ProductStock.Purpose AS Purpose,
		|	ProductStock.Warehouse AS Warehouse,
		|	ProductStock.Premise AS Premise,
		|	ProductStock.Series AS Series
		|INTO FilterItemsInCellsInWarehouses
		|FROM
		|	ProductStock AS ProductStock
		|		
		|		INNER JOIN AddressWarehousesAndPremises AS Filter
		|		ON Filter.Warehouse = ProductStock.Warehouse
		|		 AND Filter.Premise = ProductStock.Premise
		|INDEX BY
		|	Products, Characteristic, Purpose, Warehouse, Premise, Series
		|;
		|
		|///////////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	ProductStock.Products AS Products,
		|	ProductStock.Characteristic AS Characteristic,
		|	ProductStock.Purpose AS Purpose,
		|	ProductStock.Series AS Series
		|INTO FilterItemsInCells
		|FROM
		|	FilterItemsInCellsInWarehouses AS ProductStock
		|INDEX BY
		|	Products, Characteristic, Purpose, Series";
	
	Texts.Add(Text);
	If Not AdjustingBalances Then
		
		Text =
			"SELECT
			|	GoodsInStorageBins.Products AS Products,
			|	GoodsInStorageBins.Characteristic AS Characteristic,
			|	GoodsInStorageBins.Purpose AS Purpose,
			|	GoodsInStorageBins.Package AS Package,
			|	GoodsInStorageBins.Cell AS Cell,
			|	GoodsInStorageBins.Series AS Series,
			|	GoodsInStorageBins.InStockBalance - GoodsInStorageBins.ForPickingBalance AS Count
			|INTO GoodsInStorageBins
			|FROM
			|	AccumulationRegister.GoodsInStorageBins.Balance(, (
			|			Products,
			|			Characteristic,
			|			Purpose,
			|			Series)
			|		IN(
			|			SELECT
			|				Filter.Products AS Products,
			|				Filter.Characteristic AS Characteristic,
			|				Filter.Purpose AS Purpose,
			|				Filter.Series AS Series
			|			FROM
			|				FilterItemsInCells AS Filter
			|			)) AS GoodsInStorageBins
			|WHERE
			|	GoodsInStorageBins.InStockBalance - GoodsInStorageBins.ForPickingBalance > 0
			|INDEX BY
			|	Products, Characteristic, Purpose, Series, Cell";
			
	Else
		
		Text =
			"SELECT
			|	Set.Products AS Products,
			|	Set.Characteristic AS Characteristic,
			|	Set.Purpose AS Purpose,
			|	Set.Package AS Package,
			|	Set.Cell AS Cell,
			|	Set.Series AS Series,
			|	SUM(Set.Count) AS Count
			|INTO GoodsInStorageBins
			|FROM(
			|	SELECT
			|		GoodsInStorageBins.Products AS Products,
			|		GoodsInStorageBins.Characteristic AS Characteristic,
			|		GoodsInStorageBins.Purpose AS Purpose,
			|		GoodsInStorageBins.Package AS Package,
			|		GoodsInStorageBins.Cell AS Cell,
			|		GoodsInStorageBins.Series AS Series,
			|		GoodsInStorageBins.InStockBalance - GoodsInStorageBins.ForPickingBalance AS Count
			|	FROM
			|		AccumulationRegister.GoodsInStorageBins.Balance(, (
			|				Products,
			|				Characteristic,
			|				Purpose,
			|				Series)
			|			IN(
			|				SELECT
			|					Filter.Products AS Products,
			|					Filter.Characteristic AS Characteristic,
			|					Filter.Purpose AS Purpose,
			|					Filter.Series AS Series
			|				FROM
			|					FilterItemsInCells AS Filter
			|				)) AS GoodsInStorageBins
			|	WHERE
			|		GoodsInStorageBins.InStockBalance - GoodsInStorageBins.ForPickingBalance <> 0
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		GoodsInStorageBins.Products AS Products,
			|		GoodsInStorageBins.Characteristic AS Characteristic,
			|		GoodsInStorageBins.Purpose AS Purpose,
			|		GoodsInStorageBins.Package AS Package,
			|		GoodsInStorageBins.Cell AS Cell,
			|		GoodsInStorageBins.Series AS Series,
			|		CASE
			|			WHEN GoodsInStorageBins.RecordType = VALUE(AccumulationRecordType.Receipt)
			|				THEN - GoodsInStorageBins.InStock + GoodsInStorageBins.ForPicking
			|			ELSE GoodsInStorageBins.InStock - GoodsInStorageBins.ForPicking
			|		END AS Count
			|	FROM
			|		AccumulationRegister.GoodsInStorageBins AS GoodsInStorageBins
			|	WHERE
			|		GoodsInStorageBins.Recorder = &Recorder
			|			AND(
			|				GoodsInStorageBins.Products,
			|				GoodsInStorageBins.Characteristic,
			|				GoodsInStorageBins.Purpose,
			|				GoodsInStorageBins.Series)
			|			IN(
			|				SELECT
			|					Filter.Products AS Products,
			|					Filter.Characteristic AS Characteristic,
			|					Filter.Purpose AS Purpose,
			|					Filter.Series AS Series
			|				FROM
			|					FilterItemsInCells AS Filter)
			|				) AS Set
			|GROUP BY
			|	Set.Products,
			|	Set.Characteristic,
			|	Set.Purpose,
			|	Set.Series,
			|	Set.Package,
			|	Set.Cell
			|HAVING
			|	SUM(Set.Count) > 0
			|INDEX BY
			|	Products, Characteristic, Purpose, Series, Cell";
		
	EndIf;
	
	Texts.Add(Text);
	Text =
		"DROP FilterItemsInCells
		|;
		|
		|///////////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	GoodsInStorageBins.Products AS Ref
		|FROM
		|	GoodsInStorageBins AS GoodsInStorageBins
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Filter.Products AS Products,
		|	Filter.Characteristic AS Characteristic,
		|	Filter.Purpose AS Purpose,
		|	Filter.Warehouse AS Warehouse,
		|	Filter.Premise AS Premise,
		|	Filter.Series AS Series,
		|	GoodsInStorageBins.Cell AS Cell,
		|	GoodsInStorageBins.Package AS Package,
		|	ISNULL(GoodsInStorageBins.Package.PackageType = VALUE(Enum.TypesOfItemsPackages.CargoItem), FALSE) AS ItIsACargoItem,
		|	GoodsInStorageBins.Count AS Count,
		|	GoodsInStorageBins.Count * ISNULL(&RequestTextForPackingCoefficient, 1) AS QuantityOfUnits
		|FROM
		|	FilterItemsInCellsInWarehouses AS Filter
		|		INNER JOIN GoodsInStorageBins AS GoodsInStorageBins
		|		ON GoodsInStorageBins.Products = Filter.Products
		|		 AND GoodsInStorageBins.Characteristic = Filter.Characteristic
		|		 AND GoodsInStorageBins.Purpose = Filter.Purpose
		|		 AND GoodsInStorageBins.Series = Filter.Series
		|		 AND GoodsInStorageBins.Cell.Owner = Filter.Warehouse
		|		 AND GoodsInStorageBins.Cell.Premise = Filter.Premise
		|ORDER BY
		|	Products, Characteristic, Purpose, Series, Warehouse, Premise, Package, Cell
		|;
		|
		|///////////////////////////////////////////////////////////////////////////////////////
		|DROP FilterItemsInCellsInWarehouses;
		|DROP GoodsInStorageBins
		|;
		|
		|///////////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ProductStock.ControlledLotReference AS ControlledLotReference,
		|	ProductStock.Products AS Products,
		|	ProductStock.Characteristic AS Characteristic,
		|	ProductStock.Warehouse AS Warehouse,
		|	ProductStock.Purpose AS Purpose,
		|	ProductStock.Series AS Series,
		|	ProductStock.Premise AS Premise,
		|	NOT AddressWarehousesAndPremises.Warehouse IS NULL AS ToSelectCells,
		|	
		|	ISNULL(InventoryAndDemands.Count, 0) AS ItemControl,
		|	
		|	ISNULL(GoodsInWarehousesAreSummarized.Count, 0)
		|		- ISNULL(GoodsForIssue.Count, 0) AS ControlBatch,
		|	
		|	ProductStock.Count AS Count,
		|	VALUE(Catalog.StorageBins.EmptyRef) AS Cell,
		|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package
		|FROM
		|	ProductStock AS ProductStock
		|		
		|		LEFT JOIN GoodsForIssue AS GoodsForIssue
		|		ON GoodsForIssue.ControlledLotReference = ProductStock.ControlledLotReference
		|		 AND GoodsForIssue.Products = ProductStock.Products
		|		 AND GoodsForIssue.Characteristic = ProductStock.Characteristic
		|		 AND GoodsForIssue.Warehouse = ProductStock.Warehouse
		|		 AND GoodsForIssue.Purpose = ProductStock.Purpose
		|		 AND GoodsForIssue.Series = ProductStock.Series
		|		
		|		LEFT JOIN GoodsInWarehousesAreSummarized AS GoodsInWarehousesAreSummarized
		|		ON GoodsInWarehousesAreSummarized.ControlledLotReference = ProductStock.ControlledLotReference
		|		 AND GoodsInWarehousesAreSummarized.Products = ProductStock.Products
		|		 AND GoodsInWarehousesAreSummarized.Characteristic = ProductStock.Characteristic
		|		 AND GoodsInWarehousesAreSummarized.Warehouse = ProductStock.Warehouse
		|		 AND GoodsInWarehousesAreSummarized.Purpose = ProductStock.Purpose
		|		 AND GoodsInWarehousesAreSummarized.Series = ProductStock.Series
		|		
		|		LEFT JOIN InventoryAndDemands AS InventoryAndDemands
		|		ON InventoryAndDemands.ControlledLotReference = ProductStock.ControlledLotReference
		|		 AND InventoryAndDemands.Products = ProductStock.Products
		|		 AND InventoryAndDemands.Characteristic = ProductStock.Characteristic
		|		 AND InventoryAndDemands.Warehouse = ProductStock.Warehouse
		|		 AND InventoryAndDemands.Purpose = ProductStock.Purpose
		|		
		|		LEFT JOIN AddressWarehousesAndPremises AS AddressWarehousesAndPremises
		|		ON AddressWarehousesAndPremises.Warehouse = ProductStock.Warehouse
		|		 AND AddressWarehousesAndPremises.Premise = ProductStock.Premise
		|WHERE
		|	&ExcludeOverridableApplications
		|ORDER BY
		|	ControlledLotReference, Products, Characteristic, Purpose, Warehouse, Series, Premise
		|;
		|
		|///////////////////////////////////////////////////////////////////////////////////////
		|DROP ProductStock;
		|DROP GoodsForIssue;
		|DROP GoodsInWarehousesAreSummarized;
		|DROP InventoryAndDemands;
		|DROP AddressWarehousesAndPremises";
	RequestTextForPackingCoefficient = Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"GoodsInStorageBins.Package", "GoodsInStorageBins.Products");
	Text = StrReplace(Text, "&RequestTextForPackingCoefficient", RequestTextForPackingCoefficient);
	Texts.Add(Text);
	
	Text = StrConcat(Texts, Common.QueryBatchSeparator());
	If ExcludeControlRequests Then
		
		ExcludeOverridableApplications =
			"VALUETYPE(ProductStock.ControlledLotReference.Lot) <> TYPE(Document.RequestForGoodsQualityControl)"; // @query-part-1
	Else
		ExcludeOverridableApplications = "TRUE"; // @query-part-1
	EndIf;
	Text = StrReplace(Text, "&ExcludeOverridableApplications", ExcludeOverridableApplications);
	Query = New Query();
	Query.Text = Text;
	Query.SetParameter("Analysts", Analysts);
	Query.SetParameter("Date", Date);
	Query.SetParameter("Recorder", Recorder);
	ResultsPackage = Query.ExecuteBatch();
	
	ListOfItems = ResultsPackage[ResultsPackage.UBound() - 9].Unload().UnloadColumn("Ref");
	ProductLocations = ProductLocationsAccordingToItemList(ListOfItems);
	
	Cells = ResultsPackage[ResultsPackage.UBound() - 8].Unload();
	Table = ResultsPackage[ResultsPackage.UBound() - 5].Unload();
	Table.Columns.Add("Delete", New TypeDescription("Boolean"));
	NumberType = Common.TypeDescriptionNumber(15, 3, AllowedSign.Nonnegative);
	Table.Columns.Add("NumberOfPackages", NumberType);
	TotalRows = Table.Count();
	
	ControlledLotReference = Undefined;
	Products = Undefined;
	Characteristic = Undefined;
	Warehouse = Undefined;
	Purpose = Undefined;
	Series = Undefined;
	For IndexOf = 0 To TotalRows - 1 Do
		
		TableRow = Table[IndexOf];
		
		ItemHasChanged = False;
		BatchHasChanged = False;
		If ControlledLotReference <> TableRow.ControlledLotReference Then
			ControlledLotReference = TableRow.ControlledLotReference;
			ItemHasChanged = True;
		EndIf;
		If Products <> TableRow.Products Then
			Products = TableRow.Products;
			ItemHasChanged = True;
		EndIf;
		If Characteristic <> TableRow.Characteristic Then
			Characteristic = TableRow.Characteristic;
			ItemHasChanged = True;
		EndIf;
		If Warehouse <> TableRow.Warehouse Then
			Warehouse = TableRow.Warehouse;
			ItemHasChanged = True;
		EndIf;
		If Purpose <> TableRow.Purpose Then
			Purpose = TableRow.Purpose;
			ItemHasChanged = True;
		EndIf;
		If Series <> TableRow.Series Then
			Series = TableRow.Series;
			BatchHasChanged = True;
		EndIf;
		BatchHasChanged = BatchHasChanged Or ItemHasChanged;
		
		If ItemHasChanged Then
			ItemControl = TableRow.ItemControl;
		EndIf;
		
		If BatchHasChanged Then
			ControlBatch = TableRow.ControlBatch;
		EndIf;
		
		If FillInWithGoodsOfProvenQuality Then
			TableRow.Count = Min(ControlBatch, TableRow.Count);
		Else
			TableRow.Count = Min(ControlBatch, ItemControl, TableRow.Count);
		EndIf;
		TableRow.NumberOfPackages = TableRow.Count;
		ControlBatch = ControlBatch - TableRow.Count;
		ItemControl = ItemControl - TableRow.Count;
		
		TableRow.Delete = TableRow.Count = 0;
		
	EndDo;
	
	Columns = "ControlledLotReference,Products,Characteristic,Warehouse,
		|Purpose,Series,Premise,Cell,Package,Count,NumberOfPackages";
	
	Result = Table.Copy(New Array(), Columns);
	Var_Key = "Products,Characteristic,Purpose,Series,Warehouse,Premise";
	FilterByKey = New Structure(Var_Key);
	Cells.Indexes.Add(Var_Key);
	Table.Columns.Add("QuantityKit",
		Common.TypeDescriptionNumber(15, 3, AllowedSign.Nonnegative));
	
	MaxIndex_ = Table.Count() - 1;
	Kit = New Map();
	For IndexOf = 0 To MaxIndex_ Do
		
		TableRow = Table[IndexOf];
		If TableRow.Delete Then
			Continue;
		EndIf;
		If Not TableRow.ToSelectCells Then
			FillPropertyValues(Result.Add(), TableRow); // Adding a line
			Continue;
		EndIf;
		
		FillPropertyValues(FilterByKey, TableRow);
		FoundRows = Cells.FindRows(FilterByKey);
		MaxCellIndex = FoundRows.Count() - 1;
		ThereAreCommodityPlaces = False;
		For CellIndex = 0 To MaxCellIndex Do
			CellRow = FoundRows[CellIndex];
			If Not CellRow.ItIsACargoItem Then
				Count = Min(TableRow.Count, CellRow.QuantityOfUnits);
				TableRow.Count = TableRow.Count - Count;
				If Count = 0 Then
					Continue;
				EndIf;
				NewRow = Result.Add(); // Adding a line
				FillPropertyValues(NewRow, CellRow);
				NewRow.ControlledLotReference = TableRow.ControlledLotReference;
				NewRow.Count = Count;
			Else
				ThereAreCommodityPlaces = True;
			EndIf;
		EndDo;
		
		// Product locations.
		Products = ProductLocations.Get(TableRow.Products);
		If TableRow.Count > 0 And ThereAreCommodityPlaces And Products <> Undefined Then
			
			Kit.Clear();
			For Each Package In Products Do
				Kit.Insert(Package.Key, 0);
			EndDo;
			
			// We determine the number of whole sets.
			KitCount = 0;
			For CellIndex = 0 To MaxCellIndex Do
				CellRow = FoundRows[CellIndex];
				If Not CellRow.ItIsACargoItem Then
					Continue;
				EndIf;
				
				Count = Kit.Get(CellRow.Package);
				If Count <> Undefined Then
					KitCount = Count + CellRow.Count * Products[CellRow.Package];
					Kit.Insert(CellRow.Package, KitCount);
				EndIf;
				
			EndDo;
			For Each Package In Kit Do
				KitCount = Min(KitCount, Package.Value);
			EndDo;
			
			TotalNumberOfKits = Min(TableRow.Count, KitCount);
			TableRow.Count = TableRow.Count - TotalNumberOfKits;
			
			// We collect kits from packages.
			For Each Package In Kit Do
				Kit.Insert(Package.Key, ?(Products[Package.Key] = 0, 0, TotalNumberOfKits / Products[Package.Key]));
			EndDo;
			For CellIndex = 0 To MaxCellIndex Do
				CellRow = FoundRows[CellIndex];
				If Not CellRow.ItIsACargoItem Then
					Continue;
				EndIf;
				
				Count = Kit.Get(CellRow.Package);
				If Count <> Undefined And Count > 0 Then
					CurrentQuantity = Min(Count, CellRow.Count);
					Kit.Insert(CellRow.Package, Count - CurrentQuantity);
					NewRow = Result.Add(); // Adding a line
					FillPropertyValues(NewRow, CellRow);
					NewRow.ControlledLotReference = TableRow.ControlledLotReference;
					NewRow.Count = CurrentQuantity * Products[CellRow.Package];
				EndIf;
				
			EndDo;
			
		EndIf;
		
		If TableRow.Count > 0 Then
			FillPropertyValues(Result.Add(), TableRow); // Adding a line
		EndIf;
		
	EndDo;
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	BatchProcessingOfTablePartServer.TreatTS(Result, StructureOfActions, Undefined);
	Return Result;
	
EndFunction

// Using the link to the Lot reference object, it determines the warehouse analytics
// for which Balances should be obtained in order to fill in data on the number of Lot Reference items in the warehouse.
//  Parameters:
//   FillingData - DefinedType.QualityControlLot
//  Returns:
//   ValueTable - table with fields:
//    * Products - CatalogRef.Products - The item of the item of the Lot reference.
//    * Characteristic - CatalogRef.ItemsCharacteristics - characteristics of the item of the Lot reference.
//    * Warehouse - CatalogRef.Warehouses - the warehouse where the item of the Lot reference is located.
//    * Purpose - CatalogRef.Assignments - the destination for which the item of the Lot reference is intended.
//    * ControlledLotReference - CatalogRef.ControlledLots - The Lot reference of the item for which there are Balances of the blocked item.
//    * Series - CatalogRef.ItemsBatches - Batch of item Lot reference.
//    * Premise - CatalogRef.Warerooms - the room in which the item of the Lot reference is located.
Function AnalystsOfReceivedGoods(FillingData) Export
	
	CorrectedDocument = DocumentCorrection.CorrectedDocument(FillingData);
	Ref = ?(CorrectedDocument = Undefined, FillingData, CorrectedDocument);
	
	Query = New Query();
	Query.Text =
		"SELECT
		|	Lots.Ref AS Ref
		|FROM
		|	Catalog.ControlledLots AS Lots
		|WHERE
		|	Lots.Lot = &Ref";
	Query.SetParameter("Ref", Ref);
	Selection = Query.Execute().Select();
	ControlledLotReferenceBase = Undefined;
	If Selection.Next() Then
		ControlledLotReferenceBase = Selection.Ref;
	EndIf;
	Query.SetParameter("ControlledLotReference", ControlledLotReferenceBase);
	Query.Text =
		"SELECT ALLOWED DISTINCT
		|	Goods.ControlledLotReference AS ControlledLotReference,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Purpose AS Purpose,
		|	Goods.Premise AS Premise,
		|	Goods.Series AS Series
		|FROM
		|	AccumulationRegister.ProductStock.Balance(, ControlledLotReference = &ControlledLotReference) AS Goods
		|WHERE
		|	Goods.InStockBalance > 0";
	Analysts = Query.Execute().Unload();
	
Return Analysts;

EndFunction

// Adds a selection for setting the Conditional appearance of quality Attributes
// Parameters:
//  Filters - Array of See QualityControl.AddFilter
//  DataPath - String -
//  Value - String,Number -
//  Var_ComparisonType - DataCompositionComparisonType
Procedure AddFilter(Filters, DataPath, Value, Var_ComparisonType = Undefined) Export
	
	TypeOfComparisonIsCurrent = ?(Var_ComparisonType = Undefined, DataCompositionComparisonType.Equal, Var_ComparisonType);
	Filters.Add(New Structure("DataPath,Value,ComparisonType", DataPath, Value, TypeOfComparisonIsCurrent));
	
EndProcedure

// Forms the structure of fields for Conditional appearance in the form.
// Parameters:
//  ElementToCheckQuality - FormField - form field associated with the Quality control Attribute
//  ElementDateOfQualityConfirmation - FormField - the form field associated with the Attribute of the Quality confirmation data
// Returns:
//  Structure - structure with fields:
//   * ToControlQuality - FormField - form field associated with the Quality control Attribute
//   * QualityConfirmationDate - FormField - the form field associated with the Attribute of the Quality confirmation data
Function Fields(ElementToCheckQuality, ElementDateOfQualityConfirmation) Export
	
	Return New Structure("ToControlQuality,QualityConfirmationDate",
		ElementToCheckQuality, ElementDateOfQualityConfirmation);
	
EndFunction

// Adds elements of the design of quality control Attributes to the Conditional appearance of the form.
//  Parameters:
//   ConditionalAppearance - DataCompositionConditionalAppearance - the Conditional appearance of the form property
//   Fields - See QualityControl.Fields
//   FlagDisabled - Array of See QualityControl.AddFilter
//   DateIsOptional - Array of See QualityControl.AddFilter
Procedure SetupAppearance(ConditionalAppearance, Fields, FlagDisabled = Undefined, DateIsOptional = Undefined) Export
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Fields.QualityConfirmationDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(Fields.ToControlQuality.DataPath);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	If FlagDisabled <> Undefined And  FlagDisabled.Count() > 0 Then
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Fields.ToControlQuality.Name);
		
		FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
		FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
		
			For Each FilterElement In FlagDisabled Do
				ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
				ItemFilter.LeftValue = New DataCompositionField(FilterElement.DataPath);
				ItemFilter.ComparisonType = FilterElement.ComparisonType;
				ItemFilter.RightValue = FilterElement.Value;
			EndDo;
			
		Item.Appearance.SetParameterValue("ReadOnly", True);
		
	EndIf;
	
	If DateIsOptional <> Undefined And DateIsOptional.Count() > 0 Then
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Fields.QualityConfirmationDate.Name);
		
		FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
		FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
		
		For Each FilterElement In DateIsOptional Do
			ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField(FilterElement.DataPath);
			ItemFilter.ComparisonType = FilterElement.ComparisonType;
			ItemFilter.RightValue = FilterElement.Value;
		EndDo;
		
		Item.Appearance.SetParameterValue("MarkIncomplete", False);
		
	EndIf;
	
EndProcedure

// Sets the Conditional appearance of quality Attributes in documents. where the controlled Lot reference is specified explicitly.
// Parameters:
//  ConditionalAppearance - DataCompositionConditionalAppearance - conditional form design
//  Field - FormField - the field associated with the Quality control Attribute
Procedure ConditionalAppearanceOfDateOfConfirmationOfQualityOfSurplus(ConditionalAppearance, Field) Export
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Field.Name);
	
	OrGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.SubjectToUnlocking");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ControlledLotReference");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Text", NStr("ru = '<только для партий, подлежащих разблокировке>';
													|vi = '<only for lots to be unlocked>';
													|en = '<only for lots to be unlocked>'; fa = '<only for lots to be unlocked>';
													|it = '<only for lots to be unlocked>';
													|pl = '<only for lots to be unlocked>';
													|tr = '<sadece kilidi açılacak lotlar için>'"));
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
EndProcedure

// Serves the user's interactive work with quality control documents (act and application).
// Defines the warehouse and premises in the header of the document according to the data in the table part. If the Attribute value is the same in the table part, then it is filled in with this value in the header, otherwise it is empty.
// Parameters:
//  Object - FormDataStructure - The Attribute of the form associated with the document of the quality control of goods or the application for quality control of goods
Procedure FillCleanWarehouseRoomAccordingToTabularPartOfDocument(Object) Export
	
	If Object.Goods.Count() = 0 Then
		Return;
	EndIf;
	Object.Warehouse = Object.Goods[0].Warehouse;
	Object.Premise = Object.Goods[0].Premise;
	For IndexOf = 1 To Object.Goods.Count() - 1 Do
		If Object.Goods[IndexOf].Warehouse <> Object.Warehouse Then
			Object.Warehouse = Catalogs.Warehouses.EmptyRef();
		EndIf;
		If Object.Goods[IndexOf].Premise <> Object.Premise Then
			Object.Premise = Catalogs.Warerooms.EmptyRef();
		EndIf;
	EndDo;
	
EndProcedure

// Procedure for use in object modules when creating documents based on a quality control report.
// Checks whether creation is allowed based on the data of the report. If not, it raises an exception.
// Parameters:
//  HeaderAttributes - Structure - structure with fields:
//   * Status - EnumRef.StatusesOfQualityControlCertificates - The Status of the quality control act.
Procedure RaiseExceptionWhenCreatingBasedOnAct(HeaderAttributes) Export
	
	If HeaderAttributes.Status = Enums.StatusesOfQualityControlCertificates.InProgress Then
		
		ErrorText = StrTemplate(NStr("ru = 'Для выполнения команды необходимо установить статус ""%1"" или ""%2"".';
									|vi = 'To run the command, set the ""%1"" or ""%2"" status.';
									|en = 'To run the command, set the ""%1"" or ""%2"" status.'; fa = 'To run the command, set the ""%1"" or ""%2"" status.';
									|it = 'To run the command, set the ""%1"" or ""%2"" status.';
									|pl = 'To run the command, set the ""%1"" or ""%2"" status.';
									|tr = 'Komutu gerçekleştirmek için durumun "" %1 "" veya "" %2 "" olarak ayarlanması gerekiyor.'"),
			Enums.StatusesOfQualityControlCertificates.AwaitingDecision,
			Enums.StatusesOfQualityControlCertificates.IsProcessed);
		Raise ErrorText;
		
	EndIf;
	
EndProcedure

// Initializes the parameters of the structure to describe the variant of processing the tabular part associated with a specific algorithm of the mechanism's actions.
// Parameters:
//  ActionName - String - ID of the algorithm for processing the table part.
// Returns:
//  Structure - structure with fields:
//   * ReadableFields - String - The fields of the table part that will be transferred from the client to the server in the processing of the table part.
//   * EditableFields - String - Table part fields to be filled in by the table part handler.
//   * QueryOptions - Structure - Parameters of the request to receive data required for batch processing of strings.
//   * OverridableProcessingInObjectManager - Boolean - If true, you can override the processing in the object manager module.
//   * KeyDetailsOfHeader - Structure - Contains data of the object header, the change of which requires processing of rows, as it may lead
//                                          to changes in the data generated by the batch processing request. It is necessary to generate such data only
//                                          if it is not specified in the parameter of the query parameter.
//   * FullObjectName - String - the full name of the metadata object in which the table part will be processed.
//   * QueryText - String,Undefined - The Query Text of the data required for batch processing of strings.
//   * UseGoodsQualityControl - Boolean - The service one that does not require redefinition Inside the mechanism at server will be reset if the functional option
//                                                    of using item quality control is turned off, which will result in processing not being performed.
Function New_ActionParameters(ActionName) Export
	
	ActionParameters = New Structure();
	QueryOptions = New Structure();
	ActionParameters.Insert("ReadableFields", "");
	ActionParameters.Insert("EditableFields", "");
	ActionParameters.Insert("QueryOptions", QueryOptions);
	ActionParameters.Insert("OverridableProcessingInObjectManager", False);
	ActionParameters.Insert("KeyDetailsOfHeader", New Structure());
	ActionParameters.Insert("FullObjectName", "");
	ActionParameters.Insert("QueryText", Undefined); // if you need to completely redefine the logic.
	ActionParameters.Insert("UseGoodsQualityControl", True);
	
	If ActionName = "FillInCheckQualityDateOfQualityConfirmation" Then
		
		// When changing the readable fields of the table part, it is necessary to call the action processing for the row of the table part.
		// When changing the request parameters and key Attributes of the header, it is necessary to cause
		// the cache of action parameters to be updated and the action to be processed for the entire table part.
		
		ActionParameters.ReadableFields = "Products,Warehouse";
		ActionParameters.EditableFields = "ToControlQuality,QualityConfirmationDate";
		ActionParameters.Insert("QueryTextDocumentData", Undefined);
		// Undefined means the following query text:
		//	"SELECT
		//	|T table.ID of THE line AS ID OF THE line,
		//	|T table.Nomenclature AS A Nomenclature,
		//	|T table.Warehouse AS A Warehouse,
		//	|	&Quality Control Agreement AS A Contract,
		//	|	&Monitoring the quality of dataprosses AS dataprosses,
		//	|T Lay out HOW to Install,
		//	|T Add HOW TO Reset
		//	|PUT THE data in the DOCUMENT to fill in the quality control DATACONFIRMATION of quality
		//	|FROM
		//	|	#Data sourcesdata AS A Table
		//	|INDEX BY
		//	|Nomenclature,Warehouse,Contract";
		
		QueryOptions.Insert("QualityControlContract");
		QueryOptions.Insert("QualityControlDateOfReceipt", '00010101');
		
	ElsIf ActionName = "FillInUnblockableDateOfQualityConfirmation" Then
		
		ActionParameters.ReadableFields = "Products,ControlledLotReference";
		ActionParameters.EditableFields = "ControlledLotReference,SubjectToUnlocking,QualityConfirmationDate";
		
		ActionParameters.Insert("QueryTextDocumentData", Undefined);
		// Undefined means the following query text:
		//	"SELECT
		//	|T table.ID of THE line AS ID OF THE line,
		//	|T table.Nomenclature AS A Nomenclature,
		//	|T table.Controlled PARTY AS A Controlled Party,
		//	|	&Monitoring the quality of the blockingdataracessinetdatesapproachments of the party AS data accesses,
		//	|	&Quality Control Install HOW To Install,
		//	|	&Quality Control Reset HOW TO Reset
		//	|PUT THE data in the DOCUMENT to fill it out, there will be A blockage of the Quality confirmation data
		//	|FROM
		//	|	#Data sourcesdata AS A Table
		//	|INDEX BY
		//	|Nomenclature";
		
		QueryOptions.Insert("QualityControlDateOfUnblockingIfThereIsNoDateOfReceiptOfLotReference", '00010101');
		QueryOptions.Insert("QualityControlReset", False);
		QueryOptions.Insert("QualityControlSet", False);
		
	ElsIf ActionName = "FillInSenderSControlledLotReference" Then
		
	EndIf;
	
	Return ActionParameters;
	
EndFunction

#EndRegion

#Region Internal

Function UpdateActionParameters(ManagerModule, Object, ParametersCache, Forcibly = False) Export
	
	Result = False;
	
	NewCache = ManagerModule.QualityControlActionParameters(Object);
	DisableIfFOIsDisabled(NewCache);
	NewActionParameters = QualityControlClientServer.CacheByKey(NewCache, ParametersCache.Key);
	
	For Each Item In NewActionParameters Do
			
			If Item.Key = "Key" Then
				Continue;
			EndIf;
			For Each QueryParameter In Item.Value.QueryOptions Do
				
				If ParametersCache[Item.Key].QueryOptions[QueryParameter.Key]
						<> QueryParameter.Value Then
					Result = True;
					Break;
				EndIf;
				
			EndDo;
			
			If Result Then
				Break;
			EndIf;
			
			For Each KeyDetailsOfHeader In Item.Value.KeyDetailsOfHeader Do
				
				If ParametersCache[Item.Key].KeyDetailsOfHeader[KeyDetailsOfHeader.Key]
						<> KeyDetailsOfHeader.Value Then
					Result = True;
					Break;
				EndIf;
				
			EndDo;
			
			If Result Then
				Break;
			EndIf;
			
	EndDo;
	
	For Each Property In NewActionParameters Do
		ParametersCache[Property.Key] = Property.Value;
	EndDo;
	
	Return Result Or Forcibly;
	
EndFunction

Procedure BatchProcessingToSupplementDataSourceQualityControl(Actions, QueryDetails, CachedValues) Export
	
	Var Action_Parameters;
	QueriesTexts = QueryDetails.QueriesTexts; // ValueList
	
	Added_Texts = New ValueList();
	UseTypicalLogicForCalculatingDates = False;
	
	If BatchProcessingOfTablePartServer.YouNeedToPerformAction(
			"FillInCheckQualityDateOfQualityConfirmation",
			Actions,
			CachedValues,
			Action_Parameters) Then
		
		ActionParameters = Action_Parameters["FillInCheckQualityDateOfQualityConfirmation"];
		
		QueryTextDocumentData = ActionParameters.QueryTextDocumentData;
		QueryText = ActionParameters.QueryText;
		
		If QueryText = Undefined Then
			
			UseTypicalLogicForCalculatingDates = True;
			
			If QueryTextDocumentData = Undefined Then
				
				Text =
					"SELECT
					|	Table.IdOfTTRow AS IdOfTTRow,
					|	Table.Products AS Products,
					|	Table.Warehouse AS Warehouse,
					|	&QualityControlContract AS Contract,
					|	&QualityControlDateOfReceipt AS DateOfReceipt,
					|	FALSE AS Set,
					|	FALSE AS Reset
					|INTO DataOfDocumentToBeFilledInCheckQualityDateOfQualityConfirmation
					|FROM
					|	#DataSource AS Table
					|INDEX BY
					|	Products,Warehouse,Contract";
					
			Else
				
				Text = QueryTextDocumentData;
				
			EndIf;
			Text = StrReplace(Text, "#DataSource", "TTDataSource");
			
			Added_Texts.Add(Text);
			
			Text =
				"SELECT
				|	Table.IdOfTTRow AS IdOfTTRow,
				|	NOT ControlledItem.Ref IS NULL
				|		AND NOT QualityControlWarehouses.Ref IS NULL
				|		AND ContractsWithQualityAssurance.Ref IS NULL
				|		AND NOT Table.Reset
				|	OR Table.Set
				|		AND NOT Table.Reset AS ToControlQuality,
				|	CASE
				|		WHEN ControlledItem.Ref IS NULL
				|				OR QualityControlWarehouses.Ref IS NULL
				|				OR NOT ContractsWithQualityAssurance.Ref IS NULL
				|				OR Table.Reset
				|			THEN DATETIME(1, 1, 1)
				|		WHEN Table.DateOfReceipt = DATETIME(1, 1, 1)
				|			THEN DATETIME(1, 1, 1)
				|		WHEN CalculationOfQualityControlPeriodOverridable.DateFound > DATETIME(1, 1, 1)
				|			THEN CalculationOfQualityControlPeriodOverridable.DateFound
				|		ELSE DATEADD(Table.DateOfReceipt, DAY, ControlledItem.TermOfQualityControl)
				|	END AS QualityConfirmationDate
				|FROM
				|	DataOfDocumentToBeFilledInCheckQualityDateOfQualityConfirmation AS Table
				|		LEFT JOIN Catalog.Products AS ControlledItem
				|		ON ControlledItem.Ref  = Table.Products
				|		AND ControlledItem.ControlQualityOfReceivedGoods
				|		LEFT JOIN Catalog.Warehouses AS QualityControlWarehouses
				|		ON QualityControlWarehouses.Ref  = Table.Warehouse
				|		AND QualityControlWarehouses.ControlQualityOfReceivedGoods
				|		LEFT JOIN Catalog.CounterpartyContracts AS ContractsWithQualityAssurance
				|		ON ContractsWithQualityAssurance.Ref = Table.Contract
				|		AND ContractsWithQualityAssurance.GoodsQualityIsGuaranteedByVendor
				|		LEFT JOIN CalculationOfQualityControlPeriodOverridable ON TRUE";
			
			Substitutions = ProvisionInDocumentsServer.AddToDateAccordingToEnterpriseCalendar(
				"Table.DateOfReceipt",
				"ControlledItem.TermOfQualityControl");
			
			Text = StrReplace(Text, "CalculationOfQualityControlPeriodOverridable.DateFound", Substitutions.Field);
			Text = StrReplace(Text, "LEFT JOIN CalculationOfQualityControlPeriodOverridable ON TRUE", Substitutions.Joins);
			
			Added_Texts.Add(Text, "FillInCheckQualityDateOfQualityConfirmation");
			
		Else
			
			Added_Texts.Add(QueryText, "FillInCheckQualityDateOfQualityConfirmation");
			
		EndIf;
		
		QueryOptions = QueryDetails.QueryOptions; // Structure
		CommonClientServer.SupplementStructure(QueryOptions, ActionParameters.QueryOptions);
		
	EndIf;
	
	If BatchProcessingOfTablePartServer.YouNeedToPerformAction(
			"FillInUnblockableDateOfQualityConfirmation",
			Actions,
			CachedValues,
			Action_Parameters) Then
		
		ActionParameters = Action_Parameters["FillInUnblockableDateOfQualityConfirmation"];
		QueryTextDocumentData = ActionParameters.QueryTextDocumentData;
		QueryText = ActionParameters.QueryText;
		
		If QueryText = Undefined Then
			
			UseTypicalLogicForCalculatingDates = True;
			
			If QueryTextDocumentData = Undefined Then
				
				Text =
					"SELECT
					|	Table.IdOfTTRow AS IdOfTTRow,
					|	Table.Products AS Products,
					|	Table.ControlledLotReference AS ControlledLotReference,
					|	&QualityControlDateOfUnblockingIfThereIsNoDateOfReceiptOfLotReference AS DateOfReceipt,
					|	&QualityControlSet AS Set,
					|	&QualityControlReset AS Reset
					|INTO DataOfDocumentToBeFilledInMustBeUnblockedDateOfQualityConfirmation
					|FROM
					|	#DataSource AS Table
					|INDEX BY
					|	Products";
					
			Else
				
				Text = QueryTextDocumentData;
				
			EndIf;
			
			Text = StrReplace(Text, "#DataSource", "TTDataSource");
		
			Added_Texts.Add(Text);
			
			Text =
				"SELECT
				|	Table.IdOfTTRow AS IdOfTTRow,
				|	NOT Table.Reset
				|		AND (Table.Set OR ISNULL(Table.ControlledLotReference.ScheduleGoodsUnlock, FALSE)) AS SubjectToUnlocking,
				|	CASE
				|		WHEN Table.Reset
				|			THEN VALUE(Catalog.ControlledLots.EmptyRef)
				|		ELSE Table.ControlledLotReference
				|	END AS ControlledLotReference,
				|	CASE
				|		WHEN Table.Reset
				|				OR Table.ControlledLotReference.ScheduleGoodsUnlock IS NULL
				|				OR NOT Table.ControlledLotReference.ScheduleGoodsUnlock
				|			THEN DATETIME(1, 1, 1)
				|		WHEN Table.ControlledLotReference.QualityConfirmationDate <> DATETIME(1, 1, 1)
				|			THEN Table.ControlledLotReference.QualityConfirmationDate
				// For degenerate Lot references with no receipt date, where is the Lot reference order or Contract
				|		WHEN Table.ControlledLotReference.DateOfReceipt = DATETIME(1, 1, 1)
				|			THEN Table.DateOfReceipt
				|		WHEN CalculationOfQualityControlPeriodOverridable.DateFound > DATETIME(1, 1, 1)
				|			THEN CalculationOfQualityControlPeriodOverridable.DateFound
				|		ELSE DATEADD(Table.ControlledLotReference.DateOfReceipt, DAY, ISNULL(ControlledItem.TermOfQualityControl, 0))
				|	END AS QualityConfirmationDate
				|FROM
				|	DataOfDocumentToBeFilledInMustBeUnblockedDateOfQualityConfirmation AS Table
				|		LEFT JOIN Catalog.Products AS ControlledItem
				|		ON ControlledItem.Ref  = Table.Products
				|		AND ControlledItem.ControlQualityOfReceivedGoods
				|		LEFT JOIN CalculationOfQualityControlPeriodOverridable ON TRUE";
		
			Substitutions = ProvisionInDocumentsServer.AddToDateAccordingToEnterpriseCalendar(
				"Table.ControlledLotReference.DateOfReceipt",
				"ControlledItem.TermOfQualityControl");
			
			Text = StrReplace(Text, "CalculationOfQualityControlPeriodOverridable.DateFound", Substitutions.Field);
			Text = StrReplace(Text, "LEFT JOIN CalculationOfQualityControlPeriodOverridable ON TRUE", Substitutions.Joins);
			
			Added_Texts.Add(Text, "FillInUnblockableDateOfQualityConfirmation");
			
		Else
			
			Added_Texts.Add(QueryText, "FillInUnblockableDateOfQualityConfirmation");
			
		EndIf;
		
		QueryOptions = QueryDetails.QueryOptions; // Structure
		CommonClientServer.SupplementStructure(QueryOptions, ActionParameters.QueryOptions);
		
	EndIf;
	
	If UseTypicalLogicForCalculatingDates Then
		ProvisionInDocumentsServer.AddTemporaryTablesYearsOfEnterpriseSchedule(QueriesTexts);
	EndIf;
	
	For IndexOf = 0 To Added_Texts.Count() - 1 Do
		
		QueriesTexts.Add(Added_Texts[IndexOf].Value, Added_Texts[IndexOf].Presentation);
		
	EndDo;
	
	If BatchProcessingOfTablePartServer.YouNeedToPerformAction(
			"FillInSenderSControlledLotReference",
			Actions,
			CachedValues,
			Action_Parameters) Then
		
		ActionParameters = Action_Parameters["FillInSenderSControlledLotReference"];
		Text = StrReplace(ActionParameters.QueryText, "#DataSource", "TTDataSource");
		QueriesTexts.Add(Text, "FillInSenderSControlledLotReference");
		QueryOptions = QueryDetails.QueryOptions; // Structure
		CommonClientServer.SupplementStructure(QueryOptions, ActionParameters.QueryOptions);
		
	EndIf;
	
EndProcedure

Function ControlMayBeDeterminedByContract(BusinessOperation) Export
	
	Result = BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier
			Or BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit
			Or BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit
			Or BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt
			Or BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery
			Or BusinessOperation = Enums.BusinessTransactions.ImportFromEAEU
			Or BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit
			Or BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit
			Or BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery
			Or BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUUninvoicedDelivery
			Or BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUUninvoicedDelivery
			Or BusinessOperation = Enums.BusinessTransactions.PurchaseByImport
			Or BusinessOperation = Enums.BusinessTransactions.ImportGoodsInTransit
			Or BusinessOperation = Enums.BusinessTransactions.ImportReceiptFromGoodsInTransit
			Or BusinessOperation = Enums.BusinessTransactions.PurchaseViaAdvanceHolder
			Or BusinessOperation = Enums.BusinessTransactions.ReceiptFromToller2_5
			Or BusinessOperation = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale
			Or BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5;
			
	Return Result;
	
EndFunction

Procedure FillInCheckQualityDateOfQualityConfirmation(CurrentRow, DataForProcessing, Actions) Export
	
	Var Action_Parameters;
	If Not Actions.Property("FillInCheckQualityDateOfQualityConfirmation", Action_Parameters) Then
		Return;
	EndIf;
	
	ActionParameters = Action_Parameters["FillInCheckQualityDateOfQualityConfirmation"];
	FillInRegular = True;
	If ActionParameters.OverridableProcessingInObjectManager Then
		
		ObjectManager = Common.ObjectManagerByFullName(ActionParameters.FullObjectName);
		ObjectManager.FillInCheckQualityDateOfQualityConfirmation(
			CurrentRow,
			DataForProcessing,
			ActionParameters,
			FillInRegular);
			
	EndIf;
	
	If Not FillInRegular Then
		Return;
	EndIf;
	
	// Regular filling.
	CurrentRow.ToControlQuality = DataForProcessing.ToControlQuality;
	CurrentRow.QualityConfirmationDate = DataForProcessing.QualityConfirmationDate;
	
EndProcedure

Procedure FillInUnblockableDateOfQualityConfirmation(CurrentRow, DataForProcessing, Actions) Export
	
	Var Action_Parameters;
	If Not Actions.Property("FillInUnblockableDateOfQualityConfirmation", Action_Parameters) Then
		Return;
	EndIf;
	
	ActionParameters = Action_Parameters["FillInUnblockableDateOfQualityConfirmation"];
	FillInRegular = True;
	If ActionParameters.OverridableProcessingInObjectManager Then
		
		ObjectManager = Common.ObjectManagerByFullName(ActionParameters.FullObjectName);
		ObjectManager.FillInUnblockableDateOfQualityConfirmation(
			CurrentRow,
			DataForProcessing,
			ActionParameters,
			FillInRegular);
			
	EndIf;
	
	If Not FillInRegular Then
		Return;
	EndIf;
	
	// Regular filling.
	CurrentRow.ControlledLotReference = DataForProcessing.ControlledLotReference;
	CurrentRow.SubjectToUnlocking = DataForProcessing.SubjectToUnlocking;
	CurrentRow.QualityConfirmationDate = DataForProcessing.QualityConfirmationDate;
	
EndProcedure

Procedure FillInSenderSControlledLotReference(CurrentRow, DataForProcessing, Actions) Export
	
	Var Action_Parameters;
	If Not Actions.Property("FillInSenderSControlledLotReference", Action_Parameters) Then
		Return;
	EndIf;
	
	ActionParameters = Action_Parameters["FillInSenderSControlledLotReference"];
	FillInRegular = True;
	If ActionParameters.OverridableProcessingInObjectManager Then
		
		ObjectManager = Common.ObjectManagerByFullName(ActionParameters.FullObjectName);
		ObjectManager.FillInSenderSControlledLotReference(
			CurrentRow,
			DataForProcessing,
			ActionParameters,
			FillInRegular);
			
	EndIf;
	
	If Not FillInRegular Then
		Return;
	EndIf;
	
	// Regular filling.
	CurrentRow.ControlledLotOfTheSender = DataForProcessing.ControlledLotOfTheSender;
	
EndProcedure

// Returns premises with address storage
// Parameters:
//  Table - ValueTable:
//   * Warehouse - CatalogRef.Warehouses -
//   * Premise - CatalogRef.Warerooms -
//  Date - Date -
// Returns:
// QueryResultSelection -
Function WarehouseSelection_(Table, Date) Export
	
	Texts = New Array();
	Text =
		"SELECT DISTINCT
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Premise AS Premise
		|INTO WarehousesAndPremises
		|FROM
		|	&Goods AS Goods
		|INDEX BY
		|	Warehouse, Premise";
	Texts.Add(Text);
	
	Text = QueryTextBinLocationWarehousing();
	Texts.Add(Text);
	
	Text =
		"SELECT
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Premise AS Premise
		|FROM
		|	AddressWarehousesAndPremises AS Goods";
	Texts.Add(Text);
	
	Query = New Query();
	Query.Text = StrConcat(Texts, Common.QueryBatchSeparator());
	Query.SetParameter("Goods", Table);
	Query.SetParameter("Date", ?(ValueIsFilled(Date),Date,CurrentSessionDate()));
	
	WarehouseSelection_ = Query.Execute().Select();
	
	Return WarehouseSelection_;
	
EndFunction

// Filling is performed if the Attributes in the document are not filled in.
// To fill in the database, an element of the Catalog of the controlled party that is suitable for the key is searched.
// If there is no such element, the Attribute will be filled in with the link of the new object. The object itself will be created in the procedure
// Create a controlled partyin the Incoming Order.
// 
// Parameters:
//  Object - DocumentObject - Document.
Procedure FillInControlledLotReferenceInReceiptOrder(Object) Export
	
	SetPrivilegedMode(True);
	
	BatchIsFull = ValueIsFilled(Object.ControlledLotReference);
	QualityControlIsEnabled = GetFunctionalOption("UseGoodsQualityControl");
	If BatchIsFull And Not QualityControlIsEnabled
			And Object.Goods.Find(True, "ToControlQuality") = Undefined Then
		Object.ControlledLotReference = Catalogs.ControlledLots.EmptyRef();
		Return;
	EndIf;
	
	If Not QualityControlIsEnabled
			Or Object.AdditionalProperties.DocumentsPosting.DocumentProperties.WriteMode
				<> DocumentWriteMode.Posting
			Or Object.RecordOfAPreviouslyReceivedLot
			Or Not QualityControlIsSupported(Object.ReferenceOrder) Then
		Return;
	EndIf;
	
	If Not BatchIsFull Then
		
		DataLock = New DataLock();
		
		LockItem = DataLock.Add("Catalog.ControlledLots");
		
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.SetValue("Lot", Object.ReferenceOrder);
		
		//@skip-check lock-out-of-try
		DataLock.Lock();
		
		Query = New Query(
			"SELECT
			|	Lots.Ref AS Ref
			|FROM
			|	Catalog.ControlledLots AS Lots
			|WHERE
			|	Lots.Lot = &Lot");
		Query.SetParameter("Lot", Object.ReferenceOrder);
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			Object.ControlledLotReference = Selection.Ref;
		Else
			Object.ControlledLotReference = Catalogs.ControlledLots.GetRef();
			Object.AdditionalProperties.Insert("CreateControlledLotReference");
		EndIf;
		
	EndIf;
	
EndProcedure

// Creates an element of the Controlled Party directory if there is no reference to the Controlled Party Attribute from the Object in the database.
// 
// Parameters:
//  Object - DocumentObject - Document object.PrikhodnyOrderNaTovary.
Procedure CreateControlledLotReferenceInReceiptOrder(Object) Export
	
	If Not Object.AdditionalProperties.Property("CreateControlledLotReference") Then
		Return;
	EndIf;
	
	CreateAndRecordLotReferencesByOrder(
		Object.ControlledLotReference,
		Object.ReferenceOrder,
		Object.BusinessOperation,
		Object.Sender);
	
EndProcedure

// Filling is performed if the Attributes in the document are not filled in.
// To fill in the database, an element of the Catalog of the controlled party that is suitable for the key is searched.
// If there is no such element, the Attribute will be filled in with the link of the new object. The object itself will be created in the procedure
// Create a controllable part of the table part.
// 
// Parameters:
//  Object - DocumentObject - Document.
//  TabPart - TabularSection -
//  DocumentsOfLotReference - ValueTable -
//  Indexes - String -
Procedure FillInControlledLotReferencesInTablePart(Object, TabPart, DocumentsOfLotReference, Indexes) Export
	
	SetPrivilegedMode(True);
	
	QualityControlIsEnabled = GetFunctionalOption("UseGoodsQualityControl");
	If Not QualityControlIsEnabled
			Or Object.AdditionalProperties.DocumentsPosting.DocumentProperties.WriteMode
				<> DocumentWriteMode.Posting Then
		Return;
	EndIf;
	
	DataLock = New DataLock();
	
	LockItem = DataLock.Add("Catalog.ControlledLots");
	
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.DataSource = DocumentsOfLotReference;
	LockItem.UseFromDataSource("Lot", "DocumentLots");
	
	//@skip-check lock-out-of-try
	DataLock.Lock();
	
	Query = New Query(
		"SELECT
		|	Lots.Ref AS Ref,
		|	Lots.Lot AS DocumentLots
		|FROM
		|	Catalog.ControlledLots AS Lots
		|WHERE
		|	Lots.Lot IN(&DocumentsOfLotReference)");
	Query.SetParameter("DocumentsOfLotReference", DocumentsOfLotReference.UnloadColumn("DocumentLots"));
	TableOfControlledLotsReferences = Query.Execute().Unload();
	TableOfControlledLotsReferences.Indexes.Add("DocumentLots");
	
	RowFilter = New Structure(Indexes);
	SelectionOfLotReferenceDocuments = New Structure("DocumentLots");
	
	For Each String In TabPart Do
		
		FillPropertyValues(RowFilter, String, Indexes);
		DocumentsLotReferenceString = DocumentsOfLotReference.FindRows(RowFilter)[0];
		SelectionOfLotReferenceDocuments.DocumentLots = DocumentsLotReferenceString.DocumentLots;
		FoundRows = TableOfControlledLotsReferences.FindRows(SelectionOfLotReferenceDocuments);
		If FoundRows.Count() > 0 Then
			String.ControlledLotReference = FoundRows[0].Ref;
		Else
			ControlledLots = Undefined;
			If Not Object.AdditionalProperties.Property("CreateControlledLotReference", ControlledLots) Then
				ControlledLots = New Map();
				Object.AdditionalProperties.Insert("CreateControlledLotReference", ControlledLots);
			EndIf;
			LinkToLotReference = ControlledLots.Get(SelectionOfLotReferenceDocuments.DocumentLots);
			If LinkToLotReference = Undefined Then
				LinkToLotReference = Catalogs.ControlledLots.GetRef();
				AttributesOfLotReferenceBeingCreated = New Structure();
				AttributesOfLotReferenceBeingCreated.Insert("Ref", LinkToLotReference);
				AttributesOfLotReferenceBeingCreated.Insert("BusinessOperation", DocumentsLotReferenceString.BusinessOperation);
				AttributesOfLotReferenceBeingCreated.Insert("Sender", DocumentsLotReferenceString.Sender);
				ControlledLots.Insert(SelectionOfLotReferenceDocuments.DocumentLots, AttributesOfLotReferenceBeingCreated);
			EndIf;
			String.ControlledLotReference = LinkToLotReference;
		EndIf;
		
	EndDo;
	
EndProcedure

// Creates an element of the Controlled Party directory if there is no reference to the Controlled Party Attribute from the Object in the database.
// 
// Parameters:
//  Object - DocumentObject - Document
Procedure CreateControlledLotReferencesInTablePart(Object) Export
	
	ControlledLots = Undefined;
	If Not Object.AdditionalProperties.Property("CreateControlledLotReference", ControlledLots) Then
		Return;
	EndIf;
	
	For Each KeyAndValue In ControlledLots Do
		
		AttributesOfLotReferenceBeingCreated = KeyAndValue.Value; // Structure
		CreateAndRecordLotReferencesByOrder(
			AttributesOfLotReferenceBeingCreated.Ref,
			KeyAndValue.Key,
			AttributesOfLotReferenceBeingCreated.BusinessOperation,
			AttributesOfLotReferenceBeingCreated.Sender);
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

Procedure DisableIfFOIsDisabled(Result)
	
	If Not GetFunctionalOption("UseGoodsQualityControl") Then
		If TypeOf(Result) = Type("Structure") Then
			
			For Each Property In Result Do
				If Property.Key = "Key" Then
					Continue;
				EndIf;
				Property.Value.UseGoodsQualityControl = False;
			EndDo;
			
		Else
			
			For Each Item In Result Do // Structure
				
				For Each Property In Item.Parameters Do
					If Property.Key = "Key" Then
						Continue;
					EndIf;
					Property.Value.UseGoodsQualityControl = False;
				EndDo;
				
			EndDo;
			
		EndIf;
	EndIf;
	
EndProcedure

Procedure CreateAndRecordLotReferencesByOrder(ControlledLotReference, ReferenceOrder, BusinessOperation, Sender)
	
	SetPrivilegedMode(True);
	ObjectManager = Common.ObjectManagerByRef(ReferenceOrder);
	PartyDetails = ObjectManager.AttributesOfControlledLotReference(ReferenceOrder, "ControlledLotReference");
	PartyDetails.DateOfReceipt = BegOfDay(PartyDetails.DateOfReceipt);
	ControlledLotReferenceObject = Catalogs.ControlledLots.CreateItem();
	ControlledLotReferenceObject.SetNewObjectRef(ControlledLotReference);
	FillPropertyValues(ControlledLotReferenceObject, PartyDetails);
	ControlledLotReferenceObject.Description = QualityControlClientServer.PresentationOfControlledLotReference(
		PartyDetails, Common.DefaultLanguageCode());
	If ValueIsFilled(BusinessOperation) Then
		ControlledLotReferenceObject.BusinessOperation = BusinessOperation;
		ControlledLotReferenceObject.Sender = Sender;
	EndIf;
	ControlledLotReferenceObject.DeleteBusinessUnitProcessed = True;
	ControlledLotReferenceObject.Write();
	
EndProcedure

Function QueryTextBinLocationWarehousing()

	Return
		"SELECT
		|	WarehousesAndPremises.Warehouse AS Warehouse,
		|	WarehousesAndPremises.Premise AS Premise
		|INTO AddressWarehousesAndPremises
		|FROM
		|	WarehousesAndPremises AS WarehousesAndPremises
		|		INNER JOIN InformationRegister.SettingsOfBinLocationWarehouses AS SettingsOfBinLocationWarehouses
		|		ON (SettingsOfBinLocationWarehouses.UseBinLocationWarehousing)
		|			AND (SettingsOfBinLocationWarehouses.StartDateOfUsingWarehouseBinSystem <= &Date)
		|			AND (SettingsOfBinLocationWarehouses.Warehouse = WarehousesAndPremises.Warehouse)
		|			AND (SettingsOfBinLocationWarehouses.Premise = WarehousesAndPremises.Premise)
		|			AND (NOT WarehousesAndPremises.Premise = VALUE(Catalog.Warerooms.EmptyRef)
		|				OR (NOT SettingsOfBinLocationWarehouses.Warehouse.UseWarerooms
		|					OR &Date < SettingsOfBinLocationWarehouses.Warehouse.StartDateOfWareroomUse))
		|INDEX BY
		|	Warehouse, Premise";
		
EndFunction

Function ProductLocationsAccordingToItemList(ListOfItems)
	
	QueryTextPackages = Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"Packages.Ref", "ItemList.Ref");
	
	QueryText =
		"SELECT
		|	ItemList.Ref AS Ref,
		|	Packages.Ref AS Package,
		|	ISNULL(&RequestTextForPackingCoefficient, 1) AS ZoomRatio
		|FROM
		|	Catalog.Products AS ItemList
		|		
		|		LEFT JOIN Catalog.PackagingGroups AS Sets
		|		ON Sets.Ref = ItemList.PackagingGroup
		|		 AND Sets.Ref <> VALUE(Catalog.PackagingGroups.SpecialForItem)
		|		
		|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS Packages
		|		ON Packages.Owner = ISNULL(Sets.Ref, ItemList.Ref)
		|WHERE
		|	ItemList.Ref IN(&ListOfItems)
		|		AND ItemList.PackagingGroup <> VALUE(Catalog.PackagingGroups.EmptyRef)
		|		AND Packages.PackageType = VALUE(Enum.TypesOfItemsPackages.CargoItem)
		|		AND NOT Packages.DeletionMark";
	QueryText = StrReplace(QueryText, "&RequestTextForPackingCoefficient", QueryTextPackages);
	Query = New Query(QueryText);
	Query.SetParameter("ListOfItems", ListOfItems);
	Selection = Query.Execute().Select();
	
	Result = New Map();
	CurrentProducts = Undefined;
	Packages = Undefined;
	While Selection.Next() Do
		If Selection.Ref <> CurrentProducts Then
			CurrentProducts = Selection.Ref;
			Packages = New Map();
			Result.Insert(CurrentProducts, Packages);
		EndIf;
		Packages.Insert(Selection.Package, Selection.ZoomRatio);
	EndDo;
	Return Result;
	
EndFunction

Procedure ClearIfNotCostAccounting(LineOfBusiness)
	
	If Not LinesOfBusinessServer.ThisIsLineOfActivityWithSeparationOfGoodsAndWorks(LineOfBusiness) Then
		LineOfBusiness = Catalogs.LinesOfBusiness.EmptyRef();
	EndIf;
	
EndProcedure

Function BatchFields()
	
	BatchFields = "ReasonForGoodsLock,ScheduleGoodsUnlock,QualityConfirmationDate,DateOfReceipt,Partner," +
		"Contract,ReceiptDocumentNumber,DateOfReceiptDocument,Lot,Counterparty,LineOfBusiness," +
		"Organization,Department,BusinessOperation,Sender";
	Return BatchFields;
	
EndFunction

#EndRegion
