#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	ExecutionIsAllowed = Parameters.ExecutionIsAllowed;
	Department  = Parameters.DepartmentFilter;
	ProductionArea        = Parameters.LotFilter;
	RCView          = Parameters.ViewRatbor;
	WorkCenter   = Parameters.WorkCenterFilter;
	Operation       = Parameters.OperationFilter;
	Product        = Parameters.ProductSelection_4_;
	Performer    = Parameters.PerformerFilter;
	Stage           = Parameters.StepFilter;
	Lot         = Parameters.ButchFilter;
	
	ShiftJobsAreUsed = 
		ProductionServer.ProductionBusinessUnitDescription(Department).UseShiftTasks;
	
	Operations.SettingsComposer.Settings.AdditionalProperties.Insert(
																	"ShiftJobsAreUsed",
																	ShiftJobsAreUsed);
	
	UseAdditionalAttributesAndInfo = GetFunctionalOption(
													"UseAdditionalAttributesAndInfo");
	
	IsMobileClient = Common.IsMobileClient();
	
	Items.ShiftTaskPresentation.Visible = ShiftJobsAreUsed;
	
	PuttingIntoOperationMode = Parameters.Property("WorkMode") And Parameters.WorkMode = "AcceptanceIntoWork";
	
	Settings = DataProcessors.ExecutionOfOperations2_2.GetUserSettings();
	
	If Settings <> Undefined Then
	
		PlotInSettings     = ValueIsFilled(Settings.ProductionArea);
		Rcvconfigurations          = ValueIsFilled(Settings.WorkCenter);
		ArtistInSettings = ValueIsFilled(Settings.Performer);
		
	EndIf;
	
	Items.OperationsContextMenuPutIntoOperation.Visible        = PuttingIntoOperationMode;
	Items.OperationContextMenuToCelebrateTheFulfillmentOfAnother.Visible = PuttingIntoOperationMode;
	Items.OperationsPutIntoOperation.Visible                       = PuttingIntoOperationMode;
	
	Items.OperationsContextMenuMarkCompletion.Visible  = Not PuttingIntoOperationMode;
	Items.OperationsContextMenuPartialExecution.Visible = Not PuttingIntoOperationMode;
	Items.OperationsPartialExecution.Visible                = Not PuttingIntoOperationMode;
	
	If PuttingIntoOperationMode Then
		CommonClientServer.SetDynamicListFilterItem(
			Operations,
			"Status",
			StatusesOfOperationAssigned(),
			DataCompositionComparisonType.InList,
			,
			True);
		Title = NStr("vi = 'Thuê';
					|ru = 'Принятие в работу';
					|en = 'Putting into operation'; fa = 'Putting into operation';
					|it = 'Presa in carico';
					|pl = 'Przyjęcie do wykonania';
					|tr = 'İşe kabul edilme'");
	EndIf;
	
	SetShiftSelection();
	
	SetFilters();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	FilterParameters = New Structure();
	
	FilterParameters.Insert("ExecutionIsAllowed", ExecutionIsAllowed);
	FilterParameters.Insert("RCView", RCView);
	FilterParameters.Insert("WorkCenter", WorkCenter);
	FilterParameters.Insert("Performer", Performer);
	FilterParameters.Insert("Operation", Operation);
	FilterParameters.Insert("Product", Product);
	FilterParameters.Insert("Lot", Lot);
	FilterParameters.Insert("Stage", Stage);
	FilterParameters.Insert("ProductionArea", ProductionArea);
	
	Close(FilterParameters);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersOperations

&AtClient
Procedure OperationsOnActivateRow(Item)
	
	If IsMobileClient Then
		VisibilityOfMainActionButton = ?(Items.Operations.SelectedRows.Count()>1,True,False);
		
		Items.MarkCompletion.Visible = VisibilityOfMainActionButton And Not PuttingIntoOperationMode;
		Items.PutIntoOperation.Visible     = VisibilityOfMainActionButton And PuttingIntoOperationMode;
		Items.Select.Visible            = Not VisibilityOfMainActionButton;
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure OperationsOnGetDataAtServer(TagName, Settings, Rows)
	
	Today = BegOfDay(CurrentSessionDate());
	
	KeysList = Rows.GetKeys();
	
	If Not Settings.AdditionalProperties.Property("ShiftJobsAreUsed")
			Or (Settings.AdditionalProperties.Property("ShiftJobsAreUsed")
			And Not Settings.AdditionalProperties.ShiftJobsAreUsed) Then
		Return
	EndIf; 
	
	ShiftData = ProductionAccounting.CurShift(KeysList[0].Department);
	
	Date = ?(ValueIsFilled(ShiftData),ShiftData.Date,Today);
	
	Query = New Query(
		"SELECT
		|	ShiftJobs.Date AS Date,
		|	ShiftJobs.Shift AS Shift,
		|	Operations.Ref AS Ref
		|FROM
		|	Document.ProductionOperation2_2 AS Operations
		|		LEFT JOIN Document.ShiftTask AS ShiftJobs
		|		ON Operations.ShiftTask = ShiftJobs.Ref
		|WHERE
		|	Operations.Ref IN(&References)");
	
	Query.SetParameter("References", KeysList);
	
	Result = Query.Execute().Select();
	
	While Result.Next() Do
		
		ShiftDate = Result.Date;
		
		StringDate  = Format(ShiftDate, "DF=dd.MM");
		LineChange = String(Result.Shift);
		
		Rows[Result.Ref].Data.ShiftTaskPresentation = StringDate + " " + LineChange;
			
		If ShiftDate < Date Then
			
			Rows[Result.Ref].Appearance["ShiftTaskPresentation"].SetParameterValue("TextColor",
																											New Color(255,0,0));
			
		EndIf;
	
	EndDo;
	
EndProcedure

&AtClient
Procedure OperationsSelection(Item, RowSelected, Field, StandardProcessing)
	StandardProcessing = False;
	ProductionManagementClient.OpenOperationDocumentForm(RowSelected[0]);
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FiltersLineClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure();
	
	FormParameters.Insert("Product",Product);
	FormParameters.Insert("Performer",Performer);
	FormParameters.Insert("Operation",Operation);
	FormParameters.Insert("RCView",RCView);
	FormParameters.Insert("WorkCenter",WorkCenter);
	FormParameters.Insert("ExecutionIsAllowed",ExecutionIsAllowed);
	FormParameters.Insert("Stage",Stage);
	FormParameters.Insert("Lot",Lot);
	FormParameters.Insert("Department",Department);
	FormParameters.Insert("ProductionArea",ProductionArea);
	
	OpenForm("DataProcessor.ExecutionOfOperations2_2.Form.MobileApplicationFiltersSetting",
		FormParameters,
		ThisForm,
		,
		,
		,
		New CallbackDescription("SetFiltersClient",ThisObject));
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OperationsSetStatusInProgress(Command)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.Operations);
	
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	ProductionAccountingClient.SetProductionOperationStatus(
		SelectedRows,
		"Running",
		Department);
	
EndProcedure

&AtClient
Procedure OperationsSetStatusCompleted(Command)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.Operations);
	
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	If Not CheckingAdditionalBankingDetails(SelectedRows) Then
		Return;
	EndIf;
	
	ProductionAccountingClient.SetProductionOperationStatus(
		SelectedRows,
		"Executed",
		Department);
	
