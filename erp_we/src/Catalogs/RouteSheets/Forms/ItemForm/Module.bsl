#Region Variables

&AtClient
Var CachedValues;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	BasicBufferTimeUnit = Catalogs.ProductionStages.BasicBufferTimeUnit();
	CalculateTheCoefficientNumber = Object.CalculateFactor;
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	SetSelectionInListOfOperations();
	
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	// Handler of the subsystem "Versioning of objects"
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	ProductionServer.AddWarningRouteMapsAreOutdated(ThisObject);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// The end of the standard subsystem.Pluggable commands
	// Standard subsystems.Worksfiles
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnReadCreateAtServer();
	
	FillInThereIsAutomaticSelectionOfNomenclature();
	
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
	NotCheckedAttributeArray = New Array;
	
	If Not SplitRouteSheets Then
		NotCheckedAttributeArray.Add("MaximumNumberOfProductUnitsLots");
	EndIf; 
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Handler of the "Properties" subsystem
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	
	CurrentObject.MaximumNumberOfProductUnitsLots = MaximumNumberOfProductUnitsLots;

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_RouteSheets",, Object.Ref);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	// End StandardSubsystems.AttachableCommands
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	SetAvailabilityOfItemsByStatusServer();
	
	SetSelectionInListOfOperations();
	
	FillInServiceDetails();
	
	SetAvailabilityOfStatusChangeCommands();
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Subsystem "Properties"
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	If EventName = "Write_File" Then
		
		Items.Operations.Refresh();
		
	ElsIf EventName = "CopyingLinesToClipboard" Then
		
		SetAvailabilityOfClipboardCommands(ThisForm, AttributeAvailability);
		
	EndIf;
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource <> Undefined 
		And TypeOf(ChoiceSource) = Type("ClientApplicationForm")
		And ChoiceSource.FormName = "CommonForm.ConfigureProductAutoSelection" Then
		
		ProcessingSelectionSettingUpAutomaticSelectionOfProducts(ChoiceSource.TSName, ValueSelected);
		
	ElsIf ChoiceSource <> Undefined 
		And TypeOf(ChoiceSource) = Type("ClientApplicationForm") 
		And ChoiceSource.FormName = "CommonForm.ConfigureFilterByPropertiesAndCalculationUsingFormulas" Then
		
		SelectionProcessingSettingUpSelectionByPropertiesAndCalculationByFormulas(ChoiceSource.TSName, ValueSelected);
		
	Else
		ProcessingSelectionOfSelectionOnServer(ValueSelected);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If CurrentPage.Name = "AdvancedGroup"
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure UnitOfMeasureOfPreliminaryBufferOnChange(Item)
	
	If Object.UnitOfMeasureOfPreliminaryBuffer.IsEmpty() Then
		Object.UnitOfMeasureOfPreliminaryBuffer = BasicBufferTimeUnit;
	EndIf; 
	
EndProcedure

&AtClient
Procedure UnitOfMeasureOfFollowUpBufferOnChange(Item)
	
	If Object.UnitOfMeasureOfFollowUpBuffer.IsEmpty() Then
		Object.UnitOfMeasureOfFollowUpBuffer = BasicBufferTimeUnit;
	EndIf;
		
EndProcedure

&AtClient
Procedure SplitRouteSheetsOnChange(Item)
	
	If Not SplitRouteSheets Then
		If MaximumNumberOfProductUnitsLots <> 0 Then
			MaximumNumberOfProductUnitsLots = 0;
		EndIf; 
	Else
		If MaximumNumberOfProductUnitsLots = 0 Then
			MaximumNumberOfProductUnitsLots = 1;
		EndIf; 
	EndIf;
	
	AvailabilityControl(ThisForm);
	
EndProcedure

&AtClient
Procedure PreliminaryBufferOnChange(Item)
	
	SetBlankMarkForBuffers(ThisForm);
	
EndProcedure

&AtClient
Procedure FollowUpBufferOnChange(Item)
	
	SetBlankMarkForBuffers(ThisForm);
	
EndProcedure

&AtClient
Procedure CalculateTheCoefficientNumber0OnChange(Item)
	
	WhenChangingCalculateCoefficientNumber();
	
EndProcedure

&AtClient
Procedure CalculateTheCoefficientNumber1OnChange(Item)
	
	WhenChangingCalculateCoefficientNumber();
	
EndProcedure

&AtClient
Procedure FactorDenominatorOnChange(Item)
	
	ConfigureDecryptionCoefficientDenominator(ThisObject);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersOperations

&AtClient
Procedure OperationsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	AddOperation(Cancel);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersManufacturedProducts

&AtClient
Procedure ManufacturedProductsSelection(Item, RowSelected, Field, StandardProcessing)
	
	ProcessFieldSelectionInTable("ManufacturedProducts", Field.Name, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsOnStartEdit(Item, NewRow, Copy)
	
	If NewRow Then
		
		WhenEnteringNewLineOnRouteMap(ThisForm, Item.Name, Items[Item.Name].CurrentData, Copy);
		
		TotalProductNumber = Object.ManufacturedProducts.Count() + Object.RecyclableWaste.Count();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ManufacturedProductsProductsOnChange(Item)

	CurrentRow = Items.ManufacturedProducts.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));

	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "ManufacturedProducts"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	ProductDataManagementClientServer.WhenChangingProductsInLineWithAutoSelection(CurrentRow, Object);
	ProductDataManagementClientServer.WhenChangingCharacteristicInLineWithAutoSelection(CurrentRow, Object);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsCharacteristicOnChange(Item)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	
	ProductDataManagementClientServer.WhenChangingCharacteristicInLineWithAutoSelection(CurrentData, Object);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsOnEditEnd(Item, NewRow, CancelEdit)
	
	If Not CancelEdit Then
		NumberOfProductsWithCostTypeIsCalculated = Object.ManufacturedProducts.Count();
		CurrentData = Items.ManufacturedProducts.CurrentData;
		If Object.ForFinishedProductsKind.IsEmpty() 
			And CurrentData.LineNumber = 1 
			And Not CurrentData.Products.IsEmpty() Then
			Object.ForFinishedProductsKind = GeneralPurposeTMServerCall.ObjectAttributeValue(CurrentData.Products, "ProductKind");
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ManufacturedProductsBeforeDeleteRow(Item, Cancel)
	
	ProductDataManagementClient.ClearProductSelectionSettings(
		Items.ManufacturedProducts,
		Items.ManufacturedProducts.SelectedRows,
		Object.PropertyMapping);
	ProductDataManagementClient.ClearSelectionSettingsByProperties(
		Items.ManufacturedProducts,
		Items.ManufacturedProducts.SelectedRows,
		Object.SelectionByProperties);
		
EndProcedure

&AtClient
Procedure ManufacturedProductsAfterDeleteRow(Item)
	
	NumberOfProductsWithCostTypeIsCalculated = Object.ManufacturedProducts.Count();
	TotalProductNumber = Object.ManufacturedProducts.Count() + Object.RecyclableWaste.Count();
	
EndProcedure

&AtClient
Procedure ManufacturedProducts_InsertRows(Command)
	
	GetLinesFromClipboard("ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure ManufacturedProducts_CopyLines(Command)
	
	CopyTSLines("ManufacturedProducts");
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersRecyclableWaste

&AtClient
Procedure RecyclableWasteSelection(Item, RowSelected, Field, StandardProcessing)
	
	ProcessFieldSelectionInTable("RecyclableWaste", Field.Name, StandardProcessing);
	
EndProcedure

&AtClient
Procedure RecyclableWasteProductsOnChange(Item)
	
	CurrentRow = Items.RecyclableWaste.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	ProductDataManagementClientServer.WhenChangingProductsInLineWithAutoSelection(CurrentRow, Object);
	ProductDataManagementClientServer.WhenChangingCharacteristicInLineWithAutoSelection(CurrentRow, Object);
	
EndProcedure

&AtClient
Procedure RecyclableWasteCharacteristicOnChange(Item)
	
	CurrentData = Items.RecyclableWaste.CurrentData;
	
	ProductDataManagementClientServer.WhenChangingCharacteristicInLineWithAutoSelection(CurrentData, Object);
	
EndProcedure

&AtClient
Procedure RecyclableWasteOnStartEdit(Item, NewRow, Copy)
	
	If NewRow Then
	
		WhenEnteringNewLineOnRouteMap(ThisForm, Item.Name, Items[Item.Name].CurrentData, Copy);
	
		TotalProductNumber = Object.ManufacturedProducts.Count() + Object.RecyclableWaste.Count();
	
	EndIf;
	
EndProcedure

&AtClient
Procedure RecyclableWasteBeforeDeleteRow(Item, Cancel)
	
	ProductDataManagementClient.ClearProductSelectionSettings(
		Items.RecyclableWaste,
		Items.RecyclableWaste.SelectedRows,
		Object.PropertyMapping);
	ProductDataManagementClient.ClearSelectionSettingsByProperties(
		Items.RecyclableWaste,
		Items.RecyclableWaste.SelectedRows,
		Object.SelectionByProperties);
	
EndProcedure

&AtClient
Procedure RecyclableWasteAfterDeleteRow(Item)
	TotalProductNumber = Object.ManufacturedProducts.Count() + Object.RecyclableWaste.Count();
EndProcedure

&AtClient
Procedure RecyclableWasteToInsertRows(Command)
	
	GetLinesFromClipboard("RecyclableWaste");
	
EndProcedure

&AtClient
Procedure RecyclableWasteToCopyRows(Command)
	
	CopyTSLines("RecyclableWaste");
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersMaterialsAndServices

&AtClient
Procedure MaterialsAndServicesSelection(Item, RowSelected, Field, StandardProcessing)
	
	ProcessFieldSelectionInTable("MaterialsAndServices", Field.Name, StandardProcessing);
	
EndProcedure

&AtClient
Procedure MaterialsAndServicesOnStartEdit(Item, NewRow, Copy)
	
	If NewRow Then
		
		WhenEnteringNewLineOnRouteMap(ThisForm, Item.Name, Items[Item.Name].CurrentData, Copy);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure MaterialsAndServicesBeforeDeleteRow(Item, Cancel)
	
	ProductDataManagementClient.ClearProductSelectionSettings(
				Items.MaterialsAndServices,
				Items.MaterialsAndServices.SelectedRows,
				Object.PropertyMapping);
	ProductDataManagementClient.ClearSelectionSettingsByProperties(
				Items.MaterialsAndServices,
				Items.MaterialsAndServices.SelectedRows,
				Object.SelectionByProperties);
	
EndProcedure

&AtClient
Procedure MaterialsAndServicesProductsOnChange(Item)
	
	CurrentRow = Items.MaterialsAndServices.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));

	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "MaterialsAndServices"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	ProductDataManagementClientServer.WhenChangingProductsInLineWithAutoSelection(CurrentRow, Object);
	ProductDataManagementClientServer.WhenChangingCharacteristicInLineWithAutoSelection(CurrentRow, Object);
	
