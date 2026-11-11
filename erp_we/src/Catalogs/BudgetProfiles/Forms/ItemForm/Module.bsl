#Region Variables

&AtServer
Var CurrentReportItem; // Undefined, CatalogRef.FinancialReportItems, String - the current item or its address in the temporary storage.

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	TableOfCombinations = FinancialReportingCached.AcceptableCombinationsOfBudgetElements();
	CacheOfValidCombinations = CreateCacheBasedOnCombinationTable(TableOfCombinations);
	
	TableOfCombinations = FinancialReportingCached.InvalidCombinationsOfBudgetElements();
	CacheOfInvalidCombinations = CreateCacheBasedOnCombinationTable(TableOfCombinations);
	
	UpdateTreeOfNewElements();
	UpdateElementTree(Parameters.CopyingValue);
	
	RefreshFormTitle();
	SetTextAnalystInHeader();
	
	// StandardSubsystems.ObjectAttributesLock
	ObjectAttributesLock.LockAttributes(ThisObject);
	// End StandardSubsystems.ObjectAttributesLock
	
	FormControl();
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	TreeElementsOfBudgetView = FormAttributeToValue("ReportItems");
	Catalogs.FinancialReportItems.WriteStructureOfReportView(CurrentObject.Ref, TreeElementsOfBudgetView, CurrentObject.DeletionMark);
	
	UpdateElementTree();
	
	If CurrentReportItem <> Undefined Then
		TreeRow = FinancialReportingServer.SubordinateItem(
			ReportItems,
			"ReportItem",
			CurrentReportItem);
		If TreeRow <> Undefined Then
			Items.DisplayReportItems.CurrentRow = TreeRow.GetID();
		EndIf;
	EndIf;
	
	RefreshFormTitle();
	
	// StandardSubsystems.ObjectAttributesLock
	ObjectAttributesLock.LockAttributes(ThisObject);
	// End StandardSubsystems.ObjectAttributesLock
	
	FormControl();
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Items.DisplayReportItems.Expand(DisplayReportItems.GetItems()[0].GetID(), True);

	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_NonFinancialItemsOfBudgets"
		Or EventName = "Write_BudgetFlowItems"
		Or EventName = "Write_BudgetBalanceItems"
		Or EventName = "Write_BudgetFlowItemDimensions" Then
		
		If ValueIsFilled(Parameter) And TypeOf(Parameter) = Type("String") Then
			If EventName = "Write_NonFinancialItemsOfBudgets" Then
				ItemKind = ItemKind("NonFinancialItem");
			ElsIf EventName = "Write_BudgetFlowItems" Then
				ItemKind = ItemKind("BudgetFlowItem");
			ElsIf EventName = "Write_BudgetBalanceItems" Then
				ItemKind = ItemKind("BudgetBalanceItem");
			Else
				ItemKind = ItemKind("Dimension");
			EndIf;
			RowsIDs = New Array;
			FillInRowIdsToUpdateName(RowsIDs, ItemKind, Source, Parameter);
			UpdateNamesOfReportElements(ReportItems, RowsIDs, ItemKind, Parameter, True);
			UpdateNamesOfReportElements(DisplayReportItems, RowsIDs, ItemKind, Parameter, False);
		EndIf;
		
		UpdateTreeOfNewElements();
		TreeRow = FinancialReportingClient.SubordinateElementOfFormElement(
			NewItemTree,
			"ReportingKindItem",
			Source);
		
		If TreeRow <> Undefined Then
			Items.NewItemTree.CurrentRow = TreeRow.GetID();
		EndIf;
		
	EndIf;
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	CurrentRow = Items.DisplayReportItems.CurrentRow;
	If CurrentRow <> Undefined Then
		TreeRow = ReportItems.FindByID(CurrentRow);
		If TreeRow <> Undefined Then
			CurrentReportItem = TreeRow.ReportItem;
		EndIf;
	EndIf;
	
	PreviousUsageFlag = Common.ObjectAttributeValue(Object.Ref, "UseToEnterPlan");
	If ValueIsFilled(Object.Ref)
		And Object.UseToEnterPlan <> PreviousUsageFlag Then
		
		ArrayOfViewsToUpdate = New Array;
		ArrayOfViewsToUpdate.Add(Enums.FinancialReportItemKinds.AllBudgetBalanceItems);
		ArrayOfViewsToUpdate.Add(Enums.FinancialReportItemKinds.AllBudgetFlowItems);
		ArrayOfViewsToUpdate.Add(Enums.FinancialReportItemKinds.BudgetFlowItem);
		ArrayOfViewsToUpdate.Add(Enums.FinancialReportItemKinds.BudgetBalanceItem);
		ArrayOfViewsToUpdate.Add(Enums.FinancialReportItemKinds.NonFinancialItem);
		
		ItemsTree = FormAttributeToValue("ReportItems");
		For Each UpdatedItem In ArrayOfViewsToUpdate Do
			ItemsToUpdate = ItemsTree.Rows.FindRows(New Structure("ItemKind", UpdatedItem), True);
			For Each TreeRow In ItemsToUpdate Do
				If Not ValueIsFilled(TreeRow.AddressOfItemStructure) Then
					TreeRow.AddressOfItemStructure = BudgetReportingClientServer.PlaceItemInStorage(TreeRow, UUID);
				EndIf;
			EndDo;
		EndDo;
		ValueToFormAttribute(ItemsTree, "ReportItems");
		
	EndIf;
	
	If ItemsTree = Undefined Then
		ItemsTree = FormAttributeToValue("ReportItems");
	EndIf;
	
	If Modified Then
		CurrentObject.ItemAndIndicatorCache.Load(GetCacheOfArticlesAndMetrics(ItemsTree));
	EndIf;
		
	CurrentObject.HasPrivilegedAccess = CurrentObject.ItemAndIndicatorCache.FindRows(
			New Structure("PrivilegedMode", True)).Count() > 0;
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If Not Cancel And ValueIsFilled(Object.Ref) And Modified Then
		
		SetPrivilegedMode(True);
	
		Set = InformationRegisters.CacheOfAuxiliaryBudgetProfileData.CreateRecordSet();
		Set.Filter.BudgetProfile.Set(Object.Ref);
		Set.Write();
		
		CleaningParameters = New Array;
		CleaningParameters.Add(Object.Ref);
		
		BackgroundJobs.Execute("BudgetingServer.DeleteSavedBudgetTemplates", CleaningParameters);
		
		SetPrivilegedMode(False);

	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement

	ConfigurationModificationOverridable.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	Items.DisplayReportItems.Expand(
		DisplayReportItems.GetItems()[0].GetID(), True);
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	Unverifiable = New Array;
	If Object.PlanningMethod = Enums.BudgetPreparationMethods.ForAFixedPeriod Then
		Unverifiable.Add("NumberOfPeriodsOfRollingBudget");
	EndIf;
	
	If Object.LocationOptionOfActualDataOffset <> Enums.LocationOptionsOfActualDataOffsets.BeforeBudgetPreparation Then
		Unverifiable.Add("ActualDataLimitOffset");
		Unverifiable.Add("ActualDataLimitTimeFence");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, Unverifiable);
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OwnerOnChange(Item)
	
	UpdateTreeOfNewElements();
	
EndProcedure

&AtClient
Procedure QuickSearchOfNewOnChange(Item)
	
	UpdateTreeOfNewElements();
	
EndProcedure

&AtClient
Procedure QuickSearchOfNewClearing(Item, StandardProcessing)
	
	UpdateTreeOfNewElements();
	
EndProcedure

&AtClient
Procedure FindNewItem(Command)
	
	UpdateTreeOfNewElements();
	
EndProcedure

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText, 
		ThisObject, 
		"Object.Comment");
	
EndProcedure

&AtClient
Procedure UseToEnterPlanOnChange(Item)
	
	UseToEnterPlanWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure TheBoundaryOfTheActualDataWhenChanging(Item)
	
	FormControl();
	
EndProcedure

&AtClient
Procedure PlanningMethodOnChange(Item)
	
	FormControl();
	
EndProcedure

