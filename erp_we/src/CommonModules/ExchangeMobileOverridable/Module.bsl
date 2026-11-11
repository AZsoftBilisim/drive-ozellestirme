#Region Public

// The function checks that the data needs to be transferred to this node
//
// Parameters:
//  Data - Arbitrary - The object or set of records to check.
//    What is transferred everywhere is not processed.
//  ExchangeNode - ExchangePlanRef - The exchange plan sub-asset where the transfer is carried out.
//
// Returns:
//  Boolean - True - it is necessary to carry out the transfer, 
//    False - the transfer does not need to be performed.
//
Function DataTransferRequired(Data, ExchangeNode) Export
	
	Transfer = True;

#If Not MobileStandaloneServer Then

	If TypeOf(Data) = Type("InformationRegisterRecordSet.StorageBinsLocks") Then
		// We check that the lock logger is the documents in use
		If TypeOf(Data.Filter.Recorder.Value) <> Type("DocumentRef.SetStorageBinLocks")
			And TypeOf(Data.Filter.Recorder.Value) <> Type("DocumentRef.InventoryRecount") Then
			Transfer = False;
		EndIf;
	EndIf;
	
#EndIf
 	
	Return Transfer;
	
EndFunction

// The procedure writes the data in XML format.
// The procedure analyzes the transmitted data object and, based on this analysis
// , writes it in a certain way to the XML format.
//
// Parameters:
//  XMLWriter - XMLWriter - an object that records XML data.
//  Data - Arbitrary - data to be written in XML format.
//
Procedure WriteData(XMLWriter, Data) Export
	
	// In this case, there is no data that requires non-standard processing
	// We record data using the standard method
	
	If TypeOf(Data) = Type("CatalogObject.PackagesAndUnitsOfMeasure") Then
		PackagingUnitsOfMeasurementInXMLN(XMLWriter, Data);
	ElsIf TypeOf(Data) = Type("CatalogObject.PackagingGroups") Then
		SetsOfPackagesInXML(XMLWriter, Data);
	ElsIf TypeOf(Data) = Type("CatalogObject.Assignments") Then
		AssignmentsInHTML(XMLWriter, Data);
	ElsIf TypeOf(Data) = Type("CatalogObject.MetadataObjectIDs") Then
		IdentifiersOfMetadataObjectsInXML_(XMLWriter, Data);
	ElsIf TypeOf(Data) = Type("CatalogObject.Products") Then
		ProductsInHTML(XMLWriter, Data);
	ElsIf TypeOf(Data) = Type("CatalogObject.Users") Then
		UsersInHTML(XMLWriter, Data);
	ElsIf TypeOf(Data) = Type("CatalogObject.Warehouses") Then
		WarehousesInFormat(XMLWriter, Data);
	ElsIf TypeOf(Data) = Type("CatalogObject.Warerooms") Then
		StorageFacilitiesInXMLX(XMLWriter, Data);
	ElsIf TypeOf(Data) = Type("CatalogObject.StorageBins") Then
		StorageCellsInXML_(XMLWriter, Data);
	ElsIf TypeOf(Data) = Type("CatalogObject.ItemsCharacteristics") Then
		CharacteristicsOfProductInHTML(XMLWriter, Data);
	ElsIf TypeOf(Data) = Type("CatalogObject.ItemKinds") Then
		ProductTypesInHTML(XMLWriter, Data);
	ElsIf TypeOf(Data) = Type("CatalogObject.ReportsOptions") Then
		ReportOptionsInHTML(XMLWriter, Data);
	ElsIf TypeOf(Data) = Type("CatalogObject.PerformanceDashboards") Then
		MCPVXMLDashboards(XMLWriter, Data); 
	ElsIf TypeOf(Data) = Type("DocumentObject.SetStorageBinLocks") Then
		SettingCellLocksToHTML(XMLWriter, Data);  
	ElsIf TypeOf(Data) = Type("DocumentObject.InventoryRecount") Then	
		InventoryRecountToXML(XMLWriter, Data);   
	ElsIf TypeOf(Data) = Type("DocumentObject.GoodsReceiptNote") Then	
		ReceiptGoodsOrderToHTML(XMLWriter, Data);
	ElsIf TypeOf(Data) = Type("DocumentObject.GoodsIssueNote") Then	
		ExpenseOrderToHTML(XMLWriter, Data);  
	ElsIf TypeOf(Data) = Type("DocumentObject.GoodsPickingPlacement") Then	
		GoodsPickingPlacementToHTML(XMLWriter, Data);	
	ElsIf TypeOf(Data) = Type("InformationRegisterRecordSet.ItemsBarcodes") Then
		ProductBarcodesToXML(XMLWriter, Data);
	ElsIf TypeOf(Data) = Type("InformationRegisterRecordSet.PlaceProductsInStorageBins") Then
		PlacementOfItemsByStorageCellsInHTML(XMLWriter, Data);
	ElsIf TypeOf(Data) = Type("InformationRegisterRecordSet.ReportsSnapshots") Then
		ReportsSnapshotsIntoXML(XMLWriter, Data); 
	ElsIf TypeOf(Data) = Type("InformationRegisterRecordSet.StorageBinsLocks") Then
		BlockingOfStorageCellsInXML(XMLWriter, Data);
	ElsIf TypeOf(Data) = Type("DocumentObject.PurchaseOrder") Then	
		PurchaseOrderINHTML(XMLWriter, Data);
	ElsIf TypeOf(Data) = Type("CatalogObject.ItemsBatches") Then
		ItemSeriesInHTML(XMLWriter, Data);
	ElsIf TypeOf(Data) = Type("CatalogObject.BatchAccountingPolicies") Then
		BatchAccountingPoliciesInHTML(XMLWriter, Data);
	ElsIf TypeOf(Data) = Type("InformationRegisterRecordSet.SettingsOfBinLocationWarehouses") Then
		AddressWarehouseSettingsInXML(XMLWriter, Data);
	ElsIf TypeOf(Data) = Type("CatalogObject.Partners") Then
		PartnersInHTML(XMLWriter, Data);
	ElsIf TypeOf(Data) = Type("CatalogObject.ProductKitConfigurations") Then
		ItemConfigurationOptionsInHTML(XMLWriter, Data);
	ElsIf TypeOf(Data) = Type("DocumentObject.InventoryAdjustmentGoodsShipmentOrder") Then
		CorrectionByOrderInHTML(XMLWriter, Data);
	Else
		ValueType = StrSplit(TypeOf(Data), " ")[0];
		If ValueType = "Catalog" Then
			OtherCatalogsInHTML(XMLWriter, Data);
		ElsIf ValueType = "Document" Then
			OtherDocumentsInHTML(XMLWriter, Data);
		ElsIf ValueType = "Constant" Then
			ConstantsInHTML(XMLWriter, Data);
		EndIf;
	EndIf;
	
#If MobileStandaloneServer Then
	Constants.RegisterRecordsSent.Set(Constants.RegisterRecordsSent.Get() + 1);
#EndIf
	
EndProcedure

// The function reads data from XML format.
// Analyzes the transmitted object readingxml and based on this analysis
// reads data from it in a certain way.
//
// Parameters:
//  XMLReader - XMLReader - An object that reads XML data.
//
// Returns:
//  Arbitrary - the value read from the readingxml object.
//
Function ReadData(XMLReader) Export
	
	If XMLReader.Name = "CatalogObject.PackagesAndUnitsOfMeasure" Then
		Data = PackagingUnitsOfMeasurementFromXML(XMLReader);
	ElsIf XMLReader.Name = "CatalogObject.PackagingGroups" Then
		Data = SetsOfPackagesFromXML(XMLReader);
	ElsIf XMLReader.Name = "CatalogObject.Assignments" Then
		Data = AssignmentsFromXML(XMLReader);
	ElsIf XMLReader.Name = "CatalogObject.MetadataObjectIDs" Then
		Data = IdentifiersOfMetadataObjectsFromXML(XMLReader);
	ElsIf XMLReader.Name = "CatalogObject.Products" Then
		Data = ProductsFromXML(XMLReader);
	ElsIf XMLReader.Name = "CatalogObject.Users" Then
		Data = UsersFromXML(XMLReader);
	ElsIf XMLReader.Name = "CatalogObject.Warehouses" Then
		Data = WarehousesFromXML(XMLReader);
	ElsIf XMLReader.Name = "CatalogObject.Warerooms" Then
		Data = StorageRoomsFromXML(XMLReader);
	ElsIf XMLReader.Name = "CatalogObject.StorageBins" Then
		Data = StorageCellsFromXML(XMLReader);
	ElsIf XMLReader.Name = "CatalogObject.ItemsCharacteristics" Then
		Data = CharacteristicsOfXMLProductList(XMLReader);
	ElsIf XMLReader.Name = "CatalogObject.ItemKinds" Then
		Data = TypesOfProductsFromXML(XMLReader);
	ElsIf XMLReader.Name = "CatalogObject.ReportsOptions" Then
		Data = ReportOptionsFromXML(XMLReader);
	ElsIf XMLReader.Name = "CatalogObject.PerformanceDashboards" Then
		Data = ICPDashboardsFromXML(XMLReader); 
	ElsIf XMLReader.Name =  "DocumentObject.SetStorageBinLocks" Then	
		Data = SettingCellLocksFromXML(XMLReader);
	ElsIf XMLReader.Name =  "DocumentObject.InventoryRecount" Then	
		Data = InventoryCountingFromXML(XMLReader);
	ElsIf XMLReader.Name =  "DocumentObject.GoodsReceiptNote" Then	
		Data = ReceiptGoodsOrderFromXML(XMLReader); 
	ElsIf XMLReader.Name =  "DocumentObject.GoodsIssueNote" Then	
		Data = ExpenseOrderFromXML(XMLReader);   
	ElsIf XMLReader.Name = "DocumentObject.GoodsPickingPlacement" Then	
		Data = GoodsPickingPlacementFromXML(XMLReader);
	ElsIf XMLReader.Name = "InformationRegisterRecordSet.ItemsBarcodes" Then
		Data = ProductBarcodesFromXML(XMLReader);
	ElsIf XMLReader.Name = "InformationRegisterRecordSet.PlaceProductsInStorageBins" Then
		Data = PlacementOfItemsByStorageCellsFromXML(XMLReader);
	ElsIf XMLReader.Name = "InformationRegisterRecordSet.ReportsSnapshots" Then
		Data = ReportsSnapshotsFromXML(XMLReader);
	ElsIf XMLReader.Name = "InformationRegisterRecordSet.StorageBinsLocks" Then
		Data = BlockingStorageCellsFromXML(XMLReader);
	ElsIf XMLReader.Name =  "DocumentObject.PurchaseOrder" Then	
		Data = PurchaseOrderFromXML(XMLReader);
	ElsIf XMLReader.Name = "CatalogObject.ItemsBatches" Then
		Data = SeriesOfItemsFromXML(XMLReader);
	ElsIf XMLReader.Name = "CatalogObject.BatchAccountingPolicies" Then
		Data = SeriesAccountingPoliciesFromXML(XMLReader);
	ElsIf XMLReader.Name = "InformationRegisterRecordSet.SettingsOfBinLocationWarehouses" Then
		Data = AddressWarehouseSettingsFromXML(XMLReader);
	ElsIf XMLReader.Name = "CatalogObject.Partners" Then
		Data = PartnersFromXML(XMLReader);
	ElsIf XMLReader.Name = "CatalogObject.ProductKitConfigurations" Then
		Data = OptionsForCompletingItemFromXML(XMLReader);
	ElsIf XMLReader.Name =  "DocumentObject.InventoryAdjustmentGoodsShipmentOrder" Then	
		Data = CorrectionByOrderFromXML(XMLReader);
	Else
		ObjectName = StrSplit(XMLReader.Name, ".")[0];
		If ObjectName = "DocumentObject" Then
			Data = OtherDocumentsFromXML(XMLReader);
		ElsIf ObjectName = "CatalogObject" Then
			Data = OtherCatalogsFromXML(XMLReader);
		ElsIf ObjectName = "ConstantValueManager" Then
			Data = ConstantsFromXML(XMLReader);
		EndIf;
	EndIf;
	
#If Not MobileStandaloneServer Then
#Else
	Constants.RegisterRecordsReceived.Set(Constants.RegisterRecordsReceived.Get() + 1);
#EndIf
	
	Return Data;
	
EndFunction