EndProcedure

&AtClient
Procedure OperationsSetStatusFailed(Command)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.Operations);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	ProductionAccountingClient.SetProductionOperationStatus(
		SelectedRows,
		"NotExecuted",
		Department);
	
EndProcedure

&AtClient
Procedure PartialExecution(Command)
	
	If Not CheckingAdditionalBankingDetails(Items.Operations.SelectedRows) Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	
	FormParameters.Insert("Ref",Items.Operations.CurrentRow);
	
	Notification = New CallbackDescription("PartialExecutionCompletion", ThisForm);
	
	OpenForm("DataProcessor.ExecutionOfOperations2_2.Form.MarkPartialExecution",
					FormParameters, 
					ThisForm,
					,
					,
					,
					Notification);
EndProcedure

&AtClient
Procedure CancelAssignment(Command)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.Operations);
	
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	ProductionAccountingClient.CancelAssignmentOfProductionOperations(SelectedRows, Department);
	
EndProcedure

&AtClient
Procedure PartialExecutionCompletion(ClosingResult, AdditionalParameters) Export
	Items.Operations.Refresh();
EndProcedure

&AtClient
Procedure ClearFilters(Command)
	
	If Not Rcvconfigurations Then
		RCView        = Undefined;
		WorkCenter = Undefined;
	EndIf;
	
	If Not ArtistInSettings Then
		Performer = Undefined;
	EndIf;
	
	If Not PlotInSettings Then
		ProductionArea = Undefined;
	EndIf;
	
	Operation = Undefined;
	Product  = Undefined;
	Stage     = Undefined;
	Lot   = Undefined;
	
	SetFilters();