EndProcedure

&AtClient
Procedure MaterialsAndServicesCharacteristicOnChange(Item)
	
	CurrentData = Items.MaterialsAndServices.CurrentData;
	
	ProductDataManagementClientServer.WhenChangingCharacteristicInLineWithAutoSelection(CurrentData, Object);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersLaborCosts

&AtClient
Procedure LaborCostsSelection(Item, RowSelected, Field, StandardProcessing)
	
	ProcessFieldSelectionInTable("LaborCosts", Field.Name, StandardProcessing);
	
EndProcedure

&AtClient
Procedure LaborCostsInsertLines(Command)
	
	GetLinesFromClipboard("LaborCosts");
	
EndProcedure

&AtClient
Procedure TheEffortToCopyRows(Command)
	
	CopyTSLines("LaborCosts");
	
EndProcedure

&AtClient
Procedure LaborCostsBeforeDeleteRow(Item, Cancel)
	
	ProductDataManagementClient.ClearSelectionSettingsByProperties(
		Items.LaborCosts,
		Items.LaborCosts.SelectedRows,
		Object.SelectionByProperties);
	
EndProcedure
	
&AtClient
Procedure LaborCostsOnStartEdit(Item, NewRow, Copy)
	
	If NewRow Then
		
		WhenEnteringNewLineOnRouteMap(ThisForm, Item.Name, Items[Item.Name].CurrentData, Copy);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	 FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldDrag(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)
	 FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

