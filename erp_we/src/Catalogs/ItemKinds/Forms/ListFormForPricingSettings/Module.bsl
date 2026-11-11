#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	UseItemVariants = GetFunctionalOption("UseItemVariants");
	UseItemsBatch          = GetFunctionalOption("UseItemsBatch");
	UseItemPackages       = GetFunctionalOption("UseItemPackages");
	
	SetConditionalAppearance();
	
	SetFOSettings();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
		
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure ChangePricingSettings(Command)
	
	ChangePricingSettingsOpen();

EndProcedure

&AtClient
Procedure ChangePricingSettingsOpen()
	
	CurrentData = Items.List.CurrentData;
	
	If CurrentData = Undefined Or CurrentData.IsFolder Then
		Return;
	EndIf;
	
	FormParameters = New Structure;	
	FormParameters.Insert("FeatureOption", 		2);
	FormParameters.Insert("VersionOfTheSeries", 				2);
	FormParameters.Insert("PackagingOption", 				2);
	
	If Items.List.SelectedRows.Count()>1 Then
		
		FormParameters.Insert("UseCharacteristics", 	UseItemVariants);
		FormParameters.Insert("KeepAccountingByBatch", 			UseItemsBatch);
		FormParameters.Insert("UsePackages", 		UseItemPackages);
		
	Else
		
		FormParameters.Insert("UseCharacteristics", 	CurrentData.UseCharacteristics And UseItemVariants);
		FormParameters.Insert("KeepAccountingByBatch", 			CurrentData.KeepAccountingByBatch And UseItemsBatch);
		FormParameters.Insert("UsePackages", 		CurrentData.UsePackages And UseItemPackages);
		
	EndIf;

	
	DescriptionOfClosingNotification = New CallbackDescription("ChangePricingSettingsCompletion", ThisObject);
	
	OpenForm("Catalog.ItemKinds.Form.PricingBreakdownSettingsForm",FormParameters, ThisForm,,,,DescriptionOfClosingNotification,FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
		
	StandardProcessing = False;
	
	CurrentData = Item.CurrentData;
	
	If CurrentData <> Undefined Then
		If Not CurrentData.IsFolder Then
			If Field = Items.ProductKind Then

				FormParameters = New Structure;
				FormParameters.Insert("Key", CurrentData.ProductKind);
				FormParameters.Insert("UsePriceManagementSystem25", True);
				OpenForm("Catalog.ItemKinds.ObjectForm", FormParameters, Items.List);
				
			Else
				
				ChangePricingSettingsOpen();
				
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region AttachableCommands


// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure

// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

#Region Other

&AtServer
Procedure SetFOSettings()
	
	Items.TypesOfNomenclatureGroupCharacteristics.Visible = UseItemVariants;
	Items.TypesOfNomenclatureGroupSeries.Visible = UseItemsBatch;
	Items.TypesOfNomenclaturePackagingGroup.Visible = UseItemPackages;
	
EndProcedure

&AtClient
Procedure ChangePricingSettingsCompletion(AlertResult, NotificationParameters) Export

	CurrentData = Items.List.CurrentData;
	If CurrentData = Undefined Or CurrentData.IsFolder Then
		Return;
	EndIf;
	
	ItemKinds = New Array();
	If Items.List.SelectedRows.Count()>1 Then
		For Each String In Items.List.SelectedRows Do
			ItemKinds.Add(String);
		EndDo;
	Else
		ItemKinds.Add(CurrentData.ProductKind);
	EndIf;
	
	ChangePricingSettingsCompletionServer(ItemKinds, AlertResult);
	
	Items.List.Refresh();
	
EndProcedure

&AtServer
Procedure ChangePricingSettingsCompletionServer(ItemKinds, AlertResult) Export
	
	InstallationParameters = New Structure("SettingsOfPriceKeyByItemVariant, SettingsOfPriceKeyByBatch, SettingsOfPriceKeyByPackage", Undefined, Undefined,Undefined,);
	
	If AlertResult.FeatureOption = 0 Then
		InstallationParameters.SettingsOfPriceKeyByItemVariant = Enums.FilterOptionForPriceKey.DontUse;
	ElsIf AlertResult.FeatureOption = 1 Then
		InstallationParameters.SettingsOfPriceKeyByItemVariant = Enums.FilterOptionForPriceKey.Use;
	EndIf;

	If AlertResult.VersionOfTheSeries = 0 Then
		InstallationParameters.SettingsOfPriceKeyByBatch = Enums.FilterOptionForPriceKey.DontUse;
	ElsIf AlertResult.VersionOfTheSeries = 1 Then
		InstallationParameters.SettingsOfPriceKeyByBatch = Enums.FilterOptionForPriceKey.Use;
	EndIf;

	If AlertResult.PackagingOption = 0 Then
		InstallationParameters.SettingsOfPriceKeyByPackage = Enums.FilterOptionForPriceKey.DontUse;
	ElsIf AlertResult.PackagingOption = 1 Then
		InstallationParameters.SettingsOfPriceKeyByPackage = Enums.FilterOptionForPriceKey.Use;
	EndIf;

	Catalogs.ItemKinds.SetPricingDetails(ItemKinds, InstallationParameters);

EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SetCharacteristics.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CharacteristicsDescription_2.Name);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.UseCharacteristics");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.IsFolder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("BackColor", WebColors.WhiteSmoke);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng đặc tính>';
													|ru = '<характеристики не используются>';
													|en = '<variants are not used>'; fa = '<گونه‌ها استفاده نمی‌شوند>';
													|it = '<le caratteristiche non vengono usate>';
													|pl = '<charakterystyki nie dotyczą>';
													|tr = '<varyantlar kullanılmamaktadır>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CharacteristicsDescription_2.Name);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.UseCharacteristics");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.SetCharacteristics");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 0;
	Item.Appearance.SetParameterValue("Text", "");
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.InstallSeries.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SeriesDescription.Name);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.KeepAccountingByBatch");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.IsFolder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("BackColor", WebColors.WhiteSmoke);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng sê-ri>';
													|ru = '<серии не используются>';
													|en = '<batches are not used>'; fa = '<batches are not used>';
													|it = '<le serie non sono utilizzate>';
													|pl = '<serie nie są używane>';
													|tr = '<partiler kullanılmamaktadır>'"));

	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SeriesDescription.Name);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.KeepAccountingByBatch");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.InstallSeries");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 0;
	Item.Appearance.SetParameterValue("Text", "");
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.InstallPackages_2.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PackagingDescription.Name);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.UsePackages");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.IsFolder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("BackColor", WebColors.WhiteSmoke);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng bộ đóng gói>';
													|ru = '<упаковки не используются>';
													|en = '<packaging units are not used>'; fa = '<packaging units are not used>';
													|it = '<уimballaggio non utilizzato>';
													|pl = '<opakowania nie są wykorzystywane>';
													|tr = '<paketleme üniteleri kullanılmamaktadır>'"));

	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PackagingDescription.Name);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.UsePackages");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.InstallPackages_2");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 0;
	Item.Appearance.SetParameterValue("Text", "");
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductKind.Name);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.UseCharacteristics");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.KeepAccountingByBatch");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.UsePackages");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	Item.Appearance.SetParameterValue("BackColor", WebColors.WhiteSmoke);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);

