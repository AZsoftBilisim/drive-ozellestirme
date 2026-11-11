
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	DefineBehaviorInMobileClient();
	
	SetConditionalAppearance();
	
	FillInAnalysisOptions();
	
	If AnalysisOptions.GetItems().Count() = 0 Then
		Items.Pages.CurrentPage = Items.MessagesPage;
	Else
		Items.Pages.CurrentPage = Items.PageOfAnalysisOptionSettings;
	EndIf;
	
	DetailDisplayOption = "ShowCurValueAndDetails";
	
	If Not IsMobileClient Then
		Items.AnalysisOptionPages.CurrentPage = Items.AnalysisOptionsByPurposesPage;
	EndIf;
	
	// We cache the display options and the type of analysis, as a comparison with them on the client will be required.
	DisplayOptionBriefly = Enums.DisplayOptionsOfAnalysisOptions.Brief1;
	DisplayOptionChart = Enums.DisplayOptionsOfAnalysisOptions.Chart;
	DisplayOptionTable = Enums.DisplayOptionsOfAnalysisOptions.Table;
	TypeOfAnalysisComponentByComponentComparison = Enums.IndicatorAnalysisTypes.ComponentWiseComparisonStructure;
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;

EndProcedure

&AtClient
Procedure OnOpen(Cancel)

	If IsMobileClient Then
		FillInListOfAnalysisOptions();
		AnalysisOptionsList.Sort("AnalysisOption");
	EndIf;

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	OnReadCreateAtServer();
	
	Icon = CurrentObject.Icon.Get();
	If Icon <> Undefined Then
		PictureAddress = PutToTempStorage(Icon, UUID);
	EndIf;

EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)

	If Not IsMobileClient Then
		AnalysisOptionsList.Clear();
		FillInListOfAnalysisOptions();
		AnalysisOptionsList.Sort("AnalysisOption");
	EndIf;
	If AnalysisOptionsList.Count() = 0 Then
		CommonClient.MessageToUser(NStr("vi = 'Chưa chọn phương án phân tích nào';
										|ru = 'Не выбрано ни одного варианта анализа';
										|en = 'No analysis option is selected'; fa = 'No analysis option is selected';
										|it = 'Nessuna versione di analisi è stata selezionata';
										|pl = 'Nie wybrano ani wariantu analizy';
										|tr = 'Analizin hiç bir seçeneği seçilmedi'"), , , , Cancel);
	EndIf;

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	If CurrentObject.IsNew() Then
		CurrentObject.Author = Users.CurrentUser();
	EndIf;
	
	CurrentObject.AnalysisOptions.Clear();
	
	For Each AnalysisOption In AnalysisOptionsList Do
		NewRow = CurrentObject.AnalysisOptions.Add();
		FillPropertyValues(NewRow, AnalysisOption);
	EndDo;
	
	If Not IsBlankString(PictureAddress) Then
		CurrentObject.Icon = New ValueStorage(GetFromTempStorage(PictureAddress));
	Else
		CurrentObject.Icon = Undefined;
	EndIf;
	
	If Not IsBlankString(PictureAddress) Then
		CurrentObject.AdditionalProperties.Insert("PictureAddress", PictureAddress);
	EndIf;

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	Notify("Entry_MCPDashboard", WriteParameters, Object.Ref);

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	If Not Object.AuthorOnly And Object.DashboardUser.Count() = 0 Then
		Common.MessageToUser(NStr("vi = 'Chưa chỉ định người sử dụng bảng điều khiển';
									|ru = 'Не назначены пользователи дашборда';
									|en = 'Dashboard users are not assigned'; fa = 'Dashboard users are not assigned';
									|it = 'Non è stato assegnato nessun utente del pannello di controllo ';
									|pl = 'Nie przydzielono użytkowników panelu';
									|tr = 'Gösterge tablosu kullanıcıları atanmadı'"), ,
			"DashboardUser", "Object", Cancel);
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure Availability_OptionOnChange(Item)

	Object.AuthorOnly = (Availability_Option = "OnlyAuthor");
	
	If Object.AuthorOnly Then
		Object.DashboardUser.Clear();
	EndIf;
	
	FormControl(ThisObject);

EndProcedure

&AtClient
Procedure NumberOfIndicatorMonitorColumnsStartChoice(Item, ChoiceData, StandardProcessing)

	StandardProcessing = False;
	
	If IsMobileClient Then
		ShowChooseFromList(New CallbackDescription("NumberOfColumnsOfIndicatorMonitorSelectionFromEndList",
			ThisObject), Item.ChoiceList);
	EndIf;

EndProcedure

&AtClient
Procedure NumberOfIndicatorMonitorColumnsChoiceProcessing(Item, ValueSelected, StandardProcessing)

	StandardProcessing = False;
	
	If ValueSelected = "Other" Then
		Object.ColumnsCount = 5;
	Else
		Object.ColumnsCount = ValueSelected;
	EndIf;
	
	FormControl(ThisObject);

EndProcedure

&AtClient
Procedure SizeOfChartTablesStartChoice(Item, ChoiceData, StandardProcessing)

	StandardProcessing = False;
	
	If IsMobileClient Then
		ShowChooseFromList(New CallbackDescription("SizeOfTablesChartsSelectionFromEndList", ThisObject),
			Item.ChoiceList);
	EndIf;

EndProcedure

&AtClient
Procedure SizeOfChartTablesTuning(Item, Direction, StandardProcessing)

	StandardProcessing = False;
	
	If Direction > 0 Then
		Object.Scale = Min(500, Object.Scale + 25);
	Else
		Object.Scale = Max(50, Object.Scale - 25);
	EndIf;

EndProcedure

&AtClient
Procedure SizeOfChartTablesChoiceProcessing(Item, ValueSelected, StandardProcessing)

	StandardProcessing = False;
	
	If ValueSelected = "arbitrary" Then
		Object.Scale = 225;
	Else
		Object.Scale = ValueSelected;
	EndIf;
	
	FormControl(ThisObject);

EndProcedure

&AtClient
Procedure PictureAddressClick(Item, StandardProcessing)

	StandardProcessing = False;

	SelectIconFile();

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAnalysisOptions

&AtClient
Procedure AnalysisOptionsAvailabilityByPurposeOnChange(Item)

	If Items.AnalysisOptions.CurrentData <> Undefined Then
		UpdateAccessibilityCompositionDown(Items.AnalysisOptions.CurrentRow,
			Items.AnalysisOptions.CurrentData.AvailabilityByPurpose);
		UpdateAccessibilityComposition(Items.AnalysisOptions.CurrentRow);
		
	EndIf;

EndProcedure

&AtClient
Procedure AnalysisOptionsEnabledOnChange(Item)

	If Items.AnalysisOptions.CurrentData <> Undefined Then
		UpdateAccessibilityComposition(Items.AnalysisOptions.CurrentRow);
	EndIf;

EndProcedure

&AtClient
Procedure AnalysisOptionsBeforeRowChange(Item, Cancel)

	ChoiceList = Items.AnalysisOptionsViewOption.ChoiceList;

	FillInListOfDisplayOptions(ChoiceList, Item.CurrentData.AnalysisType);

EndProcedure

&AtClient
Procedure AnalysisOptionsOnChange(Item)

	Modified = True;

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAnalysisOptionsList

&AtClient
Procedure AnalysisOptionsListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)

	If IsMobileClient Then

		Cancel = True;
		ParametersString1  = "DisplayOptionChart,DisplayOptionBriefly,DisplayOptionTable,TypeOfAnalysisComponentByComponentComparison";
		StringDataStructure = New Structure(ParametersString1);
		FillPropertyValues(StringDataStructure, ThisObject);
		StringDataStructure.Insert("ParametersString1", ParametersString1);
		OpenForm("Catalog.PerformanceDashboards.Form.LineEditForm",
			StringDataStructure, ThisObject, UUID, , ,
			New CallbackDescription("AnalysisOptionsListLineEditingEnd", ThisObject,
			New Structure("NewRow", True)));

	EndIf;

EndProcedure

&AtClient
Procedure AnalysisOptionsListBeforeRowChange(Item, Cancel)

	If IsMobileClient Then

		Cancel = True;
		ParametersString1 = "DisplayOptionChart,DisplayOptionBriefly,DisplayOptionTable,TypeOfAnalysisComponentByComponentComparison,AnalysisOption,ViewOption,Details_3,TableSummary,AnalysisType";
		StringDataStructure = New Structure(ParametersString1);
		FillPropertyValues(StringDataStructure, ThisObject);
		FillPropertyValues(StringDataStructure, Item.CurrentData);
		StringDataStructure.Insert("ParametersString1", ParametersString1);
		OpenForm("Catalog.PerformanceDashboards.Form.LineEditForm",
			StringDataStructure, ThisObject, UUID, , ,
			New CallbackDescription("AnalysisOptionsListLineEditingEnd", ThisObject,
			New Structure("NewRow", False)), FormWindowOpeningMode.LockOwnerWindow);

	Else

		ChoiceList = Items.AnalysisOptionsListViewOption.ChoiceList;

		FillInListOfDisplayOptions(ChoiceList, Item.CurrentData.AnalysisType);
	
	EndIf;

EndProcedure

&AtClient
Procedure AnalysisOptionsListBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)

	If Not CancelEdit Then
		CurrentData = Items.AnalysisOptionsList.CurrentData;
		If Not ValueIsFilled(CurrentData.AnalysisOption) Then
			CommonClient.MessageToUser(NStr("vi = 'Chưa chỉ ra phương án phân tích';
											|ru = 'Не указан вариант анализа';
											|en = 'Analysis option is not specified'; fa = 'Analysis option is not specified';
											|it = 'Versione di analisi non indicata';
											|pl = 'Nie podano wariantu analizy';
											|tr = 'Analiz seçeneği belirtilmedi'"), , , , Cancel);
		Else
			MatchingLines = AnalysisOptionsList.FindRows(New Structure("AnalysisOption",
				CurrentData.AnalysisOption));
			If MatchingLines.Count() > 1 Then
				CommonClient.MessageToUser(NStr("vi = 'Đang sử dụng phương án phân tích được chọn';
												|ru = 'Выбранный вариант анализа уже используется';
												|en = 'Selected analysis option is already used'; fa = 'Selected analysis option is already used';
												|it = 'La versione di analisi selezionata è già in uso';
												|pl = 'Wybrany wariant analizy jest już używany';
												|tr = 'Seçilen analiz seçeneği artık kullanılıyor'"),
					, , , Cancel);
			EndIf;
		EndIf;
		If Not ValueIsFilled(CurrentData.ViewOption) Then
			CommonClient.MessageToUser(NStr("vi = 'Chưa chỉ ra phương án hiển thị';
											|ru = 'Не указан вариант отображения';
											|en = 'Display option is not specified'; fa = 'Display option is not specified';
											|it = 'Versione di visualizzazione non indicata';
											|pl = 'Nie jest określony wariant wyświetlenia';
											|tr = 'Yansıtma seçeneği belirtilmedi'"), , , , Cancel);
		EndIf;
	EndIf;

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDashboardUser

&AtClient
Procedure DashboardUserChoiceProcessing(Item, ValueSelected, StandardProcessing)

	Object.DashboardUser.Clear();
	If TypeOf(ValueSelected) = Type("Array") Then
		For Each Value In ValueSelected Do
			UserChoiceProcessing(Value);
		EndDo;
	Else
		UserChoiceProcessing(ValueSelected);
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Set_Marks(Command)

	UpdateAccessibilityCompositionDown(Undefined, True);
	
	Modified = True;

EndProcedure

&AtClient
Procedure ClearAll(Command)

	UpdateAccessibilityCompositionDown(Undefined, False);
	
	Modified = True;

EndProcedure

&AtClient
Procedure PickUsers(Command)

	FormParameters = New Structure;
	FormParameters.Insert("ChoiceMode", True);
	FormParameters.Insert("CloseOnChoice", False);
	FormParameters.Insert("MultipleChoice", True);
	FormParameters.Insert("AdvancedPick", True);
	FormParameters.Insert("ExtendedPickFormParameters", ExtendedPickFormParameters());
	
	OpenForm("Catalog.Users.ChoiceForm", FormParameters, Items.DashboardUser);

EndProcedure

&AtClient
Procedure AddImage(Command)

	SelectIconFile();

EndProcedure

&AtClient
Procedure ClearImage(Command)

	PictureAddress = "";

EndProcedure

&AtClient
Procedure ChangeImage(Command)

	SelectIconFile();

EndProcedure

#EndRegion

#Region Private

#Region Other

&AtClientAtServerNoContext
Procedure FormControl(Form)

	Items = Form.Items;
	Object = Form.Object;
	
	Items.DashboardUser.Visible = Not Object.AuthorOnly;
	Items.NumberOfIndicatorMonitorColumns.SpinButton = (Object.ColumnsCount > 4);
	Items.SizeOfChartTables.SpinButton = (Object.Scale > 200);

EndProcedure

&AtServer
Procedure OnReadCreateAtServer()

	FillInListOfSelectingNumberOfColumnsOfIndicatorMonitor(ThisObject);
	FillInSizeSelectionListOfChartTables(ThisObject);
	
	FormControl(ThisObject);
	
	If Object.AuthorOnly Then
		Availability_Option = "OnlyAuthor";
	Else
		Availability_Option = "AllUsers2";
	EndIf;

EndProcedure

&AtClient
Procedure FillInListOfDisplayOptions(ChoiceList, AnalysisType)

	ChoiceList.Clear();

	ChoiceList.Add(DisplayOptionBriefly);
	ChoiceList.Add(DisplayOptionChart);

	If AnalysisType = TypeOfAnalysisComponentByComponentComparison Then
		ChoiceList.Add(DisplayOptionTable);
	EndIf;

EndProcedure

&AtClient
Procedure SelectIconFile()

	ImportParameters = FileSystemClient.FileImportParameters();
	ImportParameters.FormIdentifier = UUID;
	ImportParameters.Dialog.Title = NStr("vi = 'Hãy chọn tệp cho hình ảnh bảng điều khiển';
										|ru = 'Выберите файл для картинки дашборда';
										|en = 'Select a file for the picture dashboard'; fa = 'Select a file for the picture dashboard';
										|it = 'Selezionare un file per l''immagine del pannello di controllo';
										|pl = 'Wybierz plik dla obrazu panelu';
										|tr = 'Gösterge paneli resmi için dosya seç'");
	ImportParameters.Dialog.Filter = NStr(
		"vi = 'Tệp hình ảnh (*.gif;*.jpg;*.jpeg;*.bmp;*.png)|*.gif;*.jpg;*.jpeg;*.bmp;*.png';
		|ru = 'Файл картинки (*.gif;*.jpg;*.jpeg;*.bmp;*.png)|*.gif;*.jpg;*.jpeg;*.bmp;*.png';
		|en = 'Picture file (*.gif;*.jpg;*.jpeg;*.bmp;*.png)|*.gif;*.jpg;*.jpeg;*.bmp;*.png'; fa = 'Picture file (*.gif;*.jpg;*.jpeg;*.bmp;*.png)|*.gif;*.jpg;*.jpeg;*.bmp;*.png';
		|it = 'File dell''immagine (*.gif;*.jpg;*.jpeg;*.bmp;*.png)|*.gif;*.jpg;*.jpeg;*.bmp;*.png';
		|pl = 'Plik obrazu (*.gif;*.jpg;*.jpeg;*.bmp;*.png)|*.gif;*.jpg;*.jpeg;*.bmp;*.png';
		|tr = 'Resim dosyası (*.gif;*.jpg;*.jpeg;*.bmp;*.png)|*.gif;*.jpg;*.jpeg;*.bmp;*.png'");
	ImportParameters.Dialog.Preview = False;
	ImportParameters.Dialog.FilterIndex = 0;
	ImportParameters.Dialog.CheckFileExistence = True;

	Notification = New CallbackDescription("SelectingFileCompletion", ThisObject);
	FileSystemClient.ImportFile_(Notification, ImportParameters);

EndProcedure

&AtClient
Procedure SelectingFileCompletion(FileData, AdditionalParameters) Export

	If FileData <> Undefined Then
		
		PictureAddress = FileData.Location;
		
	EndIf;

EndProcedure

#EndRegion

&AtServer
Procedure DefineBehaviorInMobileClient()

	IsMobileClient = Common.IsMobileClient();
	If Not IsMobileClient Then 
		Return;
	EndIf;
	
	Items.AnalysisOptionPages.CurrentPage = Items.AnalysisOptionsPageList;
	
	Items.IconGroup.Visible = False;

EndProcedure

&AtServerNoContext
Procedure FillInListOfSelectingNumberOfColumnsOfIndicatorMonitor(Form)

	Items = Form.Items;
	
	NumberOfColumnsSelectionList = Items.NumberOfIndicatorMonitorColumns.ChoiceList;
	NumberOfColumnsSelectionList.Clear();
	NumberOfColumnsSelectionList.Add(0, NStr("vi = 'Tự động';
											|ru = 'Авто';
											|en = 'Auto'; fa = 'خودکار';
											|it = 'Auto';
											|pl = 'Auto';
											|tr = 'Oto'"));
	NumberOfColumnsSelectionList.Add(1);
	NumberOfColumnsSelectionList.Add(2);
	NumberOfColumnsSelectionList.Add(3);
	NumberOfColumnsSelectionList.Add(4);
	NumberOfColumnsSelectionList.Add(NStr("vi = 'Khác';
											|ru = 'Другое';
											|en = 'Other'; fa = 'سایر';
											|it = 'Altro';
											|pl = 'Other';
											|tr = 'Diğer'"), NStr("vi = 'Khác...';
																|ru = 'Другое...';
																|en = 'Other…'; fa = 'Other…';
																|it = 'Altro...';
																|pl = 'Other…';
																|tr = 'Diğer...'"));
	
	Items.NumberOfIndicatorMonitorColumns.DropListButton = True;
	Items.NumberOfIndicatorMonitorColumns.TextEdit = True;

EndProcedure

&AtServerNoContext
Procedure FillInSizeSelectionListOfChartTables(Form)

	Items = Form.Items;
	
	SizeSelectionList = Items.SizeOfChartTables.ChoiceList;
	SizeSelectionList.Clear();
	SizeSelectionList.Add(50, NStr("vi = 'Tự động';
									|ru = 'Авто';
									|en = 'Auto'; fa = 'خودکار';
									|it = 'Auto';
									|pl = 'Auto';
									|tr = 'Oto'"));
	SizeSelectionList.Add(75, "75%");
	SizeSelectionList.Add(100, NStr("vi = '100% (chuẩn)';
									|ru = '100% (стандартно)';
									|en = '100% (standard)'; fa = '100% (standard)';
									|it = '100% (standard)';
									|pl = '100% (standardowo)';
									|tr = '100% (standart)'"));
	SizeSelectionList.Add(125, "125%");
	SizeSelectionList.Add(150, "150%");
	SizeSelectionList.Add(175, "175%");
	SizeSelectionList.Add(200, NStr("vi = '200% (lớn)';
									|ru = '200% (крупный)';
									|en = '200% (large)'; fa = '200% (large)';
									|it = '200% (grande)';
									|pl = '200% (duży)';
									|tr = '200% (büyük)'"));
	SizeSelectionList.Add(225, NStr("vi = 'tùy ý';
									|ru = 'произвольный';
									|en = 'arbitrary'; fa = 'arbitrary';
									|it = 'libero';
									|pl = 'arbitrary';
									|tr = 'isteğe bağlı'"));
	
	Items.NumberOfIndicatorMonitorColumns.DropListButton = True;
	Items.NumberOfIndicatorMonitorColumns.TextEdit = True;

EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AnalysisOptions.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AnalysisOptions.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("BackColor", StyleColors.ReportGroup1BackColor);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AnalysisOptionsAvailabilityByPurpose.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AnalysisOptionsTarget.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AnalysisOptions.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 1;

	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AnalysisOptionsEnabled.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AnalysisOptionsAnalysisOption.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AnalysisOptions.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AnalysisOptionsDetails_3.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AnalysisOptionsTableSummary.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AnalysisOptions.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AnalysisOptionsTableSummary.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AnalysisOptions.ViewOption");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.DisplayOptionsOfAnalysisOptions.Brief1);
	ValueList.Add(Enums.DisplayOptionsOfAnalysisOptions.Chart);
	ItemFilter.RightValue = ValueList;

	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AnalysisOptionsListTableSummary.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AnalysisOptionsList.ViewOption");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.DisplayOptionsOfAnalysisOptions.Brief1);
	ValueList.Add(Enums.DisplayOptionsOfAnalysisOptions.Chart);
	ItemFilter.RightValue = ValueList;

	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AnalysisOptionsDetails_3.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AnalysisOptions.ViewOption");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.DisplayOptionsOfAnalysisOptions.Brief1;

	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AnalysisOptionsListDetails_3.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AnalysisOptionsList.ViewOption");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.DisplayOptionsOfAnalysisOptions.Brief1;

	Item.Appearance.SetParameterValue("ReadOnly", True);

EndProcedure

&AtClient
Procedure UpdateAccessibilityComposition(RowID)

	CurrentData = AnalysisOptions.FindByID(RowID);
	
	CurParentData = CurrentData.GetParent();
	
	If Not CurParentData = Undefined Then
		ParentItems1 = CurParentData.GetItems();
		
		NumberOfZeros = 0;
		QuantityOfUnits = 0;
		NumberOfTwos = 0;
		For Each ParentItem1 In ParentItems1 Do 
			If ParentItem1.RowType = 0 Then 
				AccessibilityValue = ParentItem1.AvailabilityByPurpose;
				
			ElsIf ParentItem1.RowType = 1 Then 
				AccessibilityValue = ParentItem1.Enabled;
				
			EndIf;
			
			If AccessibilityValue = 0 Then
				NumberOfZeros = NumberOfZeros + 1;
				
			ElsIf AccessibilityValue = 1 Then
				QuantityOfUnits = QuantityOfUnits + 1;
				
			ElsIf AccessibilityValue = 2 Then
				NumberOfTwos = NumberOfTwos + 1;
				
			EndIf;
			
		EndDo;
		
		ItemCount = ParentItems1.Count();
		
		If NumberOfZeros = 0 Then
			If QuantityOfUnits = ItemCount Then
				CurParentData.AvailabilityByPurpose = 1;
				
			Else
				CurParentData.AvailabilityByPurpose = 2;
				
			EndIf;
		Else
			If NumberOfZeros = ItemCount Then
				CurParentData.AvailabilityByPurpose = 0;
				
			Else
				CurParentData.AvailabilityByPurpose = 2;
				
			EndIf;
		EndIf;
		
		UpdateAccessibilityComposition(CurParentData.GetID());
		
	EndIf;

EndProcedure

&AtClient
Procedure UpdateAccessibilityCompositionDown(RowID, State)

	If RowID = Undefined Then
		CollectionOfAnalysisOptions = AnalysisOptions.GetItems();
		
	Else
		CurrentData = AnalysisOptions.FindByID(RowID);
		
		State = ?(State = 2, 0, State);
		
		If CurrentData.RowType = 0 Then
			CurrentData.AvailabilityByPurpose = State;
			
		ElsIf CurrentData.RowType = 1 Then
			CurrentData.Enabled = State;
			
		EndIf;
		
		CollectionOfAnalysisOptions = CurrentData.GetItems();
		
	EndIf;
	
	For Each ElementOfAnalysisOptionsCollection In CollectionOfAnalysisOptions Do
		If ElementOfAnalysisOptionsCollection.RowType = 0 Then
			ElementOfAnalysisOptionsCollection.AvailabilityByPurpose = State;
		
			UpdateAccessibilityCompositionDown(ElementOfAnalysisOptionsCollection.GetID(), State);
		
		ElsIf ElementOfAnalysisOptionsCollection.RowType = 1 Then
			ElementOfAnalysisOptionsCollection.Enabled = State;
			
		EndIf;
		
	EndDo;

EndProcedure

&AtClient
Procedure FillInListOfAnalysisOptions(RowID = Undefined)

	If RowID = Undefined Then
		// Processing all
		CollectionOfAnalysisOptions = AnalysisOptions.GetItems();
		
	Else
		CurrentData = AnalysisOptions.FindByID(RowID);
		
		CollectionOfAnalysisOptions = CurrentData.GetItems();
		
	EndIf;
	
	For Each ElementOfAnalysisOptionsCollection In CollectionOfAnalysisOptions Do
		
		ItemID = ElementOfAnalysisOptionsCollection.GetID();
		
		If ElementOfAnalysisOptionsCollection.RowType = 0 Then
			
			FillInListOfAnalysisOptions(ItemID);
			
		ElsIf ElementOfAnalysisOptionsCollection.RowType = 1
			And ElementOfAnalysisOptionsCollection.Enabled Then
			
			NewlySelectedAnalysisOption = AnalysisOptionsList.Add();
			NewlySelectedAnalysisOption.AnalysisOption = ElementOfAnalysisOptionsCollection.AnalysisOption;
			NewlySelectedAnalysisOption.ViewOption = ElementOfAnalysisOptionsCollection.ViewOption;
			NewlySelectedAnalysisOption.Details_3 = ElementOfAnalysisOptionsCollection.Details_3;
			NewlySelectedAnalysisOption.TableSummary = ElementOfAnalysisOptionsCollection.TableSummary;
			NewlySelectedAnalysisOption.AnalysisType = ElementOfAnalysisOptionsCollection.AnalysisType;
			
		EndIf;
	EndDo;

EndProcedure

&AtServer
Procedure FillInAnalysisOptions()

	Query = New Query;
	If Parameters.Property("CopyingValue")
		And ValueIsFilled(Parameters.CopyingValue) Then
		Query.SetParameter("Ref", Parameters.CopyingValue);
	Else
		Query.SetParameter("Ref", Object.Ref);
	EndIf;
	Query.Text =
	"SELECT
	|	AnalysisOptionsOfTargetValues.Owner AS Target,
	|	FALSE AS AvailabilityByPurpose,
	|	AnalysisOptionsOfTargetValues.Ref AS AnalysisOption,
	|	CASE
	|		WHEN PerformanceDashboardsAnalysisOptions.Ref IS NULL
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS Enabled,
	|	CASE
	|		WHEN PerformanceDashboardsAnalysisOptions.ViewOption IS NULL
	|			THEN AnalysisOptionsOfTargetValues.DisplayOptionDefault
	|		ELSE PerformanceDashboardsAnalysisOptions.ViewOption
	|	END AS ViewOption,
	|	CASE
	|		WHEN PerformanceDashboardsAnalysisOptions.Details_3 IS NULL
	|			THEN FALSE
	|		ELSE PerformanceDashboardsAnalysisOptions.Details_3
	|	END AS Details_3,
	|	CASE
	|		WHEN PerformanceDashboardsAnalysisOptions.TableSummary IS NULL
	|			THEN FALSE
	|		ELSE PerformanceDashboardsAnalysisOptions.TableSummary
	|	END AS TableSummary,
	|	1 AS RowType,
	|	AnalysisOptionsOfTargetValues.AnalysisType AS AnalysisType
	|FROM
	|	Catalog.AnalysisOptionsOfTargetValues AS AnalysisOptionsOfTargetValues
	|		LEFT JOIN Catalog.PerformanceDashboards.AnalysisOptions AS PerformanceDashboardsAnalysisOptions
	|		ON AnalysisOptionsOfTargetValues.Ref = PerformanceDashboardsAnalysisOptions.AnalysisOption
	|			AND (PerformanceDashboardsAnalysisOptions.Ref = &Ref)
	|WHERE
	|	NOT AnalysisOptionsOfTargetValues.DeletionMark
	|
	|ORDER BY
	|	AnalysisOptionsOfTargetValues.Owner.AttributeOfAdditionalSortingHierarchical,
	|	AnalysisOptionsOfTargetValues.AddlOrderingAttribute
	|TOTALS
	|	CASE
	|		WHEN MAX(Enabled) = TRUE
	|				AND MIN(Enabled) = TRUE
	|			THEN 1
	|		WHEN MAX(Enabled) = FALSE
	|				AND MIN(Enabled) = FALSE
	|			THEN 0
	|		WHEN MAX(Enabled) = TRUE
	|				AND MIN(Enabled) = FALSE
	|			THEN 2
	|	END AS AvailabilityByPurpose,
	|	AVG(CASE
	|			WHEN Target IS NULL
	|				THEN 1
	|			ELSE 0
	|		END) AS RowType
	|BY
	|	Target HIERARCHY";
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		ValueAnalysisOptions = QueryResult.Unload(QueryResultIteration.ByGroupsWithHierarchy);
		
		PrepareTreeOfAnalysisOptions(ValueAnalysisOptions);
		
		DeleteRowsWithoutSubordinates(ValueAnalysisOptions);
		
		ValueToFormData(ValueAnalysisOptions, AnalysisOptions);
		
	EndIf;

EndProcedure

&AtServer
Procedure PrepareTreeOfAnalysisOptions(AnalysisOptionTree, InitialValidationLine = Undefined)

	If InitialValidationLine = Undefined Then
		TreeRows = AnalysisOptionTree.Rows;
	Else
		TreeRows = InitialValidationLine.Rows;
	EndIf;
	
	For Each TreeRow In TreeRows Do
		If TreeRow.Rows.Count() Then
			PrepareTreeOfAnalysisOptions(AnalysisOptionTree, TreeRow);
		EndIf;
		
		If Not TreeRow.Parent = Undefined And TreeRow.Target = TreeRow.Parent.Target Then
			LinesOfCurTreeLine = TreeRow.Rows;
			
			InsertPosition = TreeRows.IndexOf(TreeRow);
			For Each RowOfCurTreeRow In LinesOfCurTreeLine Do
				TransferredLine = TreeRow.Parent.Rows.Insert(InsertPosition);
				FillPropertyValues(TransferredLine, RowOfCurTreeRow);
				
				InsertPosition = InsertPosition + 1;
				
			EndDo;
			
			TreeRow.Rows.Clear();
			
		EndIf;
		
	EndDo;

EndProcedure

&AtServer
Procedure DeleteRowsWithoutSubordinates(AnalysisOptionTree, InitialValidationLine = Undefined)

	If InitialValidationLine = Undefined Then
		TreeRows = AnalysisOptionTree.Rows;
	Else
		TreeRows = InitialValidationLine.Rows;
	EndIf;
	
	RowIndex = TreeRows.Count() - 1;
	While RowIndex >= 0 Do 
		RowToValidate = TreeRows[RowIndex];
		
		If RowToValidate.RowType = 1 Then
			RowIndex = RowIndex - 1;
			Continue;
		EndIf;
		
		If RowToValidate.Rows.Count() Then
			DeleteRowsWithoutSubordinates(AnalysisOptionTree, RowToValidate);
		Else
			TreeRows.Delete(RowToValidate);
		EndIf;
		
		RowIndex = RowIndex - 1;
		
	EndDo;

EndProcedure

&AtClient
Procedure UserChoiceProcessing(ValueSelected)

	If TypeOf(ValueSelected) = Type("CatalogRef.Users") Then
		Object.DashboardUser.Add().User = ValueSelected;
	EndIf;

EndProcedure

&AtServer
Function ExtendedPickFormParameters()

	SelectedUsers = New ValueTable;
	SelectedUsers.Columns.Add("User");
	SelectedUsers.Columns.Add("PictureNumber");
	
	GroupMembers = Object.DashboardUser.Unload(, "User");
	
	For Each Item In GroupMembers Do
		
		SelectedUsersRow = SelectedUsers.Add();
		SelectedUsersRow.User = Item.User;
	
	EndDo;
	
	PickFormHeader = NStr("vi = 'Chọn người sử dụng cho bảng điều khiển';
							|ru = 'Подбор пользователей для дашборда МЦП';
							|en = 'Pick users for Performance dashboard'; fa = 'Pick users for Performance dashboard';
							|it = 'Selezione utenti per il pannello di controllo Monitor degli indici obiettivo';
							|pl = 'Wybór użytkowników dla panelu Monitora Wskaźników Celowych';
							|tr = 'PPA paneli için kullanıcı seçimi'");
	ExtendedPickFormParameters = 
		New Structure("PickFormHeader, SelectedUsers, CannotPickGroups",
		PickFormHeader, SelectedUsers, True);
	StorageAddress = PutToTempStorage(ExtendedPickFormParameters);
	Return StorageAddress;

EndFunction

&AtClient
Procedure SizeOfTablesChartsSelectionFromEndList(Result, AdditionalParameters) Export

	If Result <> Undefined Then
		If Result.Value = "arbitrary" Then
			Object.Scale = 225;
		Else
			Object.Scale = Result.Value;
		EndIf;
		FormControl(ThisObject);
	EndIf;

EndProcedure

&AtClient
Procedure NumberOfColumnsOfIndicatorMonitorSelectionFromEndList(Result, AdditionalParameters) Export

	If Result <> Undefined Then
		If Result.Value = "Other" Then
			Object.ColumnsCount = 5;
		Else
			Object.ColumnsCount = Result.Value;
		EndIf;
		FormControl(ThisObject);
	EndIf;

EndProcedure

&AtClient
Procedure AnalysisOptionsListLineEditingEnd(Result, AdditionalParameters) Export

	If TypeOf(Result) = Type("Structure") Then
		If AdditionalParameters.NewRow Then
			TableRow = AnalysisOptionsList.Add();
		Else
			TableRow = Items.AnalysisOptionsList.CurrentData;
		EndIf;
		FillPropertyValues(TableRow, Result);
	EndIf;

EndProcedure

#EndRegion
