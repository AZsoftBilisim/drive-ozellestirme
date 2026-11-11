
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
	
	If Parameters.Property("Stage", Object.Stage) And ValueIsFilled(Object.Stage) Then
		PresentationStage = Documents.ProductionStage2_2.PresentationStage(Object.Stage);
		Title = StrTemplate("%1 %2", NStr("vi = 'Quy trình công nghệ của công đoạn';
											|ru = 'Технологический процесс этапа';
											|en = 'Technological process of the stage'; fa = 'Technological process of the stage';
											|it = 'Technological process of the stage';
											|pl = 'Technological process of the stage';
											|tr = 'Aşamanın teknolojik süreci'"), PresentationStage);
	Else
		Cancel = True;
		Return;
	EndIf;
	
	If Not Parameters.Property("Mode", Mode) Then
		Mode = ProductionProcessEditorClientServer.ModeFromList();
	EndIf;
	
	Try
		LockDataForEdit(Object.Stage, , UUID);
	Except
		Items.InfoBarLabel.Title =
			StrTemplate(NStr("vi = 'Không thể phong tỏa công đoạn ""%1"", có thể là nó đang được soạn.';
							|ru = 'Не удалось заблокировать этап ""%1"", возможно он в настоящий момент редактируется.';
							|en = 'Cannot lock the ""%1"" stage. It might be locked for editing.'; fa = 'Cannot lock the ""%1"" stage. It might be locked for editing.';
							|it = 'Cannot lock the ""%1"" stage. It might be locked for editing.';
							|pl = 'Cannot lock the ""%1"" stage. It might be locked for editing.';
							|tr = '""%1"" aşaması kilitlenemedi, şu anda düzenleniyor olabilir.'"), PresentationStage);
		ReadOnly = True;
	EndTry;
	
	CreateServiceAttributesOfOperations();
	
	Initialize();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Modified
		And Not Exit Then
		
		StandardProcessing = False;
		Cancel = True;
		
		QueryText = NStr("vi = 'Đã thay đổi dữ liệu. Lưu các thay đổi?';
						|ru = 'Данные были изменены. Сохранить изменения?';
						|en = 'The data has changed. Do you want to save the changes?'; fa = 'The data has changed. Do you want to save the changes?';
						|it = 'I dati sono stati modificati. Salvare le modifiche?';
						|pl = 'Dane zostały zmienione. Chcesz zapisać zmiany?';
						|tr = 'Veriler değiştirildi. Değişiklikler kaydedilsin mi?'");
		CallbackDescription = New CallbackDescription("BeforeCloseCompletion", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNoCancel);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	UnblockLinks = New Array;
	UnblockLinks.Add(Object.Stage);
	For Each ProductionOperation In Cache.ProductionOperations Do
		UnblockLinks.Add(ProductionOperation);
	EndDo;
	UnlockData(UnblockLinks, UUID);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource <> Undefined 
		And ChoiceSource.FormName = "DataProcessor.ProductionProcessEditor.Form.PickOperations" Then
		
		Modified = True;
		AddSelectionOperations(ValueSelected);
		
	ElsIf ChoiceSource <> Undefined
		And ChoiceSource.FormName = "Catalog.ManufacturingOperationClassifier.Form.ListForm" Then
		
		Modified = True;
		ProcessingSelectionOfOperationByClassifier(ValueSelected, Not ChoiceSource.CloseOnChoice);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	TreeOfOperationsConvolution(True);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "CopyingLinesToClipboard" Then
		
		ConfigureDependentFormElements(ThisObject, "Operation"); 
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure InscriptionTechnologicalProcessProcessingOfNavigationLink(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "#OpenTechnologicalProcess" Then
		ShowValue(, Object.TechnologicalProcess);
	EndIf;
	
EndProcedure

&AtClient
Procedure SetupSettingsStartChoice(Item, ChoiceData, StandardProcessing)
	
	CurrentData = Items.Operations.CurrentData;
	If ValueIsFilled(CurrentData.WorkCenter) Then
		
		StandardProcessing = False;
		
		ProductionProcessEditorClient.OpenSetupOptionSelectionForm(
			CurrentData.WorkCenter,
			CurrentData.SetupSettings,
			Item);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ClassifierOfTechnologicalOperationsChoiceProcessing(Item, ValueSelected, AdditionalData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	
	ProcessingSelectionOfOperationByClassifier(ValueSelected);
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure OperationKindOnChange(Item)
	
	OnChangeOfOperation(Item.Name);
	
EndProcedure

&AtClient
Procedure SetupSettingsOnChange(Item)
	
	OnChangeOfOperation(Item.Name);
	
EndProcedure

&AtClient
Procedure LoadOnChange(Item)
	
	OnChangeOfOperation(Item.Name);
	
EndProcedure

&AtClient
Procedure TransferLotOnChange(Item)
	
	CurrentData = Items.Operations.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ProductionProcessEditorClientServer.FillInUnitOfMeasurementOfTransferBatch(
		CurrentData, CurrentData.UnitOfMeasureOfTransferBatch);
	
	OnChangeOfOperation(Item.Name);
	
EndProcedure

&AtClient
Procedure ControlOnChange(Item)
	
	OnChangeOfOperation(Item.Name);
	
EndProcedure

&AtClient
Procedure RepeatableOnChange(Item)
	
	OnChangeOfOperation(Item.Name);
	
EndProcedure

&AtClient
Procedure SkippableOnChange(Item)
	
	OnChangeOfOperation(Item.Name);
	
EndProcedure

&AtClient
Procedure ContinuousOnChange(Item)
	
	OnChangeOfOperation(Item.Name);
	
EndProcedure

&AtClient
Procedure LongDescOnChange(Item)
	
	OnChangeOfOperation(Item.Name);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersOperations

&AtClient
Procedure OperationsOnChange(Item)
	
	OnChangeOfOperation(Item.CurrentItem.Name);
	
EndProcedure

&AtClient
Procedure OperationsOnActivateRow(Item)
	
	CurrentRow = Items.Operations.CurrentRow;
	
	If CurrentRow = CurrentRowID(ThisObject) Then
		Return;
	EndIf;
	
	If CurrentRow = Undefined Then
		ClearTables(ListOfResources(ThisObject));
		Return;
	EndIf;
	
	Cache.RowActivation = True;
	
	AttachIdleHandler("Attachable_OperationsOnActivateRow", 0.1, True);
	
EndProcedure

&AtClient
Procedure OperationsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Item.ReadOnly Then
	
		StandardProcessing = False;
		
		CurrentData = Item.CurrentData;
		If CurrentData <> Undefined Then
			If Field.Name = "Description" And ValueIsFilled(CurrentData.Operation) Then
				ShowValue(, CurrentData.Operation);
			ElsIf Field.Name = "WorkCenter" And ValueIsFilled(CurrentData.WorkCenter) Then
				ShowValue(, CurrentData.WorkCenter);
			ElsIf Field.Name = "TechnologicalProcess" And ValueIsFilled(CurrentData.TechnologicalProcess) Then
				ShowValue(, CurrentData.TechnologicalProcess);
			EndIf;
		EndIf;
	
	EndIf;
	
EndProcedure

&AtClient
Procedure OperationsBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	
	Cancel = True;
	
	OperationsAddNew(Copy);
	
EndProcedure

&AtClient
Procedure OperationsBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
	SelectedRows = Items.Operations.SelectedRows;
	
	If CheckAbilityToEditOperations(SelectedRows, "All") Then
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("RowsIDs", CommonClient.CopyRecursive(SelectedRows));
		
		If SelectedRows.Count() = 1 Then
			RowData = Operations.FindByID(SelectedRows[0]);
			QueryText = StrTemplate(NStr("vi = 'Xóa giao dịch ""%1""?';
										|ru = 'Удалить операцию ""%1""?';
										|en = 'Delete the ""%1"" operation?'; fa = 'Delete the ""%1"" operation?';
										|it = 'Delete the ""%1"" operation?';
										|pl = 'Delete the ""%1"" operation?';
										|tr = '""%1"" işlemi silinsin mi?'"), RowData.Description);
		Else
			QueryText = NStr("vi = 'Xóa các giao dịch được chọn?';
							|ru = 'Удалить выделенные операции?';
							|en = 'Delete the selected operations?'; fa = 'Delete the selected operations?';
							|it = 'Delete the selected operations?';
							|pl = 'Delete the selected operations?';
							|tr = 'Seçilen işlemler silinsin mi?'");
		EndIf;
		
		CallbackDescription = New CallbackDescription("OperationsBeforeDeleteRowCompletion", ThisObject, AdditionalParameters);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OperationsBeforeRowChange(Item, Cancel)
	
	If Cache.RowActivation Then
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure OperationsDragCheck(Item, DragParameters, StandardProcessing, String, Field)
	
	StandardProcessing = False;
	
	If String = Undefined Then
		DragParameters.Action = DragAction.Cancel;
		Return;
	EndIf;
	
	If String = Items.Operations.CurrentRow Then
		DragParameters.Action = DragAction.Cancel;
		Return;
	EndIf;
	
	RowData = Operations.FindByID(String);
	If RowData = Undefined
		Or RowData.ReadOnly
		Or ThisIsGroupOfIndividualOperations(RowData) Then
		DragParameters.Action = DragAction.Cancel;
		Return;
	EndIf;
	
	Value = DragParameters.Value;
	
	If Not TypeOf(Value) = Type("Structure") Then
		DragParameters.Action = DragAction.Cancel;
		Return;
	EndIf;
	
	Value.Insert("ReceiverId", String);
	
EndProcedure

&AtClient
Procedure OperationsDrag(Item, DragParameters, StandardProcessing, String, Field)
	
	StandardProcessing = False;
	
	If String = Undefined
		Or Not TypeOf(DragParameters.Value) = Type("Structure") Then
		Return;
	EndIf;
	
	Drag(String(DragParameters.Action), DragParameters.Value);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersManufacturedProducts

&AtClient
Procedure ManufacturedProductsAfterDeleteRow(Item)
	
	OnChangeOfOperation(Item.Name);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsOnEditEnd(Item, NewRow, CancelEdit)
	
	If Not CancelEdit Then
		OnChangeOfOperation(Item.Name);
	EndIf;
	
EndProcedure

&AtClient
Procedure ManufacturedProductsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Item.ReadOnly Then
	
		StandardProcessing = False;
		
		CurrentData = Item.CurrentData;
		If CurrentData <> Undefined Then
			If Field.Name = "ManufacturedProductsProducts" And ValueIsFilled(CurrentData.Products) Then
				ShowValue(, CurrentData.Products);
			ElsIf Field.Name = "ManufacturedProductsCharacteristic" And ValueIsFilled(CurrentData.Characteristic) Then
				ShowValue(, CurrentData.Characteristic);
			EndIf;
		EndIf;
	
	EndIf;
	
EndProcedure

&AtClient
Procedure ManufacturedProductsProductsOnChange(Item)
	
	ProductsWhenChangedOnServer("ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure ManufacturedProductsNumberOfPackagesOnChange(Item)
	
	WhenChangingNumberOfPackages("ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure ManufacturedProductsPackageOnChange(Item)
	
	WhenChangingNumberOfPackages("ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure ManufacturedProductsDragStart(Item, DragParameters, Perform)
	
	DragStart(Item.Name, DragParameters, Perform);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersMaterialsAndServices

&AtClient
Procedure MaterialsAndServicesAfterDeleteRow(Item)
	
	OnChangeOfOperation(Item.Name);
	
EndProcedure

&AtClient
Procedure MaterialsAndServicesOnEditEnd(Item, NewRow, CancelEdit)
	
	If Not CancelEdit Then
		OnChangeOfOperation(Item.Name);
	EndIf;
	
EndProcedure

&AtClient
Procedure MaterialsAndServicesSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Item.ReadOnly Then
	
		StandardProcessing = False;
		
		CurrentData = Item.CurrentData;
		If CurrentData <> Undefined Then
			If Field.Name = "MaterialsAndServicesProducts" And ValueIsFilled(CurrentData.Products) Then
				ShowValue(, CurrentData.Products);
			ElsIf Field.Name = "MaterialsAndServicesCharacteristic" And ValueIsFilled(CurrentData.Characteristic) Then
				ShowValue(, CurrentData.Characteristic);
			EndIf;
		EndIf;
	
	EndIf;
	
EndProcedure

&AtClient
Procedure MaterialsAndServicesProductsOnChange(Item)
	
	ProductsWhenChangedOnServer("MaterialsAndServices");
	
EndProcedure

&AtClient
Procedure MaterialsAndServicesNumberOfPackagesOnChange(Item)
	
	WhenChangingNumberOfPackages("MaterialsAndServices");
	
EndProcedure

&AtClient
Procedure MaterialsAndServicesPackageOnChange(Item)
	
	WhenChangingNumberOfPackages("MaterialsAndServices");
	
EndProcedure

&AtClient
Procedure MaterialsAndServicesDragStart(Item, DragParameters, Perform)
	
	DragStart(Item.Name, DragParameters, Perform);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersLaborCosts

&AtClient
Procedure LaborCostsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Item.ReadOnly Then
	
		StandardProcessing = False;
		
		CurrentData = Item.CurrentData;
		If CurrentData <> Undefined Then
			If Field.Name = "LaborCostsWorkKind" And ValueIsFilled(CurrentData.WorkKind) Then
				ShowValue(, CurrentData.WorkKind);
			EndIf;
		EndIf;
	
	EndIf;
	
EndProcedure

&AtClient
Procedure LaborCostsAfterDeleteRow(Item)
	
	OnChangeOfOperation(Item.Name);
	
EndProcedure

&AtClient
Procedure LaborCostsOnEditEnd(Item, NewRow, CancelEdit)
	
	If Not CancelEdit Then
		OnChangeOfOperation(Item.Name);
	EndIf;
	
EndProcedure

&AtClient
Procedure LaborCostsDragStart(Item, DragParameters, Perform)
	
	DragStart(Item.Name, DragParameters, Perform);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteAndClose(Command)
	
	CompleteEditing();
	
EndProcedure

&AtClient
Procedure ReplaceWithAlternative(Command)
	
	SelectTechnologicalProcess(New CallbackDescription("ReplaceWithAlternativeCompletion", ThisObject));
	
EndProcedure

&AtClient
Procedure ReplaceWithStandard(Command)
	
	TechProcessParameters = ProductionProcessEditorServerCall.StandardStageProcessTechnology(Object.Stage);
	
	QueryText = NStr("vi = 'Sẽ thay thế sang quy trình công nghệ tiêu chuẩn của công đoạn. Tiếp tục?';
					|ru = 'Будет выполнена замена на стандартный технологический процесс этапа. Продолжить?';
					|en = 'The technological process will be replaced with the standard technological process of the stage. Continue?'; fa = 'The technological process will be replaced with the standard technological process of the stage. Continue?';
					|it = 'The technological process will be replaced with the standard technological process of the stage. Continue?';
					|pl = 'The technological process will be replaced with the standard technological process of the stage. Continue?';
					|tr = 'Aşamanın standart teknolojik süreci ile değiştirilecektir. Devam edilsin mi?'");
	
	ShowQueryBox(
		New CallbackDescription("ReplaceWithProcessEnd", ThisObject, TechProcessParameters),
		QueryText,
		QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure ReplaceItWithIndividualOne(Command)
	
	ReplaceWithIndividualOneAtServer();
	
EndProcedure

&AtClient
Procedure CreateTypicalTechnicalProcess(Command)
	
	ClearMessages();
	
	DataForCreatingTechnicalProcess = PrepareDataForCreatingTypicalProcessTechnology();
	
	If Not DataForCreatingTechnicalProcess.TechnicalProcessCheckHasBeenCompleted Then
		
		Return;
		
	Else
		
		QueryText = NStr("vi = 'Sẽ tạo và ghi lại quy trình công nghệ mới. Tiếp tục?';
						|ru = 'Будет создан и записан новый технологический процесс. Продолжить?';
						|en = 'A new technological process will be created and saved. Continue?'; fa = 'A new technological process will be created and saved. Continue?';
						|it = 'A new technological process will be created and saved. Continue?';
						|pl = 'A new technological process will be created and saved. Continue?';
						|tr = 'Yeni teknolojik süreç oluşturulacak ve kaydedilecek. Devam edilsin mi?'");
		
		CallbackDescription = New CallbackDescription(
			"QuestionCreateTypicalProcessEnd", ThisObject, DataForCreatingTechnicalProcess);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo); 
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeFactor(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("BillOfMaterials", Object.BillOfMaterials);
	FormParameters.Insert("TechnologicalProcess", Object.TechnologicalProcess);
	FormParameters.Insert("TechnologicalProcessFactor", Object.TechnologicalProcessFactor);
	FormParameters.Insert("CountPlan", Object.Count);
	FormParameters.Insert("ReadOnly", ReadOnly);
	
	OpenForm("DataProcessor.ProductionProcessEditor.Form.ChangeFactor",
		FormParameters,
		ThisObject,,,,
		New CallbackDescription("ChangeFactorCompletion", ThisObject));
	
EndProcedure

&AtClient
Procedure Reread(Command)
	
	If Modified Then
		
		QueryText = NStr("vi = 'Sẽ mất những thay đổi đưa vào. Tiếp tục?';
						|ru = 'Внесенные изменения будут потеряны. Продолжить?';
						|en = 'Changes will be lost. Continue?'; fa = 'Changes will be lost. Continue?';
						|it = 'Modifiche apportate saranno perse. Continuare?';
						|pl = 'Wprowadzone zmiany zostaną utracone. Kontynuować?';
						|tr = 'Girilen düzenlemeler kaybedilecek. Devam edilsin mi?'");
		
		CallbackDescription = New CallbackDescription("QuestionReReadEnd", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		
	Else
		
		Initialize();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OperationsMoveUp(Command)
	
	ShiftOfOperations(Items.Operations.SelectedRows, Command.Name);
	
EndProcedure

&AtClient
Procedure OperationsMoveDown(Command)
	
	ShiftOfOperations(Items.Operations.SelectedRows, Command.Name);
	
EndProcedure

&AtClient
Procedure SelectionOperations(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("Department", Object.Department);
	FormParameters.Insert("UnitViewOnly");
	
	If StoreOperationsInBillsOfMaterials Then
		FormParameters.Insert("CatalogName", "Catalog.TechnologicalProcesses");
		FormParameters.Insert("Status", PredefinedValue("Enum.TechnologicalProcessStatuses.Valid"));
	Else
		FormParameters.Insert("CatalogName", "Catalog.RouteSheets");
		FormParameters.Insert("Status", PredefinedValue("Enum.StatusesOfRouteSheets.Valid")); 
	EndIf;
	
	OpenForm("DataProcessor.ProductionProcessEditor.Form.PickOperations",
		FormParameters,
		ThisObject);
	
EndProcedure

&AtClient
Procedure OperationsSelectionByWHO(Command)
	
	ProductionProcessEditorClient.OpenFormForSelectingOperationsByClassifier(
		ThisObject,,
		False);
	
EndProcedure

&AtClient
Procedure OperationsToDeleteNonCompressed(Command)
	
	IDs = New Array;
	
	RowData = Undefined;
	While NextRow(ThisObject, RowData) Do
		If Not RowData.ReadOnly Then
			IDs.Add(RowData.GetID());
		EndIf;
	EndDo;
	
	If IDs.Count() = 0 Then
		ShowMessageBox(,NStr("vi = 'Không có giao dịch nào chưa bắt đầu mà có thể bị xóa.';
							|ru = 'Нет неначатых операций, которые можно удалить.';
							|en = 'There are no unstarted operations that can be deleted.'; fa = 'There are no unstarted operations that can be deleted.';
							|it = 'There are no unstarted operations that can be deleted.';
							|pl = 'There are no unstarted operations that can be deleted.';
							|tr = 'Silinebilecek başlatılmamış işlem yoktur.'"));
	Else
		AdditionalParameters = New Structure("RowsIDs", IDs);
		CallbackDescription = New CallbackDescription("DeleteOperationsCompletion", ThisObject, AdditionalParameters);
		ShowQueryBox(CallbackDescription, NStr("vi = 'Sẽ xóa tất cả các giao dịch chưa bắt đầu. Tiếp tục?';
												|ru = 'Будут удалены все неначатые операции. Продолжить?';
												|en = 'All unstarted operations will be deleted. Continue?'; fa = 'All unstarted operations will be deleted. Continue?';
												|it = 'All unstarted operations will be deleted. Continue?';
												|pl = 'All unstarted operations will be deleted. Continue?';
												|tr = 'Başlatılmamış tüm işlemler silinecektir. Devam edilsin mi?'"), QuestionDialogMode.YesNo);
	EndIf;
	
EndProcedure

&AtClient
Procedure DeleteOperationsFromSelected(Command)
	
	CurrentRow = Items.Operations.CurrentRow;
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	IDs = New Array;
	
	RowData = Undefined;
	While NextRow(ThisObject, RowData,,False) Do
		Id = RowData.GetID();
		If Id = CurrentRow Or IDs.Count() > 0 Then
			IDs.Add(Id);
		EndIf;
	EndDo;
	
	If CheckAbilityToEditOperations(IDs, "All") Then
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("RowsIDs", IDs);
		
		QueryText = StrTemplate(NStr("vi = 'Sẽ xóa tất cả các giao dịch bắt đầu từ ""%1"". Tiếp tục?';
									|ru = 'Будут удалены все операции, начиная с ""%1"". Продолжить?';
									|en = 'All operations starting from ""%1"" will be deleted. Continue?'; fa = 'All operations starting from ""%1"" will be deleted. Continue?';
									|it = 'All operations starting from ""%1"" will be deleted. Continue?';
									|pl = 'All operations starting from ""%1"" will be deleted. Continue?';
									|tr = '""%1"" ile başlayan tüm işlemler silinecektir. Devam edilsin mi?'"),
			Items.Operations.CurrentData.Description);
			
		CallbackDescription = New CallbackDescription("DeleteOperationsCompletion", ThisObject, AdditionalParameters);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure RenumberOperations(Command)
	
	SelectedRows = Items.Operations.SelectedRows;
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	If CheckAbilityToEditOperations(SelectedRows, "All") Then

		RowIndexes = IndexesOfOperations(ThisObject, SelectedRows);
		RowIndexes.SortByPresentation();
		
		If RowIndexes.Count() = 0 And SelectedRows.Count() > 0 Then
			ShowMessageBox(, NStr("vi = 'Cần chọn dòng thuộc lớp trên cùng.';
									|ru = 'Необходимо выделить строки верхнего уровня.';
									|en = 'Select the top-level lines.'; fa = 'Select the top-level lines.';
									|it = 'Select the top-level lines.';
									|pl = 'Select the top-level lines.';
									|tr = 'Üst seviye satırların seçilmesi gerekmektedir.'"));
			Return;
		EndIf;
		
		For IndexOf = 0 To RowIndexes.Count()-1 Do
			If Number(RowIndexes[0].Presentation)+IndexOf <> Number(RowIndexes[IndexOf].Presentation) Then
				ShowMessageBox(, NStr("vi = 'Các dòng được chọn phải được sắp xếp liên tiếp.';
										|ru = 'Выделенные строки должны располагаться последовательно.';
										|en = 'The selected lines must be placed sequentially.'; fa = 'The selected lines must be placed sequentially.';
										|it = 'The selected lines must be placed sequentially.';
										|pl = 'The selected lines must be placed sequentially.';
										|tr = 'Seçilen satırlar sırayla yerleştirilmelidir.'"));
				Return;
			EndIf;
		EndDo;
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("RowIndexes", RowIndexes);
		
		ShowInputNumber(New CallbackDescription("RenumberOperationsCompletion", ThisObject, AdditionalParameters),
			Operations.FindByID(RowIndexes[0].Value).OperationNumber,
			NStr("vi = 'Hãy nhập số ban đầu';
				|ru = 'Введите начальный номер';
				|en = 'Enter the initial number'; fa = 'Enter the initial number';
				|it = 'Enter the initial number';
				|pl = 'Enter the initial number';
				|tr = 'Başlangıç numarasını girin'"), 5, 0);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DivideOperations(Command)
		
	SelectedRows = Items.Operations.SelectedRows;
	If SelectedRows.Count() = 0 Then
		Return;
	ElsIf SelectedRows.Count() > 1 Then
		ShowMessageBox(, NStr("vi = 'Lệnh không thể được thực thi cho nhiều dòng.';
								|ru = 'Команда не может быть выполнена для нескольких строк.';
								|en = 'Command cannot be executed for multiple lines.'; fa = 'Command cannot be executed for multiple lines.';
								|it = 'Il comando non può essere eseguito per alcune righe.';
								|pl = 'Polecenie nie może być wykonane dla kilku wierszy.';
								|tr = 'Birden fazla satır için komut gerçekleştirilemez.'"));
		Return;
	EndIf;
	
	If CheckAbilityToEditOperations(SelectedRows, "Detailed") Then
		
		RowID = SelectedRows[0];
		RowData = Operations.FindByID(RowID);
		
		Notification = New CallbackDescription("DivideOperationsCompletion",
			ThisObject,
			New Structure("RowID", RowID));
		
		FormParameters = StringTreeStructureConstructor(ThisObject);
		FillPropertyValues(FormParameters, RowData,,"Count");
		FormParameters.Insert("Count", RowData.Required2);
		FormParameters.Insert("Department", Object.Department);
		
		OpenForm("DataProcessor.ProductionProcessEditor.Form.SplitOperation",
			FormParameters, ThisObject,,,, Notification);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CollapseTreeOperations(Command)
	
	TreeOfOperationsConvolution(True);
	
EndProcedure

&AtClient
Procedure ExpandTreeOperations(Command)
	
	TreeOfOperationsConvolution(False);
	
EndProcedure

&AtClient
Procedure SetNumberOfOperations(Command)
	
	SelectedRows = Items.Operations.SelectedRows;
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	If CheckAbilityToEditOperations(SelectedRows, "All") Then
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("RowsIDs", CommonClient.CopyRecursive(SelectedRows));
		
		ShowInputNumber(New CallbackDescription("SetNumberOfEnds", ThisObject, AdditionalParameters),
			Operations.FindByID(SelectedRows[0]).Required2,
			NStr("vi = 'Nhập số lượng';
				|ru = 'Введите новое количество';
				|en = 'Enter the new quantity'; fa = 'Enter the new quantity';
				|it = 'Enter the new quantity';
				|pl = 'Enter the new quantity';
				|tr = 'Yeni miktarı girin'"), 10, 3);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure MaterialsAndServicesFillOutTheCalculationArticle(Command)
	
	FillInCalculationArticleInLines("MaterialsAndServices");
	
EndProcedure

&AtClient
Procedure LaborCostsFillInTheCalculationArticle(Command)
	
	FillInCalculationArticleInLines("LaborCosts");
	
EndProcedure

&AtClient
Procedure ManufacturedProducts_CopyLines(Command)
	
	CopyTSLines("ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure ManufacturedProducts_InsertRows(Command)
	
	GetLinesFromClipboard("ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure MaterialsAndServicesCopyLines(Command)
	
	CopyTSLines("MaterialsAndServices");
	
EndProcedure

&AtClient
Procedure MaterialsAndServicesInsertLines(Command)
	
	GetLinesFromClipboard("MaterialsAndServices");
	
EndProcedure

&AtClient
Procedure TheEffortToCopyRows(Command)
	
	CopyTSLines("LaborCosts");
	
EndProcedure

&AtClient
Procedure LaborCostsInsertLines(Command)
	
	GetLinesFromClipboard("LaborCosts");
	
EndProcedure

#EndRegion

#Region Private

#Region WorkWithProcessTechnology

&AtServer
Procedure FillInProcessData(Initialize = False)
	
	ClearTables();
	
	BasedOnQueue = Initialize
		And (ThisIsIndividualTechnicalProcess(Object)
			Or ProductionManagementClientServer.StatusesAvailableByOperationalManagement(
				DivisionParameters, False).Find(Object.Status) <> Undefined);
	
	If BasedOnQueue Then
		
		RequestTextParameters = InformationRegisters.QueueOfProductionOperations.RequestTextParametersQueueOfOperations();
		RequestTextParameters.ExecutionIndicators = True;
		RequestTextParameters.AttributesOfContractorOfOperation = True;
		RequestTextParameters.AttributesForCalculatingTimeOfOperation = True;
		RequestTextParameters.ExtendedAttributesOfOperations = True;
		RequestTextParameters.SelectionFields1 = AdditionalFieldsOfOperationsQueue();
		RequestTextParameters.OutputTableName = "TTQueue";
		RequestTextParameters.Filters.Add("Queue.Stage = &Stage");
		
		QueryText = InformationRegisters.QueueOfProductionOperations.QueryTextOperationQueue(RequestTextParameters) + "
		|
		|;
		|
		|SELECT
		|	TTQueue.*,
		|	TTQueue.Load                                                                            AS LoadStandard,
		|	States1.Ref                                                                              AS State,
		|	ISNULL(TTQueue.Operation.LongDesc, TTQueue.ProductionOperation.Comment)         AS LongDesc,
		|	TRUE IN (SELECT TOP 1
		|				TRUE
		|			FROM
		|				InformationRegister.OperationsToCreateShiftTasks AS Assigned
		|			WHERE
		|				Assigned.Stage = &Stage
		|				AND TTQueue.Operation = Assigned.Operation
		|				AND TTQueue.OperationID = Assigned.OperationID
		|				AND NOT Assigned.ShiftTask = VALUE(Document.ShiftTask.EmptyRef)) AS Assigned_
		|FROM
		|	TTQueue AS TTQueue
		|
		|	LEFT JOIN Enum.OperationStates AS States1
		|	ON TTQueue.StateOfOrder = States1.Order
		|
		|ORDER BY
		|	OperationNumber,
		|	Description
		|
		|";
		
		Query = New Query;
		Query.TempTablesManager = New TempTablesManager();
		Query.Text = QueryText;
		Query.SetParameter("Stage", Object.Stage);
		
		TransactionList = Operations.GetItems();
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			NewRow = TransactionList.Add();
			FillPropertyValues(NewRow, Selection);
			NewRow.ExecutionIndicators = ExecutionIndicators(Selection);
			If ThisOperationIsIndividual(NewRow) Then
				ProductionOperations = Cache.ProductionOperations; // Array
				ProductionOperations.Add(NewRow.ProductionOperation);
				Try
					LockDataForEdit(NewRow.ProductionOperation, , UUID);
				Except
					NewRow.ReadOnly = True;
				EndTry;
			EndIf;
		EndDo;
		
	Else
		
		SaveResourceCache(Undefined);
		
		AddProcessOperations();
		
	EndIf;
	
	ResourceTable.Clear();
	FillInServiceAttributesOfLinesOfOperationsATServer();
	
	TreeSortGroup(ThisObject);
	
EndProcedure

&AtClient
Procedure ReplaceWithAlternativeCompletion(Result, AdditionalParameters) Export
	
	If ValueIsFilled(Result) Then
		
		TechProcessParameters = ProductionProcessEditorClientServer.ProcessParametersConstructor();
		TechProcessParameters.TechnologicalProcessType         = AlternativeProcessTechnology();
		TechProcessParameters.TechnologicalProcess              = Result;
		TechProcessParameters.TechnologicalProcessFactor = Object.Count;
		
		FormParameters = New Structure;
		FormParameters.Insert("BillOfMaterials",         Object.BillOfMaterials);
		FormParameters.Insert("CountPlan",       Object.Count);
		FormParameters.Insert("TechProcessParameters", TechProcessParameters);
		
		OpenForm("DataProcessor.ProductionProcessEditor.Form.ReplaceTechnologicalProcess",
			FormParameters,
			ThisObject,,,,
			New CallbackDescription("ReplaceWithProcessEnd", ThisObject, TechProcessParameters));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ReplaceWithProcessEnd(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		
		If TypeOf(Result) = Type("Structure") Then
			TechProcessParameters = Result;
		Else
			TechProcessParameters = AdditionalParameters;
		EndIf;
		
		FillPropertyValues(Object, TechProcessParameters);
		Object.SaveTechnologicalProcessLimitations = False;
		
		FillInProcessData();
		
		Modified = True;
		
		ConfigureDependentFormElements(ThisObject);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeFactorCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined
			And Object.TechnologicalProcessFactor <> Result Then
		
		Object.TechnologicalProcessFactor = Result;
		
		FillInProcessData();
		
		Modified = True;
		
		ConfigureDependentFormElements(ThisObject, "TechnologicalProcess");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectTechnologicalProcess(CallbackDescription)
	
	ItemKinds = New Array;
	ItemKinds.Add(Object.ProductKind);
	ItemKinds.Add(PredefinedValue("Catalog.ItemKinds.EmptyRef"));
	
	Filter = New Structure;
	Filter.Insert("Department",  Object.Department);
	Filter.Insert("ForFinishedProductsKind", ItemKinds);
	
	If StoreOperationsInBillsOfMaterials Then
		ChoiceFormName = "Catalog.TechnologicalProcesses.ChoiceForm";
		Filter.Insert("Status", PredefinedValue("Enum.TechnologicalProcessStatuses.Valid"));
	Else
		ChoiceFormName = "Catalog.RouteSheets.ChoiceForm";
		Filter.Insert("Status", PredefinedValue("Enum.StatusesOfRouteSheets.Valid")); 
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("ChoiceMode", True);
	FormParameters.Insert("Filter", Filter);
	FormParameters.Insert("DisableSelection", Object.TechnologicalProcess);
	FormParameters.Insert("UnitViewOnly");
	FormParameters.Insert("ForTypeOfProductsOnlyViewing");
	FormParameters.Insert("StatusViewOnly");
	
	OpenForm(ChoiceFormName,
		FormParameters,
		ThisObject,,,,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtServer
Function AdditionalFieldsOfOperationsQueue()
	
	Result = New Array;
	
	Field = "
	|MIN(CASE
	|		WHEN ISNULL(Queue.ProductionOperation.RepetitionIsRequired, FALSE) = TRUE
	|			THEN 10
	|		ELSE
	|			Queue.State.Order
	|	END) AS StateOfOrder
	|";
	
	Result.Add(Field);
	
	Return Result;
	
EndFunction

&AtServer
Function CheckCompletionOfTechnicalProcess(Mode = "RecordingTechnicalProcess")
	
	Cancel = False;
	Messages = New Array;
	TransactionMetadata = Metadata.Documents.ProductionOperation2_2;
	OrderCheckTable = ProductionProcessEditor.TableOfVerificationOfOrderOfElementsOfProductionProcessDesigner();
	DataProcessor = DataProcessors.ProductionProcessEditor.Create();
	ThereAreEditableLines = False;
	ControlOfAttributes = Undefined;
	
	SaveDataOfCurrentOperation();
	
	ResourcesCache = GetCacheOfResources();
	
	RowData = Undefined; // FormDataTreeItem
	While NextRow(ThisObject, RowData) Do
		
		AddOperationToOrderCheckTable(OrderCheckTable, RowData);
		
		If ThisIsGroupOfIndividualOperations(RowData) Then
			
			ControlOfAttributes = ControlledAttributesOfOperationsInGroup();
			
		Else
			
			CheckFillingInAttributesOfOperationHeaderOfOperation(RowData, Cancel);
			
			StructureOfData = OperationResourceStorageStructure(RowData, ResourcesCache);
			If StructureOfData <> Undefined Then
				
				For Each TSName In ListOfResources(ThisObject, True) Do
					DataProcessor[TSName].Load(StructureOfData[TSName]);
				EndDo;
				
				CheckFillingOfTableParts(DataProcessor, RowData, Cancel);
				
			EndIf;
			
			BindMessagesToUserOfOperation(Messages, RowData);
			
			If ThisIsIndividualOperationInGroup(RowData) And ControlOfAttributes <> Undefined Then
				GroupOfOperations = RowData.GetParent();
				For Each KeyAndValue In ControlOfAttributes Do
					AttributeName = KeyAndValue.Key;
					If KeyAndValue.Value = Undefined Then
						ControlOfAttributes[AttributeName] = RowData[AttributeName];
					ElsIf ControlOfAttributes[AttributeName] <> RowData[AttributeName] Then
						MessageText = StrTemplate(NStr("vi = 'Các giá trị của mục tin ""%1"" trong các giao dịch của nhóm';
														|ru = 'Различаются значения реквизита ""%1"" в операциях группы';
														|en = 'Values of the ""%1"" attribute differ in the group operations'; fa = 'Values of the ""%1"" attribute differ in the group operations';
														|it = 'Values of the ""%1"" attribute differ in the group operations';
														|pl = 'Values of the ""%1"" attribute differ in the group operations';
														|tr = 'Grup işlemlerindeki ""%1"" özniteliğinin değerleri farklıdır'"),
							TransactionMetadata.Attributes[AttributeName].Synonym);
						Common.MessageToUser(MessageText,,,,Cancel);
						ControlOfAttributes.Delete(AttributeName);
					EndIf;
				EndDo;
				BindMessagesToUserOfOperation(Messages, GroupOfOperations);
			EndIf;
			
		EndIf;
		
		ThereAreEditableLines = ThereAreEditableLines Or Not RowData.ReadOnly;
		
	EndDo;
	
	If Not Object.SaveTechnologicalProcessLimitations And ThereAreEditableLines Then
		
		StructureOfChecks = ProductionProcessEditor.StructureOfOperationSequenceChecks(, DivisionParameters);
		
		If Mode = "CreatingTechnicalProcess"
			And StructureOfChecks.Property("ControlOperations") Then
			StructureOfChecks.ControlOperations.Delete("ControlIndividualOfOperationsInSequence");
		EndIf;
		
		ProductionProcessEditor.CheckOrderOfProductionProcessElements(
			OrderCheckTable,
			StructureOfChecks,
			Cancel,
			Messages);
	EndIf;
	
	For Each Message In Messages Do
		Common.MessageToUser(Message.Text);
	EndDo;
	
	Return Not Cancel;
	
EndFunction

&AtServer
Procedure CheckFillingInAttributesOfOperationHeaderOfOperation(RowData, Cancel)
	
	OwnerOfOperation = ?(
		ValueIsFilled(Object.BOMStage), Object.BOMStage, Catalogs.ProductionStages.GetRef());
	
	OperationObject = Catalogs.ManufacturingOperations.CreateItem();
	OperationObject.Owner = OwnerOfOperation;
	FillPropertyValues(OperationObject, RowData);
	
	If Not OperationObject.CheckFilling() Then
		Cancel = True;
	EndIf;
	
	ProductionProcessEditor.CheckFillingOfOperationWorkCenters(OperationObject, Object.Department, Undefined, Cancel);
	
	ProductionProcessEditor.CheckCorrectnessOfOperationControlOption(OperationObject, DivisionParameters, Undefined, Cancel);
	
	If ThisOperationIsIndividual(RowData) Then
		
		CheckedAttributes = VerifiableAttributesOfOperationHeaderOfOperation();
		
		For Each AttributeName In CheckedAttributes Do
			If Not ValueIsFilled(RowData[AttributeName]) Then
				MessageText = StrTemplate(NStr("vi = 'Chưa điền trường ""%1""';
												|ru = 'Поле ""%1"" не заполнено';
												|en = '""%1"" is required'; fa = '""%1"" is required';
												|it = 'Il campo ""%1"" non è compilato';
												|pl = 'Pole ""%1"" nie jest wypełnione';
												|tr = '""%1"" alanı doldurulmamış'"), Items[AttributeName].Title);
				Common.MessageToUser(MessageText,,,,Cancel);
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function VerifiableAttributesOfOperationHeaderOfOperation()
	
	Result = New Array;
	
	Result.Add("Required2");
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function ControlledAttributesOfOperationsInGroup()
	
	Result = New Structure;
	
	Result.Insert("CLASSIFIEROFTECHNOLOGICALOPERATIONS");
	Result.Insert("OperationKind");
	Result.Insert("Control");
	
	Return Result;
	
EndFunction

&AtServer
Procedure CheckFillingOfTableParts(DataProcessor, RowData, Cancel)
	
	MessageTemplate = NStr("vi = 'Chưa điền cột ""%1"" tại dòng %2 trong danh sách ""%3""';
							|ru = 'Не заполнена колонка ""%1"" в строке %2 списка ""%3""';
							|en = 'Column ""%1"" in line #%2, list ""%3"" cannot be empty.'; fa = 'Column ""%1"" in line #%2, list ""%3"" cannot be empty.';
							|it = 'La colonna ""%1"" nella riga %2 dell''elenco ""%3"" non è compilata';
							|pl = 'Nie wypełniono kolumny ""%1"" w wierszu %2 listy ""%3""';
							|tr = 'Sütun ""%1"", ""%3"" listesinin %2satırında doldurulmamış'");
	
	TSMetadata = Metadata.DataProcessors.ProductionProcessEditor.TabularSections;
	
	ListOfResources = ListOfResources(ThisObject, True);
	For IndexOf = 0 To ListOfResources.Count() - 1 Do
		TSName = ListOfResources[IndexOf];
		For RowIndex = 0 To DataProcessor[TSName].Count() - 1 Do
			String = DataProcessor[TSName][RowIndex];
			For Each AttributeName In ListOfResourcesCheckFilling(TSName, RowData) Do
				If Not ValueIsFilled(String[AttributeName]) Then
					MessageText = StrTemplate(MessageTemplate,
						TSMetadata[TSName].Attributes[AttributeName].Synonym, RowIndex+1, TSMetadata[TSName].Synonym);
					Common.MessageToUser(MessageText,,,,Cancel);
				EndIf;
			EndDo;
		EndDo;
		If ThereAreItemsPackagingUnitsOfVHF(TSName) And DataProcessor[TSName].Count() > 0 Then
			CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
			CheckParameters.TSName = TSName;
			ProductsServer.CheckWhetherCharacteristicsAreFilledIn(DataProcessor, New Array(), Cancel, CheckParameters);
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure BindMessagesToUserOfOperation(Messages, RowData)
	
	RowIndex = RowsCollection(ThisObject, RowData).IndexOf(RowData);
	
	If ValueIsFilled(RowData.Description) Then
		Description = RowData.Description;
	Else
		Description = StrTemplate(NStr("vi = 'Dòng %1';
										|ru = 'Строка %1';
										|en = 'Row %1'; fa = 'Row %1';
										|it = 'Riga %1';
										|pl = 'Wiersz %1';
										|tr = 'Satır %1'"), RowIndex+1);
	EndIf;
	
	For Each Message In GetUserMessages(True) Do
		Message.Text = StrTemplate("%1: %2", Description, Message.Text);
		Messages.Add(Message);
	EndDo;
	
EndProcedure

&AtServer
Procedure ReplaceWithIndividualOneAtServer()
	
	TechProcessParameters = ProductionProcessEditorClientServer.ProcessParametersConstructor();
	TechProcessParameters.TechnologicalProcessType = IndividualTechnicalProcess();
	TechProcessParameters.TechnologicalProcessFactor = Object.TechnologicalProcessFactor;
	
	FillPropertyValues(Object, TechProcessParameters);
	Object.SaveTechnologicalProcessLimitations = False;
	
	ResourceTable.Clear();
	FillInServiceAttributesOfLinesOfOperationsATServer();
	
	InitializeNewOperation();
	
	Modified = True;
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtServer
Procedure AddOperationToOrderCheckTable(OrderCheckTable, RowData)
	
	If ThisIsIndividualOperationInGroup(RowData) Then
		Return;
	EndIf;
	
	NewRow = OrderCheckTable.Add();
	NewRow.Object                 = RowData;
	NewRow.Operation               = RowData.Operation;
	NewRow.Presentation          = RowData.Description;
	NewRow.OperationNumber          = RowData.OperationNumber;
	NewRow.NextOperation = RowData.NextOperation; 
	
EndProcedure

#EndRegion

#Region WorkingOfOperations

&AtClient
Procedure Attachable_OperationsOnActivateRow()
	
	OperationsWhenActivatingLineATServer();
	
	Cache.RowActivation = False;
	
EndProcedure

&AtServer
Procedure OperationsWhenActivatingLineATServer()
	
	SaveDataOfCurrentOperation();
	
	InitializeNewOperation();
	
	SaveCurrentLine(ThisObject);
	
EndProcedure
	
&AtServer
Procedure SaveDataOfCurrentOperation()
	
	RowID = CurrentRowID(ThisObject);
	
	SaveResourcesOfIndividualOperation(RowID);
	
EndProcedure
	
&AtServer
Procedure InitializeNewOperation()
	
	CurrentRow = Items.Operations.CurrentRow;
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Operations.FindByID(CurrentRow);
	
	ProductionProcessEditor.ConfigureSettingsForSelectingWorkCenters(
		CurrentData, ThisObject, Object.Department);
	
	ProductionProcessEditor.ConfigureSiteSelectionParameters(
		CurrentData, ThisObject, Object.Department);
	
	Items.ProductionArea.InputHint = ProductionProcessEditor.PlotPresentation(
		CurrentData, Items.ProductionArea.Visible);
	
	LoadResourcesOfOperationsIntoObject(CurrentRow);
	
	UpdateCurrentSupplyIndicators();
	
	ConfigureDependentFormElements(ThisObject, "Operation");
	
EndProcedure

&AtClient
Procedure OnChangeOfOperation(AttributesList)
	
	CurrentRow = Items.Operations.CurrentRow;
	CurrentData = Operations.FindByID(CurrentRow);
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	SortGroup = False;
	ProcessAtServer      = False;
	
	For Each AttributeName In StrSplit(AttributesList,",") Do
		
		FillInAttributesOfOperationsOfGroup(ThisObject, CurrentData, AttributeName);
		
		If AttributeName = "OperationNumber"
			Or AttributeName = "NextOperation" Then
			SortGroup = True;
		Else
			ProcessAtServer = True;
		EndIf;
		
	EndDo;
	
	If ProcessAtServer Then
		IndividualUpTo = ThisOperationIsIndividual(CurrentData);
		OnChangeOfOperationATServer(AttributesList, CurrentRow);
		SortGroup = SortGroup Or IndividualUpTo <> ThisOperationIsIndividual(CurrentData);
	EndIf;
	
	If Not SortGroup Or Not TreeSortGroupClient() Then
		FillInServiceAttributesOfLineOfOperation(ThisObject, CurrentData);
		FillInAttributesOfOFOperationGroup(ThisObject, CurrentData.GetParent());
	EndIf;
	
	Modified = True;
	CurrentData.Modified = True;
	
	ConfigureDependentFormElements(ThisObject, "Operation");
	
EndProcedure

&AtServer
Procedure OnChangeOfOperationATServer(AttributesList, RowID)
	
	RowData = Operations.FindByID(RowID);
	If RowData = Undefined Then
		Return;
	EndIf;
	
	If AttributesList = "Required2" And Not ThisOperationIsIndividual(RowData) Then
		
		RowData.TechnologicalProcessFactor = RowData.Required2 / RowData.Count;
		LoadResourcesOfOperationsIntoObject(RowID);
		ReflectChangesOfOperationResources(RowID, Object);
		
	Else
		
		If ConvertOfOperationToIndividualOne(RowID, False)
			Or StrFind(AttributesList, "ManufacturedProducts") > 0
			Or StrFind(AttributesList, "MaterialsAndServices") > 0
			Or StrFind(AttributesList, "LaborCosts") > 0 Then
			SaveResourcesOfIndividualOperation(RowID);
		EndIf;
	
		If StrFind(AttributesList, "ProductionArea") > 0
			Or StrFind(AttributesList, "WorkCenter") > 0
			Or StrFind(AttributesList, "SetupSettings") > 0 Then
			
			RowsArray = CommonClientServer.ValueInArray(RowData);
			If ThisIsGroupOfIndividualOperations(RowData) Then
				For Each SubordinateLineData In RowData.GetItems() Do
					RowsArray.Add(SubordinateLineData);
				EndDo;
			EndIf;
			
			For Each RowData In RowsArray Do
				
				If StrFind(AttributesList, "ProductionArea") > 0 Then
				
					ProductionProcessEditor.ProductionAreaOnChange(RowData, ThisObject);
					
				EndIf;
					
				ProductionProcessEditor.CheckCorrectSetupOption(RowData);
				
				ProductionProcessEditor.ReadDetailsOfWorkCenter(RowData, RowData);
				
				If Not RowData.ParallelLoad Then
					RowData.Load = 0;
				EndIf;
				
				If RowData.SynchronousLoad Then
					RowData.TimePerPiece = 0;
					RowData.SetupTime = 0;
				EndIf;
				
				ProductionProcessEditor.SetupSettingsOnChange(RowData, RowData);
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
	UpdateSupplyIndicatorsGeneral();
	UpdateCurrentSupplyIndicators();
	
EndProcedure

// Check the correct selection of lines.
// 
// Parameters:
//  Form - ClientApplicationForm
//  RowsIDs - Array of Number
//  Mode - String, Number - the mode of operation of the check (
//    "All" - without restrictions,
//    "Individual" - only individual,
//    "Single-level" - which have the same level,
//    "Detailed" - only executable Operations, without grouping strings,
//    0...N - only a specific level).
// Returns:
//  Boolean
&AtClientAtServerNoContext
Function CheckCorrectnessOfSelectionOfLines(Form, RowsIDs, Mode = "All")
	
	MessageText = "";
	
	If Mode = "All" Then
		Return MessageText;
	EndIf;
	
	ArrayOfLevels = New Array;
	GroupsArray1   = New Array;
	
	For Each RowID In RowsIDs Do
		RowData = Form.Operations.FindByID(RowID);
		Level = LevelOfLine(RowData);
		If ArrayOfLevels.Find(Level) = Undefined Then
			ArrayOfLevels.Add(Level);
		EndIf;
		If ThisIsGroupOfIndividualOperations(RowData) Then
			GroupsArray1.Add(RowID);
		EndIf;
		If (TypeOf(Mode) = Type("Number") And Level <> Mode)
				Or (Mode = "SingleLevel" And ArrayOfLevels.Count() > 1)
				Or (Mode = "SpecialTerms" And Not ThisOperationIsIndividual(RowData))
				Or (Mode = "Detailed" And GroupsArray1.Count() > 0) Then
			MessageText = ProductionProcessEditorClientServer.WarningTextCommandCannotBeExecuted(ArrayOfLevels);
			Break;
		EndIf;
	EndDo;
	
	Return MessageText;
	
EndFunction

// Check the ability to edit Operations.
// 
// Parameters:
//  RowsIDs - Array of Number, Undefined - IDs
//  Mode - String, Number - See CheckCorrectnessOfSelectionOfLines
// Returns:
//  Boolean - Check The Ability To Edit Operations
&AtClient
Function CheckAbilityToEditOperations(RowsIDs = Undefined, Mode = 0)
	
	WarningText = "";
	
	For Each RowID In RowsIDs Do
		RowData = Operations.FindByID(RowID);
		If RowData.ReadOnly Then
			If Cache.StateArray.Find(RowData.State) <= BorderOfEditableStates()
				Or RowData.ThereAreCreated Then
				WarningText = NStr("vi = 'Không thể thay đổi hoặc xóa các giao dịch đã hoàn thành hoặc đang thực hiện.';
									|ru = 'Нельзя изменять и удалять выполненные или находящиеся в работе операции.';
									|en = 'Cannot edit or delete operations that are completed or in progress.'; fa = 'Cannot edit or delete operations that are completed or in progress.';
									|it = 'Cannot edit or delete operations that are completed or in progress.';
									|pl = 'Cannot edit or delete operations that are completed or in progress.';
									|tr = 'Gerçekleştirilmiş veya devam etmekte olan işlemleri değiştiremez veya silemezsiniz.'");
				Break;
			Else
				WarningText = NStr("vi = 'Không thể thay đổi hoặc xóa các giao dịch đã hoàn thành hoặc đang thực hiện.';
									|ru = 'Нельзя изменять и удалять операции, предшествующие выполненным или находящимся в работе.';
									|en = 'Cannot edit or delete operations that precede the completed operations or operations in progress.'; fa = 'Cannot edit or delete operations that precede the completed operations or operations in progress.';
									|it = 'Cannot edit or delete operations that precede the completed operations or operations in progress.';
									|pl = 'Cannot edit or delete operations that precede the completed operations or operations in progress.';
									|tr = 'Gerçekleştirilmiş veya devam etmekte olan işlemlerden önceki işlemleri değiştiremez veya silemezsiniz.'");
			EndIf;
		EndIf;
	EndDo;
	
	If IsBlankString(WarningText) Then
		WarningText = CheckCorrectnessOfSelectionOfLines(ThisObject, RowsIDs, Mode);
	EndIf;
	
	If Not IsBlankString(WarningText) Then
		ShowMessageBox(, WarningText);
		Return False;
	Else
		Return True;
	EndIf;
	
EndFunction

&AtServer
Function ConvertOfOperationToIndividualOne(RowID, SaveResources = True)
	
	RowData = Operations.FindByID(RowID);
	If RowData = Undefined
		Or RowData.ReadOnly
		Or ThisOperationIsIndividual(RowData)
		Or ThisIsGroupOfIndividualOperations(RowData) Then
		Return False;
	EndIf;
	
	RowData.Operation                 = Undefined;
	RowData.TechnologicalProcess   = Undefined;
	RowData.TechnologicalProcessFactor = Object.TechnologicalProcessFactor;
	RowData.ProductionOperation = Undefined;
	RowData.Repeatable           = False;
	If RowData.Control = Enums.ManufacturingOperationControlOptions.RequiredForSubsequentOperations Then
		RowData.Control  = Enums.ManufacturingOperationControlOptions.NotRequired;
	EndIf;
	
	If RowData.Count > 1 Then
		RowData.TimePerPiece = RowData.TimePerPiece / RowData.Count;
		RowData.Count   = 1;
	EndIf;
	 
	 RowData.Modified = True;
	
	If SaveResources Then
		SaveResourcesOfIndividualOperation(RowID);
	EndIf;
	
	Return True;
	
EndFunction

&AtClientAtServerNoContext
Function LevelOfLine(RowData)
	
	Result = 0;
	Parent  = RowData.GetParent();
	
	While Parent <> Undefined Do
		Result = Result + 1;
		Parent  = Parent.GetParent();
	EndDo;
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function RowsCollection(Form, RowData)
	
	Parent = ?(RowData <> Undefined, RowData.GetParent(), Undefined);
	If Parent <> Undefined Then
		Return Parent.GetItems(); // FormDataTreeItemCollection
	Else
		Return Form.Operations.GetItems(); // FormDataTreeItemCollection
	EndIf;
	
EndFunction

&AtClientAtServerNoContext
Function NextRow(Form, Cursor = Undefined, NestedLevels = True, PriorityOfDescendants = True)
	
	TransactionList = Form.Operations.GetItems();
	
	If NestedLevels And PriorityOfDescendants Then
		
		If Cursor = Undefined Then
			CurrentIndex = 0;
		Else
			Parent = Cursor.GetParent();
			If Parent <> Undefined Then
				TransactionList = Parent.GetItems();
			EndIf;
			CurrentIndex = TransactionList.IndexOf(Cursor)+1;
		EndIf;
		
		If CurrentIndex <= TransactionList.Count()-1 Then
			While TransactionList.Count() > 0 Do
				Cursor = TransactionList[CurrentIndex];
				TransactionList = Cursor.GetItems();
				CurrentIndex = 0;
			EndDo;
		ElsIf Parent <> Undefined Then
			Cursor = Parent;
		Else
			Cursor = Undefined;
		EndIf;
		
	Else
		
		If Cursor = Undefined Then
			If TransactionList.Count() > 0 Then
				Cursor = TransactionList[0];
			EndIf;
			Return Cursor <> Undefined; // Boolean
		EndIf;
		
		ListOfOperationsIsNested = Cursor.GetItems();
		If ListOfOperationsIsNested.Count() > 0 And NestedLevels Then
			Cursor = ListOfOperationsIsNested[0];
		Else
			Parent = Cursor.GetParent();
			If Parent <> Undefined Then
				TransactionList = Parent.GetItems();
			EndIf;
			CurrentIndex = TransactionList.IndexOf(Cursor);
			If CurrentIndex < TransactionList.Count()-1 Then
				Cursor = TransactionList[CurrentIndex+1];
			ElsIf Parent <> Undefined Then
				Cursor = Parent;
				Return NextRow(Form, Cursor, False, False);
			Else
				Cursor = Undefined;
			EndIf;
		EndIf;
		
	EndIf;
	
	Return Cursor <> Undefined; // Boolean
	
EndFunction

&AtClientAtServerNoContext
Procedure FillInLineImage(Form, RowData)
	
	PictureMain = Undefined;
	
	If ThisIsNSIOperation(RowData) Then
		PictureMain = PictureLib.ProductionProcessOperation;
	ElsIf ThisIsGroupOfIndividualOperations(RowData) Then
		PictureMain = PictureLib.MetadataDocuments;
	ElsIf ThisOperationIsIndividual(RowData) Then
		PictureMain = PictureLib.ManufacturingProcessDocument;
	EndIf;
	
	RowData.RowPicture = PictureMain;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetAttributeOfLine(Form, RowData, AttributeName, Value, IncludingSubordinates = True)
	
	If RowData.ReadOnly
		And Not AttributeName = "NextOperation"
		And Not ThisIsGroupOfIndividualOperations(RowData) Then
		Return;
	EndIf;
	
	If RowData[AttributeName] <> Value Then
		Form.Modified = True;
		RowData.Modified = True;
		RowData[AttributeName] = Value;
		If IncludingSubordinates Then
			FillInAttributesOfOperationsOfGroup(Form, RowData, AttributeName);
		EndIf;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function StringGroupingKey(RowData)
	
	Term1 = Format(RowData.OperationNumber, "ND=5; NLZ=; NG=;");
	Term2 = Format(RowData.NextOperation, "ND=5; NLZ=; NG=;");
	Term3 = ?(ThisOperationIsIndividual(RowData), 0, Format(RowData.OperationID,"ND=5; NLZ=; NG=;"));
	
	Result = StrTemplate("%1_%2_%3", Term1, Term2, Term3);
	Return Result;
	
EndFunction

// The row sorting key.
// 
// Parameters:
//  Form - ClientApplicationForm
//  RowData - ValueTreeRow
// 
// Returns:
//  String - String Sorting Key
&AtClientAtServerNoContext
Function StringSortingKey(Form, RowData)
	
	Term1 = Format(RowData.OperationNumber, "ND=5; NLZ=; NG=;");
	Term2 = RowData.Description;
	Term3 = Format(RowData.OperationID, "ND=5; NLZ=; NG=;");
	
	Result = StrTemplate("%1_%2_%3", Term1, Term2, Term3);
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Procedure SaveCurrentLine(Form, RowID = Undefined)
	
	SavedValue = New Structure;
	
	CurrentRow = ?(RowID = Undefined, Form.Items.Operations.CurrentRow, RowID);
	CurrentData = ?(CurrentRow = Undefined, Undefined, Form.Operations.FindByID(CurrentRow));
	
	If CurrentData <> Undefined Then
		
		SavedValue.Insert("RowID",   CurrentRow);
		SavedValue.Insert("OperationID", CurrentData.OperationID);
		SavedValue.Insert("GroupingKey",       StringGroupingKey(CurrentData));
		
		Form.Cache.Insert("State_CurrentLine", SavedValue);
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure RestoreCurrentLine(Form)
	
	SavedValue = Undefined;
	IDs = New Array(3);
	
	If Not Form.Cache.Property("State_CurrentLine", SavedValue) Then
		Return;
	EndIf;
	
	RowData = Undefined;
	While NextRow(Form, RowData) Do
		If ThisIsGroupOfIndividualOperations(RowData) Then
			If SavedValue.GroupingKey = StringGroupingKey(RowData) Then
				IDs[1] = RowData.GetID();
			EndIf;
			If SavedValue.OperationID = 0 Then
				Break;
			EndIf;
		ElsIf SavedValue.OperationID = RowData.OperationID Then
			IDs[0] = RowData.GetID();
		ElsIf SavedValue.GroupingKey = StringGroupingKey(RowData) Then
			IDs[2] = RowData.GetID();
		EndIf;
	EndDo;
	
	For Each Id In IDs Do
		If Id <> Undefined Then
			Form.Items.Operations.CurrentRow = Id;
			Break;
		EndIf;
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Function CurrentRowID(Form)
	
	SavedValue = Undefined;
	If Not Form.Cache.Property("State_CurrentLine", SavedValue) Then
		Return -1;
	Else
		Return SavedValue.RowID;
	EndIf;
	
EndFunction

&AtClient
Procedure SaveStateOfTreeLevels()
	
	SavedValue = New Array;
	
	RowData = Undefined;
	While NextRow(ThisObject, RowData, False) Do
		If ThisIsGroupOfIndividualOperations(RowData) Then
			Expanded = Items.Operations.Expanded(RowData.GetID());
			If Expanded Then
				SavedValue.Add(StringGroupingKey(RowData));
			EndIf;
		EndIf;
	EndDo;
	
	Cache.Insert("State_TreeLevels", SavedValue);
	
EndProcedure

&AtClient
Procedure RestoreStateOfTreeLevels()
	
	SavedValue = Undefined;
	
	If Not Cache.Property("State_TreeLevels", SavedValue) Then
		Return;
	EndIf;
	
	RowData = Undefined;
	While NextRow(ThisObject, RowData, False) Do
		RowID = RowData.GetID();
		If ThisIsGroupOfIndividualOperations(RowData)
				And SavedValue.Find(StringGroupingKey(RowData)) <> Undefined
				And Not Items.Operations.Expanded(RowID) Then
			Items.Operations.Expand(RowID, False);
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure TreeOfOperationsConvolution(GroupBy = True, TreeRows = Undefined)
	
	If TreeRows = Undefined Then
		TreeRows = Operations;
	EndIf;
	
	For Each TreeRow In TreeRows.GetItems() Do
		If GroupBy Then
			TreeOfOperationsConvolution(GroupBy, TreeRow);
			Items.Operations.Collapse(TreeRow.GetID());
		Else
			Items.Operations.Expand(TreeRow.GetID(), True);
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Function TreeSortGroupClient()
	
	Result = False;
	
	SaveStateOfTreeLevels();
	
	If TreeSortGroup(ThisObject) Then
		RestoreStateOfTreeLevels();
		RestoreCurrentLine(ThisObject);
		Result = True;
	EndIf;
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function TreeSortGroup(Form)
	
	KeysList   = New ValueList();
	DataOfGroups    = New Map();
	OperationData_ = New Map();
	
	RowData = Undefined; // Form.Operations
	While NextRow(Form, RowData) Do
		GroupingKey = StringGroupingKey(RowData);
		SortingKey  = StringSortingKey(Form, RowData);
		If ThisIsGroupOfIndividualOperations(RowData) Then
			DataOfGroups.Insert(GroupingKey, RowData.GetItems().Count());
		Else
			StringsList = OperationData_.Get(GroupingKey);
			If StringsList = Undefined Then
				StringsList = New ValueList;
				OperationData_.Insert(GroupingKey, StringsList);
			EndIf;
			StringDataByStructure = StringTreeStructureConstructor(Form);
			FillPropertyValues(StringDataByStructure, RowData);
			StringsList.Add(StringDataByStructure, SortingKey);
		EndIf;
		If KeysList.FindByValue(GroupingKey) = Undefined Then
			KeysList.Add(GroupingKey, SortingKey);
		EndIf;
	EndDo;
	
	Order1 = StrConcat(KeysList.UnloadValues(), ";");
	KeysList.SortByPresentation();
	Order2 = StrConcat(KeysList.UnloadValues(), ";");
	
	RebuildTree = Order1 <> Order2; // Boolean
	If Not RebuildTree Then
		For Each ListItem In KeysList Do
			DataOfGroup   = DataOfGroups.Get(ListItem.Value);
			OperationData = OperationData_.Get(ListItem.Value);
			If ((DataOfGroup = Undefined) <> (OperationData = Undefined))
				Or (DataOfGroup <> OperationData.Count()) Then
				RebuildTree = True;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	If RebuildTree Then
		TreeRows = Form.Operations.GetItems();
		TreeRows.Clear();
		For Each ListItem In KeysList Do
			StringsList = OperationData_.Get(ListItem.Value);
			If StringsList <> Undefined Then
				StringsList.SortByPresentation();
				If StringsList.Count() = 1 Then
					NewRow = TreeRows.Add();
					FillPropertyValues(NewRow, StringsList[0].Value);
				Else
					NewGrouping = TreeRows.Add();
					For Each Item In StringsList Do
						NewRow = NewGrouping.GetItems().Add();
						FillPropertyValues(NewRow, Item.Value);
					EndDo;
				EndIf;
			EndIf;
		EndDo;
		FillInServiceAttributesOfLinesOfOperations(Form);
	EndIf;
	
	Return RebuildTree; // Boolean
	
EndFunction

&AtClient
Procedure SetNumberOfEnds(NewCount, AdditionalParameters) Export
	
	If NewCount <> Undefined Then
		
		SetNumberATServer(NewCount, AdditionalParameters.RowsIDs);
		
		Modified = True;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetNumberATServer(Count, RowsIDs)
	
	RowData = Undefined;
	While NextRow(ThisObject, RowData) Do
		
		ParentRowData = RowData.GetParent();
		
		RowID = RowData.GetID();
		ParentLineID = ?(ParentRowData <> Undefined, ParentRowData.GetID(), Undefined);
		
		If ThisIsGroupOfIndividualOperations(RowData)
			Or (RowsIDs.Find(RowID) = Undefined
				And RowsIDs.Find(ParentLineID) = Undefined) Then
			Continue;
		EndIf;
		
		SetAttributeOfLine(
			ThisObject, RowData, "Required2", Count, False);
		SetAttributeOfLine(
			ThisObject, RowData, "TechnologicalProcessFactor", RowData.Required2 / RowData.Count, False);
		ReflectChangesOfOperationResources(RowID, OperationResourceStorageStructure(RowData));
		
		FillInAttributesOfOFOperationGroup(ThisObject, ParentRowData);
		
	EndDo;
	
	LoadResourcesOfOperationsIntoObject(Items.Operations.CurrentRow);
	
	UpdateSupplyIndicatorsGeneral();
	UpdateCurrentSupplyIndicators();
	
EndProcedure

#Region ServiceDetails_

&AtServer
Procedure FillInServiceAttributesOfLinesOfOperationsATServer(RowsIDs = Undefined)
	
	ResourcesCache  = GetCacheOfResources();
	RowData = Undefined;
	
	While NextRow(ThisObject, RowData) Do
		RowID = RowData.GetID();
		If RowsIDs = Undefined
				Or RowsIDs.Find(RowID) <> Undefined Then
			StructureOfData = OperationResourceStorageStructure(RowData, ResourcesCache);
			ReflectChangesOfOperationResources(RowID, StructureOfData);
			ProductionProcessEditor.ReadDetailsOfWorkCenter(
				RowData, RowData);
			ProductionProcessEditorClientServer.FillInUnitOfMeasurementOfTransferBatch(
				RowData, RowData.UnitOfMeasureOfTransferBatch);
			FillInServiceAttributesOfLineOfOperation(ThisObject, RowData);
		EndIf;
	EndDo;
	
	UpdateSupplyIndicatorsGeneral();
	
EndProcedure
	
&AtClientAtServerNoContext
Procedure FillInServiceAttributesOfLinesOfOperations(Form, RowsIDs = Undefined)
	
	RowData = Undefined;
	While NextRow(Form, RowData) Do
		If RowsIDs = Undefined
				Or RowsIDs.Find(RowData.GetID()) <> Undefined Then
			FillInServiceAttributesOfLineOfOperation(Form, RowData);
		EndIf;
	EndDo;
	
	ResetServiceCacheAttributes(Form);
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInServiceAttributesOfLineOfOperation(Form, RowData)
	
	FillInStateOfOperation(Form, RowData);
	
	SetServiceAttributes(Form, RowData, "ThisIsGroupOfIndividualOperations",  ThisIsGroupOfIndividualOperations(RowData));
	SetServiceAttributes(Form, RowData, "ThisOperationIsIndividual",        ThisOperationIsIndividual(RowData));
	SetServiceAttributes(Form, RowData, "ThisIsIndividualOperationInGroup", ThisIsIndividualOperationInGroup(RowData));
	
	FillInAttributesOfOFOperationGroup(Form, RowData);
	
	FillInLineImage(Form, RowData);
	
	FillInOnlyViewOfOperationFlag(Form, RowData);
	
	FillInUpload(Form, RowData);
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInAttributesOfOFOperationGroup(Form, GroupRowData)
	
	If Not ThisIsGroupOfIndividualOperations(GroupRowData) Then
		Return;
	EndIf;
	
	GroupsAreRequired          = 0;
	ModificationOfGroup = False;
	GroupViewOnly     = False;
	StateOfGroup          = Form.Cache.StateArray.UBound();
	RequiresSupply       = False;
	IndicatorsOfResources       = ResourceIndicatorsConstructor(True);
	
	ChildItems = GroupRowData.GetItems();
	ServiceDetails_ = ServiceAttributesOfOperations(Form);
	
	For IndexOf = 0 To ChildItems.Count() - 1 Do
		RowData = ChildItems[IndexOf];
		For Each KeyAndValue In ServiceDetails_ Do
			LongDesc = KeyAndValue.Value;
			If LongDesc.GroupCalculation Then
				If IndexOf= 0 Then
					LongDesc.CurrentValue = RowData[LongDesc.NameOfMainAttribute];
					GroupRowData[LongDesc.NameOfServiceAttribute] = True;
				ElsIf (ValueIsFilled(LongDesc.CurrentValue) Or ValueIsFilled(RowData[LongDesc.NameOfMainAttribute]))
						And LongDesc.CurrentValue <> RowData[LongDesc.NameOfMainAttribute] Then
					GroupRowData[LongDesc.NameOfServiceAttribute] = False;
				EndIf;
			EndIf;
		EndDo;
		GroupsAreRequired = GroupsAreRequired + RowData.Required2;
	EndDo;
	
	For IndexOf = 0 To ChildItems.Count() - 1 Do
		RowData = ChildItems[IndexOf];
		For Each KeyAndValue In ServiceDetails_ Do
			LongDesc = KeyAndValue.Value;
			If LongDesc.GroupCalculation Then
				If Not IsBlankString(LongDesc.AttributesOfDifferenceControl) Then
					Synchronized_ = True;
					For Each AttributeName In StrSplit(LongDesc.AttributesOfDifferenceControl, ",") Do
						If Not GroupRowData[ServiceDetails_[AttributeName].NameOfServiceAttribute] Then
							Synchronized_ = False;
							Break;
						EndIf;
					EndDo;
					GroupRowData[LongDesc.NameOfServiceAttribute] = Synchronized_;
				EndIf;
				If GroupRowData[LongDesc.NameOfServiceAttribute] Then
					GroupRowData[LongDesc.NameOfMainAttribute] = LongDesc.CurrentValue;
					RowData[LongDesc.NameOfServiceAttribute] = False;
				Else
					If LongDesc.BlockForDifferences Or LongDesc.MonitorForDifferences Then
						GroupRowData[LongDesc.NameOfMainAttribute] = Undefined;
					Else
						GroupRowData[LongDesc.NameOfMainAttribute] = LongDesc.CurrentValue;
					EndIf;
					RowData[LongDesc.NameOfServiceAttribute] = True;
				EndIf;
			EndIf
		EndDo;
		ModificationOfGroup = Max(ModificationOfGroup, RowData.Modified);
		GroupViewOnly = Max(GroupViewOnly, RowData.ReadOnly);
		StateOfGroup = Min(StateOfGroup, Form.Cache.StateArray.Find(RowData.State));
		RequiresSupply = Max(RequiresSupply, RowData.RequiresSupply);
		For Each KeyAndValue In IndicatorsOfResources Do
			IndicatorsOfResources[KeyAndValue.Key] = Max(IndicatorsOfResources[KeyAndValue.Key], RowData[KeyAndValue.Key]);
		EndDo;
	EndDo;
	
	GroupRowData.Count         = 1;
	GroupRowData.Required2          = ?(ServiceAttributeValue(Form, GroupRowData, "Required2"), GroupsAreRequired, 0);
	GroupRowData.Modified = ModificationOfGroup;
	GroupRowData.ReadOnly     = GroupViewOnly;
	GroupRowData.State          = Form.Cache.StateArray[StateOfGroup];
	GroupRowData.RequiresSupply = RequiresSupply;
	FillPropertyValues(GroupRowData, IndicatorsOfResources);
	ResourceIndicatorsFillInImages(GroupRowData);
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInAttributesOfOperationsOfGroup(Form, GroupRowData, AttributeName)
	
	If Not ThisIsGroupOfIndividualOperations(GroupRowData) Then
		Return;
	EndIf;
	
	LongDesc = ServiceAttributesDescription(Form, AttributeName);
	If LongDesc = Undefined
		Or Not LongDesc.BulkEdit Then
		Return;
	EndIf;
	
	GroupRowData[LongDesc.NameOfServiceAttribute] = True;
	For Each RowData In GroupRowData.GetItems() Do
		SetAttributeOfLine(Form, RowData, AttributeName, GroupRowData[AttributeName], False);
		RowData[LongDesc.NameOfServiceAttribute] = False;
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInStateOfOperation(Form, RowData)
	
	If RowData.ReadOnly And ValueIsFilled(RowData.State)
			Or ThisIsGroupOfIndividualOperations(RowData) Then
		Return;
	EndIf;
	
	Indicators = ExecutionIndicators(RowData.ExecutionIndicators);
	State  = PredefinedValue("Enum.OperationStates.PendingPredecessorCompletion");
	
	If ValueIsFilled(Indicators.State) Then
		State = Indicators.State;
		If Form.Cache.StateArray.Find(State) > BorderOfEditableStates() And Indicators.Assigned_ = True Then
			State = PredefinedValue("Enum.OperationStates.Assigned_");
		EndIf; 
	Else
		ExecutionIsAllowed = True;
		For Each String In PreviousOperations_(Form, RowData).ByANumber Do
			ExecutionIsAllowed = Min(ExecutionIsAllowed, Form.Cache.StateArray.Find(String.State) < BoundaryOfFiniteStates());
		EndDo;
		If ExecutionIsAllowed Or Indicators.ExecutionIsAllowed > 0 Then
			State = ?(Form.DivisionParameters.UseShiftTasks,
				PredefinedValue("Enum.OperationStates.ToAssign"),
				PredefinedValue("Enum.OperationStates.ForCompletion"));
		EndIf;
	EndIf;
	
	RowData.State = State;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInOnlyViewOfOperationFlag(Form, RowData)
	
	If Not RowData.ReadOnly
		And Not ThisIsGroupOfIndividualOperations(RowData) Then
		
		RowData.ThereAreCreated  = ExecutionIndicators(RowData.ExecutionIndicators).CreatedOn > 0;
		RowData.ReadOnly = Form.Cache.StateArray.Find(RowData.State) < BorderOfEditableStates()
			Or RowData.ThereAreCreated;
		
		If RowData.ReadOnly Then
			PredecessorData = Undefined;
			While NextRow(Form, PredecessorData) Do
				If PredecessorData.OperationNumber < RowData.OperationNumber Then
					If Not PredecessorData.ReadOnly Then
						PredecessorData.ReadOnly = True;
					EndIf;
				Else
					Break;
				EndIf;
			EndDo;
		Else
			RowData.ExecutionIndicators = Undefined;
		EndIf;
	
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInUpload(Form, RowData)
	
	If ThisOperationIsIndividual(RowData) Then
		
		RowData.LoadStandard = ?(RowData.Required2 > 0, RowData.Load / RowData.Required2, 0);
		
	Else
		
		RowData.Load = RowData.LoadStandard * RowData.Required2 / RowData.Count;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure CreateServiceAttributesOfOperations()
	
	AttributesToBeAdded = New Array;
	
	For Each KeyFromValue In ServiceAttributesOfOperations(ThisObject) Do
		
		LongDesc = KeyFromValue.Value;
		AttributesToBeAdded.Add(New FormAttribute(LongDesc.NameOfServiceAttribute, LongDesc.Type, "Operations"));
		
	EndDo;
	
	ChangeAttributes(AttributesToBeAdded);
	
EndProcedure

&AtClientAtServerNoContext
Function ServiceAttributesOfOperations(Form)
	
	If Form.Cache <> Undefined
		And Form.Cache.Property("ServiceAttributesOfOperations") Then
			
		Result = Form.Cache.ServiceAttributesOfOperations; // Structure
		
	Else
		
		Result = New Structure;
		
		//
		AttributesList = "ThisOperationIsIndividual,ThisIsGroupOfIndividualOperations,ThisIsIndividualOperationInGroup";
		For Each AttributeName In StrSplit(AttributesList,",") Do
			LongDesc = DescriptionOfServiceAttributeConstructor(AttributeName);
			LongDesc.GroupCalculation = False;
			Result.Insert(LongDesc.NameOfMainAttribute, LongDesc);
		EndDo;
		
		//
		AttributesList = "Description,OperationNumber,NextOperation";
		For Each AttributeName In StrSplit(AttributesList,",") Do
			LongDesc = DescriptionOfServiceAttributeConstructor(AttributeName);
			LongDesc.BulkEdit = True;
			LongDesc.InListColumn = True;
			Result.Insert(LongDesc.NameOfMainAttribute, LongDesc);
		EndDo;
		
		//
		AttributesList = "UnitOfMeasure,ProductionArea,WorkCenter";
		For Each AttributeName In StrSplit(AttributesList,",") Do
			LongDesc = DescriptionOfServiceAttributeConstructor(AttributeName);
			LongDesc.BulkEdit = True;
			LongDesc.BlockForDifferences = True;
			LongDesc.InListColumn = True;
			Result.Insert(LongDesc.NameOfMainAttribute, LongDesc);
		EndDo;
		
		//
		AttributesList = CommonClientServer.StructureKeysToString(ControlledAttributesOfOperationsInGroup());
		For Each AttributeName In StrSplit(AttributesList,",") Do
			LongDesc = DescriptionOfServiceAttributeConstructor(AttributeName);
			LongDesc.BulkEdit = True;
			LongDesc.MonitorForDifferences = True;
			LongDesc.GroupTextForDifferences = NStr("vi = '<cần trùng khớp với giao dịch của nhóm>';
													|ru = '<должен совпадать у операций группы>';
													|en = '<must match for group operations>'; fa = '<must match for group operations>';
													|it = '<must match for group operations>';
													|pl = '<must match for group operations>';
													|tr = '<grup işlemleri için aynı olmalıdır>'");
			LongDesc.TextOfOperationForDifferences = NStr("vi = '<được xác định ở mức độ nhóm>';
															|ru = '<задается на уровне группы>';
															|en = '<set at the group level>'; fa = '<set at the group level>';
															|it = '<set at the group level>';
															|pl = '<set at the group level>';
															|tr = '<grup seviyesinde belirtilir>'");
			LongDesc.InPropertiesPanel = True;
			Result.Insert(LongDesc.NameOfMainAttribute, LongDesc);
		EndDo;
		
		//
		AttributesList = "SetupSettings,Load,TransferLot,Repeatable,Skippable,Continuous,LongDesc";
		For Each AttributeName In StrSplit(AttributesList,",") Do
			LongDesc = DescriptionOfServiceAttributeConstructor(AttributeName);
			LongDesc.BulkEdit = True;
			LongDesc.BlockForDifferences = True;
			LongDesc.InPropertiesPanel = True;
			Result.Insert(LongDesc.NameOfMainAttribute, LongDesc);
		EndDo;
		
		//
		AttributesList = "TimePerPiece,TimePerPieceUnitOfMeasure,SetupTime,SetupTimeUnitOfMeasure,WorkTimeOnSynchronousLoad,UnitOfMeasureForSynchronousLoad";
		For Each AttributeName In StrSplit(AttributesList,",") Do
			LongDesc = DescriptionOfServiceAttributeConstructor(AttributeName);
			LongDesc.BulkEdit = True;
			LongDesc.BlockForDifferences = True;
			LongDesc.InListColumn = True;
			LongDesc.AttributesOfDifferenceControl = AttributeName+",UnitOfMeasure,ProductionArea,WorkCenter,SetupSettings";
			Result.Insert(LongDesc.NameOfMainAttribute, LongDesc);
		EndDo;
		
		//
		AttributesList = "WorkTimeOnSynchronousLoad,UnitOfMeasureOfLoad,UnitOfMeasureOfTransferBatch,
		|UnitOfMeasureForSynchronousLoad,SetupSettingsAreUsed,ParallelLoad,SynchronousLoad";
		For Each AttributeName In StrSplit(AttributesList,",") Do
			LongDesc = DescriptionOfServiceAttributeConstructor(StrReplace(AttributeName, Chars.LF, ""));
			Result.Insert(LongDesc.NameOfMainAttribute, LongDesc);
		EndDo;
		
		//
		LongDesc = DescriptionOfServiceAttributeConstructor("Required2");
		LongDesc.BlockForDifferences = True;
		LongDesc.InListColumn = True;
		LongDesc.AttributesOfDifferenceControl = "UnitOfMeasure";
		Result.Insert(LongDesc.NameOfMainAttribute, LongDesc);
		
		If Form.Cache <> Undefined Then
			Form.Cache.Insert("ServiceAttributesOfOperations", Result);
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function ServiceAttributesDescription(Form, AttributeName)
	
	LongDesc = Undefined;
	ServiceAttributesOfOperations(Form).Property(AttributeName, LongDesc);
	Return LongDesc;
	
EndFunction

&AtClientAtServerNoContext
Procedure SetServiceAttributes(Form, RowData, AttributeName, Value)
	
	LongDesc = ServiceAttributesDescription(Form, AttributeName); // See DescriptionOfServiceAttributeConstructor
	RowData[LongDesc.NameOfServiceAttribute] = Value;
	
EndProcedure

&AtClientAtServerNoContext
Function ServiceAttributeValue(Form, RowData, AttributeName)
	
	LongDesc = ServiceAttributesDescription(Form, AttributeName); // See DescriptionOfServiceAttributeConstructor
	Value = RowData[LongDesc.NameOfServiceAttribute]; // Boolean
	Return Value;
	
EndFunction

// The standard number of operations, taking into account the coefficient of application of the process technology
// 
// Parameters:
//  Process parameters - see Parameterstechprocessconstructor
//  RowData - FormDataTreeItem
// 
// Returns:
//  Number
&AtServer
Function NumberOfOperationsIsNormative(RowData)
	
	Result = RowData.Required2 * Object.QuantityPerReleaseLotUnit / Object.Count;
	
	Return Result;
	
EndFunction

#EndRegion

#Region AddingRemovingSplitting

&AtServer
Function AddProcessOperations(TechProcessParameters = Undefined, Filteroperations = Undefined, NumberingSystem = 0)
	
	RowsIDs = New Array();
	LastNumber = LastNumber(ThisObject);
	SaveIdsOfOperations = False;
	
	If TechProcessParameters = Undefined Then
		TechProcessParameters = ProductionProcessEditorClientServer.ProcessParametersConstructor();
		FillPropertyValues(TechProcessParameters, Object);
		SaveIdsOfOperations = True;
	EndIf;
	
	If Not ValueIsFilled(TechProcessParameters.TechnologicalProcess) Then
		Return RowsIDs;
	EndIf;
	
	Data_Stage = Documents.ProductionStage2_2.DataForCalculatingOperationQueue(Object.Stage, False)[Object.Stage];
	FillPropertyValues(Data_Stage, TechProcessParameters);
	
	EditorOperations   = Operations.GetItems();
	ProcessOperations = InformationRegisters.QueueOfProductionOperations.ListOfOperationsAccordingToStageData(Data_Stage, Object.SaveTechnologicalProcessLimitations);
	
	AttributesValues = Common.ObjectsAttributesValues(ProcessOperations.UnloadColumn("Operation"), "CLASSIFIEROFTECHNOLOGICALOPERATIONS,ProductionArea,LongDesc");
	
	For Each String In ProcessOperations Do
		If Filteroperations = Undefined Or Filteroperations.Find(String.Operation) <> Undefined Then
			NewRow = EditorOperations.Add();
			FillPropertyValues(NewRow, String);
			NewRow.Required2 = String.QuantityPerBatch;
			NewRow.TechnologicalProcessFactor = TechProcessParameters.TechnologicalProcessFactor;
			NewRow.Description = String.OperationPresentation;
			FillPropertyValues(NewRow, AttributesValues[NewRow.Operation]);
			NewRow.LoadStandard = String.Load;
			If NumberingSystem = 1 Then // 0 - do not change, 1 - shift, 2 - add
				NewRow.OperationNumber = NewRow.OperationNumber + LastNumber;
				NewRow.NextOperation = NewRow.NextOperation + LastNumber;
			ElsIf NumberingSystem = 2 Then
				NewRow.OperationNumber = LastNumber + 1;
				NewRow.NextOperation = NewRow.OperationNumber + 1;
				LastNumber = LastNumber + 1;
			EndIf;
			If Not SaveIdsOfOperations Then
				NewRow.OperationID = NewOperationID(ThisObject);
			EndIf;
			If ValueIsFilled(String.RouteSheet) Then
				NewRow.TechnologicalProcess = String.RouteSheet;
			EndIf;
			NewRow.Modified = NumberingSystem <> 0;
			RowsIDs.Add(NewRow.GetID());
		EndIf;
	EndDo;
	
	If Not Object.SaveTechnologicalProcessLimitations Then
		CorrectNumberingOfOperations(ThisObject);
	EndIf;
	
	Return RowsIDs;
	
EndFunction

&AtServer
Procedure AddSelectionOperations(CalculationResult1)
	
	If Not ValueIsFilled(CalculationResult1) Then
		Return;
	EndIf;
	
	TechProcessParameters = ProductionProcessEditorClientServer.ProcessParametersConstructor();
	TechProcessParameters.TechnologicalProcessType = AlternativeProcessTechnology();
	TechProcessParameters.TechnologicalProcess      = CalculationResult1.TechnologicalProcess;
	TechProcessParameters.TechnologicalProcessFactor = Object.TechnologicalProcessFactor;
	
	RowsIDs = AddProcessOperations(TechProcessParameters, CalculationResult1.Operations, 2);
	FillInServiceAttributesOfLinesOfOperationsATServer(RowsIDs);
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure ProcessingSelectionOfOperationByClassifier(ValueSelected, NewOperation = False)
	
	If NewOperation Then
		
		If OperationsAddNew() = Undefined Then
			Return;
		EndIf;
		
	EndIf;
		
	AttributesList = ProcessingSelectionOfOperationByClassifierATServer(ValueSelected, NewOperation);
		
	OnChangeOfOperation(AttributesList);
	
EndProcedure

&AtServer
Function ProcessingSelectionOfOperationByClassifierATServer(ValueSelected, NewOperation = False)
	
	CurrentRow = Items.Operations.CurrentRow;
	CurrentData = Operations.FindByID(CurrentRow);
	
	DetailsOfWHO = ProductionProcessEditor.ValuesOfDetailsOfOperationsForWHO(
		CurrentData, ThisObject, ValueSelected, NewOperation);
	
	For Each KeyAndValue In DetailsOfWHO Do
		SetAttributeOfLine(ThisObject, CurrentData, KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
	Return CommonClientServer.StructureKeysToString(DetailsOfWHO)
	
EndFunction

&AtClient
Function OperationsAddCopy(SourceIdentificator, SaveNumbering = False)
	
	MessageText = CheckCorrectnessOfSelectionOfLines(ThisObject,
		CommonClientServer.ValueInArray(SourceIdentificator),
		"Detailed");
	If Not IsBlankString(MessageText) Then
		ShowMessageBox(, MessageText);
		Return Undefined;
	EndIf;
	
	NewRow = OperationsAddCopyClient(SourceIdentificator, SaveNumbering);
	
	AddCopyOfOperationsATServer(NewRow.GetID());
	
	Return NewRow;
	
EndFunction

&AtClient
Function OperationsAddCopyClient(SourceIdentificator, SaveNumbering = False)
	
	LastNumber = LastNumber(ThisObject);
	SourceRow = Operations.FindByID(SourceIdentificator);
	
	ItemKind = ProductionProcessEditorClientServer.TypeOfElementOfOperation();
	
	NewRow = RowsCollection(ThisObject, ?(SaveNumbering, SourceRow, Undefined)).Add();
	FillPropertyValues(NewRow, SourceRow);
	NewRow.OperationID    = NewOperationID(ThisObject);
	NewRow.ProductionOperation = Undefined;
	NewRow.ReadOnly           = False;
	NewRow.State                = Undefined;
	NewRow.ExecutionIndicators     = Undefined;
	
	If Not SaveNumbering Then
		NewRow.OperationNumber = LastNumber + 1;
		NewRow.NextOperation = 0;
		NewRow.Description = ProductionProcessEditorClientServer.NameOfNewItem(ItemKind, NewRow.OperationNumber);
	EndIf;
	
	Return NewRow;
	
EndFunction

&AtServer
Procedure AddCopyOfOperationsATServer(RowID)
	
	RowData = Operations.FindByID(RowID);
	If RowData = Undefined Then
		Return;
	EndIf;
	
	If ThisIsOperationOfOperationAccordingToBillOfMaterials(RowData) Then
		ConvertOfOperationToIndividualOne(RowID);
	ElsIf ThisOperationIsIndividual(RowData) Then
		SaveResourcesOfIndividualOperation(RowID);
	EndIf;
	
	FillInServiceAttributesOfLinesOfOperationsATServer(CommonClientServer.ValueInArray(RowID));
	
EndProcedure

&AtClient
Function OperationsAddNew(Copy = False)
	
	ItemKind = ProductionProcessEditorClientServer.TypeOfElementOfOperation();
	CurrentRow = Items.Operations.CurrentRow;
	
	If Copy And CurrentRow <> Undefined Then
		NewRow = OperationsAddCopy(CurrentRow);
	Else
		OperationNumber  = LastNumber(ThisObject) + 1;
		NewRow    = Operations.GetItems().Add();
		NewRow.OperationID = NewOperationID(ThisObject);
		NewRow.OperationNumber         = OperationNumber;
		NewRow.Description          = ProductionProcessEditorClientServer.NameOfNewItem(ItemKind, OperationNumber);
		NewRow.TimePerPieceUnitOfMeasure     = PredefinedValue("Enum.TimeMeasureUnits.Minute");
		NewRow.SetupTimeUnitOfMeasure          = PredefinedValue("Enum.TimeMeasureUnits.Minute");
		NewRow.Control              = PredefinedValue("Enum.ManufacturingOperationControlOptions.NotRequired");
		NewRow.Count            = 1;
		NewRow.Required2             = Object.TechnologicalProcessFactor;
		NewRow.TechnologicalProcessFactor = Object.TechnologicalProcessFactor;
	EndIf;
	
	If NewRow = Undefined Then
		Return Undefined;
	EndIf;
	
	CorrectNumberingOfOperations(ThisObject);
	
	FillInServiceAttributesOfLineOfOperation(ThisObject, NewRow);
	FillInAttributesOfOFOperationGroup(ThisObject, NewRow.GetParent());
	
	Modified = True;
	NewRow.Modified = True;
	
	Items.Operations.CurrentRow = NewRow.GetID();
	
	Return NewRow;
	
EndFunction

&AtClient
Procedure OperationsBeforeDeleteRowCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		
		DeleteOperations(AdditionalParameters.RowsIDs);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DeleteOperationsCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		
		DeleteOperations(AdditionalParameters.RowsIDs);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DeleteOperations(RowsIDs)
	
	DeleteOperationsOnServer(RowsIDs);
	
	TreeSortGroupClient();
	
	Modified = True;
	
EndProcedure

&AtServer
Procedure DeleteOperationsOnServer(RowsIDs)
	
	IndexesBeforeChange = IndexesOfOperations(ThisObject);
	
	RowsArray = New Array;
	GroupsArray1 = New Array;
		
	For Each RowID In RowsIDs Do
		RowData = Operations.FindByID(RowID);
		If ThisIsGroupOfIndividualOperations(RowData) Then
			For Each SubordinateLineData In RowData.GetItems() Do
				RowsArray.Add(SubordinateLineData);
			EndDo;
			GroupsArray1.Add(RowData);
		Else
			RowsArray.Add(RowData);
		EndIf;
	EndDo;
	
	For Each RowData In RowsArray Do
		ReflectChangesOfOperationResources(RowData.GetID());
		RowsCollection(ThisObject, RowData).Delete(RowData);
	EndDo;
	
	For Each RowData In GroupsArray1 Do
		RowsCollection(ThisObject, RowData).Delete(RowData);
	EndDo;
	
	CorrectNumberingOfOperations(ThisObject, IndexesBeforeChange);
	
	UpdateSupplyIndicatorsGeneral();
	
EndProcedure

&AtClient
Procedure DivideOperationsCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		
		SourceIdentificator = AdditionalParameters.RowID;
		
		IDIsNew = OperationsAddCopyClient(SourceIdentificator, True).GetID();
		
		OperationsShareEndATServer(Result, SourceIdentificator, IDIsNew);
		
		SaveCurrentLine(ThisObject, IDIsNew);
		
		TreeSortGroupClient();
		
		Modified = True;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OperationsShareEndATServer(Result, SourceIdentificator, ReceiverId)
	
	ConvertOfOperationToIndividualOne(SourceIdentificator);
	ConvertOfOperationToIndividualOne(ReceiverId);
	
	SourceRow = Operations.FindByID(SourceIdentificator);
	DestinationRow = Operations.FindByID(ReceiverId);
	
	SetAttributeOfLine(ThisObject, SourceRow, "Required2", SourceRow.Required2 - Result.Count, False);
	SetAttributeOfLine(ThisObject, DestinationRow, "ProductionArea", Result.ProductionArea, False);
	SetAttributeOfLine(ThisObject, DestinationRow, "WorkCenter", Result.WorkCenter, False);
	SetAttributeOfLine(ThisObject, DestinationRow, "Required2", Result.Count, False);
	
	ProcessAtServer = New Array;
	If SourceRow.WorkCenter <> DestinationRow.WorkCenter Then
		ProcessAtServer.Add("WorkCenter");
	EndIf;
	If SourceRow.ProductionArea <> DestinationRow.ProductionArea Then
		ProcessAtServer.Add("ProductionArea");
	EndIf;
	
	StructureOfData = ResourceStructureIsCurrent(ThisObject);
	
	SourceResources = RecalculateResourceStructureByCoefficient(StructureOfData, SourceRow.Required2 / (SourceRow.Required2 + DestinationRow.Required2));
	SaveResourcesOfIndividualOperation(SourceIdentificator, SourceResources);
	
	ReceiverResources = RecalculateResourceStructureByCoefficient(StructureOfData, DestinationRow.Required2 / (SourceRow.Required2 + DestinationRow.Required2));
	SaveResourcesOfIndividualOperation(ReceiverId, ReceiverResources);
	
	OnChangeOfOperationATServer(StrConcat(ProcessAtServer,","), ReceiverId);
	
EndProcedure

#EndRegion

#Region MovingNumbering

&AtClient
Procedure ShiftOfOperations(RowsIDs, ActionName)
	
	If Not ValueIsFilled(RowsIDs) Then
		Return;
	EndIf;
	
	If CheckAbilityToEditOperations(RowsIDs) Then
		
		TransactionList = Operations.GetItems();
		
		Indexes1 = IndexesOfOperations(ThisObject, RowsIDs);
		If ActionName = "MoveDownOfOperations" Then
			Offset = 1;
			Indexes1.SortByPresentation(SortDirection.Desc);
			If Number(Indexes1[0].Presentation) + Offset > TransactionList.Count() - 1 Then
				Offset = 0;
			EndIf;
		ElsIf ActionName = "MoveUpOfOperations" Then
			Offset = -1;
			Indexes1.SortByPresentation(SortDirection.Asc);
			If Number(Indexes1[0].Presentation) + Offset < InitialIndexOfEditing(ThisObject) Then
				Offset = 0;
			EndIf;
		Else
			Return;
		EndIf;
		
		If Offset = 0 Then
			Return;
		EndIf;
		
		For Each ListItem In Indexes1 Do
			CurrentIndex = Number(ListItem.Presentation);
			RowData = TransactionList[CurrentIndex];
			SetAttributeOfLine(ThisObject, RowData, "OperationNumber", RowData.OperationNumber + Offset);
			SetAttributeOfLine(ThisObject, RowData, "NextOperation", RowData.NextOperation + Offset);
			PerformShift = ?(Offset > 0,
				RowData.OperationNumber >= TransactionList[CurrentIndex+1].OperationNumber,
				RowData.OperationNumber <= TransactionList[CurrentIndex-1].OperationNumber);
			If PerformShift Then
				Indexes2 = IndexesOfOperations(ThisObject, RowsIDs, True);
				TransactionList.Move(CurrentIndex, Offset);
				CorrectNumberingOfOperations(ThisObject, Indexes2);
			EndIf;
		EndDo;
		
		UpdateSupplyIndicatorsGeneral();
		
		FillInServiceAttributesOfLinesOfOperations(ThisObject);
		
		Modified = True;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure CorrectNumberingOfOperations(Form, IndexesBeforeChange = Undefined)
	
	TransactionList = Form.Operations.GetItems();
	
	For IndexOf = 0 To TransactionList.Count() - 1 Do
		RowData = TransactionList[IndexOf];
		If IndexesBeforeChange <> Undefined Then
			FoundItem = IndexesBeforeChange.FindByValue(RowData.GetID());
			If FoundItem <> Undefined Then
				Delta = IndexOf - Number(FoundItem.Presentation);
				If Delta <> 0 Then
					SetAttributeOfLine(Form, RowData, "OperationNumber", RowData.OperationNumber + Delta);
					SetAttributeOfLine(Form, RowData, "NextOperation", RowData.NextOperation + Delta);
				EndIf;
			EndIf;
		EndIf;
		If IndexOf = TransactionList.Count() - 1 Then
			If RowData.NextOperation <> 0 Then
				SetAttributeOfLine(Form, RowData, "NextOperation", 0);
			EndIf;
		Else
			If RowData.NextOperation = 0 Then
				SetAttributeOfLine(Form, RowData, "NextOperation", RowData.OperationNumber + 1);
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Function IndexesOfOperations(Form, RowsIDs = Undefined, Exclude = False)
	
	Result = New ValueList();
	TransactionList = Form.Operations.GetItems();
	
	For Each String In TransactionList Do
		RowID = String.GetID();
		If RowsIDs = Undefined
				Or (RowsIDs.Find(RowID) <> Undefined And Exclude = False)
				Or (RowsIDs.Find(RowID) = Undefined And Exclude = True) Then
			Result.Add(RowID, IndexOfPresentation(TransactionList.IndexOf(String)));
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function IndexOfPresentation(IndexOf)
	
	Return Right("000000"+Format(IndexOf,"NG=;"), 6);
	
EndFunction

&AtClient
Procedure RenumberOperationsCompletion(InitialNumber, AdditionalParameters) Export
	
	If InitialNumber <> Undefined Then
		
		MinimumNumber_ = MinimumEditableNumber(ThisObject);
		If InitialNumber < MinimumNumber_ Then
			ShowMessageBox(, StrTemplate(NStr("vi = 'Số không được nhỏ hơn %1';
												|ru = 'Номер должен быть не меньше %1';
												|en = 'Number must be not less than %1'; fa = 'Number must be not less than %1';
												|it = 'Number must be not less than %1';
												|pl = 'Number must be not less than %1';
												|tr = 'Sayı en az %1 olmalıdır'"), MinimumNumber_));
			Return;
		EndIf;
		
		Number = InitialNumber;
		For Each ListItem In AdditionalParameters.RowIndexes Do
			RowData = Operations.FindByID(ListItem.Value);
			SetAttributeOfLine(ThisObject, RowData, "OperationNumber", Number);
			SetAttributeOfLine(ThisObject, RowData, "NextOperation", Number + 1);
			Number = Number + 1;
		EndDo;
		
		CorrectNumberingOfOperations(ThisObject);
		
		TreeSortGroupClient();
		
		Modified = True;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function LastNumber(Form)
	
	TransactionList     = Form.Operations.GetItems();
	OperationsCount = TransactionList.Count();
	
	Return ?(OperationsCount > 0, TransactionList[OperationsCount-1].OperationNumber, 0);
	
EndFunction

&AtClientAtServerNoContext
Function PreviousOperations_(Form, Cursor)
	
	RowsCollection = Form.Operations.GetItems();
	
	PreviousByNumber  = New Array;
	PreviousByIndex = New Array;
	
	CursorIndex = ?(ThisIsIndividualOperationInGroup(Cursor),
		RowsCollection.IndexOf(Cursor.GetParent()),
		RowsCollection.IndexOf(Cursor));
	
	RowData = Undefined;
	While NextRow(Form, RowData) Do
		If RowData.NextOperation = Cursor.OperationNumber
			And Not ThisIsGroupOfIndividualOperations(RowData) Then
			PreviousByNumber.Add(RowData);
		EndIf;
		CurrentIndex = ?(ThisIsIndividualOperationInGroup(RowData),
			RowsCollection.IndexOf(RowData.GetParent()),
			RowsCollection.IndexOf(RowData));
		If CurrentIndex = CursorIndex -1
			And Not ThisIsGroupOfIndividualOperations(RowData) Then
			PreviousByIndex.Add(RowData);
		EndIf;
	EndDo;
	
	Result = New Structure;
	Result.Insert("ByANumber", PreviousByNumber);
	Result.Insert("ByIndex", PreviousByIndex);
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function MinimumEditableNumber(Form)
	
	If ThereAreBlockedOfOperations(Form) Then
		TransactionList = Form.Operations.GetItems();
		Result = TransactionList[InitialIndexOfEditing(Form)-1].OperationNumber+1;
	Else
		Result = 1;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#Region ResourcesOfOperations

// List of resources.
// 
// Parameters:
// 	Form - ClientApplicationForm
//  ToArray - Boolean - the need to collapse into an array
// 
// Returns:
//  String, Array of String - List of Resources
&AtClientAtServerNoContext
Function ListOfResources(Form, ToArray = False)
	
	ListOfData = CommonClientServer.StructureKeysToString(ListOfResourcesToFillInNSI(Form));
	
	If ToArray Then
		Return StrSplit(ListOfData, ",");
	Else
		Return ListOfData;
	EndIf;
	
EndFunction

// List of resources for transferring NSI data (specification, route map) of operations to the editor and software
// 
// Parameters:
// 	Form - ClientApplicationForm
// 	TakeIntoAccountDivisionParameters - Boolean
// 
// Returns:
//  Structure
&AtClientAtServerNoContext
Function ListOfResourcesToFillInNSI(Form, TakeIntoAccountDivisionParameters = False)
	
	Result = New Structure;
	
	If Form.DivisionParameters.UseFinishedProductsInOperations
		Or Not TakeIntoAccountDivisionParameters Then
		Result.Insert("ManufacturedProducts", "ManufacturedProducts,RecyclableWaste");
	EndIf;
	If Form.DivisionParameters.UseMaterialsInOperations
		Or Not TakeIntoAccountDivisionParameters Then
		Result.Insert("MaterialsAndServices", "MaterialsAndServices");
	EndIf;
	Result.Insert("LaborCosts", "LaborCosts");
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function ListOfResourcesConvolutionParameters(TSName)
	
	Result = New Structure("GroupingColumns,TotalingColumns");
	
	If TSName = "ManufacturedProducts" Then
		Result.GroupingColumns = "Products,Characteristic,Package";
		Result.TotalingColumns = "NumberOfPackages,Count";
	ElsIf TSName = "MaterialsAndServices" Then
		Result.GroupingColumns = "Products,Characteristic,Package,ProductCostElement,ItemsType";
		Result.TotalingColumns = "NumberOfPackages,Count";
	ElsIf TSName = "LaborCosts" Then
		Result.GroupingColumns = "WorkKind,ProductCostElement";
		Result.TotalingColumns = "Count";
	EndIf;
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function ListOfResourcesCheckFilling(TSName, RowData)
	
	Result = New Array;
	
	If TSName = "ManufacturedProducts" Then
		Result.Add("Products");
		Result.Add("NumberOfPackages");
	ElsIf TSName = "MaterialsAndServices" Then
		Result.Add("Products");
		Result.Add("NumberOfPackages");
		If ThisOperationIsIndividual(RowData) And Not RowData.ReadOnly Then
			Result.Add("ProductCostElement");
		EndIf;
	ElsIf TSName = "LaborCosts" Then
		Result.Add("WorkKind");
		Result.Add("Count");
		If ThisOperationIsIndividual(RowData) And Not RowData.ReadOnly Then
			Result.Add("ProductCostElement");
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function ThereAreItemsPackagingUnitsOfVHF(TSName)
	
	Return TSName = "ManufacturedProducts" Or TSName = "MaterialsAndServices";
	
EndFunction

&AtServer
Function ResourceStorageKey(RowData)
	
	If ThisIsGroupOfIndividualOperations(RowData) Then
		Return Undefined;
	EndIf;
	
	DataHashing = New DataHashing(HashFunction.MD5);
	
	If ThisIsStandardProcessTechnology(Object) Or ThisIsAlternativeProcessTechnology(Object) Then
		DataHashing.Append(String(Object.TechnologicalProcess.UUID()));
		DataHashing.Append(String(Object.TechnologicalProcessFactor));
	ElsIf ValueIsFilled(RowData.TechnologicalProcess) Then
		DataHashing.Append(String(RowData.TechnologicalProcess.UUID()));
		DataHashing.Append(String(RowData.TechnologicalProcessFactor)); 
	ElsIf ThisIsOperationOfOperationAccordingToBillOfMaterials(RowData) Then
		DataHashing.Append(String(Object.BillOfMaterials.UUID()));
	Else
		DataHashing.Append(String(RowData.OperationID));
	EndIf;
	
	Return DataHashing.HashSum;
	
EndFunction

&AtServer
Function ResourceStorageStructure(RowData, ResourcesCache)
	
	If ResourcesCache = Undefined Then
		ResourcesCache = New Map();
	EndIf;
	
	TechnologicalProcess    = RowData.TechnologicalProcess;
	TechnologicalProcessType = TypeOf(RowData.TechnologicalProcess);
	
	SpecificationData = ResourcesCache.Get("SpecificationData");
	If SpecificationData = Undefined
		And ValueIsFilled(Object.BillOfMaterials) Then
		ItemData_3 = Catalogs.BillsOfMaterials.ProductData_5();
		FillPropertyValues(ItemData_3, Object);
		ListOfData = "ManufacturedProducts,RecyclableWaste,MaterialsAndServices,LaborCosts,Operations";
		SelectionParameters = Catalogs.BillsOfMaterials.DataSamplingParameters(ListOfData);
		SelectionParameters.OverridingReleasePartySetting.Use = True;
		SelectionParameters.OverridingReleasePartySetting.ProductionIssueByCustomPortions = True;
		SelectionParameters.IntermediateSemiFinishedProducts = ProductDataManagementClientServer.IntermediateSemiFinishedProductsGet();
		SpecificationData = Catalogs.BillsOfMaterials.SpecificationDataByProducts(
								ItemData_3, SelectionParameters, New Structure("Stage", Object.BOMStage));
		ResourcesCache.Insert("SpecificationData", SpecificationData);
	EndIf;
	
	If ThisIsStandardProcessBillOfMaterials(Object)
		Or ThisIsOperationOfOperationAccordingToBillOfMaterials(RowData)
		Or ValueIsFilled(TechnologicalProcess)
			And TechnologicalProcessType = Type("CatalogRef.TechnologicalProcesses")
			And SpecificationData <> Undefined
			And SpecificationData.Operations.FindRows(FilterOperations(RowData)).Count() > 0 Then
		
		StructureOfData = SpecificationData;
		
	Else
		
		Var_Key = ResourceStorageKey(RowData);
		If Var_Key <> Undefined Then
			StructureOfData = ResourcesCache.Get(Var_Key);
			If StructureOfData <> Undefined Then
				Return StructureOfData;
			EndIf;
		EndIf;
		
		If ValueIsFilled(TechnologicalProcess)
			And TechnologicalProcessType = Type("CatalogRef.TechnologicalProcesses") Then
			
			ItemData_3 = Catalogs.TechnologicalProcesses.ItemData_3();
			FillPropertyValues(ItemData_3, Object);
			StructureOfData = Catalogs.TechnologicalProcesses.ProcessDataByNomenclature(
				TechnologicalProcess,
				RowData.TechnologicalProcessFactor,
				ItemData_3,
				Catalogs.TechnologicalProcesses.DataSamplingParameters("MaterialsAndServices,LaborCosts"));
			
		ElsIf ValueIsFilled(TechnologicalProcess)
			And TechnologicalProcessType = Type("CatalogRef.RouteSheets") Then
			
			StructureOfData = Catalogs.RouteSheets.RouteMapData(
				TechnologicalProcess,
				RowData.TechnologicalProcessFactor,
				Object.Products,
				Object.Characteristic);
			StructureOfData.Insert("MaterialsAndServices", StructureOfData.UsedMaterials);
			
		ElsIf ThisOperationIsIndividual(RowData)
			And ValueIsFilled(RowData.ProductionOperation) Then
			
			TSData = Common.ObjectAttributesValues(
				RowData.ProductionOperation, New Structure(ListOfResources(ThisObject),,"MaterialsAndWorks"));
			StructureOfData = Common.CopyRecursive(GetFromTempStorage(Cache.DescriptionOfResources));
			For Each TSName In ListOfResources(ThisObject, True) Do
				For Each String In TSData[TSName].Unload() Do
					Table = StructureOfData[TSName]; // ValueTable
					FillPropertyValues(Table.Add(), String);
				EndDo;
				If TSName = "MaterialsAndServices" Then
					StructureOfActions = New Structure;
					StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
					ProductsServer.FillInServiceDetailsForProductInCollection(StructureOfData[TSName], StructureOfActions);
				EndIf;
			EndDo;
			
		ElsIf ThisIsGroupOfIndividualOperations(RowData) Then
			
			StructureOfData = New Structure;
			For Each SubordinateLineData In RowData.GetItems() Do
				SupplementResourceStructure(StructureOfData, ResourceStorageStructure(SubordinateLineData, ResourcesCache));
			EndDo;
			
		Else
			
			StructureOfData = Undefined;
			
		EndIf;
		
		If Var_Key <> Undefined Then
			ResourcesCache.Insert(Var_Key, StructureOfData);
			SaveResourceCache(ResourcesCache);
		EndIf;
		
	EndIf;
	
	Return StructureOfData;
	
EndFunction

&AtServer
Function OperationResourceStorageStructure(RowData, ResourcesCache = Undefined, ConvertToQuantity = Undefined)
	
	Result = New Structure;
	
	If ResourcesCache = Undefined Then
		ResourcesCache = GetCacheOfResources();
	EndIf;
	
	StructureOfData = ResourceStorageStructure(RowData, ResourcesCache);
	
	If StructureOfData = Undefined Then
		Return Undefined;
	EndIf;
	
	ZoomRatio = 1;
	
	If ResourcesCache.Get("SpecificationData") = StructureOfData Then
		
		FoundRows = StructureOfData.Operations.FindRows(FilterOperations(RowData));
		If FoundRows.Count() = 0 Then
			Return Undefined;
		EndIf;
		
		For Each KeyAndValue In ListOfResourcesToFillInNSI(ThisObject) Do
			TSName    = KeyAndValue.Key;
			ArrayTS = StrSplit(KeyAndValue.Value,",");
			Table  = Undefined; // ValueTable
			If Not Result.Property(TSName, Table) Then
				Table = GetFromTempStorage(Cache.DescriptionOfResources)[TSName].Copy();
			EndIf;
			For Each NameTCHNSI In ArrayTS Do
				If StructureOfData.Property(NameTCHNSI) Then
					For Each String In StructureOfData[NameTCHNSI] Do
						If Catalogs.BillsOfMaterials.DataLineOfBillOfMaterialsBelongsToOperation(
							FoundRows[0], String, NameTCHNSI = "ManufacturedProducts" Or NameTCHNSI ="RecyclableWaste") Then
							FillPropertyValues(Table.Add(), String);
						EndIf;
					EndDo;
				EndIf;
			EndDo;
			Result.Insert(TSName, Table);
		EndDo;
		
		If FoundRows[0].QuantityPerBatch > 0 Then
			ZoomRatio = ?(ConvertToQuantity <> Undefined, ConvertToQuantity, RowData.Required2) / FoundRows[0].QuantityPerBatch;
		EndIf;
		
	Else
		
		FilterOperations = New Structure("Operation", RowData.Operation);
		
		For Each KeyAndValue In ListOfResourcesToFillInNSI(ThisObject) Do
			TSName    = KeyAndValue.Key;
			ArrayTS = StrSplit(KeyAndValue.Value,",");
			Table  = Undefined; // ValueTable
			If Not Result.Property(TSName, Table) Then
				Table = GetFromTempStorage(Cache.DescriptionOfResources)[TSName].Copy();
			EndIf;
			For Each NameTCHNSI In ArrayTS Do
				MasterDataTable = Undefined; // ValueTable
				If StructureOfData.Property(NameTCHNSI, MasterDataTable) Then
					For Each String In ?(
							MasterDataTable.Columns.Find("Operation") <> Undefined, MasterDataTable.FindRows(FilterOperations), MasterDataTable) Do
						FillPropertyValues(Table.Add(), String);
					EndDo;
				EndIf;
			EndDo;
			Result.Insert(TSName, Table);
		EndDo;
		
		If ThisIsAlternativeProcessTechnology(Object) And ThisIsProcessOperation(RowData) Then
			ProductionProcessEditor.AddResourcesBillOfMaterials(
				Result,
				ResourcesCache.Get("SpecificationData"),
				ProductionProcessEditor.ListOfDataWhenAddingResourcesBillOfMaterials(RowData));
		EndIf;
		
		If ConvertToQuantity <> Undefined Then
			ZoomRatio = ConvertToQuantity / RowData.Required2;
		EndIf;
		
	EndIf;
	
	Return RecalculateResourceStructureByCoefficient(Result, ZoomRatio);
	
EndFunction

&AtClientAtServerNoContext
Function ResourceStructureIsCurrent(Form)
	
	StructureOfData = New Structure;
	
	For Each TSName In ListOfResources(Form, True) Do
		StructureOfData.Insert(TSName, Form.Object[TSName].Unload());
	EndDo;
	
	Return StructureOfData;
	
EndFunction

&AtServer
Procedure SupplementResourceStructure(ReceiverStructure, SourceStructure)
	
	If SourceStructure = Undefined Then
		Return;
	EndIf;
	
	For Each KeyAndValue In SourceStructure Do
		Table = Undefined; // ValueTable
		If Not ReceiverStructure.Property(KeyAndValue.Key, Table) Then
			ReceiverStructure.Insert(KeyAndValue.Key, KeyAndValue.Value.Copy());
		Else
			For Each String In KeyAndValue.Value Do
				FillPropertyValues(Table.Add(), String);
			EndDo;
			ConvolutionParameters = ListOfResourcesConvolutionParameters(KeyAndValue.Key);
			Table.GroupBy(ConvolutionParameters.GroupingColumns, ConvolutionParameters.TotalingColumns);
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Function RecalculateResourceStructureByCoefficient(StructureOfData, ZoomRatio)
	
	If ZoomRatio = 1 Then
		Return StructureOfData; // Structure
	EndIf;
	
	Result = New Structure;
	
	For Each TSName In ListOfResources(ThisObject, True) Do
		Table1 = New ValueTable;
		If StructureOfData.Property(TSName, Table1) Then
			Table2 = Table1.Copy();
			For Each String In Table2 Do
				For Each AttributeName In StrSplit(ListOfResourcesConvolutionParameters(TSName).TotalingColumns, ",") Do
					String[AttributeName] = String[AttributeName] * ZoomRatio;
				EndDo;
			EndDo;
			Result.Insert(TSName, Table2);
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

&AtServer
Procedure LoadResourcesOfOperationsIntoObject(RowID)
	
	ClearTables(ListOfResources(ThisObject));
	
	RowData = Operations.FindByID(RowID);
	If RowData = Undefined Then
		Return;
	EndIf;
	
	StructureOfData = OperationResourceStorageStructure(RowData);
	
	If StructureOfData <> Undefined Then
		For Each TSName In ListOfResources(ThisObject, True) Do
			Table = Undefined; // ValueTable
			If StructureOfData.Property(TSName, Table) Then
				Object[TSName].Load(Table);
			EndIf;
			If ThereAreItemsPackagingUnitsOfVHF(TSName) Then
				FillInServiceAttributesOfItemInLines(TSName);
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Procedure SaveResourcesOfIndividualOperation(RowID, StructureOfData = Undefined)
	
	RowData = Operations.FindByID(RowID);
	If RowData = Undefined
		Or Not ThisOperationIsIndividual(RowData) Then
		Return;
	EndIf;
	
	Resources = ?(StructureOfData = Undefined, ResourceStructureIsCurrent(ThisObject), StructureOfData);
	
	ResourcesCache = GetCacheOfResources();
	
	ResourcesCache.Insert(ResourceStorageKey(RowData), Resources);
	
	SaveResourceCache(ResourcesCache);
	
	ReflectChangesOfOperationResources(RowID, Resources);
	
EndProcedure

&AtServer
Procedure ReflectChangesOfOperationResources(RowID, StructureOfData = Undefined)
	
	RowData = Operations.FindByID(RowID);
	If RowData = Undefined Then
		Return;
	EndIf;
	
	If Not ThisIsGroupOfIndividualOperations(RowData) Then
		
		Filter = New Structure("OperationID", RowData.OperationID);
		For Each FoundRow In ResourceTable.FindRows(Filter) Do
			ResourceTable.Delete(FoundRow);
		EndDo;
		
		If StructureOfData <> Undefined Then
			For Each TSName In ListOfResources(ThisObject, True) Do
				Table = Undefined; // ValueTable
				If StructureOfData.Property(TSName, Table) Then
					For IndexOf = 0 To Table.Count() - 1 Do
						NewRow = ResourceTable.Add();
						NewRow.OperationID = RowData.OperationID;
						NewRow.TSName = TSName;
						NewRow.Order = IndexOf + 1;
						FillPropertyValues(NewRow, Table[IndexOf]);
					EndDo;
				EndIf;
			EndDo;
		EndIf;
		
	EndIf;
	
	UpdateResourceAvailabilityIndicatorsGeneral(ThisObject, RowID, StructureOfData);
	
EndProcedure

&AtClientAtServerNoContext
Function ResourceIndicatorsConstructor(CalculationOfResults = False)
	
	Result = New Structure;
	
	Result.Insert("ThereAreOutputProducts",  ?(CalculationOfResults, False, "ManufacturedProducts"));
	Result.Insert("ThereAreMaterialsAndServices", ?(CalculationOfResults, False, "MaterialsAndServices"));
	Result.Insert("ThereAreLaborCosts",     ?(CalculationOfResults, False, "LaborCosts"));
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Procedure ResourceIndicatorsFillInImages(RowData)
	
	RowData.ThereAreOutputProductsPicture = ?(RowData.ThereAreOutputProducts,
		PictureLib.ManufacturingProcessCheckboxGray, Undefined);
	RowData.ThereAreMaterialsAndServicesPicture = ?(RowData.ThereAreMaterialsAndServices,
		PictureLib.ManufacturingProcessCheckboxGray, Undefined);
	RowData.ThereAreMaterialsAndServicesPicture = ?(RowData.RequiresSupply,
		PictureLib.OrderStructureMaterial, RowData.ThereAreMaterialsAndServicesPicture);
	RowData.ThereAreLaborCostsPicture= ?(RowData.ThereAreLaborCosts,
		PictureLib.ManufacturingProcessCheckboxGray, Undefined);
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateResourceAvailabilityIndicatorsGeneral(Form, RowID, StructureOfData)
	
	RowData = Form.Operations.FindByID(RowID);
	If RowData = Undefined
		Or StructureOfData = Undefined Then
		Return;
	EndIf;
	
	For Each KeyAndValue In ResourceIndicatorsConstructor() Do
		
		TSName = KeyAndValue.Value;
		
		RowData[KeyAndValue.Key] = False;
		If StructureOfData.Property(TSName) Then
			RowData[KeyAndValue.Key] = StructureOfData[TSName].Count();
		EndIf;
		
	EndDo;
	
	ResourceIndicatorsFillInImages(RowData);
	
EndProcedure

&AtServer
Procedure UpdateSupplyIndicatorsGeneral()
	
	SecurityTable.Load(GetFromTempStorage(Cache.AddressOfStageSupplyTable));
	
	FilterSupply = New Structure("Products,Characteristic");
	FilterResources     = New Structure("TSName,OperationID", "MaterialsAndServices");
	
	RowData = Undefined;
	While NextRow(ThisObject, RowData, True) Do
		
		If ThisIsGroupOfIndividualOperations(RowData) Then
			Continue;
		EndIf;
		
		RowData.RequiresSupply = False;
		
		FilterResources.OperationID = RowData.OperationID;
		For Each StringMaterialOfOperation In ResourceTable.FindRows(FilterResources) Do
			FillPropertyValues(FilterSupply, StringMaterialOfOperation);
			FoundLinesSupply = SecurityTable.FindRows(FilterSupply);
			If FoundLinesSupply.Count() > 0 Then
				Software_1 = FoundLinesSupply[0];
			Else
				Software_1 = SecurityTable.Add();
				FillPropertyValues(Software_1, FilterSupply);
			EndIf;
			Software_1.QuantityInProcess = Software_1.QuantityInProcess + StringMaterialOfOperation.Count;
			Delta = Min(Software_1.QuantityInProcess - Software_1.QuantityPerStage, StringMaterialOfOperation.Count);
			If Delta > 0 Then
				If StringMaterialOfOperation.ItemsType = Enums.ItemsTypes.Work_5
					Or StringMaterialOfOperation.ItemsType = Enums.ItemsTypes.OperationService Then
					Software_1.NotProvide = Software_1.NotProvide + Delta;
				Else
					Software_1.ToSupply_ = Software_1.ToSupply_ + Delta;
				EndIf;
			EndIf;
			If Software_1.QuantityInProcess > Max(Software_1.QuantityPerStage, Software_1.QuantityInProcess) - Software_1.ToSupply_ Then
				RowData.RequiresSupply = True;
				If Software_1.NumberOfOperationExceeding = 0 Then
					Software_1.NumberOfOperationExceeding = RowData.OperationNumber;
				EndIf;
			EndIf;
		EndDo;
		
		ResourceIndicatorsFillInImages(RowData);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure UpdateCurrentSupplyIndicators()
	
	CurrentRow = Items.Operations.CurrentRow;
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	RowData = Operations.FindByID(CurrentRow);
	
	Filter = New Structure("Products,Characteristic");
	For Each String In Object.MaterialsAndServices Do
		FillPropertyValues(Filter, String);
		FoundRows = SecurityTable.FindRows(Filter);
		If ValueIsFilled(FoundRows)
			And FoundRows[0].NumberOfOperationExceeding <> 0
			And RowData.OperationNumber >= FoundRows[0].NumberOfOperationExceeding Then
			String.RequiresSupply = True;
		Else
			String.RequiresSupply = False;
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure FillInCalculationArticleInLines(TSName)
	
	If Not ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items[TSName]) Then
		Return;
	EndIf;
	
	Filter = New Structure;
	Filter.Insert("ExpenseType", ProductionClient.TypesOfCostsForChoosingCalculationArticle(TSName));
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", Filter);
	FormParameters.Insert("MultipleChoice", False);
	
	CallbackDescription = New CallbackDescription("FillInCalculationArticleInLinesCompletion", ThisObject, TSName);
	
	OpenForm(
		"Catalog.ProductCostElements.ChoiceForm",
		FormParameters,
		ThisObject,,,,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure FillInCalculationArticleInLinesCompletion(ClosingResult, TSName) Export

	If ClosingResult = Undefined Then
		Return;
	EndIf;
	
	SelectedRows = Items[TSName].SelectedRows;
	TabularSection = Object[TSName];
	
	HasChanges = False;
	For Each RowID In SelectedRows Do
		
		CurrentData = TabularSection.FindByID(RowID);
		
		If CurrentData.ProductCostElement <> ClosingResult Then
			CurrentData.ProductCostElement = ClosingResult;
			HasChanges = True;
		EndIf;
		
	EndDo;
	
	If HasChanges Then
		OnChangeOfOperation(TSName);
	EndIf;
	
EndProcedure

#Region Drag

&AtClient
Procedure DragStart(TSName, DragParameters, Perform)
	
	CurrentData = Items.Operations.CurrentData;
	If CurrentData = Undefined
		Or ThisIsGroupOfIndividualOperations(CurrentData) Then
		Perform = False;
	EndIf;
	
	Value = New Structure;
	Value.Insert("SourceIdentificator", CurrentData.GetID());
	Value.Insert("TSName", TSName);
	Value.Insert("Rows", DragParameters.Value);
	
	DragParameters.Value = Value;
	If CurrentData.ReadOnly Then
		DragParameters.AllowedActions = DragAllowedActions.Copy;
	Else
		DragParameters.AllowedActions = DragAllowedActions.CopyAndMove;
	EndIf;
	
EndProcedure

&AtServer
Procedure Drag(Action, Value)
	
	TSName            = Value.TSName;
	ConvolutionParameters = ListOfResourcesConvolutionParameters(TSName);
	
	SourceRow = Operations.FindByID(Value.SourceIdentificator);
	DestinationRow = Operations.FindByID(Value.ReceiverId);
	
	If SourceRow = Undefined Or DestinationRow = Undefined Then
		Return;
	EndIf;
	
	ReceiverResources = OperationResourceStorageStructure(DestinationRow);
	If ReceiverResources = Undefined Then
		Return;
	EndIf;
		
	If Not DestinationRow.ReadOnly Then
		DestinationRow.Modified = True;
		Table = ReceiverResources[TSName]; // ValueTable
		For Each RowID In Value.Rows Do
			RowData = Object[TSName].FindByID(RowID);
			FillPropertyValues(Table.Add(), RowData);
		EndDo;
		Table.GroupBy(ConvolutionParameters.GroupingColumns, ConvolutionParameters.TotalingColumns);
		ConvertOfOperationToIndividualOne(Value.ReceiverId, False);
		SaveResourcesOfIndividualOperation(Value.ReceiverId, ReceiverResources);
	EndIf;
	
	If Action = "Move" And Not SourceRow.ReadOnly Then
		SourceRow.Modified = True;
		For Each RowID In Value.Rows Do
			RowData = Object[TSName].FindByID(RowID);
			Object[TSName].Delete(RowData);
		EndDo;
		SourceResources = ResourceStructureIsCurrent(ThisObject);
		ConvertOfOperationToIndividualOne(Value.SourceIdentificator, False);
		SaveResourcesOfIndividualOperation(Value.SourceIdentificator, SourceResources);
	EndIf;
	
	UpdateSupplyIndicatorsGeneral();
	
	RowsArray = New Array;
	RowsArray.Add(SourceRow);
	RowsArray.Add(DestinationRow);
	
	For Each RowData In RowsArray Do
		If RowData.Modified Then
			FillInServiceAttributesOfLineOfOperation(ThisObject, RowData);
			FillInAttributesOfOFOperationGroup(ThisObject, RowData.GetParent());
			Modified = True;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region Supply

&AtServer
Function StageAssuranceTable()
	
	QueryText = 
	"SELECT
	|	Supply.Products           AS Products,
	|	Supply.Characteristic         AS Characteristic,
	|	SUM(Supply.Count)      AS Count
	|INTO TTSoftware
	|FROM
	|	Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS Supply
	|WHERE
	|	Supply.Ref = &Stage
	|	AND NOT Supply.Canceled
	|GROUP BY
	|	Supply.Products,
	|	Supply.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Expense.Products                AS Products,
	|	Expense.Characteristic              AS Characteristic,
	|	SUM(Expense.Count)           AS Count
	|INTO TTExpense
	|FROM
	|	Document.ProductionStage2_2.MaterialsAndWorksConsumption AS Expense
	|WHERE
	|	Expense.Ref = &Stage
	|GROUP BY
	|	Expense.Products,
	|	Expense.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(TTSoftware.Products, TTExpense.Products)          AS Products,
	|	ISNULL(TTSoftware.Characteristic, TTExpense.Characteristic)      AS Characteristic,
	|	ISNULL(TTSoftware.Count, 0)                                AS QuantityPerStage,
	|	0                                                                  AS QuantityInProcess,
	|	ISNULL(TTExpense.Count, 0)                                     AS Spent,
	|	0                                                                  AS ToSupply_,
	|	0                                                                  AS NotProvide
	|FROM
	|	TTSoftware AS TTSoftware
	|		FULL JOIN TTExpense AS TTExpense
	|		ON TTSoftware.Products = TTExpense.Products
	|			AND TTSoftware.Characteristic = TTExpense.Characteristic
	|";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Stage", Object.Stage);
	
	Result = Query.Execute().Unload();
	
	FilterFields = "Products,Characteristic";
	Filter = New Structure(FilterFields);
	
	DistributionOfStageInventory = DistributionOfStageInventory();
	DistributionOfStageInventory.Indexes.Add(FilterFields);
	
	For Each String In Result Do
		
		FillPropertyValues(Filter, String);
		For Each FoundRow In DistributionOfStageInventory.FindRows(Filter) Do
			If FoundRow.DemandCharacteristic = Enums.DemandCharacteristics.ToSupply Then
				String.ToSupply_ = String.ToSupply_ + FoundRow.Count;
			ElsIf FoundRow.DemandCharacteristic = Enums.DemandCharacteristics.NotProvide Then
				String.NotProvide = String.NotProvide + FoundRow.Count;
			EndIf;
		EndDo;
		
	EndDo;
	
	Return Result;
	
EndFunction

&AtServer
Function DistributionOfStageInventory()
	
	StageObject = Object.Stage.GetObject();
	
	EmbeddingParameters = Documents.ProductionStage2_2.AvailableRemainingEmbeddingOptions(StageObject);
	
	InternalParameters = New Structure("IsDocument", True);
	EmbeddingParameters.Insert("InternalParameters", InternalParameters);
	
	FormData1 = New Structure;
	FormData1.Insert("Object",                  StageObject);
	FormData1.Insert("UUID", StageObject.UUID);
	FormData1.Insert("Modified",      True);
	
	FormData1.Insert(
		"ProductionBatchData",
		Documents.ProductionStage2_2.ProductionBatchData(
			StageObject.ReferenceOrder,
			StageObject.AssignmentProducts,
			StageObject.ProductionLot));
	
	FormData1.Insert(
		"AvailableRemainingEmbeddingOptions",
		EmbeddingParameters);
		
	InventoryAllocationTable = ProvisionInDocumentsServer.InventoryAllocationForDocumentBeingEdited(
		False, FormData1, False);
		
	Return InventoryAllocationTable;
	
EndFunction

#EndRegion

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
	
	If NumberOfInserted > 0 Then
		OnChangeOfOperation(TSName);
	EndIf;
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboardOnServer(TSName)
	
	CompositionOfLines     = Undefined;
	FilterParameters = Undefined;
	
	If TSName = "ManufacturedProducts" Then
		CompositionOfLines = "Products,Characteristic,Package,NumberOfPackages";
	ElsIf TSName = "MaterialsAndServices" Then
		CompositionOfLines = "Products,Characteristic,Package,NumberOfPackages,ProductCostElement";
	ElsIf TSName = "LaborCosts" Then
		CompositionOfLines = "WorkKind,Count,ProductCostElement";
	EndIf;
	
	SelectGoods = TSName <> "LaborCosts";
	
	StructureOfActions = New Structure;
	
	If SelectGoods Then
		
		ArrayOfProductTypes = ProductDataManagementClientServer.ArrayOfAvailableItemTypes(ThisObject);
		FilterParameters = New Map;
		FilterParameters.Insert("Products.ItemsType", ArrayOfProductTypes);
		
		StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
		StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
		StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
		
	EndIf;
	
	LinesFromBuffer = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, CompositionOfLines);
	
	If Not ValueIsFilled(LinesFromBuffer) Then
		Return;
	EndIf;
	
	ObjectTable = Object[TSName]; // FormDataCollection
	RowsToProcess = New Array();
	
	For Each LineFromBuffer In LinesFromBuffer Do
		
		CurrentRow = ObjectTable.Add();
		FillPropertyValues(CurrentRow, LineFromBuffer);
		
		If SelectGoods Then
			RowsToProcess.Add(CurrentRow);
		EndIf;
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		ObjectTable);
	
EndProcedure

&AtServerNoContext
Function ThereAreLinesInClipboard()
	
	Return ProcessingOfTabularForms.ThereAreLinesInClipboard();
	
EndFunction

&AtClientAtServerNoContext
Procedure SetAvailabilityOfClipboardCommands(Form, BankingDetailsAreAvailable)
	
	Form.Items.ManufacturedProducts_InsertRows.Enabled = BankingDetailsAreAvailable;
	Form.Items.ContextMenuOutputItemsInsertLines.Enabled = BankingDetailsAreAvailable;
	
	Form.Items.MaterialsAndServicesInsertLines.Enabled = BankingDetailsAreAvailable;
	Form.Items.ContextMenuMaterialsAndServicesInsertLines.Enabled = BankingDetailsAreAvailable;
	
	Form.Items.LaborCostsInsertLines.Enabled = BankingDetailsAreAvailable;
	Form.Items.ContextMenuLaborCostsInsertLines.Enabled = BankingDetailsAreAvailable;
	
EndProcedure

#EndRegion

#Region ReadingWritingData

&AtClient
Function PrepareDataForEndOfEditing()
	
	Result = New Structure;
	
	Result.Insert("Department",      Object.Department);
	Result.Insert("Stage",               Object.Stage);
	Result.Insert("PresentationStage", PresentationStage);
	Result.Insert("Mode",              Mode);
	
	AddressOfStageDataToUpdate = PutToTempStorage(Undefined,
		?(Mode = ProductionProcessEditorClientServer.ModeFromStageForm(),
				FormOwner.UUID,
				UUID));
	Result.Insert("AddressOfStageDataToUpdate", AddressOfStageDataToUpdate);
	
	CommonClientServer.SupplementStructure(Result, PrepareDataToEndEditingATServer());
	
	Return Result;
	
EndFunction

&AtServer
Function PrepareDataToEndEditingATServer()
	
	Result = New Structure;
	
	Result.Insert("TechnicalProcessCheckHasBeenCompleted", CheckCompletionOfTechnicalProcess());
	
	If Result.TechnicalProcessCheckHasBeenCompleted Then
		
		ProcessRecordingParameters = ParametersOfProcessRecordingProcedure();
		Result.Insert("AddressOfProcessRecordingParameters",
			PutToTempStorage(ProcessRecordingParameters, UUID));
			
		StageUpdateParameters   = ParametersForUpdatingStageData();
		Result.Insert("AddressOfStageUpdateParameters",
			PutToTempStorage(StageUpdateParameters, UUID));
		Result.Insert("StageNeedsToBeUpdated", StageUpdateParameters.StageNeedsToBeUpdated);
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtClient
Function PrepareDataForCreatingTypicalProcessTechnology()
	
	Result = New Structure;
	
	CommonClientServer.SupplementStructure(Result, PrepareDataForCreatingTypicalProcessAtServer());
	
	Return Result;
	
EndFunction

&AtServer
Function PrepareDataForCreatingTypicalProcessAtServer()
	
	Result = New Structure;
	
	Result.Insert("TechnicalProcessCheckHasBeenCompleted", CheckCompletionOfTechnicalProcess("CreatingTechnicalProcess"));
	
	If Result.TechnicalProcessCheckHasBeenCompleted Then
		
		ProcessRecordingParameters = ParametersOfProcedureForCreatingTypicalTechnicalProcess();
		Result.Insert("AddressOfParametersForCreatingTypicalTechnicalProcess",
			PutToTempStorage(ProcessRecordingParameters, UUID));
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Function ParametersOfProcessRecordingProcedure()
	
	TechProcessParameters = ProductionProcessEditorClientServer.ProcessParametersConstructor();
	FillPropertyValues(TechProcessParameters, Object);
	
	Result = New Structure;
	Result.Insert("Stage", Object.Stage);
	Result.Insert("Department", Object.Department);
	Result.Insert("ReferenceOrder", Object.ReferenceOrder);
	Result.Insert("TechProcessParameters", TechProcessParameters);
	Result.Insert("ProductionOperations", Cache.ProductionOperations);
	Result.Insert("SaveTechnologicalProcessLimitations", Object.SaveTechnologicalProcessLimitations);
	
	If ThisIsIndividualTechnicalProcess(TechProcessParameters) Then
		
		ResourcesCache = GetCacheOfResources();
		
		TransactionTable = TableOfOperationsConstructor();
		ResourcesOfOperations = New Map;
		
		RowData = Undefined;
		While NextRow(ThisObject, RowData) Do
			If Not ThisIsGroupOfIndividualOperations(RowData) Then
				If ThisOperationIsIndividual(RowData) Then
					ResourcesOfOperation = OperationResourceStorageStructure(RowData, ResourcesCache);
					If ResourcesOfOperation <> Undefined Then
						ResourcesOfOperations.Insert(RowData.OperationID, ResourcesOfOperation);
					EndIf;
				EndIf;
				FillPropertyValues(TransactionTable.Add(), RowData);
			EndIf;
		EndDo;
		
		Result.Insert("TransactionTable", TransactionTable);
		Result.Insert("ResourcesOfOperations", ResourcesOfOperations);
	
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Function ParametersOfProcedureForCreatingTypicalTechnicalProcess()
	
	TechProcessParameters = ProductionProcessEditorClientServer.ProcessParametersConstructor();
	FillPropertyValues(TechProcessParameters, Object);
	
	Result = New Structure;
	Result.Insert("TechProcessParameters", TechProcessParameters);
	Result.Insert("PresentationStage", PresentationStage);
	Result.Insert("Department", Object.Department);
	Result.Insert("ProductKind", Object.ProductKind);
	
	ResourcesCache = GetCacheOfResources();
	
	TransactionTable = TableOfOperationsConstructor();
	ResourcesOfOperations = New Map;
	
	RowData = Undefined;
	While NextRow(ThisObject, RowData) Do
		If Not ThisIsGroupOfIndividualOperations(RowData) Then
			NewRow = TransactionTable.Add();
			FillPropertyValues(NewRow, RowData);
			NewRow.Count = NumberOfOperationsIsNormative(RowData);
			NewRow.Load   = RowData.LoadStandard;
			ResourcesOfOperation = OperationResourceStorageStructure(RowData, ResourcesCache, NewRow.Count);
			If ResourcesOfOperation <> Undefined Then
				ResourcesOfOperations.Insert(RowData.OperationID, ResourcesOfOperation);
			EndIf;
		EndIf;
	EndDo;
	
	Result.Insert("TransactionTable", TransactionTable);
	Result.Insert("ResourcesOfOperations", ResourcesOfOperations);
	
	Return Result;
	
EndFunction

&AtServer
Function ParametersForUpdatingStageData()
	
	TransactionTree = FormAttributeToValue("Operations");
	
	ProcessTechnologyResources = ProductionProcessEditor.TableOfProcessResources();
	For Each String In ResourceTable Do
		NewRow = ProcessTechnologyResources.Add();
		FillPropertyValues(NewRow, String);
		OperationData = TransactionTree.Rows.Find(String.OperationID, "OperationID", True);
		If OperationData <> Undefined Then
			NewRow.NameOfTheOperation = OperationData.Description;
			NewRow.OperationNumber        = OperationData.OperationNumber;
		EndIf;
	EndDo;
	ProductionServer.CollapseValueTable(ProcessTechnologyResources,,"Count"); 
	
	QueryOptions = ProductionProcessEditor.RequestParametersResourceMappingProcessStage();
	
	QueryOptions.ProcessTechnologyResources = ProcessTechnologyResources;
	QueryOptions.Stage               = Object.Stage;
	QueryOptions.Department      = Object.Department;
	QueryOptions.ReferenceOrder       = Object.ReferenceOrder;
	
	MappingTable = ProductionProcessEditor.ResourceComparisonTableProcessStage(QueryOptions);
	
	Result = New Structure("StageNeedsToBeUpdated", MappingTable.Find(True, "IsChanged") <> Undefined And StoreOperationsInBillsOfMaterials);
	
	If Result.StageNeedsToBeUpdated Then
		
		Result.Insert("ProcessTechnologyResources", ProcessTechnologyResources);
		Result.Insert("SecurityTable", SecurityTable.Unload());
		Result.Insert("MappingTable", MappingTable);
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtClient
Procedure CompleteEditing()
	
	ClearMessages();
	
	If Modified Then
		
		DataToEndEditing = PrepareDataForEndOfEditing();
		
		If Not DataToEndEditing.TechnicalProcessCheckHasBeenCompleted Then
			
			Return;
			
		ElsIf DataToEndEditing.StageNeedsToBeUpdated Then
			
			OpenForm("DataProcessor.ProductionProcessEditor.Form.UpdateStageData",
				DataToEndEditing,
				ThisObject,,,,
				New CallbackDescription("UpdateStageDataCompletion", ThisObject, DataToEndEditing));
			
		Else
			
			StartRecordingProcessData(DataToEndEditing);
			
		EndIf;
	
	Else
		
		Close(Undefined);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure StartRecordingProcessData(DataToEndEditing, CloseAtEnd = True)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Stage", Object.Stage);
	AdditionalParameters.Insert("Department", Object.Department);
	AdditionalParameters.Insert("CloseAtEnd", CloseAtEnd);
	
	Notification = New CallbackDescription("RecordingOfProcessDataEnd", ThisObject, AdditionalParameters);
	
	ProductionProcessEditorClient.StartRecordingProcessData(
		ThisObject, DataToEndEditing, Notification);
	
EndProcedure

&AtClient
Procedure RecordingOfProcessDataEnd(TimeConsumingOperation, AdditionalParameters) Export
	
	Result = ProductionProcessEditorClient.RecordingOfProcessDataEnd(
		ThisObject, TimeConsumingOperation, AdditionalParameters);
	
	If Result.CloseAtEnd Then
		
		Modified = False;
		
		Close(ClosingParameters());
		
	EndIf;
	
EndProcedure

&AtClient
Procedure QuestionCreateTypicalProcessEnd(QuestionResult, DataForCreatingTechnicalProcess) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		
		StartCreatingTypicalProcessTechnology(DataForCreatingTechnicalProcess);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure StartCreatingTypicalProcessTechnology(DataForCreatingTechnicalProcess)
	
	Notification = New CallbackDescription("CreatingTypicalProcessTechnologyCompletion", ThisObject);
	
	ProductionProcessEditorClient.StartCreatingTypicalProcessTechnology(
		ThisObject, DataForCreatingTechnicalProcess, Notification);
	
EndProcedure

&AtClient
Procedure CreatingTypicalProcessTechnologyCompletion(TimeConsumingOperation, AdditionalParameters) Export
	
	ProductionProcessEditorClient.CreatingTypicalProcessTechnologyCompletion(ThisObject, TimeConsumingOperation);
	
EndProcedure

&AtClient
Procedure QuestionReReadEnd(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		
		Initialize();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateStageDataCompletion(Result, DataToEndEditing) Export
	
	If Not ValueIsFilled(Result) Then
		Return;
	EndIf;
	
	If Result.RecordTechnicalProcess Then
		
		StartRecordingProcessData(DataToEndEditing);
		
	ElsIf Result.Property("CloseAtEnd") Then
		
		Modified = False;
		
		Close(ClosingParameters());
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	Item = ConditionalAppearance.Items.Add();
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.Operations.Name);
	
	AndGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Operations.ReadOnly");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.TechnologicalProcessType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = IndividualTechnicalProcess();
	
	Item.Appearance.SetParameterValue("BackColor", StyleColors.BackgroundColorOfUnavailableOperation);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	Item = ConditionalAppearance.Items.Add();
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.TimePerPiece.Name);
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.TimePerPieceUnitOfMeasure.Name);
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.SetupTime.Name);
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.SetupTimeUnitOfMeasure.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Operations.SynchronousLoad");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Show", False);
	
	//
	Item = ConditionalAppearance.Items.Add();
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.WorkTimeOnSynchronousLoad.Name);
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.UnitOfMeasureForSynchronousLoad.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Operations.SynchronousLoad");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Show", False);
	
	//
	Item = ConditionalAppearance.Items.Add();
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.TechnologicalProcess.Name);
	
	AndGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Operations.TechnologicalProcess");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Operations.Operation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.LightGray);
	Item.Appearance.SetParameterValue("Text", TextOfTechnicalProcessIsIndividual());
	
	//
	Item = ConditionalAppearance.Items.Add();
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.TechnologicalProcess.Name);
	
	AndGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Operations.TechnologicalProcess");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Operations.Operation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.LightGray);
	Item.Appearance.SetParameterValue("Text", TextProcessBillOfMaterials());
	
	//
	Item = ConditionalAppearance.Items.Add();
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.UnitOfMeasure.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Operations.UnitOfMeasure");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.LightGray);
	Item.Appearance.SetParameterValue("Text", ProductionManagementClientServer.PresentationOfUnitOfOperation(Undefined,,True));
	
	//
	ServiceDetails_ = ServiceAttributesOfOperations(ThisObject);
	
	//
	Item = ConditionalAppearance.Items.Add();
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.OperationNumber.Name);
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.NextOperation.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ServiceDetails_["ThisIsIndividualOperationInGroup"].ServicePath);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.LightGray);
	
	//
	Item = ConditionalAppearance.Items.Add();
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.Required2.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ServiceDetails_["ThisIsGroupOfIndividualOperations"].ServicePath);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	For Each KeyAndValue In ServiceDetails_ Do
		LongDesc = KeyAndValue.Value;
			
		If LongDesc.BlockForDifferences Then
		
			//
			Item = ConditionalAppearance.Items.Add();
			Item.Fields.Items.Add().Field = New DataCompositionField(Items[LongDesc.NameOfMainAttribute].Name);
			
			AndGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
			AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
			
			ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField(ServiceDetails_["ThisIsGroupOfIndividualOperations"].ServicePath);
			ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
			ItemFilter.RightValue = True;
			
			ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField(LongDesc.ServicePath);
			ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
			ItemFilter.RightValue = False;
			
			Item.Appearance.SetParameterValue("ReadOnly", True);
			Item.Appearance.SetParameterValue("TextColor", WebColors.LightGray);
			Item.Appearance.SetParameterValue("Text", LongDesc.GroupTextForDifferences);
		
		EndIf;
		
		If LongDesc.BulkEdit Then
		
			//
			Item = ConditionalAppearance.Items.Add();
			Item.Fields.Items.Add().Field = New DataCompositionField(Items[LongDesc.NameOfMainAttribute].Name);
			
			AndGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
			AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
			
			ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField(ServiceDetails_["ThisIsIndividualOperationInGroup"].ServicePath);
			ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
			ItemFilter.RightValue = True;
			
			ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField(LongDesc.ServicePath);
			ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
			ItemFilter.RightValue = False;
			
			ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField(LongDesc.PathOfMain);
			ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
			
			Item.Appearance.SetParameterValue("TextColor", WebColors.LightGray);
		
		EndIf;
		
	EndDo;
	
	//
	Item = ConditionalAppearance.Items.Add();
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.Required2.Name);
	
	AndGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Operations.Required2");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ServiceDetails_["ThisIsGroupOfIndividualOperations"].ServicePath);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	Enums.OperationStates.SetConditionalAppearanceOfState(
		ThisObject, "State", "Operations.State", "Operations.ThereAreCreated");
	
	//
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "ManufacturedProductsProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.ManufacturedProducts.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "MaterialsAndServicesProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.MaterialsAndServices.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);
	
	//
	Item = ConditionalAppearance.Items.Add();
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.MaterialsAndServicesRequiresSupply.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialsAndServices.RequiresSupply");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.LightGray);
	
	//
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(
		ThisObject, "ManufacturedProductsCharacteristic", "Object.ManufacturedProducts.ItemVariantsAreUsed");
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(
		ThisObject, "MaterialsAndServicesCharacteristic", "Object.MaterialsAndServices.ItemVariantsAreUsed");

EndProcedure

&AtServer
Procedure Initialize()
	
	QueryText = "
	|SELECT
	|	DocumentAttributes.Status                                                            AS Status,
	|	DocumentAttributes.ReferenceOrder                                                      AS ReferenceOrder,
	|	DocumentAttributes.Department                                                     AS Department,
	|	DocumentAttributes.BillOfMaterials                                                      AS BillOfMaterials,
	|	DocumentAttributes.Stage                                                              AS BOMStage,
	|	DocumentAttributes.LineOfBusiness                                           AS LineOfBusiness,
	|
	|	DocumentAttributes.ProductionLot.MainProductProducts                    AS Products,
	|	DocumentAttributes.ProductionLot.MainProductCharacteristic                  AS Characteristic,
	|	DocumentAttributes.NumberOfPackagesPlan                                            AS NumberOfPackagesPlan,
	|	DocumentAttributes.PackagePlan                                                      AS PackagePlan,
	|	DocumentAttributes.NumberOfPackagesPlan * ISNULL(&PackagingFactor, 1)        AS Count,
	|	DocumentAttributes.QuantityPerReleaseLotUnit                                  AS QuantityPerReleaseLotUnit,
	|
	|	DocumentAttributes.ProductionLot.MainProductProducts.ProductKind    AS ProductKind,
	|	DocumentAttributes.ReferenceOrder.EarliestStartDate                                        AS ProductionStart,
	|	DocumentAttributes.ReferenceOrder.Department                                        AS ProductionDispatcherBusinessUnit,
	|
	|	&TechProcessParameters
	|
	|FROM
	|	Document.ProductionStage2_2 AS DocumentAttributes
	|
	|	LEFT JOIN InformationRegister.TechnologicalProcessesOfProductionStages AS TechnicalProcess
	|	ON DocumentAttributes.Ref = TechnicalProcess.Stage
	|
	|WHERE
	|	DocumentAttributes.Ref = &Stage
	|";
	
	QueryTextPackagingFactor = Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"DocumentAttributes.PackagePlan",
		"DocumentAttributes.ProductionLot.MainProductProducts");
		
	QueryText = StrReplace(
		QueryText,
		"&PackagingFactor",
		QueryTextPackagingFactor);
		
	QueryText = StrReplace(QueryText,
		"&TechProcessParameters",
		ProductionProcessEditor.QueryTextParametersOfTechnicalProcessOfStage());
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Stage", Object.Stage);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	FillPropertyValues(Object, Selection);
	
	FillInServiceDetails();
	
	InitializeCache();
	
	FillInProcessData(True);
	
	CustomizeFormElements();
	
	Modified = False;
	
EndProcedure

&AtServer
Procedure FillInServiceDetails()
	
	StoreOperationsInBillsOfMaterials = GetFunctionalOption("StoreOperationsInBillsOfMaterials");
	UseOperationExecutionControl = GetFunctionalOption("UseOperationExecutionControl");
	
	LongTermOperationsStructure = New Structure("DataWriter,CreatingTypicalProcessTechnology");
	
	DivisionParameters = ProductionServer.ProductionBusinessUnitDescription(Object.Department);
	
	Object.SaveTechnologicalProcessLimitations = Not ThisIsIndividualTechnicalProcess(Object);
	
EndProcedure

&AtServer
Procedure FillInServiceAttributesOfItemInLines(TSName, FillInLines = Undefined)
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(
		Object[TSName], StructureOfActions, FillInLines);
	
EndProcedure

&AtServer
Procedure CustomizeFormElements()
	
	Items.ClassifierOfTechnologicalOperations.Visible      = StoreOperationsInBillsOfMaterials;
	Items.ProductionArea.Visible  = DivisionParameters.UseAreas;
	Items.Control.Visible = UseOperationExecutionControl And Not DivisionParameters.UseManufacturingExecutionSystem;
	Items.GroupTransferBatch.Visible = DivisionParameters.UseManufacturingExecutionSystem;
	Items.Continuous.Visible = DivisionParameters.UseManufacturingExecutionSystem;
	
	ReadOnly = ReadOnly
		Or (Object.Status = Enums.StatusesOfProductionStages2_2.Completed)
		Or Not AccessRight("Update", Metadata.Documents.ProductionStage2_2);
	
	Items.FormWriteAndClose.Enabled = Not ReadOnly;
	
	Items.OperationNumber.MinValue = MinimumEditableNumber(ThisObject);
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Items = Form.Items;
	Object = Form.Object;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	ItemsAvailability = Not Form.ReadOnly;
	Standard    = ThisIsStandardProcessTechnology(Object);
	AlternateType = ThisIsAlternativeProcessTechnology(Object);
	Individual_ = ThisIsIndividualTechnicalProcess(Object);
	
	DivisionParameters = Form.DivisionParameters;
	
	If AttributesStructure1.Property("TechnologicalProcess")
		Or Initialize Then
			
			ByRouteMap    = TypeOf(Object.TechnologicalProcess) = Type("CatalogRef.RouteSheets");
			LockedAttributesAvailable  = ThereAreBlockedOfOperations(Form);
			
			Items.FormReplaceWithAlternative.Enabled = ItemsAvailability And Not LockedAttributesAvailable;
			Items.FormReplaceWithStandard.Enabled    = ItemsAvailability And Not Standard And Not LockedAttributesAvailable;
			Items.FormReplaceItWithIndividualOne.Enabled = ItemsAvailability And Not Individual_ And Not DivisionParameters.UseManufacturingExecutionSystem;
			Items.FormChangeFactor.Enabled      = ItemsAvailability And Not LockedAttributesAvailable And (AlternateType Or ByRouteMap);
			Items.FormCreateTypicalTechnicalProcess.Enabled = Individual_;
			Items.EditingPanelGroup1.Enabled   = ItemsAvailability;
			
			Items.GroupEditingPanel.Visible      = Individual_;
			Items.AdditionSearch1.Visible                = Not Individual_;
			Items.Operations.ReadOnly                   = Not Individual_ Or Not ItemsAvailability;
			
			Items.Operations.EnableDrag          = Individual_;
			For Each TSName In ListOfResources(Form, True) Do
				Items[TSName].EnableStartDrag  = Individual_;
			EndDo;
			
			ConfigureProcessParametersLabel(Form);
			
	EndIf;
	
	If AttributesStructure1.Property("Operation")
		Or Initialize Then
		
		CurrentRow  = Items.Operations.CurrentRow;
		CurrentData  = ?(CurrentRow = Undefined, Undefined, Form.Operations.FindByID(CurrentRow));
		IsFolder      = ThisIsGroupOfIndividualOperations(CurrentData);
		Individual_1 = ThisOperationIsIndividual(CurrentData);
		IndividualInGroup = ThisIsIndividualOperationInGroup(CurrentData);
		
		AvailabilityOfOfOperationElements = ItemsAvailability And Individual_
			And CurrentData <> Undefined And Not CurrentData.ReadOnly;
		
		Items.GroupPageMain.ReadOnly         = Not AvailabilityOfOfOperationElements;
		Items.GroupPageOutputProducts.ReadOnly  = Not AvailabilityOfOfOperationElements Or IsFolder;
		Items.GroupPageMaterialsAndWorks.ReadOnly = Not AvailabilityOfOfOperationElements Or IsFolder;
		Items.GroupPageLaborCosts.ReadOnly     = Not AvailabilityOfOfOperationElements Or IsFolder;
		Items.GroupPageMore.ReadOnly    = Not AvailabilityOfOfOperationElements;
		
		Items.ClassifierOfTechnologicalOperations.ReadOnly                = Not AvailabilityOfOfOperationElements;
		Items.OperationKind.ReadOnly        = Not AvailabilityOfOfOperationElements;
		Items.SetupSettings.ReadOnly     = Not AvailabilityOfOfOperationElements Or Not CurrentData.SetupSettingsAreUsed;
		Items.Load.ReadOnly           = Not AvailabilityOfOfOperationElements Or Not CurrentData.ParallelLoad;
		Items.TransferLot.ReadOnly = Not AvailabilityOfOfOperationElements;
		Items.Control.ReadOnly           = Not AvailabilityOfOfOperationElements;
		Items.Repeatable.Visible          = Not Individual_;
		Items.Repeatable.ReadOnly     = Not AvailabilityOfOfOperationElements;
		Items.Skippable.ReadOnly    = Not AvailabilityOfOfOperationElements;
		Items.Continuous.ReadOnly        = True;
		Items.LongDesc.ReadOnly           = Not AvailabilityOfOfOperationElements;
		
		If Individual_ Then
			For Each KeyAndValue In ServiceAttributesOfOperations(Form) Do
				LongDesc = KeyAndValue.Value;
				If Not LongDesc.InPropertiesPanel Then
					Continue;
				EndIf;
				If LongDesc.MonitorForDifferences
					And Items[LongDesc.NameOfMainAttribute].Type = FormFieldType.InputField Then
					If IsFolder And Not CurrentData[LongDesc.NameOfServiceAttribute] Then
						Items[LongDesc.NameOfMainAttribute].InputHint = LongDesc.GroupTextForDifferences;
					ElsIf IndividualInGroup And Not CurrentData[LongDesc.NameOfServiceAttribute] Then
						Items[LongDesc.NameOfMainAttribute].InputHint = LongDesc.TextOfOperationForDifferences;
					Else
						Items[LongDesc.NameOfMainAttribute].InputHint = "";
					EndIf;
				EndIf;
				Items[LongDesc.NameOfMainAttribute].ReadOnly = Not AvailabilityOfOfOperationElements
					Or Items[LongDesc.NameOfMainAttribute].ReadOnly
					Or ?(IsFolder, Not CurrentData[LongDesc.NameOfServiceAttribute] And LongDesc.BlockForDifferences, False)
					Or ?(IndividualInGroup, Not CurrentData[LongDesc.NameOfServiceAttribute] And LongDesc.MonitorForDifferences, False);
			EndDo;
		EndIf;
		
		Items.SetupSettings.MarkIncomplete = AvailabilityOfOfOperationElements And Not IsFolder
			And Not Items.SetupSettings.ReadOnly And Not ValueIsFilled(CurrentData.SetupSettings);
		Items.Load.MarkIncomplete = AvailabilityOfOfOperationElements And Not IsFolder
			And Not Items.Load.ReadOnly And Not ValueIsFilled(CurrentData.Load);
		Items.Control.MarkIncomplete = AvailabilityOfOfOperationElements And Not IsFolder
			And Not ValueIsFilled(CurrentData.Control);
			
		Items.MaterialsAndServicesProductCostElement.AutoMarkIncomplete = Individual_1;
		Items.LaborCostsProductCostElement.AutoMarkIncomplete = Individual_1;
		
		Items.MaterialsAndServicesFillOutTheCalculationArticle.Enabled = AvailabilityOfOfOperationElements And Not IsFolder;
		Items.LaborCostsFillInTheCalculationArticle.Enabled = AvailabilityOfOfOperationElements And Not IsFolder;
		
		SetAvailabilityOfClipboardCommands(Form, AvailabilityOfOfOperationElements And ThereAreLinesInClipboard());
		
		If Form.UseOperationExecutionControl Then
			
			OptionsArray = ProductionAccountingClientServer.ControlOptionsForIndividualOfOperation(
				?(CurrentData <> Undefined, CurrentData.Control, Undefined));
			Items.Control.ChoiceList.LoadValues(OptionsArray);
			
		EndIf;
		
	EndIf;
	
	If Initialize
		Or AttributesStructure1.Property("InfoBar") Then
		
		Items.InformationPanelGroup.Visible = ValueIsFilled(Items.InfoBarLabel.Title);
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureProcessParametersLabel(Form)
	
	Object = Form.Object;
	
	RowsArray = New Array();
	
	RowsArray.Add(String(Object.TechnologicalProcessType));
	If Not ThisIsIndividualTechnicalProcess(Object) Then
		RowsArray.Add(",");
		If ThisIsStandardProcessBillOfMaterials(Object) Then
			RowsArray.Add(" ");
			RowsArray.Add(NStr("vi = 'theo bảng kê chi tiết các nguồn lực sản xuất';
								|ru = 'по спецификации';
								|en = 'by bill of materials'; fa = 'by bill of materials';
								|it = 'per specifica';
								|pl = 'wg specyfikacji';
								|tr = 'ürün reçetesine göre'"));
		ElsIf Not ValueIsFilled(Object.TechnologicalProcess) Then
			RowsArray.Add(" ");
			RowsArray.Add(NStr("vi = 'chưa chỉ ra';
								|ru = 'не задан';
								|en = 'not specified'; fa = 'مشخص نشده';
								|it = 'non impostato';
								|pl = 'nie określono';
								|tr = 'belirtilmedi'"));
		EndIf;
		RowsArray.Add(" ");
		If ValueIsFilled(Object.TechnologicalProcess) Then
			LinkString_ = String(Object.TechnologicalProcess);
			RowsArray.Add(New FormattedString(LinkString_, Form.Cache.ImportantLabelFont,,,"#OpenTechnologicalProcess"));
		EndIf;
	EndIf;
	
	Form.InscriptionProcessParameters = New FormattedString(RowsArray);
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		CompleteEditing();
	ElsIf QuestionResult = DialogReturnCode.No Then
		Modified = False;
		Close();
	EndIf;
	
EndProcedure

&AtServer
Procedure ClearTables(TablesNames = "")
	
	Tables = New Structure;
	Tables.Insert("Operations", Operations.GetItems());
	Tables.Insert("ManufacturedProducts", Object.ManufacturedProducts);
	Tables.Insert("MaterialsAndServices", Object.MaterialsAndServices);
	Tables.Insert("LaborCosts", Object.LaborCosts);
	
	For Each KeyAndValue In Tables Do
		If IsBlankString(TablesNames) Or StrFind(TablesNames, KeyAndValue.Key) > 0 Then
			Tables[KeyAndValue.Key].Clear();
		EndIf;
	EndDo;
	
EndProcedure

&AtServerNoContext
Procedure UnlockData(References, FormIdentifier)
	
	For Each Ref In References Do
		UnlockDataForEdit(Ref, FormIdentifier);
	EndDo;
	
EndProcedure

&AtServer
Procedure ProductsWhenChangedOnServer(TSName)
	
	CurrentData = Object[TSName].FindByID(Items[TSName].CurrentRow);
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	RowsArray = New Array;
	RowsArray.Add(CurrentData);
	FillInServiceAttributesOfItemInLines(TSName, RowsArray);
	
EndProcedure

&AtClient
Procedure WhenChangingNumberOfPackages(TSName)
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	
	BatchProcessingOfTablePartClient.ProcessTSString(Items[TSName].CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Function ClosingParameters()
	
	Result = New Structure;
	
	If Mode = ProductionProcessEditorClientServer.ModeFromStageForm() Then
		Result.Insert("AddressOfStageDataToUpdate", AddressOfStageDataToUpdate);
	EndIf;
	
	Return Result;
	
EndFunction

#Region Cache

&AtServer
Procedure InitializeCache()
	
	Cache = New Structure;
	Cache.Insert("AdditionalDataAddress");
	Cache.Insert("ImportantLabelFont", StyleFonts.ImportantLabelFont);
	Cache.Insert("ProductionOperations", New Array);
	Cache.Insert("RowActivation", False);
	Cache.Insert("BlockRows", New Array);
	
	StringTreeStructure = New Structure;
	For Each Column In FormAttributeToValue("Operations").Columns Do
		StringTreeStructure.Insert(Column.Name, Column.ValueType.AdjustValue(Undefined));
	EndDo;
	For Each KeyAndValue In ServiceAttributesOfOperations(ThisObject) Do
		AttributeName = KeyAndValue.Value.NameOfServiceAttribute;
		If StringTreeStructure.Property(AttributeName) Then
			StringTreeStructure.Delete(AttributeName);
		EndIf;
	EndDo;
	Cache.Insert("StringTreeStructure", StringTreeStructure);
	
	DataProcessorObject  = FormAttributeToValue("Object");
	DescriptionOfResources = New Structure;
	For Each TSName In ListOfResources(ThisObject, True) Do
		DescriptionOfResources.Insert(TSName, DataProcessorObject[TSName].UnloadColumns());
	EndDo;
	Cache.Insert("DescriptionOfResources", PutToTempStorage(DescriptionOfResources, UUID));
	
	StateArray = New Array;
	For Each Value In Enums.OperationStates Do
		StateArray.Add(Value);
	EndDo;
	Cache.Insert("StateArray", StateArray);
	
	StageAssuranceTable = StageAssuranceTable();
	Cache.Insert("AddressOfStageSupplyTable", PutToTempStorage(StageAssuranceTable, UUID));
	
	SaveResourceCache(Undefined);
	
EndProcedure

&AtServer
Function GetValueFromCache(Var_Key)
	
	Result = Undefined;
	
	GetServerCache().Property(Var_Key, Result);
	
	Return Result
	
EndFunction

&AtServer
Procedure PutValueInCache(Var_Key, Value)
	
	CacheServer = GetServerCache();
	
	CacheServer.Insert(Var_Key, Value);
	
	SaveServerCache(CacheServer);
	
EndProcedure

&AtServer
Function GetServerCache()
	
	If IsTempStorageURL(Cache.AdditionalDataAddress) Then
		Return GetFromTempStorage(Cache.AdditionalDataAddress);
	Else
		StructureOfData = New Structure;
		Return StructureOfData;
	EndIf;
	
EndFunction

&AtServer
Procedure SaveServerCache(StructureOfData)
	
	Cache.AdditionalDataAddress = PutToTempStorage(StructureOfData, UUID);
	
EndProcedure

&AtServer
Function GetCacheOfResources()
	
	ResourcesCache = GetValueFromCache("Resources");
	
	If ResourcesCache = Undefined Then
		ResourcesCache = New Map();
	EndIf;
	
	Return ResourcesCache;
	
EndFunction

&AtServer
Procedure SaveResourceCache(ResourcesCache)
	
	PutValueInCache("Resources", ResourcesCache);
	
EndProcedure

&AtClientAtServerNoContext
Function NewOperationID(Form)
	
	Result = Undefined;
	
	If Not Form.Cache.Property("NewOperationID", Result) Then
		Result = 0;
		RowData = Undefined;
		While NextRow(Form, RowData, True) Do
			Result = Max(RowData.OperationID, Result);
		EndDo;
	EndIf;
	
	Result = Result + 1;
	Form.Cache.Insert("NewOperationID", Result);
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function InitialIndexOfEditing(Form)
	
	Result = Undefined;
	TransactionList = Form.Operations.GetItems();
	
	If Not Form.Cache.Property("InitialIndexOfEditing", Result) Then
		Result = 0;
		RowData = Undefined;
		While NextRow(Form, RowData, False) Do
			If RowData.ReadOnly Then
				Result = Max(TransactionList.IndexOf(RowData)+1, Result);
			EndIf;
		EndDo;
		Form.Cache.Insert("InitialIndexOfEditing", Result);
	EndIf;
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function ThereAreBlockedOfOperations(Form)
	
	Result = Undefined;
	
	If Not Form.Cache.Property("ThereAreBlockedOfOperations", Result) Then
		Result = False;
		RowData = Undefined;
		While NextRow(Form, RowData) Do
			If RowData.ReadOnly Then
				Result = True;
				Break;
			EndIf;
		EndDo;
		Form.Cache.Insert("ThereAreBlockedOfOperations", Result);
	EndIf;
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Procedure ResetServiceCacheAttributes(Form)
	
	For Each Var_Key In StrSplit("NewOperationID,InitialIndexOfEditing,ThereAreBlockedOfOperations",",") Do
		If Form.Cache.Property(Var_Key) Then
			Form.Cache.Delete(Var_Key);
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region Constructors

// Table of operations constructor.
// 
// Returns:
//  ValueTable - Table of Operations Constructor
&AtServer
Function TableOfOperationsConstructor()
	
	Result = New ValueTable;
	
	For Each Column In FormAttributeToValue("Operations").Columns Do
		Result.Columns.Add(Column.Name, Column.ValueType);
	EndDo;
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function StringTreeStructureConstructor(Form)
	
	Result = New Structure;
	
	For Each KeyAndValue In Form.Cache.StringTreeStructure Do
		Result.Insert(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function ExecutionIndicators(Values = Undefined)
	
	Result = New Structure;
	
	Keys = "State,Assigned_,Scheduled,CreatedOn,Running,Completed2,UnderControl,UnderRevision,DefectiveGoods,Skipped3,ExecutionIsAllowed";
	For Each Var_Key In StrSplit(Keys, ",") Do
		Result.Insert(Var_Key, 0);
	EndDo;
	
	If Values <> Undefined Then
		FillPropertyValues(Result, Values);
	EndIf;
	
	Return Result;
	
EndFunction

// Description of the service Attribute constructor.
// 
// Parameters:
//  AttributeName - String - The name of the props
// 
// Returns:
//  Structure - Description Of The Service Attribute Constructor:
// * NameOfMainAttribute - String
// * NameOfServiceAttribute - String
// * Path - String
// * Type - TypeDescription
// * BulkEdit - Boolean
// * BlockForDifferences - Boolean
// * MonitorForDifferences - Boolean
// * GroupTextForDifferences - String
// * TextOfOperationForDifferences - String
// * AttributesOfDifferenceControl - String
// * InListColumn - Boolean
// * InPropertiesPanel - Boolean
&AtClientAtServerNoContext
Function DescriptionOfServiceAttributeConstructor(AttributeName)
	
	Result = New Structure;
	
	Result.Insert("NameOfMainAttribute", AttributeName);
	Result.Insert("PathOfMain", "Operations."+Result.NameOfMainAttribute);
	Result.Insert("NameOfServiceAttribute", AttributeName+"_");
	Result.Insert("ServicePath", "Operations."+Result.NameOfServiceAttribute);
	
	Result.Insert("GroupCalculation", True);
	Result.Insert("BulkEdit", False);
	
	Result.Insert("BlockForDifferences", False);
	Result.Insert("AttributesOfDifferenceControl", "");
	Result.Insert("MonitorForDifferences", False);
	Result.Insert("GroupTextForDifferences", NStr("vi = '-';
													|ru = '-';
													|en = '-'; fa = '-';
													|it = '-';
													|pl = '-';
													|tr = '-'"));
	Result.Insert("TextOfOperationForDifferences", NStr("vi = '-';
														|ru = '-';
														|en = '-'; fa = '-';
														|it = '-';
														|pl = '-';
														|tr = '-'"));
	
	Result.Insert("InListColumn", False);
	Result.Insert("InPropertiesPanel", False);
	
	Result.Insert("Type", New TypeDescription("Boolean"));
	Result.Insert("CurrentValue", Undefined);
	
	Return Result;
	
EndFunction

#EndRegion

#Region Constants

&AtClientAtServerNoContext
Function StandardProcessTechnology()
	Return PredefinedValue("Enum.TechnologicalProcessTypesOfStage.Standard");
EndFunction

&AtClientAtServerNoContext
Function ThisIsStandardProcessTechnology(Object)
	Return Object.TechnologicalProcessType = StandardProcessTechnology();
EndFunction

&AtClientAtServerNoContext
Function ThisIsStandardProcessBillOfMaterials(Object)
	Return Object.TechnologicalProcessType = StandardProcessTechnology()
		And TypeOf(Object.TechnologicalProcess) = Type("CatalogRef.BillsOfMaterials")
		And ValueIsFilled(Object.TechnologicalProcess);
EndFunction

&AtClientAtServerNoContext
Function AlternativeProcessTechnology()
	Return PredefinedValue("Enum.TechnologicalProcessTypesOfStage.AlternateType");
EndFunction

&AtClientAtServerNoContext
Function ThisIsAlternativeProcessTechnology(Object)
	Return Object.TechnologicalProcessType = AlternativeProcessTechnology();
EndFunction

&AtClientAtServerNoContext
Function IndividualTechnicalProcess()
	Return PredefinedValue("Enum.TechnologicalProcessTypesOfStage.Individual_");
EndFunction

&AtClientAtServerNoContext
Function ThisIsIndividualTechnicalProcess(Object)
	Return Object.TechnologicalProcessType = IndividualTechnicalProcess();
EndFunction

&AtClientAtServerNoContext
Function TextOfTechnicalProcessIsIndividual()
	Return NStr("vi = 'Riêng biệt';
				|ru = 'Индивидуальный';
				|en = 'Individual'; fa = 'شخص حقیقی';
				|it = 'Individual';
				|pl = 'Individual';
				|tr = 'Özelleştirilmiş'");
EndFunction

&AtClientAtServerNoContext
Function TextProcessBillOfMaterials()
	Return NStr("vi = 'Bảng kê chi tiết các nguồn lực sản xuất';
				|ru = 'Спецификация';
				|en = 'Bill of materials'; fa = 'فهرست مواد (BOM)';
				|it = 'Bill of materials';
				|pl = 'Bill of materials';
				|tr = 'Ürün reçetesi'");
EndFunction

&AtClientAtServerNoContext
Function ThisIsNSIOperation(RowData)
	Return ProductionProcessEditorClientServer.ThisIsNSIOperation(RowData);
EndFunction

&AtClientAtServerNoContext
Function ThisIsOperationOfOperationAccordingToBillOfMaterials(RowData)
	Return ProductionProcessEditorClientServer.ThisIsOperationOfOperationAccordingToBillOfMaterials(RowData);
EndFunction

&AtClientAtServerNoContext
Function ThisIsProcessOperation(RowData)
	Return ProductionProcessEditorClientServer.ThisIsProcessOperation(RowData);
EndFunction

&AtClientAtServerNoContext
Function ThisOperationIsIndividual(RowData)
	Return ProductionProcessEditorClientServer.ThisOperationIsIndividual(RowData);
EndFunction

&AtClientAtServerNoContext
Function ThisIsGroupOfIndividualOperations(RowData)
	Return ProductionProcessEditorClientServer.ThisIsGroupOfIndividualOperations(RowData);
EndFunction

&AtClientAtServerNoContext
Function ThisIsIndividualOperationInGroup(RowData)
	Return ProductionProcessEditorClientServer.ThisOperationIsIndividual(RowData)
		And RowData.GetParent() <> Undefined;
EndFunction

&AtClientAtServerNoContext
Function FilterOperations(RowData)
	Return New Structure("Operation,OperationID", RowData.Operation, RowData.OperationID);
EndFunction

&AtClientAtServerNoContext
Function BorderOfEditableStates()
	Return 7;
EndFunction

&AtClientAtServerNoContext
Function BoundaryOfFiniteStates()
	Return 3;
EndFunction

#EndRegion

#EndRegion

#EndRegion
