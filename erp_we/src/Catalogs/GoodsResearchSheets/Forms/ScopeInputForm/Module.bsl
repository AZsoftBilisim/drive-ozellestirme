#Region Variables

&AtClient
Var CachedValues;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Parameters.Property("SettingsMode") Then
		SettingsMode = Parameters.SettingsMode;
	EndIf;

	SelectionAccordingToTSProperties = New Array;
	ListOfItemsTS = New Array;
	
	If Parameters.Property("SelectionByProperties") Then
		SelectionAccordingToTSProperties = Parameters.SelectionByProperties;
	EndIf;
	
	If Parameters.Property("ItemList") Then
		ListOfItemsTS = Parameters.ItemList;
	EndIf;
	
	If SelectionAccordingToTSProperties.Count() > 0 Then
		StructuresArrayIntoValueTable(SelectionAccordingToTSProperties, SelectionByProperties, True);
	EndIf;
	
	If ListOfItemsTS.Count() > 0 And SettingsMode = PredefinedValue(
		"Enum.AssignmentOptionsOfGoodsResearchSheet.ItemList") Then
		StructuresArrayIntoValueTable(ListOfItemsTS, GoodsList, False);
	ElsIf ListOfItemsTS.Count() = 1 Then
		FillPropertyValues(ThisObject, ListOfItemsTS[0], "ProductKind, Products, Characteristic");
	EndIf;
	
	If Parameters.ReadOnly Then
		Items.SettingsMode.ReadOnly = True;
		Items.ProductKind.ReadOnly = True;
		Items.Products.ReadOnly = True;
		Items.Characteristic.ReadOnly = True;
		Items.Goods.ReadOnly = True;
	EndIf;
	
	SetConditionalAppearance();
	SetItemsAvailability();
	
	FillInServiceDetailsForUsingPropertiesCharacteristics();
	UpdateInformation2(SelectionByProperties);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Modified Then 
		ClearMessages();
		QueryText = NStr("vi = 'Dữ liệu đã thay đổi. Lưu lại thay đổi?';
						|ru = 'Данные были изменены. Сохранить изменения?';
						|en = 'The data has changed. Do you want to save the changes?'; fa = 'The data has changed. Do you want to save the changes?';
						|it = 'I dati sono stati modificati. Salvare le modifiche?';
						|pl = 'Dane zostały zmienione. Chcesz zapisać zmiany?';
						|tr = 'Veriler değiştirildi. Değişiklikler kaydedilsin mi?'");
		Notification = New CallbackDescription("WriteAndCloseOnClient", ThisObject);
		CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit, QueryText); 
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	RecalculateLineNumbers();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SettingsModeOnChange(Item)
	ConfigurationOptionOnChangeAtServer();
EndProcedure

&AtClient
Procedure ProductsOnChange(Item)
	ProductsWhenChangedOnServer();
	Modified = True;
EndProcedure

&AtClient
Procedure CharacteristicOnChange(Item)
	CharacteristicWhenChangingOnServer();
	Modified = True;
EndProcedure

&AtClient
Procedure ProductKindOnChange(Item)
	ProductTypeWhenChangedOnServer();
	Modified = True;
EndProcedure

&AtClient
Procedure ProductsClearing(Item, StandardProcessing)
	ProductTypeWhenChangedOnServer();
	Modified = True;
EndProcedure

