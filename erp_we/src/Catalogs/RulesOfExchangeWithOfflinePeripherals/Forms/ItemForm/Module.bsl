
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	// Handler of the subsystem prohibiting editing of object details
	ObjectAttributesLock.LockAttributes(ThisForm);
	
	If Not ValueIsFilled(Object.PeripheralType) Then
		Object.PeripheralType = DefaultTypeOfConnectedEquipment();
	EndIf;

	Customize();
	
	Items.Pages.CurrentPage = Items.SelectionPageChanged;
	
	MaximumGoodsQuantity = Object.MaximumGoodsQuantity + 99999;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	ArrayOfEquipmentTypes = New Array;
	ArrayOfEquipmentTypes.Add(Enums.PeripheralTypes.LabelPrintingScales);
	
	Items.PeripheralType.ChoiceList.LoadValues(ArrayOfEquipmentTypes);
	
	UpdateSettingsComposerSelections();
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	GoodsQuantity = Goods.Count();
	If GoodsQuantity > 0 Then
		If Goods[GoodsQuantity-1].Code - 99999 > CurrentObject.MaximumGoodsQuantity And CurrentObject.MaximumGoodsQuantity <> 0 Then
			CommonClientServer.MessageToUser(
			NStr("vi = 'Trong phần bảng ""Hàng hóa"" có quá nhiều hàng hóa. Hãy thay đổi số lượng tối đa hàng hóa hoặc giảm số lượng hàng cần giao bằng bộ lọc.';
				|ru = 'В табличной части ""Товары"" слишком много товаров. Измените максимальное количество товаров или уменьшите количество товаров к выгрузке при помощи отбора.';
				|en = 'The ""Goods"" table contains too many goods. Change the maximum quantity of goods or reduce quantity of goods to be exported using the filter.'; fa = 'The ""Goods"" table contains too many goods. Change the maximum quantity of goods or reduce quantity of goods to be exported using the filter.';
				|it = 'Ci sono troppi prodotti nella tabella ""Prodotti"". Modificate la quantità massima di merci o riducete la quantità di merci da importare utilizzando la selezione.';
				|pl = 'W sekcji tabelarycznej ""Товары"" jest za dużo towarów. Zmień maksymalną ilość towarów lub zmniejsz ilość towarów do wysyłki za pomocą wyboru.';
				|tr = '""Ürünler"" tablo bölümünde çok fazla ürün mevcut. Bir filtre kullanarak maksimum ürün sayısını değiştir veya boşaltılacak ürün sayısını azalt.'"),,"Goods",,Cancel);
			Return;
		EndIf;
	EndIf;
	
	If GoodsDataIsRead Then
		UpdateListOfProductsOnServer();
	EndIf;
	
	CurrentObject.DataCompositionSettings = New ValueStorage(SettingsComposer.GetSettings());

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// Handler of the subsystem prohibiting editing of object details
	ObjectAttributesLock.LockAttributes(ThisForm);

	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If GoodsDataIsRead Then
		
		If Goods.Count() > 0 Then
			ApplyChangesOnServer(CurrentObject);
		Else
			OfflinePeripheralsServerCall.UpdateProductCodes(CurrentObject.Ref);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_RulesOfExchangeWithOfflinePeripherals", WriteParameters, Object.Ref);

	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// Subsystem prohibiting editing of key details of objects	
	ObjectAttributesLock.LockAttributes(ThisForm);

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SettingsComposerSettingsFilterOnChange(Item)
	Items.Pages.CurrentPage = Items.SelectionPageChanged;
	FilterChanged = True;
	If Item.CurrentData <> Undefined Then
		If Item.CurrentData.LeftValue = New DataCompositionField("Warehouse") Then
			UpdateSettingsComposerSelections();
		EndIf;	
	EndIf;	
EndProcedure

&AtClient
Procedure PeripheralTypeOnChange(Item)
	
	Customize();
	Items.Pages.CurrentPage = Items.SelectionPageChanged;
	
EndProcedure

&AtClient
Procedure MaximumGoodsQuantityOnChange(Item)
	
	MaximumGoodsQuantity = Object.MaximumGoodsQuantity + 99999;
	
	// The maximum code has been changed - control is required.
	Status(NStr("vi = 'Đang cập nhật danh sách hàng hóa...';
				|ru = 'Выполняется обновление списка товаров...';
				|en = 'Updating Item list...'; fa = 'Updating Item list...';
				|it = 'Aggiornamento della lista delle merci in corso...';
				|pl = 'Trwa aktualizacja listy towarów...';
				|tr = 'Mal listesi güncelleniyor...'"));
	UpdateListOfProductsOnServer();
	Items.Pages.CurrentPage = Items.ProductListPage;
	
EndProcedure

&AtClient
Procedure PeripheralTypeClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	OldCode = Items.Goods.CurrentData.Code;
	
EndProcedure

&AtClient
Procedure GoodsBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData.Code = OldCode Then
		Return;
	EndIf;
	
	If Not CancelEdit Then
		
		FoundRow = FindProductLineWithCode(CurrentData.Code, CurrentData.GetID());
		If FoundRow <> Undefined Then
			
			FoundRow = Goods.FindByID(FoundRow);
			
			ErrorDescription = NStr("vi = 'Mã này đã được dùng cho mặt hàng %Products%';
									|ru = 'Такой код уже назначен для номенклатуры %Products%';
									|en = 'Such code is already assigned for items %Products%'; fa = 'Such code is already assigned for items %Products%';
									|it = 'Questo codice è già impostato per l''articolo %Products%';
									|pl = 'Ten kod został już przypisany do towarów. %Products%';
									|tr = '%Products% öğesi için böyle kod zaten atandı'");
			ErrorDescription = StrReplace(ErrorDescription, "%Products%", """" + FoundRow.Products + """"
			+ ?(ValueIsFilled(FoundRow.Characteristic), " " + NStr("vi = 'với đặc tính';
																	|ru = 'с характеристикой';
																	|en = 'with variant'; fa = 'with variant';
																	|it = 'con la caratteristica';
																	|pl = 'z charakterystyką';
																	|tr = 'özellik ile'") + " """ + FoundRow.Characteristic + """", "")
			+ ?(ValueIsFilled(FoundRow.Package), " " + NStr("vi = 'trong bộ đóng gói';
															|ru = 'в упаковке';
															|en = 'in packaging unit'; fa = 'in packaging unit';
															|it = 'nella confezione';
															|pl = 'w opakowaniu';
															|tr = 'paketleme ünitesinde'") + " """ + FoundRow.Package + """", ""))+NStr("vi = '. Trao đổi chỗ?';
																																	|ru = '. Обменять их местами?';
																																	|en = '. Counterchange them?'; fa = '. Counterchange them?';
																																	|it = '. Cambiarli di posto?';
																																	|pl = '. Zamienić je miejscami?';
																																	|tr = '. Yerleri ile değiştir?'");
			
			ShowQueryBox(New CallbackDescription("GoodsBeforeEditEndCompletion", ThisObject, New Structure("FoundRow, Cancel, CurrentData", FoundRow, Cancel, CurrentData)), ErrorDescription, QuestionDialogMode.YesNo);
			Cancel = True;
			Return;
			
		Else
			
			CurrentData.New = True;
			CurrentData.ChangedByUser = True;
			ProcessChangesToProductCodeOnServer(CurrentData.Code);
			
		EndIf;
		
	Else
		CurrentData.Code = OldCode;
	EndIf;
	
	Modified = True;
EndProcedure

&AtClient
Procedure GoodsBeforeEditEndCompletion(QuestionResult, AdditionalParameters) Export
	
	FoundRow = AdditionalParameters.FoundRow;
	CurrentData = AdditionalParameters.CurrentData;
	
	If Not ValueIsFilled(FoundRow.Products) Or QuestionResult = DialogReturnCode.Yes Then
		
		CurrentData.ChangedByUser = True;
		FoundRow.ChangedByUser = True;
		
		TempStructure = StringStructure(FoundRow);
		FillPropertyValues(FoundRow, CurrentData,,"Code, ChangedByUser");
		CurrentData.Code = OldCode;
		FillPropertyValues(CurrentData, TempStructure);
		
		Items.Goods.CurrentRow = FoundRow.GetID();
		
		Modified = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
	If Not GoodsCodeEditingIsAvailable Then
		Return;
	EndIf;
	
	For Each SelectedRow In Items.Goods.SelectedRows Do
		CurrentData = Goods.FindByID(SelectedRow);
		If ValueIsFilled(CurrentData.Products) And CurrentData.Used Then
			
			ShowQueryBox(
				New CallbackDescription("GoodsBeforeDeleteRowCompletion", ThisObject),
				NStr("vi = 'Mặt hàng đã xóa bỏ tương ứng với bộ lọc đã chọn sau khi xóa bỏ chương trình sẽ ấn định lại mã hàng hóa. Tiếp tục?';
					|ru = 'Удаляемой номенклатуре, соответствующей заданному отбору после удаления будет заново назначены коды товаров. Продолжить?';
					|en = 'After deletion goods codes will be reassigned to the deleted products, which satisfy the specified filter. Continue?'; fa = 'After deletion goods codes will be reassigned to the deleted products, which satisfy the specified filter. Continue?';
					|it = 'All''articolo da cancellare, corrispondente alla selezione corrente, dopo la cancellazione verranno nuovamente assegnati i codici delle merci. Continuare?';
					|pl = 'Do usuwanych towarów, odpowiadających określonemu wyborowi zostaną ponowie przydzielone kody towarowe. Kontynuować?';
					|tr = 'Belirtilen seçime karşılık gelen silinen öğeye, silme işleminden sonra yeniden ürün kodları atanacaktır. Devam et?'"), 
				QuestionDialogMode.YesNo);
			Return;
			
		EndIf;
	EndDo;
	
	GoodsBeforeDeleteRowCompletion(DialogReturnCode.Yes, Undefined);
	
EndProcedure

&AtClient
Procedure GoodsBeforeDeleteRowCompletion(Result, AdditionalParameters) Export 
	
	If Result <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	// User data modification
	For Each SelectedRow In Items.Goods.SelectedRows Do
		
		CurrentData = Goods.FindByID(SelectedRow);
		
		If Not ValueIsFilled(CurrentData.Products) Then
			// The data in the row has already been cleared
			Continue;
		EndIf;
		
		CurrentData.Products   = Undefined;
		CurrentData.Characteristic = Undefined;
		CurrentData.Package       = Undefined;
		CurrentData.Used   = Undefined;
		CurrentData.Description   = Undefined;
		CurrentData.SoldByWeight        = Undefined;
		CurrentData.Barcode       = Undefined;
		CurrentData.Price           = Undefined;
		
		CurrentData.ChangedByUser = True;
		
	EndDo;
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Not (Field = Items.GoodsCode
		Or Field = Items.GoodsCodeInteractively) Then
	
		RowSelected = Goods.FindByID(RowSelected);
		If RowSelected <> Undefined Then
			ShowValue(Undefined, RowSelected.Products);
		EndIf;
	
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	Cancel = True;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure UpdateTheProductList(Command)
	
	Status(NStr("vi = 'Đang cập nhật danh sách hàng hóa...';
				|ru = 'Выполняется обновление списка товаров...';
				|en = 'Updating Item list...'; fa = 'Updating Item list...';
				|it = 'Aggiornamento della lista delle merci in corso...';
				|pl = 'Trwa aktualizacja listy towarów...';
				|tr = 'Mal listesi güncelleniyor...'"));
	UpdateListOfProductsOnServerReopening();
	
EndProcedure

&AtClient
Procedure ShowAListOfProducts(Command)
	
	Status(NStr("vi = 'Đang cập nhật danh sách hàng hóa...';
				|ru = 'Выполняется обновление списка товаров...';
				|en = 'Updating Item list...'; fa = 'Updating Item list...';
				|it = 'Aggiornamento della lista delle merci in corso...';
				|pl = 'Trwa aktualizacja listy towarów...';
				|tr = 'Mal listesi güncelleniyor...'"));
	UpdateListOfProductsOnServer();
	Items.Pages.CurrentPage = Items.ProductListPage;
	
EndProcedure

&AtClient
Procedure MoveUp(Command)
	
	// Changing data
	For Each SelectedRow In Items.Goods.SelectedRows Do
		
		CurrentData = Goods.FindByID(SelectedRow);
		CurrentRowIndex = Goods.IndexOf(CurrentData);
		If CurrentRowIndex > 0 Then
			
			AssignmentRow = Goods[CurrentRowIndex-1];
			
			AssignmentRow.ChangedByUser = True;
			CurrentData.ChangedByUser = True;
			
			Code = AssignmentRow.Code;
			AssignmentRow.Code = CurrentData.Code;
			CurrentData.Code = Code;
			
			Goods.Move(CurrentRowIndex,-1);
			
		Else
			Break;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure MoveDown(Command)
	
	// User data modification
	Qty = Items.Goods.SelectedRows.Count()-1;
	For LineNumber = 0 To Qty Do
		
		CurrentData = Goods.FindByID(Items.Goods.SelectedRows[Qty-LineNumber]);
		
		CurrentRowIndex = Goods.IndexOf(CurrentData);
		If CurrentRowIndex < Goods.Count()-1 Then
			
			AssignmentRow = Goods[CurrentRowIndex+1];
			
			AssignmentRow.ChangedByUser = True;
			CurrentData.ChangedByUser = True;
			
			Code = AssignmentRow.Code;
			AssignmentRow.Code = CurrentData.Code;
			CurrentData.Code = Code;
			
			Goods.Move(CurrentRowIndex,1);
			
		Else
			Break;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure RestoreDefaultFilterSettings(Command)
	LoadDefaultSelectionSettings();
EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	TMCommonUseClient.AllowObjectAttributeEdit(ThisForm);
	
EndProcedure

&AtClient
Procedure DeleteTheSummaryItemCodesInTheEndOfTheList(Command)
	
	If Goods.Count() > 0 Then
		TSRow = Goods[Goods.Count() - 1];
		If Not ValueIsFilled(TSRow.Products) Then
			DeleteFreeProductCodesOnServer();
		Else
			ShowMessageBox(Undefined, NStr("vi = 'Không có dữ liệu để xóa';
											|ru = 'Нет данных для удаления';
											|en = 'There is no data for deletion'; fa = 'There is no data for deletion';
											|it = 'Non ci sono dati da cancellare';
											|pl = 'Brak danych do usunięcia';
											|tr = 'Silinecek veri yok'"));
		EndIf;
	Else
		ShowMessageBox(Undefined, NStr("vi = 'Không có dữ liệu để xóa';
										|ru = 'Нет данных для удаления';
										|en = 'There is no data for deletion'; fa = 'There is no data for deletion';
										|it = 'Non ci sono dati da cancellare';
										|pl = 'Brak danych do usunięcia';
										|tr = 'Silinecek veri yok'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsBarcode.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Goods.Barcode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Goods.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Goods.Used");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PeripheralType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.PeripheralTypes.LabelPrintingScales;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<sẽ khởi tạo mã vạch khi kết xuất>';
													|ru = '<штрихкод будет сгенерирован при выгрузке>';
													|en = '<barcode will be generated during exporting>'; fa = '<barcode will be generated during exporting>';
													|it = '<il codice a barre verrà generato durante l''importazione>';
													|pl = '<kod kreskowy zostanie wygenerowany po wyeksportowaniu>';
													|tr = '<barkod yükleme sırasında oluşturulacaktır>'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPrice.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Goods.Price");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Goods.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Goods.Used");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ErrorNoteText);
	Item.Appearance.SetParameterValue("HorizontalAlign", HorizontalAlign.Left);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Chưa đặt đơn giá>';
													|ru = '<Не задана цена>';
													|en = '<Price not defined>'; fa = '<Price not defined>';
													|it = '<Prezzo non impostato>';
													|pl = '<Cena nie została ustalona>';
													|tr = '<Fiyat ayarlanmadı>'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDescription.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Goods.Description");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Goods.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Goods.Used");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ErrorNoteText);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Chưa đặt tên gọi>';
													|ru = '<Не задано наименование>';
													|en = '<Description not defined>'; fa = '<Description not defined>';
													|it = '<Nome non impostato>';
													|pl = '<Nazwa nie została ustalona>';
													|tr = '<Tanım ayarlanmadı>'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCode.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCodeInteractively.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Goods.Code");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = New DataCompositionField("MaximumGoodsQuantity");

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaximumGoodsQuantity");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ErrorNoteText);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Goods.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Goods.Used");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);

EndProcedure

#Region Other

&AtServer
Function FreeCodes()
	
	FreeCodes = New Array;
	GoodsQuantity = Goods.Count();
	If GoodsQuantity > 0 Then
		
		For Each TSRow In Goods.FindRows(New Structure("Products", Catalogs.Products.EmptyRef())) Do
			FreeCodes.Add(TSRow.Code);
		EndDo;
		If ValueIsFilled(Goods[GoodsQuantity-1].Products) Then
			FreeCodes.Add(Goods[GoodsQuantity-1].Code + 1);
		EndIf;
		
	EndIf;
	
	Return FreeCodes;
	
EndFunction

&AtServer
Procedure LoadDefaultSelectionSettings()
	
	If OfflinePeripheralsServerCallLocalization.ThisIsTypeOfOfflineEquipmentCashRegister(Object.PeripheralType) Then
		DataCompositionSchema = Catalogs.RulesOfExchangeWithOfflinePeripherals.GetTemplate("CRProductCodesUpdate");
	ElsIf Object.PeripheralType = Enums.PeripheralTypes.LabelPrintingScales Then
		DataCompositionSchema = Catalogs.RulesOfExchangeWithOfflinePeripherals.GetTemplate("UpdateOfPLUItemCodes");
	Else
		Raise NStr("vi = 'Sai kiểu thiết bị bán hàng';
					|ru = 'Некорректный тип подключаемого оборудования';
					|en = 'Invalid peripherals type'; fa = 'Invalid peripherals type';
					|it = 'Tipo incorretto dell''apparecchiatura collegata';
					|pl = 'Nieprawidłowy typ urządzenia peryferyjnego';
					|tr = 'Bağlanan ekipmanın türü yanlış'");
	EndIf;
	
	PriceManagementSystemServerCall.GetPricingScheme(DataCompositionSchema);
	
	SettingsComposer.Initialize(
		New DataCompositionAvailableSettingsSource(PutToTempStorage(DataCompositionSchema, UUID)));
	
	SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
	
	SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
	
EndProcedure

&AtServer
Procedure Customize()
	
	If OfflinePeripheralsServerCallLocalization.ThisIsTypeOfOfflineEquipmentCashRegister(Object.PeripheralType) Then
		DataCompositionSchema = Catalogs.RulesOfExchangeWithOfflinePeripherals.GetTemplate("CRProductCodesUpdate");
	ElsIf Object.PeripheralType = Enums.PeripheralTypes.LabelPrintingScales Then
		DataCompositionSchema = Catalogs.RulesOfExchangeWithOfflinePeripherals.GetTemplate("UpdateOfPLUItemCodes");
	Else
		Raise NStr("vi = 'Sai kiểu thiết bị kết nối';
					|ru = 'Некорректный тип подключаемого оборудования';
					|en = 'Invalid peripherals type'; fa = 'Invalid peripherals type';
					|it = 'Tipo incorretto dell''apparecchiatura collegata';
					|pl = 'Nieprawidłowy typ urządzenia peryferyjnego';
					|tr = 'Bağlanan ekipmanın türü yanlış'");
	EndIf;
	
	PriceManagementSystemServerCall.GetPricingScheme(DataCompositionSchema);
	
	SettingsComposer.Initialize(
		New DataCompositionAvailableSettingsSource(PutToTempStorage(DataCompositionSchema, UUID)));
	
	LinkToReadSettings = Object.Ref;
	If Not ValueIsFilled(LinkToReadSettings) And Parameters <> Undefined And Parameters.Property("CopyingValue") And ValueIsFilled(Parameters.CopyingValue) Then
		LinkToReadSettings = Parameters.CopyingValue;
	EndIf;
	
	If ValueIsFilled(LinkToReadSettings) Then
		
		Query = New Query(
		"SELECT
		|	RulesOfExchangeWithOfflinePeripherals.DataCompositionSettings AS DataCompositionSettings
		|FROM
		|	Catalog.RulesOfExchangeWithOfflinePeripherals AS RulesOfExchangeWithOfflinePeripherals
		|WHERE
		|	RulesOfExchangeWithOfflinePeripherals.Ref = &ExchangeRule");
		
		Query.SetParameter("ExchangeRule", LinkToReadSettings);
		
		Result = Query.Execute();
		Selection = Result.Select();
		
		If Selection.Next() Then
			SelectingDataLayoutSettings = Selection.DataCompositionSettings; // ValueStorage
			DataCompositionSettings = SelectingDataLayoutSettings.Get();
			If ValueIsFilled(DataCompositionSettings) Then
				SettingsComposer.LoadSettings(DataCompositionSettings);
			Else
				SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
			EndIf;
		EndIf;
		
	Else
		SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
	EndIf;
	
	SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
	
	Items.UnitOfMeasureForWeight.Visible = Object.PeripheralType = Enums.PeripheralTypes.LabelPrintingScales;
	
	GoodsCodeEditingIsAvailable = Users.IsFullUser(,, False)
	 Or Object.PeripheralType = Enums.PeripheralTypes.LabelPrintingScales;
	
	Items.GoodsDelete.Enabled                         = GoodsCodeEditingIsAvailable;
	Items.GoodsMoveDown.Enabled                 = GoodsCodeEditingIsAvailable;
	Items.GoodsMoveUp.Enabled                = GoodsCodeEditingIsAvailable;
	Items.GoodsContextMenuDelete.Enabled          = GoodsCodeEditingIsAvailable;
	Items.GoodsContextMenuMoveUp.Enabled = GoodsCodeEditingIsAvailable;
	Items.GoodsContextMenuMoveDown.Enabled  = GoodsCodeEditingIsAvailable;
	Items.GoodsCode.ReadOnly                          = Not GoodsCodeEditingIsAvailable;
	Items.GoodsCodeInteractively.ReadOnly              = Not GoodsCodeEditingIsAvailable;
	
	Items.GoodsDeleteTheSummaryItemCodesInTheEndOfTheList.Visible = Users.IsFullUser(,, False);
	
EndProcedure

&AtServer
Function AddressSettingsComposerInTheTemporaryStorage()
	
	AddressSettingsComposerInTheTemporaryStorage = PutToTempStorage(SettingsComposer.GetSettings());
	
	Return AddressSettingsComposerInTheTemporaryStorage;
	
EndFunction

&AtServer
Procedure WriteCodeInTable(Table, Data, Code, Used)
	
	SpecificationRow = Table.Find(Code, "Code");
	If SpecificationRow = Undefined Then
		SpecificationRow = Table.Add();
		SpecificationRow.New = True;
	EndIf;
	
	SpecificationRow.ChangedAutomatically = True;
	
	FillPropertyValues(SpecificationRow, Data);
	
	SpecificationRow.Code             = Code;
	SpecificationRow.Used    = Used;
	
EndProcedure

&AtServer
Function TableOfGoods(Goods, PriceKind)
	
	Query = New Query(
	"SELECT
	|	GoodsCodes.Code AS Code,
	|	GoodsCodes.New AS New,
	|	GoodsCodes.ChangedByUser AS ChangedByUser,
	|	GoodsCodes.ChangedAutomatically AS ChangedAutomatically,
	|	GoodsCodes.Used AS Used,
	|	GoodsCodes.Products AS Products,
	|	GoodsCodes.Characteristic AS Characteristic,
	|	GoodsCodes.Package AS Package
	|INTO ProductCodesSourceTable
	|FROM
	|	&ValueTable AS GoodsCodes
	|;
	|
	|SELECT
	|	GoodsCodes.Code AS Code,
	|	GoodsCodes.New AS New,
	|	GoodsCodes.ChangedByUser AS ChangedByUser,
	|	GoodsCodes.ChangedAutomatically AS ChangedAutomatically,
	|	GoodsCodes.Used AS Used,
	|	GoodsCodes.Products AS Products,
	|	GoodsCodes.Characteristic AS Characteristic,
	|	GoodsCodes.Package AS Package,
	|	(CASE
	|		WHEN GoodsCodes.Products.ProductKind.SettingsOfPriceKeyByPackage = VALUE(Enum.FilterOptionForPriceKey.DontUse)
	|			THEN VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|		ELSE GoodsCodes.Package
	|	END)AS PricingPackage,
	|	(CASE
	|		WHEN GoodsCodes.Products.ProductKind.SettingsOfPriceKeyByItemVariant = VALUE(Enum.FilterOptionForPriceKey.DontUse)
	|			THEN VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
	|		ELSE GoodsCodes.Characteristic.ItemsCharacteristicForPricing
	|	END) AS PricingVariant,
	|	VALUE(Catalog.ItemsBatchesForPricing.EmptyRef) AS PricingBatch	
	|INTO GoodsCodes
	|FROM
	|	ProductCodesSourceTable AS GoodsCodes
	|INDEX BY GoodsCodes.Products, GoodsCodes.Characteristic, GoodsCodes.Package
    |;
	|
	|SELECT DISTINCT
	|	GoodsCodes.New AS New,
	|	GoodsCodes.ChangedByUser AS ChangedByUser,
	|	GoodsCodes.ChangedAutomatically AS ChangedAutomatically,
	|	GoodsCodes.Used AS Used,
	|	GoodsCodes.Code AS Code,
	|	GoodsCodes.Products AS Products,
	|	ISNULL(GoodsCodes.Products.Description,"""") AS NomenclatureName,
	|	ISNULL(GoodsCodes.Products.DescriptionFull,"""") AS ProductFullName,
	|	GoodsCodes.Characteristic AS Characteristic,
	|	ISNULL(GoodsCodes.Characteristic.Description,"""") AS CharacteristicName,
	|	ISNULL(GoodsCodes.Characteristic.DescriptionFull,"""") AS CharacteristicFullName,
	|	GoodsCodes.Package AS Package,
	|	ISNULL(GoodsCodes.Package.Description, """") AS PackagingName_,
	|	ISNULL(ItemsBarcodes.Barcode, """") AS Barcode,
	|	(ISNULL(&QueryTextPackagingFactor1, 1)
	|		/ ISNULL(&QueryTextPackagingFactor2, 1)) *
	|	ISNULL(ItemPricesCrossSectionOfTheLatest.Price, 0) AS Price,
	|	CASE
	|		WHEN &RequestTextTypeOfMeasuredValueUnitOfMeasurement = VALUE(Enum.TypesOfMeasuredValues.Weight)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS SoldByWeight
	|FROM
	|	GoodsCodes AS GoodsCodes
	|		LEFT JOIN InformationRegister.ItemsBarcodes AS ItemsBarcodes
	|		ON GoodsCodes.Products = ItemsBarcodes.Products
	|			AND GoodsCodes.Characteristic = ItemsBarcodes.Characteristic
	|			AND GoodsCodes.Package = ItemsBarcodes.Package
	|			AND &LabelPrintingScales
	|		LEFT JOIN
	|			&ItemsPrices AS ItemPricesCrossSectionOfTheLatest
	|		ON 
	|			&ItemPriceConnectionCondition	
	|TOTALS
	|	MAX(Barcode)
	|BY
	|	Code");
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"GoodsCodes.Package",
			"GoodsCodes.Products"));
		
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ItemPricesCrossSectionOfTheLatest.Package",
			"ItemPricesCrossSectionOfTheLatest.Products"));
		
	Query.Text = StrReplace(Query.Text,
		"&RequestTextTypeOfMeasuredValueUnitOfMeasurement",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"MeasuredValueType",
			"GoodsCodes.Package",
			"GoodsCodes.Products"));
		
	Query.Text = StrReplace(Query.Text,
		"&ItemsPrices",
		PriceManagementSystemClientServer.QueryTextInformationRegisterItemsPrices("GoodsCodes",
			"&CurrentDate",
			New Structure("Parameter", "&PriceKind"),
			Undefined));
			
	Query.Text = StrReplace(Query.Text,
		"&ItemPriceConnectionCondition",
		PriceManagementSystemClientServer.RequestTextInformationRegisterItemPricesConnectionCondition(
		"GoodsCodes",
		"ItemPricesCrossSectionOfTheLatest",
		Undefined,
		Undefined));
		
	If Object.PeripheralType = Enums.PeripheralTypes.LabelPrintingScales Then
		Query.Text = StrReplace(Query.Text, "&LabelPrintingScales", "ItemsBarcodes.Barcode LIKE &BarcodeFormat ESCAPE ""\""");
		Query.SetParameter("BarcodeFormat", InformationRegisters.ItemsBarcodes.WeightBarcodeFormat(InformationRegisters.ItemsBarcodes.BarcodeNodePrefix()));
	Else
		Query.Text = StrReplace(Query.Text, "&LabelPrintingScales", "TRUE");
	EndIf;
	
	Query.SetParameter("PriceKind",         PriceKind);
	Query.SetParameter("CurrentDate",     EndOfDay(CurrentSessionDate()));
	Query.SetParameter("ValueTable", Goods);
	
	TableOfGoods = New ValueTable;
	TableOfGoods.Columns.Add("Used",          New TypeDescription("Boolean"));
	TableOfGoods.Columns.Add("Code",                   New TypeDescription("Number"));
	TableOfGoods.Columns.Add("CodeInteractively",       New TypeDescription("Number"));
	TableOfGoods.Columns.Add("Products",          New TypeDescription("CatalogRef.Products"));
	TableOfGoods.Columns.Add("Characteristic",        New TypeDescription("CatalogRef.ItemsCharacteristics"));
	TableOfGoods.Columns.Add("Package",              New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	TableOfGoods.Columns.Add("Description",          New TypeDescription("String"));
	TableOfGoods.Columns.Add("DescriptionFull",    New TypeDescription("String"));
	TableOfGoods.Columns.Add("Barcode",              New TypeDescription("String"));
	TableOfGoods.Columns.Add("Price",                  New TypeDescription("Number"));
	TableOfGoods.Columns.Add("SoldByWeight",               New TypeDescription("Boolean"));
	TableOfGoods.Columns.Add("New",                 New TypeDescription("Boolean"));
	TableOfGoods.Columns.Add("ChangedByUser", New TypeDescription("Boolean"));
	TableOfGoods.Columns.Add("ChangedAutomatically", New TypeDescription("Boolean"));
	
	MaximumCodeOfGoodsSoldByWeight = OfflinePeripheralsServerCall.MaximumCodeOfGoodsSoldByWeight();
	
	SelectionByCodes = Query.Execute().Select(QueryResultIteration.ByGroups);
	While SelectionByCodes.Next() Do
		
		NewRow = TableOfGoods.Add();
		
		Selection = SelectionByCodes.Select();
		While Selection.Next() Do
			
			If Not ValueIsFilled(NewRow.Code) Then
				NewRow.Used          = Selection.Used;
				NewRow.Code                   = Selection.Code;
				If Object.PeripheralType = Enums.PeripheralTypes.LabelPrintingScales Then
					NewRow.CodeInteractively   = Selection.Code - MaximumCodeOfGoodsSoldByWeight;
				Else
					NewRow.CodeInteractively   = Selection.Code;
				EndIf;
				NewRow.Products          = Selection.Products;
				NewRow.Characteristic        = Selection.Characteristic;
				NewRow.Package              = Selection.Package;
				NewRow.Description = ProductsClientServer.PresentationOfProductsForPrinting(
					Selection.NomenclatureName,
					Selection.CharacteristicName,
					Selection.PackagingName_,
					Selection.PackagingName_);
				NewRow.DescriptionFull = ProductsClientServer.PresentationOfProductsForPrinting(
					Selection.ProductFullName,
					Selection.CharacteristicFullName,
					Selection.PackagingName_);
				NewRow.Price                  = Selection.Price;
				NewRow.Barcode              = InformationRegisters.ItemsBarcodes.PrepareBarcode(TrimAll(Selection.Barcode));
				NewRow.SoldByWeight               = Selection.SoldByWeight;
				NewRow.New                 = Selection.New;
				NewRow.ChangedByUser = Selection.ChangedByUser;
				NewRow.ChangedAutomatically = Selection.ChangedAutomatically;
			Else
				NewRow.Barcode = NewRow.Barcode + ", " + TrimAll(Selection.Barcode);
			EndIf;
			
		EndDo;
		
	EndDo;
	
	TableOfGoods.Sort("Code");
	Return TableOfGoods;
	
EndFunction

&AtServer
Procedure DownloadCodesFromRegister(CurrentObject)
	
	TypesOfPrices = New Structure("RetailPriceType, SpecialPriceType", Catalogs.TypesOfPrices.EmptyRef(), Catalogs.TypesOfPrices.EmptyRef());
	CurrentObjectDetailsList = New Structure(
		"Warehouse, WarehouseRetailViewPrices, WarehouseIndividualPriceType",
		"Warehouse",
		"Warehouse.RetailPriceType",
		"Warehouse.SpecialPriceType");
	CurrentObjectDetails = Common.ObjectAttributesValues(CurrentObject, CurrentObjectDetailsList);
	If PriceManagementSystemServerCall.UsePriceManagementSystem25() Then
		ProductRangeSettings = InformationRegisters.HistoryOfStoreFormatChange.CurAssortmentSettings(CurrentObjectDetails.Warehouse);
		If ProductRangeSettings.RetailPricesFromStoreFormat Then
			ObjectAttributes = Common.ObjectAttributesValues(ProductRangeSettings.StoreFormat, "RetailPriceType, SpecialPriceType");
			TypesOfPrices.RetailPriceType = ObjectAttributes.RetailPriceType;
			TypesOfPrices.SpecialPriceType = ObjectAttributes.SpecialPriceType;
		Else
			TypesOfPrices.RetailPriceType = CurrentObjectDetails.WarehouseRetailViewPrices;
			TypesOfPrices.SpecialPriceType = CurrentObjectDetails.WarehouseIndividualPriceType;
		EndIf;
	Else
		TypesOfPrices.RetailPriceType = CurrentObjectDetails.WarehouseRetailViewPrices;
	EndIf;
	
	Table = OfflinePeripheralsServerCall.DataOfGoodsUnderExchangeRule(CurrentObject, TypesOfPrices.RetailPriceType, TypesOfPrices.SpecialPriceType);
	
	If Table <> Undefined Then
		Goods.Load(Table);
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateProductTable(GoodsCodes, ExchangeRule, PriceKind, SpecialPriceType, AddressOnSettings)
	
	If OfflinePeripheralsServerCallLocalization.ThisIsTypeOfOfflineEquipmentCashRegister(Object.PeripheralType) Then
		DataCompositionSchema = Catalogs.RulesOfExchangeWithOfflinePeripherals.GetTemplate("CRProductCodesUpdate");
	ElsIf Object.PeripheralType = Enums.PeripheralTypes.LabelPrintingScales Then
		DataCompositionSchema = Catalogs.RulesOfExchangeWithOfflinePeripherals.GetTemplate("UpdateOfPLUItemCodes");
	Else
		Raise NStr("vi = 'Sai kiểu thiết bị kết nối';
					|ru = 'Некорректный тип подключаемого оборудования';
					|en = 'Invalid peripherals type'; fa = 'Invalid peripherals type';
					|it = 'Tipo incorretto dell''apparecchiatura collegata';
					|pl = 'Nieprawidłowy typ urządzenia peryferyjnego';
					|tr = 'Bağlanan ekipmanın türü yanlış'");
	EndIf;
	
	PriceManagementSystemServerCall.GetPricingScheme(DataCompositionSchema);
	
	// Preparing a data layout layout builder, loading settings
	Composer = New DataCompositionSettingsComposer;
	Composer.Initialize(New DataCompositionAvailableSettingsSource(DataCompositionSchema));
	
	Composer.LoadSettings(GetFromTempStorage(AddressOnSettings));
	Composer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
	
	// Filling in the report structure and selected fields.
	Composer.Settings.Structure.Clear();
	
	DetailedRecordsGroup = Composer.Settings.Structure.Add(Type("DataCompositionGroup"));
	DetailedRecordsGroup.Use = True;
	
	Composer.Settings.Selection.Items.Clear();
	
	SelectedField               = DetailedRecordsGroup.Selection.Items.Add(Type("DataCompositionSelectedField"));
	SelectedField.Field          = New DataCompositionField("Products");
	SelectedField.Use = True;
	
	If GetFunctionalOption("UseItemVariants") Then
		SelectedField               = DetailedRecordsGroup.Selection.Items.Add(Type("DataCompositionSelectedField"));
		SelectedField.Field          = New DataCompositionField("Characteristic");
		SelectedField.Use = True;
	EndIf;
	
	If GetFunctionalOption("UseItemPackages") Then
		SelectedField               = DetailedRecordsGroup.Selection.Items.Add(Type("DataCompositionSelectedField"));
		SelectedField.Field          = New DataCompositionField("Package");
		SelectedField.Use = True;
	EndIf;
	
	SelectedField               = DetailedRecordsGroup.Selection.Items.Add(Type("DataCompositionSelectedField"));
	SelectedField.Field          = New DataCompositionField("MatchesFilter");
	SelectedField.Use = True;
	
	SelectedField               = DetailedRecordsGroup.Selection.Items.Add(Type("DataCompositionSelectedField"));
	SelectedField.Field          = New DataCompositionField("Code");
	SelectedField.Use = True;
	
	SelectedField               = DetailedRecordsGroup.Selection.Items.Add(Type("DataCompositionSelectedField"));
	SelectedField.Field          = New DataCompositionField("Used");
	SelectedField.Use = True;
	
	SelectedField               = DetailedRecordsGroup.Selection.Items.Add(Type("DataCompositionSelectedField"));
	SelectedField.Field          = New DataCompositionField("SoldByWeight");
	SelectedField.Use = True;
	
	SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(Composer);
	
	// Layout layout and query execution.
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, Composer.GetSettings(), , , Type("DataCompositionValueCollectionTemplateGenerator"));
	
	Parameter = CompositionTemplate.ParameterValues.Find("Date");
	If Parameter <> Undefined Then
		Parameter.Value = CurrentSessionDate();
	EndIf;
	Parameter = CompositionTemplate.ParameterValues.Find("PriceKind");
	If Parameter <> Undefined Then
		Parameter.Value = PriceKind;
	EndIf;
	Parameter = CompositionTemplate.ParameterValues.Find("SpecialPriceType");
	If Parameter <> Undefined Then
		Parameter.Value = SpecialPriceType;
	EndIf;	
	Parameter = CompositionTemplate.ParameterValues.Find("ExchangeRule");
	If Parameter <> Undefined Then
		Parameter.Value = ExchangeRule;
	EndIf;
	Parameter = CompositionTemplate.ParameterValues.Find("UnitOfMeasureForWeight");
	If Parameter <> Undefined Then
		Parameter.Value = Object.UnitOfMeasureForWeight;
	EndIf;
	Parameter = CompositionTemplate.ParameterValues.Find("BarcodeFormat");
	If Parameter <> Undefined Then
		Parameter.Value = InformationRegisters.ItemsBarcodes.WeightBarcodeFormat(InformationRegisters.ItemsBarcodes.BarcodeNodePrefix());
	EndIf;
	Parameter = CompositionTemplate.ParameterValues.Find("UseItemPackages");
	If Parameter <> Undefined Then
		Parameter.Value = GetFunctionalOption("UseItemPackages");
	EndIf;
	Parameter = CompositionTemplate.ParameterValues.Find("UseItemVariants");
	If Parameter <> Undefined Then
		Parameter.Value = GetFunctionalOption("UseItemVariants");
	EndIf;
	
	Query = New Query(
	"SELECT
	|	&ExchangeRule AS ExchangeRule,
	|	GoodsCodes.Code AS Code,
	|	GoodsCodes.Used AS Used,
	|	GoodsCodes.Products AS Products,
	|	GoodsCodes.Characteristic AS Characteristic,
	|	GoodsCodes.Package AS Package
	|INTO GoodsCodes
	|FROM
	|	&ValueTable AS GoodsCodes
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Package");
	Query.Text = Query.Text + ";" + StrReplace(CompositionTemplate.DataSets[0].Query, "InformationRegister.ItemsIDOfPeripheralsOffline", "GoodsCodes");
	
	// Filling in parameters from the selection fields of the processing form settings linker.
	For Each Parameter In CompositionTemplate.ParameterValues Do
		Query.Parameters.Insert(Parameter.Name, Parameter.Value);
	EndDo;
	
	TableProductCodes = GoodsCodes.Unload();
	TableProductCodes.Indexes.Add("Code");
	
	Query.SetParameter("ValueTable", TableProductCodes);
	
	If TableProductCodes.Count() > 0 Then
		Code = TableProductCodes[TableProductCodes.Count() - 1].Code + 1;
	Else
		Code = OfflinePeripheralsServerCall.MaximumCodeOfGoodsSoldByWeight() + 1;
	EndIf;
	
	FreeCodes = New ValueTable;
	FreeCodes.Columns.Add("Code", New TypeDescription("Number"));
	For Each TSRow In Goods.FindRows(New Structure("Products", Catalogs.Products.EmptyRef())) Do
		NewRow = FreeCodes.Add();
		NewRow.Code = TSRow.Code;
	EndDo;
	
	ZoomRatio1 = Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
						"SourceDataLastRequest.Package",
						"SourceDataLastRequest.Products");
	ZoomRatio2 = Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
						"SourceDataLastRequest.Products.UnitOfMeasure",
						"SourceDataLastRequest.Products");
	SubstitutionText = StrTemplate("ISNULL(%1, 1)/ISNULL(%2, 1)", ZoomRatio1, ZoomRatio2);
	
	Query.Text = StrReplace(Query.Text, "&TemplateForSubstitutingCalculatedCoefficient", SubstitutionText);
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		If Selection.MatchesFilter Then
			If Not ValueIsFilled(Selection.Code) Then
				
				If FreeCodes.Count() = 0 Then
					WriteCodeInTable(TableProductCodes, Selection, Code, True);
					Code = Code + 1;
				Else
					WriteCodeInTable(TableProductCodes, Selection, FreeCodes[0].Code, True);
					FreeCodes.Delete(0);
				EndIf;
				
			Else
				WriteCodeInTable(TableProductCodes, Selection, Selection.Code, True);
			EndIf;
		Else
			WriteCodeInTable(TableProductCodes, Selection, Selection.Code, False);
		EndIf;
	EndDo;
	
	GoodsCodes.Load(TableOfGoods(TableProductCodes, PriceKind));
	
EndProcedure

&AtServer
Procedure UpdateListOfProductsOnServerFirstOpening()
	
	OfflinePeripheralsServerCall.UpdateProductCodes(Object.Ref);
	DownloadCodesFromRegister(Object.Ref);
	
EndProcedure

&AtServer
Procedure UpdateListOfProductsOnServerReopening()
	
	FoundRows = Goods.FindRows(New Structure("New, ChangedByUser", True, False));
	For Each TSRow In FoundRows Do
		
		If Not ValueIsFilled(TSRow.Products) Then
			// The data in the row has already been cleared
			Continue;
		EndIf;
		
		TSRow.Products   = Undefined;
		TSRow.Characteristic = Undefined;
		TSRow.Package       = Undefined;
		TSRow.Used   = Undefined;
		TSRow.Description   = Undefined;
		TSRow.SoldByWeight        = Undefined;
		TSRow.Barcode       = Undefined;
		TSRow.Price           = Undefined;
		
	EndDo;
	
	// Deleting unrecorded free codes from the end of the table.
	LastRowIndex = Goods.Count() - 1;
	For LineNumber = -LastRowIndex To 0 Do
		TSRow = Goods[-LineNumber];
		If Not ValueIsFilled(TSRow.Products) And TSRow.New Then
			Goods.Delete(-LineNumber);
		Else
			Break;
		EndIf;
	EndDo;
	
	TypesOfPrices = New Structure("RetailPriceType, SpecialPriceType", Catalogs.TypesOfPrices.EmptyRef(), Catalogs.TypesOfPrices.EmptyRef());
	WarehouseDetails_ = Common.ObjectAttributesValues(
		Object.Warehouse, "RetailPriceType, SpecialPriceType");
	If PriceManagementSystemServerCall.UsePriceManagementSystem25() Then
		ProductRangeSettings = InformationRegisters.HistoryOfStoreFormatChange.CurAssortmentSettings(Object.Warehouse);
		If ProductRangeSettings.RetailPricesFromStoreFormat Then
			ObjectAttributes = Common.ObjectAttributesValues(ProductRangeSettings.StoreFormat, "RetailPriceType, SpecialPriceType");
			TypesOfPrices.RetailPriceType = ObjectAttributes.RetailPriceType;
			TypesOfPrices.SpecialPriceType = ObjectAttributes.SpecialPriceType;
		Else
			TypesOfPrices.RetailPriceType = WarehouseDetails_.RetailPriceType;
			TypesOfPrices.SpecialPriceType = WarehouseDetails_.SpecialPriceType;
		EndIf;
	Else
		TypesOfPrices.RetailPriceType = WarehouseDetails_.RetailPriceType;
	EndIf;
	
	UpdateProductTable(Goods, Object.Ref, TypesOfPrices.RetailPriceType, TypesOfPrices.SpecialPriceType, AddressSettingsComposerInTheTemporaryStorage());
	
	Modified = True;
	
EndProcedure

&AtServer
Procedure UpdateListOfProductsOnServer()
	
	UpdateSettingsComposerSelections();
	If Not GoodsDataIsRead Then
		// The first opening of the list of products
		UpdateListOfProductsOnServerFirstOpening();
		UpdateListOfProductsOnServerReopening();
		
		GoodsDataIsRead = True;
	Else
		UpdateListOfProductsOnServerReopening();
	EndIf;
	
	FilterChanged = False;
	
EndProcedure

&AtClient
Function StringStructure(String)
	
	TSRow = New Structure;
	TSRow.Insert("Used");
	TSRow.Insert("Products");
	TSRow.Insert("Characteristic");
	TSRow.Insert("Package");
	TSRow.Insert("Description");
	TSRow.Insert("Price");
	TSRow.Insert("Barcode");
	TSRow.Insert("SoldByWeight");
	
	FillPropertyValues(TSRow, String);
	
	Return TSRow;
	
EndFunction

&AtServer
Procedure ApplyChangesOnServer(CurrentObject)
	
	BeginTransaction();
	Try
		
		// Recording of product codes changed by the user
		FoundRows = Goods.FindRows(New Structure("ChangedByUser, New", True, False));
		For Each TSRow In FoundRows Do
			RecordManager = InformationRegisters.ItemsIDOfPeripheralsOffline.CreateRecordManager();
			FillPropertyValues(RecordManager, TSRow);
			RecordManager.ExchangeRule = CurrentObject.Ref;
			RecordManager.Write();
		EndDo;
		
		// Recording automatically added rows
		FoundRows = Goods.FindRows(New Structure("ChangedAutomatically, ChangedByUser, New", True, False, False));
		For Each TSRow In FoundRows Do
			RecordManager = InformationRegisters.ItemsIDOfPeripheralsOffline.CreateRecordManager();
			FillPropertyValues(RecordManager, TSRow);
			RecordManager.ExchangeRule = CurrentObject.Ref;
			RecordManager.Write();
		EndDo;
		
		// Recording new product codes
		FoundRows = Goods.FindRows(New Structure("New", True));
		For Each TSRow In FoundRows Do
			RecordManager = InformationRegisters.ItemsIDOfPeripheralsOffline.CreateRecordManager();
			FillPropertyValues(RecordManager, TSRow);
			RecordManager.ExchangeRule = CurrentObject.Ref;
			RecordManager.Write();
		EndDo;
		
		For Each TSRow In Goods Do
			TSRow.ChangedByUser = False;
			TSRow.ChangedAutomatically = False;
			TSRow.New                 = False;
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		WriteLogEvent(NStr("vi = 'Chỉnh sửa quy tắc trao đổi với MTT Offline';
							|ru = 'Редактирование правила обмена с ККМ Offline';
							|en = 'Edit rules of exchange with offline cash register'; fa = 'Edit rules of exchange with offline cash register';
							|it = 'Modifica della regola di scambio con i KKM (Macchinari di Registrazione e Controllo) Offline';
							|pl = 'Edycja reguły wymiany z kasami offline';
							|tr = 'Çevrimdışı yazar kasa ile değişim kuralı düzenleme'", CommonClientServer.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			StrTemplate(NStr("vi = 'Trong thời gian áp dụng thay đổi, đã xảy ra lỗi:
			                     |%1';
			                     |ru = 'Во время применения изменений произошла ошибка:
			                     |%1';
			                     |en = 'An error occurred when applying the changes:
			                     |%1'; fa = 'An error occurred when applying the changes:
			                     |%1';
			                     |it = 'Si è verificato un errore durante l''applicazione delle modifiche:
			                     |%1';
			                     |pl = 'W czasie stosowania zmian zaistniał błąd: 
			                     |%1';
			                     |tr = 'Değişiklikler uygulanırken hata oluştu:
			                     |%1'"), DetailErrorDescription(ErrorInfo())));
		
	EndTry;
	
EndProcedure

&AtServer
Function FindProductLineWithCode(Code, Id)
	
	ReturnValue = Undefined;
	
	FoundRows = Goods.FindRows(New Structure("Code", Code));
	If FoundRows.Count() > 1 Then
		For Each FoundRow In FoundRows Do
			If FoundRow.GetID() <> Id Then
				ReturnValue = FoundRow.GetID();
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	Return ReturnValue;
	
EndFunction

&AtServer
Procedure ProcessChangesToProductCodeOnServer(CurrentCode)
	
	GoodsQuantity = Goods.Count();
	If GoodsQuantity > 0 Then
		
		MaximumCodeInTable = Goods[GoodsQuantity-1].Code;
		If MaximumCodeInTable = CurrentCode Then
			If GoodsQuantity > 1 Then
				MaximumCodeInTable = Goods[GoodsQuantity-2].Code;
			EndIf;
		EndIf;
		
		If MaximumCodeInTable > OldCode Then
			
			NewRow = Goods.Add();
			NewRow.Code = OldCode;
			NewRow.ChangedByUser = True;
			
		EndIf;
		
		Difference = CurrentCode - MaximumCodeInTable;
		While Difference > 1 Do
			
			NewRow = Goods.Add();
			NewRow.New = True;
			NewRow.ChangedByUser = True;
			
			MaximumCodeInTable = MaximumCodeInTable + 1;
			NewRow.Code = MaximumCodeInTable;
			Difference = Difference - 1;
			
		EndDo;
	EndIf;
	
	Goods.Sort("Code");
	
EndProcedure

&AtServer
Procedure DeleteFreeProductCodesOnServer()
	
	BeginTransaction();
	Try
		
		ArrayOfRowsToDelete = New Array;
		
		// Removing free product codes from the end of the list.
		LastRowIndex = Goods.Count() - 1;
		For LineNumber = -LastRowIndex To 0 Do
			TSRow = Goods[-LineNumber];
			If Not ValueIsFilled(TSRow.Products) Then
				
				RecordManager = InformationRegisters.ItemsIDOfPeripheralsOffline.CreateRecordManager();
				FillPropertyValues(RecordManager, TSRow);
				RecordManager.ExchangeRule = Object.Ref;
				RecordManager.Delete();
				
				ArrayOfRowsToDelete.Add(TSRow);
				
			Else
				Break;
			EndIf;
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		WriteLogEvent(NStr("vi = 'Xóa mã MTT Offline tự do';
							|ru = 'Удаление свободных кодов ККМ Offline';
							|en = 'Delete available codes of offline cash register'; fa = 'Delete available codes of offline cash register';
							|it = 'Cancellazione dei codici liberi dei KKM (Macchinari di Registrazione e Controllo) Offline';
							|pl = 'Usuwanie wolnych kodów kas offline';
							|tr = 'Boş çevrimdışı yazar kasa kodlarının silinmesi'", CommonClientServer.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			StrTemplate(NStr("vi = 'Khi xóa mã tự do của MTT Offline đã xảy ra lỗi:
			                     |%1';
			                     |ru = 'Во время удаления свободных кодов ККМ Offline произошла ошибка:
			                     |%1';
			                     |en = 'An error occurred when deleting available codes of offline cash register:
			                     |%1'; fa = 'An error occurred when deleting available codes of offline cash register:
			                     |%1';
			                     |it = 'Durante la cancellazione dei codici liberi dei KKM (Macchinari di Registrazione e Controllo) si è verificato un errore:
			                     |%1';
			                     |pl = 'W czasie usuwania wolnych kodów kas offline zaistniał błąd:
			                     |%1';
			                     |tr = 'Boş çevrimdışı yazar kasa kodlarının silinmesi sırasında hata oluştu:
			                     |%1'"), DetailErrorDescription(ErrorInfo())));
		
		Return;
		
	EndTry;
	
	For Each TSRow In ArrayOfRowsToDelete Do
		Goods.Delete(TSRow);
	EndDo;
	
EndProcedure

&AtServer
Procedure UpdateSettingsComposerSelections()
	
	For Each FIlterRow In SettingsComposer.Settings.Filter.Items Do
		If FIlterRow.LeftValue = New DataCompositionField("Warehouse") Then
			SettingsComposer.Settings.DataParameters.SetParameterValue("ExcludeZeroStockBalances", FIlterRow.Use);
		EndIf;
	EndDo;
	
EndProcedure


// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure GoodsOnActivateCell(Item)
	
	If Not Item.CurrentItem = Items.GoodsCode Then
		Return;
	EndIf;
	
	If Not GoodsCodeEditingIsAvailable Then
		StandardProcessing = False;
		Return;
	EndIf;
	
	If Items.Goods.CurrentData = Undefined Then
		Return;
	EndIf;
	
	OldCode = Items.Goods.CurrentData.Code;
	
	FreeCodes = FreeCodes();
	Items.GoodsCode.ChoiceList.Clear();
	For Each FreeCode In FreeCodes Do
		Items.GoodsCode.ChoiceList.Add(FreeCode );
	EndDo;
	
EndProcedure

&AtServerNoContext
Function DefaultTypeOfConnectedEquipment()

	Result = Enums.PeripheralTypes.LabelPrintingScales;
	DefaultTypeOfConnectedEquipmentLocalization(Result);
	
	Return Result;
	
EndFunction

&AtServerNoContext
Procedure DefaultTypeOfConnectedEquipmentLocalization(PeripheralType)
	
	
EndProcedure

#EndRegion

#EndRegion