EndProcedure

#If MobileClient Then

&AtClient
Procedure ScanBarcode(Command)
	
	If MultimediaTools.BarcodeScanningSupported() Then
		
		ScanningHandler = New CallbackDescription("ScanProcessing", ThisForm);
		
		MultimediaTools.ShowBarcodeScanning(NStr("vi = 'Hướng máy ảnh vào mã vạch';
												|ru = 'Наведите камеру на штрихкод';
												|en = 'Point the camera at the barcode'; fa = 'Point the camera at the barcode';
												|it = 'Puntare la camera sul codice a barre';
												|pl = 'Skieruj aparat na kod kreskowy';
												|tr = 'Kamerayı barkodun üzerine getirin'"),
			ScanningHandler,
			,
			BarcodeType.Linear);
	EndIf;
		
EndProcedure

&AtClient
Procedure ScanProcessing(Barcode, Result, Message, AdditionalParameters) Export

	If Result Then
		
		MultimediaTools.PlaySoundAlert(SoundAlert.Default,True);
		MultimediaTools.CloseBarcodeScanning();
		FillInSelectionForm(Barcode);
	Else
		
		Message = NStr("vi = 'Lỗi xử lý mã vạch';
						|ru = 'Ошибка обработки штрих кода';
						|en = 'Barcode processing error'; fa = 'Barcode processing error';
						|it = 'Errore di elaborazione del codice a barre';
						|pl = 'Wystąpił błąd podczas przetwarzania kodu kreskowego';
						|tr = 'Barkod işleme hatası'");
		
	EndIf;
EndProcedure

#EndIf

#EndRegion

#Region Private

#Region Filters

&AtClient
Procedure SetFiltersClient(Result = Undefined, AdditionalParameters = Undefined) Export
	SetFilters(Result, AdditionalParameters);
EndProcedure

&AtServer
Procedure SetFilters(Result = Undefined, AdditionalParameters = Undefined)
	
	If Result <> Undefined Then
		
		ExecutionIsAllowed = Result.ExecutionIsAllowed;
		RCView = Result.RCView;
		WorkCenter = Result.WorkCenter;
		Performer = Result.Performer;
		Operation = Result.Operation;
		Product = Result.Product;
		Lot = Result.Lot;
		Stage = Result.Stage;
		ProductionArea = Result.ProductionArea;
	
	EndIf;
	
	FiltersLine = "";
	
	SetSelectionCanBePerformed();
	SetSelectionByStage();
	SetSelectionByBatch();
	SetSelectionByProduct();
	SetSelectionByOperation();
	SetSelectionByPerformer();
	SetSelectionByWorkCenter();
	SetSelectionBySite();
	SetSelectionByDivision();
	
	ConfigureSelectionElements();
	
EndProcedure

&AtServer
Procedure SetSelectionCanBePerformed()
	
	CommonClientServer.SetDynamicListFilterItem(Operations,
		"YouCanStartNow",
		ExecutionIsAllowed,
		DataCompositionComparisonType.Equal,
		,
		ExecutionIsAllowed);
	
EndProcedure

&AtServer
Procedure SetSelectionByDivision()
	
	CommonClientServer.SetDynamicListFilterItem(Operations,
		"Department",
		Department,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Department));
EndProcedure

&AtServer
Procedure SetSelectionBySite()
	
	CommonClientServer.SetDynamicListFilterItem(Operations,
		"ProductionArea",
		ProductionArea,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(ProductionArea));
		
	AddToSelectionLine(ProductionArea);
	
EndProcedure

&AtServer
Procedure SetShiftSelection()
	If ShiftJobsAreUsed Then
		
		ShiftData = ProductionAccounting.CurShift(Department);
		
		FilterDate = ?(ValueIsFilled(ShiftData),ShiftData.Date,CurrentSessionDate());
		
		SmenaGroup = CommonClientServer.CreateFilterItemGroup(
													Operations.Filter.Items,
													"SmenaGroup",
													DataCompositionFilterItemsGroupType.AndGroup);
		
		CommonClientServer.AddCompositionItem(
			SmenaGroup,
			"ShiftTask.Date",
			DataCompositionComparisonType.LessOrEqual,
			FilterDate,
			"Date",
			True);
		
		CommonClientServer.AddCompositionItem(
			SmenaGroup,
			"ShiftTask.Status",
			DataCompositionComparisonType.NotEqual,
			PredefinedValue("Enum.ShiftTaskStatuses.Closed"),
			"Shifts",
			True);
		
	EndIf;
EndProcedure

&AtServer
Procedure SetSelectionByOperation()
	
	CommonClientServer.SetDynamicListFilterItem(Operations,
		"Operation",
		Operation,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Operation));
		
	AddToSelectionLine(Operation);
	