&AtClient
Procedure ProductKindClearing(Item, StandardProcessing)
	ProductTypeWhenChangedOnServer();
	Modified = True;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsProductsOnChange(Item)
	TableRow = Items.Goods.CurrentData;
	If TableRow <> Undefined Then
		If ValueIsFilled(TableRow.Products) Then
			TableRow.ProductKind = GetProductType(TableRow.Products);
		EndIf;
	EndIf;

	FillInFeatureAttribute = New Structure("Products", "ItemVariantsAreUsed");

	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInFeatureAttribute", FillInFeatureAttribute);
	StructureOfActions.Insert("CheckCharacteristicsByOwner", TableRow.Characteristic);
	
	BatchProcessingOfTablePartClient.ProcessTSString(TableRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsOnChange(Item)
	
	RecalculateLineNumbers();
	Modified = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure UsageClarificationProduct(Command)
	OpenRequirementApplicationRefinementSetting("Products");
EndProcedure

&AtClient
Procedure UsageClarificationCharacteristic(Command)
	OpenRequirementApplicationRefinementSetting("Characteristic");
EndProcedure

&AtClient
Procedure OkCommand(Command)
	
	ClearMessages();
	If Modified Then
		CompleteEditing();
	Else
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure CancelCommand(Command)
	
	Modified = False;
	
	Close();
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure CompleteEditing()
	
	SelectionByArrayProperties = New Array;
	
	If SettingsMode = PredefinedValue(
		"Enum.AssignmentOptionsOfGoodsResearchSheet.ProductKind") Then
		ListOfItemsArray = New Array;
		DataFromStructure = New Structure;
		DataFromStructure.Insert("ProductKind", ProductKind);
		DataFromStructure.Insert("Products", Products);
		DataFromStructure.Insert("Characteristic", Characteristic);
		If ValueIsFilled(ProductKind) Or ValueIsFilled(Products) Or ValueIsFilled(
			Characteristic) Then
			ListOfItemsArray.Add(DataFromStructure);
		EndIf;
		SelectionByArrayProperties = GoodsResearchClient.DetailsOfTableInArrayOfStructures(
			SelectionByProperties, GoodsResearchClient.DetailsOfSelectionByProperties());
	Else
		Cancel = False;
		LinesWithErrors = New Array;
		CheckCompletionOfItemList(GoodsList, LinesWithErrors, Cancel);
		If Not CheckFilling() Or Cancel Then
			For Each Error In LinesWithErrors Do
				If Error.ErrorType = "CheckingCharacteristics" Then
					ErrorText = StrTemplate(NStr(
						"vi = 'Chưa điền cột ""Đặc tính"" tại dòng %1 trong danh sách ""Danh sách mặt hàng""';
						|ru = 'Не заполнена колонка ""Характеристика"" в строке %1 списка ""Список номенклатуры""';
						|en = 'The ""Variant"" column in line %1 of the ""Item list"" list is not filled in'; fa = 'The ""Variant"" column in line %1 of the ""Item list"" list is not filled in';
						|it = 'The ""Variant"" column in line %1 of the ""Item list"" list is not filled in';
						|pl = 'The ""Variant"" column in line %1 of the ""Item list"" list is not filled in';
						|tr = '""Öğe"" satırı %1''de ""Varyant"" sütunu doldurulmamış'"),
						Error.LineNumber);
					CommonClient.MessageToUser(
						ErrorText, , CommonClientServer.PathToTabularSection("GoodsList", 
						Error.LineNumber, "Characteristic"), , Cancel);
				ElsIf Error.ErrorType = "CheckingDuplicates" Then
					ErrorText = StrTemplate(
					NStr("vi = 'Trên dòng %1 của danh sách ""Danh sách mặt hàng"", mặt hàng ""%2"" bị trùng lặp.';
						|ru = 'В строке %1 списка ""Список номенклатуры"" дублируется номенклатура ""%2""';
						|en = 'In line %1 of the ""Item list"" list, the ""%2"" is duplicated'; fa = 'In line %1 of the ""Item list"" list, the ""%2"" is duplicated';
						|it = 'In line %1 of the ""Item list"" list, the ""%2"" is duplicated';
						|pl = 'In line %1 of the ""Item list"" list, the ""%2"" is duplicated';
						|tr = '""Öğe listesi"" satırı %1''de ""%2"" öğe tekrarlanıyor'"),
						Error.LineNumber, Error.Products);
					CommonClient.MessageToUser(
						ErrorText, , CommonClientServer.PathToTabularSection("GoodsList", 
						Error.LineNumber, "Products"), , Cancel);
				EndIf;
			EndDo;
			Return;
		EndIf;
		ListOfItemsArray = GoodsResearchClient.DetailsOfTableInArrayOfStructures(
			GoodsList, GoodsResearchClient.AttributesSetupItemList());
	EndIf;

	Modified = False;
	
	Close(New Structure("SelectionByProperties,ItemList,SettingsMode",SelectionByArrayProperties, ListOfItemsArray, SettingsMode));
	
EndProcedure

&AtClient
Procedure WriteAndCloseOnClient(Result, AdditionalParameters) Export 
	
	CompleteEditing();
	
EndProcedure

&AtServer
Procedure CheckClearDetailsWhenChangingDestinationOption()
	
	If SettingsMode = Enums.AssignmentOptionsOfGoodsResearchSheet.ProductKind Then
		ProductKind = Undefined;
		Products	= Undefined;
		Characteristic	= Undefined;
		GoodsResearch.ClearSettingsForClarifyingApplicationOfItemResearchMap(SelectionByProperties);
	EndIf;
	
	If SettingsMode = Enums.AssignmentOptionsOfGoodsResearchSheet.ItemList Then
		GoodsList.Clear();
		If Not ValueIsFilled(Products) Then
			GoodsResearch.ClearSettingsForClarifyingApplicationOfItemResearchMap(SelectionByProperties);
		EndIf;
	EndIf;
	
	FillInServiceDetailsForUsingPropertiesCharacteristics();
	
EndProcedure

&AtServer
Procedure ProductsWhenChangedOnServer()
	
	If ValueIsFilled(Products) Then
		FilterProductKind = Common.ObjectAttributeValue(Products, "ProductKind");
		If FilterProductKind <> ProductKind Then
			ProductKind = FilterProductKind;
		EndIf;
	EndIf;
	
	FillInServiceDetailsForUsingPropertiesCharacteristics();
	GoodsResearch.ClearSettingsForClarifyingApplicationOfItemResearchMap(SelectionByProperties);
	
	UpdateInformation2(SelectionByProperties);
	
EndProcedure

&AtServer
Procedure CharacteristicWhenChangingOnServer()

	GoodsResearch.ClearSettingsForClarifyingApplicationOfItemResearchMap(SelectionByProperties);
	UpdateInformation2(SelectionByProperties);
	
EndProcedure

&AtServer
Procedure ProductTypeWhenChangedOnServer()
	
	If ValueIsFilled(ProductKind) Then
		FilterProductKind = Common.ObjectAttributeValue(Products, "ProductKind");
		If FilterProductKind <> ProductKind Then
			Products = Undefined;
		EndIf; 
	Else
		Products = Undefined;
	EndIf;
	
	FillInServiceDetailsForUsingPropertiesCharacteristics();
	
	GoodsResearch.ClearSettingsForClarifyingApplicationOfItemResearchMap(SelectionByProperties);
	
	UpdateInformation2(SelectionByProperties);
	
EndProcedure

&AtServer
Procedure UpdateInformation2(Val SelectionByProperties1)

	AvailabilityOfApplicationRefinements = New Structure("Products,Characteristic",True,True);
	
	AssignmentOptionTypeOfProduct = (SettingsMode = PredefinedValue("Enum.AssignmentOptionsOfGoodsResearchSheet.ProductKind"));
	
	UseItemVariants = GetFunctionalOption("UseItemVariants");
	Items.GroupTypeOfItemCharacteristics.Visible     = UseItemVariants;
	Items.GoodsCharacteristic.Visible                    = UseItemVariants;
	
	If AssignmentOptionTypeOfProduct Then
		If ValueIsFilled(Products) Then
			AvailabilityOfApplicationRefinements.Products            = False;
		Else
			Items.Products.InputHint    = NStr("vi = '<bất kỳ mặt hàng>';
												|ru = '<любая номенклатура>';
												|en = '<any items>'; fa = '<any items>';
												|it = '<qualsiasi nomenclatura>';
												|pl = '<dowolny produkt>';
												|tr = '<herhangi bir öğe>'");
			AvailabilityOfApplicationRefinements.Products            = True;
		EndIf;
	Else
		Items.Products.InputHint    = "";
	EndIf;
	
	If ItemVariantsAreUsed Then
		Items.Characteristic.Enabled     = AssignmentOptionTypeOfProduct;
		Items.Characteristic.InputHint  = NStr("vi = '<đặc tính bất kỳ>';
												|ru = '<любая характеристика>';
												|en = '<any variant>'; fa = '<any variant>';
												|it = '<qualsiasi caratteristica>';
												|pl = '<dowolna charakterystyka>';
												|tr = '<herhangi bir varyant>'");
	Else
		Items.Characteristic.Enabled     = False;
		Items.Characteristic.InputHint  = NStr("vi = '<không sử dụng đặc tính>';
												|ru = '<характеристики не используются>';
												|en = '<variants are not used>'; fa = '<گونه‌ها استفاده نمی‌شوند>';
												|it = '<le caratteristiche non vengono usate>';
												|pl = '<charakterystyki nie dotyczą>';
												|tr = '<varyantlar kullanılmamaktadır>'");
		AvailabilityOfApplicationRefinements.Characteristic          = False;
	EndIf;
	
	For Each KeyAndValue In AvailabilityOfApplicationRefinements Do
		
		SetSettingsForApplicationRefinementElements(ThisObject, SelectionByProperties1, KeyAndValue.Key, KeyAndValue.Value);
		
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSettingsForApplicationRefinementElements(Form, SelectionByProperties1, SettingKind, Enabled = True)
	
	Items = Form.Items;
	
	ElementNames = ItemNamesBySettingType(SettingKind);
	
	CurrentCommand = Items[ElementNames.ClarificationOfApplication]; // FormButton
	
	ConnectionKey = GoodsResearchClientServer.SelectionByPropertiesOfCommunicationKey(SettingKind);
		
	ListOfSelectionLines = SelectionByProperties1.FindRows(New Structure("ConnectionKey", ConnectionKey));
	ThereAreAdvancedSettings = (ListOfSelectionLines.Count() > 0);
	
	CurrentCommand.Enabled = Not ValueIsFilled(Form[ElementNames.ApplicationArea])
		And (Form[ElementNames.ThereAreProperties] Or ThereAreAdvancedSettings)
		And Enabled;
		
	If ThereAreAdvancedSettings Then
		Items[ElementNames.ApplicationArea].InputHint = NStr("vi = '<với lựa chọn theo thuộc tính>';
															|ru = '<с отбором по свойствам>';
															|en = '<with filter by properties>'; fa = '<with filter by properties>';
															|it = '<con selezione per proprietà>';
															|pl = '<z wyborem wg właściwości>';
															|tr = '<özelliklere göre filtre ile>'");
		CurrentCommand.Picture = PictureLib.FilterByKindsAndPropertiesOfItems;
	Else
		CurrentCommand.Picture = PictureLib.Filters;
	EndIf;
	SetTextOfHintToClarifyApplication(Form, SettingKind, CurrentCommand, ListOfSelectionLines);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetTextOfHintToClarifyApplication(Form, SettingKind, Command, ListOfSelectionLines)
	
	ToolTipText = "";
	
	If Command.Enabled Then
		
		If ListOfSelectionLines.Count() > 0 Then
			
			PropertiesArray = New Array;
			For Each String In ListOfSelectionLines Do
				If PropertiesArray.Find(String.Property) = Undefined Then
					PropertiesArray.Add(String.Property);
				EndIf;
			EndDo;
			
			ToolTipText = StrTemplate(NStr("vi = 'Đặt lọc theo %1: %2';
											|ru = 'Установлен отбор по %1: %2';
											|en = 'Filter by %1: %2 is set'; fa = 'Filter by %1: %2 is set';
											|it = 'Impostata la selezione per %1:%2';
											|pl = 'Ustalono wybór wg %1: %2';
											|tr = '%1 göre filtre yapılandırıldı: %2'"),
				?(PropertiesArray.Count()>1, NStr("vi = 'thuộc tính';
													|ru = 'свойствам';
													|en = 'properties'; fa = 'properties';
													|it = 'alle proprietà';
													|pl = 'właściwości';
													|tr = 'özelliklere'"), NStr("vi = 'thuộc tính';
																			|ru = 'свойству';
																			|en = 'property'; fa = 'property';
																			|it = 'alla proprietà';
																			|pl = 'właściwości';
																			|tr = 'özelliğe'")),
				StrConcat(PropertiesArray, "; "));
				
		Else
			
			ToolTipText = NStr("vi = 'Đã thiết lập lọc theo thuộc tính';
								|ru = 'Установить отбор по свойствам';
								|en = 'Set filter by properties'; fa = 'Set filter by properties';
								|it = 'Impostare filtro per proprietà';
								|pl = 'Ustaw filtr wg właściwości';
								|tr = 'Özelliklere göre filtre yapılandır'");
			
		EndIf;
		
	Else
		ElementNames = ItemNamesBySettingType(SettingKind);
	
		If SettingKind = "Products" Then
			ToolTipText = NStr("vi = 'Lọc theo các thuộc tính của mặt hàng có sẵn cho sơ đồ nghiên cứu hàng hóa theo loại mặt hàng.';
								|ru = 'Отбор по свойствам номенклатуры доступен для карты исследования товаров на вид номенклатуры';
								|en = 'Filter by item properties is available for the goods research sheet for item kind'; fa = 'Filter by item properties is available for the goods research sheet for item kind';
								|it = 'Filter by item properties is available for the goods research sheet for item kind';
								|pl = 'Filter by item properties is available for the goods research sheet for item kind';
								|tr = 'Öğe özelliklerine göre seçim, ürün inceleme kartı için öğe türüne göre kullanılabilir'");
		ElsIf SettingKind = "Characteristic" And Not Form.ItemVariantsAreUsed Then
			ToolTipText = NStr("vi = 'Không sử dụng đặc tính, không thể lọc theo thuộc tính';
								|ru = 'Характеристики не используются, отбор по свойствам недоступен';
								|en = 'Variants are not used, filter by properties is not available'; fa = 'Variants are not used, filter by properties is not available';
								|it = 'Le caratteristiche non sono utilizzate, il filtro per proprietà non è disponibile';
								|pl = 'Charakterystyki nie są używane, filtr wg właściwości jest niedostępny';
								|tr = 'Varyantlar kullanılmamaktadır, özelliklere göre filtre mevcut değil'");
		ElsIf Not Form[ElementNames.ThereAreProperties] Then
			ToolTipText = NStr("vi = 'Không có thuộc tính để thiết lập bộ lọc';
								|ru = 'Отсутствуют свойства для установки отбора';
								|en = 'Missing properties for setting filter'; fa = 'Missing properties for setting filter';
								|it = 'Mancano le proprietà per l''impostazione del filtro';
								|pl = 'Brak właściwości dla ustawienia filtru';
								|tr = 'Filtre yapılandırmak için özellik bulunmamaktadır'");
		EndIf;
		
	EndIf;
	
	Command.ExtendedTooltip.Title = ToolTipText;
	
EndProcedure

&AtClientAtServerNoContext
Function ItemNamesBySettingType(SettingKind)
	
	ReturnStructure = New Structure;
	
	If SettingKind = "Products" Then
		ReturnStructure.Insert("ClarificationOfApplication", "UsageClarificationProduct");
		ReturnStructure.Insert("ApplicationArea", "Products");
		ReturnStructure.Insert("ThereAreProperties", "ProductsHasPropeties");
	ElsIf SettingKind = "Characteristic" Then
		ReturnStructure.Insert("ClarificationOfApplication", "UsageClarificationCharacteristic");
		ReturnStructure.Insert("ApplicationArea", "Characteristic");
		ReturnStructure.Insert("ThereAreProperties", "CharacteristicHasPropeties");
	EndIf;
	
	Return ReturnStructure;
	
EndFunction

&AtServer
Procedure FillInServiceDetailsForUsingPropertiesCharacteristics()
	
	QueryTexts = New Array;
	QueryTexts.Add("
	|SELECT
	|	CASE
	|		WHEN T.UseVariants IN (
	|				VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
	|				VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems),
	|				VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind))
	|			THEN TRUE
	|		ELSE FALSE
	|	END           AS ItemVariantsAreUsed,
	|
	|	MAX(CASE
	|		WHEN SetOfProductProperties_.Ref IS NULL
	|			THEN FALSE
	|		ELSE TRUE
	|	END)          AS ProductsHasPropeties,
	|
	|	MAX(CASE
	|		WHEN T.UseVariants IN (
	|				VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
	|				VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems),
	|				VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind))
	|			THEN (NOT SetPropertiesCharacteristics.Ref IS NULL)
	|		ELSE FALSE
	|	END)          AS CharacteristicHasPropeties
	|
	|FROM
	|	&Table AS T
	|
	|		LEFT JOIN Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes AS SetOfProductProperties_
	|		ON &UseAdditionalAttributesAndInfo
	|			AND NOT SetOfProductProperties_.DeletionMark
	|			AND (SetOfProductProperties_.Ref = &TypeOfItemSetOfProperties1
	|				OR SetOfProductProperties_.Ref = &Set_Catalog_Products_Overall)
	|
	|		LEFT JOIN Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes AS SetPropertiesCharacteristics
	|		ON &UseAdditionalAttributesAndInfo
	|			AND NOT SetPropertiesCharacteristics.DeletionMark
	|			AND (SetPropertiesCharacteristics.Ref =
	|					CASE
	|						WHEN T.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
	|							THEN T.ItemVariantsOwner.CharacteristicsPropertySet
	|						ELSE &TypeOfItemSetOfProperties2
	|					END
	|				OR SetPropertiesCharacteristics.Ref = &Set_Catalog_ItemsCharacteristics_Overall)
	|WHERE
	|	T.Ref = &Ref
	|
	|GROUP BY
	|	CASE
	|		WHEN T.UseVariants IN (
	|				VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
	|				VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems),
	|				VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind))
	|			THEN TRUE
	|		ELSE FALSE
	|	END");
	
	If SettingsMode = PredefinedValue("Enum.AssignmentOptionsOfGoodsResearchSheet.ProductKind") And ValueIsFilled(Products) Then
		TableName = "Products";
		AttributeName = "Products";
		DataSourceTypeOfProduct = "T.ProductKind";
	Else
		TableName = "ItemKinds";
		AttributeName = "ProductKind";
		DataSourceTypeOfProduct = "T";
	EndIf;
	
	Query = New Query;
	QueryText = ProductionManagement.CombineRequestTextsIntoPackage(QueryTexts);
	QueryText = StrReplace(QueryText, "&Table",                      StrTemplate("Catalog.%1", TableName));
	QueryText = StrReplace(QueryText, "&TypeOfItemSetOfProperties1", StrTemplate("%1.PropertiesSet", DataSourceTypeOfProduct));
	QueryText = StrReplace(QueryText, "&TypeOfItemSetOfProperties2", StrTemplate("%1.CharacteristicsPropertySet", DataSourceTypeOfProduct));
	Query.Text = QueryText;
	Query.SetParameter("Ref", ThisObject[AttributeName]);
	Query.SetParameter("UseAdditionalAttributesAndInfo", GetFunctionalOption("UseAdditionalAttributesAndInfo"));
	Query.SetParameter("Set_Catalog_Products_Overall", PropertyManager.PropertiesSetByName("Catalog_Products_Overall"));
	Query.SetParameter("Set_Catalog_ItemsCharacteristics_Overall", PropertyManager.PropertiesSetByName("Catalog_ItemsCharacteristics_Overall"));
	
	QueryResults = Query.ExecuteBatch();
	
	Selection = QueryResults[0].Select();
	If Selection.Next() Then
		FillPropertyValues(ThisObject, Selection);
	Else
		ProductsHasPropeties   = False;
		CharacteristicHasPropeties = False;
		ItemVariantsAreUsed = False;
	EndIf;
	
EndProcedure

#Region Other

&AtClient
Procedure OpenRequirementApplicationRefinementSetting(SettingKind)
	
	FormParameters = New Structure;
	
	FormParameters.Insert("ConnectionKey", GoodsResearchClientServer.SelectionByPropertiesOfCommunicationKey(SettingKind));
	
	SelectionByArrayProperties = GoodsResearchClient.DetailsOfSettingsByLineInArray(
		FormParameters,
		SelectionByProperties,
		GoodsResearchClient.DetailsSettingUpSelectionByProperties());
		
	FormParameters.Insert("SelectionByProperties", SelectionByArrayProperties);
	FormParameters.Insert("SettingKind",     SettingKind);
	FormParameters.Insert("ProductKind",  ProductKind);
	FormParameters.Insert("ReadOnly",  ReadOnly);
	
	CallbackDescription = New CallbackDescription(
		"OpenSettingForClarifyingUseOfGoodsResearchMapEnd",
		ThisObject,
		SettingKind);
	
	OpenForm("Catalog.GoodsResearchSheets.Form.SettingFormOfRefinementForApplyingTheGoodsResearchSheet",
		FormParameters,
		ThisObject,,,,
		CallbackDescription);
	
EndProcedure

// Notification when the application refinement configuration is completed
// 
// Parameters:
// 	SettingsResult - Structure - From:
// 		* SelectionByProperties - ValueTable - selection table by properties
// 		* LongDesc - String - configuration description
// 	AdditionalParameters - Structure - advanced setting
&AtClient
Procedure OpenSettingForClarifyingUseOfGoodsResearchMapEnd(SettingsResult, AdditionalParameters) Export
	
	If SettingsResult = Undefined Then
		Return;
	EndIf;
	
	Modified = True;
	
	ConnectionKey = GoodsResearchClientServer.SelectionByPropertiesOfCommunicationKey(AdditionalParameters);
	
	GoodsResearchClient.UpdateSelectionSettingsByPropertiesByKey(
		SelectionByProperties,
		SettingsResult.SelectionByProperties,
		ConnectionKey);
		
	UpdateInformation2(SelectionByProperties);
	
EndProcedure

&AtServer
Procedure ConfigurationOptionOnChangeAtServer()
	
	CheckClearDetailsWhenChangingDestinationOption();
	
	SetItemsAvailability();
	
	UpdateInformation2(SelectionByProperties);
	
EndProcedure

&AtServer
Procedure StructuresArrayIntoValueTable(StructuresArray, ValueTable, SelectionByProperties)
	
	For Each Item In StructuresArray Do
		NewRow = ValueTable.Add();
		FillPropertyValues(NewRow, Item);
		If Not SelectionByProperties Then
			If ValueIsFilled(NewRow.Characteristic) Then
				NewRow.ItemVariantsAreUsed = True;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure SetItemsAvailability()
	
	VisibilityDestinationOption = (SettingsMode = Enums.AssignmentOptionsOfGoodsResearchSheet.ItemList);
	
	Items.ItemListGroup.Visible = VisibilityDestinationOption;
	Items.GroupProductKind.Visible = Not VisibilityDestinationOption;
	
EndProcedure

&AtServerNoContext
Function GetProductType(Products)
	
	Return Common.ObjectAttributeValue(Products, "ProductKind");
	
EndFunction

&AtServer
Procedure SetConditionalAppearance()

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject,
		"GoodsCharacteristic", "GoodsList.ItemVariantsAreUsed");

EndProcedure

// Checks whether the characteristics in the value table are filled in.
//
// Parameters:
//  GoodsList - ValueTable - a table for checking with columns: Nomenclature, Characteristics.
//  LinesWithErrors - Array of Number - lines with errors.
//  Cancel - Boolean - True - the characteristics are not filled in the required lines, otherwise - False.
&AtServer
Procedure CheckFillingOfCharacteristicsInTableOfValues(Val GoodsList, LinesWithErrors, Cancel)
	
	Query = New Query;
	QueryText =
	"SELECT
	|	GoodsList.Products AS Products,
	|	GoodsList.LineNumber AS LineNumber
	|INTO LinesWithErrors
	|FROM
	|	&GoodsList AS GoodsList
	|WHERE
	|	GoodsList.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|		WHEN CAST(LinesWithErrors.Products AS Catalog.Products).UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
	|			OR CAST(LinesWithErrors.Products AS Catalog.Products).UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
	|			OR CAST(LinesWithErrors.Products AS Catalog.Products).UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS CharacteristicNotFilledIn,
	|	LinesWithErrors.LineNumber AS LineNumber
	|FROM
	|	LinesWithErrors AS LinesWithErrors
	|WHERE
	|	CAST(LinesWithErrors.Products AS Catalog.Products).UseVariants <> VALUE(Enum.ItemVariantsUsageOptions.DontUse)";

	Query.Text = QueryText;
	
	Query.SetParameter("GoodsList", GoodsList.Unload());
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		If Selection.CharacteristicNotFilledIn Then
			Cancel = True;
			Error = New Structure("LineNumber, ErrorType, Products", Selection.LineNumber, "CheckingCharacteristics", "");
			LinesWithErrors.Add(Error);
		EndIf;
		
	EndDo;

EndProcedure

// Checks duplicate rows in the value table.
//
// Parameters:
//  GoodsList - ValueTable - a table for checking with columns: Nomenclature, Characteristics.
//  LinesWithErrors - Array of Structure - lines with errors.
//  Cancel - Boolean - True - there are duplicates in the lines, otherwise - False.
&AtServer
Procedure CheckDuplicatesInValueTable(Val GoodsList, LinesWithErrors, Cancel)
	
	Query = New Query;
	QueryText =
	"SELECT
	|	GoodsList.Products AS Products,
	|	GoodsList.Characteristic AS Characteristic,
	|	GoodsList.LineNumber AS LineNumber
	|INTO LinesWithErrors
	|FROM
	|	&GoodsList AS GoodsList
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	COUNT(*) AS DuplicateCount,
	|	LinesWithErrors.Products AS Products,
	|	LinesWithErrors.Characteristic AS Characteristic
	|INTO DuplicatesOfLines
	|FROM
	|	LinesWithErrors AS LinesWithErrors
	|GROUP BY
	|	LinesWithErrors.Products,
	|	LinesWithErrors.Characteristic
	|HAVING
	|	COUNT(*) > 1
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LinesWithErrors.Products AS Products,
	|	LinesWithErrors.Characteristic AS Characteristic,
	|	LinesWithErrors.LineNumber AS LineNumber
	|FROM
	|	DuplicatesOfLines AS DuplicatesOfLines
	|		INNER JOIN LinesWithErrors AS LinesWithErrors
	|		ON LinesWithErrors.Products = DuplicatesOfLines.Products
	|		AND LinesWithErrors.Characteristic = DuplicatesOfLines.Characteristic";

	Query.Text = QueryText;
	
	Query.SetParameter("GoodsList", GoodsList.Unload());
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do

		Cancel = True;
		Error = New Structure("LineNumber, ErrorType, Products", Selection.LineNumber, "CheckingDuplicates",
			ProductsClientServer.ProductPresentation(Selection.Products, Selection.Characteristic));
		LinesWithErrors.Add(Error);

	EndDo;

EndProcedure

&AtServer
Procedure CheckCompletionOfItemList(Val GoodsList, LinesWithErrors, Cancel)
	
	CheckFillingOfCharacteristicsInTableOfValues(GoodsList, LinesWithErrors, Cancel);
	CheckDuplicatesInValueTable(GoodsList, LinesWithErrors, Cancel);
	
EndProcedure

&AtClient
Procedure RecalculateLineNumbers()
	
	For Each String In GoodsList Do
		String.LineNumber = GoodsList.IndexOf(String)+1;
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion
