#Region Variables

&AtClient
Var ClosingInProgress;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	ReadOnly = Not AccessRight("Update", Metadata.InformationRegisters.SetUpSupplyControl);
	
	If Parameters.AvailableStockControl Then
		Zakolovok = NStr("vi = 'Mặt hàng không kiểm soát số dư tự do (Kho bãi: %1)';
						|ru = 'Номенклатура без контроля свободного остатка (Склад: %1)';
						|en = 'Item without available inventory control (Warehouse: %1)'; fa = 'Item without available inventory control (Warehouse: %1)';
						|it = 'Articolo senza il controllo della rimanenza libera (Magazzino: %1)';
						|pl = 'Pozycja bez kontroli dostępnego salda (Magazyn: %1)';
						|tr = 'Serbest balans kontrolü olmayan öğe (Ambar: %1)'");
	Else
		Zakolovok = NStr("vi = 'Mặt hàng có kiểm soát số dư tự do (Kho bãi: %1)';
						|ru = 'Номенклатура с контролем свободного остатка (Склад: %1)';
						|en = 'Item with available inventory control (Warehouse: %1)'; fa = 'Item with available inventory control (Warehouse: %1)';
						|it = 'Articolo con controllo della rimanenza libera (Magazzino: %1)';
						|pl = 'Pozycja z kontrolą dostępnego salda (Magazyn: %1)';
						|tr = 'Serbest balans kontrolü olan öğe (Ambar: %1)'");
	EndIf;
	Title = StrReplace(Zakolovok, "%1",Parameters.Warehouse);
	
	AvailableStockControl = Parameters.AvailableStockControl;
	Warehouse                          = Parameters.Warehouse;
	
	UpdateList();
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	If ChoiceSource.FormName = "InformationRegister.SetUpSupplyControl.Form.SelectItemVariants" Then
		CurrentRow = Items.List.CurrentData;
		
		FillPropertyValues(CurrentRow, ValueSelected);
		FormCaption(CurrentRow);
	EndIf;
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	StandardProcessing = False;
	
	If Modified And Exit Then
		Cancel = True;
		WarningText = NStr("vi = 'Đã thay đổi dữ liệu. Tất cả thay đổi sẽ bị mất.';
							|ru = 'Данные были изменены. Все изменения будут потеряны.';
							|en = 'All changes made to the data will be lost.'; fa = 'All changes made to the data will be lost.';
							|it = 'I dati sono stati modificati. Tutte le modifiche verranno perse.';
							|pl = 'Dane zostały zmienione. Wszystkie zmiany zostaną utracone.';
							|tr = 'Veri değişti. Tüm değişiklikler kaybolacak.'");
		Return;
	EndIf;
	
	If Not ClosingInProgress And Modified Then
		
		ButtonsList = New ValueList();
		ButtonsList.Add("Close", NStr("vi = 'Đóng';
										|ru = 'Закрыть';
										|en = 'Close'; fa = 'بستن';
										|it = 'Chiudere';
										|pl = 'Zamknij';
										|tr = 'Kapat'"));
		ButtonsList.Add("NotClose", NStr("vi = 'Không đóng';
										|ru = 'Не закрывать';
										|en = 'Do not close'; fa = 'بسته نشود';
										|it = 'Non chiudere';
										|pl = 'Nie zamykaj';
										|tr = 'Kapatmayın'"));
		
		Cancel = True;
		ShowQueryBox(New CallbackDescription("BeforeCloseCompletion", ThisObject), NStr("vi = 'Tất cả dữ liệu đã thay đổi sẽ bị mất. Đóng biểu mẫu?';
																						|ru = 'Все измененные данные будут потеряны. Закрыть форму?';
																						|en = 'All changed data will be lost. Close the form?'; fa = 'All changed data will be lost. Close the form?';
																						|it = 'Tutti i dati modificati andranno persi. Chiudere il form?';
																						|pl = 'Wszystkie zmodyfikowane dane zostaną utracone. Chcesz zamknąć formularz?';
																						|tr = 'Tüm değişiklikler kaybolacak. Kapatılsın mı?'"), ButtonsList);
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
    
    UserAnswer = QuestionResult;
    
    If UserAnswer <> "NotClose" Then
        ClosingInProgress = True;
		Modified = False;
		Close();
    EndIf;

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	CurrentRow = Items.List.CurrentData;
	
	If Field = Items.ListCharacteristic Then
		
		If ValueIsFilled(CurrentRow.Products) And CurrentRow.EntryType <> 0 Then
			OpeningParameters = New Structure;
			OpeningParameters.Insert("Products",                   CurrentRow.Products);
			OpeningParameters.Insert("ListOfExceptionCharacteristics", CurrentRow.ExceptionCharacteristics);
			
			OpenForm("InformationRegister.SetUpSupplyControl.Form.SelectItemVariants", 
				OpeningParameters,
				ThisForm,
				UUID);
		EndIf;
		
	EndIf;
EndProcedure

&AtClient
Procedure ListProductsOnChange(Item)

	CurrentRow = Items.List.CurrentData;
	
	UpdateList(Items.List.CurrentRow);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Save(Command)
	ClearMessages();
	If WriteControlSettingsToRegister() Then
		Notify("RecordingSoftwareControlSettings", Warehouse);
		ClosingInProgress = True;
		Close();
	EndIf;
EndProcedure

&AtClient
Procedure Write(Command)
	ClearMessages();
	If WriteControlSettingsToRegister() Then
		Notify("RecordingSoftwareControlSettings", Warehouse);
	EndIf;
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure UpdateList(CurrentRow = Undefined)

	Query = New Query();
	Query.Text =
		"SELECT ALLOWED
		|	T.Products AS Products,
		|	COUNT(*) AS Count
		|INTO TTExceptionCharacteristics
		|FROM
		|	InformationRegister.SetUpSupplyControl AS T
		|WHERE
		|	T.Warehouse = &Warehouse
		|	AND T.AvailableStockControl <> &AvailableStockControl
		|	AND T.Characteristic <> VALUE(Catalog.ItemsCharacteristics.EmptyRef)
		|	AND T.Products = &Products
		|
		|GROUP BY
		|	T.Products
		|
		|INDEX BY
		|	Products
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	T.Products AS Products,
		|	T.Characteristic AS CharacteristicException,
		|	0 AS EntryType,
		|	0 AS NumberOfExceptions
		|FROM
		|	InformationRegister.SetUpSupplyControl AS T
		|WHERE
		|	T.Warehouse = &Warehouse
		|	AND T.AvailableStockControl <> &AvailableStockControl
		|	AND T.Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.DontUse)
		|	AND T.Products = &Products
		|
		|UNION ALL
		|
		|SELECT
		|	T.Products,
		|	T.Characteristic,
		|	1,
		|	ISNULL(Exceptions.Count, 0)
		|FROM
		|	InformationRegister.SetUpSupplyControl AS T
		|		LEFT JOIN TTExceptionCharacteristics AS Exceptions
		|		ON T.Products = Exceptions.Products
		|WHERE
		|	T.Warehouse = &Warehouse
		|	AND T.AvailableStockControl <> &AvailableStockControl
		|	AND T.Products.UseVariants <> VALUE(Enum.ItemVariantsUsageOptions.DontUse)
		|	AND T.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
		|	AND T.Products = &Products
		|
		|UNION ALL
		|
		|SELECT
		|	T.Products,
		|	T.Characteristic,
		|	2,
		|	ISNULL(Exceptions.Count, 0)
		|FROM
		|	InformationRegister.SetUpSupplyControl AS T
		|		LEFT JOIN TTExceptionCharacteristics AS Exceptions
		|		ON T.Products = Exceptions.Products
		|WHERE
		|	T.Warehouse = &Warehouse
		|	AND T.AvailableStockControl <> &AvailableStockControl
		|	AND T.Products.UseVariants <> VALUE(Enum.ItemVariantsUsageOptions.DontUse)
		|	AND T.Characteristic <> VALUE(Catalog.ItemsCharacteristics.EmptyRef)
		|	AND T.Products = &Products
		|TOTALS
		|	MAX(EntryType),
		|	MAX(NumberOfExceptions)
		|BY
		|	Products";

	Query.SetParameter("Warehouse", Parameters.Warehouse);
	Query.SetParameter("AvailableStockControl", Parameters.AvailableStockControl);
	
	If CurrentRow = Undefined Then
		Query.Text = StrReplace(Query.Text, "AND T.Products = &Products", "");
	Else
		ListLine = List.FindByID(CurrentRow);
		Query.SetParameter("Products", ListLine.Products);
	EndIf;

	QueryResult = Query.Execute();
	Selection = QueryResult.Select(QueryResultIteration.ByGroups);
	
	If CurrentRow <> Undefined Then

		If Selection.Next() Then

			FillPropertyValues(ListLine, Selection);

			If ListLine.EntryType = 2 Then

				SelectionOfCharacteristics = Selection.Select();
				While SelectionOfCharacteristics.Next() Do

					ListLine.ExceptionCharacteristics.Add(SelectionOfCharacteristics.CharacteristicException);

				EndDo;

			EndIf;

			FormCaption(ListLine);

		Else

			ItemVariantsAreUsed = ItemVariantsAreUsed(ListLine.Products);
			ListLine.EntryType = Number(ItemVariantsAreUsed);
			ListLine.ExceptionCharacteristics.Clear();
			ListLine.NumberOfExceptions = 0;
			FormCaption(ListLine);

		EndIf;

	Else

		While Selection.Next() Do
			
			ListLine = List.Add();
			FillPropertyValues(ListLine, Selection);
			
			If ListLine.EntryType = 2 Then
				
				SelectionOfCharacteristics = Selection.Select();
				While SelectionOfCharacteristics.Next() Do
					
					ListLine.ExceptionCharacteristics.Add(SelectionOfCharacteristics.CharacteristicException);
					
				EndDo;
				
			EndIf;
			
			FormCaption(ListLine);
		EndDo;

	EndIf;

EndProcedure

&AtClientAtServerNoContext
Procedure FormCaption(String)

	If String.EntryType = 0 Then
		String.Characteristic = NStr("vi = '<chưa sử dụng>';
									|ru = '<не используются>';
									|en = '<not used>'; fa = '<استفاده نمی‌شود>';
									|it = '<non vengono utilizzati>';
									|pl = '<nie jest używane>';
									|tr = '<kullanılmamaktadır>'");
	ElsIf String.EntryType = 1 And String.NumberOfExceptions = 0 Then
		String.Characteristic = NStr("vi = 'đối với tất cả đặc tính';
									|ru = 'для всех характеристик';
									|en = 'for all variants'; fa = 'برای همه گونه‌ها';
									|it = 'per tutte le caratteristiche';
									|pl = 'dla wszystkich charakterystyk';
									|tr = 'tüm varyantlar için'");
	ElsIf String.EntryType = 2 And String.NumberOfExceptions = 1 Then
		String.Characteristic =
			StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'đối với %1 đặc tính';
																			|ru = 'для %1 характеристики';
																			|en = 'for the %1 variant'; fa = 'for the %1 variant';
																			|it = 'per %1 la caratteristica';
																			|pl = 'dla %1 charakterystyki';
																			|tr = '%1 varyantı için'"), String.NumberOfExceptions);
	Else
		String.Characteristic =
			StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'đối với %1 đặc tính';
																			|ru = 'для %1 характеристик';
																			|en = 'for %1 variants'; fa = 'for %1 variants';
																			|it = 'per %1 caratteristiche';
																			|pl = 'dla %1 charakterystyk';
																			|tr = '%1 özellik için'"), String.NumberOfExceptions);
	EndIf;

EndProcedure

&AtServerNoContext
Function ItemVariantsAreUsed(Products)
	Return Catalogs.Products.ItemVariantsAreUsed(Products);
EndFunction

&AtServer
Function WriteControlSettingsToRegister()
	
	DoublesAreMissing = CheckForDuplicateProducts();
	
	If DoublesAreMissing Then
		RecordSet = InformationRegisters.SetUpSupplyControl.CreateRecordSet();
		RecordSet.Filter.Warehouse.Set(Warehouse);
		
		FillingStructure = New Structure("Warehouse, AvailableStockControl", Warehouse, Not AvailableStockControl);
		
		For Each String In List Do
			FillingStructure.Insert("Products", String.Products);
			If Not ValueIsFilled(String.Products) Then
				Continue;
			EndIf; 
			ThereAreCharacteristics = False;
			For Each Characteristic In String.ExceptionCharacteristics Do
				RecordRow = RecordSet.Add();
				FillPropertyValues(RecordRow, FillingStructure);
				RecordRow.Characteristic = Characteristic.Value;
				ThereAreCharacteristics          = True;
			EndDo;
			If Not ThereAreCharacteristics Then
				RecordRow = RecordSet.Add();
				FillPropertyValues(RecordRow, FillingStructure);
			EndIf;
		EndDo;
		
		RecordRow = RecordSet.Add();
		RecordRow.Warehouse                          = Warehouse;
		RecordRow.AvailableStockControl = AvailableStockControl;
		RecordSet.Write();
		
	EndIf;
	
	Return DoublesAreMissing
	
EndFunction

&AtServer
Function CheckForDuplicateProducts()
	
	Query = New Query(
		"SELECT
		|	GoodsTable.Products   AS Products
		|INTO
		|	DocumentGoods
		|FROM
		|	&GoodsTable AS GoodsTable;
		|
		|SELECT
		|	Goods.Products             AS Products
		|FROM
		|	DocumentGoods AS Goods
		|GROUP BY
		|	Goods.Products
		|HAVING 
		|	COUNT (*) > 1");
	
	Query.SetParameter("GoodsTable", List.Unload(,"Products"));
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		
		ErrorText = NStr("vi = 'Mặt hàng ""%Products%"" bị trùng.';
						|ru = 'Номенклатура ""%Products%"" повторяется.';
						|en = 'Items ""%Products%"" are repeated.'; fa = 'Items ""%Products%"" are repeated.';
						|it = 'Articoli ""%Products%"" si ripetono.';
						|pl = 'Nomenklatura ""%Products%"" jest powtarzana.';
						|tr = '""%Products%"" öğe tekrarlanmaktadır.'");
		ErrorText = StrReplace(ErrorText, "%Products%", Selection.Products);
		
		CommonClientServer.MessageToUser(ErrorText, ,"List");
		
	EndDo;
	
	Return QueryResult.IsEmpty();
	
EndFunction

&AtServer
Procedure SetConditionalAppearance()
	ConditionalAppearance.Items.Clear();
	
	//
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListCharacteristic.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.EntryType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);

	//
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListCharacteristic.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.EntryType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);

EndProcedure

#EndRegion

#Region Initialize
	
	ClosingInProgress = False;
	
#EndRegion