// The procedure registers changes for all data included in the exchange plan
// Parameters:
//  ExchangeNode - ExchangePlanRef - The exchange plan sub-asset for which the changes are registered.
Procedure RecordDataChanges(ExchangeNode) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	ReportsSnapshots.Variant AS Variant
	|FROM
	|	InformationRegister.ReportsSnapshots AS ReportsSnapshots
	|WHERE
	|	ReportsSnapshots.Variant REFS Catalog.ReportsOptions";
	
	ExchangePlanContent = ExchangeNode.Metadata().Content;
	For Each ExchangePlanContentItem In ExchangePlanContent Do
		
		If ExchangePlanContentItem.Metadata = Metadata.Catalogs.ReportsOptions Then
			ReferencesArrray = Query.Execute().Unload().UnloadColumn("Variant");
			If ReferencesArrray.Count() > 0 Then
				ExchangePlans.RecordChanges(ExchangeNode, ReferencesArrray);
			EndIf;
		Else
			ExchangePlans.RecordChanges(ExchangeNode,ExchangePlanContentItem.Metadata);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure RecordChangesForOfflineModeOnWrite(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	If TypeOf(Source) = Type("CatalogObject.ReportsOptions") Then
		Query = New Query;
		Query.SetParameter("Variant", Source.Ref);
		Query.Text =
		"SELECT TOP 1
		|	ReportsSnapshots.Variant AS Variant
		|FROM
		|	InformationRegister.ReportsSnapshots AS ReportsSnapshots
		|WHERE
		|	ReportsSnapshots.Variant = &Variant";
		If Query.Execute().IsEmpty() Then
			Return;
		EndIf;
	EndIf;
	
	NodesForRegistration = NodesForRegistration();
	
	RegisterChangesForExchangeNodes(NodesForRegistration, Source);
	
EndProcedure

// Registers objects in the exchange nodes of the mobile app.
//
// Parameters:
//  NodesArray - Array of ExchangePlanRef - contains nodes for the registration of changes of an object;
//  Object - CatalogObject, InformationRegisterRecordSet - the object for which changes are registered.
//
Procedure RegisterChangesForExchangeNodes(NodesArray, Object) Export
	
	If NodesArray.Count() = 0 Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	ExchangePlans.RecordChanges(NodesArray, Object.Ref);
	
EndProcedure

Procedure RecordChangesForOfflineModeRegistersOnWrite(Source, Cancel, Replacing) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	NodesForRegistration = NodesForRegistration();
	
	RegisterChangesForExchangeNodesRegisters(NodesForRegistration, Source);
	
EndProcedure

// Registers objects in the exchange nodes of the mobile app.
//
// Parameters:
//  NodesArray - Array of ExchangePlanRef - contains nodes for the registration of changes of an object;
//  RecordSet - InformationRegisterRecordSet - the object for which changes are registered.
//
Procedure RegisterChangesForExchangeNodesRegisters(NodesArray, RecordSet) Export
	
	If NodesArray.Count() = 0 Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	If TypeOf(RecordSet) = Type("InformationRegisterRecordSet.ItemsBarcodes") Then
		SetOfEntriesBarcodes = InformationRegisters.ItemsBarcodes.CreateRecordSet();
		
		For Each Record In RecordSet Do
			SetOfEntriesBarcodes.Filter.Barcode.Set(Record.Barcode, True);
			SetOfEntriesBarcodes.Filter.Products.Set(Record.Products, True);
			SetOfEntriesBarcodes.Filter.Characteristic.Set(Record.Characteristic, True);
			SetOfEntriesBarcodes.Filter.Series.Set(Record.Series, True);
			SetOfEntriesBarcodes.Filter.Package.Set(Record.Package, True);
			
			ExchangePlans.RecordChanges(NodesArray, SetOfEntriesBarcodes);
		EndDo;
	Else
		ExchangePlans.RecordChanges(NodesArray, RecordSet);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region DataExport

Procedure ConstantsInHTML(XMLWriter, Data)
	
	ObjectName = StrSplit(Data.Metadata().FullName(), ".");
	XMLWriter.WriteStartElement("ConstantValueManager." + ObjectName[1]);
	
	Type = String(TypeOf(Data.Value));
	If Type = "Number" Or Type = "String" Or Type = "Date" Or Type = "Boolean" Then	
		XMLWriter.WriteStartElement("ConstantValue");
		XMLWriter.WriteText(String(Data.Value));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("ValueType");
		XMLWriter.WriteText(Type);
		XMLWriter.WriteEndElement();
	Else
		Type = Data.Value.Metadata().FullName();
		
		If StrSplit(Type, ".")[0] = "Enum" Then
			XMLWriter.WriteStartElement("ConstantValue");
			XMLWriter.WriteText(XMLString(Data.Value));
			XMLWriter.WriteEndElement();
		Else
			XMLWriter.WriteStartElement("ConstantValue");
			XMLWriter.WriteText(String(Data.Value.UUID()));
			XMLWriter.WriteEndElement();
		EndIf;
		
		XMLWriter.WriteStartElement("ValueType");
		XMLWriter.WriteText(Type);
		XMLWriter.WriteEndElement();
	EndIf;
	
	XMLWriter.WriteEndElement();
	
EndProcedure

#Region Catalogs

Procedure OtherCatalogsInHTML(XMLWriter, Data)
	
	ObjectName = StrSplit(Data.Ref.Metadata().FullName(), ".");
	XMLWriter.WriteStartElement("CatalogObject." + ObjectName[1]);
	
	XMLWriter.WriteStartElement("Ref");
	XMLWriter.WriteText(String(Data.Ref.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Description");
	XMLWriter.WriteText(Data.Description);
	XMLWriter.WriteEndElement();
	
	If Metadata.DefinedTypes.ReceiptReferenceOrder.Type.ContainsType(TypeOf(Data.Ref)) Then
		XMLWriter.WriteStartElement("Organization");
		XMLWriter.WriteText(String(Data.Organization.UUID()));
		XMLWriter.WriteEndElement();
	EndIf;
	
	XMLWriter.WriteEndElement();
	
EndProcedure

Procedure ProductsInHTML(XMLWriter, Data)
	
	XMLWriter.WriteStartElement("CatalogObject.Products");
	
	XMLWriter.WriteStartElement("Ref");
	XMLWriter.WriteText(String(Data.Ref.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Parent");
	XMLWriter.WriteText(String(Data.Parent.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Description");
	XMLWriter.WriteText(Data.Description);
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("IsFolder");
	XMLWriter.WriteText(String(Data.IsFolder));
	XMLWriter.WriteEndElement();
	
	If Not Data.IsFolder Then
		
		XMLWriter.WriteStartElement("SKU");
		XMLWriter.WriteText(Data.SKU);
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("DescriptionFull");
		XMLWriter.WriteText(Data.DescriptionFull);
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("SearchCode");
		XMLWriter.WriteText(Data.SearchCode);
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("CodeByKindsOfBusinessActivityClassifier");
		XMLWriter.WriteText(Data.CodeByKindsOfBusinessActivityClassifier);
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("UnitOfMeasure");
		XMLWriter.WriteText(String(Data.UnitOfMeasure.UUID()));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("ProductKind");
		XMLWriter.WriteText(String(Data.ProductKind.UUID()));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("PackagingGroup");
		XMLWriter.WriteText(String(Data.PackagingGroup.UUID()));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("AccountingFeature");
		XMLWriter.WriteText(XMLString(Data.AccountingFeature));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("ItemsType");
		XMLWriter.WriteText(XMLString(Data.ItemsType));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("UseVariants");
		XMLWriter.WriteText(XMLString(Data.UseVariants));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("WeightUse");
		XMLWriter.WriteText(String(Data.WeightUse));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("YouCanSpecifyWeightInDocuments");
		XMLWriter.WriteText(String(Data.YouCanSpecifyWeightInDocuments));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("WeightUnitOfMeasure");
		XMLWriter.WriteText(String(Data.WeightUnitOfMeasure.UUID()));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("WeightNumerator");
		XMLWriter.WriteText(String(Data.WeightNumerator));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("WeightDenominator");
		XMLWriter.WriteText(String(Data.WeightDenominator));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("AreaUse");
		XMLWriter.WriteText(String(Data.AreaUse));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("AreaCanBeSpecifiedInDocuments");
		XMLWriter.WriteText(String(Data.AreaCanBeSpecifiedInDocuments));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("AreaUnitOfMeasure");
		XMLWriter.WriteText(String(Data.AreaUnitOfMeasure.UUID()));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("AreaNumerator");
		XMLWriter.WriteText(String(Data.AreaNumerator));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("AreaDenominator");
		XMLWriter.WriteText(String(Data.AreaDenominator));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("VolumeUse");
		XMLWriter.WriteText(String(Data.VolumeUse));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("VolumeCanBeSpecifiedInDocuments");
		XMLWriter.WriteText(String(Data.VolumeCanBeSpecifiedInDocuments));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("VolumeUnitOfMeasure");
		XMLWriter.WriteText(String(Data.VolumeUnitOfMeasure.UUID()));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("VolumeNumerator");
		XMLWriter.WriteText(String(Data.VolumeNumerator));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("VolumeDenominator");
		XMLWriter.WriteText(String(Data.VolumeDenominator));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("LengthUse");
		XMLWriter.WriteText(String(Data.LengthUse));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("YouCanSpecifyLengthInDocuments");
		XMLWriter.WriteText(String(Data.YouCanSpecifyLengthInDocuments));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("LengthUnitOfMeasure");
		XMLWriter.WriteText(String(Data.LengthUnitOfMeasure.UUID()));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("LengthNumerator");
		XMLWriter.WriteText(String(Data.LengthNumerator));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("LengthDenominator");
		XMLWriter.WriteText(String(Data.LengthDenominator));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("UsePackages");
		XMLWriter.WriteText(String(Data.UsePackages));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("ShelfLifeUnitOfMeasure");
		XMLWriter.WriteText(XMLString(Data.ShelfLifeUnitOfMeasure));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("ExpirationDate_");
		XMLWriter.WriteText(String(Data.ExpirationDate_));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("ItemVariantsOwner");
		XMLWriter.WriteText(String(Data.ItemVariantsOwner.UUID()));
		XMLWriter.WriteEndElement();
		
	EndIf;
	
	XMLWriter.WriteEndElement();
	
EndProcedure

Procedure PackagingUnitsOfMeasurementInXMLN(XMLWriter, Data)
	
	XMLWriter.WriteStartElement("CatalogObject.PackagesAndUnitsOfMeasure");
	
	XMLWriter.WriteStartElement("Ref");
	XMLWriter.WriteText(String(Data.Ref.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Owner");
	XMLWriter.WriteText(String(Data.Owner.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("OwnerType");
	XMLWriter.WriteText(Data.Owner.Metadata().FullName());
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Parent");
	XMLWriter.WriteText(String(Data.Parent.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Description");
	XMLWriter.WriteText(Data.Description);
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Predefined");
	XMLWriter.WriteText(String(Data.Predefined));
	XMLWriter.WriteEndElement();
	
	If Data.Predefined Then
		XMLWriter.WriteStartElement("PredefinedDataName");
		XMLWriter.WriteText(Data.PredefinedDataName);
		XMLWriter.WriteEndElement();
	EndIf;
	
	XMLWriter.WriteStartElement("Dimensionless");
	XMLWriter.WriteText(String(Data.Dimensionless));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Weight");
	XMLWriter.WriteText(String(Data.Weight));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("WeightUnitOfMeasure");
	XMLWriter.WriteText(String(Data.WeightUnitOfMeasure.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Height");
	XMLWriter.WriteText(String(Data.Height));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("HeightUnitOfMeasure");
	XMLWriter.WriteText(String(Data.HeightUnitOfMeasure.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Depth");
	XMLWriter.WriteText(String(Data.Depth));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("DepthUnitOfMeasure");
	XMLWriter.WriteText(String(Data.DepthUnitOfMeasure.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("UnitOfMeasure");
	XMLWriter.WriteText(String(Data.UnitOfMeasure.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Numerator");
	XMLWriter.WriteText(String(Data.Numerator));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Denominator");
	XMLWriter.WriteText(String(Data.Denominator));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("LinearDimensionsPresentation");
	XMLWriter.WriteText(String(Data.LinearDimensionsPresentation));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("VolumeM3");
	XMLWriter.WriteText(String(Data.VolumeM3));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("VolumeUnitOfMeasure");
	XMLWriter.WriteText(String(Data.VolumeUnitOfMeasure.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("WarehouseGroup");
	XMLWriter.WriteText(String(Data.WarehouseGroup.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("StandardSize");
	XMLWriter.WriteText(String(Data.StandardSize.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Width");
	XMLWriter.WriteText(String(Data.Width));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("WidthUnitOfMeasure");
	XMLWriter.WriteText(String(Data.WidthUnitOfMeasure.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("NumberOfPackages");
	XMLWriter.WriteText(String(Data.NumberOfPackages));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("SuppliedInReusablePackage");
	XMLWriter.WriteText(String(Data.SuppliedInReusablePackage));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("ReusablePackageItems");
	XMLWriter.WriteText(String(Data.ReusablePackageItems.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("ReusablePackageVariant");
	XMLWriter.WriteText(String(Data.ReusablePackageVariant.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("MinimumNumberOfReusablePackages");
	XMLWriter.WriteText(String(Data.MinimumNumberOfReusablePackages));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("MeasuredValueType");
	XMLWriter.WriteText(XMLString(Data.MeasuredValueType));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("DescriptionFull");
	XMLWriter.WriteText(Data.DescriptionFull);
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("InternationalAbbreviation");
	XMLWriter.WriteText(Data.InternationalAbbreviation);
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("PackageType");
	XMLWriter.WriteText(XMLString(Data.PackageType));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("DescriptionLanguage1");
	XMLWriter.WriteText(String(Data.DescriptionLanguage1));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("DescriptionLanguage2");
	XMLWriter.WriteText(String(Data.DescriptionLanguage2));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteEndElement();
	
EndProcedure

Procedure SetsOfPackagesInXML(XMLWriter, Data)
	
	XMLWriter.WriteStartElement("CatalogObject.PackagingGroups");
	
	XMLWriter.WriteStartElement("Ref");
	XMLWriter.WriteText(String(Data.Ref.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Description");
	XMLWriter.WriteText(Data.Description);
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Predefined");
	XMLWriter.WriteText(String(Data.Predefined));
	XMLWriter.WriteEndElement();
	
	If Data.Predefined Then
		XMLWriter.WriteStartElement("PredefinedDataName");
		XMLWriter.WriteText(Data.PredefinedDataName);
		XMLWriter.WriteEndElement();
	EndIf;
	
	XMLWriter.WriteStartElement("UnitOfMeasure");
	XMLWriter.WriteText(String(Data.UnitOfMeasure.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("UnitForReports");
	XMLWriter.WriteText(String(Data.UnitForReports.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("UnitFactorForReports");
	XMLWriter.WriteText(String(Data.UnitFactorForReports));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteEndElement();
	
EndProcedure

Procedure UsersInHTML(XMLWriter, Data)
	
	XMLWriter.WriteStartElement("CatalogObject.Users");
	
	XMLWriter.WriteStartElement("Ref");
	XMLWriter.WriteText(String(Data.Ref.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Description");
	XMLWriter.WriteText(Data.Description);
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("IBUserID");
	XMLWriter.WriteText(String(Data.IBUserID));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("IsInternal");
	XMLWriter.WriteText(String(Data.IsInternal));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteEndElement();
	
EndProcedure

Procedure PartnersInHTML(XMLWriter, Data)
	
	XMLWriter.WriteStartElement("CatalogObject.Partners");
	
	XMLWriter.WriteStartElement("Ref");
	XMLWriter.WriteText(String(Data.Ref.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Description");
	XMLWriter.WriteText(Data.Description);
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Client");
	XMLWriter.WriteText(String(Data.Client));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Vendor");
	XMLWriter.WriteText(String(Data.Vendor));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("DescriptionFull");
	XMLWriter.WriteText(String(Data.DescriptionFull));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteEndElement();
	
EndProcedure

Procedure IdentifiersOfMetadataObjectsInXML_(XMLWriter, Data)
	
	XMLWriter.WriteStartElement("CatalogObject.MetadataObjectIDs");
	
	XMLWriter.WriteStartElement("Ref");
	XMLWriter.WriteText(String(Data.Ref.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Description");
	XMLWriter.WriteText(Data.Description);
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("FullName");
	XMLWriter.WriteText(String(Data.FullName));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteEndElement();
	
EndProcedure

Procedure WarehousesInFormat(XMLWriter, Data)
	
	XMLWriter.WriteStartElement("CatalogObject.Warehouses");
	
	XMLWriter.WriteStartElement("Ref");
	XMLWriter.WriteText(String(Data.Ref.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Description");
	XMLWriter.WriteText(Data.Description);
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Parent");
	XMLWriter.WriteText(String(Data.Parent.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("IsFolder");
	XMLWriter.WriteText(String(Data.IsFolder));
	XMLWriter.WriteEndElement();
	
	If Not Data.IsFolder Then
		
		XMLWriter.WriteStartElement("UseBinLocationWarehousing");
		XMLWriter.WriteText(String(Data.UseBinLocationWarehousing));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("UseBinLocationWarehousingForInformation");
		XMLWriter.WriteText(String(Data.UseBinLocationWarehousingForInformation));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("UseWarehouseManagemantSystemForGoodsIssue");
		XMLWriter.WriteText(String(Data.UseWarehouseManagemantSystemForGoodsIssue));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("UseWarehouseManagemantSystemForGoodsSurplusesShortages");
		XMLWriter.WriteText(String(Data.UseWarehouseManagemantSystemForGoodsSurplusesShortages));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("UseWarehouseManagemantSystemForGoodsReceipt");
		XMLWriter.WriteText(String(Data.UseWarehouseManagemantSystemForGoodsReceipt));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("UseItemsBatch");
		XMLWriter.WriteText(String(Data.UseItemsBatch));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("UseWarerooms");
		XMLWriter.WriteText(String(Data.UseWarerooms));
		XMLWriter.WriteEndElement();  
		
		XMLWriter.WriteStartElement("UseGoodsReceiptNoteStatuses");
		XMLWriter.WriteText(String(Data.UseGoodsReceiptNoteStatuses));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("UseGoodsIssueNoteStatuses");
		XMLWriter.WriteText(String(Data.UseGoodsIssueNoteStatuses));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("UseCostAccountingByBatches");
		XMLWriter.WriteText(String(Data.UseCostAccountingByBatches));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("StartDateOfWareroomUse");
		XMLWriter.WriteText(String(Data.StartDateOfWareroomUse));
		XMLWriter.WriteEndElement();
		
	EndIf;
	
	XMLWriter.WriteEndElement();
	
EndProcedure

Procedure StorageFacilitiesInXMLX(XMLWriter, Data)
	
	XMLWriter.WriteStartElement("CatalogObject.Warerooms");
	
	XMLWriter.WriteStartElement("Ref");
	XMLWriter.WriteText(String(Data.Ref.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Description");
	XMLWriter.WriteText(Data.Description);
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Owner");
	XMLWriter.WriteText(String(Data.Owner.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("UseBinLocationWarehousing");
	XMLWriter.WriteText(String(Data.UseBinLocationWarehousing));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("UseBinLocationWarehousingForInformation");
	XMLWriter.WriteText(String(Data.UseBinLocationWarehousingForInformation));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteEndElement();
	
EndProcedure

Procedure AssignmentsInHTML(XMLWriter, Data)
	
	XMLWriter.WriteStartElement("CatalogObject.Assignments");
	
	XMLWriter.WriteStartElement("Ref");
	XMLWriter.WriteText(String(Data.Ref.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Description");
	XMLWriter.WriteText(Data.Description);
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("ControlOnlyStock");
	XMLWriter.WriteText(String(Data.ControlOnlyStock));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("ConsiderVATRates");
	XMLWriter.WriteText(String(Data.ConsiderVATRates));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteEndElement();
	
EndProcedure

Procedure StorageCellsInXML_(XMLWriter, Data)
	
	XMLWriter.WriteStartElement("CatalogObject.StorageBins");
	
	XMLWriter.WriteStartElement("Ref");
	XMLWriter.WriteText(String(Data.Ref.UUID()));
	XMLWriter.WriteEndElement();
	
	If ValueIsFilled(Data.Description) Then 
		XMLWriter.WriteStartElement("Description");
		XMLWriter.WriteText(Data.Description);
		XMLWriter.WriteEndElement();
	EndIf;
		
	XMLWriter.WriteStartElement("Code");
	XMLWriter.WriteText(Data.Code);
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Parent");
	XMLWriter.WriteText(String(Data.Parent.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("IsFolder");
	XMLWriter.WriteText(String(Data.IsFolder));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Owner");
	XMLWriter.WriteText(String(Data.Owner.UUID()));
	XMLWriter.WriteEndElement();
	
	If Not Data.IsFolder Then
		
		XMLWriter.WriteStartElement("StorageBinType");
		XMLWriter.WriteText(XMLString(Data.StorageBinType));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("Premise");
		XMLWriter.WriteText(String(Data.Premise.UUID()));
		XMLWriter.WriteEndElement();
		
	EndIf;
	
	XMLWriter.WriteEndElement();
	
EndProcedure

Procedure CharacteristicsOfProductInHTML(XMLWriter, Data)
	
	XMLWriter.WriteStartElement("CatalogObject.ItemsCharacteristics");
	
	XMLWriter.WriteStartElement("Ref");
	XMLWriter.WriteText(String(Data.Ref.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Description");
	XMLWriter.WriteText(Data.Description);
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("DescriptionFull");
	XMLWriter.WriteText(Data.DescriptionFull);
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("OwnerType");
	XMLWriter.WriteText(Data.Owner.Metadata().FullName());
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Owner");
	XMLWriter.WriteText(String(Data.Owner.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("DeletionMark");
	XMLWriter.WriteText(String(Data.DeletionMark));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Predefined");
	XMLWriter.WriteText(String(Data.Predefined));
	XMLWriter.WriteEndElement();
	
	If Data.Predefined Then
		XMLWriter.WriteStartElement("PredefinedDataName");
		XMLWriter.WriteText(Data.PredefinedDataName);
		XMLWriter.WriteEndElement();
	EndIf;
	
	If ValueIsFilled(Data.Principal) Then
		XMLWriter.WriteStartElement("TypePrincipal");
		XMLWriter.WriteText(Data.Principal.Metadata().FullName());
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("Principal");
		XMLWriter.WriteText(String(Data.Principal.UUID()));
		XMLWriter.WriteEndElement();
	EndIf;
	
	If ValueIsFilled(Data.Counterparty) Then
		XMLWriter.WriteStartElement("TypeCounterparty");
		XMLWriter.WriteText(Data.Counterparty.Metadata().FullName());
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("Counterparty");
		XMLWriter.WriteText(String(Data.Counterparty.UUID()));
		XMLWriter.WriteEndElement();
	EndIf;
	
	XMLWriter.WriteEndElement();
	
EndProcedure

Procedure ItemConfigurationOptionsInHTML(XMLWriter, Data)
	
	XMLWriter.WriteStartElement("CatalogObject.ProductKitConfigurations");
	
	XMLWriter.WriteStartElement("Ref");
	XMLWriter.WriteText(String(Data.Ref.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Description");
	XMLWriter.WriteText(Data.Description);
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("OwnerType");
	XMLWriter.WriteText(Data.Owner.Metadata().FullName());
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Owner");
	XMLWriter.WriteText(String(Data.Owner.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Characteristic");
	XMLWriter.WriteText(String(Data.Characteristic.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Main");
	XMLWriter.WriteText(String(Data.Main));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("SetPricingOption");
	XMLWriter.WriteText(XMLString(Data.SetPricingOption));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("ContainsGoods");
	XMLWriter.WriteText(String(Data.ContainsGoods));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("ContainsServices");
	XMLWriter.WriteText(String(Data.ContainsServices));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteEndElement();
	
EndProcedure

Procedure ProductTypesInHTML(XMLWriter, Data)
	
	XMLWriter.WriteStartElement("CatalogObject.ItemKinds");
	
	XMLWriter.WriteStartElement("Ref");
	XMLWriter.WriteText(String(Data.Ref.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Description");
	XMLWriter.WriteText(Data.Description);
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Parent");
	XMLWriter.WriteText(String(Data.Parent.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("IsFolder");
	XMLWriter.WriteText(String(Data.IsFolder));
	XMLWriter.WriteEndElement();
	
	If Not Data.IsFolder Then
		
		XMLWriter.WriteStartElement("SpecifyNumberWhenRegisteringBatch");
		XMLWriter.WriteText(String(Data.SpecifyNumberWhenRegisteringBatch));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("UseShelfLifeOnBatchRegistration");
		XMLWriter.WriteText(String(Data.UseShelfLifeOnBatchRegistration));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("UseRFIDTags");
		XMLWriter.WriteText(String(Data.UseRFIDTags));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("UseBatchProductionDate");
		XMLWriter.WriteText(String(Data.UseBatchProductionDate));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("CIMSPMSNumber");
		XMLWriter.WriteText(String(Data.CIMSPMSNumber));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("UseUSAISManufacturerBatch");
		XMLWriter.WriteText(String(Data.UseUSAISManufacturerBatch));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("UseCertificate2USAISBatch");
		XMLWriter.WriteText(String(Data.UseCertificate2USAISBatch));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("UseManufacturerVetISBatch");
		XMLWriter.WriteText(String(Data.UseManufacturerVetISBatch));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("UseWarehouseJournalRecordVetISBatch");
		XMLWriter.WriteText(String(Data.UseWarehouseJournalRecordVetISBatch));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("UseVetISLotIDBatch");
		XMLWriter.WriteText(String(Data.UseVetISLotIDBatch));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("MRCMOTP");
		XMLWriter.WriteText(String(Data.MRCMOTP));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("KeepAccountingByBatch");
		XMLWriter.WriteText(String(Data.KeepAccountingByBatch));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("AccountingFeature");
		XMLWriter.WriteText(XMLString(Data.AccountingFeature));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("BatchUsageSettings");
		XMLWriter.WriteText(XMLString(Data.BatchUsageSettings));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("GenerateBatchAutomatically");
		XMLWriter.WriteText(String(Data.GenerateBatchAutomatically));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("BatchOwner");
		XMLWriter.WriteText(String(Data.BatchOwner.UUID()));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("LabelTemplateBatches");
		XMLWriter.WriteText(String(Data.LabelTemplateBatches.UUID()));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("BatchSettingsAreTakenFromOtherItemsKind");
		XMLWriter.WriteText(String(Data.BatchSettingsAreTakenFromOtherItemsKind));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("WorkingNameTemplateSetOfSeries");
		XMLWriter.WriteText(String(Data.WorkingNameTemplateSetOfSeries));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("ShelfLifeUnitOfMeasure");
		XMLWriter.WriteText(XMLString(Data.ShelfLifeUnitOfMeasure));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("PrecisionOfBatchShelfLifeIndication");
		XMLWriter.WriteText(XMLString(Data.PrecisionOfBatchShelfLifeIndication));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("SpecifyQuantityWhenRegisteringBatch");
		XMLWriter.WriteText(String(Data.SpecifyQuantityWhenRegisteringBatch));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("BatchAccountingPolicy");
		XMLWriter.WriteText(String(Data.BatchAccountingPolicy.UUID()));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("SettingsOfPriceKeyByBatch");
		XMLWriter.WriteText(XMLString(Data.SettingsOfPriceKeyByBatch));
		XMLWriter.WriteEndElement();
		
		If Data.BatchAccountingPolicies.Count() Then   
			
			XMLWriter.WriteStartElement("BatchAccountingPolicies");	
			For Each AccountingPolicyLine In Data.BatchAccountingPolicies Do
				XMLWriter.WriteStartElement("SeriesAccountingPolicyElement");
				
				XMLWriter.WriteStartElement("Warehouse");
				XMLWriter.WriteText(String(AccountingPolicyLine.Warehouse.UUID()));
				XMLWriter.WriteEndElement();
				
				XMLWriter.WriteStartElement("BatchAccountingPolicy");
				XMLWriter.WriteText(String(AccountingPolicyLine.BatchAccountingPolicy.UUID()));
				XMLWriter.WriteEndElement();
				
				XMLWriter.WriteEndElement();
			EndDo;
			XMLWriter.WriteEndElement();
		EndIf;
		
		If Data.AttributesForBatchControl.Count() Then   
			
			XMLWriter.WriteStartElement("AttributesForBatchControl");	
			For Each AttributesString In Data.AttributesForBatchControl Do
				XMLWriter.WriteStartElement("AttributesElementForSeriesControl");

				XMLWriter.WriteStartElement("IsAddlAttribute");
				XMLWriter.WriteText(String(AttributesString.IsAddlAttribute));
				XMLWriter.WriteEndElement();
				
				XMLWriter.WriteStartElement("Property");
				XMLWriter.WriteText(String(AttributesString.Property));
				XMLWriter.WriteEndElement();
				
				XMLWriter.WriteStartElement("RequiredToFill");
				XMLWriter.WriteText(String(AttributesString.RequiredToFill));
				XMLWriter.WriteEndElement();
				
				XMLWriter.WriteEndElement();
			EndDo;
			XMLWriter.WriteEndElement();
		EndIf;
		
	EndIf;
	
	XMLWriter.WriteEndElement();
	
EndProcedure

Procedure BatchAccountingPoliciesInHTML(XMLWriter, Data)
	
	XMLWriter.WriteStartElement("CatalogObject.BatchAccountingPolicies");
	
	XMLWriter.WriteStartElement("Ref");
	XMLWriter.WriteText(String(Data.Ref.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Description");
	XMLWriter.WriteText(Data.Description);
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("PolicyType");
	XMLWriter.WriteText(XMLString(Data.PolicyType));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("SpecifyDuringProduction");
	XMLWriter.WriteText(String(Data.SpecifyDuringProduction));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("SpecifyOnMaterialConsumption");
	XMLWriter.WriteText(String(Data.SpecifyOnMaterialConsumption));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("SpecifyByPickingResult");
	XMLWriter.WriteText(String(Data.SpecifyByPickingResult));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("SpecifyOnReturnToWarehouse");
	XMLWriter.WriteText(String(Data.SpecifyOnReturnToWarehouse));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("SpecifyOnShipment");
	XMLWriter.WriteText(String(Data.SpecifyOnShipment));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("SpecifyOnProductionIssueToBusinessUnit");
	XMLWriter.WriteText(String(Data.SpecifyOnProductionIssueToBusinessUnit));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("SpecifyWhenMovingMaterials");
	XMLWriter.WriteText(String(Data.SpecifyWhenMovingMaterials));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("SpecifyWhenMovingProducts");
	XMLWriter.WriteText(String(Data.SpecifyWhenMovingProducts));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("SpecifyOnRetailShipment");
	XMLWriter.WriteText(String(Data.SpecifyOnRetailShipment));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("SpecifyOnShipmentToCustomer");
	XMLWriter.WriteText(String(Data.SpecifyOnShipmentToCustomer));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("SpecifyWhenShippingKitsForDisassembly");
	XMLWriter.WriteText(String(Data.SpecifyWhenShippingKitsForDisassembly));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("SpecifyWhenShippingComponentsForAssembly");
	XMLWriter.WriteText(String(Data.SpecifyWhenShippingComponentsForAssembly));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("SpecifyOnShipmentForInternalNeeds");
	XMLWriter.WriteText(String(Data.SpecifyOnShipmentForInternalNeeds));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("SpecifyOnShipmentByReturnToVendor");
	XMLWriter.WriteText(String(Data.SpecifyOnShipmentByReturnToVendor));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("SpecifyOnShipmentByTransfer");
	XMLWriter.WriteText(String(Data.SpecifyOnShipmentByTransfer));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("SpecifyWhenRecordingSurpluses");
	XMLWriter.WriteText(String(Data.SpecifyWhenRecordingSurpluses));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("SpecifyUponAllocatingCostsToProductionLots");
	XMLWriter.WriteText(String(Data.SpecifyUponAllocatingCostsToProductionLots));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("SpecifyWhenRecordingShortages");
	XMLWriter.WriteText(String(Data.SpecifyWhenRecordingShortages));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("SpecifyUponTransferBetweenWarerooms");
	XMLWriter.WriteText(String(Data.SpecifyUponTransferBetweenWarerooms));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("SpecifyWhenRecountingInventory");
	XMLWriter.WriteText(String(Data.SpecifyWhenRecountingInventory));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("SpecifyWhenPlanningPicking");
	XMLWriter.WriteText(String(Data.SpecifyWhenPlanningPicking));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("SpecifyWhenPlanningShipment");
	XMLWriter.WriteText(String(Data.SpecifyWhenPlanningShipment));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("SpecifyOnReceiving");
	XMLWriter.WriteText(String(Data.SpecifyOnReceiving));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("SpecifyWhenReceivingMaterials");
	XMLWriter.WriteText(String(Data.SpecifyWhenReceivingMaterials));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("SpecifyWhenReceivingComponentsAfterDisassembly");
	XMLWriter.WriteText(String(Data.SpecifyWhenReceivingComponentsAfterDisassembly));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("SpecifyOnReceivingFromVendor");
	XMLWriter.WriteText(String(Data.SpecifyOnReceivingFromVendor));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("SpecifyOnReceivingByReturnFromCustomer");
	XMLWriter.WriteText(String(Data.SpecifyOnReceivingByReturnFromCustomer));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("SpecifyOnReceivingByTransfer");
	XMLWriter.WriteText(String(Data.SpecifyOnReceivingByTransfer));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("SpecifyOnReceivingByOtherRecordingAsReceived");
	XMLWriter.WriteText(String(Data.SpecifyOnReceivingByOtherRecordingAsReceived));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("SpecifyWhenReceivingProductsFromManufacturing");
	XMLWriter.WriteText(String(Data.SpecifyWhenReceivingProductsFromManufacturing));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("SpecifyWhenReceivingAssembledKits");
	XMLWriter.WriteText(String(Data.SpecifyWhenReceivingAssembledKits));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("BatchesAccountingByFEFO");
	XMLWriter.WriteText(String(Data.BatchesAccountingByFEFO));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("AccountForRemainingSeries");
	XMLWriter.WriteText(String(Data.AccountForRemainingSeries));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("UseCostAccountingByBatches");
	XMLWriter.WriteText(String(Data.UseCostAccountingByBatches));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("SpecifyOnReturnOfGoodsNotAcceptedByRecipient");
	XMLWriter.WriteText(String(Data.SpecifyOnReturnOfGoodsNotAcceptedByRecipient));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("ForWarehouse");
	XMLWriter.WriteText(String(Data.ForWarehouse));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("ForProduction");
	XMLWriter.WriteText(String(Data.ForProduction));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("SpecifyOnGoodsMarkingForSPMS");
	XMLWriter.WriteText(String(Data.SpecifyOnGoodsMarkingForSPMS));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("BatchesAccountingInUninvoicedGoodsDeliveries");
	XMLWriter.WriteText(String(Data.BatchesAccountingInUninvoicedGoodsDeliveries));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("BatchesAccountingOfGoodsInTransitFromVendor");
	XMLWriter.WriteText(String(Data.BatchesAccountingOfGoodsInTransitFromVendor));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("BatchesAccountingInDepositedGoods");
	XMLWriter.WriteText(String(Data.BatchesAccountingInDepositedGoods));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("SeriesAccountingOfGoodsTransferredToSubcontractor");
	XMLWriter.WriteText(String(Data.SeriesAccountingOfGoodsTransferredToSubcontractor));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("SeriesAccountingInventoryInOperation");
	XMLWriter.WriteText(String(Data.SeriesAccountingInventoryInOperation));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("AccountingOfBatchesInGoodsTransferredToCommissionAgent");
	XMLWriter.WriteText(String(Data.AccountingOfBatchesInGoodsTransferredToCommissionAgent));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteEndElement();
	
EndProcedure

Procedure ItemSeriesInHTML(XMLWriter, Data)
	
	XMLWriter.WriteStartElement("CatalogObject.ItemsBatches");
	
	XMLWriter.WriteStartElement("Ref");
	XMLWriter.WriteText(String(Data.Ref.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Description");
	XMLWriter.WriteText(Data.Description);
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("DeletionMark");
	XMLWriter.WriteText(String(Data.DeletionMark));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("ValidUntil_");
	XMLWriter.WriteText(String(Data.ValidUntil_));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("ProductKind");
	XMLWriter.WriteText(String(Data.ProductKind.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Number");
	XMLWriter.WriteText(String(Data.Number));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("RFIDTID");
	XMLWriter.WriteText(String(Data.RFIDTID));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("RFIDUser");
	XMLWriter.WriteText(String(Data.RFIDUser));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("RFIDEPC");
	XMLWriter.WriteText(String(Data.RFIDEPC));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("EPCGTIN");
	XMLWriter.WriteText(String(Data.EPCGTIN));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("RFIDTagIsCorruptedAndCannotBeRead");
	XMLWriter.WriteText(String(Data.RFIDTagIsCorruptedAndCannotBeRead));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("ProductionDate");
	XMLWriter.WriteText(String(Data.ProductionDate));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("NumberOfSPMSControlIdentificationMark");
	XMLWriter.WriteText(String(Data.NumberOfSPMSControlIdentificationMark));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("LotIDVetIS");
	XMLWriter.WriteText(String(Data.LotIDVetIS));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("MaximumRetailPriceMOTP");
	XMLWriter.WriteText(String(Data.MaximumRetailPriceMOTP));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteEndElement();
	
EndProcedure

Procedure ReportOptionsInHTML(XMLWriter, Data)
	
	XMLWriter.WriteStartElement("CatalogObject.ReportsOptions");
	
	XMLWriter.WriteStartElement("Ref");
	XMLWriter.WriteText(String(Data.Ref.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Description");
	XMLWriter.WriteText(Data.Description);
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteEndElement();
	
EndProcedure

Procedure MCPVXMLDashboards(XMLWriter, Data)
	
	XMLWriter.WriteStartElement("CatalogObject.PerformanceDashboards");
	
	XMLWriter.WriteStartElement("Ref");
	XMLWriter.WriteText(String(Data.Ref.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Description");
	XMLWriter.WriteText(Data.Description);
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Author");
	XMLWriter.WriteText(String(Data.Author.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("AuthorOnly");
	XMLWriter.WriteText(String(Data.AuthorOnly));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Icon");
	Icon = XDTOSerializer.WriteXDTO(Data.Icon);
	XDTOFactory.WriteXML(XMLWriter, Icon, "ValueStorage", "http://v8.1c.ru/8.1/data/core", , XMLTypeAssignment.Explicit);
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("DashboardUser");
	For Each UsersLine In Data.DashboardUser Do
		XMLWriter.WriteStartElement("User");
		XMLWriter.WriteText(String(UsersLine.User.UUID()));
		XMLWriter.WriteEndElement();
	EndDo;
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteEndElement();
	
EndProcedure

#EndRegion

#Region InformationRegisters

Procedure ProductBarcodesToXML(XMLWriter, Data)
	
	XMLWriter.WriteStartElement("InformationRegisterRecordSet.ItemsBarcodes");

	XMLWriter.WriteStartElement("Barcode");
	XMLWriter.WriteText(Data.Filter.Barcode.Value);
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Products");
	XMLWriter.WriteText(String(Data.Filter.Products.Value.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Characteristic");
	XMLWriter.WriteText(String(Data.Filter.Characteristic.Value.UUID()));
	XMLWriter.WriteEndElement();

	XMLWriter.WriteStartElement("Series");
	XMLWriter.WriteText(String(Data.Filter.Series.Value.UUID()));
	XMLWriter.WriteEndElement();

	XMLWriter.WriteStartElement("Package");
	XMLWriter.WriteText(String(Data.Filter.Package.Value.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteEndElement();
	
EndProcedure

Procedure ReportsSnapshotsIntoXML(XMLWriter, Data)
	
	If Data.Count() = 0 Then
		Return;
	EndIf;
	
	XMLWriter.WriteStartElement("InformationRegisterRecordSet.ReportsSnapshots");
	
	XMLWriter.WriteStartElement("User");
	XMLWriter.WriteText(String(Data[0].User.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Report");
	XMLWriter.WriteText(String(Data[0].Report.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("ValueTypeReport");
	XMLWriter.WriteText(?(TypeOf(Data[0].Report) = Type("CatalogRef.MetadataObjectIDs"),
							"MetadataObjectIDs",
							"ExtensionObjectIDs"));
	XMLWriter.WriteEndElement();

	XMLWriter.WriteStartElement("ReportVariant");
	XMLWriter.WriteText(String(Data[0].Variant.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("OptionValueType");
	XMLWriter.WriteText(?(TypeOf(Data[0].Variant) = Type("CatalogRef.ReportsOptions"),
							"ReportsOptions",
							"PerformanceDashboards"));
	XMLWriter.WriteEndElement();

	XMLWriter.WriteStartElement("UserSettingsHash");
	XMLWriter.WriteText(Data[0].UserSettingsHash);
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("ReportResult");
	ReportResult = XDTOSerializer.WriteXDTO(Data[0].ReportResult);
	XDTOFactory.WriteXML(XMLWriter, ReportResult, "ValueStorage", "http://v8.1c.ru/8.1/data/core", , XMLTypeAssignment.Explicit);
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("UpdateDate");
	XMLWriter.WriteText(String(Data[0].UpdateDate));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("LastViewedDate");
	XMLWriter.WriteText(String(Data[0].LastViewedDate));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("ReportUpdateError");
	XMLWriter.WriteText(String(Data[0].ReportUpdateError));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteEndElement();
	
EndProcedure

Procedure BlockingOfStorageCellsInXML(XMLWriter, Data)
	
	XMLWriter.WriteStartElement("InformationRegisterRecordSet.StorageBinsLocks");
	
	XMLWriter.WriteStartElement("RecorderValueType");
	XMLWriter.WriteText(?(TypeOf(Data.Filter.Recorder.Value) = Type("DocumentRef.SetStorageBinLocks"),
							"SetStorageBinLocks",
							"InventoryRecount"));
	XMLWriter.WriteEndElement();

	XMLWriter.WriteStartElement("Recorder");
	XMLWriter.WriteText(String(Data.Filter.Recorder.Value.UUID()));
	XMLWriter.WriteEndElement();
	
	If Data.Count() Then
		XMLWriter.WriteStartElement("Locks");
		
		For Each Block In Data Do
			XMLWriter.WriteStartElement("LockItem");
			
			XMLWriter.WriteStartElement("Active");
			XMLWriter.WriteText(String(Block.Active));
			XMLWriter.WriteEndElement();

			XMLWriter.WriteStartElement("Cell");
			XMLWriter.WriteText(String(Block.Cell.UUID()));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("LockType");
			XMLWriter.WriteText(XMLString(Block.LockType));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteEndElement();
		EndDo;
		XMLWriter.WriteEndElement();
	EndIf;
	
	XMLWriter.WriteEndElement();
	
EndProcedure

Procedure AddressWarehouseSettingsInXML(XMLWriter, Data)
	
	XMLWriter.WriteStartElement("InformationRegisterRecordSet.SettingsOfBinLocationWarehouses");

	XMLWriter.WriteStartElement("Warehouse");
	XMLWriter.WriteText(String(Data.Filter.Warehouse.Value.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Premise");
	XMLWriter.WriteText(String(Data.Filter.Premise.Value.UUID()));
	XMLWriter.WriteEndElement();
	
	If Data.Count() Then
		XMLWriter.WriteStartElement("SettingsForWarehouses");
		
		For Each Setting In Data Do
			XMLWriter.WriteStartElement("WarehouseSettingsElement");
			
			XMLWriter.WriteStartElement("UseBinLocationWarehousing");
			XMLWriter.WriteText(String(Setting.UseBinLocationWarehousing));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("StartDateOfUsingWarehouseBinSystem");
			XMLWriter.WriteText(String(Setting.StartDateOfUsingWarehouseBinSystem));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteEndElement();
		EndDo;
		XMLWriter.WriteEndElement();
	EndIf;
	
	XMLWriter.WriteEndElement();
	
EndProcedure

Procedure PlacementOfItemsByStorageCellsInHTML(XMLWriter, Data)
	
	XMLWriter.WriteStartElement("InformationRegisterRecordSet.PlaceProductsInStorageBins");

	XMLWriter.WriteStartElement("Products");
	XMLWriter.WriteText(String(Data.Filter.Products.Value.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Cell");
	XMLWriter.WriteText(String(Data.Filter.Cell.Value.UUID()));
	XMLWriter.WriteEndElement();

	XMLWriter.WriteStartElement("Warehouse");
	XMLWriter.WriteText(String(Data.Filter.Warehouse.Value.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Premise");
	XMLWriter.WriteText(String(Data.Filter.Premise.Value.UUID()));
	XMLWriter.WriteEndElement();
	
	If Data.Count() Then
		XMLWriter.WriteStartElement("Location");
		
		For Each Location In Data Do
			XMLWriter.WriteStartElement("PlacementElement");
			
			XMLWriter.WriteStartElement("MainStorageBin");
			XMLWriter.WriteText(String(Location.MainStorageBin));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteEndElement();
		EndDo;
		XMLWriter.WriteEndElement();
	EndIf;
	
	XMLWriter.WriteEndElement();
	
EndProcedure

#EndRegion

#Region Documents

Procedure SettingCellLocksToHTML(XMLWriter, Data)
		
	XMLWriter.WriteStartElement("DocumentObject.SetStorageBinLocks");
	
	XMLWriter.WriteStartElement("Ref");
	XMLWriter.WriteText(String(Data.Ref.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Number");
	XMLWriter.WriteText(Data.Number);
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Date");
	XMLWriter.WriteText(String(Data.Date));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("DeletionMark");
	XMLWriter.WriteText(String(Data.DeletionMark));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Posted");
	XMLWriter.WriteText(String(Data.Posted));
	XMLWriter.WriteEndElement();  
	
	If ValueIsFilled(Data.EmployeeResponsible) Then
		XMLWriter.WriteStartElement("EmployeeResponsible");
		XMLWriter.WriteText(String(Data.EmployeeResponsible.UUID()));
		XMLWriter.WriteEndElement();
	EndIf;

	If ValueIsFilled(Data.Comment) Then
		XMLWriter.WriteStartElement("Comment");
		XMLWriter.WriteText(Data.Comment);
		XMLWriter.WriteEndElement();
	EndIf;
	
	XMLWriter.WriteStartElement("Warehouse");
	XMLWriter.WriteText(String(Data.Warehouse.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Premise");
	XMLWriter.WriteText(String(Data.Premise.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteEndElement();
	
EndProcedure

Procedure InventoryRecountToXML(XMLWriter, Data)
	
	XMLWriter.WriteStartElement("DocumentObject.InventoryRecount");
	
	XMLWriter.WriteStartElement("Ref");
	XMLWriter.WriteText(String(Data.Ref.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Number");
	XMLWriter.WriteText(Data.Number);
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Date");
	XMLWriter.WriteText(String(Data.Date));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("DeletionMark");
	XMLWriter.WriteText(String(Data.DeletionMark));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Posted");
	XMLWriter.WriteText(String(Data.Posted));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("PrintQuantityByRecords");
	XMLWriter.WriteText(String(Data.PrintQuantityByRecords));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Performer");
	XMLWriter.WriteText(String(Data.Performer.UUID()));
	XMLWriter.WriteEndElement(); 
	
	If ValueIsFilled(Data.EmployeeResponsible) Then
		XMLWriter.WriteStartElement("EmployeeResponsible");
		XMLWriter.WriteText(String(Data.EmployeeResponsible.UUID()));
		XMLWriter.WriteEndElement();
	EndIf;

	If ValueIsFilled(Data.Comment) Then
		XMLWriter.WriteStartElement("Comment");
		XMLWriter.WriteText(Data.Comment);
		XMLWriter.WriteEndElement();
	EndIf;
	
	XMLWriter.WriteStartElement("Warehouse");
	XMLWriter.WriteText(String(Data.Warehouse.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Premise");
	XMLWriter.WriteText(String(Data.Premise.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Status");
	XMLWriter.WriteText(XMLString(Data.Status));
	XMLWriter.WriteEndElement();
	
	If Data.Goods.Count() Then
		
		XMLWriter.WriteStartElement("Goods");
		For Each LineProducts_ In Data.Goods Do
			XMLWriter.WriteStartElement("Item_Products");

			XMLWriter.WriteStartElement("Count");
			XMLWriter.WriteText(String(LineProducts_.Count));
			XMLWriter.WriteEndElement();
				
			XMLWriter.WriteStartElement("NumberOfPackages");
			XMLWriter.WriteText(String(LineProducts_.NumberOfPackages));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("CountReal");
			XMLWriter.WriteText(String(LineProducts_.CountReal));
			XMLWriter.WriteEndElement();
				
			XMLWriter.WriteStartElement("NumberOfPackagesReal");
			XMLWriter.WriteText(String(LineProducts_.NumberOfPackagesReal));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("Products");
			XMLWriter.WriteText(String(LineProducts_.Products.UUID()));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("Package");
			XMLWriter.WriteText(String(LineProducts_.Package.UUID()));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("Characteristic");
			XMLWriter.WriteText(String(LineProducts_.Characteristic.UUID()));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("Purpose");
			XMLWriter.WriteText(String(LineProducts_.Purpose.UUID()));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("Cell");
			XMLWriter.WriteText(String(LineProducts_.Cell.UUID()));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("SurplusDamage");
			XMLWriter.WriteText(String(LineProducts_.SurplusDamage));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("Series");
			XMLWriter.WriteText(String(LineProducts_.Series.UUID()));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("BatchesIndicationStatus");
			XMLWriter.WriteText(String(LineProducts_.BatchesIndicationStatus));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteEndElement();
		EndDo;
		XMLWriter.WriteEndElement();
	EndIf;
	
	XMLWriter.WriteEndElement();
	
EndProcedure

Procedure ReceiptGoodsOrderToHTML(XMLWriter, Data)
	
	XMLWriter.WriteStartElement("DocumentObject.GoodsReceiptNote");
	
	XMLWriter.WriteStartElement("Ref");
	XMLWriter.WriteText(String(Data.Ref.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Number");
	XMLWriter.WriteText(Data.Number);
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Date");
	XMLWriter.WriteText(String(Data.Date));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("DeletionMark");
	XMLWriter.WriteText(String(Data.DeletionMark));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Posted");
	XMLWriter.WriteText(String(Data.Posted));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Warehouse");
	XMLWriter.WriteText(String(Data.Warehouse.UUID()));
	XMLWriter.WriteEndElement();

	XMLWriter.WriteStartElement("Performer");
	XMLWriter.WriteText(String(Data.Performer.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Sender");
	XMLWriter.WriteText(String(Data.Sender.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("TypeSender");
	XMLWriter.WriteText(Data.Sender.Metadata().FullName());
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("ReferenceOrder");
	XMLWriter.WriteText(String(Data.ReferenceOrder.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("TypeOfOrder");
	XMLWriter.WriteText(Data.ReferenceOrder.Metadata().FullName());
	XMLWriter.WriteEndElement();
	
	If ValueIsFilled(Data.Comment) Then
		XMLWriter.WriteStartElement("Comment");
		XMLWriter.WriteText(Data.Comment);
		XMLWriter.WriteEndElement();
	EndIf;
	
	XMLWriter.WriteStartElement("Status");
	XMLWriter.WriteText(XMLString(Data.Status));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Premise");
	XMLWriter.WriteText(String(Data.Premise.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("ReceivingArea");
	XMLWriter.WriteText(String(Data.ReceivingArea.UUID()));
	XMLWriter.WriteEndElement();
	
	If ValueIsFilled(Data.IncomingDocumentDate) Then
		XMLWriter.WriteStartElement("IncomingDocumentDate");
		XMLWriter.WriteText(String(Data.IncomingDocumentDate));
		XMLWriter.WriteEndElement(); 
	EndIf;
	
	If ValueIsFilled(Data.IncomingDocumentNumber) Then 
		XMLWriter.WriteStartElement("IncomingDocumentNumber");
		XMLWriter.WriteText(Data.IncomingDocumentNumber);
		XMLWriter.WriteEndElement();
	EndIf;
	
	XMLWriter.WriteStartElement("BusinessOperation");
	XMLWriter.WriteText(XMLString(Data.BusinessOperation));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("WarehouseOperation");
	XMLWriter.WriteText(XMLString(Data.WarehouseOperation));
	XMLWriter.WriteEndElement();
	
	If Data.Goods.Count() Then
		
		XMLWriter.WriteStartElement("Goods");
		For Each LineProducts_ In Data.Goods Do
			XMLWriter.WriteStartElement("Item_Products");

			XMLWriter.WriteStartElement("Count");
			XMLWriter.WriteText(String(LineProducts_.Count));
			XMLWriter.WriteEndElement();
				
			XMLWriter.WriteStartElement("NumberOfPackages");
			XMLWriter.WriteText(String(LineProducts_.NumberOfPackages));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("Products");
			XMLWriter.WriteText(String(LineProducts_.Products.UUID()));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("Package");
			XMLWriter.WriteText(String(LineProducts_.Package.UUID()));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("Characteristic");
			XMLWriter.WriteText(String(LineProducts_.Characteristic.UUID()));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("BatchesIndicationStatus");
			XMLWriter.WriteText(String(LineProducts_.BatchesIndicationStatus));
			XMLWriter.WriteEndElement();
			
			If ValueIsFilled(LineProducts_.DocumentShipments) Then
				XMLWriter.WriteStartElement("DocumentShipments");
				XMLWriter.WriteText(String(LineProducts_.DocumentShipments.UUID()));
				XMLWriter.WriteEndElement();
			EndIf;
			
			XMLWriter.WriteStartElement("Barcode");
			XMLWriter.WriteText(String(LineProducts_.Barcode));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("Series");
			XMLWriter.WriteText(String(LineProducts_.Series.UUID()));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("PackingList");
			XMLWriter.WriteText(String(LineProducts_.PackingList.UUID()));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("PackingListParent");
			XMLWriter.WriteText(String(LineProducts_.PackingListParent.UUID()));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("Purpose");
			XMLWriter.WriteText(String(LineProducts_.Purpose.UUID()));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteEndElement();
		EndDo;
		XMLWriter.WriteEndElement();
	EndIf;
	
	XMLWriter.WriteEndElement();
	
EndProcedure

Procedure ExpenseOrderToHTML(XMLWriter, Data)
	
	XMLWriter.WriteStartElement("DocumentObject.GoodsIssueNote");
	
	XMLWriter.WriteStartElement("Ref");
	XMLWriter.WriteText(String(Data.Ref.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Number");
	XMLWriter.WriteText(Data.Number);
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Date");
	XMLWriter.WriteText(String(Data.Date));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("DateOfShipment");
	XMLWriter.WriteText(String(Data.DateOfShipment));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("DeletionMark");
	XMLWriter.WriteText(String(Data.DeletionMark));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Posted");
	XMLWriter.WriteText(String(Data.Posted));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("ShippingZone");
	XMLWriter.WriteText(String(Data.ShippingZone.UUID()));
	XMLWriter.WriteEndElement();
	
	If ValueIsFilled(Data.Comment) Then
		XMLWriter.WriteStartElement("Comment");
		XMLWriter.WriteText(Data.Comment);
		XMLWriter.WriteEndElement();
	EndIf;
	
	XMLWriter.WriteStartElement("EmployeeResponsible");
	XMLWriter.WriteText(String(Data.EmployeeResponsible.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Inspector");
	XMLWriter.WriteText(String(Data.Inspector.UUID()));
	XMLWriter.WriteEndElement(); 
	
	XMLWriter.WriteStartElement("ShippedBy");
	XMLWriter.WriteText(String(Data.ShippedBy.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Premise");
	XMLWriter.WriteText(String(Data.Premise.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Warehouse");
	XMLWriter.WriteText(String(Data.Warehouse.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Recipient");
	XMLWriter.WriteText(String(Data.Recipient.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Type_Recipient");
	XMLWriter.WriteText(Data.Recipient.Metadata().FullName());
	XMLWriter.WriteEndElement();
		
	XMLWriter.WriteStartElement("Status");
	XMLWriter.WriteText(XMLString(Data.Status));
	XMLWriter.WriteEndElement();
	
	If Data.GoodsByReferences.Count() Then
		
		XMLWriter.WriteStartElement("GoodsByReferences");
		For Each LineProducts_ In Data.GoodsByReferences Do
			XMLWriter.WriteStartElement("GoodsByOrderElement");

			XMLWriter.WriteStartElement("Products");
			XMLWriter.WriteText(String(LineProducts_.Products.UUID()));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("Characteristic");
			XMLWriter.WriteText(String(LineProducts_.Characteristic.UUID()));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("Purpose");
			XMLWriter.WriteText(String(LineProducts_.Purpose.UUID()));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("Series");
			XMLWriter.WriteText(String(LineProducts_.Series.UUID()));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("BatchesIndicationStatus");
			XMLWriter.WriteText(String(LineProducts_.BatchesIndicationStatus));
			XMLWriter.WriteEndElement();
			
			If ValueIsFilled(LineProducts_.ReferenceOrder) Then
				XMLWriter.WriteStartElement("TypeOfOrder");
				XMLWriter.WriteText(LineProducts_.ReferenceOrder.Metadata().FullName());
				XMLWriter.WriteEndElement();
				
				XMLWriter.WriteStartElement("ReferenceOrder");
				XMLWriter.WriteText(String(LineProducts_.ReferenceOrder.UUID()));
				XMLWriter.WriteEndElement();
			EndIf;
			
			XMLWriter.WriteStartElement("Count");
			XMLWriter.WriteText(String(LineProducts_.Count));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteEndElement();
		EndDo;
		XMLWriter.WriteEndElement();
	EndIf;
	
	If Data.ShippedGoods.Count() Then
		
		XMLWriter.WriteStartElement("ShippedGoods");
		For Each LineProducts_ In Data.ShippedGoods Do
			XMLWriter.WriteStartElement("GoodsToBeShippedElement");

			XMLWriter.WriteStartElement("Products");
			XMLWriter.WriteText(String(LineProducts_.Products.UUID()));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("Characteristic");
			XMLWriter.WriteText(String(LineProducts_.Characteristic.UUID()));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("Purpose");
			XMLWriter.WriteText(String(LineProducts_.Purpose.UUID()));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("Series");
			XMLWriter.WriteText(String(LineProducts_.Series.UUID()));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("BatchesIndicationStatus");
			XMLWriter.WriteText(String(LineProducts_.BatchesIndicationStatus));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("ThisIsAPackingList");
			XMLWriter.WriteText(String(LineProducts_.ThisIsAPackingList));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("ThisIsInternalRowOfEmptyPackingList");
			XMLWriter.WriteText(String(LineProducts_.ThisIsInternalRowOfEmptyPackingList));
			XMLWriter.WriteEndElement();
			
			If ValueIsFilled(LineProducts_.PackingListParent) Then
				XMLWriter.WriteStartElement("PackingListParent");
				XMLWriter.WriteText(String(LineProducts_.PackingListParent.UUID()));
				XMLWriter.WriteEndElement();
			EndIf;
			
			If ValueIsFilled(LineProducts_.PackingList) Then
				XMLWriter.WriteStartElement("PackingList");
				XMLWriter.WriteText(String(LineProducts_.PackingList.UUID()));
				XMLWriter.WriteEndElement();
			EndIf;
			
			XMLWriter.WriteStartElement("Package");
			XMLWriter.WriteText(String(LineProducts_.Package.UUID()));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("Count");
			XMLWriter.WriteText(String(LineProducts_.Count));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("NumberOfPackages");
			XMLWriter.WriteText(String(LineProducts_.NumberOfPackages));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("Action");
			XMLWriter.WriteText(XMLString(LineProducts_.Action));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteEndElement();
		EndDo;
		XMLWriter.WriteEndElement();
	EndIf;
	
	XMLWriter.WriteEndElement();
	
EndProcedure

Procedure GoodsPickingPlacementToHTML(XMLWriter, Data)
	
	XMLWriter.WriteStartElement("DocumentObject.GoodsPickingPlacement");
	
	XMLWriter.WriteStartElement("Ref");
	XMLWriter.WriteText(String(Data.Ref.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Number");
	XMLWriter.WriteText(Data.Number);
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Date");
	XMLWriter.WriteText(String(Data.Date));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("DeletionMark");
	XMLWriter.WriteText(String(Data.DeletionMark));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Posted");
	XMLWriter.WriteText(String(Data.Posted));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("OperationKind");
	XMLWriter.WriteText(XMLString(Data.OperationKind));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("ShippingZone");
	XMLWriter.WriteText(String(Data.ShippingZone.UUID()));
	XMLWriter.WriteEndElement();

	XMLWriter.WriteStartElement("ReceivingArea");
	XMLWriter.WriteText(String(Data.ReceivingArea.UUID()));
	XMLWriter.WriteEndElement();
	
	If ValueIsFilled(Data.Performer) Then
		XMLWriter.WriteStartElement("Performer");
		XMLWriter.WriteText(String(Data.Performer.UUID()));
		XMLWriter.WriteEndElement();
	EndIf;
	
	If ValueIsFilled(Data.ReferenceOrder) Then
		XMLWriter.WriteStartElement("ReferenceOrder");
		XMLWriter.WriteText(String(Data.ReferenceOrder.UUID()));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("TypeOfOrder");
		XMLWriter.WriteText(Data.ReferenceOrder.Metadata().FullName());
		XMLWriter.WriteEndElement();
	EndIf;
	
	If ValueIsFilled(Data.Comment) Then
		XMLWriter.WriteStartElement("Comment");
		XMLWriter.WriteText(Data.Comment);
		XMLWriter.WriteEndElement();
	EndIf;
	
	XMLWriter.WriteStartElement("Warehouse");
	XMLWriter.WriteText(String(Data.Warehouse.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Premise");
	XMLWriter.WriteText(String(Data.Premise.UUID()));
	XMLWriter.WriteEndElement();

	XMLWriter.WriteStartElement("Status");
	XMLWriter.WriteText(XMLString(Data.Status));
	XMLWriter.WriteEndElement();
	
	If ValueIsFilled(Data.VolumePutAway) Then
		XMLWriter.WriteStartElement("VolumePutAway");
		XMLWriter.WriteText(String(Data.VolumePutAway));
		XMLWriter.WriteEndElement();
	EndIf;	
	
	If ValueIsFilled(Data.WeightPlacement) Then
		XMLWriter.WriteStartElement("WeightPlacement");
		XMLWriter.WriteText(String(Data.WeightPlacement));
		XMLWriter.WriteEndElement();
	EndIf;
	
	If Data.GoodsFilter.Count() Then
		
		XMLWriter.WriteStartElement("GoodsFilter");
		For Each LineProductsSelection In Data.GoodsFilter Do
			XMLWriter.WriteStartElement("GoodsItemFilter");

			XMLWriter.WriteStartElement("Count");
			XMLWriter.WriteText(String(LineProductsSelection.Count));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("CountPicked");
			XMLWriter.WriteText(String(LineProductsSelection.CountPicked));
			XMLWriter.WriteEndElement();
				
			XMLWriter.WriteStartElement("NumberOfPackages");
			XMLWriter.WriteText(String(LineProductsSelection.NumberOfPackages));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("NumberOfPackagesPicked");
			XMLWriter.WriteText(String(LineProductsSelection.NumberOfPackagesPicked));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("Products");
			XMLWriter.WriteText(String(LineProductsSelection.Products.UUID()));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("Package");
			XMLWriter.WriteText(String(LineProductsSelection.Package.UUID()));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("Characteristic");
			XMLWriter.WriteText(String(LineProductsSelection.Characteristic.UUID()));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("Cell");
			XMLWriter.WriteText(String(LineProductsSelection.Cell.UUID()));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("Purpose");
			XMLWriter.WriteText(String(LineProductsSelection.Purpose.UUID()));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("Series");
			XMLWriter.WriteText(String(LineProductsSelection.Series.UUID()));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("BatchesIndicationStatus");
			XMLWriter.WriteText(String(LineProductsSelection.BatchesIndicationStatus));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteEndElement();
		EndDo;
		XMLWriter.WriteEndElement();
	EndIf;
	
	If Data.GoodsPlacement.Count() Then
		
		XMLWriter.WriteStartElement("GoodsPlacement");
		For Each LineProductsSelection In Data.GoodsPlacement Do
			XMLWriter.WriteStartElement("GoodsItemPlacement");

			XMLWriter.WriteStartElement("Count");
			XMLWriter.WriteText(String(LineProductsSelection.Count));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("CountPlaced");
			XMLWriter.WriteText(String(LineProductsSelection.CountPlaced));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("NumberOfPackages");
			XMLWriter.WriteText(String(LineProductsSelection.NumberOfPackages));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("NumberOfPackagesPlaced");
			XMLWriter.WriteText(String(LineProductsSelection.NumberOfPackagesPlaced));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("Products");
			XMLWriter.WriteText(String(LineProductsSelection.Products.UUID()));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("Package");
			XMLWriter.WriteText(String(LineProductsSelection.Package.UUID()));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("Characteristic");
			XMLWriter.WriteText(String(LineProductsSelection.Characteristic.UUID()));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("Cell");
			XMLWriter.WriteText(String(LineProductsSelection.Cell.UUID()));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("Purpose");
			XMLWriter.WriteText(String(LineProductsSelection.Purpose.UUID()));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("Series");
			XMLWriter.WriteText(String(LineProductsSelection.Series.UUID()));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("BatchesIndicationStatus");
			XMLWriter.WriteText(String(LineProductsSelection.BatchesIndicationStatus));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteEndElement();
		EndDo;
		XMLWriter.WriteEndElement(); 
	EndIf;
	
	XMLWriter.WriteEndElement();
	
EndProcedure

Procedure PurchaseOrderINHTML(XMLWriter, Data)
	
	XMLWriter.WriteStartElement("DocumentObject.PurchaseOrder");
	
	XMLWriter.WriteStartElement("Ref");
	XMLWriter.WriteText(String(Data.Ref.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Number");
	XMLWriter.WriteText(Data.Number);
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Date");
	XMLWriter.WriteText(String(Data.Date));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("DeletionMark");
	XMLWriter.WriteText(String(Data.DeletionMark));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Posted");
	XMLWriter.WriteText(String(Data.Posted));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Organization");
	XMLWriter.WriteText(String(Data.Organization.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Manager");
	XMLWriter.WriteText(String(Data.Manager.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteEndElement();
	
EndProcedure

Procedure CorrectionByOrderInHTML(XMLWriter, Data)
	
	XMLWriter.WriteStartElement("DocumentObject.InventoryAdjustmentGoodsShipmentOrder");
	
	XMLWriter.WriteStartElement("Ref");
	XMLWriter.WriteText(String(Data.Ref.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Number");
	XMLWriter.WriteText(Data.Number);
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Date");
	XMLWriter.WriteText(String(Data.Date));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("DeletionMark");
	XMLWriter.WriteText(String(Data.DeletionMark));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Posted");
	XMLWriter.WriteText(String(Data.Posted));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("ShippingZone");
	XMLWriter.WriteText(String(Data.ShippingZone.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("EmployeeResponsible");
	XMLWriter.WriteText(String(Data.EmployeeResponsible.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Premise");
	XMLWriter.WriteText(String(Data.Premise.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Warehouse");
	XMLWriter.WriteText(String(Data.Warehouse.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("WarehouseDocument");
	XMLWriter.WriteText(String(Data.WarehouseDocument.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("TypeOrder");
	XMLWriter.WriteText(Data.WarehouseDocument.Metadata().FullName());
	XMLWriter.WriteEndElement();
	
	If ValueIsFilled(Data.RecipientNote) Then
		XMLWriter.WriteStartElement("RecipientNote");
		XMLWriter.WriteText(String(Data.RecipientNote.UUID()));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("OrderTypeRecipient");
		XMLWriter.WriteText(Data.RecipientNote.Metadata().FullName());
		XMLWriter.WriteEndElement();
	EndIf;
	
	If Data.Goods.Count() Then
		
		XMLWriter.WriteStartElement("Goods");
		For Each LineProducts_ In Data.Goods Do
			XMLWriter.WriteStartElement("Item_Products");

			XMLWriter.WriteStartElement("Count");
			XMLWriter.WriteText(String(LineProducts_.Count));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("Products");
			XMLWriter.WriteText(String(LineProducts_.Products.UUID()));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("Characteristic");
			XMLWriter.WriteText(String(LineProducts_.Characteristic.UUID()));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("Series");
			XMLWriter.WriteText(String(LineProducts_.Series.UUID()));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("Purpose");
			XMLWriter.WriteText(String(LineProducts_.Purpose.UUID()));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("Package");
			XMLWriter.WriteText(String(LineProducts_.Package.UUID()));
			XMLWriter.WriteEndElement();
				
			XMLWriter.WriteStartElement("NumberOfPackages");
			XMLWriter.WriteText(String(LineProducts_.NumberOfPackages));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("OperationKind");
			XMLWriter.WriteText(XMLString(LineProducts_.OperationKind));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("BatchesIndicationStatus");
			XMLWriter.WriteText(String(LineProducts_.BatchesIndicationStatus));
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteEndElement();
		EndDo;
		XMLWriter.WriteEndElement();
	EndIf;
	
	XMLWriter.WriteEndElement();
	
EndProcedure

Procedure OtherDocumentsInHTML(XMLWriter, Data)
	
	ObjectName = StrSplit(Data.Ref.Metadata().FullName(), ".");
	
	XMLWriter.WriteStartElement("DocumentObject." + ObjectName[1]);
	
	XMLWriter.WriteStartElement("Ref");
	XMLWriter.WriteText(String(Data.Ref.UUID()));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Number");
	XMLWriter.WriteText(Data.Number);
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Date");
	XMLWriter.WriteText(String(Data.Date));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("DeletionMark");
	XMLWriter.WriteText(String(Data.DeletionMark));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("Posted");
	XMLWriter.WriteText(String(Data.Posted));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteEndElement();
	
EndProcedure

#EndRegion

#EndRegion

#Region DataImport

Function ConstantsFromXML(XMLReader)
	
	ObjectName = StrSplit(XMLReader.Name, ".");
	
	XDTODataObject = XDTOFactory.ReadXML(XMLReader);
	
	Type = MobileWarehouseKeeperWorkspace.ObjectManagerByFullName("Constant." + ObjectName[1]);
	ValueType = XDTODataObject.ValueType;
	If ValueType = "Number" Then
		Type.Set(Number(XDTODataObject.ConstantValue));
	ElsIf ValueType = "Date" Then
		Type.Set(Date(XDTODataObject.ConstantValue));
	ElsIf ValueType = "Boolean" Then
		Type.Set(Boolean(XDTODataObject.ConstantValue));
	ElsIf ValueType = "String" Then
		If TypeOf(XDTODataObject.ConstantValue) = Type("XDTODataObject") Then
			Type.Set("");
		Else
			Type.Set(String(XDTODataObject.ConstantValue));
		EndIf;
	ElsIf StrSplit(ValueType, ".")[0] = "Enum" Then
		If TypeOf(XDTODataObject.ConstantValue) = Type("String") Then
			ValueType = MobileWarehouseKeeperWorkspace.ObjectManagerByFullName(ValueType);
			Type.Set(ValueType[XDTODataObject.ConstantValue]);
		EndIf;
	Else
		ValueType = MobileWarehouseKeeperWorkspace.ObjectManagerByFullName(ValueType);
		Type.Set(ValueType.GetRef(New UUID(XDTODataObject.ConstantValue)));
	EndIf;
	
	Return Undefined;
	
EndFunction

#Region Catalogs

Function OtherCatalogsFromXML(XMLReader)
	
	ObjectName = StrSplit(XMLReader.Name, ".");
	XDTODataObject = XDTOFactory.ReadXML(XMLReader); // XDTODataObject
	
	Type = MobileWarehouseKeeperWorkspace.ObjectManagerByFullName("Catalog." + ObjectName[1]);
	DataReference = Type.GetRef(New UUID(XDTODataObject.Ссылка));
	Data = DataReference.GetObject();
	
	If Data = Undefined Then
		Data = Type.CreateItem();
		Data.SetNewObjectRef(DataReference);
	Else
		Data = DataReference.GetObject();
	EndIf;
	
	FillPropertyValues(Data, XDTODataObject);
	
	If XDTODataObject.Properties().Get("Organization") <> Undefined Then
		Data.Organization = Catalogs.Companies.GetRef(New UUID(XDTODataObject.Организация));
	EndIf;
	
	Return Data;
	
EndFunction

Function PackagingUnitsOfMeasurementFromXML(XMLReader)
	
	XDTODataObject = XDTOFactory.ReadXML(XMLReader);
	
	DataReference = Catalogs.PackagesAndUnitsOfMeasure.GetRef(New UUID(XDTODataObject.Ref));
	Data = DataReference.GetObject();
	
	If Data = Undefined Then
		Data = Catalogs.PackagesAndUnitsOfMeasure.CreateItem();
		Data.SetNewObjectRef(DataReference);
	Else
		Data = DataReference.GetObject();
	EndIf;
	
	FillPropertyValues(Data, XDTODataObject);
	
	OwnerType = XDTODataObject.OwnerType;
	Type = MobileWarehouseKeeperWorkspace.ObjectManagerByFullName(OwnerType);
	Data.Owner = Type.GetRef(New UUID(XDTODataObject.Owner));
	
	Data.Parent = Catalogs.PackagesAndUnitsOfMeasure.GetRef(New UUID(XDTODataObject.Parent));
	
	Data.Dimensionless = Boolean(XDTODataObject.Dimensionless);
	Data.Weight = Number(XDTODataObject.Weight);
	Data.WeightUnitOfMeasure = Catalogs.PackagesAndUnitsOfMeasure.GetRef(New UUID(XDTODataObject.WeightUnitOfMeasure));
	Data.Height = Number(XDTODataObject.Height);
	Data.HeightUnitOfMeasure = Catalogs.PackagesAndUnitsOfMeasure.GetRef(New UUID(XDTODataObject.HeightUnitOfMeasure));
	Data.Depth = Number(XDTODataObject.Depth);
	Data.DepthUnitOfMeasure = Catalogs.PackagesAndUnitsOfMeasure.GetRef(New UUID(XDTODataObject.DepthUnitOfMeasure));
	Data.UnitOfMeasure = Catalogs.PackagesAndUnitsOfMeasure.GetRef(New UUID(XDTODataObject.UnitOfMeasure));
	Data.Numerator = Number(XDTODataObject.Numerator);
	Data.Denominator = Number(XDTODataObject.Denominator);
	
	If TypeOf(XDTODataObject.LinearDimensionsPresentation) = Type("XDTODataObject") Then
		Data.LinearDimensionsPresentation = "";
	Else
		Data.LinearDimensionsPresentation = String(XDTODataObject.LinearDimensionsPresentation);
	EndIf;
	
	Data.VolumeM3 = Number(XDTODataObject.VolumeM3);
	Data.VolumeUnitOfMeasure = Catalogs.PackagesAndUnitsOfMeasure.GetRef(New UUID(XDTODataObject.VolumeUnitOfMeasure));
	Data.WarehouseGroup = Catalogs.WarehousePackageGroups.GetRef(New UUID(XDTODataObject.WarehouseGroup));
	Data.StandardSize = Catalogs.StandardSizesOfPackages.GetRef(New UUID(XDTODataObject.StandardSize));
	Data.Width = Number(XDTODataObject.Width);
	Data.WidthUnitOfMeasure = Catalogs.PackagesAndUnitsOfMeasure.GetRef(New UUID(XDTODataObject.WidthUnitOfMeasure));
	Data.NumberOfPackages = Number(XDTODataObject.NumberOfPackages);
	Data.SuppliedInReusablePackage = Boolean(XDTODataObject.SuppliedInReusablePackage);
	Data.ReusablePackageItems = Catalogs.Products.GetRef(New UUID(XDTODataObject.ReusablePackageItems));
	Data.ReusablePackageVariant = Catalogs.ItemsCharacteristics.GetRef(New UUID(XDTODataObject.ReusablePackageVariant));
	Data.MinimumNumberOfReusablePackages = Number(XDTODataObject.MinimumNumberOfReusablePackages);
	
	If TypeOf(XDTODataObject.MeasuredValueType) = Type("String") Then
		Data.MeasuredValueType = Enums.TypesOfMeasuredValues[XDTODataObject.MeasuredValueType];
	EndIf;
	
	If TypeOf(XDTODataObject.DescriptionFull) = Type("XDTODataObject") Then
		Data.DescriptionFull = "";
	Else
		Data.DescriptionFull = String(XDTODataObject.DescriptionFull);
	EndIf;
	
	If TypeOf(XDTODataObject.InternationalAbbreviation) = Type("XDTODataObject") Then
		Data.InternationalAbbreviation = "";
	Else
		Data.InternationalAbbreviation = String(XDTODataObject.InternationalAbbreviation);
	EndIf;
	
	If TypeOf(XDTODataObject.PackageType) = Type("String") Then
		Data.PackageType = Enums.TypesOfItemsPackages[XDTODataObject.PackageType];
	EndIf;
	
	If TypeOf(XDTODataObject.DescriptionLanguage1) = Type("XDTODataObject") Then
		Data.DescriptionLanguage1 = "";
	Else
		Data.DescriptionLanguage1 = String(XDTODataObject.DescriptionLanguage1);
	EndIf;
	
	If TypeOf(XDTODataObject.DescriptionLanguage2) = Type("XDTODataObject") Then
		Data.DescriptionLanguage2 = "";
	Else
		Data.DescriptionLanguage2 = String(XDTODataObject.DescriptionLanguage2);
	EndIf;
	
	Return Data;
	
EndFunction

Function SetsOfPackagesFromXML(XMLReader)
	
	XDTODataObject = XDTOFactory.ReadXML(XMLReader); // XDTODataObject
	
	DataReference = Catalogs.PackagingGroups.GetRef(New UUID(XDTODataObject.Ссылка));
	Data = DataReference.GetObject();
	
	If Data = Undefined Then
		Data = Catalogs.PackagingGroups.CreateItem();
		Data.SetNewObjectRef(DataReference);
	Else
		Data = DataReference.GetObject();
	EndIf;
	
	FillPropertyValues(Data, XDTODataObject);
	
	Data.UnitOfMeasure = Catalogs.PackagesAndUnitsOfMeasure.GetRef(New UUID(XDTODataObject.ЕдиницаИзмерения));
	Data.UnitForReports = Catalogs.PackagesAndUnitsOfMeasure.GetRef(New UUID(XDTODataObject.ЕдиницаДляОтчетов));
	Data.UnitFactorForReports = Number(XDTODataObject.КоэффициентЕдиницыДляОтчетов);
	
	Return Data;
	
EndFunction

Function ProductsFromXML(XMLReader)
	
	XDTODataObject = XDTOFactory.ReadXML(XMLReader);
	IsFolder = Boolean(XDTODataObject.IsFolder);
	
	DataReference = Catalogs.Products.GetRef(New UUID(XDTODataObject.Ref));
	Data = DataReference.GetObject();
	
	If Data = Undefined And IsFolder Then
		Data = Catalogs.Products.CreateFolder();
		Data.SetNewObjectRef(DataReference);
	ElsIf Data = Undefined And Not IsFolder Then
		Data = Catalogs.Products.CreateItem();
		Data.SetNewObjectRef(DataReference);
	Else
		Data = DataReference.GetObject();
	EndIf;
	
	FillPropertyValues(Data, XDTODataObject);
	
	Data.Parent = Catalogs.Products.GetRef(New UUID(XDTODataObject.Parent));
	
	If IsFolder Then
		Return Data;
	EndIf;
	
	Data.UnitOfMeasure = Catalogs.PackagesAndUnitsOfMeasure.GetRef(New UUID(XDTODataObject.UnitOfMeasure));
	Data.ProductKind = Catalogs.ItemKinds.GetRef(New UUID(XDTODataObject.ProductKind));
	Data.PackagingGroup = Catalogs.PackagingGroups.GetRef(New UUID(XDTODataObject.PackagingGroup));
	If TypeOf(XDTODataObject.AccountingFeature) = Type("String") Then
		Data.AccountingFeature = Enums.ItemAccountingFeatures[XDTODataObject.AccountingFeature];
	EndIf;
	If TypeOf(XDTODataObject.ItemsType) = Type("String") Then
		Data.ItemsType = Enums.ItemsTypes[XDTODataObject.ItemsType];
	EndIf;
	If TypeOf(XDTODataObject.UseVariants) = Type("String") Then
		Data.UseVariants = Enums.ItemVariantsUsageOptions[XDTODataObject.UseVariants];
	EndIf;
	
	Data.WeightUse = Boolean(XDTODataObject.WeightUse);
	Data.YouCanSpecifyWeightInDocuments = Boolean(XDTODataObject.YouCanSpecifyWeightInDocuments);
	Data.WeightUnitOfMeasure = Catalogs.PackagesAndUnitsOfMeasure.GetRef(New UUID(XDTODataObject.WeightUnitOfMeasure));
	Data.WeightNumerator = Number(XDTODataObject.WeightNumerator);
	Data.WeightDenominator = Number(XDTODataObject.WeightDenominator);
	
	Data.AreaUse = Boolean(XDTODataObject.AreaUse);
	Data.AreaCanBeSpecifiedInDocuments = Boolean(XDTODataObject.AreaCanBeSpecifiedInDocuments);
	Data.AreaUnitOfMeasure = Catalogs.PackagesAndUnitsOfMeasure.GetRef(New UUID(XDTODataObject.AreaUnitOfMeasure));
	Data.AreaNumerator = Number(XDTODataObject.AreaNumerator);
	Data.AreaDenominator = Number(XDTODataObject.AreaDenominator);
	
	Data.VolumeUse = Boolean(XDTODataObject.VolumeUse);
	Data.VolumeCanBeSpecifiedInDocuments = Boolean(XDTODataObject.VolumeCanBeSpecifiedInDocuments);
	Data.VolumeUnitOfMeasure = Catalogs.PackagesAndUnitsOfMeasure.GetRef(New UUID(XDTODataObject.VolumeUnitOfMeasure));
	Data.VolumeNumerator = Number(XDTODataObject.VolumeNumerator);
	Data.VolumeDenominator = Number(XDTODataObject.VolumeDenominator);
	
	Data.LengthUse = Boolean(XDTODataObject.LengthUse);
	Data.YouCanSpecifyLengthInDocuments = Boolean(XDTODataObject.YouCanSpecifyLengthInDocuments);
	Data.LengthUnitOfMeasure = Catalogs.PackagesAndUnitsOfMeasure.GetRef(New UUID(XDTODataObject.LengthUnitOfMeasure));
	Data.LengthNumerator = Number(XDTODataObject.LengthNumerator);
	Data.LengthDenominator = Number(XDTODataObject.LengthDenominator);
	
	Data.UsePackages = Boolean(XDTODataObject.UsePackages);
	
	If TypeOf(XDTODataObject.SKU) = Type("XDTODataObject") Then
		Data.SKU = "";
	Else
		Data.SKU = String(XDTODataObject.SKU);
	EndIf;
	
	If TypeOf(XDTODataObject.SearchCode) = Type("XDTODataObject") Then
		Data.SearchCode = "";
	Else
		Data.SearchCode = String(XDTODataObject.SearchCode);
	EndIf;
	
	If TypeOf(XDTODataObject.CodeByKindsOfBusinessActivityClassifier) = Type("XDTODataObject") Then
		Data.CodeByKindsOfBusinessActivityClassifier = "";
	Else
		Data.CodeByKindsOfBusinessActivityClassifier = String(XDTODataObject.CodeByKindsOfBusinessActivityClassifier);
	EndIf;
	
	If TypeOf(XDTODataObject.DescriptionFull) = Type("XDTODataObject") Then
		Data.DescriptionFull = "";
	Else
		Data.DescriptionFull = String(XDTODataObject.DescriptionFull);
	EndIf;
	
	If TypeOf(XDTODataObject.ShelfLifeUnitOfMeasure) = Type("String") Then
		Data.ShelfLifeUnitOfMeasure = Enums.TimeMeasureUnits[XDTODataObject.ShelfLifeUnitOfMeasure];
	EndIf;
	
	Data.ExpirationDate_ = Number(XDTODataObject.ExpirationDate_);
	Data.ItemVariantsOwner = Catalogs.ItemKinds.GetRef(New UUID(XDTODataObject.ItemVariantsOwner));
	
	Return Data;
	
EndFunction

Function UsersFromXML(XMLReader)
	
	XDTODataObject = XDTOFactory.ReadXML(XMLReader); // XDTODataObject
	
	DataReference = Catalogs.Users.GetRef(New UUID(XDTODataObject.Ссылка));
	Data = DataReference.GetObject();
	
	If Data = Undefined Then
		Data = Catalogs.Users.CreateItem();
		Data.SetNewObjectRef(DataReference);
	Else
		Data = DataReference.GetObject();
	EndIf;
	
	FillPropertyValues(Data, XDTODataObject);
	Data.IBUserID = New UUID(XDTODataObject.ИдентификаторПользователяИБ);
	Data.IsInternal = Boolean(XDTODataObject.Служебный);
	
	Return Data;
	
EndFunction

Function PartnersFromXML(XMLReader)
	
	XDTODataObject = XDTOFactory.ReadXML(XMLReader); // XDTODataObject
	
	DataReference = Catalogs.Partners.GetRef(New UUID(XDTODataObject.Ссылка));
	Data = DataReference.GetObject();
	
	If Data = Undefined Then
		Data = Catalogs.Partners.CreateItem();
		Data.SetNewObjectRef(DataReference);
	Else
		Data = DataReference.GetObject();
	EndIf;
	
	FillPropertyValues(Data, XDTODataObject);
	Data.Client = Boolean(XDTODataObject.Клиент);
	Data.Vendor = Boolean(XDTODataObject.Поставщик);
	If TypeOf(XDTODataObject.НаименованиеПолное) = Type("XDTODataObject") Then
		Data.DescriptionFull = "";
	Else
		Data.DescriptionFull = String(XDTODataObject.НаименованиеПолное);
	EndIf;
	
	Return Data;
	
EndFunction

Function IdentifiersOfMetadataObjectsFromXML(XMLReader)
	
	XDTODataObject = XDTOFactory.ReadXML(XMLReader); // XDTODataObject
	
	DataReference = Catalogs.MetadataObjectIDs.GetRef(New UUID(XDTODataObject.Ссылка));
	Data = DataReference.GetObject();
	
	If Data = Undefined Then
		Data = Catalogs.MetadataObjectIDs.CreateItem();
		Data.SetNewObjectRef(DataReference);
	Else
		Data = DataReference.GetObject();
	EndIf;
	
	FillPropertyValues(Data, XDTODataObject);
	If TypeOf(XDTODataObject.ПолноеИмя) = Type("XDTODataObject") Then
		Data.FullName = "";
	Else
		Data.FullName = String(XDTODataObject.ПолноеИмя);
	EndIf;
	
	Return Data;
	
EndFunction

Function WarehousesFromXML(XMLReader)
	
	XDTODataObject = XDTOFactory.ReadXML(XMLReader);
	IsFolder = Boolean(XDTODataObject.IsFolder);
	
	DataReference = Catalogs.Warehouses.GetRef(New UUID(XDTODataObject.Ref));
	Data = DataReference.GetObject();
	
	If Data = Undefined And IsFolder Then
		Data = Catalogs.Warehouses.CreateFolder();
		Data.SetNewObjectRef(DataReference);
	ElsIf Data = Undefined And Not IsFolder Then
		Data = Catalogs.Warehouses.CreateItem();
		Data.SetNewObjectRef(DataReference);
	Else
		Data = DataReference.GetObject();
	EndIf;
	
	FillPropertyValues(Data, XDTODataObject);
	
	Data.Parent = Catalogs.Warehouses.GetRef(New UUID(XDTODataObject.Parent));
	
	If IsFolder Then
		Return Data;
	EndIf;
	
	Data.UseBinLocationWarehousing                          = Boolean(XDTODataObject.UseBinLocationWarehousing);
	Data.UseBinLocationWarehousingForInformation                 = Boolean(XDTODataObject.UseBinLocationWarehousingForInformation);
	Data.UseWarehouseManagemantSystemForGoodsIssue                  = Boolean(XDTODataObject.UseWarehouseManagemantSystemForGoodsIssue);
	Data.UseWarehouseManagemantSystemForGoodsSurplusesShortages = Boolean(XDTODataObject.UseWarehouseManagemantSystemForGoodsSurplusesShortages);
	Data.UseWarehouseManagemantSystemForGoodsReceipt               = Boolean(XDTODataObject.UseWarehouseManagemantSystemForGoodsReceipt);
	Data.UseItemsBatch                         = Boolean(XDTODataObject.UseItemsBatch);
	Data.UseWarerooms                        = Boolean(XDTODataObject.UseWarerooms);
	Data.UseGoodsReceiptNoteStatuses                   = Boolean(XDTODataObject.UseGoodsReceiptNoteStatuses);
	Data.UseGoodsIssueNoteStatuses                   = Boolean(XDTODataObject.UseGoodsIssueNoteStatuses);
	Data.UseCostAccountingByBatches                        = Boolean(XDTODataObject.UseCostAccountingByBatches);
	Data.StartDateOfWareroomUse             = Date(XDTODataObject.StartDateOfWareroomUse);

	Return Data;
	
EndFunction

Function StorageRoomsFromXML(XMLReader)
	
	XDTODataObject = XDTOFactory.ReadXML(XMLReader);
	
	DataReference = Catalogs.Warerooms.GetRef(New UUID(XDTODataObject.Ref));
	Data = DataReference.GetObject();
	
	If Data = Undefined Then
		Data = Catalogs.Warerooms.CreateItem();
		Data.SetNewObjectRef(DataReference);
	Else
		Data = DataReference.GetObject();
	EndIf;
	
	FillPropertyValues(Data, XDTODataObject);
	Data.UseBinLocationWarehousing = Boolean(XDTODataObject.UseBinLocationWarehousing);
	Data.UseBinLocationWarehousingForInformation = Boolean(XDTODataObject.UseBinLocationWarehousingForInformation);
	
	Data.Owner = Catalogs.Warehouses.GetRef(New UUID(XDTODataObject.Owner));
	
	Return Data;
	
EndFunction

Function AssignmentsFromXML(XMLReader)
	
	XDTODataObject = XDTOFactory.ReadXML(XMLReader); // XDTODataObject
	
	DataReference = Catalogs.Assignments.GetRef(New UUID(XDTODataObject.Ссылка));
	Data = DataReference.GetObject();
	
	If Data = Undefined Then
		Data = Catalogs.Assignments.CreateItem();
		Data.SetNewObjectRef(DataReference);
	Else
		Data = DataReference.GetObject();
	EndIf;
	
	FillPropertyValues(Data, XDTODataObject);
	Data.ControlOnlyStock = Boolean(XDTODataObject.КонтролироватьТолькоНаличие);
	Data.ConsiderVATRates = Boolean(XDTODataObject.УчитыватьСтавкиНДС);
	
	Return Data;
	
EndFunction

Function StorageCellsFromXML(XMLReader)
	
	XDTODataObject = XDTOFactory.ReadXML(XMLReader);
	IsFolder = Boolean(XDTODataObject.IsFolder);
	
	DataReference = Catalogs.StorageBins.GetRef(New UUID(XDTODataObject.Ref));
	Data = DataReference.GetObject();
	
	If Data = Undefined And IsFolder Then
		Data = Catalogs.StorageBins.CreateFolder();
		Data.SetNewObjectRef(DataReference);
	ElsIf Data = Undefined And Not IsFolder Then
		Data = Catalogs.StorageBins.CreateItem();
		Data.SetNewObjectRef(DataReference);
	Else
		Data = DataReference.GetObject();
	EndIf;
	
	FillPropertyValues(Data, XDTODataObject);
	
	Data.Parent = Catalogs.StorageBins.GetRef(New UUID(XDTODataObject.Parent));
	Data.Owner = Catalogs.Warehouses.GetRef(New UUID(XDTODataObject.Owner));
	
	If IsFolder Then
		Return Data;
	EndIf;
	
	Data.Premise = Catalogs.Warerooms.GetRef(New UUID(XDTODataObject.Premise));
	If TypeOf(XDTODataObject.StorageBinType) = Type("String") Then
		Data.StorageBinType = Enums.TypesOfStorageCells[XDTODataObject.StorageBinType];
	EndIf;
	
	Return Data;
	
EndFunction

Function CharacteristicsOfXMLProductList(XMLReader)
	
	XDTODataObject = XDTOFactory.ReadXML(XMLReader);
	
	DataReference = Catalogs.ItemsCharacteristics.GetRef(New UUID(XDTODataObject.Ref));
	Data = DataReference.GetObject();
	
	If Data = Undefined Then
		Data = Catalogs.ItemsCharacteristics.CreateItem();
		Data.SetNewObjectRef(DataReference);
	Else
		Data = DataReference.GetObject();
	EndIf;
	
	FillPropertyValues(Data, XDTODataObject);
	
	If XDTODataObject.Properties().Get("Principal") <> Undefined Then
		TypePrincipal = XDTODataObject.TypePrincipal;
		Type = MobileWarehouseKeeperWorkspace.ObjectManagerByFullName(TypePrincipal);
		Data.Principal = Type.GetRef(New UUID(XDTODataObject.Principal));
	EndIf;
	
	If XDTODataObject.Properties().Get("Counterparty") <> Undefined Then
		TypeCounterparty = XDTODataObject.TypeCounterparty;
		Type = MobileWarehouseKeeperWorkspace.ObjectManagerByFullName(TypeCounterparty);
		Data.Counterparty = Type.GetRef(New UUID(XDTODataObject.Counterparty));
	EndIf;
	
	OwnerType = XDTODataObject.OwnerType;
	Type = MobileWarehouseKeeperWorkspace.ObjectManagerByFullName(OwnerType);
	Data.Owner = Type.GetRef(New UUID(XDTODataObject.Owner));
	
	If TypeOf(XDTODataObject.DescriptionFull) = Type("XDTODataObject") Then
		Data.DescriptionFull = "";
	Else
		Data.DescriptionFull = String(XDTODataObject.DescriptionFull);
	EndIf;
	
	Data.DeletionMark = Boolean(XDTODataObject.DeletionMark);
	
	Return Data;
	
EndFunction

Function OptionsForCompletingItemFromXML(XMLReader)
	
	XDTODataObject = XDTOFactory.ReadXML(XMLReader);
	
	DataReference = Catalogs.ProductKitConfigurations.GetRef(New UUID(XDTODataObject.Ref));
	Data = DataReference.GetObject();
	
	If Data = Undefined Then
		Data = Catalogs.ProductKitConfigurations.CreateItem();
		Data.SetNewObjectRef(DataReference);
	Else
		Data = DataReference.GetObject();
	EndIf;
	
	FillPropertyValues(Data, XDTODataObject);
	
	OwnerType = XDTODataObject.OwnerType;
	Type = MobileWarehouseKeeperWorkspace.ObjectManagerByFullName(OwnerType);
	Data.Owner = Type.GetRef(New UUID(XDTODataObject.Owner));
	
	If XDTODataObject.Properties().Get("Characteristic") <> Undefined Then
		Data.Characteristic = Catalogs.ItemsCharacteristics.GetRef(New UUID(XDTODataObject.Characteristic));
	EndIf;
	
	Data.Main = Boolean(XDTODataObject.Main);
	Data.ContainsGoods = Boolean(XDTODataObject.ContainsGoods);
	Data.ContainsServices = Boolean(XDTODataObject.ContainsServices);
	
	If TypeOf(XDTODataObject.SetPricingOption) = Type("String") Then
		Data.SetPricingOption = Enums.SetPriceCalculationOptions[XDTODataObject.SetPricingOption];
	EndIf;
	
	Return Data;
	
EndFunction

Function TypesOfProductsFromXML(XMLReader)
	
	XDTODataObject = XDTOFactory.ReadXML(XMLReader);
	IsFolder = Boolean(XDTODataObject.IsFolder);
	
	DataReference = Catalogs.ItemKinds.GetRef(New UUID(XDTODataObject.Ref));
	Data = DataReference.GetObject();
	
	If Data = Undefined And IsFolder Then
		Data = Catalogs.ItemKinds.CreateFolder();
		Data.SetNewObjectRef(DataReference);
	ElsIf Data = Undefined And Not IsFolder Then
		Data = Catalogs.ItemKinds.CreateItem();
		Data.SetNewObjectRef(DataReference);
	Else
		Data = DataReference.GetObject();
	EndIf;
	
	FillPropertyValues(Data, XDTODataObject);
	
	Data.Parent = Catalogs.ItemKinds.GetRef(New UUID(XDTODataObject.Parent));
	
	If IsFolder Then
		Return Data;
	EndIf;
	
	Data.SpecifyNumberWhenRegisteringBatch = Boolean(XDTODataObject.SpecifyNumberWhenRegisteringBatch);
	Data.UseShelfLifeOnBatchRegistration = Boolean(XDTODataObject.UseShelfLifeOnBatchRegistration);
	Data.UseRFIDTags = Boolean(XDTODataObject.UseRFIDTags);
	Data.UseBatchProductionDate = Boolean(XDTODataObject.UseBatchProductionDate);
	Data.CIMSPMSNumber = Boolean(XDTODataObject.CIMSPMSNumber);
	Data.UseUSAISManufacturerBatch = Boolean(XDTODataObject.UseUSAISManufacturerBatch);
	Data.UseCertificate2USAISBatch = Boolean(XDTODataObject.UseCertificate2USAISBatch);
	Data.UseManufacturerVetISBatch = Boolean(XDTODataObject.UseManufacturerVetISBatch);
	Data.UseWarehouseJournalRecordVetISBatch = Boolean(XDTODataObject.UseWarehouseJournalRecordVetISBatch);
	Data.UseVetISLotIDBatch = Boolean(XDTODataObject.UseVetISLotIDBatch);
	Data.MRCMOTP = Boolean(XDTODataObject.MRCMOTP);
	Data.KeepAccountingByBatch = Boolean(XDTODataObject.KeepAccountingByBatch);
	
	If TypeOf(XDTODataObject.AccountingFeature) = Type("String") Then
		Data.AccountingFeature = Enums.ItemAccountingFeatures[XDTODataObject.AccountingFeature];
	EndIf;
	If TypeOf(XDTODataObject.BatchUsageSettings) = Type("String") Then
		Data.BatchUsageSettings = Enums.ItemsBatchUsageSettings[XDTODataObject.BatchUsageSettings];
	EndIf;
	Data.GenerateBatchAutomatically = Boolean(XDTODataObject.GenerateBatchAutomatically);
	Data.BatchOwner = Catalogs.ItemKinds.GetRef(New UUID(XDTODataObject.BatchOwner));
	Data.LabelTemplateBatches = Catalogs.LabelAndPriceTagTemplates.GetRef(New UUID(XDTODataObject.LabelTemplateBatches));
	Data.BatchSettingsAreTakenFromOtherItemsKind = Boolean(XDTODataObject.BatchSettingsAreTakenFromOtherItemsKind);
	If TypeOf(XDTODataObject.WorkingNameTemplateSetOfSeries) = Type("XDTODataObject") Then
		Data.WorkingNameTemplateSetOfSeries = "";
	Else
		Data.WorkingNameTemplateSetOfSeries = String(XDTODataObject.WorkingNameTemplateSetOfSeries);
	EndIf;
	If TypeOf(XDTODataObject.ShelfLifeUnitOfMeasure) = Type("String") Then
		Data.ShelfLifeUnitOfMeasure = Enums.TimeMeasureUnits[XDTODataObject.ShelfLifeUnitOfMeasure];
	EndIf;
	If TypeOf(XDTODataObject.PrecisionOfBatchShelfLifeIndication) = Type("String") Then
		Data.PrecisionOfBatchShelfLifeIndication = Enums.AccuracyOfShelfLifeIndication[XDTODataObject.PrecisionOfBatchShelfLifeIndication];
	EndIf;
	Data.SpecifyQuantityWhenRegisteringBatch = Boolean(XDTODataObject.SpecifyQuantityWhenRegisteringBatch);
	Data.BatchAccountingPolicy = Catalogs.BatchAccountingPolicies.GetRef(New UUID(XDTODataObject.BatchAccountingPolicy));
	If TypeOf(XDTODataObject.SettingsOfPriceKeyByBatch) = Type("String") Then
		Data.SettingsOfPriceKeyByBatch = Enums.FilterOptionForPriceKey[XDTODataObject.SettingsOfPriceKeyByBatch];
	EndIf;
	
	Data.BatchAccountingPolicies.Clear(); 
	
	If XDTODataObject.Properties().Get("BatchAccountingPolicies") <> Undefined Then   
		
		If TypeOf(XDTODataObject.BatchAccountingPolicies.SeriesAccountingPolicyElement) <> Type("XDTOList") Then
			ListOfXDTOAccountingPolicyString	= New Array;
			ListOfXDTOAccountingPolicyString.Add(XDTODataObject.BatchAccountingPolicies.SeriesAccountingPolicyElement);
		Else
			ListOfXDTOAccountingPolicyString = XDTODataObject.BatchAccountingPolicies.SeriesAccountingPolicyElement;
		EndIf;
			
		For Each AccountingPolicyLine In ListOfXDTOAccountingPolicyString Do
			NewRow = Data.BatchAccountingPolicies.Add();
			NewRow.Warehouse = Catalogs.Warehouses.GetRef(New UUID(AccountingPolicyLine.Warehouse));
			NewRow.BatchAccountingPolicy = Catalogs.BatchAccountingPolicies.GetRef(New UUID(AccountingPolicyLine.BatchAccountingPolicy)); 
		EndDo;
	EndIf;
	
	Data.AttributesForBatchControl.Clear(); 
	
	If XDTODataObject.Properties().Get("AttributesForBatchControl") <> Undefined Then   
		
		If TypeOf(XDTODataObject.AttributesForBatchControl.AttributesElementForSeriesControl) <> Type("XDTOList") Then
			XDTOListStringAttributes	= New Array;
			XDTOListStringAttributes.Add(XDTODataObject.AttributesForBatchControl.AttributesElementForSeriesControl);
		Else
			XDTOListStringAttributes = XDTODataObject.AttributesForBatchControl.AttributesElementForSeriesControl;
		EndIf;
			
		For Each AttributesString In XDTOListStringAttributes Do
			NewRow = Data.AttributesForBatchControl.Add();
			NewRow.IsAddlAttribute = Boolean(AttributesString.IsAddlAttribute);
			NewRow.Property = ChartsOfCharacteristicTypes.AdditionalAttributesAndInfo.GetRef(New UUID(AttributesString.Property));
			NewRow.RequiredToFill = Boolean(AttributesString.RequiredToFill); 
		EndDo;
	EndIf;
	
	Return Data;
	
EndFunction

Function SeriesAccountingPoliciesFromXML(XMLReader)
	
	XDTODataObject = XDTOFactory.ReadXML(XMLReader); // XDTODataObject
	
	DataReference = Catalogs.BatchAccountingPolicies.GetRef(New UUID(XDTODataObject.Ссылка));
	Data = DataReference.GetObject();
	
	If Data = Undefined Then
		Data = Catalogs.BatchAccountingPolicies.CreateItem();
		Data.SetNewObjectRef(DataReference);
	Else
		Data = DataReference.GetObject();
	EndIf;
	
	FillPropertyValues(Data, XDTODataObject);
	
	If TypeOf(XDTODataObject.ТипПолитики) = Type("String") Then
		Data.PolicyType = Enums.TypesOfBatchSpecificationPolicies[XDTODataObject.ТипПолитики];
	EndIf;
	Data.SpecifyDuringProduction = Boolean(XDTODataObject.УказыватьПриПроизводствеПродукции);
	Data.SpecifyOnMaterialConsumption = Boolean(XDTODataObject.УказыватьПриРасходеМатериалов);
	Data.SpecifyByPickingResult = Boolean(XDTODataObject.УказыватьПоФактуОтбора);
	Data.SpecifyOnReturnToWarehouse = Boolean(XDTODataObject.УказыватьПриВозвратеНаСклад);
	Data.SpecifyOnShipment = Boolean(XDTODataObject.УказыватьПриОтгрузке);
	Data.SpecifyOnProductionIssueToBusinessUnit = Boolean(XDTODataObject.УказыватьПриВыпускеВПодразделение);
	Data.SpecifyWhenMovingMaterials = Boolean(XDTODataObject.УказыватьПриДвиженииМатериалов);
	Data.SpecifyWhenMovingProducts = Boolean(XDTODataObject.УказыватьПриДвиженииПродукции);
	Data.SpecifyOnRetailShipment = Boolean(XDTODataObject.УказыватьПриОтгрузкеВРозницу);
	Data.SpecifyOnShipmentToCustomer = Boolean(XDTODataObject.УказыватьПриОтгрузкеКлиенту);
	Data.SpecifyWhenShippingKitsForDisassembly = Boolean(XDTODataObject.УказыватьПриОтгрузкеКомплектовДляРазборки);
	Data.SpecifyWhenShippingComponentsForAssembly = Boolean(XDTODataObject.УказыватьПриОтгрузкеКомплектующихДляСборки);
	Data.SpecifyOnShipmentForInternalNeeds = Boolean(XDTODataObject.УказыватьПриОтгрузкеНаВнутренниеНужды);
	Data.SpecifyOnShipmentByReturnToVendor = Boolean(XDTODataObject.УказыватьПриОтгрузкеПоВозвратуПоставщику);
	Data.SpecifyOnShipmentByTransfer = Boolean(XDTODataObject.УказыватьПриОтгрузкеПоПеремещению);
	Data.SpecifyWhenRecordingSurpluses = Boolean(XDTODataObject.УказыватьПриОтраженииИзлишков);
	Data.SpecifyUponAllocatingCostsToProductionLots = Boolean(XDTODataObject.УказыватьПриОтраженииЗатратНаПроизводство);
	Data.SpecifyWhenRecordingShortages = Boolean(XDTODataObject.УказыватьПриОтраженииНедостач);
	Data.SpecifyUponTransferBetweenWarerooms = Boolean(XDTODataObject.УказыватьПриПеремещенииМеждуПомещениями);
	Data.SpecifyWhenRecountingInventory = Boolean(XDTODataObject.УказыватьПриПересчетеТоваров);
	Data.SpecifyWhenPlanningPicking = Boolean(XDTODataObject.УказыватьПриПланированииОтбора);
	Data.SpecifyWhenPlanningShipment = Boolean(XDTODataObject.УказыватьПриПланированииОтгрузки);
	Data.SpecifyOnReceiving = Boolean(XDTODataObject.УказыватьПриПриемке);
	Data.SpecifyWhenReceivingMaterials = Boolean(XDTODataObject.УказыватьПриПолученииМатериалов);
	Data.SpecifyWhenReceivingComponentsAfterDisassembly = Boolean(XDTODataObject.УказыватьПриПриемкеКомплектующихПослеРазборки);
	Data.SpecifyOnReceivingFromVendor = Boolean(XDTODataObject.УказыватьПриПриемкеОтПоставщика);
	Data.SpecifyOnReceivingByReturnFromCustomer = Boolean(XDTODataObject.УказыватьПриПриемкеПоВозвратуОтКлиента);
	Data.SpecifyOnReceivingByTransfer = Boolean(XDTODataObject.УказыватьПриПриемкеПоПеремещению);
	Data.SpecifyOnReceivingByOtherRecordingAsReceived = Boolean(XDTODataObject.УказыватьПриПриемкеПоПрочемуОприходованию);
	Data.SpecifyWhenReceivingProductsFromManufacturing = Boolean(XDTODataObject.УказыватьПриПриемкеПродукцииИзПроизводства);
	Data.SpecifyWhenReceivingAssembledKits = Boolean(XDTODataObject.УказыватьПриПриемкеСобранныхКомплектов);
	Data.BatchesAccountingByFEFO = Boolean(XDTODataObject.УчетСерийПоFEFO);
	Data.AccountForRemainingSeries = Boolean(XDTODataObject.УчитыватьОстаткиСерий);
	Data.UseCostAccountingByBatches = Boolean(XDTODataObject.УчитыватьСебестоимостьПоСериям);
	Data.SpecifyOnReturnOfGoodsNotAcceptedByRecipient = Boolean(XDTODataObject.УказыватьПриВозвратеНепринятыхПолучателемТоваров);
	Data.ForWarehouse = Boolean(XDTODataObject.ДляСклада);
	Data.ForProduction = Boolean(XDTODataObject.ДляПроизводства);
	Data.SpecifyOnGoodsMarkingForSPMS = Boolean(XDTODataObject.УказыватьПриМаркировкеПродукцииДляГИСМ);
	Data.BatchesAccountingInUninvoicedGoodsDeliveries = Boolean(XDTODataObject.УчетСерийВНеотфактурованныхПоставкахТоваров);
	Data.BatchesAccountingOfGoodsInTransitFromVendor = Boolean(XDTODataObject.УчетТоваровВПутиОтПоставщикаПоСериям);
	Data.BatchesAccountingInDepositedGoods = Boolean(XDTODataObject.УчетСерийВПереданныхНаХранениеТоварах);
	Data.SeriesAccountingOfGoodsTransferredToSubcontractor = Boolean(XDTODataObject.УчетСерийПереданныхПереработчикуТоваров);
	Data.SeriesAccountingInventoryInOperation = Boolean(XDTODataObject.УчитыватьСерииТМЦВЭксплуатации);
	Data.AccountingOfBatchesInGoodsTransferredToCommissionAgent = Boolean(XDTODataObject.УчетСерийВПереданныхНаКомиссиюТоваров);
	
	Return Data;
	
EndFunction

Function SeriesOfItemsFromXML(XMLReader)
	
	XDTODataObject = XDTOFactory.ReadXML(XMLReader);
	
	DataReference = Catalogs.ItemsBatches.GetRef(New UUID(XDTODataObject.Ref));
	Data = DataReference.GetObject();
	
	If Data = Undefined Then
		Data = Catalogs.ItemsBatches.CreateItem();
		Data.SetNewObjectRef(DataReference);
	Else
		Data = DataReference.GetObject();
	EndIf;
	
	FillPropertyValues(Data, XDTODataObject);
	
	Data.ProductKind = Catalogs.ItemKinds.GetRef(New UUID(XDTODataObject.ProductKind));
	Data.DeletionMark = Boolean(XDTODataObject.DeletionMark);
	
	Data.ValidUntil_ = Date(XDTODataObject.ValidUntil_);
	Data.ProductionDate = Date(XDTODataObject.ProductionDate);
	If TypeOf(XDTODataObject.Number) = Type("XDTODataObject") Then
		Data.Number = "";
	Else
		Data.Number = String(XDTODataObject.Number);
	EndIf;
	
	If TypeOf(XDTODataObject.RFIDTID) = Type("XDTODataObject") Then
		Data.RFIDTID = "";
	Else
		Data.RFIDTID = String(XDTODataObject.RFIDTID);
	EndIf;
	If TypeOf(XDTODataObject.RFIDUser) = Type("XDTODataObject") Then
		Data.RFIDUser = "";
	Else
		Data.RFIDUser = String(XDTODataObject.RFIDUser);
	EndIf;
	If TypeOf(XDTODataObject.RFIDEPC) = Type("XDTODataObject") Then
		Data.RFIDEPC = "";
	Else
		Data.RFIDEPC = String(XDTODataObject.RFIDEPC);
	EndIf;
	If TypeOf(XDTODataObject.EPCGTIN) = Type("XDTODataObject") Then
		Data.EPCGTIN = "";
	Else
		Data.EPCGTIN = String(XDTODataObject.EPCGTIN);
	EndIf;
	
	Data.RFIDTagIsCorruptedAndCannotBeRead = Boolean(XDTODataObject.RFIDTagIsCorruptedAndCannotBeRead);
	
	If TypeOf(XDTODataObject.NumberOfSPMSControlIdentificationMark) = Type("XDTODataObject") Then
		Data.NumberOfSPMSControlIdentificationMark = "";
	Else
		Data.NumberOfSPMSControlIdentificationMark = String(XDTODataObject.NumberOfSPMSControlIdentificationMark);
	EndIf;
	
	If TypeOf(XDTODataObject.LotIDVetIS) = Type("XDTODataObject") Then
		Data.LotIDVetIS = "";
	Else
		Data.LotIDVetIS = String(XDTODataObject.LotIDVetIS);
	EndIf;
	Data.MaximumRetailPriceMOTP = Number(XDTODataObject.MaximumRetailPriceMOTP);
	
	Return Data;
	
EndFunction

Function ReportOptionsFromXML(XMLReader)
	
	XDTODataObject = XDTOFactory.ReadXML(XMLReader); // XDTODataObject
	
	DataReference = Catalogs.ReportsOptions.GetRef(New UUID(XDTODataObject.Ссылка));
	Data = DataReference.GetObject();
	
	If Data = Undefined Then
		Data = Catalogs.ReportsOptions.CreateItem();
		Data.SetNewObjectRef(DataReference);
	Else
		Data = DataReference.GetObject();
	EndIf;
	
	FillPropertyValues(Data, XDTODataObject);
	
	Return Data;
	
EndFunction

Function ICPDashboardsFromXML(XMLReader)
	
	XDTODataObject = XDTOFactory.ReadXML(XMLReader); // XDTODataObject
	
	DataReference = Catalogs.PerformanceDashboards.GetRef(New UUID(XDTODataObject.Ссылка));
	Data = DataReference.GetObject();
	
	If Data = Undefined Then
		Data = Catalogs.PerformanceDashboards.CreateItem();
		Data.SetNewObjectRef(DataReference);
	Else
		Data = DataReference.GetObject();
	EndIf;
	
	FillPropertyValues(Data, XDTODataObject);
	
	Data.Author = Catalogs.Users.GetRef(New UUID(XDTODataObject.Автор));
    Data.Icon = XDTODataObject.Иконка.ValueStorage;
	
	Data.DashboardUser.Clear();
	If XDTODataObject.ПользователиДашборда.Properties().Get("User") <> Undefined Then
		If TypeOf(XDTODataObject.ПользователиДашборда.Пользователь) = Type("String") Then
			NewRow = Data.DashboardUser.Add();
			NewRow.User = Catalogs.Users.GetRef(New UUID(XDTODataObject.ПользователиДашборда.Пользователь));
		Else	
			For Each UserString In XDTODataObject.ПользователиДашборда.Пользователь Do
				NewRow = Data.DashboardUser.Add();
				NewRow.User = Catalogs.Users.GetRef(New UUID(UserString));
			EndDo;
		EndIf;
	EndIf;
	
	Return Data;
	
EndFunction

#EndRegion

#Region InformationRegisters

Function ProductBarcodesFromXML(XMLReader)
	
	XDTODataObject = XDTOFactory.ReadXML(XMLReader);
	
	Barcode = XDTODataObject.Barcode;
	Products  = Catalogs.Products.GetRef(New UUID(XDTODataObject.Products));
	Characteristic = Catalogs.ItemsCharacteristics.GetRef(New UUID(XDTODataObject.Characteristic));
	Series = Catalogs.ItemsBatches.GetRef(New UUID(XDTODataObject.Series));
	Package = Catalogs.PackagesAndUnitsOfMeasure.GetRef(New UUID(XDTODataObject.Package));
			
	RecordSet = InformationRegisters.ItemsBarcodes.CreateRecordSet();

	RecordSet.Filter.Barcode.Set(Barcode);
	RecordSet.Filter.Products.Set(Products);
	RecordSet.Filter.Characteristic.Set(Characteristic);
	RecordSet.Filter.Series.Set(Series);
	RecordSet.Filter.Package.Set(Package);

	NewRecord = RecordSet.Add();
	
	NewRecord.Barcode       = Barcode;
	NewRecord.Products   = Products;
	NewRecord.Characteristic = Characteristic;
	NewRecord.Series          = Series;
	NewRecord.Package       = Package;
	
	Try
		RecordSet.Write();
	Except
	EndTry;
	
	Return Undefined;
	
EndFunction

Function ReportsSnapshotsFromXML(XMLReader)
	
	XDTODataObject = XDTOFactory.ReadXML(XMLReader);
	
	User = Catalogs.Users.GetRef(New UUID(XDTODataObject.User));
	If XDTODataObject.ValueTypeReport = "MetadataObjectIDs" Then
		Report = Catalogs.MetadataObjectIDs.GetRef(New UUID(XDTODataObject.Report));
	Else
		Report = Catalogs.ExtensionObjectIDs.GetRef(New UUID(XDTODataObject.Report));
	EndIf;
	If XDTODataObject.OptionValueType = "ReportsOptions" Then
		Variant = Catalogs.ReportsOptions.GetRef(New UUID(XDTODataObject.ReportVariant));
	Else
		Variant = Catalogs.PerformanceDashboards.GetRef(New UUID(XDTODataObject.ReportVariant));
	EndIf;
	
	RecordManager = InformationRegisters.ReportsSnapshots.CreateRecordManager();
	
	RecordManager.User = User;
	RecordManager.Report = Report;
	RecordManager.Variant = Variant;
	RecordManager.UserSettingsHash = XDTODataObject.UserSettingsHash;
	
	RecordManager.ReportResult = XDTODataObject.ReportResult.ValueStorage;
	RecordManager.UpdateDate = Date(XDTODataObject.UpdateDate);
	RecordManager.LastViewedDate = Date(XDTODataObject.LastViewedDate);
	
	RecordManager.ReportUpdateError = Boolean(XDTODataObject.ReportUpdateError);
	
	Try
		RecordManager.Write();
	Except
	EndTry;
	
	Return Undefined;
	
EndFunction

Function BlockingStorageCellsFromXML(XMLReader)
	
	XDTODataObject = XDTOFactory.ReadXML(XMLReader);
	
	RecordSet = InformationRegisters.StorageBinsLocks.CreateRecordSet();   
	If XDTODataObject.RecorderValueType = "SetStorageBinLocks" Then
		Recorder = Documents.SetStorageBinLocks.GetRef(New UUID(XDTODataObject.Recorder));
	Else
		Recorder = Documents.InventoryRecount.GetRef(New UUID(XDTODataObject.Recorder));
	EndIf;   
	
	RecordSet.Filter.Recorder.Set(Recorder);
	
	If XDTODataObject.Properties().Get("Locks") <> Undefined Then   
		
		If TypeOf(XDTODataObject.Locks.LockItem) <> Type("XDTOList") Then
			ListOfXDTOLockString	= New Array;
			ListOfXDTOLockString.Add(XDTODataObject.Locks.LockItem);
		Else
			ListOfXDTOLockString = XDTODataObject.Locks.LockItem;
		EndIf;
			
		For Each LockString In ListOfXDTOLockString Do
			NewRecord = RecordSet.Add();
	
			NewRecord.Recorder	  = Recorder;
			NewRecord.Active	  = Boolean(LockString.Active);
			NewRecord.Cell 		  = Catalogs.StorageBins.GetRef(New UUID(LockString.Cell));
			If TypeOf(LockString.LockType) = Type("String") Then
				NewRecord.LockType = Enums.TypesOfWarehouseBinLocks[LockString.LockType];
			EndIf;
		EndDo;
	EndIf;
	
	Try
		RecordSet.Write();
	Except
	EndTry;
	
	Return Undefined;
	
EndFunction

Function AddressWarehouseSettingsFromXML(XMLReader)
	
	XDTODataObject = XDTOFactory.ReadXML(XMLReader);
	
	RecordSet = InformationRegisters.SettingsOfBinLocationWarehouses.CreateRecordSet();   
	Warehouse = Catalogs.Warehouses.GetRef(New UUID(XDTODataObject.Warehouse));
	Premise = Catalogs.Warerooms.GetRef(New UUID(XDTODataObject.Premise));
	RecordSet.Filter.Warehouse.Set(Warehouse);
	RecordSet.Filter.Premise.Set(Premise);
	
	If XDTODataObject.Properties().Get("SettingsForWarehouses") <> Undefined Then   
		
		If TypeOf(XDTODataObject.SettingsForWarehouses.WarehouseSettingsElement) <> Type("XDTOList") Then
			XDTOListWarehouseSettingsLine	= New Array;
			XDTOListWarehouseSettingsLine.Add(XDTODataObject.SettingsForWarehouses.WarehouseSettingsElement);
		Else
			XDTOListWarehouseSettingsLine = XDTODataObject.SettingsForWarehouses.WarehouseSettingsElement;
		EndIf;
			
		For Each WarehouseSettingsLine In XDTOListWarehouseSettingsLine Do
			NewRecord = RecordSet.Add();
	
			NewRecord.Warehouse = Warehouse;
			NewRecord.Premise = Premise;
			NewRecord.UseBinLocationWarehousing = Boolean(WarehouseSettingsLine.UseBinLocationWarehousing);
			NewRecord.StartDateOfUsingWarehouseBinSystem = Date(WarehouseSettingsLine.StartDateOfUsingWarehouseBinSystem);
		EndDo;
	EndIf;
	
	Try
		RecordSet.Write();
	Except
	EndTry;
	
	Return Undefined;
	
EndFunction

Function PlacementOfItemsByStorageCellsFromXML(XMLReader)
	
	XDTODataObject = XDTOFactory.ReadXML(XMLReader);
	
	RecordSet = InformationRegisters.PlaceProductsInStorageBins.CreateRecordSet();   
	Products = Catalogs.Products.GetRef(New UUID(XDTODataObject.Products));
	Cell = Catalogs.StorageBins.GetRef(New UUID(XDTODataObject.Cell));
	Warehouse = Catalogs.Warehouses.GetRef(New UUID(XDTODataObject.Warehouse));
	Premise = Catalogs.Warerooms.GetRef(New UUID(XDTODataObject.Premise));
	
	RecordSet.Filter.Products.Set(Products);
	RecordSet.Filter.Cell.Set(Cell);
	RecordSet.Filter.Warehouse.Set(Warehouse);
	RecordSet.Filter.Premise.Set(Premise);
	
	If XDTODataObject.Properties().Get("Location") <> Undefined Then   
		
		If TypeOf(XDTODataObject.Location.PlacementElement) <> Type("XDTOList") Then
			ListOfXDTOStringPlacement = New Array;
			ListOfXDTOStringPlacement.Add(XDTODataObject.Location.PlacementElement);
		Else
			ListOfXDTOStringPlacement = XDTODataObject.Location.PlacementElement;
		EndIf;
			
		For Each LinePlacement In ListOfXDTOStringPlacement Do
			NewRecord = RecordSet.Add();
			
			NewRecord.Products = Products;
			NewRecord.Cell = Cell;
			NewRecord.Warehouse = Warehouse;
			NewRecord.Premise = Premise;
			NewRecord.MainStorageBin = Boolean(LinePlacement.MainStorageBin);
		EndDo;
	EndIf;
	
	Try
		RecordSet.Write();
	Except
	EndTry;
	
	Return Undefined;
	
EndFunction

#EndRegion

#Region Documents

Function SettingCellLocksFromXML(XMLReader)
	
	XDTODataObject = XDTOFactory.ReadXML(XMLReader);
	
	DataReference = Documents.SetStorageBinLocks.GetRef(New UUID(XDTODataObject.Ref));
	Data = DataReference.GetObject();
	
	If Data = Undefined Then
		Data = Documents.SetStorageBinLocks.CreateDocument();
		Data.SetNewObjectRef(DataReference);
	Else
		Data = DataReference.GetObject();
	EndIf;
			
	FillPropertyValues(Data, XDTODataObject); 
	
	Data.Date = Date(XDTODataObject.Date);
	Data.DeletionMark = Boolean(XDTODataObject.DeletionMark);
	Data.Posted = Boolean(XDTODataObject.Posted);
	If XDTODataObject.Properties().Get("EmployeeResponsible") <> Undefined Then
		Data.EmployeeResponsible = Catalogs.Users.GetRef(New UUID(XDTODataObject.EmployeeResponsible));
	EndIf;
	Data.Warehouse = Catalogs.Warehouses.GetRef(New UUID(XDTODataObject.Warehouse));
	Data.Premise = Catalogs.Warerooms.GetRef(New UUID(XDTODataObject.Premise));

	Return Data;
	
EndFunction

Function InventoryCountingFromXML(XMLReader)
	
	XDTODataObject = XDTOFactory.ReadXML(XMLReader);
	
	DataReference = Documents.InventoryRecount.GetRef(New UUID(XDTODataObject.Ref));
	Data = DataReference.GetObject();
	
	If Data = Undefined Then
		Data = Documents.InventoryRecount.CreateDocument();
		Data.SetNewObjectRef(DataReference);
	Else
		Data = DataReference.GetObject();
	EndIf;
			
	FillPropertyValues(Data, XDTODataObject); 
	
	Data.Date = Date(XDTODataObject.Date);
	Data.DeletionMark = Boolean(XDTODataObject.DeletionMark);
	Data.Posted = Boolean(XDTODataObject.Posted);
	Data.PrintQuantityByRecords = Boolean(XDTODataObject.PrintQuantityByRecords);
	Data.Performer = Catalogs.Users.GetRef(New UUID(XDTODataObject.Performer));
	If XDTODataObject.Properties().Get("EmployeeResponsible") <> Undefined Then
		Data.EmployeeResponsible = Catalogs.Users.GetRef(New UUID(XDTODataObject.EmployeeResponsible));
	EndIf;	
	Data.Warehouse = Catalogs.Warehouses.GetRef(New UUID(XDTODataObject.Warehouse));
    Data.Premise = Catalogs.Warerooms.GetRef(New UUID(XDTODataObject.Premise));
	If TypeOf(XDTODataObject.Status) = Type("String") Then
		Data.Status = Enums.InventoryRecountStatuses[XDTODataObject.Status];
	EndIf;
	
	Data.Goods.Clear();
	
	If XDTODataObject.Properties().Get("Goods") <> Undefined Then
		
		If TypeOf(XDTODataObject.Goods.Item_Products) <> Type("XDTOList") Then
			ListOfXDTORowGoods	= New Array;
			ListOfXDTORowGoods.Add(XDTODataObject.Goods.Item_Products);
		Else
			ListOfXDTORowGoods = XDTODataObject.Goods.Item_Products;
		EndIf;
			
		For Each LineProducts_ In ListOfXDTORowGoods Do
			NewRow = Data.Goods.Add();
			NewRow.Count = Number(LineProducts_.Count);
			NewRow.NumberOfPackages = Number(LineProducts_.NumberOfPackages);
			NewRow.CountReal = Number(LineProducts_.CountReal);
			NewRow.NumberOfPackagesReal = Number(LineProducts_.NumberOfPackagesReal);
			NewRow.Products = Catalogs.Products.GetRef(New UUID(LineProducts_.Products));
			NewRow.Package = Catalogs.PackagesAndUnitsOfMeasure.GetRef(New UUID(LineProducts_.Package));
			NewRow.Characteristic = Catalogs.ItemsCharacteristics.GetRef(New UUID(LineProducts_.Characteristic));
			NewRow.Purpose = Catalogs.Assignments.GetRef(New UUID(LineProducts_.Purpose));
			NewRow.Cell = Catalogs.StorageBins.GetRef(New UUID(LineProducts_.Cell));
			NewRow.SurplusDamage = Boolean(LineProducts_.SurplusDamage);
			NewRow.Series = Catalogs.ItemsBatches.GetRef(New UUID(LineProducts_.Series));
			NewRow.BatchesIndicationStatus = Number(LineProducts_.BatchesIndicationStatus);
		EndDo;
	EndIf;
	
	Return Data;
	
EndFunction 

Function ReceiptGoodsOrderFromXML(XMLReader)
	
	XDTODataObject = XDTOFactory.ReadXML(XMLReader); // XDTODataObject
	
	DataReference = Documents.GoodsReceiptNote.GetRef(New UUID(XDTODataObject.Ссылка));
	Data = DataReference.GetObject();
	
	If Data = Undefined Then
		Data = Documents.GoodsReceiptNote.CreateDocument();
		Data.SetNewObjectRef(DataReference);
	Else
		Data = DataReference.GetObject();
	EndIf;
			
	FillPropertyValues(Data, XDTODataObject); 
	
	Data.Date = Date(XDTODataObject.Дата);
	Data.DeletionMark = Boolean(XDTODataObject.ПометкаУдаления);
	Data.Posted = Boolean(XDTODataObject.Проведен);
	Data.Warehouse = Catalogs.Warehouses.GetRef(New UUID(XDTODataObject.Склад));
	Data.Performer = Catalogs.Users.GetRef(New UUID(XDTODataObject.Исполнитель));
	
	TypeSender = XDTODataObject.ТипОтправитель;
	Type = MobileWarehouseKeeperWorkspace.ObjectManagerByFullName(TypeSender);
	Data.Sender = Type.GetRef(New UUID(XDTODataObject.Отправитель));
	
	TypeOfOrder = XDTODataObject.ТипРаспоряжение;
	Type = MobileWarehouseKeeperWorkspace.ObjectManagerByFullName(TypeOfOrder);
	Data.ReferenceOrder = Type.GetRef(New UUID(XDTODataObject.Распоряжение));
	
	If TypeOf(XDTODataObject.Статус) = Type("String") Then
		Data.Status = Enums.GoodsReceiptNoteStatuses[XDTODataObject.Статус];
	EndIf;
	Data.Premise = Catalogs.Warerooms.GetRef(New UUID(XDTODataObject.Помещение));
    Data.ReceivingArea = Catalogs.StorageBins.GetRef(New UUID(XDTODataObject.ЗонаПриемки));
	If XDTODataObject.Properties().Get("IncomingDocumentDate") <> Undefined Then
		Data.IncomingDocumentDate = Date(XDTODataObject.ДатаВходящегоДокумента);
	EndIf;
	If TypeOf(XDTODataObject.ХозяйственнаяОперация) = Type("String") Then
		Data.BusinessOperation = Enums.BusinessTransactions[XDTODataObject.ХозяйственнаяОперация];
	EndIf;
	If TypeOf(XDTODataObject.СкладскаяОперация) = Type("String") Then
		Data.WarehouseOperation = Enums.WarehouseTransactions[XDTODataObject.СкладскаяОперация];
	EndIf;
	
	Data.Goods.Clear(); 
	
	If XDTODataObject.Properties().Get("Goods") <> Undefined Then   
		
		If TypeOf(XDTODataObject.Товары.ЭлементТовары) <> Type("XDTOList") Then
			ListOfXDTORowGoods	= New Array;
			ListOfXDTORowGoods.Add(XDTODataObject.Товары.ЭлементТовары);
		Else
			ListOfXDTORowGoods = XDTODataObject.Товары.ЭлементТовары;
		EndIf;
			
		For Each LineProducts_ In ListOfXDTORowGoods Do
			NewRow = Data.Goods.Add();
			NewRow.Count = Number(LineProducts_.Count);
			NewRow.NumberOfPackages = Number(LineProducts_.NumberOfPackages);
			NewRow.Products = Catalogs.Products.GetRef(New UUID(LineProducts_.Products));
			NewRow.Package = Catalogs.PackagesAndUnitsOfMeasure.GetRef(New UUID(LineProducts_.Package));
		    NewRow.Characteristic = Catalogs.ItemsCharacteristics.GetRef(New UUID(LineProducts_.Characteristic));
			NewRow.BatchesIndicationStatus = Number(LineProducts_.BatchesIndicationStatus);
			If XDTODataObject.Properties().Get("LineProducts_.DocumentShipments") <> Undefined Then
				NewRow.DocumentShipments = Documents.GoodsReceiptNote.GetRef(New UUID(LineProducts_.DocumentShipments));
			EndIf;
			If TypeOf(LineProducts_.Barcode) = Type("XDTODataObject") Then
				NewRow.Barcode = "";
			Else
				NewRow.Barcode = String(LineProducts_.Barcode);
			EndIf;
			
			NewRow.Series = Catalogs.ItemsBatches.GetRef(New UUID(LineProducts_.Series));
			NewRow.PackingList = Documents.PackingList.GetRef(New UUID(LineProducts_.PackingList));
			NewRow.PackingListParent = Documents.PackingList.GetRef(New UUID(LineProducts_.PackingListParent));
			NewRow.Purpose = Catalogs.Assignments.GetRef(New UUID(LineProducts_.Purpose));
		EndDo;
	EndIf;
	
	Return Data;
	
EndFunction

Function ExpenseOrderFromXML(XMLReader)
	
	XDTODataObject = XDTOFactory.ReadXML(XMLReader);
	
	DataReference = Documents.GoodsIssueNote.GetRef(New UUID(XDTODataObject.Ref));
	Data = DataReference.GetObject();
	
	If Data = Undefined Then
		Data = Documents.GoodsIssueNote.CreateDocument();
		Data.SetNewObjectRef(DataReference);
	Else
		Data = DataReference.GetObject();
	EndIf;
			
	FillPropertyValues(Data, XDTODataObject); 
	
	Data.Date = Date(XDTODataObject.Date);
	Data.DateOfShipment = Date(XDTODataObject.DateOfShipment);
	Data.DeletionMark = Boolean(XDTODataObject.DeletionMark);
	Data.Posted = Boolean(XDTODataObject.Posted);
	Data.ShippingZone = Catalogs.StorageBins.GetRef(New UUID(XDTODataObject.ShippingZone));
	Data.EmployeeResponsible = Catalogs.Users.GetRef(New UUID(XDTODataObject.EmployeeResponsible));
	Data.Inspector = Catalogs.Users.GetRef(New UUID(XDTODataObject.Inspector));
	Data.ShippedBy = Catalogs.Users.GetRef(New UUID(XDTODataObject.ShippedBy));
	Data.Premise = Catalogs.Warerooms.GetRef(New UUID(XDTODataObject.Premise));
	Data.Warehouse = Catalogs.Warehouses.GetRef(New UUID(XDTODataObject.Warehouse));
	
	Type_Recipient = XDTODataObject.Type_Recipient;
	Type = MobileWarehouseKeeperWorkspace.ObjectManagerByFullName(Type_Recipient);
	Data.Recipient = Type.GetRef(New UUID(XDTODataObject.Recipient));
	
	If TypeOf(XDTODataObject.Status) = Type("String") Then
		Data.Status = Enums.GoodsIssueNoteStatuses[XDTODataObject.Status];
	EndIf;
	
	Data.GoodsByReferences.Clear(); 
	
	If XDTODataObject.Properties().Get("GoodsByReferences") <> Undefined Then   
		
		If TypeOf(XDTODataObject.GoodsByReferences.GoodsByOrderElement) <> Type("XDTOList") Then
			ListOfXDTORowGoods	= New Array;
			ListOfXDTORowGoods.Add(XDTODataObject.GoodsByReferences.GoodsByOrderElement);
		Else
			ListOfXDTORowGoods = XDTODataObject.GoodsByReferences.GoodsByOrderElement;
		EndIf;
			
		For Each LineProducts_ In ListOfXDTORowGoods Do
			NewRow = Data.GoodsByReferences.Add();
			NewRow.Products = Catalogs.Products.GetRef(New UUID(LineProducts_.Products));
			NewRow.Characteristic = Catalogs.ItemsCharacteristics.GetRef(New UUID(LineProducts_.Characteristic));
			NewRow.Purpose = Catalogs.Assignments.GetRef(New UUID(LineProducts_.Purpose));
			NewRow.Series = Catalogs.ItemsBatches.GetRef(New UUID(LineProducts_.Series));
			NewRow.BatchesIndicationStatus = Number(LineProducts_.BatchesIndicationStatus);
			If LineProducts_.Properties().Get("ReferenceOrder") <> Undefined Then
				TypeOfOrder = LineProducts_.TypeOfOrder;
				Type = MobileWarehouseKeeperWorkspace.ObjectManagerByFullName(TypeOfOrder);
				NewRow.ReferenceOrder = Type.GetRef(New UUID(LineProducts_.ReferenceOrder));
			EndIf;
			NewRow.Count = Number(LineProducts_.Count);
		EndDo;
	EndIf;
	
	Data.ShippedGoods.Clear(); 
	
	If XDTODataObject.Properties().Get("ShippedGoods") <> Undefined Then   
		
		If TypeOf(XDTODataObject.ShippedGoods.GoodsToBeShippedElement) <> Type("XDTOList") Then
			ListOfXDTORowGoods	= New Array;
			ListOfXDTORowGoods.Add(XDTODataObject.ShippedGoods.GoodsToBeShippedElement);
		Else
			ListOfXDTORowGoods = XDTODataObject.ShippedGoods.GoodsToBeShippedElement;
		EndIf;
			
		For Each LineProducts_ In ListOfXDTORowGoods Do
			NewRow = Data.ShippedGoods.Add();
			NewRow.Products = Catalogs.Products.GetRef(New UUID(LineProducts_.Products));
			NewRow.Characteristic = Catalogs.ItemsCharacteristics.GetRef(New UUID(LineProducts_.Characteristic));
			NewRow.Purpose = Catalogs.Assignments.GetRef(New UUID(LineProducts_.Purpose));
			NewRow.Series = Catalogs.ItemsBatches.GetRef(New UUID(LineProducts_.Series));
			NewRow.BatchesIndicationStatus = Number(LineProducts_.BatchesIndicationStatus);
			NewRow.ThisIsAPackingList = Boolean(LineProducts_.ThisIsAPackingList);
			NewRow.ThisIsInternalRowOfEmptyPackingList = Number(LineProducts_.ThisIsInternalRowOfEmptyPackingList);
			If LineProducts_.Properties().Get("PackingListParent") <> Undefined Then
				NewRow.PackingListParent = Documents.PackingList.GetRef(New UUID(LineProducts_.PackingListParent));
			EndIf;
			If LineProducts_.Properties().Get("PackingList") <> Undefined Then
				NewRow.PackingList = Documents.PackingList.GetRef(New UUID(LineProducts_.PackingList));
			EndIf;
			NewRow.Package = Catalogs.PackagesAndUnitsOfMeasure.GetRef(New UUID(LineProducts_.Package));
			NewRow.Count = Number(LineProducts_.Count);
			NewRow.NumberOfPackages = Number(LineProducts_.NumberOfPackages);
			If TypeOf(LineProducts_.Action) = Type("String") Then
				NewRow.Action = Enums.ActionsWithGoodsIssueNoteRows[LineProducts_.Action];
			EndIf;
		EndDo;
	EndIf;
	
	Return Data;
	
EndFunction

Function GoodsPickingPlacementFromXML(XMLReader)
	
	XDTODataObject = XDTOFactory.ReadXML(XMLReader);
	
	DataReference = Documents.GoodsPickingPlacement.GetRef(New UUID(XDTODataObject.Ref));
	Data = DataReference.GetObject();
	
	If Data = Undefined Then
		Data = Documents.GoodsPickingPlacement.CreateDocument();
		Data.SetNewObjectRef(DataReference);
	Else
		Data = DataReference.GetObject();
	EndIf;
			
	FillPropertyValues(Data, XDTODataObject); 
	
	Data.Date = Date(XDTODataObject.Date);
	Data.DeletionMark = Boolean(XDTODataObject.DeletionMark);
	Data.Posted = Boolean(XDTODataObject.Posted);	
	If TypeOf(XDTODataObject.OperationKind) = Type("String") Then
		Data.OperationKind = Enums.OperationKindsOfGoodsPlacementPicking[XDTODataObject.OperationKind];
	EndIf;	
	Data.ShippingZone = Catalogs.StorageBins.GetRef(New UUID(XDTODataObject.ShippingZone));
	Data.ReceivingArea = Catalogs.StorageBins.GetRef(New UUID(XDTODataObject.ReceivingArea));
	If XDTODataObject.Properties().Get("Performer") <> Undefined Then
		Data.Performer = Catalogs.Users.GetRef(New UUID(XDTODataObject.Performer));
	EndIf;
	If XDTODataObject.Properties().Get("ReferenceOrder") <> Undefined Then
		TypeOfOrder = XDTODataObject.TypeOfOrder;
		Type = MobileWarehouseKeeperWorkspace.ObjectManagerByFullName(TypeOfOrder);
		Data.ReferenceOrder = Type.GetRef(New UUID(XDTODataObject.ReferenceOrder));
	EndIf;
	Data.Warehouse = Catalogs.Warehouses.GetRef(New UUID(XDTODataObject.Warehouse));
	Data.Premise = Catalogs.Warerooms.GetRef(New UUID(XDTODataObject.Premise));
 	If TypeOf(XDTODataObject.Status) = Type("String") Then
		Data.Status = Enums.StatusesOfGoodsPickingPlacement[XDTODataObject.Status];
	EndIf;
	If XDTODataObject.Properties().Get("VolumePutAway") <> Undefined Then
		Data.VolumePutAway = Number(XDTODataObject.VolumePutAway);
	EndIf;
	If XDTODataObject.Properties().Get("WeightPlacement") <> Undefined Then
		Data.WeightPlacement = Number(XDTODataObject.WeightPlacement);
	EndIf;
	
	Data.GoodsFilter.Clear();
	
	If XDTODataObject.Properties().Get("GoodsFilter") <> Undefined Then   
		
		If TypeOf(XDTODataObject.GoodsFilter.GoodsItemFilter) <> Type("XDTOList") Then
			XDTOListRowGoodsFilter	= New Array;
			XDTOListRowGoodsFilter.Add(XDTODataObject.GoodsFilter.GoodsItemFilter);
		Else
			XDTOListRowGoodsFilter = XDTODataObject.GoodsFilter.GoodsItemFilter;
		EndIf;
			
		For Each LineProductsSelection In XDTOListRowGoodsFilter Do
			NewRow = Data.GoodsFilter.Add();
			NewRow.Count = Number(LineProductsSelection.Count);
			NewRow.CountPicked = Number(LineProductsSelection.CountPicked);
			NewRow.NumberOfPackages = Number(LineProductsSelection.NumberOfPackages);
			NewRow.NumberOfPackagesPicked = Number(LineProductsSelection.NumberOfPackagesPicked);
			NewRow.Products = Catalogs.Products.GetRef(New UUID(LineProductsSelection.Products));
			NewRow.Package = Catalogs.PackagesAndUnitsOfMeasure.GetRef(New UUID(LineProductsSelection.Package));
			NewRow.Characteristic = Catalogs.ItemsCharacteristics.GetRef(New UUID(LineProductsSelection.Characteristic));
			NewRow.Cell = Catalogs.StorageBins.GetRef(New UUID(LineProductsSelection.Cell));
			NewRow.Purpose = Catalogs.Assignments.GetRef(New UUID(LineProductsSelection.Purpose));
			NewRow.Series = Catalogs.ItemsBatches.GetRef(New UUID(LineProductsSelection.Series));
			NewRow.BatchesIndicationStatus = Number(LineProductsSelection.BatchesIndicationStatus);
		EndDo;
	EndIf;

	Data.GoodsPlacement.Clear();
	
	If XDTODataObject.Properties().Get("GoodsPlacement") <> Undefined Then  
		
		If TypeOf(XDTODataObject.GoodsPlacement.GoodsItemPlacement) <> Type("XDTOList") Then
			XDTOListRowGoodsPlacement	= New Array;
			XDTOListRowGoodsPlacement.Add(XDTODataObject.GoodsPlacement.GoodsItemPlacement);
		Else
			XDTOListRowGoodsPlacement = XDTODataObject.GoodsPlacement.GoodsItemPlacement;
		EndIf;
	
		For Each LineProductsSelection In XDTOListRowGoodsPlacement Do
			NewRow = Data.GoodsPlacement.Add();
			NewRow.Count = Number(LineProductsSelection.Count);
			NewRow.CountPlaced = Number(LineProductsSelection.CountPlaced);
			NewRow.NumberOfPackages = Number(LineProductsSelection.NumberOfPackages);
			NewRow.NumberOfPackagesPlaced = Number(LineProductsSelection.NumberOfPackagesPlaced);
			NewRow.Products = Catalogs.Products.GetRef(New UUID(LineProductsSelection.Products));
			NewRow.Package = Catalogs.PackagesAndUnitsOfMeasure.GetRef(New UUID(LineProductsSelection.Package));
			NewRow.Characteristic = Catalogs.ItemsCharacteristics.GetRef(New UUID(LineProductsSelection.Characteristic));
			NewRow.Cell = Catalogs.StorageBins.GetRef(New UUID(LineProductsSelection.Cell));
			NewRow.Purpose = Catalogs.Assignments.GetRef(New UUID(LineProductsSelection.Purpose));
			NewRow.Series = Catalogs.ItemsBatches.GetRef(New UUID(LineProductsSelection.Series));
			NewRow.BatchesIndicationStatus = Number(LineProductsSelection.BatchesIndicationStatus);
		EndDo;
	EndIf;

	Return Data;
	
EndFunction

Function PurchaseOrderFromXML(XMLReader)
	
	XDTODataObject = XDTOFactory.ReadXML(XMLReader);
	
	DataReference = Documents.PurchaseOrder.GetRef(New UUID(XDTODataObject.Ref));
	Data = DataReference.GetObject();
	
	If Data = Undefined Then
		Data = Documents.PurchaseOrder.CreateDocument();
		Data.SetNewObjectRef(DataReference);
	Else
		Data = DataReference.GetObject();
	EndIf;
			
	FillPropertyValues(Data, XDTODataObject); 
	
	Data.Date = Date(XDTODataObject.Date);
	Data.DeletionMark = Boolean(XDTODataObject.DeletionMark);
	Data.Posted = Boolean(XDTODataObject.Posted);
	Data.Organization = Catalogs.Companies.GetRef(New UUID(XDTODataObject.Organization));
	Data.Manager = Catalogs.Users.GetRef(New UUID(XDTODataObject.Manager));
		
	Return Data;
	
EndFunction

Function CorrectionByOrderFromXML(XMLReader)
	
	XDTODataObject = XDTOFactory.ReadXML(XMLReader);
	
	DataReference = Documents.InventoryAdjustmentGoodsShipmentOrder.GetRef(New UUID(XDTODataObject.Ref));
	Data = DataReference.GetObject();
	
	If Data = Undefined Then
		Data = Documents.InventoryAdjustmentGoodsShipmentOrder.CreateDocument();
		Data.SetNewObjectRef(DataReference);
	Else
		Data = DataReference.GetObject();
	EndIf;
			
	FillPropertyValues(Data, XDTODataObject); 
	
	Data.Date = Date(XDTODataObject.Date);
	Data.DeletionMark = Boolean(XDTODataObject.DeletionMark);
	Data.Posted = Boolean(XDTODataObject.Posted);
	
	Data.ShippingZone = Catalogs.StorageBins.GetRef(New UUID(XDTODataObject.ShippingZone));
	Data.EmployeeResponsible = Catalogs.Users.GetRef(New UUID(XDTODataObject.EmployeeResponsible));
	Data.Premise = Catalogs.Warerooms.GetRef(New UUID(XDTODataObject.Premise));
	Data.Warehouse = Catalogs.Warehouses.GetRef(New UUID(XDTODataObject.Warehouse));
	
	TypeOrder = XDTODataObject.TypeOrder;
	Type = MobileWarehouseKeeperWorkspace.ObjectManagerByFullName(TypeOrder);
	Data.WarehouseDocument = Type.GetRef(New UUID(XDTODataObject.WarehouseDocument));
	
	If XDTODataObject.Properties().Get("RecipientNote") <> Undefined Then
		OrderTypeRecipient = XDTODataObject.OrderTypeRecipient;
		Type = MobileWarehouseKeeperWorkspace.ObjectManagerByFullName(OrderTypeRecipient);
		Data.RecipientNote = Type.GetRef(New UUID(XDTODataObject.RecipientNote));
	EndIf;
	
	Data.Goods.Clear(); 
	
	If XDTODataObject.Properties().Get("Goods") <> Undefined Then   
		
		If TypeOf(XDTODataObject.Goods.Item_Products) <> Type("XDTOList") Then
			ListOfXDTORowGoods	= New Array;
			ListOfXDTORowGoods.Add(XDTODataObject.Goods.Item_Products);
		Else
			ListOfXDTORowGoods = XDTODataObject.Goods.Item_Products;
		EndIf;
			
		For Each LineProducts_ In ListOfXDTORowGoods Do
			NewRow = Data.Goods.Add();
			NewRow.Count = Number(LineProducts_.Count);
			NewRow.Products = Catalogs.Products.GetRef(New UUID(LineProducts_.Products));
			NewRow.Characteristic = Catalogs.ItemsCharacteristics.GetRef(New UUID(LineProducts_.Characteristic));
			NewRow.Series = Catalogs.ItemsBatches.GetRef(New UUID(LineProducts_.Series));
			NewRow.Purpose = Catalogs.Assignments.GetRef(New UUID(LineProducts_.Purpose));
			NewRow.Package = Catalogs.PackagesAndUnitsOfMeasure.GetRef(New UUID(LineProducts_.Package));
			NewRow.NumberOfPackages = Number(LineProducts_.NumberOfPackages);
			NewRow.BatchesIndicationStatus = Number(LineProducts_.BatchesIndicationStatus);
			
			If TypeOf(LineProducts_.OperationKind) = Type("String") Then
				NewRow.OperationKind = Enums.OperationKindsOfStockBalanceAdjustingEntries[LineProducts_.OperationKind];
			EndIf;
		EndDo;
	EndIf;
	
	Return Data;
	
EndFunction

Function OtherDocumentsFromXML(XMLReader)
	
	ObjectName = StrSplit(XMLReader.Name, ".");
	XDTODataObject = XDTOFactory.ReadXML(XMLReader); // XDTODataObject
	
	Type = MobileWarehouseKeeperWorkspace.ObjectManagerByFullName("Document." + ObjectName[1]);
	DataReference = Type.GetRef(New UUID(XDTODataObject.Ссылка));
	Data = DataReference.GetObject();
	
	If Data = Undefined Then
		Data = Type.CreateDocument();
		Data.SetNewObjectRef(DataReference);
	Else
		Data = DataReference.GetObject();
	EndIf;
			
	FillPropertyValues(Data, XDTODataObject);
	
	Return Data;
	
EndFunction

#EndRegion

// Returns an array of exchange plan nodes, including excluded ones.
//
// Returns:
//  Array of ExchangePlanRef - array of nodes for registering changes.
//
Function NodesForRegistration()
	
	SetPrivilegedMode(True);
	
	Query = New Query("SELECT
	|	Mobile.Ref
	|FROM
	|	ExchangePlan.Mobile AS Mobile
	|WHERE
	|	NOT Mobile.DeletionMark
	|	AND NOT Mobile.ThisNode");
	
	Return Query.Execute().Unload().UnloadColumn("Ref");
EndFunction

#EndRegion

#EndRegion