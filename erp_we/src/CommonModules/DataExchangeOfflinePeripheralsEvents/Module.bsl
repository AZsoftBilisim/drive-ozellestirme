
#Region Public

// Register changes to the directory
//
// Parameters:
//  Source - CatalogObject.Peripherals,
//             Reference object.Opakowaniowej,
//             Reference object.Characteristically,
//             Reference object.Nomenclature, Reference Object.Types Of Nomenclature-Source.
//  Cancel - Boolean - a sign of failure.
//
Procedure RegisterChangesToCatalog(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	SourceType = TypeOf(Source);
	If SourceType = Type("CatalogObject.Products") Then
		
		Query = New Query;
		QueryText = "SELECT
		|	ItemsIDOfPeripheralsOffline.ExchangeRule AS ExchangeRule,
		|	ItemsIDOfPeripheralsOffline.Code AS Code,
		|	Peripherals.InfobaseNode AS InfobaseNode
		|FROM
		|	InformationRegister.ItemsIDOfPeripheralsOffline AS ItemsIDOfPeripheralsOffline
		|		LEFT JOIN Catalog.Peripherals AS Peripherals
		|		ON ItemsIDOfPeripheralsOffline.ExchangeRule = Peripherals.ExchangeRule
		|WHERE
		|	ItemsIDOfPeripheralsOffline.Used
		|	AND NOT Peripherals.InfobaseNode IS NULL
		|	AND Peripherals.InfobaseNode <> VALUE(ExchangePlan.ExchangeWithOfflinePeripherals.EmptyRef)
		|	AND ItemsIDOfPeripheralsOffline.Products = &Value
		|	AND (ItemsIDOfPeripheralsOffline.Products.Description <> &ValueName_
		|	OR ItemsIDOfPeripheralsOffline.Products.DescriptionFull <> &MeaningFullName)
		|";
	
		Query.Text = QueryText;
		Query.SetParameter("MeaningFullName", Source.DescriptionFull);
		
	ElsIf SourceType = Type("CatalogObject.ItemsCharacteristics") Then
		
		Query = New Query;
		
		QueryText = "SELECT
		|	ItemsIDOfPeripheralsOffline.ExchangeRule AS ExchangeRule,
		|	ItemsIDOfPeripheralsOffline.Code AS Code,
		|	Peripherals.InfobaseNode AS InfobaseNode
		|FROM
		|	InformationRegister.ItemsIDOfPeripheralsOffline AS ItemsIDOfPeripheralsOffline
		|		LEFT JOIN Catalog.Peripherals AS Peripherals
		|		ON ItemsIDOfPeripheralsOffline.ExchangeRule = Peripherals.ExchangeRule
		|WHERE
		|	ItemsIDOfPeripheralsOffline.Used
		|	AND NOT Peripherals.InfobaseNode IS NULL
		|	AND Peripherals.InfobaseNode <> VALUE(ExchangePlan.ExchangeWithOfflinePeripherals.EmptyRef)
		|	AND ItemsIDOfPeripheralsOffline.Characteristic = &Value
		|	AND (ItemsIDOfPeripheralsOffline.Characteristic.Description <> &ValueName_
		|	OR ItemsIDOfPeripheralsOffline.Characteristic.DescriptionFull <> &MeaningFullName)";
		
		Query.Text = QueryText;
		Query.SetParameter("MeaningFullName", Source.DescriptionFull);
		
	ElsIf SourceType = Type("CatalogObject.PackagesAndUnitsOfMeasure") Then
		
		Query = New Query;
		
		QueryText = "SELECT
		|	ItemsIDOfPeripheralsOffline.ExchangeRule AS ExchangeRule,
		|	ItemsIDOfPeripheralsOffline.Code AS Code,
		|	Peripherals.InfobaseNode AS InfobaseNode
		|FROM
		|	InformationRegister.ItemsIDOfPeripheralsOffline AS ItemsIDOfPeripheralsOffline
		|		LEFT JOIN Catalog.Peripherals AS Peripherals
		|		ON ItemsIDOfPeripheralsOffline.ExchangeRule = Peripherals.ExchangeRule
		|WHERE
		|	ItemsIDOfPeripheralsOffline.Used
		|	AND NOT Peripherals.InfobaseNode IS NULL
		|	AND Peripherals.InfobaseNode <> VALUE(ExchangePlan.ExchangeWithOfflinePeripherals.EmptyRef)
		|	AND ItemsIDOfPeripheralsOffline.Package = &Value
		|	AND ItemsIDOfPeripheralsOffline.Package.Description <> &ValueName_";

		
		Query.Text = QueryText;
		
	ElsIf SourceType = Type("CatalogObject.ItemKinds") Then
		
		Query = New Query;
		
		QueryText = "SELECT
		|	ItemsIDOfPeripheralsOffline.ExchangeRule AS ExchangeRule,
		|	ItemsIDOfPeripheralsOffline.Code AS Code,
		|	Peripherals.InfobaseNode AS InfobaseNode
		|FROM
		|	InformationRegister.ItemsIDOfPeripheralsOffline AS ItemsIDOfPeripheralsOffline
		|		LEFT JOIN Catalog.Peripherals AS Peripherals
		|		ON ItemsIDOfPeripheralsOffline.ExchangeRule = Peripherals.ExchangeRule
		|WHERE
		|	ItemsIDOfPeripheralsOffline.Used
		|	AND NOT Peripherals.InfobaseNode IS NULL
		|	AND Peripherals.InfobaseNode <> VALUE(ExchangePlan.ExchangeWithOfflinePeripherals.EmptyRef)
		|	AND ItemsIDOfPeripheralsOffline.Products.ProductKind = &Value";
		
		
		Query.Text = QueryText;
	
	ElsIf SourceType = Type("CatalogObject.Peripherals") 
			And ValueIsFilled(Source.InfobaseNode)
			And ValueIsFilled(Source.ExchangeRule)
			And Source.EquipmentType = Enums.PeripheralTypes.LabelPrintingScales Then
				
		SourceLinkExchangeRule = Common.ObjectAttributeValue(Source.Ref,
													Metadata.Catalogs.Peripherals.Attributes.ExchangeRule.Name);
		
		If Source.ExchangeRule <> SourceLinkExchangeRule Then
			ExchangePlans.DeleteChangeRecords(Source.InfobaseNode);
			
			Query = New Query(
			"SELECT
			|	ItemsIDOfPeripheralsOffline.ExchangeRule AS ExchangeRule,
			|	ItemsIDOfPeripheralsOffline.Code           AS Code,
			|	&InfobaseNode                                   AS InfobaseNode
			|FROM
			|	InformationRegister.ItemsIDOfPeripheralsOffline AS ItemsIDOfPeripheralsOffline
			|WHERE
			|	ItemsIDOfPeripheralsOffline.ExchangeRule = &ExchangeRule");
			
			Query.SetParameter("ExchangeRule", Source.ExchangeRule);
			Query.SetParameter("InfobaseNode", Source.InfobaseNode);
		Else
			Return;
		EndIf;

	Else
		Return;
	EndIf;
	
	Query.SetParameter("Value",             Source.Ref);
	Query.SetParameter("ValueName_", Source.Description);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	Set = InformationRegisters.ItemsIDOfPeripheralsOffline.CreateRecordSet();
	While Selection.Next() Do
		
		Set.Filter.ExchangeRule.Value = Selection.ExchangeRule;
		Set.Filter.ExchangeRule.Use = True;
		
		Set.Filter.Code.Value = Selection.Code;
		Set.Filter.Code.Use = True;
		
		ExchangePlans.RecordChanges(Selection.InfobaseNode, Set);
	
	EndDo;
	
EndProcedure

// To register, document changes
//
// Parameters:
//  Source - DocumentObject.PriceSetup - source.
//  Cancel - Boolean - a sign of failure.
//  WriteMode - DocumentWriteMode
//  PostingMode - DocumentPostingMode
//
Procedure RegisterDocumentChanges(Source, Cancel, WriteMode, PostingMode) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	SourceType = TypeOf(Source);
	If SourceType = Type("DocumentObject.PriceSetup") Then
		
		Query = New Query;
		
		QueryText = "SELECT
		|	ItemsIDOfPeripheralsOffline.ExchangeRule AS ExchangeRule,
		|	ItemsIDOfPeripheralsOffline.Code AS Code,
		|	Peripherals.InfobaseNode AS InfobaseNode
		|FROM
		|	InformationRegister.ItemsIDOfPeripheralsOffline AS ItemsIDOfPeripheralsOffline
		|		LEFT JOIN Catalog.Peripherals AS Peripherals
		|		ON ItemsIDOfPeripheralsOffline.ExchangeRule = Peripherals.ExchangeRule
		|		INNER JOIN &TableSettingPricesOfGoodsItem AS SettingPricesForProductProductRange
		|		ON ItemsIDOfPeripheralsOffline.Products = SettingPricesForProductProductRange.Products
		|			AND &FieldOfCommunicationCharacteristicsOfCenter = &DataCenterCharacteristicsField
		|WHERE
		|	ItemsIDOfPeripheralsOffline.Used
		|	AND NOT Peripherals.InfobaseNode IS NULL
		|	AND Peripherals.InfobaseNode <> VALUE(ExchangePlan.ExchangeWithOfflinePeripherals.EmptyRef)
		|	AND SettingPricesForProductProductRange.Ref = &Value";
	
		
		If Constants.UsePriceManagementSystem25.Get() Then
			TableSettingPricesOfGoodsItem = "Document.PriceSetup.Goods2_5";
			DataCenterCharacteristicsField = "SettingPricesForProductProductRange.PricingVariant";
			FieldOfCommunicationCharacteristicsOfCenter = "ISNULL(ItemsIDOfPeripheralsOffline.Characteristic.ItemsCharacteristicForPricing, VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef))";
		Else
			TableSettingPricesOfGoodsItem = "Document.PriceSetup.Goods";
			DataCenterCharacteristicsField = "SettingPricesForProductProductRange.Characteristic";
			FieldOfCommunicationCharacteristicsOfCenter = "ItemsIDOfPeripheralsOffline.Characteristic";
		EndIf;
		QueryText = StrReplace(QueryText, "&"+"TableSettingPricesOfGoodsItem", TableSettingPricesOfGoodsItem);
		QueryText = StrReplace(QueryText, "&"+"DataCenterCharacteristicsField", DataCenterCharacteristicsField);
		QueryText = StrReplace(QueryText, "&"+"FieldOfCommunicationCharacteristicsOfCenter", FieldOfCommunicationCharacteristicsOfCenter);
		
		Query.Text = QueryText;
		Query.SetParameter("Value", Source.Ref);
		
	Else
		Return;
	EndIf;
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	Set = InformationRegisters.ItemsIDOfPeripheralsOffline.CreateRecordSet();
	While Selection.Next() Do
		
		Set.Filter.ExchangeRule.Value = Selection.ExchangeRule;
		Set.Filter.ExchangeRule.Use = True;
		
		Set.Filter.Code.Value = Selection.Code;
		Set.Filter.Code.Use = True;
		
		ExchangePlans.RecordChanges(Selection.InfobaseNode, Set);
	
	EndDo;
	
EndProcedure

// Register changes to the information register
//
// Parameters:
//  Source - InformationRegisterRecordSet.ItemsPrices, InformationRegisterRecordSet.ItemsBarcodes - source.
//  Cancel - Boolean - a sign of failure.
//  Replacing - Boolean
//
Procedure RegisterInformationRegisterChanges(Source, Cancel, Replacing) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	SourceType = TypeOf(Source);
	If SourceType = Type("InformationRegisterRecordSet.ItemsBarcodes") Then
		
		Query = New Query;
		
		QueryText  ="SELECT DISTINCT
		|	ItemsIDOfPeripheralsOffline.ExchangeRule AS ExchangeRule,
		|	ItemsIDOfPeripheralsOffline.Code AS Code,
		|	Peripherals.InfobaseNode AS InfobaseNode
		|FROM
		|	InformationRegister.ItemsIDOfPeripheralsOffline AS ItemsIDOfPeripheralsOffline
		|		LEFT JOIN Catalog.Peripherals AS Peripherals
		|		ON ItemsIDOfPeripheralsOffline.ExchangeRule = Peripherals.ExchangeRule
		|		LEFT JOIN InformationRegister.ItemsBarcodes AS ItemsBarcodes
		|		ON ItemsIDOfPeripheralsOffline.Products = ItemsBarcodes.Products
		|			AND ItemsIDOfPeripheralsOffline.Characteristic = ItemsBarcodes.Characteristic
		|			AND ItemsIDOfPeripheralsOffline.Package = ItemsBarcodes.Package
		|WHERE
		|	ItemsIDOfPeripheralsOffline.Used
		|	AND Peripherals.InfobaseNode <> VALUE(ExchangePlan.ExchangeWithOfflinePeripherals.EmptyRef)
		|	AND ItemsBarcodes.Barcode = &Value";
		
		Query.Text = QueryText;
		Query.SetParameter("Value", Source.Filter.Barcode.Value);
		
	Else
		Return;
	EndIf;
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	Set = InformationRegisters.ItemsIDOfPeripheralsOffline.CreateRecordSet();
	While Selection.Next() Do
		
		Set.Filter.ExchangeRule.Value = Selection.ExchangeRule;
		Set.Filter.ExchangeRule.Use = True;
		
		Set.Filter.Code.Value = Selection.Code;
		Set.Filter.Code.Use = True;
		
		ExchangePlans.RecordChanges(Selection.InfobaseNode, Set);
	
	EndDo;
	
EndProcedure

// Create an exchange node with connected hardware offline
//
// Parameters:
//  Source - CatalogObject.Peripherals - source.
//  Cancel - Boolean - a sign of failure.
//
Procedure CreateAnOfflinePeripheralsExchangeNode(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Source.InfobaseNode) Then
		If TypeOf(Source) = Type("CatalogObject.Peripherals")
				And Source.EquipmentType = Enums.PeripheralTypes.LabelPrintingScales Then
			Source.InfobaseNode = GetRibNode(Source);
			
		EndIf;
	EndIf;
	
	Source.AdditionalProperties.Insert(
		"ChangedExchangeRule", 
		Source.ExchangeRule <> Common.ObjectAttributeValue(Source.Ref, "ExchangeRule"));
	
EndProcedure

// Clear the exchange node with the connected equipment offline.
//
// Parameters:
//  Source - CatalogObject.Peripherals - source.
//  CopiedObject - CatalogObject.Peripherals - The object of copying.
//
Procedure ClearAnOfflinePeripheralsExchangeNode(Source, CopiedObject) Export
	
	Source.InfobaseNode = ExchangePlans.ExchangeWithOfflinePeripherals.EmptyRef();
	
EndProcedure

// Register change when you change the exchange rules of the connected equipment.
//
// Parameters:
//  Source - CatalogObject.Peripherals - source.
//  Cancel - Boolean - Refusal.
//
Procedure RegisterChangesWhenChangingPeripheralsExchangeRules(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	If TypeOf(Source) = Type("CatalogObject.Peripherals")
		And Source.EquipmentType = Enums.PeripheralTypes.LabelPrintingScales
		And Source.AdditionalProperties.ChangedExchangeRule Then
		
		SetPrivilegedMode(True);
		ExchangePlans.RecordChanges(Source.InfobaseNode, Metadata.InformationRegisters.ItemsIDOfPeripheralsOffline);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// The function creates a node for this instance of connected hardware and returns a reference to it
// It is used before writing an item in the Connected hardware directory.
//
// Parameters:
//  ConnectedEquipmentObject - CatalogObject.Peripherals - Link to an instance of the connected hardware.
// 
// Returns:
//   ExchangePlanRef.ExchangeWithOfflinePeripherals - Returns the node for this instance of connected hardware.
//
Function GetRibNode(ConnectedEquipmentObject)
	
	ObjectNode = ExchangePlans.ExchangeWithOfflinePeripherals.CreateNode();
	ObjectNode.SetNewCode();
	ObjectNode.Description = ConnectedEquipmentObject.Description;
	ObjectNode.Write();
	
	Return ObjectNode.Ref;
	
EndFunction

#EndRegion