&AtClient
Procedure TheCommandSchemeOfOperations(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("RouteSheet", Object.Ref);
	
	OpenForm("Report.RouteSheetChart.Form", FormParameters); 
	
EndProcedure

&AtClient
Procedure TheTeamToFillInTheRouteMap(Command)
	
	FilterParameters = New Structure("DeletionMark", False);
	FormParameters = New Structure("DisableSelection,Filter", Object.Ref, FilterParameters);
	CallbackDescription = New CallbackDescription("HandlerFillInFromOperationsSheet", ThisObject);
	OpenForm("Catalog.RouteSheets.ChoiceForm", 
				FormParameters,,,,, 
				CallbackDescription,
				FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure TheSetStatusInDevelopmentCommand(Command)
	
	If Not AttributeAvailability Then
		
		CallbackDescription = New CallbackDescription("SetStatusUnderDevelopmentCompletion", ThisObject);
		OpenForm("Catalog.RouteSheets.Form.AttributeUnlocking", 
								New Structure("Object", Object.Ref),,,,,
								CallbackDescription,
								FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TheSetStatusCommandIsActive(Command)
	
	SetNewStatusAndRecord(PredefinedValue("Enum.StatusesOfRouteSheets.Valid"));
	
EndProcedure

&AtClient
Procedure TheSetStatusClosedCommand(Command)
	
	SetNewStatusAndRecord(PredefinedValue("Enum.StatusesOfRouteSheets.Closed_"));
	
EndProcedure

&AtClient
Procedure CheckFillInCommand(Command)
	
	ClearMessages();
	
	If CheckForcedFilling() Then
		WarningText = NStr("vi = 'Sơ đồ quy trình có thể được thực hiện hợp lệ.';
							|ru = 'Маршрутную карту можно сделать действующей.';
							|en = '""Valid"" status can be set for this route sheet.'; fa = '""Valid"" status can be set for this route sheet.';
							|it = 'È possibile rendere attiva la scheda di lavorazione.';
							|pl = 'Karta technologiczna może być ustawiona jako aktualna.';
							|tr = 'Rota aktif hale getirilebilir.'");
	Else
		WarningText = NStr("vi = 'Sơ đồ quy trình không thể hợp lệ.';
							|ru = 'Маршрутная карта не может быть действующей.';
							|en = '""Valid"" status cannot be set for this route sheet.'; fa = '""Valid"" status cannot be set for this route sheet.';
							|it = 'La scheda di lavorazione non può essere attiva.';
							|pl = 'Karta technologiczna nie może być ustawiona jako aktualna.';
							|tr = 'Rota aktif hale getirilemez.'");
	EndIf;
	
	ShowMessageBox(,WarningText,, NStr("vi = 'Kiểm tra bản đồ lộ trình';
										|ru = 'Проверка маршрутной карты';
										|en = 'Check route sheet'; fa = 'Check route sheet';
										|it = 'Controllo della scheda di lavorazione';
										|pl = 'Weryfikacja karty technologicznej';
										|tr = 'Rota kontrolü'"));
	
EndProcedure

&AtClient
Procedure TheCommandToConfigureTheComposition(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("UseFinishedProducts", Object.UseFinishedProducts);
	FormParameters.Insert("UseMaterials", Object.UseMaterials);
	FormParameters.Insert("UseOperations", Object.UseOperations);
	FormParameters.Insert("UseLaborCosts", Object.UseLaborCosts);
	
	CallbackDescription = New CallbackDescription("ToAdjustTheCompositionCompletion", ThisObject);
	OpenForm("Catalog.RouteSheets.Form.SettingRouteSheetContent", FormParameters,,,,, CallbackDescription);
	
EndProcedure

&AtClient
Procedure Copy(Command)
	
	If Modified Then
		ShowMessageBox(, NStr("vi = 'Đối tượng không được ghi lại!';
								|ru = 'Объект не записан!';
								|en = 'Object is not saved.'; fa = 'Object is not saved.';
								|it = 'L''oggetto non è registrato!';
								|pl = 'Obiekt nie jest zapisany!';
								|tr = 'Nesne kaydedilmedi!'"));
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription("QuestionCopyRouteMap", ThisForm);
	ProductDataManagementClient.ShowCopyRouteMapWithOperationsQuestion(CallbackDescription);
	
EndProcedure

#Region ManufacturedProducts

&AtClient
Procedure OutputItemsSetUpAutomaticItemSelection_3(Command)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	
	ClearMessages();
	
	If CurrentData = Undefined Then
		MessageText = NStr("vi = 'Hàng của bảng ""Sản phẩm đầu ra"" không được chọn.';
							|ru = 'Не выбрана строка таблицы ""Выходные изделия"".';
							|en = 'Line of the ""Finished products"" table is not selected.'; fa = 'Line of the ""Finished products"" table is not selected.';
							|it = 'Non è stata scelta una riga della tabella ""Prodotti di output"".';
							|pl = 'Nie wybrano wiersza tabeli ""Wyroby wyjściowe"".';
							|tr = '""Üretilen Nihai Ürünler"" tablosunun satırı seçilmedi.'");
		CommonClientServer.MessageToUser(MessageText,, "Object.ManufacturedProducts", "Object");
		Return;
	EndIf;
	
	PropertyMapping = ProductDataManagementClient.DetailsOfSettingsByLineInArray(
		CurrentData,
		Object.PropertyMapping,
		ProductDataManagementClientServer.DetailsSettingUpPropertyMatching());
	
	ProductDataManagementClient.ConfigureProductsAutoselection(
							ThisForm,
							"ManufacturedProducts",
							PropertyMapping,
							Object.ForFinishedProductsKind,
							NStr("vi = 'Chỉ ra trong sơ đồ quy trình';
								|ru = 'Указывается в маршрутной карте';
								|en = 'Specified in the route sheet'; fa = 'مشخص‌شده در برگه مسیر';
								|it = 'Indicato nella scheda di lavorazione';
								|pl = 'Jest wskazywany w karcie technologicznej';
								|tr = 'Rotada belirtilmektedir'"),
							Not AttributeAvailability);

EndProcedure

&AtClient
Procedure OutputItemsSettingUpSelectionByPropertiesAndCalculationByFormulas_5(Command)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	
	ClearMessages();
	
	If CurrentData = Undefined Then
		
		MessageText = NStr("vi = 'Hàng của bảng ""Sản phẩm đầu ra"" không được chọn.';
							|ru = 'Не выбрана строка таблицы ""Выходные изделия"".';
							|en = 'Line of the ""Finished products"" table is not selected.'; fa = 'Line of the ""Finished products"" table is not selected.';
							|it = 'Non è stata scelta una riga della tabella ""Prodotti di output"".';
							|pl = 'Nie wybrano wiersza tabeli ""Wyroby wyjściowe"".';
							|tr = '""Üretilen Nihai Ürünler"" tablosunun satırı seçilmedi.'");
		CommonClientServer.MessageToUser(MessageText,, "Object.ManufacturedProducts", "Object");
		
		Return;
	EndIf;
	
	OpenSettingsForSelectingByPropertiesAndCalculatingByFormulas(CurrentData, "ManufacturedProducts");
	
EndProcedure

#EndRegion

#Region RecyclableWaste

&AtClient
Procedure RecyclableWasteConfigureAutoSelectionOfProductItems(Command)
	
	CurrentData = Items.RecyclableWaste.CurrentData;
	
	ClearMessages();
	
	If CurrentData = Undefined Then
		MessageText = NStr("vi = 'Chưa chọn dòng bảng ""Sản phẩm phụ và xuất xưởng trung gian""';
							|ru = 'Не выбрана строка таблицы ""Побочный и промежуточный выпуск"".';
							|en = 'Line of the ""Side and intermediate release"" table is not selected.'; fa = 'Line of the ""Side and intermediate release"" table is not selected.';
							|it = 'Non è stata scelta una riga della tabella ""Produzione collaterale e intermedia"".';
							|pl = 'Nie jest wybrany wiersz tabeli ""Poboczne i pośrednie wypuszczenie"".';
							|tr = '""Yan ve Ara Ürün Çıkışı"" tablosunun satırı seçilmedi.'");
		CommonClientServer.MessageToUser(MessageText,, "Object.RecyclableWaste", "Object");
		Return;
	EndIf;
	
	ProductDataManagementClient.ConfigureProductsAutoselection(
							ThisForm,
							"RecyclableWaste",
							Object.PropertyMapping,
							Object.ForFinishedProductsKind,
							NStr("vi = 'Chỉ ra trong sơ đồ quy trình';
								|ru = 'Указывается в маршрутной карте';
								|en = 'Specified in the route sheet'; fa = 'مشخص‌شده در برگه مسیر';
								|it = 'Indicato nella scheda di lavorazione';
								|pl = 'Jest wskazywany w karcie technologicznej';
								|tr = 'Rotada belirtilmektedir'"),
							Not AttributeAvailability);
	
EndProcedure

&AtClient
Procedure RecyclableWasteConfigureFilterByPropertiesAndCalculationUsingFormulas(Command)

	CurrentData = Items.RecyclableWaste.CurrentData;
	
	ClearMessages();
	
	If CurrentData = Undefined Then
		
		MessageText = NStr("vi = 'Chưa chọn dòng bảng ""Sản phẩm phụ và xuất xưởng trung gian""';
							|ru = 'Не выбрана строка таблицы ""Побочный и промежуточный выпуск"".';
							|en = 'Line of the ""Side and intermediate release"" table is not selected.'; fa = 'Line of the ""Side and intermediate release"" table is not selected.';
							|it = 'Non è stata scelta una riga della tabella ""Produzione collaterale e intermedia"".';
							|pl = 'Nie jest wybrany wiersz tabeli ""Poboczne i pośrednie wypuszczenie"".';
							|tr = '""Yan ve Ara Ürün Çıkışı"" tablosunun satırı seçilmedi.'");
		CommonClientServer.MessageToUser(MessageText,, "Object.RecyclableWaste", "Object");
		
		Return;
	EndIf;
	
	OpenSettingsForSelectingByPropertiesAndCalculatingByFormulas(CurrentData, "RecyclableWaste");
	
EndProcedure

#EndRegion

#Region UsedMaterials

&AtClient
Procedure SetUpAutoSelectionOfMaterialsCommand(Command)
	
	CurrentData = Items.MaterialsAndServices.CurrentData;
	
	ClearMessages();
	
	If CurrentData = Undefined Then
		MessageText = NStr("vi = 'Hàng của bảng ""Nguyên vật liệu và nhân công"" không được chọn.';
							|ru = 'Не выбрана строка таблицы ""Материалы и работы"".';
							|en = 'Row of the ""Materials and works"" table is not selected.'; fa = 'Row of the ""Materials and works"" table is not selected.';
							|it = 'Non è stata scelta una riga della tabella ""Materiali e lavori"".';
							|pl = 'Nie wybrano wiersza tabeli ""Materiały i prace"".';
							|tr = '""Malzemeler ve İşler"" tablosunun satırı seçilmedi.'");
		CommonClientServer.MessageToUser(MessageText,, "Object.MaterialsAndServices", "Object");
		Return;
	EndIf;
	
	PropertyMapping = ProductDataManagementClient.DetailsOfSettingsByLineInArray(
		CurrentData,
		Object.PropertyMapping,
		ProductDataManagementClientServer.DetailsSettingUpPropertyMatching());
	
	ProductDataManagementClient.ConfigureProductsAutoselection(
							ThisForm,
							"MaterialsAndServices",
							PropertyMapping, 
							Object.ForFinishedProductsKind,
							NStr("vi = 'Chỉ ra trong sơ đồ quy trình';
								|ru = 'Указывается в маршрутной карте';
								|en = 'Specified in the route sheet'; fa = 'مشخص‌شده در برگه مسیر';
								|it = 'Indicato nella scheda di lavorazione';
								|pl = 'Jest wskazywany w karcie technologicznej';
								|tr = 'Rotada belirtilmektedir'"),
							Not AttributeAvailability);
	
EndProcedure

&AtClient
Procedure MaterialsAndServices_SettingUpFilterByPropertiesAndCalculationByFormulas(Command)
	
	CurrentData = Items.MaterialsAndServices.CurrentData;
	
	ClearMessages();
	
	If CurrentData = Undefined Then
		
		MessageText = NStr("vi = 'Hàng của bảng ""Nguyên vật liệu và nhân công"" không được chọn.';
							|ru = 'Не выбрана строка таблицы ""Материалы и работы"".';
							|en = 'Row of the ""Materials and works"" table is not selected.'; fa = 'Row of the ""Materials and works"" table is not selected.';
							|it = 'Non è stata scelta una riga della tabella ""Materiali e lavori"".';
							|pl = 'Nie wybrano wiersza tabeli ""Materiały i prace"".';
							|tr = '""Malzemeler ve İşler"" tablosunun satırı seçilmedi.'");
		CommonClientServer.MessageToUser(MessageText,, "Object.MaterialsAndServices", "Object");
		
		Return;
	EndIf;
	
	OpenSettingsForSelectingByPropertiesAndCalculatingByFormulas(CurrentData, "MaterialsAndServices");
	
EndProcedure

&AtClient
Procedure LaborCostsSettingUpSelectionByPropertiesAndCalculationByFormulas_3(Command)
	
	CurrentData = Items.LaborCosts.CurrentData;
	
	ClearMessages();
	
	If CurrentData = Undefined Then
		
		MessageText = NStr("vi = 'Hàng của bảng ""Chi phí nhân công""chưa được chọn.';
							|ru = 'Не выбрана строка таблицы ""Трудозатраты"".';
							|en = 'Line of the ""Labor costs"" table is not selected.'; fa = 'Line of the ""Labor costs"" table is not selected.';
							|it = 'Non è stata scelta una riga della tabella ""Costi di manodopera"".';
							|pl = 'Nie wybrano wiersza tabeli ""Nakłady pracy"".';
							|tr = '""İş Gücü Maliyetleri"" tablosunun satırı seçilmedi.'");
		CommonClientServer.MessageToUser(MessageText,, "Object.LaborCosts", "Object");
		
		Return;
	EndIf;
	
	OpenSettingsForSelectingByPropertiesAndCalculatingByFormulas(CurrentData, "LaborCosts");

EndProcedure

&AtClient
Procedure OpenSelectionOfMaterialsCommand(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("CloseOnChoice", False);
	ArrayOfProductTypes = ProductDataManagementClientServer.ArrayOfAvailableItemTypes(ThisObject, "MaterialsAndServices");
	AvailableProductTypes = New FixedArray(ArrayOfProductTypes);
	FormParameters.Insert("Filter", New Structure("ItemsType", AvailableProductTypes));
	
	OpenForm("Catalog.Products.Form.ChoiceForm", 
			FormParameters, 
			ThisForm, 
			UUID,,,, 
			FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure MaterialsAndServicesInsertLines(Command)
	
	GetLinesFromClipboard("MaterialsAndServices");
	
EndProcedure

&AtClient
Procedure MaterialsAndServicesCopyLines(Command)
	
	CopyTSLines("MaterialsAndServices");
	
EndProcedure

#EndRegion

#Region Operations

&AtClient
Procedure AddOperationCommand(Command)
	
	Items.Operations.AddRow();
	
EndProcedure

&AtClient
Procedure AddNestedRouteCommand(Command)
	
	AddOperation(, True);
	
EndProcedure

&AtClient
Procedure TheCommandToChangeTheTypeOfOperationOnANestedRoute(Command)
	
	ChangeTypeOfOperation(True);
	
EndProcedure

&AtClient
Procedure TheCommandToChangeTheTypeOfOperationOnTheOperation(Command)
	
	ChangeTypeOfOperation(False);
	
EndProcedure

&AtClient
Procedure MoveOperationForwardCommand(Command)
	
	MoveOperation(True);
	
EndProcedure

&AtClient
Procedure MoveOperationBackCommand(Command)
	
	MoveOperation(False);
	
EndProcedure

#EndRegion

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

#Region Private

// StandardSubsystems.Properties

&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	PropertyManager.FillAdditionalAttributesInForm(ThisObject);
EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

// End StandardSubsystems.Properties

#Region PropertySubsystemProcedures

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

#EndRegion

#Region WorkingWithClipboard

&AtClient
Procedure CopyTSLines(TSName)
	
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items[TSName]) Then
		CopyLinesOnServer(TSName);
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(Items[TSName].SelectedRows.Count());
	EndIf;
	
EndProcedure

&AtServer
Procedure CopyLinesOnServer(TSName)
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object[TSName], Items[TSName].SelectedRows);
	
EndProcedure

&AtClient
Procedure GetLinesFromClipboard(TSName)
	
	NumberOfRowsBeforeInsertion = Object[TSName].Count();
	
	GetLinesFromClipboardOnServer(TSName);
	
	NumberOfInserted = Object[TSName].Count() - NumberOfRowsBeforeInsertion;
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboardOnServer(TSName)
	
	CompositionOfLines     = Undefined;
	FilterParameters = Undefined;
	
	If TSName = "ManufacturedProducts" Then
		CompositionOfLines = "Products,Characteristic,Package,NumberOfPackages";
	ElsIf TSName = "MaterialsAndServices" Or TSName = "RecyclableWaste" Then
		CompositionOfLines = "Products,Characteristic,Package,NumberOfPackages,ProductCostElement";
	ElsIf TSName = "LaborCosts" Then
		CompositionOfLines = "WorkKind,Count,ProductCostElement";
	EndIf;
	
	SelectGoods = TSName <> "LaborCosts";
	
	StructureOfActions = New Structure;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	If SelectGoods Then
		
		ArrayOfProductTypes = ProductDataManagementClientServer.ArrayOfAvailableItemTypes(ThisObject, TSName);
		FilterParameters = New Map;
		FilterParameters.Insert("Products.ItemsType", ArrayOfProductTypes);
		
		StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
		
	EndIf;
	
	LinesFromBuffer = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, CompositionOfLines);
	
	If Not ValueIsFilled(LinesFromBuffer) Then
		Return;
	EndIf;
	
	ObjectTable = Object[TSName]; // FormDataCollection
	RowsToProcess = New Array;
	For Each LineFromBuffer In LinesFromBuffer Do
		
		CurrentRow = ObjectTable.Add();
		FillPropertyValues(CurrentRow, LineFromBuffer);
		
		WhenEnteringNewLineOnRouteMap(ThisForm, TSName, CurrentRow);
		
		If SelectGoods Then
			RowsToProcess.Add(CurrentRow);
		EndIf;
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		ObjectTable,
		CachedValues);
	
	FillInServiceDetails();
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetAvailabilityOfClipboardCommands(Form, BankingDetailsAreAvailable)
	
	Form.Items.RecyclableWasteToInsertRows.Enabled = BankingDetailsAreAvailable;
	Form.Items.ContextMenuReturnableWasteInsertRows.Enabled = BankingDetailsAreAvailable;
	
	Form.Items.ManufacturedProducts_InsertRows.Enabled = BankingDetailsAreAvailable;
	Form.Items.ContextMenuOutputItemsInsertLines.Enabled = BankingDetailsAreAvailable;
	
	Form.Items.MaterialsAndServicesInsertLines.Enabled = BankingDetailsAreAvailable;
	Form.Items.ContextMenuMaterialsAndServicesInsertLines.Enabled = BankingDetailsAreAvailable;
	
	Form.Items.LaborCostsInsertLines.Enabled = BankingDetailsAreAvailable;
	Form.Items.ContextMenuLaborCostsInsertLines.Enabled = BankingDetailsAreAvailable;
	
EndProcedure

#EndRegion

#Region Operations

&AtClient
Procedure ChangeTypeOfOperation(ContainsNestedRoute)

	If Not CurLineIsOperation() Then
		Return;
	EndIf;
	
	If ContainsNestedRoute Then
		QueryText = NStr("vi = 'Thay đổi loại giao dịch thành ""Quy trình lồng nhau""?';
						|ru = 'Изменить вид операции на ""Вложенный маршрут""?';
						|en = 'Change the operation type to ""Nested route""?'; fa = 'Change the operation type to ""Nested route""?';
						|it = 'Cambiare il tipo di operazione in ""Percorso impostato""?';
						|pl = 'Zmienić typ operacji na ""Trasa zagnieżdżona""?';
						|tr = 'İşlem türü ""İç içe yol"" olarak değiştirilsin mi?'");
	Else
		QueryText = NStr("vi = 'Thay đổi loại giao dịch thành ""Giao dịch""?';
						|ru = 'Изменить вид операции на ""Операция""?';
						|en = 'Change the operation type to ""Operation""?'; fa = 'Change the operation type to ""Operation""?';
						|it = 'Cambiare il tipo di operazione in ""Operazione""?';
						|pl = 'Zmienić typ operacji na ""Operacja""?';
						|tr = 'İşlem türü ""İşlem"" olarak değiştirilsin mi?'");
	EndIf; 
	
	CallbackDescription = New CallbackDescription("QuestionChangeTypeOfOperation", ThisForm, ContainsNestedRoute);
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);

EndProcedure

&AtClient
Procedure MoveOperation(GoForward)
	
	ErrorText = "";
	
	If Not CurLineIsOperation() Then
		Return;
	EndIf;
	
	CurrentData = Items.Operations.CurrentData;
	If MoveOperationOnServer(CurrentData.Ref, GoForward, ErrorText) Then
		NotifyChanged(Type("CatalogRef.ManufacturingOperations"));
	Else
		ShowMessageBox(,ErrorText);
	EndIf;
	
EndProcedure

&AtServerNoContext
Function MoveOperationOnServer(Ref, GoForward, ErrorText)

	OperationObject = Ref.GetObject();
	Try
		OperationObject.Lock();
	Except
		ErrorText = NStr("vi = 'Không thể sắp xếp giao dịch.
								|Có thể là người sử dụng đang chỉnh sửa giao dịch.';
								|ru = 'Не удалось переместить операцию.
								|Возможно, операция редактируется пользователем.';
								|en = 'Cannot move the operation. 
								|Maybe, the operation is being edited by another user.'; fa = 'Cannot move the operation. 
								|Maybe, the operation is being edited by another user.';
								|it = 'Non è stato possibile spostare l''operazione.
								|Probabilmente l''operazione sta venendo modificata dall''utente.';
								|pl = 'Przemieszczenie operacji nie powiodło się.
								|Być może operacja jest edytowana przez użytkownika.';
								|tr = 'İşlem taşınamadı.
								|İşlem, kullanıcı tarafından düzenleniyor olabilir.'");
	    Return False;
	EndTry;
	OperationNumber          = OperationObject.OperationNumber;
	NextOperation = OperationObject.NextOperation;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ManufacturingOperations.Ref
	|FROM
	|	Catalog.ManufacturingOperations AS ManufacturingOperations
	|WHERE
	|	ManufacturingOperations.Owner = &Owner
	|	AND NOT ManufacturingOperations.DeletionMark
	|	AND (&GoForward
	|				AND ManufacturingOperations.OperationNumber = &NextOperation
	|			OR NOT &GoForward
	|				AND ManufacturingOperations.NextOperation = &OperationNumber)";
	
	Query.SetParameter("Owner",               OperationObject.Owner);
	Query.SetParameter("OperationNumber",          OperationNumber);
	Query.SetParameter("NextOperation", NextOperation);
	Query.SetParameter("GoForward",                 GoForward);
	
	Result = Query.Execute().Unload(); // See ProductionServer.ServiceStructureOfValueTable
	If Result.Count() = 0 Then
		
		Return True;
		
	ElsIf Result.Count() > 1 Then
		// There shouldn't be multiple operations
		If GoForward Then
			ErrorText = NStr("vi = 'Không thể chuyển giao dịch về sau,
									|bởi vì có nhiều giao dịch tiếp theo.';
									|ru = 'Не удалось переместить операцию вперед,
									|т.к. следующих операций несколько.';
									|en = 'Cannot put the operation forward 
									|as there are several following operations.'; fa = 'Cannot put the operation forward 
									|as there are several following operations.';
									|it = 'Non è stato possibile spostare in avanti l''operazione,
									|poiché ci sono più operazioni successive.';
									|pl = 'Przemieszczenie operacji naprzód nie powiodło się,
									|ponieważ następnych operacji jest kilka.';
									|tr = 'Birden fazla sonraki işlem olduğundan dolayı
									|işlem ileriye taşınamadı.'");
		Else
			ErrorText = NStr("vi = 'Không thể chuyển giao dịch lên trước,
									|bởi vì có nhiều giao dịch trước đó.';
									|ru = 'Не удалось переместить операцию назад,
									|т.к. предыдущих операций несколько.';
									|en = 'Cannot put the operation back
									|as there are several previous operations.'; fa = 'Cannot put the operation back
									|as there are several previous operations.';
									|it = 'Non è stato possibile spostare indietro l''operazione,
									|poiché ci sono più operazioni precedenti.';
									|pl = 'Przemieszczenie operacji wstecz nie powiodło się,
									|ponieważ poprzednich operacji jest kilka.';
									|tr = 'Birden fazla sonraki işlem olduğundan dolayı
									|işlem geriye taşınamadı.'");
		EndIf;
		Return False;
	EndIf;
	
	ReplacementOperation = Undefined;
	
	// Block the operation with which the transfer will be performed
	ReplacementOperation = Result[0].Ref.GetObject();
	Try
		ReplacementOperation.Lock();
	Except
		If GoForward Then
			ErrorText = NStr("vi = 'Không thể sắp xếp giao dịch.
									|Có thể là người sử dụng đang chỉnh sửa giao dịch tiếp theo.';
									|ru = 'Не удалось переместить операцию.
									|Возможно, следующая операция редактируется пользователем.';
									|en = 'Cannot move the operation.
									|Maybe, the following operation is being edited by another user.'; fa = 'Cannot move the operation.
									|Maybe, the following operation is being edited by another user.';
									|it = 'Non è stato possibile spostare l''operazione.
									|Probabilmente l''operazione successiva sta venendo modificata dall''utente.';
									|pl = 'Przemieszczenie operacji nie powiodło się.
									|Być może, następna operacja jest edytowana przez użytkownika.';
									|tr = 'İşlem taşınamadı.
									|Sonraki işlem, kullanıcı tarafından düzenleniyor olabilir.'");
		Else
			ErrorText = NStr("vi = 'Không thể sắp xếp giao dịch.
									|Có thể là người sử dụng đang chỉnh sửa giao dịch trước đó.';
									|ru = 'Не удалось переместить операцию.
									|Возможно, предыдущая операция редактируется пользователем.';
									|en = 'Cannot move the operation.
									|Maybe, the previous operation is being edited by another user.'; fa = 'Cannot move the operation.
									|Maybe, the previous operation is being edited by another user.';
									|it = 'Non è stato possibile spostare l''operazione.
									|Probabilmente l''operazione precedente sta venendo modificata dall''utente.';
									|pl = 'Przemieszczenie operacji nie powiodło się.
									|Być może, poprzednia operacja jest edytowana przez użytkownika.';
									|tr = 'İşlem taşınamadı.
									|Önceki işlem, kullanıcı tarafından düzenleniyor olabilir.'");
		EndIf;
	    Return False;
	EndTry;
	
	OperationObject.OperationNumber          = ReplacementOperation.OperationNumber;
	OperationObject.NextOperation = ReplacementOperation.NextOperation;
	
	ReplacementOperation.OperationNumber          = OperationNumber;
	ReplacementOperation.NextOperation = NextOperation;
	
	Try
		OperationObject.Write();
		ReplacementOperation.Write();
	Except
		ErrorText = NStr("vi = 'Không thể di chuyển giao dịch.';
						|ru = 'Не удалось переместить операцию.';
						|en = 'Cannot move the operation.'; fa = 'Cannot move the operation.';
						|it = 'Non è stato possibile spostare l''operazione.';
						|pl = 'Przemieszczenie operacji nie powiodło się.';
						|tr = 'İşlem taşınamadı.'");
		Return False;
	EndTry;
	
	OperationObject.Unlock();
	ReplacementOperation.Unlock();
	
	Return True;

EndFunction

&AtClient
Function CurLineIsOperation()

	CurrentData = Items.Operations.CurrentData;
	If CurrentData = Undefined Or TypeOf(CurrentData) = Type("DynamicListGroupRow") Then
		Return False;
	EndIf;

	Return True;
	
EndFunction

&AtServer
Procedure SetSelectionInListOfOperations()
	
	CommonClientServer.SetDynamicListFilterItem(
		Operations, 
		"Owner", 
		Object.Ref, 
		DataCompositionComparisonType.Equal,
		, 
		True);
	
	CommonClientServer.SetDynamicListFilterItem(
		Operations, 
		"DeletionMark", 
		False, 
		DataCompositionComparisonType.Equal,
		, 
		True);
	
	CommonClientServer.SetDynamicListParameter(
		Operations,
		"RouteSheet",
		Object.Ref,
		True);
	
EndProcedure

&AtClient
Procedure AddOperation(Cancel = False, AddNestedRoute = False)

	If Not AttributeAvailability Then
		
		Cancel = True;
		
	ElsIf Not ValueIsFilled(Object.Ref) Then
		
		Cancel = True;
		
		If Object.Status = PredefinedValue("Enum.StatusesOfRouteSheets.Valid") Then
			QueryText = NStr("vi = 'Có thể nhập giao dịch với trạng thái ""Đang phát triển"".
										|Thay đổi trạng thái và ghi lại bảng kê chi tiết?';
										|ru = 'Ввод операций возможен со статусом ""В разработке"".
										|Изменить статус и записать спецификацию?';
										|en = 'You can enter operations only with status ""Under development"".
										|Change the status and save the BOM?'; fa = 'You can enter operations only with status ""Under development"".
										|Change the status and save the BOM?';
										|it = 'L''immissione di operazioni è permessa con stato ""In lavorazione"".
										|Modificare lo stato e registrare la specifica?';
										|pl = 'Wprowadzanie operacji jest możliwe ze statusem ""W przygotowaniu"".
										|Zmienić status i zapisać specyfikację?';
										|tr = 'İşlem girişi, ""Geliştirme Aşamasında"" durumu ile mümkündür.
										|Durum değiştirilsin ve ürün reçetesine kaydedilsin mi?'");
		Else
			QueryText = NStr("vi = 'Chỉ có thể nhập giao dịch sau khi ghi lại tờ lộ trình.
										|Ghi lại tờ lộ trình?';
										|ru = 'Ввод операций возможен только после записи маршрутной карты.
										|Записать маршрутную карту?';
										|en = 'Operations can be entered only after saving the route sheet.
										|Save the route sheet?'; fa = 'Operations can be entered only after saving the route sheet.
										|Save the route sheet?';
										|it = 'L''immissione di operazioni è permessa solamente dopo la scrittura della scheda di lavorazione.
										|Scrivere la scheda di lavorazione?';
										|pl = 'Wprowadzanie operacji jest możliwe tylko po zapisaniu karty technologicznej.
										|Zapisać kartę technologiczną?';
										|tr = 'İşlem girişi sadece rota kaydedildikten sonra mümkündür.
										|Rota kaydedilsin mi?'");
		EndIf;
		
		CallbackDescription = New CallbackDescription("QuestionAddOperation", ThisForm, AddNestedRoute);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		
	ElsIf AddNestedRoute Then
		
		AddNestedRoute();
		
	EndIf;

EndProcedure

#EndRegion

#Region AutoSelection_SelectionByProperties_CalculationOfQuantity

&AtClient
Procedure ProcessingSelectionSettingUpAutomaticSelectionOfProducts(TSName, ValueSelected)
	
	CurrentData = Items[TSName].CurrentData;
	
	MethodOfProductsAutoselection = CurrentData.MethodOfProductsAutoselection;
	
	If ProductDataManagementClient.ConfigureProductsAutoselectionCompletion(ValueSelected, CurrentData, Object.PropertyMapping) Then
		
		If MethodOfProductsAutoselection <> CurrentData.MethodOfProductsAutoselection Then
			
			StructureOfActions = New Structure;
			StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
			BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
			
		EndIf;
		
		FillInThereIsAutomaticSelectionOfNomenclature();
		Modified = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectionProcessingSettingUpSelectionByPropertiesAndCalculationByFormulas(TSName, ValueSelected)
	
	CurrentData = Items[TSName].CurrentData;
	
	If ProductDataManagementClient.ConfigureSelectionByPropertiesAndCalculationByFormulasCompletion(ValueSelected, CurrentData, Object.SelectionByProperties) Then
		Modified = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenSettingsForSelectingByPropertiesAndCalculatingByFormulas(CurrentData, TSName)
	
	AddressInStorage = PutDataForCalculationByFormulasInRepository(TSName);
	
	SelectionByProperties = ProductDataManagementClient.DetailsOfSettingsByLineInArray(
		CurrentData,
		Object.SelectionByProperties,
		ProductDataManagementClientServer.DetailsSettingUpSelectionByProperties());
	
	ProductDataManagementClient.ConfigureSelectionByPropertiesAndCalculationByFormulas(
								ThisForm,
								TSName,
								SelectionByProperties,
								Object.ForFinishedProductsKind,
								Not AttributeAvailability,
								,
								AddressInStorage);

EndProcedure

&AtServer
Function PutDataForCalculationByFormulasInRepository(TSName)
	
	FormTable = Items[TSName]; // FormTable
	
	DataForCalculation = Catalogs.RouteSheets.UploadDataForFormulaConstructor(
		Object,
		TSName,
		Object[TSName].FindByID(FormTable.CurrentRow));
	
	Result = PutToTempStorage(DataForCalculation, UUID);
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Procedure WhenEnteringNewLineOnRouteMap(Form, TSName, LineOfATabularSection, Copy = False)
	
	SourceLinkKey = ?(Copy, LineOfATabularSection.ConnectionKey, Undefined);
	
	LineOfATabularSection.ConnectionKey = New UUID;
	
	If TSName <> "LaborCosts" Then
	
		ProductDataManagementClientServer.WhenEnteringNewLineWithAutoSelection(
			LineOfATabularSection, 
			SourceLinkKey,
			Form.Object.PropertyMapping);
		
	EndIf;
		
	ProductDataManagementClientServer.WhenEnteringNewLineWithSelectionByProperties(
		LineOfATabularSection,
		SourceLinkKey,
		Form.Object.SelectionByProperties);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure OnReadCreateAtServer()
	
	SetAvailabilityOfItemsByStatusServer();
	
	CostTypeIsCalculated = Enums.CostTypesOfFinishedProducts.Calculating;
	
	SplitRouteSheets = (Object.MaximumNumberOfProductUnitsLots <> 0);
	
	MaximumNumberOfProductUnitsLots = Object.MaximumNumberOfProductUnitsLots;
	
	UseBillOfMaterialsParameterization = 
		GetFunctionalOption("UseBillOfMaterialsParameterization");
		
	FillInServiceDetails();
	
	SetAvailabilityOfStatusChangeCommands();
	AvailabilityControl(ThisForm);
	VisibilityManagement(ThisForm);
	SetBlankMarkForBuffers(ThisForm);
	ConfigureDecryptionCoefficientDenominator(ThisForm);
	
	ConfigureRouteMapComposition();
	
	ProductDataManagementClientServer.SetMaterialSelectionParameters(
		Items.MaterialsAndServicesProducts, ThisObject);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ValidOnDate.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.StatusesOfRouteSheets.Valid;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Department.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.StatusesOfRouteSheets.Valid;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "ManufacturedProductsProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.ManufacturedProducts.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "RecyclableWasteProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.RecyclableWaste.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "MaterialsAndServicesProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.MaterialsAndServices.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProducts.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ManufacturedProducts.MainProduct");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , True, False, False, False, ));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TheOutputProductOperation.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ManufacturedProducts.OperationEdit");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NoteText);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<giao dịch cuối cùng>';
													|ru = '<последняя операция>';
													|en = '<last operation>'; fa = '<last operation>';
													|it = '<operazione ultima>';
													|pl = '<ostatnia operacja>';
													|tr = '<son işlem>'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReturnableWasteOperation.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.RecyclableWaste.OperationEdit");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NoteText);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<giao dịch cuối cùng>';
													|ru = '<последняя операция>';
													|en = '<last operation>'; fa = '<last operation>';
													|it = '<operazione ultima>';
													|pl = '<ostatnia operacja>';
													|tr = '<son işlem>'"));

	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MaterialsAndServicesOperation.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialsAndServices.OperationEdit");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NoteText);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<giao dịch đầu tiên>';
													|ru = '<первая операция>';
													|en = '<first operation>'; fa = '<first operation>';
													|it = '<operazione prima>';
													|pl = '<pierwsza operacja>';
													|tr = '<ilk işlem>'"));

	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LaborCostsOperation.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.LaborCosts.OperationEdit");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NoteText);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<giao dịch đầu tiên>';
													|ru = '<первая операция>';
													|en = '<first operation>'; fa = '<first operation>';
													|it = '<operazione prima>';
													|pl = '<pierwsza operacja>';
													|tr = '<ilk işlem>'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductsCostShare.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("NumberOfProductsWithCostTypeIsCalculated");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = 2;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MaximumNumberOfProductUnitsLots.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SplitRouteSheets");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ForFinishedProductsKind.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ThereIsProductItemAutoSelection");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	ProductDataManagement.EstablishConditionalAppearanceOfSelectionByPropertiesAndCalculationByFormulas(
		ThisForm,
		"Object",
		"ManufacturedProducts",
		"NumberOfPackages");
	ProductDataManagement.EstablishConditionalAppearanceOfSelectionByPropertiesAndCalculationByFormulas(
		ThisForm,
		"Object",
		"RecyclableWaste",
		"NumberOfPackages");
	ProductDataManagement.EstablishConditionalAppearanceOfSelectionByPropertiesAndCalculationByFormulas(
		ThisForm,
		"Object",
		"MaterialsAndServices",
		"NumberOfPackages");
	ProductDataManagement.EstablishConditionalAppearanceOfSelectionByPropertiesAndCalculationByFormulas(
		ThisForm,
		"Object",
		"LaborCosts",
		"Count");
		
	ProductDataManagement.SetConditionalAppearanceForAutoSelectingProducts(ThisForm, "Object", "ManufacturedProducts");
	ProductDataManagement.SetConditionalAppearanceForAutoSelectingProducts(ThisForm, "Object", "RecyclableWaste");
	ProductDataManagement.SetConditionalAppearanceForAutoSelectingProducts(ThisForm, "Object", "MaterialsAndServices");
	
EndProcedure

&AtServer
Procedure FillInServiceDetails()
	
	StructureOfActions = New Structure;
	
	ActionCharacteristics = New Structure("Products", "ItemVariantsAreUsed");
	StructureOfActions.Insert("FillInFeatureAttribute", ActionCharacteristics);
	
	ActionArticle = New Structure("Products", "SKU");
	StructureOfActions.Insert("FillInArticleAttribute", ActionArticle);
	
	ProductsServer.FillInServiceDetailsForProductInCollection(
		Object.ManufacturedProducts, StructureOfActions);
	
	ProductsServer.FillInServiceDetailsForProductInCollection(
		Object.RecyclableWaste, StructureOfActions);
			
	ProductsServer.FillInServiceDetailsForProductInCollection(
		Object.MaterialsAndServices, StructureOfActions);
		
	If UseBillOfMaterialsParameterization Then
		
		ProductDataManagement.FillInServiceDetailsOfAutoSelectionAndCalculationOfNumber(
			Object.ManufacturedProducts,
			True,
			True,
			Object.SelectionByProperties);
		ProductDataManagement.FillInServiceDetailsOfAutoSelectionAndCalculationOfNumber(
			Object.RecyclableWaste,
			True,
			True,
			Object.SelectionByProperties);
		ProductDataManagement.FillInServiceDetailsOfAutoSelectionAndCalculationOfNumber(
			Object.MaterialsAndServices,
			True,
			True,
			Object.SelectionByProperties);
		ProductDataManagement.FillInServiceDetailsOfAutoSelectionAndCalculationOfNumber(
			Object.LaborCosts,
			False,
			True,
			Object.SelectionByProperties);
		
	EndIf;
	
	TotalProductNumber = Object.ManufacturedProducts.Count() + Object.RecyclableWaste.Count();
	
	NumberOfProductsWithCostTypeIsCalculated = Object.ManufacturedProducts.Count();
	
	SourceOfCompositionOfSetsInProduction = ProductDataManagementCached.SourceOfCompositionOfSetsInProduction();
	
EndProcedure

// Performs filling in using a different route map
// 
// Parameters:
// 	Source - CatalogObject.RouteSheets
&AtServer
Procedure FillInFromOperationsSheet(Source)
	
	BeginTransaction();
	
	Try
		
		If ValueIsFilled(Object.Ref) Then
			DeleteRecipientOperations();
		Else
			If Not ValueIsFilled(Object.Description) Then
				Object.Description = Source.Description;
			EndIf;
			Write();
		EndIf;
		ReceiverLink_ = Object.Ref;
		
		If Not Catalogs.RouteSheets.FillInFromOperationsSheet(Object, Source, ReceiverLink_) Then
			Raise NStr("vi = 'Không thể điền vào bản đồ tuyến đường.';
						|ru = 'Не удалось заполнить по маршрутной карте.';
						|en = 'Cannot fill in according to the route sheet.'; fa = 'Cannot fill in according to the route sheet.';
						|it = 'Non è stato possibile compilare secondo la scheda di lavorazione.';
						|pl = 'Nie udało się wypełnić wg karty technologicznej.';
						|tr = 'Rotaya göre doldurulamadı.'");
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
 		WriteLogEvent(
			NStr("vi = 'Điền sơ đồ quy trình';
				|ru = 'Заполнение маршрутной карты';
				|en = 'Route sheet filling'; fa = 'Route sheet filling';
				|it = 'Compilazione della scheda di lavorazione';
				|pl = 'Wypełnianie karty technologicznej';
				|tr = 'Rotanın doldurulması'", CommonClientServer.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			DetailErrorDescription(ErrorInfo()));
			
 		Raise;
		
	EndTry; 
	
EndProcedure

&AtServer
Procedure DeleteRecipientOperations()

	Query = New Query;
	Query.Text = 
	"SELECT
	|	ManufacturingOperations.Ref
	|FROM
	|	Catalog.ManufacturingOperations AS ManufacturingOperations
	|WHERE
	|	ManufacturingOperations.Owner = &Owner
	|	AND NOT ManufacturingOperations.DeletionMark";
	
	Query.SetParameter("Owner", Object.Ref);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		OperationObject = Selection.Ref.GetObject();
		OperationObject.DataExchange.Load = True;
		OperationObject.SetDeletionMark(True);
	EndDo;

EndProcedure

&AtServer
Procedure SetAvailabilityOfItemsByStatusServer()
	
	If ReadOnly Then
		Return;
	EndIf;
	
	AttributeAvailability = (Object.Status = Enums.StatusesOfRouteSheets.UnderDevelopment);
	RouteMapClosed = (Object.Status = Enums.StatusesOfRouteSheets.Closed_);
	
	// Header Controls
	Items.Code.ReadOnly = Not AttributeAvailability;
	Items.ForFinishedProductsKind.ReadOnly = Not AttributeAvailability;
	Items.Department.ReadOnly = Not AttributeAvailability;
	
	// Elements of table parts
	Items.ManufacturedProducts.ReadOnly = Not AttributeAvailability;
	Items.RecyclableWaste.ReadOnly = Not AttributeAvailability;
	Items.MaterialsAndServices.ReadOnly = Not AttributeAvailability;
	Items.LaborCosts.ReadOnly = Not AttributeAvailability;
	
	// Commands
	Items.MaterialsAndServicesOpenMaterialSelection.Enabled = AttributeAvailability;
	Items.FormFillInFromOperationsSheet.Enabled = AttributeAvailability;
	
	// If the route card is closed, then we will make the rest of the details unavailable
	
	Items.ValidOnDate.ReadOnly = RouteMapClosed;
	Items.ValidToDate.ReadOnly = RouteMapClosed;
	Items.EmployeeResponsible.ReadOnly = RouteMapClosed;
	Items.SplitRouteSheets.ReadOnly = RouteMapClosed;
	Items.MaximumNumberOfProductUnitsLots.ReadOnly = RouteMapClosed;
	Items.PreliminaryBuffer.ReadOnly = RouteMapClosed;
	Items.UnitOfMeasureOfPreliminaryBuffer.ReadOnly = RouteMapClosed;
	Items.FollowUpBuffer.ReadOnly = RouteMapClosed;
	Items.UnitOfMeasureOfFollowUpBuffer.ReadOnly = RouteMapClosed;
	
	// Availability of operation list items
	Items.Operations.ChangeRowSet       = AttributeAvailability;
	Items.OperationsGroupAdd.Enabled = AttributeAvailability;
	
	Items.OperationsChangeTheOperationTypeToOperation.Enabled         = AttributeAvailability;
	Items.OperationsChangeTheOperationTypeToANestedRoute.Enabled = AttributeAvailability;
	Items.OperationsContextMenuChangeTheOperationTypeToOperation.Enabled = AttributeAvailability;
	Items.OperationsContextMenuChangeTheOperationTypeToANestedRoute.Enabled = AttributeAvailability;
	
	Items.OperationsMoveTheOperationBack.Enabled   = AttributeAvailability;
	Items.OperationsMoveTheOperationForward.Enabled  = AttributeAvailability;
	
	SetAvailabilityOfClipboardCommands(
		ThisForm,
		ProcessingOfTabularForms.ThereAreLinesInClipboard() And AttributeAvailability);
	
EndProcedure

&AtServer
Function CheckForcedFilling()
	
	Cancel = False;
	
	CatalogObject = FormAttributeToValue("Object");
	CatalogObject.Status = Enums.StatusesOfRouteSheets.Valid;
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, New Array, CatalogObject);
	// End StandardSubsystems.Properties
	
	If Not CatalogObject.CheckFilling() Then
		Cancel = True;
	EndIf;
	
	CatalogObject.CheckNestedRoutes(Cancel);
	
	Return Not Cancel;
	
EndFunction

&AtServer
Procedure SetAvailabilityOfStatusChangeCommands()
	
	Items.SetStatusValid.Enabled   = (Object.Status <> Enums.StatusesOfRouteSheets.Valid);
	Items.SetTheClosedStatus_5.Enabled    = (Object.Status <> Enums.StatusesOfRouteSheets.Closed_);
	Items.SetStatusUnderDevelopment.Enabled = (Object.Status <> Enums.StatusesOfRouteSheets.UnderDevelopment);
	Items.CheckFilling.Enabled         = (Object.Status <> Enums.StatusesOfRouteSheets.Valid);
	Items.ToAdjustTheComposition.Visible               = (Object.Status <> Enums.StatusesOfRouteSheets.Valid);

EndProcedure
 
&AtClient
Procedure SetNewStatusAndRecord(Status)

	If Object.DeletionMark Then
		WarningText = NStr("vi = 'Bạn không thể thay đổi trạng thái của một tuyến đường được đánh dấu để xóa.';
							|ru = 'Нельзя изменить статус помеченной на удаление маршрутной карты.';
							|en = 'Cannot change status of the route sheet marked for deletion.'; fa = 'Cannot change status of the route sheet marked for deletion.';
							|it = 'Non è possibile modificare lo stato di una scheda di lavorazione contrassegnata per la cancellazione.';
							|pl = 'Nie można zmienić statusu karty technologicznej zaznaczonej do usunięcia.';
							|tr = 'Silinmek üzere işaretlenen rotanın durumu değiştirilemez.'");
  		ShowMessageBox(,WarningText);
		Return;
	EndIf; 
	
	ClearMessages();
	
	CurrentStatus = Object.Status;
	
	Object.Status = Status;
	If Not Write() Then
		Object.Status = CurrentStatus;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AvailabilityControl(Form)

	ItemArray = New Array;;
	ItemArray.Add("MaximumNumberOfProductUnitsLots");
	TMCommonUseClientServer.SetPropertyOfFormElements(
								Form.Items, 
								ItemArray, 
								"ReadOnly", 
								Not Form.SplitRouteSheets);
	
EndProcedure

&AtClientAtServerNoContext
Procedure VisibilityManagement(Form, Action = "")
	
	Object = Form.Object;
	Items = Form.Items;
	
	AllActions = IsBlankString(Action);
	
	If AllActions Or Action = "CalculateFactor" Then
		
		DisplayCoefficient = True
			;
		
		Items.GroupApplicationRate.Visible = DisplayCoefficient;
		Items.GroupCoefficientFormula.Visible = DisplayCoefficient And Object.CalculateFactor;
		
	EndIf;
	
	If AllActions Then
		
		VisibilityOfElements = False
			;
		
		Items.TheGroupSplitAndRouteSheets.Visible = VisibilityOfElements;
		Items.GroupPlanningTheOperationOfKeyTypesOfWorkCenters.Visible = VisibilityOfElements;
		Items.ManufacturedProductsCostShare.Visible = VisibilityOfElements;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected)

	If TypeOf(ValueSelected) = Type("Array") Then
		GoodsList = ValueSelected;
	Else
		GoodsList = New Array;
		GoodsList.Add(ValueSelected);
	EndIf;
	
	TSName = "MaterialsAndServices";
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("CheckCharacteristicsByOwner");
	StructureOfActions.Insert("CheckFillPackageByOwner");
	
	ObjectTable = Object[TSName]; // FormDataCollection
	RowsToProcess = New Array();
	
	For Each RowOfProduct In GoodsList Do
		
		CurrentRow = ObjectTable.Add();
		CurrentRow.Products = RowOfProduct;
		
		WhenEnteringNewLineOnRouteMap(ThisObject, TSName, CurrentRow);
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		ObjectTable);

EndProcedure

&AtClient
Procedure HandlerFillInFromOperationsSheet(RouteMapSource, AdditionalParameters) Export

	If RouteMapSource = Undefined Then
		Return;
	EndIf; 
	
	QueryText = NStr("vi = 'Khi điền dữ liệu cũ sẽ bị xóa.
								|Điền?';
								|ru = 'При заполнении прежние данные будут утеряны.
								|Заполнить?';
								|en = 'The previous data will be lost during the population.
								|Populate?'; fa = 'The previous data will be lost during the population.
								|Populate?';
								|it = 'Procedendo con la compilazione i dati precedenti verranno persi.
								|Continuare?';
								|pl = 'Podczas wypełniania poprzednie dane zostaną utracone.
								|Wypełnić?';
								|tr = 'Doldururken önceki veriler kaybolacaktır.
								|Doldurulsun mu?'");
	ButtonsList = New ValueList;
	ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Điền';
												|ru = 'Заполнить';
												|en = 'Fill'; fa = 'پرکردن';
												|it = 'Compilare';
												|pl = 'Fill';
												|tr = 'Doldur'"));
	ButtonsList.Add(DialogReturnCode.Cancel);
	CallbackDescription = New CallbackDescription("FillInQuestionUsingRouteMap", ThisForm, RouteMapSource);
	ShowQueryBox(CallbackDescription, QueryText, ButtonsList,,, NStr("vi = 'Điền theo quy trình';
																	|ru = 'Заполнение по маршрутной карте';
																	|en = 'Fill in according to the route sheet'; fa = 'Fill in according to the route sheet';
																	|it = 'Compilazione secondo la scheda di lavorazione';
																	|pl = 'Wypełnianie wg karty technologicznej';
																	|tr = 'Rotaya göre doldurma'"));

EndProcedure

&AtClient
Procedure FillInQuestionUsingRouteMap(QuestionResult, RouteMapSource) Export

	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	FillInFromOperationsSheet(RouteMapSource);
	
	NotifyChanged(Type("CatalogRef.ManufacturingOperations"));
	
	Notify("Write_ManufacturingOperations");
	
EndProcedure

&AtClient
Procedure QuestionChangeTypeOfOperation(QuestionResult, ContainsNestedRoute) Export

	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	CurrentData = Items.Operations.CurrentData;
	
	If ContainsNestedRoute Then
		NameOfFormToOpen_ = "NestedRouteForm";
	Else
		NameOfFormToOpen_ = "OperationForm";
	EndIf; 
	
	FormParameters = New Structure("Key", CurrentData.Ref);
	OpenForm("Catalog.ManufacturingOperations.Form." + NameOfFormToOpen_, FormParameters);

EndProcedure

&AtClient
Procedure QuestionAddOperation(QuestionResult, AddNestedRoute) Export

	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	If Object.Status = PredefinedValue("Enum.StatusesOfRouteSheets.Valid") Then
		Object.Status = PredefinedValue("Enum.StatusesOfRouteSheets.UnderDevelopment");
	EndIf;
	
	If Write() Then
		
		If AddNestedRoute Then
			AddNestedRoute();
		Else
			Items.Operations.AddRow();
		EndIf; 
	EndIf;

EndProcedure

&AtClient
Procedure AddNestedRoute()

	FormParameters = New Structure;
	FormParameters.Insert("ContainsNestedRoute", True);
	FormParameters.Insert("Owner", Object.Ref);
	OpenForm("Catalog.ManufacturingOperations.ObjectForm", New Structure("FillingValues", FormParameters));

EndProcedure

&AtClient
Procedure SetStatusUnderDevelopmentCompletion(ClosingResult, AdditionalParameters) Export

	If ClosingResult = True Then
		SetNewStatusAndRecord(PredefinedValue("Enum.StatusesOfRouteSheets.UnderDevelopment"));
	EndIf;

EndProcedure

&AtClient
Procedure ProcessFieldSelectionInTable(TableName, FieldName, StandardProcessing)

	If Not ReadOnly And AttributeAvailability Then
		Return;
	EndIf;

	CurrentData = Items[TableName].CurrentData;
	
	If (FieldName = "ManufacturedProductsProducts"
			Or FieldName = "ManufacturedProductsProductsCode"
			Or FieldName = "OutputItemsItemNumber"
			Or FieldName = "MaterialsAndServicesProducts"
			Or FieldName = "MaterialsAndServicesProductsCode"
			Or FieldName = "MaterialsAndServicesSKU")
		And ValueIsFilled(CurrentData.Products)  Then
		
		StandardProcessing = False;
		ShowValue(, CurrentData.Products);
		
	ElsIf (FieldName = "TheOutputProductOperation"
		Or FieldName = "ReturnableWasteOperation"
		Or FieldName = "MaterialsAndServicesOperation"
		Or FieldName = "LaborCostsOperation")
		And ValueIsFilled(CurrentData.OperationEdit) Then
		
		StandardProcessing = False;
		ShowValue(, CurrentData.OperationEdit);
		
	ElsIf (FieldName = "MaterialsAndServicesProductCostElement"
			Or FieldName = "LaborCostsProductCostElement")
		And ValueIsFilled(CurrentData.ProductCostElement)  Then
		
		StandardProcessing = False;
		ShowValue(, CurrentData.ProductCostElement);
		
	ElsIf (FieldName = "LaborCostsWorkKind")
		And ValueIsFilled(CurrentData.WorkKind)  Then
		
		StandardProcessing = False;
		ShowValue(, CurrentData.WorkKind);
		
	EndIf; 
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetBlankMarkForBuffers(Form)

	If Not ValueIsFilled(Form.Object.UnitOfMeasureOfPreliminaryBuffer)
		And Form.Object.PreliminaryBuffer <> 0 Then
		Form.Items.UnitOfMeasureOfPreliminaryBuffer.MarkIncomplete = True;
	Else
		Form.Items.UnitOfMeasureOfPreliminaryBuffer.MarkIncomplete = False;
	EndIf; 	

	If Not ValueIsFilled(Form.Object.UnitOfMeasureOfFollowUpBuffer)
		And Form.Object.FollowUpBuffer <> 0 Then
		Form.Items.UnitOfMeasureOfFollowUpBuffer.MarkIncomplete = True;
	Else
		Form.Items.UnitOfMeasureOfFollowUpBuffer.MarkIncomplete = False;
	EndIf; 	
	
EndProcedure

&AtClient
Procedure ToAdjustTheCompositionCompletion(ClosingResult, AdditionalParameters) Export

	If TypeOf(ClosingResult) <> Type("Structure") Then
		Return;
	EndIf; 
	
	FillPropertyValues(Object, ClosingResult);
	ConfigureRouteMapComposition();
	
EndProcedure

&AtServer
Procedure ConfigureRouteMapComposition()

	Items.Operations.Visible = Object.UseOperations;
	Items.ManufacturedProducts.Visible = Object.UseFinishedProducts;
	Items.RecyclableWaste.Visible = Object.UseFinishedProducts;
	Items.MaterialsAndServices.Visible = Object.UseMaterials;
	Items.LaborCosts.Visible = Object.UseLaborCosts;

	Items.TheOutputProductOperation.Visible = Object.UseOperations;
	Items.ReturnableWasteOperation.Visible = Object.UseOperations;
	Items.MaterialsAndServicesOperation.Visible = Object.UseOperations;
	Items.LaborCostsOperation.Visible = Object.UseOperations;
	
EndProcedure


&AtClient
Procedure WhenChangingCalculateCoefficientNumber()
	
	Object.CalculateFactor = CalculateTheCoefficientNumber;
	
	VisibilityManagement(ThisObject, "CalculateFactor");
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDecryptionCoefficientDenominator(Form)
	
	UnitPresentation = TMCommonUseClientServer.InPlural(
		NStr("vi = 'đơn vị';
			|ru = 'единицу';
			|en = 'unit'; fa = 'واحد';
			|it = 'un''unità';
			|pl = 'jednostkę';
			|tr = 'birimini'"),
		NStr("vi = 'đơn vị tính';
			|ru = 'единицы';
			|en = 'units'; fa = 'واحد';
			|it = 'unità';
			|pl = 'jednostki';
			|tr = 'birimlerini'"),
		NStr("vi = 'đơn vị tính';
			|ru = 'единицы';
			|en = 'units'; fa = 'واحد';
			|it = 'unità';
			|pl = 'jednostki';
			|tr = 'birimlerini'"),
		Form.Object.FactorDenominator);
	
	Form.Items.DecodingTheCoefficientDenominator.Title = StrTemplate(
		NStr("vi = '%1 bảng kê chi tiết các nguồn lực sản xuất sản phẩm chính';
			|ru = '%1 основного изделия спецификации';
			|en = '%1 of main BOM product'; fa = '%1 of main BOM product';
			|it = '%1 del prodotto principale della specifica';
			|pl = '%1 produktu podstawowego specyfikacji';
			|tr = 'ürün reçetesi nihai ana ürün %1'"),
		UnitPresentation);
	
EndProcedure

&AtServer
Procedure FillInThereIsAutomaticSelectionOfNomenclature()
	
	ThereIsProductItemAutoSelection = UseBillOfMaterialsParameterization 
	And (
		ProductDataManagement.ThereIsAutomaticSelectionOfItemsInTable(Object.MaterialsAndServices)
		Or ProductDataManagement.ThereIsAutomaticSelectionOfItemsInTable(Object.RecyclableWaste)
		Or ProductDataManagement.ThereIsAutomaticSelectionOfItemsInTable(Object.ManufacturedProducts)
	);
	
EndProcedure

&AtClient
Procedure QuestionCopyRouteMap(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	Ref = CopyRouteMapOnServer(Object.Ref);
	
	If Ref <> Undefined Then
		
		ProductDataManagementClient.NotifyAboutCopyingRouteMapWithOperations();
		
		OpenForm("Catalog.RouteSheets.ObjectForm", New Structure("Key", Ref));
	
	EndIf; 

EndProcedure
 
&AtServerNoContext
Function CopyRouteMapOnServer(Source)
	
	Return Catalogs.RouteSheets.CopyRouteMapWithOperations(Source);
	
EndFunction

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

#EndRegion

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
