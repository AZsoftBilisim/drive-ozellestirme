#Region Variables

&AtClient
Var ModifyingExistingRow;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
	Items.CustomizeForm.Visible = AccessRight("Insert", Metadata.Catalogs.NonFinancialItemProfiles);
	Items.Indicators.ReadOnly = ReadOnly;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	InputDescriptionStructure = GetFromTempStorage(AddressOfParameterStructure);
	
	If InputDescriptionStructure <> Undefined Then
		CheckDocumentCompletion(InputDescriptionStructure, Cancel);
		SaveTabularPartToDocument(InputDescriptionStructure, CurrentObject);
		CheckCurrencyFillingByNonFinancialIndicators(CurrentObject, Cancel);
	EndIf;
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Recording_SettingNFPValues", , Object.Ref);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	OnReadCreateAtServer();
	
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
Procedure NonFinancialItemOnChange(Item)
	
	RedrawForm(True);
	
EndProcedure

&AtClient
Procedure OperationKindOnChange(Item)
	
	KindOfOperationWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure InputTemplateOnChange(Item)
	
	InstallNewTemplateOnServer(Object.InputTemplate);
	
EndProcedure

&AtClient
Procedure SetDateInterval()
	
	PeriodParameter_ = New StandardPeriod;
	PeriodParameter_.StartDate = Object.BeginOfPeriod;
	PeriodParameter_.EndDate = Object.PeriodEnding;
	
	Dialog = New StandardPeriodEditDialog;
	Dialog.Period = PeriodParameter_;
	Dialog.Show(New CallbackDescription("EditPeriodCompletion", ThisObject));
	
EndProcedure

&AtClient
Procedure BeginOfPeriodOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If Items.PagesPeriodEnd.CurrentPage = Items.PeriodEndItem Then
		Object.BeginOfPeriod = WorkingWithClientServerPeriods.BeginningDateOfPeriod(Object.BeginOfPeriod, Periodicity);
		RedrawForm();
	EndIf;
	
EndProcedure

&AtClient
Procedure EndOfPeriod1OnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	Object.PeriodEnding = WorkingWithClientServerPeriods.PeriodEndDate_(Object.PeriodEnding, Periodicity);
	
	RedrawForm();
	
EndProcedure

// Plug-in event handler for the form element. When you change the Analytics field in the header.
// 
// Parameters:
// 	Item - FormField - 
&AtClient
Procedure Attachable_WhenChangingHeaderAnalytics(Item)
	
	If Not BudgetReportingClientServer.LeftPartOfNameMatches(Item.Name, "Dimension") Then
		Return;
	EndIf;
	
	DimensionNumber = Number(StrReplace(Item.Name, "Dimension", ""));
	FilterParameters = New Structure("DimensionAddressCurrency", DimensionNumber);
	AnalyticsIsUsedInCurrency = IndicatorPropertyCache.FindRows(FilterParameters).Count() > 0;
	FilterParameters = New Structure("QuantityDimensionAddress", DimensionNumber);
	AnalyticsIsUsedInQuantity = IndicatorPropertyCache.FindRows(FilterParameters).Count() > 0;
	
	If AnalyticsIsUsedInCurrency Or AnalyticsIsUsedInQuantity Then
		SetValuesFromAnalyticsByRows(Item.Name, AnalyticsIsUsedInCurrency, AnalyticsIsUsedInQuantity);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTabularSection

&AtClient
Procedure TabularSectionOnChange(Item)
	
	If ModifyingExistingRow = True Then
		Return;
	EndIf;
	
	For Each TableRow In TabularSection Do
		TableRow.DocumentRowNumber = TabularSection.IndexOf(TableRow) + 1;
	EndDo;
	
EndProcedure

