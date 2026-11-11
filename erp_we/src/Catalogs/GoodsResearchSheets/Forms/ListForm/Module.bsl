
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	// StandardSubsystems.AttachableCommands
	TypesList = List.SettingsComposer.Settings.Selection.SelectionAvailableFields.FindField(New DataCompositionField("Ref")).Type;
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = TypesList;
	PlacementParameters.CommandBar = Items.FormCommandBar;
	
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.Core
	
	SetVisibility1();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterProductKindOnChange(Item)
	
	FilterProductTypeWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure FilterProductsOnChange(Item)
	
	FilterProductsWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure FilterStatusOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Status", FilterStatus, DataCompositionComparisonType.Equal,, ValueIsFilled(FilterStatus));
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtServerNoContext
Procedure ListOnGetDataAtServer(TagName, Settings, Rows)
	
	VisibleNomenclatureTemplate = NStr("vi = '%1 %2 %3';
										|ru = '%1 %2 %3';
										|en = '%1 %2 %3'; fa = '%1 %2 %3';
										|it = '%1 %2 %3';
										|pl = '%1 %2 %3';
										|tr = '%1 %2 %3'");
	TemplateListOfItems = NStr("vi = '%1 %2';
								|ru = '%1 %2';
								|en = '%1 %2'; fa = '%1 %2';
								|it = '%1 %2';
								|pl = '%1 %2';
								|tr = '%1 %2'");
	TemplateMultiplePositions = NStr("vi = '%1 và hơn nữa %2';
									|ru = '%1 и еще %2';
									|en = '%1 and %2 more'; fa = '%1 and %2 more';
									|it = '%1 and %2 more';
									|pl = '%1 and %2 more';
									|tr = '%1 ve %2 tane daha  '");
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	GoodsResearchSheetsGoods.Ref AS Ref,
		|	GoodsResearchSheetsGoods.Products AS Products,
		|	GoodsResearchSheetsGoods.Characteristic AS Characteristic,
		|	GoodsResearchSheetsGoods.ProductKind AS ProductKind,
		|	GoodsResearchSheetsGoods.Ref.AssignmentOption AS AssignmentOption
		|FROM
		|	Catalog.GoodsResearchSheets.Goods AS GoodsResearchSheetsGoods
		|WHERE
		|	GoodsResearchSheetsGoods.Ref IN(&References)
		|TOTALS BY
		|	Ref";
	
	Query.SetParameter("References", Rows.GetKeys());
	QueryResult = Query.Execute();
	
	FetchLink = QueryResult.Select(QueryResultIteration.ByGroups);
	
	While FetchLink.Next() Do
		
		FirstPosition = True;
		NumberOfRows = 1;
		SelectionDetailRecords = FetchLink.Select();
	
		While SelectionDetailRecords.Next() Do
			If FirstPosition Then
				FirstPosition = False;
				If SelectionDetailRecords.AssignmentOption
					= Enums.AssignmentOptionsOfGoodsResearchSheet.ProductKind Then
					Presentation = StringFunctionsClientServer.SubstituteParametersToString(VisibleNomenclatureTemplate, 
						?(ValueIsFilled(SelectionDetailRecords.ProductKind), String(
						SelectionDetailRecords.ProductKind) + ";", ""), ?(ValueIsFilled(
						SelectionDetailRecords.Products), String(SelectionDetailRecords.Products) + ";", ""),
						?(ValueIsFilled(SelectionDetailRecords.Characteristic), String(
						SelectionDetailRecords.Characteristic) + ";", ""));
				Else
					Presentation = StringFunctionsClientServer.SubstituteParametersToString(TemplateListOfItems,
						?(ValueIsFilled(SelectionDetailRecords.Products), String(
						SelectionDetailRecords.Products) + ";", ""), ?(ValueIsFilled(
						SelectionDetailRecords.Characteristic), String(SelectionDetailRecords.Characteristic) + ";", ""));
				EndIf;
			Else
				NumberOfRows = NumberOfRows + 1;
			EndIf;
		EndDo;
		
		ListLine = Rows[FetchLink.Ref];
		If NumberOfRows > 1 Then
			If CurrentLanguage().LanguageCode = "ru" Then
				PresentationNumberOfPositions = GetStringDeclensionsByNumber("position", NumberOfRows - 1, "",
					"NM=Cardinal", "CS=Nominative; NP=Number");
				ListLine.Data["Text"] = StringFunctionsClientServer.SubstituteParametersToString(
					TemplateMultiplePositions, TrimAll(Presentation), PresentationNumberOfPositions[0]);
			Else
				ListLine.Data["Text"] = StringFunctionsClientServer.SubstituteParametersToString(
					TemplateMultiplePositions, Presentation, String(NumberOfRows - 1));
			EndIf;
		Else
			Presentation = TrimAll(Presentation);
			StringFunctionsClientServer.DeleteLastCharInString(Presentation);
			ListLine.Data["Text"] = Presentation;
		EndIf;
		ListLine.Appearance["Text"].SetParameterValue("TextColor", WebColors.Blue);
	EndDo;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

// Parameters:
//   Command - FormCommand - executed command
//
&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

&AtClient
Procedure SetStatusUnderDevelopment(Command)

	SetStatusOfGoodsResearchCard("Draft", NStr("vi = 'Bản nháp';
												|ru = 'Черновик';
												|en = 'Draft'; fa = 'پیش‌نویس';
												|it = 'Draft';
												|pl = 'Draft';
												|tr = 'Taslak'"));
	
EndProcedure

&AtClient
Procedure SetStatusValid(Command)
	
	SetStatusOfGoodsResearchCard("Valid", NStr("vi = 'Có hiệu lực';
												|ru = 'Действует';
												|en = 'Valid'; fa = 'معتبر';
												|it = 'In vigore';
												|pl = 'Aktualne';
												|tr = 'Aktif'"));
	
EndProcedure

&AtClient
Procedure SetStatusClosed(Command)
	
	SetStatusOfGoodsResearchCard("Closed_", NStr("vi = 'Đã đóng';
												|ru = 'Закрыта';
												|en = 'Closed'; fa = 'بسته‌شده';
												|it = 'Chiusa';
												|pl = 'Zamknięta';
												|tr = 'Kapalı'"));
	
EndProcedure

#EndRegion

#Region Private

#Region Other
&AtClient
Procedure SetStatusOfGoodsResearchCard(StatusValue, StatusPresentation)

	HighlightedLinks = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	
	GoodsResearchClient.SetStatusOfGoodsResearchCards(StatusValue, StatusPresentation, HighlightedLinks);

EndProcedure

&AtServer
Procedure FilterProductsWhenChangedOnServer()

	QueryTexts = New Array;
	
	If ValueIsFilled(FilterProducts) Then
		
		QueryTexts.Add("
		|SELECT
		|	T.Ref AS Ref
		|FROM
		|	Catalog.GoodsResearchSheets.Goods AS T
		|WHERE
		|	T.Products = &Products
		|
		|UNION ALL
		|
		|SELECT
		|	T.Ref
		|FROM
		|	Catalog.GoodsResearchSheets.Goods AS T
		|WHERE
		|	T.Products = VALUE(Catalog.Products.EmptyRef)
		|	AND T.ProductKind = &ProductKind
		|");
		
	EndIf;
	
	FilterList = New ValueList;
	Use = (QueryTexts.Count() > 0);
	
	If Use Then
		
		Query = New Query;
		Query.Text = StrConcat(QueryTexts, " UNION ");
		Query.SetParameter("Products",    FilterProducts);
		ProductKind = Common.ObjectAttributeValue(FilterProducts, "ProductKind");
		Query.SetParameter("ProductKind", ProductKind);
		
		FilterList.LoadValues(Query.Execute().Unload().UnloadColumn("Ref"));
		
		If FilterProductKind <> ProductKind Then
			FilterProductKind = Undefined;
			CommonClientServer.DeleteDynamicListFilterGroupItems(List, "Ref");
		EndIf;
		
	EndIf;
		
	FilterRemainingGoodsByShelfLives = CommonClientServer.CreateFilterItemGroup(
		List.SettingsComposer.FixedSettings.Filter.Items,
		NStr("vi = 'Lọc theo mặt hàng';
			|ru = 'Отбор по номенклатуре';
			|en = 'Filter by items'; fa = 'فیلتر بر اساس اقلام';
			|it = 'La selezione in base all''elenco articoli';
			|pl = 'Filtr wg pozycji';
			|tr = 'Öğeye göre filtre'"),
		DataCompositionFilterItemsGroupType.AndGroup);
	
	CommonClientServer.AddCompositionItem(
			FilterRemainingGoodsByShelfLives,
			"Ref",
			DataCompositionComparisonType.InList,
			FilterList,
			,
			Use);

EndProcedure

&AtServer
Procedure FilterProductTypeWhenChangedOnServer()

	QueryTexts = New Array;
	
	If ValueIsFilled(FilterProductKind) Then
		
		QueryTexts.Add("
		|SELECT
		|	T.Ref
		|FROM
		|	Catalog.GoodsResearchSheets.Goods AS T
		|WHERE
		|	T.ProductKind = &ProductKind
		|
		|UNION ALL
		|
		|SELECT
		|	T.Ref
		|FROM
		|	Catalog.GoodsResearchSheets.Goods AS T
		|WHERE
		|	T.Products.ProductKind = &ProductKind
		|");
		
	EndIf;
	
	FilterList = New ValueList;
	Use = (QueryTexts.Count() > 0);
	
	If Use Then
		
		Query = New Query;
		Query.Text = StrConcat(QueryTexts, " UNION ");
		Query.SetParameter("ProductKind", FilterProductKind);
		
		FilterList.LoadValues(Query.Execute().Unload().UnloadColumn("Ref"));
		
		ProductKind = Common.ObjectAttributeValue(FilterProducts, "ProductKind");
		If FilterProductKind <> ProductKind Then
			FilterProducts = Undefined;
			CommonClientServer.DeleteDynamicListFilterGroupItems(List, "Ref");
		EndIf;
		
	EndIf;
	
	FilterByTheProductKind = CommonClientServer.CreateFilterItemGroup(
		List.SettingsComposer.FixedSettings.Filter.Items,
		NStr("vi = 'Lọc theo loại mặt hàng';
			|ru = 'Отбор по виду номенклатуры';
			|en = 'Filter by item kind'; fa = 'Filter by item kind';
			|it = 'Filter by item kind';
			|pl = 'Filter by item kind';
			|tr = 'Öğe türüne göre filtre'"),
		DataCompositionFilterItemsGroupType.AndGroup);
	
	CommonClientServer.AddCompositionItem(
			FilterByTheProductKind,
			"Ref",
			DataCompositionComparisonType.InList,
			FilterList,
			,
			Use);
	
EndProcedure

&AtServer
Procedure SetVisibility1()
	
	ThereIsChangeAccess = AccessRight("Update", Metadata.Catalogs.GoodsResearchSheets);
	
	Items.ListSetStatusUnderDevelopment.Visible = ThereIsChangeAccess;
	Items.ListSetStatusValid.Visible = ThereIsChangeAccess;
	Items.ListSetStatusClosed.Visible = ThereIsChangeAccess;
	
EndProcedure

#EndRegion

#EndRegion