EndProcedure

&AtServerNoContext
Procedure ListOnGetDataAtServer(TagName, Settings, Rows)
	
	Query = New Query;
	Query.Text =
	    "SELECT
	    |	ItemKinds.Ref AS ProductKind,
	    |	ItemKinds.ItemVariantsAttributesForPriceKey.(
	    |		AttributeName),
	    |	ItemKinds.BatchAttributesForPriceKey.(
	    |		AttributeName)
	    |FROM
	    |	Catalog.ItemKinds AS ItemKinds
	    |WHERE
	    |	ItemKinds.Ref IN (&ItemKinds)
	    |	AND NOT ItemKinds.IsFolder";
	
	Query.SetParameter("ItemKinds", Rows.GetKeys());
	
	DataListLine = Undefined;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
			
		DataListLine = Rows[Selection.ProductKind].Data;

		DataListLine.CharacteristicsDescription_2 = NStr("vi = 'theo đặc tính';
														|ru = 'по характеристикам';
														|en = 'by item variants'; fa = 'بر اساس گونه‌های قلم';
														|it = 'per caratteristiche';
														|pl = 'według charakterystyk';
														|tr = 'varyantlara göre'");
		If DataListLine.SetCharacteristics = 0 Then
			TempTable = Selection.ItemVariantsAttributesForPriceKey.Unload();
			If TempTable.Count() > 0 Then
				AttributesArray = TempTable.UnloadColumn("AttributeName");
				Attributes = StrConcat(AttributesArray, ",");

				DataListLine.CharacteristicsDescription_2 = StrTemplate(NStr("vi = 'theo mục tin (%1)';
																			|ru = 'по реквизитам (%1)';
																			|en = 'by attributes (%1)'; fa = 'by attributes (%1)';
																			|it = 'Per attributi (%1)';
																			|pl = 'wg artybutów (%1)';
																			|tr = 'özniteliklere göre (%1)'"), Attributes);
			EndIf;
		EndIf;
		
		DataListLine.SeriesDescription = NStr("vi = 'theo sê-ri';
												|ru = 'по сериям';
												|en = 'by batch'; fa = 'بر اساس بچ';
												|it = 'Per serie';
												|pl = 'wg serii';
												|tr = 'partilere göre'");
		If DataListLine.InstallSeries = 0 Then
			TempTable = Selection.BatchAttributesForPriceKey.Unload();
			If TempTable.Count() > 0 Then
				AttributesArray = TempTable.UnloadColumn("AttributeName");
				Attributes = StrConcat(AttributesArray, ",");

				DataListLine.SeriesDescription = StrTemplate(NStr("vi = 'theo mục tin (%1)';
																	|ru = 'по реквизитам (%1)';
																	|en = 'by attributes (%1)'; fa = 'by attributes (%1)';
																	|it = 'Per attributi (%1)';
																	|pl = 'wg artybutów (%1)';
																	|tr = 'özniteliklere göre (%1)'"), Attributes);
			EndIf;
		EndIf;
		
		DataListLine.PackagingDescription = NStr("vi = 'theo bộ đóng gói';
												|ru = 'по упаковкам';
												|en = 'by packaging units'; fa = 'بر اساس واحدهای بسته‌بندی';
												|it = 'Per imballaggi';
												|pl = 'wg opakowań';
												|tr = 'paketleme ünitelerine göre'");

	EndDo;

        
EndProcedure

#EndRegion

#EndRegion

