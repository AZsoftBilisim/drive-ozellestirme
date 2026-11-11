
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	If Parameters.Property("Filter") And Parameters.Filter.Property("Owner") Then

		Owner            = Parameters.Filter.Owner;
		OwnerForSelection   = Undefined;
		GeneralFeatures = Undefined;

		If TypeOf(Owner) = Type("CatalogRef.Products") Then

			OwnerUseOfCharacteristics = Common.ObjectAttributeValue(Owner, "UseVariants");

			If OwnerUseOfCharacteristics = Enums.ItemVariantsUsageOptions.SpecialForItems Then
				OwnerForSelection = Owner;
				GeneralFeatures = False;
			ElsIf OwnerUseOfCharacteristics = Enums.ItemVariantsUsageOptions.CommonForItemKind Then
				OwnerForSelection = Common.ObjectAttributeValue(Owner, "ProductKind");
				GeneralFeatures = True;
			ElsIf OwnerUseOfCharacteristics = Enums.ItemVariantsUsageOptions.CommonWithOtherItemKind Then
				OwnerForSelection = Common.ObjectAttributeValue(Owner, "ItemVariantsOwner");
				GeneralFeatures = True;
			EndIf;

			Products = Owner;
			
		ElsIf TypeOf(Owner) = Type("CatalogRef.ItemKinds") Then

			OwnerUseOfCharacteristics = Common.ObjectAttributeValue(Owner, "UseVariants");

			If OwnerUseOfCharacteristics = Enums.ItemVariantsUsageOptions.CommonForItemKind Then
				OwnerForSelection = Owner;
				GeneralFeatures = True;
			ElsIf OwnerUseOfCharacteristics = Enums.ItemVariantsUsageOptions.CommonWithOtherItemKind Then
				OwnerForSelection = Common.ObjectAttributeValue(Owner, "ItemVariantsOwner");
				GeneralFeatures = True;
			EndIf;

		EndIf;

		If OwnerForSelection = Undefined Then

			TitleText = NStr("vi = 'Đối với phần tử: ""%Owner%"", không sử dụng đặc tính';
							|ru = 'Для элемента: ""%Owner%"" характеристики не используются';
							|en = 'Variants are not used for item: ""%Owner%""'; fa = 'Variants are not used for item: ""%Owner%""';
							|it = 'Per l''elemento: ""%Owner%"" le caratteristiche non sono utilizzate';
							|pl = 'Dla elementu: ""%Owner%"" charakterystyki nie są używane';
							|tr = '""%Owner%"" öğesi için varyantlar kullanılmamaktadır'");
			TitleText = StrReplace(TitleText, "%Owner%", String(Owner));

			AutoTitle = False;
			Title     = TitleText;

			Items.List.ReadOnly = True;
		Else
			
			TitleText = NStr("vi = 'Đặc tính mặt hàng (%Owner%)';
							|ru = 'Характеристики номенклатуры (%Owner%)';
							|en = 'Item variants (%Owner%)'; fa = 'Item variants (%Owner%)';
							|it = 'Caratteristiche dell''articolo (%Owner%)';
							|pl = 'Charakterystyki towarów (%Owner%)';
							|tr = 'Ürün varyantları (%Owner%)'");
			TitleText = StrReplace(TitleText, "%Owner%", String(OwnerForSelection));

			AutoTitle = False;
			Title     = TitleText;
			
		EndIf;

		If GeneralFeatures = True Then
			Items.WarningDecoration.Visible = True;
			Items.WarningDecoration.Title = Items.WarningDecoration.Title + " """ + String(OwnerForSelection) + """";
		Else
			Items.WarningDecoration.Visible = False;
		EndIf;
		
		Parameters.Filter.Owner = OwnerForSelection;

	EndIf;

	If ValueIsFilled(Products) Then
		ItemsType = Common.ObjectAttributeValue(Products, "ItemsType");
		ShowTheCompositionOfTheSet = (ItemsType = Enums.ItemsTypes.Set) And GetFunctionalOption("UseSets"); 
	Else
		ShowTheCompositionOfTheSet = False;
	EndIf;
	
	CommonClientServer.SetDynamicListParameter(List, "Products", Products, True);
	CommonClientServer.SetDynamicListParameter(List, "ShowTheCompositionOfTheSet", ShowTheCompositionOfTheSet, True);
	Items.SetComposition.Visible = ShowTheCompositionOfTheSet;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.Core
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_ItemsCharacteristics" 
		And ValueIsFilled(Source) Then
		Items.List.CurrentRow = Source;
	EndIf;
	
	If EventName = "Write_ProductKitConfigurations" Then
		Items.List.Refresh();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.SetComposition Then
		
		StandardProcessing = False;
		
		BasicEquipment = SetsServerCall.DefaultProductConfigurationOption(
			Owner,
			Items.List.CurrentData.Ref);
		
		FormParameters = Undefined;
		If Not ValueIsFilled(BasicEquipment) Then
			Filter = New Structure;
			Filter.Insert("Owner", Owner);
			Filter.Insert("Characteristic", Items.List.CurrentData.Ref);
			FormParameters = New Structure("Filter", Filter);
		Else
			FormParameters = New Structure("Key", BasicEquipment);
		EndIf;
		
		OpenForm("Catalog.ProductKitConfigurations.Form.SetComposition",
			FormParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	If Not Copy 
		And Not ValueIsFilled(Owner) Then
		WarningText = NStr("vi = 'Để tạo đặc tính, cần mở danh sách từ biểu mẫu dạng mặt hàng hoặc mặt hàng.';
							|ru = 'Для создания характеристик список нужно открывать из формы вида номенклатуры или номенклатуры.';
							|en = 'To create variants, the list should be opened from the form of item kind or products.'; fa = 'To create variants, the list should be opened from the form of item kind or products.';
							|it = 'Per creare caratteristiche, è necessario aprire l''elenco dal modulo dell''articolo o del tipo di articolo.';
							|pl = 'W celu utworzenia charakterystyk, listę należy otwierać z formularza rodzaju towarów albo towaru.';
							|tr = 'Özellikleri oluşturmak için liste öğe veya öğe türü formundan açılmalıdır.'");
		ShowMessageBox(,WarningText);
		Cancel = True;
		Return;
	EndIf;
	
	If Not Copy	And Not Var_Group Then
		Cancel = True;
		If TypeOf(Owner) = Type("CatalogRef.Products") Then
			ProductKind = GeneralPurposeTMServerCall.ObjectAttributeValue(Owner, "ProductKind");
		Else
			ProductKind = Owner;
		EndIf;
		ParametersStructure = New Structure("ProductKind, Owner, Products", ProductKind, Owner, Products);
		OpenForm("Catalog.ItemsCharacteristics.Form.ItemForm",  ParametersStructure, ThisForm);
	ElsIf Copy
		And Not Var_Group Then
		Cancel = True;
		CurrentData = Items.List.CurrentData;
		ParametersStructure = New Structure("CopyingValue, Products", CurrentData.Ref, Products);
		OpenForm("Catalog.ItemsCharacteristics.Form.ItemForm",  ParametersStructure, ThisForm);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure MarkSelectedOnesWithDuplicates(Command)
	SearchAndReplaceDuplicatesMasterDataClient.MarkSelectedOnesWithDuplicates(Items.List);
EndProcedure

#EndRegion

#Region Private


&AtServerNoContext
Procedure ListOnGetDataAtServer(TagName, Settings, Rows)
	
	ShowTheCompositionOfTheSet = Settings.DataParameters.Items.Find("ShowTheCompositionOfTheSet");
	
	If ShowTheCompositionOfTheSet = Undefined
		Or Not ShowTheCompositionOfTheSet.Value Then
		Return;
	EndIf;
	
	DisplayedCharacteristics = Rows.GetKeys();
	Products = Settings.DataParameters.Items.Find("Products");
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	COUNT(ConfigurationOptionsForProductRange.LineNumber) AS NumberOfComponents_,
	|	ConfigurationOptionsForProductRange.Ref.Characteristic AS Characteristic
	|FROM
	|	Catalog.ProductKitConfigurations.Goods AS ConfigurationOptionsForProductRange
	|WHERE
	|	ConfigurationOptionsForProductRange.Ref.Characteristic IN (&DisplayedCharacteristics)
	|	AND ConfigurationOptionsForProductRange.Ref.Owner = &Products
	|
	|GROUP BY
	|	ConfigurationOptionsForProductRange.Ref.Characteristic";
	
	Query.SetParameter("DisplayedCharacteristics", DisplayedCharacteristics);
	Query.SetParameter("Products", Products.Value);
	
	InformationOnComponents = Query.Execute().Unload();
	
	For Each KeyValue In Rows Do
		
		FoundRows = InformationOnComponents.FindRows(New Structure("Characteristic", KeyValue.Key));
		
		If FoundRows.Count() = 0 Then
			NumberOfComponents_ = 0;
		Else
			NumberOfComponents_ = FoundRows[0].NumberOfComponents_;
		EndIf;
		
		If NumberOfComponents_ > 0 Then
			TextOfComponents = StringWithNumber(
				NStr("vi = ';%1 thành phần;;%1 thành phần;%1 thành phần;%1 thành phần';
					|ru = ';%1 комплектующая;;%1 комплектующие;%1 комплектующих;%1 комплектующие';
					|en = ';%1 component;;%1 components;%1 components;%1 components'; fa = ';%1 component;;%1 components;%1 components;%1 components';
					|it = ';%1 componente;;%1 componenti;%1 componenti;%1 componenti';
					|pl = ';%1 komponent;;%1 komponenty;%1 komponentów;%1 komponenty';
					|tr = ';%1 set;;%1 setler;%1 setlerin;%1 setler'"),
				NumberOfComponents_,
				NumericValueType.Cardinal);
		Else
			TextOfComponents = NStr("vi = 'Tùy chỉnh';
									|ru = 'Настроить';
									|en = 'Customize'; fa = 'سفارشی‌سازی';
									|it = 'Impostare';
									|pl = 'Ustaw';
									|tr = 'Ayarla'");
		EndIf;
		
		LineToDraw = KeyValue.Value;
		
		LineToDraw.Data.SetComposition = TextOfComponents;
	EndDo;
	
EndProcedure

#EndRegion