EndProcedure

&AtServer
Procedure SetSelectionByPerformer()
	
	If ProductionServer.AccountingOfLaborCostsInContextOfEmployeesIsUsed(CurrentSessionDate()) Then
		Person = ?(ValueIsFilled(Performer),
			Common.ObjectAttributeValue(Performer, "Individual"),
			Undefined);
		
		Assignees = New Array;
		Assignees.Add(Performer);
		Assignees.Add(Person);
		
		CommonClientServer.SetDynamicListFilterItem(Operations,
			"Performer",
			Assignees,
			DataCompositionComparisonType.InList,
			,
			ValueIsFilled(Performer));
	Else
		
		CommonClientServer.SetDynamicListFilterItem(Operations,
			"Performer",
			Performer,
			DataCompositionComparisonType.Equal,
			,
			ValueIsFilled(Performer));
	EndIf;
	
	AddToSelectionLine(Performer);
	
EndProcedure

&AtServer
Procedure SetSelectionByProduct()
	
	CommonClientServer.SetDynamicListFilterItem(Operations,
		"Stage.ProductionLot.MainProductProducts",
		Product,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Product));
		
	AddToSelectionLine(Product);
	
EndProcedure

&AtServer
Procedure SetSelectionByBatch()
	
	CommonClientServer.SetDynamicListFilterItem(Operations,
		"Stage.ProductionLot",
		Lot,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Lot));
		
	AddToSelectionLine(Lot);
	
EndProcedure

&AtServer
Procedure SetSelectionByStage()
	CommonClientServer.SetDynamicListFilterItem(Operations,
		"Stage",
		Stage,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(Stage));
		
	AddToSelectionLine(Stage);
	
EndProcedure

