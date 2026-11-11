
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Parameters.Property("Filter") Then
		
		If Parameters.Filter.Property("ItemOwner") Then
			ItemOwner = Parameters.Filter.ItemOwner;
		EndIf;
		
		If Parameters.Filter.Property("Products") And ValueIsFilled(Parameters.Filter.Products) Then
			
			Products = Parameters.Filter.Products;
			Parameters.Filter.Delete("Products");
			
			If Parameters.Filter.Property("Characteristic") Then
				Characteristic = Parameters.Filter.Characteristic;
				Parameters.Filter.Delete("Characteristic");
			EndIf;
			
			If Parameters.Filter.Property("Package") Then
				
				Package = Parameters.Filter.Package;
				Parameters.Filter.Delete("Package");
				If Not ValueIsFilled(Package)
					And ValueIsFilled(Products) Then
					ProductCrossReferencesMappingOverridable.BasicUnitOfProductMeasurement(Products, Package);
				EndIf;
			EndIf;
			
		Else
			
			Parameters.Filter.Delete("Products");
			If Parameters.Filter.Property("Characteristic") Then
				Parameters.Filter.Delete("Characteristic");
			EndIf;
			If Parameters.Filter.Property("Package") Then
				Parameters.Filter.Delete("Package");
			EndIf;
			
		EndIf;
	
		If Parameters.Filter.Property("CustomerInvoiceServices")
			And ValueIsFilled(Parameters.Filter.CustomerInvoiceServices) Then
			CustomerInvoiceServices = Parameters.Filter.CustomerInvoiceServices;
		EndIf;
	
		If Parameters.Filter.Property("ItemsType")
			And ValueIsFilled(Parameters.Filter.ItemsType) Then
			If TypeOf(Parameters.Filter.ItemsType) = Type("FixedArray") Then
				ItemsTypes.LoadValues(New Array(Parameters.Filter.ItemsType));
			ElsIf TypeOf(Parameters.Filter.ItemsType) = Type("Array") Then
				ItemsTypes.LoadValues(Parameters.Filter.ItemsType);
			Else
				ItemsTypes.Add(Parameters.Filter.ItemsType);
			EndIf;
		EndIf;
		
	EndIf;
	
	SetPropertiesOfRedefinedFormElements();
	SetDynamicListProperties();
	
	If ValueIsFilled(Products) Then
		
		ItemPresentation = NStr("vi = 'Tất cả vị trí chưa được so sánh';
								|ru = 'Все позиции, которые не сопоставлены';
								|en = 'All unmapped items'; fa = 'All unmapped items';
								|it = 'Tutte le voci non abbinate';
								|pl = 'Wszystkie pozycje, które nie są porównane';
								|tr = 'Eşleşmeyen tüm konumlar'");
		Items.Filter.ChoiceList.Add(3, ItemPresentation);
		
		If ValueIsFilled(Package) Then
			ProductPresentation = String(Products) + ?(ValueIsFilled(Characteristic), ", " + Characteristic, "") + " " + Package;
			ItemPresentation = NStr("vi = 'Tất cả vị trí được so sánh với ""%1""';
									|ru = 'Все позиции, которые сопоставлены с ""%1""';
									|en = 'All items mapped with ""%1""'; fa = 'All items mapped with ""%1""';
									|it = 'Tutte le posizioni che sono associate a ""%1""';
									|pl = 'Wszystkie pozycje, które są przypisane do ""%1""';
									|tr = '""%1"" ile eşleşen tüm konumlar'");
			ItemPresentation = StrTemplate(ItemPresentation, ProductPresentation);
			Items.Filter.ChoiceList.Add(2, ItemPresentation);
			Filter = 2;
		Else
			Filter = 1;
		EndIf;
					
		ProductPresentation = String(Products) + ?(ValueIsFilled(Characteristic), ", " + Characteristic, "");
		ItemPresentation = NStr("vi = 'Tất cả vị trí được so sánh với ""%1""';
								|ru = 'Все позиции, которые сопоставлены с ""%1""';
								|en = 'All items mapped with ""%1""'; fa = 'All items mapped with ""%1""';
								|it = 'Tutte le posizioni che sono associate a ""%1""';
								|pl = 'Wszystkie pozycje, które są przypisane do ""%1""';
								|tr = '""%1"" ile eşleşen tüm konumlar'");
		ItemPresentation = StrTemplate(ItemPresentation, ProductPresentation);
		Items.Filter.ChoiceList.Add(1, ItemPresentation);
		Items.Filter.ChoiceList.Add(0, NStr("vi = 'Tất cả vị trí';
											|ru = 'Все позиции';
											|en = 'All items'; fa = 'همه اقلام';
											|it = 'Tutte le posizioni';
											|pl = 'Wszystkie pozycje';
											|tr = 'Tüm konumlar'"));
		
		EstablishSelectionByMatchedProduct();
	
		If Parameters.Property("AvailabilityOfSelections") And Not Parameters.AvailabilityOfSelections Then
			Items.Filter.Enabled = False;
		EndIf;
	Else
		Items.Filter.Visible = False;
	EndIf;
	
	ProductCrossReferencesMappingOverridable.WhenCreatingOnServer_FormForSelectingProductListOfCounterparties(
		ThisForm, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterOnChange(Item)
	
	EstablishSelectionByMatchedProduct();
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	If Copy Then
		Return;
	EndIf;

	Cancel = True;
	
	If Var_Group Then
		
		OpenForm(
			"Catalog.ProductCrossReferences.FolderForm",
			New Structure("ItemOwner,IsFolder", ItemOwner, True),
			,
			,);
		
	Else
			
		FormParameters = New Structure;
		FormParameters.Insert("ItemOwner", ItemOwner);
		FormParameters.Insert("Products", Products);
		FormParameters.Insert("Characteristic", Characteristic);
		FormParameters.Insert("Package", Package);
		
		OpenForm(
			"Catalog.ProductCrossReferences.ObjectForm",
			FormParameters,
			,
			,);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)
	
	AttachIdleHandler("ProcessListRowActivation", 0.2, True);
	
EndProcedure
	
#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	PartnersProductsClient.Attachable_ExecuteOverridableCommand_CounterpartyNomenclatures(ThisObject, Command);
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	ProductCrossReferencesMappingClientOverridable.Attachable_ExecuteIntegrationCommand_CounterpartyNomenclatures(
		ThisObject, Command, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

#Region Private

&AtServer
Procedure SetPropertiesOfRedefinedFormElements()

	MappingMetadata = ProductCrossReferencesMappingInternal.ProductMappingMetadata();

	If ValueIsFilled(Parameters.FormCaption) Then
		ObjectPresentation = Parameters.FormCaption;
	Else
		ObjectPresentation = MappingMetadata.ItemProductsAndPresentation;
	EndIf;
	
	Title = ObjectPresentation;
	
	Items.ListProducts.Title   = MappingMetadata.ProductObjectPresentation;
	Items.ListCharacteristic.Title = MappingMetadata.FeaturePresentationOfObject;
	Items.ListPackage.Title       = MappingMetadata.PackagingObjectPresentation;
	
EndProcedure

&AtServer
Procedure EstablishSelectionByMatchedProduct()
	
	If Filter = 3 Then // All positions that are not matched.
		SetRemoveDynamicListSelection("TheCounterpartySNomenclatureIsNotMatched", True, True);
		SetRemoveDynamicListSelection("TheCounterpartySNomenclatureIsFullyMatched");
		SetRemoveDynamicListSelection("TheCounterpartySNomenclatureIsMatchedByTheCharacteristicNomenclature");
	ElsIf Filter = 2 Then // All items that are mapped to "Nomenclature, characteristics, packaging".
		SetRemoveDynamicListSelection("TheCounterpartySNomenclatureIsNotMatched");
		SetRemoveDynamicListSelection("TheCounterpartySNomenclatureIsFullyMatched", True, True);
		SetRemoveDynamicListSelection("TheCounterpartySNomenclatureIsMatchedByTheCharacteristicNomenclature");
	ElsIf Filter = 1 Then // All items that are mapped to "Nomenclature, characteristic".
		SetRemoveDynamicListSelection("TheCounterpartySNomenclatureIsNotMatched");
		SetRemoveDynamicListSelection("TheCounterpartySNomenclatureIsFullyMatched");
		SetRemoveDynamicListSelection("TheCounterpartySNomenclatureIsMatchedByTheCharacteristicNomenclature", True, True);
	Else // All positions.
		SetRemoveDynamicListSelection("TheCounterpartySNomenclatureIsNotMatched");
		SetRemoveDynamicListSelection("TheCounterpartySNomenclatureIsFullyMatched");
		SetRemoveDynamicListSelection("TheCounterpartySNomenclatureIsMatchedByTheCharacteristicNomenclature");
	EndIf;
	
EndProcedure

&AtServer
Procedure SetRemoveDynamicListSelection(Val FieldName, Val EnableUsage = False, Val RightValue = "")
	
	CommonClientServer.SetDynamicListFilterItem(
		List, FieldName, RightValue, DataCompositionComparisonType.Equal, , EnableUsage);

EndProcedure

&AtClient
Procedure ProcessListRowActivation()
	
	GroupingType   = Type("DynamicListGroupRow");
	TypeOfCurLine = TypeOf(Items.List.CurrentRow);
	
	CurLineGroup = False;
	If TypeOfCurLine = Type("CatalogRef.ProductCrossReferences") Then
		CurLineGroup = StringIsGroup(Items.List.CurrentRow);
	EndIf;
	
	If TypeOfCurLine <> GroupingType
		And Items.List.CurrentData <> Undefined And Not CurLineGroup Then
		Items.PageHintGroup.CurrentPage = Items.TooltipThereIsData;
	Else
		Items.PageHintGroup.CurrentPage = Items.TooltipNoData;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function StringIsGroup(CurrentRow)
	
	Return CurrentRow.IsFolder;
	
EndFunction

&AtServer
Procedure SetDynamicListProperties()

	QueryText = "";
	ProductCrossReferencesMappingOverridable.DynamicListRequestText_CounterpartyProductSelectionForm(QueryText);
	
	If ValueIsFilled(QueryText) Then
		ListProperties = Common.DynamicListPropertiesStructure();
		ListProperties.QueryText                 = QueryText;
		ListProperties.MainTable              = "Catalog.ProductCrossReferences";
		ListProperties.DynamicDataRead = True;
		
		Common.SetDynamicListProperties(Items.List, ListProperties);
	EndIf;
	
	List.Parameters.SetParameterValue("EmptyItemList",  EmptyItemList);
	List.Parameters.SetParameterValue("NomenclatureSelection",   Products);
	List.Parameters.SetParameterValue("FeatureSelection", Characteristic);
	List.Parameters.SetParameterValue("PackagingSelection",       Package);
	
	ArrayOfSuitableProductTypes = New Array();
	If CustomerInvoiceServices Then
		ArrayOfSuitableProductTypes.Add(Enums.ItemsTypes.Work_5);
		ArrayOfSuitableProductTypes.Add(Enums.ItemsTypes.OperationService);
	ElsIf ItemsTypes.Count() > 0 Then
		ArrayOfSuitableProductTypes = ItemsTypes.UnloadValues();
	Else
		ArrayOfSuitableProductTypes.Add(Enums.ItemsTypes.OwnGoods);
		ArrayOfSuitableProductTypes.Add(Enums.ItemsTypes.ReusablePackage);
		ArrayOfSuitableProductTypes.Add(Enums.ItemsTypes.Work_5);
		ArrayOfSuitableProductTypes.Add(Enums.ItemsTypes.OperationService);		
	EndIf;
	List.Parameters.SetParameterValue("ItemsTypes", ArrayOfSuitableProductTypes);
		
	ToolTip1 = StrTemplate(NStr("vi = '%1 không phù hợp với mặt hàng';
								|ru = '%1 не сопоставлена с номенклатурой';
								|en = '%1 is not mapped with items'; fa = '%1 is not mapped with items';
								|it = '%1 non è associato con alcun prodotto';
								|pl = '%1 nie porównano z pozycją';
								|tr = '%1 öğe ile eşleşmedi'"),
							ObjectPresentation);
	ToolTip2 = StrTemplate(NStr("vi = '%1 không phù hợp với mặt hàng khác';
								|ru = '%1 сопоставлена с другой номенклатурой';
								|en = '%1 is mapped with different items'; fa = '%1 is mapped with different items';
								|it = '%1 associato con un altro prodotto';
								|pl = '%1 porównano z inną pozycją';
								|tr = '%1 diğer öğe ile eşleşti'"),
							ObjectPresentation);
	ToolTip3 = StrTemplate(NStr("vi = '%1 phù hợp với mặt hàng';
								|ru = '%1 сопоставлена с номенклатурой';
								|en = '%1 is mapped with items'; fa = '%1 is mapped with items';
								|it = '%1 associato al prodotto';
								|pl = '%1 porównano z pozycją';
								|tr = '%1 öğe ile eşleşti'"),
							ObjectPresentation);
	
	List.Parameters.SetParameterValue("ToolTip1", ToolTip1);
	List.Parameters.SetParameterValue("ToolTip2", ToolTip2);
	List.Parameters.SetParameterValue("ToolTip3", ToolTip3);
	
	ProductCrossReferencesMappingOverridable.SetDynamicListParameters_CounterpartyProductSelectionForm(Parameters, List);

EndProcedure


#EndRegion