&AtClient
Procedure TabularSectionBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	If Not ValueIsFilled(Object.NonFinancialItem)
		And Not ValueIsFilled(Object.InputTemplate) Then
		WarningText = NStr("vi = 'Chỉ ra một số liệu phi tài chính hoặc mẫu đầu vào';
							|ru = 'Укажите нефинансовый показатель или шаблон ввода';
							|en = 'Specify non-financial item or input template'; fa = 'Specify non-financial item or input template';
							|it = 'Indicate l''indice non finanziario oppure il modello di inserimento';
							|pl = 'Podaj wskaźnik niefinansowy lub szablony wprowadzania';
							|tr = 'Finansal olmayan öğe veya giriş numunesi belirtin'");
		ShowMessageBox(,WarningText);
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure TabularSectionOnEditEnd(Item, NewRow, CancelEdit)
	
	ModifyingExistingRow = False;
	
EndProcedure

&AtClient
Procedure TabularSectionBeforeRowChange(Item, Cancel)
	
	// Setting a flag so that when an existing line is changed
	// , the line numbers are not recalculated.
	ModifyingExistingRow = True;
	
EndProcedure

&AtClient
Procedure TabularSectionOnStartEdit(Item, NewRow, Copy)
	
	// Setting the flag so that after adding a new row
	// , when changing cells, the row numbers are not recalculated.
	ModifyingExistingRow = True;
	
	TablePartWhenYouStartEditingOnServer();
	
EndProcedure

&AtClient
Procedure FillInTheSettingsOfTheNonFinancialIndicator(Command)
	
	If TabularSection.Count() Then
		CallbackDescription = New CallbackDescription("SelectingLineClearingMode", ThisObject);
		QueryText = NStr("vi = 'Xóa các hàng hiện có?';
						|ru = 'Удалить существующие строки?';
						|en = 'Remove existing lines?'; fa = 'Remove existing lines?';
						|it = 'Eliminare le righe esistenti?';
						|pl = 'Usunąć istniejące wiersze?';
						|tr = 'Mevcut satırlar silinsin mi?'");
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNoCancel);
	Else
		Modified = True;
		FillAtServer(True);
	EndIf;
	
EndProcedure

&AtClient
Procedure TabularSectionBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	DoubleLineNumber = Undefined;
	
	If Not CancelEdit Then
		If NewRow And LineDuplicatesExistingOne(Item.CurrentRow, DoubleLineNumber) Then
			MessageText = NStr("vi = 'Không thể nhập các dòng có đối tượng phân tích giống nhau.
										|Các đối tượng phân tích chỉ ra đã được dùng trong dòng số %1';
										|ru = 'Нельзя вводить строки с одинаковой аналитикой.
										|Указанные аналитики уже встречаются в строке №%1';
										|en = 'Cannot enter lines with the same dimension.
										|The specified dimensions are already present in line No. %1'; fa = 'Cannot enter lines with the same dimension.
										|The specified dimensions are already present in line No. %1';
										|it = 'Non si può inserire le righe con analitica identica.
										|Le analitiche indicate si trovano già nella riga №%1';
										|pl = 'Nie można wprowadzać wierszy z tymi samymi danymi analitycznymi.
										|Wspomniane dane analityczne już się znajdują w wierszu nr%1';
										|tr = 'Aynı boyutlara sahip satırları girmek yasak.
										| Belirtilen boyutlarla satır numara %1''de zaten karşılaşılıyor'");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, DoubleLineNumber);
			ShowMessageBox(, MessageText);
			Cancel = True;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectTheValuesOfTheAnalyticsColumns(Command)
	
	DimensionNumber = Number(StrReplace(Command.Name, "SelectTheValuesOfTheAnalyticsColumns", ""));
	FormParameters = EditListFormParameters(DimensionNumber);
	CallbackDescription = New CallbackDescription("SelectingColumnValues", ThisObject, FormParameters);
	OpenForm("CommonForm.EditValueList",
		FormParameters,,,,,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// Plug-in event handler for the form element. When changing the list column.
// 
// Parameters:
// 	Item - FormField - 
&AtClient
Procedure Attachable_WhenChangingListColumn(Item)
	
	If Not BudgetReportingClientServer.LeftPartOfNameMatches(Item.Name, "Dimension") Then
		Return;
	EndIf;
	
	WhenChangingListColumnOnServer(Item.Name);
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject);
	
EndProcedure

&AtClient
Procedure CustomizeForm(Command)
	
	If Object.OperationKind = PredefinedValue("Enum.OperationKindsOfSettingOfNonFinancialItemValues.EnterValuesFromTemplate") Then
		If TemplateIsUsedInDocuments(Object.InputTemplate, Object.Ref) Then
			CallbackDescription = New CallbackDescription("CreatingNewTemplate", ThisObject);
			QueryText = NStr("vi = 'Khuôn mẫu được dùng trong các chứng từ mà không thể chỉnh sửa.
								|Tạo khuôn mẫu mới?';
								|ru = 'Шаблон используется в документах - редактирование недоступно.
								|Создать новый шаблон?';
								|en = 'Template is used in documents, editing is not available. 
								|Create a new template?'; fa = 'Template is used in documents, editing is not available. 
								|Create a new template?';
								|it = 'Il modello viene utilizzato nei documenti - redazione è impossibile.
								|Creare un modello nuovo?';
								|pl = 'Szablon jest używany w dokumentach - edycja jest niedostępna.
								|Utworzyć nowy szablon?';
								|tr = 'Numune belgelerde kullanılıyor: düzenlemeler yapılamıyor. 
								| Yeni numune oluşturulsun mu?'");
			ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
			Return;
		EndIf;
		FormParameters = New Structure("Key", Object.InputTemplate);
	Else
		FormParameters = New Structure("FillingIndicator", Object.NonFinancialItem);
	EndIf;
	
	FormParameters.Insert("DocumentSource", Object.Ref);
	
	OpenForm("Catalog.NonFinancialItemProfiles.Form.ItemForm", FormParameters);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

#Region Private

&AtServer
Procedure OnReadCreateAtServer()
	
	CopyingDocument = False;
	If Parameters.Property("CopyingValue")
		And ValueIsFilled(Parameters.CopyingValue) Then
		CopyingDocument = True;
	EndIf;
	
	If Object.Ref.IsEmpty() Then
		If Not CopyingDocument Then
			FillInDefaultColumnValues();
		EndIf;
	Else
		If Parameters.Property("NFP_FillDefaultValues") And Not TabularSection.Count() Then
			FillInDefaultColumnValues();
		EndIf;
	EndIf;
	
	SetDocumentForm();
	
	CurrencyOfManAccounting = Constants.ManagementAccountingCurrency.Get();
	
	If Object.Ref.IsEmpty() Then
		If CopyingDocument Then
			RestoreTabularPartOfDocument();
			SetValuesFromAnalyticsByRows(Undefined, False, True);
		Else
			DetailsStructure1 = GetFromTempStorage(AddressOfParameterStructure);
			If DetailsStructure1 <> Undefined Then
				If DetailsStructure1.Period = "ValidFrom" Then
					Object.BeginOfPeriod = CurrentSessionDate();
				ElsIf ValueIsFilled(Periodicity) Then
					Object.BeginOfPeriod = WorkingWithClientServerPeriods.BeginningDateOfPeriod(CurrentSessionDate(), Periodicity);
					If Items.PagesPeriodEnd.CurrentPage = Items.PeriodEndItem Then
						Object.PeriodEnding = WorkingWithClientServerPeriods.PeriodEndDate_(CurrentSessionDate(), Periodicity);
					EndIf;
				EndIf;
			EndIf;
			FillInDefaultRowValues();
			SetValuesFromAnalyticsByRows(Undefined, True, True);
		EndIf;
	Else
		If Parameters.Property("NFP_FillDefaultValues") And Not TabularSection.Count() Then
			FillInDefaultRowValues();
			SetValuesFromAnalyticsByRows(Undefined, True, True);
			Modified = True;
		Else
			RestoreTabularPartOfDocument();
			SetValuesFromAnalyticsByRows(Undefined, False, True);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Function StructureForCallingManagerModuleProcedures()
	
	ObjectAndCalculationParameters = New Structure;
	ObjectAndCalculationParameters.Insert("Object", Object);
	ObjectAndCalculationParameters.Insert("InputDescriptionStructure", GetFromTempStorage(AddressOfParameterStructure));
	ObjectAndCalculationParameters.Insert("TabularSection", TabularSection);
	ObjectAndCalculationParameters.Insert("IndicatorValues", IndicatorValues);
	
	Return ObjectAndCalculationParameters;
	
EndFunction

&AtServer
Procedure KindOfOperationWhenChangingOnServer()
	
	Object.ColumnValues.Clear();
	Object.DocumentRows.Clear();
	Object.DocumentColumns.Clear();
	
	If Object.OperationKind = Enums.OperationKindsOfSettingOfNonFinancialItemValues.EnterValuesFromTemplate Then
		If ValueIsFilled(Object.NonFinancialItem) Then
			Object.InputTemplate = Catalogs.NonFinancialItemProfiles.DefaultInputPattern(Object.NonFinancialItem);
			If ValueIsFilled(Object.InputTemplate) Then
				InstallNewTemplateOnServer(Object.InputTemplate);
			EndIf;
		EndIf;
		Object.NonFinancialItem = Undefined;
	Else
		Object.InputTemplate = Undefined;
	EndIf;
	
	SaveTabularPartToDocument();
	SetDocumentForm();
	RestoreTabularPartOfDocument();
	
EndProcedure

&AtServer
Procedure WhenChangingListColumnOnServer(ItemName)
	
	SetValueFromAnalytics("Currency_", Items.TabularSection.CurrentRow, ItemName);
	SetValueFromAnalytics("Ed_", Items.TabularSection.CurrentRow, ItemName);
	
EndProcedure

&AtServer
Procedure TablePartWhenYouStartEditingOnServer()
	
	SetValueFromAnalytics("Currency_", Items.TabularSection.CurrentRow, Undefined);
	SetValueFromAnalytics("Ed_", Items.TabularSection.CurrentRow, Undefined);
	
EndProcedure

&AtClient
Procedure CreatingNewTemplate(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		FormParameters = New Structure;
		FormParameters.Insert("CopyingValue", Object.InputTemplate);
		FormParameters.Insert("DocumentSource", Object.Ref);
		OpenForm("Catalog.NonFinancialItemProfiles.Form.ItemForm", FormParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectingColumnValues(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		SetColumnValuesOnServer(Result, AdditionalParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetColumnValuesOnServer(Result, AdditionalParameters)
	
	ValueSearchStructure = New Structure("Dimension, DimensionName", AdditionalParameters.Dimension, "Dimension");
	DefaultElements = Object.ColumnValues.FindRows(ValueSearchStructure);
	For Each Item In DefaultElements Do
		Object.ColumnValues.Delete(Item);
	EndDo;
	ValueSearchStructure.Insert("Value");
	For Each Item In Result Do
		ValueSearchStructure.Value = Item;
		If Object.ColumnValues.FindRows(ValueSearchStructure).Count() Then
			Continue;
		EndIf;
		NewRow = Object.ColumnValues.Add();
		FillPropertyValues(NewRow, ValueSearchStructure);
	EndDo;
	
	RedrawForm();
	
	TheStructureOfTheSearch = New Structure("DimensionAddressCurrency", AdditionalParameters.DimensionNumber);
	If IndicatorPropertyCache.FindRows(TheStructureOfTheSearch).Count() Then
		SetValuesFromAnalyticsByRows("Dimension" + AdditionalParameters.DimensionNumber, True, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectingLineClearingMode(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	Modified = True;
	FillAtServer(Result = DialogReturnCode.Yes);
	
EndProcedure

&AtServer
Procedure SetDocumentForm()
	
	PeriodParameters_ = New Structure("BeginOfPeriod, PeriodEnding",
		Object.BeginOfPeriod,
		Object.PeriodEnding);
	PeriodParameters_.Insert("DocumentDate", ?(ValueIsFilled(Object.Ref), Object.Date, CurrentSessionDate()));
	InputDescriptionStructure = Documents.SetValuesForNonFinancialItems.DescriptionStructureOfInputDocumentFields(
		Object.OperationKind,
		Object.NonFinancialItem,
		Object.InputTemplate,
		Object.ColumnValues.Unload(),
		PeriodParameters_);
	
	AddressOfParameterStructure = PutToTempStorage(InputDescriptionStructure, UUID);
	
	ReflectTemplateStructure(InputDescriptionStructure);
	
	FormControl();
	
EndProcedure

&AtServer
Procedure FormControl()
	
	InputDescriptionStructure = GetFromTempStorage(AddressOfParameterStructure);
	
	If Object.OperationKind = Enums.OperationKindsOfSettingOfNonFinancialItemValues.EnterValuesFromTemplate Then
		Items.NonFinancialItem.Visible = False;
		Items.InputTemplate.Visible = True;
	Else
		Items.InputTemplate.Visible = False;
		Items.NonFinancialItem.Visible = True;
	EndIf;
	
	If InputDescriptionStructure <> Undefined Then
		If InputDescriptionStructure.Period = "Period" Then
			Items.BeginOfPeriod.Title = NStr("vi = 'Kỳ từ';
											|ru = 'Период с';
											|en = 'Period from'; fa = 'دوره از';
											|it = 'Periodo dal';
											|pl = 'Okres od';
											|tr = 'Dönem başı'");
			Items.BeginOfPeriod.Visible = True;
			Items.PagesPeriodEnd.CurrentPage = Items.PeriodEndItem;
		ElsIf InputDescriptionStructure.Period = "ValidFrom" Then
			Items.BeginOfPeriod.Title = NStr("vi = 'Có hiệu lực từ';
											|ru = 'Действует с';
											|en = 'Valid from'; fa = 'معتبر از';
											|it = 'In vigore dal';
											|pl = 'Obowiązuje od';
											|tr = 'Geçerlilik başlangıcı'");
			Items.BeginOfPeriod.Visible = True;
			Items.PagesPeriodEnd.CurrentPage = Items.ValidTo;
		Else
			Items.BeginOfPeriod.Visible = False;
			Items.PagesPeriodEnd.CurrentPage = Items.PeriodEndNo;
		EndIf;
	EndIf;
	
	If Items.Indicators.ChildItems.Count()
		And Items.TabularSection.Visible Then
		
		Items.Indicators.Representation = UsualGroupRepresentation.WeakSeparation;
		Items.Indicators.ShowTitle = True;
		
		Items.IndicatorValues.Representation = UsualGroupRepresentation.WeakSeparation;
		Items.IndicatorValues.ShowTitle = True;
		
	Else
		
		Items.Indicators.Representation = UsualGroupRepresentation.None;
		Items.Indicators.ShowTitle = False;
		
		Items.IndicatorValues.Representation = UsualGroupRepresentation.None;
		Items.IndicatorValues.ShowTitle = False;
		
	EndIf;
	
	SettingButtons = Items.SetUpColumns.ChildItems;
	While SettingButtons.Count() Do
		Items.Delete(SettingButtons[0]);
	EndDo;
	
	If InputDescriptionStructure <> Undefined Then
		
		Items.Fill.Visible = InputDescriptionStructure.Property("FillingRules");
		
		If InputDescriptionStructure.Property("DimensionColumns1") Then
			
			DimensionColumns1 = InputDescriptionStructure.DimensionColumns1; // ValueTable - 
			For Each FoundRow In DimensionColumns1 Do
				DimensionNumber = DimensionColumns1.IndexOf(FoundRow) + 1;
				FieldName = FinancialReportingCached.NameOfBudgetReportField(FoundRow.Dimension);
				NewButton = Items.Add(FieldName, Type("FormButton"), Items.SetUpColumns);
				NewButton.Type = FormButtonType.CommandBarButton;
				NewButton.CommandName = "SelectTheValuesOfTheAnalyticsColumns" + DimensionNumber;
				NewButton.Title = String(FoundRow.Dimension);
			EndDo;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ReflectTemplateStructure(InputDescriptionStructure)
	
	For Each AddedElement In AddedItems Do
		Item = Items.Find(AddedElement.Value);
		If Item <> Undefined Then
			Items.Delete(Item);
		EndIf;
	EndDo;
	
	ItemsToDelete_ = New Array;
	For Each Column In GetAttributes("TabularSection") Do
		If Column.Name <> "DocumentRowNumber" Then
			ItemsToDelete_.Add("TabularSection." + Column.Name);
		EndIf;
	EndDo;
	
	AddedItems.Clear();
	
	If InputDescriptionStructure = Undefined Then
		
		ChangeAttributes(,ItemsToDelete_);
		Return;
		
	EndIf;
	
	Periodicity = InputDescriptionStructure.Periodicity;
	
	IndicatorPropertyCache.Load(InputDescriptionStructure.PropertiesOfIndicators);
	
	Documents.SetValuesForNonFinancialItems.ReflectDocumentHeaderDetails(InputDescriptionStructure,
		Items,
		AddedItems);
	
	IndicatorValues.Clear();
	Documents.SetValuesForNonFinancialItems.ReflectIndicatorsEditedInHeader(InputDescriptionStructure,
		Items,
		AddedItems,
		IndicatorValues);
	
	Documents.SetValuesForNonFinancialItems.ReflectTabularPartOfDocument(InputDescriptionStructure,
		Items,
		ThisObject,
		AddedItems,
		ItemsToDelete_);
	
EndProcedure

&AtServer
Procedure RestoreTabularPartOfDocument()
	
	TabularSection.Clear();
	
	InputDescriptionStructure = GetFromTempStorage(AddressOfParameterStructure);
	
	If InputDescriptionStructure = Undefined Then
		Return;
	EndIf;
	
	For Each IndicatorLine_ In IndicatorValues Do
		FoundRows = Object.IndicatorValues.FindRows(New Structure("Factor", IndicatorLine_.Factor));
		If FoundRows.Count() Then
			FillPropertyValues(IndicatorLine_, FoundRows[0]);
		EndIf;
	EndDo;
	
	ColumnsOfValuesOfTablePart = InputDescriptionStructure.ColumnsOfValuesOfTablePart;
	TreeOfValueColumns = InputDescriptionStructure.ValueColumns;
	
	For Each DocumentLine In Object.DocumentRows Do
		
		NewRow = TabularSection.Add();
		FillPropertyValues(NewRow, DocumentLine);
		For Each Column In ColumnsOfValuesOfTablePart Do
			
			If BudgetReportingClientServer.LeftPartOfNameMatches(Column, "Currency_")
				Or BudgetReportingClientServer.LeftPartOfNameMatches(Column, "Ed_") Then
				Continue;
			EndIf;
			
			TreeColumn = TreeOfValueColumns.Rows.Find(Column, "Name", True);
			ColumnFields = Common.CopyRecursive(TreeColumn.AccumulatedSelection);
			ColumnFields.Insert("DocumentRowNumber", NewRow.DocumentRowNumber);
			ValueStrings = Object.DocumentColumns.FindRows(ColumnFields);
			If ValueStrings.Count() Then
				NewRow[Column] = ValueStrings[0].Value;
				If ColumnsOfValuesOfTablePart.Find("Currency_" + Column) <> Undefined Then
					NewRow["Currency_" + Column] = ValueStrings[0].Currency;
				ElsIf TreeColumn.Parent <> Undefined
					And ColumnsOfValuesOfTablePart.Find("Currency_" + TreeColumn.Parent.Name) <> Undefined Then
					NewRow["Currency_" + TreeColumn.Parent.Name] = ValueStrings[0].Currency;
				EndIf;
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure SaveTabularPartToDocument(Val InputDescriptionStructure = Undefined, ObjectToSave = Undefined)
	
	If InputDescriptionStructure = Undefined Then
		InputDescriptionStructure = GetFromTempStorage(AddressOfParameterStructure);
	EndIf;
	
	If ObjectToSave = Undefined Then
		CurrentObject = Object;
	Else
		CurrentObject = ObjectToSave;
	EndIf;
	
	ObjectAndCalculationParameters = StructureForCallingManagerModuleProcedures();
	ObjectAndCalculationParameters.InputDescriptionStructure = InputDescriptionStructure;
	ObjectAndCalculationParameters.Object = CurrentObject;
	
	Documents.SetValuesForNonFinancialItems.SaveTabularPartToDocument(ObjectAndCalculationParameters, CurrentObject);
	
EndProcedure

&AtServer
Procedure CheckDocumentCompletion(InputDescriptionStructure, Cancel)
	Errors = Undefined;
	
	For Each Item In InputDescriptionStructure.LeftColumn Do
		If Not ValueIsFilled(Object[Item.Name]) Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chưa điền trường ""%1""';
					|ru = 'Не заполнено поле ""%1""';
					|en = '""%1"" is required'; fa = '""%1"" is required';
					|it = 'Il campo ""%1"" non è compilato';
					|pl = 'Nie wypełniono pola ""%1""';
					|tr = '""%1"" alanı doldurulmadı'"),
				Item.Presentation);
			CommonClientServer.AddUserError(Errors, "Object." + Item.Name, ErrorText, "");
		EndIf;
	EndDo;
	
	For Each Item In InputDescriptionStructure.RightColumn Do
		If Not ValueIsFilled(Object[Item.Name]) Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chưa điền trường ""%1""';
					|ru = 'Не заполнено поле ""%1""';
					|en = '""%1"" is required'; fa = '""%1"" is required';
					|it = 'Il campo ""%1"" non è compilato';
					|pl = 'Nie wypełniono pola ""%1""';
					|tr = '""%1"" alanı doldurulmadı'"),
				Item.Presentation);
			CommonClientServer.AddUserError(Errors, "Object." + Item.Name, ErrorText, "");
		EndIf;
	EndDo;
	
	For Each LineOfATabularSection In TabularSection Do
		For Each Structure In InputDescriptionStructure.EditableColumns Do
			If Not ValueIsFilled(LineOfATabularSection[Structure.Name]) Then
				Field = "TabularSection[%1]." + Structure.Name;
				IndexOf = TabularSection.IndexOf(LineOfATabularSection);
				ErrorText = NStr("vi = 'Trong dòng %1, trường ""%2"" không được điền';
								|ru = 'В строке %1 не заполнено поле ""%2""';
								|en = '""%2"" is required in line %1'; fa = '""%2"" is required in line %1';
								|it = 'Nella riga %1 non è compilato il campo ""%2""';
								|pl = 'W wierszu %1 nie wypełniono pole ""%2""';
								|tr = '%1 satırında doldurulmayan alan ""%2""'");
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, (IndexOf + 1), Structure.Presentation);
				CommonClientServer.AddUserError(Errors, Field, ErrorText, "", IndexOf);
			EndIf;
		EndDo;
	EndDo;
	
	If InputDescriptionStructure.Property("DimensionColumns1") Then
		For Each AnalyticsLine_ In InputDescriptionStructure.DimensionColumns1 Do
			TheStructureOfTheSearch = New Structure("DimensionName, Dimension", "Dimension", AnalyticsLine_.Dimension);
			If Not Object.ColumnValues.FindRows(TheStructureOfTheSearch).Count() Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Giá trị cột không được chỉ định ""%1""';
						|ru = 'Не указаны значения колонок ""%1""';
						|en = 'No values of columns ""%1""'; fa = 'No values of columns ""%1""';
						|it = 'I valori delle colonne ""%1"" non sono indicati';
						|pl = 'Nie zostały podane wartości kolumn ""%1""';
						|tr = '""%1"" sütunlarının değeri belirtilmedi'"),
					String(AnalyticsLine_.Dimension));
				CommonClientServer.AddUserError(Errors, , ErrorText, "");
			EndIf;
		EndDo;
	EndIf;
	
	CommonClientServer.ReportErrorsToUser(Errors, Cancel);
	
EndProcedure

&AtServer
Procedure CheckCurrencyFillingByNonFinancialIndicators(CurrentObject, Cancel)
	
	Errors = Undefined;
	
	NonFinancialIndicators = CurrentObject.DocumentColumns.Unload(, "NonFinancialItem, Currency");
	If NonFinancialIndicators.Count() = 0 Then
		NonFinancialIndicators = CurrentObject.IndicatorValues.Unload(, "Factor, Currency");
		NonFinancialIndicators.Columns.Factor.Name = "NonFinancialItem";
	EndIf;
	NonFinancialIndicatorsData = Common.ObjectsAttributesValues(NonFinancialIndicators.UnloadColumn("NonFinancialItem"), "IndicatorKind, CurrencyIsDeterminedByDimension");
	
	For Each NFP In NonFinancialIndicatorsData Do
		If NFP.Value.IndicatorKind = Enums.NonFinancialItemKinds.Cash_
			And Not NFP.Value.CurrencyIsDeterminedByDimension Then
			DocumentLine = NonFinancialIndicators.Find(NFP.Key);
			If Not ValueIsFilled(DocumentLine.Currency) Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Đối với chỉ tiêu ""%1"" chưa chỉ ra tiền tệ';
						|ru = 'Для показателя ""%1"" не указана валюта';
						|en = 'For the %1 indicator, a currency is not specified'; fa = 'For the %1 indicator, a currency is not specified';
						|it = 'Per l''indicatore ""%1"" la valuta non è indicata';
						|pl = 'Dla wskaźnika ""%1"" nie jest określona waluta';
						|tr = '""%1"" göstergesi için para birimi belirtilmedi'"),
					String(NFP.Key));
				CommonClientServer.AddUserError(Errors, , ErrorText, "");
			EndIf;
		EndIf;
	EndDo;
	
	CommonClientServer.ReportErrorsToUser(Errors, Cancel);
	
EndProcedure

&AtServer
Procedure InstallNewTemplateOnServer(Source)
	
	Object.OperationKind = Enums.OperationKindsOfSettingOfNonFinancialItemValues.EnterValuesFromTemplate;
	Object.InputTemplate = Source;
	
	FillInDefaultColumnValues();
	
	RedrawForm(True);
	
	If Not TabularSection.Count() Then
		FillInDefaultRowValues();
		SetValuesFromAnalyticsByRows(Undefined, True, True);
	Else
		SetValuesFromAnalyticsByRows(Undefined, False, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "RecordedNFPInputTemplate" Then
		If Parameter = Object.InputTemplate
			Or Source = Object.Ref Then
			InstallNewTemplateOnServer(Parameter);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure RedrawForm(CheckPeriod = False)
	
	SaveTabularPartToDocument();
	SetDocumentForm();
	RestoreTabularPartOfDocument();
	
	If CheckPeriod Then
		InputDescriptionStructure = GetFromTempStorage(AddressOfParameterStructure);
		If InputDescriptionStructure <> Undefined
			And InputDescriptionStructure.Period <> "ValidFrom" Then
			BeginOfPeriod = ?(ValueIsFilled(Object.BeginOfPeriod), Object.BeginOfPeriod, CurrentSessionDate());
			Object.BeginOfPeriod = WorkingWithClientServerPeriods.BeginningDateOfPeriod(BeginOfPeriod, Periodicity);
			If ValueIsFilled(Object.PeriodEnding) Then
				Object.PeriodEnding = WorkingWithClientServerPeriods.PeriodEndDate_(Object.PeriodEnding, Periodicity);
			Else
				Object.PeriodEnding = WorkingWithClientServerPeriods.PeriodEndDate_(Object.BeginOfPeriod, Periodicity);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

// Sets the value of the start and end of period details for the selected period.
// 
// Parameters:
// 	Result - StandardPeriod, Undefined - The selected period value.
// 	AdditionalParameters - Structure - advanced setting.
&AtClient
Procedure EditPeriodCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Object.BeginOfPeriod = Result.StartDate;
	Object.PeriodEnding = Result.EndDate;
	Object.BeginOfPeriod = ?(Object.BeginOfPeriod > Object.PeriodEnding, Object.PeriodEnding, Object.BeginOfPeriod);
	
	RedrawForm(True);
	
EndProcedure

&AtServer
Procedure FillAtServer(DeleteRows_1)
	
	ObjectAndCalculationParameters = StructureForCallingManagerModuleProcedures();
	If ObjectAndCalculationParameters.InputDescriptionStructure <> Undefined Then
		Documents.SetValuesForNonFinancialItems.FillInConfiguredDocument(ObjectAndCalculationParameters, DeleteRows_1);
	EndIf;
	
EndProcedure

// Returns a structure describing the input received from the temporary storage.
// 
// Parameters:
// 	TempStorageAddress - String - the address of the temporary storage.
// Returns:
// 	Undefined, Structure - Input Description Structure:
// 	 *EditableColumns - Array of Structure - Array of editable column structures:
// 	  **Name - String - column name.
&AtServer
Function StructureOfInputDescriptionFromTemporaryStorage(TempStorageAddress)
	Return GetFromTempStorage(TempStorageAddress);
EndFunction

&AtServer
Function LineDuplicatesExistingOne(CurrentRow, DoubleLineNumber)
	
	TableRow = TabularSection.FindByID(CurrentRow);
	InputDescriptionStructure = StructureOfInputDescriptionFromTemporaryStorage(AddressOfParameterStructure);
	
	TheStructureOfTheSearch = New Structure;
	For Each Structure In InputDescriptionStructure.EditableColumns Do
		TheStructureOfTheSearch.Insert(Structure.Name, TableRow[Structure.Name]);
	EndDo;
	
	FoundRows = TabularSection.FindRows(TheStructureOfTheSearch);
	For Each FoundRow In FoundRows Do
		If FoundRow <> TableRow Then
			DoubleLineNumber = FoundRow.DocumentRowNumber;
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

&AtServer
Procedure AddDefaultRowsRecursively(EditableColumns, ValueTable, Level = 0, AccumulatedSelection = Undefined)
	
	If Level = EditableColumns.Count() Then
		ThereAreSignificant = False;
		If AccumulatedSelection <> Undefined Then
			For Each KeyAndValue In AccumulatedSelection Do
				If ValueIsFilled(KeyAndValue.Value) Then
					ThereAreSignificant = True;
					Break;
				EndIf;
			EndDo;
		EndIf;
		If Not ThereAreSignificant Then
			Return;
		EndIf;
		NewRow = TabularSection.Add();
		NewRow.DocumentRowNumber = TabularSection.IndexOf(NewRow) + 1;
		FillPropertyValues(NewRow, AccumulatedSelection);
		Return;
	EndIf;
	
	If AccumulatedSelection = Undefined Then
		AccumulatedSelection = New Structure;
	EndIf;
	
	CurMeasurement_ = "";
	StructureByCurLevel = EditableColumns[Level]; // Structure - 
	StructureByCurLevel.Property("Name", CurMeasurement_);
	Dimension = EditableColumns[Level].Dimension;
	
	If StrFind(CurMeasurement_, "Dimension") Then
		SearchName = "Dimension";
	Else
		SearchName = CurMeasurement_;
	EndIf;
	
	FoundValues = ValueTable.FindRows(New Structure("DimensionName, Dimension", SearchName, Dimension));
	If FoundValues.Count() Then
		For Each FoundRow In FoundValues Do
			AccumulatedSelection.Insert(CurMeasurement_, FoundRow.Value);
			AddDefaultRowsRecursively(EditableColumns, ValueTable, Level + 1, AccumulatedSelection);
			AccumulatedSelection.Delete(CurMeasurement_);
		EndDo;
	Else
		AccumulatedSelection.Insert(CurMeasurement_, Undefined);
		AddDefaultRowsRecursively(EditableColumns, ValueTable, Level + 1, AccumulatedSelection);
		AccumulatedSelection.Delete(CurMeasurement_);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInDefaultRowValues()
	
	If Object.OperationKind <> Enums.OperationKindsOfSettingOfNonFinancialItemValues.EnterValuesFromTemplate Then
		Return;
	EndIf;
	
	InputDescriptionStructure = GetFromTempStorage(AddressOfParameterStructure);
	If InputDescriptionStructure = Undefined Then
		Return;
	EndIf;
	
	ValueTable = Common.ObjectAttributeValue(Object.InputTemplate, "DefaultComplexTableValues").Unload();
	AddDefaultRowsRecursively(InputDescriptionStructure.EditableColumns, ValueTable);
	
EndProcedure

&AtServer
Procedure FillInDefaultColumnValues()
	
	Object.ColumnValues.Clear();
	If Object.OperationKind <> Enums.OperationKindsOfSettingOfNonFinancialItemValues.EnterValuesFromTemplate Then
		Return;
	EndIf;
	
	ColumnValues = Documents.SetValuesForNonFinancialItems.TemplateColumnValues(Object.InputTemplate);
	Object.ColumnValues.Load(ColumnValues);
	
EndProcedure

&AtServer
Function EditListFormParameters(AnalyticsRowIndex)
	
	InputDescriptionStructure = GetFromTempStorage(AddressOfParameterStructure);
	If InputDescriptionStructure = Undefined Then
		Return Undefined;
	EndIf;
	
	Dimension = InputDescriptionStructure.DimensionColumns1[AnalyticsRowIndex - 1].Dimension;
	
	TheStructureOfTheSearch = New Structure("DimensionName, Dimension", "Dimension", Dimension);
	DesiredValues = Object.ColumnValues.Unload(TheStructureOfTheSearch);
	
	FormParameters = New Structure;
	ValueType = Common.ObjectAttributeValue(Dimension, "ValueType");
	FormParameters.Insert("ValueType", ValueType);
	FormParameters.Insert("Title", String(Dimension));
	FormParameters.Insert("Values", DesiredValues.UnloadColumn("Value"));
	FormParameters.Insert("Dimension", Dimension);
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	AttributesNames = "";
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		AttributesNames = AttributesNames + ?(AttributesNames = "", "", ", ") + "DimensionKind" + DimensionNumber;
	EndDo;
	
	DimensionKinds = Common.ObjectAttributesValues(IndicatorPropertyCache[0].Factor, AttributesNames);
	
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		If DimensionKinds["DimensionKind" + DimensionNumber] = Dimension Then
			FormParameters.Insert("DimensionNumber", DimensionNumber);
			Break;
		EndIf;
	EndDo;
	
	Return FormParameters;
	
EndFunction

&AtServerNoContext
Function TemplateIsUsedInDocuments(InputTemplate, Document)
	
	Return Catalogs.NonFinancialItemProfiles.TemplateIsUsedInDocuments(InputTemplate, Document);
	
EndFunction

&AtServer
Procedure SetValueFromAnalytics(ValueType, RowIndex, SourceOfChange, CacheOfAnalyticsValues = Undefined)
	
	ObjectAndCalculationParameters = StructureForCallingManagerModuleProcedures();
	Documents.SetValuesForNonFinancialItems.SetValueFromAnalytics(ObjectAndCalculationParameters, ValueType, RowIndex, SourceOfChange, CacheOfAnalyticsValues);
	
EndProcedure

&AtServer
Procedure SetValuesFromAnalyticsByRows(SourceOfChange, Currency, UnitOfMeasure)
	
	CacheOfAnalyticsValues = New Map;
	For Each LineOfATabularSection In TabularSection Do
		If Currency Then
			SetValueFromAnalytics("Currency_",
				LineOfATabularSection.GetID(), SourceOfChange, CacheOfAnalyticsValues);
		EndIf;
		If UnitOfMeasure Then
			SetValueFromAnalytics("Ed_",
				LineOfATabularSection.GetID(), SourceOfChange, CacheOfAnalyticsValues);
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure NonFinancialItemChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	Attributes = GeneralPurposeTMServerCall.ObjectAttributesValues(ValueSelected, "ImportFromOtherSubsystems, ByScenarios");
	InputUnavailable = Attributes.ImportFromOtherSubsystems And Not Attributes.ByScenarios;
	If InputUnavailable Then
		WarningText = NStr("vi = 'Các giá trị cho số liệu đã chọn luôn được tải từ các hệ thống con khác.';
							|ru = 'Значения для выбранного показателя всегда загружаются из других подсистем';
							|en = 'Values for the selected indicator are always imported from other subsystems'; fa = 'Values for the selected indicator are always imported from other subsystems';
							|it = 'I valori per l''indice selezionato vengono caricati dagli altri sottosistemi';
							|pl = 'Wartości dla wybranego wskaźnika są zawsze pobierane z innych podsystemów.';
							|tr = 'Her zaman diğer alt sistemlerden indirilen seçili göstergeler için değerler'");
		ShowMessageBox(,WarningText);
		StandardProcessing = False;
	EndIf;
	
EndProcedure

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
	If Item.Name = "sh_ShamsiInput_BeginOfPeriod" Then
		BeginOfPeriodOnChange(Items.BeginOfPeriod);
	ElsIf Item.Name = "sh_ShamsiInput_PeriodEnding" Then
		EndOfPeriod1OnChange(Items.PeriodEnding);
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
