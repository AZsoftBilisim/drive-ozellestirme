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
	
	If TypeOf(Parameters.FilterStructure1) = Type("Structure") Then
		FilterStructure1 = Parameters.FilterStructure1;
	Else
		FilterStructure1 = New Structure;
	EndIf;
	
	AddressInStorage  = Parameters.AddressInStorage;
	BeginOfPeriod    = Parameters.BeginOfPeriod;
	PeriodEnding = Parameters.PeriodEnding;
	SingleChoice   = Parameters.SingleChoice;
	
	Items.QuickFiltersGroup.Visible = ?(Parameters.Property("ChangingPeriodAndOrganization"),
		Parameters.ChangingPeriodAndOrganization, False);
	NotifyOnSelection = ?(Parameters.Property("NotifyOnSelection"), Parameters.NotifyOnSelection, False);
	FilterStructure1.Property("Organization", Organization);
	
	FilterStructure1.Property("Department", Department);
	FilterStructure1.Property("Department", PreviousDepartment);
	
	FilterStructure1.Property("LineOfBusiness", LineOfBusiness);
	FilterStructure1.Property("LineOfBusiness", DirectionOfActivityIsSame);
	
	FilterStructure1.Property("Purpose", Purpose);
	FilterStructure1.Property("Purpose", ThePurposeIsTheSame);
	
	FilterStructure1.Property("ProductionOrder", ProductionOrder);
	FilterStructure1.Property("ExcludeProductionByThirdParties", ExcludeProductionByThirdParties);
	
	If FilterStructure1.Property("StagesOfTheCurrentMonth") And FilterStructure1.StagesOfTheCurrentMonth Then
		StagesOfTheCurrentMonth = True;
		Items.StagesOfTheCurrentMonth.Visible = False;
	EndIf;
	
	If ValueIsFilled(LineOfBusiness)
		And FilterStructure1.Property("OnlySpecifiedAreaOfActivity") 
		And FilterStructure1.OnlySpecifiedAreaOfActivity
	Then
		Items.LineOfBusiness.Enabled = False;
	EndIf;
	FilterStructure1.Property("InternalSubcontracting", InternalSubcontracting);
	FilterStructure1.Property("MaterialProvider",               MaterialProvider);
	ThisIsCA = GetFunctionalOption("ComplexAutomation");
	If ThisIsCA Then
		Items.ProductionLotsStage.Title = NStr("vi = 'Lô sản xuất';
												|ru = 'Партия производства';
												|en = 'Production lot'; fa = 'بچ تولید';
												|it = 'Lotto di produzione';
												|pl = 'Partia produkcji';
												|tr = 'Üretim lotu'");
		Items.StagesOfTheCurrentMonth.Visible = False;
	EndIf;
	
	If SingleChoice Then
		Items.ProductionBatchesSelectLines.Visible   = False;
		Items.ProductionBatchesExcludeLines.Visible = False;
		Items.ProductionLotsRowIsSelected.Visible   = False;
		Items.FormMoveTo_.Title = NStr("vi = 'Chọn';
										|ru = 'Выбрать';
										|en = 'Select'; fa = 'انتخاب';
										|it = 'Выбрать';
										|pl = 'Select';
										|tr = 'Seç'");
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	FillInTableServer();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	ClosingInProgress = False;
	ChangeTitleStagesOfCurMonth();
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	If Not ValueIsFilled(Settings["SelectionOption"]) Then
		Settings["SelectionOption"]			= "ByProducts";
		Settings["SelectionOptionPrevious"]	= "ByProducts";
	EndIf;
	
	If FilterStructure1.Property("Organization") Then
		Settings["Organization"] = FilterStructure1["Organization"];
	EndIf;
	
	If FilterStructure1.Property("Department") Then
		Settings["Department"] = FilterStructure1["Department"];
	EndIf;
	
	If FilterStructure1.Property("LineOfBusiness") Then
		Settings["LineOfBusiness"] = FilterStructure1["LineOfBusiness"];
	EndIf;
	
	If FilterStructure1.Property("Purpose") Then
		Settings["Purpose"] = FilterStructure1["Purpose"];
	EndIf;
	
	Settings["Organization"] = SettingsValueCached.GetDefaultOrganization(Settings["Organization"]);
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	FillInTableServer();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)

	If Modified Then
		
		StandardProcessing = False;
		
		If Not ClosingInProgress Then
			Cancel = True;
			ShowQueryBox(New CallbackDescription("BeforeCloseCompletion", ThisObject), 
							NStr("vi = 'Dữ liệu đã thay đổi. Chuyển thay đổi?';
								|ru = 'Данные были изменены. Перенести изменения?';
								|en = 'Data has changed. Transfer the changes?'; fa = 'Data has changed. Transfer the changes?';
								|it = 'I dati sono stati modificati. Trasferire le modifiche?';
								|pl = 'Dane zostały zmienione. Chcesz przenieść zmiany?';
								|tr = 'Veriler değiştirildi. Değişiklikler aktarılsın mı?'"),
							QuestionDialogMode.YesNoCancel);
		EndIf;
	EndIf;

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure BeginOfPeriodOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	ChangeTitleStagesOfCurMonth();
	FillInTableServer();
EndProcedure

&AtClient
Procedure EndOfPeriodOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	ChangeTitleStagesOfCurMonth();
	FillInTableServer();
EndProcedure

&AtClient
Procedure OrganizationField_OnChange(Item)
	FillInTableServer();
EndProcedure

&AtClient
Procedure SelectionOptionOnChange(Item)
	
	If SelectionOption <> SelectionOptionPrevious Then
		FillInTableServer();
		SelectionOptionPrevious = SelectionOption;
	EndIf;
	
EndProcedure

&AtClient
Procedure StagesOfTheCurrentMonthOnChange(Item)
	
	FillInTableServer();
	
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	
	If Department <> PreviousDepartment Then
		FillInTableServer();
		PreviousDepartment = Department;
	EndIf;
	
EndProcedure

&AtClient
Procedure PurposeOnChange(Item)
	
	If Purpose <> ThePurposeIsTheSame Then
		FillInTableServer();
		ThePurposeIsTheSame = Purpose;
	EndIf;
	
EndProcedure

&AtClient
Procedure LineOfBusinessOnChange(Item)
	
	If LineOfBusiness <> DirectionOfActivityIsSame Then
		FillInTableServer();
		DirectionOfActivityIsSame = LineOfBusiness;
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductionOrderOnChange(Item)
	FillInTableServer();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersProductionLots

&AtClient
Procedure ProductionLotsSelection(Item, RowSelected, Field, StandardProcessing)
	
	TableRow = Items.ProductionLots.CurrentData;
	If SingleChoice And TableRow <> Undefined Then
		ClosingInProgress = True;
		If NotifyOnSelection Then
			NotifyChoice(TableRow.ProductionLot);
		Else
			Close(TableRow.ProductionLot);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectPeriod(Command)
	
	ChoiceParameters = New Structure("BeginOfPeriod, EndOfPeriod", BeginOfPeriod, PeriodEnding);
	CallbackDescription = New CallbackDescription("SelectPeriodCompletion", ThisObject);
	OpenForm("CommonForm.SelectAStandardPeriod", ChoiceParameters, Items.SelectPeriod,
		, , , CallbackDescription);
	
EndProcedure

&AtClient
Procedure MoveToDocument()
	
	If SingleChoice Then
		TableRow = Items.ProductionLots.CurrentData;
		If TableRow = Undefined Then
			Return;
		EndIf;
		
		ClosingInProgress = True;
		If NotifyOnSelection Then
			NotifyChoice(TableRow.ProductionLot);
		Else
			Close(TableRow.ProductionLot);
		EndIf;
	Else
		MoveLinesToDocument();
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectLinesStages(Command)
	
	MarkLines(True);
	
EndProcedure

&AtClient
Procedure ExcludeLinesStages(Command)
	
	MarkLines(False);
	
EndProcedure

&AtClient
Procedure UpdateTheStagesList(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	FillInTableServer();
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ChangeTitleStagesOfCurMonth()
	
	If Not Items.StagesOfTheCurrentMonth.Visible Then
		Return;
	EndIf;
	
	OneMonthIsSelected = BeginOfPeriod = BegOfMonth(PeriodEnding);
	If OneMonthIsSelected Then
		Items.StagesOfTheCurrentMonth.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Chỉ những lô hàng mà công việc theo đó được thực hiện vào tháng này (%1)';
				|ru = 'Только партии, работы по которым выполнялись в текущем месяце (%1)';
				|en = 'Only the lots processed this month (%1)'; fa = 'Only the lots processed this month (%1)';
				|it = 'Solamente i lotti, per i quali sono stati eseguiti i lavori nel mese corrente (%1)';
				|pl = 'Tylko partie, zgodnie z którymi prace były wykonywane w bieżącym miesiącu (%1)';
				|tr = 'Yalnızca mevcut ay içinde iş yapılan lotlar (%1)'"),
			Format(BeginOfPeriod, NStr("vi = 'ДФ=''ММММ гггг''';
										|ru = 'ДФ=''ММММ гггг''';
										|en = 'DF=''MMMM yyyy'''; fa = 'DF=''MMMM yyyy''';
										|it = 'ДФ=''ММММ гггг''';
										|pl = 'DF=''MMMM yyyy''';
										|tr = 'DF=''MMMM yyyy'''")));
	Else
		Items.StagesOfTheCurrentMonth.Title = 
			NStr("vi = 'Chỉ những lô hàng mà làm việc với chúng được thực hiện vào kỳ này';
				|ru = 'Только партии, работы по которым выполнялись в текущем периоде';
				|en = 'Only the lots processed in the current period'; fa = 'Only the lots processed in the current period';
				|it = 'Только партии, работы по которым выполнялись в текущем периоде';
				|pl = 'Only the lots processed in the current period';
				|tr = 'Yalnızca mevcut dönem içinde iş yapılan lotlar'");
	EndIf;
EndProcedure

&AtClient
Procedure SelectPeriodCompletion(SelectionResult, AddlParameters) Export
	
	If SelectionResult = Undefined Then
		Return;
	EndIf;
	BeginOfPeriod = SelectionResult.BeginOfPeriod;
	PeriodEnding = SelectionResult.EndOfPeriod;
	ChangeTitleStagesOfCurMonth();
	FillInTableServer();
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Visibility of the stage.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductionLotsStage.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SelectionOption");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "ByProducts";
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	// The text of the blank stage.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductionLotsStage.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ProductionLots.Stage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<công đoạn không được tạo>';
													|ru = '<этапы не созданы>';
													|en = '<stages are not created>'; fa = '<stages are not created>';
													|it = '<fasi non create>';
													|pl = '<etapy nie zostały utworzone>';
													|tr = '<aşamalar oluşturulmadı>'"));
	
	// The text of the blank division
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductionLotsDepartment.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ProductionLots.Department");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<xác định khi phát hành>';
													|ru = '<определяется при выпуске>';
													|en = '<determined upon release>'; fa = '<determined upon release>';
													|it = '<determinato al rilascio>';
													|pl = '<jest określane przy wypuszczeniu>';
													|tr = '<ürün çıkışı esnasında tanımlanmaktadır>'"));
	
EndProcedure

#Region Other

&AtServer
Function PutStringsInStorage_()
	
	TableOfSelectedRows = ProductionLots.Unload(New Structure("RowIsSelected", True));
	
	AddressInStorage = PutToTempStorage(TableOfSelectedRows, AddressInStorage);
	
	Return AddressInStorage;
	
EndFunction

&AtServer
Procedure FillInTableServer()
	
	EndOfPeriodValue = ?(ValueIsFilled(PeriodEnding), PeriodEnding, Date(3999, 12, 31, 23, 59, 59));
	FilterStructure1.Insert("PeriodEnding", EndOfPeriodValue);
	FilterStructure1.Insert("Organization", Organization);
	
	FilterStructure1.Insert("BeginOfPeriod",          BeginOfPeriod);
	FilterStructure1.Insert("Department",          Department);
	FilterStructure1.Insert("LineOfBusiness",LineOfBusiness);
	FilterStructure1.Insert("Purpose",             Purpose);
	FilterStructure1.Insert("CurMonthOnly",     StagesOfTheCurrentMonth);
	FilterStructure1.Insert("DetailByStages", ?(SelectionOption = "ByProducts", False, True));
	FilterStructure1.Insert("ProductionOrder",    ProductionOrder);
	FilterStructure1.Insert("ExcludeProductionByThirdParties", ExcludeProductionByThirdParties);
	FilterStructure1.Insert("InternalSubcontracting",  InternalSubcontracting);
	FilterStructure1.Insert("MaterialProvider",                MaterialProvider);
	Result = CostsServer.ProductionBatchesForCostSharing(FilterStructure1);
	
	ProductionLots.Load(Result);
	
EndProcedure

&AtClient
Procedure MoveLinesToDocument()
	
	AddressInStorage = PutStringsInStorage_();
	Modified = False;
	
	Close(AddressInStorage);
	
EndProcedure

&AtClient
Procedure MarkLines(Check)

	If Items.ProductionLots.SelectedRows.Count() > 1 Then
		For Each RowIndex In Items.ProductionLots.SelectedRows Do
			StringProduction = Items.ProductionLots.RowData(RowIndex);
			StringProduction.RowIsSelected = Check;
		EndDo;
	Else
		For Each StringProduction In ProductionLots Do
			StringProduction.RowIsSelected = Check;
		EndDo; 
	EndIf;

EndProcedure

#EndRegion

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		ClosingInProgress = True;
		MoveLinesToDocument();
	ElsIf QuestionResult = DialogReturnCode.No Then
		ClosingInProgress = True;
		Close();
	Else
		ClosingInProgress = False;
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
	If Item.Name = "sh_ShamsiInput_F_BeginOfPeriod" Then
		BeginOfPeriodOnChange(Items.BeginOfPeriod);
	ElsIf Item.Name = "sh_ShamsiInput_F_PeriodEnding" Then
		EndOfPeriodOnChange(Items.EndOfPeriod);
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