&AtClient
Procedure RecommendationsForImprovingCalculationSpeed(Command)
	
	If Object.Ref.IsEmpty() Then
		WarningText = NStr("vi = 'Cần ghi lại dạng ngân sách để tính toán các khuyến nghị';
							|ru = 'Вид бюджета должен быть записан для расчета рекомендаций';
							|en = 'Save budget profile before calculating recommendations'; fa = 'Save budget profile before calculating recommendations';
							|it = 'Il tipo di budget deve essere registrato per calcolare i valori consigliati';
							|pl = 'Rodzaj budżetu musi być zapisany aby rozliczyć zalecenia';
							|tr = 'Bütçe profili önerilen hesaplama için kaydedilebilir'");
		ShowMessageBox(,WarningText);
		Return;
	EndIf;
	
	FilterValues = New Structure("BudgetProfile", Object.Ref);
	FormParameters = New Structure("Filter, GenerateOnOpen", FilterValues, True);
	OpenForm("Report.RecommendationsForImprovingBudgetEntryFormCalculationSpeed.Form", FormParameters);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDisplayReportItems

&AtClient
Procedure ReportItemsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	EditReportElement();
	
EndProcedure

&AtClient
Procedure ReportItemsBeforeDeleteRow(Item, Cancel)
	
	SelectedRows = Items.DisplayReportItems.SelectedRows;
	
	For Each ArrayElement In SelectedRows Do
	
		CurrentRow = DisplayReportItems.FindByID(ArrayElement);
		ItemKind = CurrentRow.ItemKind;
	
		If (ItemKind = ItemKind("EmptyRef") 
				And CurrentRow.GetParent() = Undefined)
			Or ItemKind = ItemKind("Columns")
			Or ItemKind = ItemKind("Rows")
			Or ItemKind = ItemKind("CellsSettings") Then
			
			Cancel = True;
			Return;
			
		EndIf;
	
	EndDo;
	
	ItemsList = New ValueList;
	For Each ArrayElement In SelectedRows Do
		
		CurrentRow = DisplayReportItems.FindByID(ArrayElement);
		ItemsList.Add(ReflectedLine(CurrentRow, ThisObject).GetID());
		For Cnt = 2 To Items.NameForPrinting.ChildItems.Count() Do
			If CurrentRow.Property("LineIndexOfReportItems"+ Cnt) Then 
				If CurrentRow["LineIndexOfReportItems" + Cnt] = Undefined Then
					Continue;
				EndIf;
				LineIndexOfReportItems = CurrentRow["LineIndexOfReportItems" + Cnt];
				ItemsList.Add(LineIndexOfReportItems);
			EndIf;
		EndDo;
		
	EndDo;
	
	ReportElementsBeforeDeletingOnServer(ItemsList);
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure ReportItemsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure ReportItemsDragStart(Item, DragParameters, Perform)
	
	TreeLineSender = "DisplayReportItems";
	
EndProcedure

&AtClient
Procedure ReportItemsDragCheck(Item, DragParameters, StandardProcessing, LineReceiverReflection, Field)
	
	StandardProcessing = False;
	CanBeAddedToStructure = True;
	
	DestinationRow = ReflectedLine(LineReceiverReflection, ThisObject);
	If DestinationRow <> Undefined Then
		DestinationRow = DestinationRow.GetID();
	EndIf;
	
	If TypeOf(DragParameters.Value) = Type("Array") Then
		For Each ElementViewStringReflection In DragParameters.Value Do
			CanBeAddedToStructure = DraggingIsAllowed(ElementViewStringReflection, DestinationRow);
			If Not CanBeAddedToStructure Then
				Break;
			EndIf;
		EndDo;
	Else
		CanBeAddedToStructure = DraggingIsAllowed(DragParameters.Value, DestinationRow);
	EndIf;
	
	If CanBeAddedToStructure Then
		If DragParameters.Action <> DragAction.Move
			And DragParameters.Action <> DragAction.Copy Then
			DragParameters.Action = DragAction.Move;
		EndIf;
	Else
		DragParameters.Action = DragAction.Cancel;
	EndIf;
	
EndProcedure

&AtClient
Procedure ReportItemsDrag(Item, DragParameters, StandardProcessing, LineReceiverReflection, Field)
	Cache = Undefined;
	
	If Items.DisplayReportItems.ReadOnly Then
		StandardProcessing = False;
		WarningText = NStr("vi = 'Dạng ngân sách được dùng trong các chứng từ và không thể chỉnh sửa';
							|ru = 'Вид бюджета используется в документах и недоступен для редактирования';
							|en = 'This budget profile is used in the documents. You cannot edit it'; fa = 'This budget profile is used in the documents. You cannot edit it';
							|it = 'Il tipo di budget è utilizzato nei documenti e non è modificabile';
							|pl = 'Rodzaj budżetu jest używany w dokumentach i nie może być edytowany';
							|tr = 'Bütçe profili belgelerde kullanılmaktadır ve düzenlemeye müsait değildir'");
		ShowMessageBox(,WarningText);
		Return;
	EndIf;
	
	DestinationRow = ReflectedLine(LineReceiverReflection, ThisObject);
	If DestinationRow <> Undefined Then
		DestinationRow = DestinationRow.GetID();
	EndIf;
	
	StandardProcessing = False;
	RowsArray = DragParameters.Value;
	If TypeOf(DragParameters.Value) <> Type("Array") Then
		RowsArray = New Array;
		RowsArray.Add(DragParameters.Value);
	EndIf;
	
	IdsOfTransferredLines = New Array;
	
	If TreeLineSender = Item.Name Then
		For Each PortableString In RowsArray Do
			If IdsOfTransferredLines.Find(PortableString) <> Undefined Then
				// The line was subordinate to the already transferred line
				Continue;
			EndIf;
			ReflectedLine = ReflectedLine(PortableString, ThisObject);
			MoveLine(ReportItems,
					ReflectedLine.GetID(),
					DestinationRow,
					DragParameters.Action = DragAction.Copy,
					IdsOfTransferredLines,
					Cache);
		EndDo;
	Else
		If DestinationRow = Undefined Then
			TreeRoot = FinancialReportingClient.RootElementOfFormElement(ReportItems);
			DestinationRow = TreeRoot.GetID();
		EndIf;
		AddToBudgetViewStructure(RowsArray, DestinationRow);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersNewItemTree

&AtClient
Procedure TreeOfNewBudgetViewElementsStartDragging(Item, DragParameters, Perform)
	
	TreeLineSender = "NewItemTree";
	
EndProcedure

&AtClient
Procedure TreeOfNewElementsInTheSelectBudgetView(Item, RowSelected, Field, StandardProcessing)
	
	TreeLineSender = "NewItemTree";
	RowsArray = New Array;
	RowsArray.Add(RowSelected);
	AddToBudgetViewStructure(RowsArray, Items.DisplayReportItems.CurrentRow);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ViewTheReportView(Command)
	
	If Not ValueIsFilled(Object.Ref) Or Modified Then
		
		CallbackDescription = New CallbackDescription("ViewTheReportViewCompletion", ThisObject);
		QueryText = NStr("vi = 'Chỉ có thể xem dạng báo cáo sau khi ghi lại dữ liệu. Ghi lại?';
						|ru = 'Просмотр вида отчета возможен только после записи данных. Записать?';
						|en = 'Budget report can be viewed only after the data is saved. Do you want to save data?'; fa = 'Budget report can be viewed only after the data is saved. Do you want to save data?';
						|it = 'Visualizzare il tipo di report è possibile solo dopo la registrazione dei dati. Registrare?';
						|pl = 'Przeglądanie rodzaju raportu jest możliwe tylko po zapisaniu danych. Zapisać?';
						|tr = 'Rapor türünün gösterimi sadece veriler kaydedilince mümkündür. Kaydedilsin mi?'");
		ShowQueryBox(CallbackDescription,
			QueryText,
			QuestionDialogMode.OKCancel);
		Return;
		
	EndIf;
	
	ViewReportViewFragment();
	
EndProcedure

&AtClient
Procedure ViewTheReportViewCompletion(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	
	If Response = DialogReturnCode.OK Then
		ClearMessages();
		ItemRecorded = Write();
	ElsIf Response = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	If Not ItemRecorded Then
		Return;
	EndIf;
	
	ViewReportViewFragment();

EndProcedure

&AtClient
Procedure ViewReportViewFragment()
	
	ReportParameters = New Structure;
	ReportParameters.Insert("BudgetingModel", Object.Owner);
	ReportParameters.Insert("BudgetProfile", Object.Ref);
	ReportParameters.Insert("GenerateBudgetReportWhenOpening", True);
	
	OpenForm("Report.BudgetReport.Form.ReportForm",
	ReportParameters,
	ThisObject,
	Object.Ref);

EndProcedure

&AtClient
Procedure CreateABudgetItem(Command)
	
	CurrentData = Items.NewItemTree.CurrentData;
	
	FillingValues = New Structure();
	If TypeOf(CurrentData.ReportingKindItem) = Type("CatalogRef.BudgetFlowItems")
		Or TypeOf(CurrentData.ReportingKindItem) = Type("CatalogRef.BudgetBalanceItems")
		Or TypeOf(CurrentData.ReportingKindItem) = Type("CatalogRef.NonFinancialItemsOfBudgets") Then
		
		If CurrentData.IsFolder Then
			FillingValues.Insert("Parent", CurrentData.ReportingKindItem); 
		Else
			RowParent = CurrentData.GetParent();
			If RowParent <> Undefined Then
				FillingValues.Insert("Parent", RowParent.ReportingKindItem);
			EndIf;
		EndIf;
		
		If TypeOf(CurrentData.ReportingKindItem) = Type("CatalogRef.BudgetFlowItems") Then
			NameOfNewElementForm = "BudgetFlowItems.ObjectForm";
		ElsIf TypeOf(CurrentData.ReportingKindItem) = Type("CatalogRef.BudgetBalanceItems") Then
			NameOfNewElementForm = "BudgetBalanceItems.ObjectForm";
		ElsIf TypeOf(CurrentData.ReportingKindItem) = Type("CatalogRef.NonFinancialItemsOfBudgets") Then
			NameOfNewElementForm = "NonFinancialItemsOfBudgets.ObjectForm";
		EndIf;
		
		NameOfNewElementForm = "Catalog." + NameOfNewElementForm;
		
	ElsIf CurrentData.ReportingKindItem = "Dimension"
		Or TypeOf(CurrentData.ReportingKindItem) = Type("ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions") Then
		
		NameOfNewElementForm = "ChartOfCharacteristicTypes.BudgetFlowItemDimensions.ObjectForm";
		
	Else
		WarningText = NStr("vi = 'Chỉ có thể thêm các dạng ngân sách của chỉ tiêu ngân sách';
							|ru = 'Можно добавлять только статьи бюджетов и показатели бюджетов';
							|en = 'Only budget flow items and budget balance items can be added'; fa = 'Only budget flow items and budget balance items can be added';
							|it = 'È possibile aggiungere solo elementi di budget e indicatori di budget';
							|pl = 'Można dodawać tylko pozycje budżetów i wskaźniki budżetów';
							|tr = 'Sadece bütçe kalemleri ve bütçe dengesi kalemleri eklenebilir'");
		ShowMessageBox(, WarningText, 60);
		Return;
	EndIf;
	
	FormParameters = New Structure("FillingValues", FillingValues);
	OpenForm(NameOfNewElementForm, FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure CreateBudgetEntryDocument(Command)
	
	If Not ValueIsFilled(Object.Ref) Or Modified Then
		
		CallbackDescription = New CallbackDescription("CreateBudgetEntryDocumentCompletion", ThisObject);
		QueryText = NStr("vi = 'Chỉ có thể xem dạng báo cáo sau khi ghi lại dữ liệu. Ghi lại?';
						|ru = 'Просмотр вида отчета возможен только после записи данных. Записать?';
						|en = 'Budget report can be viewed only after the data is saved. Do you want to save data?'; fa = 'Budget report can be viewed only after the data is saved. Do you want to save data?';
						|it = 'Visualizzare il tipo di report è possibile solo dopo la registrazione dei dati. Registrare?';
						|pl = 'Przeglądanie rodzaju raportu jest możliwe tylko po zapisaniu danych. Zapisać?';
						|tr = 'Rapor türünün gösterimi sadece veriler kaydedilince mümkündür. Kaydedilsin mi?'");
		ShowQueryBox(CallbackDescription,
			QueryText,
			QuestionDialogMode.OKCancel);
		Return;
		
	EndIf;
	
	CreateInstanceOfBudgetFragment();
EndProcedure

&AtClient
Procedure CreateBudgetEntryDocumentCompletion(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	
	If Response = DialogReturnCode.OK Then
		ClearMessages();
		ItemRecorded = Write();
		If Not ItemRecorded Then
			Return;
		EndIf;
	Else
		Return;
	EndIf;
	
	CreateInstanceOfBudgetFragment();
	
EndProcedure

&AtClient
Procedure CreateInstanceOfBudgetFragment()
	
	FillingData = Undefined;
	FormParameters = Undefined;
	
	ClearMessages();
	If Not CheckBudgetViewOnServer() Then
		WarningText = NStr("vi = 'Đã tìm thấy lỗi';
							|ru = 'Обнаружены ошибки';
							|en = 'Errors are found'; fa = 'Errors are found';
							|it = 'Errori trovati';
							|pl = 'Wykryto błędy';
							|tr = 'Hatalar bulundu'");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	
	FillingData = New Structure("BudgetProfile", Object.Ref);
	FormParameters = New Structure("FillingValues", FillingData);
	OpenForm("Document.BudgetEntryForm.Form.DocumentForm", FormParameters);
	
EndProcedure

&AtClient
Procedure Change(Command)

	EditReportElement();
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	UpdateTreeOfNewElements();
	
EndProcedure

&AtClient
Procedure CheckBudgetProfile(Command)
	
	If Object.Ref.IsEmpty() Or Modified Then
		
		QueryText = NStr("vi = 'Dạng ngân sách sẽ được lưu lại. Tiếp tục?';
						|ru = 'Вид бюджета будет сохранен. Продолжить?';
						|en = 'Budget profile will be saved. Continue?'; fa = 'Budget profile will be saved. Continue?';
						|it = 'Il tipo del budget verrà salvato. Continuare?';
						|pl = 'Rodzaj budżetu zostanie zapisany. Kontynuować?';
						|tr = 'Bütçe profili kaydedilecek. Devam edilsin mi?'");
		CallbackDescription = New CallbackDescription("CheckBudgetProfileCompletion", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		Return;
		
	EndIf;
		
	CheckBudgetViewFragment();
	
EndProcedure

&AtClient
Procedure CheckBudgetProfileCompletion(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	
	If Response = DialogReturnCode.Yes Then
		ClearMessages();
		ItemRecorded = Write();
	Else 
		Return
	EndIf;
	
	If Not ItemRecorded Then
		Return;
	EndIf;
	
	CheckBudgetViewFragment();
	
EndProcedure

&AtClient
Procedure CheckBudgetViewFragment()
	
	ClearMessages();
	If Not CheckBudgetViewOnServer() Then
		WarningText = NStr("vi = 'Đã tìm thấy lỗi';
							|ru = 'Обнаружены ошибки';
							|en = 'Errors are found'; fa = 'Errors are found';
							|it = 'Errori trovati';
							|pl = 'Wykryto błędy';
							|tr = 'Hatalar bulundu'");
		ShowMessageBox(, WarningText);
	Else
		WarningText = NStr("vi = 'Không có lỗi';
							|ru = 'Ошибок нет';
							|en = 'No errors'; fa = 'No errors';
							|it = 'Nessun errore';
							|pl = 'Brak błędów';
							|tr = 'Hata yok'");
		ShowMessageBox(, WarningText);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	ProcedureParameters = TMCommonUseClient.PermissionParametersForEditingItemDetails();
	ProcedureParameters.NotificationAboutUnblocking = New CallbackDescription("AllowObjectAttributeEditCompletion", ThisObject);
	TMCommonUseClient.AllowObjectAttributeEdit(ThisObject, ProcedureParameters);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

&AtClient
Procedure Group(Command)
	
	If Items.DisplayReportItems.ReadOnly Then
		WarningText = NStr("vi = 'Dạng ngân sách được sử dụng trong các chứng từ và không cho phép chỉnh sửa';
							|ru = 'Вид бюджета используется в документах и недоступен для редактирования';
							|en = 'This budget profile is used in the documents. You cannot edit it'; fa = 'This budget profile is used in the documents. You cannot edit it';
							|it = 'Il tipo di budget è utilizzato nei documenti e non è modificabile';
							|pl = 'Rodzaj budżetu jest używany w dokumentach i nie może być edytowany';
							|tr = 'Bütçe profili belgelerde kullanılmaktadır ve düzenlemeye müsait değildir'");
		ShowMessageBox(,WarningText);
		Return;
	EndIf;
	
	SelectedRows = Items.DisplayReportItems.SelectedRows;
	
	If SelectedRows.Count() < 2 Then
		Return;
	EndIf;
	
	SelectedRowsList = New ValueList;
	SelectedRowsList.LoadValues(SelectedRows);
	SelectedRowsList.SortByValue();
	SelectedRows = SelectedRowsList.UnloadValues();
	
	String1 = DisplayReportItems.FindByID(SelectedRows[0]);
	String2 = DisplayReportItems.FindByID(SelectedRows[1]);
	
	If String1.GetParent() = String2 Then
		// direct order
		InitialValue = 0;
		InverseCoefficient = -1;
	Else
		// reverse order
		InitialValue = SelectedRows.Count() - 1;
		InverseCoefficient = 1;
	EndIf;
	
	HasErrors = False;
	PreviousString = Undefined;
	OrderedRows = New Array;
	
	CheckString = DisplayReportItems.FindByID(SelectedRows[0]);
	
	Table = FinancialReportingClient.RootElementOfFormElement(CheckString, ItemKind("ComplexTable"));
	If Table = Undefined Then
		Table = FinancialReportingClient.RootElementOfFormElement(CheckString,
			ItemKind("TableIndicatorsInColumns"));
		If Table = Undefined Then
			Table = FinancialReportingClient.RootElementOfFormElement(CheckString,
				ItemKind("TableIndicatorsInRows"));
		EndIf;
	EndIf;
	
	If Table <> Undefined
		And FinancialReportingClient.RootElementOfFormElement(CheckString, ItemKind("Rows")) = Undefined Then
		HasErrors = True;
	Else
		For Cnt = 0 To SelectedRows.Count() - 1 Do
			SearchID = SelectedRows[InitialValue - Cnt * InverseCoefficient];
			String = DisplayReportItems.FindByID(SearchID);
			OrderedRows.Add(String.LineIndexOfReportItems);
			If String.ItemKind <> PredefinedValue("Enum.FinancialReportItemKinds.Dimension") Then
				HasErrors = True;
				Break;
			EndIf;
			If Cnt <> 0 And String.GetItems().Count() > 1 Then
				HasErrors = True;
				Break;
			EndIf;
			If PreviousString <> Undefined Then
				If PreviousString.GetParent() <> String Then
					HasErrors = True;
					Break;
				EndIf;
			EndIf;
			PreviousString = String;
		EndDo;
	EndIf;
	
	If HasErrors Then
		MessageText = NStr("vi = 'Không thể gom nhóm các dòng đã chỉ định.
									|Chỉ có thể gom nhóm chiều đo trong các dòng nằm dưới nhau';
									|ru = 'Невозможно сгруппировать указанные строки.
									|Сгруппированы могут быть только измерения в строках, располагающиеся друг под другом';
									|en = 'Cannot group the selected lines.
									|You can only group dimensions in adjacent lines'; fa = 'Cannot group the selected lines.
									|You can only group dimensions in adjacent lines';
									|it = 'Non è possibile raggruppare le righe specificate.
									|È possibile raggruppare solo le dimensioni nelle righe che si trovano l''una sotto l''altra';
									|pl = 'Grupowanie określonych wierszy nie jest możliwe.
									|Można zgrupować tylko wymiary w wierszach, znajdujących się jeden pod drugim';
									|tr = 'Belirtilen satırlar gruplandırılamaz.
									| Gruplandırma sadece satırlarda değişiklikler yapılıp yığılmasıyla gerçekleştirilebilir'");
		ShowMessageBox(,MessageText);
		Return;
	EndIf;
	
	LowerLine = ReportItems.FindByID(OrderedRows[0]);
	
	For Cnt = 0 To OrderedRows.UBound() Do
		
		SubordinateRow = OrderedRows[Cnt];
		TreeRow = ReportItems.FindByID(SubordinateRow);
		If Cnt < OrderedRows.UBound() Then
			TreeRow.DisplayWithParent = True;
			If Not ValueIsFilled(TreeRow.AddressOfItemStructure) Then
				TreeRow.AddressOfItemStructure = BudgetReportingClientServer.PlaceItemInStorage(
						TreeRow, UUID);
			EndIf;
		EndIf;
		
		For Each String In TreeRow.GetItems() Do
			If OrderedRows.Find(String.GetID()) = Undefined Then
				ParentInstallationOptions = FinancialReportingClient.TemplateForNewParentInstallationOptions();
				ParentInstallationOptions.FormIdentifier = UUID;
				FinancialReportingClient.SetNewParentOfFormElement(String,
					LowerLine,
					ParentInstallationOptions);
			EndIf;
		EndDo;
		
	EndDo;
	
	Items.DisplayReportItems.SelectedRows.Clear();
	Items.DisplayReportItems.CurrentRow = OrderedRows[OrderedRows.UBound()];
	
	UTurnMatching = ListOfUTurnFlags(DisplayReportItems);
	
	UpdateDisplayTree();
	
	RestoreExpandedTreeNodes_(DisplayReportItems, UTurnMatching);
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure Ungroup(Command)
	
	If Items.DisplayReportItems.ReadOnly Then
		WarningText = NStr("vi = 'Dạng ngân sách được dùng trong các chứng từ và không cho phép chỉnh sửa';
							|ru = 'Вид бюджета используется в документах и недоступен для редактирования';
							|en = 'This budget profile is used in the documents. You cannot edit it'; fa = 'This budget profile is used in the documents. You cannot edit it';
							|it = 'Il tipo di budget è utilizzato nei documenti e non è modificabile';
							|pl = 'Rodzaj budżetu jest używany w dokumentach i nie może być edytowany';
							|tr = 'Bütçe profili belgelerde kullanılmaktadır ve düzenlemeye müsait değildir'");
		ShowMessageBox(,WarningText);
		Return;
	EndIf;
	
	CurrentData = Items.DisplayReportItems.CurrentData;
	For Cnt = 2 To Items.NameForPrinting.ChildItems.Count() Do
		If CurrentData.Property("LineIndexOfReportItems"+ Cnt) Then
			Value = CurrentData["LineIndexOfReportItems" + Cnt];
			If Value <> Undefined Then
				DataString1 = ReportItems.FindByID(Value);
				DataString1.DisplayWithParent = False;
				If Not ValueIsFilled(DataString1.AddressOfItemStructure) Then
					DataString1.AddressOfItemStructure = BudgetReportingClientServer.PlaceItemInStorage(DataString1, UUID);
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
	UTurnMatching = ListOfUTurnFlags(DisplayReportItems);
	
	UpdateDisplayTree();
	
	RestoreExpandedTreeNodes_(DisplayReportItems, UTurnMatching);
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure MoveUp(Command)
	
	CurrentRow = Items.DisplayReportItems.CurrentData;
	Parent = CurrentRow.GetParent();
	If Parent = Undefined Then
		Return;
	EndIf;
	If CurrentRow.ItemKind = PredefinedValue("Enum.FinancialReportItemKinds.Rows")
		Or CurrentRow.ItemKind = PredefinedValue("Enum.FinancialReportItemKinds.Columns")
		Or CurrentRow.ItemKind = PredefinedValue("Enum.FinancialReportItemKinds.CellsSettings") Then
		Return;
	EndIf;
	
	ShiftElement(CurrentRow, -1);
	ShiftElement(ReflectedLine(CurrentRow, ThisObject), -1);
	Modified = True;
	
EndProcedure

&AtClient
Procedure MoveDown(Command)
	
	CurrentRow = Items.DisplayReportItems.CurrentData;
	Parent = CurrentRow.GetParent();
	If Parent = Undefined Then
		Return;
	EndIf;
	If CurrentRow.ItemKind = PredefinedValue("Enum.FinancialReportItemKinds.Rows")
		Or CurrentRow.ItemKind = PredefinedValue("Enum.FinancialReportItemKinds.Columns")
		Or CurrentRow.ItemKind = PredefinedValue("Enum.FinancialReportItemKinds.CellsSettings") Then
		Return;
	EndIf;
	
	ShiftElement(CurrentRow, 1);
	ShiftElement(ReflectedLine(CurrentRow, ThisObject), 1);
	Modified = True;
	
EndProcedure

&AtClient
Procedure AllowObjectAttributeEditCompletion(Result, AdditionalParameters) Export
	
	FormControl();
	
EndProcedure

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure
// End StandardSubsystems.Properties

#EndRegion

#Region Private

// StandardSubsystems.Properties 
&AtServer
Procedure UpdateAdditionalAttributesItems()
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
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

&AtServer
Procedure PerformStringProcessingRecursively(CellsSettings, TableRow, ProcedureName)
	
	SubordinateRows = FinancialReportingServer.SubordinateRows(TableRow);
	For Each String In SubordinateRows Do
		
		PerformStringProcessingRecursively(CellsSettings, String, ProcedureName);
		
		If ProcedureName = "ClearRelatedDesignElements" Then
			ClearRelatedDesignElements(CellsSettings, String.GetID());
		ElsIf ProcedureName = "ClearDeletedReportElements" Then
			ClearDeletedReportElements(CellsSettings, String.GetID());
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure ReportElementsBeforeDeletingOnServer(ItemsList);
	
	For Each ValueListItem In ItemsList Do
		
		RowID = ValueListItem.Value;
		CurrentRow = ReportItems.FindByID(RowID);
		
		If CurrentRow = Undefined Then
			// The string was subordinate to the already deleted string
			Continue;
		EndIf;
		
		ComplexTable = FinancialReportingServer.RootItem(CurrentRow,
			Enums.FinancialReportItemKinds.ComplexTable);
		If ComplexTable = Undefined Then
			Table = FinancialReportingServer.RootItem(CurrentRow,
				Enums.FinancialReportItemKinds.TableIndicatorsInColumns);
			If Table = Undefined Then
				Table = FinancialReportingServer.RootItem(CurrentRow,
					Enums.FinancialReportItemKinds.TableIndicatorsInRows);
			EndIf;
		Else
			Table = ComplexTable;
		EndIf;
		
		If Table <> Undefined Then
			CellsSettings = FinancialReportingServer.SubordinateItem(Table,
				"ItemKind", Enums.FinancialReportItemKinds.CellsSettings);
			
			PerformStringProcessingRecursively(CellsSettings.GetID(), 
					CurrentRow, "ClearRelatedDesignElements");
			ClearRelatedDesignElements(CellsSettings.GetID(), CurrentRow.GetID());
			
			If ComplexTable <> Undefined Then
				PerformStringProcessingRecursively(CellsSettings.GetID(), 
						CurrentRow, "ClearDeletedReportElements");
				ClearDeletedReportElements(CellsSettings.GetID(), CurrentRow.GetID());
			EndIf;
		EndIf;
		
		PutToTempStorage(Undefined, CurrentRow.AddressOfItemStructure);
		CurrentRow.AddressOfItemStructure = "";
		CurrentRow.GetParent().GetItems().Delete(CurrentRow);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure UseToEnterPlanWhenChangingOnServer()
	
	UpdateTreeOfNewElements();
	FormControl();
	
	// Reset the editing parameters
	If Not Object.UseToEnterPlan Then
		Object.MainInputMethod = Enums.BudgetEditingMethods.TabularInput;
		Object.EnableSpreadsheetDocumentProtection = False;
		Object.SaveBudgetInTabularFormToBudgetEntryForm = False;
		Object.UseDeferredPostingOfBudgetEntryForms = False;
		Object.GenerateRelatedBudgetTurnovers = False;
		
		ItemsTree = FormAttributeToValue("ReportItems");
		ElementsWithHierarchyOutput = ItemsTree.Rows.FindRows(New Structure("ShowItemHierarchy",
			True), True);
		For Each ReportItem In ElementsWithHierarchyOutput Do
			ReportItem.HasSettings = 0;
		EndDo;
		ValueToFormAttribute(ItemsTree, "ReportItems");
		UpdateDisplayTree();
	EndIf;
	
EndProcedure

&AtServer
Function CheckBudgetViewOnServer()
	
	Return Catalogs.BudgetProfiles.BudgetViewIsFilledInCorrectly(Object.Ref)
				And BudgetingModelOfBudgetTypeIsValid(Object.Ref);
	
EndFunction

&AtServer
Function BudgetingModelOfBudgetTypeIsValid(BudgetProfile)
	
	Valid = False;
	
	If ValueIsFilled(BudgetProfile) Then
		BudgetingModel = Common.ObjectAttributeValue(BudgetProfile, "Owner");
		Valid = Catalogs.BudgetingModels.BudgetingModelWorks(BudgetingModel);
		
		If Not Valid Then
			ErrorText = NStr("vi = 'Mô hình lập ngân sách của dạng ngân sách không hoạt động';
							|ru = 'Модель бюджетирования вида бюджета не действует';
							|en = 'Budgeting model of the budget profile is invalid'; fa = 'Budgeting model of the budget profile is invalid';
							|it = 'Il modello di determinazione del budget non è valido per il tipo di budget';
							|pl = 'Model budżetowania rodzaju budżetu nie obowiązuje';
							|tr = 'Bütçe profilinin bütçeleme modeli çalışmıyor'");
			Common.MessageToUser(ErrorText);
		EndIf;
	EndIf;
	
	Return Valid;
	
EndFunction

&AtServer
Procedure RefreshFormTitle()
	
	TypePresentation = NStr("vi = 'Dạng ngân sách';
							|ru = 'Вид бюджета';
							|en = 'Budget profile'; fa = 'پروفایل بودجه';
							|it = 'Tipologia di bilancio';
							|pl = 'Rodzaj budżetu';
							|tr = 'Bütçe profili'");
	
	If Not ValueIsFilled(Object.Ref) Then
		Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 (tạo mới)';
				|ru = '%1 (создание)';
				|en = '%1 (Create)'; fa = '%1 (Create)';
				|it = '%1 (creazione)';
				|pl = '%1 (utworzenie)';
				|tr = '%1 (oluşturma)'"),
			TypePresentation);
	Else
		Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 (%2)';
				|ru = '%1 (%2)';
				|en = '%1 (%2)'; fa = '%1 (%2)';
				|it = '%1 (%2)';
				|pl = '%1 (%2)';
				|tr = '%1 (%2)'"),
			Object.Description,
			TypePresentation);
	EndIf;
	
EndProcedure

&AtServer
Function CreateCacheBasedOnCombinationTable(TableOfCombinations, Level = 0)
	
	If Level = TableOfCombinations.Columns.Count() Then
		Return True;
	EndIf;
	
	Values = TableOfCombinations.Copy();
	CurColumnName = Values.Columns[Level].Name;
	Values.GroupBy(CurColumnName);
	
	CacheResult = New Map;
	For Each Value In Values Do
		CurrentValue = Value[CurColumnName];
		SelectedCombinations = TableOfCombinations.Copy(New Structure(CurColumnName, CurrentValue));
		LowerLevelCache = CreateCacheBasedOnCombinationTable(SelectedCombinations, Level + 1);
		CacheResult.Insert(CurrentValue, LowerLevelCache);
	EndDo;
	
	Return New FixedMap(CacheResult);
	
EndFunction

&AtServer
Procedure UpdateTreeOfNewElements()
	
	TreeParameters = New Structure;
	
	TreeParameters.Insert("NameOfTreeElement", "NewItemTree");
	TreeParameters.Insert("QuickSearch", QuickSearchOfNew);
	TreeParameters.Insert("BudgetingModel", Object.Owner);
	TreeParameters.Insert("TreeMode", Enums.ModesOfNewItemTreeDisplay.ConfigureBudgetProfile);
	TreeParameters.Insert("UseToEnterPlan", Object.UseToEnterPlan);
	TreeParameters.Insert("HeaderDimensions", Object.HeaderDimensions.Unload().UnloadColumn("DimensionKind"));
	
	BudgetReportingServerCall.UpdateTreeOfNewElements(ThisObject, TreeParameters);
	
EndProcedure

&AtServer
Procedure OutputTreeOfElementsToDisplayTree(TreeItems, ParentString, DepthOfLevels, PrivilegedReceiptParameters)
	FormulaOperandsArePrivileged = PrivilegedReceiptParameters.FormulaOperandsArePrivileged;
	ComplexTableIsPrivileged  = PrivilegedReceiptParameters.ComplexTableIsPrivileged;
	
	TreeRows = TreeItems.GetItems();
	DisplayLines = ParentString.GetItems();
	For Each TreeRow In TreeRows Do
		If TreeRow.DisplayWithParent Then
			For Cnt = 2 To DepthOfLevels Do
				If Not ParentString.Property("LineIndexOfReportItems"+ Cnt) Or 
						ParentString["LineIndexOfReportItems" + Cnt] = Undefined Then
					Break
				EndIf;
			EndDo;
			ParentString["NameForPrinting" + Cnt] = TreeRow.NameForPrinting;
			ParentString["LineIndexOfReportItems" + Cnt] = TreeRow.GetID();
			ParentString["AdditionalFieldPresentation" + Cnt] = TreeRow.AdditionalFieldPresentation;
			CurrentParent = ParentString;
		Else
			NewRow = DisplayLines.Add();
			FillPropertyValues(NewRow, TreeRow);
			CurrentParent = NewRow;
			NewRow.LineIndexOfReportItems = TreeRow.GetID();
		EndIf;
		
		If Not NewRow = Undefined Then
			If NewRow.ItemKind = Enums.FinancialReportItemKinds.CellsSettings Then
				ThereIsPrivilegedMode = False;
				TheStructureOfTheSearch = New Structure("Parent",TreeRow.ReportItem);
				If ComplexTableIsPrivileged.FindRows(TheStructureOfTheSearch).Count() > 0 Then
					ThereIsPrivilegedMode = True;
				EndIf;
			Else
				ThereIsPrivilegedMode = False;
				If ValueIsFilled(NewRow.PrivilegedMode)
					And Not NewRow.PrivilegedMode Then
					TheStructureOfTheSearch = New Structure("Parent",TreeRow.ReportItem);
					If FormulaOperandsArePrivileged.FindRows(TheStructureOfTheSearch).Count() > 0 Then
						ThereIsPrivilegedMode = True;
					EndIf;
				Else
					ThereIsPrivilegedMode = ?(ValueIsFilled(NewRow.PrivilegedMode),
								NewRow.PrivilegedMode, False);
				EndIf;
			EndIf;
			NewRow.PrivilegedModePicture = Not Number(ThereIsPrivilegedMode);
		EndIf;
		
		OutputTreeOfElementsToDisplayTree(TreeRow,
				CurrentParent,
				DepthOfLevels,
				PrivilegedReceiptParameters);
	EndDo;
	
EndProcedure

&AtServer 
Procedure UpdateElementTree(CopyingValue = Undefined)
	
	CurReportView = Object.Ref;
	If ValueIsFilled(CopyingValue) Then
		CurReportView = CopyingValue;
	EndIf;
	
	IndexOfRootRowImage = 100;
	If Not ValueIsFilled(CurReportView) Then
		TreeRows = ReportItems.GetItems();
		RootRow = TreeRows.Add();
		RootRow.NameForPrinting = NStr("vi = 'Phần tử báo cáo';
										|ru = 'Элементы отчета';
										|en = 'Report items'; fa = 'اقلام گزارش';
										|it = 'Elementi del report';
										|pl = 'Elementy raportu';
										|tr = 'Rapor öğeleri'");

		RootRow.ItemKind = Enums.FinancialReportItemKinds.EmptyRef();
		RootRow.CustomPicture = IndexOfRootRowImage;
		
		UpdateDisplayTree();
		
		Return;
	EndIf;
	
	ItemsTree = BudgetReportingCacheCalculationServer.BudgetItemTree(CurReportView);
	
	RootRow = ItemsTree.Rows.Add();
	RootRow.NameForPrinting = NStr("vi = 'Phần tử báo cáo';
									|ru = 'Элементы отчета';
									|en = 'Report items'; fa = 'اقلام گزارش';
									|it = 'Elementi del report';
									|pl = 'Elementy raportu';
									|tr = 'Rapor öğeleri'");
	RootRow.ItemKind = Enums.FinancialReportItemKinds.EmptyRef();
	RootRow.CustomPicture = IndexOfRootRowImage;
	
	LineNumber = 0;
	While LineNumber < ItemsTree.Rows.Count() Do
		
		Page1 = ItemsTree.Rows[LineNumber];
		// Delete the lines by condition
		If Page1.CustomPicture <> IndexOfRootRowImage Then
			InstallationParameters = FinancialReportingServer.TemplateForNewParentInstallationOptions();
			FinancialReportingServer.SetNewParent(Page1, RootRow, InstallationParameters);
			ItemsTree.Rows.Delete(Page1);
			Continue;
		EndIf;
		LineNumber = LineNumber + 1;
		
	EndDo;
	
	If ValueIsFilled(CopyingValue) Then
		RecreateTreeElementsWhenCopying(ItemsTree.Rows);
		Modified = True;
	EndIf;
	
	ValueToFormAttribute(ItemsTree, "ReportItems");
	
	UpdateDisplayTree();
	
EndProcedure

&AtServer
Function GetAddressOfRecordedElement(LinkCache, Item)
	
	Address = LinkCache[Item];
	If Address = Undefined Then
		Address = BudgetReportingClientServer.PlaceItemInStorage(Item, UUID);
		ElementStructure = GetFromTempStorage(Address); // See FinancialReportingClientServer.ReportElementStructure
		ElementStructure.Ref = Undefined;
		PutToTempStorage(ElementStructure, Address);
		LinkCache.Insert(Item, Address);
	EndIf;
	
	Return Address;
		
EndFunction

&AtServer
Procedure RecreateTreeElementsWhenCopying(Rows, LinkCache = Undefined)
	
	If LinkCache = Undefined Then
		LinkCache = New Map;
	EndIf;
	
	For Each TreeRow In Rows Do
		Address = LinkCache[TreeRow.ReportItem];
		If Address = Undefined Then
			
			Address = BudgetReportingClientServer.PlaceItemInStorage(TreeRow, UUID);
			LinkCache.Insert(TreeRow.ReportItem, Address);
			ElementStructure = GetFromTempStorage(Address); // See FinancialReportingClientServer.ReportElementStructure
			ElementStructure.Ref = Undefined;
			
			For Each RowColumn In ElementStructure.TableItems Do
				
				If TypeOf(RowColumn.String) = Type("CatalogRef.FinancialReportItems") Then
					RowColumn.String = GetAddressOfRecordedElement(LinkCache, RowColumn.String);
				EndIf;
				If TypeOf(RowColumn.Column) = Type("CatalogRef.FinancialReportItems") Then
					RowColumn.Column = GetAddressOfRecordedElement(LinkCache, RowColumn.Column);
				EndIf;
				If TypeOf(RowColumn.Item) = Type("CatalogRef.FinancialReportItems") Then
					RowColumn.Item = GetAddressOfRecordedElement(LinkCache, RowColumn.Item);
				EndIf;
				
				NestedElementStructure = GetFromTempStorage(RowColumn.Item);
				For Each OperandString_ In NestedElementStructure.FormulaOperands Do
					If TypeOf(OperandString_.Operand) = Type("CatalogRef.FinancialReportItems") Then
						OperandString_.AddressOfItemStructure = GetAddressOfRecordedElement(LinkCache, OperandString_.Operand);
						OperandString_.Operand = Undefined;
					EndIf;
					Operand = GetFromTempStorage(OperandString_.AddressOfItemStructure);
					If Operand.ItemKind = Enums.FinancialReportItemKinds.TableCell Then
						For Each PropsString In Operand.ItemKindAttributes Do
							If PropsString.Attribute = ChartsOfCharacteristicTypes.ItemAttributesOfFinancialReports.CellRow Then
								If Not IsTempStorageURL(PropsString.Value) Then
									PropsString.Value = GetAddressOfRecordedElement(LinkCache, PropsString.Value);
								EndIf;
							EndIf;
							If PropsString.Attribute = ChartsOfCharacteristicTypes.ItemAttributesOfFinancialReports.CellColumn Then
								If Not IsTempStorageURL(PropsString.Value) Then
									PropsString.Value = GetAddressOfRecordedElement(LinkCache, PropsString.Value);
								EndIf;
							EndIf;
						EndDo;
						PutToTempStorage(Operand, OperandString_.AddressOfItemStructure);
					EndIf;
				EndDo;
				PutToTempStorage(NestedElementStructure, RowColumn.Item);
				
			EndDo;
			
			For Each OperandString_ In ElementStructure.FormulaOperands Do
				If TypeOf(OperandString_.Operand) = Type("CatalogRef.FinancialReportItems") Then
					OperandString_.AddressOfItemStructure = GetAddressOfRecordedElement(LinkCache, OperandString_.Operand);
					OperandString_.Operand = Undefined;
				EndIf;
			EndDo;
			
			For Each LayoutString In ElementStructure.RegisteredRows Do
				If TypeOf(LayoutString.ReportItem) = Type("CatalogRef.FinancialReportItems") Then
					LayoutString.ReportItem = GetAddressOfRecordedElement(LinkCache, LayoutString.ReportItem);
				EndIf;
			EndDo;
			
			For Each LayoutString In ElementStructure.DesigningColumns Do
				If TypeOf(LayoutString.ReportItem) = Type("CatalogRef.FinancialReportItems") Then
					LayoutString.ReportItem = GetAddressOfRecordedElement(LinkCache, LayoutString.ReportItem);
				EndIf;
			EndDo;
			
			For Each LayoutString In ElementStructure.DrillDownOfAppearanceItemFilterFields Do
				If TypeOf(LayoutString.ReportItem) = Type("CatalogRef.FinancialReportItems") Then
					LayoutString.ReportItem = GetAddressOfRecordedElement(LinkCache, LayoutString.ReportItem);
				EndIf;
			EndDo;
			
			For Each SourceRow1 In ElementStructure.ValueSources Do
				SourceRow1.Source = GetAddressOfRecordedElement(LinkCache, SourceRow1.Source);
			EndDo;
			
			PutToTempStorage(ElementStructure, Address);
			
		EndIf;
		
		TreeRow.AddressOfItemStructure = Address;
		TreeRow.ReportItem = Undefined;
		RecreateTreeElementsWhenCopying(TreeRow.Rows, LinkCache);
	EndDo;
	
EndProcedure

&AtClient
Procedure AdjustStringAccordingToOptionalMode(CurrentRow, Cache = Undefined)
	
	AdditionalMode = DefineAdditionalParameters(CurrentRow, Cache);
	
	Attributes = New Structure();
	
	If CurrentRow.ItemKind = ItemKind("BudgetFlowItem", Cache)
		Or CurrentRow.ItemKind = ItemKind("BudgetBalanceItem", Cache)
		Or CurrentRow.ItemKind = ItemKind("AllBudgetFlowItems", Cache)
		Or CurrentRow.ItemKind = ItemKind("AllBudgetBalanceItems", Cache) Then
		
		If Not ValueIsFilled(CurrentRow.DisplayedIndicators) Then
			CurrentRow.DisplayedIndicators = PredefinedValue("Enum.TypesOfDisplayedBudgetReportIndicators.Sum");
			Attributes.Insert("DisplayedIndicators", CurrentRow.DisplayedIndicators);
		EndIf;
		
	EndIf;
	
	If CurrentRow.ItemKind = ItemKind("BudgetBalanceItem", Cache)
		Or CurrentRow.ItemKind = ItemKind("AllBudgetBalanceItems", Cache) Then
		If Not ValueIsFilled(CurrentRow.IndicatorValueType) Then
			CurrentRow.IndicatorValueType = PredefinedValue("Enum.ValueTypesOfBudgetReportIndicators.Turnover");
			Attributes.Insert("IndicatorValueType", CurrentRow.IndicatorValueType);
		EndIf;
	EndIf;
	
	If ValueIsFilled(CurrentRow.AddressOfItemStructure)
		And Attributes.Count() Then
		FinancialReportingServerCall.SetValuesForAdditionalBankingDetails(CurrentRow.AddressOfItemStructure, Attributes);
	EndIf;
	
	WithoutSettings = False;
	WithoutIndicators = False;
	WithoutReverseSign = False;
	
	NameOfAdditionalModes = "Enum.AdditionalModesOfReportItems.";
	If AdditionalMode = PredefinedValue(NameOfAdditionalModes + "ItemInBudgetBalanceItem") Then
		WithoutSettings = True;
		WithoutIndicators = True;
	ElsIf AdditionalMode = PredefinedValue(NameOfAdditionalModes + "AllItemsInComplexTable")
		Or AdditionalMode = PredefinedValue(NameOfAdditionalModes + "AllIndicatorsInAComplexTable") Then
		WithoutSettings = True;
		WithoutIndicators = True;
		WithoutReverseSign = True;
	ElsIf AdditionalMode = PredefinedValue(NameOfAdditionalModes + "TableItemInComplexTable")
		Or AdditionalMode = PredefinedValue(NameOfAdditionalModes + "TableItemInInputMode") Then
		WithoutSettings = True;
	EndIf;
	
	StructureOnReset = New Structure;
	If WithoutSettings Then
		CurrentRow.HasSettings = False;
		StructureOnReset.Insert("HasSettings");
		StructureOnReset.Insert("AdditionalSelection");
	EndIf;
	
	If WithoutReverseSign Then
		CurrentRow.ReverseSign = Undefined;
		StructureOnReset.Insert("ReverseSign");
	EndIf;
	
	StructureOfAdditionalDetailsForResetting = New Structure;
	If WithoutIndicators Then
		CurrentRow.DisplayedIndicators = Undefined;
		StructureOfAdditionalDetailsForResetting.Insert("DisplayedIndicators");
		StructureOfAdditionalDetailsForResetting.Insert("IndicatorValueType");
	EndIf;
	
	If StructureOnReset.Count()
		Or StructureOfAdditionalDetailsForResetting.Count() Then
		
		If ValueIsFilled(CurrentRow.AddressOfItemStructure)
			Or ValueIsFilled(CurrentRow.ReportItem) Then
			ConfigureStringToMatchOptionalServerMode(CurrentRow.ReportItem,
					CurrentRow.AddressOfItemStructure,
					StructureOnReset,
					StructureOfAdditionalDetailsForResetting,
					UUID);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure ConfigureStringToMatchOptionalServerMode(ReportItem, StorageAddress,
							StructureOnReset,
							StructureOfAdditionalDetailsForResetting,
							FormUniqueID)
	
	If ValueIsFilled(ReportItem) Then
		StorageAddress = BudgetReportingClientServer.PlaceItemInStorage(ReportItem, FormUniqueID);
	EndIf;
	
	FinancialReportingServerCall.SetAttributeValue(StorageAddress, StructureOnReset);
	FinancialReportingServerCall.SetValuesForAdditionalBankingDetails(StorageAddress,
			StructureOfAdditionalDetailsForResetting);
	
EndProcedure

&AtClient
Function SkipDisplayedImages(Parent)
	
	SubordinateRows = FinancialReportingClient.SubordinateLinesOfFormElement(Parent);
	AllChecked = False;
	While Not AllChecked Do
		ThereWereSubstitutions = False;
		For Each SubordinateRow In SubordinateRows Do
			If SubordinateRow.DisplayWithParent = True Then
				ThereWereSubstitutions = True;
				Parent = SubordinateRow;
				Break;
			EndIf;
		EndDo;
		If ThereWereSubstitutions Then
			SubordinateRows = FinancialReportingClient.SubordinateLinesOfFormElement(Parent);
		Else
			Break;
		EndIf;
	EndDo;
	
	Return Parent;
	
EndFunction

&AtClient
Procedure AddToBudgetViewStructure(NewItems, Val ParentID_)
	
	If Items.DisplayReportItems.ReadOnly Then
		WarningText = NStr("vi = 'Dạng ngân sách được sử dụng trong các chứng từ và không cho phép chỉnh sửa';
							|ru = 'Вид бюджета используется в документах и недоступен для редактирования';
							|en = 'This budget profile is used in the documents. You cannot edit it'; fa = 'This budget profile is used in the documents. You cannot edit it';
							|it = 'Il tipo di budget è utilizzato nei documenti e non è modificabile';
							|pl = 'Rodzaj budżetu jest używany w dokumentach i nie może być edytowany';
							|tr = 'Bütçe profili belgelerde kullanılmaktadır ve düzenlemeye müsait değildir'");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	
	// Let's define a branch of the budget type structure
	If ParentID_ = Undefined Then
		Parent = FinancialReportingClient.RootElementOfFormElement(ReportItems);
	Else
		Parent = ReportItems.FindByID(ParentID_);
	EndIf;
	
	Parent = SkipDisplayedImages(Parent);
	ParentID_ = Parent.GetID();
	
	SubordinateParentItems1 = FinancialReportingClient.SubordinateLinesOfFormElement(Parent);
	TotalItems = SubordinateParentItems1.Count();
	If TotalItems Then
		PutFormulaBackInPlace = SubordinateParentItems1[TotalItems - 1].ItemKind = ItemKind("GroupFormula");
	EndIf;
	
	For Each NewBudgetViewElement In NewItems Do
		
		NewElementString = NewBudgetViewElement;
		If TypeOf(NewBudgetViewElement) = Type("Number") Then
			NewElementString = NewItemTree.FindByID(NewBudgetViewElement);
		EndIf;
		
		SubordinateRows = Undefined;
		If NewElementString.IsFolder = True Then
			ItemKind = ItemKind("Group");
			SubordinateRows = FinancialReportingClient.SubordinateLinesOfFormElement(NewElementString);
		Else
			ItemKind = NewElementString.ItemKind;
		EndIf;
		
		If Not YouCanAddItToBudgetViewStructure(ItemKind, ParentID_) Then
			Continue;
		EndIf;
		
		// We create tables after selecting the type
		If ItemKind = ItemKind("ComplexTable") Then
			
			AdditionalParameters = New Structure("Parent, NewElementString", Parent, NewElementString);
			Notification = New CallbackDescription("WhenSelectingTableType", ThisObject, AdditionalParameters);
			OpenForm("Catalog.FinancialReportItems.Form.TableTypeChoiceForm",,
				ThisObject,,,,
				Notification,
				FormWindowOpeningMode.LockOwnerWindow);
			Continue;
		EndIf;
		
		// We create tables after selecting the type
		If ItemKind = ItemKind("Dimension") Then
			
			DimensionType = BudgetReportingClientServer.DetermineMeasurementTypeByValueType(NewElementString.ReportingKindItem);
			
			ValueSelectionFormIsRequired = True;
			TypeOfSelectionForm = "Dimension";
			
			AdditionalParameters = New Structure("Parent", ParentID_);
			Notification = New CallbackDescription("WhenSelectingMeasurementProperties", ThisObject, AdditionalParameters);
			
			If DimensionType = PredefinedValue("Enum.TypesOfBudgetReportDimensions.Period") Then
				TypeOfSelectionForm = "Period";
			EndIf;
			If DimensionType = PredefinedValue("Enum.TypesOfBudgetReportDimensions.RegisterDimension")
				And StrFind(NewElementString.ReportingKindItem, "Dimension") Then
				ValueSelectionFormIsRequired = False;
			EndIf;
			If DimensionType = PredefinedValue("Enum.TypesOfBudgetReportDimensions.RegisterDimension")
				And NewElementString.ReportingKindItem = "UnitOfMeasure" Then
				ValueSelectionFormIsRequired = False;
			EndIf;
			
			If ValueSelectionFormIsRequired Then
				
					PickingParameters = New Structure;
					PickingParameters.Insert("DimensionType", DimensionType);
					PickingParameters.Insert("AdditionalInformation", NewElementString.ReportingKindItem);
					PickingParameters.Insert("Owner", DetermineOwnerOfElement(
						NewElementString.ReportingKindItem,
						ParentID_));
					
					If TypeOfSelectionForm = "Period" Then
						PickingParameters.Insert("Periodicity", Object.Periodicity);
						PickingParameters.Insert("PlanningMethod", Object.PlanningMethod);
						PickingParameters.Insert("NumberOfPeriodsOfRollingBudget", Object.NumberOfPeriodsOfRollingBudget);
					Else
						ToColumns = Parent.ItemKind = ItemKind("Columns")
							Or FinancialReportingClient.RootElementOfFormElement(Parent, ItemKind("Columns")) <> Undefined;
						PickingParameters.Insert("ToColumns", ToColumns);
						
						UseToEnterPlan = Object.UseToEnterPlan;
						If Object.UseToEnterPlan Then 
							CurrentRow = Parent;
							While CurrentRow <> Undefined Do
								If CurrentRow.ItemKind = PredefinedValue("Enum.FinancialReportItemKinds.DerivedItem") Then
									UseToEnterPlan = False;
									Break;
								EndIf;
								CurrentRow = CurrentRow.GetParent();
							EndDo;
						EndIf;
						PickingParameters.Insert("UseToEnterPlan", UseToEnterPlan);
					EndIf;
					
					If TypeOfSelectionForm = "Period" Then
						ChoiceFormName = "Catalog.BudgetProfiles.Form.PeriodPropertyForm";
					Else
						ChoiceFormName = "Catalog.BudgetProfiles.Form.DimensionPropertyForm";
					EndIf;
					OpenForm(ChoiceFormName, PickingParameters, ThisObject,,,,Notification,FormWindowOpeningMode.LockOwnerWindow);
				Continue;
			EndIf;
			
		EndIf;
		
		RowsDestination = Parent.GetItems();
		NewRow = RowsDestination.Add();
		
		FillPropertyValues(NewRow, NewElementString);
		NewRow.ItemKind = ItemKind;
		If ItemKind = ItemKind("Group") Then
			NewRow.CustomPicture = 36;
		EndIf;
		NewRow.NameForPrinting = NewElementString.Description;
		
		Modified = True;
		If ItemKind = ItemKind("EditedValue") Then
			
			ItemArray = BudgetReportingClient.NamesOfEditedCells(ReportItems, NewRow.GetID());
			NewRow.NameForPrinting = BudgetReportingClientServer.NameOfBudgetValueToEdit(ItemArray);
			
		ElsIf ItemKind = ItemKind("RowColumn") Then
			
			ElSpeakers = ItemKind("Columns");
			CheckParent1 = FinancialReportingClient.RootElementOfFormElement(NewRow, ElSpeakers);
			If Not CheckParent1 = Undefined Then
				NewRow.NameForPrinting = NStr("vi = 'Cột';
												|ru = 'Колонка';
												|en = 'Column'; fa = 'ستون';
												|it = 'Colonna';
												|pl = 'Kolumna';
												|tr = 'Sütun'");
			Else
				NewRow.NameForPrinting = NStr("vi = 'Dòng';
												|ru = 'Строка';
												|en = 'Row'; fa = 'Row';
												|it = 'Riga';
												|pl = 'Wiersz';
												|tr = 'Satır'");
			EndIf;
			
		ElsIf ItemKind = ItemKind("Group") Then
			
			NewRow.DisplayItemTitle = True;
			
		ElsIf ItemKind = ItemKind("GroupFormula") Then
			
			NewRow.NameForPrinting = NStr("vi = 'Số tiền';
											|ru = 'Сумма';
											|en = 'Amount'; fa = 'مبلغ';
											|it = 'Importo';
											|pl = 'Amount';
											|tr = 'Tutar'");
			
		ElsIf ItemKind = ItemKind("BudgetFlowItem")
			Or ItemKind = ItemKind("BudgetBalanceItem")
			Or ItemKind = ItemKind("NonFinancialItem")
			Or ItemKind = ItemKind("Dimension")
			Or ItemKind = ItemKind("AllBudgetFlowItems")
			Or ItemKind = ItemKind("AllBudgetBalanceItems") Then
			
			NewRow.ItemIndicatorDimensionType = NewElementString.ReportingKindItem;
			
			If ItemKind = ItemKind("BudgetFlowItem")
				Or ItemKind = ItemKind("BudgetBalanceItem")
				Or ItemKind = ItemKind("AllBudgetFlowItems")
				Or ItemKind = ItemKind("AllBudgetBalanceItems") Then
				
				AdjustStringAccordingToOptionalMode(NewRow);
				
			EndIf;
			
		EndIf;
		
		NewRow.AddressOfItemStructure = BudgetReportingClientServer.PlaceItemInStorage(NewRow, UUID);
		
		ParentOfReflection = ReflectionString(Parent);
		AddReflectionLine(ParentOfReflection.GetItems(), NewRow, ThisObject);
		
		Items.DisplayReportItems.Expand(ReflectionString(ParentID_).GetID());
		Items.DisplayReportItems.Expand(ReflectionString(NewRow).GetID(), True);
		
		If SubordinateRows <> Undefined Then
			AddToBudgetViewStructure(SubordinateRows, NewRow.GetID());
		EndIf;
		
	EndDo;
	
	If TotalItems And PutFormulaBackInPlace Then
		Move = SubordinateParentItems1.Count() - TotalItems;
		SubordinateParentItems1.Move(TotalItems - 1, Move);
	EndIf;
	
	If NewRow <> Undefined Then
		Items.DisplayReportItems.CurrentRow = ReflectionString(NewRow).GetID();
		If NewRow.ItemKind = ItemKind("DerivedItem") Then
			
			EditReportElement();
			
		EndIf;
	Else
		Items.DisplayReportItems.CurrentRow = ReflectionString(ParentID_).GetID();
	EndIf;
	
EndProcedure

&AtClient
Procedure WhenSelectingMeasurementProperties(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	ParentRow = ReportItems.FindByID(AdditionalParameters.Parent);
	RowElements = ParentRow.GetItems();
	
	RowParentReflection = ReflectionString(ParentRow);
	RowElementsReflection = RowParentReflection.GetItems();
	
	TotalItems = RowElements.Count();
	If TotalItems Then
		PutFormulaBackInPlace = RowElements[TotalItems - 1].ItemKind = ItemKind("GroupFormula");
	EndIf;
	
	Dimension = PredefinedValue("Enum.FinancialReportItemKinds.Dimension");
	Picture = FinancialReportingServerCall.CustomPicture(Dimension);
	
	For Each Value In Result Do
		
		FoundItem = Undefined;
		
		If FindFixedAnalyticsLine(RowElements,
				Dimension,
				Value.ItemIndicatorDimensionType,
				Value.DimensionValue,
				Value.ThisIsDimensionOther,
				FoundItem) Then
			
			If FoundItem.ThisIsDimensionOther Then
				If Value.EnableEdit Then
					If Value.AllValues Then
						FoundItem.NameForPrinting = BudgetReportingClientServer.PresentationOfOtherBudgetingAnalytics(
							Value.ItemIndicatorDimensionType,
							?(Value.ShowItemHierarchy, "AllHierarchy", "All"));
					Else
						FoundItem.NameForPrinting = BudgetReportingClientServer.PresentationOfOtherBudgetingAnalytics(
							Value.ItemIndicatorDimensionType,
							"AddedAndOther");
					EndIf;
				Else
					FoundItem.NameForPrinting = BudgetReportingClientServer.PresentationOfOtherBudgetingAnalytics(
						Value.ItemIndicatorDimensionType,
						"OtherItems");
				EndIf;
				
				FinancialReportingServerCall.SetValueOfAdditionalProps(
					FoundItem.AddressOfItemStructure,
					"EnableEdit",
					Value.EnableEdit);
			EndIf;
			
			Continue;
		EndIf;
		
		NewRow = RowElements.Add();
		Modified = True;
		
		FillPropertyValues(NewRow, Value);
		NewRow.CustomPicture = Picture;
		NewRow.ItemKind = Dimension;
		
		If NewRow.ThisIsDimensionOther Then
			If Value.EnableEdit Then
				If Value.AllValues Then
					NewRow.NameForPrinting = BudgetReportingClientServer.PresentationOfOtherBudgetingAnalytics(
						NewRow.ItemIndicatorDimensionType,
						?(Value.ShowItemHierarchy, "AllHierarchy", "All"));
					NewRow.SourceAllElements = True;
				Else
					NewRow.NameForPrinting = BudgetReportingClientServer.PresentationOfOtherBudgetingAnalytics(
						NewRow.ItemIndicatorDimensionType,
						"AddedAndOther");
				EndIf;
			Else
				NewRow.NameForPrinting = BudgetReportingClientServer.PresentationOfOtherBudgetingAnalytics(
					NewRow.ItemIndicatorDimensionType,
					"OtherItems");
			EndIf;
		ElsIf NewRow.ShowItemHierarchy = True Then
			NewRow.SourceAllElements = True;
		EndIf;
		
		NewRow.AddressOfItemStructure = BudgetReportingClientServer.PlaceItemInStorage(NewRow, UUID);
		
		If NewRow.ThisIsDimensionOther Then
			FinancialReportingServerCall.SetValueOfAdditionalProps(
				NewRow.AddressOfItemStructure,
				"EnableEdit",
				Value.EnableEdit);
		EndIf;
		
		If NewRow.SourceAllElements = True Then
				FinancialReportingServerCall.SetValueOfAdditionalProps(
					NewRow.AddressOfItemStructure,
					"SourceAllElements",
					True);
				FinancialReportingServerCall.SetValueOfAdditionalProps(
					NewRow.AddressOfItemStructure,
					"ShowItemHierarchy",
					NewRow.ShowItemHierarchy);
		EndIf;
		
		AddReflectionLine(RowElementsReflection, NewRow, ThisObject);
		
	EndDo;
	
	Items.DisplayReportItems.Expand(RowParentReflection.GetID());
	
	If TotalItems And PutFormulaBackInPlace Then
		Move = RowElements.Count() - TotalItems;
		RowElements.Move(TotalItems - 1, Move);
		RowElementsReflection.Move(TotalItems - 1, Move);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInRowIdsToUpdateName(RowsIDs, ItemKind,
	ItemIndicatorDimensionType, Description, Tree = Undefined)

	If Tree = Undefined Then
		Tree = ReportItems;
	EndIf;

	SubordinateRows = FinancialReportingServer.SubordinateRows(Tree);
	For Each TreeRow In SubordinateRows Do
		If TreeRow.ItemKind = ItemKind Then
			If ValueIsFilled(TreeRow.ItemIndicatorDimensionType)
				And TreeRow.ItemIndicatorDimensionType = ItemIndicatorDimensionType
				Or Common.ObjectAttributeValue(TreeRow.ReportItem, "NameForPrinting")
				= Description Then
				RowsIDs.Add(TreeRow.GetID());
				If ValueIsFilled(TreeRow.AddressOfItemStructure) Then
					ElementStructure = GetFromTempStorage(TreeRow.AddressOfItemStructure);
					ElementStructure.NameForPrinting = Description;
					PutToTempStorage(ElementStructure, TreeRow.AddressOfItemStructure);
				EndIf;
			EndIf;
		EndIf;
		FillInRowIdsToUpdateName(RowsIDs, ItemKind,
			ItemIndicatorDimensionType, Description, TreeRow);
	EndDo;

EndProcedure

&AtClient
Procedure UpdateNamesOfReportElements(Tree, RowsIDs, ItemKind, Description,
	ByRowIds)

	SubordinateRows = FinancialReportingClient.SubordinateLinesOfFormElement(Tree);
	For Each TreeRow In SubordinateRows Do
		If TreeRow.ItemKind = ItemKind Then
			RowID = ?(ByRowIds, TreeRow.GetID(),
				TreeRow.LineIndexOfReportItems);
			If RowsIDs.Find(RowID) <> Undefined Then
				TreeRow.NameForPrinting = Description;
			EndIf;
		EndIf;
		UpdateNamesOfReportElements(TreeRow, RowsIDs, ItemKind, Description,
			ByRowIds);
	EndDo;

EndProcedure

// Returns a string of tree values for tree Elements
// 
// Parameters:
// 	AdditionalParameters - Structure - structure of additional parameters specified as a parameter of the notification processing method:
// 	 *NewElementString - FormDataTreeItem -
// Returns:
// 	FormDataTreeItem - tree string of tree elements:
// 	 *ItemKind - EnumRef.FinancialReportItemKinds -
// 	 *ReportingKindItem - CatalogRef.BudgetFlowItems -
// 	 						- CatalogRef.Companies -
// 	 						- CatalogRef.BusinessStructure -
// 	 						- EnumRef.Periodicity -
// 	 						- CatalogRef.BudgetBalanceItems -
// 	 						- String - 
// 	 						- ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions -
// 	 						- CatalogRef.NonFinancialItemsOfBudgets -
// 	 						- CatalogRef.BudgetingScenarios - 
// 	 *CustomPicture - Number -
// 	 *Description - String -
// 	 *IsFolder - Boolean -
//
&AtClient
Function StringNewElementFromAdditionalParameters(AdditionalParameters)
	Return AdditionalParameters.NewElementString;
EndFunction

&AtClient
Procedure WhenSelectingTableType(TableType, AddlParameters) Export
	
	If TableType = Undefined Then
		Return;
	EndIf;
	
	Parent = AddlParameters.Parent;
	NewElementString = StringNewElementFromAdditionalParameters(AddlParameters);
	
	RowsDestination = Parent.GetItems(); // FormDataTreeItemCollection -
	NewRow = RowsDestination.Add();
	
	FillPropertyValues(NewRow, NewElementString);
	NewRow.NameForPrinting = NewElementString.Description;
	
	If TableType = 0 Then
		NewRow.ItemKind = PredefinedValue("Enum.FinancialReportItemKinds.TableIndicatorsInRows");
	ElsIf TableType = 1 Then
		NewRow.ItemKind = PredefinedValue("Enum.FinancialReportItemKinds.TableIndicatorsInColumns");
	ElsIf TableType = 2 Then
		NewRow.ItemKind = PredefinedValue("Enum.FinancialReportItemKinds.ComplexTable");
	EndIf;
	
	Modified = True;
	
	AddReflectionLine(ReflectionString(Parent).GetItems(), NewRow, ThisObject);
	
	SubordinateRows = NewRow.GetItems();
	
	ItemKind = ItemKind("Columns");
	AdditionalTableElement = SubordinateRows.Add();
	AdditionalTableElement.ItemKind = ItemKind;
	AdditionalTableElement.NameForPrinting = String(ItemKind);
	Postfix = ?(TableType = 1, "Return", "");
	AdditionalTableElement.CustomPicture = FinancialReportingServerCall.CustomPicture(ItemKind, Postfix);
	
	AddReflectionLine(ReflectionString(NewRow).GetItems(), AdditionalTableElement, ThisObject);
	
	ItemKind = ItemKind("Rows");
	AdditionalTableElement = SubordinateRows.Add();
	AdditionalTableElement.ItemKind = ItemKind;
	AdditionalTableElement.NameForPrinting = String(ItemKind);
	Postfix = ?(TableType = 0, "Return", "");
	AdditionalTableElement.CustomPicture = FinancialReportingServerCall.CustomPicture(ItemKind, Postfix);
	
	AddReflectionLine(ReflectionString(NewRow).GetItems(), AdditionalTableElement, ThisObject);
	
	ItemKind = ItemKind("CellsSettings");
	AdditionalTableElement = SubordinateRows.Add();
	AdditionalTableElement.ItemKind = ItemKind;
	If TableType = 2 Then
		AdditionalTableElement.NameForPrinting = String(ItemKind);
	Else
		AdditionalTableElement.NameForPrinting = NStr("vi = 'Tùy chỉnh lập';
														|ru = 'Настройка оформления';
														|en = 'Appearance setting'; fa = 'تنظیم ظاهر';
														|it = 'Impostazione di formattazione';
														|pl = 'Ustawienia wyglądu';
														|tr = 'Düzenleme ayarı'");
	EndIf;
	AdditionalTableElement.CustomPicture = FinancialReportingServerCall.CustomPicture(ItemKind);
	AddReflectionLine(ReflectionString(NewRow).GetItems(), AdditionalTableElement, ThisObject);
	
	Items.DisplayReportItems.Expand(ReflectionString(Parent).GetID());
	Items.DisplayReportItems.Expand(ReflectionString(NewRow).GetID(), True);
	Items.DisplayReportItems.CurrentRow = ReflectionString(NewRow).GetID();
	
EndProcedure

&AtClient
Function DraggingIsAllowed(TreeRow, ParentReceiver)
	
	ViewOfDraggableElement = Undefined;
	If TypeOf(TreeRow) = Type("Number") Then //dragging inside the tree
		ReportElementDisplay = DisplayReportItems.FindByID(TreeRow);
		// Dragging may occur from one budget view to another. In this case, the report item
		// may not be found by ID.
		If ReportElementDisplay <> Undefined Then
			ViewOfDraggableElement = ReportElementDisplay.ItemKind;
		EndIf;
	Else
		ViewOfDraggableElement = TreeRow.ItemKind;
	EndIf;
	
	If Not ValueIsFilled(ViewOfDraggableElement) Or
		Not YouCanAddItToBudgetViewStructure(ViewOfDraggableElement, ParentReceiver) Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

&AtClient
Function YouCanAddItToBudgetViewStructure(ElementTypePortable, IDOfLineWhereWeAreTakingIt)
	
	TheStructureOfTheSearch = New Array;
	TheStructureOfTheSearch.Add(ElementTypePortable); // Item
	If IDOfLineWhereWeAreTakingIt = Undefined Then
		TheStructureOfTheSearch.Add(ItemKind("EmptyRef")); // Parent
	Else
		ReportElementString = ReportItems.FindByID(IDOfLineWhereWeAreTakingIt);
		TheStructureOfTheSearch.Add(ReportElementString.ItemKind); // Parent
		
		FoundRows = CacheOfInvalidCombinations.Get(ElementTypePortable);
		If FoundRows <> Undefined Then
			For Each StringOfInvalidCombinations In FoundRows Do
				Item = FinancialReportingClient.RootElementOfFormElement(ReportElementString,
						StringOfInvalidCombinations.Key);
				If Item <> Undefined Then
					Return False;
				EndIf;
			EndDo;
		EndIf;
		
		Item1 = Undefined;
		
		If ReportElementString.ItemKind <> ItemKind("Columns")
			And ReportElementString.ItemKind <> ItemKind("Rows") Then
			
			Item1 = GetRowByViewByHierarchy(ReportElementString, ItemKind("Rows"));
			If Item1 = Undefined Then
				Item1 = GetRowByViewByHierarchy(ReportElementString, ItemKind("Columns"));
			EndIf;
			If Item1 <> Undefined Then
				Item1 = Item1.ItemKind;
			EndIf;
			
		EndIf;
		
		If Not ValueIsFilled(Item1) Then
			Item1 = ItemKind("EmptyRef");
		EndIf;
		
		TheStructureOfTheSearch.Add(Item1); // ColumnRows
			
		Item2 = GetRowByViewByHierarchy(ReportElementString, ItemKind("TableIndicatorsInRows"));
		If Item2 = Undefined Then
			Item2 = GetRowByViewByHierarchy(ReportElementString, ItemKind("TableIndicatorsInColumns"));
		EndIf;
		If Item2 = Undefined Then
			Item2 = GetRowByViewByHierarchy(ReportElementString, ItemKind("ComplexTable"));
		EndIf;
		If Item2 <> Undefined Then
			Item2 = Item2.ItemKind;
		EndIf;
		If Not ValueIsFilled(Item2) Then
			Item2 = ItemKind("EmptyRef");
		EndIf;
		
		TheStructureOfTheSearch.Add(Item2); // TableType
		
	EndIf;
	
	SearchPoint = CacheOfValidCombinations;
	For Each SearchItem In TheStructureOfTheSearch Do
		
		FoundRows = SearchPoint.Get(SearchItem);
		If FoundRows = True Then
			Return True;
		ElsIf FoundRows = Undefined Then
			Return False;
		ElsIf FoundRows.Count() Then
			SearchPoint = FoundRows;
		Else
			Return False;
		EndIf;
		
	EndDo;
	
	Return True;
	
EndFunction

&AtClient
Function GetRowByViewByHierarchy(ElementString, ItemKind)
	
	If ElementString.ItemKind = ItemKind Then
		Return ElementString;
	EndIf;
	
	Return FinancialReportingClient.RootElementOfFormElement(ElementString, ItemKind);
	
EndFunction

&AtServer
Procedure ClearDeletedReportElements(SettingUpIDCells, IDCurrentRow)
	
	CellsSettings = ReportItems.FindByID(SettingUpIDCells);
	CurrentRow = ReportItems.FindByID(IDCurrentRow);
	
	If Not ValueIsFilled(CellsSettings.AddressOfItemStructure) Then
		CellsSettings.AddressOfItemStructure = BudgetReportingClientServer.PlaceItemInStorage(CellsSettings, UUID);
	EndIf;
	ElementStructure = GetFromTempStorage(CellsSettings.AddressOfItemStructure);
	FoundRows = ElementStructure.TableItems.FindRows(New Structure("String", CurrentRow.ReportItem));
	For Each FoundRow In FoundRows Do
		ElementStructure.TableItems.Delete(FoundRow);
	EndDo;
	FoundRows = ElementStructure.TableItems.FindRows(New Structure("String", CurrentRow.AddressOfItemStructure));
	For Each FoundRow In FoundRows Do
		ElementStructure.TableItems.Delete(FoundRow);
	EndDo;
	FoundRows = ElementStructure.TableItems.FindRows(New Structure("Column", CurrentRow.ReportItem));
	For Each FoundRow In FoundRows Do
		ElementStructure.TableItems.Delete(FoundRow);
	EndDo;
	FoundRows = ElementStructure.TableItems.FindRows(New Structure("Column", CurrentRow.AddressOfItemStructure));
	For Each FoundRow In FoundRows Do
		ElementStructure.TableItems.Delete(FoundRow);
	EndDo;
	PutToTempStorage(ElementStructure, CellsSettings.AddressOfItemStructure);
	
EndProcedure

&AtServer
Procedure ClearRelatedDesignElements(SettingUpIDCells, IDCurrentRow)
	
	CellsSettings = ReportItems.FindByID(SettingUpIDCells);
	CurrentRow = ReportItems.FindByID(IDCurrentRow);
	If Not ValueIsFilled(CellsSettings.AddressOfItemStructure) Then
		CellsSettings.AddressOfItemStructure = BudgetReportingClientServer.PlaceItemInStorage(CellsSettings, UUID);
	EndIf;
	ElementStructure = GetFromTempStorage(CellsSettings.AddressOfItemStructure);
	
	ArrayOfItemsToDelete = New Array;
	TableStructure = New Structure("RegisteredRows, DesigningColumns, DrillDownOfAppearanceItemFilterFields");
	For Each KeyAndValue In TableStructure Do
		FoundRows = ElementStructure[KeyAndValue.Key].FindRows(New Structure("ReportItem", CurrentRow.ReportItem));
		CommonClientServer.SupplementArray(
				FoundRows,
				ElementStructure[KeyAndValue.Key].FindRows(New Structure("ReportItem", CurrentRow.AddressOfItemStructure)));
		For Each FoundRow In FoundRows Do
			ArrayOfItemsToDelete.Add(FoundRow.AppearanceItemKey);
		EndDo;
		For Each FoundRow In FoundRows Do
			ElementStructure[KeyAndValue.Key].Delete(FoundRow);
		EndDo;
	EndDo;
	
	ArrayOfItemsToDelete = CommonClientServer.CollapseArray(ArrayOfItemsToDelete);
	
	For Each ItemKey In ArrayOfItemsToDelete Do
		ElementKeyIsUsed = False;
		For Each KeyAndValue In TableStructure Do
			FoundRows = ElementStructure[KeyAndValue.Key].FindRows(New Structure("AppearanceItemKey", ItemKey));
			
			If FoundRows.Count() > 0 Then
				ElementKeyIsUsed = True;
				Break;
			EndIf;
		EndDo;
		
		If Not ElementKeyIsUsed Then
			ItemToRemove = ElementStructure.AppearanceItems.Find(ItemKey, "AppearanceItemKey");
			If Not ItemToRemove = Undefined Then
				ElementStructure.AppearanceItems.Delete(ItemToRemove);
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure HowToFillInAddressOfElementStructureToConfigureCells(Rows, AddressOfItemStructure, CachedAddressInStorage)
	
	For Each Item In Rows.GetItems() Do
		
		If Not Item.ItemKind = Enums.FinancialReportItemKinds.Columns
			And Not Item.ItemKind = Enums.FinancialReportItemKinds.Rows Then
			
			If Not ValueIsFilled(Item.AddressOfItemStructure) Then
				Item.AddressOfItemStructure = 
						BudgetReportingClientServer.PlaceItemInStorage(Item, UUID);
			EndIf;
			
			SettingsData = GetFromTempStorage(AddressOfItemStructure); // See FinancialReportingClientServer.ReportElementStructure
		
			FoundRows = SettingsData.TableItems.FindRows(New Structure("String", Item.ReportItem));
			For Each FoundRow In FoundRows Do
				FoundRow.String = Item.AddressOfItemStructure;
			EndDo;
			FoundRows = SettingsData.TableItems.FindRows(New Structure("Column", Item.ReportItem));
			For Each FoundRow In FoundRows Do
				FoundRow.Column = Item.AddressOfItemStructure;
			EndDo;
			
			PutToTempStorage(SettingsData, AddressOfItemStructure);
			CachedAddressInStorage.Insert(Item.ReportItem, Item.AddressOfItemStructure);
			
		EndIf;
		
		If Not Item.ItemKind = Enums.FinancialReportItemKinds.CellsSettings Then
			HowToFillInAddressOfElementStructureToConfigureCells(Item, AddressOfItemStructure, CachedAddressInStorage);
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInStructureAddressBeforeSettingUpCells(Id, AddressOfItemStructure, AddingParameters)
	
	String = ReportItems.FindByID(Id);
	TableType = Enums.FinancialReportItemKinds.ComplexTable;
	Table = FinancialReportingServer.RootItem(String, TableType);
	Var_247_TableType = Enums.FinancialReportItemKinds.ComplexTable;
	If Table = Undefined Then
		TableType = Enums.FinancialReportItemKinds.TableIndicatorsInColumns;
		Table = FinancialReportingServer.RootItem(String, TableType);
		Var_247_TableType = Enums.FinancialReportItemKinds.TableIndicatorsInColumns;
	EndIf;
	If Table = Undefined Then
		TableType = Enums.FinancialReportItemKinds.TableIndicatorsInRows;
		Table = FinancialReportingServer.RootItem(String, TableType);
		Var_247_TableType = Enums.FinancialReportItemKinds.TableIndicatorsInRows;
	EndIf;
	
	If Var_247_TableType <> Enums.FinancialReportItemKinds.ComplexTable Then
		AddingParameters.Insert("CheckTableView", True);
		AddingParameters.Insert("TableType", Var_247_TableType);
	EndIf;
	
	CachedAddressInStorage = New Map;
	HowToFillInAddressOfElementStructureToConfigureCells(Table, AddressOfItemStructure, CachedAddressInStorage);
	
	SettingsData = GetFromTempStorage(AddressOfItemStructure); // See FinancialReportingClientServer.ReportElementStructure
	For Each RowColumn In SettingsData.TableItems Do
		
		If TypeOf(RowColumn.Item) = Type("CatalogRef.FinancialReportItems") Then
			RowColumn.Item = FinancialReportingServerCall.PlaceItemInStorage(
				RowColumn.Item, UUID);
		EndIf;
		If TypeOf(RowColumn.String) = Type("CatalogRef.FinancialReportItems") Then
			RowColumn.String = CachedAddressInStorage[RowColumn.String];
		EndIf;
		If TypeOf(RowColumn.Column) = Type("CatalogRef.FinancialReportItems") Then
			RowColumn.Column = CachedAddressInStorage[RowColumn.Column];
		EndIf;
		
		ElementData = GetFromTempStorage(RowColumn.Item);
		For Each Operand In ElementData.FormulaOperands Do
			If Not ValueIsFilled(Operand.AddressOfItemStructure) Then
				Operand.AddressOfItemStructure = FinancialReportingServerCall.PlaceItemInStorage(
					Operand.Operand, UUID);
			EndIf;
			OperandData = GetFromTempStorage(Operand.AddressOfItemStructure);
			If OperandData.ItemKind = Enums.FinancialReportItemKinds.TableCell Then
				ItemRef = FinancialReportingServerCall.ValueOfAdditionalProps(
						OperandData,
						"CellRow");
				If TypeOf(ItemRef) = Type("CatalogRef.FinancialReportItems") Then
					FinancialReportingServerCall.SetValueOfAdditionalProps(
						OperandData,
						"CellRow",
						CachedAddressInStorage[ItemRef]);
				EndIf;
				ItemRef = FinancialReportingServerCall.ValueOfAdditionalProps(
						OperandData, 
						"CellColumn");
				If TypeOf(ItemRef) = Type("CatalogRef.FinancialReportItems") Then
					FinancialReportingServerCall.SetValueOfAdditionalProps(
							OperandData,
							"CellColumn",
							CachedAddressInStorage[ItemRef]);
				EndIf;
				PutToTempStorage(OperandData, Operand.AddressOfItemStructure);
			EndIf;
		EndDo;
		PutToTempStorage(ElementData, RowColumn.Item);
		
	EndDo;
	
	For Each RowColumn In SettingsData.RegisteredRows Do
		
		If TypeOf(RowColumn.ReportItem) = Type("CatalogRef.FinancialReportItems") Then
			RowColumn.ReportItem = CachedAddressInStorage[RowColumn.ReportItem];
		EndIf;
		
	EndDo;
	
	For Each RowColumn In SettingsData.DesigningColumns Do
		
		If TypeOf(RowColumn.ReportItem) = Type("CatalogRef.FinancialReportItems") Then
			RowColumn.ReportItem = CachedAddressInStorage[RowColumn.ReportItem];
		EndIf;
		
	EndDo;
	
	For Each RowColumn In SettingsData.DrillDownOfAppearanceItemFilterFields Do
		
		If TypeOf(RowColumn.ReportItem) = Type("CatalogRef.FinancialReportItems") Then
			RowColumn.ReportItem = CachedAddressInStorage[RowColumn.ReportItem];
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Function DefineAdditionalParameters(CurrentRow, Cache = Undefined)
	
	NameOfAdditionalModes = "Enum.AdditionalModesOfReportItems.";
	If CurrentRow.ItemKind = ItemKind("BudgetFlowItem", Cache) Then
		If FinancialReportingClient.RootElementOfFormElement(
			CurrentRow, ItemKind("BudgetBalanceItem", Cache)) <> Undefined Then
			
			Return PredefinedValue(NameOfAdditionalModes + "ItemInBudgetBalanceItem");
			
		ElsIf FinancialReportingClient.RootElementOfFormElement(
			CurrentRow, ItemKind("AllBudgetBalanceItems", Cache)) <> Undefined Then
			
			Return PredefinedValue(NameOfAdditionalModes + "ItemInBudgetBalanceItem");
			
		ElsIf Object.UseToEnterPlan Then
			
			Return PredefinedValue(NameOfAdditionalModes + "BudgetFlowItemInInputMode");
			
		EndIf;
	ElsIf CurrentRow.ItemKind = ItemKind("AllBudgetFlowItems", Cache) Then
		If FinancialReportingClient.RootElementOfFormElement(
			CurrentRow, ItemKind("BudgetBalanceItem", Cache)) <> Undefined Then
			
			Return PredefinedValue(NameOfAdditionalModes + "ItemInBudgetBalanceItem");
			
		ElsIf FinancialReportingClient.RootElementOfFormElement(
			CurrentRow, ItemKind("AllBudgetBalanceItems", Cache)) <> Undefined Then
			
			Return PredefinedValue(NameOfAdditionalModes + "ItemInBudgetBalanceItem");
			
		ElsIf FinancialReportingClient.RootElementOfFormElement(
			CurrentRow, ItemKind("ComplexTable", Cache)) <> Undefined Then
			
			Return PredefinedValue(NameOfAdditionalModes + "AllItemsInComplexTable");
			
		EndIf;
	ElsIf CurrentRow.ItemKind = ItemKind("RowColumn", Cache) Then
		If Object.UseToEnterPlan Then
			
			Return PredefinedValue(NameOfAdditionalModes + "TableItemInInputMode");
			
		ElsIf FinancialReportingClient.RootElementOfFormElement(
			CurrentRow, ItemKind("ComplexTable", Cache)) <> Undefined Then
			
			Return PredefinedValue(NameOfAdditionalModes + "TableItemInComplexTable");
			
		EndIf;
	ElsIf CurrentRow.ItemKind = ItemKind("AllBudgetBalanceItems", Cache) Then
		If FinancialReportingClient.RootElementOfFormElement(
			CurrentRow, ItemKind("ComplexTable")) <> Undefined Then
			
			Return PredefinedValue(NameOfAdditionalModes + "AllIndicatorsInAComplexTable");
			
		EndIf;
	EndIf;
	
EndFunction

&AtClient
Procedure EditFragmentReportElement(CurrentRow)
	
	If CurrentRow.ItemKind = ItemKind("Columns")
		Or CurrentRow.ItemKind = ItemKind("Rows")
		Or CurrentRow.ItemKind = ItemKind("EmptyRef") Then
		Return;
	EndIf;
	
	TheseAreLines = FinancialReportingClient.RootElementOfFormElement(CurrentRow, ItemKind("Columns")) = Undefined;
	If IsBlankString(CurrentRow.AddressOfItemStructure) Then
		CurrentRow.AddressOfItemStructure = BudgetReportingClientServer.PlaceItemInStorage(CurrentRow, UUID);
	EndIf;
	
	FormParameters = New Structure();
	
	If CurrentRow.ItemKind = ItemKind("CellsSettings") Then
		FillInStructureAddressBeforeSettingUpCells(CurrentRow.GetID(), CurrentRow.AddressOfItemStructure, FormParameters);
	EndIf;
	
	If CurrentRow.ItemKind = ItemKind("ReportHeader") Then
		AddressOfTheAnalyticsList = PlaceListOfAnalyticsCapsInRepository(Object.HeaderDimensions, UUID);
		FormParameters.Insert("AddressOfTheAnalyticsList", AddressOfTheAnalyticsList);
	EndIf;
	
	FormParameters.Insert("LineIDOfReportItem",CurrentRow.GetID());
	FormParameters.Insert("Key", 							CurrentRow.ReportItem);
	FormParameters.Insert("ItemKind", 						CurrentRow.ItemKind);
	FormParameters.Insert("ItemAddressInStorage", 			CurrentRow.AddressOfItemStructure);
	FormParameters.Insert("MainStorageID", 	UUID);
	FormParameters.Insert("ReportItems", 					ReportItems);
	FormParameters.Insert("UseToEnterPlan", 		Object.UseToEnterPlan);
	FormParameters.Insert("AdditionalFormMode", 		DefineAdditionalParameters(CurrentRow));
	FormParameters.Insert("BudgetingModel", 			Object.Owner);
	FormParameters.Insert("LocationOptionOfActualDataOffset", Object.LocationOptionOfActualDataOffset);
	FormParameters.Insert("TheseAreLines", 						TheseAreLines);
	NamesOfEditedCells = BudgetReportingClient.NamesOfEditedCells(ReportItems, CurrentRow.GetID());
	FormParameters.Insert("EditedValues", 			PutToTempStorage(NamesOfEditedCells, UUID));
	
	Notification = New CallbackDescription("UpdateBudgetViewLineAfterChange", ThisObject, FormParameters);
	OpenForm("Catalog.FinancialReportItems.ObjectForm", 
				FormParameters, ThisObject, , , , Notification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure WhenSelectingGroupedItem(CurrentRow, AdditionalParameters) Export
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	CurrentRow = CurrentRow.Value;
	EditFragmentReportElement(CurrentRow);
	
EndProcedure

&AtClient
Procedure EditReportElement()
	
	If Items.DisplayReportItems.ReadOnly Then
		WarningText = NStr("vi = 'Dạng ngân sách được sử dụng trong các chứng từ và không cho phép soạn';
							|ru = 'Вид бюджета используется в документах и недоступен для редактирования';
							|en = 'This budget profile is used in the documents. You cannot edit it'; fa = 'This budget profile is used in the documents. You cannot edit it';
							|it = 'Il tipo di budget è utilizzato nei documenti e non è modificabile';
							|pl = 'Rodzaj budżetu jest używany w dokumentach i nie może być edytowany';
							|tr = 'Bütçe profili belgelerde kullanılmaktadır ve düzenlemeye müsait değildir'");
		ShowMessageBox(,WarningText);
		Return;
	EndIf;
	
	CurLineDisplay = Items.DisplayReportItems.CurrentData;
	ChoiceList = New ValueList;
	StringOfElements = ReflectedLine(CurLineDisplay, ThisObject);
	ChoiceList.Add(StringOfElements, StringOfElements.NameForPrinting);
	For Cnt = 2 To Items.NameForPrinting.ChildItems.Count() Do
		If CurLineDisplay.Property("LineIndexOfReportItems"+ Cnt) Then
			LineIndexOfReportItems = CurLineDisplay["LineIndexOfReportItems" + Cnt];
			If LineIndexOfReportItems <> Undefined Then
				StringOfElements = ReportItems.FindByID(LineIndexOfReportItems);
				ChoiceList.Add(StringOfElements, StringOfElements.NameForPrinting);
			EndIf;
		EndIf;
	EndDo;
		
	If ChoiceList.Count() = 1 Then
		CurrentRow = ChoiceList[0].Value;
		EditFragmentReportElement(CurrentRow);
	Else
		CallbackDescription = New CallbackDescription("WhenSelectingGroupedItem", ThisObject);
		ShowChooseFromMenu(CallbackDescription, ChoiceList, CurrentItem);
	EndIf;
	
EndProcedure

&AtServerNoContext
Function AdditionalFieldsOfReportElement(Result)
	
	AdditionalFields = Result.AdditionalFields.Unload();
	Return StrConcat(AdditionalFields.UnloadColumn("Description"), ", ");
	
EndFunction

&AtClient
Procedure UpdateBudgetViewLineAfterChange(Result, AdditionalParameters) Export
	
	BudgetReportingClientServer.FillInLineInListOfReportElements(
			Result,
			AdditionalParameters.LineIDOfReportItem,
			AdditionalParameters.ItemAddressInStorage,
			ReportItems);
	
	If Result <> Undefined Then
		
		AdditionalFields = AdditionalFieldsOfReportElement(Result);
		
		LineReflection = ReflectionString(AdditionalParameters.LineIDOfReportItem, False);
		If LineReflection <> Undefined Then
			ReportElementString = ReportItems.FindByID(AdditionalParameters.LineIDOfReportItem);
			FillPropertyValues(LineReflection, ReportElementString);
			LineReflection.AdditionalFieldPresentation = AdditionalFields;
		Else
			For Cnt = 2 To Items.NameForPrinting.ChildItems.Count() Do
				LineReflection = FinancialReportingClient.SubordinateElementOfFormElement(
						DisplayReportItems, "LineIndexOfReportItems" + Cnt, 
						AdditionalParameters.LineIDOfReportItem);
				If LineReflection <> Undefined Then
					ReportElementString = ReportItems.FindByID(AdditionalParameters.LineIDOfReportItem);
					LineReflection["NameForPrinting" + Cnt] = ReportElementString.NameForPrinting;
					LineReflection["AdditionalFieldPresentation" + Cnt] = AdditionalFields;
					Break;
				EndIf;
			EndDo;
		EndIf;
		ThereIsPrivilegedMode = False;
		If Result.Property("ThereIsPrivilegedMode") And Result.ThereIsPrivilegedMode Then
			ThereIsPrivilegedMode = Result.ThereIsPrivilegedMode;
		Else
			ThereIsPrivilegedMode = ValueIsFilled(LineReflection.PrivilegedMode) And LineReflection.PrivilegedMode;
		EndIf;			
		LineReflection.PrivilegedModePicture = Not Number(ThereIsPrivilegedMode);
		
		Modified = True;
	EndIf;
	
EndProcedure

&AtClient
Function FindFixedAnalyticsLine(RowElements, ItemKind, DimensionType, Value, Other, FoundItem = Undefined)
	
	For Each Item In RowElements Do
		If Item.ItemKind = ItemKind
			And Item.DimensionValue = Value
			And Item.ThisIsDimensionOther = Other
			And Item.ItemIndicatorDimensionType = DimensionType Then
			
			FoundItem = Item;
			Return True;
			
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

&AtClient
Function ItemKind(ElementTypeName, ElementCache_ = Undefined)
	
	If ElementCache_ = Undefined Then
		ElementCache_ = New Map;
	EndIf;
	
	Value = ElementCache_[ElementTypeName];
	If Value = Undefined Then
		Value = PredefinedValue("Enum.FinancialReportItemKinds." + ElementTypeName);
		ElementCache_.Insert(ElementTypeName, Value);
	EndIf;
	
	Return Value;
	
EndFunction

&AtClient 
Procedure MoveLine(Tree, IdWhat, ToID = Undefined, Copy, IdsOfTransferredLines, Cache = Undefined)
	
	CurrentRow = Tree.FindByID(IdWhat);
	
	If ToID = Undefined Then
		NewParent = FinancialReportingClient.RootElementOfFormElement(Tree);
		NewParentReflection = ReflectionString(NewParent);
	Else
		NewParent = Tree.FindByID(ToID);
		// The reflection string is identified by the first element of the string in the case of grouping.
		NewParentReflection = ReflectionString(NewParent);
		// And in fact, the row will be subordinate to the lower of the grouped elements
		// , so for the report item, the row on the first row of the grouping will be applied, 
		// and for the transfer, the row that is lower in the grouping from the report item.
		NewParent = SkipDisplayedImages(NewParent);
	EndIf;
	
	// Let's check that the element is not transferred to its subordinate element
	Parent = NewParent.GetParent();
	While Parent <> Undefined Do
		If Parent = CurrentRow Then
			Return;
		EndIf;
		Parent = Parent.GetParent();
	EndDo;
	
	If Not YouCanAddItToBudgetViewStructure(CurrentRow.ItemKind, ToID) Then
		Return;
	EndIf;
	
	// When dragging the grouping branch, we check whether the elements can be moved to the current context
	// for tables, such a check does not make sense, because the transfer is always carried out to the root.
	If CurrentRow.ItemKind <> ItemKind("TableIndicatorsInColumns")
		And CurrentRow.ItemKind <> ItemKind("TableIndicatorsInRows")
		And CurrentRow.ItemKind <> ItemKind("ComplexTable") Then
		
		If ThereAreInaccessibleItemsAfterMigration(CurrentRow, ToID) Then
			Text = NStr("vi = 'Đã hủy chuyển. Trong các phần tử trực thuộc của dòng chuyển đã tìm thấy các phần tử không hợp lệ';
						|ru = 'Перенос отменен. В подчиненных элементах переносимой строки обнаружены недопустимые элементы';
						|en = 'Transfer is canceled. Invalid items are found in the subordinate items of the line to be transferred'; fa = 'Transfer is canceled. Invalid items are found in the subordinate items of the line to be transferred';
						|it = 'Trasferimento annullato. Elementi non validi trovati negli elementi subordinati della riga da trasferire';
						|pl = 'Przeniesienie zostało anulowane. W elementach podporządkowanych przenoszonego wiersza wykryto niedostępne elementy';
						|tr = 'Erteleme iptal edildi. Satırların taşınan alt öğelerinde izin verilemeyecek öğeler tespit edildi'");
			ShowMessageBox(, Text, 60);
			Return;
		EndIf;
		
	EndIf;
	
	RowElements = FinancialReportingClient.SubordinateLinesOfFormElement(NewParent);
	TotalItems = RowElements.Count();
	If TotalItems Then
		PutFormulaBackInPlace = RowElements[TotalItems - 1].ItemKind = ItemKind("GroupFormula");
	EndIf;
	
	ParametersForSavingIDs = New Structure(
		"Mode, IDsMap, NumberOfIDs",
		"Remember", New Map, Items.NameForPrinting.ChildItems.Count());
	
	InstallationParameters = FinancialReportingClient.TemplateForNewParentInstallationOptions();
	InstallationParameters.FormIdentifier = UUID;
	InstallationParameters.Copy = Copy;
	InstallationParameters.IDParameters_ = ParametersForSavingIDs;
	FinancialReportingClient.SetNewParentOfFormElement(CurrentRow, NewParent, InstallationParameters);
	CurLineReflection = ReflectionString(CurrentRow);
	
	ParametersForSavingIDs.Mode = "Refresh";
	InstallationParameters = FinancialReportingClient.TemplateForNewParentInstallationOptions();
	InstallationParameters.LoopControl = False;
	InstallationParameters.Copy = Copy;
	InstallationParameters.IDParameters_ = ParametersForSavingIDs;
	FinancialReportingClient.SetNewParentOfFormElement(CurLineReflection, NewParentReflection, InstallationParameters);
	
	Modified = True;
	AdjustStringAccordingToOptionalModeRecursively(NewParent, Cache);
	
	Items.DisplayReportItems.Expand(NewParentReflection.GetID(), True);
	
	If TotalItems And PutFormulaBackInPlace Then
		Move = RowElements.Count() - TotalItems;
		RowElements.Move(TotalItems - 1, Move);
		RowElementsReflection = FinancialReportingClient.SubordinateLinesOfFormElement(NewParent);
		RowElementsReflection.Move(TotalItems - 1, Move);
	EndIf;
	
	For Each RowID In ParametersForSavingIDs.IDsMap Do
		IdsOfTransferredLines.Add(RowID.Key);
	EndDo;
	
EndProcedure

&AtClient
Function ThereAreInaccessibleItemsAfterMigration(Parent, ToID)
	
	ParentItems1 = Parent.GetItems();
	For Each Item In ParentItems1 Do
		
		If Item.ItemKind = ItemKind("GroupFormula") Then
			Continue;
		EndIf;
		
		If Not YouCanAddItToBudgetViewStructure(Item.ItemKind, ToID) Then
			Return True;
		EndIf;
		
		If ThereAreInaccessibleItemsAfterMigration(Item, ToID) Then
			Return True;
		EndIf;
		
	EndDo;
	
	Return False;
	
EndFunction

&AtClient
Procedure AdjustStringAccordingToOptionalModeRecursively(Parent, Cache = Undefined)
	
	ParentItems1 = Parent.GetItems();
	For Each Item In ParentItems1 Do
		
		AdjustStringAccordingToOptionalMode(Item, Cache);
		AdjustStringAccordingToOptionalModeRecursively(Item, Cache);
		
	EndDo;
	
EndProcedure

&AtServer
Function ThereAreInstances()
	
	If Object.Ref.IsEmpty() Then
		Return False;
	EndIf;
	
	SetPrivilegedMode(True);
	
	Query = New Query(
	"SELECT TOP 1
	|	BudgetEntryForm.Ref
	|FROM
	|	Document.BudgetEntryForm AS BudgetEntryForm
	|WHERE
	|	BudgetEntryForm.BudgetProfile = &BudgetProfile"
	);
	
	Query.SetParameter("BudgetProfile", Object.Ref);
	
	EmptyResult = Query.Execute().IsEmpty();
	
	SetPrivilegedMode(False);
	
	Return Not EmptyResult;
	
EndFunction

&AtServer
Procedure FormControl()
	
	If Items.Owner.ReadOnly Then
		BudgetUsed = ThereAreInstances();
		Items.DisplayReportItems.ReadOnly = BudgetUsed;
		Items.UseToEnterPlan.ReadOnly = True;
		Items.ConfigureBudgetProfile.ReadOnly = BudgetUsed;
		Items.HeaderDimensions.ReadOnly = True;
	Else
		Items.DisplayReportItems.ReadOnly = False;
		Items.UseToEnterPlan.ReadOnly = False;
		Items.ConfigureBudgetProfile.ReadOnly = False;
		Items.HeaderDimensions.ReadOnly = False;
	EndIf;
	
	Items.ConfigureBudgetProfile.Enabled = Not ReadOnly;
	Items.HeaderDimensions.Enabled = Not ReadOnly;
	
	Items.EditingSettingsGroup.Visible = Object.UseToEnterPlan;
	//++ TMAR
	Items.GenerateRelatedBudgetTurnovers.Visible = Object.UseToEnterPlan;
	//-- TMAR
	
	Items.FormCreateBudgetEntryDocument.Visible = Object.UseToEnterPlan And AccessRight("InteractiveInsert", Metadata.Documents.BudgetEntryForm);
	Items.FormViewTheReportView.Visible = AccessRight("View", Metadata.Reports.BudgetReport);
	If Object.UseToEnterPlan Then
		Commands.ViewTheReportView.ToolTip = NStr("vi = 'Xem dạng báo cáo (khi có bản ngân sách đã nhập)';
													|ru = 'Посмотреть вид отчета (при наличии введенных экземпляров бюджетов)';
													|en = 'View report type (if entered budget entry forms are available)'; fa = 'View report type (if entered budget entry forms are available)';
													|it = 'Посмотреть вид отчета (при наличии введенных экземпляров бюджетов)';
													|pl = 'View report type (if entered budget entry forms are available)';
													|tr = 'Rapor türünü görüntüle (girilen bütçe giriş formları varsa)'");
	Else
		Commands.ViewTheReportView.ToolTip = NStr("vi = 'Xem dạng báo cáo';
													|ru = 'Посмотреть вид отчета';
													|en = 'View budget report'; fa = 'مشاهده گزارش بودجه';
													|it = 'Посмотреть вид отчета';
													|pl = 'Zobacz rodzaj raportu';
													|tr = 'Rapor türünü göster'");
	EndIf;
	If AccessRight("View", Metadata.Documents.BudgetEntryForm) Then
		Items.FormInstancesByBudgetProfile.Visible = Object.UseToEnterPlan;
	EndIf;
	
	If Object.PlanningMethod = Enums.BudgetPreparationMethods.ForAFixedPeriod Then
		ConfigureBudgetProfile = NStr("vi = 'Trong kỳ cố định %1';
										|ru = 'На фиксированный период %1';
										|en = 'For fixed period %1'; fa = 'For fixed period %1';
										|it = 'Per un periodo fisso %1';
										|pl = 'Na okres stały %1';
										|tr = '%1 sabit döneminde'");
		ConfigureBudgetProfile = StringFunctionsClientServer.SubstituteParametersToString(ConfigureBudgetProfile, Lower(Object.Periodicity));
	ElsIf Object.PlanningMethod = Enums.BudgetPreparationMethods.Rolling Then
		NumberOfPeriods_ = WorkingWithClientServerPeriods.PeriodInNumbersPeriodicityInWords(
				Object.NumberOfPeriodsOfRollingBudget, 
				Object.Periodicity);
		ConfigureBudgetProfile = NStr("vi = 'Ngân sách kỳ liên hoàn %1 trước';
										|ru = 'Скользящий бюджет на %1 вперед';
										|en = 'Rolling budget for %1 forward'; fa = 'Rolling budget for %1 forward';
										|it = 'Budget rinnovabile per %1 in anticipo';
										|pl = 'Budżet kroczący na %1 do przodu';
										|tr = '%1 ve sonrası dinamik bütçe'");
		ConfigureBudgetProfile = StringFunctionsClientServer.SubstituteParametersToString(ConfigureBudgetProfile, NumberOfPeriods_);
	EndIf;
	
	ConfigureBudgetProfile = ConfigureBudgetProfile + "; ";
	
	If Object.LocationOptionOfActualDataOffset = Enums.LocationOptionsOfActualDataOffsets.WithinBudgetPeriod Then
		ConfigureBudgetProfile = ConfigureBudgetProfile + " " + NStr("vi = 'biên dữ liệu thực tế trong giai đoạn ngân sách';
																	|ru = 'граница факт.данных внутри периода бюджета';
																	|en = 'actual data boundary is within budget period'; fa = 'actual data boundary is within budget period';
																	|it = 'limite dei dati effettivi all''interno del periodo di budget';
																	|pl = 'granica danych fakt. wewnątrz okresu budżetu';
																	|tr = 'bütçe dönemi dahilinde gerçek veri limiti'");
	ElsIf Object.LocationOptionOfActualDataOffset = Enums.LocationOptionsOfActualDataOffsets.BeforeBudgetPreparation Then
		NumberOfPeriods_ = WorkingWithClientServerPeriods.PeriodInNumbersPeriodicityInWords(
				Object.ActualDataLimitOffset, 
				Object.ActualDataLimitTimeFence);
		ConfigureBudgetProfile = ConfigureBudgetProfile + NStr("vi = 'lập ra %1 trước khi bắt đầu kỳ lập kế hoạch';
																|ru = 'составляется за %1 до начала периода планирования';
																|en = 'created for %1 before the beginning of the planning period'; fa = 'created for %1 before the beginning of the planning period';
																|it = 'viene redatto %1 prima dell''inizio del periodo di pianificazione';
																|pl = 'tworzy się za %1 do rozpoczęcia planowania';
																|tr = 'planlama döneminin başlangıcı öncesinde %1 için derlendi'");
		ConfigureBudgetProfile = StringFunctionsClientServer.SubstituteParametersToString(ConfigureBudgetProfile, NumberOfPeriods_);
	EndIf;
	
	If Object.PlanningMethod = Enums.BudgetPreparationMethods.ForAFixedPeriod Then
		Items.FixedPeriod.Visible		= True;
		Items.RollingPlanning.Visible	= False;
	Else
		Items.FixedPeriod.Visible		= False;
		Items.RollingPlanning.Visible	= True;
	EndIf;
	
	BeforeBudget = Object.LocationOptionOfActualDataOffset = Enums.LocationOptionsOfActualDataOffsets.BeforeBudgetPreparation;
	Items.ActualDataLimitOffset.Enabled 						= BeforeBudget;
	Items.ActualDataLimitTimeFence.Enabled 					= BeforeBudget;
	Items.PeriodCaptionPostfix.Enabled 					= BeforeBudget;
	
	If Object.HasPrivilegedAccess Then
		Items.HasPrivilegedAccess.Visible = True;
	Else
		Items.HasPrivilegedAccess.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Function DetermineOwnerOfElement(DimensionKind, WhereToAdd_)
	
	If TypeOf(DimensionKind) <> Type("ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions") Then
		Return Undefined;
	EndIf;
	
	TypesArray = Common.ObjectAttributeValue(DimensionKind, "ValueType").Types();
	
	If TypesArray.Find(Type("CatalogRef.ObjectsPropertiesValues")) <> Undefined Then
		Return New Structure("Types, Value", 
						"CatalogRef.ObjectsPropertiesValues",
						Common.ObjectAttributeValue(DimensionKind, "AdditionalProperty"));
	EndIf;
	
	OwnersCompliance = FinancialReportingCached.MatchingSelectionsByOwner();
	
	AddAddress = ReportItems.FindByID(WhereToAdd_);
	While AddAddress <> Undefined Do
		
		CurrentValueType = TypeOf(AddAddress.DimensionValue);
		If AddAddress.ItemKind = Enums.FinancialReportItemKinds.Dimension
			And ValueIsFilled(AddAddress.DimensionValue)
			And CurrentValueType <> Type("String") Then
			
			If AddAddress.ThisIsDimensionOther Then
				Continue;
			EndIf;
			
			ArrayOfTypeConstraints = New Array;
			For Each Type In TypesArray Do
				
				MetadataObject = Metadata.FindByType(Type);
				If Metadata.Catalogs.Find(MetadataObject.Name) = Undefined Then
					Continue;
				EndIf;
				
				RedefinedOwner = OwnersCompliance[Type];
				If RedefinedOwner <> Undefined
					And RedefinedOwner.Find(CurrentValueType, "Type") <> Undefined Then
					ArrayOfTypeConstraints.Add(Type);
					Continue;
				EndIf;
				
				Owners = MetadataObject.Owners;
				If Owners.Contains(Metadata.FindByType(CurrentValueType)) Then
					ArrayOfTypeConstraints.Add(Type);
				EndIf;
				
			EndDo;
			
			If ArrayOfTypeConstraints.Count() Then
				DesiredPredefinedOwner = OwnersCompliance[ArrayOfTypeConstraints[0]];
				SearchSettings_ = Undefined;
				If DesiredPredefinedOwner <> Undefined Then
					SearchSettings_ = DesiredPredefinedOwner.Find(CurrentValueType, "Type");
				EndIf;
				Attribute = ?(SearchSettings_ = Undefined, "Owner", SearchSettings_.Attribute);
				Return New Structure("Types, Value, Attribute", TypesArray, AddAddress.DimensionValue, Attribute);
			EndIf;
			
		EndIf;
			
		AddAddress = FinancialReportingClientServer.RowParent(AddAddress);
	EndDo;
	
	Return Undefined;
	
EndFunction

&AtClient
Function ListOfUTurnFlags(ParentOfRows, MatchingLevels = Undefined, Level = Undefined)
	
	If MatchingLevels = Undefined Then
		MatchingLevels = New Map;
	EndIf;
	
	RowElements = ParentOfRows.GetItems();
	For Each TreeRow In RowElements Do
		
		CurLevelID = ?(Level <> Undefined, Level, "") + "|" + RowElements.IndexOf(TreeRow);
		If Items.DisplayReportItems.SelectedRows.Find(TreeRow.GetID()) <> Undefined Then
			MatchingLevels.Insert(CurLevelID, 2);
		Else
			Expanded = Items.DisplayReportItems.Expanded(TreeRow.GetID());
			If Expanded Then
				Expanded = 1;
			Else
				Expanded = 0;
			EndIf;
			MatchingLevels.Insert(CurLevelID, Expanded);
			ListOfUTurnFlags(TreeRow, MatchingLevels, CurLevelID);
		EndIf;
		
	EndDo;
	
	Return MatchingLevels;
	
EndFunction

&AtClient
Procedure RestoreExpandedTreeNodes_(ParentOfRows, UTurnMatching, Level = Undefined)
	
	RowElements = ParentOfRows.GetItems();
	For Each TreeRow In RowElements Do
		
		CurLevelID = ?(Level <> Undefined, Level, "") + "|" + RowElements.IndexOf(TreeRow);
		UTurnFlag = UTurnMatching[CurLevelID];
		If UTurnFlag = 2 Then
			Items.DisplayReportItems.Expand(TreeRow.GetID(), True);
			Continue;
		ElsIf UTurnFlag = 1 Then
			Items.DisplayReportItems.Expand(TreeRow.GetID(), False);
		EndIf;
		RestoreExpandedTreeNodes_(TreeRow, UTurnMatching, CurLevelID);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure UpdateDisplayTree()
	
	DisplayReportItems.GetItems().Clear();
	DetailsToDelete = New Array;
	For Each Attribute In GetAttributes("DisplayReportItems") Do
		IndexOf = StrReplace(Attribute.Name, "NameForPrinting", "");
		If StrFind(Attribute.Name, "NameForPrinting") And 
			Not IsBlankString(IndexOf) Then
			DetailsToDelete.Add(Attribute.Path + "." + Attribute.Name);
			DetailsToDelete.Add(Attribute.Path + ".LineIndexOfReportItems" + IndexOf);
			DetailsToDelete.Add(Attribute.Path + ".AdditionalFieldPresentation" + IndexOf);
		EndIf;
	EndDo;
	
	DepthOfLevels = BudgetReportingCacheCalculationServer.CalculateDepthOfLevels(ReportItems);
	
	NameElementsToDelete = New Array;
	For Each Item In Items.NameForPrinting.ChildItems Do
		If StrFind(Item.Name, "DisplayReportItemsNameForPrinting") And 
			Not IsBlankString(StrReplace(Item.Name, "DisplayReportItemsNameForPrinting", "")) Then
			NameElementsToDelete.Add(Item);
		EndIf;
	EndDo;
	
	For Each Item In NameElementsToDelete Do
		Items.Delete(Item);
	EndDo;
	
	DetailsToAdd_ = New Array;
	ValidIndexTypes = New Array;
	ValidIndexTypes.Add(Type("Number"));
	ValidIndexTypes.Add(Type("String"));
	
	For Cnt = 2 To DepthOfLevels Do
		Attribute = New FormAttribute("NameForPrinting" + Cnt, New TypeDescription("String"), "DisplayReportItems");
		DetailsToAdd_.Add(Attribute);
		Attribute = New FormAttribute("LineIndexOfReportItems" + Cnt, New TypeDescription(ValidIndexTypes), "DisplayReportItems");
		DetailsToAdd_.Add(Attribute);
		Attribute = New FormAttribute("AdditionalFieldPresentation" + Cnt, New TypeDescription("String"), "DisplayReportItems");
		DetailsToAdd_.Add(Attribute);
	EndDo;
	
	ChangeAttributes(DetailsToAdd_, DetailsToDelete);
	
	For Cnt = 2 To DepthOfLevels Do
		DataPath = "NameForPrinting" + Cnt;
		FormItem = Items.Add("DisplayReportItems" + DataPath, 
												Type("FormField"), Items.NameForPrinting);
		FormItem.Type = FormFieldType.InputField;
		FormItem.DataPath = "DisplayReportItems." + DataPath;
		FormItem.TitleLocation = FormItemTitleLocation.None;
	EndDo;
	
	Query = New Query;
	Query.Text = "SELECT DISTINCT
	|	FinancialReportItemsFormulaOperands.Operand
	|INTO Operands
	|FROM
	|	Catalog.FinancialReportItems.FormulaOperands AS FinancialReportItemsFormulaOperands
	|WHERE
	|	FinancialReportItemsFormulaOperands.Ref.Owner = &BudgetProfile
	|INDEX BY
	|	Operand
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Operands.Operand,
	|	Operands.Operand.Parent AS Parent,
	|	TRUE AS PrivilegedMode
	|INTO FormulaOperandsArePrivileged
	|FROM
	|	Operands AS Operands
	|		LEFT JOIN Catalog.FinancialReportItems.ItemKindAttributes AS FinancialReportItemsItemKindAttributes
	|		ON Operands.Operand = FinancialReportItemsItemKindAttributes.Ref
	|			AND (FinancialReportItemsItemKindAttributes.Attribute = &PrivilegedMode)
	|
	|GROUP BY
	|	Operands.Operand,
	|	Operands.Operand.Parent
	|
	|HAVING
	|	MAX(CAST(ISNULL(FinancialReportItemsItemKindAttributes.Value, FALSE) AS BOOLEAN)) = TRUE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FormulaOperandsArePrivileged.Operand,
	|	FormulaOperandsArePrivileged.Parent
	|FROM
	|	FormulaOperandsArePrivileged AS FormulaOperandsArePrivileged
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(ISNULL(FinancialReportItemsItemKindAttributes.Value, FALSE)) AS PrivilegedModeElement,
	|	FinancialReportItemsTableItems.Ref AS Parent,
	|	MAX(ISNULL(FormulaOperandsArePrivileged.PrivilegedMode, FALSE)) AS OperandsPrivilegedMode
	|FROM
	|	Catalog.FinancialReportItems.TableItems AS FinancialReportItemsTableItems
	|		LEFT JOIN Catalog.FinancialReportItems.ItemKindAttributes AS FinancialReportItemsItemKindAttributes
	|		ON FinancialReportItemsTableItems.Item = FinancialReportItemsItemKindAttributes.Ref
	|			AND (FinancialReportItemsItemKindAttributes.Attribute = &PrivilegedMode)
	|		LEFT JOIN FormulaOperandsArePrivileged AS FormulaOperandsArePrivileged
	|		ON FinancialReportItemsTableItems.Item = FormulaOperandsArePrivileged.Parent
	|WHERE
	|	FinancialReportItemsTableItems.Ref.Owner = &BudgetProfile
	|
	|GROUP BY
	|	FinancialReportItemsTableItems.Ref
	|
	|HAVING
	|	(MAX(ISNULL(FinancialReportItemsItemKindAttributes.Value, FALSE)) = TRUE
	|		OR MAX(ISNULL(FormulaOperandsArePrivileged.PrivilegedMode, FALSE)) = TRUE)";
	
	Query.SetParameter("PrivilegedMode", ChartsOfCharacteristicTypes.ItemAttributesOfFinancialReports.PrivilegedMode);
	Query.SetParameter("BudgetProfile",Object.Ref);
	
	PrivilegedReceiptParameters = New Structure;
	QueryResults = Query.ExecuteBatch();
	FormulaOperandsArePrivileged	= QueryResults[2].Unload();
	ComplexTableIsPrivileged	= QueryResults[3].Unload();
	
	PrivilegedReceiptParameters.Insert("FormulaOperandsArePrivileged", FormulaOperandsArePrivileged);
	PrivilegedReceiptParameters.Insert("ComplexTableIsPrivileged", ComplexTableIsPrivileged);
	
	OutputTreeOfElementsToDisplayTree(ReportItems, DisplayReportItems, DepthOfLevels, PrivilegedReceiptParameters);
	
EndProcedure

&AtClientAtServerNoContext
Function ReflectedLine(String, Form)
	
	If String = Undefined Then
		Return Undefined;
	EndIf;
	
	ReportItems = Form.ReportItems;
	DisplayReportItems = Form.DisplayReportItems;
	
	If TypeOf(String) = Type("Number") Then
		TableRow = DisplayReportItems.FindByID(String);
	Else
		TableRow = String;
	EndIf;
	
	Return ReportItems.FindByID(TableRow.LineIndexOfReportItems);
	
EndFunction

&AtClient
Function ReflectionString(Val String, IncludingCombined = True)
	
	If String = Undefined Then
		Return Undefined;
	EndIf;
	
	If TypeOf(String) = Type("Number") Then
		String = ReportItems.FindByID(String);
	EndIf;
	
	Result = FinancialReportingClient.SubordinateElementOfFormElement(DisplayReportItems, 
		"LineIndexOfReportItems", String.GetID());
	
	If IncludingCombined Then
	
		If Result = Undefined Then
			For Cnt = 2 To Items.NameForPrinting.ChildItems.Count() Do
				Result = FinancialReportingClient.SubordinateElementOfFormElement(DisplayReportItems,
					"LineIndexOfReportItems" + Cnt, String.GetID());
				If Result <> Undefined Then
					Return Result;
				EndIf;
			EndDo;
		EndIf;
	
	EndIf;
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Procedure AddReflectionLine(AddingElements, SourceReportElement, Form)
	
	NewReflectionLine = AddingElements.Add();
	FillPropertyValues(NewReflectionLine, SourceReportElement);
	NewReflectionLine.LineIndexOfReportItems = SourceReportElement.GetID();
	For Cnt = 2 To Form.Items.NameForPrinting.ChildItems.Count() Do
		If NewReflectionLine.Property("LineIndexOfReportItems"+ Cnt) Then
			NewReflectionLine["LineIndexOfReportItems" + Cnt] = Undefined;
		EndIf;
	EndDo;
	NewReflectionLine.PrivilegedModePicture = Not Number(NewReflectionLine.PrivilegedMode);
	
EndProcedure

&AtServerNoContext
Function PlaceListOfAnalyticsCapsInRepository(Val HeaderDimensions, UUID)
	
	Return PutToTempStorage(HeaderDimensions.Unload(), UUID);
	
EndFunction

&AtClient
Procedure HeaderDimensionsClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If Items.HeaderDimensions.ReadOnly Then
		WarningText = NStr("vi = 'Không nên thay đổi đối tượng phân tích mà không kiểm tra để bỏ phong tỏa các mục tin trên biểu mẫu';
							|ru = 'Не рекомендуется изменять аналитики, не пройдя проверку на разблокирование реквизитов формы';
							|en = 'It is not recommended that you change dimensions without executing the form attribute unlock check'; fa = 'It is not recommended that you change dimensions without executing the form attribute unlock check';
							|it = 'Non è consigliabile modificare l''analisi senza passare il controllo per sbloccare i requisiti del modulo';
							|pl = 'Nie zaleca się zmieniać analityki bez dokonania weryfikacji odblokowania atrybutów formularza';
							|tr = 'Boyutların düzenlenmeleri önerilmemektedir, form özniteliklerinin kilitlerinin açılma işlemine geçilmedi'");
		ShowMessageBox(,WarningText);
		Return;
	EndIf;

	FormParameters = New Structure("AddressOfTheAnalyticsList", 
						PlaceListOfAnalyticsCapsInRepository(Object.HeaderDimensions, UUID));
	
	CallbackDescription = New CallbackDescription("EditingAnalyticsList", ThisObject);
	
	OpenForm("Catalog.BudgetProfiles.Form.HeaderDimensions", 
				FormParameters,,,,, CallbackDescription, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure EditingAnalyticsList(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Object.HeaderDimensions.Clear();
	CommonClientServer.SupplementTableFromArray(Object.HeaderDimensions, Result, "DimensionKind");
	Modified = True;
	EditingAnalyticsListOnServer();
	
EndProcedure

&AtServer
Procedure EditingAnalyticsListOnServer()
	
	SetTextAnalystInHeader();
	UpdateTreeOfNewElements();
	
EndProcedure

&AtServer
Procedure SetTextAnalystInHeader()
	
	TableOfTypesOfAnalytics = Object.HeaderDimensions.Unload();
	HeaderDimensions = StrConcat(TableOfTypesOfAnalytics.UnloadColumn("DimensionKind"), ", ");
	If IsBlankString(HeaderDimensions) Then
		HeaderDimensions = NStr("vi = '<chưa chỉ định>';
								|ru = '<не указаны>';
								|en = '<not specified>'; fa = '<مشخص نشده>';
								|it = '<non specificati>';
								|pl = '<nie określone>';
								|tr = '<belirtilmeyenler>'");
	EndIf;
	
EndProcedure

&AtClient
Procedure ShiftElement(CurrentRow, Direction)
	
	Parent = CurrentRow.GetParent();
	RowsCollection = Parent.GetItems();
	RowIndex = RowsCollection.IndexOf(CurrentRow);
	If RowIndex + Direction < 0 Or
		RowIndex + Direction = RowsCollection.Count() Then
		Return;
	EndIf;
	RowsCollection.Move(RowIndex, Direction);
	
EndProcedure

&AtServer
Procedure FillCacheOfArticlesAndIndicators(ElementTreeString, VTCacheOfArticlesAndIndicators)
			
	If ValueIsFilled(ElementTreeString.AddressOfItemStructure) Then
		ElementData = GetFromTempStorage(ElementTreeString.AddressOfItemStructure);
	Else
		ElementData = ElementTreeString.ReportItem;
	EndIf;
	
	ArrayOfElementsToCheck = New Array();
	ArrayOfElementsToCheck.Add(ElementData);
	
	If ElementTreeString.ItemKind = Enums.FinancialReportItemKinds.BudgetFlowItem 
		Or ElementTreeString.ItemKind = Enums.FinancialReportItemKinds.BudgetBalanceItem 
		Or ElementTreeString.ItemKind = Enums.FinancialReportItemKinds.NonFinancialItem Then

		NewRow = VTCacheOfArticlesAndIndicators.Add();
		If ElementTreeString.ItemKind = Enums.FinancialReportItemKinds.BudgetFlowItem Then
			NewRow.ItemIndicator = FinancialReportingServerCall.ValueOfAdditionalProps(ElementData, "BudgetFlowItem");
		ElsIf ElementTreeString.ItemKind = Enums.FinancialReportItemKinds.BudgetBalanceItem Then
			NewRow.ItemIndicator = FinancialReportingServerCall.ValueOfAdditionalProps(ElementData, "BudgetBalanceItem");
		ElsIf ElementTreeString.ItemKind = Enums.FinancialReportItemKinds.NonFinancialItem Then
			NewRow.ItemIndicator = FinancialReportingServerCall.ValueOfAdditionalProps(ElementData, "NonFinancialItem");
		EndIf;
		NewRow.PrivilegedMode = FinancialReportingServerCall.ValueOfAdditionalProps(ElementData, "PrivilegedMode");
	EndIf;

	For Each Page1 In ElementData.TableItems Do
		
		If TypeOf(Page1.Item) = Type("String") Then
			TableData = GetFromTempStorage(Page1.Item);
		Else
			TableData = Page1.Item;
		EndIf;
		
		If TableData.ItemKind = Enums.FinancialReportItemKinds.DerivedItem Then
			ArrayOfElementsToCheck.Add(TableData);
		EndIf;
		
		If Not (TableData.ItemKind = Enums.FinancialReportItemKinds.BudgetFlowItem 
			Or TableData.ItemKind = Enums.FinancialReportItemKinds.BudgetBalanceItem 
			Or TableData.ItemKind = Enums.FinancialReportItemKinds.NonFinancialItem) Then
			
			Continue;
		EndIf;
		
		NewRow = VTCacheOfArticlesAndIndicators.Add();
		If TableData.ItemKind = Enums.FinancialReportItemKinds.BudgetFlowItem Then
			NewRow.ItemIndicator = FinancialReportingServerCall.ValueOfAdditionalProps(TableData, "BudgetFlowItem");
		ElsIf TableData.ItemKind = Enums.FinancialReportItemKinds.BudgetBalanceItem Then
			NewRow.ItemIndicator = FinancialReportingServerCall.ValueOfAdditionalProps(TableData, "BudgetBalanceItem");
		ElsIf TableData.ItemKind = Enums.FinancialReportItemKinds.NonFinancialItem Then
			NewRow.ItemIndicator = FinancialReportingServerCall.ValueOfAdditionalProps(TableData, "NonFinancialItem");
		EndIf;
		NewRow.PrivilegedMode = FinancialReportingServerCall.ValueOfAdditionalProps(TableData, "PrivilegedMode");

		ArrayOfElementsToCheck.Add(TableData);
		
	EndDo;
	
	For Each ElementToCheck In ArrayOfElementsToCheck Do
		
		For Each Page1 In ElementToCheck.FormulaOperands Do
			
			If TypeOf(ElementToCheck.FormulaOperands) = Type("ValueTable")
				And ValueIsFilled(Page1.AddressOfItemStructure) Then
				DataOperand = GetFromTempStorage(Page1.AddressOfItemStructure);
			Else
				DataOperand = Page1.Operand;
			EndIf;
			
			If Not (DataOperand.ItemKind = Enums.FinancialReportItemKinds.BudgetFlowItem 
				Or DataOperand.ItemKind = Enums.FinancialReportItemKinds.BudgetBalanceItem 
				Or DataOperand.ItemKind = Enums.FinancialReportItemKinds.NonFinancialItem) Then
				
				Continue;
			EndIf;

			NewRow = VTCacheOfArticlesAndIndicators.Add();
			If DataOperand.ItemKind = Enums.FinancialReportItemKinds.BudgetFlowItem Then
				NewRow.ItemIndicator = FinancialReportingServerCall.ValueOfAdditionalProps(
						DataOperand, "BudgetFlowItem");
			ElsIf DataOperand.ItemKind = Enums.FinancialReportItemKinds.BudgetBalanceItem Then
				NewRow.ItemIndicator = FinancialReportingServerCall.ValueOfAdditionalProps(
						DataOperand, "BudgetBalanceItem");
			ElsIf DataOperand.ItemKind = Enums.FinancialReportItemKinds.NonFinancialItem Then
				NewRow.ItemIndicator = FinancialReportingServerCall.ValueOfAdditionalProps(
						DataOperand, "NonFinancialItem");
			EndIf;
			NewRow.PrivilegedMode = FinancialReportingServerCall.ValueOfAdditionalProps(
					DataOperand, "PrivilegedMode");

		EndDo;
		
	EndDo;
		
	For Each String In ElementTreeString.Rows Do
		FillCacheOfArticlesAndIndicators(String, VTCacheOfArticlesAndIndicators);	
	EndDo;
	
EndProcedure

&AtServer
Function GetCacheOfArticlesAndMetrics(ItemsTree)
	
	VTCacheOfArticlesAndIndicators = New ValueTable;
	VTCacheOfArticlesAndIndicators.Columns.Add("ItemIndicator");
	VTCacheOfArticlesAndIndicators.Columns.Add("PrivilegedMode", New TypeDescription("Boolean"));

	For Each ElementTreeString In ItemsTree.Rows Do
		FillCacheOfArticlesAndIndicators(ElementTreeString, VTCacheOfArticlesAndIndicators);
	EndDo;
	
	VTCacheOfArticlesAndIndicators.GroupBy("ItemIndicator,PrivilegedMode");

	Return VTCacheOfArticlesAndIndicators;
	
EndFunction

#EndRegion