&AtServer
Procedure SetSelectionByWorkCenter()
	
	If ValueIsFilled(WorkCenter) Then
		
		RCDetails = Common.ObjectAttributesValues(WorkCenter, "WorkCenterType.Department, ProductionArea");
		
		RCDivision = RCDetails.WorkCenterTypeDepartment;
		RCSection       = RCDetails.ProductionArea;
		
		If RCDivision <> Department
			Or (ValueIsFilled(ProductionArea) And RCSection <> ProductionArea) Then
			
			MessageText = NStr("vi = 'Nguồn lực sản xuất được chọn không thuộc bộ phận hoặc khu vực hiện tại';
								|ru = 'Выбранный рабочий центр не находится в текущем подразделении или участке';
								|en = 'The selected work center is not in the current business unit or site'; fa = 'The selected work center is not in the current business unit or site';
								|it = 'Il centro operativo selezionato non si trova nel reparto corrente o area';
								|pl = 'Wybrane centrum pracy nie znajduje się w bieżącym dziale lub działce';
								|tr = 'Seçili iş merkezi, mevcut departmanda veya sahada bulunmamaktadır'");
			Common.MessageToUser(MessageText);
			
			WorkCenter = Undefined;
			
			Return;
			
		EndIf;
		
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(Operations,
		"WorkCenter",
		WorkCenter,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(WorkCenter));
	
	CommonClientServer.SetDynamicListFilterItem(Operations,
		"WorkCenterType",
		RCView,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(RCView));
	
	AddToSelectionLine(WorkCenter);
	
	If Not ValueIsFilled(WorkCenter) Then
		AddToSelectionLine(RCView);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInSelectionForm(Barcode)
	
	Ref = GetRef(Barcode);
	
	If TypeOf(Ref) = Type("CatalogRef.WorkCenters") And Not Rcvconfigurations Then
		
		WorkCenter = Ref;
		
	ElsIf (TypeOf(Ref) = Type("CatalogRef.Persons")
		) And Not ArtistInSettings Then
		
		Performer = Ref;
		
	ElsIf TypeOf(Ref) = Type("CatalogRef.ManufacturingOperations") Then
		
		Operation = Ref;
		
	ElsIf TypeOf(Ref) = Type("CatalogRef.Products") Then
		
		Product = Ref;
		
	ElsIf TypeOf(Ref) = Type("CatalogRef.ProductionLots") Then
		
		Lot = Ref;
		
	ElsIf TypeOf(Ref) = Type("DocumentRef.ProductionStage2_2") Then
		
		Stage = Ref;
		
	ElsIf TypeOf(Ref) = Type("DocumentRef.ProductionOperation2_2") Then
		
		Items.Operations.CurrentRow = Ref;
		
		Return;
		
	Else
		
		Message = New UserMessage;
		Message.Text = NStr("vi = 'Không tìm thấy mã vạch';
							|ru = 'Штрих-код не найден';
							|en = 'Barcode is not found'; fa = 'Barcode is not found';
							|it = 'Codice a barre non trovato';
							|pl = 'Kod kreskowy nie został znaleziony';
							|tr = 'Barkod bulunamadı'");
		Message.Message();
		
	EndIf;
	
	SetFilters();
	
EndProcedure

&AtServer
Procedure ConfigureSelectionElements()
	
	If FiltersLine = "" Then
		FiltersLine = ?(ExecutionIsAllowed,NStr("vi = 'Đặt bộ lọc *';
												|ru = 'Установить отбор*';
												|en = 'Set filter*'; fa = 'Set filter*';
												|it = 'Impostare selezione*';
												|pl = 'Ustaw dobór*';
												|tr = 'Filtre yapılandır*'"),NStr("vi = 'Đặt bộ lọc';
																			|ru = 'Установить отбор';
																			|en = 'Set filter'; fa = 'تعیین فیلتر';
																			|it = 'Impostare selezione';
																			|pl = 'Ustaw filtr';
																			|tr = 'Filtre yapılandır'"));
		Items.ClearFilters.Visible		= False;
	Else
		FiltersLine = Left(FiltersLine, StrLen(FiltersLine)-2);
		Items.ClearFilters.Visible		= True;
	EndIf;
	
EndProcedure

&AtServer
Procedure AddToSelectionLine(Ref)
	If ValueIsFilled(Ref) Then
		DocumentsTypesDetails = Documents.AllRefsType();

		LinkDocument_ = DocumentsTypesDetails.ContainsType(TypeOf(Ref));
		
		FiltersLine = FiltersLine
			+ ?(LinkDocument_,
				Common.ObjectAttributeValue(Ref, "Number"),
				Common.ObjectAttributeValue(Ref, "Description"))
			+ ", ";
	EndIf;
EndProcedure


#EndRegion

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Color-coding of operations that cannot be started
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Operations.YouCanStartNow");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.GrayTextColor1);
	
	// Registration of the "Status" field
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.Status.Name);
	
	StatusesList = New ValueList();
	StatusesList.LoadValues(StatusesOfOperationAssigned());
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Operations.Status");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = StatusesList;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Chỉ định';
													|ru = 'Назначена';
													|en = 'Assigned'; fa = 'تخصیص‌یافته';
													|it = 'Assegnato';
													|pl = 'Assigned';
													|tr = 'Atandı'"));
	
	// Registration of the "Operation" field
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.OperationsOperation.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Operations.Operation");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("Operations.Description"));
	
EndProcedure

&AtServerNoContext
Function GetRef(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.ProductionStage2_2.EmptyRef"));
	Managers.Add(PredefinedValue("Catalog.ProductionLots.EmptyRef"));
	Managers.Add(PredefinedValue("Catalog.Products.EmptyRef"));
	Managers.Add(PredefinedValue("Catalog.WorkCenters.EmptyRef"));
	Managers.Add(PredefinedValue("Catalog.ManufacturingOperations.EmptyRef"));
	Managers.Add(PredefinedValue("Document.ProductionOperation2_2.EmptyRef"));
	Managers.Add(PredefinedValue("Catalog.Persons.EmptyRef"));

	References = BarcodingOfPrintForms.GetLinkFromBarcodeOfTabularDocument(Barcode,Managers);
	
	If References.Count() = 1 Then
		
		Return References[0];
		
	EndIf;
	Return Undefined;

EndFunction

&AtClient
Function CheckingAdditionalBankingDetails(Val SelectedRows)
	
	If UseAdditionalAttributesAndInfo Then
		
		OperationsWithAdditionalBankingDetails = GetOperationsForFillingInAdditionalBankingDetails(SelectedRows);
		
		If OperationsWithAdditionalBankingDetails.Count() = 1 And SelectedRows.Count() = 1 Then
			
			FormParameters = New Structure();
			FormParameters.Insert("Key", OperationsWithAdditionalBankingDetails[0]);
			FormParameters.Insert("Status", 
				PredefinedValue("Enum.ProductionOperationStatuses.Executed"));
			FormParameters.Insert("AdditionalDetailsNotFilledIn", True);
			FormParameters.Insert("CheckWhenOpening", True);

			OpenForm("Document.ProductionOperation2_2.Form.DocumentForm", FormParameters);
			
			Return False;
			
		ElsIf SelectedRows.Count() > 1 And OperationsWithAdditionalBankingDetails.Count() > 0 Then
			
			CommonClient.MessageToUser(NStr("vi = 'Không thể thực hiện nhiều giao dịch được chọn.
				|Cần nhập chỉ tiêu kiểm soát.';
				|ru = 'Множественное выполнение выделенных операций недоступно.
				|Необходимо ввести контролируемые показатели.';
				|en = 'Multiple execution of selected operations is not available.
				|Controlled indicators must be entered.'; fa = 'Multiple execution of selected operations is not available.
				|Controlled indicators must be entered.';
				|it = 'Impossibile eseguire operazioni multiple selezionate. 
				| è necessario inserire indicatori controllati.';
				|pl = 'Wielokrotne wykonanie wybranych operacji jest niemożliwe.
				|Należy wprowadzić kontrolowane wskaźniki.';
				|tr = 'Belirtilen işlemlerin birden çok gerçekleştirilmesi mümkün değil.
				|Kontrollü göstergeleri girmeniz gerekmektedir.'"));
			
			Return False;
			
		EndIf;
		
	EndIf;
	
	Return True;
	
EndFunction

&AtServerNoContext
Function GetOperationsForFillingInAdditionalBankingDetails(SelectedRows)
	
	Result = New Array();
	
	For Each Ref In SelectedRows Do
	
		If PropertyManager.UseAddlAttributes(Ref) Then
			
			AddAttributes = PropertyManager.ObjectProperties(Ref);
			
			For Each Attribute In AddAttributes Do
				If Attribute.RequiredToFill
					And PropertyManager.PropertyValue(Ref, Attribute) = Undefined Then
					
					Result.Add(Ref);
					
					Break;
					
				EndIf;
			EndDo;
			
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function StatusesOfOperationAssigned()
	
	Result = New Array;
	
	Result.Add(PredefinedValue("Enum.ProductionOperationStatuses.CreatedOn_"));
	
	Return Result;
	
EndFunction

#EndRegion
